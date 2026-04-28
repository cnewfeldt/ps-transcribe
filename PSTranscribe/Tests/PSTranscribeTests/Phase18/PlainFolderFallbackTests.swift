import Testing
import Foundation
@testable import PSTranscribe

@Suite("PlainFolderFallbackTests")
struct PlainFolderFallbackTests {

    @Test(.disabled("Pending Plan 18-06 -- D-15 silent fallback to clipboard-only"))
    @MainActor func plainFolderWriteFailureSilentlyFallsBackToClipboard() async {
        // settings.dictationFolderPath = "/this/path/cannot/exist/and/has/no/perms"
        // mode=.both. begin -> end -> pasteboard SET, library entry created with empty filePath,
        // no exception thrown.
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- fallback library entry has empty filePath"))
    @MainActor func fallbackLibraryEntryHasEmptyFilePath() async {
        // After fallback: latest library entry has filePath == ""
        // AND inlineTranscript is set (D-12 fallback preserves transcript inline because file write failed).
        #expect(Bool(true))
    }
}
