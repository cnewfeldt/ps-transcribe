---
phase: 23-visual-regression-infra
plan: 01
subsystem: testing
tags: [swift, swiftpm, swift-testing, snapshot-testing, macos, test-scaffolding]

# Dependency graph
requires:
  - phase: 22-(none-direct)
    provides: existing PSTranscribeTests Swift Testing target + macos-26 build-check workflow
provides:
  - swift-snapshot-testing 1.19.2 SwiftPM dep on PSTranscribeTests test target
  - SnapshotFixtures.swift helper enum (withAppearance helper + 5 canonical frame size constants)
  - VisualRegressionTests.swift @Suite skeleton with 5 stub @Test methods (final class, .serialized, .snapshots(record: .missing))
  - Empty __Snapshots__/ directory committed via .gitkeep at swift-snapshot-testing default sibling-of-tests location
affects: [23-03, 23-04, 23-05]

# Tech tracking
tech-stack:
  added: [pointfreeco/swift-snapshot-testing@1.19.2]
  patterns:
    - "Test-target-only SwiftPM dep wiring via explicit .product(name:package:) form"
    - "@Suite final class + per-method @MainActor for tests that need lifecycle scoping (deviates from existing struct-based suites; see Deviations)"
    - "Stub @Test bodies that record Issue.record placeholders so Wave 0 ships a visibly-red suite forcing Plan 03 to actually replace each body"

key-files:
  created:
    - PSTranscribe/Tests/PSTranscribeTests/SnapshotFixtures.swift
    - PSTranscribe/Tests/PSTranscribeTests/VisualRegressionTests.swift
    - PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/.gitkeep
  modified:
    - PSTranscribe/Package.swift
    - PSTranscribe/Package.resolved

key-decisions:
  - "Pin swift-snapshot-testing at from: 1.19.2 (CONTEXT D-01 wording v2.x reconciled against actual upstream releases; no v2 line exists)"
  - "Test target uses explicit .product(name:package:) dependency form to match executable target style and surface SnapshotTesting product"
  - "VisualRegressionTests is @Suite final class (not struct) per RESEARCH/PATTERNS, but with NO stored properties or init/deinit -- the per-test defer documented in Plan 03 is the primary NSApp.appearance restore (Pitfall #2). Class-vs-struct distinction preserved per must_haves."
  - "@MainActor moved from class declaration to per-@Test method declaration to match existing AppSettingsTests / SessionCoordinatorTests pattern and avoid Swift 6.3 @const compile error"
  - "5 stub @Test methods (one per surface) all record Issue.record so the suite is visibly red until Plan 03 fills in real assertSnapshot calls"

patterns-established:
  - "Wave 0 stub-fail discipline: skeleton tests record Issue.record so they fail loudly until the real implementation lands. Forces Plan 03 to replace each body, prevents green-but-empty suites."
  - "Test target external dep wiring: append .package() to dependencies array, expand .testTarget shorthand to explicit list including .product(name:package:)"
  - "Snapshot fixture file layout: file-level @MainActor enum (no @Suite), mirrors MockURLProtocol.swift shape, hosts withAppearance(_:body:) helper + per-surface canonical frame size constants"

requirements-completed: [VISREG-01, VISREG-02, VISREG-03, VISREG-04]
# Note: this is the partial-Wave-0 framework only. Plans 23-03 and 23-04 fully satisfy
# VISREG-02..04 (5 surfaces x 3 appearances = 15 baseline assertions) and add the CI
# gate. Plan 01 stands up the dependency, fixture file, suite skeleton, and snapshots
# directory so Wave 1 plans can run in parallel against a stable surface.

# Metrics
duration: ~10min
completed: 2026-05-02
---

# Phase 23 Plan 01: Visual Regression Infra Wave 0 Scaffolding Summary

