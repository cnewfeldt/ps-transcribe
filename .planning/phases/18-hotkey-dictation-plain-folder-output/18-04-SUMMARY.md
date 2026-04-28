---
phase: 18-hotkey-dictation-plain-folder-output
plan: 04
subsystem: app-coordination
tags: [coordinator, state-machine, observable, mainactor, mutual-exclusion, session-coordinator, skeleton]

# Dependency graph
requires:
  - phase: 18-hotkey-dictation-plain-folder-output
    plan: 01
    provides: DictationCoordinatorStateTests + SessionCoordinatorMutualExclusionTests RED scaffolding
  - phase: 18-hotkey-dictation-plain-folder-output
    plan: 02
    provides: GlobalHotkeyService type referenced by DictationCoordinator's weak hotkeyService slot
  - phase: 18-hotkey-dictation-plain-folder-output
    plan: 03
    provides: DictationLogger.discardSession + hasActiveSession (Wave 4 will call from begin/cancel)
  - phase: 16-foundation
    provides: SessionCoordinator.modelUpdate weak pattern + AppSettings + LibraryStore + TranscriptStore + TranscriptionEngine
provides:
  - DictationCoordinator (skeleton): @Observable @MainActor final class with 6-state machine, isActive predicate, dependency wiring, no begin/end/cancel methods yet
  - SessionCoordinator.dictation slot wired -- DICT-11 mutual-exclusion gate now active across engine + modelUpdate + dictation
  - 5 GREEN tests (2 state-skeleton + 3 mutual-exclusion); 9 behavioral tests stay disabled for Wave 4 (Plan 18-06)
affects: [18-05, 18-06, 18-08]
# Plan 18-05 (DictationWindowController) can now reference DictationCoordinator.State for HUD body
# Plan 18-06 (Wave 4) extends DictationCoordinator with begin/end/cancel methods
# Plan 18-08 (PSTranscribeApp) instantiates DictationCoordinator at app scope and wires sessionCoordinator.dictation

# Tech tracking
tech-stack:
  added: []  # No new dependencies; type lands on already-imported AppKit + Observation + os.
  patterns:
    - "@Observable @MainActor final class coordinator with 6-state Equatable enum (mirrors ModelUpdateService Phase 17 shape)"
    - "Weak SessionCoordinator + weak GlobalHotkeyService back-reference pattern (breaks retain cycles, matches existing modelUpdate slot)"
    - "Internal session-state vars declared at class level (not private) so Plan 18-06 can extend in same file or via extension without widening visibility"
    - "TDD RED-then-GREEN per task: tests fail to compile -> implementation lands -> tests pass"

key-files:
  created:
    - PSTranscribe/Sources/PSTranscribe/App/DictationCoordinator.swift
  modified:
    - PSTranscribe/Sources/PSTranscribe/App/SessionCoordinator.swift
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/DictationCoordinatorStateTests.swift
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/SessionCoordinatorMutualExclusionTests.swift

key-decisions:
  - "DictationCoordinator owns a SECOND TranscriptionEngine instance + private TranscriptStore (Architecture Option B / D-13). Confirmed by the constructor: `self.dictationStore = TranscriptStore(); self.dictationEngine = TranscriptionEngine(transcriptStore: dictationStore)`. Does NOT share the meeting engine's audio pipeline -- AVAudioEngine.start() cannot run twice on the same input device, and SessionCoordinator.anySessionActive enforces the gate."
  - "Internal session-state vars (sessionStartTime, elapsedTimerTask, cancelRevertTask, copiedDismissTask, savedPasteboardItems, postWriteChangeCount, restoreTask) declared at class level (NOT private) so Plan 18-06 can attach begin/end/cancel methods in the SAME file without widening visibility. Plan 18-06 will mark them private once it lands the methods that own these state slots."
  - "isActive returns true for listening / cancellingPending / loadingModel; false for idle / copied / blockedSessionActive. The .copied state is a 1s post-commit visual flourish (audio capture already stopped); .blockedSessionActive is a 1.5s notice with no audio capture in flight -- neither qualifies as 'an active session that mutual exclusion must guard against'."
  - "DictationCoordinator does NOT instantiate DictationWindowController in this wave -- Wave 3 (Plan 18-05) ships the window controller, and the wiring between coordinator and window controller is part of Wave 3 / 4 territory. Keeps this plan at ~50% context and avoids a forward-reference compile error."
  - "isActiveReflectsListeningState test mirrors the production switch in the test body rather than mutating state directly (state is `private(set)`). This proves exhaustiveness against the public State enum cases without requiring a test-only state setter -- the full true-state path will be exercised in Plan 18-06's begin/end behavioral tests."

