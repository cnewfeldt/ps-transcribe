import Foundation
import os

private let dictLog = Logger(subsystem: "com.pstranscribe.app", category: "DictationLogger")

/// Errors thrown by `DictationLogger`. Conforms to `LocalizedError` so the UI
/// layer (Phase 18) can surface human-readable messages.
enum DictationLoggerError: LocalizedError {
    case cannotCreateFile(String)
    case folderPathInvalid(String)

    var errorDescription: String? {
        switch self {
        case .cannotCreateFile(let p):  return "Cannot create dictation file at \(p)"
        case .folderPathInvalid(let p): return "Dictation folder path invalid: \(p)"
        }
    }
}

/// Plain-markdown writer for hotkey dictation sessions.
///
/// Single-purpose by design (Phase 16 D-01 / D-02):
///   - NO YAML frontmatter
///   - NO diarization patches
///   - NO speaker tracking beyond the static "**You**" label
///   - NO post-session finalization rewrite
///
/// Append-only during the session; atomic file close on `endSession`.
/// Filenames carry a millisecond suffix to avoid collisions on rapid sessions
/// (FOLDER-03 / Pitfall #9).
actor DictationLogger {
    private var fileHandle: FileHandle?
    private var currentFilePath: URL?
    private var sessionStartTime: Date?

    init() {}

    /// Begin a dictation session. Validates the folder path, creates the directory if absent,
    /// generates a collision-safe filename, writes the markdown header, and opens the file
    /// handle for append. Throws if the path is invalid or the file cannot be created.
    func startSession(folderPath: String) throws {
        let directory = try validatedFolderPath(folderPath)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let now = Date()
        sessionStartTime = now

        // Filename: yyyy-MM-dd HH-mm-ss-SSS Dictation.md  (millisecond suffix avoids Pitfall #9)
        let fileFmt = DateFormatter()
        fileFmt.locale = Locale(identifier: "en_US_POSIX")
        fileFmt.dateFormat = "yyyy-MM-dd HH-mm-ss-SSS"
        let filename = "\(fileFmt.string(from: now)) Dictation.md"
        let url = directory.appendingPathComponent(filename)
        currentFilePath = url

        // Header: "# Dictation -- yyyy-MM-dd HH:mm\n\n"  (NO YAML frontmatter, ever -- D-02)
        let headerFmt = DateFormatter()
        headerFmt.locale = Locale(identifier: "en_US_POSIX")
        headerFmt.dateFormat = "yyyy-MM-dd HH:mm"
        let header = "# Dictation -- \(headerFmt.string(from: now))\n\n"

        guard FileManager.default.createFile(atPath: url.path, contents: header.data(using: .utf8)) else {
            sessionStartTime = nil
            currentFilePath = nil
            throw DictationLoggerError.cannotCreateFile(url.path)
        }
        // Owner read/write only (mirrors TranscriptLogger pattern; threat model V8 in RESEARCH.md).
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: 0o600)],
            ofItemAtPath: url.path
        )
        fileHandle = try FileHandle(forWritingTo: url)
        fileHandle?.seekToEndOfFile()
    }

    /// Append a single utterance to the current session. No-op if no session is active.
    /// Phase 16 supplies this API; Phase 18 wires it to the dictation transcription stream.
    func append(text: String, timestamp: Date) {
        guard let fileHandle, let start = sessionStartTime else { return }
        let offset = max(0, Int(timestamp.timeIntervalSince(start)))
        let hh = offset / 3600
        let mm = (offset % 3600) / 60
        let ss = offset % 60
        let line = "**You** (\(String(format: "%02d:%02d:%02d", hh, mm, ss)))\n\(text)\n\n"
        if let data = line.data(using: .utf8) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
        }
    }

    /// Close the file handle, return the final URL, and clear session state.
    /// Idempotent -- calling after a closed session returns nil.
    func endSession() -> URL? {
        try? fileHandle?.close()
        fileHandle = nil
        let saved = currentFilePath
        currentFilePath = nil
        sessionStartTime = nil
        return saved
    }

    // MARK: - Path validation (mirrors TranscriptLogger.validatedVaultPath, lines 40-50)

    /// Validates and canonicalizes a user-supplied folder path. Rejects paths containing
    /// `..` or null bytes BEFORE feeding them to URL construction (defense-in-depth).
    private func validatedFolderPath(_ rawPath: String) throws -> URL {
        let expanded = NSString(string: rawPath).expandingTildeInPath
        guard !expanded.isEmpty,
              !expanded.contains("\0"),
              !expanded.contains("..") else {
            dictLog.error("Invalid dictation folder path rejected: contains traversal pattern or null byte")
            throw DictationLoggerError.folderPathInvalid(rawPath)
        }
        return URL(fileURLWithPath: expanded).resolvingSymlinksInPath().standardized
    }
}