**swift-snapshot-testing 1.19.2 wired into the test target, empty VisualRegression @Suite skeleton with 5 Issue-recording stubs discoverable via `swift test list`, SnapshotFixtures helper file with appearance + frame helpers, __Snapshots__/.gitkeep committed.**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-05-02T17:03:53-07:00 (first task commit)
- **Completed:** 2026-05-02T17:08:19-07:00 (last task commit)
- **Tasks:** 3
- **Files modified:** 5 (2 modified, 3 created)

## Accomplishments

- swift-snapshot-testing 1.19.2 resolved via SwiftPM and wired into PSTranscribeTests test target ONLY (executable target untouched -- production binary surface unchanged)
- VisualRegression @Suite skeleton committed with 5 stub @Test methods, all discoverable via `swift test list`
- SnapshotFixtures.swift fixture file with `withAppearance(_:body:)` helper for D-05 NSApp.appearance pinning + 5 canonical per-surface frame size constants (CGSize per CONTEXT D-04 ranges)
- __Snapshots__/ directory committed via empty .gitkeep at the swift-snapshot-testing default sibling-of-tests location
- `swift build` and `swift build --target PSTranscribeTests` both green

## Task Commits

Each task was committed atomically:

1. **Task 1: Add swift-snapshot-testing 1.19.2 to Package.swift** -- `48086ad` (feat)
2. **Task 2: Create __Snapshots__ directory placeholder + SnapshotFixtures.swift skeleton** -- `e80c207` (feat)
3. **Task 3: Create VisualRegressionTests.swift suite skeleton with 5 stub @Test methods** -- `66d62fe` (feat)

