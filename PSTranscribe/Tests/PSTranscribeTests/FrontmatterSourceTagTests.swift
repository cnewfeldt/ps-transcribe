// FrontmatterSourceTagTests
// Phase 24 (NYQUIST-04) -- Phase 8 REBR-03 closure: finalized transcript frontmatter
// contains the rebrand source tag '- source/pstranscribe' and DOES NOT contain the
// legacy 'source/tome' tag. Verifies TranscriptLogger.swift:151.
//
// End-to-end round-trip: startSession + append + endSession + finalizeFrontmatter
// in a UUID-scoped tempDir; defer cleanup. Pattern lifted from DictationLoggerTests.swift.

import Testing
import Foundation
@testable import PSTranscribe

@Suite("FrontmatterSourceTagTests", .serialized)
struct FrontmatterSourceTagTests {

    private func tempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FrontmatterSourceTagTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test func finalizedFrontmatterContainsSourcePstranscribe() async throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let logger = TranscriptLogger()
        // TranscriptLogger is an `actor`; startSession is `throws` (sync inside the actor),
        // append is sync inside the actor, endSession() returns Void, and finalizeFrontmatter()
        // returns the finalized file URL. The frontmatter is written by startSession at line 137-152
        // of TranscriptLogger.swift -- including the `- source/pstranscribe` tag at line 151.
        try await logger.startSession(
            sourceApp: "Teams",
            vaultPath: dir.path,
            sessionType: .callCapture
        )
        await logger.append(speaker: "You", text: "test utterance", timestamp: Date())
        await logger.endSession()
        let url = await logger.finalizeFrontmatter()

        guard let url else {
            Issue.record("finalizeFrontmatter returned nil")
            return
        }
        let contents = try String(contentsOf: url, encoding: .utf8)

        // REBR-03 invariant -- both halves of the rebrand:
        #expect(contents.contains("- source/pstranscribe"),
                "Finalized frontmatter must contain '- source/pstranscribe' rebrand tag")
        #expect(!contents.contains("source/tome"),
                "Finalized frontmatter must NOT contain legacy 'source/tome' tag")
    }
}
