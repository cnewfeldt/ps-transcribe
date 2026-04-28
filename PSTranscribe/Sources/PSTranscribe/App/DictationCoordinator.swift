import AppKit
import Foundation
import Observation
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
    /// Saved pasteboard items captured before the dictation write (DICT-06).
    var savedPasteboardItems: [NSPasteboardItem]?
    /// Pasteboard `changeCount` immediately after our write -- used as the restore guard.
    var postWriteChangeCount: Int?
    /// Task that performs the delayed clipboard restore.
    var restoreTask: Task<Void, Never>?

    // MARK: - Init

    init(settings: AppSettings,
         sessionCoordinator: SessionCoordinator,
         libraryStore: LibraryStore) {
        self.settings = settings
        self.sessionCoordinator = sessionCoordinator
        self.libraryStore = libraryStore
        self.dictationLogger = DictationLogger()
        self.dictationStore = TranscriptStore()
        self.dictationEngine = TranscriptionEngine(transcriptStore: dictationStore)
        dictCoordLog.info("DictationCoordinator initialized; engine ready for pre-warm")
    }
}
