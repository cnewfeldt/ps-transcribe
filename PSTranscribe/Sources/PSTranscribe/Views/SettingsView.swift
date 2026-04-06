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
            Section("Output Folders") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Meetings")
                            .font(.system(size: 12, weight: .medium))
                        Text(settings.vaultMeetingsPath.isEmpty ? "No folder selected" : settings.vaultMeetingsPath)
                            .font(.system(size: 11))
                            .foregroundStyle(settings.vaultMeetingsPath.isEmpty ? .tertiary : .secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer()

                    Button("Choose...") {
                        chooseFolder(message: "Choose the folder for meeting transcripts") { path in
                            settings.vaultMeetingsPath = path
                        }
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Voice Memos")
                            .font(.system(size: 12, weight: .medium))
                        Text(settings.vaultVoicePath.isEmpty ? "No folder selected" : settings.vaultVoicePath)
                            .font(.system(size: 11))
                            .foregroundStyle(settings.vaultVoicePath.isEmpty ? .tertiary : .secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer()

                    Button("Choose...") {
                        chooseFolder(message: "Choose the folder for voice memo transcripts") { path in
                            settings.vaultVoicePath = path
                        }
                    }
                }

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
