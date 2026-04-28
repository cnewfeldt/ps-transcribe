import Testing
import Foundation
@testable import PSTranscribe

@Suite("DictationLoggerDiscardTests")
struct DictationLoggerDiscardTests {

    private func tmpDir() -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("DictDiscard-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test func discardSessionDeletesFile() async throws {
        let dir = tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let logger = DictationLogger()
        try await logger.startSession(folderPath: dir.path)

        // Sanity: file exists after startSession
        let beforeContents = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        #expect(beforeContents.count == 1, "startSession should create exactly one file")

        await logger.discardSession()

        let afterContents = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        #expect(afterContents.isEmpty, "discardSession should remove the file")
        #expect(await logger.hasActiveSession == false)
    }

    @Test func discardSessionIsIdempotent() async throws {
        let dir = tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let logger = DictationLogger()
        // No active session -- discard must be a safe no-op.
        await logger.discardSession()
        await logger.discardSession()

        // After endSession (file persists), discard must be a safe no-op as well.
        try await logger.startSession(folderPath: dir.path)
        _ = await logger.endSession()
        await logger.discardSession()

        // The file from endSession should still exist (we ended, didn't discard).
        let contents = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        #expect(contents.count == 1, "endSession-then-discard should not delete the ended file")
    }

    @Test func hasActiveSessionReflectsLifecycle() async throws {
        let dir = tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let logger = DictationLogger()
        #expect(await logger.hasActiveSession == false, "Fresh logger has no active session")

        try await logger.startSession(folderPath: dir.path)
        #expect(await logger.hasActiveSession == true, "After startSession, hasActiveSession is true")

        await logger.discardSession()
        #expect(await logger.hasActiveSession == false, "After discardSession, hasActiveSession is false")

        // Round-trip: re-open and end normally.
        try await logger.startSession(folderPath: dir.path)
        #expect(await logger.hasActiveSession == true)
        _ = await logger.endSession()
        #expect(await logger.hasActiveSession == false, "After endSession, hasActiveSession is false")
    }
}
