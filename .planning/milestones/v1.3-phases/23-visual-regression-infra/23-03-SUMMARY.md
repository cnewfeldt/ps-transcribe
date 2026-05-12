---
phase: 23-visual-regression-infra
plan: 03
subsystem: testing
tags: [swift-testing, snapshot-testing, nshostingview, appearance, visual-regression]

requires:
  - phase: 23-01
    provides: SwiftPM dep on swift-snapshot-testing 1.19.2, empty @Suite skeleton with 5 stubs, SnapshotFixtures shell, __Snapshots__ dir
provides:
  - 15 @Test methods (5 surfaces × Light/Dark/System) replacing the 5 Wave 0 stubs
  - 5 production stub-state factories in SnapshotFixtures (AppSettings, LibraryStore, NotionService, SessionCoordinator, ModelUpdateService, SaveDestinations, LibraryEntry)
  - 15 baseline PNGs locked at PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/
  - host.appearance fix: NSHostingView ignores .preferredColorScheme during off-screen capture; per-test NSAppearance.Name argument bypasses the trap
  - hasCompletedOnboarding pre-set in stubAppSettings so ContentView snapshots render the production library/transcript surface, not the Onboarding overlay
affects: [phase 23-05, future visual UAT, any future appearance changes]

tech-stack:
  added: []
  patterns:
    - "Snapshot helper takes optional NSAppearance.Name -- Light/Dark set host.appearance directly, System inherits from NSApp.appearance via SnapshotFixtures.withAppearance(.aqua)"
    - "@MainActor per-method (not class-level) -- swift-testing 6.3 + swift-testing's @const/@section requirement is incompatible with class-level @MainActor + stored state"
    - "LibrarySidebarHarness file-private wrapper holds @State for the @Binding selectedID -- standard SwiftUI test pattern for binding-required views"
    - "stubAppSettings pre-clears v1.2 keys AND pre-sets gating flags (hasCompletedOnboarding = true) so production .task triggers do not flip into onboarding/migration overlays during snapshots"

key-files:
  created:
    - PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/contentViewLight.ContentView-Light.png
    - PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/contentViewDark.ContentView-Dark.png
    - PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/contentViewSystem.ContentView-System.png
    - PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/dictationHUDLight.DictationHUD-Light.png
    - PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/dictationHUDDark.DictationHUD-Dark.png
    - PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/dictationHUDSystem.DictationHUD-System.png
    - PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/controlBarLight.ControlBar-Light.png
    - PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/controlBarDark.ControlBar-Dark.png
    - PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/controlBarSystem.ControlBar-System.png
    - PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/librarySidebarLight.LibrarySidebar-Light.png
    - PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/librarySidebarDark.LibrarySidebar-Dark.png
    - PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/librarySidebarSystem.LibrarySidebar-System.png
    - PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/settingsViewLight.SettingsView-Light.png
    - PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/settingsViewDark.SettingsView-Dark.png
    - PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/settingsViewSystem.SettingsView-System.png
  modified:
    - PSTranscribe/Tests/PSTranscribeTests/SnapshotFixtures.swift
    - PSTranscribe/Tests/PSTranscribeTests/VisualRegressionTests.swift

key-decisions:
  - "NSHostingView.appearance set directly per test -- .preferredColorScheme alone is unreliable for off-screen NSHostingView bitmap capture (RESEARCH Pitfall #4 confirmed in practice)"
  - "System variant matches Light by D-05 design -- pinning NSApp.appearance to .aqua and leaving host.appearance nil verifies the inheritance path; the resulting bitmap is intentionally identical to the Light variant"
  - "hasCompletedOnboarding = true in stubAppSettings -- cleanest place to gate the OnboardingView .task trigger; UserDefaults is process-global so stubAppSettings is the single source of truth"
  - "User-approved baselines per Phase 23 VALIDATION -- visual judgment gate satisfied"

patterns-established:
  - "Snapshot helper signature: (view, size, name, appearance: NSAppearance.Name? = nil) -- propagates to any future visual surfaces"
  - "Light = .aqua, Dark = .darkAqua, System = nil + withAppearance(.aqua) wrapper -- canonical 3-appearance triplet for new surfaces"

