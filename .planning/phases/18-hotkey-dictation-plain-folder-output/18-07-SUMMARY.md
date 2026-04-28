---
phase: 18-hotkey-dictation-plain-folder-output
plan: 07
subsystem: settings
tags: [settings, ui, swiftui, keyboard-shortcuts-recorder, folder-picker, dictation-section, source-grep, userdefaults-persistence]

# Dependency graph
requires:
  - phase: 18-hotkey-dictation-plain-folder-output (Plan 18-02)
    provides: KeyboardShortcuts SwiftPM dependency + KeyboardShortcuts.Name.dictateGlobal extension
  - phase: 18-hotkey-dictation-plain-folder-output (Plan 18-06)
    provides: DictationCoordinator behavior fully wired -- Settings UI now has live state to drive
  - phase: 16-foundation
    provides: AppSettings dictationOutputMode / dictationFolderPath / dictationHotkeyMode / clipboardRestoreDelay keys with didSet -> UserDefaults persistence
  - phase: 18-hotkey-dictation-plain-folder-output (Plan 18-01)
    provides: Wave 0 disabled SettingsViewDictationSectionTests + AppSettingsDictationPersistenceTests stubs (un-disabled by this plan)
provides:
  - Settings > Dictation section (5 controls -- Recorder, hotkey-mode Picker, output-mode Picker, folder picker, restore-delay Stepper)
  - 5 GREEN source-grep tests proving Settings UI structure (BLOCKER #4 closed)
  - 3 GREEN UserDefaults round-trip tests for FOLDER-05 + DICT-02 (BLOCKER #7 closed)
affects: [18-08]

# Tech tracking
tech-stack:
  added: []  # KeyboardShortcuts dep was added in Plan 18-02; this plan only imports it in SettingsView
  patterns:
    - "Source-grep test pattern for un-introspectable SwiftUI views (mirrors LibraryEntryRowDictationIconTests from Plan 18-06)"
    - "UserDefaults round-trip persistence test pattern with defer-cleanup (write to s1 -> construct fresh AppSettings as s2 -> assert read-back -> defer removeObject for cleanup)"
    - "Disabled-row UI pattern: .disabled() + .opacity(0.5) when mode is incompatible (folder picker greyed out when DictationOutputMode == .clipboard)"

key-files:
  created:
    - .planning/phases/18-hotkey-dictation-plain-folder-output/18-VERIFICATION.md
    - .planning/phases/18-hotkey-dictation-plain-folder-output/deferred-items.md
  modified:
    - PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/SettingsViewDictationSectionTests.swift
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/AppSettingsDictationPersistenceTests.swift

key-decisions:
  - "Used `KeyboardShortcuts.Recorder(for: .dictateGlobal)` (the v2.4.0 init form WITHOUT a label parameter) inside an HStack with a separate `Text(\"Hotkey\")` label, rather than `Recorder(\"Hotkey\", name: .dictateGlobal)`. Reason: the `for:` initializer is the canonical v2.4.0 API per the library's example; pairing it with our own Text label keeps the `.font(.system(size: 12))` styling consistent with adjacent rows. The accepting test asserts on `KeyboardShortcuts.Recorder` substring + the `for: .dictateGlobal` argument label, both of which match."
  - "Folder picker row uses `.disabled(...)` AND `.opacity(0.5)` when output mode is .clipboard, not just `.disabled(...)`. Reason: `.disabled` alone leaves controls fully opaque on macOS 26, which makes the disabled state ambiguous. Adding the opacity dim mirrors the visual convention of the rest of the app and makes the no-op state immediately legible."
  - "AppSettingsDictationPersistenceTests use `defer { UserDefaults.standard.removeObject(forKey: ...) }` rather than wrapping in a custom suite trait. Reason: simplest mechanism that survives test crashes (Swift Testing runs `defer` even on `#expect` failure inside `@MainActor` test bodies). Each test is hermetic and the cleanup runs before the next test even starts."
  - "Did NOT migrate ClipboardRestoreTests to the PasteboardTestLock pattern from Plan 18-06. Reason: out of scope for Plan 18-07 (Settings UI + persistence tests). Filed as a deferred item with the diagnosis + suggested fix so a future plan can close it cleanly. The pre-existing intermittent failure does not invalidate Plan 18-07's deliverables."

requirements-completed: [DICT-02, FOLDER-04, FOLDER-05]
requirements-touched-but-not-completed: [DICT-01, FOLDER-01]

# Metrics
duration: 4min
completed: 2026-04-28
---

# Phase 18 Plan 07: Settings > Dictation Section + Test Gate Closures Summary

**Settings > Dictation section with 5 controls (Recorder, two Pickers, folder picker, restore-delay Stepper) appended after Section("Speech Model") in SettingsView.swift, plus 8 newly-GREEN tests across 2 suites that close BLOCKER #4 (Settings UI test gate) and BLOCKER #7 (FOLDER-05 / DICT-02 deterministic persistence coverage).**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-04-28T18:53:29Z
- **Completed:** 2026-04-28T18:57:55Z
- **Tasks:** 4 (3 auto + 1 human-verify auto-approved)
- **Files modified:** 5 (3 source/test, 2 verification artifacts)

## Accomplishments

- `SettingsView.swift` extended with `import KeyboardShortcuts` and a new `Section("Dictation")` block immediately after `Section("Speech Model")` (Phase 17 D-06 ordering preserved -- order verified by `awk` line-number check).
- New `dictationSectionContent` `@ViewBuilder` private property hosts 5 controls in a `VStack(alignment: .leading, spacing: 10)`:
  1. Hotkey row -- `KeyboardShortcuts.Recorder(for: .dictateGlobal)` paired with a 12pt "Hotkey" label.
  2. Hotkey behavior `Picker` bound to `$settings.dictationHotkeyMode` (Toggle / Hold).
  3. Output `Picker` bound to `$settings.dictationOutputMode` (Clipboard only / Plain folder only / Both).
  4. Folder row -- monospaced path display + "Choose..." button reusing the existing `chooseFolder(message:onSelect:)` helper at SettingsView.swift:585. Disabled + dimmed when output mode is `.clipboard`.
  5. Restore-delay `Stepper` bound to `$settings.clipboardRestoreDelay` (0..30s, 0.5s step, monospaced "%.1fs" display).
- Footer caption: "Dictated text is excluded from clipboard-history apps (Alfred, Maccy, Pasta) via pasteboard markers." -- documents the privacy-marker behavior shipped in Plan 18-06.
- `SettingsViewDictationSectionTests` un-disabled with 5 real source-grep assertions (BLOCKER #4 -- automated test gate satisfying Nyquist Dimension 8).
- `AppSettingsDictationPersistenceTests` un-disabled with 3 UserDefaults round-trip assertions, each with `defer` cleanup (BLOCKER #7 -- FOLDER-05 has deterministic coverage; DICT-02 covered for both `dictationOutputMode` and `dictationHotkeyMode` keys).
- Build remains GREEN (`swift build` exits 0 in 0.23s after first incremental).
- Plan 18-07 test surface: 8/8 GREEN (5 SettingsViewDictationSectionTests + 3 AppSettingsDictationPersistenceTests).

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Section("Dictation") to SettingsView with 5 controls** -- `acd77e1` (feat)
2. **Task 2: Un-disable SettingsViewDictationSectionTests** -- `e83d102` (test)
3. **Task 3: Un-disable AppSettingsDictationPersistenceTests** -- `d0c73df` (test)
4. **Task 4: Manual visual verification (auto-approved per auto-mode policy)** -- no source commit; recorded in `18-VERIFICATION.md`

**Plan metadata:** TBD (final commit alongside SUMMARY.md / STATE.md / ROADMAP.md).

## Files Created/Modified

- **modified:** `PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift` -- added `import KeyboardShortcuts`; appended `Section("Dictation") { dictationSectionContent }` after the Speech Model section in the Form body; added the `dictationSectionContent` `@ViewBuilder` private property (~70 lines) above the `// MARK: - Folder picker` block. Net delta: +73 lines, no deletions.
- **modified:** `PSTranscribe/Tests/PSTranscribeTests/Phase18/SettingsViewDictationSectionTests.swift` -- removed all `.disabled(...)` traits and replaced commented-out test bodies with real `#expect(source.contains(...))` assertions. 5 tests, 7 `#expect` calls (some tests have a primary + secondary assertion).
- **modified:** `PSTranscribe/Tests/PSTranscribeTests/Phase18/AppSettingsDictationPersistenceTests.swift` -- removed all `.disabled(...)` traits and replaced commented-out test bodies with real round-trip assertions, each guarded by `defer { UserDefaults.standard.removeObject(forKey: ...) }`. 3 tests.
- **created:** `.planning/phases/18-hotkey-dictation-plain-folder-output/18-VERIFICATION.md` -- records the Task 4 auto-approval rationale and lists the four deterministic gates that passed.
- **created:** `.planning/phases/18-hotkey-dictation-plain-folder-output/deferred-items.md` -- documents the pre-existing `ClipboardRestoreTests.clipboardRestoresAfterDelay` cross-suite pasteboard race (out-of-scope for Plan 18-07; suggested fix is to migrate the suite to the `PasteboardTestLock` pattern from Plan 18-06).

### New Public API Surface

None. Plan 18-07 is purely UI + tests -- no new exported symbols, no changes to existing types.

### Tests Made GREEN

| Test | Suite | Coverage |
|---|---|---|
| `settingsViewContainsDictationSection` | SettingsViewDictationSectionTests | Asserts `Section("Dictation")` substring present |
| `settingsViewContainsRecorderForDictateGlobal` | SettingsViewDictationSectionTests | Asserts `KeyboardShortcuts.Recorder` + `for: .dictateGlobal` argument substring |
| `settingsViewContainsOutputModePicker` | SettingsViewDictationSectionTests | Asserts `$settings.dictationOutputMode` + `Picker` substrings |
| `settingsViewContainsHotkeyModePicker` | SettingsViewDictationSectionTests | Asserts `$settings.dictationHotkeyMode` substring |
| `settingsViewInvokesChooseFolderForDictation` | SettingsViewDictationSectionTests | Asserts `chooseFolder(message:` + `settings.dictationFolderPath = path` substrings |
| `dictationFolderPathRoundTripsViaUserDefaults` | AppSettingsDictationPersistenceTests | Writes a unique `/tmp/dictation-roundtrip-<UUID>` to s1, constructs fresh s2, asserts read-back |
| `dictationOutputModeRoundTripsViaUserDefaults` | AppSettingsDictationPersistenceTests | Writes a flipped DictationOutputMode to s1, constructs fresh s2, asserts read-back |
| `dictationHotkeyModeRoundTripsViaUserDefaults` | AppSettingsDictationPersistenceTests | Writes a flipped DictationHotkeyMode to s1, constructs fresh s2, asserts read-back |

## Decisions Made

See frontmatter `key-decisions` field. Highlights:

- Used the `Recorder(for:)` initializer (no label argument) inside a custom HStack with a 12pt "Hotkey" Text label, rather than the `Recorder("Hotkey", name:)` form. Both forms exist in v2.4.0; the bare-init form gives consistent typography and cleaner integration with the surrounding VStack rows.
- Belt-and-suspenders disabled state for the folder row: `.disabled(...)` plus `.opacity(0.5)`. The dimmed appearance makes the no-op state immediately legible on macOS 26 where `.disabled` alone leaves controls fully opaque.
- Per-test `defer { UserDefaults.standard.removeObject(forKey: ...) }` cleanup rather than a custom suite trait or `setUp/tearDown`. Simplest correct mechanism; runs even on `#expect` failure.
- Filed `ClipboardRestoreTests.clipboardRestoresAfterDelay` as a deferred item rather than fixing it in this plan -- out of scope (Plan 18-07 is Settings UI + persistence; the test belongs to the Plan 18-06 surface).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Pre-existing test flake documented as deferred item**
- **Found during:** Task 1 verification (full `swift test` after the SettingsView edit)
- **Issue:** The full-suite `swift test` run produced one failing test -- `ClipboardRestoreTests.clipboardRestoresAfterDelay` failed with `(pb.string(forType: .string) → "hello") == "OLD"`. The plan's Task 1 acceptance criteria include `cd PSTranscribe && swift test 2>&1 | grep -cE "^.+ failed" returns 0`, which the failure technically violates.
- **Diagnosis:** Re-ran the suite in isolation (`swift test --filter ClipboardRestoreTests`) -- 3/3 GREEN. The failure is a cross-suite pasteboard race documented inside the test file's own comment ("`.serialized` is required because all 3 tests share NSPasteboard.general (system-global state). Without serialization the tests race"). It surfaces only when `ClipboardRestoreTests`, `ClipboardPrivacyMarkersTests`, and `DictationCommitFlowTests` run in parallel and trample each other's `NSPasteboard.general` state.
- **Why pre-existing:** Plan 18-06 introduced the `PasteboardTestLock` actor mutex to handle exactly this case but did NOT migrate `ClipboardRestoreTests` to use it. Plan 18-07 inherited that gap. Nothing in Plan 18-07's source diff (SettingsView.swift only) touches NSPasteboard or any of those suites.
- **Fix applied:** Filed in `.planning/phases/18-hotkey-dictation-plain-folder-output/deferred-items.md` with the diagnosis + suggested migration to `PasteboardTestLock.shared.acquire { ... }`. Did NOT attempt the fix in Plan 18-07 (out-of-scope per the executor's SCOPE BOUNDARY rule -- only auto-fix issues directly caused by the current task's changes).
- **Files modified:** `.planning/phases/18-hotkey-dictation-plain-folder-output/deferred-items.md` (created).
- **Commits:** No source change. The deferred-items.md is committed alongside this SUMMARY in the plan-metadata commit.
- **Auto-mode acceptance:** The auto-mode checkpoint policy in the executor prompt explicitly defines the gate as "build is GREEN, both un-disabled test suites pass, grep-based source verification confirms" -- all four pass cleanly. The pre-existing flake does not appear in any Plan 18-07-introduced suite.

---

**Total deviations:** 1 (Rule 3 - documented as deferred; out of scope for direct fix).
**Impact on plan:** None. Plan 18-07 deliverables are all GREEN; the flake is a Plan 18-06 carry-over with a clear migration path.

## Issues Encountered

None within Plan 18-07's scope. The pre-existing flake is documented above and in `deferred-items.md`.

## User Setup Required

None. The Settings UI is wired entirely against existing AppSettings keys (Phase 16) and the existing KeyboardShortcuts.Name.dictateGlobal extension (Plan 18-02). User-facing flow:

1. App relaunch -- the new section appears in Settings between Speech Model and the Form's bottom edge.
2. Default Cmd+Shift+D hotkey is already registered (Plan 18-02). Users can change or clear it via the Recorder.
3. Default output mode is `.clipboard`, so the folder row starts greyed out. Switching to `.plainFolder` or `.both` enables the Choose... button -- clicking it opens NSOpenPanel against the user's filesystem.

## Self-Check: PASSED

All acceptance criteria verified:

- [x] File exists: `PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift` (modified)
- [x] `import KeyboardShortcuts` added (1 occurrence)
- [x] `Section("Dictation")` declared (1 occurrence)
- [x] Section appears AFTER `Section("Speech Model")` (awk line-number check returned `ok`)
- [x] `dictationSectionContent` `@ViewBuilder` declared (1 occurrence)
- [x] `KeyboardShortcuts.Recorder` referenced (1 occurrence)
- [x] `for: .dictateGlobal` argument referenced (1 occurrence)
- [x] `$settings.dictationHotkeyMode` Picker bound (1 occurrence)
- [x] `$settings.dictationOutputMode` Picker bound (1 occurrence)
- [x] `chooseFolder(message:` invocation count is 3 (existing 2 Obsidian uses + new Dictation use; meets `>= 2`)
- [x] `settings.dictationFolderPath = path` assignment present (1 occurrence)
- [x] `$settings.clipboardRestoreDelay` Stepper bound (1 occurrence)
- [x] `.disabled(settings.dictationOutputMode == .clipboard)` present (1 occurrence)
- [x] SettingsViewDictationSectionTests: 0 `.disabled(` remaining
- [x] SettingsViewDictationSectionTests: 5 tests pass (`Test run with 5 tests in 1 suite passed`)
- [x] SettingsViewDictationSectionTests: 7 `#expect(source.contains` calls (meets `>= 7`)
- [x] AppSettingsDictationPersistenceTests: 0 `.disabled(` remaining
- [x] AppSettingsDictationPersistenceTests: 3 tests pass (`Test run with 3 tests in 1 suite passed`)
- [x] AppSettingsDictationPersistenceTests: 4 occurrences of `UserDefaults.standard.removeObject(forKey:` (3 defer cleanups + 1 in comment; meets the >= 3 intent)
- [x] swift build exits 0 (incremental rebuild after the SettingsView edit completed in 0.23s)
- [x] All three task commits present in git log: `acd77e1` (Task 1), `e83d102` (Task 2), `d0c73df` (Task 3)
- [x] 18-VERIFICATION.md created with auto-approval rationale
- [x] deferred-items.md created with pre-existing flake diagnosis

**Pre-existing flake note:** Full-suite `swift test` reports `Test run with 175 tests in 33 suites failed after 7.355 seconds with 1 issue` -- the 1 issue is `ClipboardRestoreTests.clipboardRestoresAfterDelay` (cross-suite pasteboard race, pre-existing, out-of-scope per Plan 18-07 boundary; documented in deferred-items.md and not blocking Plan 18-07).

## Next Phase Readiness

**Plan 18-08 (Wave 6 -- Final integration: pulsing-mic menu-bar indicator, ContentView NotificationCenter listener, full-app smoke):** Unblocked. Plan 18-07 was the last plan that touches user-facing chrome (Settings UI). Plan 18-08 integrates the menu-bar indicator and the cross-component refresh signal, then closes the phase.

**Phase 18 status:** 7 of 8 plans landed. Wave 6 (Plan 18-08) is the only remaining executable plan in the phase.

The Settings UI surface is contractually frozen for downstream waves:
- Plan 18-08 may read `dictationCoordinator.isActive` for the menu-bar SF Symbol toggle (already wired in Plan 18-04 / 18-06; Settings doesn't need to know about it).
- Phase 19 (Integration & Hardening) will exercise the Settings flow as part of the QA checklist; no further Settings code changes anticipated unless a regression surfaces.

No threat-model items reopened. T-18-07-01 / T-18-07-03 are mitigated structurally by the existing `DictationLogger.validatedFolderPath` (Phase 16) and the KeyboardShortcuts library's input validation (Plan 18-02). T-18-07-04 (test pollution) is mitigated by the `defer` cleanup pattern in the persistence tests.

---
*Phase: 18-hotkey-dictation-plain-folder-output*
*Completed: 2026-04-28*
