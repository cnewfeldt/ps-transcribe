import Testing
import Foundation
import AppKit
@testable import PSTranscribe

@Suite("ClipboardRestoreTests")
struct ClipboardRestoreTests {

    @Test(.disabled("Pending Plan 18-06 -- clipboard restore after delay"))
    @MainActor func clipboardRestoresAfterDelay() async {
        // Save "OLD" -> endDictation writes "NEW" -> wait > restoreDelay -> pasteboard string == "OLD"
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- restore skipped when changeCount changed"))
    @MainActor func clipboardRestoreSkippedWhenChangeCountChanged() async {
        // Save "OLD" -> endDictation writes "NEW" -> user copies "USER" mid-window
        // -> restore window passes -> pasteboard string == "USER" (NOT restored to OLD)
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- restore window honors clipboardRestoreDelay setting"))
    @MainActor func restoreDelayHonorsAppSettings() async {
        // settings.clipboardRestoreDelay = 0.5 -> restore happens after 0.5s, not 3.0s
        #expect(Bool(true))
    }
}
