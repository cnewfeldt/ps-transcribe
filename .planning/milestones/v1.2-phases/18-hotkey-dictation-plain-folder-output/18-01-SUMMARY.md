---
phase: 18-hotkey-dictation-plain-folder-output
plan: 01
subsystem: testing
tags: [tdd, swift-testing, red-tests, wave-0, nyquist, dictation, scaffolding]

# Dependency graph
requires:
  - phase: 16-foundation
    provides: DictationLogger actor + SessionCoordinator + AppSettings dictation keys (the substrate Wave 0 tests reference for compile-time)
provides:
  - 16 RED test files in Tests/PSTranscribeTests/Phase18/
  - 60 .disabled tests acting as automated GREEN gates for Plans 18-02 through 18-08
  - Suite-name -> wave mapping that downstream plans un-disable to satisfy Nyquist compliance
affects: [18-02, 18-03, 18-04, 18-05, 18-06, 18-07, 18-08]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Swift Testing @Suite + @Test(.disabled("Pending Plan 18-XX")) for forward-declared RED tests
    - Source-grep test pattern for SwiftUI surfaces (View introspection isn't available; test asserts production source contains required literals)

key-files:
  created:
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/GlobalHotkeyServiceTests.swift
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/DictationLoggerDiscardTests.swift
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/DictationCoordinatorStateTests.swift
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/SessionCoordinatorMutualExclusionTests.swift
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/DictationWindowControllerTests.swift
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/ClipboardRestoreTests.swift
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/ClipboardPrivacyMarkersTests.swift
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/AutoNameTests.swift
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/DictationCancelFlowTests.swift
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/DictationCommitFlowTests.swift
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/PlainFolderFallbackTests.swift
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/LibraryEntryRowDictationIconTests.swift
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/SettingsViewDictationSectionTests.swift
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/AppSettingsDictationPersistenceTests.swift
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/MenuBarIndicatorTests.swift
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/DictationHUDLiveTranscriptTests.swift
  modified: []

key-decisions:
  - "All 60 new tests use .disabled('Pending Plan 18-XX') so the suite stays GREEN while documenting the wave that will un-disable each test"
  - "Source-grep tests used for SwiftUI surfaces (LibraryEntryRow, SettingsView, MenuBarExtra, DictationHUD) where direct View introspection isn't available in unit tests"
  - "Test bodies are placeholders (#expect(Bool(true))) with extensive comments showing the post-Wave-N assertion -- forces the un-disabling wave to write the real assertion against actual production symbols rather than against a frozen mock from Wave 0"

patterns-established:
  - "Forward-declared test pattern: @Test(.disabled('Pending Plan 18-XX')) gates compilation against unavailable symbols. The test body is a placeholder; the un-disabling wave (18-02..08) is responsible for replacing both the trait AND the body with real assertions."
  - "Source-grep test pattern: when SwiftUI Views/Forms can't be introspected, assert source contains required literals (Section names, modifier calls, SF Symbol names). Mirrors the existing approach in this test target."

# scaffolded: [DICT-01, DICT-02, DICT-03, DICT-04, DICT-05, DICT-06, DICT-07, DICT-08, DICT-09, DICT-10, DICT-11, FOLDER-01, FOLDER-04, FOLDER-05]  # historical sibling field, retired in Phase 22
requirements-completed: []  # Wave 0 ships test scaffolding only -- no requirement is delivered until its implementing wave (18-02..08) lands and un-disables the corresponding @Suite. Plan frontmatter listed these IDs to declare scaffolding-coverage, not delivery; see Deviations section.

# Metrics
duration: 3min
completed: 2026-04-28
---

# Phase 18 Plan 01: Wave 0 RED Test Scaffolding Summary

**16 forward-declared Swift Testing suites (60 .disabled tests) seeded under Tests/PSTranscribeTests/Phase18/ providing automated GREEN gates for every Phase 18 implementation wave, satisfying Nyquist compliance.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-04-28T17:31:22Z
- **Completed:** 2026-04-28T17:34:45Z
- **Tasks:** 1
- **Files modified:** 16 (all created)

## Accomplishments

- Created `Tests/PSTranscribeTests/Phase18/` directory with 16 RED test files matching 18-VALIDATION.md `Wave 0 Requirements` exactly.
- 60 individual `@Test` declarations seeded, each carrying `.disabled("Pending Plan 18-XX")` so the un-disabling wave is documented in the test trait itself.
- Build remains GREEN (`swift build` exits 0); test suite remains GREEN (`swift test` -> 174 passed, 60 skipped, 0 failed).
- Test count grew by 60 (across 16 new suites: 17 existing -> 33 total).
- Nyquist compliance gate satisfied: every implementation task in Plans 18-02..08 now has an `<automated>` command pointing at a real `@Suite`.

## Task Commits

1. **Task 1: Create Phase 18 test directory and 16 RED test files** - `caad22d` (test)

**Plan metadata:** TBD (this commit)

## Files Created/Modified

All 16 files created under `PSTranscribe/Tests/PSTranscribeTests/Phase18/`:

| Suite | File | Un-disabled by | REQ Coverage |
|---|---|---|---|
| `GlobalHotkeyServiceTests` | GlobalHotkeyServiceTests.swift | Plan 18-02 | DICT-01 |
| `DictationLoggerDiscardTests` | DictationLoggerDiscardTests.swift | Plan 18-03 | DICT-08 / D-08 |
| `DictationCoordinatorStateTests` | DictationCoordinatorStateTests.swift | Plans 18-04, 18-06 | DICT-02/04/08/11 + D-05/06/07/14/16 |
| `SessionCoordinatorMutualExclusionTests` | SessionCoordinatorMutualExclusionTests.swift | Plan 18-04 | DICT-11 |
| `DictationWindowControllerTests` | DictationWindowControllerTests.swift | Plan 18-05 | DICT-10 + D-04 |
| `ClipboardRestoreTests` | ClipboardRestoreTests.swift | Plan 18-06 | DICT-06 |
| `ClipboardPrivacyMarkersTests` | ClipboardPrivacyMarkersTests.swift | Plan 18-06 | DICT-09 |
| `AutoNameTests` | AutoNameTests.swift | Plan 18-06 | D-10 / DICT-07 |
| `DictationCancelFlowTests` | DictationCancelFlowTests.swift | Plan 18-06 | DICT-08 / D-08 |
| `DictationCommitFlowTests` | DictationCommitFlowTests.swift | Plan 18-06 | DICT-05 + DICT-07 + FOLDER-02 + FOLDER-03 + D-12 |
| `PlainFolderFallbackTests` | PlainFolderFallbackTests.swift | Plan 18-06 | D-15 |
| `LibraryEntryRowDictationIconTests` | LibraryEntryRowDictationIconTests.swift | Plan 18-06 | D-11 |
| `SettingsViewDictationSectionTests` | SettingsViewDictationSectionTests.swift | Plan 18-07 | DICT-02 + FOLDER-01 + FOLDER-04 |
| `AppSettingsDictationPersistenceTests` | AppSettingsDictationPersistenceTests.swift | Plan 18-07 | FOLDER-05 |
| `MenuBarIndicatorTests` | MenuBarIndicatorTests.swift | Plan 18-08 | DICT-03 |
| `DictationHUDLiveTranscriptTests` | DictationHUDLiveTranscriptTests.swift | Plan 18-08 | DICT-04 |

## Wave Un-Disable Checklist (for downstream plans)

Each plan must un-disable (i.e., remove `.disabled` trait, fill in real assertion body) the following tests as part of its acceptance criteria:

- **Plan 18-02 (GlobalHotkeyService + KeyboardShortcuts dep):**
  - `GlobalHotkeyServiceTests` -- 3 tests
- **Plan 18-03 (DictationLogger.discardSession + hasActiveSession):**
  - `DictationLoggerDiscardTests` -- 3 tests
- **Plan 18-04 (DictationCoordinator skeleton + SessionCoordinator.dictation):**
  - `DictationCoordinatorStateTests` -- 2 tests (initialStateIsIdle, isActiveReflectsListeningState, partialTextReflectsTranscriptStore, beginNoOpsWhenSessionAlreadyActive)
  - `SessionCoordinatorMutualExclusionTests` -- 3 tests
- **Plan 18-05 (DictationWindowController + DictationHUD shell):**
  - `DictationWindowControllerTests` -- 3 tests
- **Plan 18-06 (Cancel/Commit flow + clipboard + auto-name + LibraryEntryRow icon):**
  - Remaining `DictationCoordinatorStateTests` -- 7 tests (toggle, Esc, hold)
  - `ClipboardRestoreTests` -- 3 tests
  - `ClipboardPrivacyMarkersTests` -- 3 tests
  - `AutoNameTests` -- 7 tests
  - `DictationCancelFlowTests` -- 3 tests
  - `DictationCommitFlowTests` -- 5 tests
  - `PlainFolderFallbackTests` -- 2 tests
  - `LibraryEntryRowDictationIconTests` -- 2 tests
- **Plan 18-07 (Settings UI + AppSettings persistence):**
  - `SettingsViewDictationSectionTests` -- 5 tests
  - `AppSettingsDictationPersistenceTests` -- 3 tests
- **Plan 18-08 (Menu bar indicator + HUD live wiring):**
  - `MenuBarIndicatorTests` -- 2 tests
  - `DictationHUDLiveTranscriptTests` -- 2 tests

Total tests to un-disable across waves 1-6: **60**.

## Decisions Made

- **Test body is `#expect(Bool(true))` placeholder.** The un-disabling wave (18-02..08) replaces both the `.disabled` trait AND the placeholder body with the real assertion against actual production symbols. This forces the implementing plan to wire its tests to the symbols it just created -- no copy-paste from a frozen Wave 0 mock that may have drifted.
- **Source-grep tests for SwiftUI surfaces.** `LibraryEntryRowDictationIconTests`, `SettingsViewDictationSectionTests`, `MenuBarIndicatorTests`, and `DictationHUDLiveTranscriptTests` use the source-grep pattern (test reads `.swift` file as String and asserts contains literal). This is the existing convention in this test target where SwiftUI Views can't be introspected directly.
- **DictationCoordinatorStateTests aggregates state-machine tests across two waves.** Wave 2 (18-04) un-disables 4 tests (basic state init + isActive + partialText + blocked). Wave 4 (18-06) un-disables the remaining 7 (toggle/Esc/hold semantics) once the cancel-confirmation state machine ships. Documented above.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Reverted premature requirement-completion marks in REQUIREMENTS.md**
- **Found during:** state update step (after Task 1 commit)
- **Issue:** The PLAN.md frontmatter `requirements:` field listed DICT-01..11 + FOLDER-01/04/05 (14 IDs). Following the executor instructions verbatim, `requirements mark-complete` was invoked which flipped checkboxes and table rows to "Complete". This is incorrect: Wave 0 ships *test scaffolding only*. The actual production code that satisfies these requirements is delivered by Plans 18-02 through 18-08. Marking them complete here would mislead `/gsd-verify-work` into reporting Phase 18 done when it has only RED tests on disk.
- **Fix:** Reverted all 14 IDs back to `- [ ]` (incomplete) and `Pending` in the traceability table via `sed`. Also revised SUMMARY frontmatter `requirements-completed` to `[]` and added new `requirements-scaffolded` field documenting which IDs *have* test stubs ready (informational, not delivery-tracking). Future plans (18-02..08) will mark each requirement complete as they un-disable the corresponding suite.
- **Files modified:** `.planning/REQUIREMENTS.md` (28 line edits), `.planning/phases/18-hotkey-dictation-plain-folder-output/18-01-SUMMARY.md` (frontmatter)
- **Verification:** `grep '- \[x\] \*\*DICT-' .planning/REQUIREMENTS.md` returns empty; `grep '| DICT-.* | Phase 18 | Pending |' .planning/REQUIREMENTS.md` returns 11 rows + 3 FOLDER rows.
- **Committed in:** Will be in plan-metadata commit alongside SUMMARY.md, STATE.md, ROADMAP.md.

### Mechanical (compiler) adjustments (not Rule-1-4 deviations)

The action spec listed 16 files with exact suite names and test bodies; all 16 were created verbatim modulo three trivial Swift-style adjustments to satisfy the compiler:
- Added `_ = logger` / `_ = rowSourcePath` / `_ = settingsViewPath` / `_ = hudSourcePath` no-op references in tests where the local constant would otherwise produce an "unused variable" warning. These are harmless and removed by the un-disabling wave.
- Replaced curly-quote unicode characters in disabled-trait reason strings (`…`, `≥`, `→`) with ASCII equivalents (`...`, `>=`, `->`) to avoid any encoding ambiguity in trait strings.
- Added `_ = await logger.endSession()` to `hasActiveSessionReflectsLifecycle` to clean up the started session and silence the "constant unused" warning.

These are mechanical, do not change semantics.

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug, requirement state correction)
**Impact on plan:** Critical for traceability accuracy. Without this fix, Phase 18 would appear shipped with zero implementation code on disk.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required. This plan only adds test scaffolding.

