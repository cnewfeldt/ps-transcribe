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

    var body: some View {
        VStack(spacing: 0) {
            RecordingNameField(
                sessionName: $sessionName,
                isSessionActive: activeSessionType != nil,
                sessionElapsed: sessionElapsed,
                isRecording: isRunning,
                savedConfirmation: savedConfirmation,
                onToggleSidebar: {
                    withAnimation(.spring(duration: 0.3, bounce: 0.1)) {
                        isSidebarVisible.toggle()
                    }
                },
                onOpenSettings: {
                    openSettings()
                }
            )

            HStack(spacing: 0) {
                if isSidebarVisible {
                    LibrarySidebar(
                        entries: libraryEntries,
                        selectedID: $selectedEntryID,
                        activeEntryID: activeLibraryEntryID,
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
                        }
                    )
                    .frame(width: 220)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }

                detailView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)

            ControlBar(
                isRecording: isRunning,
                activeSessionType: activeSessionType,
                audioLevel: audioLevel,
                detectedApp: detectedAppName,
                detectedAppBundleID: detectedAppBundleID,
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
                let speakerLabel = removed.speaker == .you ? "You" : "Them"
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
