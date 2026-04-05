import SwiftUI
import AppKit
import Sparkle

@main
struct PSTranscribeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var settings: AppSettings
    private let updaterController = AppUpdaterController()

    init() {
        PSTranscribeApp.migrateUserDefaultsIfNeeded()
        _settings = State(initialValue: AppSettings())
    }

    var body: some Scene {
        WindowGroup {
            ContentView(settings: settings)
                .onAppear {
                    settings.applyScreenShareVisibility()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 720, height: 500)
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
        Settings {
            SettingsView(settings: settings, updater: updaterController.updater)
        }
        MenuBarExtra {
            Text("PS Transcribe")
                .font(.headline)
            Divider()
            Button("Quit PS Transcribe") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Image(systemName: "book.closed")
                .symbolRenderingMode(.monochrome)
        }
    }
    private static func migrateUserDefaultsIfNeeded() {
        let oldDomain = "io.gremble.tome"
        let sentinelKey = "hasMigratedFromTome"

        // Already migrated -- skip
        guard !UserDefaults.standard.bool(forKey: sentinelKey) else { return }

        // Open the old bundle ID's UserDefaults domain
        guard let oldDefaults = UserDefaults(suiteName: oldDomain) else { return }

        // Only migrate keys AppSettings and ContentView actually read
        let keysToMigrate = [
            "transcriptionLocale",
            "inputDeviceID",
            "vaultMeetingsPath",
            "vaultVoicePath",
            "hideFromScreenShare",
            "hasCompletedOnboarding",
        ]

        let newDefaults = UserDefaults.standard
        for key in keysToMigrate {
            if let value = oldDefaults.object(forKey: key) {
                newDefaults.set(value, forKey: key)
            }
        }

        // Mark migration complete
        newDefaults.set(true, forKey: sentinelKey)
        newDefaults.synchronize()

        // Delete old keys (clean break, no rollback)
        for key in keysToMigrate {
            oldDefaults.removeObject(forKey: key)
        }
        oldDefaults.synchronize()
    }
}

/// Observes new window creation and applies screen-share visibility setting.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowObserver: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let hidden = UserDefaults.standard.object(forKey: "hideFromScreenShare") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "hideFromScreenShare")
        let sharingType: NSWindow.SharingType = hidden ? .none : .readOnly

        for window in NSApp.windows {
            window.sharingType = sharingType
        }

        // Watch for new windows being created (e.g. Settings window)
        windowObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                let hide = UserDefaults.standard.object(forKey: "hideFromScreenShare") == nil
                    ? true
                    : UserDefaults.standard.bool(forKey: "hideFromScreenShare")
                let type: NSWindow.SharingType = hide ? .none : .readOnly
                for window in NSApp.windows {
                    window.sharingType = type
                }
            }
        }
    }
}
