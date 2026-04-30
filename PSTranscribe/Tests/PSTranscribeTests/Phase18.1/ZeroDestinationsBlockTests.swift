import Foundation
import Testing
@testable import PSTranscribe

@Suite("Phase 18.1 D-20 -- meeting/voice memo blocked when zero destinations enabled")
struct ZeroDestinationsBlockTests {

    private var contentViewSource: String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()         // Phase18.1/
            .deletingLastPathComponent()         // PSTranscribeTests/
            .deletingLastPathComponent()         // Tests/
            .appendingPathComponent("Sources/PSTranscribe/Views/ContentView.swift")
        return (try? String(contentsOf: url)) ?? ""
    }

    @Test("ContentView.startSession contains the D-20 guard via saveDestinations.isAnyDestinationEnabled")
    func contentViewHasD20Guard() {
        #expect(contentViewSource.contains("saveDestinations.isAnyDestinationEnabled"))
    }

    @Test("ContentView contains the D-20 error string verbatim")
    func contentViewHasD20ErrorString() {
        #expect(contentViewSource.contains("No save destination configured. Enable Local File, Obsidian, or Notion in Settings."))
    }

    @Test("ContentView no longer references vaultMeetingsPath/vaultVoicePath")
    func contentViewHasNoLegacyVaultRefs() {
        #expect(!contentViewSource.contains("vaultMeetingsPath"))
        #expect(!contentViewSource.contains("vaultVoicePath"))
    }

    @Test("ContentView no longer references DictationOutputMode/dictationFolderPath/dictationOutputMode")
    func contentViewHasNoLegacyDictationRefs() {
        #expect(!contentViewSource.contains("dictationOutputMode"))
        #expect(!contentViewSource.contains("dictationFolderPath"))
        #expect(!contentViewSource.contains("DictationOutputMode."))
    }

    @MainActor
    @Test("SaveDestinations.isAnyDestinationEnabled mirrors D-20 boolean exactly")
    func saveDestinationsBooleanMatchesD20() {
        let keys = ["localFileEnabled", "obsidianEnabled", "obsidianFolderPath",
                    "notionAutoSendEnabled", "notionDatabaseID"]
        for k in keys { UserDefaults.standard.removeObject(forKey: k) }
        defer { for k in keys { UserDefaults.standard.removeObject(forKey: k) } }

        let settings = AppSettings()
        let dest = SaveDestinations(settings: settings, notionService: NotionService())

        settings.localFileEnabled = false
        settings.obsidianEnabled = false
        settings.notionAutoSendEnabled = false
        #expect(dest.isAnyDestinationEnabled == false, "D-20: zero destinations -> session-start blocks")

        settings.localFileEnabled = true
        #expect(dest.isAnyDestinationEnabled == true, "D-20: any destination on -> session-start allowed")

        settings.localFileEnabled = false
        settings.obsidianEnabled = true
        settings.obsidianFolderPath = "/tmp/somewhere"
        #expect(dest.isAnyDestinationEnabled == true)

        settings.obsidianEnabled = true
        settings.obsidianFolderPath = ""
        settings.localFileEnabled = false
        settings.notionAutoSendEnabled = false
        #expect(dest.isAnyDestinationEnabled == false, "Obsidian on but folder empty -> not configured")
    }
}
