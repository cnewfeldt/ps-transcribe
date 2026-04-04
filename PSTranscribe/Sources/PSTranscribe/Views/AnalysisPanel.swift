import SwiftUI

/// Right-side panel displaying live or saved LLM analysis of the transcript.
///
/// Per UI-SPEC (phase 06):
/// - Four states: empty, loading, live, review
/// - Section cards for Summary, Action Items, Key Topics
/// - Pulsing accent dot in header when an update is in-flight (live mode only)
struct AnalysisPanel: View {
    let summary: String
    let actionItems: [String]
    let keyTopics: [String]
    let isUpdating: Bool
    /// true during recording, false for saved-session review mode.
    let isLive: Bool
    let hasData: Bool

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            if !hasData && !isUpdating {
                emptyState
            } else if !hasData && isUpdating {
                loadingState
            } else {
                contentScroll
            }
        }
        .frame(minWidth: 220, idealWidth: 260, maxWidth: 300)
        .frame(maxHeight: .infinity)
        .background(Color.bg2)
        .overlay(Divider(), alignment: .leading)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Analysis")
                .font(.system(size: 10, weight: .semibold))
                .textCase(.uppercase)
                .tracking(0.8)
                .foregroundStyle(Color.fg2)
            Spacer()
            if isLive && isUpdating {
                AnalysisPulseDot()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - States

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "brain")
                .font(.system(size: 24))
                .foregroundStyle(Color.fg3)
            Text("No analysis yet")
                .font(.system(size: 12))
                .foregroundStyle(Color.fg2)
            Text("Analysis will appear as the conversation progresses")
                .font(.system(size: 11))
                .foregroundStyle(Color.fg3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
    }

    private var loadingState: some View {
        VStack(spacing: 8) {
            ProgressView()
                .controlSize(.mini)
                .tint(Color.accent1)
            Text("Analyzing...")
                .font(.system(size: 10))
                .foregroundStyle(Color.fg2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var contentScroll: some View {
        ScrollView {
            VStack(spacing: 24) {
                if !summary.isEmpty {
                    AnalysisSectionCard(title: "Summary") {
                        Text(summary)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.fg1)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                if !actionItems.isEmpty {
                    AnalysisSectionCard(title: "Action Items") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(actionItems, id: \.self) { item in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "square")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.fg3)
                                    Text(item)
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.fg1)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                if !keyTopics.isEmpty {
                    AnalysisSectionCard(title: "Key Topics") {
                        KeyTopicsView(topics: keyTopics)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Section Card

private struct AnalysisSectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .textCase(.uppercase)
                .tracking(0.8)
                .foregroundStyle(Color.accent1)

            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.accent1.opacity(0.4))
                    .frame(width: 3)

                content()
                    .padding(.leading, 8)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.bg1.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.06))
        )
    }
}

// MARK: - Key Topics (simple wrapping via LazyVGrid)

private struct KeyTopicsView: View {
    let topics: [String]

    private let columns = [GridItem(.adaptive(minimum: 60, maximum: 180), spacing: 6, alignment: .leading)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
            ForEach(topics, id: \.self) { topic in
                Text(topic)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.fg2)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.bg0.opacity(0.8))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.08)))
            }
        }
    }
}

// MARK: - Pulsing Dot

private struct AnalysisPulseDot: View {
    @State private var pulse = false
    var body: some View {
        Circle()
            .fill(Color.accent1)
            .frame(width: 4, height: 4)
            .opacity(pulse ? 1.0 : 0.3)
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
            .onAppear { pulse = true }
    }
}
