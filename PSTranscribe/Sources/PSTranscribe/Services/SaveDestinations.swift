import Foundation
import Observation
import os

private let saveDestLog = Logger(subsystem: "com.pstranscribe.app", category: "SaveDestinations")

/// Metadata for a single piece of content being saved. Producers (DictationCoordinator,
/// ContentView meeting/memo flow) pass this to `SaveDestinations.save(...)`.
struct SaveMetadata: Sendable {
    var sessionType: SessionType
    var title: String         // auto-name or user-provided; used for filename suffix and Notion title
    var startDate: Date
    var duration: TimeInterval
    var sourceApp: String     // "PSTranscribe" for dictation; conferencing app for meetings; "Voice Memo" for memos
    var speakers: [String]    // empty for dictation per D-12
    var tags: [String]        // empty for dictation per D-12
}

/// Per-destination outcome from a SaveDestinations.save() call. Each URL is non-nil
/// only when that destination's write succeeded. Library entry callers use the priority
/// Local File > Obsidian > Notion > inline transcript to choose `filePath` (RESEARCH.md §4).
struct SaveResult: Sendable {
    var localFileURL: URL?
    var obsidianFileURL: URL?
    var notionPageURL: URL?
    /// True when every enabled destination succeeded (or no destinations were enabled).
    var allSucceeded: Bool {
        return errors.isEmpty
    }
    /// Per-destination errors logged for diagnostic purposes.
    var errors: [String] = []
}

/// Shared fan-out: routes `(content, metadata)` to whichever destinations are enabled
/// in `AppSettings`. Per-destination failure is non-fatal (D-18) -- one writer's exception
/// does not abort the others. The library entry caller decides whether to fall back to an
/// inline transcript when all enabled writers failed (Dictation D-19).
@Observable
@MainActor
final class SaveDestinations {
    let settings: AppSettings
    let localFileWriter: LocalFileWriter
    let obsidianWriter: ObsidianWriter
    let notionService: NotionService

    init(settings: AppSettings,
         notionService: NotionService,
         localFileWriter: LocalFileWriter = LocalFileWriter(),
         obsidianWriter: ObsidianWriter = ObsidianWriter()) {
        self.settings = settings
        self.notionService = notionService
        self.localFileWriter = localFileWriter
        self.obsidianWriter = obsidianWriter
    }

    /// True when at least one destination is enabled. Meeting/memo session-start (D-20)
    /// blocks on this. Dictation does NOT block on this -- clipboard write fires
    /// unconditionally (D-15) and the library entry stores the inline transcript (D-19).
    var isAnyDestinationEnabled: Bool {
        settings.localFileEnabled
            || (settings.obsidianEnabled && !settings.obsidianFolderPath.isEmpty)
            || (settings.notionAutoSendEnabled && !settings.notionDatabaseID.isEmpty)
    }

    /// Post-session fan-out for already-assembled content (Memo / Dictation single-shot
    /// writes, plus Obsidian + Notion for meetings). Meetings DO NOT pass through here
    /// for their Local File write -- TranscriptLogger streams that file during the session
    /// (RESEARCH.md Pitfall #7); ContentView calls savePostSession(...) at session end so
    /// Obsidian/Notion writers run, but the meeting Local File path is already on disk.
    /// Returns `SaveResult` populated per-destination.
    func save(content: String, metadata: SaveMetadata) async -> SaveResult {
        var result = SaveResult()

        if settings.localFileEnabled {
            do {
                let url = try await localFileWriter.write(
                    content: content,
                    metadata: metadata,
                    rootPath: settings.localFileRoot
                )
                result.localFileURL = url
            } catch {
                let msg = "LocalFileWriter failed: \(error.localizedDescription)"
                saveDestLog.error("\(msg, privacy: .public)")
                result.errors.append(msg)
            }
        }

        if settings.obsidianEnabled, !settings.obsidianFolderPath.isEmpty {
            do {
                let url = try await obsidianWriter.write(
                    content: content,
                    metadata: metadata,
                    folderPath: settings.obsidianFolderPath
                )
                result.obsidianFileURL = url
            } catch {
                let msg = "ObsidianWriter failed: \(error.localizedDescription)"
                saveDestLog.error("\(msg, privacy: .public)")
                result.errors.append(msg)
            }
        }

        if settings.notionAutoSendEnabled, !settings.notionDatabaseID.isEmpty {
            do {
                let url = try await notionService.sendTranscript(
                    databaseID: settings.notionDatabaseID,
                    title: metadata.title,
                    date: metadata.startDate,
                    duration: metadata.duration,
                    sourceApp: metadata.sourceApp,
                    sessionType: metadata.sessionType.notionValue,
                    speakers: metadata.speakers,
                    tags: metadata.tags,
                    transcriptMarkdown: content
                )
                result.notionPageURL = url
            } catch {
                let msg = "NotionService failed: \(error.localizedDescription)"
                saveDestLog.error("\(msg, privacy: .public)")
                result.errors.append(msg)
            }
        }

        return result
    }

    /// Open a streaming dictation session in the Local File destination if enabled.
    /// No-op if `localFileEnabled` is false (Dictation D-19 degenerate path: no file written).
    /// DictationCoordinator calls this from `beginDictation()`; the matching close is
    /// `endDictationLocalFile()` at endDictation time.
    /// Throws are SUPPRESSED here per D-15 silent-fallback semantics: a failed open is
    /// logged to os_log and the session continues with no file on disk. Library entry
    /// stores the inline transcript fallback (Dictation D-19).
    func beginDictationLocalFile(dictationLogger: DictationLogger) async {
        guard settings.localFileEnabled else { return }
        let dictationFolder = (settings.localFileRoot as NSString)
            .appendingPathComponent(SessionType.dictation.localFileSubfolder)
        do {
            try await dictationLogger.startSession(folderPath: dictationFolder)
        } catch {
            // D-15: silent fallback to clipboard-only/inline. Log only the error description
            // (NEVER the assembled transcript -- T-18-06-06 / T-18.1-02).
            saveDestLog.error("Dictation Local File open failed: \(error.localizedDescription, privacy: .public). Falling back to clipboard-only.")
        }
    }
}
