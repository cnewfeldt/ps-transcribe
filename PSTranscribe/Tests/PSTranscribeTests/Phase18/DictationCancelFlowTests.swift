import Testing
import Foundation
import AppKit
@testable import PSTranscribe

/// `.serialized` because `cancelLeavesPasteboardUntouched` shares NSPasteboard.general
/// with other suites. Without serialization, parallel pasteboard writes race.
@Suite("DictationCancelFlowTests", .serialized)
struct DictationCancelFlowTests {

    private func tmpFolder() -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("DictCancel-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @MainActor
    private func makeCoordinator(folder: URL, mode: DictationOutputMode) -> (DictationCoordinator, AppSettings, LibraryStore) {
        let settings = AppSettings()
        settings.dictationOutputMode = mode
        settings.dictationFolderPath = folder.path
        let coordinator = SessionCoordinator()
        let library = LibraryStore()
        let dict = DictationCoordinator(settings: settings, sessionCoordinator: coordinator, libraryStore: library)
        return (dict, settings, library)
    }

    @Test @MainActor func cancelLeavesPasteboardUntouched() async {
        await PasteboardTestLock.shared.acquire()
        defer { Task { await PasteboardTestLock.shared.release() } }
        defer { NSPasteboard.general.clearContents() }
        let folder = tmpFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("USER_OLD", forType: .string)
        let (dict, _, _) = makeCoordinator(folder: folder, mode: .clipboard)
        dict._test_setState(.listening); dict._test_setSessionStartTime(Date()); dict._test_setElapsed(5)
        await dict.cancelDictation()
        #expect(NSPasteboard.general.string(forType: .string) == "USER_OLD")
    }

    @Test @MainActor func cancelLeavesLibraryUntouched() async {
        let folder = tmpFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let (dict, _, library) = makeCoordinator(folder: folder, mode: .both)
        let beforeCount = await library.entries.count
        dict._test_setState(.listening); dict._test_setSessionStartTime(Date()); dict._test_setElapsed(5)
        await dict.cancelDictation()
        let afterCount = await library.entries.count
        #expect(afterCount == beforeCount)
    }

    @Test @MainActor func cancelDeletesPlainFolderFile() async {
        let folder = tmpFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let (dict, _, _) = makeCoordinator(folder: folder, mode: .plainFolder)
        try? await dict.dictationLogger.startSession(folderPath: folder.path)
        dict._test_setState(.listening); dict._test_setSessionStartTime(Date()); dict._test_setElapsed(5)
        let beforeContents = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        #expect(beforeContents.count == 1)
        await dict.cancelDictation()
        let afterContents = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        #expect(afterContents.isEmpty)
    }
}
