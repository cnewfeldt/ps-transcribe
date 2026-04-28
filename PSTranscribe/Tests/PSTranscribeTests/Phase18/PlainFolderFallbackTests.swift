import Testing
import Foundation
import AppKit
@testable import PSTranscribe

/// `.serialized` because both tests share NSPasteboard.general (system-global state).
@Suite("PlainFolderFallbackTests", .serialized)
struct PlainFolderFallbackTests {

    @Test @MainActor func plainFolderWriteFailureSilentlyFallsBackToClipboard() async {
        await PasteboardTestLock.shared.acquire()
        defer { Task { await PasteboardTestLock.shared.release() } }
        defer { NSPasteboard.general.clearContents() }
        let settings = AppSettings()
        settings.dictationOutputMode = .both
        // Path containing ".." triggers DictationLogger.validatedFolderPath rejection
        // (defense-in-depth traversal check). startSession throws -> coordinator catches
        // and silently falls back to clipboard-only. (D-15)
        settings.dictationFolderPath = "/tmp/../../etc/dict-fail-\(UUID().uuidString)"
        let coordinator = SessionCoordinator()
        let library = LibraryStore()
        let dict = DictationCoordinator(settings: settings, sessionCoordinator: coordinator, libraryStore: library)

        dict._test_setState(.listening); dict._test_setSessionStartTime(Date()); dict._test_setElapsed(5)
        dict.dictationStore.volatileYouText = "fallback transcript"

        await dict.endDictation()
        try? await Task.sleep(for: .milliseconds(50))

        #expect(NSPasteboard.general.string(forType: .string) == "fallback transcript")
        let last = await library.entries.first
        #expect(last?.sessionType == .dictation)
        #expect(last?.filePath == "")
        // D-15 + D-12: fallback path preserves inlineTranscript (file write failed, but we still keep the text).
        #expect(last?.inlineTranscript == "fallback transcript")
    }

    @Test @MainActor func fallbackLibraryEntryHasEmptyFilePath() async {
        await PasteboardTestLock.shared.acquire()
        defer { Task { await PasteboardTestLock.shared.release() } }
        defer { NSPasteboard.general.clearContents() }
        let settings = AppSettings()
        settings.dictationOutputMode = .clipboard
        let coordinator = SessionCoordinator()
        let library = LibraryStore()
        let dict = DictationCoordinator(settings: settings, sessionCoordinator: coordinator, libraryStore: library)
        dict._test_setState(.listening); dict._test_setSessionStartTime(Date()); dict._test_setElapsed(5)
        dict.dictationStore.volatileYouText = "clipboard only"
        await dict.endDictation()
        try? await Task.sleep(for: .milliseconds(50))
        let last = await library.entries.first
        #expect(last?.filePath == "")
        #expect(last?.inlineTranscript == "clipboard only")
    }
}
