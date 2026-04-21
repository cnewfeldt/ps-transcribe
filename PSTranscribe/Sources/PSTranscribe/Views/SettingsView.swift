import SwiftUI
import CoreAudio
import Sparkle

private enum NotionConfigStatus {
    case notConfigured
    case connected
    case fullyConfigured
}

struct SettingsView: View {
    @Bindable var settings: AppSettings
    var updater: SPUUpdater
    var notionService: NotionService
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
            Section("Audio Input") {
                Picker("Microphone", selection: $settings.inputDeviceID) {
                    Text("System Default").tag(AudioDeviceID(0))
                    ForEach(inputDevices, id: \.id) { device in
                        Text(device.name).tag(device.id)
                    }
                }
                .font(.system(size: 12))
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
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 640)
        .onAppear {
            inputDevices = MicCapture.availableInputDevices()
            notionDatabaseInput = settings.notionDatabaseID
            autoValidateNotionIfNeeded()
        }
    }

    // MARK: - Obsidian section content

    /// Detected Obsidian vault for either configured folder path, if any.
    private var detectedObsidianVault: (root: String, name: String)? {
        if !settings.vaultMeetingsPath.isEmpty,
           let v = obsidianVaultForPath(settings.vaultMeetingsPath) { return v }
        if !settings.vaultVoicePath.isEmpty,
           let v = obsidianVaultForPath(settings.vaultVoicePath) { return v }
        return nil
    }

    private var hasAnyObsidianFolder: Bool {
        !settings.vaultMeetingsPath.isEmpty || !settings.vaultVoicePath.isEmpty
    }

    @ViewBuilder
    private var obsidianSectionContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Status line — mirrors the Notion "Connected to ..." row
            HStack(spacing: 6) {
                Circle()
                    .fill(hasAnyObsidianFolder ? (detectedObsidianVault != nil ? .green : .orange) : .gray)
                    .frame(width: 8, height: 8)
                Text(obsidianStatusText)
                    .font(.system(size: 12))
                Spacer()
            }

            if !hasAnyObsidianFolder {
                Text("Transcripts won't be saved until a folder is configured below.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Divider().padding(.vertical, 2)

            obsidianFolderRow(
                label: "Meetings folder",
                path: settings.vaultMeetingsPath,
                onChoose: { path in settings.vaultMeetingsPath = path },
                onClear:  { settings.vaultMeetingsPath = "" },
                chooseMessage: "Choose the folder for meeting transcripts"
            )

            obsidianFolderRow(
                label: "Voice memos folder",
                path: settings.vaultVoicePath,
                onChoose: { path in settings.vaultVoicePath = path },
                onClear:  { settings.vaultVoicePath = "" },
                chooseMessage: "Choose the folder for voice memo transcripts"
            )
        }
    }

    private var obsidianStatusText: String {
        if let vault = detectedObsidianVault {
            return "Connected to vault: \(vault.name)"
        }
        if hasAnyObsidianFolder {
            return "Folder set, but not inside an Obsidian vault"
        }
        return "Not configured"
    }

    @ViewBuilder
    private func obsidianFolderRow(
        label: String,
        path: String,
        onChoose: @escaping (String) -> Void,
        onClear: @escaping () -> Void,
        chooseMessage: String
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                Text(path.isEmpty ? "No folder selected" : path)
                    .font(.system(size: 11))
                    .foregroundStyle(path.isEmpty ? .tertiary : .secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            if !path.isEmpty {
                Button("Remove") {
                    onClear()
                }
                .font(.system(size: 11))
                .foregroundStyle(.red)
            }

            Button(path.isEmpty ? "Choose..." : "Change...") {
                chooseFolder(message: chooseMessage, onSelect: onChoose)
            }
        }
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

    // MARK: - Folder picker

    private func chooseFolder(message: String, onSelect: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = message

        if panel.runModal() == .OK, let url = panel.url {
            onSelect(url.path)
        }
    }
}
