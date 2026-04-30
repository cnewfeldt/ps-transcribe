import Testing
import Foundation
import AppKit
@testable import PSTranscribe

/// `.serialized` because all tests share NSPasteboard.general (system-global state).
/// Parallel execution races: one test's clipboard write lands while another reads
/// the pasteboard from a different test's session, producing flaky assertions.
///
/// Phase 18.1 migration: previously parameterized over the deleted DictationOutputMode
/// enum. Now parameterized over the new shared destination flag (settings.localFileEnabled)
/// and the new SaveDestinations injection. Clipboard writes are unconditional (D-15);
/// the LocalFileWriter convention writes dictation files to <root>/Dictation/.
@Suite("DictationCommitFlowTests", .serialized)
struct DictationCommitFlowTests {

    private func tmpFolder() -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("DictCommit-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Returns the dictation subfolder URL the new LocalFileWriter convention would use.
    private func dictationSubfolder(under root: URL) -> URL {
        root.appendingPathComponent("Dictation", isDirectory: true)
    }

    @MainActor
    private func makeCoordinator(rootFolder: URL, localFileEnabled: Bool) -> (DictationCoordinator, LibraryStore) {
        let settings = AppSettings()
        settings.localFileEnabled = localFileEnabled
        settings.localFileRoot = rootFolder.path
        settings.obsidianEnabled = false
        settings.notionAutoSendEnabled = false
        let coordinator = SessionCoordinator()
        let library = LibraryStore()
        let saveDest = SaveDestinations(settings: settings, notionService: NotionService())
        let dict = DictationCoordinator(
            settings: settings,
            sessionCoordinator: coordinator,
            libraryStore: library,
            saveDestinations: saveDest
        )
        return (dict, library)
    }

    @Test @MainActor func clipboardOnlyModeWritesNoFile() async {
        await PasteboardTestLock.shared.acquire()
        defer { Task { await PasteboardTestLock.shared.release() } }
        defer { NSPasteboard.general.clearContents() }
        let folder = tmpFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let (dict, _) = makeCoordinator(rootFolder: folder, localFileEnabled: false)
        dict._test_setState(.listening); dict._test_setSessionStartTime(Date()); dict._test_setElapsed(5)
        dict.dictationStore.volatileYouText = "hello world"
        await dict.endDictation()
        let dictationDir = dictationSubfolder(under: folder)
        let contents = (try? FileManager.default.contentsOfDirectory(atPath: dictationDir.path)) ?? []
        #expect(contents.isEmpty, "localFileEnabled=false must not produce a dictation file")
        #expect(NSPasteboard.general.string(forType: .string) == "hello world")
    }

    /// 18.1 D-15 update: clipboard write is now UNCONDITIONAL. Previously this test asserted
    /// the clipboard kept USER_OLD when plainFolder mode was active; now the clipboard is
    /// always overwritten with the assembled transcript regardless of file destination.
    @Test @MainActor func localFileEnabledStillWritesClipboard() async {
        await PasteboardTestLock.shared.acquire()
        defer { Task { await PasteboardTestLock.shared.release() } }
        defer { NSPasteboard.general.clearContents() }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("USER_OLD", forType: .string)
        let folder = tmpFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let (dict, _) = makeCoordinator(rootFolder: folder, localFileEnabled: true)
        let dictationDir = dictationSubfolder(under: folder)
        try? await dict.dictationLogger.startSession(folderPath: dictationDir.path)
        dict._test_setState(.listening); dict._test_setSessionStartTime(Date()); dict._test_setElapsed(5)
        dict.dictationStore.volatileYouText = "hello world"
        await dict.endDictation()
        #expect(NSPasteboard.general.string(forType: .string) == "hello world",
                "D-15: clipboard write is unconditional even when Local File is enabled")
        let contents = (try? FileManager.default.contentsOfDirectory(atPath: dictationDir.path)) ?? []
        #expect(contents.count == 1, "localFileEnabled=true must produce one .md file in Dictation/")
    }

    @Test @MainActor func localFileEnabledWritesFileAndClipboard() async {
        await PasteboardTestLock.shared.acquire()
        defer { Task { await PasteboardTestLock.shared.release() } }
        defer { NSPasteboard.general.clearContents() }
        let folder = tmpFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let (dict, _) = makeCoordinator(rootFolder: folder, localFileEnabled: true)
        let dictationDir = dictationSubfolder(under: folder)
        try? await dict.dictationLogger.startSession(folderPath: dictationDir.path)
        dict._test_setState(.listening); dict._test_setSessionStartTime(Date()); dict._test_setElapsed(5)
        dict.dictationStore.volatileYouText = "hello world"
        await dict.endDictation()
        #expect(NSPasteboard.general.string(forType: .string) == "hello world")
        let contents = (try? FileManager.default.contentsOfDirectory(atPath: dictationDir.path)) ?? []
        #expect(contents.count == 1)
    }

