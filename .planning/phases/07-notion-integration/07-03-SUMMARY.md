---
phase: 07
plan: 03
title: Tag sheet + send flow + context menu wiring
subsystem: notion-integration
tags: [notion, swiftui, context-menu, tag-sheet]
dependency_graph:
  requires: [07-01, 07-02]
  provides: [notion-send-flow, tag-sheet-ui, context-menu-notion]
  affects: [LibraryEntry, ContentView, LibrarySidebar, LibraryEntryRow]
tech_stack:
  added: [FlowLayout (custom Layout), AppStorage tag persistence]
  patterns: [sheet(item:), actor async/await, @Sendable closures]
key_files:
  created:
    - PSTranscribe/Sources/PSTranscribe/Views/NotionTagSheet.swift
  modified:
    - PSTranscribe/Sources/PSTranscribe/Models/Models.swift
    - PSTranscribe/Sources/PSTranscribe/Views/LibraryEntryRow.swift
    - PSTranscribe/Sources/PSTranscribe/Views/LibrarySidebar.swift
    - PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift
    - PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift
decisions:
  - notionPageURL stored as optional String? on LibraryEntry for backward-compatible Codable JSON (nil for existing entries)
  - isNotionConfigured uses settings.notionDatabaseID.isEmpty as proxy -- avoids async actor call on NotionService.apiKey() in a computed property
  - FlowLayout custom Layout for chip wrapping -- no external dependency needed for macOS 26+
  - notionSendEntry uses sheet(item:) binding pattern so LibraryEntry identity drives sheet lifecycle
  - spinner overlay rendered inside sheet .overlay rather than app-level to scope the loading indicator to the sheet
metrics:
  duration_minutes: 12
  completed_date: "2026-04-06"
  tasks_completed: 2
  tasks_total: 3
  files_changed: 6
---

# Phase 07 Plan 03: Tag Sheet + Send Flow + Context Menu Wiring Summary

**One-liner:** End-to-end "Send to Notion" flow with tag input sheet, AppStorage tag persistence, and context menu items (Send/Open/Resend) gated on `notionPageURL` state.

## Tasks Completed

| Task | Description | Commit |
|------|-------------|--------|
| 1 | LibraryEntry notionPageURL + NotionTagSheet view | 050f1f0 |
| 2 | Context menu wiring + ContentView send handler | 1feb7d0 |
| 3 | Human verification (checkpoint) | -- awaiting |

## What Was Built

**Task 1 -- LibraryEntry + NotionTagSheet:**
- Added `notionPageURL: String?` to `LibraryEntry` (backward-compatible optional; existing `library.json` entries decode with `nil`)
- Created `NotionTagSheet.swift` with: header (title + date), tag text field with Add button, selected tag chips with X-to-remove, previously-used chips (AppStorage JSON list capped at 10), Cancel/Send footer
- `FlowLayout` custom `Layout` implementation for horizontal wrapping chip rows (no third-party dependency)
- `persistTags()` helper merges newly used tags head-first into persistent list, deduplicates, caps at 10

**Task 2 -- Context menu + ContentView wiring:**
- `LibraryEntryRow`: added `isNotionConfigured: Bool` and `onSendToNotion: (() -> Void)?` props; context menu renders Send/Open/Resend based on whether `entry.notionPageURL` is nil
- `LibrarySidebar`: threaded `isNotionConfigured` and `onSendToNotion: ((UUID) -> Void)?` through to each row
- `ContentView`: added `let notionService: NotionService`, state vars (`notionSendEntry`, `isNotionSending`, `notionSendError`), `isNotionConfigured` computed property, `.sheet(item: $notionSendEntry)` presenting `NotionTagSheet`, spinner overlay while sending, `sendToNotion(entry:tags:)` async handler that reads file, extracts speakers, calls actor, updates `notionPageURL` on success
- `PSTranscribeApp`: passes `notionService` to `ContentView`

## Verification

- `swift build`: clean (2.15s)
- `swift test`: 23/23 tests pass

## Deviations from Plan

None -- plan executed exactly as written. The `notionSendError` state is captured but currently surfaces only internally (the sheet stays open on error as the plan specifies); a future plan could add inline error display to the sheet.

## Checkpoint: Task 3 -- Human Verification Required

**Type:** checkpoint:human-verify

The following flow requires manual end-to-end verification with a real Notion integration:

1. Open Settings -> Notion -> paste a valid API key -> verify "Connected to {workspace}" appears
2. Paste a database URL -> verify database title resolves
3. Close Settings. Record a short voice memo. Stop. Finalize.
4. Right-click the recording -> verify "Send to Notion..." appears
5. Click "Send to Notion..." -> tag sheet appears with entry title and date
6. Add a tag (type + Enter/Add). Add another from "previously used" if available.
7. Click Send -> spinner -> dismiss -> verify "Open in Notion" now shows in context menu
8. Click "Open in Notion" -> browser opens the Notion page
9. In Notion: verify the page has correct Title, Date, Duration, Source App, Session Type, Speakers, Tags properties
10. In Notion: verify the page body contains the transcript with speaker labels and timestamps
11. Right-click the same recording -> verify "Open in Notion" + "Resend to Notion..." appear (not "Send")
12. Record a second session. Right-click -> verify "Send to Notion..." (not Open/Resend since it hasn't been sent)
13. Kill Notion API key in Keychain (or remove from Settings). Right-click -> verify Notion items are hidden from context menu

## Known Stubs

None -- all data is wired through real state. The `notionSendError` state is captured but not yet displayed inline in the sheet UI (plan did not specify an error display widget; the sheet stays open on error for retry).

## Threat Flags

None -- no new network endpoints, auth paths, or schema changes at trust boundaries beyond what was already established in 07-01/07-02.

## Self-Check: PASSED

- [x] NotionTagSheet.swift exists at PSTranscribe/Sources/PSTranscribe/Views/NotionTagSheet.swift
- [x] Models.swift has notionPageURL field
- [x] Commits 050f1f0 and 1feb7d0 exist
- [x] swift build clean
- [x] 23/23 tests pass
