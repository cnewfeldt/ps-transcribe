import Testing
import Foundation
import AppKit
import SwiftUI
@testable import PSTranscribe

@Suite("DictationWindowControllerTests")
struct DictationWindowControllerTests {

    @Test @MainActor func panelHasNoneSharingType() {
        let ctrl = DictationWindowController(rootView: AnyView(EmptyView()))
        // Use fully-qualified `NSWindow.SharingType.none` — bare `.none` resolves to
        // `Optional<NSWindow.SharingType>.none` (i.e. nil) due to Swift's type-inference
        // preference for Optional when both are reachable.
        #expect(ctrl.window?.sharingType == NSWindow.SharingType.none, "HUD must be invisible to legacy CGWindowListCreateImage capture")
    }

    @Test @MainActor func panelHasFloatingLevelAndCanJoinAllSpaces() {
        let ctrl = DictationWindowController(rootView: AnyView(EmptyView()))
        guard let panel = ctrl.window else {
            Issue.record("Window is nil")
            return
        }
        #expect(panel.level == .floating, "HUD must float above other apps")
        #expect(panel.collectionBehavior.contains(.canJoinAllSpaces), "HUD must follow user across spaces")
        #expect(panel.collectionBehavior.contains(.fullScreenAuxiliary), "HUD must be visible during fullscreen")
        // Verify non-activating: borderless + .nonactivatingPanel mask
        #expect(panel.styleMask.contains(.borderless), "HUD has no chrome")
        #expect(panel.styleMask.contains(.nonactivatingPanel), "HUD does not steal focus")
    }

    @Test @MainActor func panelPositionsAtBottomCenter() {
        let ctrl = DictationWindowController(rootView: AnyView(EmptyView()))
        ctrl.show()
        defer { ctrl.hide() }
        guard let panel = ctrl.window, let screen = NSScreen.main else {
            Issue.record("No window or screen available")
            return
        }
        let visible = screen.visibleFrame
        let frame = panel.frame
        // X-axis: panel midpoint within 1pt of screen midpoint
        #expect(abs(frame.midX - visible.midX) <= 1.0, "panel.midX must equal screen.midX (±1pt)")
        // Y-axis: panel sits in the bottom quarter band
        #expect(frame.minY >= visible.minY, "panel.minY must be at or above screen.minY")
        #expect(frame.maxY <= visible.minY + (visible.height / 2), "panel.maxY must be in lower half of screen")
    }
}
