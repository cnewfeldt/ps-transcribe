---
phase: 17-model-auto-update
plan: 04
subsystem: ui
tags: [swift, swiftui, macos, settings, model-update, sparkle]

requires:
  - phase: 17-01
    provides: ModelUpdateService, ModelUpdateState enum, BlockedReason 3-arity enum, AppSettings keys
  - phase: 17-02
    provides: downloadAndApply(), cancelDownload(), download pipeline
  - phase: 17-03
    provides: applySwap(), rollback, SessionCoordinator.modelUpdate wiring, anySessionActive gate

provides:
  - ModelUpdateService instantiated at PSTranscribeApp scope (@State, constructed in init())
  - SessionCoordinator.modelUpdate = modelUpdateService wired in ContentView .task
  - modelUpdateService.bindTranscriptionEngine() + bindAnySessionActiveProvider() bind methods
  - 10s auto-check trigger in ContentView .task (respects throttle + toggle)
  - Settings > "Speech Model" section after "Updates" section (D-06 ordering)
  - All four UI states: idle/upToDate, updateAvailable, downloading/verifying/applying, blocked
  - Manual "Check for Updates" button always visible (D-12)
  - Auto-update toggle bound to AppSettings.modelAutoUpdateEnabled (D-11)
  - Opportunistic check on Settings open (D-10)

affects: [17-05-manifest-publish, 18-hotkey-dictation, 19-integration-hardening]

tech-stack:
  added: []
  patterns:
    - "Late-binding via public bind methods: transcriptionEngine and anySessionActiveProvider assigned in ContentView .task, not at init time"
    - "4-state ViewBuilder switch on ModelUpdateState enum drives all Speech Model UI"
    - "isWorkingState() helper disables manual button during checking/downloading/verifying/applying"
    - "readableDate() helper parses yyyyMMdd version string to human-readable Medium date"

key-files:
  created:
    - .planning/phases/17-model-auto-update/17-VERIFICATION.md
  modified:
    - PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift
    - PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift
    - PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift
    - PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift

key-decisions:
  - "bind methods (bindTranscriptionEngine, bindAnySessionActiveProvider) used for late-binding because private weak var transcriptionEngine cannot be assigned from outside the type"
  - "Form height bumped from 640 to 720 to accommodate new Speech Model section without cramping"
  - "Full smoke-test deferred to post-17-05: 404 on manifest fetch is the documented expected pre-publish state, not a bug"
  - "Task 3 (manual smoke test) approved by user with A-G deferred to post-17-05; H covered by 17-03 unit tests; I (no regressions) confirmed"

patterns-established:
  - "Phase 17 UI wiring pattern: instantiate service at App scope, pass to SettingsView and ContentView, late-bind engine in .task"
  - "UI state switch pattern: @ViewBuilder speechModelSectionContent with explicit case-per-state rendering"

requirements-completed: [MODEL-02, MODEL-04, MODEL-08, MODEL-09, MODEL-10]

duration: ~45min (continuation agent, 3 tasks)
completed: 2026-04-27
---

# Phase 17 Plan 04: UI Wiring -- Settings > Speech Model Section Summary

**ModelUpdateService wired to app scope + SettingsView Speech Model section with all four UI states; auto-check triggers at startup and Settings open; full smoke-test approved with A-G deferred to post-17-05 manifest publish**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-04-27 (prior agent session for Tasks 1-2; continuation for Task 3)
- **Completed:** 2026-04-27
- **Tasks:** 3 (2 auto + 1 checkpoint:human-verify)
- **Files modified:** 5 (4 source files + 1 planning file)

## Accomplishments

- ModelUpdateService instantiated at PSTranscribeApp `@State` scope and injected into both SettingsView and ContentView; SessionCoordinator.modelUpdate wired in ContentView's `.task` block
- Settings > "Speech Model" section added after "Updates" section (D-06 ordering) with all four UI states: idle/upToDate, updateAvailable, downloading/verifying/applying, and blocked (min_app_version + insufficientDiskSpace)
- Manual "Check for Updates" button always visible; auto-update toggle bound to AppSettings.modelAutoUpdateEnabled; opportunistic check fires on Settings open; 10s delayed auto-check fires at launch respecting throttle + toggle gates

## Task Commits

1. **Task 1: Instantiate ModelUpdateService at app scope; thread through ContentView; wire auto-check trigger** - `000384f` (feat)
2. **Task 2: SettingsView Section('Speech Model') with all four UI states + manual check button + auto-update toggle** - `e77c35a` (feat)
3. **Task 3: Manual smoke test -- Settings > Speech Model UX states** - `15f6571` (docs -- verification note)

## Files Created/Modified

- `PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift` -- Added `@State private var modelUpdateService: ModelUpdateService`; updated `init()` to construct service; injected into SettingsView and ContentView call sites
- `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift` -- Added `modelUpdateService` parameter; wired `sessionCoordinator.modelUpdate` + `bindTranscriptionEngine` + `bindAnySessionActiveProvider` in `.task`; added 10s auto-check trigger
- `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift` -- Added `bindTranscriptionEngine(_:)` and `bindAnySessionActiveProvider(_:)` public bind methods for late-binding
- `PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift` -- Added `@Bindable var modelUpdateService: ModelUpdateService`; added `Section("Speech Model")` with `speechModelSectionContent` ViewBuilder; all verbatim D-07/D-09/D-11/D-12/D-16 strings; bumped form height 640 -> 720
- `.planning/phases/17-model-auto-update/17-VERIFICATION.md` -- Smoke-test result: A-G deferred to post-17-05; H covered by 17-03 unit tests; I no regressions confirmed

## Decisions Made

- **bind methods for late-binding:** `transcriptionEngine` is `private weak var` and cannot be assigned externally. `bindTranscriptionEngine(_:)` and `bindAnySessionActiveProvider(_:)` added as public entry points called in ContentView's `.task` block.
- **Form height 640 -> 720:** Speech Model section requires ~80px additional vertical space to render without cramping the five existing sections.
- **Full smoke-test deferred to post-17-05:** The manifest URL returns 404 before Plan 17-05 publishes. This is documented expected behavior, not a bug. User approved with explicit acknowledgment.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added bindTranscriptionEngine() and bindAnySessionActiveProvider() bind methods to ModelUpdateService**
- **Found during:** Task 1 (app scope wiring)
- **Issue:** Plan instructed ContentView to call `modelUpdateService.bindTranscriptionEngine(transcriptionEngine)` but `transcriptionEngine` was declared `private weak var` in ModelUpdateService -- not assignable from outside the type
- **Fix:** Added two public bind methods to ModelUpdateService as the only valid external assignment path
- **Files modified:** `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift`
- **Verification:** Swift build exits 0; methods callable from ContentView's `.task`
- **Committed in:** `000384f` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 2 -- missing critical bind surface)
**Impact on plan:** Required for correct cross-type late-binding. No scope creep.

## Issues Encountered

- 404 on manifest fetch during smoke test: expected pre-17-05 state. Not a regression. User acknowledged and approved.

## User Setup Required

None -- no external service configuration required for Phase 17-04.

## Next Phase Readiness

- Phase 17 is functionally complete on the app side. ModelUpdateService pipeline (17-01 through 17-04) is fully wired.
- Plan 17-05 (manifest publication) remains. Once 17-05 publishes the live manifest to gh-pages, the full A-through-G smoke test should be run and 17-VERIFICATION.md updated.
- Phase 18 (Hotkey Dictation) is unblocked -- no dependencies on Phase 17's live manifest.

---
*Phase: 17-model-auto-update*
*Completed: 2026-04-27*
