import Testing
import Foundation
@testable import PSTranscribe

@Suite("AppSettingsDictationPersistenceTests")
struct AppSettingsDictationPersistenceTests {

    /// FOLDER-05 (and adjacent FOLDER-04 / DICT-02) -- persisted via AppSettings didSet -> UserDefaults.
    /// Pattern: write a value to a fresh AppSettings instance, then construct a NEW AppSettings
    /// instance and confirm the value was read back from UserDefaults.
    /// Each test cleans up via `defer { UserDefaults.standard.removeObject(forKey:) }` so
    /// the test runner's UserDefaults isn't polluted across runs (T-18-01-04 mitigation).

    @Test @MainActor func dictationFolderPathRoundTripsViaUserDefaults() {
        defer { UserDefaults.standard.removeObject(forKey: "dictationFolderPath") }
        let unique = "/tmp/dictation-roundtrip-\(UUID().uuidString)"
        let s1 = AppSettings()
        s1.dictationFolderPath = unique
        // didSet has fired and written to UserDefaults synchronously.
        let s2 = AppSettings()
        #expect(s2.dictationFolderPath == unique, "FOLDER-05: dictationFolderPath must persist across AppSettings instances")
    }

    @Test @MainActor func dictationOutputModeRoundTripsViaUserDefaults() {
        defer { UserDefaults.standard.removeObject(forKey: "dictationOutputMode") }
        let s1 = AppSettings()
        let original = s1.dictationOutputMode
        let target: DictationOutputMode = (original == .both ? .clipboard : .both)
        s1.dictationOutputMode = target
        let s2 = AppSettings()
        #expect(s2.dictationOutputMode == target, "DICT-02: dictationOutputMode must persist across AppSettings instances")
    }

    @Test @MainActor func dictationHotkeyModeRoundTripsViaUserDefaults() {
        defer { UserDefaults.standard.removeObject(forKey: "dictationHotkeyMode") }
        let s1 = AppSettings()
        let target: DictationHotkeyMode = (s1.dictationHotkeyMode == .toggle ? .pressAndHold : .toggle)
        s1.dictationHotkeyMode = target
        let s2 = AppSettings()
        #expect(s2.dictationHotkeyMode == target, "DICT-02: dictationHotkeyMode must persist across AppSettings instances")
    }
}
