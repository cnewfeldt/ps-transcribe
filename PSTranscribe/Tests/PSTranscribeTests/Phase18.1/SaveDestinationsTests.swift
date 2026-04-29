import Foundation
import Testing
@testable import PSTranscribe

@MainActor
@Suite("Phase 18.1 -- SaveDestinations fan-out semantics")
struct SaveDestinationsTests {

    private func tempPath() -> String {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("psd-savedest-\(UUID().uuidString)")
            .path
    }

    private func metadata(_ type: SessionType) -> SaveMetadata {
        SaveMetadata(
            sessionType: type,
            title: "fan-out test",
            startDate: Date(),
            duration: 5,
            sourceApp: "PSTranscribe",
            speakers: [],
            tags: []
        )
    }

    private func freshSettings() -> AppSettings {
        let keys = ["localFileEnabled", "localFileRoot", "obsidianEnabled",
                    "obsidianFolderPath", "notionAutoSendEnabled", "notionDatabaseID"]
        for k in keys { UserDefaults.standard.removeObject(forKey: k) }
        return AppSettings()
    }

    @Test("isAnyDestinationEnabled returns true when localFileEnabled regardless of paths")
    func isAnyEnabled_localFile() {
        let settings = freshSettings()
        defer { for k in ["localFileEnabled", "obsidianEnabled", "notionAutoSendEnabled"] { UserDefaults.standard.removeObject(forKey: k) } }
        let dest = SaveDestinations(settings: settings, notionService: NotionService())
        settings.localFileEnabled = true
        settings.obsidianEnabled = false
        settings.notionAutoSendEnabled = false
        #expect(dest.isAnyDestinationEnabled == true)
    }

    @Test("isAnyDestinationEnabled returns false when all three disabled")
    func isAnyEnabled_none() {
        let settings = freshSettings()
        let dest = SaveDestinations(settings: settings, notionService: NotionService())
        settings.localFileEnabled = false
        settings.obsidianEnabled = false
        settings.notionAutoSendEnabled = false
        #expect(dest.isAnyDestinationEnabled == false)
    }

    @Test("isAnyDestinationEnabled requires Obsidian path to be non-empty")
    func isAnyEnabled_obsidianRequiresPath() {
        let settings = freshSettings()
        let dest = SaveDestinations(settings: settings, notionService: NotionService())
        settings.localFileEnabled = false
        settings.obsidianEnabled = true
        settings.obsidianFolderPath = ""
        settings.notionAutoSendEnabled = false
        #expect(dest.isAnyDestinationEnabled == false, "Obsidian enabled but no folder picked == not configured")
        settings.obsidianFolderPath = "/tmp/foo"
        #expect(dest.isAnyDestinationEnabled == true)
    }

    @Test("save() with localFileEnabled writes a file and returns localFileURL")
    func saveLocalFileOnly() async throws {
        let settings = freshSettings()
        let root = tempPath()
        defer {
            try? FileManager.default.removeItem(atPath: root)
            for k in ["localFileEnabled", "localFileRoot", "obsidianEnabled", "notionAutoSendEnabled"] {
                UserDefaults.standard.removeObject(forKey: k)
            }
        }
        settings.localFileEnabled = true
        settings.localFileRoot = root
        settings.obsidianEnabled = false
        settings.notionAutoSendEnabled = false

        let dest = SaveDestinations(settings: settings, notionService: NotionService())
        let result = await dest.save(content: "hello", metadata: metadata(.dictation))

        #expect(result.localFileURL != nil)
        #expect(result.obsidianFileURL == nil)
        #expect(result.notionPageURL == nil)
        #expect(result.errors.isEmpty)
        if let url = result.localFileURL {
            #expect(FileManager.default.fileExists(atPath: url.path))
            #expect(url.path.contains("/Dictation/"))
        }
    }

    @Test("save() with both Local File and Obsidian enabled writes both")
    func saveBothLocalAndObsidian() async throws {
        let settings = freshSettings()
        let root = tempPath()
        let vault = tempPath()
        defer {
            try? FileManager.default.removeItem(atPath: root)
            try? FileManager.default.removeItem(atPath: vault)
            for k in ["localFileEnabled", "localFileRoot", "obsidianEnabled", "obsidianFolderPath", "notionAutoSendEnabled"] {
                UserDefaults.standard.removeObject(forKey: k)
            }
        }
        settings.localFileEnabled = true
        settings.localFileRoot = root
        settings.obsidianEnabled = true
        settings.obsidianFolderPath = vault
        settings.notionAutoSendEnabled = false

        let dest = SaveDestinations(settings: settings, notionService: NotionService())
        let result = await dest.save(content: "hi", metadata: metadata(.callCapture))

        #expect(result.localFileURL != nil)
        #expect(result.obsidianFileURL != nil)
        #expect(result.notionPageURL == nil)
    }

    @Test("save() per-destination failure is non-fatal: invalid Local File root logs error but Obsidian still writes")
    func nonFatalPerDestination() async throws {
        let settings = freshSettings()
        let vault = tempPath()
        defer {
            try? FileManager.default.removeItem(atPath: vault)
            for k in ["localFileEnabled", "localFileRoot", "obsidianEnabled", "obsidianFolderPath", "notionAutoSendEnabled"] {
                UserDefaults.standard.removeObject(forKey: k)
            }
        }
        settings.localFileEnabled = true
        settings.localFileRoot = "/tmp/foo/../bar"  // forces validation failure
        settings.obsidianEnabled = true
        settings.obsidianFolderPath = vault
        settings.notionAutoSendEnabled = false

        let dest = SaveDestinations(settings: settings, notionService: NotionService())
        let result = await dest.save(content: "hi", metadata: metadata(.dictation))

        #expect(result.localFileURL == nil, "invalid root rejected")
        #expect(result.obsidianFileURL != nil, "Obsidian still writes despite Local File failure")
        #expect(!result.errors.isEmpty, "failure recorded in errors[]")
    }
}
