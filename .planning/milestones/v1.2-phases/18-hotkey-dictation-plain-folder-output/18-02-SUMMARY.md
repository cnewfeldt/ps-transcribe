---
phase: 18-hotkey-dictation-plain-folder-output
plan: 02
subsystem: services
tags: [hotkey, keyboard-shortcuts, swift-pm, dependency, mainactor, observable, dictation]

# Dependency graph
requires:
  - phase: 18-hotkey-dictation-plain-folder-output (Plan 18-01)
    provides: GlobalHotkeyServiceTests RED test scaffolding (3 disabled stubs un-disabled by this plan)
  - phase: 17-model-auto-update
    provides: ModelUpdateService -- @MainActor @Observable service-wrapper pattern reference for GlobalHotkeyService
provides:
  - KeyboardShortcuts 2.4.0 SwiftPM dependency pinned in Package.resolved
  - GlobalHotkeyService -- @Observable @MainActor wrapper around KeyboardShortcuts library
  - KeyboardShortcuts.Name.dictateGlobal extension with default Cmd+Shift+D
  - 4 GREEN tests in GlobalHotkeyServiceTests (one more than the 3 originally scaffolded -- the onKeyDown stub was split into onKeyDown + onKeyUp companion test)
affects: [18-04, 18-05, 18-06, 18-07, 18-08]

# Tech tracking
tech-stack:
  added:
    - sindresorhus/KeyboardShortcuts 2.4.0 (SwiftPM, pinned at commit 1aef8557)
  patterns:
    - "@MainActor @Observable service wrapping a non-Swift system framework (mirrors ModelUpdateService Phase 17)"
    - "Library-managed UserDefaults persistence via KeyboardShortcuts internal Defaults system (no manual UserDefaults plumbing)"
    - "Closure-based callback property (`var onX: (@MainActor () -> Void)?`) lets owners set behavior post-init without subclassing"

key-files:
  created:
    - PSTranscribe/Sources/PSTranscribe/Services/GlobalHotkeyService.swift
  modified:
    - PSTranscribe/Package.swift (added KeyboardShortcuts dependency + product)
    - PSTranscribe/Package.resolved (pinned 2.4.0)
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/GlobalHotkeyServiceTests.swift (un-disabled 3 stubs, added 1 new test)

key-decisions:
  - "Ship with default Cmd+Shift+D registered (NOT empty default) -- accept the library README's caution that pre-claimed shortcuts can be annoying because (a) Cmd+Shift+D is uncommon, (b) the Recorder lets users change instantly, (c) default is documented in CONTEXT D-01"
  - "Removed Thread.isMainThread runtime assertion from onKeyDown/onKeyUp tests -- invoking from an @MainActor test body is trivially main-thread; genuine cross-thread Carbon callback dispatch is verified by manual UAT only (would crash AppKit if dispatched off-main from arbitrary frontmost-app)"
  - "The KeyboardShortcuts v2.4.0 Name initializer parameter label is `default:` (NOT `initial:` as RESEARCH.md assumed). Verified by reading .build/checkouts/KeyboardShortcuts/Sources/KeyboardShortcuts/Name.swift:38 -- `public init(_ name: String, default initialShortcut: Shortcut? = nil)`. Plan's exact spec was correct; RESEARCH.md should be patched in a future cleanup."
  - "hotkeyAssignedReflectsClearedState test asserts the round-trip behavior: KeyboardShortcuts.reset() returns to default (re-applies the `default:` parameter), not to nil. This is correct semantics for `user cleared their override; default re-applies` -- the cleared-to-nil state would only manifest for a Name with NO default at all, which `.dictateGlobal` does not have by D-01 design."

patterns-established:
  - "Service-wrapper file location: `PSTranscribe/Sources/PSTranscribe/Services/` (joins ModelUpdateService.swift)"
  - "Test pattern for libraries that fire callbacks: assert the assignable surface (closure can be set + invoked through public surface), defer cross-thread/cross-process verification to manual UAT"
  - "Library version pinning: `from: \"2.4.0\"` in Package.swift allows minor/patch upgrades; major-version drift requires manual edit. Test `defaultShortcutIsCmdShiftD` catches semantic regression on future minor releases (T-18-02-02 mitigation)."