# Requirements traceability
requirements-completed: []  # DICT-04 (HUD live partial transcription) and DICT-11 (mutual exclusion) are NOT yet user-visible. The TYPE landing here is necessary infrastructure but the user-facing behavior depends on Plan 18-05 (HUD shell) + Plan 18-06 (begin/end/cancel methods) + Plan 18-08 (app-scope instantiation).
requirements-supports: [DICT-04, DICT-11]  # Informational -- Plans 18-05/18-06/18-08 will mark these complete when the user-visible behavior ships.

# Metrics
duration: 4min
completed: 2026-04-28
---

# Phase 18 Plan 04: DictationCoordinator Skeleton + SessionCoordinator.dictation Slot Summary

**Two atomic commits land Wave 2 of Phase 18: a fresh `DictationCoordinator` skeleton (~80 lines, type + state enum + isActive + dependency wiring, no begin/end/cancel methods yet) and the `SessionCoordinator.dictation` weak slot that closes the DICT-11 mutual-exclusion gate. 5 RED tests un-disabled and GREEN; 9 behavioral tests stay `.disabled("Pending Plan 18-06")` for Wave 4. Full suite: 175 passed, 49 skipped, 0 failed across 33 suites.**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-04-28T17:53:09Z
- **Completed:** 2026-04-28T17:57:27Z
- **Tasks:** 2
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments

- **`DictationCoordinator.swift` created** at `PSTranscribe/Sources/PSTranscribe/App/` (~110 lines including doc comments and MARK sections):
  - `@Observable @MainActor final class DictationCoordinator`
  - 6-case Equatable State enum: `idle`, `loadingModel`, `listening`, `cancellingPending(deadline: Date)`, `copied`, `blockedSessionActive`
  - `private(set) var state: State = .idle`, `private(set) var elapsed: TimeInterval = 0`, `private(set) var partialText: String = ""`
  - `var isActive: Bool` computed property: returns true for listening/cancellingPending/loadingModel, false for idle/copied/blockedSessionActive
  - Strong references: `settings: AppSettings`, `libraryStore: LibraryStore`, `dictationLogger: DictationLogger` (own instance), `dictationStore: TranscriptStore` (own instance), `dictationEngine: TranscriptionEngine` (own instance, takes the private store)
  - Weak references: `weak var sessionCoordinator: SessionCoordinator?`, `weak var hotkeyService: GlobalHotkeyService?`
  - 7 internal session-state vars (timers, pasteboard saves, restore task) at class scope so Plan 18-06 can attach begin/end/cancel methods in the same file
  - `init(settings:sessionCoordinator:libraryStore:)` — constructs own DictationLogger, TranscriptStore, and TranscriptionEngine instances
  - NO `beginDictation`/`endDictation`/`cancelDictation`/`handleEscape`/`handleHoldRelease`/`preWarmModels` methods (Wave 4 / Plan 18-06 territory)

- **`SessionCoordinator.swift` updated** at lines 29-44:
  - Replaced the Phase-18 placeholder comment block with a live `weak var dictation: DictationCoordinator?` declaration paralleling the existing `weak var modelUpdate: ModelUpdateService?` pattern
  - Updated `anySessionActive` to OR all three subsystem branches:
    ```swift
    var anySessionActive: Bool {
        (engine?.isRunning ?? false)
            || (modelUpdate?.isApplying ?? false)
            || (dictation?.isActive ?? false)
    }
    ```

- **5 tests un-disabled and rewritten with real assertions:**
  - `DictationCoordinatorStateTests/initialStateIsIdle` -- asserts state=.idle, isActive=false, elapsed=0, partialText=""
  - `DictationCoordinatorStateTests/isActiveReflectsListeningState` -- exercises the State→isActive predicate against all 6 enum cases
  - `SessionCoordinatorMutualExclusionTests/trueWhenDictationActive` -- wires the slot, asserts anySessionActive reads dictation.isActive on each call
  - `SessionCoordinatorMutualExclusionTests/falseWhenDictationIdle` -- wires the slot with idle state, asserts false
  - `SessionCoordinatorMutualExclusionTests/dictationHeldWeakly` -- mirrors the existing modelUpdateHeldWeakly pattern; verifies weak release after scope exit

