import Testing
import Foundation
import AppKit
@testable import PSTranscribe

@Suite("DictationCommitFlowTests")
struct DictationCommitFlowTests {

    @Test(.disabled("Pending Plan 18-06 -- commit (.clipboard): writes pasteboard, no file"))
    @MainActor func clipboardOnlyModeWritesNoFile() async {
        // mode=.clipboard. begin -> utterances -> end -> pasteboard set, no file in dictationFolderPath
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- commit (.plainFolder): writes file, no clipboard"))
    @MainActor func plainFolderOnlyModeWritesNoClipboard() async {
        // mode=.plainFolder. Pre-set pasteboard "OLD".
        // begin -> utterances -> end -> pasteboard remains "OLD" (no overwrite),
        // file exists with header.
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- commit (.both): writes file AND clipboard"))
    @MainActor func bothModeWritesFileAndClipboard() async {
        // mode=.both. end -> pasteboard set, file exists.
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- every commit creates a library entry"))
    @MainActor func libraryEntryCreatedForEachOutputMode() async {
        // For each of .clipboard / .plainFolder / .both:
        // library entry count incremented by 1, sessionType==.dictation
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- D-12: clipboard-only entry preserves inlineTranscript through Codable round-trip"))
    @MainActor func clipboardOnlyEntryPersistsInlineTranscriptViaCodable() async throws {
        // mode=.clipboard. Commit a session with assembled="hello world".
        // Resulting LibraryEntry.inlineTranscript == "hello world" AND survives JSONEncoder->JSONDecoder.
        // mode=.plainFolder/.both -> inlineTranscript == nil (file is source of truth).
        #expect(Bool(true))
    }
}
