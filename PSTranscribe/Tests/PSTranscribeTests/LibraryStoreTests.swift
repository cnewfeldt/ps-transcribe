import Testing
import Foundation
@testable import PSTranscribe

@Suite("LibraryStore Tests")
struct LibraryStoreTests {
    func makeEntry(name: String? = nil) -> LibraryEntry {
        LibraryEntry(
            id: UUID(),
            name: name,
            sessionType: .callCapture,
            startDate: Date(),
            duration: 0,
            filePath: "/tmp/test.md",
            sourceApp: "Teams",
            isFinalized: false,
            firstLinePreview: nil
        )
    }

    func tempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("LibraryStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test func addEntryInsertsAtIndexZero() async throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = LibraryStore(directory: dir)
        let entry1 = makeEntry(name: "First")
        let entry2 = makeEntry(name: "Second")
        await store.addEntry(entry1)
        await store.addEntry(entry2)

        let entries = await store.entries
        #expect(entries.count == 2)
        #expect(entries[0].name == "Second")
        #expect(entries[1].name == "First")
    }

    @Test func entriesPersistToDiskAndReloadOnInit() async throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let entry = makeEntry(name: "Persisted Entry")

        let store1 = LibraryStore(directory: dir)
        await store1.addEntry(entry)

        // Create a new store pointing at the same directory -- it should load from disk
        let store2 = LibraryStore(directory: dir)
        let reloaded = await store2.entries
        #expect(reloaded.count == 1)
        #expect(reloaded[0].name == "Persisted Entry")
        #expect(reloaded[0].id == entry.id)
    }

    @Test func updateEntryModifiesCorrectEntry() async throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = LibraryStore(directory: dir)
        let entry = makeEntry(name: "Original Name")
        await store.addEntry(entry)

        await store.updateEntry(id: entry.id) { e in
            e.name = "Updated Name"
        }

        let entries = await store.entries
        #expect(entries.count == 1)
        #expect(entries[0].name == "Updated Name")
    }

    @Test func emptyStoreLoadsMissingFileGracefully() async throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = LibraryStore(directory: dir)
        let entries = await store.entries
        #expect(entries.isEmpty)
    }
}