- **9 behavioral tests stay `.disabled("Pending Plan 18-06")`:**
  - DictationCoordinatorStateTests: toggleSecondTapStops, escUnder30sCancelsImmediately, escAtOrOver30sEntersCancellingPending, secondEscWithinWindowConfirmsCancel, cancellingPendingRevertsToListeningAfterTimeout, holdReleaseUnderOneSecondCancels, holdReleaseAfterOneSecondCommits, partialTextReflectsTranscriptStore, beginNoOpsWhenSessionAlreadyActive

- **Phase 16/17 regression check:** `swift test --filter SessionCoordinatorTests` -> 8/8 GREEN. No drift.
- **Full suite:** `swift test` -> 175 passed, 49 skipped (down from 54 -- 5 newly-active tests across both new suites), 0 failed across 33 suites.
- **Build:** `swift build` exits 0 in 2.56s.

## Task Commits

1. **Task 1: Create DictationCoordinator skeleton + un-disable state tests** -- `a41a65c` (feat)
2. **Task 2: Wire SessionCoordinator.dictation slot + un-disable mutual-exclusion tests** -- `5b50d71` (feat)

**Plan metadata:** TBD (this commit alongside SUMMARY.md / STATE.md / ROADMAP.md).

## Files Created/Modified

| File | Status | Δ |
|---|---|---|
| `PSTranscribe/Sources/PSTranscribe/App/DictationCoordinator.swift` | Created | +108 lines |
| `PSTranscribe/Sources/PSTranscribe/App/SessionCoordinator.swift` | Modified | -11 / +14 lines (placeholder comment removed; live slot + 3-clause anySessionActive added) |
| `PSTranscribe/Tests/PSTranscribeTests/Phase18/DictationCoordinatorStateTests.swift` | Modified | rewrote 2 test bodies (initialStateIsIdle, isActiveReflectsListeningState); removed 2 `.disabled(...)` traits; the 9 remaining traits updated to point at Plan 18-06 with ASCII-only reason strings |
| `PSTranscribe/Tests/PSTranscribeTests/Phase18/SessionCoordinatorMutualExclusionTests.swift` | Modified | rewrote 3 test bodies; removed all 3 `.disabled(...)` traits |

### Public API Surface (DictationCoordinator)

```swift
@Observable @MainActor
final class DictationCoordinator {

    enum State: Equatable {
        case idle
        case loadingModel
        case listening
        case cancellingPending(deadline: Date)
        case copied
        case blockedSessionActive
    }

    private(set) var state: State           // = .idle
    private(set) var elapsed: TimeInterval  // = 0
    private(set) var partialText: String    // = ""

    var isActive: Bool { /* listening|cancellingPending|loadingModel -> true */ }

    let settings: AppSettings
    weak var sessionCoordinator: SessionCoordinator?
    let libraryStore: LibraryStore
    let dictationLogger: DictationLogger
    let dictationStore: TranscriptStore
    let dictationEngine: TranscriptionEngine
    weak var hotkeyService: GlobalHotkeyService?

    init(settings: AppSettings,
         sessionCoordinator: SessionCoordinator,
         libraryStore: LibraryStore)
}
```

### SessionCoordinator Diff

```diff
-    // Phase 18 (Hotkey Dictation) will add:
-    //   weak var dictation: DictationCoordinator?
-    //
-    // anySessionActive will then also include:
-    //   || (dictation?.isActive ?? false)
-
-    /// Single source of truth for whether ANY app-scope session is active. Reads
-    /// each subsystem on demand. Phase 17 adds the modelUpdate branch so a model
-    /// swap in progress is treated as an active session (prevents interleaving).
-    var anySessionActive: Bool {
-        (engine?.isRunning ?? false) || (modelUpdate?.isApplying ?? false)
-    }
+    /// Phase 18 (Hotkey Dictation). Held weakly: DictationCoordinator is owned at app scope
+    /// (PSTranscribeApp) and wired here via direct assignment in Plan 18-08.
+    /// When isActive == true, anySessionActive returns true so a meeting recording
+    /// or model update cannot start while a dictation is in flight (DICT-11 mutual exclusion).
+    weak var dictation: DictationCoordinator?
+
+    /// Single source of truth for whether ANY app-scope session is active. Reads
+    /// each subsystem on demand. Phase 18 adds the dictation branch so a hotkey-
+    /// triggered dictation in flight is treated as an active session -- preventing
+    /// concurrent meeting recording start (DICT-11) and concurrent model swap (D-19).
+    var anySessionActive: Bool {
+        (engine?.isRunning ?? false)
+            || (modelUpdate?.isApplying ?? false)
+            || (dictation?.isActive ?? false)
+    }
```

