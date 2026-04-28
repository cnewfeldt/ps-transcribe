import Testing
import Foundation
import AppKit
import SwiftUI
@testable import PSTranscribe

@Suite("DictationWindowControllerTests")
struct DictationWindowControllerTests {

    @Test(.disabled("Pending Plan 18-05 -- DictationWindowController"))
    @MainActor func panelHasNoneSharingType() {
        // let ctrl = DictationWindowController(rootView: AnyView(EmptyView()))
        // #expect(ctrl.window?.sharingType == .none)
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-05 -- bottom-center positioning"))
    @MainActor func panelPositionsAtBottomCenter() {
        // After show(): panel.frame.midX == screen.visibleFrame.midX (within 1pt)
        // panel.frame.minY > screen.visibleFrame.minY
        // panel.frame.maxY < screen.visibleFrame.midY
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-05 -- non-activating panel collection behavior"))
    @MainActor func panelHasFloatingLevelAndCanJoinAllSpaces() {
        // panel.level == .floating
        // panel.collectionBehavior contains .canJoinAllSpaces and .fullScreenAuxiliary
        #expect(Bool(true))
    }
}