## Self-Check: PASSED

All acceptance criteria verified:

- [x] Directory exists: `PSTranscribe/Tests/PSTranscribeTests/Phase18/`
- [x] Exactly 16 files in Phase18 dir
- [x] 16 `@Suite` declarations across all files (one per file)
- [x] Each named suite verified present in matching filename
- [x] No stale `LibraryEntryFilePathTests.swift` created
- [x] Every file imports `@testable import PSTranscribe`
- [x] Every file imports `Testing`
- [x] 60 disabled tests carry `Pending Plan 18-XX` trait (>= 40 minimum)
- [x] Build is GREEN: `swift build` exits 0
- [x] Test suite is GREEN: 174 passed, 60 skipped, 0 failed
- [x] No existing tests regressed
- [x] Commit `caad22d` exists in `git log`

## Next Phase Readiness

Plans 18-02 through 18-08 are unblocked. Each downstream plan now has at least one `@Suite` it must un-disable as part of its acceptance criteria. The Nyquist compliance gate (`nyquist_compliant: true` in `18-VALIDATION.md` frontmatter) is now backed by real, runnable test commands.

Wave 1 is the next executable: Plans 18-02 (GlobalHotkeyService + KeyboardShortcuts dependency) and 18-03 (DictationLogger.discardSession + hasActiveSession) can run in parallel since they touch disjoint files.

---
*Phase: 18-hotkey-dictation-plain-folder-output*
*Completed: 2026-04-28*
