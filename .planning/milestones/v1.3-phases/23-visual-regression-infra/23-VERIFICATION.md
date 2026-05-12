---
phase: 23-visual-regression-infra
verified: 2026-05-02T19:45:00Z
status: passed
score: 14/14 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: none
  previous_score: n/a
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 23: Visual Regression Infra Verification Report

**Phase Goal:** Stand up snapshot testing for primary surfaces (Light/Dark/System appearance) and wire it into CI so future appearance changes can't silently break the UI.
**Verified:** 2026-05-02T19:45:00Z
**Status:** passed
**Re-verification:** No -- initial verification

## Goal Achievement

### Roadmap Success Criteria (5)

| # | Roadmap Success Criterion | Status | Evidence |
|---|---------------------------|--------|----------|
| SC-1 | Snapshot test framework chosen with ADR documenting trade-offs | VERIFIED | `23-ADR-snapshot-framework.md` (81 lines, full Nygard structure: Status / Context / Decision / Alternatives Considered / Consequences). Names `pointfreeco/swift-snapshot-testing` 1.19.2 and rejects 3 alternatives (custom XCTest+CGImage hash, snapshotpreviews, XCUITest). |
| SC-2 | Snapshot baselines exist for ContentView, LibraryView, SettingsView, RecordingView, DictationHUD across Light + Dark + System | VERIFIED | 15 PNGs at `PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/` (5 surfaces x 3 appearances). Surface mapping reconciled per CONTEXT D-03: LibraryView -> LibrarySidebar, RecordingView -> ControlBar (documented in ADR). |
| SC-3 | Snapshot test target runs locally with one command and produces a clear pass/fail report | VERIFIED | `cd PSTranscribe && swift test --filter VisualRegression` -- ran during verification: 15/15 tests passed in 0.97s. Suite name `VisualRegression` is the explicit `--filter` target. |
| SC-4 | Snapshot tests run in CI as a pre-merge gate | VERIFIED | `.github/workflows/build-check.yml` line 44-46 adds `swift test` step after `swift build` on `macos-26`. Trigger is `pull_request: branches: [main]`. release-dmg.yml unchanged per CONTEXT canonical_refs. |
| SC-5 | Update workflow documented in CONTRIBUTING / `.planning/codebase/` | VERIFIED | `CONTRIBUTING.md` (66 lines, repo root) and `.planning/codebase/TESTING.md` (line 300+) both contain regen incantation `SNAPSHOT_TESTING_RECORD=all swift test --filter VisualRegression` and the `all | failed | missing | never` env-var contract. Cross-linked to ADR. |

**Roadmap SC score:** 5/5 verified

### Plan-level Observable Truths (9, deduplicated from PLAN frontmatter)

