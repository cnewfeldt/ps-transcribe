import AppKit
import Foundation
import Observation
import CoreAudio
import SwiftUI

/// User-controlled appearance preference (Phase 21, D-08).
///
/// `.system` is the default and resolves to `nil` so `.preferredColorScheme(nil)`
/// is a SwiftUI no-op — preserving Phase 20's system-following behavior byte-for-byte.
/// `.light` and `.dark` force the chosen scheme app-wide via the modifier applied at
/// each Scene root in `PSTranscribeApp.body` (D-05) and via `NSAppearance(named:)`
/// on the Dictation HUD's NSPanel (D-07).
enum AppearancePreference: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }

    /// SwiftUI bridge: `.system` returns `nil` (no override), the others map to
    /// their `ColorScheme` peers.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

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

    // MARK: - v1.2 Save Destinations (Phase 18.1, D-06 / D-10)

    /// Local File destination toggle. Default `true` (D-06): meetings + voice memos work
    /// out of the box without setup. UserDefaults key `"localFileEnabled"`.
    var localFileEnabled: Bool {
        didSet { UserDefaults.standard.set(localFileEnabled, forKey: "localFileEnabled") }
    }

    /// Root folder for the Local File destination. Hardcoded subfolders `Meeting/`,
    /// `Memo/`, `Dictation/` are created lazily on first write per content type
    /// (D-04 / D-06). Default expands to `~/Documents/PSTranscribe`. UserDefaults
    /// key `"localFileRoot"`.
    var localFileRoot: String {
        didSet { UserDefaults.standard.set(localFileRoot, forKey: "localFileRoot") }
    }

    /// Obsidian destination toggle. Default `false` (D-10): Obsidian is opt-in --
    /// not all users have a vault. UserDefaults key `"obsidianEnabled"`.
    var obsidianEnabled: Bool {
        didSet { UserDefaults.standard.set(obsidianEnabled, forKey: "obsidianEnabled") }
    }

    /// Single Obsidian folder for all content types. Replaces the v1.0
    /// `vaultMeetingsPath` + `vaultVoicePath` pair (D-07 / D-10). Default `""`
    /// (no folder picked yet). Content-type tagging happens via YAML
    /// `session-type:` frontmatter (D-08), not via separate folders.
    /// UserDefaults key `"obsidianFolderPath"`.
    var obsidianFolderPath: String {
        didSet { UserDefaults.standard.set(obsidianFolderPath, forKey: "obsidianFolderPath") }
    }

    // MARK: - v1.2 Dictation Settings (Phase 16, D-03 / D-04)

    /// Hotkey activation model. Default `.toggle` (research-locked).
    var dictationHotkeyMode: DictationHotkeyMode {
        didSet { UserDefaults.standard.set(dictationHotkeyMode.rawValue, forKey: "dictationHotkeyMode") }
    }

    // MARK: - v1.2 Appearance Override (Phase 21, D-08 / D-09)

    /// User-controlled app-wide appearance preference. `.system` (default) preserves
    /// Phase 20's system-following behavior. `.light` / `.dark` force the chosen scheme
    /// at every SwiftUI scene root and on the Dictation HUD's NSPanel.
    /// UserDefaults key `"appearancePreference"`.
    var appearancePreference: AppearancePreference {
        didSet { UserDefaults.standard.set(appearancePreference.rawValue, forKey: "appearancePreference") }
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

        // v1.2 Save Destinations (Phase 18.1, D-06 / D-10)
        // No migration -- app not yet released to users (D-17 rip-and-replace).
        if defaults.object(forKey: "localFileEnabled") == nil {
            self.localFileEnabled = true  // D-06
        } else {
            self.localFileEnabled = defaults.bool(forKey: "localFileEnabled")
        }
        self.localFileRoot = defaults.string(forKey: "localFileRoot")
            ?? NSString("~/Documents/PSTranscribe").expandingTildeInPath  // D-06
        if defaults.object(forKey: "obsidianEnabled") == nil {
            self.obsidianEnabled = false  // D-10
        } else {
            self.obsidianEnabled = defaults.bool(forKey: "obsidianEnabled")
        }
        self.obsidianFolderPath = defaults.string(forKey: "obsidianFolderPath") ?? ""  // D-10

        // v1.2 Dictation keys (Phase 16, D-04)
        let hotkeyModeRaw = defaults.string(forKey: "dictationHotkeyMode")
            ?? DictationHotkeyMode.toggle.rawValue
        self.dictationHotkeyMode = DictationHotkeyMode(rawValue: hotkeyModeRaw) ?? .toggle

        // v1.2 Appearance Override (Phase 21, D-08 / D-09)
        let appearanceRaw = defaults.string(forKey: "appearancePreference")
            ?? AppearancePreference.system.rawValue
        self.appearancePreference = AppearancePreference(rawValue: appearanceRaw) ?? .system

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

    var locale: Locale {
        Locale(identifier: transcriptionLocale)
    }
}
