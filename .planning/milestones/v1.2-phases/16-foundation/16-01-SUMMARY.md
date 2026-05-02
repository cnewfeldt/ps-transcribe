---
phase: 16
plan: 01
subsystem: models
tags: [foundation, models, dictation, enum, codable, tdd, roadmap]
requires: []
provides:
  - SessionType.dictation
  - DictationOutputMode (clipboard / plainFolder / both)
  - DictationHotkeyMode (toggle / pressAndHold)
  - Exhaustive .dictation arms in 6 SessionType switch sites
affects:
  - PSTranscribe/Sources/PSTranscribe/Models/Models.swift
  - PSTranscribe/Sources/PSTranscribe/Views/CaptureDock.swift
  - PSTranscribe/Sources/PSTranscribe/Views/ControlBar.swift
  - PSTranscribe/Sources/PSTranscribe/Views/DetailsPane.swift
  - PSTranscribe/Sources/PSTranscribe/Views/LibraryEntryRow.swift
  - PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift
  - .planning/ROADMAP.md
tech-stack:
  added: []
  patterns: [exhaustive-switch-no-default, swift-testing, tdd-red-green, string-raw-enum]
key-files:
  created:
    - PSTranscribe/Tests/PSTranscribeTests/SessionTypeCodableTests.swift
  modified:
    - PSTranscribe/Sources/PSTranscribe/Models/Models.swift
    - PSTranscribe/Sources/PSTranscribe/Views/CaptureDock.swift
    - PSTranscribe/Sources/PSTranscribe/Views/ControlBar.swift
    - PSTranscribe/Sources/PSTranscribe/Views/DetailsPane.swift
    - PSTranscribe/Sources/PSTranscribe/Views/LibraryEntryRow.swift
    - PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift
    - .planning/ROADMAP.md
decisions:
  - All three new enums are String/Codable/Sendable (matches existing SessionType conventions)
  - LibraryEntry.displayName left untouched — its `sessionType == .callCapture` ternary is an equality check, not a switch; .dictation falls through to the Voice Memo display path (Phase 18 refines)
  - ContentView.startSession .dictation arm is an early-return diagnostic; dictation entry point is DictationCoordinator (Phase 18)
  - ContentView.autoStopThreshold uses 6s for dictation (matches voiceMemo short-utterance threshold)
  - LibraryEntryRow uses "mic.circle.fill" SF Symbol so dictation rows are visually distinct from voice memo rows
  - No `default:` arms added — compiler exhaustiveness is the feature
metrics:
  tasks: 2
  duration: "4m"
  commits: 2
  tests_added: 9
  tests_passing: 9
  build_errors: 0
  build_warnings_new: 0
  completed: "2026-04-27T20:20:07Z"
requirements-completed: [SC-1]
---

# Phase 16 Plan 01: Models.swift Dictation Enums + Switch-Site Updates Summary

Added the three foundational enum changes that all v1.2 work depends on (`SessionType.dictation`, `DictationOutputMode`, `DictationHotkeyMode`), updated all six existing `SessionType` switch sites with explicit `.dictation` arms in the same atomic commit so the build never broke for downstream Wave 2 plans, and corrected the stale ROADMAP.md Phase 16 description per D-01.

## What Was Built

### 1. New Codable round-trip test suite (Task 1, RED)

`PSTranscribe/Tests/PSTranscribeTests/SessionTypeCodableTests.swift` — 81 lines, 9 `@Test` declarations using Swift Testing (`@Suite` / `@Test` / `#expect`), modeled on the existing `SpeakerCodableTests.swift` pattern. Tests cover:

- `SessionType.dictation` JSON round-trip + `rawValue == "dictation"` lowerCamel assertion (2 tests)
- `DictationOutputMode` round-trip for `.clipboard`, `.plainFolder`, `.both` plus `rawValue` assertions, plus a `decodingUnknownRawValueFails` negative test (4 tests)
- `DictationHotkeyMode` round-trip for `.toggle`, `.pressAndHold` plus `rawValue` assertions, plus a `decodingUnknownRawValueFails` negative test (3 tests)

The file was committed in a deliberate RED state — the build failed with "type 'SessionType' has no member 'dictation'" / "cannot find 'DictationOutputMode' / 'DictationHotkeyMode' in scope" — until Task 2 landed the production code.

### 2. Three enum definitions in `Models.swift` (Task 2, GREEN)

```swift
enum SessionType: String, Codable, Sendable {
    case callCapture
    case voiceMemo
    case dictation  // Phase 16, D-09
}

// MARK: - v1.2 Dictation Modes (Phase 16, D-10 / D-11)

/// Where dictation transcripts are written when a hotkey-triggered dictation session ends.
/// Default is `.clipboard` (D-08): plain folder is opt-in so no files appear on disk
/// without explicit user action.
enum DictationOutputMode: String, Codable, Sendable {
    case clipboard
    case plainFolder
    case both
}

/// Hotkey activation model. `.toggle` (default) starts on first tap, stops on second.
/// `.pressAndHold` records only while the hotkey is held down.
enum DictationHotkeyMode: String, Codable, Sendable {
    case toggle
    case pressAndHold
}
```

`Equatable` is synthesized automatically by Swift for these `String`-raw enums with no associated values — no manual conformance was required, so the test helpers `T: Codable & Equatable` worked without additional declarations.

### 3. Six exhaustive `.dictation` switch arms