| # | Truth (from PLAN must_haves) | Status | Evidence |
|---|------------------------------|--------|----------|
| T-1 | swift-snapshot-testing 1.19.2 resolves and links into test target only, never executable target | VERIFIED | `Package.swift` line 12 declares `from: "1.19.2"`; line 29 wires `.product(name: "SnapshotTesting", package: "swift-snapshot-testing")` into `.testTarget` only. Executable target deps (lines 17-21) contain no SnapshotTesting reference. `Package.resolved` registers 1 entry for swift-snapshot-testing. |
| T-2 | SnapshotFixtures.swift has canonical-frame helper + withAppearance helper | VERIFIED | File exists; lines 22-27 define `withAppearance<R>(_ name: NSAppearance.Name?, body:)` with capture/restore via `defer`; lines 35-39 define 5 frame-size CGSize constants (contentView, librarySidebar, settingsView, controlBar, dictationHUD). |
| T-3 | __Snapshots__ directory committed at swift-snapshot-testing default sibling location | VERIFIED | `PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/` exists with 15 PNGs committed; sibling to the test source files as required by swift-snapshot-testing default path resolution. |
| T-4 | All 15 @Test methods cover 5 surfaces x 3 appearances | VERIFIED | `grep -nE '@Test '` on VisualRegressionTests.swift returns exactly 15 lines (lines 84, 109, 134, 166, 173, 180, 196, 219, 242, 268, 288, 308, 335, 346, 357). 5 surfaces x {Light, Dark, System} = 15. All compile and execute. |
| T-5 | First record produces exactly 15 baseline PNGs | VERIFIED | `find ...__Snapshots__ -name '*.png' \| wc -l` returns 15. Baselines named `<testFunc>.<Surface>-<Appearance>.png` per swift-snapshot-testing convention with `named:` parameter. Total weight 1232 KB (under 5 MB sanity bound). |
| T-6 | Strict precision (1.0 / 0.99) used; replay passes | VERIFIED | VisualRegressionTests.swift line 69-70: `precision: 1.0, perceptualPrecision: 0.99` in the snapshot helper. Replay run during verification: all 15 tests pass. No per-test loosening present (`grep -c 'precision: 1.0'` = 1 in the helper only). |
| T-7 | System tests pin NSApp.appearance via `.aqua` and restore via defer; Light/Dark use `.preferredColorScheme` | VERIFIED | 5 `withAppearance(.aqua)` calls (one per System @Test). 5 `.preferredColorScheme(.light)` + 5 `.preferredColorScheme(.dark)` modifiers. `withAppearance` helper (SnapshotFixtures.swift line 22-27) uses `defer { NSApp.appearance = prior }`. |
| T-8 | DictationHUD instantiated directly per Phase 18-05 contract; baselines at default location | VERIFIED | VisualRegressionTests.swift lines 335-367: 3 DictationHUD tests construct `DictationHUD(state: .listening, elapsed: 12.5, partialText: ..., onStop: {})` directly -- no DictationWindowController. Baselines at `__Snapshots__/VisualRegressionTests/dictationHUD*.png`. |
| T-9 | CI: PR builds run `swift test` after `swift build`; record-mode guard fails fast; on failure diff PNGs uploaded | VERIFIED | build-check.yml lines 30-35 (guard step), 37-39 (build), 44-46 (test), 54-61 (failure-only upload-artifact@v4). YAML validates via Python yaml.safe_load. release-dmg.yml unchanged. |

**Plan truth score:** 9/9 verified

