import AppKit
import Foundation
import Observation
import SwiftUI
import os

private let dictCoordLog = Logger(subsystem: "com.pstranscribe.app", category: "DictationCoordinator")

/// App-scope coordinator that orchestrates hotkey-triggered dictation sessions.
///
/// Owns its own `TranscriptionEngine` instance + private `TranscriptStore` -- does
/// NOT share the meeting engine's audio pipeline (Architecture Option B / Phase 18 D-13).
/// This separation is required because `AVAudioEngine.start()` cannot run twice on
/// the same input device. `SessionCoordinator.anySessionActive` enforces the gate
/// that prevents both engines from running simultaneously (DICT-11).
///
/// State machine drives the HUD's visual state and is the single source of truth
/// for `isActive`, which feeds back into `SessionCoordinator.anySessionActive`.
///
/// Wave 2 (this plan, 18-04) lands the type, state enum, dependency wiring, and
/// `isActive`. Wave 4 (Plan 18-06) lands `beginDictation`, `endDictation`,
/// `cancelDictation`, `handleEscape`, `handleHoldRelease`, and `preWarmModels`.
@Observable
@MainActor
final class DictationCoordinator {

    // MARK: - State machine

    /// All HUD-visible states. Equatable so SwiftUI can animate transitions.
    /// `cancellingPending` carries a deadline so the UI can show "Press Esc again
    /// to cancel" while the coordinator's internal timer race remains the
    /// authoritative cancel-or-revert decision (Phase 18 D-06).
    enum State: Equatable {
        case idle
        case loadingModel
        case listening
        case cancellingPending(deadline: Date)
        case copied
        case blockedSessionActive
    }

    private(set) var state: State = .idle
    private(set) var elapsed: TimeInterval = 0
    private(set) var partialText: String = ""

    /// True when the coordinator owns an in-flight or transitioning session.
    /// `SessionCoordinator.anySessionActive` ORs this into the global "any session"
    /// flag. listening / cancellingPending / loadingModel all qualify as active --
    /// in those states a new dictation must NOT start.
    /// idle / copied / blockedSessionActive are NOT active (copied is a 1s
    /// post-commit visual flourish; blockedSessionActive is a 1.5s notice with
    /// no audio capture in flight).
    var isActive: Bool {
        switch state {
        case .listening, .cancellingPending, .loadingModel:
            return true
        case .idle, .copied, .blockedSessionActive:
            return false
        }
    }

    // MARK: - Dependencies (held strongly except SessionCoordinator)

    let settings: AppSettings
    weak var sessionCoordinator: SessionCoordinator?
    let libraryStore: LibraryStore
    let dictationLogger: DictationLogger
    let dictationStore: TranscriptStore
    let dictationEngine: TranscriptionEngine
    /// 18.1 D-18: shared destination fan-out (Local File, Obsidian, Notion).
    /// Constructed at app scope and injected here; coordinator owns a strong ref.
    let saveDestinations: SaveDestinations
    /// Hotkey service is wired by the app scope (Plan 18-08); coordinator stores
    /// the reference so Wave 4 can attach `onKeyDown`/`onKeyUp` callbacks.
    weak var hotkeyService: GlobalHotkeyService?

    // MARK: - Internal session state (used by Wave 4 begin/end/cancel logic)

    /// Wall-clock start of the current session. nil when state == .idle.
    var sessionStartTime: Date?
    /// Background task that ticks `elapsed` every 250ms while listening.
    var elapsedTimerTask: Task<Void, Never>?
    /// Task that auto-reverts cancellingPending → listening after 3s if no second Esc.
    var cancelRevertTask: Task<Void, Never>?
    /// Task that dismisses the HUD ~1.0s after entering .copied.
    var copiedDismissTask: Task<Void, Never>?

    // MARK: - Init

    init(settings: AppSettings,
         sessionCoordinator: SessionCoordinator,
         libraryStore: LibraryStore,
         saveDestinations: SaveDestinations) {
        self.settings = settings
        self.sessionCoordinator = sessionCoordinator
        self.libraryStore = libraryStore
        self.saveDestinations = saveDestinations
        self.dictationLogger = DictationLogger()
        self.dictationStore = TranscriptStore()
        self.dictationEngine = TranscriptionEngine(transcriptStore: dictationStore)
        dictCoordLog.info("DictationCoordinator initialized; engine ready for pre-warm")
    }

    // MARK: - Wiring (called once after windowController is constructed at app scope)

    /// Wave 4 wiring point. PSTranscribeApp (Plan 18-08) constructs the
    /// DictationWindowController, then calls `attach(windowController:)` so the
    /// coordinator can install a content closure that reads live coordinator
    /// state (state/elapsed/partialText). The closure is captured weakly to
    /// break the coordinator <-> windowController retain pair.
    func attach(windowController: DictationWindowController) {
        self.windowController = windowController
        windowController.setContent(AnyView(DictationHUDBinding(coordinator: self)))
    }

