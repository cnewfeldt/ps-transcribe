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

    @Test(.disabled("Pending Plan 18-03 -- DictationLogger.discardSession()"))
    func discardSessionDeletesFile() async throws {
        let dir = tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let logger = DictationLogger()
        try await logger.startSession(folderPath: dir.path)
        // Wave 1 ships discardSession(); after GREEN this asserts the file is gone.
        // await logger.discardSession()
        // let contents = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        // #expect(contents.isEmpty)
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-03 -- discardSession idempotency"))
    func discardSessionIsIdempotent() async throws {
        let logger = DictationLogger()
        // await logger.discardSession()
        // await logger.discardSession()  // must not crash, must not throw
        _ = logger
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-03 -- hasActiveSession getter"))
    func hasActiveSessionReflectsLifecycle() async throws {
        let dir = tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let logger = DictationLogger()
        // #expect(await logger.hasActiveSession == false)
        try await logger.startSession(folderPath: dir.path)
        // #expect(await logger.hasActiveSession == true)
        // await logger.discardSession()
        // #expect(await logger.hasActiveSession == false)
        _ = await logger.endSession()
        #expect(Bool(true))
    }
}
