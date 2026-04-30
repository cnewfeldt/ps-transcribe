import Foundation
import os

private let lfwLog = Logger(subsystem: "com.pstranscribe.app", category: "LocalFileWriter")

enum LocalFileWriterError: LocalizedError {
    case folderPathInvalid(String)
    case cannotCreateFile(String)
    var errorDescription: String? {
        switch self {
        case .folderPathInvalid(let p): return "Local File root invalid: \(p)"
        case .cannotCreateFile(let p):  return "Cannot create file at \(p)"
        }
    }
}

/// Writes content to `localFileRoot/{Meeting|Memo|Dictation}/`. Format per content type
/// (D-05): Meeting/Memo include YAML frontmatter (matches v1.0 TranscriptLogger output);
/// Dictation is plain markdown with NO frontmatter (matches Phase 16 DictationLogger output).
/// The subfolder identifies session-type; no `session-type:` frontmatter is added in
/// Local File files (D-05).
///
/// Subfolders (`Meeting/`, `Memo/`, `Dictation/`) are created lazily on first write
/// per content type (D-06).
actor LocalFileWriter {

    init() {}

    /// Single-shot post-session write. Used for:
    ///   - Dictation: post-session full transcript write (fallback when streaming via
    ///     DictationLogger wasn't used or failed; the streaming path is the primary
    ///     route in v18.1).
    ///   - Future: voice-memo / meeting paths if they migrate off the streaming
    ///     TranscriptLogger.
    /// In v18.1, meetings and voice memos are streamed by TranscriptLogger and skip
    /// this writer (callers pass `skipLocalFile: true` to `SaveDestinations.save` to
    /// prevent a duplicate write).
    /// Returns the final on-disk URL.
    func write(content: String, metadata: SaveMetadata, rootPath: String) async throws -> URL {
        let directory = try validatedFolderPath(rootPath)
        let subfolder = directory.appendingPathComponent(metadata.sessionType.localFileSubfolder, isDirectory: true)
        try FileManager.default.createDirectory(at: subfolder, withIntermediateDirectories: true)

        switch metadata.sessionType {
        case .dictation:
            return try writeDictationPlainMarkdown(content: content, metadata: metadata, in: subfolder)
        case .callCapture, .voiceMemo:
            return try writeMeetingOrMemoFrontmatter(content: content, metadata: metadata, in: subfolder)
        }
    }

    // MARK: - Dictation: plain markdown (D-05 / Phase 16 D-01)

    private func writeDictationPlainMarkdown(
        content: String,
        metadata: SaveMetadata,
        in directory: URL
    ) throws -> URL {
        // Filename matches DictationLogger pattern: yyyy-MM-dd HH-mm-ss-SSS Dictation.md
        let fileFmt = DateFormatter()
        fileFmt.locale = Locale(identifier: "en_US_POSIX")
        fileFmt.dateFormat = "yyyy-MM-dd HH-mm-ss-SSS"
        let filename = "\(fileFmt.string(from: metadata.startDate)) Dictation.md"
        let url = directory.appendingPathComponent(filename)

        let headerFmt = DateFormatter()
        headerFmt.locale = Locale(identifier: "en_US_POSIX")
        headerFmt.dateFormat = "yyyy-MM-dd HH:mm"
        let header = "# Dictation -- \(headerFmt.string(from: metadata.startDate))\n\n"
        let body = header + content + (content.hasSuffix("\n") ? "" : "\n")

        guard FileManager.default.createFile(atPath: url.path, contents: body.data(using: .utf8)) else {
            throw LocalFileWriterError.cannotCreateFile(url.path)
        }
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: 0o600)],
            ofItemAtPath: url.path
        )
        return url
    }

    // MARK: - Meeting / Memo: YAML frontmatter (D-05; matches TranscriptLogger format for parity)

    private func writeMeetingOrMemoFrontmatter(
        content: String,
        metadata: SaveMetadata,
        in directory: URL
    ) throws -> URL {
        let fileFmt = DateFormatter()
        fileFmt.locale = Locale(identifier: "en_US_POSIX")
        fileFmt.dateFormat = "yyyy-MM-dd HH-mm-ss"

        let isVoiceMemo = metadata.sessionType == .voiceMemo
        let fileLabel = isVoiceMemo ? "Voice Memo" : "Call Recording"
        let noteType = isVoiceMemo ? "fleeting" : "meeting"
        let logTag = isVoiceMemo ? "log/voice" : "log/meeting"
        let sourceTag = isVoiceMemo ? "source/voice" : "source/meeting"

        let dateFmt = DateFormatter(); dateFmt.dateFormat = "yyyy-MM-dd"
        let timeFmt = DateFormatter(); timeFmt.dateFormat = "HH:mm"
        let dateStr = dateFmt.string(from: metadata.startDate)
        let timeStr = timeFmt.string(from: metadata.startDate)
        let durationStr = formatDuration(metadata.duration)

        let safeName = sanitizedFilenameComponent(metadata.title)
        let nameSuffix = safeName.isEmpty ? fileLabel : safeName
        let filename = "\(fileFmt.string(from: metadata.startDate)) \(nameSuffix).md"
        let url = directory.appendingPathComponent(filename)

        let frontmatter = """
        ---
        type: \(noteType)
        created: "\(dateStr)"
        time: "\(timeStr)"
        duration: "\(durationStr)"
        source_app: "\(metadata.sourceApp)"
        source_file: "\(filename)"
        attendees: \(speakerArrayString(metadata.speakers))
        context: ""
        tags:
          - \(logTag)
          - status/inbox
          - \(sourceTag)
          - source/pstranscribe
        ---

        # \(fileLabel) -- \(dateStr) \(timeStr)


        ## Transcript

        \(content)
        """

        guard FileManager.default.createFile(atPath: url.path, contents: frontmatter.data(using: .utf8)) else {
            throw LocalFileWriterError.cannotCreateFile(url.path)
        }
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: 0o600)],
            ofItemAtPath: url.path
        )
        return url
    }

    // MARK: - Helpers (mirror TranscriptLogger conventions)

    private func validatedFolderPath(_ rawPath: String) throws -> URL {
        let expanded = NSString(string: rawPath).expandingTildeInPath
        guard !expanded.isEmpty, !expanded.contains("\0") else {
            lfwLog.error("Local File root rejected: empty or null pattern")
            throw LocalFileWriterError.folderPathInvalid(rawPath)
        }
        // Reject `..` only when it appears as a discrete path component (real traversal),
        // not as a substring inside a legitimate filename like `My..Project` (WR-03).
        // We check pathComponents BEFORE standardization because `.standardized`
        // collapses `..` segments away (e.g. /tmp/foo/../bar -> /tmp/bar).
        let preStdURL = URL(fileURLWithPath: expanded)
        if preStdURL.pathComponents.contains("..") {
            lfwLog.error("Local File root rejected: traversal pattern in path components")
            throw LocalFileWriterError.folderPathInvalid(rawPath)
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

    private func speakerArrayString(_ speakers: [String]) -> String {
        if speakers.isEmpty { return "[]" }
        let escaped = speakers.map { "\"\($0)\"" }.joined(separator: ", ")
        return "[\(escaped)]"
    }
}
