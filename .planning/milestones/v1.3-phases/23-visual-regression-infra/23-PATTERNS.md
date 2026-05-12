# Phase 23: Visual Regression Infra - Pattern Map

**Mapped:** 2026-05-02
**Files analyzed:** 7 (3 to create, 4 to modify)
**Analogs found:** 6 / 7 (one greenfield item -- ADR -- has no in-repo analog)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `PSTranscribe/Tests/PSTranscribeTests/VisualRegressionTests.swift` | test (Swift Testing snapshot suite) | request-response (synchronous render -> bitmap compare) | `PSTranscribe/Tests/PSTranscribeTests/AppSettingsTests.swift` (`@Suite(.serialized)` shape, `@MainActor`, nested `@Suite`, defer cleanup) + `DictationLoggerTests.swift` (per-test temp-resource pattern, `Issue.record` for soft fails) | exact (role + data flow) |
| `PSTranscribe/Tests/PSTranscribeTests/SnapshotFixtures.swift` | test fixture / helper (stub builders + appearance helper) | request-response | `PSTranscribe/Tests/PSTranscribeTests/MockURLProtocol.swift` (file-level test helper, no `@Suite`, used by other tests) + `DictationLoggerTests.swift::tempDir()` + `defer` cleanup pattern (capture/restore shape) | exact (role: shared test helper) |
| `PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/*.png` | snapshot baseline assets (binary PNGs auto-generated on first record) | file-I/O | none (no precedent for binary test fixtures in repo) | no analog -- defaults from swift-snapshot-testing apply |
| `PSTranscribe/Package.swift` | dependency manifest | config | self (existing `dependencies:` array + `.testTarget` block at lines 8-29) | exact -- modify in place |
| `.github/workflows/build-check.yml` | CI workflow (PR gate) | event-driven (on: pull_request) | self (existing `swift build` step at lines 18-20) + `lint-summaries.yml` (path-filter precedent, NOT applied here per D-06) | exact -- extend in place |
| `.planning/codebase/TESTING.md` | doc (codebase intelligence) | n/a | self (current file -- contains stale "no test targets" claim from 2026-03-30 analysis) | exact -- refresh in place |
| `CONTRIBUTING.md` | doc (repo root) | n/a | none in repo (greenfield); shape derived from RESEARCH §"Local regen incantation" + Open Q #2 | no analog -- new file |
| `.planning/phases/23-visual-regression-infra/23-ADR-snapshot-framework.md` | ADR (Nygard-style) | n/a | none in repo (no `.planning/adr/` directory exists; first ADR in this codebase) | no analog -- new file |

## Pattern Assignments

### `PSTranscribe/Tests/PSTranscribeTests/VisualRegressionTests.swift` (test, snapshot)

**Primary analog:** `PSTranscribe/Tests/PSTranscribeTests/AppSettingsTests.swift`
**Secondary analog:** `PSTranscribe/Tests/PSTranscribeTests/DictationLoggerTests.swift`

**Imports pattern** (from `DictationLoggerTests.swift` lines 1-3 + `AppSettingsTests.swift` lines 1-3):

```swift
import Testing
import Foundation
@testable import PSTranscribe
```

For visual regression, this becomes:

```swift
import Testing
import SnapshotTesting   // NEW -- from swift-snapshot-testing
import SwiftUI
import AppKit
@testable import PSTranscribe
```

**Suite-declaration pattern** (from `AppSettingsTests.swift` lines 5-6 + `DictationLoggerTests.swift` lines 5-6):

```swift
@Suite("AppSettings v1.2 keys", .serialized)
struct AppSettingsTests {
```

```swift
@Suite("DictationLogger", .serialized)
struct DictationLoggerTests {
```

For visual regression, the suite needs `@MainActor` (NSHostingView + NSApp are MainActor) and `final class` (so init/deinit can capture+restore NSApp.appearance per RESEARCH Pattern 1):

```swift
@MainActor
@Suite("Visual Regression", .serialized, .snapshots(record: .missing))
final class VisualRegressionTests {
    private let originalAppearance: NSAppearance?
    init() { self.originalAppearance = NSApp.appearance }
    deinit { NSApp.appearance = originalAppearance }
}
```

Note: existing suites are `struct`. Visual regression switches to `final class` specifically because Swift Testing's setUp/tearDown migration requires `init`/`deinit` semantics (init replaces setUp, deinit replaces tearDown). `final class` is required for `deinit`.

**Per-test cleanup pattern** (from `AppSettingsTests.swift` lines 28-31):

