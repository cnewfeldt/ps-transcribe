import SwiftUI

/// Three-block native macOS HUD body (Phase 18 D-01, D-03):
///   [recording dot] [0:12 timer] [partial transcript or status]   [Stop]
///
/// The body reads the coordinator's state machine and produces the right text per case.
/// Styled to match the system HUD vibrancy material set by `DictationWindowController`.
///
/// Hosted via `NSHostingView` inside a borderless non-activating NSPanel; sized roughly
/// 420x56pt (panel may shrink width on narrow screens -- view uses `frame(maxWidth: .infinity)`
/// so it adapts).
struct DictationHUD: View {
    let state: DictationCoordinator.State
    let elapsed: TimeInterval
    let partialText: String
    let onStop: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Recording indicator: red dot, animates pulse only while listening.
            recordingIndicator
                .frame(width: 10, height: 10)

            // Elapsed timer mm:ss (always shown; reads 0:00 in idle/loadingModel).
            Text(formatElapsed(elapsed))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary)
                .frame(minWidth: 40, alignment: .leading)

            // Live partial transcript or status text.
            Text(displayText)
                .font(.body)
                .foregroundStyle(displayTextColor)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Stop button (D-01): visible whenever a session is active.
            // Hidden during .copied pill (no need to stop something that already ended).
            if showsStopButton {
                Button("Stop", action: onStop)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
    }

    // MARK: - State-driven content

    /// Display string per state. Drives the user-visible HUD message.
    private var displayText: String {
        switch state {
        case .idle:
            return ""
        case .loadingModel:
            return "Loading model…"
        case .listening:
            return partialText.isEmpty ? "Listening…" : partialText
        case .cancellingPending:
            return "Press Esc again to cancel"
        case .copied:
            return "Copied to clipboard"
        case .blockedSessionActive:
            return "Recording in progress — dictation unavailable"
        }
    }

    /// Color hint: the cancellingPending and blockedSessionActive states use a less-emphatic tone
    /// so the user notices something has changed without it feeling like an error.
    private var displayTextColor: Color {
        switch state {
        case .cancellingPending, .blockedSessionActive:
            return .secondary
        default:
            return .primary
        }
    }

    /// Stop button is hidden in .copied (the session already ended) and
    /// .blockedSessionActive (no session was started).
    private var showsStopButton: Bool {
        switch state {
        case .listening, .cancellingPending, .loadingModel:
            return true
        case .idle, .copied, .blockedSessionActive:
            return false
        }
    }

    // MARK: - Recording indicator

    @ViewBuilder
    private var recordingIndicator: some View {
        switch state {
        case .listening:
            Circle()
                .fill(.red)
                .symbolEffect(.pulse, isActive: true)
        case .cancellingPending, .loadingModel:
            Circle()
                .fill(.orange)
        case .copied:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .blockedSessionActive:
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(.secondary)
        case .idle:
            Circle()
                .fill(.gray.opacity(0.3))
        }
    }

    // MARK: - Time formatting

    private func formatElapsed(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let mm = total / 60
        let ss = total % 60
        return String(format: "%d:%02d", mm, ss)
    }
}

#Preview("Listening") {
    DictationHUD(
        state: .listening,
        elapsed: 12,
        partialText: "the quick brown fox jumps over the lazy dog",
        onStop: {}
    )
    .frame(width: 420, height: 56)
    .background(.regularMaterial)
}

#Preview("Loading") {
    DictationHUD(
        state: .loadingModel,
        elapsed: 0,
        partialText: "",
        onStop: {}
    )
    .frame(width: 420, height: 56)
    .background(.regularMaterial)
}

#Preview("Copied") {
    DictationHUD(
        state: .copied,
        elapsed: 25,
        partialText: "",
        onStop: {}
    )
    .frame(width: 420, height: 56)
    .background(.regularMaterial)
}

#Preview("Cancelling Pending") {
    DictationHUD(
        state: .cancellingPending(deadline: Date().addingTimeInterval(3)),
        elapsed: 32,
        partialText: "",
        onStop: {}
    )
    .frame(width: 420, height: 56)
    .background(.regularMaterial)
}

#Preview("Blocked") {
    DictationHUD(
        state: .blockedSessionActive,
        elapsed: 0,
        partialText: "",
        onStop: {}
    )
    .frame(width: 420, height: 56)
    .background(.regularMaterial)
}
