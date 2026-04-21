import SwiftUI
import AppKit
import Sparkle

@main
struct PSTranscribeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var settings: AppSettings
    private let updaterController = AppUpdaterController()
    @State private var notionService = NotionService()

    init() {
        _settings = State(initialValue: AppSettings())
    }

    var body: some Scene {
        WindowGroup {
            ContentView(settings: settings, notionService: notionService)
                .onAppear {
                    settings.applyScreenShareVisibility()
                }
        }
        .defaultSize(width: 1280, height: 820)
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
        Settings {
            SettingsView(settings: settings, updater: updaterController.updater, notionService: notionService)
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
}

/// Observes new window creation and applies screen-share visibility setting.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowObserver: Any?
    /// Retained because NSToolbar's delegate is held weakly.
    private static let titlebarDelegate = ChronicleTitlebarDelegate()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let hidden = UserDefaults.standard.object(forKey: "hideFromScreenShare") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "hideFromScreenShare")
        let sharingType: NSWindow.SharingType = hidden ? .none : .readOnly

        for window in NSApp.windows {
            window.sharingType = sharingType
            Self.applyChronicleTitlebar(to: window)
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
                    Self.applyChronicleTitlebar(to: window)
                }
            }
        }
    }

    /// Chronicle titlebar: paper bg, centered "PS Transcribe" title via NSToolbar.
    /// Only applies to the main window (not Settings).
    static func applyChronicleTitlebar(to window: NSWindow) {
        // Settings window keeps its native style but gets a branded title.
        let isSettings = window.title == "Settings"
            || window.title == "PS Transcribe - Settings"
            || window.identifier?.rawValue.contains("settings") == true
        if isSettings {
            window.title = "PS Transcribe - Settings"
            return
        }

        window.titleVisibility = .hidden // NSToolbar item supplies the visible title
        window.titlebarAppearsTransparent = true
        // Do NOT insert fullSizeContentView: we want the paper window bg to fill
        // the titlebar strip, not the SwiftUI content (which has per-column tints).
        window.styleMask.remove(.fullSizeContentView)
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(red: 0xFA/255, green: 0xFA/255, blue: 0xF7/255, alpha: 1)

        if window.toolbar?.identifier != ChronicleTitlebarDelegate.toolbarID {
            let toolbar = NSToolbar(identifier: ChronicleTitlebarDelegate.toolbarID)
            toolbar.delegate = titlebarDelegate
            toolbar.displayMode = .iconOnly
            toolbar.allowsUserCustomization = false
            if #available(macOS 11.0, *) {
                toolbar.centeredItemIdentifier = ChronicleTitlebarDelegate.titleItemID
            }
            window.toolbarStyle = .unified
            window.toolbar = toolbar
        }
    }
}

/// NSToolbar delegate that supplies a single centered title item.
final class ChronicleTitlebarDelegate: NSObject, NSToolbarDelegate {
    static let toolbarID = "ChronicleTitlebar"
    static let titleItemID = NSToolbarItem.Identifier("chronicle.title")

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [Self.titleItemID]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [Self.titleItemID]
    }

    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard itemIdentifier == Self.titleItemID else { return nil }

        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        let label = NSTextField(labelWithString: "PS Transcribe")
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = NSColor(red: 0x1A/255, green: 0x1A/255, blue: 0x17/255, alpha: 1)
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        item.view = label
        item.label = "PS Transcribe"
        item.paletteLabel = "Title"
        return item
    }
}
