import SwiftUI

struct LibrarySidebar: View {
    let entries: [LibraryEntry]
    @Binding var selectedID: UUID?
    let activeEntryID: UUID?
    var onRename: ((UUID, String) -> Void)?
    var onDelete: ((UUID) -> Void)?
    var isNotionConfigured: Bool = false
    var onSendToNotion: ((UUID) -> Void)?
    var isObsidianAvailable: Bool = false
    var obsidianURLForEntry: ((LibraryEntry) -> URL?) = { _ in nil }

    @State private var searchQuery: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            searchField
            if entries.isEmpty {
                emptyState
            } else {
                scrollContent
            }
        }
        .background(Color.paperWarm)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.x6) {
            Text("Library")
                .font(.chronicleSans(18, weight: .bold))
                .foregroundStyle(Color.ink)
            Text("\(entries.count)")
                .font(.chronicleMono(12))
                .foregroundStyle(Color.inkFaint)
            Spacer()
        }
        .padding(.horizontal, Spacing.x22)
        .padding(.top, Spacing.x14)
        .padding(.bottom, Spacing.x10)
    }

    // MARK: - Search

    private var searchField: some View {
        HStack(spacing: Spacing.x6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundStyle(Color.inkFaint)
            TextField("Search recordings", text: $searchQuery)
                .font(.chronicleSans(12))
                .foregroundStyle(Color.ink)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, Spacing.x10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: Radius.button)
                .fill(Color(red: 30/255, green: 30/255, blue: 28/255).opacity(0.05))
        )
        .padding(.horizontal, Spacing.x14)
        .padding(.bottom, Spacing.x10)
    }

    // MARK: - Grouped content

    private var scrollContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                ForEach(groupedEntries, id: \.key) { group in
                    dateDivider(group.key)
                    ForEach(group.value, id: \.id) { entry in
                        LibraryEntryRow(
                            entry: entry,
                            isSelected: selectedID == entry.id,
                            onRename: { newName in onRename?(entry.id, newName) },
                            onDelete: { onDelete?(entry.id) },
                            isNotionConfigured: isNotionConfigured,
                            onSendToNotion: { onSendToNotion?(entry.id) },
                            obsidianURL: obsidianURLForEntry(entry),
                            isObsidianAvailable: isObsidianAvailable
                        )
                        .padding(.horizontal, Spacing.x10)
                        .padding(.vertical, 5) // 10pt total between adjacent rows
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedID = entry.id
                        }
                    }
                }
            }
            .padding(.bottom, Spacing.x14)
        }
    }

    @ViewBuilder
    private func dateDivider(_ label: String) -> some View {
        Text(label)
            .font(.chronicleMono(10, weight: .semibold))
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(Color.inkFaint)
            .padding(.top, Spacing.x14)
            .padding(.bottom, Spacing.x6)
            .padding(.horizontal, Spacing.x22)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 28))
                .foregroundStyle(Color.inkFaint)
            Text("No recordings yet")
                .font(.chronicleSans(12))
                .foregroundStyle(Color.inkMuted)
            Text("Start a call capture or voice memo to begin.")
                .font(.chronicleSans(11))
                .foregroundStyle(Color.inkFaint)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Grouping

    private var filteredEntries: [LibraryEntry] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return entries }
        return entries.filter { entry in
            entry.displayName.lowercased().contains(q)
                || (entry.firstLinePreview?.lowercased().contains(q) ?? false)
        }
    }

    /// Groups by date label (e.g. "APR 20"), preserving entry order.
    private var groupedEntries: [(key: String, value: [LibraryEntry])] {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        var seen: [String: [LibraryEntry]] = [:]
        var order: [String] = []
        for entry in filteredEntries {
            let key = fmt.string(from: entry.startDate).uppercased()
            if seen[key] == nil { order.append(key) }
            seen[key, default: []].append(entry)
        }
        return order.map { ($0, seen[$0] ?? []) }
    }
}