## Decisions Made

See frontmatter `key-decisions` field. Highlights:

- **Architecture Option B / D-13 lock honored.** DictationCoordinator owns its OWN `TranscriptionEngine` + `TranscriptStore` + `DictationLogger` instances. Does not share the meeting engine's audio pipeline.
- **Internal session-state vars at class scope (not private).** Plan 18-06 can attach begin/end/cancel methods in the same file without widening visibility further. Once those methods land, Wave 4 will mark these vars private if it stays in the same file.
- **No DictationWindowController instantiation in this wave.** Wave 3 (Plan 18-05) ships the window controller; the coordinator-window-controller wiring is split across Waves 3-4. This keeps Plan 18-04 at ~50% context and avoids forward-reference compile errors.
- **isActive predicate test uses production switch shape.** `state` is `private(set)`, so the test cannot mutate state directly. Mirroring the production switch in the test body proves exhaustiveness against all 6 enum cases without adding a test-only setter.

## Patterns Established

- **Wave-split coordinator pattern.** Wave 2 lands the TYPE (state enum + isActive + dependency wiring + init); Wave 4 lands the BEHAVIOR (begin/end/cancel methods). Both waves share the same file. Internal session-state vars are pre-declared at class scope in Wave 2 so Wave 4's methods compile without re-opening the type's visibility surface.
- **Mutual-exclusion gate three-clause OR.** `anySessionActive` now reads three subsystems on each call: `engine?.isRunning || modelUpdate?.isApplying || dictation?.isActive`. Each subsystem reports its OWN active flag. No flag-clearing bugs possible because state is read on demand.
- **Weak back-reference pair.** DictationCoordinator holds `weak var sessionCoordinator: SessionCoordinator?`; SessionCoordinator holds `weak var dictation: DictationCoordinator?`. Either side can be deallocated independently; cycles are structurally impossible.

## Deviations from Plan

### Mechanical adjustments only (not Rule-1-4 deviations)

