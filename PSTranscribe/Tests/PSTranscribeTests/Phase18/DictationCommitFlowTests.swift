import Testing
import Foundation
import AppKit
@testable import PSTranscribe

/// `.serialized` because all 5 tests share NSPasteboard.general (system-global state).
/// Parallel execution races: one test's clipboard write lands while another reads
/// the pasteboard from a different test's session, producing flaky assertions.
@Suite("DictationCommitFlowTests", .serialized)
struct DictationCommitFlowTests {

    private func tmpFolder() -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("DictCommit-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @MainActor
    private func makeCoordinator(folder: URL, mode: DictationOutputMode) -> (DictationCoordinator, LibraryStore) {
        let settings = AppSettings()
        settings.dictationOutputMode = mode
        settings.dictationFolderPath = folder.path
        let coordinator = SessionCoordinator()
        let library = LibraryStore()
        let dict = DictationCoordinator(settings: settings, sessionCoordinator: coordinator, libraryStore: library)
        return (dict, library)
    }

    @Test @MainActor func clipboardOnlyModeWritesNoFile() async {
        await PasteboardTestLock.shared.acquire()
        defer { Task { await PasteboardTestLock.shared.release() } }
        defer { NSPasteboard.general.clearContents() }
        let folder = tmpFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let (dict, _) = makeCoordinator(folder: folder, mode: .clipboard)
        dict._test_setState(.listening); dict._test_setSessionStartTime(Date()); dict._test_setElapsed(5)
        dict.dictationStore.volatileYouText = "hello world"
        await dict.endDictation()
        let contents = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        #expect(contents.isEmpty)
        #expect(NSPasteboard.general.string(forType: .string) == "hello world")
    }

    @Test @MainActor func plainFolderOnlyModeWritesNoClipboard() async {
        await PasteboardTestLock.shared.acquire()
        defer { Task { await PasteboardTestLock.shared.release() } }
        defer { NSPasteboard.general.clearContents() }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("USER_OLD", forType: .string)
        let folder = tmpFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let (dict, _) = makeCoordinator(folder: folder, mode: .plainFolder)
        try? await dict.dictationLogger.startSession(folderPath: folder.path)
        dict._test_setState(.listening); dict._test_setSessionStartTime(Date()); dict._test_setElapsed(5)
        dict.dictationStore.volatileYouText = "hello world"
        await dict.endDictation()
        #expect(NSPasteboard.general.string(forType: .string) == "USER_OLD")
        let contents = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        #expect(contents.count == 1)
    }

    @Test @MainActor func bothModeWritesFileAndClipboard() async {
        await PasteboardTestLock.shared.acquire()
        defer { Task { await PasteboardTestLock.shared.release() } }
        defer { NSPasteboard.general.clearContents() }
        let folder = tmpFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let (dict, _) = makeCoordinator(folder: folder, mode: .both)
        try? await dict.dictationLogger.startSession(folderPath: folder.path)
        dict._test_setState(.listening); dict._test_setSessionStartTime(Date()); dict._test_setElapsed(5)
        dict.dictationStore.volatileYouText = "hello world"
        await dict.endDictation()
        #expect(NSPasteboard.general.string(forType: .string) == "hello world")
        let contents = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        #expect(contents.count == 1)
    }

    @Test @MainActor func libraryEntryCreatedForEachOutputMode() async {
        await PasteboardTestLock.shared.acquire()
        defer { Task { await PasteboardTestLock.shared.release() } }
        defer { NSPasteboard.general.clearContents() }
        for mode in [DictationOutputMode.clipboard, .plainFolder, .both] {
            let folder = tmpFolder()
            defer { try? FileManager.default.removeItem(at: folder) }
            let (dict, library) = makeCoordinator(folder: folder, mode: mode)
            if mode != .clipboard {
                try? await dict.dictationLogger.startSession(folderPath: folder.path)
            }
            dict._test_setState(.listening); dict._test_setSessionStartTime(Date()); dict._test_setElapsed(5)
            dict.dictationStore.volatileYouText = "test transcript for mode \(mode.rawValue)"
            let beforeCount = await library.entries.count
            await dict.endDictation()
            try? await Task.sleep(for: .milliseconds(50))
            let afterCount = await library.entries.count
            #expect(afterCount == beforeCount + 1)
            let lastEntry = await library.entries.first
            #expect(lastEntry?.sessionType == .dictation)
        }
    }

    /// D-12 (BLOCKER #2 fix): clipboard-only entries persist transcript inline so the user
    /// can recover it after the clipboard restore window expires. Verifies BOTH the in-memory
    /// state AND the JSON Codable round-trip (so it survives library.json save/load).
    @Test @MainActor func clipboardOnlyEntryPersistsInlineTranscriptViaCodable() async throws {
        await PasteboardTestLock.shared.acquire()
        defer { Task { await PasteboardTestLock.shared.release() } }
        defer { NSPasteboard.general.clearContents() }
        let folder = tmpFolder()
        defer { try? FileManager.default.removeItem(at: folder) }

        // Case 1: mode == .clipboard -> inlineTranscript == assembled
        let (dict, library) = makeCoordinator(folder: folder, mode: .clipboard)
        dict._test_setState(.listening); dict._test_setSessionStartTime(Date()); dict._test_setElapsed(5)
        dict.dictationStore.volatileYouText = "hello inline"
        await dict.endDictation()
        try? await Task.sleep(for: .milliseconds(50))
        let last = await library.entries.first
        #expect(last?.inlineTranscript == "hello inline", "D-12: clipboard-only entries must store the full transcript inline")
        #expect(last?.filePath == "", "D-12: clipboard-only entries use empty-string filePath sentinel")

        // Codable round-trip (proves it survives JSON write/read in library.json)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encoded = try encoder.encode(last)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(LibraryEntry.self, from: encoded)
        #expect(decoded.inlineTranscript == "hello inline", "D-12: inlineTranscript must Codable-round-trip")
        #expect(decoded.filePath == "")

        // Backward-compat: a JSON document MISSING inlineTranscript decodes as nil (existing entries pre-Phase-18).
        // Use ISO-8601 date format to match LibraryStore's persistence strategy.
        let legacyJSON = """
        {"id":"\(UUID().uuidString)","sessionType":"voiceMemo","startDate":"2026-04-28T12:00:00Z","duration":10,"filePath":"/tmp/x","sourceApp":"PSTranscribe","isFinalized":true}
        """
        let legacy = try decoder.decode(LibraryEntry.self, from: Data(legacyJSON.utf8))
        #expect(legacy.inlineTranscript == nil, "Legacy entries (no inlineTranscript key) must decode as nil")

        // Case 2: mode == .plainFolder -> inlineTranscript == nil (file is source of truth)
        let folder2 = tmpFolder()
        defer { try? FileManager.default.removeItem(at: folder2) }
        let (dict2, library2) = makeCoordinator(folder: folder2, mode: .plainFolder)
        try? await dict2.dictationLogger.startSession(folderPath: folder2.path)
        dict2._test_setState(.listening); dict2._test_setSessionStartTime(Date()); dict2._test_setElapsed(5)
        dict2.dictationStore.volatileYouText = "stored on disk"
        await dict2.endDictation()
        try? await Task.sleep(for: .milliseconds(50))
        let last2 = await library2.entries.first
        #expect(last2?.inlineTranscript == nil, "D-12: plainFolder entries must NOT store inline (file is source of truth)")
    }
}
