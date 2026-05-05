import Foundation
import Testing
@testable import PSTranscribe

@Suite("Phase 18.1 D-20 -- meeting/voice memo blocked when zero destinations enabled")
struct ZeroDestinationsBlockTests {

    private var contentViewSource: String {
        // #filePath -> .../PSTranscribe/Tests/PSTranscribeTests/Phase18.1/ZeroDestinationsBlockTests.swift
        // We need to climb to .../PSTranscribe/ then descend into Sources/.
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()         // -> Phase18.1/
            .deletingLastPathComponent()         // -> PSTranscribeTests/
            .deletingLastPathComponent()         // -> Tests/
            .deletingLastPathComponent()         // -> PSTranscribe/ (package root)
            .appendingPathComponent("Sources/PSTranscribe/Views/ContentView.swift")
        return (try? String(contentsOf: url)) ?? ""
    }

    private var saveDestinationsSource: String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/PSTranscribe/Services/SaveDestinations.swift")
        return (try? String(contentsOf: url)) ?? ""
    }

    @Test("ContentView.startSession contains the D-20 guard via saveDestinations.isAnyDestinationEnabled")
    func contentViewHasD20Guard() {
        #expect(contentViewSource.contains("saveDestinations.isAnyDestinationEnabled"))
    }

    @Test("D-20 error string lives verbatim in SaveDestinations.swift (centralized constant)")
    func saveDestinationsContainsD20ErrorString() {
        #expect(saveDestinationsSource.contains(
            "No save destination configured. Enable Local File, Obsidian, or Notion in Settings."))
    }

    @Test("ContentView startSession references the D-20 constant (not the literal)")
    func contentViewStartSessionUsesConstant() {
        #expect(contentViewSource.contains("DestinationGuardErrors.noDestinationsConfigured"))
    }

    @Test("ContentView no longer references vaultMeetingsPath/vaultVoicePath")
    func contentViewHasNoLegacyVaultRefs() {
        // Phase 24 (NYQUIST-05): tightened from bare-substring to property-access
        // pattern. The guardrail's intent is "no reads of the removed AppSettings
        // properties `vaultMeetingsPath` / `vaultVoicePath`." Plan 24-02 lifted a
        // pure helper `recoveredSessionType(transcriptPath:vaultVoicePath:)` whose
        // parameter name (intentionally named after the conceptual prefix string)
        // collides with the bare-substring check while introducing zero legacy
        // AppSettings reads. The tightened pattern matches the original intent:
        // forbid `settings.vaultVoicePath` / `settings.vaultMeetingsPath` reads,
        // allow unrelated identifiers that happen to share the substring.
        #expect(!contentViewSource.contains("settings.vaultMeetingsPath"))
        #expect(!contentViewSource.contains("settings.vaultVoicePath"))
        #expect(!contentViewSource.contains(".vaultMeetingsPath ="))
        #expect(!contentViewSource.contains(".vaultVoicePath ="))
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