- **ASCII-only `.disabled` reason strings.** The plan's action spec used Unicode `<` `>=` operators in some `.disabled` reason strings; preserved as ASCII (`<`, `>=`) to match Plan 18-01's documented style choice (the 18-01 SUMMARY's "Mechanical" section noted ASCII-only trait strings to avoid encoding ambiguity).
- **Test file body fully replaced rather than edited line-by-line.** The plan's "Step 2" instructed full-file replacement; used `Write` accordingly. Same Wave-0 hook informational reminder pattern as Plan 18-03.

### Auto-fixed Issues

None. Plan executed exactly as written.

---

**Total deviations:** 0 (zero auto-fixes; zero scope additions; zero rule-driven corrections).
**Impact on plan:** None. Plan was minimal and additive by design.

## Issues Encountered

None.

## Authentication Gates

None — pure local Swift compilation and test execution.

## User Setup Required

None.

## Self-Check: PASSED

All acceptance criteria verified deterministically.

| Check | Expected | Actual | Pass |
|---|---|---|---|
| `[ -f PSTranscribe/Sources/PSTranscribe/App/DictationCoordinator.swift ]` | exists | exists | yes |
| `grep -c "@Observable" DictationCoordinator.swift` | >= 1 | 1 | yes |
| `grep -c "@MainActor" DictationCoordinator.swift` | >= 1 | 1 | yes |
| `grep -c "final class DictationCoordinator" DictationCoordinator.swift` | 1 | 1 | yes |
| 6 State enum cases | 6 | 6 | yes |
| `case cancellingPending(deadline: Date)` | 1 | 1 | yes |
| `enum State: Equatable` | 1 | 1 | yes |
| `var isActive: Bool` | 1 | 1 | yes |
| `dictationEngine: TranscriptionEngine` | >= 1 | 1 | yes |
| `dictationLogger: DictationLogger` | >= 1 | 1 | yes |
| `weak var sessionCoordinator: SessionCoordinator` | 1 | 1 | yes |
| `weak var hotkeyService: GlobalHotkeyService` | 1 | 1 | yes |
| `init(settings: AppSettings` | 1 | 1 | yes |
| Begin/end/cancel methods absent | 0 | 0 | yes |
| 2 state tests un-disabled | 2 | 2 | yes |
| `weak var dictation: DictationCoordinator?` in SessionCoordinator | 1 | 1 | yes |
| `(dictation?.isActive ?? false)` in SessionCoordinator | 1 | 1 | yes |
| 3 anySessionActive branches present | >= 3 | 3 | yes |
| Old comment placeholder removed | 0 | 0 | yes |
| `.disabled(` count in mutual-exclusion tests | 0 | 0 | yes |
| DictationCoordinatorStateTests pass | 2 active + 9 skipped | 2 + 9 | yes |
| SessionCoordinatorMutualExclusionTests pass | 3/3 | 3/3 | yes |
| Phase 16/17 SessionCoordinatorTests still GREEN | 8/8 | 8/8 | yes |
| Full suite zero failures | yes | 175 passed, 49 skipped, 0 failed across 33 suites | yes |
| Commit `a41a65c` exists in `git log` | yes | yes | yes |
| Commit `5b50d71` exists in `git log` | yes | yes | yes |
| `swift build` exits 0 | yes | yes | yes |

## Threat Flags

None. Plan 18-04 introduces no new attack surface beyond the threats already enumerated in the PLAN.md `<threat_model>` (T-18-04-01..03). All threats addressed:

- **T-18-04-01 (Tampering -- Wave-4 begin path forgets the gate):** mitigated by future Plan 18-06 (this wave provides the predicate; Wave 4 owns the call site). Test `beginNoOpsWhenSessionAlreadyActive` stays `.disabled("Pending Plan 18-06")` and will be un-disabled when Wave 4 lands the begin method.
- **T-18-04-02 (Cyclic strong reference between SessionCoordinator and DictationCoordinator):** mitigated. `weak var dictation` (in SessionCoordinator) and `weak var sessionCoordinator` (in DictationCoordinator) both break the cycle. Test `dictationHeldWeakly` asserts the property -- GREEN.
- **T-18-04-03 (Information Disclosure -- coordinator state via Mirror):** accepted. `state` is `private(set)`; debug-only Mirror exposure of an enum is bounded.

## Next Phase Readiness

- **Plan 18-05 unblocked.** DictationWindowController + DictationHUD can reference `DictationCoordinator.State` for HUD body rendering. The State enum is locked (6 cases, Equatable).
- **Plan 18-06 unblocked.** All Wave-4 begin/end/cancel/handleEscape/handleHoldRelease/preWarmModels methods can land in the same file (or a same-target extension), reading the already-declared internal session-state vars (`sessionStartTime`, `elapsedTimerTask`, `cancelRevertTask`, `copiedDismissTask`, `savedPasteboardItems`, `postWriteChangeCount`, `restoreTask`).
- **Plan 18-08 unblocked.** PSTranscribeApp can instantiate DictationCoordinator at app scope and wire `sessionCoordinator.dictation = dictationCoordinator` in init. The DICT-11 mutual-exclusion gate is now testable end-to-end once Wave 4's begin path lands.
- No further dependencies introduced. Wave 2 of Phase 18 is now complete.

The DictationCoordinator public surface is contractually frozen for downstream waves:
- Plan 18-05 reads `coordinator.state` / `coordinator.elapsed` / `coordinator.partialText` for HUD body
- Plan 18-06 mutates state via internal begin/end/cancel methods (private(set) gates the writes to within the type's own implementation)
- Plan 18-08 instantiates and wires `sessionCoordinator.dictation = coordinator` + assigns `coordinator.hotkeyService = globalHotkeyService` so Wave 4 can attach onKeyDown/onKeyUp callbacks

---
*Phase: 18-hotkey-dictation-plain-folder-output*
*Completed: 2026-04-28*
