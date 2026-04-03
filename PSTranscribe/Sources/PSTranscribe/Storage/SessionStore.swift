import Foundation
import os

struct SessionCheckpoint: Codable {
    let sessionId: String          // datetime-based identifier
    let sessionStartTime: Date
    let transcriptPath: String     // absolute path to transcript file
    var completedSteps: [String]   // ["transcript_written", "frontmatter_done", "diarization_done"]
    var isFinalized: Bool
}

actor SessionStore {
    private let sessionsDirectory: URL
    private var currentFile: URL?
    private var fileHandle: FileHandle?
    private var currentSessionId: String?
    private let encoder = JSONEncoder()
    private let log = Logger(subsystem: "com.pstranscribe.app", category: "SessionStore")

    private var checkpointsDirectory: URL {
        sessionsDirectory.appendingPathComponent(".checkpoints", isDirectory: true)
    }

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        sessionsDirectory = appSupport.appendingPathComponent("PSTranscribe/sessions", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: sessionsDirectory, withIntermediateDirectories: true)
            try FileManager.default.setAttributes(
                [.posixPermissions: NSNumber(value: 0o700)],
                ofItemAtPath: sessionsDirectory.path
            )
        } catch {
            // Using print here since log is not yet available in init before self is fully initialized
            // The Logger property is set after sessionsDirectory, but we can still log via a local logger
            let initLog = Logger(subsystem: "com.pstranscribe.app", category: "SessionStore")
            initLog.error("Failed to create sessions directory: \(error.localizedDescription, privacy: .public)")
            // Fatal for SessionStore -- subsequent writes will fail
        }

        encoder.dateEncodingStrategy = .iso8601
    }

    private func ensureCheckpointsDirectory() {
        do {
            try FileManager.default.createDirectory(at: checkpointsDirectory, withIntermediateDirectories: true)
            try FileManager.default.setAttributes(
                [.posixPermissions: NSNumber(value: 0o700)],
                ofItemAtPath: checkpointsDirectory.path
            )
        } catch {
            log.error("Failed to create checkpoints directory: \(error.localizedDescription, privacy: .public)")
        }
    }

    func writeCheckpoint(_ checkpoint: SessionCheckpoint) {
        let filename = "\(checkpoint.sessionId).checkpoint.json"
        let path = checkpointsDirectory.appendingPathComponent(filename)
        do {
            let data = try JSONEncoder().encode(checkpoint)
            try data.write(to: path)
            try FileManager.default.setAttributes(
                [.posixPermissions: NSNumber(value: 0o600)],
                ofItemAtPath: path.path
            )
        } catch {
            log.error("Failed to write checkpoint: \(error.localizedDescription, privacy: .public)")
            // Non-fatal -- crash recovery is best-effort
        }
    }

    func updateCheckpoint(sessionId: String, step: String) {
        let filename = "\(sessionId).checkpoint.json"
        let path = checkpointsDirectory.appendingPathComponent(filename)
        do {
            let data = try Data(contentsOf: path)
            var checkpoint = try JSONDecoder().decode(SessionCheckpoint.self, from: data)
            checkpoint.completedSteps.append(step)
            let updated = try JSONEncoder().encode(checkpoint)
            try updated.write(to: path)
        } catch {
            log.error("Failed to update checkpoint for \(sessionId, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    func finalizeCheckpoint(sessionId: String) {
        let filename = "\(sessionId).checkpoint.json"
        let path = checkpointsDirectory.appendingPathComponent(filename)
        do {
            try FileManager.default.removeItem(at: path)
        } catch {
            log.warning("Failed to remove checkpoint \(sessionId, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    func scanIncompleteCheckpoints() -> [SessionCheckpoint] {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: checkpointsDirectory, includingPropertiesForKeys: nil)
            return files.filter { $0.pathExtension == "json" }.compactMap { file in
                do {
                    let data = try Data(contentsOf: file)
                    let checkpoint = try JSONDecoder().decode(SessionCheckpoint.self, from: data)
                    return checkpoint.isFinalized ? nil : checkpoint
                } catch {
                    log.error("Failed to read checkpoint \(file.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
                    return nil
                }
            }
        } catch {
            log.error("Failed to scan checkpoints directory: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    func startSession() throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let sessionId = formatter.string(from: Date())
        let filename = "session_\(sessionId).jsonl"
        currentFile = sessionsDirectory.appendingPathComponent(filename)
        currentSessionId = sessionId

        FileManager.default.createFile(atPath: currentFile!.path, contents: nil)
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: 0o600)],
            ofItemAtPath: currentFile!.path
        )
        do {
            fileHandle = try FileHandle(forWritingTo: currentFile!)
        } catch {
            log.error("Failed to open session file for writing: \(error.localizedDescription, privacy: .public)")
            throw error
        }

        // Write initial checkpoint for crash recovery
        ensureCheckpointsDirectory()
        let checkpoint = SessionCheckpoint(
            sessionId: sessionId,
            sessionStartTime: Date(),
            transcriptPath: currentFile!.path,
            completedSteps: [],
            isFinalized: false
        )
        writeCheckpoint(checkpoint)
    }

    func appendRecord(_ record: SessionRecord) {
        guard let fileHandle else { return }

        do {
            let data = try encoder.encode(record)
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            fileHandle.write("\n".data(using: .utf8)!)
        } catch {
            print("SessionStore: failed to write record: \(error)")
        }
    }

    func endSession() {
        try? fileHandle?.close()
        fileHandle = nil
        currentFile = nil
        currentSessionId = nil
    }

    var sessionsDirectoryURL: URL { sessionsDirectory }

    /// Returns the session ID for the current active session (nil if no session is active).
    var activeSessionId: String? { currentSessionId }
}
