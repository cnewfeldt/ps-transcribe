import SwiftUI
import CoreAudio
import Sparkle

struct SettingsView: View {
    @Bindable var settings: AppSettings
    var updater: SPUUpdater
    var ollamaState: OllamaState
    @State private var inputDevices: [(id: AudioDeviceID, name: String)] = []
    @State private var showModelBrowser = false

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

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Obsidian Vault Name")
                            .font(.system(size: 12, weight: .medium))
                        Text("Used to open transcripts in Obsidian")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    TextField("e.g. MyVault", text: $settings.obsidianVaultName)
                        .frame(width: 120)
                        .multilineTextAlignment(.trailing)
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

            Section("Ollama") {
                HStack {
                    if ollamaState.isCheckingConnection {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(connectionColor)
                            .font(.system(size: 9))
                    }
                    Text(connectionLabel)
                        .font(.system(size: 12))
                    Spacer()
                }

                if ollamaState.connectionStatus == .connected && !ollamaState.models.isEmpty {
                    Picker("Model", selection: $settings.selectedOllamaModel) {
                        ForEach(ollamaState.models) { model in
                            Text(model.name).tag(model.name)
                        }
                    }
                    .font(.system(size: 12))
                }

                if ollamaState.connectionStatus == .connected && ollamaState.models.isEmpty {
                    Text("No models found -- run `ollama pull llama3.2:3b` in Terminal")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                if ollamaState.connectionStatus == .connected {
                    Button("Browse Models") {
                        showModelBrowser = true
                    }
                    .font(.system(size: 12))
                }
            }
            .sheet(isPresented: $showModelBrowser) {
                OllamaModelBrowseSheet(
                    ollamaState: ollamaState,
                    selectedModel: $settings.selectedOllamaModel
                )
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
        .frame(width: 450, height: 520)
        .onChange(of: ollamaState.models) { _, newModels in
            guard !newModels.isEmpty else { return }
            if settings.selectedOllamaModel.isEmpty || !newModels.contains(where: { $0.name == settings.selectedOllamaModel }) {
                settings.selectedOllamaModel = newModels.first(where: { $0.name == "llama3.2:3b" })?.name ?? newModels.first?.name ?? ""
            }
        }
        .onAppear {
            inputDevices = MicCapture.availableInputDevices()
            Task { await ollamaState.refresh() }
        }
    }

    private var connectionColor: Color {
        switch ollamaState.connectionStatus {
        case .connected: return .green
        case .notRunning: return Color.recordRed
        case .notFound: return Color.fg3
        }
    }

    private var connectionLabel: String {
        switch ollamaState.connectionStatus {
        case .connected: return "Connected"
        case .notRunning: return "Not running"
        case .notFound: return "Not found"
        }
    }

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
