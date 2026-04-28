import Testing
import Foundation
import AppKit
@testable import PSTranscribe

@Suite("DictationCancelFlowTests")
struct DictationCancelFlowTests {

    @Test(.disabled("Pending Plan 18-06 -- cancel atomic: no clipboard write"))
    @MainActor func cancelLeavesPasteboardUntouched() async {
        // Pre-write "OLD" to pasteboard. begin -> cancel -> pasteboard string == "OLD"
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- cancel atomic: no library entry"))
    @MainActor func cancelLeavesLibraryUntouched() async {
        // Pre-count library. begin -> cancel -> library count unchanged.
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- cancel atomic: plain-folder file deleted"))
    @MainActor func cancelDeletesPlainFolderFile() async {
        // mode=.plainFolder. begin opens file. cancel -> file does NOT exist on disk.
        #expect(Bool(true))
    }
}