    var windowController: DictationWindowController?

    // MARK: - Lifecycle: pre-warm

    /// Called at app launch (D-13: eager pre-warm) to download and load the
    /// dictation engine's models in the background. First hotkey press is then
    /// instant. If pre-warm fails, the coordinator transparently falls back to
    /// lazy load on first hotkey press (state .loadingModel until ready).
    func preWarmModels() async {
        await dictationEngine.prepareModels()
    }

    // MARK: - Lifecycle: begin

    /// Start a dictation session. Guards on:
    ///   1. self.isActive -- already in flight, no-op (D-05 toggle semantics).
    ///   2. sessionCoordinator.anySessionActive -- another session (meeting recording
    ///      or model update) is in flight, show .blockedSessionActive notice for 1.5s
    ///      then return to .idle. (D-14, DICT-11)
    /// Otherwise: opens a DictationLogger session if mode includes plainFolder
    /// (with silent fallback per D-15), shows the HUD, starts the elapsed timer,
    /// and starts the dictation engine. State transitions: idle -> loadingModel -> listening.
    func beginDictation() async {
        guard !isActive else { return }

        if sessionCoordinator?.anySessionActive == true {
            await showBlockedNotice()
            return
        }

        sessionStartTime = Date()
        partialText = ""
        elapsed = 0

        // 18.1 D-18: dictation file persistence is now driven by SaveDestinations.
        // beginDictationLocalFile opens a streaming session against localFileRoot/Dictation
        // when localFileEnabled is true; logs + no-throws on failure (D-15 silent fallback).
        await saveDestinations.beginDictationLocalFile(dictationLogger: dictationLogger)

        state = dictationEngine.modelsReady ? .listening : .loadingModel
        windowController?.show()

        elapsedTimerTask?.cancel()
        elapsedTimerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                guard let self else { return }
                if let start = self.sessionStartTime {
                    self.elapsed = Date().timeIntervalSince(start)
                    self.partialText = self.dictationStore.volatileYouText
                }
            }
        }

        await dictationEngine.start(
            locale: settings.locale,
            inputDeviceID: settings.inputDeviceID,
            appBundleID: nil
        )
        if dictationEngine.modelsReady, case .loadingModel = state {
            state = .listening
        }
    }

    // MARK: - Lifecycle: end (commit)

    /// Stop the engine, assemble the final transcript, branch on output mode
    /// (.clipboard / .plainFolder / .both), create a library entry, and transition
    /// to .copied for ~1s before returning to .idle. (D-05, D-09, D-10, D-12, FOLDER-04)
    func endDictation() async {
        switch state {
        case .listening:
            break
        case .cancellingPending:
            cancelRevertTask?.cancel()
            cancelRevertTask = nil
        default:
            return
        }

        await dictationEngine.stop()
        elapsedTimerTask?.cancel(); elapsedTimerTask = nil

        // Phase 18-09 Gap #1 fix — snapshot utterances so the append loop and the assembled
        // string see the same data, and concurrent mutation during the await chain cannot
        // reorder file writes (T-18-09-02).
        let utterancesSnapshot = dictationStore.utterances
        let utterancesText = utterancesSnapshot.map { $0.text }
        let volatile = dictationStore.volatileYouText.trimmingCharacters(in: .whitespacesAndNewlines)
        let assembled = (utterancesText + (volatile.isEmpty ? [] : [volatile]))
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Phase 18-09 Gap #1 fix — flush the dictation transcript to the plain-folder file
        // BEFORE closing the session. The D-15 silent-fallback path leaves
        // hasActiveSession == false (startSession threw, was caught at lines 163-168, no
        // session opened); the guard ensures the failed-open file path NEVER receives
        // transcript writes (preserves D-15 secrecy + T-18-06-06: os_log content stays
        // free of transcript text).
        if await dictationLogger.hasActiveSession {
            for utterance in utterancesSnapshot {
                await dictationLogger.append(text: utterance.text, timestamp: utterance.timestamp)
            }
            // Volatile remainder: the active engine's partial-but-not-yet-finalized text.
            // The clipboard assembled string already includes it (line above); appending
            // it as a final synthetic utterance keeps the file body and clipboard text aligned.
            if !volatile.isEmpty {
                await dictationLogger.append(text: volatile, timestamp: Date())
            }
        }

        let finalFileURL: URL? = await dictationLogger.endSession()

        // 18.1 D-15: clipboard write is unconditional and always-on. Order is critical
        // (Pitfall #4): clipboard MUST be written BEFORE any *network* await
        // (saveDestinations.save -> Notion API call), so a slow Notion request cannot
        // block the user's paste UX. The dictationLogger flush above is local-disk I/O
        // (microseconds in practice); if a future failure mode makes that flush block
        // on a slow disk (network home, fsync stall), the clipboard write should be
        // moved above the dictationLogger block.
        writeToClipboardWithPrivacyMarkers(assembled)

        // 18.1 D-18: post-clipboard fan-out to Obsidian + Notion. Local File for
        // dictation is owned by the streaming dictationLogger above (already on disk),
        // so we toggle localFileEnabled off for this single call to prevent a second
        // Local File copy.
        let saveMetadata = SaveMetadata(
            sessionType: .dictation,
            title: autoNameFromTranscript(assembled),
            startDate: sessionStartTime ?? Date(),
            duration: elapsed,
            sourceApp: "PSTranscribe",
            speakers: [],
            tags: []
        )
        let saveResult = await saveDictationToNonLocalDestinations(
            content: assembled,
            metadata: saveMetadata
        )

        // D-19 / D-12: source-of-truth for the library row's filePath.
        // Priority: Local File (streamed via dictationLogger) > Obsidian (fan-out) > "" + inline transcript.
        let primaryFilePath: String = finalFileURL?.path
            ?? saveResult.obsidianFileURL?.path
            ?? ""
        let inlineTranscriptToStore: String? =
            (finalFileURL == nil && saveResult.obsidianFileURL == nil) ? assembled : nil

        let preview = String(assembled.prefix(120))
        let entry = LibraryEntry(
            id: UUID(),
            name: autoNameFromTranscript(assembled),
            sessionType: .dictation,
            startDate: sessionStartTime ?? Date(),
            duration: elapsed,
            filePath: primaryFilePath,
            sourceApp: "PSTranscribe",
            isFinalized: true,
            firstLinePreview: preview.isEmpty ? nil : preview,
            notionPageURL: saveResult.notionPageURL?.absoluteString,
            inlineTranscript: inlineTranscriptToStore
        )
        await libraryStore.addEntry(entry)

        state = .copied
        copiedDismissTask?.cancel()
        copiedDismissTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(1000))
            guard let self else { return }
            self.windowController?.hide()
            self.state = .idle
            self.cleanupSession()
        }

        NotificationCenter.default.post(name: .dictationSessionEnded, object: nil)
    }

    // MARK: - Lifecycle: cancel (atomic, D-08)

    /// Atomic cancel: stop engine, discard plain-folder file (if any), no clipboard
    /// write, no library entry. Idempotent on already-idle. (D-08)
    func cancelDictation() async {
        guard isActive else { return }
        await dictationEngine.stop()
        elapsedTimerTask?.cancel(); elapsedTimerTask = nil
        cancelRevertTask?.cancel(); cancelRevertTask = nil

        if await dictationLogger.hasActiveSession {
            await dictationLogger.discardSession()
        }
        windowController?.hide()
        state = .idle
        cleanupSession()
    }

    // MARK: - Esc handler (D-06)

    /// Esc routing per D-06:
    ///   - .listening, elapsed < 30s -> immediate cancel
    ///   - .listening, elapsed >= 30s -> .cancellingPending(deadline: now+3s),
    ///     auto-revert to .listening after 3s if no second Esc
    ///   - .cancellingPending -> confirm cancel
    ///   - other states -> ignore
    func handleEscape() async {
        switch state {
        case .listening:
            if elapsed < 30.0 {
                await cancelDictation()
            } else {
                let deadline = Date().addingTimeInterval(3.0)
                state = .cancellingPending(deadline: deadline)
                cancelRevertTask?.cancel()
                cancelRevertTask = Task { [weak self] in
                    try? await Task.sleep(for: .seconds(3))
                    guard let self else { return }
                    if case .cancellingPending = self.state {
                        self.state = .listening
                    }
                }
            }
        case .cancellingPending:
            await cancelDictation()
        default:
            break
        }
    }

    // MARK: - Press-and-hold release handler (D-07)

    /// Hold-release routing per D-07:
    ///   - held < 1.0s -> silent cancel (accidental tap)
    ///   - held >= 1.0s -> commit (endDictation)
    func handleHoldRelease() async {
        guard case .listening = state, let start = sessionStartTime else { return }
        let held = Date().timeIntervalSince(start)
        if held < 1.0 {
            await cancelDictation()
        } else {
            await endDictation()
        }
    }

    // MARK: - Private helpers

    private func cleanupSession() {
        sessionStartTime = nil
        elapsed = 0
        partialText = ""
        dictationStore.clear()
    }

    /// 18.1 D-19 helper: fan out dictation content to Obsidian + Notion only.
    /// The Local File destination for dictation is owned by the streaming `dictationLogger`,
    /// which has already written the file before this call. We pass `skipLocalFile: true`
    /// so SaveDestinations does not write a SECOND Local File copy. (WR-01: this replaces
    /// a transient `settings.localFileEnabled` toggle which was observable to SwiftUI and
    /// wrote UserDefaults twice per save.)
    private func saveDictationToNonLocalDestinations(content: String, metadata: SaveMetadata) async -> SaveResult {
        return await saveDestinations.save(
            content: content,
            metadata: metadata,
            skipLocalFile: true
        )
    }

    /// D-14: 1.5s notice when hotkey fires during another active session.
    private func showBlockedNotice() async {
        state = .blockedSessionActive
        windowController?.show()
        try? await Task.sleep(for: .milliseconds(1500))
        windowController?.hide()
        state = .idle
    }

    /// DICT-09: write to NSPasteboard with both Transient + AutoGenerated privacy markers
    /// so well-behaved clipboard managers (Alfred, Maccy, Pasta) skip the entry.
    private func writeToClipboardWithPrivacyMarkers(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        pb.setData(Data(), forType: NSPasteboard.PasteboardType("org.nspasteboard.TransientType"))
        pb.setData(Data(), forType: NSPasteboard.PasteboardType("org.nspasteboard.AutoGeneratedType"))
    }

    /// D-10: derive a library entry name from the first ~5 words of the transcript,
    /// truncate at 50 chars on word boundary, append ellipsis if truncated, strip
    /// leading/trailing ASCII punctuation. Falls back to "Dictation YYYY-MM-DD HH:mm"
    /// if the candidate is empty after stripping.
    /// Internal (not private) so AutoNameTests can exercise it directly via @testable.
    func autoNameFromTranscript(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return fallbackTimestampName()
        }
        let tokens = trimmed.split(separator: " ", omittingEmptySubsequences: true).prefix(5)
        var candidate = tokens.joined(separator: " ")

        if candidate.count > 50 {
            let limit = candidate.index(candidate.startIndex, offsetBy: 50)
            var sliceEnd = limit
            while sliceEnd > candidate.startIndex && candidate[sliceEnd] != " " {
                sliceEnd = candidate.index(before: sliceEnd)
            }
            if sliceEnd == candidate.startIndex {
                candidate = String(candidate.prefix(50))
            } else {
                candidate = String(candidate[..<sliceEnd])
            }
            candidate += "…"
        }

        let punct = CharacterSet(charactersIn: ".,;:!?\"'()[]{}<>-_`~/\\")
        candidate = candidate.trimmingCharacters(in: punct)

        return candidate.isEmpty ? fallbackTimestampName() : candidate
    }

    private func fallbackTimestampName() -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd HH:mm"
        return "Dictation \(fmt.string(from: Date()))"
    }

    // MARK: - Test surface (only callable from Swift Testing via @testable)

    #if DEBUG
    func _test_writeToClipboard(_ text: String) {
        writeToClipboardWithPrivacyMarkers(text)
    }
    func _test_setState(_ newState: State) { state = newState }
    func _test_setElapsed(_ value: TimeInterval) { elapsed = value }
    func _test_setSessionStartTime(_ date: Date?) { sessionStartTime = date }
    #endif
}

