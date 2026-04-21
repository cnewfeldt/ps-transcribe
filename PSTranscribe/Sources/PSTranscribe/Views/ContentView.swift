import SwiftUI
import AppKit
import Combine
import os

private let conferencingBundleIDs: [String: String] = [
    "com.microsoft.teams2": "Teams",
    "com.microsoft.teams": "Teams",
    "us.zoom.xos": "Zoom",
    "com.apple.FaceTime": "FaceTime",
    "com.tinyspeck.slackmacgap": "Slack",
    "com.cisco.webexmeetingsapp": "Webex",
    "Cisco-Systems.Spark": "Webex",
    "com.google.Chrome": "Chrome",
    "company.thebrowser.Browser": "Arc",
    "com.apple.Safari": "Safari",
    "com.microsoft.edgemac": "Edge",
]

struct ContentView: View {
    @Bindable var settings: AppSettings
    let notionService: NotionService
    @State private var transcriptStore = TranscriptStore()
    @State private var transcriptionEngine: TranscriptionEngine?
    @State private var sessionStore = SessionStore()
    @State private var transcriptLogger = TranscriptLogger()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    @State private var audioLevel: Float = 0
    @State private var activeSessionType: SessionType?
    @State private var detectedAppName: String?
    @State private var detectedAppBundleID: String?
    @State private var silenceSeconds: Int = 0
    @State private var sessionElapsed: Int = 0

    // Library state
    @State private var libraryStore = LibraryStore()
    @State private var libraryEntries: [LibraryEntry] = []
    @State private var selectedEntryID: UUID?
    @State private var activeLibraryEntryID: UUID?
    @State private var sessionName: String = ""
    @State private var isEditingTranscriptName: Bool = false
    @State private var transcriptNameDraft: String = ""
    @FocusState private var transcriptNameFieldFocused: Bool
    @State private var loadedUtterances: [Utterance] = []
    @State private var savedConfirmation: Bool = false
    @State private var nameDebounceTask: Task<Void, Never>?
    @State private var isSidebarVisible: Bool = true
    @Environment(\.openSettings) private var openSettings

    // Notion send state
    @State private var notionSendEntry: LibraryEntry?
    @State private var isNotionSending: Bool = false
    @State private var notionSendError: String?

    private var isNotionConfigured: Bool {
        !settings.notionDatabaseID.isEmpty
    }

    /// Returns the last path component of a configured vault folder as a
    /// friendly label. Falls back to the provided default when unset.
    private func folderDisplayName(path: String, fallback: String) -> String {
        guard !path.isEmpty else { return fallback }
        let last = URL(fileURLWithPath: path).lastPathComponent
        return last.isEmpty ? fallback : last
    }

    /// Human-readable name of the currently selected input device, shown in
    /// the Capture Dock status line when idle. Falls back to "System default".
    private var currentInputDeviceName: String {
        if settings.inputDeviceID == 0 { return "System default" }
        let devices = MicCapture.availableInputDevices()
        return devices.first(where: { $0.id == settings.inputDeviceID })?.name ?? "System default"
    }

    /// Seconds of VAD-confirmed silence before auto-stop fires, per session mode.
    /// Voice memos: short trailing silence means "done dictating."
    /// Call capture: long tolerances — natural meeting pauses shouldn't kill the recording.
    private var autoStopThreshold: Int {
        switch activeSessionType {
        case .voiceMemo: return 6
        case .callCapture: return 120
        case .none: return 120
        }
    }

