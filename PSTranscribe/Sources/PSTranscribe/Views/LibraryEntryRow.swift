import SwiftUI
import AppKit

struct LibraryEntryRow: View {
    let entry: LibraryEntry
    let isSelected: Bool
    var onRename: ((String) -> Void)?
    var onDelete: (() -> Void)?
    var isNotionConfigured: Bool = false
    var onSendToNotion: (() -> Void)?
    var obsidianURL: URL? = nil
    var isObsidianAvailable: Bool = false
    @State private var fileExists: Bool = true

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.x10) {
            iconChip

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.displayName)
                    .font(.chronicleSans(12.5, weight: .semibold))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)

                Text(metadataLine)
                    .font(.chronicleMono(11))
                    .foregroundStyle(Color.inkFaint)
                    .lineLimit(1)

                Text(previewText)
                    .font(.chronicleSans(11.5))
                    .foregroundStyle(
                        previewText == "No transcript" ? Color.inkFaint : Color.inkMuted
                    )
                    .italic(previewText == "No transcript")
                    .opacity(previewText == "No transcript" ? 0.55 : 0.85)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 0)

            statusBadge
        }
        .padding(.horizontal, Spacing.x14)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: Radius.button)
                .fill(isSelected ? Color.paper : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.button)
                        .stroke(Color.rule, lineWidth: isSelected ? 0.5 : 0)
                )
                .shadow(
                    color: isSelected ? Color(red: 30/255, green: 30/255, blue: 28/255).opacity(0.08) : .clear,
                    radius: 3, x: 0, y: 1
                )
        )
        .onAppear {
            guard !entry.filePath.isEmpty else { fileExists = true; return }
            fileExists = FileManager.default.fileExists(atPath: entry.filePath)
        }
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
            Button("Open in Obsidian") {
                if let url = obsidianURL {
                    NSWorkspace.shared.open(url)
                }
            }
            .disabled(!isObsidianAvailable || obsidianURL == nil)
            .help(isObsidianAvailable ? "" : "Configure vault paths in Settings")

            if isNotionConfigured {
                Divider()
                if entry.notionPageURL == nil {
                    Button("Send to Notion...") {
                        onSendToNotion?()
                    }
                } else {
                    Button("Open in Notion") {
                        if let urlString = entry.notionPageURL,
                           let url = URL(string: urlString) {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    Button("Resend to Notion...") {
                        onSendToNotion?()
                    }
                }
            }

            Divider()
            Button("Delete", role: .destructive) {
                onDelete?()
            }
        }
    }

    // MARK: - Helpers

    private var iconChip: some View {
        ZStack {
            Circle()
                .fill(Color.paperSoft)
            Image(systemName: typeIconName)
                .font(.system(size: 10))
                .foregroundStyle(Color.inkMuted)
        }
        .frame(width: 22, height: 22)
        .padding(.top, 2)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if !entry.isFinalized {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
                .foregroundStyle(Color.yellow.opacity(0.85))
                .help("Session was interrupted -- transcript may be incomplete")
                .padding(.top, 4)
        } else if !fileExists && !entry.filePath.isEmpty {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
                .foregroundStyle(Color.recRed)
                .help("File has been moved or deleted")
                .padding(.top, 4)
        }
    }

    private var previewText: String {
        let p = entry.firstLinePreview?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return p.isEmpty ? "No transcript" : p
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

    /// "HH:MM · Nm" style per spec (e.g. "10:24 · 48m").
    private var metadataLine: String {
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm"
        let timeStr = timeFmt.string(from: entry.startDate)
        let durationStr = formatDuration(entry.duration)
        return "\(timeStr) · \(durationStr)"
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