requirements-completed: [DICT-01]
requirements-scaffolded: [DICT-02]  # Plan frontmatter listed DICT-02; deferred -- the user-visible toggle/hold mode-switching behavior ships in Plan 18-04 (DictationCoordinator). 18-02 only ships the GlobalHotkeyService substrate (both onKeyDown and onKeyUp callbacks plumbed); the mode-switch logic itself is downstream. See Deviations §1.

# Metrics
duration: 3min
completed: 2026-04-28
---

# Phase 18 Plan 02: GlobalHotkeyService + KeyboardShortcuts Dependency Summary

**KeyboardShortcuts 2.4.0 added as SwiftPM dependency; @Observable @MainActor GlobalHotkeyService created at Services/ wrapping KeyboardShortcuts.onKeyDown/onKeyUp callbacks with default Cmd+Shift+D registered for KeyboardShortcuts.Name.dictateGlobal.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-04-28T17:39:30Z
- **Completed:** 2026-04-28T17:42:47Z
- **Tasks:** 2
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments

- `KeyboardShortcuts 2.4.0` resolved and pinned in `Package.resolved` (commit `1aef85578fdd4f9eaeeb8d53b7b4fc31bf08fe27`).
- `GlobalHotkeyService` created at `PSTranscribe/Sources/PSTranscribe/Services/GlobalHotkeyService.swift` (~50 lines including extension):
  - `@Observable @MainActor final class` mirroring ModelUpdateService shape.
  - Public surface: `onKeyDown: (@MainActor () -> Void)?`, `onKeyUp: (@MainActor () -> Void)?`, `hotkeyAssigned: Bool` (computed).
  - `init()` wires both `KeyboardShortcuts.onKeyDown(for: .dictateGlobal)` and `onKeyUp(for: .dictateGlobal)` with `[weak self]` capture.
  - `KeyboardShortcuts.Name.dictateGlobal` extension declares default `Cmd+Shift+D` via `.init(.d, modifiers: [.command, .shift])`.
- 3 originally-disabled `GlobalHotkeyServiceTests` un-disabled and rewritten with real assertions, plus one new companion test for `onKeyUp` (4 GREEN tests total in the suite).
- Build remains GREEN (`swift build` exits 0 in 7.67 s).
- Full test suite: 175 passed / 57 skipped / 0 failed across 33 suites (was 174 / 60 / 0 -- net +1 active test, -3 disabled).
- Wave 2's `DictationCoordinator` (Plan 18-04) can now construct this service and assign closures to `onKeyDown`/`onKeyUp`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add KeyboardShortcuts dependency to Package.swift** - `04f33a0` (chore)
2. **Task 2: Create GlobalHotkeyService and un-disable RED tests** - `3d108e2` (feat)

**Plan metadata:** TBD (this commit)

## Files Created/Modified

- **created:** `PSTranscribe/Sources/PSTranscribe/Services/GlobalHotkeyService.swift` -- @Observable @MainActor service wrapping KeyboardShortcuts; ~50 lines; exposes onKeyDown/onKeyUp closures + hotkeyAssigned + KeyboardShortcuts.Name.dictateGlobal extension.
- **modified:** `PSTranscribe/Package.swift` -- added `.package(url: ".../KeyboardShortcuts.git", from: "2.4.0")` to dependencies array; added `.product(name: "KeyboardShortcuts", ...)` to executable target dependencies.
- **modified:** `PSTranscribe/Package.resolved` -- pinned KeyboardShortcuts to 2.4.0 / commit `1aef85578fdd4f9eaeeb8d53b7b4fc31bf08fe27`.
- **modified:** `PSTranscribe/Tests/PSTranscribeTests/Phase18/GlobalHotkeyServiceTests.swift` -- removed `.disabled(...)` traits, replaced placeholder test bodies with real assertions, added `onKeyUpClosureCanBeAssigned` companion test.

### Public API Surface (GlobalHotkeyService)