// MARK: - Notification name (consumed by ContentView listener in Plan 18-08)

extension Notification.Name {
    static let dictationSessionEnded = Notification.Name("com.pstranscribe.dictationSessionEnded")
}

// MARK: - HUD Binding (18.1 gap-08: live re-render fix)

/// SwiftUI wrapper that reads `@Observable DictationCoordinator` properties
/// inside its body, so SwiftUI's Observation framework subscribes to them and
/// re-renders the HUD when state / elapsed / volatileYouText mutate.
///
/// Why this exists: the previous shape installed a one-shot `AnyView(DictationHUD(...))`
/// snapshot in the window controller. Plain Swift values evaluated at install time
/// were frozen into DictationHUD's `let` properties, breaking Observation tracking.
/// User-visible symptom: HUD stayed at .idle (gray dot, "0:00", empty caption,
/// hidden Stop button) for the entire app lifetime, even while the audio engine
/// was actually running. See .planning/debug/18.1-uat-issue-2-dictation-no-recording.md.
///
/// DictationHUD remains parameterized (Phase 18 D-05) -- this wrapper is the
/// thin Observation bridge between the @Observable coordinator and the
/// snapshot-style HUD view.
///
/// Internal (not private) so `@testable import PSTranscribe` in
/// DictationHUDLiveBindingTests can reference the type directly. (18.1 gap-08: internal for @testable import)
struct DictationHUDBinding: View {
    let coordinator: DictationCoordinator
    var body: some View {
        DictationHUD(
            state: coordinator.state,
            elapsed: coordinator.elapsed,
            partialText: coordinator.dictationStore.volatileYouText,
            onStop: { [weak coordinator] in
                Task { @MainActor in await coordinator?.endDictation() }
            }
        )
    }
}
