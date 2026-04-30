import Foundation
import os

private let obsLog = Logger(subsystem: "com.pstranscribe.app", category: "ObsidianWriter")

enum ObsidianWriterError: LocalizedError {
    case folderPathInvalid(String)
    case cannotCreateFile(String)
    var errorDescription: String? {
        switch self {
        case .folderPathInvalid(let p): return "Obsidian folder invalid: \(p)"
        case .cannotCreateFile(let p):  return "Cannot create file at \(p)"
        }
    }
}

/// Writes content to a single Obsidian folder with `session-type:` YAML frontmatter
/// (D-07 / D-08 / D-11). All session types (meeting / memo / dictation) land in the
/// same folder; the type is encoded in:
///   1. YAML frontmatter `session-type:` (DataView-queryable)
///   2. Filename type-label (collision avoidance, RESEARCH.md §5)
///
/// Filename pattern: `YYYY-MM-DD HH-mm-ss-SSS <Label> <auto-name>.md`
/// where <Label> is "Meeting" / "Memo" / "Dictation" and <auto-name> may be empty
/// (then trailing space is trimmed).
///
/// Frontmatter format is INTENTIONALLY simpler than TranscriptLogger's (no source_file,
/// no context section): the Obsidian writer is a single-shot post-session write, not
/// a streaming session.
actor ObsidianWriter {

    init() {}

    func write(content: String, metadata: SaveMetadata, folderPath: String) async throws -> URL {
        let directory = try validatedFolderPath(folderPath)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let fileFmt = DateFormatter()
        fileFmt.locale = Locale(identifier: "en_US_POSIX")
        fileFmt.dateFormat = "yyyy-MM-dd HH-mm-ss-SSS"
        let typeLabel = metadata.sessionType.obsidianFilenameLabel
        let safeName = sanitizedFilenameComponent(metadata.title)
        let nameSuffix = safeName.isEmpty ? "" : " \(safeName)"
        let filename = "\(fileFmt.string(from: metadata.startDate)) \(typeLabel)\(nameSuffix).md"
        let url = directory.appendingPathComponent(filename)

        let dateFmt = DateFormatter(); dateFmt.dateFormat = "yyyy-MM-dd"
        let timeFmt = DateFormatter(); timeFmt.dateFormat = "HH:mm"
        let dateStr = dateFmt.string(from: metadata.startDate)
        let timeStr = timeFmt.string(from: metadata.startDate)
        let durationStr = formatDuration(metadata.duration)
        let sessionTypeValue = metadata.sessionType.obsidianFrontmatterValue

        let body = """
        ---
        session-type: \(sessionTypeValue)
        created: "\(dateStr)"
        time: "\(timeStr)"
        duration: "\(durationStr)"
        source_app: "\(metadata.sourceApp)"
        tags:
          - status/inbox
        ---

        # \(typeLabel) -- \(dateStr) \(timeStr)

        \(content)
        """

        guard FileManager.default.createFile(atPath: url.path, contents: body.data(using: .utf8)) else {
            throw ObsidianWriterError.cannotCreateFile(url.path)
        }
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: 0o600)],
            ofItemAtPath: url.path
        )
        return url
    }

    private func validatedFolderPath(_ rawPath: String) throws -> URL {
        let expanded = NSString(string: rawPath).expandingTildeInPath
        guard !expanded.isEmpty, !expanded.contains("\0") else {
            obsLog.error("Obsidian folder rejected: empty or null pattern")
            throw ObsidianWriterError.folderPathInvalid(rawPath)
        }
        // Reject `..` only when it appears as a discrete path component (real traversal),
        // not as a substring inside a legitimate filename like `My..Project` (WR-03).
        // We check pathComponents BEFORE standardization because `.standardized`
        // collapses `..` segments away (e.g. /tmp/foo/../bar -> /tmp/bar).
        let preStdURL = URL(fileURLWithPath: expanded)
        if preStdURL.pathComponents.contains("..") {
            obsLog.error("Obsidian folder rejected: traversal pattern in path components")
            throw ObsidianWriterError.folderPathInvalid(rawPath)
        }
        return preStdURL.resolvingSymlinksInPath().standardized
    }

    private func sanitizedFilenameComponent(_ input: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: " -_."))
        let filtered = String(input.unicodeScalars.filter { allowed.contains($0) })
        return String(filtered.trimmingCharacters(in: .whitespaces).prefix(50))
    }

    private func formatDuration(_ d: TimeInterval) -> String {
        let total = max(0, Int(d))
        let mm = total / 60
        let ss = total % 60
        return String(format: "%02d:%02d", mm, ss)
    }
}
