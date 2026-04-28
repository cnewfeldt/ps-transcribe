import AppKit
import Foundation
import Observation
import CoreAudio

@Observable
@MainActor
final class AppSettings {
    var transcriptionLocale: String {
        didSet { UserDefaults.standard.set(transcriptionLocale, forKey: "transcriptionLocale") }
    }

    /// Stored as the AudioDeviceID integer. 0 means "use system default".
    var inputDeviceID: AudioDeviceID {
        didSet { UserDefaults.standard.set(Int(inputDeviceID), forKey: "inputDeviceID") }
    }

    var vaultMeetingsPath: String {
        didSet { UserDefaults.standard.set(vaultMeetingsPath, forKey: "vaultMeetingsPath") }
    }

    var vaultVoicePath: String {
        didSet { UserDefaults.standard.set(vaultVoicePath, forKey: "vaultVoicePath") }
    }

    /// When true, all app windows are invisible to screen sharing / recording.
    var hideFromScreenShare: Bool {
        didSet {
            UserDefaults.standard.set(hideFromScreenShare, forKey: "hideFromScreenShare")
            applyScreenShareVisibility()
        }
    }

    var lastUsedSessionType: SessionType {
        didSet {
            UserDefaults.standard.set(lastUsedSessionType.rawValue, forKey: "lastUsedSessionType")
        }
    }

    /// Notion database ID (not a secret -- stored in UserDefaults, not Keychain).
    var notionDatabaseID: String {
        didSet { UserDefaults.standard.set(notionDatabaseID, forKey: "notionDatabaseID") }
    }

    /// When true, finalized recordings are auto-sent to Notion with empty tags.
    /// Users can still open the entry and use "Resend to Notion" to add tags afterward.
    var notionAutoSendEnabled: Bool {
        didSet { UserDefaults.standard.set(notionAutoSendEnabled, forKey: "notionAutoSendEnabled") }
    }

    // MARK: - v1.2 Dictation Settings (Phase 16, D-03 / D-04)

    /// Dictation output destination. Default `.clipboard` (D-08): plain folder is opt-in.
    var dictationOutputMode: DictationOutputMode {
        didSet { UserDefaults.standard.set(dictationOutputMode.rawValue, forKey: "dictationOutputMode") }
    }

    /// Plain-markdown output folder for hotkey dictation. Default `~/Documents/PS Transcribe Dictations`
    /// (matches Phase 19 success criterion #4). Folder is created on first dictation save (Phase 18 owns creation),
    /// not on app launch.
    var dictationFolderPath: String {
        didSet { UserDefaults.standard.set(dictationFolderPath, forKey: "dictationFolderPath") }
    }

    /// Hotkey activation model. Default `.toggle` (research-locked).
    var dictationHotkeyMode: DictationHotkeyMode {
        didSet { UserDefaults.standard.set(dictationHotkeyMode.rawValue, forKey: "dictationHotkeyMode") }
    }

    /// Seconds to wait after dictation paste before restoring the prior clipboard contents (DICT-06).
    /// Default 3.0 seconds.
    var clipboardRestoreDelay: TimeInterval {
        didSet { UserDefaults.standard.set(clipboardRestoreDelay, forKey: "clipboardRestoreDelay") }
    }

    // MARK: - v1.2 Model Auto-Update Settings (Phase 16, D-04)

    /// SHA / version identifier of the currently installed FluidAudio model. Empty until first
    /// successful download. Phase 17 reads/writes this; Phase 16 only declares it.
    var installedModelVersion: String {
        didSet { UserDefaults.standard.set(installedModelVersion, forKey: "installedModelVersion") }
    }

    /// Last time the app checked the model manifest. nil = never checked. Drives the 24-hour
    /// throttle in MODEL-01. Phase 17 reads/writes this; Phase 16 only declares it.
    var modelLastCheckedDate: Date? {
        didSet {
            if let d = modelLastCheckedDate {
                UserDefaults.standard.set(d, forKey: "modelLastCheckedDate")
            } else {
                UserDefaults.standard.removeObject(forKey: "modelLastCheckedDate")
            }
        }
    }

    // MARK: - v1.2 Model Auto-Update Settings (Phase 17, D-11)

