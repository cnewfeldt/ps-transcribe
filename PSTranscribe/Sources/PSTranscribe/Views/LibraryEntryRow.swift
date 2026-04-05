import SwiftUI
import AppKit

struct LibraryEntryRow: View {
    let entry: LibraryEntry
    let isSelected: Bool
    var onRename: ((String) -> Void)?
    var onDelete: (() -> Void)?

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
                    // Recording name (edit via right-click -> Rename)
                    Text(entry.displayName)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fg1)
                        .lineLimit(1)

                    // Metadata line
                    Text(metadataLine)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fg2)
                        .lineLimit(1)

                    // Clickable file path (SESS-04)
                    if !entry.filePath.isEmpty {
                        Text(URL(fileURLWithPath: entry.filePath).lastPathComponent)
                            .font(.system(size: 10))
                            .foregroundStyle(Color.accent1.opacity(0.7))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .onTapGesture {
                                NSWorkspace.shared.selectFile(
                                    entry.filePath,
                                    inFileViewerRootedAtPath: URL(fileURLWithPath: entry.filePath)
                                        .deletingLastPathComponent().path
                                )
                            }
                            .help(entry.filePath)
                    }

                    // First-line preview
                    Text(entry.firstLinePreview?.isEmpty == false ? entry.firstLinePreview! : "No transcript")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fg3)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer(minLength: 0)

                // Missing file badge
                if !FileManager.default.fileExists(atPath: entry.filePath) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.recordRed)
                        .help("File has been moved or deleted")
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(height: 72)
        .contextMenu {
            Button("Rename...") {
                Self.presentRenameDialog(
                    currentName: entry.name ?? entry.displayName,
                    onConfirm: { newName in
                        onRename?(newName)
                    }
                )
            }
            Button("Show in Finder") {
                NSWorkspace.shared.selectFile(
                    entry.filePath,
                    inFileViewerRootedAtPath: URL(fileURLWithPath: entry.filePath)
                        .deletingLastPathComponent().path
                )
            }
            Divider()
            Button("Delete", role: .destructive) {
                onDelete?()
            }
        }
    }

    // MARK: - Helpers

    private var rowBackground: Color {
        if isSelected {
            return Color.bg1.opacity(0.85)
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

    // MARK: - Rename Dialog

    /// Presents a native NSAlert with an accessory text field for renaming a recording.
    /// Calls `onConfirm` with the trimmed new name if the user clicks Rename and the name is non-empty.
    @MainActor
    fileprivate static func presentRenameDialog(currentName: String, onConfirm: @escaping (String) -> Void) {
        let alert = NSAlert()
        alert.messageText = "Rename Recording"
        alert.informativeText = "Enter a new name for this recording. The transcript file on disk will be renamed to match."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 24))
        textField.stringValue = currentName
        textField.placeholderString = "Recording name"
        textField.lineBreakMode = .byTruncatingTail
        textField.cell?.usesSingleLineMode = true
        alert.accessoryView = textField

        // Focus + select all on open so the user can type-to-replace.
        DispatchQueue.main.async {
            alert.window.initialFirstResponder = textField
            textField.selectText(nil)
        }

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }

        let trimmed = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != currentName else { return }
        onConfirm(trimmed)
    }
}
