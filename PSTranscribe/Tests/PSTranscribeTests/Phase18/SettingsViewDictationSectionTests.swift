import Testing
import Foundation
@testable import PSTranscribe

@Suite("SettingsViewDictationSectionTests")
struct SettingsViewDictationSectionTests {

    /// Source-grep tests for the Settings UI section (DICT-02 + FOLDER-01 + FOLDER-04).
    /// SwiftUI Form/Section/Picker are not directly introspectable in unit tests; the
    /// production-code contract is verified by source-level pattern checks. Mirrors the
    /// existing LibraryEntryRowDictationIconTests grep approach in this suite.
    /// BLOCKER #4 fix: supplies the automated test gate that Nyquist Dimension 8 demands.

    private let settingsViewPath = "Sources/PSTranscribe/Views/SettingsView.swift"

    @Test func settingsViewContainsDictationSection() throws {
        let source = try String(contentsOfFile: settingsViewPath, encoding: .utf8)
        #expect(source.contains(#"Section("Dictation")"#),
                "SettingsView must declare Section(\"Dictation\") (Phase 17 D-06 ordering, after Speech Model)")
    }

    @Test func settingsViewContainsRecorderForDictateGlobal() throws {
        let source = try String(contentsOfFile: settingsViewPath, encoding: .utf8)
        #expect(source.contains("KeyboardShortcuts.Recorder"),
                "SettingsView must use KeyboardShortcuts.Recorder for hotkey assignment (DICT-01)")
        #expect(
            source.contains("for: .dictateGlobal") || source.contains("name: .dictateGlobal"),
            "Recorder must be bound to KeyboardShortcuts.Name.dictateGlobal"
        )
    }

    @Test func settingsViewContainsOutputModePicker() throws {
        let source = try String(contentsOfFile: settingsViewPath, encoding: .utf8)
        #expect(source.contains("$settings.dictationOutputMode"),
                "SettingsView must bind a Picker to $settings.dictationOutputMode (DICT-02)")
        #expect(source.contains("Picker"),
                "SettingsView must use Picker for output-mode selection")
    }

    @Test func settingsViewContainsHotkeyModePicker() throws {
        let source = try String(contentsOfFile: settingsViewPath, encoding: .utf8)
        #expect(source.contains("$settings.dictationHotkeyMode"),
                "SettingsView must bind a Picker to $settings.dictationHotkeyMode (DICT-02)")
    }

    @Test func settingsViewInvokesChooseFolderForDictation() throws {
        let source = try String(contentsOfFile: settingsViewPath, encoding: .utf8)
        #expect(source.contains("chooseFolder(message:"),
                "Folder picker must reuse the existing chooseFolder helper (no duplication)")
        #expect(source.contains("settings.dictationFolderPath = path"),
                "Folder picker must persist the chosen path to AppSettings.dictationFolderPath (FOLDER-01)")
    }
}
