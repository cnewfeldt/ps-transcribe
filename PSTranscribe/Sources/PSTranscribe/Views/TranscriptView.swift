import SwiftUI

/// Chronicle-style bubble transcript.
struct TranscriptView: View {
    let utterances: [Utterance]
    let volatileYouText: String
    let volatileThemText: String
    var onRemoveUtterance: ((UUID) -> Void)?

    var body: some View {
        GeometryReader { geo in
            let maxBubbleWidth = max(180, geo.size.width * 0.5)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(utterances.enumerated()), id: \.element.id) { (idx, utterance) in
                            let prev = idx > 0 ? utterances[idx - 1] : nil
                            let next = idx < utterances.count - 1 ? utterances[idx + 1] : nil
                            UtteranceBubble(
                                utterance: utterance,
                                isFirstInGroup: prev?.speaker != utterance.speaker,
                                isLastInGroup: next?.speaker != utterance.speaker,
                                maxBubbleWidth: maxBubbleWidth
                            )
                            .id(utterance.id)
                            .contextMenu {
                                if onRemoveUtterance != nil {
                                    Button("Remove", role: .destructive) {
                                        onRemoveUtterance?(utterance.id)
                                    }
                                }
                            }
                        }

                        if !volatileYouText.isEmpty {
                            VolatileIndicator(
                                text: volatileYouText,
                                speaker: .you,
                                maxBubbleWidth: maxBubbleWidth
                            )
                            .id("volatile-you")
                        }
                        if !volatileThemText.isEmpty {
                            VolatileIndicator(
                                text: volatileThemText,
                                speaker: .them,
                                maxBubbleWidth: maxBubbleWidth
                            )
                            .id("volatile-them")
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .onChange(of: utterances.count) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        if let last = utterances.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: volatileYouText) {
                    proxy.scrollTo("volatile-you", anchor: .bottom)
                }
                .onChange(of: volatileThemText) {
                    proxy.scrollTo("volatile-them", anchor: .bottom)
                }
            }
        }
    }
}

// MARK: - Bubble

private struct UtteranceBubble: View {
    let utterance: Utterance
    let isFirstInGroup: Bool
    let isLastInGroup: Bool
    let maxBubbleWidth: CGFloat

    private var isYou: Bool {
        if case .you = utterance.speaker { return true }
        return false
    }

    private var speakerName: String {
        switch utterance.speaker {
        case .you:              return "You"
        case .them:             return "Speaker 2"
        case .named(let label): return label
        }
    }

    /// Corner radii — flattened join when the previous bubble is same speaker.
    private var shape: UnevenRoundedRectangle {
        let r = Radius.bubble
        let join = Radius.bubbleJoin
        if isYou {
            return UnevenRoundedRectangle(
                topLeadingRadius: r,
                bottomLeadingRadius: r,
                bottomTrailingRadius: r,
                topTrailingRadius: isFirstInGroup ? r : join
            )
        } else {
            return UnevenRoundedRectangle(
                topLeadingRadius: isFirstInGroup ? r : join,
                bottomLeadingRadius: r,
                bottomTrailingRadius: r,
                topTrailingRadius: r
            )
        }
    }

    var body: some View {
        VStack(alignment: isYou ? .trailing : .leading, spacing: 4) {
            if isFirstInGroup {
                Text(speakerName)
                    .font(.chronicleMono(10, weight: .semibold))
                    .tracking(0.5)
                    .textCase(.uppercase)
                    .foregroundStyle(isYou ? Color.inkFaint : Color.spk2Rail)
                    .padding(isYou ? .trailing : .leading, 4)
            }

            HStack(spacing: 0) {
                if isYou { Spacer(minLength: 0) }

                bubbleContent
                    .frame(maxWidth: maxBubbleWidth, alignment: isYou ? .trailing : .leading)

                if !isYou { Spacer(minLength: 0) }
            }
        }
    }

    private var bubbleContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(utterance.text)
                .font(.chronicleSans(13))
                .lineSpacing(2)
                .foregroundStyle(isYou ? Color.youFg : Color.spk2Fg)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(timestamp)
                .font(.chronicleMono(10))
                .foregroundStyle((isYou ? Color.youFg : Color.spk2Fg).opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isYou ? Color.youBg : Color.spk2Bg)
        .clipShape(shape)
    }

    private var timestamp: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: utterance.timestamp)
    }
}

// MARK: - Volatile (live) indicator

private struct VolatileIndicator: View {
    let text: String
    let speaker: Speaker
    let maxBubbleWidth: CGFloat
    @State private var pulse = false

    private var isYou: Bool {
        if case .you = speaker { return true }
        return false
    }

    var body: some View {
        HStack(spacing: 0) {
            if isYou { Spacer(minLength: 0) }

            HStack(spacing: 6) {
                Text(text)
                    .font(.chronicleSans(13).italic())
                    .foregroundStyle((isYou ? Color.youFg : Color.spk2Fg).opacity(0.75))
                Circle()
                    .fill(isYou ? Color.youFg.opacity(0.7) : Color.spk2Rail)
                    .frame(width: 4, height: 4)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: maxBubbleWidth, alignment: .leading)
            .background(isYou ? Color.youBg : Color.spk2Bg)
            .clipShape(RoundedRectangle(cornerRadius: Radius.bubble))
            .opacity(pulse ? 0.9 : 0.55)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
            .onAppear { pulse = true }

            if !isYou { Spacer(minLength: 0) }
        }
    }
}

// MARK: - Legacy dark-theme tokens (kept until other views migrate)

extension Color {
    // Backgrounds — warm
    static let bg0 = Color(red: 0.10, green: 0.09, blue: 0.09)   // #1A1818
    static let bg1 = Color(red: 0.18, green: 0.17, blue: 0.16)   // #2E2B29 (glass base)
    static let bg2 = Color(red: 0.14, green: 0.13, blue: 0.12)   // #242120

    // Foregrounds — warm cream
    static let fg1 = Color(red: 0.94, green: 0.93, blue: 0.91)   // #F0EDE8
    static let fg2 = Color(red: 0.54, green: 0.52, blue: 0.50)   // #8A8480
    static let fg3 = Color(red: 0.36, green: 0.34, blue: 0.33)   // #5C5854

    // Accent — lavender
    static let accent1 = Color(red: 0.77, green: 0.63, blue: 1.0) // #C4A0FF
    static let accent2 = Color(red: 0.58, green: 0.47, blue: 0.75)// dimmer

    // Recording red
    static let recordRed = Color(red: 0.91, green: 0.36, blue: 0.36) // #E85B5B

    // Named speaker palette
    static let speakerTeal = Color(red: 0.60, green: 0.85, blue: 0.75)
    static let speakerAmber = Color(red: 0.95, green: 0.75, blue: 0.45)
}
