# ADR VISREG-01: Snapshot Testing Framework Choice

**Status:** Accepted (Phase 23, 2026-05-02)
**Decider:** User + planner (CONTEXT.md D-01)
**Supersedes:** Phase 20 D-09 (manual screenshot diff baselines under `screenshots/baseline/`)

## Context

v1.2 Phases 20 (Chronicle adaptive light/dark token palette) and 21 (AppearancePreference override) shipped without automated visual regression coverage. Both phases' CONTEXT.md `<deferred>` sections explicitly flagged snapshot testing as a follow-up. Phase 23 closes those deferrals so future appearance-related changes cannot silently break the UI.

The five surfaces in scope -- `ContentView`, `LibrarySidebar`, `SettingsView`, `ControlBar`, `DictationHUD` -- need pixel-comparison baselines across Light, Dark, and System appearances (15 baselines total). The CI gate is the existing `.github/workflows/build-check.yml` on `macos-26`.

## Decision

Use **`pointfreeco/swift-snapshot-testing`** pinned to `from: "1.19.2"` (latest stable as of 2026-03-30).

- Added as a SwiftPM dependency on the `.testTarget("PSTranscribeTests")` only -- production binary surface unchanged.
- Use the **Swift Testing trait API** (`@Suite(.snapshots(record:))` + `assertSnapshot(of:as:)`) introduced in 1.17.0, not the legacy XCTest assertion path.
- Strict precision: `precision: 1.0`, `perceptualPrecision: 0.99`. Per CONTEXT.md D-02, tightened only -- never loosened globally. Per-test overrides allowed only with documented justification in the test body.
- Baselines committed under `PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/`. No git LFS (~750 KB total expected).

### Reconciliation note

CONTEXT.md D-01 names the library version as "v2.x". No v2 release exists; the pointfreeco/swift-snapshot-testing project has been on the 1.x line since 2019 and the latest tagged release is 1.19.2 (2026-03-30, verified via GitHub API). The version recorded above -- 1.19.2 -- is the operational decision; the rest of D-01's substance (test-target only, Swift Testing trait API, ADR documenting trade-offs) holds verbatim.

## Alternatives Considered

### 1. Custom XCTest + `cacheDisplay` + CGImage SHA-256 hash compare (rejected)

A hand-rolled solution using AppKit's `bitmapImageRepForCachingDisplay` plus a SHA-256 hash for equality. Pros: zero third-party deps. Cons:

- Hash equality is binary -- no perceptual tolerance. CONTEXT.md D-02 locks `perceptualPrecision: 0.99`, which requires a Delta-E implementation behind it. We would have to write that implementation.
- No diff PNG output for human review on failure.
- No Swift Testing trait integration; we would re-implement the `record` mode plumbing.
- Maintenance burden of a hand-rolled diffing pipeline is not worth dodging one well-maintained dep on a SwiftPM-only test target.

### 2. `emergetools/snapshotpreviews` (rejected)

An alternative library that integrates Xcode `#Preview` blocks with auto-discovery and gallery generation. Pros: leverages existing `#Preview` annotations. Cons:

- iOS-first; less mature macOS coverage (the `NSView` strategy is not the primary code path).
- CONTEXT.md D-01 explicitly locks `swift-snapshot-testing`.
- Worth revisiting in a future phase if `#Preview`-driven snapshot coverage becomes desirable.

### 3. XCUITest screenshot pipeline (rejected)

UI-automation-driven screenshots of the actual running app. Pros: catches AppKit-level regressions (NSPanel chrome, vibrancy material). Cons:

- Heavier infrastructure -- requires building, launching, and driving the live app.
- Slower (multi-second per screenshot vs sub-100ms via `cacheDisplay`).
- Higher flake rate from real-app timing.
- CONTEXT.md `<deferred>` already rejects this for Phase 23. Reconsider only if SwiftUI rendering diverges meaningfully from `NSHostingView` rendering (no current signal that it does).

## Consequences

### Positive

- One well-maintained dependency covers every Phase 23 requirement (perceptual diff, env-var record mode, automatic diff PNG output, Swift Testing trait, macOS NSView image strategy).
- Strict precision means legitimate UI changes always require a baseline regen -- the regression-detection signal stays high.
- CI integration is a 4-line YAML diff (1 env, 1 guard step, 1 test step, 1 artifact upload) on top of the existing `build-check.yml`.

### Negative / Trade-offs

- Test target gains one external dependency. Production binary unchanged.
- Baseline PNGs (~50 KB x 15 ~= 750 KB) committed to the repo on `main`. Acceptable; git LFS deferred until baseline count grows past a few hundred (CONTEXT.md `<deferred>`).
- Strict precision raises false-positive risk on macOS minor-version drift between developer hardware and the `macos-26` CI runner. Treatment per RESEARCH Pitfall #5: regenerate baselines on the same OS image as CI; never loosen `precision` globally.

### Operational

- Local regen incantation: `SNAPSHOT_TESTING_RECORD=all swift test --filter VisualRegression`. Documented verbatim in `CONTRIBUTING.md` (Plan 23-05) and `.planning/codebase/TESTING.md` (Plan 23-05).
- CI never sets `SNAPSHOT_TESTING_RECORD`. The build-check workflow includes a guard step (Plan 23-04) that fails fast if the env var is set in CI -- prevents silent baseline overwrite.
- Reviewer responsibility: eyeball PNG diffs in PR when baselines change. Failed CI runs upload diff PNGs as `actions/upload-artifact` for download.

## References

- `.planning/phases/23-visual-regression-infra/23-CONTEXT.md` -- locked decisions D-01..D-08
- `.planning/phases/23-visual-regression-infra/23-RESEARCH.md` -- version verification (GitHub API), API surface verification (source inspection), pitfall analysis
- `.planning/phases/23-visual-regression-infra/23-PATTERNS.md` -- file-by-file analog mapping
- `https://github.com/pointfreeco/swift-snapshot-testing` -- library home
- `https://github.com/pointfreeco/swift-snapshot-testing/releases/tag/1.17.0` -- Swift Testing trait introduction (Beta)
- `https://github.com/pointfreeco/swift-snapshot-testing/releases/tag/1.19.0` -- attachment + `record:` parameter introduction
