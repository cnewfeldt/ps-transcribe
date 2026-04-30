import Foundation
import Testing
@testable import PSTranscribe

@Suite("Phase 18.1 -- SettingsView destination sections (source-grep)")
struct SettingsView18_1Tests {

    private var settingsViewSource: String {
        // #filePath -> .../PSTranscribe/Tests/PSTranscribeTests/Phase18.1/SettingsView18_1Tests.swift
        // We need to climb to .../PSTranscribe/ then descend into Sources/.
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()         // -> Phase18.1/
            .deletingLastPathComponent()         // -> PSTranscribeTests/
            .deletingLastPathComponent()         // -> Tests/
            .deletingLastPathComponent()         // -> PSTranscribe/  (package root)
            .appendingPathComponent("Sources/PSTranscribe/Views/SettingsView.swift")
        return (try? String(contentsOf: url)) ?? ""
    }

    @Test("Section('Local File') is present")
    func hasLocalFileSection() {
        #expect(settingsViewSource.contains("Section(\"Local File\")"))
    }

    @Test("Section('Obsidian') is present")
    func hasObsidianSection() {
        #expect(settingsViewSource.contains("Section(\"Obsidian\")"))
    }

    @Test("Section('Dictation') is present")
    func hasDictationSection() {
        #expect(settingsViewSource.contains("Section(\"Dictation\")"))
    }

    @Test("Local File enable toggle binds to settings.localFileEnabled")
    func localFileToggleBinding() {
        #expect(settingsViewSource.contains("$settings.localFileEnabled"))
    }

    @Test("Obsidian enable toggle binds to settings.obsidianEnabled")
    func obsidianToggleBinding() {
        #expect(settingsViewSource.contains("$settings.obsidianEnabled"))
    }

    @Test("Local File root path binds to settings.localFileRoot")
    func localFileRootBinding() {
        #expect(settingsViewSource.contains("settings.localFileRoot"))
    }

    @Test("Obsidian single folder binds to settings.obsidianFolderPath")
    func obsidianFolderBinding() {
        #expect(settingsViewSource.contains("settings.obsidianFolderPath"))
    }

    @Test("Deleted properties no longer referenced")
    func deletedPropertiesAbsent() {
        #expect(!settingsViewSource.contains("vaultMeetingsPath"))
        #expect(!settingsViewSource.contains("vaultVoicePath"))
        #expect(!settingsViewSource.contains("dictationOutputMode"))
        #expect(!settingsViewSource.contains("dictationFolderPath"))
        #expect(!settingsViewSource.contains("DictationOutputMode."))
    }

    @Test("Section order: Local File before Obsidian before Notion before Dictation")
    func sectionOrder() {
        let src = settingsViewSource
        guard let lf = src.range(of: "Section(\"Local File\")"),
              let ob = src.range(of: "Section(\"Obsidian\")"),
              let no = src.range(of: "Section(\"Notion\")"),
              let dc = src.range(of: "Section(\"Dictation\")") else {
            Issue.record("missing one or more sections")
            return
        }
        #expect(lf.lowerBound < ob.lowerBound)
        #expect(ob.lowerBound < no.lowerBound)
        #expect(no.lowerBound < dc.lowerBound)
    }

    @Test("Dictation section retains clipboardRestoreDelay Stepper (regression)")
    func dictationKeepsRestoreDelay() {
        #expect(settingsViewSource.contains("$settings.clipboardRestoreDelay"))
    }

    @Test("Dictation section retains KeyboardShortcuts.Recorder for .dictateGlobal (regression)")
    func dictationKeepsRecorder() {
        #expect(settingsViewSource.contains("KeyboardShortcuts.Recorder"))
        #expect(settingsViewSource.contains(".dictateGlobal"))
    }
}
