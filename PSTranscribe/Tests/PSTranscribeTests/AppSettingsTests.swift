import Testing
import Foundation
@testable import PSTranscribe

@Suite("AppSettings v1.2 keys", .serialized)
struct AppSettingsTests {

    // List of v1.2 UserDefaults keys this suite touches. Cleared before/after each test.
    // 18.1 (Plan 01): dictationOutputMode + dictationFolderPath were deleted; their
    // round-trip persistence is now covered by AppSettingsDestinationPersistenceTests
    // for the new shared destination keys (localFileEnabled / localFileRoot / etc.).
    private static let v12Keys = [
        "dictationHotkeyMode",
        "clipboardRestoreDelay",
        "installedModelVersion",
        "modelLastCheckedDate",
        "modelAutoUpdateEnabled",
        "appearancePreference",  // Phase 25 NYQUIST-07
    ]

    fileprivate static func clearV12Keys() {
        for key in v12Keys { UserDefaults.standard.removeObject(forKey: key) }
    }

    // MARK: - Defaults

    @Suite("defaults", .serialized)
    struct Defaults {
        @Test @MainActor func dictationHotkeyMode() {
            AppSettingsTests.clearV12Keys()
            defer { AppSettingsTests.clearV12Keys() }
            let s = AppSettings()
            #expect(s.dictationHotkeyMode == .toggle)
        }

        @Test @MainActor func clipboardRestoreDelay() {
            AppSettingsTests.clearV12Keys()
            defer { AppSettingsTests.clearV12Keys() }
            let s = AppSettings()
            #expect(s.clipboardRestoreDelay == 3.0)
        }

        @Test @MainActor func installedModelVersion() {
            AppSettingsTests.clearV12Keys()
            defer { AppSettingsTests.clearV12Keys() }
            let s = AppSettings()
            #expect(s.installedModelVersion == "")
        }

        @Test @MainActor func modelLastCheckedDate() {
            AppSettingsTests.clearV12Keys()
            defer { AppSettingsTests.clearV12Keys() }
            let s = AppSettings()
            #expect(s.modelLastCheckedDate == nil)
        }

        @Test @MainActor func modelAutoUpdateEnabled_defaultsTrue() {
            AppSettingsTests.clearV12Keys()
            defer { AppSettingsTests.clearV12Keys() }
            let s = AppSettings()
            #expect(s.modelAutoUpdateEnabled == true)
        }

        @Test @MainActor func appearancePreferenceDefaultsToSystem() {
            AppSettingsTests.clearV12Keys()
            defer { AppSettingsTests.clearV12Keys() }
            let s = AppSettings()
            #expect(s.appearancePreference == .system)
        }
    }

    // MARK: - Round-trips

    @Test @MainActor func roundTrip_dictationHotkeyMode() {
        Self.clearV12Keys()
        defer { Self.clearV12Keys() }
        let s1 = AppSettings()
        s1.dictationHotkeyMode = .pressAndHold
        let s2 = AppSettings()
        #expect(s2.dictationHotkeyMode == .pressAndHold)
    }

    @Test @MainActor func roundTrip_clipboardRestoreDelay() {
        Self.clearV12Keys()
        defer { Self.clearV12Keys() }
        let s1 = AppSettings()
        s1.clipboardRestoreDelay = 5.5
        let s2 = AppSettings()
        #expect(s2.clipboardRestoreDelay == 5.5)
    }

    @Test @MainActor func roundTrip_installedModelVersion() {
        Self.clearV12Keys()
        defer { Self.clearV12Keys() }
        let s1 = AppSettings()
        s1.installedModelVersion = "abc123"
        let s2 = AppSettings()
        #expect(s2.installedModelVersion == "abc123")
    }

    @Test @MainActor func roundTrip_modelLastCheckedDate() {
        Self.clearV12Keys()
        defer { Self.clearV12Keys() }
        let known = Date(timeIntervalSince1970: 1_700_000_000)  // 2023-11-14T22:13:20Z
        let s1 = AppSettings()
        s1.modelLastCheckedDate = known
        let s2 = AppSettings()
        let restored = s2.modelLastCheckedDate
        #expect(restored != nil)
        if let restored {
            #expect(abs(restored.timeIntervalSince(known)) < 1.0)
        }
    }

    @Test @MainActor func modelLastCheckedDateNilClearsKey() {
        Self.clearV12Keys()
        defer { Self.clearV12Keys() }
        let s1 = AppSettings()
        s1.modelLastCheckedDate = Date()
        s1.modelLastCheckedDate = nil
        #expect(UserDefaults.standard.object(forKey: "modelLastCheckedDate") == nil)
        let s2 = AppSettings()
        #expect(s2.modelLastCheckedDate == nil)
    }

    @Test @MainActor func roundTrip_modelAutoUpdateEnabledFalse() {
        Self.clearV12Keys()
        defer { Self.clearV12Keys() }
        let s1 = AppSettings()
        s1.modelAutoUpdateEnabled = false
        let s2 = AppSettings()
        #expect(s2.modelAutoUpdateEnabled == false)
    }

    @Test @MainActor func roundTrip_modelAutoUpdateEnabledRestoresTrue() {
        Self.clearV12Keys()
        defer { Self.clearV12Keys() }
        let s1 = AppSettings()
        s1.modelAutoUpdateEnabled = false
        s1.modelAutoUpdateEnabled = true
        let s2 = AppSettings()
        #expect(s2.modelAutoUpdateEnabled == true)
    }

    // MARK: - v1.2 Appearance Override (Phase 25 NYQUIST-07)

    @Test @MainActor func roundTrip_appearancePreferenceLight() {
        Self.clearV12Keys()
        defer { Self.clearV12Keys() }
        let s1 = AppSettings()
        s1.appearancePreference = .light
        let s2 = AppSettings()
        #expect(s2.appearancePreference == .light)
    }

    @Test @MainActor func roundTrip_appearancePreferenceDark() {
        Self.clearV12Keys()
        defer { Self.clearV12Keys() }
        let s1 = AppSettings()
        s1.appearancePreference = .dark
        let s2 = AppSettings()
        #expect(s2.appearancePreference == .dark)
    }

    @Test @MainActor func appearancePreferenceMissingKeyFallsBackToSystem() {
        Self.clearV12Keys()
        defer { Self.clearV12Keys() }
        // Phase 25 NYQUIST-07 / REQ-21.6: Simulate fresh-from-Phase-20 install -- no key in UD.
        #expect(UserDefaults.standard.object(forKey: "appearancePreference") == nil)
        let s = AppSettings()
        #expect(s.appearancePreference == .system)
    }
}