_(Note: a parallel-executor commit `59c5b22` for Plan 23-02 landed between Tasks 2 and 3 in `git log`. That commit is not part of this plan; my plan's three commits remain `48086ad`, `e80c207`, `66d62fe`.)_

## Files Created/Modified

- `PSTranscribe/Package.swift` -- Added `pointfreeco/swift-snapshot-testing` dep `from: "1.19.2"`; expanded `.testTarget` deps to explicit list including `.product(name: "SnapshotTesting", package: "swift-snapshot-testing")`. Executable target untouched.
- `PSTranscribe/Package.resolved` -- Auto-updated by `swift package resolve` to record swift-snapshot-testing 1.19.2 + transitive deps (swift-custom-dump, xctest-dynamic-overlay, swift-syntax).
- `PSTranscribe/Tests/PSTranscribeTests/SnapshotFixtures.swift` -- New file. `@MainActor enum SnapshotFixtures` with `withAppearance(_:body:)` capture-and-restore helper + 5 canonical per-surface frame size constants (`contentViewFrame`, `librarySidebarFrame`, `settingsViewFrame`, `controlBarFrame`, `dictationHUDFrame`). Plan 03 will fill in the stub-state factory section that's currently a documented placeholder.
- `PSTranscribe/Tests/PSTranscribeTests/VisualRegressionTests.swift` -- New file. `@Suite("VisualRegression", .serialized, .snapshots(record: .missing))` on `final class VisualRegressionTests`. 5 stub `@Test @MainActor func` methods each recording `Issue.record("Pending Plan 23-03: ... not yet implemented")`. Plan 03 will replace each body with real `assertSnapshot` calls and expand from 5 stubs into 15 (5 surfaces x 3 appearances).
- `PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/.gitkeep` -- New empty file. Commits the `__Snapshots__/` directory so it exists in git from Wave 0; swift-snapshot-testing's first record run writes baselines into the same directory.

## Decisions Made

- **D-01 reconciliation:** CONTEXT.md says `v2.x` of swift-snapshot-testing but no v2 line exists upstream. Pinned `from: "1.19.2"` (latest stable, 2026-03-30) per RESEARCH guidance. All other D-01 substance preserved (test-target only, Swift Testing trait API, ADR forthcoming in Plan 23-02).
- **`final class` vs `struct` for VisualRegressionTests:** Plan / PATTERNS specified `final class` to support init/deinit lifecycle for NSApp.appearance restore. Preserved the class form per must_haves; dropped the init/deinit + stored property because Swift 6.3 @const enforcement on swift-testing's macro output rejected it. Per RESEARCH Pitfall #2 the per-test `defer` is the documented primary restore primitive -- the class lifecycle was always belt-and-suspenders only.
- **`@MainActor` placement:** Plan specified at class level. Moved to per-@Test method to match the existing convention in `AppSettingsTests` / `SessionCoordinatorTests` and to avoid the Swift 6.3 macro compile error.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Removed init/deinit + stored-property NSApp.appearance capture from VisualRegressionTests; moved @MainActor from class to per-@Test method**

- **Found during:** Task 3 (VisualRegressionTests.swift skeleton creation)
- **Issue:** The plan and PATTERNS prescribed `@MainActor @Suite(...) final class VisualRegressionTests` with a `private let originalAppearance: NSAppearance?` stored property and an `init() { ... }` / `deinit { NSApp.appearance = originalAppearance }` lifecycle pair as a belt-and-suspenders restore. Compiling against Swift 6.3 + swift-testing produced multiple errors:
  - `error: '@const' value should be initialized with a compile-time value` on the `private nonisolated static let $s..._testContentRecord...: Testing.__TestContentRecord = (...)` properties that the `@Test` and `@Suite` macros expand into.
  - `error: global variable must be a compile-time constant to use @section attribute` on the same generated metadata.
  - `error: cannot access property 'originalAppearance' with a non-Sendable type 'NSAppearance?' from nonisolated deinit`.
  Root cause: Swift 6.3's `@const` / `@section` enforcement on swift-testing's macro-generated `__TestContentRecord` static metadata is not satisfied when the host class has stored properties + an init that interacts with actor-isolated state, nor when class-level `@MainActor` propagates to the static metadata's initializer.
- **Fix:** Two changes, surgical:
  1. Removed `private let originalAppearance: NSAppearance?`, the `init()`, and the `deinit`. The class is now a pure `@Suite` skeleton with no stored state.
  2. Removed `@MainActor` from the class declaration. Each `@Test` method is annotated `@Test @MainActor func` -- this matches the existing convention in `AppSettingsTests` (line 28: `@Test @MainActor func`) and `SessionCoordinatorTests` (line 17+: `@Test @MainActor func`).
  Per RESEARCH Pitfall #2, the per-test `defer { NSApp.appearance = prior }` inside each System @Test body is the documented primary restore primitive. Plan 23-03 will add the per-test `defer` pair when filling in the System variants -- so the safety net is preserved at the documented-correct location, not at the suite level.
- **Files modified:** `PSTranscribe/Tests/PSTranscribeTests/VisualRegressionTests.swift`
- **Verification:**
  - `swift build --target PSTranscribeTests` -- "Build of target: 'PSTranscribeTests' complete!"
  - `swift test list | grep VisualRegression` -- enumerates all 5 stub methods
  - `final class VisualRegressionTests` preserved per must_haves (Task 3 acceptance criterion `grep -c 'final class VisualRegressionTests'` returns 1)
- **Committed in:** `66d62fe` (Task 3 commit; deviation note recorded in commit message body)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** No scope creep. Class-vs-struct invariant preserved. Lifecycle restore re-located from suite-level (belt-and-suspenders, per Pitfall #2 documented as not the primary primitive anyway) to per-test-defer (the documented primary primitive). Plan 23-03's pre-existing instructions to add per-test `defer` pairs in System variants now ALSO carry the suite-level safety net, so functional coverage is unchanged.

## Issues Encountered

- The pre-commit hook (or some local automation) included `.planning/phases/23-visual-regression-infra/23-ADR-snapshot-framework.md` in Task 1's commit (`48086ad`) even though only `PSTranscribe/Package.swift` and `PSTranscribe/Package.resolved` were `git add`-ed by name. The ADR file was a pre-existing untracked artifact from Plan 23-02 (parallel executor). The Plan 23-02 SUMMARY commit (`59c5b22`, parallel) explicitly notes this race: "Note: the ADR file itself was swept into commit 48086ad (feat(23-01)) by a concurrent executor race; this commit is the SUMMARY and plan-completion record for 23-02." No corrective action taken in Plan 01: reverting the inadvertent inclusion would create a destructive ripple in the parallel Plan 02 executor's expected state. Documented for orchestrator awareness.
- Working tree was at the correct base (`25aab21`) on entry per the worktree branch check; no reset was needed beyond the initial guard.

## User Setup Required

None -- no external service configuration required. swift-snapshot-testing is a SwiftPM-resolved test-target dep; first build resolves and caches it transparently.

## Next Phase Readiness

**Wave 1 plans (23-03 fixtures + assertions, 23-04 CI gate) can proceed in parallel against this scaffolding:**

- `Package.swift` already wires `SnapshotTesting` into the test target. Plan 23-03 needs no Package.swift edit; can `import SnapshotTesting` directly.
- `SnapshotFixtures.swift` already declares the `@MainActor enum SnapshotFixtures` shell, the `withAppearance(_:body:)` helper, and the 5 frame size constants. Plan 23-03 fills in the stub-state factory section (placeholder comment block).
- `VisualRegressionTests.swift` already declares the `@Suite("VisualRegression", .serialized, .snapshots(record: .missing))` and 5 stub `@Test` method names. Plan 23-03 replaces stub bodies with real `assertSnapshot` calls and expands from 5 to 15 methods (Light + Dark + System per surface).
- `__Snapshots__/.gitkeep` is in place so swift-snapshot-testing's first record run has a writable target directory.
- `swift test list` confirms the suite is discoverable from Wave 0; CI added in Plan 23-04 will surface the stub-fail until Plan 23-03 lands.

**Open items / concerns:**

- Plan 23-03 must add the per-test `defer { NSApp.appearance = prior }` pair inside each System @Test body. This is now the SOLE restore primitive (suite-level lifecycle was deviation-removed). Plan 23-03's existing instructions per RESEARCH Pitfall #2 already prescribe exactly this pattern, so no plan amendment needed.
- Plan 23-03 should re-verify the canonical frame sizes in `SnapshotFixtures.swift` against the actual rendered output. The values currently match CONTEXT D-04 suggested ranges + `WindowGroup.defaultSize(width: 1280, height: 820)`, but were not visually verified at Wave 0.

## Self-Check

Verifying claims before declaring complete.

### Files Created

- FOUND: PSTranscribe/Tests/PSTranscribeTests/SnapshotFixtures.swift
- FOUND: PSTranscribe/Tests/PSTranscribeTests/VisualRegressionTests.swift
- FOUND: PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/.gitkeep

### Files Modified

- FOUND: PSTranscribe/Package.swift (contains pointfreeco/swift-snapshot-testing 1.19.2)
- FOUND: PSTranscribe/Package.resolved (contains swift-snapshot-testing entry)

### Commits

- FOUND: 48086ad -- feat(23-01): add swift-snapshot-testing 1.19.2 to test target (Task 1)
- FOUND: e80c207 -- feat(23-01): scaffold SnapshotFixtures helper and __Snapshots__ dir (Task 2)
- FOUND: 66d62fe -- feat(23-01): scaffold VisualRegression suite skeleton with 5 stub tests (Task 3)

### Verification Commands

- `cd PSTranscribe && swift build` -- Build complete!
- `cd PSTranscribe && swift build --target PSTranscribeTests` -- Build of target: 'PSTranscribeTests' complete!
- `cd PSTranscribe && swift test list | grep VisualRegression` -- enumerates all 5 stub methods (`contentViewLight`, `controlBarLight`, `dictationHUDLight`, `librarySidebarLight`, `settingsViewLight`)

## Self-Check: PASSED

---

*Phase: 23-visual-regression-infra*
*Completed: 2026-05-02*
