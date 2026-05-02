---
phase: 18-hotkey-dictation-plain-folder-output
verified: 2026-04-28T22:15:00Z
status: gaps_found
score: 15/16 must-haves verified (1 goal-blocking data-flow gap, 1 documentation lag, 1 carry-over flake expanded)
overrides_applied: 0
re_verification: false
gaps:
  - truth: "Plain-folder dictation files contain the spoken transcript text (FOLDER-02 + phase goal: 'optional plain-folder file output')"
    status: failed
    reason: "DictationCoordinator NEVER calls dictationLogger.append(text:timestamp:) during a session. Source grep over DictationCoordinator.swift returns calls to startSession (line 163), endSession (line 221), discardSession (line 277), hasActiveSession (line 276) — but ZERO calls to append. The plain-folder file therefore contains only the header `# Dictation -- yyyy-MM-dd HH:mm\\n\\n` with no transcript body. The Phase 16 DictationLogger.append API exists but is unwired. The existing test `DictationCommitFlowTests.bothModeWritesFileAndClipboard` only counts files in the folder; it does NOT read the file body, so this defect is invisible to the test suite. FOLDER-02 ('clean markdown') technically passes (no YAML, valid markdown header), but the file is empty content — not what users expect from 'plain-folder dictation file output'. The clipboard write path is unaffected (assembled transcript flows from dictationStore.utterances directly to NSPasteboard); only on-disk persistence is broken."
    artifacts:
      - path: "PSTranscribe/Sources/PSTranscribe/App/DictationCoordinator.swift"
        issue: "Missing per-utterance append plumbing. The 250ms elapsed-timer task at lines 175-184 reads dictationStore.volatileYouText for the HUD but does not flush utterances to dictationLogger. Either subscribe to TranscriptStore changes (utterances array growth) and append each finalized utterance, OR perform a single batched write of all assembled utterances inside endDictation BEFORE calling endSession."
      - path: "PSTranscribe/Tests/PSTranscribeTests/Phase18/DictationCommitFlowTests.swift"
        issue: "Tests assert file count but not file body content. Add a test that reads the on-disk file and asserts the body contains the spoken transcript text."
    missing:
      - "Wire dictationLogger.append calls from DictationCoordinator. Recommended: at the top of endDictation (before endSession), iterate dictationStore.utterances and call await dictationLogger.append(text:, timestamp:) for each. This preserves the millisecond-offset header convention from DictationLogger.append (lines 78-89)."
      - "Add a regression test reading the on-disk plain-folder file body and asserting it contains the assembled transcript (not just the header)."
  - truth: "REQUIREMENTS.md traceability table reflects DICT-10 status accurately"
    status: failed
    reason: "REQUIREMENTS.md line 24 still shows `[ ] DICT-10` (unchecked) and the traceability table at line 95 marks DICT-10 as `Pending`, but the code at DictationWindowController.swift:47 sets `panel.sharingType = .none` and the requirement is genuinely satisfied. Documentation has not been updated to match the shipped state."
    artifacts:
      - path: ".planning/REQUIREMENTS.md"
        issue: "Line 24 should be `[x]` (DICT-10 is implemented). Line 95 traceability row should read `Complete` instead of `Pending`."
    missing:
      - "Flip `- [ ] **DICT-10**:` to `- [x] **DICT-10**:` on line 24 of REQUIREMENTS.md"
      - "Update traceability row `| DICT-10 | Phase 18 | Pending |` to `| DICT-10 | Phase 18 | Complete |` on line 95"
  - truth: "All Phase 18 tests pass deterministically when the full suite runs"
    status: partial
    reason: "Cross-suite parallel-test races affect MORE tests than `deferred-items.md` documents. Across 5 full-suite runs, three different tests have intermittently failed: (1) `ClipboardRestoreTests.clipboardRestoresAfterDelay` — already documented in deferred-items.md; (2) `PlainFolderFallbackTests.plainFolderWriteFailureSilentlyFallsBackToClipboard` — observed to fail in 2/5 runs, identical pasteboard race signature; (3) `DictationLoggerTests.rapidSessionsNoCollision` — observed to fail in 1/5 runs, parallel timestamp-collision race. All three pass in isolation. Same root cause as the documented flake (parallel tests sharing global state — NSPasteboard.general and millisecond-resolution clocks). Single fix path covers all three."
    artifacts:
      - path: "PSTranscribe/Tests/PSTranscribeTests/Phase18/PlainFolderFallbackTests.swift"
        issue: "Pasteboard race when run in parallel with other Phase 18 pasteboard suites; needs `PasteboardTestLock` actor mutex pattern"
      - path: "PSTranscribe/Tests/PSTranscribeTests/Phase18/ClipboardRestoreTests.swift"
        issue: "Documented in deferred-items.md; same migration"
      - path: "PSTranscribe/Tests/PSTranscribeTests/DictationLoggerTests.swift"
        issue: "Parallel-suite millisecond-resolution timestamp collision; either serialize by suite or bump filename suffix to nanoseconds"
    missing:
      - "Update deferred-items.md to list all three flaky tests under one ticket (currently lists only ClipboardRestoreTests)"
      - "Apply the `PasteboardTestLock` mutex to ClipboardRestoreTests AND PlainFolderFallbackTests"
      - "Either serialize DictationLoggerTests with `.serialized` at the suite level, or bump DictationLogger filename suffix from millisecond (-SSS) to nanosecond resolution to make collisions implausible"
