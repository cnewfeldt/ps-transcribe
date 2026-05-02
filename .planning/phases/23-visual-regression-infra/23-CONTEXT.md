# Phase 23: Visual Regression Infra - Context

**Gathered:** 2026-05-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Stand up snapshot testing infrastructure for primary macOS surfaces in Light + Dark + System appearances and wire it into PR-blocking CI so future appearance changes can't silently break the UI. Closes the snapshot-testing deferrals from Phase 20 (`20-CONTEXT.md` `<deferred>`) and Phase 21 (`21-CONTEXT.md` `<deferred>`: "Automated visual-regression tests for the override").

**In scope:**
- Add `pointfreeco/swift-snapshot-testing` v2.x as a SwiftPM test-target dependency
- New visual regression test file(s) under `Tests/PSTranscribeTests/` (Swift Testing `@Suite` style)
- Snapshot baselines for 5 surfaces × 3 appearances = 15 baseline PNGs committed at `Tests/PSTranscribeTests/__Snapshots__/`
- Test fixture helper for `NSApp.appearance` override + restoration
- Extend `.github/workflows/build-check.yml` with a `swift test` step
- Update workflow doc (regen-baseline instructions) — location TBD by planner (CONTRIBUTING.md and/or `.planning/codebase/TESTING.md`)
- ADR documenting framework choice and trade-offs (VISREG-01)

**Out of scope:**
- Refactoring views to be more snapshot-friendly beyond minimum needed for deterministic rendering
- Snapshot tests for surfaces outside the 5-surface roster (TranscriptView, NotionTagSheet, OnboardingView, DetailsPane, CaptureDock, LibraryEntryRow)
- Multi-size variants per surface (compact + standard) — single canonical frame each
- Git LFS adoption — PNGs are small (~50KB × 15 ≈ 750KB total)
- Pre-commit hook enforcement — CI gate is sufficient
- WCAG / accessibility-mode visual regression (Increase Contrast, Reduce Transparency)
- Marketing site (`/website`) visual regression
- Cross-platform / non-macos-26 runner verification

</domain>

<decisions>
## Implementation Decisions

### Framework choice

- **D-01:** Snapshot library is `pointfreeco/swift-snapshot-testing` v2.x. Added as a SwiftPM dep on the `.testTarget("PSTranscribeTests")` only — not on the executable target. Use the Swift Testing trait integration (`@Suite` / `@Test` compatible API), not the XCTest assertion path. Matches the existing test suite convention (every existing test in `Tests/PSTranscribeTests/` uses `import Testing`). Phase produces an ADR documenting trade-offs vs custom XCTest+CGImage hash and Swift Testing native compare (VISREG-01).

- **D-02:** Diff strictness is **strict**: `precision: 1.0`, `perceptualPrecision: 0.99`. Catches real visual regressions (token drift, shadow loss, baseline shift). Tolerance is tightened, never loosened, unless a specific test has a justified per-call override. Forces baseline regen on legitimate UI change — that is the whole point of VISREG.

### Surface roster

- **D-03:** Five surfaces get baselines, mapped from the roadmap's wording to actual file names:
  - `ContentView` (`Sources/PSTranscribe/Views/ContentView.swift`)
  - `LibrarySidebar` (`Sources/PSTranscribe/Views/LibrarySidebar.swift`) — replaces roadmap's "LibraryView"
  - `SettingsView` (`Sources/PSTranscribe/Views/SettingsView.swift`)
  - `ControlBar` (`Sources/PSTranscribe/Views/ControlBar.swift`) — replaces roadmap's "RecordingView" (record button + status is the recording UI)
  - `DictationHUD` (`Sources/PSTranscribe/Views/DictationHUD.swift`) — snapshotted via `NSHostingView` of the SwiftUI root, NOT via the live `NSPanel`. Vibrancy material is a `.hudWindow` runtime concern; snapshot covers the rendered SwiftUI output.

