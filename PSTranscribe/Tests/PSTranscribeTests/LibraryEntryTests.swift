import Testing
import Foundation
@testable import PSTranscribe

@Suite("LibraryEntry Tests")
struct LibraryEntryTests {
    @Test func displayNameCallCaptureFallback() {
        let entry = LibraryEntry(
            id: UUID(),
            name: nil,
            sessionType: .callCapture,
            startDate: Date(timeIntervalSince1970: 1775260800), // Apr 2, 2026
            duration: 120,
            filePath: "/tmp/test.md",
            sourceApp: "Teams",
            isFinalized: true,
            firstLinePreview: nil
        )
        #expect(entry.displayName.hasPrefix("Call Recording -- "))
    }

    @Test func displayNameVoiceMemoFallback() {
        let entry = LibraryEntry(
            id: UUID(),
            name: nil,
            sessionType: .voiceMemo,
            startDate: Date(),
            duration: 60,
            filePath: "/tmp/test.md",
            sourceApp: "Voice Memo",
            isFinalized: true,
            firstLinePreview: nil
        )
        #expect(entry.displayName.hasPrefix("Voice Memo -- "))
    }

    @Test func displayNameCustomName() {
        let entry = LibraryEntry(
            id: UUID(),
            name: "Weekly Standup",
            sessionType: .callCapture,
            startDate: Date(),
            duration: 300,
            filePath: "/tmp/test.md",
            sourceApp: "Zoom",
            isFinalized: true,
            firstLinePreview: nil
        )
        #expect(entry.displayName == "Weekly Standup")
    }

    @Test func jsonRoundTrip() throws {
        let original = LibraryEntry(
            id: UUID(),
            name: "Test",
            sessionType: .voiceMemo,
            startDate: Date(timeIntervalSince1970: 1_000_000),
            duration: 45.5,
            filePath: "/Users/test/vault/file.md",
            sourceApp: "Voice Memo",
            isFinalized: true,
            firstLinePreview: "Hello world"
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(LibraryEntry.self, from: data)
        #expect(decoded.id == original.id)
        #expect(decoded.name == original.name)
        #expect(decoded.sessionType == original.sessionType)
        #expect(decoded.filePath == original.filePath)
        #expect(decoded.firstLinePreview == original.firstLinePreview)
    }
}
