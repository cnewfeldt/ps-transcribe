import Testing
import Foundation
import KeyboardShortcuts
@testable import PSTranscribe

@Suite("GlobalHotkeyServiceTests")
struct GlobalHotkeyServiceTests {

    @Test @MainActor func defaultShortcutIsCmdShiftD() {
        // Force the library to evaluate the `default:` parameter on first lookup.
        // After this call, getShortcut returns the default if no user override is set.
        _ = GlobalHotkeyService()
        let shortcut = KeyboardShortcuts.getShortcut(for: .dictateGlobal)
        #expect(shortcut != nil, "Default shortcut should be registered after first lookup")
        #expect(shortcut?.key == .d, "Default key should be 'd'")
        #expect(shortcut?.modifiers.contains(.command) == true, "Default modifiers should include .command")
        #expect(shortcut?.modifiers.contains(.shift) == true, "Default modifiers should include .shift")
    }

    @Test @MainActor func onKeyDownClosureCanBeAssigned() {
        // We cannot synthesize a real Carbon hotkey event in a unit test (would require
        // posting CGEvents from the test runner), so we verify the assignable surface:
        // the closure property exists and accepts a MainActor closure.
        let svc = GlobalHotkeyService()
        var fired = false
        svc.onKeyDown = { @MainActor in fired = true }
        // Manually invoke through the public surface (the closure is assignable).
        svc.onKeyDown?()
        #expect(fired == true)
        // WARNING #10: removed Thread.isMainThread assertion. Invoking from an
        // @MainActor test body is trivially main-thread; the genuine cross-thread
        // Carbon callback path is verified by manual UAT.
    }

    @Test @MainActor func onKeyUpClosureCanBeAssigned() {
        let svc = GlobalHotkeyService()
        var fired = false
        svc.onKeyUp = { @MainActor in fired = true }
        svc.onKeyUp?()
        #expect(fired == true)
        // WARNING #10: removed Thread.isMainThread assertion (same reasoning as onKeyDown above).
    }

    @Test @MainActor func hotkeyAssignedReflectsClearedState() {
        // Ensure default is set first.
        _ = GlobalHotkeyService()
        #expect(GlobalHotkeyService().hotkeyAssigned == true)

        // Simulate user clearing the hotkey via the Recorder.
        KeyboardShortcuts.reset(.dictateGlobal)
        // After reset, the library returns nil from getShortcut UNTIL the next read
        // re-applies the default (the library's `default:` parameter behavior).
        // The library's reset() clears the user override; if `default:` was provided,
        // the next getShortcut returns the default again. So this test asserts the
        // round-trip behavior: reset returns to default (not nil) -- which is correct
        // semantics for "user cleared their override; default re-applies."
        let svc = GlobalHotkeyService()
        #expect(svc.hotkeyAssigned == true, "After reset, default should re-apply (default: parameter)")
    }
}
