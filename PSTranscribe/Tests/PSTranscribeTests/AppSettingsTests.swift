import Testing
import Foundation
@testable import PSTranscribe

@Suite("AppSettings v1.2 keys", .serialized)
struct AppSettingsTests {

    // List of v1.2 UserDefaults keys this suite touches. Cleared before/after each test.
    private static let v12Keys = [
        "dictationOutputMode",
        "dictationFolderPath",
        "dictationHotkeyMode",
        "clipboardRestoreDelay",
        "installedModelVersion",
        "modelLastCheckedDate",
        "modelAutoUpdateEnabled",
    ]

    fileprivate static func clearV12Keys() {
        for key in v12Keys { UserDefaults.standard.removeObject(forKey: key) }
    }

    // MARK: - Defaults

    @Suite("defaults", .serialized)
    struct Defaults {
        @Test @MainActor func dictationOutputMode() {
            AppSettingsTests.clearV12Keys()
            defer { AppSettingsTests.clearV12Keys() }
            let s = AppSettings()
            #expect(s.dictationOutputMode == .clipboard)
        }

        @Test @MainActor func dictationFolderPath() {
            AppSettingsTests.clearV12Keys()
            defer { AppSettingsTests.clearV12Keys() }
            let s = AppSettings()
            #expect(s.dictationFolderPath.hasSuffix("Documents/PS Transcribe Dictations"))
            #expect(!s.dictationFolderPath.contains("~"))  // tilde must be expanded
        }

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
    }

    // MARK: - Round-trips

    @Test @MainActor func roundTrip_dictationOutputMode() {
        Self.clearV12Keys()
        defer { Self.clearV12Keys() }
        let s1 = AppSettings()
        s1.dictationOutputMode = .both
        let s2 = AppSettings()
        #expect(s2.dictationOutputMode == .both)
    }

    @Test @MainActor func roundTrip_dictationFolderPath() {
        Self.clearV12Keys()
        defer { Self.clearV12Keys() }
        let path = "/tmp/dictation-test-\(UUID().uuidString)"
        let s1 = AppSettings()
        s1.dictationFolderPath = path
        let s2 = AppSettings()
        #expect(s2.dictationFolderPath == path)
    }

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
}
