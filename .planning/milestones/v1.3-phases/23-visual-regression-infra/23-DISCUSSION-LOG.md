# Phase 23: Visual Regression Infra - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-02
**Phase:** 23-visual-regression-infra
**Areas discussed:** Framework choice + Swift Testing fit; Surface roster + size discipline; Appearance trio strategy (Light/Dark/System); CI gate shape + baseline storage

---

## Framework choice + Swift Testing fit

### Q1 — Snapshot framework

| Option | Description | Selected |
|--------|-------------|----------|
| swift-snapshot-testing v2.x (Recommended) | Add as SwiftPM dep. Use NSView/NSWindow strategies + Swift Testing trait integration. Standard tool, well-maintained. ADR documents the choice (VISREG-01). | ✓ |
| Custom XCTest+CGImage hash | No new dep. Render NSView to NSBitmapImageRep, hash, compare. We own diff visualization, regenerate flow, fail UI. | |
| Survey both, decide in research phase | Defer to gsd-phase-researcher. | |

**User's choice:** swift-snapshot-testing v2.x
**Notes:** Roadmap pre-suggested this library; Swift Testing trait support in v2.x means it integrates with the existing `@Suite` / `@Test` test convention without an XCTest detour.

### Q2 — Diff strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Strict: precision 1.0, perceptualPrecision 0.99 (Recommended) | Catches real visual regressions. Forces baseline regen on legitimate UI change. | ✓ |
| Lenient: precision 0.99, perceptualPrecision 0.95 | Tolerates minor anti-aliasing drift. Lower flake risk; masks small token regressions. | |
| Per-surface: strict on small, lenient on large | Avoids tradeoff. More bookkeeping. | |

**User's choice:** Strict (1.0 / 0.99)
**Notes:** Strict is the whole point of the regression gate; flake mitigation is via baseline regen, not tolerance loosening.

---

## Surface roster + size discipline

### Q3 — Resolve ambiguous surface names

| Option | Description | Selected |
|--------|-------------|----------|
| Map roadmap names to closest concrete views (Recommended) | ContentView, LibrarySidebar, SettingsView, ControlBar, DictationHUD. RecordingView=ControlBar. LibraryView=LibrarySidebar. | ✓ |
| Composite ContentView in two states (idle + recording) | ContentView-idle, ContentView-recording, SettingsView, DictationHUD. | |
| Both — leaf views AND composite | 7 surfaces × 3 appearances = 21 baselines. | |

**User's choice:** Map to concrete views (5 surfaces)
**Notes:** Roadmap names "LibraryView" and "RecordingView" don't exist as files. ControlBar is the recording UI; LibrarySidebar is the library presentation.

### Q4 — Frame sizing strategy

| Option | Description | Selected |
|--------|-------------|----------|
| One canonical size per surface (Recommended) | 5 surfaces × 3 appearances = 15 baselines. Lean repo. | ✓ |
| Two sizes per surface (compact + standard) | Catches wrap/truncation regressions. 30 baselines. | |
| Production frame sizes pulled from real window state | Aligned with shipped UI; brittle on default-size tweaks. | |

**User's choice:** One canonical size per surface
**Notes:** Planner picks production-realistic dimensions; values can be tuned during planning.

---

## Appearance trio strategy (Light/Dark/System)

### Q5 — System appearance handling

| Option | Description | Selected |
|--------|-------------|----------|
| Pin runner via NSApp.appearance override (Recommended) | Test fixture sets NSApp.appearance = NSAppearance(named: .aqua). Verifies inheritance deterministically. Restore in teardown. | ✓ |
| Skip 'System' entirely — only Light + Dark baselines | 5×2=10 baselines; misses inheritance regression. | |
| Two System variants (Light-pinned + Dark-pinned) | 5×4=20 baselines; validates inheritance both ways. | |

**User's choice:** Pin runner via NSApp.appearance override (.aqua)
**Notes:** `.darkAqua` direction deferred — single direction is sufficient for inheritance verification; doubling doesn't add proportional signal.

---

## CI gate shape + baseline storage

### Q6 — CI workflow shape

| Option | Description | Selected |
|--------|-------------|----------|
| Extend build-check.yml — add 'swift test' step (Recommended) | Single workflow runs build + tests. Same macos-26 runner. | ✓ |
| New workflow visual-regression.yml — path-filtered | Triggers only on PRs touching Views/, Design/, Tests/. Two workflows. | |
| Extend build-check + path-filtered swift test | swift test runs only on UI/test changes. Conditional step. | |

**User's choice:** Extend build-check.yml with `swift test`
**Notes:** All Swift Testing suites run on every PR — visual regression piggybacks. Avoids the trap of skipping tests on PRs that touch indirect dependencies.

### Q7 — Baseline storage and regen flow

| Option | Description | Selected |
|--------|-------------|----------|
| Plain commit + env-var regen flow (Recommended) | PNGs in __Snapshots__/ committed to main. Regenerate with `SNAPSHOT_TESTING_RECORD=true swift test`. | ✓ |
| Git LFS for PNGs | LFS quota friction; premature for ~15 small files. | |
| Plain commit + dedicated regen script | Same as option 1 plus wrapper script. | |

**User's choice:** Plain commit + env-var regen
**Notes:** ~750KB total (~15 PNGs × ~50KB). Standard swift-snapshot-testing pattern. Reviewer eyeballs PNG diff in PR.

---

## Continue check

### Q8 — Anything else before writing CONTEXT.md?

| Option | Description | Selected |
|--------|-------------|----------|
| Write CONTEXT.md now (Recommended) | Decisions are locked. | ✓ |
| DictationHUD render path — NSPanel vs NSHostingView | | |
| View state injection — stub TranscriptStore/AppSettings | | |
| Update workflow doc location (VISREG-06) | | |

**User's choice:** Write CONTEXT.md now
**Notes:** Three deferred areas folded into Claude's Discretion in CONTEXT.md — planner handles them with the locked decisions as constraints.

---

## Claude's Discretion

- Test file structure (one suite vs split-per-surface) — bias toward one suite given small count
- State injection for ContentView and LibrarySidebar (stub TranscriptStore/AppSettings/LibraryStore in a SnapshotFixtures helper)
- NSApp.appearance restoration mechanics (suite-level init/deinit vs per-test closure vs Swift Testing trait)
- DictationHUD render path mechanics (extracting SwiftUI root for NSHostingView snapshot)
- Snapshot file naming convention (default vs custom names like `ContentView-light.png`)
- ADR location and shape (.planning/adr/, inline in 23-PLAN.md, or Phase 23 doc)
- Frame width/height exact values (planner tunes against `WindowGroup` defaults)
- Workflow doc location for VISREG-06 (CONTRIBUTING.md and/or `.planning/codebase/TESTING.md` refresh)

---

## Deferred Ideas

- Inverse `.darkAqua` System variant
- Multi-size snapshot variants (compact + standard per surface)
- Snapshot tests for additional surfaces (TranscriptView, NotionTagSheet, OnboardingView, DetailsPane, CaptureDock, LibraryEntryRow)
- Pre-commit hook for snapshot freshness
- Git LFS adoption
- XCUITest-based screenshot pipeline alternative
- Marketing site visual regression
- WCAG / accessibility-mode visual regression
- Menu bar icon snapshot
- Multi-runner image / multi-OS-version matrix