    /// User toggle for automatic model update checks. When false, both the launch auto-check
    /// and the opportunistic check on Settings open are suppressed; the manual button still
    /// works (D-12 / D-13). Default true. Phase 17 D-11. UserDefaults key `"modelAutoUpdateEnabled"`.
    var modelAutoUpdateEnabled: Bool {
        didSet { UserDefaults.standard.set(modelAutoUpdateEnabled, forKey: "modelAutoUpdateEnabled") }
    }

    init() {
        let defaults = UserDefaults.standard
        self.transcriptionLocale = defaults.string(forKey: "transcriptionLocale") ?? "en-US"
        self.inputDeviceID = AudioDeviceID(defaults.integer(forKey: "inputDeviceID"))
        self.vaultMeetingsPath = defaults.string(forKey: "vaultMeetingsPath") ?? NSString("~/Documents/PSTranscribe/Meetings").expandingTildeInPath
        self.vaultVoicePath = defaults.string(forKey: "vaultVoicePath") ?? NSString("~/Documents/PSTranscribe/Voice").expandingTildeInPath
        // Default to true (hidden) if key has never been set
        if defaults.object(forKey: "hideFromScreenShare") == nil {
            self.hideFromScreenShare = true
        } else {
            self.hideFromScreenShare = defaults.bool(forKey: "hideFromScreenShare")
        }
        let rawType = defaults.string(forKey: "lastUsedSessionType") ?? SessionType.callCapture.rawValue
        self.lastUsedSessionType = SessionType(rawValue: rawType) ?? .callCapture
        self.notionDatabaseID = defaults.string(forKey: "notionDatabaseID") ?? ""
        self.notionAutoSendEnabled = defaults.bool(forKey: "notionAutoSendEnabled")

        // v1.2 Dictation keys (Phase 16, D-04)
        let dictationModeRaw = defaults.string(forKey: "dictationOutputMode")
            ?? DictationOutputMode.clipboard.rawValue
        self.dictationOutputMode = DictationOutputMode(rawValue: dictationModeRaw) ?? .clipboard

        self.dictationFolderPath = defaults.string(forKey: "dictationFolderPath")
            ?? NSString("~/Documents/PS Transcribe Dictations").expandingTildeInPath

        let hotkeyModeRaw = defaults.string(forKey: "dictationHotkeyMode")
            ?? DictationHotkeyMode.toggle.rawValue
        self.dictationHotkeyMode = DictationHotkeyMode(rawValue: hotkeyModeRaw) ?? .toggle

        // TimeInterval (Double) -- UserDefaults.double returns 0.0 for missing keys, so check object presence.
        if defaults.object(forKey: "clipboardRestoreDelay") == nil {
            self.clipboardRestoreDelay = 3.0
        } else {
            self.clipboardRestoreDelay = defaults.double(forKey: "clipboardRestoreDelay")
        }

        // v1.2 Model Update keys (Phase 16, D-04) -- declared only; Phase 17 wires consumption.
        self.installedModelVersion = defaults.string(forKey: "installedModelVersion") ?? ""
        self.modelLastCheckedDate = defaults.object(forKey: "modelLastCheckedDate") as? Date

        // v1.2 modelAutoUpdateEnabled (Phase 17, D-11). Default true if key has never been set.
        // bool(forKey:) returns false for missing keys, so we must check for key presence first.
        if defaults.object(forKey: "modelAutoUpdateEnabled") == nil {
            self.modelAutoUpdateEnabled = true
        } else {
            self.modelAutoUpdateEnabled = defaults.bool(forKey: "modelAutoUpdateEnabled")
        }
    }

    /// Apply current screen-share visibility to all app windows.
    func applyScreenShareVisibility() {
        let type: NSWindow.SharingType = hideFromScreenShare ? .none : .readOnly
        for window in NSApp.windows {
            window.sharingType = type
        }
    }

    var vaultMeetingsURL: URL? {
        guard !vaultMeetingsPath.isEmpty else { return nil }
        return URL(fileURLWithPath: vaultMeetingsPath)
    }

    var vaultVoiceURL: URL? {
        guard !vaultVoicePath.isEmpty else { return nil }
        return URL(fileURLWithPath: vaultVoicePath)
    }

    var locale: Locale {
        Locale(identifier: transcriptionLocale)
    }
}
