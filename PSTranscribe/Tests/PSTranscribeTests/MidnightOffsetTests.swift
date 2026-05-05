// MidnightOffsetTests
// Phase 24 (NYQUIST-02) -- Phase 02 STAB-02: midnight-cross offset math.
//
// Asserts that TranscriptLogger.append produces session-relative HH:MM:SS
// offsets that remain non-negative and in temporal order across a wide time
// gap (mimics midnight crossing via Date arithmetic).
//
// Lifted analog: DictationLoggerTests.appendComputesSessionRelativeOffset
// (which asserts ordering rather than exact values, the same approach here).

import Testing
import Foundation
@testable import PSTranscribe

@Suite("MidnightOffsetTests", .serialized)
struct MidnightOffsetTests {

    private func tempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MidnightOffsetTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test func midnightBoundaryProducesNonNegativeOrderedOffsets() async throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let logger = TranscriptLogger()
        try await logger.startSession(sourceApp: "Test", vaultPath: dir.path)
        // Allow startSession's internal sessionStartTime to be set.
        try await Task.sleep(for: .milliseconds(50))
        let baseline = Date().addingTimeInterval(-0.05)
        // Two utterances 60s apart -- the gap mimics a midnight crossing without
        // requiring the test to actually run at midnight. The TranscriptLogger
        // uses session-relative offsets (max(0, ...) at TranscriptLogger.swift:203),
        // so any clock-time arithmetic that would have gone negative pre-fix is
        // clamped at 0.
        await logger.append(speaker: "You", text: "before-midnight", timestamp: baseline.addingTimeInterval(5))
        await logger.append(speaker: "You", text: "after-midnight",  timestamp: baseline.addingTimeInterval(65))
        await logger.endSession()
        let url = await logger.finalizeFrontmatter()

        guard let url else { Issue.record("finalizeFrontmatter returned nil"); return }
        let contents = try String(contentsOf: url, encoding: .utf8)

        // Both utterances present + ordered
        guard let firstIdx = contents.range(of: "before-midnight")?.lowerBound,
              let secondIdx = contents.range(of: "after-midnight")?.lowerBound else {
            Issue.record("Could not find both utterances in transcript")
            return
        }
        #expect(firstIdx < secondIdx, "Utterances must be in temporal order")

        // Offsets are HH:MM:SS shape -- assert presence of at least one such pattern
        #expect(contents.range(of: #"\(\d{2}:\d{2}:\d{2}\)"#, options: .regularExpression) != nil,
                "Transcript must contain at least one (HH:MM:SS) offset")
        // No negative offsets: search for `(-` immediately followed by digits inside offset parens
        #expect(contents.range(of: #"\(-\d"#, options: .regularExpression) == nil,
                "Offsets must be non-negative (max(0, ...) guard at TranscriptLogger.swift:203)")
    }
}