requirements-completed:
  - VISREG-02
  - VISREG-03
  - VISREG-04
---

# Plan 23-03 Summary -- 15 Real Snapshot Tests + Baseline PNGs

## What was built

Replaced the 5 Wave 0 stub bodies (Plan 23-01) with 15 real `@Test` methods covering 5 surfaces × Light/Dark/System appearances. Implemented 7 production stub-state factories in `SnapshotFixtures.swift` so the surfaces render with deterministic state and no leaked UserDefaults. Recorded 15 baseline PNGs via `SNAPSHOT_TESTING_RECORD=all swift test --filter VisualRegression` and locked them at `PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/`.

All 15 tests pass in default (non-record) mode against the committed baselines.

## Surfaces covered

| Surface         | Frame (W × H pts) | Production view called                         |
|-----------------|-------------------|-------------------------------------------------|
| ContentView     | 1280 × 820        | `ContentView(settings:notionService:libraryStore:sessionCoordinator:modelUpdateService:saveDestinations:)` |
| LibrarySidebar  | 280 × 600         | `LibrarySidebar(entries:selectedID:activeEntryID:)` via `LibrarySidebarHarness` |
| SettingsView    | 520 × 400         | `SettingsView(settings:updater:notionService:modelUpdateService:)` |
| ControlBar      | 800 × 56          | `ControlBar(...)` (13-arg memberwise init, full recording state) |
| DictationHUD    | 560 × 120         | `DictationHUD(state:.listening, elapsed:partialText:onStop:)` |

## Issues encountered + corrections

### 1. `.preferredColorScheme` does not reach NSHostingView (Pitfall #4 confirmed)

First record run produced 15 PNGs where Light, Dark, and System variants of every surface had byte-identical content. The `.preferredColorScheme(.light/.dark)` modifier on the rooted SwiftUI view did not reach `NSHostingView`'s resolved appearance during off-screen `cacheDisplay` bitmap capture.

**Fix:** Snapshot helper now takes an optional `appearance: NSAppearance.Name? = nil`. Light variants pass `.aqua`, Dark variants pass `.darkAqua`. The helper sets `host.appearance = NSAppearance(named: appearance)` before `layoutSubtreeIfNeeded()`. System variants pass nil and rely on `SnapshotFixtures.withAppearance(.aqua)` to set `NSApp.appearance` -- this is the inheritance path verified by D-05, and System bitmaps intentionally match Light because both resolve to `.aqua`.

After the fix, all 5 surfaces have distinct Light vs Dark hashes; System matches Light by design.

### 2. ContentView snapshots showed OnboardingView overlay

`ContentView` reads `@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false` and triggers `showOnboarding = true` in its `.task` block when the flag is false (`Sources/PSTranscribe/Views/ContentView.swift:294-295`). Test runs cleared other UserDefaults keys but did not pre-set this flag, so the snapshot captured the OnboardingView sheet instead of the production library/transcript surface.

**Fix:** `SnapshotFixtures.stubAppSettings()` now sets `defaults.set(true, forKey: "hasCompletedOnboarding")` after the existing `removeObject` loop. Single source of truth; UserDefaults is process-global so the assignment persists for the duration of the test run.

## Verifiable outcomes

- `swift build`: green
- `swift test --filter VisualRegression` (default mode, baselines locked): all 15 tests PASS in 0.9s
- `SNAPSHOT_TESTING_RECORD=all swift test --filter VisualRegression`: re-records all 15 baselines
- Light vs Dark hash distinct for all 5 surfaces; System == Light per D-05 inheritance design
- User reviewed all 15 baselines visually and approved (Phase 23 VALIDATION baseline-correctness gate satisfied)

## Commits

- `9c1e5b9` -- `feat(23-03): implement SnapshotFixtures stub-state factories`
- `4fcbc19` -- `feat(23-03): replace 5 stubs with 15 real @Test methods + snapshot helper`
- `4f01e41` -- `fix(23-03): set NSHostingView.appearance directly for Light/Dark variants`
- `0882d09` -- `test(23-03): record 15 baseline PNGs for visual regression suite`
- `<this commit>` -- `docs(23-03): complete visual regression Wave 1 plan`
