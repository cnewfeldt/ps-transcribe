import Foundation
import os

actor SessionStore {
    private let sessionsDirectory: URL
    private var currentFile: URL?
    private var fileHandle: FileHandle?
    private let encoder = JSONEncoder()
    private let log = Logger(subsystem: "com.pstranscribe.app", category: "SessionStore")

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

    func startSession() throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "session_\(formatter.string(from: Date())).jsonl"
        currentFile = sessionsDirectory.appendingPathComponent(filename)

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
    }

    var sessionsDirectoryURL: URL { sessionsDirectory }
}