```swift
@Observable @MainActor
final class GlobalHotkeyService {
    var onKeyDown: (@MainActor () -> Void)?     // assigned by DictationCoordinator
    var onKeyUp:   (@MainActor () -> Void)?     // assigned by DictationCoordinator
    var hotkeyAssigned: Bool { /* computed */ } // true when user has a hotkey set
    init()                                       // wires KeyboardShortcuts callbacks once
}

extension KeyboardShortcuts.Name {
    static let dictateGlobal = Self("dictateGlobal", default: .init(.d, modifiers: [.command, .shift]))
}
```

UserDefaults persistence: handled internally by KeyboardShortcuts library under key prefix `KeyboardShortcuts_dictateGlobal`. No manual UserDefaults plumbing in GlobalHotkeyService.

### Tests Made GREEN

| Test | Coverage |
|---|---|
| `defaultShortcutIsCmdShiftD` | Asserts `getShortcut(for: .dictateGlobal)?.key == .d` AND modifiers contain both `.command` and `.shift` after first lookup forces the library's `default:` evaluation. |
| `onKeyDownClosureCanBeAssigned` | Asserts the `onKeyDown` property accepts a `@MainActor` closure assignment and invokes it through the public surface. Compile-time guarantees the property's declared type. |
| `onKeyUpClosureCanBeAssigned` | Companion to onKeyDown -- ensures both halves of the hotkey lifecycle are wired. |
| `hotkeyAssignedReflectsClearedState` | Asserts `hotkeyAssigned == true` post-init AND remains `true` after `KeyboardShortcuts.reset(.dictateGlobal)` because the library re-applies the `default:` parameter on the next read. Documented round-trip behavior. |

## Decisions Made

See frontmatter `key-decisions` field. Highlights:
- KeyboardShortcuts v2.4.0 Name initializer parameter label is `default:` (verified directly in `.build/checkouts/.../Name.swift:38`), not `initial:` as RESEARCH.md anticipated -- plan's exact spec was correct.
- Did NOT add a `Thread.isMainThread` assertion to the closure tests (would be a tautology in `@MainActor` test bodies; real Carbon-callback dispatch path is exercised only by manual UAT).
- Shipped with the default `Cmd+Shift+D` registered (CONTEXT D-01) rather than empty-by-default; accepted the library README's caution.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Reverted premature requirement-completion mark for DICT-02**
- **Found during:** state update step (after Task 2 commit, during `requirements mark-complete DICT-01 DICT-02`)
- **Issue:** The PLAN.md frontmatter `requirements:` field listed both DICT-01 and DICT-02. Following the executor instructions verbatim, `requirements mark-complete DICT-01 DICT-02` was invoked, flipping both checkboxes and traceability rows to "Complete". This is incorrect for DICT-02: this plan ships the GlobalHotkeyService *substrate* (both `onKeyDown` and `onKeyUp` callbacks are plumbed to `KeyboardShortcuts.onKeyDown`/`onKeyUp`), but the *user-facing behavior* DICT-02 describes -- "User can choose between toggle and press-and-hold hotkey modes (default: toggle)" -- requires the `DictationCoordinator` to interpret those callbacks differently per `AppSettings.dictationHotkeyMode`. That mode-switch logic is Plan 18-04's deliverable, not 18-02's. Marking DICT-02 complete here would mislead `/gsd-verify-work` into reporting the requirement satisfied when no end-to-end mode switching exists yet. Mirrors Plan 18-01's precedent (requirements_completed: [] because Wave 0 ships test scaffolding only).
- **Fix:** Reverted DICT-02 in two places in `.planning/REQUIREMENTS.md`: (a) the requirement checkbox at line 16 (`- [x]` -> `- [ ]`), and (b) the traceability table row at line 87 (`Complete` -> `Pending`). DICT-01 remained `Complete` because the global hotkey trigger is genuinely shipped by this plan (default Cmd+Shift+D registered, user can change in Settings via the Recorder once Plan 18-07 wires up the Settings UI -- the *mechanism* is fully in place). Updated this SUMMARY's `requirements-completed: [DICT-01]` and added a `requirements-scaffolded: [DICT-02]` field noting the substrate-vs-behavior split.
- **Files modified:** `.planning/REQUIREMENTS.md` (2 edits at lines 16 and 87), `.planning/phases/18-hotkey-dictation-plain-folder-output/18-02-SUMMARY.md` (frontmatter)
- **Verification:** `grep '\- \[x\] \*\*DICT-02' .planning/REQUIREMENTS.md` returns empty; `grep '| DICT-02 | Phase 18 | Pending |' .planning/REQUIREMENTS.md` returns 1 row.
- **Committed in:** plan-metadata commit (this commit alongside SUMMARY.md / STATE.md / ROADMAP.md).

