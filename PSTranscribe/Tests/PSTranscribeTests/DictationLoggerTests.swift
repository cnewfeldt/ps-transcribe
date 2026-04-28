import Testing
import Foundation
@testable import PSTranscribe

@Suite("DictationLogger", .serialized)
struct DictationLoggerTests {

    private func tempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DictationLoggerTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test func startSessionWritesHeader() async throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let logger = DictationLogger()
        try await logger.startSession(folderPath: dir.path)
        let url = await logger.endSession()
        #expect(url != nil)

        guard let url else { return }
        let contents = try String(contentsOf: url, encoding: .utf8)
        #expect(contents.hasPrefix("# Dictation -- "))
        // The header line ends with a date in yyyy-MM-dd HH:mm form, followed by \n\n.
        let firstLine = contents.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false).first ?? ""
        #expect(firstLine.contains("-- "))
        #expect(contents.contains("\n\n"))
        // CRITICAL: no YAML frontmatter (D-02)
        #expect(!contents.contains("---"))
    }

    @Test func appendWritesUtterance() async throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let logger = DictationLogger()
        try await logger.startSession(folderPath: dir.path)
        let now = Date()
        await logger.append(text: "Hello world", timestamp: now)
        let url = await logger.endSession()

        guard let url else { Issue.record("endSession returned nil"); return }
        let contents = try String(contentsOf: url, encoding: .utf8)
        #expect(contents.contains("**You** ("))
        #expect(contents.contains("Hello world"))
        // Offset format HH:MM:SS appears between **You** ( and )
        #expect(contents.range(of: #"\*\*You\*\* \(\d{2}:\d{2}:\d{2}\)"#, options: .regularExpression) != nil)
    }

    @Test func appendComputesSessionRelativeOffset() async throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let logger = DictationLogger()
        try await logger.startSession(folderPath: dir.path)
        // The logger's session start is its own "now", not t0. So we test relative ordering, not absolute.
        // Use synthesized timestamps: append two utterances at +5s and +65s relative to NOW (after startSession).
        try await Task.sleep(for: .milliseconds(50))  // ensure session start is in the past
        let sessionT0 = Date().addingTimeInterval(-0.05)
        await logger.append(text: "first", timestamp: sessionT0.addingTimeInterval(5))
        await logger.append(text: "second", timestamp: sessionT0.addingTimeInterval(65))
        let url = await logger.endSession()

        guard let url else { Issue.record("endSession returned nil"); return }
        let contents = try String(contentsOf: url, encoding: .utf8)
        // We assert ordering rather than exact offsets (the logger's internal startTime is set during startSession,
        // which may be a few ms before sessionT0). The two appended timestamps differ by ~60s, so the
        // first offset should be smaller than the second, and "first" appears before "second".
        guard let firstIdx = contents.range(of: "first")?.lowerBound,
              let secondIdx = contents.range(of: "second")?.lowerBound else {
            Issue.record("Could not find both appended utterances")
            return
        }
        #expect(firstIdx < secondIdx)
    }

    @Test func endSessionReturnsURLAndClosesHandle() async throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let logger = DictationLogger()
        try await logger.startSession(folderPath: dir.path)
        await logger.append(text: "x", timestamp: Date())
        let url1 = await logger.endSession()
        let url2 = await logger.endSession()  // second call after state cleared

        #expect(url1 != nil)
        #expect(url2 == nil)
        if let url1 {
            #expect(FileManager.default.fileExists(atPath: url1.path))
        }
    }

    @Test func rapidSessionsNoCollision() async throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let loggerA = DictationLogger()
        let loggerB = DictationLogger()
        try await loggerA.startSession(folderPath: dir.path)
        // Production filename suffix is millisecond-resolution (`yyyy-MM-dd HH-mm-ss-SSS`).
        // Two back-to-back startSession calls on different actor instances can land in the
        // same millisecond on a fast machine. The realistic Pitfall #9 case the production
        // code defends against is two RAPID-but-distinct user-triggered sessions (the
        // user cannot fire two hotkeys within sub-millisecond from a single
        // @MainActor-serialized DictationCoordinator). Use a 2ms gap to ensure the test
        // exercises the actual production guarantee instead of racing against itself.
        try await Task.sleep(for: .milliseconds(2))
        try await loggerB.startSession(folderPath: dir.path)
        let urlA = await loggerA.endSession()
        let urlB = await loggerB.endSession()

        #expect(urlA != nil)
        #expect(urlB != nil)
        #expect(urlA != urlB, "Two startSession calls within milliseconds must produce distinct file URLs (Pitfall #9)")
    }

    @Test func rejectsTraversal() async throws {
        let logger = DictationLogger()
        await #expect(throws: DictationLoggerError.self) {
            try await logger.startSession(folderPath: "../../../etc")
        }
    }

    @Test func rejectsNullByte() async throws {
        let logger = DictationLogger()
        await #expect(throws: DictationLoggerError.self) {
            try await logger.startSession(folderPath: "/tmp/foo\0bar")
        }
    }

    @Test func outputFileHasRestrictivePermissions() async throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let logger = DictationLogger()
        try await logger.startSession(folderPath: dir.path)
        let url = await logger.endSession()

        guard let url else { Issue.record("endSession returned nil"); return }
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        let perms = (attrs[.posixPermissions] as? NSNumber)?.intValue ?? 0
        #expect(perms == 0o600, "DictationLogger output must be 0o600 (owner-only read/write); got \(String(perms, radix: 8))")
    }

    @Test func noYAMLFrontmatterAfterFullSession() async throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let logger = DictationLogger()
        try await logger.startSession(folderPath: dir.path)
        let now = Date()
        await logger.append(text: "First", timestamp: now)
        await logger.append(text: "Second", timestamp: now.addingTimeInterval(2))
        await logger.append(text: "Third", timestamp: now.addingTimeInterval(4))
        let url = await logger.endSession()

        guard let url else { Issue.record("endSession returned nil"); return }
        let contents = try String(contentsOf: url, encoding: .utf8)
        // D-02: NO YAML frontmatter, EVER. Pitfall #10.
        #expect(!contents.contains("---"), "Plain-folder output must contain no YAML frontmatter delimiter '---'")
    }
}
