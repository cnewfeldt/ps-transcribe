---
phase: 08-code-defect-fixes
plan: 02
subsystem: UI/Audio/Storage
tags: [badge, crash-recovery, logging, os-logger, rebrand, state-cleanup]
dependency_graph:
  requires: []
  provides: [incomplete-badge, file-exists-caching, source-pstranscribe-tag, uniform-os-logger, transcript-store-clear-on-stop]
  affects: [LibraryEntryRow, TranscriptLogger, SystemAudioCapture, MicCapture, SessionStore, ContentView]
tech_stack:
  added: []
  patterns: [SwiftUI @State + .onAppear caching, os.Logger file-scope pattern, actor-safe nonisolated logging]
key_files:
  created: []
  modified:
    - PSTranscribe/Sources/PSTranscribe/Views/LibraryEntryRow.swift
    - PSTranscribe/Sources/PSTranscribe/Storage/TranscriptLogger.swift
    - PSTranscribe/Sources/PSTranscribe/Audio/SystemAudioCapture.swift
    - PSTranscribe/Sources/PSTranscribe/Audio/MicCapture.swift
    - PSTranscribe/Sources/PSTranscribe/Storage/SessionStore.swift
    - PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift
    - README.md
decisions:
  - "File-level private let log in SystemAudioCapture is accessible from nonisolated delegate method -- no inline Logger needed"
  - "MicCapture received import os and file-level Logger to match Phase 2 pattern"
  - "transcriptStore.clear() placed after firstLine capture at line 664 per Pitfall 4 guidance"
metrics:
  duration_minutes: 18
  completed_date: "2026-04-07T16:16:39Z"
  tasks_completed: 2
  files_modified: 7
---

# Phase 08 Plan 02: Crash Recovery Badge, Logging, Rebrand, Stop Cleanup Summary

Five discrete defects resolved: yellow Incomplete badge for crash-recovered sessions, per-render FileManager I/O eliminated, frontmatter tag rebranded to source/pstranscribe, three error-path print() calls replaced with os.Logger, and transcriptStore.clear() wired into stopSession.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Add Incomplete badge and file-exists caching to LibraryEntryRow | 47b8216 | LibraryEntryRow.swift |
| 2 | Fix source/tome tag, replace print() with os.Logger, wire transcriptStore.clear() | 798ba50 | TranscriptLogger.swift, SystemAudioCapture.swift, MicCapture.swift, SessionStore.swift, ContentView.swift, README.md |

## What Was Built

**Task 1 -- LibraryEntryRow (D-03, D-04, D-05, D-06):**
- Added `@State private var fileExists: Bool = true` -- filesystem check now happens once in `.onAppear`, not on every SwiftUI body evaluation
- Yellow `clock.badge.exclamationmark.fill` badge for `!entry.isFinalized` entries with tooltip "Session was interrupted -- transcript may be incomplete"
- Missing-file red badge gated behind `entry.isFinalized` -- incomplete sessions show Incomplete badge only, not both badges simultaneously

**Task 2 -- Multi-file fixes (D-07, D-08, D-09):**
- `TranscriptLogger.swift` line 151: `source/tome` -> `source/pstranscribe`
- `README.md` line 103: `source/tome` -> `source/pstranscribe`
- `SystemAudioCapture.swift`: `print("SystemAudioCapture: stream stopped...")` -> `log.error(...)` using existing file-scope Logger (no inline Logger needed -- file-level `private let` is accessible from `nonisolated` methods)
- `MicCapture.swift`: added `import os` + file-level Logger, replaced `print("[MIC-8-FAIL]...")` with `log.error("Mic failed: ...")`
- `SessionStore.swift`: replaced `print("SessionStore: failed to write record: ...")` with `log.error("Failed to write record: ...", privacy: .public)`
- `ContentView.swift`: added `transcriptStore.clear()` immediately after `firstLine` capture in `stopSession` Task block (line 665) -- safe because `firstLine` is already captured on the preceding line, and `loadedUtterances` is subsequently populated from `parseTranscript(at:)` not from the store

## Verification

- `swift build` -- Build complete (0.27s incremental, 22s full)
- `swift test` -- 23/23 tests pass, 5 suites
- `grep "source/tome" TranscriptLogger.swift` -- empty (no matches)
- `grep "source/tome" README.md` -- empty (no matches)
- `grep "print(" SystemAudioCapture.swift` -- empty (no error-path prints)
- `grep "print(" MicCapture.swift` -- empty
- `grep "print(" SessionStore.swift` -- empty
- `grep "transcriptStore.clear()" ContentView.swift` -- 2 hits (startSession line 526, stopSession line 665)

## Deviations from Plan

None -- plan executed exactly as written.

The research noted that SystemAudioCapture's `nonisolated` delegate method might need an inline Logger due to actor isolation. On inspection, the existing `log` is a file-level `private let` (not an actor-stored property), so it is freely accessible from `nonisolated` context. No deviation required.

## Known Stubs

None -- all changes wire to real behavior.

## Threat Flags

None -- changes are within the scope of the plan's threat model. The `privacy: .public` annotation on all `log.error` calls ensures only `error.localizedDescription` is logged, not transcript content or sensitive file paths, consistent with T-08-03 mitigation.

## Self-Check: PASSED

Files exist:
- PSTranscribe/Sources/PSTranscribe/Views/LibraryEntryRow.swift -- FOUND
- PSTranscribe/Sources/PSTranscribe/Storage/TranscriptLogger.swift -- FOUND
- PSTranscribe/Sources/PSTranscribe/Audio/SystemAudioCapture.swift -- FOUND
- PSTranscribe/Sources/PSTranscribe/Audio/MicCapture.swift -- FOUND
- PSTranscribe/Sources/PSTranscribe/Storage/SessionStore.swift -- FOUND
- PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift -- FOUND
- README.md -- FOUND

Commits exist:
- 47b8216 -- FOUND
- 798ba50 -- FOUND