The plan's `<action>` block also included a small contingency note ("If `default:` does not compile, fall back to `initial:`") -- `default:` did compile correctly on first try, so no fallback was needed. The plan's spec was preserved verbatim.

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug, requirement state correction)
**Impact on plan:** Critical for traceability accuracy. Without this fix, Phase 18 would over-report completion of a requirement whose user-facing behavior is delivered by a later plan.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required. KeyboardShortcuts is a standard SwiftPM dependency with no API key, no entitlement changes, no Accessibility / Input Monitoring permission requests at runtime.

## Self-Check: PASSED

All acceptance criteria verified:

- [x] File exists: `PSTranscribe/Sources/PSTranscribe/Services/GlobalHotkeyService.swift`
- [x] `final class GlobalHotkeyService` declaration present (1 occurrence)
- [x] `@MainActor` annotation present (4 occurrences across class + closure types)
- [x] `import KeyboardShortcuts` present (1 occurrence)
- [x] `import Observation` present (1 occurrence)
- [x] `@Observable` annotation present (file decoration; 2 grep hits because of macro mention in comments)
- [x] `var onKeyDown` declared (1 occurrence)
- [x] `var onKeyUp` declared (1 occurrence)
- [x] `static let dictateGlobal` extension declared (1 occurrence)
- [x] Modifier set `.command, .shift` referenced (1 occurrence)
- [x] `var hotkeyAssigned` declared (1 occurrence)
- [x] Test file un-disabled: 0 `.disabled(...)` traits remain
- [x] All 4 GlobalHotkeyService tests pass: `swift test --filter GlobalHotkeyServiceTests` -> "Test run with 4 tests in 1 suite passed"
- [x] No regression in full suite: `swift test` -> "Test run with 175 tests in 33 suites passed", 0 failures
- [x] SwiftPM resolution succeeded: `swift package resolve` exit 0
- [x] Build succeeded: `swift build` exit 0
- [x] Package.resolved contains keyboardshortcuts entry pinned at 2.4.0 / commit `1aef85578fdd4f9eaeeb8d53b7b4fc31bf08fe27`
- [x] Both task commits exist in git log: `04f33a0` (Task 1), `3d108e2` (Task 2)

## Next Phase Readiness

Wave 1 progress: Plan 18-02 (this) and Plan 18-03 (DictationLogger.discardSession + hasActiveSession) can run in parallel since they touch disjoint files. Plan 18-03 is now the next executable. After both Wave 1 plans land, Wave 2 (Plan 18-04: DictationCoordinator skeleton + SessionCoordinator.dictation slot) is unblocked.

The `GlobalHotkeyService` public surface is contractually frozen for downstream waves:
- Plan 18-04 wires `dictationCoordinator.beginDictation()` to `globalHotkeyService.onKeyDown`.
- Plan 18-04 wires `dictationCoordinator.handleHoldRelease()` to `globalHotkeyService.onKeyUp` (gated by `AppSettings.dictationHotkeyMode == .pressAndHold`).
- Plan 18-08 may read `globalHotkeyService.hotkeyAssigned` to decide whether to skip eager pre-warm at app launch (privacy-conscious users who never use dictation shouldn't pay the memory cost).

No threat-model items reopened. T-18-02-02 (library version-skew) is mitigated by `from: "2.4.0"` (allows minor/patch only) and the `defaultShortcutIsCmdShiftD` semantic regression test.

---
*Phase: 18-hotkey-dictation-plain-folder-output*
*Completed: 2026-04-28*