    private var isObsidianAvailable: Bool {
        let hasVaultPath = !settings.vaultMeetingsPath.isEmpty || !settings.vaultVoicePath.isEmpty
        let isInstalled = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "md.obsidian") != nil
        return hasVaultPath && isInstalled
    }

    private func obsidianURLForEntry(_ entry: LibraryEntry) -> URL? {
        guard !entry.filePath.isEmpty,
              let vault = obsidianVaultForPath(entry.filePath) else { return nil }
        return makeObsidianURL(filePath: entry.filePath, vaultRoot: vault.root, vaultName: vault.name)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Hidden keyboard shortcut for sidebar toggle (⌘⇧S) — was on the
            // removed RecordingNameField toolbar; now invisible but available.
            Button {
                withAnimation(.spring(duration: 0.3, bounce: 0.1)) {
                    isSidebarVisible.toggle()
                }
            } label: { EmptyView() }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .frame(width: 0, height: 0)
            .opacity(0)

            HStack(spacing: 0) {
                if isSidebarVisible {
                    VStack(spacing: 0) {
                    LibrarySidebar(
                        entries: libraryEntries,
                        selectedID: $selectedEntryID,
                        activeEntryID: activeLibraryEntryID,
                        onRename: { id, newName in
                            let capturedID = id
                            let capturedName = newName
                            Task {
                                guard let entry = await libraryStore.entries.first(where: { $0.id == capturedID }) else { return }
                                guard !entry.filePath.isEmpty else {
                                    // No file on disk yet -- just update the display name
                                    await libraryStore.updateEntry(id: capturedID) { @Sendable e in
                                        e.name = capturedName
                                    }
                                    refreshLibrary()
                                    return
                                }
                                do {
                                    let newPath = try await transcriptLogger.renameFinalized(
                                        at: URL(fileURLWithPath: entry.filePath),
                                        to: capturedName
                                    )
                                    await libraryStore.updateEntry(id: capturedID) { @Sendable e in
                                        e.name = capturedName
                                        e.filePath = newPath.path
                                    }
                                } catch {
                                    await libraryStore.updateEntry(id: capturedID) { @Sendable e in
                                        e.name = capturedName
                                    }
                                    transcriptionEngine?.lastError = "Rename failed: \(error.localizedDescription)"
                                }
                                refreshLibrary()
                            }
                        },
                        onDelete: { id in
                            let capturedID = id
                            Task {
                                // Get entry details before removing
                                let entry = await libraryStore.entries.first(where: { $0.id == capturedID })

                                // 1. Delete transcript file from disk
                                if let filePath = entry?.filePath, !filePath.isEmpty {
                                    try? FileManager.default.removeItem(atPath: filePath)
                                }

                                // 2. Archive Notion page if it was sent
                                if let notionURL = entry?.notionPageURL {
                                    try? await notionService.archivePage(urlString: notionURL)
                                }

                                // 3. Remove from library
                                await libraryStore.removeEntry(id: capturedID)
                                if selectedEntryID == capturedID {
                                    selectedEntryID = nil
                                    loadedUtterances = []
                                }
                                refreshLibrary()
                            }
                        },
                        isNotionConfigured: isNotionConfigured,
                        onSendToNotion: { id in
                            if let entry = libraryEntries.first(where: { $0.id == id }) {
                                notionSendEntry = entry
                            }
                        },
                        isObsidianAvailable: isObsidianAvailable,
                        obsidianURLForEntry: { entry in
                            obsidianURLForEntry(entry)
                        }
                    )
                    .frame(maxHeight: .infinity)

                        CaptureDock(
                            isRecording: isRunning,
                            activeSessionType: activeSessionType,
                            sessionElapsed: sessionElapsed,
                            audioLevel: audioLevel,
                            silenceSeconds: silenceSeconds,
                            autoStopThreshold: autoStopThreshold,
                            currentInputName: currentInputDeviceName,
                            statusMessage: transcriptionEngine?.assetStatus,
                            errorMessage: transcriptionEngine?.lastError,
                            modelsReady: transcriptionEngine?.modelsReady ?? false,
                            hasError: transcriptionEngine?.hasError ?? false,
                            onStartCallCapture: { startSession(type: .callCapture) },
                            onStartVoiceMemo: { startSession(type: .voiceMemo) },
                            onStop: stopSession
                        )
                    }
                    .frame(width: 270)
                    .transition(.move(edge: .leading).combined(with: .opacity))

                    Rectangle()
                        .fill(Color.rule)
                        .frame(width: 0.5)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text("Transcript")
                        .chronicleMetaLabel()
                        .padding(.horizontal, 28)
                        .padding(.top, 18)
                        .padding(.bottom, 8)

                    transcriptHeader
                        .padding(.horizontal, 28)
                        .padding(.bottom, 14)

                    detailView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Rectangle()
                    .fill(Color.rule)
                    .frame(width: 0.5)

                DetailsPane(
                    selectedEntry: libraryEntries.first(where: { $0.id == selectedEntryID }),
                    meetingsFolderName: folderDisplayName(path: settings.vaultMeetingsPath, fallback: "Meetings"),
                    voiceFolderName: folderDisplayName(path: settings.vaultVoicePath, fallback: "Voice"),
                    isObsidianAvailable: isObsidianAvailable,
                    obsidianURL: libraryEntries.first(where: { $0.id == selectedEntryID }).flatMap { obsidianURLForEntry($0) }
                )
                .frame(width: 240)
            }
            .frame(maxHeight: .infinity)

        }
        .frame(minWidth: 960, minHeight: 640)
        .background(Color.paper)
        .preferredColorScheme(.light)
        .sheet(item: $notionSendEntry) { entry in
            NotionTagSheet(
                entryTitle: entry.displayName,
                entryDate: entry.startDate,
                isPresented: Binding(
                    get: { notionSendEntry != nil },
                    set: { if !$0 { notionSendEntry = nil } }
                ),
                errorMessage: notionSendError,
                onSend: { tags in
                    sendToNotion(entry: entry, tags: tags)
                }
            )
            .overlay {
                if isNotionSending {
                    ZStack {
                        Color.black.opacity(0.4)
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                }
            }
        }
        .overlay {
            if showOnboarding {
                OnboardingView(
                    isPresented: $showOnboarding,
                    modelStatus: transcriptionEngine?.assetStatus ?? "Waiting...",
                    modelsReady: transcriptionEngine?.modelsReady ?? false,
                    onRetry: {
                        Task { await transcriptionEngine?.prepareModels() }
                    }
                )
                .transition(.opacity)
            }
        }
        .onChange(of: showOnboarding) {
            if !showOnboarding {
                hasCompletedOnboarding = true
            }
        }
        .task {
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
            if transcriptionEngine == nil {
                transcriptionEngine = TranscriptionEngine(transcriptStore: transcriptStore)
            }
            // Pre-download models at launch so recording can start immediately
            await transcriptionEngine?.prepareModels()
            // Scan for sessions left incomplete by a prior crash (STAB-01)
            let incomplete = await sessionStore.scanIncompleteCheckpoints()
            for checkpoint in incomplete {
                let existsInLibrary = await libraryStore.entries.contains {
                    $0.filePath == checkpoint.transcriptPath
                }
                if !existsInLibrary {
                    let recoveredType: SessionType
                    if checkpoint.transcriptPath.hasPrefix(settings.vaultVoicePath) {
                        recoveredType = .voiceMemo
                    } else {
                        recoveredType = .callCapture
                    }
                    let entry = LibraryEntry(
                        id: UUID(),
                        name: nil,
                        sessionType: recoveredType,
                        startDate: checkpoint.sessionStartTime,
                        duration: 0,
                        filePath: checkpoint.transcriptPath,
                        sourceApp: "Recovered",
                        isFinalized: false,
                        firstLinePreview: nil
                    )
                    await libraryStore.addEntry(entry)
                }
            }
            refreshLibrary()
        }
        // Audio level polling (meter only — silence tracking uses VAD below)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let engine = transcriptionEngine else {
                    if audioLevel != 0 { audioLevel = 0 }
                    continue
                }
                if engine.isRunning {
                    let newLevel = engine.audioLevel
                    if abs(newLevel - audioLevel) > 0.005 { audioLevel = newLevel }
                } else if audioLevel != 0 {
                    audioLevel = 0
                }
            }
        }
        // VAD-based silence auto-stop + elapsed timer
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard isRunning, let engine = transcriptionEngine else {
                    silenceSeconds = 0
                    continue
                }
                sessionElapsed += 1

                // Arm only after VAD has heard speech at least once
                guard engine.hasDetectedSpeech else {
                    silenceSeconds = 0
                    continue
                }

                if engine.isSpeaking {
                    silenceSeconds = 0
                } else {
                    silenceSeconds += 1
                    if silenceSeconds >= autoStopThreshold {
                        stopSession()
                    }
                }
            }
        }
        // Transcript buffer flush
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                await transcriptLogger.flushIfNeeded()
            }
        }
        .onChange(of: sessionName) { _, newName in
            guard activeSessionType != nil else { return }
            nameDebounceTask?.cancel()
            nameDebounceTask = Task {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                do {
                    try await transcriptLogger.setName(newName)
                    // Update library entry file path after rename
                    if let entryID = activeLibraryEntryID,
                       let newPath = await transcriptLogger.currentFilePathURL {
                        await libraryStore.updateEntry(id: entryID) { @Sendable entry in
                            entry.filePath = newPath.path
                            entry.name = newName.isEmpty ? nil : newName
                        }
                        refreshLibrary()
                    }
                } catch {
                    transcriptionEngine?.lastError = "Failed to rename: \(error.localizedDescription)"
                }
            }
        }
        .onChange(of: settings.inputDeviceID) {
            if isRunning {
                transcriptionEngine?.restartMic(inputDeviceID: settings.inputDeviceID)
            }
        }
        .onChange(of: transcriptStore.utterances.count) {
            handleNewUtterance()
        }
        .onChange(of: selectedEntryID) { _, newID in
            // Selection changed — bail out of any in-progress rename draft.
            if isEditingTranscriptName { cancelRename() }
            guard let newID,
                  let entry = libraryEntries.first(where: { $0.id == newID }),
                  activeSessionType == nil else {
                loadedUtterances = []
                return
            }
            // Skip loading if filePath is empty (entry still being recorded)
            guard !entry.filePath.isEmpty else {
                loadedUtterances = []
                return
            }
            let url = URL(fileURLWithPath: entry.filePath)
            guard FileManager.default.fileExists(atPath: entry.filePath) else {
                loadedUtterances = []
                return
            }
            do {
                loadedUtterances = try parseTranscript(at: url)
            } catch {
                loadedUtterances = []
                transcriptionEngine?.lastError = "Couldn't load transcript. The file may be corrupted."
            }
        }
    }

    // MARK: - Transcript Header

    @ViewBuilder
    private var transcriptHeader: some View {
        if isRunning || activeSessionType != nil {
            let name = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
            let displayName = name.isEmpty ? "New recording" : name
            VStack(alignment: .leading, spacing: 2) {
                editableTranscriptName(displayName: displayName) { newName in
                    sessionName = newName
                }
                Text(liveMetaLine)
                    .font(.chronicleMono(11))
                    .foregroundStyle(Color.inkFaint)
            }
        } else if let selectedID = selectedEntryID,
                  let entry = libraryEntries.first(where: { $0.id == selectedID }) {
            VStack(alignment: .leading, spacing: 2) {
                editableTranscriptName(displayName: entry.displayName) { newName in
                    renameEntry(id: entry.id, newName: newName)
                }
                Text(pastMetaLine(entry))
                    .font(.chronicleMono(11))
                    .foregroundStyle(Color.inkFaint)
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func editableTranscriptName(displayName: String, commit: @escaping (String) -> Void) -> some View {
        if isEditingTranscriptName {
            TextField("Recording name", text: $transcriptNameDraft)
                .font(.chronicleSans(15, weight: .semibold))
                .foregroundStyle(Color.ink)
                .textFieldStyle(.plain)
                .focused($transcriptNameFieldFocused)
                .onAppear {
                    transcriptNameFieldFocused = true
                    // One-shot select-all as soon as the field gets focus.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                        NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
                    }
                }
                .onSubmit { submitRename(commit: commit) }
                .onExitCommand { cancelRename() }
                .onChange(of: transcriptNameFieldFocused) { _, focused in
                    // Clicking outside the field commits the current draft.
                    if !focused && isEditingTranscriptName {
                        submitRename(commit: commit)
                    }
                }
        } else {
            Text(displayName)
                .font(.chronicleSans(15, weight: .semibold))
                .foregroundStyle(Color.ink)
                .lineLimit(1)
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    beginRename(with: displayName)
                }
                .contextMenu {
                    Button("Rename…") { beginRename(with: displayName) }
                }
        }
    }

    private func beginRename(with current: String) {
        transcriptNameDraft = current == "New recording" ? "" : current
        isEditingTranscriptName = true
    }

    private func cancelRename() {
        isEditingTranscriptName = false
        transcriptNameDraft = ""
        transcriptNameFieldFocused = false
    }

    private func submitRename(commit: (String) -> Void) {
        let trimmed = transcriptNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        // Exit edit mode first so the focus-change handler doesn't re-enter.
        isEditingTranscriptName = false
        transcriptNameFieldFocused = false
        let draft = trimmed
        transcriptNameDraft = ""
        guard !draft.isEmpty else { return }
        commit(draft)
    }

    /// Renames a library entry — mirrors the sidebar rename flow (file + library).
    private func renameEntry(id: UUID, newName: String) {
        Task {
            guard let entry = await libraryStore.entries.first(where: { $0.id == id }) else { return }
            guard !entry.filePath.isEmpty else {
                await libraryStore.updateEntry(id: id) { @Sendable e in e.name = newName }
                refreshLibrary()
                return
            }
            do {
                let newPath = try await transcriptLogger.renameFinalized(
                    at: URL(fileURLWithPath: entry.filePath),
                    to: newName
                )
                await libraryStore.updateEntry(id: id) { @Sendable e in
                    e.name = newName
                    e.filePath = newPath.path
                }
            } catch {
                await libraryStore.updateEntry(id: id) { @Sendable e in e.name = newName }
                transcriptionEngine?.lastError = "Rename failed: \(error.localizedDescription)"
            }
            refreshLibrary()
        }
    }

    private var liveMetaLine: String {
        let elapsed = Self.formatDurationShort(TimeInterval(sessionElapsed))
        let count = distinctSpeakerCount(in: transcriptStore.utterances)
        let speakersStr = "\(count) \(count == 1 ? "speaker" : "speakers")"
        return "Recording · \(elapsed) · \(speakersStr)"
    }

    private func pastMetaLine(_ entry: LibraryEntry) -> String {
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "MMM d, yyyy"
        let dateStr = dateFmt.string(from: entry.startDate)
        let durationStr = Self.formatDurationShort(entry.duration)
        let count = distinctSpeakerCount(in: loadedUtterances)
        let speakersStr = "\(count) \(count == 1 ? "speaker" : "speakers")"
        return "\(dateStr) · \(durationStr) · \(speakersStr)"
    }

    private func distinctSpeakerCount(in utterances: [Utterance]) -> Int {
        var seen = Set<String>()
        for u in utterances {
            switch u.speaker {
            case .you:              seen.insert("you")
            case .them:             seen.insert("them")
            case .named(let label): seen.insert("named:\(label)")
            }
        }
        return max(seen.count, 1) // show at least "1 speaker" during empty live state
    }

    private static func formatDurationShort(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return m > 0 ? "\(h)h \(m)m" : "\(h)h" }
        if m > 0 { return s > 0 ? "\(m)m \(s)s" : "\(m)m" }
        return "\(s)s"
    }

    // MARK: - Detail View

    @ViewBuilder
    private var detailView: some View {
        if activeSessionType != nil || isRunning {
            // Live recording view
            TranscriptView(
                utterances: transcriptStore.utterances,
                volatileYouText: transcriptStore.volatileYouText,
                volatileThemText: transcriptStore.volatileThemText
            )
        } else if let selectedID = selectedEntryID,
                  let entry = libraryEntries.first(where: { $0.id == selectedID }) {
            // Past transcript loaded (per D-10)
            TranscriptView(
                utterances: loadedUtterances,
                volatileYouText: "",
                volatileThemText: "",
                onRemoveUtterance: { utteranceID in
                    removeUtterance(utteranceID, from: entry)
                }
            )
        } else {
            // Empty detail state
            VStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.fg3)
                Text("Select a recording")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fg2)
                Text("Choose a session from the sidebar")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fg3)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Notion

    /// Fire-and-forget auto-send on session finalization. Empty tags by design;
    /// users add tags later via the manual "Resend to Notion" flow, which updates
    /// the existing page in place.
    private func autoSendToNotion(entry: LibraryEntry) async {
        let logger = Logger(subsystem: "com.pstranscribe.app", category: "NotionAutoSend")
        do {
            let markdown = try String(contentsOfFile: entry.filePath, encoding: .utf8)
            let speakers = notionService.extractSpeakers(markdown)
            logger.info("Auto-sending to Notion: \(entry.displayName)")
            let pageURL = try await notionService.sendTranscript(
                databaseID: settings.notionDatabaseID,
                title: entry.displayName,
                date: entry.startDate,
                duration: entry.duration,
                sourceApp: entry.sourceApp,
                sessionType: entry.sessionType == .callCapture ? "Call Capture" : "Voice Memo",
                speakers: speakers,
                tags: [],
                transcriptMarkdown: markdown
            )
            await libraryStore.updateEntry(id: entry.id) { @Sendable e in
                e.notionPageURL = pageURL.absoluteString
            }
            refreshLibrary()
        } catch {
            logger.error("Auto-send to Notion failed: \(error.localizedDescription)")
            notionSendError = "Auto-send to Notion failed: \(error.localizedDescription)"
        }
    }

    private func sendToNotion(entry: LibraryEntry, tags: [String]) {
        isNotionSending = true
        notionSendError = nil
        let logger = Logger(subsystem: "com.pstranscribe.app", category: "NotionSend")
        Task {
            do {
                logger.info("Sending to Notion: \(entry.displayName) at \(entry.filePath)")
                let markdown = try String(contentsOfFile: entry.filePath, encoding: .utf8)
                let speakers = notionService.extractSpeakers(markdown)

                if let existingURL = entry.notionPageURL {
                    // Resend: update existing page in place
                    logger.info("Resend: updating existing page")
                    try await notionService.updateTranscript(
                        pageURLString: existingURL,
                        databaseID: settings.notionDatabaseID,
                        title: entry.displayName,
                        date: entry.startDate,
                        duration: entry.duration,
                        sourceApp: entry.sourceApp,
                        sessionType: entry.sessionType == .callCapture ? "Call Capture" : "Voice Memo",
                        speakers: speakers,
                        tags: tags,
                        transcriptMarkdown: markdown
                    )
                } else {
                    // First send: create new page
                    let pageURL = try await notionService.sendTranscript(
                        databaseID: settings.notionDatabaseID,
                        title: entry.displayName,
                        date: entry.startDate,
                        duration: entry.duration,
                        sourceApp: entry.sourceApp,
                        sessionType: entry.sessionType == .callCapture ? "Call Capture" : "Voice Memo",
                        speakers: speakers,
                        tags: tags,
                        transcriptMarkdown: markdown
                    )
                    await libraryStore.updateEntry(id: entry.id) { @Sendable e in
                        e.notionPageURL = pageURL.absoluteString
                    }
                }
                refreshLibrary()
                notionSendEntry = nil
                isNotionSending = false
            } catch {
                logger.error("Notion send failed: \(error)")
                notionSendError = error.localizedDescription
                isNotionSending = false
            }
        }
    }

    // MARK: - Utterance Removal

    private func removeUtterance(_ utteranceID: UUID, from entry: LibraryEntry) {
        // Remove from in-memory list
        guard let index = loadedUtterances.firstIndex(where: { $0.id == utteranceID }) else { return }
        let removed = loadedUtterances.remove(at: index)

        // Rewrite the markdown file without the removed utterance's block
        guard !entry.filePath.isEmpty else { return }
        Task {
            do {
                let fileURL = URL(fileURLWithPath: entry.filePath)
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                let lines = content.components(separatedBy: "\n")

                // Find the speaker line matching this utterance's timestamp and text
                let speakerLabel: String
                switch removed.speaker {
                case .you:             speakerLabel = "You"
                case .them:            speakerLabel = "Them"
                case .named(let lbl):  speakerLabel = lbl
                }
                let offset = removed.timestamp.timeIntervalSince(.distantPast)
                let h = Int(offset) / 3600
                let m = (Int(offset) % 3600) / 60
                let s = Int(offset) % 60
                let timeStr = String(format: "%02d:%02d:%02d", h, m, s)
                let headerLine = "**\(speakerLabel)** (\(timeStr))"

                // Find and remove the block: header line + text lines + trailing blank line
                var newLines: [String] = []
                var skip = false
                for line in lines {
                    if line.trimmingCharacters(in: .whitespaces) == headerLine {
                        skip = true
                        continue
                    }
                    if skip {
                        // Skip text lines until we hit a blank line or next speaker header
                        if line.trimmingCharacters(in: .whitespaces).isEmpty {
                            skip = false
                            continue  // skip the blank separator too
                        }
                        if line.hasPrefix("**") {
                            // Next speaker block -- stop skipping
                            skip = false
                            newLines.append(line)
                        }
                        // else skip this text line
                        continue
                    }
                    newLines.append(line)
                }

                let newContent = newLines.joined(separator: "\n")
                try newContent.write(to: fileURL, atomically: true, encoding: .utf8)

                // Update Notion page if it was sent
                if let notionURL = entry.notionPageURL {
                    let speakers = notionService.extractSpeakers(newContent)
                    try? await notionService.updateTranscript(
                        pageURLString: notionURL,
                        databaseID: settings.notionDatabaseID,
                        title: entry.displayName,
                        date: entry.startDate,
                        duration: entry.duration,
                        sourceApp: entry.sourceApp,
                        sessionType: entry.sessionType == .callCapture ? "Call Capture" : "Voice Memo",
                        speakers: speakers,
                        tags: [],
                        transcriptMarkdown: newContent
                    )
                }
            } catch {
                transcriptionEngine?.lastError = "Failed to remove utterance: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Helpers

    private var isRunning: Bool {
        transcriptionEngine?.isRunning ?? false
    }

    private func refreshLibrary() {
        Task {
            libraryEntries = await libraryStore.entries
        }
    }

    private func formatTime(_ s: Int) -> String {
        "\(s / 60):\(String(format: "%02d", s % 60))"
    }

    // MARK: - Actions

    private func startSession(type: SessionType) {
        transcriptStore.clear()
        settings.lastUsedSessionType = type
        silenceSeconds = 0
        sessionElapsed = 0
        sessionName = ""
        savedConfirmation = false

        // Determine output folder and app bundle ID based on session type
        let outputPath: String
        let sourceApp: String
        var appBundleID: String?
        var resolvedAppName: String?

        switch type {
        case .callCapture:
            outputPath = settings.vaultMeetingsPath
            if let frontApp = NSWorkspace.shared.frontmostApplication,
               let bundleID = frontApp.bundleIdentifier,
               let appName = conferencingBundleIDs[bundleID] {
                sourceApp = appName
                appBundleID = bundleID
                resolvedAppName = appName
            } else {
                sourceApp = "Call"
            }
        case .voiceMemo:
            outputPath = settings.vaultVoicePath
            sourceApp = "Voice Memo"
        }

        // Guard: without a configured Obsidian folder for this session type,
        // we have nowhere to save. Surface an error and abort.
        guard !outputPath.isEmpty else {
            let label = type == .callCapture ? "Meetings" : "Voice memos"
            transcriptionEngine?.lastError =
                "Obsidian \(label) folder isn't set — configure it in Settings → Obsidian before recording."
            return
        }

        let startDate = Date()

        Task {
            transcriptionEngine?.lastError = nil
            do {
                try await sessionStore.startSession()
            } catch {
                transcriptionEngine?.lastError = error.localizedDescription
                return
            }
            let sessionId = await sessionStore.activeSessionId
            do {
                try await transcriptLogger.startSession(
                    sourceApp: sourceApp,
                    vaultPath: outputPath,
                    sessionType: type,
                    sessionStore: sessionStore,
                    sessionId: sessionId
                )
            } catch {
                await sessionStore.endSession()
                transcriptionEngine?.lastError = error.localizedDescription
                return
            }

            // Add library entry for this session (filePath updated at session stop)
            let entry = LibraryEntry(
                id: UUID(),
                name: nil,
                sessionType: type,
                startDate: startDate,
                duration: 0,
                filePath: "",
                sourceApp: sourceApp,
                isFinalized: false,
                firstLinePreview: nil
            )
            await libraryStore.addEntry(entry)
            let newEntryID = entry.id

            activeLibraryEntryID = newEntryID
            activeSessionType = type
            detectedAppName = resolvedAppName
            detectedAppBundleID = appBundleID

            refreshLibrary()
            selectedEntryID = newEntryID

            if type == .callCapture {
                await transcriptionEngine?.start(
                    locale: settings.locale,
                    inputDeviceID: settings.inputDeviceID,
                    appBundleID: appBundleID
                )
            } else {
                await transcriptionEngine?.start(
                    locale: settings.locale,
                    inputDeviceID: settings.inputDeviceID
                )
            }
        }
    }

    private func stopSession() {
        let wasCallCapture = activeSessionType == .callCapture
        let stoppedEntryID = activeLibraryEntryID

        // Cancel any pending debounce and apply name before ending session
        nameDebounceTask?.cancel()
        nameDebounceTask = nil
        let finalName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)

        activeSessionType = nil
        detectedAppName = nil
        detectedAppBundleID = nil
        silenceSeconds = 0
        activeLibraryEntryID = nil

        Task {
            // Apply the session name to the file on disk before closing
            if !finalName.isEmpty {
                try? await transcriptLogger.setName(finalName)
            }

            await transcriptionEngine?.stop()
            await sessionStore.endSession()
            await transcriptLogger.endSession()

            if wasCallCapture {
                transcriptionEngine?.assetStatus = "Identifying speakers..."
                if let segments = await transcriptionEngine?.runPostSessionDiarization() {
                    transcriptionEngine?.assetStatus = "Rewriting transcript..."
                    do {
                        try await transcriptLogger.rewriteWithDiarization(segments: segments)
                    } catch {
                        transcriptionEngine?.lastError = error.localizedDescription
                    }
                }
            }

            transcriptionEngine?.assetStatus = "Finalizing..."
            let savedPath = await transcriptLogger.finalizeFrontmatter()

            transcriptionEngine?.assetStatus = "Ready"

            // Update library entry with final duration and finalized state
            let finalDuration = TimeInterval(sessionElapsed)
            let finalPath = savedPath?.path ?? ""
            let firstLine = transcriptStore.utterances.first?.text
            transcriptStore.clear()  // D-09: clear stale utterances after session ends

            if let entryID = stoppedEntryID {
                let capturedDuration = finalDuration
                let capturedPath = finalPath
                let capturedFirstLine = firstLine
                let capturedName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
                await libraryStore.updateEntry(id: entryID) { @Sendable entry in
                    entry.duration = capturedDuration
                    if !capturedPath.isEmpty {
                        entry.filePath = capturedPath
                    }
                    entry.isFinalized = true
                    entry.firstLinePreview = capturedFirstLine
                    if !capturedName.isEmpty {
                        entry.name = capturedName
                    }
                }
                refreshLibrary()
                selectedEntryID = entryID

                // Load transcript now that filePath is populated
                if !capturedPath.isEmpty,
                   FileManager.default.fileExists(atPath: capturedPath) {
                    let finalURL = URL(fileURLWithPath: capturedPath)
                    do {
                        loadedUtterances = try parseTranscript(at: finalURL)
                    } catch {
                        loadedUtterances = []
                    }
                }

                // Auto-send to Notion with empty tags, if enabled + configured + not already sent.
                // User can still use "Resend to Notion" to add tags afterward (updates in place).
                if settings.notionAutoSendEnabled,
                   isNotionConfigured,
                   !capturedPath.isEmpty,
                   let entry = await libraryStore.entries.first(where: { $0.id == entryID }),
                   entry.notionPageURL == nil {
                    await autoSendToNotion(entry: entry)
                }
            }

            // Show inline save confirmation
            savedConfirmation = true
            try? await Task.sleep(for: .milliseconds(2500))
            withAnimation(.easeOut(duration: 0.5)) {
                savedConfirmation = false
            }
        }
    }

    private func handleNewUtterance() {
        guard let last = transcriptStore.utterances.last else { return }

        silenceSeconds = 0

        let speakerName: String
        switch last.speaker {
        case .you:              speakerName = "You"
        case .them:             speakerName = "Them"
        case .named(let label): speakerName = label
        }
        Task {
            await transcriptLogger.append(
                speaker: speakerName,
                text: last.text,
                timestamp: last.timestamp
            )
        }

        Task {
            await sessionStore.appendRecord(SessionRecord(
                speaker: last.speaker,
                text: last.text,
                timestamp: last.timestamp
            ))
        }
    }
}
