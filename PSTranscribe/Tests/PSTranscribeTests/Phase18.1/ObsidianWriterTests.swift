import Foundation
import Testing
@testable import PSTranscribe

@Suite("Phase 18.1 -- ObsidianWriter writes session-type frontmatter for all three types")
struct ObsidianWriterTests {

    private func tempFolder() -> String {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("pstranscribe-tests-obs-\(UUID().uuidString)")
            .path
    }

    private func metadata(_ type: SessionType, title: String = "test") -> SaveMetadata {
        SaveMetadata(
            sessionType: type,
            title: title,
            startDate: Date(timeIntervalSince1970: 1_700_000_000),
            duration: 60,
            sourceApp: "PSTranscribe",
            speakers: [],
            tags: []
        )
    }

    @Test("Meeting Obsidian write -- session-type: meeting + Meeting in filename")
    func meeting() async throws {
        let folder = tempFolder()
        defer { try? FileManager.default.removeItem(atPath: folder) }
        let writer = ObsidianWriter()
        let url = try await writer.write(content: "hello", metadata: metadata(.callCapture, title: "weekly review"), folderPath: folder)
        let body = try String(contentsOf: url)
        #expect(body.contains("session-type: meeting"))
        #expect(url.lastPathComponent.contains(" Meeting "))
        #expect(url.lastPathComponent.contains("weekly review"))
    }

    @Test("Memo Obsidian write -- session-type: memo + Memo in filename")
    func memo() async throws {
        let folder = tempFolder()
        defer { try? FileManager.default.removeItem(atPath: folder) }
        let writer = ObsidianWriter()
        let url = try await writer.write(content: "hi", metadata: metadata(.voiceMemo), folderPath: folder)
        let body = try String(contentsOf: url)
        #expect(body.contains("session-type: memo"))
        #expect(url.lastPathComponent.contains(" Memo "))
    }

    @Test("Dictation Obsidian write -- session-type: dictation AND has frontmatter (D-11)")
    func dictation() async throws {
        let folder = tempFolder()
        defer { try? FileManager.default.removeItem(atPath: folder) }
        let writer = ObsidianWriter()
        let url = try await writer.write(content: "hi", metadata: metadata(.dictation), folderPath: folder)
        let body = try String(contentsOf: url)
        #expect(body.hasPrefix("---\nsession-type: dictation\n"), "D-11: dictation in Obsidian gets YAML frontmatter (unlike Local File)")
        #expect(url.lastPathComponent.contains(" Dictation "))
    }

    @Test("Filename includes type label so all three types coexist in one folder")
    func filenameTypeLabel() async throws {
        let folder = tempFolder()
        defer { try? FileManager.default.removeItem(atPath: folder) }
        let writer = ObsidianWriter()

        let m = try await writer.write(content: "x", metadata: metadata(.callCapture), folderPath: folder)
        let v = try await writer.write(content: "x", metadata: metadata(.voiceMemo), folderPath: folder)
        let d = try await writer.write(content: "x", metadata: metadata(.dictation), folderPath: folder)
        #expect(m.lastPathComponent != v.lastPathComponent)
        #expect(v.lastPathComponent != d.lastPathComponent)
        #expect(m.lastPathComponent != d.lastPathComponent)
    }

    @Test("Path traversal in folderPath is rejected")
    func traversalRejected() async throws {
        let writer = ObsidianWriter()
        await #expect(throws: ObsidianWriterError.self) {
            _ = try await writer.write(content: "x", metadata: metadata(.dictation), folderPath: "/tmp/../etc")
        }
    }
}
