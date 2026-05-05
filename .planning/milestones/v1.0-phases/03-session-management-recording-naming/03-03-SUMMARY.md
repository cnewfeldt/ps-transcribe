---
phase: 03-session-management-recording-naming
plan: "03"
subsystem: session-lifecycle-wiring
tags:
  - swift
  - session-management
  - library
  - naming
  - obsidian
dependency_graph:
  requires:
    - "03-01 (LibraryStore + LibraryEntry models)"
    - "03-02 (LibrarySidebar, LibraryEntryRow, RecordingNameField UI)"
  provides:
    - "End-to-end session lifecycle: start creates entry, stop finalizes it"
    - "Mid-session rename via top bar -> TranscriptLogger.setName -> file on disk"
    - "Post-session rename via sidebar inline edit -> renameFinalized -> file on disk"
    - "Obsidian vault name setting in Settings"
    - "Show in Finder context menu on library entries"
  affects:
    - "ContentView session state flow"
    - "LibraryStore entry updates"
    - "TranscriptLogger file I/O"
tech_stack:
  added: []
  patterns:
    - "Debounced onChange (500ms Task.sleep) for rename to prevent rapid I/O races"
    - "Actor isolation: @Sendable closures for LibraryStore.updateEntry across actor boundary"
    - "Atomic rewrite pattern extended to mid-session setName and post-session renameFinalized"
key_files:
  created: []
  modified:
    - PSTranscribe/Sources/PSTranscribe/Storage/TranscriptLogger.swift
    - PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift
    - PSTranscribe/Sources/PSTranscribe/Views/LibraryEntryRow.swift
    - PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift
decisions:
  - "setName uses existing atomicRewrite infrastructure -- no new file I/O patterns needed"
  - "renameFinalized extracts date prefix from existing filename (prefix(19)) rather than re-parsing"
  - "onRename handler falls back to name-only update when file doesn't exist (missing file badge scenario)"
metrics:
  duration_minutes: 12
  completed_date: "2026-04-03"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 4
---

# Phase 03 Plan 03: Session Lifecycle Wiring Summary

**One-liner:** End-to-end session lifecycle wired -- start creates LibraryEntry, stop finalizes it, top bar name field renames file via debounced setName, sidebar inline edit calls renameFinalized, Obsidian vault name configurable in Settings.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add setName, renameFinalized, currentFilePathURL to TranscriptLogger | 1386b42 | TranscriptLogger.swift |
| 2 | Wire session lifecycle, name flow, sidebar rename, Obsidian setting | 70045f7 | ContentView.swift, LibraryEntryRow.swift, SettingsView.swift |

## What Was Built

**Task 1 -- TranscriptLogger additions:**
- `currentFilePathURL: URL?` computed property returns active session path or last session path post-finalization
- `setName(_ name: String) throws` flushes buffer, closes handle, renames file atomically, updates `source_file` frontmatter, reopens handle at new path
- `renameFinalized(at:to:) throws -> URL` for post-session renames -- extracts date prefix from existing filename, atomically rewrites to new path

**Task 2 -- ContentView/UI wiring:**
- Added `nameDebounceTask: Task<Void, Never>?` state variable
- Added `onChange(of: sessionName)` -- 500ms debounce calls `transcriptLogger.setName`, then updates `LibraryStore` entry filePath and name
- Updated `onRename` handler in LibrarySidebar to call `transcriptLogger.renameFinalized` first, falls back to name-only update if file is missing
- Added "Show in Finder" context menu to LibraryEntryRow via `NSWorkspace.shared.selectFile`
- Added "Obsidian Vault Name" TextField row to SettingsView "Output Folders" section bound to `$settings.obsidianVaultName`

## Verification

- `swift build --package-path PSTranscribe` exits 0
- `swift test --package-path PSTranscribe` passes all 18 tests
- `libraryStore.addEntry` present in ContentView.swift (session start)
- `libraryStore.updateEntry` present in ContentView.swift (session stop and name change)
- `transcriptLogger.setName` wired with 500ms debounce
- `transcriptLogger.renameFinalized` called from sidebar onRename
- `savedFileURL` not present (old pattern removed in Plan 02)
- `obsidianVaultName` binding in SettingsView

## Deviations from Plan

None -- plan executed exactly as written. The ContentView already had `libraryStore.addEntry` in startSession and `libraryStore.updateEntry`/`savedConfirmation` in stopSession from Plan 02. Task 2 added the missing pieces: debounced setName wiring, renameFinalized in onRename, Show in Finder, and Obsidian vault setting.

## Known Stubs

None -- all data flows are wired end-to-end. The Obsidian vault name field is empty by default, which is intentional (obsidian button only shows when `!obsidianVaultName.isEmpty`).

## Self-Check: PASSED

- TranscriptLogger.swift contains `var currentFilePathURL: URL?` -- FOUND
- TranscriptLogger.swift contains `func setName(_ name: String) throws` -- FOUND
- TranscriptLogger.swift contains `func renameFinalized(at filePath: URL, to newName: String) throws -> URL` -- FOUND
- ContentView.swift contains `transcriptLogger.setName` -- FOUND
- ContentView.swift contains `transcriptLogger.renameFinalized` -- FOUND
- ContentView.swift contains `sleep(for: .milliseconds(500))` -- FOUND
- LibraryEntryRow.swift contains `"Show in Finder"` -- FOUND
- SettingsView.swift contains `"Obsidian Vault Name"` -- FOUND
- Task 1 commit `1386b42` -- FOUND
- Task 2 commit `70045f7` -- FOUND