- **D-04:** Snapshot frame sizing is **one canonical size per surface**, hard-coded via `.frame(width:height:)` on the test wrapper view. Planner picks production-realistic dimensions per surface (roughly: ContentView ~1100×700, LibrarySidebar ~280×600, SettingsView ~520×400, ControlBar ~800×56, DictationHUD ~560×120 — planner verifies against actual scene defaults in `PSTranscribeApp.swift` and tunes). 5 surfaces × 3 appearances = 15 baseline PNGs.

### Appearance handling

- **D-05:** Appearance trio is rendered as follows:
  - **Light:** test wrapper applies `.preferredColorScheme(.light)`. `NSApp.appearance` left alone.
  - **Dark:** test wrapper applies `.preferredColorScheme(.dark)`. `NSApp.appearance` left alone.
  - **System:** test fixture overrides `NSApp.appearance = NSAppearance(named: .aqua)` for the duration of the test, then snapshots WITHOUT a `.preferredColorScheme` modifier. This validates the inheritance path — that views resolve `colorScheme` from app-level appearance when no explicit override is set. Fixture restores the original `NSApp.appearance` in teardown to avoid bleeding state into adjacent tests. (Pinning to `.aqua` is the deterministic choice; the inverse `.darkAqua` variant is deferred — see `<deferred>`.)
  - For surfaces wrapped in `NSHostingView` for snapshot (e.g., DictationHUD), the same `.preferredColorScheme` and `NSApp.appearance` rules apply — the hosting view inherits the SwiftUI environment and the AppKit appearance respectively.

### CI gate

- **D-06:** Extend `.github/workflows/build-check.yml` with a `swift test` step after the existing `swift build` step. Same `macos-26` runner, same Xcode 26 selection. All Swift Testing suites in `Tests/PSTranscribeTests/` run on every PR — visual regression piggybacks on the existing test target. No new workflow file. No path filter — the `swift test` step is cheap relative to the `swift build` already paid for, and avoids the trap of skipping tests on a PR that touches an indirect dependency.

### Baseline storage + regen

- **D-07:** Baseline PNGs live at `PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/` (the swift-snapshot-testing default location, sibling to test files), committed to the repo on `main`. No git LFS. Regenerate locally with:
  ```bash
  SNAPSHOT_TESTING_RECORD=true swift test --filter VisualRegression
  ```
  Reviewer eyeballs the diff in PR. Plain commit. ~750KB total expected; not a meaningful repo-bloat concern.

- **D-08:** Regen workflow documentation (VISREG-06) is added to `.planning/codebase/TESTING.md` (current "Testing Patterns" map — currently says "no test targets" which is stale; this phase is the moment to refresh it) AND a short pointer added to `CONTRIBUTING.md` if one exists, or created if not. Planner verifies CONTRIBUTING.md state during planning.

### Claude's Discretion

- **Test file structure** — Planner picks whether snapshots live in one suite (`VisualRegressionTests.swift` with one `@Test` per surface × appearance) or split per-surface (`ContentViewSnapshotTests.swift`, etc.). Bias: one suite, since the count is small (5 surfaces) and shared fixtures (NSApp.appearance override, frame sizing) want one home.
- **State injection for ContentView and LibrarySidebar** — Both depend on `@Observable` stores (`AppSettings`, `TranscriptStore`, `LibraryStore`). Planner picks deterministic stub state per snapshot — typically: empty TranscriptStore, default AppSettings, LibraryStore with a fixed 3-entry seed for visual coverage of the row component. Stubs may live in a `SnapshotFixtures.swift` helper.
- **NSApp.appearance restoration mechanics** — Whether the override goes via a `@Suite`-level `init`/`deinit`, a per-test `withAppearance(_:)` helper closure, or a Swift Testing trait. Planner picks the cleanest pattern; restoration in teardown is the hard rule.
- **DictationHUD render path mechanics** — Planner picks how to extract the SwiftUI root from `DictationWindowController` (or constructs a parallel test-only `NSHostingView` pointing at the same `DictationHUD` view). Acceptance is that the snapshot reflects what the user sees inside the panel, not the panel chrome.
- **Snapshot file naming convention** — swift-snapshot-testing default (`<TestName>.<index>.png`) is fine; planner may set a custom name if it improves diff review (e.g., `ContentView-light.png`, `ContentView-dark.png`, `ContentView-system.png`).
- **ADR location and shape** — Planner picks `.planning/adr/`, inline in `23-PLAN.md`, or a Phase 23 doc. Repo currently has no ADR directory; if the planner introduces one, that's a Phase 23 deliverable.
- **Frame width/height exact values** — Suggested ranges in D-04; planner tunes against actual `WindowGroup` defaults and verifies snapshots look representative.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and requirements

