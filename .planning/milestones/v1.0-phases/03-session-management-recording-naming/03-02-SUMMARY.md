---
phase: 03-session-management-recording-naming
plan: "02"
subsystem: ui-layout
tags: [swiftui, navigation-split-view, sidebar, library-ui]
dependency_graph:
  requires: ["03-01"]
  provides: ["LibrarySidebar", "LibraryEntryRow", "RecordingNameField", "NavigationSplitView-layout"]
  affects: ["ContentView", "PSTranscribeApp"]
tech_stack:
  added: []
  patterns:
    - NavigationSplitView with .balanced style for sidebar + detail layout
    - "@Sendable closure annotation for actor updateEntry calls in Swift 6"
    - LibraryStore actor accessed via refreshLibrary() Task wrapper on MainActor
key_files:
  created:
    - PSTranscribe/Sources/PSTranscribe/Views/LibrarySidebar.swift
    - PSTranscribe/Sources/PSTranscribe/Views/LibraryEntryRow.swift
    - PSTranscribe/Sources/PSTranscribe/Views/RecordingNameField.swift
  modified:
    - PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift
    - PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift
decisions:
  - "@Sendable annotation added to updateEntry closures -- Swift 6 strict concurrency rejects non-Sendable closures crossing actor boundaries"
  - "Library entry created with empty filePath at session start; path updated at stop via finalizeFrontmatter() return value -- TranscriptLogger.currentFilePath is private, no API to expose it"
  - "savedConfirmation replaces saveBanner -- inline confirmation in RecordingNameField, fades after 2.5s"
metrics:
  duration_minutes: 4
  completed_date: "2026-04-03"
  tasks_completed: 2
  files_modified: 5
---

# Phase 03 Plan 02: NavigationSplitView Layout + View Components Summary

NavigationSplitView sidebar layout with LibrarySidebar, LibraryEntryRow, and RecordingNameField components replacing the single-column VStack layout.

## What Was Built

Three new SwiftUI view components and a ContentView restructure:

- **LibrarySidebar**: Sidebar list backed by LibraryStore. Shows "No recordings yet" empty state with `waveform.circle` icon when library is empty. Otherwise renders a `List` with `.sidebar` style and `Color.bg2` background.
- **LibraryEntryRow**: 72px row showing type icon (`phone.fill`/`mic.fill`/`exclamationmark.circle`), recording name with click-to-edit inline TextField, metadata line (date, duration, source app), first-line preview, Obsidian link button, and missing file badge.
- **RecordingNameField**: Dual-mode top bar -- "PS TRANSCRIBE" brand label when idle, editable TextField with placeholder "Name this recording" when session active. Right side shows timer + PulsingDot when recording, checkmark + "Saved" on savedConfirmation, or "Ready" + static dot when idle.
- **ContentView**: Replaced single-column VStack with NavigationSplitView (sidebar min 180px, ideal 220px, max 300px). Top bar and ControlBar remain in outer VStack spanning full width. Detail column shows live recording, past transcript (loaded via parseTranscript), or empty state. Library entries added on startSession and updated with final path/duration on stopSession.
- **PSTranscribeApp**: Window default size updated from 320x560 to 720x500.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | LibrarySidebar, LibraryEntryRow, RecordingNameField | 751d269 | LibrarySidebar.swift, LibraryEntryRow.swift, RecordingNameField.swift |
| 2 | Restructure ContentView to NavigationSplitView | 5ad23c0 | ContentView.swift, PSTranscribeApp.swift |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] TranscriptLogger.currentFilePath is private**
- **Found during:** Task 2
- **Issue:** Plan Step 3 called `await transcriptLogger.currentFilePath` to populate the library entry file path at session start. This property is `private` in TranscriptLogger.
- **Fix:** Library entry created with `filePath: ""` at session start; path populated at session stop from `finalizeFrontmatter()` return value (the saved URL's path). This is correct behavior -- the final path may differ from the initial path if context-based renaming occurs.
- **Files modified:** ContentView.swift
- **Commit:** 5ad23c0

**2. [Rule 1 - Bug] Swift 6 SendingRisksDataRace on updateEntry closures**
- **Found during:** Task 2
- **Issue:** Closures passed to `libraryStore.updateEntry(id:transform:)` triggered Swift 6 concurrency errors -- "sending main actor-isolated value of non-Sendable type" to actor-isolated method.
- **Fix:** Captured closure-captured variables into local constants, annotated closures as `@Sendable`. This satisfies the Swift 6 strict concurrency checker.
- **Files modified:** ContentView.swift
- **Commit:** 5ad23c0

## Verification

- `swift build --package-path PSTranscribe` -- Build complete, 0 errors
- `swift test --package-path PSTranscribe` -- 18 tests in 4 suites, all passed
- `grep "NavigationSplitView" ContentView.swift` -- match found
- `grep "defaultSize" PSTranscribeApp.swift` -- shows `defaultSize(width: 720, height: 500)`
- `grep "saveBanner" ContentView.swift` -- no match (retired)

## Known Stubs

None -- all plan goals achieved. Library entry filePath starts empty but is populated correctly at session stop. The Obsidian button is wired to the real `obsidianURL(for:vaultRoot:vaultName:)` function.

## Self-Check: PASSED
- LibrarySidebar.swift exists: FOUND
- LibraryEntryRow.swift exists: FOUND
- RecordingNameField.swift exists: FOUND
- ContentView.swift contains NavigationSplitView: FOUND
- PSTranscribeApp.swift contains defaultSize(width: 720, height: 500): FOUND
- Commit 751d269 exists: FOUND
- Commit 5ad23c0 exists: FOUND
- All 18 tests pass: CONFIRMED
