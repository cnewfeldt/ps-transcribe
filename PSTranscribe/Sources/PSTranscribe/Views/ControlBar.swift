import SwiftUI
import AppKit

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

/// Pulsing radar-ring that radiates outward from a mic icon.
private struct PulsingRing: View {
    var color: Color = .green
    var size: CGFloat = 28
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.6

    var body: some View {
        Circle()
            .stroke(color.opacity(0.7), lineWidth: 2)
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                scale = 1.0
                opacity = 0.6
                withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                    scale = 1.8
                    opacity = 0.0
                }
            }
    }
}

struct ControlBar: View {
    let isRecording: Bool
    let activeSessionType: SessionType?
    let audioLevel: Float
    let detectedApp: String?
    var detectedAppBundleID: String? = nil
    let silenceSeconds: Int
    let statusMessage: String?
    let errorMessage: String?
    let modelsReady: Bool
    let hasError: Bool
    let activeErrors: [String]
    let onStartCallCapture: () -> Void
    let onStartVoiceMemo: () -> Void
    let onStop: () -> Void
    var onOpenSettings: (() -> Void)?

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

            VStack(spacing: 8) {
                HStack(spacing: isRecording ? 0 : 10) {
                    sessionButton(
                        type: .callCapture,
                        icon: "phone.fill",
                        label: "Call Capture",
                        shortcutHint: "\u{2318}R",
                        onStart: onStartCallCapture
                    )
                    .frame(maxWidth: isRecording && activeSessionType != .callCapture ? 0 : .infinity)
                    .opacity(isRecording && activeSessionType != .callCapture ? 0 : 1)
                    .clipped()

                    sessionButton(
                        type: .voiceMemo,
                        icon: "mic.fill",
                        label: "Voice Memo",
                        shortcutHint: "\u{2318}\u{21E7}R",
                        onStart: onStartVoiceMemo
                    )
                    .frame(maxWidth: isRecording && activeSessionType != .voiceMemo ? 0 : .infinity)
                    .opacity(isRecording && activeSessionType != .voiceMemo ? 0 : 1)
                    .clipped()
                }
                .animation(.spring(duration: 0.35, bounce: 0.15), value: isRecording)
                .animation(.spring(duration: 0.35, bounce: 0.15), value: activeSessionType)

                // Hidden stop shortcut (⌘.)
                if isRecording {
                    Button(action: onStop) { EmptyView() }
                        .keyboardShortcut(".", modifiers: .command)
                        .frame(width: 0, height: 0)
                        .opacity(0)
                }

            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            if isRecording && silenceSeconds >= 90 {
                Text("Silence -- auto-stop in \(120 - silenceSeconds)s")
                    .font(.system(size: 10))
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
            }
        }
        .background(Color.bg1.opacity(0.45))
        .overlay(Divider(), alignment: .top)
    }

    // MARK: - Session Button

    @ViewBuilder
    private func sessionButton(
        type: SessionType,
        icon: String,
        label: String,
        shortcutHint: String,
        onStart: @escaping () -> Void
    ) -> some View {
        let isActive = isRecording && activeSessionType == type

        Button(action: {
            if isActive {
                onStop()
            } else if !hasError {
                onStart()
            }
        }) {
            HStack(spacing: isActive ? 10 : 6) {
                if isActive {
                    PulsingDot(size: 6)
                }

                // Indicator (app icon for active call capture, otherwise SF Symbol) with pulsing ring when recording
                ZStack {
                    if isActive {
                        PulsingRing(color: .green, size: 28)
                    }
                    if isActive, type == .callCapture, let bundleID = detectedAppBundleID, let nsImage = Self.appIcon(for: bundleID) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: hasError ? "mic.slash" : (isActive ? "mic.fill" : icon))
                            .font(.system(size: 14))
                            .foregroundStyle(
                                hasError ? Color.recordRed
                                : isActive ? Color.green
                                : Color.fg1
                            )
                    }
                }
                .frame(width: 28, height: 28)

                if isActive {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Stop Recording")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.fg1)
                        Text(activeSessionLabel)
                            .font(.system(size: 10))
                            .foregroundStyle(Color.fg2)
                    }
                } else {
                    Text(label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.fg1)
                }

                Spacer()

                if !isActive {
                    Text(shortcutHint)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.fg3)
                }
            }
            .lineLimit(1)
            .padding(.vertical, 12)
            .padding(.horizontal, isActive ? 16 : 8)
            .frame(maxWidth: .infinity)
            .background(isActive ? Color.accent1.opacity(0.08) : Color.bg1.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Color.accent1.opacity(0.12) : Color.white.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
        .focusable(false)
        .keyboardShortcut(
            type == .callCapture ? "r" : "r",
            modifiers: type == .callCapture ? .command : [.command, .shift]
        )
        .disabled(!isRecording && !modelsReady && !hasError)
        .opacity(!isRecording && !modelsReady ? 0.4 : 1.0)
        .help(
            hasError ? activeErrors.joined(separator: "\n")
            : isActive ? "Stop Recording (\u{2318}.)"
            : ""
        )
    }

    /// Resolves a running app's icon image from a bundle identifier.
    /// Returns nil if the app isn't installed or can't be located.
    private static func appIcon(for bundleID: String) -> NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: url.path)
    }

    private var activeSessionLabel: String {
        switch activeSessionType {
        case .callCapture:
            if let app = detectedApp {
                return "Call Capture \u{00B7} \(app)"
            }
            return "Call Capture"
        case .voiceMemo:
            return "Voice Memo"
        case nil:
            return "Recording"
        }
    }
}