- `.planning/ROADMAP.md` §"Phase 23: Visual Regression Infra" — phase goal, success criteria, dependency note ("None — independent infra work").
- `.planning/REQUIREMENTS.md` §"Visual Regression / Snapshot Testing (`VISREG-01`)" — VISREG-01..06 requirement IDs that this phase delivers.
- `.planning/PROJECT.md` — milestone v1.3 context.

### Source files in scope (snapshot targets)

- `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift` — main window root, library + transcript composition. Pulls from `AppSettings`, `TranscriptStore`, `LibraryStore`.
- `PSTranscribe/Sources/PSTranscribe/Views/LibrarySidebar.swift` — sidebar list of library entries. Pulls from `LibraryStore`.
- `PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift` — settings form (Phase 21 added `Section("Appearance")` at top, Phase 18 added Audio Input + Local File sections).
- `PSTranscribe/Sources/PSTranscribe/Views/ControlBar.swift` — record button + status bar + error display.
- `PSTranscribe/Sources/PSTranscribe/Views/DictationHUD.swift` — HUD content; lives inside `DictationWindowController`'s NSPanel at runtime, snapshot via `NSHostingView`.
- `PSTranscribe/Sources/PSTranscribe/App/DictationWindowController.swift` — reference for how the HUD is hosted; Phase 21 D-07 wired NSPanel.appearance observation here.
- `PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift` — scene defaults; planner reads WindowGroup default sizes here when picking canonical frames.

### Source files in scope (test target)

- `PSTranscribe/Package.swift` — add `pointfreeco/swift-snapshot-testing` to `dependencies`, add to `.testTarget("PSTranscribeTests").dependencies`. Existing test target is already declared at lines ~28–31; no new target needed.
- `PSTranscribe/Tests/PSTranscribeTests/` — destination directory for new visual regression test file(s). Existing convention: Swift Testing `@Suite` + `@Test`, `import Testing`, `@testable import PSTranscribe`. See `DictationLoggerTests.swift`, `AppSettingsTests.swift` for canonical examples.

### CI infra

- `.github/workflows/build-check.yml` — extend with `swift test` step after `swift build`. Single workflow, single runner. Reference shape for the new step: matches existing `swift build` step (same `working-directory: PSTranscribe`).
- `.github/workflows/release-dmg.yml` — DOES NOT change; release build doesn't gate on tests. (Test gate is the PR-merge surface only.)
- `.github/workflows/lint-summaries.yml` — Phase 22 precedent for path-filtered conditional CI; not directly reused but useful as a pattern reference.

### Codebase intelligence (read before planning)