| # | File | Line (post-edit) | Function | Returned literal |
|---|------|------------------|----------|------------------|
| 1 | `CaptureDock.swift` | 226 | `primaryLabel` | `"End Dictation"` |
| 2 | `ControlBar.swift` | 249–250 | `activeSessionLabel` | `"Dictation"` |
| 3 | `DetailsPane.swift` | 107 | `folderLabel` | `"Dictation"` (literal — Phase 18 wires `dictationFolderName`) |
| 4 | `LibraryEntryRow.swift` | 160–161 | `typeIconName` | `"mic.circle.fill"` SF Symbol |
| 5 | `ContentView.swift` | 83 | `autoStopThreshold` | `6` seconds (matches `.voiceMemo`) |
| 6 | `ContentView.swift` | 841–844 | `startSession(type:)` | early-return + diagnostic `lastError` (dictation owned by `DictationCoordinator`, Phase 18) |

No `default:` arms were added at any site — compiler exhaustiveness is the feature, so Phase 18 must wire dictation behavior at every consumer explicitly.

### 4. ROADMAP.md Phase 16 line correction (per D-01)

**Before:**

> - [ ] **Phase 16: Foundation** — Internal scaffolding: lift `LibraryStore`, add `anySessionActive` flag, add `SessionType.dictation` + `DictationOutputMode` enum, add v1.2 `AppSettings` keys, add `TranscriptLogger.startPlainSession` + `finalizePlain`. No user-visible change.

**After:**

> - [ ] **Phase 16: Foundation** — Internal scaffolding: lift `LibraryStore`, add `SessionCoordinator` with computed `anySessionActive`, add `SessionType.dictation` + `DictationOutputMode` + `DictationHotkeyMode` enums, add v1.2 `AppSettings` keys, add new `DictationLogger` actor (plain markdown writer, no YAML frontmatter). No user-visible change.

Diff is exactly one line; no other roadmap text was changed.

## Verification

| Check | Result |
|-------|--------|
| `cd PSTranscribe && swift build` | 0 errors, 0 new warnings on touched files |
| `swift test --filter SessionTypeCodableTests` | 9/9 passed (~0.001s each) |
| `swift test` (full suite) | 48/48 passed across 10 suites — no regressions |
| `grep -c "case dictation" Models.swift` | 1 |
| `grep -c "enum DictationOutputMode" Models.swift` | 1 |
| `grep -c "enum DictationHotkeyMode" Models.swift` | 1 |
| `grep -E "case clipboard\|case plainFolder\|case both" Models.swift \| wc -l` | 3 |
| `grep -E "case toggle\|case pressAndHold" Models.swift \| wc -l` | 2 |
| `grep -rn "case .dictation" Views/ \| wc -l` | 6 |
| `grep -c "DictationLogger actor" ROADMAP.md` | 1 |
| `grep -c "TranscriptLogger.startPlainSession" ROADMAP.md` | 0 |

The two pre-existing warnings on `StreamingTranscriber.swift` (`#SendableClosureCaptures` on captured `var consumed`) are out of scope — that file was last touched in `aaa3dba` (v2.1.0 release) and is not in this plan's `files_modified` list. Logged as a pre-existing condition; not modified by this plan.

## Commits

| Task | Hash | Type | Files |
|------|------|------|-------|
| 1 (RED) | `bc296e6` | `test` | `PSTranscribe/Tests/PSTranscribeTests/SessionTypeCodableTests.swift` |
| 2 (GREEN) | `ffe8873` | `feat` | `Models.swift`, `CaptureDock.swift`, `ControlBar.swift`, `DetailsPane.swift`, `LibraryEntryRow.swift`, `ContentView.swift`, `ROADMAP.md` |

## Deviations from Plan

None — plan executed exactly as written. The plan's note about `Equatable` synthesis ("Confirm during execution; if not synthesized, add `Equatable` to all three enums") was unnecessary: Swift synthesized `Equatable` for all three `String`-raw enums automatically, and the `T: Codable & Equatable` test helper compiled without modification.

## Self-Check: PASSED

**Files verified to exist:**
- ✓ `PSTranscribe/Tests/PSTranscribeTests/SessionTypeCodableTests.swift` (created)
- ✓ `PSTranscribe/Sources/PSTranscribe/Models/Models.swift` (modified — enums present)
- ✓ `PSTranscribe/Sources/PSTranscribe/Views/CaptureDock.swift` (modified — `case .dictation` present)
- ✓ `PSTranscribe/Sources/PSTranscribe/Views/ControlBar.swift` (modified — `case .dictation` present)
- ✓ `PSTranscribe/Sources/PSTranscribe/Views/DetailsPane.swift` (modified — `case .dictation` present)
- ✓ `PSTranscribe/Sources/PSTranscribe/Views/LibraryEntryRow.swift` (modified — `case .dictation` present)
- ✓ `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift` (modified — both switch sites have `case .dictation`)
- ✓ `.planning/ROADMAP.md` (modified — Phase 16 line corrected per D-01)

**Commits verified to exist:**
- ✓ `bc296e6` — test(16-01): add failing Codable round-trip tests for dictation enums
- ✓ `ffe8873` — feat(16-01): add dictation enums and exhaustive switch arms

## Success Criteria

SC-1 from Phase 16 Success Criteria (`App builds cleanly with SessionType.dictation and DictationOutputMode added to Models.swift`) is satisfied. `DictationHotkeyMode` (D-11) and the ROADMAP.md correction (D-01) landed in the same atomic plan so downstream Wave 2 plans (16-02 AppSettings keys, 16-03 DictationLogger, 16-04 LibraryStore lift) inherit a clean compile baseline and an accurate roadmap.
