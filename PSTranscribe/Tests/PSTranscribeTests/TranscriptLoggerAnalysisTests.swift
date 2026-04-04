import Testing
import Foundation
@testable import PSTranscribe

@Suite("TranscriptLogger appendAnalysis Tests")
struct TranscriptLoggerAnalysisTests {

    private func makeTempFile(initialContent: String = "# Session\n\nSome transcript text\n") throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-analysis-\(UUID().uuidString).md")
        try initialContent.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    @Test func appendAnalysisWritesFullSection() async throws {
        let logger = TranscriptLogger()
        let tempFile = try makeTempFile()
        defer { try? FileManager.default.removeItem(at: tempFile) }

        await logger.appendAnalysis(
            to: tempFile,
            summary: "Test summary",
            actionItems: ["Buy milk", "Call dentist"],
            keyTopics: ["groceries", "health"]
        )

        let content = try String(contentsOf: tempFile, encoding: .utf8)
        #expect(content.contains("## Analysis"))
        #expect(content.contains("### Summary"))
        #expect(content.contains("Test summary"))
        #expect(content.contains("### Action Items"))
        #expect(content.contains("- [ ] Buy milk"))
        #expect(content.contains("- [ ] Call dentist"))
        #expect(content.contains("### Key Topics"))
        #expect(content.contains("groceries, health"))
    }

    @Test func appendAnalysisPreservesExistingContent() async throws {
        let logger = TranscriptLogger()
        let initial = "# Session\n\nOriginal transcript body\n"
        let tempFile = try makeTempFile(initialContent: initial)
        defer { try? FileManager.default.removeItem(at: tempFile) }

        await logger.appendAnalysis(
            to: tempFile,
            summary: "Summary",
            actionItems: ["Item"],
            keyTopics: ["topic"]
        )

        let content = try String(contentsOf: tempFile, encoding: .utf8)
        #expect(content.hasPrefix(initial))
    }

    @Test func appendAnalysisEmptyGuardDoesNotModifyFile() async throws {
        let logger = TranscriptLogger()
        let initial = "# Session\n\nOriginal\n"
        let tempFile = try makeTempFile(initialContent: initial)
        defer { try? FileManager.default.removeItem(at: tempFile) }

        let sizeBefore = (try FileManager.default.attributesOfItem(atPath: tempFile.path)[.size] as? NSNumber)?.intValue ?? -1

        await logger.appendAnalysis(
            to: tempFile,
            summary: "",
            actionItems: [],
            keyTopics: []
        )

        let sizeAfter = (try FileManager.default.attributesOfItem(atPath: tempFile.path)[.size] as? NSNumber)?.intValue ?? -2
        #expect(sizeBefore == sizeAfter)

        let content = try String(contentsOf: tempFile, encoding: .utf8)
        #expect(content == initial)
        #expect(!content.contains("## Analysis"))
    }

    @Test func appendAnalysisWritesWithOnlySummary() async throws {
        let logger = TranscriptLogger()
        let tempFile = try makeTempFile()
        defer { try? FileManager.default.removeItem(at: tempFile) }

        await logger.appendAnalysis(
            to: tempFile,
            summary: "Only the summary",
            actionItems: [],
            keyTopics: []
        )

        let content = try String(contentsOf: tempFile, encoding: .utf8)
        #expect(content.contains("## Analysis"))
        #expect(content.contains("### Summary"))
        #expect(content.contains("Only the summary"))
    }

    @Test func appendAnalysisFormatsActionItemsAsCheckboxes() async throws {
        let logger = TranscriptLogger()
        let tempFile = try makeTempFile()
        defer { try? FileManager.default.removeItem(at: tempFile) }

        await logger.appendAnalysis(
            to: tempFile,
            summary: "s",
            actionItems: ["First", "Second", "Third"],
            keyTopics: []
        )

        let content = try String(contentsOf: tempFile, encoding: .utf8)
        #expect(content.contains("- [ ] First"))
        #expect(content.contains("- [ ] Second"))
        #expect(content.contains("- [ ] Third"))
    }
}
