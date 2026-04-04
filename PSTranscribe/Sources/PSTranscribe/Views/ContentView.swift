import SwiftUI
import AppKit
import Combine

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
    @State private var transcriptStore = TranscriptStore()
    @State private var transcriptionEngine: TranscriptionEngine?
    @State private var sessionStore = SessionStore()
    @State private var transcriptLogger = TranscriptLogger()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    @State private var audioLevel: Float = 0
    @State private var activeSessionType: SessionType?
    @State private var detectedAppName: String?
    @State private var silenceSeconds: Int = 0
    @State private var sessionElapsed: Int = 0

    // Library state
    @State private var libraryStore = LibraryStore()
    @State private var libraryEntries: [LibraryEntry] = []
    @State private var selectedEntryID: UUID?
    @State private var activeLibraryEntryID: UUID?
    @State private var sessionName: String = ""
    @State private var loadedUtterances: [Utterance] = []
    @State private var savedConfirmation: Bool = false
    @State private var nameDebounceTask: Task<Void, Never>?
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .automatic
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 0) {
            // Top bar spans full width
            RecordingNameField(
                sessionName: $sessionName,
                isSessionActive: activeSessionType != nil,
                sessionElapsed: sessionElapsed,
                isRecording: isRunning,
                savedConfirmation: savedConfirmation,
                onToggleSidebar: {
                    withAnimation {
                        sidebarVisibility = sidebarVisibility == .detailOnly ? .automatic : .detailOnly
                    }
                },
                onOpenSettings: {
                    openSettings()
                }
            )

            // NavigationSplitView for sidebar + detail
            NavigationSplitView(columnVisibility: $sidebarVisibility) {
                LibrarySidebar(
                    entries: libraryEntries,
                    selectedID: $selectedEntryID,
                    activeEntryID: activeLibraryEntryID,
                    obsidianVaultName: settings.obsidianVaultName,
                    vaultRootPath: currentVaultRootPath,
                    onRename: { id, newName in
                        let capturedID = id
                        let capturedName = newName
                        Task {
                            guard let entry = await libraryStore.entries.first(where: { $0.id == capturedID }) else { return }
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
                                // File may not exist or name is invalid -- update name only
                                await libraryStore.updateEntry(id: capturedID) { @Sendable e in
                                    e.name = capturedName
                                }
                                transcriptionEngine?.lastError = "Rename failed: \(error.localizedDescription)"
                            }
                            refreshLibrary()
                        }
                    }
                )
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
                .ignoresSafeArea(.all, edges: .top)
            } detail: {
                detailView
            }
            .navigationSplitViewStyle(.balanced)
            .toolbar(removing: .sidebarToggle)
            .onAppear { hideSidebarToggleButton() }

            // ControlBar spans full width
            ControlBar(
                isRecording: isRunning,
                activeSessionType: activeSessionType,
                audioLevel: audioLevel,
                detectedApp: detectedAppName,
                silenceSeconds: silenceSeconds,
                statusMessage: transcriptionEngine?.assetStatus,
                errorMessage: transcriptionEngine?.lastError,
                modelsReady: transcriptionEngine?.modelsReady ?? false,
                hasError: transcriptionEngine?.hasError ?? false,
                activeErrors: transcriptionEngine?.activeErrors ?? [],
                onStartCallCapture: { startSession(type: .callCapture) },
                onStartVoiceMemo: { startSession(type: .voiceMemo) },
                onStop: stopSession,
                onOpenSettings: { openSettings() }
            )
        }
        .frame(minWidth: 640, minHeight: 400)
        .background(Color.bg0)
        .preferredColorScheme(.dark)
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
                    let entry = LibraryEntry(
                        id: UUID(),
                        name: nil,
                        sessionType: .callCapture,
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
        // Audio level polling
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
                    if audioLevel > 0.01 {
                        silenceSeconds = 0
                    }
                } else if audioLevel != 0 {
                    audioLevel = 0
                }
            }
        }
        // Silence auto-stop + elapsed timer
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard isRunning else {
                    silenceSeconds = 0
                    continue
                }
                sessionElapsed += 1
                if audioLevel < 0.01 {
                    silenceSeconds += 1
                    if silenceSeconds >= 120 {
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

    // MARK: - Detail View

    @ViewBuilder
    private var detailView: some View {
        if activeSessionType != nil || isRunning {
            // Live recording view
            VStack(spacing: 0) {
                TranscriptView(
                    utterances: transcriptStore.utterances,
                    volatileYouText: transcriptStore.volatileYouText,
                    volatileThemText: transcriptStore.volatileThemText
                )
            }
        } else if let selectedID = selectedEntryID,
                  let _ = libraryEntries.first(where: { $0.id == selectedID }) {
            // Past transcript loaded (per D-10)
            VStack(spacing: 0) {
                TranscriptView(
                    utterances: loadedUtterances,
                    volatileYouText: "",
                    volatileThemText: ""
                )
            }
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

    // MARK: - Window Helpers

    /// Remove the built-in sidebar toggle button that macOS places next to the traffic lights.
    private func hideSidebarToggleButton() {
        DispatchQueue.main.async {
            guard let window = NSApp.mainWindow ?? NSApp.windows.first(where: { $0.isVisible }) else { return }
            // NSSplitViewController inserts a toolbar item with identifier "com.apple.SwiftUI.navigationSplitView.toggleSidebar"
            // Removing all toolbar items or setting toolbar to nil eliminates it.
            window.toolbar = nil
        }
    }

    // MARK: - Helpers

    private var isRunning: Bool {
        transcriptionEngine?.isRunning ?? false
    }

    private var currentVaultRootPath: String {
        if let entry = libraryEntries.first(where: { $0.id == selectedEntryID }) {
            return entry.sessionType == .callCapture
                ? settings.vaultMeetingsPath : settings.vaultVoicePath
        }
        return settings.vaultMeetingsPath
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
                    do {
                        loadedUtterances = try parseTranscript(at: URL(fileURLWithPath: capturedPath))
                    } catch {
                        loadedUtterances = []
                    }
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

        let speakerName = last.speaker == .you ? "You" : "Them"
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
