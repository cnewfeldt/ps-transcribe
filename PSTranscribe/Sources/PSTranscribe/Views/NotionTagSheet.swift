import SwiftUI

struct NotionTagSheet: View {
    let entryTitle: String
    let entryDate: Date
    @Binding var isPresented: Bool
    var errorMessage: String?
    let onSend: ([String]) -> Void

    @State private var tagInput: String = ""
    @State private var selectedTags: [String] = []
    @AppStorage("notionPreviousTags") private var previousTagsJSON: String = "[]"

    private var previousTags: [String] {
        guard let data = previousTagsJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        // Exclude tags already selected
        return Array(decoded.filter { !selectedTags.contains($0) }.prefix(10))
    }

    private var dateString: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return fmt.string(from: entryDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(entryTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.fg1)
                    .lineLimit(2)
                Text(dateString)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fg2)
            }

            Divider()

            // Tag input
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.fg2)

                HStack(spacing: 8) {
                    TextField("Add a tag...", text: $tagInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fg1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.bg1)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .onSubmit { addTagFromInput() }

                    Button("Add") {
                        addTagFromInput()
                    }
                    .font(.system(size: 11))
                    .disabled(tagInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            // Selected tags
            if !selectedTags.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Selected")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.fg2)
                    TagChipRow(tags: selectedTags, showRemove: true) { tag in
                        selectedTags.removeAll { $0 == tag }
                    }
                }
            }

            // Previously used tags
            if !previousTags.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Previously used")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.fg2)
                    TagChipRow(tags: previousTags, showRemove: false) { tag in
                        if !selectedTags.contains(tag) {
                            selectedTags.append(tag)
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            // Error display
            if let errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Footer buttons
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("Send to Notion") {
                    persistTags(selectedTags)
                    onSend(selectedTags)
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(width: 340)
        .padding(20)
        .background(Color.bg0)
        .preferredColorScheme(.dark)
    }

    // MARK: - Actions

    private func addTagFromInput() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if !selectedTags.contains(trimmed) {
            selectedTags.append(trimmed)
        }
        tagInput = ""
    }

    // MARK: - Tag persistence

    /// Merges newly used tags into the persistent list (head-first, deduped, capped at 10).
    func persistTags(_ tags: [String]) {
        guard let existingData = previousTagsJSON.data(using: .utf8),
              let existing = try? JSONDecoder().decode([String].self, from: existingData) else {
            if let encoded = try? JSONEncoder().encode(Array(tags.prefix(10))),
               let str = String(data: encoded, encoding: .utf8) {
                previousTagsJSON = str
            }
            return
        }
        var merged = tags
        for tag in existing where !merged.contains(tag) {
            merged.append(tag)
        }
        let capped = Array(merged.prefix(10))
        if let encoded = try? JSONEncoder().encode(capped),
           let str = String(data: encoded, encoding: .utf8) {
            previousTagsJSON = str
        }
    }
}

// MARK: - Tag Chip Row

private struct TagChipRow: View {
    let tags: [String]
    let showRemove: Bool
    let onTap: (String) -> Void

    var body: some View {
        // Simple wrapping flow using a ZStack-based approach
        FlowLayout(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                TagChip(label: tag, showRemove: showRemove) {
                    onTap(tag)
                }
            }
        }
    }
}

// MARK: - Tag Chip

private struct TagChip: View {
    let label: String
    let showRemove: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.accent1)
                if showRemove {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color.accent1.opacity(0.7))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accent1.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout

/// A simple layout that wraps children horizontally, breaking to a new row when needed.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 300
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight = y + rowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        // First pass: calculate row heights and break points
        var rows: [[LayoutSubview]] = [[]]
        var rowWidths: [CGFloat] = [0]
        let maxWidth = bounds.width

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let currentRow = rows.count - 1
            if rowWidths[currentRow] + size.width > maxWidth, rowWidths[currentRow] > 0 {
                rows.append([subview])
                rowWidths.append(size.width + spacing)
            } else {
                rows[currentRow].append(subview)
                rowWidths[currentRow] += size.width + spacing
            }
        }

        // Second pass: place
        for row in rows {
            var rowH: CGFloat = 0
            for subview in row {
                rowH = max(rowH, subview.sizeThatFits(.unspecified).height)
            }
            x = bounds.minX
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowH + spacing
            rowHeight = rowH
            _ = rowHeight
        }
    }
}