**Combined score:** 14/14 must-haves verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `PSTranscribe/Package.swift` | swift-snapshot-testing 1.19.2 dep on test target | VERIFIED | Line 12 (dep), line 29 (test-target product wiring). Executable target untouched. |
| `PSTranscribe/Package.resolved` | swift-snapshot-testing entry | VERIFIED | grep -c returns 1. |
| `PSTranscribe/Tests/PSTranscribeTests/SnapshotFixtures.swift` | withAppearance helper + 5 frames + 7 stub-state factories | VERIFIED | 167 lines; all required symbols present (withAppearance, 5 frame constants, stubAppSettings, stubLibraryStore async, stubNotionService, stubSessionCoordinator, stubModelUpdateService, stubSaveDestinations, stubLibraryEntries). |
| `PSTranscribe/Tests/PSTranscribeTests/VisualRegressionTests.swift` | @Suite with 15 @Test methods | VERIFIED | 388 lines; `@Suite("VisualRegression", .serialized, .snapshots(record: .missing))` line 31; final class line 32; 15 @Test method declarations; snapshot helper with strict precision; LibrarySidebarHarness file-private wrapper. |
| `PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/` | 15 baseline PNGs | VERIFIED | All 15 named PNGs present; total 1232 KB (under 5 MB sanity bound). |
| `.github/workflows/build-check.yml` | env block + guard step + test step + failure upload | VERIFIED | 62 lines; YAML parses. All 4 elements present at expected locations. No path filter (CONTEXT D-06). |
| `.planning/phases/23-visual-regression-infra/23-ADR-snapshot-framework.md` | Nygard ADR for VISREG-01 | VERIFIED | 81 lines; all 5 sections (Context/Decision/Alternatives/Consequences/References + Status/Decider header); names library + version + 3 rejected alternatives. |
| `.planning/codebase/TESTING.md` | Visual Regression section, no stale "no test targets" claim | VERIFIED | Line 300 starts `## Visual Regression`; line 334 has regen incantation; line 339 has env enum; "No test targets detected" returns 0 occurrences; no stale `Tome` working-directory paths. |
| `CONTRIBUTING.md` (repo root) | regen workflow + env contract + ADR pointer | VERIFIED | 66 lines at repo root; all required sections (`## Tests`, `## Visual Regression Baselines`, `### Env var contract`, `### CI safety`, `### Strict precision`, `## Commit Hygiene`); cross-links to TESTING.md and ADR. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|------|--------|---------|
| VisualRegressionTests.swift | swift-snapshot-testing | `import SnapshotTesting` | WIRED | Line 2. |
| VisualRegressionTests.swift | PSTranscribe production module | `@testable import PSTranscribe` | WIRED | Line 6. |
| VisualRegressionTests.swift | SnapshotFixtures.swift | `SnapshotFixtures.stub*` and `SnapshotFixtures.withAppearance` calls | WIRED | 30+ call sites referencing factories + 5 withAppearance(.aqua) for System variants. |
| VisualRegressionTests.swift | swift-snapshot-testing image strategy | `assertSnapshot(of: NSHostingView, as: .image(...))` | WIRED | Snapshot helper lines 66-79. NSHostingView constructed line 53; layoutSubtreeIfNeeded line 65. |
| VisualRegressionTests.swift | Sparkle headless updater | `SPUStandardUpdaterController(startingUpdater: false, ...)` | WIRED | Line 5 import + 3 occurrences (lines 204, 227, 250) -- one per SettingsView appearance. |
| build-check.yml swift test step | VisualRegressionTests suite | `swift test` (no filter, runs full suite incl. snapshot tests) | WIRED | Line 44-46. No path filter. |
| build-check.yml record-mode guard | SNAPSHOT_TESTING_RECORD env var | shell conditional `[ -n ... ] && [ ... != "never" ]` | WIRED | Line 30-35. |
| build-check.yml upload step | actions/upload-artifact@v4 | `if: failure()` conditional | WIRED | Line 54-61, `if: failure()` count = 1 (matches plan strict expectation). |
| TESTING.md | CONTRIBUTING.md | "See also" cross-reference | WIRED | TESTING.md line 356 references CONTRIBUTING.md. |
| CONTRIBUTING.md | ADR | Markdown link to `23-ADR-snapshot-framework.md` | WIRED | CONTRIBUTING.md line 60 references the ADR path. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| VisualRegressionTests.swift snapshot helper | `host` (NSHostingView) | rendered SwiftUI view via `view.frame(...)` | Yes -- production view types (ContentView, etc.) constructed with deterministic stub state from SnapshotFixtures factories | FLOWING |
| ContentView snapshot tests | settings/notion/coord/library/modelUpdate/saveDest | Real production type instances built by SnapshotFixtures stubs (UserDefaults pre-cleared, hasCompletedOnboarding pre-set, LibraryStore seeded with 3 entries) | Yes -- factories produce real instances; UserDefaults reset prevents bleed; 3 LibraryEntry rows render | FLOWING |
| LibrarySidebar snapshot tests | entries (3 LibraryEntry) | `SnapshotFixtures.stubLibraryEntries(count: 3)` builds deterministic entries with fixed IDs / dates | Yes | FLOWING |
| SettingsView snapshot tests | updater (SPUUpdater) | `SPUStandardUpdaterController(startingUpdater: false, ...).updater` -- real Sparkle instance, not started, no network | Yes | FLOWING |
| ControlBar snapshot tests | recording state (isRecording=true, level=0.4, statusMessage="Recording", detectedApp="Zoom", silenceSeconds=5) | Hardcoded literal arguments -- this is correct because ControlBar is a parameter-only View with no upstream data source to trace | Yes (literals are intentional snapshot input) | FLOWING |
| DictationHUD snapshot tests | state=.listening, elapsed=12.5, partialText="..." | Hardcoded literals per Phase 18-05 parameter-only contract | Yes | FLOWING |

