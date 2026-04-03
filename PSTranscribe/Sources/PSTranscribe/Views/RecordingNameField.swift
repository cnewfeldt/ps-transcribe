import SwiftUI

struct RecordingNameField: View {
    @Binding var sessionName: String
    let isSessionActive: Bool
    let sessionElapsed: Int
    let isRecording: Bool
    let savedConfirmation: Bool
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Left side: brand label or name field
            if isSessionActive {
                TextField("Name this recording", text: $sessionName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.fg1)
                    .textFieldStyle(.plain)
                    .focused($isNameFieldFocused)
                    .onAppear { isNameFieldFocused = true }
            } else {
                Text("PS TRANSCRIBE")
                    .font(.system(size: 14, weight: .heavy))
                    .tracking(3)
                    .foregroundStyle(Color.fg1)
            }

            Spacer()

            // Right side: status indicator
            HStack(spacing: 6) {
                if isRecording {
                    Text(formatTime(sessionElapsed))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.fg1)
                    PulsingDot(size: 6)
                } else if savedConfirmation {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.accent1)
                    Text("Saved")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.accent1)
                } else if isSessionActive {
                    Text("\(formatTime(sessionElapsed)) Done")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.fg2)
                } else {
                    Text("Ready")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.fg2)
                    Circle()
                        .fill(Color.fg2)
                        .frame(width: 6, height: 6)
                        .opacity(0.5)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color.bg1.opacity(0.45))
        .overlay(Divider(), alignment: .bottom)
    }

    // MARK: - Helpers

    private func formatTime(_ s: Int) -> String {
        "\(s / 60):\(String(format: "%02d", s % 60))"
    }
}