- `.planning/codebase/TESTING.md` — currently says "no test targets" (analysis predates the test target's creation). Phase 23 must update this file as part of D-08.
- `.planning/codebase/STACK.md` — Swift 6.2, macOS 26, SwiftPM, no `.xcassets`. swift-snapshot-testing's `NSImage` strategy lands on the same plumbing.
- `.planning/codebase/CONVENTIONS.md` — Swift 6.2 strict concurrency; @MainActor isolation for view tests.
- `.planning/codebase/STRUCTURE.md` — view layout under `Sources/PSTranscribe/Views/`. (Note: predates rebrand; references `Tome` paths in places — actual paths use `PSTranscribe`.)

### Prior phase context (deferrals being closed)

- `.planning/milestones/v1.2-phases/20-dark-mode-parity/20-CONTEXT.md` `<deferred>` — "Automated snapshot / visual-regression tests — Explicit out-of-scope per SPEC.md (manual UAT chosen). If regression risk grows, future phase could add `swift-snapshot-testing` or XCUITest screenshot pipeline." Phase 23 closes this with the `swift-snapshot-testing` choice.
- `.planning/milestones/v1.2-phases/21-appearance-override/21-CONTEXT.md` `<deferred>` — "Automated visual-regression tests for the override — Phase 20 deferred snapshot testing. Phase 21 verification is manual UAT only." Phase 23 closes this; Phase 21's appearance override is the primary feature being regression-tested.
- `.planning/milestones/v1.2-phases/20-dark-mode-parity/20-CONTEXT.md` D-09 — establishes manual screenshot diff baselines under `screenshots/baseline/`, `screenshots/wave-1/`, etc. Phase 23 supersedes this manual approach with automated snapshot testing.
- `.planning/milestones/v1.2-phases/18-hotkey-dictation-plain-folder-output/18-CONTEXT.md` D-03 — locks DictationHUD as native `.hudWindow` vibrancy. Affects D-03/D-05 here: HUD snapshot covers SwiftUI root, not panel chrome / vibrancy material rendering.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **Existing Swift Testing test target** (`PSTranscribe/Tests/PSTranscribeTests/`) — 18 test files already in place using `import Testing` + `@Suite` + `@Test`. Visual regression tests slot in alongside as a peer suite, no test-target restructuring needed. `Package.swift` already declares `.testTarget(name: "PSTranscribeTests", ...)`.
- **Swift Testing fixture patterns** — `DictationLoggerTests.swift` uses `private func tempDir()` for per-test temp dirs and `defer { try? FileManager.default.removeItem(at: dir) }` for cleanup. Visual regression fixture for `NSApp.appearance` override + restoration mirrors this shape (capture pre-state, restore in defer/deinit).
- **Phase 18 sub-directory convention** (`Tests/PSTranscribeTests/Phase18/` and `Phase18.1/`) — precedent for grouping a phase's tests if the count grows. Phase 23 likely uses one flat file (`VisualRegressionTests.swift`) given the small surface count, but the precedent exists.
- **Existing CI shape** (`.github/workflows/build-check.yml`) — minimal 3-step workflow (checkout, Xcode select, swift build). The `swift test` step extends this pattern verbatim (`working-directory: PSTranscribe`, `run: swift test`).

### Established Patterns

- **Swift Testing exclusively** — no XCTest in the test target. swift-snapshot-testing's `assertSnapshot(of:as:)` is XCTest-flavored; v2.x's Swift Testing integration uses `expectSnapshot` or trait-based equivalents. Planner verifies the exact API shape during research.
- **`@MainActor` view rendering** — SwiftUI views are `@MainActor`; snapshot tests are also `@MainActor`. `@Suite(.serialized)` is the existing convention for tests that touch shared state (UserDefaults, file system) — visual regression tests likely also serialized due to NSApp.appearance mutation.
- **No `.xcassets`** — colors are code-defined via `Color(light:dark:)` (Phase 20 D-01). Snapshot tests don't need to bundle resources; they render against the existing in-memory token system.
- **macos-26 runner** — fonts and font hinting are stable across runs of the same OS image. Strict precision (D-02) is realistic; minor drift between runner image versions is the main flake risk and will be handled by baseline regen, not by lowering tolerance.

### Integration Points

- **Test target → executable target via `@testable import PSTranscribe`** — visual regression tests can construct any view + observable state directly. No view exports or accessibility hooks needed.
- **CI test failure surface** — `swift test` returns non-zero on snapshot diff; GitHub Actions surfaces failures in PR checks. swift-snapshot-testing writes diff PNGs to a sibling directory on failure — the CI run uploads them as artifacts (planner adds `actions/upload-artifact` step on failure for diff visibility).
- **`SNAPSHOT_TESTING_RECORD=true` env var** — local-only regen flow. CI never sets this (would silently overwrite baselines). Planner adds a guard in CI workflow that fails the build if the env var is set in CI environment.
- **DictationHUD snapshot path** — `DictationHUD` is a `View`; instantiate it directly with stub state, wrap in `NSHostingView`, render. The runtime `DictationWindowController` + `NSPanel` are NOT involved in the snapshot. This is intentional: panel chrome and vibrancy are AppKit/system rendering concerns, not regressions Phase 23 aims to catch.

</code_context>

<specifics>
## Specific Ideas

- **Strict precision is the whole point.** User chose 1.0 / 0.99 over leniency despite higher flake risk. The product invariant: a real visual change must cause a baseline regen, not silently pass. Reject any planner output that loosens tolerance globally; per-test overrides only with documented justification.
- **`SNAPSHOT_TESTING_RECORD=true swift test`** is the regen incantation. Document it verbatim. The expected developer flow: change UI → run tests locally → see failures → run with the env var → review new PNGs → commit alongside the source change → reviewer eyeballs the PNG diff in PR.
- **System appearance pinning to `.aqua`** validates inheritance. Phase 21 D-05 placed `.preferredColorScheme(settings.appearancePreference.colorScheme)` at scene roots; when preference is `.system`, the modifier resolves to `nil` and views inherit `NSApp.effectiveAppearance`. Snapshot must verify this path doesn't accidentally pin. Inverse direction (`.darkAqua`) is deferred (see `<deferred>`) — single direction is sufficient for inheritance verification, doubling adds 5 baselines without proportional signal.
- **Five surfaces, not seven.** User explicitly rejected the "leaf + composite" expansion. ControlBar covers the recording UI; LibrarySidebar covers the library presentation; ContentView covers the main window composition; SettingsView and DictationHUD are first-class. CaptureDock, TranscriptView, NotionTagSheet, OnboardingView, DetailsPane, LibraryEntryRow are deliberately out of scope for this phase.
- **CI extends, doesn't replace.** `build-check.yml` gains a `swift test` step; `release-dmg.yml` is untouched. Test gate = pre-merge surface; release path remains build-only.

</specifics>

<deferred>
## Deferred Ideas

- **Inverse `.darkAqua` System variant** — D-05 pins NSApp.appearance to `.aqua` only. A symmetric `.darkAqua` System pin would validate dark-side inheritance independently. Defer until a real regression surfaces in the asymmetric coverage, or until Phase 23 lands and we observe gaps.
- **Multi-size snapshot variants** (compact + standard per surface) — rejected in favor of one canonical frame per surface (D-04). Future phase if responsive-layout regressions become a recurring concern.
- **Snapshot tests for additional surfaces** — TranscriptView, NotionTagSheet, OnboardingView, DetailsPane, CaptureDock, LibraryEntryRow. Not in the roadmap's roster. Add in a follow-up phase if they accumulate visual bugs.
- **Pre-commit hook to enforce snapshot-baseline-up-to-date** — CI gate is sufficient. Pre-commit adds friction without adding safety the PR check doesn't already provide.
- **Git LFS for snapshot PNGs** — premature for ~750KB of small PNGs. Revisit if baseline count grows past a few hundred.
- **XCUITest-based screenshot pipeline** — alternative to swift-snapshot-testing that runs the actual app via UI automation. Heavier infra, slower, more flake. Rejected as unnecessary for the audit scope; reconsider only if SwiftUI rendering diverges meaningfully from `NSHostingView` rendering (currently no signal that it does).
- **Visual regression for the marketing site** (`/website`) — site stays light-only by milestone decision; visual regression scope is the macOS app.
- **WCAG / accessibility-mode visual regression** — Increase Contrast, Reduce Transparency, High Contrast appearances. Belongs in a dedicated accessibility phase (Phase 20 + 21 already deferred this).
- **Snapshot test for the menu bar icon** (`MenuBarExtra` label) — system-rendered glyph; snapshot would capture only what we draw, not what the user sees. Acknowledged as a tolerated coverage gap (consistent with Phase 21 Claude's Discretion on MenuBarExtra label scope).
- **Multi-runner image / multi-OS-version matrix** — single macos-26 runner is the current CI shape; cross-version drift handled by baseline regen on runner image bumps, not by parallel matrix runs.

</deferred>

---

*Phase: 23-visual-regression-infra*
*Context gathered: 2026-05-02*
