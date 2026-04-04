import SwiftUI

struct PulsingDot: View {
    var size: CGFloat = 10
    @State private var pulse = false
    var body: some View {
        Circle()
            .fill(Color.recordRed)
            .frame(width: size, height: size)
            .opacity(pulse ? 1.0 : 0.4)
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
            .onAppear { pulse = true }
    }
}

private struct MicButton: View {
    enum MicState { case idle, recording, error }

    let state: MicState
    let errorTooltip: String
    let modelsReady: Bool
    let onTap: () -> Void

    @State private var ringScale: CGFloat = 1.0
    @State private var ringOpacity: Double = 0.6

    private var iconName: String {
        switch state {
        case .idle, .recording: return "mic.fill"
        case .error: return "mic.slash"
        }
    }

    private var iconColor: Color {
        switch state {
        case .idle: return Color.fg2
        case .recording: return Color.green
        case .error: return Color.recordRed
        }
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if state == .recording {
                    Circle()
                        .stroke(Color.green.opacity(0.7), lineWidth: 2.5)
                        .frame(width: 52, height: 52)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)
                }

                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundStyle(iconColor)
                    .frame(width: 44, height: 44)
            }
        }
        .buttonStyle(.plain)
        .focusable(false)
        .disabled(state == .idle && !modelsReady)
        .opacity(state == .idle && !modelsReady ? 0.4 : 1.0)
        .help(state == .error ? errorTooltip : (state == .idle ? "Start Recording" : ""))
        .onChange(of: state) { _, newState in
            if newState == .recording {
                startPulse()
            } else {
                ringScale = 1.0
                ringOpacity = 0.6
            }
        }
        .onAppear {
            if state == .recording {
                startPulse()
            }
        }
    }

    private func startPulse() {
        ringScale = 1.0
        ringOpacity = 0.6
        withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
            ringScale = 1.8
            ringOpacity = 0.0
        }
    }
}

struct ControlBar: View {
    let isRecording: Bool
    let activeSessionType: SessionType?
    let audioLevel: Float
    let detectedApp: String?
    let silenceSeconds: Int
    let statusMessage: String?
    let errorMessage: String?
    let modelsReady: Bool
    let hasError: Bool
    let activeErrors: [String]
    let onStartCallCapture: () -> Void
    let onStartVoiceMemo: () -> Void
    let onStartLastUsed: () -> Void
    let onStop: () -> Void

    private var micState: MicButton.MicState {
        if hasError { return .error }
        if isRecording { return .recording }
        return .idle
    }

    private func micTapped() {
        switch micState {
        case .idle:
            onStartLastUsed()
        case .recording:
            onStop()
        case .error:
            if #available(macOS 14, *) {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } else {
                NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.recordRed)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
            }

            if let status = statusMessage, status != "Ready" {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(Color.accent1)
                    Text(status)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fg2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }

            if isRecording {
                // Recording state: stop bar + MicButton
                VStack(spacing: 8) {
                    Button(action: onStop) {
                        HStack(spacing: 10) {
                            PulsingDot(size: 6)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Stop Recording")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color.fg1)
                                Text(activeSessionLabel)
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.fg2)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.accent1.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.accent1.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .keyboardShortcut(".", modifiers: .command)

                    MicButton(
                        state: micState,
                        errorTooltip: activeErrors.joined(separator: "\n"),
                        modelsReady: modelsReady,
                        onTap: micTapped
                    )
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                if silenceSeconds >= 90 {
                    Text("Silence -- auto-stop in \(120 - silenceSeconds)s")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                }
            } else {
                // Idle state: buttons + MicButton centered
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Button(action: onStartCallCapture) {
                            HStack(spacing: 6) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.fg1)
                                Text("Call Capture")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color.fg1)
                                Text("\u{2318}R")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.fg3)
                            }
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                            .background(Color.bg1.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                        .keyboardShortcut("r", modifiers: .command)
                        .disabled(!modelsReady)
                        .opacity(modelsReady ? 1.0 : 0.4)

                        MicButton(
                            state: micState,
                            errorTooltip: activeErrors.joined(separator: "\n"),
                            modelsReady: modelsReady,
                            onTap: micTapped
                        )

                        Button(action: onStartVoiceMemo) {
                            HStack(spacing: 6) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.fg1)
                                Text("Voice Memo")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color.fg1)
                                Text("\u{2318}\u{21E7}R")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.fg3)
                            }
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                            .background(Color.bg1.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                        .keyboardShortcut("r", modifiers: [.command, .shift])
                        .disabled(!modelsReady)
                        .opacity(modelsReady ? 1.0 : 0.4)
                    }

                    // Gear button row -- persistent, not recording-state-dependent
                    HStack {
                        Spacer()
                        Button {
                            if #available(macOS 14, *) {
                                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                            } else {
                                NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                            }
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.fg2)
                                .frame(width: 36, height: 36)
                                .background(Color.bg1.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                        .help("Settings (\u{2318},)")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .background(Color.bg1.opacity(0.45))
        .overlay(Divider(), alignment: .top)
    }

    private var activeSessionLabel: String {
        switch activeSessionType {
        case .callCapture:
            if let app = detectedApp {
                return "Call Capture · \(app)"
            }
            return "Call Capture"
        case .voiceMemo:
            return "Voice Memo"
        case nil:
            return "Recording"
        }
    }
}
