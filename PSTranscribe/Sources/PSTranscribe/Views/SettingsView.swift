import SwiftUI
import CoreAudio
import Sparkle
import KeyboardShortcuts

private enum NotionConfigStatus {
    case notConfigured
    case connected
    case fullyConfigured
}

struct SettingsView: View {
    @Bindable var settings: AppSettings
    var updater: SPUUpdater
    var notionService: NotionService
    @Bindable var modelUpdateService: ModelUpdateService    // Phase 17, D-18
    @State private var inputDevices: [(id: AudioDeviceID, name: String)] = []

    // MARK: - Notion state
    @State private var notionAPIKeyInput: String = ""
    @State private var notionDatabaseInput: String = ""
    @State private var notionWorkspaceName: String? = nil
    @State private var notionDatabaseName: String? = nil
    @State private var notionStatus: NotionConfigStatus = .notConfigured
    @State private var notionError: String? = nil
    @State private var isValidatingNotion: Bool = false

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Appearance", selection: $settings.appearancePreference) {
                    Text("System").tag(AppearancePreference.system)
                    Text("Light").tag(AppearancePreference.light)
                    Text("Dark").tag(AppearancePreference.dark)
                }
                .font(.system(size: 12))
            }

            Section("Audio Input") {
                Picker("Microphone", selection: $settings.inputDeviceID) {
                    Text("System Default").tag(AudioDeviceID(0))
                    ForEach(inputDevices, id: \.id) { device in
                        Text(device.name).tag(device.id)
                    }
                }
                .font(.system(size: 12))
            }

            Section("Local File") {
                localFileSectionContent
            }

            Section("Obsidian") {
                obsidianSectionContent
            }

            Section("Notion") {
                notionSectionContent
            }

            Section("Privacy") {
                Toggle("Hide from screen sharing", isOn: $settings.hideFromScreenShare)
                    .font(.system(size: 12))
                Text("When enabled, the app is invisible during screen sharing and recording.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Section("Updates") {
                Toggle("Automatically check for updates", isOn: Binding(
                    get: { updater.automaticallyChecksForUpdates },
                    set: { updater.automaticallyChecksForUpdates = $0 }
                ))
                .font(.system(size: 12))
            }

            Section("Speech Model") {
                speechModelSectionContent
            }

            Section("Dictation") {
                dictationSectionContent
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 720)
        .onAppear {
            inputDevices = MicCapture.availableInputDevices()
            notionDatabaseInput = settings.notionDatabaseID
            autoValidateNotionIfNeeded()
            // Phase 17, D-10: opportunistic check on Settings open if >24h since last check.
            // checkForUpdate respects modelAutoUpdateEnabled and the throttle internally.
            Task { await modelUpdateService.checkForUpdate(force: false) }
        }
    }

    // MARK: - Local File section content (D-04 / D-06)

    @ViewBuilder
    private var localFileSectionContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Save to Local File", isOn: $settings.localFileEnabled)
                .font(.system(size: 12))

            Text("Saves Meetings, Memos, and Dictations to subfolders inside the chosen root folder on this Mac.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Divider().padding(.vertical, 2)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Root folder")
                        .font(.system(size: 12, weight: .medium))
                    Text(settings.localFileRoot.isEmpty ? "No folder selected" : settings.localFileRoot)
                        .font(.system(size: 11))
                        .foregroundStyle(settings.localFileRoot.isEmpty ? .tertiary : .secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
                Button(settings.localFileRoot.isEmpty ? "Choose..." : "Change...") {
                    chooseFolder(message: "Choose the Local File root folder") { path in
                        settings.localFileRoot = path
                    }
                }
                .font(.system(size: 12))
            }
            .disabled(!settings.localFileEnabled)
            .opacity(settings.localFileEnabled ? 1.0 : 0.5)
        }
    }

    // MARK: - Obsidian section content (D-07 / D-09 / D-10)

    /// Vault detection for the single Obsidian folder. Replaces the v1.0 two-path shape.
    private var detectedObsidianVault: (root: String, name: String)? {
        guard !settings.obsidianFolderPath.isEmpty else { return nil }
        return obsidianVaultForPath(settings.obsidianFolderPath)
    }

    private var hasObsidianFolder: Bool {
        !settings.obsidianFolderPath.isEmpty
    }

    @ViewBuilder
    private var obsidianSectionContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Save to Obsidian", isOn: $settings.obsidianEnabled)
                .font(.system(size: 12))

            HStack(spacing: 6) {
                Circle()
                    .fill(hasObsidianFolder ? (detectedObsidianVault != nil ? .green : .orange) : .gray)
                    .frame(width: 8, height: 8)
                Text(obsidianStatusText)
                    .font(.system(size: 12))
                Spacer()
            }

            if !hasObsidianFolder {
                Text("Transcripts won't be saved to Obsidian until a folder is configured below.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Divider().padding(.vertical, 2)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Folder")
                        .font(.system(size: 12, weight: .medium))
                    Text(settings.obsidianFolderPath.isEmpty ? "No folder selected" : settings.obsidianFolderPath)
                        .font(.system(size: 11))
                        .foregroundStyle(settings.obsidianFolderPath.isEmpty ? .tertiary : .secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
                if !settings.obsidianFolderPath.isEmpty {
                    Button("Remove") {
                        settings.obsidianFolderPath = ""
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                }
                Button(settings.obsidianFolderPath.isEmpty ? "Choose..." : "Change...") {
                    chooseFolder(message: "Choose the Obsidian folder for transcripts") { path in
                        settings.obsidianFolderPath = path
                    }
                }
                .font(.system(size: 12))
            }
            .disabled(!settings.obsidianEnabled)
            .opacity(settings.obsidianEnabled ? 1.0 : 0.5)
        }
    }

    private var obsidianStatusText: String {
        if let vault = detectedObsidianVault {
            return "Connected to vault: \(vault.name)"
        }
        if hasObsidianFolder {
            return "Folder set, but not inside an Obsidian vault"
        }
        return "Not configured"
    }

    // MARK: - Notion section content

    @ViewBuilder
    private var notionSectionContent: some View {
        if isValidatingNotion {
            // State 2: Validating
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Checking connection...")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        } else if notionStatus == .notConfigured {
            // State 1: Not configured
            VStack(alignment: .leading, spacing: 8) {
                SecureField("Paste your integration token", text: $notionAPIKeyInput)
                    .font(.system(size: 12))
                    .textFieldStyle(.roundedBorder)

                if let error = notionError {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                }

                HStack {
                    Button("Save") {
                        saveAPIKey()
                    }
                    .disabled(notionAPIKeyInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                Text("Create an integration at notion.so/my-integrations")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        } else if notionStatus == .connected {
            // State 3: Connected, no database
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("Connected to \(notionWorkspaceName ?? "your workspace")")
                        .font(.system(size: 12))
                    Spacer()
                    Button("Remove") {
                        removeAPIKey()
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                }

                if let error = notionError {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                }

                TextField("Paste database URL or ID", text: $notionDatabaseInput)
                    .font(.system(size: 12))
                    .textFieldStyle(.roundedBorder)

                Button("Validate Database") {
                    validateDatabase()
                }
                .disabled(notionDatabaseInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        } else {
            // State 4: Fully configured
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("Connected to \(notionWorkspaceName ?? "your workspace")")
                        .font(.system(size: 12))
                    Spacer()
                    Button("Remove") {
                        removeAPIKey()
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Database")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text(notionDatabaseName ?? "Unknown")
                            .font(.system(size: 12))
                    }
                    Spacer()
                    Button("Change") {
                        // Reset to connected state so user can paste a new database
                        notionDatabaseName = nil
                        settings.notionDatabaseID = ""
                        notionDatabaseInput = ""
                        notionError = nil
                        notionStatus = .connected
                    }
                    .font(.system(size: 11))
                }

                Divider().padding(.vertical, 2)

                Toggle(isOn: $settings.notionAutoSendEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-send on recording end")
                            .font(.system(size: 12))
                        Text("Creates a Notion page when a recording stops. Add tags later with \"Resend to Notion.\"")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .toggleStyle(.switch)
            }
        }
    }

    // MARK: - Notion actions

    private func autoValidateNotionIfNeeded() {
        Task {
            let hasKey = await notionService.apiKey() != nil
            guard hasKey else { return }
            await MainActor.run { isValidatingNotion = true }
            do {
                let workspace = try await notionService.testConnection()
                await MainActor.run {
                    notionWorkspaceName = workspace
                    notionError = nil
                }
                // If a database ID is stored, validate it too
                let dbID = settings.notionDatabaseID
                if !dbID.isEmpty {
                    let dbName = try await notionService.validateDatabase(id: dbID)
                    await MainActor.run {
                        notionDatabaseName = dbName
                        notionStatus = .fullyConfigured
                    }
                } else {
                    await MainActor.run { notionStatus = .connected }
                }
            } catch {
                await MainActor.run {
                    notionError = error.localizedDescription
                    notionStatus = .notConfigured
                }
            }
            await MainActor.run { isValidatingNotion = false }
        }
    }

    private func saveAPIKey() {
        let key = notionAPIKeyInput.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return }
        Task {
            do {
                try await notionService.setApiKey(key)
                await MainActor.run {
                    notionAPIKeyInput = ""
                    notionError = nil
                    isValidatingNotion = true
                }
                let workspace = try await notionService.testConnection()
                await MainActor.run {
                    notionWorkspaceName = workspace
                    notionStatus = .connected
                    isValidatingNotion = false
                }
            } catch {
                await MainActor.run {
                    notionError = error.localizedDescription
                    isValidatingNotion = false
                }
            }
        }
    }

    private func validateDatabase() {
        let input = notionDatabaseInput.trimmingCharacters(in: .whitespaces)
        guard !input.isEmpty else { return }
        let parsedID = parseDatabaseID(input)
        Task {
            await MainActor.run { isValidatingNotion = true }
            do {
                let dbName = try await notionService.validateDatabase(id: parsedID)
                await MainActor.run {
                    notionDatabaseName = dbName
                    settings.notionDatabaseID = parsedID
                    notionError = nil
                    notionStatus = .fullyConfigured
                    isValidatingNotion = false
                }
            } catch {
                await MainActor.run {
                    notionError = error.localizedDescription
                    isValidatingNotion = false
                }
            }
        }
    }

    private func removeAPIKey() {
        Task {
            do {
                try await notionService.deleteApiKey()
            } catch {
                // Deletion failure is non-fatal -- reset UI regardless
            }
            await MainActor.run {
                notionWorkspaceName = nil
                notionDatabaseName = nil
                notionDatabaseInput = ""
                settings.notionDatabaseID = ""
                notionError = nil
                notionStatus = .notConfigured
            }
        }
    }

    /// Extracts a 32-character hex Notion database ID from a URL or raw ID string.
    private func parseDatabaseID(_ input: String) -> String {
        // Match UUID with dashes: 8-4-4-4-12
        let uuidPattern = #"[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}"#
        // Match 32 contiguous hex chars
        let hexPattern = #"[a-f0-9]{32}"#

        for pattern in [uuidPattern, hexPattern] {
            if let range = input.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                return String(input[range]).replacingOccurrences(of: "-", with: "")
            }
        }
        // Fallback: return as-is and let the API surface any error
        return input
    }

    // MARK: - Speech Model section content

    @ViewBuilder
    private var speechModelSectionContent: some View {
        VStack(alignment: .leading, spacing: 10) {

            // State-driven content
            switch modelUpdateService.updateState {
            case .idle, .upToDate:
                upToDateRow
            case .updateAvailable(let version, let sizeBytes, _):
                updateAvailableRow(newVersion: version, sizeBytes: sizeBytes)
            case .checking:
                checkingRow
            case .blocked(.minAppVersion(let required, _, let newModelVersion)):
                minAppVersionBlockedRow(required: required, newModelVersion: newModelVersion)
            case .blocked(.insufficientDiskSpace(let needed, let available)):
                insufficientDiskRow(needed: needed, available: available)
            case .downloading(let progress, let completed, let total):
                downloadingRow(progress: progress, completed: completed, total: total)
            case .verifying:
                Text("Verifying download...").font(.system(size: 12))
            case .applying:
                Text("Installing model...").font(.system(size: 12))
            case .applied(let version):
                Text("✓ Updated to v\(version) · active").font(.system(size: 12)).foregroundStyle(.green)
            case .failed(let message):
                failedRow(message: message)
            }

            Divider().padding(.vertical, 2)

            // Manual button (D-12) — always visible regardless of state
            HStack {
                Button("Check for Updates") {
                    Task { await modelUpdateService.checkForUpdate(force: true) }
                }
                .disabled(isWorkingState(modelUpdateService.updateState))
                Spacer()
            }

            // Auto-update toggle (D-11)
            Toggle("Automatically check for new speech models", isOn: $settings.modelAutoUpdateEnabled)
                .font(.system(size: 12))
                .toggleStyle(.switch)
        }
    }

    private func isWorkingState(_ state: ModelUpdateState) -> Bool {
        switch state {
        case .checking, .downloading, .verifying, .applying: return true
        default: return false
        }
    }

    @ViewBuilder
    private var upToDateRow: some View {
        let installed = settings.installedModelVersion.isEmpty ? "—" : settings.installedModelVersion
        let dateSuffix = readableDate(forVersion: installed)
        HStack(spacing: 6) {
            Circle().fill(.green).frame(width: 8, height: 8)
            Text(dateSuffix.isEmpty
                 ? "Speech Model: v\(installed)"
                 : "Speech Model: v\(installed) · \(dateSuffix)")
                .font(.system(size: 12))
        }
    }

    @ViewBuilder
    private var checkingRow: some View {
        HStack(spacing: 8) {
            ProgressView().scaleEffect(0.7)
            Text("Checking...").font(.system(size: 12)).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func updateAvailableRow(newVersion: String, sizeBytes: Int64) -> some View {
        let installed = settings.installedModelVersion.isEmpty ? "—" : settings.installedModelVersion
        let sizeMB = Int(round(Double(sizeBytes) / 1_048_576))
        VStack(alignment: .leading, spacing: 8) {
            Text("Speech Model: v\(installed) → v\(newVersion)").font(.system(size: 12))
            HStack(spacing: 8) {
                Text("Update available · ~\(sizeMB) MB")
                    .font(.system(size: 11))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.warningTint)
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
                Button("Install Update") {
                    Task { await modelUpdateService.downloadAndApply() }
                }
            }
        }
    }

    @ViewBuilder
    private func downloadingRow(progress: Double, completed: Int64, total: Int64) -> some View {
        let completedMB = Int(round(Double(completed) / 1_048_576))
        let totalMB = Int(round(Double(total) / 1_048_576))
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: progress)
            HStack {
                Text("Installing... \(completedMB) / \(totalMB) MB").font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                Button("Cancel") { modelUpdateService.cancelDownload() }
                    .font(.system(size: 11))
            }
        }
    }

    @ViewBuilder
    private func minAppVersionBlockedRow(required: String, newModelVersion: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("New v\(newModelVersion) requires PS Transcribe ≥ \(required).")
                .font(.system(size: 12))
                .foregroundStyle(.orange)
            Button("Check for App Update") {
                updater.checkForUpdates()
            }
        }
    }

    @ViewBuilder
    private func insufficientDiskRow(needed: Int64, available: Int64) -> some View {
        let neededGB = Double(needed) / 1_073_741_824
        let availableMB = Int(round(Double(available) / 1_048_576))
        VStack(alignment: .leading, spacing: 6) {
            Text(String(format: "Update available — needs ~%.1f GB free, %d MB available",
                        neededGB, availableMB))
                .font(.system(size: 12))
                .foregroundStyle(.orange)
            HStack {
                Button("Free up space") {
                    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory,
                                                              in: .userDomainMask)[0]
                    NSWorkspace.shared.open(appSupport)
                }
                Spacer()
                Button("Install Update") { /* disabled */ }.disabled(true)
            }
        }
    }

    @ViewBuilder
    private func failedRow(message: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("⚠️ Update failed: \(message)").font(.system(size: 12)).foregroundStyle(.red)
            Button("Retry") { Task { await modelUpdateService.checkForUpdate(force: true) } }
        }
    }

    /// Best-effort: parse "20260427" as yyyyMMdd → "Apr 27, 2026". Returns "" on failure.
    private func readableDate(forVersion version: String) -> String {
        let inFmt = DateFormatter()
        inFmt.dateFormat = "yyyyMMdd"
        inFmt.timeZone = TimeZone(identifier: "UTC")
        guard let date = inFmt.date(from: version) else { return "" }
        let outFmt = DateFormatter()
        outFmt.dateStyle = .medium
        outFmt.timeZone = TimeZone(identifier: "UTC")
        return outFmt.string(from: date)
    }

    // MARK: - Dictation section content (D-14: behavior-only after 18.1)

    @ViewBuilder
    private var dictationSectionContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Hotkey recorder -- KeyboardShortcuts library handles persistence + clear-via-Delete-key.
            HStack {
                Text("Hotkey")
                    .font(.system(size: 12))
                Spacer()
                KeyboardShortcuts.Recorder(for: .dictateGlobal)
            }

            // Hotkey behavior: toggle (default) vs press-and-hold.
            Picker("Hotkey behavior", selection: $settings.dictationHotkeyMode) {
                Text("Toggle (tap to start, tap to stop)").tag(DictationHotkeyMode.toggle)
                Text("Hold (record while pressed)").tag(DictationHotkeyMode.pressAndHold)
            }
            .font(.system(size: 12))

            Divider().padding(.vertical, 2)

            // Clipboard restore delay -- Stepper in 0.5s increments, 0..30s range.
            HStack {
                Text("Restore previous clipboard after")
                    .font(.system(size: 12))
                Spacer()
                Stepper(value: $settings.clipboardRestoreDelay, in: 0...30, step: 0.5) {
                    Text(String(format: "%.1fs", settings.clipboardRestoreDelay))
                        .font(.system(.body, design: .monospaced))
                }
                .labelsHidden()
            }

            Text("Dictated text is always copied to the clipboard with privacy markers (excluded from Alfred, Maccy, Pasta history). Where the transcript is saved is configured under Local File / Obsidian / Notion above.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Folder picker

    private func chooseFolder(message: String, onSelect: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.title = message              // 18.1 gap-07: high-contrast title bar (UAT #1)
        panel.prompt = "Choose"            // 18.1 gap-07: replaces system default "Open"
        panel.message = message            // accessory description (existing)

        if panel.runModal() == .OK, let url = panel.url {
            onSelect(url.path)
        }
    }
}