```swift
@Test @MainActor func dictationHotkeyMode() {
    AppSettingsTests.clearV12Keys()
    defer { AppSettingsTests.clearV12Keys() }
    let s = AppSettings()
    #expect(s.dictationHotkeyMode == .toggle)
}
```

Apply this exact `defer { ... }` shape for NSApp.appearance restore in System tests:

```swift
@Test func contentViewSystem() {
    let prior = NSApp.appearance
    NSApp.appearance = NSAppearance(named: .aqua)
    defer { NSApp.appearance = prior }
    // ... build view, snapshot
}
```

**Per-test temp-resource pattern** (from `DictationLoggerTests.swift` lines 8-13 + 15-17):

```swift
private func tempDir() throws -> URL {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("DictationLoggerTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}

@Test func startSessionWritesHeader() async throws {
    let dir = try tempDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    // ...
}
```

Apply this for `LibraryStore` seeding in `SnapshotFixtures.stubLibraryStore()` -- per-test `temporaryDirectory.appendingPathComponent("VisRegLibrary-\(UUID().uuidString)")` so library.json never bleeds across tests.

**Soft-fail pattern** (from `DictationLoggerTests.swift` lines 45-46, 67-69):

```swift
guard let url else { Issue.record("endSession returned nil"); return }
```

```swift
guard let firstIdx = contents.range(of: "first")?.lowerBound,
      let secondIdx = contents.range(of: "second")?.lowerBound else {
    Issue.record("Could not find both appended utterances")
    return
}
```

Use for any precondition failure inside a snapshot test where you'd rather record a clear message than crash with a force-unwrap.

**Nested-suite pattern (optional structural choice)** (from `AppSettingsTests.swift` lines 26-62):

```swift
@Suite("defaults", .serialized)
struct Defaults {
    @Test @MainActor func dictationHotkeyMode() { ... }
    @Test @MainActor func clipboardRestoreDelay() { ... }
}
```

Available if the planner wants to group the 15 tests by surface (5 nested suites of 3 each) or by appearance (3 nested suites of 5 each). CONTEXT D-Discretion biases toward one flat suite; nested grouping is a fallback if file gets unwieldy.

---

### `PSTranscribe/Tests/PSTranscribeTests/SnapshotFixtures.swift` (test helper, no `@Suite`)

**Primary analog:** `PSTranscribe/Tests/PSTranscribeTests/MockURLProtocol.swift`

**File-level helper pattern** (from `MockURLProtocol.swift` lines 1-5 + 30-36):

```swift
import Foundation

/// URLProtocol subclass for injecting deterministic responses into URLSession code under test.
/// Per RESEARCH Pattern: URLProtocol mock.
final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responder: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    // ...
}

extension URLSession {
    static func mocked() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}
```

Apply this exact shape for `SnapshotFixtures.swift`: file-level `@MainActor enum SnapshotFixtures` with `static func` builders. No `@Suite` decoration; consumed by `VisualRegressionTests` via `SnapshotFixtures.stubAppSettings()` etc.

**Capture/restore-via-defer pattern** (synthesized from `DictationLoggerTests.swift::tempDir` cleanup at line 17):

```swift
defer { try? FileManager.default.removeItem(at: dir) }
```

For NSApp.appearance, `SnapshotFixtures` may expose a `withAppearance(_:body:)` closure helper:

```swift
@MainActor
static func withAppearance<R>(_ name: NSAppearance.Name?, body: () throws -> R) rethrows -> R {
    let prior = NSApp.appearance
    if let name { NSApp.appearance = NSAppearance(named: name) }
    defer { NSApp.appearance = prior }
    return try body()
}
```

This mirrors the `tempDir() + defer { remove }` shape: capture pre-state, mutate, restore in defer. Restoration happens even on throw.

**Imports pattern** (from `MockURLProtocol.swift` line 1):

```swift
import Foundation
```

For SnapshotFixtures (constructs SwiftUI views and AppKit appearances + production `@Observable` types):

```swift
import Foundation
import SwiftUI
import AppKit
@testable import PSTranscribe
```

---

### `PSTranscribe/Package.swift` (dependency manifest, modify)

**Self-analog -- in-place modification.** Existing dependencies array (lines 8-12):

```swift
dependencies: [
    .package(url: "https://github.com/FluidInference/FluidAudio.git", revision: "ea500621819cadc46d6212af44624f2b45ab3240"),
    .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.7.0"),
    .package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", from: "2.4.0"),
],
```

Existing test target (lines 24-28):

