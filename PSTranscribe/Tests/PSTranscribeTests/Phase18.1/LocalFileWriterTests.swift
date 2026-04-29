import Foundation
import Testing
@testable import PSTranscribe

@Suite("Phase 18.1 -- LocalFileWriter writes correct format per session type")
struct LocalFileWriterTests {

    private func tempRoot(_ suffix: String = "lfw") -> String {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pstranscribe-tests-\(suffix)-\(UUID().uuidString)")
        return url.path
    }

    @Test("Dictation writes plain markdown to Dictation/ subfolder, NO frontmatter")
    func dictationPlainMarkdown() async throws {
        let writer = LocalFileWriter()
        let root = tempRoot("dictation")
        defer { try? FileManager.default.removeItem(atPath: root) }

        let metadata = SaveMetadata(
            sessionType: .dictation,
            title: "first five words",
            startDate: Date(timeIntervalSince1970: 1_700_000_000),
            duration: 12.5,
            sourceApp: "PSTranscribe",
            speakers: [],
            tags: []
        )

        let url = try await writer.write(content: "this is the dictation body", metadata: metadata, rootPath: root)

        #expect(url.path.contains("/Dictation/"))
        #expect(url.lastPathComponent.hasSuffix(" Dictation.md"))

        let body = try String(contentsOf: url)
        #expect(!body.hasPrefix("---"), "D-05: dictation file MUST NOT have YAML frontmatter")
        #expect(body.contains("# Dictation --"))
        #expect(body.contains("this is the dictation body"))
    }

    @Test("Meeting writes YAML frontmatter to Meeting/ subfolder")
    func meetingFrontmatter() async throws {
        let writer = LocalFileWriter()
        let root = tempRoot("meeting")
        defer { try? FileManager.default.removeItem(atPath: root) }

        let metadata = SaveMetadata(
            sessionType: .callCapture,
            title: "quarterly review",
            startDate: Date(),
            duration: 1800,
            sourceApp: "Zoom",
            speakers: ["You", "Speaker 2"],
            tags: []
        )

        let url = try await writer.write(content: "**You** (00:00:00)\nhello", metadata: metadata, rootPath: root)

        #expect(url.path.contains("/Meeting/"))
        let body = try String(contentsOf: url)
        #expect(body.hasPrefix("---\ntype: meeting\n"), "D-05: meetings include YAML frontmatter")
        #expect(body.contains("source_app: \"Zoom\""))
        #expect(body.contains("# Call Recording -- "))
    }

    @Test("Voice memo writes YAML frontmatter to Memo/ subfolder with type: fleeting")
    func voiceMemoFrontmatter() async throws {
        let writer = LocalFileWriter()
        let root = tempRoot("memo")
        defer { try? FileManager.default.removeItem(atPath: root) }

        let metadata = SaveMetadata(
            sessionType: .voiceMemo,
            title: "shopping list",
            startDate: Date(),
            duration: 30,
            sourceApp: "Voice Memo",
            speakers: [],
            tags: []
        )

        let url = try await writer.write(content: "buy milk", metadata: metadata, rootPath: root)

        #expect(url.path.contains("/Memo/"))
        let body = try String(contentsOf: url)
        #expect(body.contains("type: fleeting"))
        #expect(body.contains("# Voice Memo -- "))
    }

    @Test("Subfolders created lazily on first write per content type (D-06)")
    func lazySubfolderCreation() async throws {
        let writer = LocalFileWriter()
        let root = tempRoot("lazy")
        defer { try? FileManager.default.removeItem(atPath: root) }

        // Before write: root does not exist
        #expect(!FileManager.default.fileExists(atPath: root))

        let metadata = SaveMetadata(
            sessionType: .dictation,
            title: "x",
            startDate: Date(),
            duration: 1,
            sourceApp: "PSTranscribe",
            speakers: [],
            tags: []
        )
        _ = try await writer.write(content: "y", metadata: metadata, rootPath: root)

        // After write: root and Dictation/ exist; Meeting/ and Memo/ DO NOT (lazy creation per type).
        #expect(FileManager.default.fileExists(atPath: root))
        #expect(FileManager.default.fileExists(atPath: "\(root)/Dictation"))
        #expect(!FileManager.default.fileExists(atPath: "\(root)/Meeting"), "D-06: only the type's subfolder is created")
        #expect(!FileManager.default.fileExists(atPath: "\(root)/Memo"))
    }

    @Test("Path traversal in localFileRoot is rejected")
    func traversalRejected() async throws {
        let writer = LocalFileWriter()
        let metadata = SaveMetadata(
            sessionType: .dictation,
            title: "x",
            startDate: Date(),
            duration: 1,
            sourceApp: "PSTranscribe",
            speakers: [],
            tags: []
        )
        await #expect(throws: LocalFileWriterError.self) {
            _ = try await writer.write(content: "y", metadata: metadata, rootPath: "/tmp/foo/../bar")
        }
    }

    @Test("SessionType.notionValue / obsidianFrontmatterValue / obsidianFilenameLabel / localFileSubfolder")
    func sessionTypeMappings() {
        #expect(SessionType.callCapture.notionValue == "Meeting")
        #expect(SessionType.voiceMemo.notionValue == "Voice Memo")
        #expect(SessionType.dictation.notionValue == "Dictation")

        #expect(SessionType.callCapture.obsidianFrontmatterValue == "meeting")
        #expect(SessionType.voiceMemo.obsidianFrontmatterValue == "memo")
        #expect(SessionType.dictation.obsidianFrontmatterValue == "dictation")

        #expect(SessionType.callCapture.obsidianFilenameLabel == "Meeting")
        #expect(SessionType.voiceMemo.obsidianFilenameLabel == "Memo")
        #expect(SessionType.dictation.obsidianFilenameLabel == "Dictation")

        #expect(SessionType.callCapture.localFileSubfolder == "Meeting")
        #expect(SessionType.voiceMemo.localFileSubfolder == "Memo")
        #expect(SessionType.dictation.localFileSubfolder == "Dictation")
    }
}