human_verification:
  - test: "Plain-folder dictation file body content (CONFIRMS GAP #1)"
    expected: "Configure Settings > Dictation > Output = Plain folder. Trigger a dictation. Speak: 'one two three four five'. Stop. Open the resulting `YYYY-MM-DD HH-mm-ss-SSS Dictation.md` file. The body should contain the spoken text. EXPECTED OUTCOME based on code inspection: the body is EMPTY — only the `# Dictation -- yyyy-MM-dd HH:mm\\n\\n` header is present. If empty body is observed, this confirms the data-flow gap. If body contains the transcript, my code analysis missed an append code path and gap #1 is incorrect."
    why_human: "Filesystem inspection of an actual session file. The unit tests assert file count, not body content."
  - test: "End-to-end hotkey dictation from a non-PS-Transcribe frontmost app"
    expected: "Press Cmd+Shift+D while Safari/Mail/etc is frontmost. HUD appears within ~200ms at the bottom-center of the active screen. Speak briefly. Press Cmd+Shift+D again. HUD shows 'Copied to clipboard' for ~1s and dismisses. Cmd+V in Safari pastes the transcript. Library sidebar shows a new entry with mic.fill icon."
    why_human: "WARNING #10 — the Carbon RegisterEventHotKey -> @MainActor dispatch path is a runtime-only guarantee. Unit tests cannot exercise the actual OS-level hotkey callback. A wrong dispatch crashes AppKit instantly."
  - test: "Pulsing menu-bar mic icon during active dictation"
    expected: "Menu bar shows `book.closed` SF Symbol when idle. During an active dictation, icon switches to `mic.fill` and visibly pulses. Returns to `book.closed` when dictation ends."
    why_human: "Visual SF Symbol animation cannot be programmatically asserted; source-grep confirms `.symbolEffect(.pulse, isActive:)` binding but only an eye can confirm the pulse actually renders."
  - test: "HUD multi-monitor positioning"
    expected: "On a multi-monitor setup, HUD appears at bottom-center of the screen that contains the keyboard focus / mouse cursor (NSScreen.main). Move focused app to second monitor, trigger hotkey — HUD appears on that monitor."
    why_human: "`NSScreen.main` semantics depend on focused-window heuristics; only manual testing confirms it lands where the user expects."
  - test: "Clipboard history exclusion (DICT-09 belt-and-suspenders)"
    expected: "Install Maccy or Alfred. Trigger a dictation, commit. Open clipboard manager — dictated text should NOT appear in clipboard history (the TransientType + AutoGeneratedType markers are well-behaved-app contracts, not OS guarantees)."
    why_human: "Third-party app behavior cannot be unit-tested. Listed in Phase 19 hardening checklist."
  - test: "Eager pre-warm cost when hotkey is unassigned"
    expected: "Clear the hotkey via Settings > Dictation > Hotkey Recorder (Delete key). Restart app. Activity Monitor should show ~500MB LOWER resident memory than the default-hotkey baseline (WARNING #11 opt-out gate)."
    why_human: "Memory measurements at app launch require Activity Monitor or `top`; not unit-testable."
---

# Phase 18: Hotkey Dictation + Plain-Folder Output Verification Report

**Phase Goal:** Standalone hotkey-driven dictation with floating HUD, clipboard write with privacy markers, optional plain-folder file output, library entry creation, and pulsing menu-bar mic indicator. Mutual exclusion with active meeting sessions.

