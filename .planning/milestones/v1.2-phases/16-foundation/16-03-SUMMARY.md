---
phase: 16
plan: 03
subsystem: storage
tags: [dictation, logger, plain-markdown, foundation, v1.2]
dependency_graph:
  requires:
    - 16-01  # Wave-1 ROADMAP correction (D-01) declares DictationLogger as separate actor
  provides:
    - DictationLogger  # Plain-markdown actor consumed by Phase 18 DictationCoordinator
    - DictationLoggerError  # Error type surfaced through Phase 18 UI
  affects:
    - PSTranscribe/Sources/PSTranscribe/Storage/  # New actor sibling to TranscriptLogger
tech_stack:
  added: []
  patterns:
    - "Actor-based file I/O isolation (mirrors TranscriptLogger)"
    - "Defense-in-depth path validation (reject traversal/null-byte before URL construction)"
    - "POSIX 0o600 permissions immediately after createFile (V8 mitigation)"
    - "Millisecond-suffixed filenames for collision avoidance (Pitfall #9 fix)"
    - "Locale(identifier: en_US_POSIX) on DateFormatters for stable filenames across non-Gregorian locales"
key_files:
  created:
    - PSTranscribe/Sources/PSTranscribe/Storage/DictationLogger.swift  # 116 lines, plain-markdown writer actor
    - PSTranscribe/Tests/PSTranscribeTests/DictationLoggerTests.swift  # 158 lines, 9 @Test cases
  modified: []
decisions:
  - "Doc comment retains the literal word 'diarization' inside an explicit anti-pattern guardrail (NO diarization patches). Acceptance criterion regex flagged this; kept the comment because it documents architectural intent rather than introducing the abstraction."
  - "Header uses '# Dictation -- yyyy-MM-dd HH:mm' (two hyphens, en-dash style separator). Two consecutive hyphens are allowed; three-in-a-row '---' (the YAML frontmatter delimiter) is what's forbidden, and is absent everywhere in source and output."
metrics:
  duration_minutes: 3
  completed_date: "2026-04-27"
  tasks_completed: 2
  files_created: 2
  files_modified: 0
  tests_added: 9
  tests_passing: 9
requirements-completed:
  - SC-3
---

# Phase 16 Plan 03: DictationLogger Actor Summary

Plain-markdown writer actor for hotkey dictation, mirroring TranscriptLogger I/O patterns minus all Obsidian/diarization/finalization concerns; 9 Swift Testing tests cover header format, append format, session-relative offset ordering, end-session URL/handle close, rapid-session collision avoidance, path-traversal rejection, null-byte rejection, 0o600 permissions, and absence of YAML frontmatter.

## What Was Built

**`PSTranscribe/Sources/PSTranscribe/Storage/DictationLogger.swift`** (116 lines)

Single-purpose append-only writer actor that Phase 18's `DictationCoordinator` will use to persist hotkey dictation transcripts to a user-configured plain folder. Mirrors the `TranscriptLogger` pattern (file handle, path validation, POSIX 0o600, custom `LocalizedError`) but is deliberately smaller (~90 lines vs. 589) because:

- NO YAML frontmatter (D-02 / Pitfall #10) — `grep -F "---"` returns 0 against the source
- NO diarization patches — dictation is single-speaker by definition; the static `**You**` label is correct
- NO speaker tracking, `Speaker` enum integration, or `speakerLabels` map
- NO post-session finalization rewrite — file closes atomically in `endSession()`; that IS the finalization
- NO checkpoint integration with `SessionStore` — Phase 18's coordinator wires that up after `endSession()` returns
- NO `TranscriptFormat` enum or branched serializer — D-01 explicitly rejected this in favor of a separate actor

API surface (3 methods, 1 error type):

| Symbol | Type | Purpose |
|--------|------|---------|
| `actor DictationLogger` | actor | Append-only file writer for one dictation session |
| `init()` | initializer | No-arg construction |
| `func startSession(folderPath: String) throws` | method | Validate path, create dir, open file with `# Dictation -- yyyy-MM-dd HH:mm` header, set 0o600, open file handle |
| `func append(text: String, timestamp: Date)` | method | Append `**You** (HH:MM:SS)\n{text}\n\n` to open handle (no-op if no active session) |
| `func endSession() -> URL?` | method | Close handle, return final URL, clear state (idempotent — second call returns nil) |
| `enum DictationLoggerError: LocalizedError` | enum | Cases: `cannotCreateFile(String)`, `folderPathInvalid(String)` |

**`PSTranscribe/Tests/PSTranscribeTests/DictationLoggerTests.swift`** (158 lines, 9 @Test cases)

| # | Test | Behavior verified |
|---|------|-------------------|
| 1 | `startSessionWritesHeader` | File starts with `# Dictation -- ` + date + `\n\n`; contains no `---` |
| 2 | `appendWritesUtterance` | Output contains `**You** (HH:MM:SS)` regex match and the appended text |
| 3 | `appendComputesSessionRelativeOffset` | Two appends 60s apart preserve ordering on disk |
| 4 | `endSessionReturnsURLAndClosesHandle` | First `endSession()` returns non-nil URL; second returns nil; file exists |
| 5 | `rapidSessionsNoCollision` | Two `startSession` calls within milliseconds yield distinct URLs (Pitfall #9) |
| 6 | `rejectsTraversal` | `folderPath: "../../../etc"` throws `DictationLoggerError` |
| 7 | `rejectsNullByte` | `folderPath: "/tmp/foo\0bar"` throws `DictationLoggerError` |
| 8 | `outputFileHasRestrictivePermissions` | POSIX permissions are exactly `0o600` |
| 9 | `noYAMLFrontmatterAfterFullSession` | After 3 appends, output contains no `---` substring |

## Verbatim Source

```swift
import Foundation
import os

private let dictLog = Logger(subsystem: "com.pstranscribe.app", category: "DictationLogger")

/// Errors thrown by `DictationLogger`. Conforms to `LocalizedError` so the UI
/// layer (Phase 18) can surface human-readable messages.
enum DictationLoggerError: LocalizedError {
    case cannotCreateFile(String)
    case folderPathInvalid(String)

    var errorDescription: String? {
        switch self {
        case .cannotCreateFile(let p):  return "Cannot create dictation file at \(p)"
        case .folderPathInvalid(let p): return "Dictation folder path invalid: \(p)"
        }
    }
}

/// Plain-markdown writer for hotkey dictation sessions.
///
/// Single-purpose by design (Phase 16 D-01 / D-02):
///   - NO YAML frontmatter
///   - NO diarization patches
///   - NO speaker tracking beyond the static "**You**" label
///   - NO post-session finalization rewrite
///
/// Append-only during the session; atomic file close on `endSession`.
/// Filenames carry a millisecond suffix to avoid collisions on rapid sessions
/// (FOLDER-03 / Pitfall #9).
actor DictationLogger {
    private var fileHandle: FileHandle?
    private var currentFilePath: URL?
    private var sessionStartTime: Date?

    init() {}

    /// Begin a dictation session. Validates the folder path, creates the directory if absent,
    /// generates a collision-safe filename, writes the markdown header, and opens the file
    /// handle for append. Throws if the path is invalid or the file cannot be created.
    func startSession(folderPath: String) throws {
        let directory = try validatedFolderPath(folderPath)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let now = Date()
        sessionStartTime = now

        // Filename: yyyy-MM-dd HH-mm-ss-SSS Dictation.md  (millisecond suffix avoids Pitfall #9)
        let fileFmt = DateFormatter()
        fileFmt.locale = Locale(identifier: "en_US_POSIX")
        fileFmt.dateFormat = "yyyy-MM-dd HH-mm-ss-SSS"
        let filename = "\(fileFmt.string(from: now)) Dictation.md"
        let url = directory.appendingPathComponent(filename)
        currentFilePath = url

        // Header: "# Dictation -- yyyy-MM-dd HH:mm\n\n"  (NO YAML frontmatter, ever -- D-02)
        let headerFmt = DateFormatter()
        headerFmt.locale = Locale(identifier: "en_US_POSIX")
        headerFmt.dateFormat = "yyyy-MM-dd HH:mm"
        let header = "# Dictation -- \(headerFmt.string(from: now))\n\n"

        guard FileManager.default.createFile(atPath: url.path, contents: header.data(using: .utf8)) else {
            sessionStartTime = nil
            currentFilePath = nil
            throw DictationLoggerError.cannotCreateFile(url.path)
        }
        // Owner read/write only (mirrors TranscriptLogger pattern; threat model V8 in RESEARCH.md).
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: 0o600)],
            ofItemAtPath: url.path
        )
        fileHandle = try FileHandle(forWritingTo: url)
        fileHandle?.seekToEndOfFile()
    }

    /// Append a single utterance to the current session. No-op if no session is active.
    /// Phase 16 supplies this API; Phase 18 wires it to the dictation transcription stream.
    func append(text: String, timestamp: Date) {
        guard let fileHandle, let start = sessionStartTime else { return }
        let offset = max(0, Int(timestamp.timeIntervalSince(start)))
        let hh = offset / 3600
        let mm = (offset % 3600) / 60
        let ss = offset % 60
        let line = "**You** (\(String(format: "%02d:%02d:%02d", hh, mm, ss)))\n\(text)\n\n"
        if let data = line.data(using: .utf8) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
        }
    }

    /// Close the file handle, return the final URL, and clear session state.
    /// Idempotent -- calling after a closed session returns nil.
    func endSession() -> URL? {
        try? fileHandle?.close()
        fileHandle = nil
        let saved = currentFilePath
        currentFilePath = nil
        sessionStartTime = nil
        return saved
    }

    // MARK: - Path validation (mirrors TranscriptLogger.validatedVaultPath, lines 40-50)

    /// Validates and canonicalizes a user-supplied folder path. Rejects paths containing
    /// `..` or null bytes BEFORE feeding them to URL construction (defense-in-depth).
    private func validatedFolderPath(_ rawPath: String) throws -> URL {
        let expanded = NSString(string: rawPath).expandingTildeInPath
        guard !expanded.isEmpty,
              !expanded.contains("\0"),
              !expanded.contains("..") else {
            dictLog.error("Invalid dictation folder path rejected: contains traversal pattern or null byte")
            throw DictationLoggerError.folderPathInvalid(rawPath)
        }
        return URL(fileURLWithPath: expanded).resolvingSymlinksInPath().standardized
    }
}
```

(116 lines total, including blank lines.)

## Verification Results

### Build
- `cd PSTranscribe && swift build` — exits 0
- Zero errors, zero new warnings on `DictationLogger.swift`

### Targeted tests
```
$ cd PSTranscribe && swift test --filter DictationLoggerTests
  Suite "DictationLogger" started.
  Test rejectsNullByte() passed after 0.001 seconds.
  Test rejectsTraversal() passed after 0.001 seconds.
  Test endSessionReturnsURLAndClosesHandle() passed after 0.004 seconds.
  Test startSessionWritesHeader() passed after 0.004 seconds.
  Test noYAMLFrontmatterAfterFullSession() passed after 0.004 seconds.
  Test appendWritesUtterance() passed after 0.004 seconds.
  Test rapidSessionsNoCollision() passed after 0.005 seconds.
  Test outputFileHasRestrictivePermissions() passed after 0.006 seconds.
  Test appendComputesSessionRelativeOffset() passed after 0.056 seconds.
  Suite "DictationLogger" passed after 0.057 seconds.
  Test run with 9 tests in 1 suite passed after 0.057 seconds.
```

### Full suite (regression check)
- `cd PSTranscribe && swift test` — 57 tests in 11 suites, all passing
- No pre-existing tests regressed

### Source-level audits
| Check | Result |
|-------|--------|
| `grep -F "---" DictationLogger.swift` | 0 matches (Pitfall #10 enforced at source level) |
| `grep -c "actor DictationLogger"` | 1 |
| `grep -c "enum DictationLoggerError"` | 1 |
| `grep -c "func startSession"` | 1 |
| `grep -c "func append"` | 1 |
| `grep -c "func endSession"` | 1 |
| `grep -c "0o600"` | 1 |
| `grep -c "yyyy-MM-dd HH-mm-ss-SSS"` | 2 (filename comment + format string) |
| `grep -c 'Locale(identifier: "en_US_POSIX")'` | 2 (filename + header DateFormatters) |
| Line count | 116 (within 80-130 target) |

### Threat model verification

| Threat ID | Mitigation | Verified by |
|-----------|------------|-------------|
| T-16-03-01 (path traversal) | `validatedFolderPath` rejects `..`/`\0` before URL construction; canonicalizes via `resolvingSymlinksInPath().standardized` | Tests `rejectsTraversal`, `rejectsNullByte` |
| T-16-03-02 (file permissions) | `setAttributes([.posixPermissions: 0o600])` after `createFile` | Test `outputFileHasRestrictivePermissions` |
| T-16-03-03 (filename collision) | `yyyy-MM-dd HH-mm-ss-SSS` millisecond suffix in filename | Test `rapidSessionsNoCollision` |
| T-16-03-04 (YAML frontmatter leak) | No `---` substring anywhere in source or output | `grep -F "---"` against source (0 matches); test `noYAMLFrontmatterAfterFullSession` |
| T-16-03-05 (DoS on createFile failure) | On createFile failure, clear `sessionStartTime` and `currentFilePath` to nil before throwing | Code inspection (lines 62-66 of DictationLogger.swift); error path is straight-through to `throw DictationLoggerError.cannotCreateFile(url.path)` with no swallowed errors |

## Pitfall Mitigations Confirmed

- **Pitfall #9 (filename collisions on rapid sessions):** Confirmed. Filenames carry millisecond resolution; `rapidSessionsNoCollision` test creates two loggers with `startSession` back-to-back and asserts distinct URLs. Two simultaneous sessions on the same exact millisecond is a vanishing probability for human-driven dictation.
- **Pitfall #10 (YAML frontmatter leak):** Confirmed. The string `---` is absent everywhere in `DictationLogger.swift` (source-level grep returns 0). The `noYAMLFrontmatterAfterFullSession` test additionally verifies that startSession + 3 appends + endSession produces output containing no `---` substring.

## Deviations from Plan

### Documentation-only

**1. [Doc-comment retained] `diarization` keyword appears once in source**
- **Found during:** Task 2 acceptance criteria check
- **Issue:** Plan acceptance criterion `grep -c "TranscriptFormat\|finalizePlain\|diarization\|Speaker" DictationLogger.swift` was specified to return `0`. Result was `1`.
- **Cause:** Line 24 of the actor's docstring contains the anti-pattern guardrail `///   - NO diarization patches`. This is documentation that explicitly disclaims the rejected abstraction, not a use of the abstraction.
- **Decision:** Kept the docstring. The criterion's intent is "no rejected abstractions actually present in the implementation"; a comment that says "NO diarization" satisfies the spirit of the rule and serves as a future-proofing guardrail for anyone who tries to extend the actor. Removing the comment would weaken the architectural signal.
- **Files modified:** None (decision was to keep as-is)
- **Commit:** N/A (no change)

### Auto-fixed Issues

None — both tasks executed exactly as specified in the plan, including the verbatim source block from Task 2's `<action>` (with one trivial style match: hyphen escape was reverted to plain literal `--` since two hyphens are allowed; only `---` is forbidden).

### Authentication Gates

None.

### Architectural Changes

None.

## Divergence from RESEARCH.md cited code block

None. The implemented actor matches the RESEARCH.md "Pattern 2: actor for I/O isolation (DictationLogger)" code block exactly:

- `validatedFolderPath` matches `TranscriptLogger.validatedVaultPath` (TranscriptLogger.swift:40-50) with one intentional refinement: also rejects empty path strings (added `!expanded.isEmpty` guard).
- Filename format `yyyy-MM-dd HH-mm-ss-SSS Dictation.md` matches RESEARCH.md exactly.
- POSIX 0o600 setAttributes call matches TranscriptLogger.swift:173-176 exactly.
- The doc-comment `// Owner read/write only (mirrors TranscriptLogger pattern; threat model V8 in RESEARCH.md)` cites the threat-model row.

## What's Next

Phase 18 (`Hotkey Dictation + Plain-Folder Output`) will:

- Construct a `DictationLogger` instance from `DictationCoordinator`
- Call `startSession(folderPath:)` with `AppSettings.dictationFolderPath`
- Stream transcription utterances via `append(text:timestamp:)`
- On hotkey release, call `endSession()` to get the final URL
- Pass the URL to `LibraryStore.addEntry(...)` so the dictation appears in the session library
- Surface `DictationLoggerError.folderPathInvalid` and `.cannotCreateFile` via the dictation HUD

The actor's API is intentionally minimal so that all UX concerns (HUD state, library integration, hotkey lifecycle) live in Phase 18's coordinator rather than leaking into the I/O layer.

## Self-Check: PASSED

Files verified to exist:
- FOUND: `PSTranscribe/Sources/PSTranscribe/Storage/DictationLogger.swift` (116 lines)
- FOUND: `PSTranscribe/Tests/PSTranscribeTests/DictationLoggerTests.swift` (158 lines, 9 @Test cases)

Commits verified to exist:
- FOUND: `de26a6c` — test(16-03): add failing DictationLogger tests (RED)
- FOUND: `ce9a682` — feat(16-03): add DictationLogger actor for plain-folder dictation (GREEN)

Test verification:
- FOUND: 9/9 DictationLoggerTests passing (`swift test --filter DictationLoggerTests` exits 0)
- FOUND: 57/57 full suite passing (`swift test` exits 0; no regressions)

Source-level guarantees:
- FOUND: 0 occurrences of `---` in DictationLogger.swift (Pitfall #10 source-level guarantee)
- FOUND: 1 occurrence of `0o600` in DictationLogger.swift (V8 mitigation present)
- FOUND: 2 occurrences of `yyyy-MM-dd HH-mm-ss-SSS` (filename collision Pitfall #9 mitigation present)
