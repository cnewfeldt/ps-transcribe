import SwiftUI

struct RecordingNameField: View {
    @Binding var sessionName: String
    let isSessionActive: Bool
    let sessionElapsed: Int
    let isRecording: Bool
    let savedConfirmation: Bool
    var onToggleSidebar: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Left side: sidebar toggle + brand label or name field
            HStack(spacing: 8) {
                Button {
                    onToggleSidebar?()
                } label: {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.inkFaint)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .help("Toggle sidebar")

                if isSessionActive {
                    TextField("Name this recording", text: $sessionName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.ink)
                        .textFieldStyle(.plain)
                        .focused($isNameFieldFocused)
                        .onAppear { isNameFieldFocused = true }
                } else {
                    Text("PS TRANSCRIBE")
                        .font(.system(size: 14, weight: .heavy))
                        .tracking(3)
                        .foregroundStyle(Color.ink)
                }
            }

            Spacer()

            // Right side: status indicator + settings gear
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    if isRecording {
                        Text(formatTime(sessionElapsed))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.ink)
                        PulsingDot(size: 6)
                    } else if savedConfirmation {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.accentInk)
                        Text("Saved")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.accentInk)
                    } else if isSessionActive {
                        Text("\(formatTime(sessionElapsed)) Done")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.inkFaint)
                    } else {
                        Text("Ready")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.inkFaint)
                        Circle()
                            .fill(Color.inkFaint)
                            .frame(width: 6, height: 6)
                            .opacity(0.5)
                    }
                }

                Button {
                    onOpenSettings?()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.inkFaint)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .help("Settings (\u{2318},)")
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color.paper)
        .overlay(
            Rectangle()
                .fill(Color.rule)
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    // MARK: - Helpers

    private func formatTime(_ s: Int) -> String {
        "\(s / 60):\(String(format: "%02d", s % 60))"
    }
}
