import AppKit
import SwiftUI

/// Owns the floating dictation HUD `NSPanel` lifecycle.
///
/// The panel:
/// - Floats above other apps without stealing focus (`.nonactivatingPanel`)
/// - Is visible across spaces, including fullscreen apps (`.canJoinAllSpaces`, `.fullScreenAuxiliary`)
/// - Renders native macOS HUD vibrancy via `NSVisualEffectView` (`.hudWindow` material, D-03)
/// - Sits bottom-center of `NSScreen.main`'s `visibleFrame`, centered within the bottom quarter (D-04)
/// - Is invisible to legacy `CGWindowListCreateImage` screen capture via `sharingType = .none` (DICT-10)
///
/// The `sharingType = .none` is set explicitly at creation because `.nonactivatingPanel`
/// never becomes a "key" window, so the AppDelegate's `didBecomeKeyNotification` observer
/// (PSTranscribeApp.swift:116-131) never fires for the HUD. Setting it directly is the only
/// reliable path. ScreenCaptureKit-based recording (Zoom, Teams, OBS) WILL capture the HUD --
/// this is a documented unfixable macOS API limitation (REQUIREMENTS.md Out of Scope row).
@MainActor
final class DictationWindowController: NSWindowController {

    /// Default panel content size. Width clamps if screen is narrower than the
    /// default plus margin. Height is fixed.
    private static let defaultWidth: CGFloat = 420
    private static let panelHeight: CGFloat = 56
    /// Minimum margin between panel edge and screen edge for the clamping logic.
    private static let edgeMargin: CGFloat = 20
    /// Floor on panel width so the HUD remains legible on very narrow screens.
    private static let minWidth: CGFloat = 280

    init(rootView: AnyView) {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: Self.defaultWidth, height: Self.panelHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        // Float above other apps without stealing focus. `.floating` keeps the panel
        // above normal windows but below modal alerts. Standard for HUDs.
        panel.level = .floating
        // Visible regardless of which space the user is on; .stationary keeps it on
        // the current screen even when user switches spaces.
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        // Privacy: belt-and-suspenders. AppDelegate's didBecomeKeyNotification observer
        // (PSTranscribeApp.swift:116-131) does NOT fire for `.nonactivatingPanel` because
        // the panel never becomes the key window. Explicit set here is the only reliable
        // path. [Pitfall #4]
        panel.sharingType = .none
        // Don't activate the app on show -- user keeps typing context in their target app.
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = false
        panel.backgroundColor = .clear  // NSVisualEffectView underneath provides material
        panel.hasShadow = true
        panel.isOpaque = false

        // Native HUD vibrancy (D-03): NSVisualEffectView with .hudWindow material.
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 12
        visualEffect.layer?.masksToBounds = true

        // SwiftUI body hosted via NSHostingView.
        let host = NSHostingView(rootView: rootView)
        host.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.addSubview(visualEffect)
        container.addSubview(host)
        visualEffect.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            visualEffect.topAnchor.constraint(equalTo: container.topAnchor),
            visualEffect.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            visualEffect.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            visualEffect.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            host.topAnchor.constraint(equalTo: container.topAnchor),
            host.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            host.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        panel.contentView = container

        super.init(window: panel)
        positionAtBottomCenter()
    }

    required init?(coder: NSCoder) { fatalError("DictationWindowController is not Storyboard-instantiable") }

    /// Replace the SwiftUI content. Wave 4 (Plan 18-06) calls this to bind the
    /// HUD to a closure that reads the live `DictationCoordinator` state. The
    /// hosting view is identified by its position as the second subview of the
    /// container created in `init` (subviews[0] = visualEffect, subviews[1] = host).
    func setContent(_ rootView: AnyView) {
        guard let panel = window,
              let container = panel.contentView,
              container.subviews.count >= 2,
              let host = container.subviews[1] as? NSHostingView<AnyView>
        else { return }
        host.rootView = rootView
    }

    /// Apply the user's appearance preference to the panel (Phase 21, D-07).
    ///
    /// `NSAppearance` is the AppKit-native equivalent of SwiftUI's
    /// `.preferredColorScheme` for AppKit-owned panels: assigning
    /// `panel.appearance` flips both the chrome and the `NSVisualEffectView`'s
    /// `.hudWindow` material rendering. Setting `nil` clears the override and the
    /// panel inherits `NSApp.effectiveAppearance`.
    func applyAppearance(_ preference: AppearancePreference) {
        guard let panel = window else { return }
        switch preference {
        case .system: panel.appearance = nil
        case .light:  panel.appearance = NSAppearance(named: .aqua)
        case .dark:   panel.appearance = NSAppearance(named: .darkAqua)
        }
    }

    /// Position vertically centered within the bottom quarter of the active screen (D-04).
    /// Clamps panel width if screen is narrower than `defaultWidth + 2*edgeMargin`
    /// (Open Question §4). Width floor is `minWidth` so the HUD stays legible.
    func positionAtBottomCenter() {
        guard let panel = window, let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame

        // Width clamping (Open Question §4): if screen is too narrow, shrink the panel.
        let availableWidth = screenFrame.width - (2 * Self.edgeMargin)
        let targetWidth = min(Self.defaultWidth, max(Self.minWidth, availableWidth))

        // Resize first, then position.
        let panelSize = CGSize(width: targetWidth, height: Self.panelHeight)

        // Bottom quarter band: from screenFrame.minY up to (screenFrame.minY + screenFrame.height/4).
        // Panel sits vertically centered within that band.
        let bottomBandTop = screenFrame.minY + (screenFrame.height / 4)
        let bottomBandMid = (screenFrame.minY + bottomBandTop) / 2
        let x = screenFrame.midX - (panelSize.width / 2)
        let y = bottomBandMid - (panelSize.height / 2)

        panel.setFrame(NSRect(x: x, y: y, width: panelSize.width, height: panelSize.height), display: false)
    }

    /// Show the panel, repositioning in case the screen configuration changed since last show.
    func show() {
        positionAtBottomCenter()
        window?.orderFrontRegardless()
    }

    /// Hide the panel without releasing it; next `show()` reuses the same panel instance.
    func hide() {
        window?.orderOut(nil)
    }
}
