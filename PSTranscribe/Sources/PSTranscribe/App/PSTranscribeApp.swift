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
        // Phase 21 D-07: keep the Dictation HUD's NSPanel appearance in sync with the
        // user's appearance preference. The HUD lives outside the SwiftUI scene graph,
        // so the .preferredColorScheme calls at the Scene roots in `body` don't reach
        // it. We bridge via NSAppearance, which is the AppKit-native equivalent and
        // also drives `.hudWindow` material rendering. Initial application is
        // synchronous; subsequent changes are observed via `withObservationTracking`,
        // which re-arms after each fire (the @Observable pattern).
        initialWindowCtrl.applyAppearance(initialSettings.appearancePreference)
        observeAppearance(controller: initialWindowCtrl, settings: initialSettings)
        // Phase 21 CR-01 / WR-04: bridge the AppKit-owned main-window titlebar
        // (Chronicle paper bg + dark title text) through the same appearance
        // preference. The titlebar is configured via NSWindow / NSToolbar APIs
        // outside the SwiftUI scene graph, so the .preferredColorScheme calls in
        // `body` don't reach it. AppDelegate.applyChronicleTitlebar runs on
        // applicationDidFinishLaunching + didBecomeKeyNotification only -- it
        // never re-fires on settings changes. This observer covers that gap by
        // iterating NSApp.windows and re-applying titlebar styling whenever the
        // user toggles the preference.
        observeChronicleTitlebar(settings: initialSettings)
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
                .preferredColorScheme(settings.appearancePreference.colorScheme)
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
            .preferredColorScheme(settings.appearancePreference.colorScheme)
        }
        MenuBarExtra {
            Group {
                Text("PS Transcribe")
                    .font(.headline)
                Divider()
                Button("Quit PS Transcribe") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .preferredColorScheme(settings.appearancePreference.colorScheme)
        } label: {
            // Phase 18 DICT-03: pulsing mic when dictation is active.
            Image(systemName: dictationCoordinator.isActive ? "mic.fill" : "book.closed")
                .symbolRenderingMode(.monochrome)
                .symbolEffect(.pulse, isActive: dictationCoordinator.isActive)
        }
    }
}

/// Phase 21 D-07: re-arming `withObservationTracking` loop that mirrors
/// `AppSettings.appearancePreference` onto the Dictation HUD's NSPanel via
/// `NSAppearance`. The `@Observable` macro emits a registration whenever the
/// tracked block reads `settings.appearancePreference`; the `onChange` closure
/// fires once per mutation; we re-call ourselves to re-register and capture the
/// next change. Loop is bounded by the lifetime of the controller + settings,
/// both of which are app-scoped (live for the whole process).
@MainActor
private func observeAppearance(
    controller: DictationWindowController,
    settings: AppSettings
) {
    withObservationTracking {
        // Read the property to register the dependency. We don't apply it here;
        // the synchronous initial application is the caller's responsibility, and
        // `onChange` handles every subsequent mutation.
        _ = settings.appearancePreference
    } onChange: {
        // `onChange` is non-isolated; hop back to MainActor before mutating
        // AppKit windows or recursing.
        Task { @MainActor in
            controller.applyAppearance(settings.appearancePreference)
            observeAppearance(controller: controller, settings: settings)
        }
    }
}

/// Phase 21 CR-01 / WR-04: re-arming `withObservationTracking` loop that
/// re-applies `AppDelegate.applyChronicleTitlebar` to every `NSApp.windows`
/// member whenever `AppSettings.appearancePreference` changes.
///
/// The Chronicle titlebar (cream paper background, custom NSToolbar centered
/// title) lives in AppKit, outside the SwiftUI scene graph. `applyChronicleTitlebar`
/// runs only at `applicationDidFinishLaunching` and on `didBecomeKeyNotification`.
/// Without this observer, toggling the appearance picker after launch would
/// leave the titlebar stuck in whatever palette was painted last -- breaking
/// the SPEC §2 "every surface receives the override" invariant.
///
/// Mirrors `observeAppearance(controller:settings:)` (the HUD bridge): same
/// re-arming pattern, same MainActor hop, same lifetime bound (settings is
/// app-scoped, so the loop terminates with the process).
@MainActor
private func observeChronicleTitlebar(settings: AppSettings) {
    withObservationTracking {
        _ = settings.appearancePreference
    } onChange: {
        Task { @MainActor in
            for window in NSApp.windows {
                AppDelegate.applyChronicleTitlebar(to: window)
            }
            observeChronicleTitlebar(settings: settings)
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
    ///
    /// Phase 21 CR-01: bridges the AppKit-owned titlebar through the user's
    /// `AppearancePreference`. `window.appearance` is set from the preference so
    /// the system titlebar chrome (toolbar buttons, traffic lights) and the
    /// `effectiveAppearance` bookkeeping flip with the picker. The cream paper
    /// background is only painted when the resolved `effectiveAppearance` is
    /// Aqua; in Dark we clear `backgroundColor` so the system titlebar material
    /// shows through. The toolbar title text uses `NSColor.labelColor` (a
    /// dynamic system color) instead of an absolute RGB value so it adapts.
    static func applyChronicleTitlebar(to window: NSWindow) {
        // Settings window keeps its native style but gets a branded title.
        let isSettings = window.title == "Settings"
            || window.title == "PS Transcribe - Settings"
            || window.identifier?.rawValue.contains("settings") == true
        if isSettings {
            window.title = "PS Transcribe - Settings"
            return
        }

        // Phase 21 CR-01: bridge appearance preference onto the AppKit window.
        // Read directly from UserDefaults so this static helper has no compile-time
        // dependency on AppSettings -- AppSettings owns the source of truth and
        // `observeChronicleTitlebar` re-invokes us on every change.
        let appearancePref = AppearancePreference(
            rawValue: UserDefaults.standard.string(forKey: "appearancePreference") ?? AppearancePreference.system.rawValue
        ) ?? .system
        switch appearancePref {
        case .system: window.appearance = nil
        case .light:  window.appearance = NSAppearance(named: .aqua)
        case .dark:   window.appearance = NSAppearance(named: .darkAqua)
        }

        window.titleVisibility = .hidden // NSToolbar item supplies the visible title
        window.titlebarAppearsTransparent = true
        // Do NOT insert fullSizeContentView: we want the paper window bg to fill
        // the titlebar strip, not the SwiftUI content (which has per-column tints).
        window.styleMask.remove(.fullSizeContentView)
        window.isMovableByWindowBackground = true

        // Only paint the Chronicle cream in light contexts. In dark, defer to the
        // system titlebar material (window.backgroundColor = nil). bestMatch reads
        // the just-assigned `window.appearance` (or the inherited app appearance
        // when the preference is .system), so this gates correctly across all
        // three picker values.
        let resolved = window.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua])
        if resolved == .darkAqua {
            window.backgroundColor = nil
        } else {
            window.backgroundColor = NSColor(red: 0xFA/255, green: 0xFA/255, blue: 0xF7/255, alpha: 1)
        }

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
        // Phase 21 CR-01: use the dynamic system label color so the title text
        // adapts to the window's effective appearance (Light vs Dark) without an
        // explicit branch. Replaces the Phase-pre-21 absolute RGB literal that
        // ignored the user's appearance preference.
        label.textColor = NSColor.labelColor
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
