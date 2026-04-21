import SwiftUI

/// Right-column details pane: waveform card + Saved to / Sent to / Speakers sections.
struct DetailsPane: View {
    let selectedEntry: LibraryEntry?
    var meetingsFolderName: String = "Meetings"
    var voiceFolderName: String = "Voice"
    var isObsidianAvailable: Bool = false
    var obsidianURL: URL? = nil

    @State private var speakerStats: [SpeakerStat] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.x22) {
                Text("Details")
                    .chronicleMetaLabel()

                if let entry = selectedEntry {
                    sectionHeader("Saved to")
                    keyValueRow("Folder", value: folderLabel(entry))
                    keyValueRow("File", value: fileLabel(entry))
                    keyValueRow("Duration", value: Self.formatDuration(entry.duration))

                    sectionHeader("Sent to")
                    keyValueRow(
                        "Notion",
                        value: entry.notionPageURL != nil ? "Synced" : "Not sent",
                        valueColor: entry.notionPageURL != nil ? Color.liveGreen : Color.inkFaint
                    )
                    keyValueRow(
                        "Obsidian",
                        value: obsidianStatusLabel(entry),
                        valueColor: obsidianStatusColor(entry)
                    )

                    if !speakerStats.isEmpty {
                        sectionHeader("Speakers")
                        ForEach(speakerStats) { stat in
                            speakerRow(stat)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.x22)
            .padding(.top, Spacing.x18)
            .padding(.bottom, Spacing.x22)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.paper)
        .task(id: selectedEntry?.id) {
            speakerStats = await Self.loadSpeakerStats(for: selectedEntry)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .chronicleMetaLabel()
            .padding(.top, Spacing.x4)
    }

    @ViewBuilder
    private func keyValueRow(_ label: String, value: String, valueColor: Color = Color.ink) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.chronicleSans(11.5))
                .foregroundStyle(Color.inkFaint)
            Spacer()
            Text(value)
                .font(.chronicleSans(11.5))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    @ViewBuilder
    private func speakerRow(_ stat: SpeakerStat) -> some View {
        HStack(spacing: Spacing.x8) {
            Circle()
                .fill(stat.color)
                .frame(width: 8, height: 8)
            Text(stat.name)
                .font(.chronicleSans(11.5))
                .foregroundStyle(Color.ink)
                .lineLimit(1)
            Spacer()
            Text("\(Int((stat.percent * 100).rounded()))%")
                .font(.chronicleSans(11.5))
                .foregroundStyle(Color.inkMuted)
        }
    }

    // MARK: - Derivations

    private func folderLabel(_ entry: LibraryEntry) -> String {
        // The entry's sessionType determines the target folder; show the
        // configured friendly name rather than the full path.
        switch entry.sessionType {
        case .callCapture: return meetingsFolderName
        case .voiceMemo:   return voiceFolderName
        }
    }

    private func fileLabel(_ entry: LibraryEntry) -> String {
        guard !entry.filePath.isEmpty else { return "—" }
        return URL(fileURLWithPath: entry.filePath).lastPathComponent
    }

    /// "Synced" when the transcript is inside a configured Obsidian vault AND
    /// the app is installed; "Not in vault" when Obsidian is set up but the
    /// file lives elsewhere; "—" when Obsidian isn't configured/installed.
    private func obsidianStatusLabel(_ entry: LibraryEntry) -> String {
        guard isObsidianAvailable else { return "—" }
        return obsidianURL != nil ? "Synced" : "Not in vault"
    }

    private func obsidianStatusColor(_ entry: LibraryEntry) -> Color {
        guard isObsidianAvailable else { return Color.inkFaint }
        return obsidianURL != nil ? Color.liveGreen : Color.inkFaint
    }

    static func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return m > 0 ? "\(h)h \(m)m" : "\(h)h" }
        if m > 0 { return s > 0 ? "\(m)m \(s)s" : "\(m)m" }
        return "\(s)s"
    }

    // MARK: - Speaker stats loader

    private static func loadSpeakerStats(for entry: LibraryEntry?) async -> [SpeakerStat] {
        guard let entry,
              !entry.filePath.isEmpty,
              FileManager.default.fileExists(atPath: entry.filePath) else { return [] }

        let url = URL(fileURLWithPath: entry.filePath)
        return await Task.detached(priority: .utility) { () -> [SpeakerStat] in
            guard let utterances = try? parseTranscript(at: url), !utterances.isEmpty else { return [] }
            var counts: [String: Int] = [:]
            var order: [String] = []
            for u in utterances {
                let key = u.speaker.displayName
                if counts[key] == nil { order.append(key) }
                let wordCount = u.text.split(whereSeparator: \.isWhitespace).count
                counts[key, default: 0] += wordCount
            }
            let total = counts.values.reduce(0, +)
            guard total > 0 else { return [] }
            return order.map { name in
                SpeakerStat(
                    name: name,
                    percent: Double(counts[name] ?? 0) / Double(total),
                    color: SpeakerStat.color(for: name)
                )
            }
        }.value
    }
}

// MARK: - SpeakerStat

struct SpeakerStat: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let percent: Double
    let color: Color

    static func color(for name: String) -> Color {
        switch name.lowercased() {
        case "you": return Color.accentInk
        default:    return Color.spk2Rail
        }
    }
}

// MARK: - Speaker display helper

extension Speaker {
    fileprivate var displayName: String {
        switch self {
        case .you:              return "You"
        case .them:             return "Them"
        case .named(let label): return label
        }
    }
}

