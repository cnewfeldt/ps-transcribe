import Foundation
import os

actor LibraryStore {
    private let indexPath: URL
    private(set) var entries: [LibraryEntry]
    private let log = Logger(subsystem: "com.pstranscribe.app", category: "LibraryStore")

    init(directory: URL? = nil) {
        let dir: URL
        if let directory {
            dir = directory
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            dir = appSupport.appendingPathComponent("PSTranscribe", isDirectory: true)
        }
        indexPath = dir.appendingPathComponent("library.json")

        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try FileManager.default.setAttributes(
                [.posixPermissions: NSNumber(value: 0o700)],
                ofItemAtPath: dir.path
            )
        } catch {
            // log is not yet fully set up here, but we record to a local logger
            let initLog = Logger(subsystem: "com.pstranscribe.app", category: "LibraryStore")
            initLog.error("LibraryStore: failed to create directory: \(error.localizedDescription, privacy: .public)")
        }

        // Load entries from disk inline during init
        let path = dir.appendingPathComponent("library.json")
        if FileManager.default.fileExists(atPath: path.path) {
            do {
                let data = try Data(contentsOf: path)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                entries = try decoder.decode([LibraryEntry].self, from: data)
            } catch {
                let initLog = Logger(subsystem: "com.pstranscribe.app", category: "LibraryStore")
                initLog.error("LibraryStore: failed to load on init: \(error.localizedDescription, privacy: .public)")
                entries = []
            }
        } else {
            entries = []
        }
    }

    func addEntry(_ entry: LibraryEntry) {
        entries.insert(entry, at: 0)
        saveToDisk()
    }

    func updateEntry(id: UUID, transform: (inout LibraryEntry) -> Void) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        transform(&entries[idx])
        saveToDisk()
    }

    func removeEntry(id: UUID) {
        entries.removeAll { $0.id == id }
        saveToDisk()
    }

    private func saveToDisk() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(entries)
            try data.write(to: indexPath)
            try FileManager.default.setAttributes(
                [.posixPermissions: NSNumber(value: 0o600)],
                ofItemAtPath: indexPath.path
            )
        } catch {
            log.error("LibraryStore: failed to save: \(error.localizedDescription, privacy: .public)")
        }
    }
}