```swift
.testTarget(
    name: "PSTranscribeTests",
    dependencies: ["PSTranscribe"],
    path: "Tests/PSTranscribeTests"
),
```

**Pattern to apply** (per RESEARCH §"Standard Stack" Installation block):

1. Append to `dependencies:` array, matching the existing `from:` style used by Sparkle and KeyboardShortcuts:

```swift
.package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.19.2"),
```

2. Replace the test target `dependencies: ["PSTranscribe"]` shorthand with the explicit-product form (matching the executable target's existing style at lines 16-20):

```swift
.testTarget(
    name: "PSTranscribeTests",
    dependencies: [
        "PSTranscribe",
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
    ],
    path: "Tests/PSTranscribeTests"
),
```

NOTE -- RESEARCH calls out that CONTEXT D-01 says "v2.x" but no v2 exists. Pin is `from: "1.19.2"`. Planner / discuss-phase resolves the wording before lock.

---

### `.github/workflows/build-check.yml` (CI workflow, modify)

**Self-analog -- in-place extension.** Existing workflow (entire file, 20 lines):

```yaml
name: Build Check

on:
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: macos-26
    steps:
      - uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5  # v4

      - name: Select Xcode 26
        run: |
          sudo xcode-select -s /Applications/Xcode_26.app || sudo xcode-select -s /Applications/Xcode.app
          swift --version

      - name: Build
        working-directory: PSTranscribe
        run: swift build
```

**Pattern to apply** (per RESEARCH §"CI workflow extension"):

1. Add a top-level `env:` block under `jobs.build:` for `SNAPSHOT_ARTIFACTS`:

```yaml
jobs:
  build:
    runs-on: macos-26
    env:
      SNAPSHOT_ARTIFACTS: ${{ runner.temp }}/snapshot-failures
    steps:
```

2. Insert a record-mode guard step BEFORE the build step (so misconfiguration fails fast):

```yaml
      - name: Guard against snapshot record mode
        run: |
          if [ -n "$SNAPSHOT_TESTING_RECORD" ] && [ "$SNAPSHOT_TESTING_RECORD" != "never" ]; then
            echo "::error::SNAPSHOT_TESTING_RECORD is set to '$SNAPSHOT_TESTING_RECORD' -- refusing to run tests in CI to prevent silent baseline overwrite."
            exit 1
          fi
```

3. Add a `swift test` step AFTER the existing `swift build` step, mirroring its shape exactly (same `working-directory: PSTranscribe`):

```yaml
      - name: Test
        working-directory: PSTranscribe
        run: swift test
```

4. Add a failure-only artifact upload step at the end:

```yaml
      - name: Upload snapshot failure artifacts
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: snapshot-failures
          path: ${{ runner.temp }}/snapshot-failures/
          retention-days: 7
          if-no-files-found: ignore
```

**Cross-reference -- DO NOT apply path filter.** `lint-summaries.yml` lines 6-10 demonstrate the path-filter pattern (`paths: - '**/*-SUMMARY.md' ...`). CONTEXT D-06 explicitly rejects path filtering for build-check.yml: "No path filter -- the swift test step is cheap relative to the swift build already paid for". Reference for awareness only.

**Pinned-action pattern** (from existing line 11): `uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5  # v4`. The new `actions/upload-artifact@v4` may use the unpinned tag form (matches RESEARCH guidance + existing `lint-summaries.yml` style which uses `@v4` SHA pin only for checkout). Planner picks; SHA-pin is more secure but the codebase is mixed.

---

### `.planning/codebase/TESTING.md` (doc, refresh)

**Self-analog -- in-place refresh.** Current file is 309 lines, dated 2026-03-30, and contains stale claims. Specific stale lines:

- Line 7-10: "No test targets detected", "No test files in `Sources/Tome/`" -- both false as of Phase 17+
- Line 13-19: build-check.yml snippet uses `Tome` working-directory (rebrand was Phase 19)
- Line 264-280: full workflow snippet is the pre-rebrand `Tome` shape

**Pattern to apply** (per CONTEXT D-08 + RESEARCH VISREG-06):

1. Replace the "Current Status" / "No test targets detected" block with current state: 18+ test files in `PSTranscribe/Tests/PSTranscribeTests/`, Swift Testing framework, conventions documented.
2. Update the working-directory and rebrand from `Tome` -> `PSTranscribe` throughout.
3. Add a new section "## Visual Regression" with:
   - Surface roster (5 surfaces)
   - Appearance trio (Light/Dark/System)
   - Regen incantation: `SNAPSHOT_TESTING_RECORD=all swift test --filter VisualRegression`
   - Note that `SNAPSHOT_TESTING_RECORD` accepts `all | failed | missing | never` (NOT `true` -- per RESEARCH Pitfall #3)
   - Pointer to `CONTRIBUTING.md` for the developer-facing version

The doc is a reference, not code; format follows the existing TESTING.md prose style (markdown headings + fenced code blocks, no emojis per global rules).

---

### `CONTRIBUTING.md` (greenfield, repo root)

**No in-repo analog.** No existing CONTRIBUTING.md, no docs at repo root other than (assume) README. Shape derived from RESEARCH §"Local regen incantation" + Open Q #2.

**Pattern to apply** (greenfield, minimal):

```markdown
# Contributing

## Tests

Run the full test suite:

    cd PSTranscribe
    swift test

Run only the visual regression suite:

    swift test --filter VisualRegression

## Visual Regression Baselines

After a legitimate UI change, regenerate snapshot baselines locally:

    cd PSTranscribe
    SNAPSHOT_TESTING_RECORD=all swift test --filter VisualRegression

Then `git add` the changed PNGs under `Tests/PSTranscribeTests/__Snapshots__/` and include them in your PR. The reviewer eyeballs the diff.

The env var accepts `all | failed | missing | never` (not `true`).

CI never sets `SNAPSHOT_TESTING_RECORD`. The build-check workflow fails fast if it is set, to prevent silent baseline overwrite.
```

Per CONTEXT D-08, this doc is verbatim-canonical for the regen incantation. Planner may add additional sections (PR workflow, code style pointers, link to `.planning/codebase/`) at discretion.

---

### `.planning/phases/23-visual-regression-infra/23-ADR-snapshot-framework.md` (greenfield, ADR)

**No in-repo analog.** No `.planning/adr/` directory exists; this is the first ADR in the codebase. RESEARCH Open Q #2 recommends Nygard-style inline at the phase folder; CONTEXT Discretion confirms placement is planner's call.

**Pattern to apply** (Nygard shape, derived from adr.github.io templates):

```markdown
# ADR VISREG-01: Snapshot Testing Framework Choice

**Status:** Accepted (Phase 23, 2026-05-02)
**Context:** Phases 20 + 21 deferred automated visual regression. Strict-precision snapshot testing of 5 macOS surfaces × 3 appearances is needed to guard against silent appearance regressions.

## Decision

Use `pointfreeco/swift-snapshot-testing` (pin `from: "1.19.2"`) as a SwiftPM dependency on the `.testTarget("PSTranscribeTests")` only. Use the Swift Testing trait API (`@Suite(.snapshots(record:))`), not the XCTest assertion path.

## Alternatives Considered

1. **Custom XCTest + `cacheDisplay` + CGImage SHA-256 hash** -- rejected: hash equality is binary (no perceptual tolerance); D-02 locks `perceptualPrecision: 0.99` which requires a Delta-E implementation; no diff PNG output.
2. **`emergetools/snapshotpreviews`** -- rejected: iOS-first, less mature macOS coverage; D-01 explicitly locks swift-snapshot-testing.
3. **XCUITest screenshot pipeline** -- rejected: heavier infra, slower, more flake; CONTEXT.md `<deferred>`.

## Consequences

- Test target gains one external dependency.
- Production binary unchanged.
- Baseline PNGs committed under `__Snapshots__/`; ~750 KB total (no LFS).
- Strict precision (`1.0 / 0.99`) means legitimate UI changes always require a baseline regen.
- Regen via `SNAPSHOT_TESTING_RECORD=all swift test --filter VisualRegression`; CI guards against accidental record-mode.
```

Format is Nygard short-form (Status / Context / Decision / Alternatives / Consequences). Planner refines content; structure is the pattern.

---

## Shared Patterns

### Swift Testing `@Suite(.serialized)` for shared-state mutation

**Source:** `PSTranscribe/Tests/PSTranscribeTests/AppSettingsTests.swift` line 5 + `DictationLoggerTests.swift` line 5
**Apply to:** `VisualRegressionTests` (mutates NSApp.appearance, which is process-global)

```swift
@Suite("Visual Regression", .serialized)
```

Per RESEARCH Pitfall #8: `.serialized` only serializes WITHIN a suite. Cross-suite parallel risk is real but mitigated by `defer { NSApp.appearance = prior }` inside each test body.

### `@MainActor` annotation for view rendering

**Source:** `AppSettingsTests.swift` line 28 (`@Test @MainActor func dictationHotkeyMode()`)
**Apply to:** All snapshot test methods + `SnapshotFixtures` enum + `VisualRegressionTests` suite type

```swift
@MainActor
@Suite(...) final class VisualRegressionTests { ... }

@Test func contentViewLight() { ... }   // inherits @MainActor from suite
```

`NSHostingView` and `NSApp.appearance` are MainActor-isolated. Suite-level `@MainActor` propagates to all `@Test` methods.

### `defer` for state restoration

**Source:** `AppSettingsTests.swift` line 30 (`defer { AppSettingsTests.clearV12Keys() }`) + `DictationLoggerTests.swift` line 17 (`defer { try? FileManager.default.removeItem(at: dir) }`)
**Apply to:** Every test that mutates `NSApp.appearance` and every fixture that creates temp directories

Restoration via `defer` runs even on early throw or `Issue.record` -- this is the documented Swift Testing teardown primitive. Suite-level `init`/`deinit` is belt-and-suspenders only (per RESEARCH Pitfall #2).

### `@testable import PSTranscribe` for production-type access

**Source:** Every test file in `PSTranscribeTests/` (e.g. `DictationLoggerTests.swift` line 3, `AppSettingsTests.swift` line 3)
**Apply to:** `VisualRegressionTests.swift` and `SnapshotFixtures.swift`

```swift
@testable import PSTranscribe
```

Required to construct `AppSettings`, `LibraryStore`, `TranscriptStore`, `NotionService`, `SessionCoordinator`, `ModelUpdateService`, the 5 SUT views, and any internal initializers.

### `Issue.record` for soft-fail messaging

**Source:** `DictationLoggerTests.swift` lines 45, 67, 142
**Apply to:** Snapshot tests that have preconditions where a clear message is more useful than a crash

```swift
guard let url else { Issue.record("endSession returned nil"); return }
```

Useful in `SnapshotFixtures` if a stub builder returns nil unexpectedly.

### `working-directory: PSTranscribe` in CI steps

**Source:** `.github/workflows/build-check.yml` line 19
**Apply to:** Every new step in `build-check.yml` that runs SwiftPM (build, test)

```yaml
working-directory: PSTranscribe
run: swift test
```

The repo root contains `PSTranscribe/Package.swift` (NOT a top-level Package.swift). All `swift` invocations require the directory change.

## No Analog Found

| File | Role | Reason |
|------|------|--------|
| `__Snapshots__/VisualRegressionTests/*.png` | binary test fixtures | No precedent for committed binary fixtures in repo. swift-snapshot-testing's default file-naming + auto-generation handles this; planner does not author the PNGs. |
| `CONTRIBUTING.md` | repo-root contributor doc | Greenfield. Shape derived from RESEARCH §"Local regen incantation" + minimal-doc convention. |
| `23-ADR-snapshot-framework.md` | architectural decision record | First ADR in this codebase. Nygard-style template per RESEARCH Open Q #2; planner may promote `.planning/adr/` if more ADRs accumulate. |

## Metadata

**Analog search scope:**
- `PSTranscribe/Tests/PSTranscribeTests/*.swift` (18 files)
- `PSTranscribe/Package.swift`
- `.github/workflows/*.yml` (3 files: build-check, lint-summaries, release-dmg)
- `.planning/codebase/*.md` (TESTING, CONVENTIONS, STRUCTURE)

**Files scanned:** ~25 (test target listing + 6 file reads + targeted greps for analogs)

**Pattern extraction date:** 2026-05-02

**Key invariants for the planner / executor to preserve:**

1. **`final class` over `struct` for VisualRegressionTests** -- required for `init`/`deinit` capture+restore. Other suites in the repo use `struct`; this is the documented exception.
2. **`@Suite(.serialized)`** -- non-negotiable. NSApp.appearance is process-global; parallel execution within the suite would race.
3. **Per-test `defer` for NSApp.appearance restore** -- not just suite-level deinit. Pitfall #2.
4. **`working-directory: PSTranscribe` in every CI step** -- the SwiftPM root is nested.
5. **Strict precision `1.0 / 0.99`** -- D-02 lock. Per-test override only with documented justification in the test body comment.
6. **`SNAPSHOT_TESTING_RECORD` accepts `all | failed | missing | never`** -- NOT `true`. Documented verbatim in TESTING.md and CONTRIBUTING.md.
7. **CI guard step BEFORE build/test** -- fails fast if anyone sets the record env var via repo Variables/Secrets.

## PATTERN MAPPING COMPLETE