All 15 tests render real production views with real (or deterministically stubbed) state. No empty arrays passed where rendering data is expected; no hollow props.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `swift build` is green | `cd PSTranscribe && swift build` | Build complete (per SUMMARY 23-01 verification + replay test below requires green build to run) | PASS |
| `swift test --filter VisualRegression` exits 0 against committed baselines | `cd PSTranscribe && swift test --filter VisualRegression` | "Test run with 15 tests in 1 suite passed after 0.970 seconds" | PASS |
| 15 baseline PNGs at expected path | `find PSTranscribe/Tests/PSTranscribeTests/__Snapshots__ -name '*.png' \| wc -l` | 15 | PASS |
| build-check.yml YAML valid | `python3 -c "import yaml; yaml.safe_load(...)"` | Parsed; full job structure inspected (env, 6 steps, all expected names) | PASS |
| Test suite discoverable by `swift test --list-tests` | (executor-verified per 23-01-SUMMARY) | Lists VisualRegression suite | PASS |
| ADR file count and structure | `wc -l 23-ADR-snapshot-framework.md`, structure grep | 81 lines, all 5 Nygard sections | PASS |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|---------------|-------------|--------|----------|
| VISREG-01 | 23-01, 23-02 | Research + choose framework, produce ADR | SATISFIED | swift-snapshot-testing 1.19.2 wired; ADR with Nygard structure naming 3 rejected alternatives. |
| VISREG-02 | 23-01, 23-03 | Snapshot tests for primary surfaces in Light | SATISFIED | 5 *Light @Test methods (contentViewLight, librarySidebarLight, settingsViewLight, controlBarLight, dictationHUDLight); 5 Light PNGs committed. Surface mapping (LibrarySidebar/ControlBar) documented per D-03. |
| VISREG-03 | 23-01, 23-03 | Snapshot tests for primary surfaces in Dark | SATISFIED | 5 *Dark @Test methods; 5 Dark PNGs committed. |
| VISREG-04 | 23-01, 23-03, 23-04 | Snapshot tests for System appearance + CI failure-artifact safety | SATISFIED | 5 *System @Test methods using `withAppearance(.aqua)`; 5 System PNGs committed. CI guard step + failure-only upload-artifact step in build-check.yml. |
| VISREG-05 | 23-04 | Wire snapshot tests into CI as pre-merge gate | SATISFIED | build-check.yml triggers on `pull_request: branches: [main]`; runs `swift test` after `swift build`; macos-26 runner. |
| VISREG-06 | 23-05 | Document snapshot update workflow in CONTRIBUTING / `.planning/codebase/` | SATISFIED | TESTING.md `## Visual Regression` section with regen incantation + env-var contract; CONTRIBUTING.md at repo root with same; both cross-linked to ADR. |

All 6 requirement IDs from the ROADMAP frontmatter (VISREG-01..06) are SATISFIED. No orphans. The PLAN frontmatter `requirements:` arrays sum to coverage of all 6.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| VisualRegressionTests.swift | -- | `Issue.record` count = 0 | -- | The Plan-01 stub fallback was fully replaced by Plan-03 real assertions (PLAN 23-03 acceptance criterion). No runtime escape hatch. |
| All Phase 23 source files | -- | TODO/FIXME/HACK/PLACEHOLDER | -- | None found in scanned files. |

No anti-patterns or stub leftovers detected.

### Human Verification Required

None. Phase 23 VALIDATION baseline-correctness gate (visual review of 15 PNGs by user) is documented in 23-03-SUMMARY as already satisfied: "User reviewed all 15 baselines visually and approved (Phase 23 VALIDATION baseline-correctness gate satisfied)" -- key-decisions block. No further human gates remain.

### Gaps Summary

No gaps. All 14 must-haves verified, all 5 ROADMAP success criteria verified, all 6 VISREG requirement IDs satisfied. The behavioral spot-check (replay run of `swift test --filter VisualRegression`) passed during verification: 15/15 tests in 0.97s.

Notable reconciliations (not gaps):

1. **D-01 version reconciliation:** CONTEXT.md said "v2.x" but no v2 release exists upstream. Phase 23 reconciled to 1.19.2 (latest stable as of 2026-03-30). ADR documents this explicitly. Acceptable -- the substantive intent of D-01 (test-target only, Swift Testing trait API, ADR documenting trade-offs) is honored.
2. **Surface naming reconciliation:** ROADMAP names "LibraryView" and "RecordingView"; CONTEXT D-03 reconciled to actual file names `LibrarySidebar` and `ControlBar`. Documented in ADR; no missing surfaces.
3. **Plan-01 deviation:** init/deinit lifecycle removed from VisualRegressionTests due to Swift 6.3 @const macro enforcement; per-test `withAppearance(.aqua)` is now the sole NSApp.appearance restore primitive. RESEARCH Pitfall #2 documented this as the canonical primitive anyway. No coverage lost.
4. **System variant intentionally matches Light:** D-05 design has System pin to `.aqua`, so System bitmap == Light bitmap by inheritance design. Documented in 23-03-SUMMARY. Asymmetric `.darkAqua` System variant explicitly deferred per CONTEXT.md `<deferred>`.

Phase goal (snapshot testing for primary surfaces across Light/Dark/System wired into CI) is fully achieved.

---

*Verified: 2026-05-02T19:45:00Z*
*Verifier: Claude (gsd-verifier)*
