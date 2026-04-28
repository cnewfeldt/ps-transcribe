import Testing
import Foundation
@testable import PSTranscribe

@Suite("GlobalHotkeyServiceTests")
struct GlobalHotkeyServiceTests {

    @Test(.disabled("Pending Plan 18-02 -- KeyboardShortcuts dependency + GlobalHotkeyService"))
    @MainActor func defaultShortcutIsCmdShiftD() {
        // Wave 1 (Plan 18-02) ships:
        //   extension KeyboardShortcuts.Name {
        //     static let dictateGlobal = Self("dictateGlobal", default: .init(.d, modifiers: [.command, .shift]))
        //   }
        // After GREEN, this test asserts the initial shortcut is Cmd+Shift+D.
        // Until then, this is a placeholder.
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-02 -- onKeyDown/onKeyUp closure typing"))
    @MainActor func onKeyDownClosureIsTypedMainActor() async {
        // Wave 1 ships GlobalHotkeyService with `onKeyDown: (@MainActor () -> Void)?`.
        // This is a compile-time guarantee: the test body assigns a `@MainActor` closure
        // and invokes it; if the property's declared type drifted, the test would not compile.
        // Real-callback MainActor dispatch is verified by manual UAT (hotkey from arbitrary app)
        // because Carbon callback paths cannot be exercised from unit tests.
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-02 -- clear-hotkey opt-out path"))
    @MainActor func hotkeyAssignedReflectsClearedState() {
        // When user clears the hotkey via Recorder, hotkeyAssigned must return false.
        #expect(Bool(true))
    }
}
