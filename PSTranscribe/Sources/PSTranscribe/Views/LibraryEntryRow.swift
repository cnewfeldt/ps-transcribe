import SwiftUI
import AppKit

struct LibraryEntryRow: View {
    let entry: LibraryEntry
    let isSelected: Bool
    let obsidianVaultName: String
    let vaultRootPath: String
    var onRename: ((String) -> Void)?

    @State private var isEditing = false
    @State private var editText = ""
    @State private var isHovered = false

    var body: some View {
        ZStack(alignment: .leading) {
            // Background
            RoundedRectangle(cornerRadius: 6)
                .fill(rowBackground)

            // Selected left stripe
            if isSelected {
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.accent1)
                        .frame(width: 3)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Row content
            HStack(alignment: .top, spacing: 8) {
                // Type icon
                Image(systemName: typeIconName)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.fg2)
                    .frame(width: 18, alignment: .center)
                    .padding(.top, 4)

                // Center content
                VStack(alignment: .leading, spacing: 4) {
                    // Recording name (editable via pencil icon or double-click)
                    if isEditing {
                        TextField(entry.displayName, text: $editText)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.fg1)
                            .textFieldStyle(.plain)
                            .onSubmit {
                                commitEdit()
                            }
                            .onExitCommand {
                                isEditing = false
                            }
                    } else {
                        HStack(spacing: 4) {
                            Text(entry.displayName)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.fg1)
                                .lineLimit(1)

                            if isHovered {
                                Button {
                                    editText = entry.name ?? ""
                                    isEditing = true
                                } label: {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color.fg2)
                                }
                                .buttonStyle(.plain)
                                .help("Rename")
                            }
                        }
                    }

                    // Metadata line
                    Text(metadataLine)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fg2)
                        .lineLimit(1)

                    // First-line preview
                    Text(entry.firstLinePreview?.isEmpty == false ? entry.firstLinePreview! : "No transcript")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fg3)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer(minLength: 0)

                // Right side icons
                VStack(alignment: .trailing, spacing: 4) {
                    // Obsidian icon button
                    if !obsidianVaultName.isEmpty && entry.isFinalized {
                        Button {
                            if let url = obsidianURL(
                                for: entry.filePath,
                                vaultRoot: vaultRootPath,
                                vaultName: obsidianVaultName
                            ) {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            Image(systemName: "link")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.accent1)
                        }
                        .buttonStyle(.plain)
                        .help("Open in Obsidian")
                    }

                    // Missing file badge
                    if !FileManager.default.fileExists(atPath: entry.filePath) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.recordRed)
                            .help("File has been moved or deleted")
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(height: 72)
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Show in Finder") {
                NSWorkspace.shared.selectFile(
                    entry.filePath,
                    inFileViewerRootedAtPath: URL(fileURLWithPath: entry.filePath)
                        .deletingLastPathComponent().path
                )
            }
        }
    }

    // MARK: - Helpers

    private var rowBackground: Color {
        if isSelected {
            return Color.bg1.opacity(0.85)
        } else if isHovered {
            return Color.bg1.opacity(0.4)
        }
        return Color.clear
    }

    private var typeIconName: String {
        if !entry.isFinalized {
            return "exclamationmark.circle"
        }
        switch entry.sessionType {
        case .callCapture:
            return "phone.fill"
        case .voiceMemo:
            return "mic.fill"
        }
    }

    private var metadataLine: String {
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "MMM d, yyyy"
        let dateStr = dateFmt.string(from: entry.startDate)
        let durationStr = formatDuration(entry.duration)
        return "\(dateStr) . \(durationStr) . \(entry.sourceApp)"
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            if m > 0 {
                return "\(h)h \(m)m"
            }
            return "\(h)h"
        } else if m > 0 {
            if s > 0 {
                return "\(m)m \(s)s"
            }
            return "\(m)m"
        }
        return "\(s)s"
    }

    private func commitEdit() {
        let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            onRename?(trimmed)
        }
        isEditing = false
    }
}
