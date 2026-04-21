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
