import SwiftUI
import AppKit
import Sparkle

@main
struct PSTranscribeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var settings: AppSettings
    @State private var libraryStore: LibraryStore               // Phase 16, D-12
    @State private var sessionCoordinator: SessionCoordinator   // Phase 16, D-07
    @State private var modelUpdateService: ModelUpdateService   // Phase 17, D-18
    @State private var globalHotkey: GlobalHotkeyService        // Phase 18
    @State private var dictationCoordinator: DictationCoordinator  // Phase 18
    @State private var dictationWindowController: DictationWindowController  // Phase 18
    @State private var saveDestinations: SaveDestinations          // Phase 18.1, D-18
    private let updaterController = AppUpdaterController()
    @State private var notionService: NotionService
    @State private var escapeKeyMonitor: Any?

    init() {
        let initialSettings = AppSettings()
        let initialLibrary = LibraryStore()
        let initialCoordinator = SessionCoordinator()
        let initialNotion = NotionService()
        let initialModelUpdate = ModelUpdateService(
            settings: initialSettings,
            engine: nil,                            // late-bound in ContentView .task
            sessionCoordinator: initialCoordinator
        )
        let initialHotkey = GlobalHotkeyService()
        // Phase 18.1 D-18: shared destination fan-out lives at app scope so every
        // content producer (dictation, meeting/memo) routes through the same instance.
        let initialSaveDestinations = SaveDestinations(
            settings: initialSettings,
            notionService: initialNotion
        )
        let initialDictation = DictationCoordinator(
            settings: initialSettings,
            sessionCoordinator: initialCoordinator,
            libraryStore: initialLibrary,
            saveDestinations: initialSaveDestinations
        )
        let initialWindowCtrl = DictationWindowController(rootView: AnyView(EmptyView()))
        // Wire HUD body to the coordinator's live state.
        initialDictation.attach(windowController: initialWindowCtrl)
        initialDictation.hotkeyService = initialHotkey
        // Phase 18 D-14: SessionCoordinator.dictation is the mutual-exclusion gate.
        initialCoordinator.dictation = initialDictation

        _settings = State(initialValue: initialSettings)
        _libraryStore = State(initialValue: initialLibrary)
        _sessionCoordinator = State(initialValue: initialCoordinator)
        _modelUpdateService = State(initialValue: initialModelUpdate)
        _globalHotkey = State(initialValue: initialHotkey)
        _dictationCoordinator = State(initialValue: initialDictation)
        _dictationWindowController = State(initialValue: initialWindowCtrl)
        _saveDestinations = State(initialValue: initialSaveDestinations)
        _notionService = State(initialValue: initialNotion)

        // Phase 18 — wire hotkey callbacks. We capture the dictation coordinator and
        // settings; both are app-scoped so a strong capture is fine for the lifetime
        // of the GlobalHotkeyService (which is itself app-scoped).
        initialHotkey.onKeyDown = { [initialDictation, initialSettings] in
            Task { @MainActor in
                switch initialSettings.dictationHotkeyMode {
                case .toggle:
                    if initialDictation.isActive {
                        await initialDictation.endDictation()
                    } else {
                        await initialDictation.beginDictation()
                    }
                case .pressAndHold:
                    await initialDictation.beginDictation()
                }
            }
        }
        initialHotkey.onKeyUp = { [initialDictation, initialSettings] in
            Task { @MainActor in
                if case .pressAndHold = initialSettings.dictationHotkeyMode {
                    await initialDictation.handleHoldRelease()
                }
                // toggle mode: ignore key-up entirely.
            }
        }

        // Phase 18 — Escape-key global monitor. Fires regardless of which app is frontmost
        // (the HUD is shown via .nonactivatingPanel so our app is never frontmost during
        // dictation). Global monitors are observe-only (cannot consume events); Esc still
        // propagates to the focused app, which in most apps is a no-op or popover dismiss.
        let monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [initialDictation] event in
            // .keyCode 53 = Escape (kVK_Escape).
            guard event.keyCode == 53 else { return }
            Task { @MainActor in
                if initialDictation.isActive {
                    await initialDictation.handleEscape()
                }
            }
        }
        _escapeKeyMonitor = State(initialValue: monitor)

        // Phase 18 D-13 — eager pre-warm at app launch with privacy-conscious opt-out.
        // RESEARCH Open Question §2 RESOLVED: 2 s sleep gives the meeting engine's first
        // prepareModels a head start before we touch the same model cache.
        // CONTEXT <specifics> + WARNING #11: skip pre-warm if the user has explicitly
        // cleared the hotkey via Recorder. D-13's "always pre-warm" applies to the default
        // user; users who clear the hotkey have opted out by action.
        let dictForPrewarm = initialDictation
        let hotkeyForPrewarm = initialHotkey
        Task.detached(priority: .background) {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                guard hotkeyForPrewarm.hotkeyAssigned else { return () }
                Task { @MainActor in
                    // User has a hotkey assigned — pay the ~500MB pre-warm cost so the
                    // first hotkey press is instant. If pre-warm fails, beginDictation
                    // falls through to D-16's "Loading model…" path.
                    await dictForPrewarm.preWarmModels()
                }
            }
        }
    }

    /// Opens a bundled license resource (e.g. "LICENSE" or "ThirdPartyLicenses")
    /// in the user's default .txt viewer. Extensions are tried in preference order.
    static func openBundledResource(named base: String) {
        let bundle = Bundle.main
        let candidates = ["txt", "md", ""]
        for ext in candidates {
            if let url = bundle.url(forResource: base, withExtension: ext.isEmpty ? nil : ext) {
                NSWorkspace.shared.open(url)
                return
            }
        }
        // Fall back to a quick alert if the file is missing from the bundle.
        let alert = NSAlert()
        alert.messageText = "File not found"
        alert.informativeText = "\(base) isn't bundled with this build."
        alert.runModal()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                settings: settings,
                notionService: notionService,
                libraryStore: libraryStore,
                sessionCoordinator: sessionCoordinator,
                modelUpdateService: modelUpdateService,
                saveDestinations: saveDestinations
            )
                .onAppear {
                    settings.applyScreenShareVisibility()
                }
        }
        .defaultSize(width: 1280, height: 820)
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
            // Help → License and Third-party notices. Required to satisfy
            // upstream MIT / Apache 2.0 attribution for shipped binaries.
            CommandGroup(after: .help) {
                Divider()
                Button("License…") { Self.openBundledResource(named: "LICENSE") }
                Button("Third-party Licenses…") { Self.openBundledResource(named: "ThirdPartyLicenses") }
            }
        }
        Settings {
            SettingsView(
                settings: settings,
                updater: updaterController.updater,
                notionService: notionService,
                modelUpdateService: modelUpdateService
            )
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
            // Phase 18 DICT-03: pulsing mic when dictation is active.
            Image(systemName: dictationCoordinator.isActive ? "mic.fill" : "book.closed")
                .symbolRenderingMode(.monochrome)
                .symbolEffect(.pulse, isActive: dictationCoordinator.isActive)
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