    /// Gap #1 regression -- the dictation file BODY must contain the spoken transcript,
    /// not just the header. Pre-fix: the file contained only `# Dictation -- ...\n\n`
    /// because endDictation never called dictationLogger.append. Post-fix: the seeded
    /// utterance text appears in the body.
    @Test @MainActor func localFileBodyContainsTranscript() async throws {
        await PasteboardTestLock.shared.acquire()
        defer { Task { await PasteboardTestLock.shared.release() } }
        defer { NSPasteboard.general.clearContents() }
        let folder = tmpFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let (dict, _) = makeCoordinator(rootFolder: folder, localFileEnabled: true)
        let dictationDir = dictationSubfolder(under: folder)

        try await dict.dictationLogger.startSession(folderPath: dictationDir.path)

        let now = Date()
        dict.dictationStore.append(Utterance(text: "hello body content", speaker: .you, timestamp: now))

        dict._test_setState(.listening)
        dict._test_setSessionStartTime(now)
        dict._test_setElapsed(5)

        await dict.endDictation()
        try? await Task.sleep(for: .milliseconds(50))

        let contents = (try? FileManager.default.contentsOfDirectory(atPath: dictationDir.path)) ?? []
        #expect(contents.count == 1, "localFileEnabled mode must produce exactly one .md file in Dictation/")
        guard let filename = contents.first else { return }
        let url = dictationDir.appendingPathComponent(filename)

        let body = try String(contentsOf: url, encoding: .utf8)
        #expect(body.contains("hello body content"),
                "Local File body must contain the spoken transcript text. Found body:\n\(body)")
        #expect(body.contains("**You** ("), "Local File body must contain the **You** speaker header from append()")
        #expect(!body.contains("---"), "Dictation file must never contain YAML frontmatter delimiter")
    }

    @Test @MainActor func libraryEntryCreatedForEachDestinationConfig() async {
        await PasteboardTestLock.shared.acquire()
        defer { Task { await PasteboardTestLock.shared.release() } }
        defer { NSPasteboard.general.clearContents() }
        for localFileEnabled in [false, true] {
            let folder = tmpFolder()
            defer { try? FileManager.default.removeItem(at: folder) }
            let (dict, library) = makeCoordinator(rootFolder: folder, localFileEnabled: localFileEnabled)
            if localFileEnabled {
                let dictationDir = dictationSubfolder(under: folder)
                try? await dict.dictationLogger.startSession(folderPath: dictationDir.path)
            }
            dict._test_setState(.listening); dict._test_setSessionStartTime(Date()); dict._test_setElapsed(5)
            dict.dictationStore.volatileYouText = "test transcript localFileEnabled=\(localFileEnabled)"
            let beforeCount = await library.entries.count
            await dict.endDictation()
            try? await Task.sleep(for: .milliseconds(50))
            let afterCount = await library.entries.count
            #expect(afterCount == beforeCount + 1)
            let lastEntry = await library.entries.first
            #expect(lastEntry?.sessionType == .dictation)
        }
    }

    /// D-12 / D-19: clipboard-only entries (no destination active) persist transcript inline
    /// so the user can recover it after the clipboard restore window expires. Verifies BOTH
    /// the in-memory state AND the JSON Codable round-trip (so it survives library.json save/load).
    @Test @MainActor func zeroDestinationEntryPersistsInlineTranscriptViaCodable() async throws {
        await PasteboardTestLock.shared.acquire()
        defer { Task { await PasteboardTestLock.shared.release() } }
        defer { NSPasteboard.general.clearContents() }
        let folder = tmpFolder()
        defer { try? FileManager.default.removeItem(at: folder) }

        // Case 1: localFileEnabled == false -> inlineTranscript == assembled
        let (dict, library) = makeCoordinator(rootFolder: folder, localFileEnabled: false)
        dict._test_setState(.listening); dict._test_setSessionStartTime(Date()); dict._test_setElapsed(5)
        dict.dictationStore.volatileYouText = "hello inline"
        await dict.endDictation()
        try? await Task.sleep(for: .milliseconds(50))
        let last = await library.entries.first
        #expect(last?.inlineTranscript == "hello inline", "D-12 / D-19: zero-destination entries must store the full transcript inline")
        #expect(last?.filePath == "", "D-12: zero-destination entries use empty-string filePath sentinel")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encoded = try encoder.encode(last)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(LibraryEntry.self, from: encoded)
        #expect(decoded.inlineTranscript == "hello inline", "D-12: inlineTranscript must Codable-round-trip")
        #expect(decoded.filePath == "")

        let legacyJSON = """
        {"id":"\(UUID().uuidString)","sessionType":"voiceMemo","startDate":"2026-04-28T12:00:00Z","duration":10,"filePath":"/tmp/x","sourceApp":"PSTranscribe","isFinalized":true}
        """
        let legacy = try decoder.decode(LibraryEntry.self, from: Data(legacyJSON.utf8))
        #expect(legacy.inlineTranscript == nil, "Legacy entries (no inlineTranscript key) must decode as nil")

        // Case 2: localFileEnabled == true -> inlineTranscript == nil (file is source of truth)
        let folder2 = tmpFolder()
        defer { try? FileManager.default.removeItem(at: folder2) }
        let (dict2, library2) = makeCoordinator(rootFolder: folder2, localFileEnabled: true)
        let dictationDir2 = dictationSubfolder(under: folder2)
        try? await dict2.dictationLogger.startSession(folderPath: dictationDir2.path)
        dict2._test_setState(.listening); dict2._test_setSessionStartTime(Date()); dict2._test_setElapsed(5)
        dict2.dictationStore.volatileYouText = "stored on disk"
        await dict2.endDictation()
        try? await Task.sleep(for: .milliseconds(50))
        let last2 = await library2.entries.first
        #expect(last2?.inlineTranscript == nil, "D-12: localFileEnabled entries must NOT store inline (file is source of truth)")
    }
}