**Verified:** 2026-04-28T22:15:00Z
**Status:** gaps_found (1 goal-blocking data-flow gap; 2 non-blocking gaps)
**Re-verification:** No — initial verification (executor's prior writes to 18-VERIFICATION.md were treated as scratch and overwritten)

## Goal Achievement

### Observable Truths

| #   | Truth                                                                                                                                            | Status     | Evidence                                                                                                                                                                                                                                                |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------ | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | User can trigger dictation via configurable global hotkey, default Cmd+Shift+D (DICT-01)                                                         | ✓ VERIFIED | `GlobalHotkeyService.swift:54-57` registers `Name.dictateGlobal` with default `.d + .command + .shift`. Wired in `PSTranscribeApp.swift:52-65` via `KeyboardShortcuts.onKeyDown`. Recorder UI at `SettingsView.swift:598`.                              |
| 2   | User can choose toggle vs press-and-hold mode (DICT-02)                                                                                          | ✓ VERIFIED | `Models.swift:74-77` defines `DictationHotkeyMode { toggle, pressAndHold }`. `PSTranscribeApp.swift:54-72` switches on `settings.dictationHotkeyMode` for callback routing. Picker exposed at `SettingsView.swift:602-605`.                             |
| 3   | Menu bar shows pulsing mic indicator while dictation is recording (DICT-03)                                                                      | ✓ VERIFIED | `PSTranscribeApp.swift:174-176` toggles `mic.fill` ↔ `book.closed` based on `dictationCoordinator.isActive` with `.symbolEffect(.pulse, isActive:)`. `MenuBarIndicatorTests` 2/2 GREEN (source-grep verified).                                          |
| 4   | Floating HUD shows live partial transcription (DICT-04)                                                                                          | ✓ VERIFIED | `DictationHUD.swift:31-37` renders `partialText` in the listening arm. `DictationCoordinator.attach()` at `DictationCoordinator.swift:112-124` binds the HUD body to `dictationStore.volatileYouText`. Elapsed timer ticks every 250ms in `beginDictation`. |
| 5   | Final transcript written to clipboard on stop (DICT-05)                                                                                          | ✓ VERIFIED | `DictationCoordinator.swift:225` calls `writeToClipboardWithPrivacyMarkers(assembled)` in `endDictation` when mode is `.clipboard` or `.both`. Helper at lines 352-370 calls `pb.setString(text, forType: .string)`.                                    |
| 6   | Previous clipboard contents restored after configurable delay, with changeCount guard (DICT-06)                                                  | ✓ VERIFIED | `DictationCoordinator.swift:375-396` saves prev items, schedules restore after `settings.clipboardRestoreDelay`, skips restore when `pb.changeCount != postWriteCount` (Pitfall #6 guard).                                                              |
| 7   | Each successful dictation creates a library entry (DICT-07 / D-09)                                                                               | ✓ VERIFIED | `DictationCoordinator.swift:238-251` constructs `LibraryEntry` with `sessionType: .dictation` on every commit; `await libraryStore.addEntry(entry)`. No min-word/duration filter.                                                                       |
| 8   | Cancel via Esc / second hotkey writes nothing; sessions ≥30s prompt for confirmation (DICT-08 / D-06 / D-08)                                     | ✓ VERIFIED | `DictationCoordinator.swift:270-282` (cancelDictation: stops engine, calls `discardSession()`, no clipboard write, no library entry). Esc routing at lines 292-314 implements 30s confirmation. `DictationCancelFlowTests` 3/3 GREEN.                   |
| 9   | Clipboard write includes pasteboard privacy markers TransientType + AutoGeneratedType (DICT-09)                                                  | ✓ VERIFIED | `DictationCoordinator.swift:366-367` sets both `org.nspasteboard.TransientType` and `org.nspasteboard.AutoGeneratedType`. `ClipboardPrivacyMarkersTests` 3/3 GREEN.                                                                                     |
| 10  | Floating HUD respects existing privacy mode (NSWindowSharingType.none) (DICT-10)                                                                 | ✓ VERIFIED | `DictationWindowController.swift:47` sets `panel.sharingType = .none` at NSPanel creation. Doc comment at line 11 references DICT-10. **Note:** REQUIREMENTS.md still shows this as `Pending` — see Gap #2 (documentation lag).                         |
| 11  | Only one recording session active at a time — meeting + dictation mutually exclusive (DICT-11)                                                   | ✓ VERIFIED | `SessionCoordinator.swift:33` holds `weak var dictation: DictationCoordinator?`. `anySessionActive` (lines 39-43) ORs `(dictation?.isActive ?? false)`. `beginDictation` at `DictationCoordinator.swift:151-154` checks gate. 3/3 mutex tests GREEN.    |
| 12  | User can configure plain output folder via folder picker in Settings (FOLDER-01)                                                                 | ✓ VERIFIED | `SettingsView.swift:628-632` Choose… button calls `chooseFolder(message: "Select dictation output folder")` — reuses existing helper at line 658 (NOT duplicated). Mirrors the Obsidian folder pattern.                                                  |
| 13  | Plain-folder transcripts are clean markdown with no YAML frontmatter AND contain the spoken text (FOLDER-02)                                     | ✗ FAILED   | DictationLogger.swift:60 writes header `"# Dictation -- yyyy-MM-dd HH:mm\\n\\n"`. NO YAML — that part holds. **But:** DictationCoordinator never calls dictationLogger.append, so the body is empty. The "clean markdown" file lacks the transcript content. See Gap #1. |
| 14  | Filenames follow human-readable date convention with millisecond suffix avoiding rapid-session collisions (FOLDER-03)                            | ⚠️ PARTIAL  | `DictationLogger.swift:51-53` formats `yyyy-MM-dd HH-mm-ss-SSS Dictation.md`. **Caveat:** `rapidSessionsNoCollision` test failed in 1/5 full-suite runs due to parallel-clock collision — see Gap #3.                                                  |
| 15  | Output mode is selectable: clipboard / plainFolder / both (FOLDER-04)                                                                            | ⚠️ PARTIAL  | `Models.swift:66-70` defines `DictationOutputMode`. `DictationCoordinator.swift:160-169` opens logger when mode includes plainFolder; lines 224-227 write clipboard when mode includes clipboard. Selection wiring is correct, but plain-folder branch produces empty-body files (see Gap #1). |
| 16  | Plain-folder path persists across app restarts via UserDefaults (FOLDER-05)                                                                      | ✓ VERIFIED | `AppSettings.swift:61-63` `dictationFolderPath` has `didSet { UserDefaults.standard.set(... forKey: "dictationFolderPath") }`. Init at line 127 reads back. `AppSettingsDictationPersistenceTests` 3/3 GREEN.                                            |

**Score:** 13 truths fully verified, 2 partial (FOLDER-03 flake-affected, FOLDER-04 partly affected by data-flow gap), 1 failed (FOLDER-02 body content). 16/16 requirements have implementation scaffolding present, but the plain-folder data flow is not fully connected to the transcript stream.

### Required Artifacts

| Artifact                                                                                          | Expected                                                                                                                                | Status     | Details                                                                                                                                                                                                |
| ------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `PSTranscribe/Sources/PSTranscribe/Services/GlobalHotkeyService.swift`                            | KeyboardShortcuts wrapper with onKeyDown/onKeyUp callbacks + hotkeyAssigned property                                                    | ✓ VERIFIED | 58 lines, all expected APIs present. `hotkeyAssigned` (line 31-33) reads `KeyboardShortcuts.getShortcut(for: .dictateGlobal)`.                                                                          |
| `PSTranscribe/Sources/PSTranscribe/App/DictationCoordinator.swift`                                | State machine + begin/end/cancel/handleEscape/handleHoldRelease/preWarmModels + clipboard markers + auto-name + plain-folder body write | ⚠️ STUB-ON-DATA | 458 lines. All lifecycle APIs present. State enum at lines 33-40, begin at 148-194, end at 201-264, cancel at 270-282, handleEscape at 292-314, handleHoldRelease at 321-329. **Missing: append() invocation chain — see Gap #1.** |
| `PSTranscribe/Sources/PSTranscribe/App/DictationWindowController.swift`                           | NSPanel with .nonactivatingPanel + .floating + .canJoinAllSpaces + sharingType=.none + bottom-center positioning                        | ✓ VERIFIED | 138 lines. styleMask at line 33, level at 39, collectionBehavior at 42, sharingType at 47, positionAtBottomCenter at 107-126.                                                                          |
| `PSTranscribe/Sources/PSTranscribe/Views/DictationHUD.swift`                                      | Three-block layout (indicator + timer + partial/status + Stop button); 5 state arms; native HUD vibrancy via container                  | ✓ VERIFIED | 181 lines including 5 #Preview blocks. Body has 5-arm switch on state, displayText helper, recordingIndicator @ViewBuilder, formatElapsed helper.                                                       |
| `PSTranscribe/Sources/PSTranscribe/Storage/DictationLogger.swift`                                 | startSession + append + endSession + discardSession + hasActiveSession; ms-suffix filenames; no YAML; 0o600 perms                       | ✓ VERIFIED | 141 lines. `discardSession` at lines 116-124 deletes file via `removeItem(at:)`. `hasActiveSession` at 106-108. `DictationLoggerDiscardTests` 3/3 GREEN. **API exists — but coordinator does not call append.** |
| `PSTranscribe/Sources/PSTranscribe/Models/Models.swift`                                           | LibraryEntry gains `var inlineTranscript: String?` (D-12), Optional + missing-key Codable round-trip                                    | ✓ VERIFIED | Line 96. `clipboardOnlyEntryPersistsInlineTranscriptViaCodable` test GREEN. Optional means missing key decodes as nil → backward compat with pre-Phase 18 library.json.                                  |
| `PSTranscribe/Sources/PSTranscribe/Views/LibraryEntryRow.swift`                                   | `case .dictation:` arm in iconChip returning `mic.fill` (D-11)                                                                          | ✓ VERIFIED | Lines 160-164. Comment cites D-11. `LibraryEntryRowDictationIconTests` 2/2 GREEN.                                                                                                                       |
| `PSTranscribe/Sources/PSTranscribe/App/SessionCoordinator.swift`                                  | `weak var dictation: DictationCoordinator?` slot + `(dictation?.isActive ?? false)` in anySessionActive                                  | ✓ VERIFIED | Line 33 + lines 39-43. Phase 16's `weak var engine` and Phase 17's `weak var modelUpdate` are also OR'd in (defense in depth).                                                                          |
| `PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift`                                     | App-scope @State for hotkey/coordinator/windowCtrl + init wiring + escapeKeyMonitor + eager pre-warm with hotkeyAssigned guard          | ✓ VERIFIED | 284 lines. Lines 12-14 declare @State. init() at 19-110 instantiates everything, attaches windowController, wires SessionCoordinator slot, registers callbacks, installs Esc monitor, schedules pre-warm. |
| `PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift`                                      | `Section("Dictation")` AFTER Speech Model section + KeyboardShortcuts.Recorder + hotkey-mode picker + output-mode picker + folder picker (chooseFolder reuse) + clipboardRestoreDelay stepper | ✓ VERIFIED | Section at line 68 (immediately after Speech Model at 64). `dictationSectionContent` at lines 590-654. Folder Choose button at 628-632 calls existing `chooseFolder` helper at line 658 — NOT duplicated. |
| `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift`                                       | `.task` listener for `.dictationSessionEnded` notification → `refreshLibrary()`                                                         | ✓ VERIFIED | Lines 394-404. The `await libraryStore.entries` read forces SwiftUI to observe before refresh.                                                                                                          |
| `PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift`                                    | All four v1.2 dictation keys (mode/folder/hotkeyMode/restoreDelay) with didSet UserDefaults sync + init read-back                       | ✓ VERIFIED | Lines 54-77 + init at 123-138. All 4 keys mirror correctly. `clipboardRestoreDelay` defaults to 3.0 via `defaults.object(forKey:) == nil` check (line 135).                                              |
| `PSTranscribe/Package.swift`                                                                      | KeyboardShortcuts 2.4.0+ SwiftPM dep                                                                                                    | ✓ VERIFIED | Line 11 (package), line 19 (product).                                                                                                                                                                  |

### Key Link Verification

| From                            | To                                            | Via                                                  | Status     | Details                                                                                                                                |
| ------------------------------- | --------------------------------------------- | ---------------------------------------------------- | ---------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| KeyboardShortcuts.onKeyDown     | DictationCoordinator.beginDictation/endDictation | GlobalHotkeyService.onKeyDown closure → app-scope handler | ✓ WIRED    | `GlobalHotkeyService.swift:40` sets library callback; `PSTranscribeApp.swift:52-65` assigns `initialHotkey.onKeyDown = { ... }`.        |
| PSTranscribeApp.init            | DictationCoordinator(settings:sessionCoordinator:libraryStore:) | Direct call in init                                  | ✓ WIRED    | `PSTranscribeApp.swift:29-33`.                                                                                                          |
| PSTranscribeApp.init            | DictationCoordinator.attach(windowController:)| Direct call in init                                  | ✓ WIRED    | `PSTranscribeApp.swift:36`.                                                                                                             |
| PSTranscribeApp.init            | SessionCoordinator.dictation slot             | Direct assignment in init                            | ✓ WIRED    | `PSTranscribeApp.swift:39`.                                                                                                             |
| DictationCoordinator.beginDictation | SessionCoordinator.anySessionActive       | Mutual-exclusion guard                               | ✓ WIRED    | `DictationCoordinator.swift:151-154`. Confirmed by `SessionCoordinatorMutualExclusionTests` 3/3 GREEN.                                  |
| DictationCoordinator.endDictation | NSPasteboard.general                         | writeToClipboardWithPrivacyMarkers helper            | ✓ WIRED    | `DictationCoordinator.swift:352-370`.                                                                                                    |
| DictationCoordinator.endDictation | LibraryStore.addEntry                        | `await libraryStore.addEntry(entry)`                 | ✓ WIRED    | `DictationCoordinator.swift:251`.                                                                                                        |
| DictationCoordinator.endDictation | NotificationCenter.default                   | `.dictationSessionEnded` post                        | ✓ WIRED    | `DictationCoordinator.swift:263`. ContentView listener at `ContentView.swift:394-404`.                                                  |
| DictationCoordinator.cancelDictation | DictationLogger.discardSession            | `await dictationLogger.discardSession()`             | ✓ WIRED    | `DictationCoordinator.swift:276-278`. Guarded by `hasActiveSession` so no orphan deletion.                                              |
| **DictationCoordinator (any path)** | **DictationLogger.append(text:timestamp:)** | (no call site exists)                            | ✗ NOT_WIRED | **GAP #1.** Source grep over `DictationCoordinator.swift` returns ZERO calls to `dictationLogger.append`. The plain-folder file body is therefore empty. |
| MenuBarExtra label              | dictationCoordinator.isActive                 | Conditional symbol + symbolEffect.pulse              | ✓ WIRED    | `PSTranscribeApp.swift:174-176`.                                                                                                         |
| Esc keyboard                    | DictationCoordinator.handleEscape             | NSEvent.addGlobalMonitorForEvents(.keyDown) at app scope | ✓ WIRED    | `PSTranscribeApp.swift:79-87`. keyCode == 53 (kVK_Escape). Routes only when isActive.                                                   |
| Eager pre-warm                  | DictationCoordinator.preWarmModels            | Task.detached(priority: .background) → MainActor.run gated on `hotkeyAssigned` | ✓ WIRED    | `PSTranscribeApp.swift:96-109`. WARNING #11 opt-out gate honored: `guard hotkeyForPrewarm.hotkeyAssigned else { return }`.              |
| SettingsView dictation folder   | chooseFolder helper                           | `chooseFolder(message:onSelect:)` at line 658        | ✓ WIRED    | `SettingsView.swift:628-632`. Same helper used by the existing Obsidian folder pickers (line 178). NOT duplicated.                       |

### Data-Flow Trace (Level 4)

| Artifact                          | Data Variable             | Source                                                                                          | Produces Real Data | Status     |
| --------------------------------- | ------------------------- | ----------------------------------------------------------------------------------------------- | ------------------ | ---------- |
| DictationHUD                      | partialText               | `dictationStore.volatileYouText` updated by 250ms timer in `beginDictation` (lines 175-184)      | Yes (live engine output) | ✓ FLOWING  |
| DictationHUD                      | elapsed                   | `Date().timeIntervalSince(sessionStartTime)` in 250ms timer                                      | Yes (wall clock)   | ✓ FLOWING  |
| DictationHUD                      | state                     | `coordinator.state` (private(set), mutated by lifecycle methods)                                 | Yes                | ✓ FLOWING  |
| MenuBarExtra label                | dictationCoordinator.isActive | `state` switch (.listening/.cancellingPending/.loadingModel return true)                     | Yes                | ✓ FLOWING  |
| LibraryEntryRow icon (.dictation) | entry.sessionType         | LibraryEntry persisted via LibraryStore.addEntry from `endDictation`; sessionType is `.dictation` literal | Yes                | ✓ FLOWING  |
| Clipboard string                  | assembled                 | `dictationStore.utterances.map { $0.text } + volatile`, joined with " "                          | Yes                | ✓ FLOWING  |
| **Plain-folder file body**        | **session utterances**    | **DictationLogger.append() — never invoked by coordinator. Only the header from startSession is written.** | **No (header only — body empty)** | **✗ DISCONNECTED (Gap #1)** |
| LibraryEntry.inlineTranscript     | assembled                 | Set when finalFileURL is nil (clipboard-only or D-15 fallback)                                  | Yes                | ✓ FLOWING  |

**Critical finding:** The plain-folder file is opened (header written via `startSession`) and closed (`endSession` returns the URL), but no per-utterance writes happen between those two points. The transcript text never lands on disk. This is a goal-blocking gap because the phase goal explicitly includes "optional plain-folder file output" and FOLDER-02 expects clean markdown content (not just a header).

### Behavioral Spot-Checks

| Behavior                                                  | Command                                                                                            | Result                                  | Status     |
| --------------------------------------------------------- | -------------------------------------------------------------------------------------------------- | --------------------------------------- | ---------- |
| swift build is GREEN                                      | `cd PSTranscribe && swift build`                                                                   | "Build complete! (0.13s)"               | ✓ PASS     |
| Phase 18 test suite (all 16 files compile and run)        | `swift test --filter Phase18` (implicit via full run)                                              | 33 suites, 175 tests in full run        | ✓ PASS     |
| Phase 18 test suite — full run, deterministic             | `swift test` (5 trials)                                                                            | 3/5 GREEN, 2/5 had 1 flaky failure each | ⚠️ FLAKY (Gap #3) |
| Phase 17 ModelUpdateService tests still GREEN (regression) | `swift test --filter ModelUpdateService`                                                           | 25 tests, all GREEN                     | ✓ PASS     |
| Phase 16 DictationLogger isolated                         | `swift test --filter DictationLogger`                                                              | 12 tests in 2 suites GREEN              | ✓ PASS     |
| Phase 16 SessionCoordinator + LibraryStore not regressed  | `swift test --filter SessionCoordinator` (covered by Phase 18 mutex tests)                          | 3/3 GREEN                               | ✓ PASS     |
| Plain-folder fallback in isolation                        | `swift test --filter PlainFolderFallbackTests`                                                     | 2/2 GREEN                               | ✓ PASS     |
| Source grep — no TODO/FIXME/PLACEHOLDER in Phase 18 files | `grep -E "TODO\|FIXME\|XXX\|HACK\|PLACEHOLDER" {coordinator, windowCtrl, hotkey, logger, hud}.swift` | No matches                              | ✓ PASS     |
| Source grep — `dictationLogger.append` call sites         | `grep -n "dictationLogger\.\|append(" DictationCoordinator.swift`                                  | startSession, endSession, hasActiveSession, discardSession — but NO append | ✗ FAIL (Gap #1) |

### Requirements Coverage

| Requirement | Source Plan(s)            | Description                                                              | Status      | Evidence                                                                                                                  |
| ----------- | ------------------------- | ------------------------------------------------------------------------ | ----------- | ------------------------------------------------------------------------------------------------------------------------- |
| DICT-01     | 18-02, 18-08              | Configurable hotkey, default Cmd+Shift+D                                 | ✓ SATISFIED | GlobalHotkeyService.swift:54-57 + PSTranscribeApp.swift:52-65 wiring; SettingsView.swift:598 Recorder.                    |
| DICT-02     | 18-04, 18-06, 18-07, 18-08 | Toggle vs press-and-hold mode                                            | ✓ SATISFIED | Models.swift:74-77 + DictationCoordinator.handleHoldRelease + PSTranscribeApp.swift:54-72 mode-switch.                    |
| DICT-03     | 18-08                     | Menu bar pulsing-mic indicator while recording                           | ✓ SATISFIED | PSTranscribeApp.swift:174-176 with .symbolEffect(.pulse, isActive:); MenuBarIndicatorTests 2/2 GREEN.                     |
| DICT-04     | 18-05, 18-06, 18-08       | Floating HUD with live partial transcription                             | ✓ SATISFIED | DictationHUD.swift + DictationCoordinator.attach() binding + 250ms partialText timer.                                     |
| DICT-05     | 18-06                     | Final transcript on clipboard on stop                                    | ✓ SATISFIED | DictationCoordinator.swift:225 calls writeToClipboardWithPrivacyMarkers.                                                  |
| DICT-06     | 18-06                     | Previous clipboard contents restored after configurable delay            | ✓ SATISFIED | DictationCoordinator.swift:375-396 with changeCount guard. ClipboardRestoreTests 3/3 in isolation.                        |
| DICT-07     | 18-06                     | Each session saved to library                                            | ✓ SATISFIED | DictationCoordinator.swift:238-251.                                                                                       |
| DICT-08     | 18-03, 18-06              | Esc / second hotkey cancel; ≥30s confirmation                            | ✓ SATISFIED | DictationCoordinator.swift:270-314. DictationCancelFlowTests 3/3 GREEN.                                                   |
| DICT-09     | 18-06                     | Pasteboard markers TransientType + AutoGeneratedType                     | ✓ SATISFIED | DictationCoordinator.swift:366-367. ClipboardPrivacyMarkersTests 3/3 GREEN.                                               |
| DICT-10     | 18-05                     | HUD respects NSWindowSharingType.none                                    | ✓ SATISFIED | DictationWindowController.swift:47. **Documentation gap:** REQUIREMENTS.md still shows Pending — see Gap #2.              |
| DICT-11     | 18-04, 18-06              | Mutual exclusion: dictation + meeting                                    | ✓ SATISFIED | SessionCoordinator.swift:33,39-43 + DictationCoordinator.swift:151-154. SessionCoordinatorMutualExclusionTests 3/3 GREEN. |
| FOLDER-01   | 18-07                     | Plain-folder picker in Settings                                          | ✓ SATISFIED | SettingsView.swift:628-632 reuses `chooseFolder` helper at line 658.                                                      |
| FOLDER-02   | 18-06 (via Phase 16)      | Clean markdown, no YAML frontmatter                                      | ✗ BLOCKED   | DictationLogger.swift:60 header only, no `---` (no-YAML half holds). **But:** body is empty — coordinator never calls append. See Gap #1. |
| FOLDER-03   | 18-06 (via Phase 16)      | Human-readable filenames, collisions avoided                             | ⚠️ FLAKY    | DictationLogger.swift:51-53 ms-suffix filename. Test passes in isolation; flakes 1/5 in parallel. See Gap #3.            |
| FOLDER-04   | 18-06, 18-07              | Output mode: clipboard / plainFolder / both                              | ⚠️ PARTIAL  | DictationCoordinator.swift:160-227 branching wires correctly; selection works. But .plainFolder and .both produce empty-body files (Gap #1). |
| FOLDER-05   | 18-07 (via Phase 16)      | Plain-folder path persists across restarts                               | ✓ SATISFIED | AppSettings.swift:61-63 didSet + init read-back at 127. AppSettingsDictationPersistenceTests 3/3 GREEN.                   |

**Coverage:** 13/16 requirements fully satisfied, 1 partial (FOLDER-04), 1 flake-affected (FOLDER-03), 1 blocked (FOLDER-02 body content). No orphaned requirements.

### Anti-Patterns Found

None in Phase 18 production source files. Source grep across `DictationCoordinator.swift`, `DictationWindowController.swift`, `GlobalHotkeyService.swift`, `DictationLogger.swift`, and `DictationHUD.swift` returned no `TODO`, `FIXME`, `XXX`, `HACK`, `PLACEHOLDER`, `placeholder`, `coming soon`, or `not yet implemented` matches.

`#if DEBUG` test-surface helpers in `DictationCoordinator.swift:440-450` are scoped correctly (only compiled in debug builds; not present in release).

### Locked Decisions Honored

| Decision   | Description                                                                                       | Honored?  | Evidence                                                                                                                                                                |
| ---------- | ------------------------------------------------------------------------------------------------- | --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| D-01/D-02  | HUD shows live partial + timer + Stop; "Copied to clipboard" pill on commit                       | ✓ Yes     | DictationHUD.swift body — three-block layout + .copied state arm.                                                                                                       |
| D-03       | Native macOS HUD aesthetic via NSVisualEffectView .hudWindow                                      | ✓ Yes     | DictationWindowController.swift:58 (`material = .hudWindow`).                                                                                                            |
| D-04       | Bottom-center positioning                                                                         | ✓ Yes     | DictationWindowController.positionAtBottomCenter (lines 107-126).                                                                                                       |
| D-05       | Toggle mode: second tap = stop & commit                                                           | ✓ Yes     | PSTranscribeApp.swift:55-60 (toggle case).                                                                                                                              |
| D-06       | Inline 30s cancel confirmation, 3s second-Esc window                                              | ✓ Yes     | DictationCoordinator.swift:292-314 + cancelRevertTask Task.sleep(for: .seconds(3)).                                                                                    |
| D-07       | Press-and-hold: <1s release = silent cancel; ≥1s = commit                                         | ✓ Yes     | DictationCoordinator.swift:321-329 (handleHoldRelease).                                                                                                                 |
| D-08       | Atomic cancel: discardSession deletes file, no clipboard, no library                              | ✓ Yes     | DictationCoordinator.swift:270-282 + DictationLogger.swift:116-124.                                                                                                     |
| D-09       | Every dictation gets a library entry                                                              | ✓ Yes     | DictationCoordinator.swift:238-251 unconditional.                                                                                                                        |
| D-10       | Auto-name from first ~5 words, 50-char truncate, ellipsis, fallback to timestamp                  | ✓ Yes     | DictationCoordinator.autoNameFromTranscript (lines 403-429). AutoNameTests 7/7 GREEN.                                                                                  |
| D-11       | LibraryEntryRow uses mic.fill for .dictation                                                      | ✓ Yes     | LibraryEntryRow.swift:160-164.                                                                                                                                          |
| D-12       | Library entry stores inlineTranscript when no file (clipboard-only or D-15 fallback)              | ✓ Yes     | Models.swift:96 + DictationCoordinator.swift:235 (`finalFileURL == nil ? assembled : nil`).                                                                              |
| D-13       | Eager pre-warm at app launch                                                                      | ✓ Yes     | PSTranscribeApp.swift:96-109. Background Task with 2s sleep before main actor invocation.                                                                                |
| D-14       | Mutual exclusion notice: 1.5s "Recording in progress" pill                                        | ✓ Yes     | DictationCoordinator.showBlockedNotice (lines 341-347).                                                                                                                  |
| D-15       | Plain-folder failure → silent fallback to clipboard; library entry still created; transcript NOT logged | ✓ Yes | DictationCoordinator.swift:163-168. Logger emits only `error.localizedDescription` (NEVER `assembled` / `transcript`). PlainFolderFallbackTests 2/2 GREEN.            |
| D-16       | Models loading state: HUD shows "Loading model…"                                                  | ✓ Yes     | DictationHUD.swift:58-59 + DictationCoordinator.swift:171.                                                                                                              |
| WARNING #11 | Pre-warm gated on hotkeyAssigned (privacy-conscious opt-out)                                     | ✓ Yes     | PSTranscribeApp.swift:101 `guard hotkeyForPrewarm.hotkeyAssigned else { return () }`.                                                                                   |
| Phase 17 D-06 | Settings section order: …Speech Model → Dictation                                                | ✓ Yes     | SettingsView.swift line 64 (Speech Model) → line 68 (Dictation), in that order.                                                                                          |

All locked decisions are structurally honored. The data-flow gap (Gap #1) is an **implementation completeness** issue — none of the locked decisions explicitly mandate per-utterance append plumbing because that was assumed inherited from Phase 16's logger API contract. The Phase 18 plans declare DictationLogger reuse but never explicitly call out wiring `append`.

### Cross-Phase Regression Check

| Phase    | Status                       | Evidence                                                                                                                                              |
| -------- | ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| Phase 16 | ✓ No regression              | DictationLogger isolated tests 9/9 GREEN. SessionCoordinator schema preserved + extended (additive Optional pattern as designed).                     |
| Phase 17 | ✓ No regression              | ModelUpdateService 25/25 GREEN. SessionCoordinator.modelUpdate slot preserved at line 27.                                                             |
| v1.0     | ✓ No regression (sampled)    | LibraryEntryRow icon switch additive (.dictation case added; .callCapture and .voiceMemo unchanged). LibraryEntry Codable backward-compatible (Optional inlineTranscript). |

### Human Verification Required

6 items deferred to human UAT — see frontmatter `human_verification` array. Most critical:

1. **Plain-folder file body content check** — confirms or refutes Gap #1. Configure plain-folder mode, run a session, open the file. Expected outcome based on code inspection: empty body (header only). If the file body contains the transcript, then I missed an append code path and Gap #1 should be retracted.
2. **End-to-end hotkey from a non-PS-Transcribe frontmost app** — WARNING #10 / Carbon callback dispatch path is not unit-testable. A wrong dispatch crashes AppKit instantly. Manual proof needed before declaring Phase 18 production-ready.
3. Pulsing menu-bar mic visual confirmation, multi-monitor HUD positioning, and clipboard-history exclusion against Maccy/Alfred (Phase 19 hardening territory but worth surfacing now).

### Gaps Summary

**Three gaps — one goal-blocking, two non-blocking:**

1. **GOAL-BLOCKING: Plain-folder file body is empty.** `DictationCoordinator` opens a logger session (header written), then closes it (file finalized) without ever calling `dictationLogger.append(text:timestamp:)`. The plain-folder output file therefore contains only `# Dictation -- yyyy-MM-dd HH:mm\\n\\n` and no transcript. The phase goal includes "optional plain-folder file output" and FOLDER-02 expects clean markdown content — both are not fully met. The fix is small: at the top of `endDictation` (before `endSession`), iterate `dictationStore.utterances` and call `await dictationLogger.append(text:, timestamp:)` for each. Tests need a body-content assertion to prevent regression.

2. **NON-BLOCKING: Documentation lag in REQUIREMENTS.md (DICT-10).** Code is correct (`panel.sharingType = .none` at `DictationWindowController.swift:47`), but REQUIREMENTS.md line 24 still shows `[ ]` and the traceability row at line 95 reads `Pending`. Trivial fix.

3. **NON-BLOCKING: Carry-over flake scope is broader than `deferred-items.md` documents.** Across 5 full-suite runs, three different tests intermittently failed — all sharing the same root cause (parallel tests touching global pasteboard / ms-clock state). `deferred-items.md` lists only `ClipboardRestoreTests.clipboardRestoresAfterDelay`, but `PlainFolderFallbackTests.plainFolderWriteFailureSilentlyFallsBackToClipboard` and `DictationLoggerTests.rapidSessionsNoCollision` exhibit the same pattern. All three pass cleanly in isolation. Phase 19 hardening territory.

**Recommendation:** Mark Phase 18 `gaps_found`. The DICT-* surface (clipboard + HUD + library + mutual exclusion + menu bar + hotkey) is substantively complete and goal-met. The FOLDER-* surface has a goal-blocking implementation gap (Gap #1) that should be closed before Phase 19. File a single follow-up plan that:

1. Wires `dictationLogger.append` from the coordinator (Gap #1)
2. Adds a body-content assertion to `DictationCommitFlowTests`
3. Flips REQUIREMENTS.md DICT-10 row (Gap #2)
4. Migrates the 3 flaky tests to `PasteboardTestLock` / suite serialization (Gap #3)

If the human verification of Gap #1 (test "Plain-folder dictation file body content") shows the file body actually contains the transcript, then I missed a code path during inspection and Gaps #1, plus the FOLDER-02 / FOLDER-04 partial / failed statuses, should be retracted. The phase would then pass with only the documentation lag and flake-scope items.

---

_Verified: 2026-04-28T22:15:00Z_
_Verifier: Claude (gsd-verifier, Opus 4.7 1M)_
_Method: Goal-backward verification against ROADMAP success criteria + 16 requirement IDs from REQUIREMENTS.md + 16 locked decisions in 18-CONTEXT.md_
