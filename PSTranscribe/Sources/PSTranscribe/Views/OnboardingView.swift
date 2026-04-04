import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    let modelStatus: String
    let modelsReady: Bool
    let onRetry: () -> Void
    @State private var currentStep = 0

    private let totalSteps = 3

    private let infoSteps: [(icon: String, title: String, body: String)] = [
        (
            "waveform.circle",
            "Welcome to PS Transcribe",
            "A lightweight meeting transcription tool that captures your conversations -- all running locally on your Mac. No API keys, no cloud services."
        ),
        (
            "text.quote",
            "Live Transcript",
            "Your conversation is transcribed in real time. \"You\" captures your mic, \"Them\" captures system audio from the other side. The transcript is the primary view -- clean and full-window."
        ),
    ]

    private var downloadFailed: Bool {
        !modelsReady && modelStatus.lowercased().contains("failed")
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            if currentStep < infoSteps.count {
                // Info steps
                Image(systemName: infoSteps[currentStep].icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Color.accent1)
                    .frame(height: 52)
                    .id(currentStep)

                Spacer().frame(height: 20)

                Text(infoSteps[currentStep].title)
                    .font(.system(size: 16, weight: .semibold))
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 10)

                Text(infoSteps[currentStep].body)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                // Model download step -- three states
                if modelsReady {
                    // SUCCESS state
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(Color.green)
                        .frame(height: 52)

                    Spacer().frame(height: 20)

                    Text("Speech Model Ready")
                        .font(.system(size: 16, weight: .semibold))
                        .multilineTextAlignment(.center)

                    Spacer().frame(height: 10)

                    Text("The on-device speech model is installed. You're ready to start transcribing.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)

                } else if downloadFailed {
                    // FAILURE state
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(Color.recordRed)
                        .frame(height: 52)

                    Spacer().frame(height: 20)

                    Text("Download Failed")
                        .font(.system(size: 16, weight: .semibold))
                        .multilineTextAlignment(.center)

                    Spacer().frame(height: 10)

                    Text(modelStatus)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)

                } else {
                    // DOWNLOADING state
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(Color.accent1)
                        .frame(height: 52)

                    Spacer().frame(height: 20)

                    Text("Installing Speech Model")
                        .font(.system(size: 16, weight: .semibold))
                        .multilineTextAlignment(.center)

                    Spacer().frame(height: 10)

                    Text("Downloading and installing the speech recognition model (~500 MB). This is a one-time setup.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)

                    Spacer().frame(height: 16)

                    // Stage-based progress bar
                    VStack(spacing: 8) {
                        ProgressView(value: downloadProgress)
                            .tint(Color.accent1)
                            .frame(maxWidth: 240)

                        Text(modelStatus)
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }

                    Spacer().frame(height: 12)

                    Text("Download times will vary based on the speed of your internet connection.")
                        .font(.system(size: 10))
                        .foregroundStyle(.quaternary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            // Dots
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Circle()
                        .fill(i == currentStep ? Color.accent1 : Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.bottom, 20)

            // Buttons
            HStack {
                if currentStep < infoSteps.count && modelsReady {
                    Button("Skip") {
                        finish()
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if currentStep < infoSteps.count {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentStep += 1
                        }
                    } label: {
                        Text("Next")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.accent1, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                } else if downloadFailed {
                    // Retry button
                    Button {
                        onRetry()
                    } label: {
                        Text("Try Again")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.accent1, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                } else {
                    // Get Started -- only enabled when models ready
                    Button {
                        finish()
                    } label: {
                        Text("Get Started")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                modelsReady ? Color.accent1 : Color.accent1.opacity(0.4),
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .disabled(!modelsReady)
                }
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bg0)
    }

    /// Maps status text to approximate progress (0.0 - 1.0)
    private var downloadProgress: Double {
        if modelsReady { return 1.0 }
        switch modelStatus {
        case let s where s.contains("Downloading"):
            return 0.2
        case let s where s.contains("Initializing"):
            return 0.6
        case let s where s.contains("voice activity"):
            return 0.8
        case let s where s.contains("Ready"):
            return 1.0
        default:
            return 0.05
        }
    }

    private func finish() {
        withAnimation(.easeOut(duration: 0.2)) {
            isPresented = false
        }
    }
}
