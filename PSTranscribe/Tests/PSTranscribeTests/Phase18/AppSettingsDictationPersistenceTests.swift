import Testing
import Foundation
@testable import PSTranscribe

@Suite("AppSettingsDictationPersistenceTests")
struct AppSettingsDictationPersistenceTests {

    /// FOLDER-05 (and adjacent FOLDER-04 / DICT-02) -- persisted via AppSettings didSet -> UserDefaults.
    /// The pattern is: write a value to a fresh AppSettings instance, then construct a NEW
    /// AppSettings instance and confirm the value was read back from UserDefaults.

    @Test(.disabled("Pending Plan 18-07 -- dictationFolderPath persists across AppSettings instances (FOLDER-05)"))
    @MainActor func dictationFolderPathRoundTripsViaUserDefaults() {
        // let unique = "/tmp/dictation-roundtrip-\(UUID().uuidString)"
        // let s1 = AppSettings()
        // s1.dictationFolderPath = unique
        // let s2 = AppSettings()
        // #expect(s2.dictationFolderPath == unique)
        // // Cleanup
        // UserDefaults.standard.removeObject(forKey: "dictationFolderPath")
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-07 -- dictationOutputMode persists across AppSettings instances (DICT-02)"))
    @MainActor func dictationOutputModeRoundTripsViaUserDefaults() {
        // let s1 = AppSettings()
        // let original = s1.dictationOutputMode
        // s1.dictationOutputMode = (original == .both ? .clipboard : .both)
        // let target = s1.dictationOutputMode
        // let s2 = AppSettings()
        // #expect(s2.dictationOutputMode == target)
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-07 -- dictationHotkeyMode persists across AppSettings instances (DICT-02)"))
    @MainActor func dictationHotkeyModeRoundTripsViaUserDefaults() {
        // let s1 = AppSettings()
        // let target: DictationHotkeyMode = (s1.dictationHotkeyMode == .toggle ? .pressAndHold : .toggle)
        // s1.dictationHotkeyMode = target
        // let s2 = AppSettings()
        // #expect(s2.dictationHotkeyMode == target)
        #expect(Bool(true))
    }
}
