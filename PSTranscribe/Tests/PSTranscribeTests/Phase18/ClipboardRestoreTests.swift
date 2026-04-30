import Testing
import Foundation
import AppKit
@testable import PSTranscribe

/// `.serialized` is required because all 3 tests share NSPasteboard.general (system-global state).
/// Without serialization the tests race: one test's `setString("USER_COPY")` lands while another
/// is asleep waiting for its restore, and changeCount/string assertions fail unpredictably.
@Suite("ClipboardRestoreTests", .serialized)
struct ClipboardRestoreTests {

    @MainActor
    private func makeCoordinator(restoreDelay: TimeInterval = 0.5) -> DictationCoordinator {
        let settings = AppSettings()
        settings.localFileEnabled = false
        settings.clipboardRestoreDelay = restoreDelay
        let coordinator = SessionCoordinator()
        let library = LibraryStore()
        let saveDest = SaveDestinations(settings: settings, notionService: NotionService())
        return DictationCoordinator(
            settings: settings,
            sessionCoordinator: coordinator,
            libraryStore: library,
            saveDestinations: saveDest
        )
    }

    @Test @MainActor func clipboardRestoresAfterDelay() async {
        await PasteboardTestLock.shared.acquire()
        defer { Task { await PasteboardTestLock.shared.release() } }
        defer { NSPasteboard.general.clearContents() }
        let pb = NSPasteboard.general
        pb.clearContents(); pb.setString("OLD", forType: .string)
        let dict = makeCoordinator(restoreDelay: 0.3)
        dict._test_writeToClipboard("NEW")
        #expect(pb.string(forType: .string) == "NEW")
        dict._test_scheduleClipboardRestore(after: 0.3)
        try? await Task.sleep(for: .milliseconds(500))
        #expect(pb.string(forType: .string) == "OLD")
    }

    @Test @MainActor func clipboardRestoreSkippedWhenChangeCountChanged() async {
        await PasteboardTestLock.shared.acquire()
        defer { Task { await PasteboardTestLock.shared.release() } }
        defer { NSPasteboard.general.clearContents() }
        let pb = NSPasteboard.general
        pb.clearContents(); pb.setString("OLD", forType: .string)
        let dict = makeCoordinator(restoreDelay: 0.5)
        dict._test_writeToClipboard("DICTATION")
        pb.clearContents(); pb.setString("USER_COPY", forType: .string)
        dict._test_scheduleClipboardRestore(after: 0.3)
        try? await Task.sleep(for: .milliseconds(500))
        #expect(pb.string(forType: .string) == "USER_COPY")
    }

    @Test @MainActor func restoreDelayHonorsAppSettings() async {
        await PasteboardTestLock.shared.acquire()
        defer { Task { await PasteboardTestLock.shared.release() } }
        defer { NSPasteboard.general.clearContents() }
        let pb = NSPasteboard.general
        pb.clearContents(); pb.setString("OLD", forType: .string)
        let dict = makeCoordinator(restoreDelay: 0.2)
        dict._test_writeToClipboard("NEW")
        dict._test_scheduleClipboardRestore(after: 0.2)
        try? await Task.sleep(for: .milliseconds(100))
        #expect(pb.string(forType: .string) == "NEW")
        try? await Task.sleep(for: .milliseconds(300))
        #expect(pb.string(forType: .string) == "OLD")
    }
}
