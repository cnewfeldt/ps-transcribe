import SwiftUI

/// Sidebar-footer capture dock — "Quiet Chronicle" redesign.
/// Replaces the window-bottom ControlBar; pinned inside the library column.
struct CaptureDock: View {
    let isRecording: Bool
    let activeSessionType: SessionType?
    let sessionElapsed: Int
    let audioLevel: Float
    let silenceSeconds: Int
    let autoStopThreshold: Int
    let currentInputName: String
    let statusMessage: String?
    let errorMessage: String?
    let modelsReady: Bool
    let hasError: Bool
    let onStartCallCapture: () -> Void
    let onStartVoiceMemo: () -> Void
    let onStop: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Optional: status / error / silence countdown -- stacked above the dock body
            if let error = errorMessage {
                Text(error)
                    .font(.chronicleMono(10))
                    .foregroundStyle(Color.recRed)
                    .lineLimit(2)
                    .padding(.horizontal, Spacing.x14)
                    .padding(.top, Spacing.x8)
            } else if let status = statusMessage, status != "Ready", !isRecording {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(Color.accentInk)
                    Text(status)
                        .font(.chronicleMono(10))
                        .foregroundStyle(Color.inkMuted)
                        .lineLimit(1)
                }
                .padding(.horizontal, Spacing.x14)
                .padding(.top, Spacing.x8)
            }

            if isRecording,
               silenceSeconds >= max(2, autoStopThreshold - max(5, autoStopThreshold / 4)) {
                Text("Silence -- auto-stop in \(max(0, autoStopThreshold - silenceSeconds))s")
                    .font(.chronicleMono(10))
                    .foregroundStyle(Color.recRed)
                    .padding(.horizontal, Spacing.x14)
                    .padding(.top, Spacing.x6)
            }

            // Dock body
            VStack(alignment: .leading, spacing: Spacing.x8) {
                statusLine
                    .padding(.horizontal, Spacing.x4)
                buttonsRow
            }
            .padding(.horizontal, 12)
            .padding(.top, Spacing.x10)
            .padding(.bottom, Spacing.x14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.paperWarm)
        .overlay(
            Rectangle()
                .fill(Color.rule)
                .frame(height: 0.5),
            alignment: .top
        )

        // Hidden ⌘. stop shortcut (preserves the prior ControlBar behavior)
        .background {
            if isRecording {
                Button(action: onStop) { EmptyView() }
                    .keyboardShortcut(".", modifiers: .command)
                    .frame(width: 0, height: 0)
                    .opacity(0)
            }
        }
    }

    // MARK: - Status line

    @ViewBuilder
    private var statusLine: some View {
        HStack(spacing: Spacing.x8) {
            statusDot
            Text(isRecording ? "RECORDING · \(formattedElapsed)" : "READY")
                .font(.chronicleMono(10, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(Color.inkFaint)

            Spacer(minLength: Spacing.x8)

            if isRecording {
                WaveformStrip(audioLevel: audioLevel)
                    .frame(width: 72, height: 12)
            } else {
                Text(currentInputName)
                    .font(.chronicleMono(10))
                    .foregroundStyle(Color.inkGhost)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.bottom, Spacing.x8)
    }

    private var statusDot: some View {
        ZStack {
            // Soft glow ring
            Circle()
                .fill((isRecording ? Color.recRed : Color.liveGreen).opacity(0.22))
                .frame(width: 12, height: 12)
            // Core dot
            Circle()
                .fill(isRecording ? Color.recRed : Color.liveGreen)
                .frame(width: 6, height: 6)
                .opacity(isRecording ? recordingDotOpacity : 1.0)
        }
    }

    @State private var recordingDotPulse = false
    private var recordingDotOpacity: Double {
        recordingDotPulse ? 1.0 : 0.45
    }

    // MARK: - Buttons

    @ViewBuilder
    private var buttonsRow: some View {
        HStack(spacing: Spacing.x6) {
            capturePrimaryButton
            if !isRecording {
                voiceMemoButton
            }
        }
        .animation(ChronicleAnimation.dockState, value: isRecording)
    }

    private var capturePrimaryButton: some View {
        Button(action: {
            if isRecording {
                onStop()
            } else if !hasError && modelsReady {
                onStartCallCapture()
            }
        }) {
            HStack(spacing: Spacing.x6) {
                Image(systemName: isRecording ? "stop.circle.fill" : "video.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isRecording ? Color.recRed : Color.paper)

                Text(primaryLabel)
                    .font(.chronicleSans(12, weight: .medium))
                    .foregroundStyle(isRecording ? Color.recRed : Color.paper)

                Spacer(minLength: Spacing.x4)
            }
            .lineLimit(1)
            .padding(.vertical, Spacing.x8)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isRecording ? Color.paper : Color.ink)
            .clipShape(RoundedRectangle(cornerRadius: Radius.button))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.button)
                    .stroke(isRecording ? Color.recRed.opacity(0.5) : Color.clear, lineWidth: 0.5)
            )
            .shadow(Shadows.primaryButton)
        }
        .buttonStyle(.plain)
        .focusable(false)
        .keyboardShortcut("r", modifiers: .command)
        .disabled(!modelsReady && !isRecording)
        .opacity((!modelsReady && !isRecording) ? 0.5 : 1.0)
        .help(isRecording ? "\(primaryLabel) (⌘.)" : "Meeting (⌘R)")
    }

    private var voiceMemoButton: some View {
        Button(action: {
            guard modelsReady, !hasError, !isRecording else { return }
            onStartVoiceMemo()
        }) {
            HStack(spacing: Spacing.x6) {
                Image(systemName: "mic")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.ink)

                Text("Memo")
                    .font(.chronicleSans(12, weight: .medium))
                    .foregroundStyle(Color.ink)

                Spacer(minLength: Spacing.x4)
            }
            .lineLimit(1)
            .padding(.vertical, Spacing.x8)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.paper)
            .clipShape(RoundedRectangle(cornerRadius: Radius.button))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.button)
                    .stroke(Color.ruleStrong, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .focusable(false)
        .keyboardShortcut("r", modifiers: [.command, .shift])
        .disabled(!modelsReady)
        .opacity(modelsReady ? 1.0 : 0.5)
        .help("Memo (⌘⇧R)")
    }

    // MARK: - Helpers

    /// Primary button text — "Meeting" / "Memo" when idle,
    /// "End Meeting" / "End Memo" while recording (based on which session is active).
    private var primaryLabel: String {
        if isRecording {
            switch activeSessionType {
            case .voiceMemo:   return "End Memo"
            case .callCapture: return "End Meeting"
            case .none:        return "Stop"
            }
        }
        return "Meeting"
    }

    private var formattedElapsed: String {
        let mins = sessionElapsed / 60
        let secs = sessionElapsed % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Waveform strip
//
// Rolling 16-sample waveform driven by the polled `audioLevel` signal.
// Each pulse updates once every ~80ms. Lightweight — no audio tap needed.

private struct WaveformStrip: View {
    let audioLevel: Float
    @State private var samples: [Float] = Array(repeating: 0, count: 16)

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(0..<samples.count, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.recRed.opacity(0.8))
                        .frame(
                            width: max(2, (geo.size.width - CGFloat(samples.count - 1) * 2) / CGFloat(samples.count)),
                            height: max(2, CGFloat(samples[i]) * geo.size.height)
                        )
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .task(id: audioLevel) {
            samples.removeFirst()
            samples.append(min(1.0, audioLevel))
        }
    }
}
