# Phase 23: Visual Regression Infra - Research

**Researched:** 2026-05-02
**Domain:** Swift snapshot testing for SwiftUI on macOS, Swift Testing trait API, GitHub Actions test gating
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Snapshot library is `pointfreeco/swift-snapshot-testing` **v2.x** [see ⚠️ Critical Correction below]. Added as a SwiftPM dep on the `.testTarget("PSTranscribeTests")` only -- not on the executable target. Use the Swift Testing trait integration (`@Suite` / `@Test` compatible API), not the XCTest assertion path. Phase produces an ADR documenting trade-offs vs custom XCTest+CGImage hash and Swift Testing native compare (VISREG-01).
- **D-02:** Diff strictness is **strict**: `precision: 1.0`, `perceptualPrecision: 0.99`. Tightened only, never loosened, except for justified per-call overrides.
- **D-03:** Five surfaces get baselines: ContentView, LibrarySidebar, SettingsView, ControlBar, DictationHUD (HUD via `NSHostingView`, not the live `NSPanel`).
- **D-04:** One canonical frame size per surface, hard-coded via `.frame(width:height:)` on the test wrapper view. 5 × 3 = 15 baseline PNGs.
- **D-05:** Light = `.preferredColorScheme(.light)`; Dark = `.preferredColorScheme(.dark)`; System = `NSApp.appearance = NSAppearance(named: .aqua)` for the test duration, restored in teardown.
- **D-06:** Extend `.github/workflows/build-check.yml` with `swift test` step after `swift build`. Same `macos-26` runner. No new workflow.
- **D-07:** Baselines at `PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/`. No git LFS.
- **D-08:** Regen workflow doc lands in `.planning/codebase/TESTING.md` (refresh stale "no test targets" claim) AND `CONTRIBUTING.md` (does not currently exist; planner creates it).

### Claude's Discretion

- Test file structure: one suite (`VisualRegressionTests.swift`) vs split per-surface. Bias toward one suite.
- State injection for ContentView and LibrarySidebar: deterministic stub state per snapshot. Stubs may live in `SnapshotFixtures.swift` helper.
- NSApp.appearance restoration mechanics: `@Suite`-level `init`/`deinit` vs per-test `withAppearance(_:)` helper closure vs Swift Testing trait. Restoration in teardown is the hard rule.
- DictationHUD render path: how to extract the SwiftUI root from `DictationWindowController` or construct a parallel test-only `NSHostingView`.
- Snapshot file naming: default (`<TestName>.<index>.png`) or custom (e.g., `ContentView-light.png`).
- ADR location and shape: `.planning/adr/`, inline in `23-PLAN.md`, or a Phase 23 doc. No ADR directory exists yet.
- Frame width/height exact values: planner tunes against `WindowGroup` defaults.

### Deferred Ideas (OUT OF SCOPE)

- Inverse `.darkAqua` System variant (single `.aqua` direction sufficient)
- Multi-size variants per surface
- Snapshot tests for additional surfaces (TranscriptView, NotionTagSheet, OnboardingView, DetailsPane, CaptureDock, LibraryEntryRow)
- Pre-commit hook enforcement
- Git LFS
- XCUITest screenshot pipeline
- Marketing site visual regression
- WCAG / accessibility-mode visual regression
- Snapshot for the menu bar icon glyph (system-rendered)
- Multi-runner / multi-OS-version matrix
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| VISREG-01 | Choose snapshot framework + ADR | Standard Stack table + ADR location guidance below |
| VISREG-02 | Snapshot tests for 5 surfaces in Light appearance | API, fixture, and frame-sizing patterns below |
| VISREG-03 | Same surfaces in Dark appearance | `.preferredColorScheme(.dark)` pattern + Code Examples |
| VISREG-04 | System appearance (validates inheritance) | NSApp.appearance fixture pattern + Pitfall #4 |
| VISREG-05 | CI integration as PR-blocking gate | `build-check.yml` extension snippet + `actions/upload-artifact` integration |
| VISREG-06 | Document regen workflow in CONTRIBUTING / `.planning/codebase/` | Regen incantation + doc placement guidance |
</phase_requirements>

## Summary

This phase introduces snapshot testing to the PSTranscribe macOS app using `pointfreeco/swift-snapshot-testing`. The library has first-class Swift Testing trait support (since 1.17.0), a macOS `NSView`-based image strategy with `precision`/`perceptualPrecision`/`size` parameters that exactly match the user's locked tolerance shape, and a documented `SNAPSHOT_TESTING_RECORD` env var that accepts the four record modes (`all` / `failed` / `missing` / `never`). The library's macOS image rendering path uses `view.bitmapImageRepForCachingDisplay` + `cacheDisplay(in:to:)` — it does NOT involve an NSWindow, sidestepping the title-bar pixel-stealing CI flake described in the dev.to article (that flake is iOS-specific). All five in-scope surfaces (ContentView, LibrarySidebar, SettingsView, ControlBar, DictationHUD) are SwiftUI `View` structs that must be wrapped in `NSHostingView` before being fed to the `NSView` `.image` strategy. The library currently has NO direct `Snapshotting<SwiftUI.View, NSImage>` strategy on macOS — `NSHostingView` wrapping is the supported pattern.

⚠️ **Critical correction to D-01:** CONTEXT.md says "v2.x" but **no v2.x exists**. Latest released version is **1.19.2** (2026-03-30). Most recent v1 series releases: 1.19.0 (2026-03-18), 1.19.1 (2026-03-19), 1.19.2 (2026-03-30). Swift Testing trait support was added in **1.17.0** (Beta). Minimum viable version is `1.17.0`; recommended pin is `from: "1.19.2"` to get the explicit `record: Record?` parameter (1.19.0) and Swift Testing attachment support (1.19.0). The "v2.x" wording in CONTEXT.md needs to be reconciled before planning locks. [VERIFIED: github.com/pointfreeco/swift-snapshot-testing/releases via GitHub API 2026-05-02]

**Primary recommendation:** Pin `.package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.19.2")`. Use `import Testing` + `import SnapshotTesting` + `@Suite(.serialized, .snapshots(record: .missing))` + `assertSnapshot(of: NSHostingView(rootView: SUT()), as: .image(precision: 1.0, perceptualPrecision: 0.99, size: .init(width: W, height: H)))`. Wrap `NSApp.appearance` mutations in a `@MainActor` final-class suite with `init`/`deinit` for capture+restore. Set `SNAPSHOT_ARTIFACTS=$RUNNER_TEMP/snapshot-failures` in the CI workflow and upload that path with `actions/upload-artifact` on test-step failure. Guard CI against accidental record mode by failing the build if `$SNAPSHOT_TESTING_RECORD` is set in the runner env.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| SwiftUI view rendering for snapshot | View / SwiftUI | AppKit (`NSHostingView`) | View tier owns display; AppKit hosting is required to feed the macOS `NSView` image strategy |
| Pixel comparison + tolerance | Test target (SnapshotTesting library) | — | Single-purpose library, owns image diffing |
| Stub state injection (AppSettings, LibraryStore, TranscriptStore) | Test target | Models / Settings / Storage tier | Tests construct in-memory instances of production `@Observable`/`actor` types via `@testable import` |
| App-wide appearance override | AppKit (`NSApp.appearance`) | SwiftUI environment | NSApp.appearance is the AppKit primitive Phase 21 D-07 already uses for the HUD panel — same primitive, applied app-wide for tests |
| CI test execution | GitHub Actions (`macos-26`) | SwiftPM (`swift test`) | Same runner as build-check, no new infra |
| Failure artifact surfacing | GitHub Actions (`upload-artifact`) | SnapshotTesting (`SNAPSHOT_ARTIFACTS` env) | Library writes diff PNGs to a configurable path; CI uploads them for human review |
| Regen workflow | Developer-local (`SNAPSHOT_TESTING_RECORD=missing` swift test) | — | Local-only, never CI |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `pointfreeco/swift-snapshot-testing` | `from: "1.19.2"` (latest 2026-03-30) | SwiftUI/NSView snapshot diffing with Swift Testing trait support | De-facto standard for Apple-platform snapshot testing; PointFree maintainers also maintain swift-syntax integration; first-class Swift Testing support since 1.17.0 (2024-09); macOS NSView image strategy precisely matches the locked precision/perceptualPrecision/size shape [VERIFIED: github.com/pointfreeco/swift-snapshot-testing release tags via GitHub API 2026-05-02] |

### Supporting

None — Apple platform built-ins (`Testing`, `SwiftUI`, `AppKit`, `Foundation`) cover everything else. No fixture-helper dependency needed; the test target writes its own `SnapshotFixtures.swift`.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `swift-snapshot-testing` | `emergetools/snapshotpreviews` | Snapshot Previews integrates Xcode `#Preview` blocks with auto-discovery and gallery generation. **Rejected for Phase 23** because: (a) the user has explicitly locked swift-snapshot-testing in D-01, and (b) it's iOS-first with less mature macOS coverage. Worth noting as a future option if `#Preview`-driven snapshot coverage becomes desirable. [VERIFIED: ctx7 library catalog 2026-05-02] |
| `swift-snapshot-testing` | Custom XCTest + `cacheDisplay` + CGImage SHA-256 hash | Lighter dependency footprint; no third-party. **Rejected** because hash equality is binary (no perceptual tolerance), no diff PNG output for review, no Swift Testing trait integration, and the maintenance burden of a hand-rolled diffing pipeline isn't worth dodging one well-maintained dep. The ADR (VISREG-01) should record this comparison. |
| `swift-snapshot-testing` | XCUITest screenshot pipeline | Captures the actual rendered app via UI automation; catches AppKit-level regressions (e.g. NSPanel chrome). **Rejected** in CONTEXT.md `<deferred>` — heavier infra, slower, more flake. |

**Installation:**

```swift
// PSTranscribe/Package.swift
dependencies: [
    .package(url: "https://github.com/FluidInference/FluidAudio.git", revision: "ea500621819cadc46d6212af44624f2b45ab3240"),
    .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.7.0"),
    .package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", from: "2.4.0"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.19.2"),  // NEW
],
targets: [
    .executableTarget(
        name: "PSTranscribe",
        dependencies: [ ... ],  // unchanged
        ...
    ),
    .testTarget(
        name: "PSTranscribeTests",
        dependencies: [
            "PSTranscribe",
            .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),  // NEW
        ],
        path: "Tests/PSTranscribeTests"
    ),
]
```

**Version verification:** As of 2026-05-02 the latest release is **1.19.2** published 2026-03-30 [VERIFIED: GitHub API `releases?per_page=8` returned `1.19.2 - 2026-03-30T18:35:12Z` as topmost entry]. Recent history: 1.18.7 (2025-09-17), 1.18.8 (2026-01-28), 1.18.9 (2026-01-29), 1.19.0 (2026-03-18), 1.19.1 (2026-03-19), 1.19.2 (2026-03-30). The library moves quickly inside the 1.x line; minimum required for Swift Testing trait API is 1.17.0 (Beta added 2024-09 per the 1.17.0 release notes [VERIFIED]).

## Architecture Patterns

### System Architecture Diagram

```
                    ┌──────────────────────────────────────────────────────┐
                    │            VisualRegressionTests Suite                │
                    │  (@Suite(.serialized, .snapshots(record: .missing)))  │
                    └──────────────────────────────────────────────────────┘
                                            │
                ┌───────────────────────────┼───────────────────────────┐
                │                           │                           │
                ▼                           ▼                           ▼
       ┌──────────────────┐       ┌──────────────────┐         ┌──────────────────┐
       │  init() captures  │       │  @Test methods    │         │  deinit restores  │
       │  NSApp.appearance │       │  (one per         │         │  NSApp.appearance │
       │  (initial state)  │       │   surface×appear) │         │  to captured val  │
       └──────────────────┘       └──────────────────┘         └──────────────────┘
                                            │
                                            ▼
                                  ┌──────────────────────┐
                                  │  SnapshotFixtures     │
                                  │  - stubAppSettings()  │
                                  │  - stubTranscriptStore│
                                  │  - stubLibraryStore() │
                                  │  - withAppearance()   │
                                  └──────────────────────┘
                                            │
                                            ▼
                              ┌──────────────────────────────┐
                              │  SUT View (production type)   │
                              │  ContentView / LibrarySidebar │
                              │  SettingsView / ControlBar /  │
                              │  DictationHUD                 │
                              └──────────────────────────────┘
                                            │
                                            ▼
                              ┌──────────────────────────────┐
                              │  .frame(width: W, height: H)  │
                              │  .preferredColorScheme(...)   │  ← Light/Dark only
                              └──────────────────────────────┘
                                            │
                                            ▼
                              ┌──────────────────────────────┐
                              │  NSHostingView(rootView:)     │
                              │  + .frame override            │
                              │  + layout pass                │
                              └──────────────────────────────┘
                                            │
                                            ▼
                          ┌─────────────────────────────────────┐
                          │  assertSnapshot(of: hostingView,    │
                          │    as: .image(precision: 1.0,       │
                          │               perceptualPrecision:  │
                          │                 0.99,               │
                          │               size: .init(W, H)))   │
                          └─────────────────────────────────────┘
                                            │
                       ┌────────────────────┼────────────────────┐
                       │                    │                    │
                       ▼                    ▼                    ▼
              ┌──────────────┐    ┌──────────────────┐  ┌──────────────────┐
              │ FIRST RUN:    │    │ SUBSEQUENT RUN:   │  │ DIFF FAILURE:    │
              │ writes baseline│    │ pixel compares    │  │ writes failed PNG│
              │ to             │    │ against baseline  │  │ to               │
              │ __Snapshots__/ │    │                   │  │ $SNAPSHOT_       │
              │                │    │                   │  │ ARTIFACTS/       │
              └──────────────┘    └──────────────────┘  └──────────────────┘
                                                                  │
                                                                  ▼
                                                        ┌──────────────────┐
                                                        │  CI: actions/    │
                                                        │  upload-artifact │
                                                        │  on failure      │
                                                        └──────────────────┘
```

### Recommended Project Structure

```
PSTranscribe/
├── Package.swift                                # +1 dependency, +1 testTarget dependency
├── Tests/
│   └── PSTranscribeTests/
│       ├── VisualRegressionTests.swift          # NEW — single suite, 15 @Test methods
│       ├── SnapshotFixtures.swift               # NEW — stub builders + appearance helpers
│       └── __Snapshots__/                       # NEW — auto-created on first run
│           └── VisualRegressionTests/
│               ├── contentViewLight.1.png
│               ├── contentViewDark.1.png
│               ├── contentViewSystem.1.png
│               ├── librarySidebarLight.1.png
│               ├── ... (12 more)
└── ...
```

(Default naming: `<TestName>.<index>.png`. If the planner picks descriptive `named:` per assertion, the file becomes `<sanitized-name>.png`.)

### Pattern 1: Swift Testing Suite with Snapshot Trait

**What:** Single `@Suite` that scopes record mode and serialization for all 15 visual regression tests.
**When to use:** Any time mutating shared global state (NSApp.appearance) across multiple tests in a Swift Testing context.
**Example:**

```swift
// Source: github.com/pointfreeco/swift-snapshot-testing README + MigratingTo1.17.md (verified via ctx7 docs)
import Testing
import SnapshotTesting
import SwiftUI
import AppKit
@testable import PSTranscribe

/// VISREG-02..04: snapshot 5 surfaces × 3 appearances.
///
/// `.serialized` because the System tests mutate NSApp.appearance, which is
/// process-global. Without serialization, parallel-running tests in other
/// suites could observe a transient `.aqua` override at random.
///
/// `.snapshots(record: .missing)` is the default-safe mode: writes a baseline
/// the first time a test runs (no baseline file on disk), fails on diff
/// thereafter. Override locally with `SNAPSHOT_TESTING_RECORD=all` env var
/// to regenerate baselines after a legitimate UI change.
@MainActor
@Suite("Visual Regression", .serialized, .snapshots(record: .missing))
final class VisualRegressionTests {
    // Capture original NSApp.appearance at suite construction so each test
    // restoration is a no-op when no test in the suite mutated it.
    private let originalAppearance: NSAppearance?

    init() {
        self.originalAppearance = NSApp.appearance
    }

    deinit {
        // Idempotent restore. Swift Testing instantiates one instance per @Test,
        // so deinit fires after every test method. Tests that mutated
        // NSApp.appearance MUST set it back to nil/originalAppearance INSIDE
        // their body's defer — this deinit is belt-and-suspenders.
        NSApp.appearance = originalAppearance
    }

    // ... @Test methods below
}
```

### Pattern 2: SwiftUI → NSHostingView → snapshot for macOS

**What:** Wrap a SwiftUI view in `NSHostingView` so it can be fed to the macOS `Snapshotting<NSView, NSImage>.image` strategy.
**When to use:** **Always** on macOS. swift-snapshot-testing has no direct `Snapshotting<SwiftUI.View, NSImage>` for macOS; only iOS/tvOS have a `Snapshotting<SwiftUI.View, UIImage>.image(layout:traits:...)` direct strategy. [VERIFIED: source inspection of `Sources/SnapshotTesting/Snapshotting/SwiftUIView.swift` showed only `#if os(iOS) || os(tvOS)` block]
**Example:**

```swift
// Source: github.com/pointfreeco/swift-snapshot-testing — Sources/SnapshotTesting/Snapshotting/NSView.swift
//   + dev.to/d4g4/our-swiftui-snapshot-tests-passed-locally-but-failed-on-ci pattern
@MainActor
private func snapshot<V: View>(
    _ view: V,
    width: CGFloat,
    height: CGFloat,
    name: String,
    fileID: StaticString = #fileID,
    file: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line
) {
    let host = NSHostingView(rootView: view.frame(width: width, height: height))
    host.frame = NSRect(x: 0, y: 0, width: width, height: height)
    // Force a layout pass before the snapshot strategy reads bitmap. NSHostingView
    // lays out lazily; without this the first render can clip or use defaults.
    host.layoutSubtreeIfNeeded()
    assertSnapshot(
        of: host,
        as: .image(
            precision: 1.0,
            perceptualPrecision: 0.99,
            size: CGSize(width: width, height: height)
        ),
        named: name,
        fileID: fileID,
        file: file,
        testName: testName,
        line: line
    )
}
```

### Pattern 3: System appearance override with restore

**What:** Mutate `NSApp.appearance` for one test's duration, restore in `defer`. Avoids `init`/`deinit` lifecycle ambiguity for cross-test bleed-over.
**When to use:** Any `@Test` for the System appearance variant.
**Example:**

```swift
// Source: derived from Phase 21 DictationWindowController.applyAppearance pattern
//   (PSTranscribeApp.swift line 357-361) — same NSAppearance(named:) primitive.
@Test @MainActor func contentViewSystem() {
    let prior = NSApp.appearance
    NSApp.appearance = NSAppearance(named: .aqua)  // D-05: pin to Aqua for inheritance verification
    defer { NSApp.appearance = prior }
    let view = ContentView(
        settings: SnapshotFixtures.stubAppSettings(),
        notionService: SnapshotFixtures.stubNotionService(),
        libraryStore: SnapshotFixtures.stubLibraryStore(seedEntries: 3),
        sessionCoordinator: SnapshotFixtures.stubSessionCoordinator(),
        modelUpdateService: SnapshotFixtures.stubModelUpdateService(),
        saveDestinations: SnapshotFixtures.stubSaveDestinations()
    )
    // NOTE: NO .preferredColorScheme modifier here. Validates that the view
    // resolves colorScheme from NSApp.effectiveAppearance when no explicit
    // override exists (D-05).
    snapshot(view, width: 1100, height: 700, name: "ContentView-System")
}
```

### Pattern 4: Stub state via Claude's Discretion fixtures

**What:** Construct in-memory instances of production `@Observable` and `actor` types directly from `@testable import PSTranscribe`.
**When to use:** Any view that depends on `AppSettings`, `LibraryStore`, `TranscriptStore`, etc.
**Example:**

```swift
// Source: derived from PSTranscribe production types (AppSettings.swift, LibraryStore.swift,
//   TranscriptStore.swift verified during research)
@MainActor
enum SnapshotFixtures {
    /// Default AppSettings — all UserDefaults-backed properties read from the live
    /// UserDefaults. To avoid bleed, tests must clean up afterward (the existing
    /// AppSettingsTests pattern uses defer + UserDefaults.standard.removeObject).
    /// For visual regression a clean-default AppSettings is appropriate; the snapshot
    /// is testing the rendered UI, not the persistence layer.
    static func stubAppSettings() -> AppSettings {
        // Pre-clear the keys this view actually reads to avoid prior-test contamination.
        for key in ["appearancePreference", "localFileEnabled", "localFileRoot",
                    "obsidianEnabled", "obsidianFolderPath", "notionDatabaseID"] {
            UserDefaults.standard.removeObject(forKey: key)
        }
        return AppSettings()
    }

    /// LibraryStore with a deterministic 3-entry seed (CONTEXT.md Claude's Discretion).
    /// Uses a temp directory so the library.json doesn't pollute the user's app
    /// support dir during test runs.
    static func stubLibraryStore(seedEntries: Int = 3) async -> LibraryStore {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("VisRegLibrary-\(UUID().uuidString)", isDirectory: true)
        let store = LibraryStore(directory: tmp)
        for i in 0..<seedEntries {
            await store.addEntry(LibraryEntry(
                id: UUID(),
                name: "Snapshot Entry \(i)",
                sessionType: i % 2 == 0 ? .callCapture : .voiceMemo,
                startDate: Date(timeIntervalSince1970: 1_700_000_000 + Double(i * 3600)),
                duration: TimeInterval(120 + i * 60),
                filePath: "",
                sourceApp: "Test",
                isFinalized: true,
                firstLinePreview: "Sample preview \(i)"
            ))
        }
        return store
    }

    // ... stubNotionService, stubSessionCoordinator, stubModelUpdateService,
    //     stubSaveDestinations follow the same shape: production types,
    //     deterministic state, temp-dir storage.
}
```

⚠️ **LibraryStore is an `actor`** (Storage/LibraryStore.swift line 4). All access from `@MainActor` test bodies requires `await`. The fixture's `stubLibraryStore` is `async`. For tests that need a `LibraryStore` parameter to pass into a SwiftUI view's `init(...)`, the test method must be `async` and `await` the fixture before constructing the view.

### Anti-Patterns to Avoid

- **Wrapping in `NSWindow` for snapshot:** Several internet examples for older swift-snapshot-testing versions wrap the SwiftUI view in an NSWindow before snapshotting. **Don't.** The macOS `NSView.image` strategy goes directly through `bitmapImageRepForCachingDisplay` + `cacheDisplay(in:to:)` — adding an NSWindow introduces title-bar chrome that varies between physical Macs and CI VMs (the dev.to article's CI flake is exactly this pattern). [VERIFIED: source inspection of NSView.swift confirmed no NSWindow involvement]
- **Skipping `layoutSubtreeIfNeeded()`:** `NSHostingView` lays out lazily. Snapshotting before layout completes can produce clipped or default-sized first-run baselines. Force a layout pass before `assertSnapshot`.
- **Using `record: .all` in CI:** CI must NEVER set `SNAPSHOT_TESTING_RECORD=all` (would silently overwrite baselines, masking the regression the gate exists to catch). Add a step that fails the build if the env var is set.
- **Putting NSApp.appearance restore in `init`/`deinit` only:** Swift Testing creates a fresh suite instance per @Test method, so `init` fires per test and `deinit` fires after. That's correct *in principle*, but if a test body throws between mutating NSApp.appearance and the next safe point, `deinit` may run before SwiftUI observers settle. Use `defer` inside the test body for the actual mutate+restore pair; treat suite-level `init`/`deinit` as safety net only.
- **Hardcoding `precision: 0.95` because "CI flakes are easier than fixing them":** D-02 locks 1.0. Loosening tolerance defeats the entire phase. Per-test overrides allowed only with documented justification recorded in the test body comment.
- **Letting `NSHostingView<AnyView>` infer through:** The production HUD path uses `NSHostingView<AnyView>` (DictationWindowController.swift:99) for runtime polymorphism. Tests should use `NSHostingView<SomeView>` with the concrete view type to avoid AnyView's known type-erasure perf and SwiftUI invalidation quirks.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Pixel-by-pixel image comparison | A custom CGImage SHA-256 hash compare | `swift-snapshot-testing`'s `.image(precision:perceptualPrecision:)` | Hash equality is binary; perceptual precision uses [Delta-E](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e) which mirrors human eye sensitivity. The 0.99 lock in D-02 is meaningless without a Delta-E implementation behind it. |
| Diff PNG generation on test failure | A custom Python/sips post-test script | swift-snapshot-testing's built-in `verifySnapshot` writes failure diffs to `$SNAPSHOT_ARTIFACTS` automatically | Writing a side-car diff pipeline is a multi-day commitment; the library does it for free in 0.5s |
| Swift Testing fixture macros | A custom `@TestFixture` macro | Init/deinit on a class-shaped suite + `defer` inside test bodies | Swift Testing's documented setup/teardown migration path from XCTest is `init` (replaces `setUp`) + `deinit` (replaces `tearDown`); no extra abstraction needed. [VERIFIED: ctx7 swift-testing MigratingFromXCTest doc] |
| Record-mode CLI flag | A `--record` argument or wrapper script | The library's `SNAPSHOT_TESTING_RECORD` env var | Already implemented since 1.17.0; documenting `SNAPSHOT_TESTING_RECORD=all swift test --filter VisualRegression` is the entire developer surface |
| Diff PNG attachments to PR comments | A bot that comments diff images on PRs | `actions/upload-artifact` step uploading `$SNAPSHOT_ARTIFACTS` | GitHub Actions UI surfaces artifacts on failed runs; reviewer downloads ZIP. Phase 23 doesn't need PR-comment automation. |

**Key insight:** swift-snapshot-testing has been the de-facto standard since 2019. Every requirement Phase 23 has — Swift Testing trait, macOS NSView image, perceptual precision, env-var record mode, automatic diff PNG output, XCTest attachment, Swift Testing attachment — is a built-in feature, not something to wrap or extend. The phase reduces to "configure the dependency and write 15 tests."

## Runtime State Inventory

This is a **greenfield phase** (adds new tests + CI step + docs). No rename / refactor / migration / data-state mutation involved. Section omitted.

## Common Pitfalls

### Pitfall 1: Layout pass not forced on NSHostingView

**What goes wrong:** `assertSnapshot` runs before SwiftUI lays out, producing a clipped or default-sized image that becomes the (wrong) baseline.
**Why it happens:** `NSHostingView` lays out lazily on the next run-loop tick. The snapshot strategy reads bitmap state immediately.
**How to avoid:** Call `host.layoutSubtreeIfNeeded()` after constructing the hosting view and before `assertSnapshot`. See Pattern 2.
**Warning signs:** First-run baselines look cropped or wrong-sized; baseline regen on a different machine produces a visually different image at the same configured frame.

### Pitfall 2: NSApp.appearance bleed across tests

**What goes wrong:** Test A (System variant) sets `NSApp.appearance = NSAppearance(named: .aqua)`, throws or exits early, never restores. Test B (Light variant) inherits the override, snapshot looks correct *for the wrong reason*.
**Why it happens:** `NSApp.appearance` is process-global. Swift Testing's suite `deinit` fires after the test body, so `defer` inside the test body is the right primitive — it runs even on early throw or `Issue.record`.
**How to avoid:** Always pair `NSApp.appearance = NSAppearance(named: .aqua)` with `defer { NSApp.appearance = prior }` *in the test body*, where `let prior = NSApp.appearance` was captured one line above. Suite `deinit` is belt-and-suspenders only.
**Warning signs:** A test passes when run alone, fails when run as part of the full suite (or vice versa).

### Pitfall 3: Confusing `record: .missing` vs `.never`

**What goes wrong:** Developer regenerates a baseline locally with `SNAPSHOT_TESTING_RECORD=missing swift test`, expecting all baselines to be rewritten. Only newly-added tests get baselines; existing ones are unchanged.
**Why it happens:** `.missing` (the default and the recommended trait setting) only writes a baseline when none exists on disk. To rewrite an existing baseline, the regen incantation is `SNAPSHOT_TESTING_RECORD=all swift test --filter VisualRegression`. [VERIFIED: source `__record` default in AssertSnapshot.swift]
**How to avoid:** Document the regen command verbatim as `SNAPSHOT_TESTING_RECORD=all swift test --filter VisualRegression` in TESTING.md and CONTRIBUTING.md. Note that the env var accepts `all | failed | missing | never`, NOT `true`.
**Warning signs:** Developer reports "I ran with record but it didn't update the baseline."

### Pitfall 4: System appearance picker change races

**What goes wrong:** Snapshot test for the System variant runs while user (or a prior test) flipped macOS system appearance dark in System Settings; baseline is captured Dark, expecting Aqua.
**Why it happens:** D-05's `NSApp.appearance = NSAppearance(named: .aqua)` overrides the *app's* appearance independent of the system. But if a test mistakenly skips the override (e.g. uses `nil`), the result depends on the host machine's current system appearance.
**How to avoid:** The System variant ALWAYS sets `NSApp.appearance = NSAppearance(named: .aqua)`. Never `nil`, never reading current system. CI runners default to Aqua but production developers may have Dark on. Make the override explicit in every System test.
**Warning signs:** System-variant baseline looks Dark on one machine and Light on another after regen.

### Pitfall 5: Strict precision flake on macos-26 runner

**What goes wrong:** CI fails with a 0.999 pixel match against a baseline regenerated locally, despite no UI change.
**Why it happens:** Most likely cause on macOS (NOT iOS) is font-rendering subpixel differences between developer hardware and the GitHub Actions runner image, or a macOS minor-version difference between baseline and CI run. The dev.to article's NSWindow-title-bar issue does NOT apply (macOS NSView strategy doesn't use NSWindow). [VERIFIED: NSView.swift source]
**How to avoid:**
1. Always regenerate baselines from the same OS image as CI (`macos-26`) — easiest path is to commit a `Makefile` or shell script that's runnable on a self-hosted macos-26 machine, or accept that local regen + CI verification is the workflow.
2. Don't loosen `precision: 1.0` globally. Per-test escape hatch only with comment.
3. If a specific surface flakes repeatedly, document it in the test body and consider tightening the canonical frame to avoid the flake-prone area (e.g. animated content).
4. Phase 23 ships with a Light/Dark/System matrix; if one variant is flake-prone the planner can `.disabled("flaky on CI - see #issue")` it pending repro.
**Warning signs:** Same baseline file passes locally, fails on CI repeatedly. `sips -g pixelWidth -g pixelHeight` on baseline vs failure PNG produces same dimensions (rules out structural mismatch).

### Pitfall 6: LibraryStore actor + sync View init mismatch

**What goes wrong:** Test calls `ContentView(libraryStore: SnapshotFixtures.stubLibraryStore(...))` — but `stubLibraryStore` is `async` because `addEntry` is on an actor.
**Why it happens:** `LibraryStore` is `actor` (Storage/LibraryStore.swift:4); seeding entries requires `await`. SwiftUI view inits are synchronous.
**How to avoid:** Test methods that need a seeded LibraryStore must be `@Test @MainActor func name() async`. Build the store first, then construct the view. See Pattern 4 fixture shape.
**Warning signs:** Compile error: "Expression is 'async' but is not marked with 'await'."

### Pitfall 7: View depends on services with side effects (Notion API, models)

**What goes wrong:** ContentView snapshot runs against a `NotionService` that tries to reach api.notion.com on `init`, hangs, exceeds the 5-second snapshot timeout.
**Why it happens:** Production services may auto-validate on construction; SwiftUI views may kick off `.task { await modelUpdate.checkForUpdate(force: false) }` (PSTranscribeApp.swift:312-315). Snapshots render briefly but don't wait for `.task` to settle, so the snapshot captures the pre-task state.
**How to avoid:** Stub services pass an empty Keychain/no API key (as the production type already handles a nil key gracefully). For ContentView snapshots, the SwiftUI `.task` modifiers fire on appear but the snapshot is taken immediately after the layout pass — typically before any network IO completes. This is fine for a snapshot test (we want the resting visual state).
**Warning signs:** Test takes >2 seconds; spurious diffs between runs.

### Pitfall 8: `@Suite(.serialized)` doesn't serialize across DIFFERENT suites

**What goes wrong:** VisualRegressionTests is `.serialized`, but other test suites (e.g. AppSettingsTests, also `.serialized`) run in parallel against the same NSApp + UserDefaults. NSApp.appearance mutation in VisualRegressionTests is visible to AppSettingsTests running in parallel.
**Why it happens:** `.serialized` only serializes WITHIN a suite. Across suites, parallel execution still happens (this is also why DictationLoggerTests' actor-based test mutates `/tmp/...-UUID` per test — to avoid parallel-suite collision).
**How to avoid:**
1. The NSApp.appearance restore via `defer` mitigates intra-suite bleed.
2. Cross-suite bleed is a real risk. If observed, the planner can either move all UI-state-touching tests into one mega-suite, or explore Swift 6.1+ `TestScoping` traits if available, or accept the risk and document.
3. The existing test base already touches UserDefaults across suites (AppSettingsTests, AppSettingsDestinationPersistenceTests — see DictationLoggerTests file for the existing `.serialized` pattern).
**Warning signs:** Intermittent unrelated failures in other test suites when VisualRegressionTests runs.

## Code Examples

Verified patterns from official sources:

### Snapshot a SwiftUI view on macOS

```swift
// Source: github.com/pointfreeco/swift-snapshot-testing — README + NSView.swift
// (verified via direct source inspection of main branch 2026-05-02)
import Testing
import SnapshotTesting
import SwiftUI
import AppKit
@testable import PSTranscribe

@MainActor
@Suite("Visual Regression", .serialized, .snapshots(record: .missing))
final class VisualRegressionTests {
    @Test func contentViewLight() {
        let view = ContentView(/* stub args */)
            .preferredColorScheme(.light)
            .frame(width: 1100, height: 700)
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(x: 0, y: 0, width: 1100, height: 700)
        host.layoutSubtreeIfNeeded()
        assertSnapshot(
            of: host,
            as: .image(precision: 1.0, perceptualPrecision: 0.99,
                       size: CGSize(width: 1100, height: 700)),
            named: "ContentView-Light"
        )
    }
}
```

### Configure record mode at suite level

```swift
// Source: github.com/pointfreeco/swift-snapshot-testing/blob/main/Sources/.../MigratingTo1.17.md
// (verified via ctx7 docs)
@Suite(.snapshots(record: .failed, diffTool: .ksdiff))
struct FeatureTests {
    @Test func myTest() {
        // Records ONLY when there's already a baseline AND the snapshot fails.
        // Useful for "show me what the new render looks like" without overwriting
        // unmodified baselines.
    }

    @Test(.snapshots(record: .all))
    func myExperimentalTest() {
        // Per-test override: always record.
    }
}
```

### CI workflow extension (canonical shape)

```yaml
# Source: extension of existing .github/workflows/build-check.yml shape
# (verified by reading the existing workflow 2026-05-02)
name: Build Check

on:
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: macos-26
    env:
      # Forward the artifacts dir to a known runner-temp path so we can upload it.
      SNAPSHOT_ARTIFACTS: ${{ runner.temp }}/snapshot-failures
    steps:
      - uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5  # v4

      - name: Select Xcode 26
        run: |
          sudo xcode-select -s /Applications/Xcode_26.app || sudo xcode-select -s /Applications/Xcode.app
          swift --version

      # NEW — guard against accidental record mode in CI environment.
      # If anyone defines SNAPSHOT_TESTING_RECORD=all via repo Variables/Secrets
      # by mistake, this step fails fast and prevents a silent baseline overwrite.
      - name: Guard against snapshot record mode
        run: |
          if [ -n "$SNAPSHOT_TESTING_RECORD" ] && [ "$SNAPSHOT_TESTING_RECORD" != "never" ]; then
            echo "::error::SNAPSHOT_TESTING_RECORD is set to '$SNAPSHOT_TESTING_RECORD' — refusing to run tests in CI to prevent silent baseline overwrite."
            exit 1
          fi

      - name: Build
        working-directory: PSTranscribe
        run: swift build

      # NEW — run tests including the snapshot suite.
      - name: Test
        working-directory: PSTranscribe
        run: swift test

      # NEW — upload diff PNGs on failure for human review in PR.
      - name: Upload snapshot failure artifacts
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: snapshot-failures
          path: ${{ runner.temp }}/snapshot-failures/
          retention-days: 7
          if-no-files-found: ignore
```

### Local regen incantation (developer-facing)

```bash
# Source: derived from swift-snapshot-testing's __record default in AssertSnapshot.swift
#   (env var read via ProcessInfo.processInfo.environment["SNAPSHOT_TESTING_RECORD"])
# To regenerate ALL baselines after a legitimate UI change:
SNAPSHOT_TESTING_RECORD=all swift test --filter VisualRegression

# To regenerate ONLY missing baselines (e.g. after adding a new @Test):
SNAPSHOT_TESTING_RECORD=missing swift test --filter VisualRegression
# (this is the default mode; running without the env var has the same effect)

# To run tests WITHOUT recording (CI shape — never overwrite, fail on miss):
SNAPSHOT_TESTING_RECORD=never swift test --filter VisualRegression
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `assertSnapshot(matching:as:)` | `assertSnapshot(of:as:)` | swift-snapshot-testing 1.12.0 (2023) | Old `matching:` is soft-deprecated but still works. Use `of:` in all new code. |
| Global `isRecording = true` | `withSnapshotTesting(record: .all) { ... }` or `@Suite(.snapshots(record: .all))` | 1.17.0 (2024-09) | Setting `isRecording` is deprecated. The new API exposes 4 modes (`.all`, `.failed`, `.missing`, `.never`) and is task-local rather than process-global. |
| Manual setUp/tearDown via XCTestCase | `init()` + `deinit` on a class-shaped Swift Testing suite | swift-testing 1.0 (2024) | New suites use init/deinit; XCTest setUp/tearDown is XCTest-only. |
| `SNAPSHOT_TESTING_RECORD=true` (folk wisdom) | `SNAPSHOT_TESTING_RECORD=all` (or `failed`/`missing`/`never`) | 1.17.0 explicitly added env-var support | The env var only accepts the four documented record modes. `true` is a no-op. [VERIFIED: __record initializer in AssertSnapshot.swift parses the env var via `Record(rawValue:)` which only handles those four strings.] |
| Snapshot via NSWindow wrapping | Snapshot via direct `NSHostingView` cacheDisplay | Always (macOS NSView strategy never used NSWindow) | The NSWindow-title-bar CI flake described in the dev.to article is iOS/UIKit-specific. macOS path is unaffected. |

**Deprecated/outdated:**

- The CONTEXT.md reference to "v2.x" of swift-snapshot-testing — no v2 exists. Latest is 1.19.2 (2026-03-30). Use `from: "1.19.2"`. ⚠️ Planner must reconcile this in the PLAN before locking the version.
- ROADMAP.md success criterion references "ContentView, LibraryView, SettingsView, RecordingView, DictationHUD" — the CONTEXT.md D-03 already corrected the actual file names to ContentView, LibrarySidebar, SettingsView, ControlBar, DictationHUD. Use the corrected roster.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Three Swift Testing test methods running in different suites in parallel may bleed NSApp.appearance state across suites despite `.serialized` within one suite. | Pitfall #8 | If `.serialized` actually does cross-suite serialization in newer Swift Testing versions, the mitigation guidance is overcautious but harmless. |
| A2 | The 5-second default timeout in `assertSnapshot` is enough for ContentView with its `.task` modifiers (which fire async). | Pitfall #7 | If snapshots time out, the per-test `timeout:` parameter can be raised. Documented in 23-PLAN if it surfaces. |
| A3 | `NSAppearance(named: .aqua)` produces deterministic Aqua rendering across `macos-26` runner and any developer Mac running macOS 26. | D-05 + Pitfall #5 | If a future macOS minor version subtly shifts Aqua rendering, baselines need regen. Standard treatment per Pitfall #5. |
| A4 | The user's "v2.x" wording in CONTEXT.md D-01 is a typo for "1.x" rather than an intent to hold the phase pending a future v2 release. | Standard Stack + ⚠️ correction | If the user actually wants to wait for v2, the entire phase is blocked indefinitely (no v2 announced). Planner should ask or proceed with 1.19.2. |
| A5 | `actions/upload-artifact@v4` is available on `macos-26` runner (it is on macos-13/14/15; assumption extends). | CI snippet | Verifiable by trying. If not, fall back to `@v3`. |

**Resolution path:** A4 is the only one needing user input before the phase locks. A1, A2, A3, A5 will resolve via execution and can be revisited if they materialize.

## Open Questions

1. **swift-snapshot-testing version pin: 1.x vs nonexistent 2.x**
   - What we know: Latest released version is 1.19.2 (2026-03-30). No v2.x has been tagged or announced.
   - What's unclear: CONTEXT.md D-01 says "v2.x". Was that a typo or did the user expect a v2 from elsewhere?
   - Recommendation: Pin `from: "1.19.2"`. Planner should call this out in the PLAN's open-questions or note section so the user can confirm.

2. **ADR location convention**
   - What we know: Repo has no ADR directory. CONTEXT.md "Claude's Discretion" leaves location to planner. Two well-known formats: **MADR** (Markdown Architectural Decision Records) — structured with explicit alternatives, pros/cons, decision drivers; and **Nygard** — short single-page, focused on the decision and its forces. [VERIFIED: arxiv.org/html/2604.27333 empirical comparison; adr.github.io templates]
   - What's unclear: Repo's prior decision-recording shape is the `.planning/` GSD ecosystem, not standalone ADRs. Introducing `.planning/adr/` adds a new convention; embedding inside `23-PLAN.md` keeps everything in the phase folder.
   - Recommendation: For a single-decision ADR (snapshot framework choice), favor a short Nygard-style doc inline at `.planning/phases/23-visual-regression-infra/23-ADR-snapshot-framework.md`. Avoids introducing a new top-level directory for one ADR. If future phases produce more ADRs, the planner of that phase can promote the convention to `.planning/adr/`.

3. **DictationHUD render path: extract or parallel?**
   - What we know: `DictationWindowController.setContent(_:)` (line 95) accepts an `AnyView` to update the HUD body at runtime. The production HUD is constructed with stub `EmptyView` then `attach(windowController:)` swaps in the live binding (PSTranscribeApp.swift:43-45).
   - What's unclear: For the snapshot test, do we instantiate a parallel `DictationHUD(state:elapsed:partialText:onStop:)` directly (clean, no controller dependency) or do we instantiate the controller and snapshot what it produced?
   - Recommendation: Instantiate `DictationHUD` directly with stub state. The view is parameter-only (no `@Observable` binding) per Phase 18-05 STATE notes ("DictationHUD is parameterized, NOT @Observable-bound"). Wrap in `NSHostingView`, snapshot. The runtime `NSPanel` chrome (vibrancy, shadow, sharingType) is intentionally out of scope per CONTEXT.md D-03.

4. **NSHostingView resize-on-frame-change timing**
   - What we know: `host.frame = NSRect(...)` and `host.layoutSubtreeIfNeeded()` should layout the SwiftUI tree at the requested size before the snapshot strategy reads bitmap.
   - What's unclear: SwiftUI's `.frame(width:height:)` modifier inside the rootView vs setting `NSHostingView.frame` externally — if both are set, which wins?
   - Recommendation: Set both — the inner `.frame(width:height:)` modifier inside `view.frame(...)` constrains SwiftUI's intrinsic sizing, and `host.frame` constrains the AppKit container. Pass the same dimensions via the `size:` parameter to `.image(...)` strategy as well (third pin). Belt-and-suspenders. If one is wrong, the other corrects.

5. **TestPlan/CI test selection: include or filter?**
   - What we know: The CI step runs `swift test` with no filter, so the new VisualRegressionTests run alongside the existing ~18 test files. Total runtime impact: TBD but cheap relative to the existing `swift build`.
   - What's unclear: If snapshot tests grow to dozens, do we want a separate CI job that only runs them, or keep them in the main test job?
   - Recommendation: Keep in main test job for now. Single test step, single failure surface. Revisit if total test runtime exceeds 5 minutes.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `macos-26` GitHub runner | CI test step | ✓ | GA since 2026-02-26 [VERIFIED: github.blog changelog] | macos-15 (older, no Xcode 26) |
| Xcode 26 (selected via existing build-check.yml step) | swift build + swift test | ✓ | Same as build-check.yml currently uses | — |
| Swift 6.2 toolchain | All Swift code | ✓ | Comes with Xcode 26 | — |
| swift-snapshot-testing 1.19.2 | Test target dependency | ✓ (will resolve via SwiftPM on first build) | 1.19.2 | Earlier 1.x (1.17.0 minimum for trait API) |
| `actions/upload-artifact@v4` | CI failure artifact upload | ✓ (assumed; widely used on macos runners) | v4 | v3 |
| `actions/checkout@v4` | Existing pattern in build-check.yml | ✓ (already pinned by SHA) | v4 | — |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None — all required tools are present in the existing CI surface or will be resolved transparently by SwiftPM.

## Validation Architecture

> Phase 23's "validation" is itself a test infrastructure: the snapshot tests ARE the validation surface for the appearance bridge. This section defines how to validate that *the test infrastructure itself* is working correctly.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Swift Testing (built into Swift 6.2) + swift-snapshot-testing 1.19.2 |
| Config file | None — Swift Testing uses `import Testing` + macros, no separate config |
| Quick run command | `swift test --filter VisualRegression` (run only the new suite) |
| Full suite command | `swift test` (all 18+ test files including new visual regression suite) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| VISREG-01 | Snapshot framework chosen + ADR documents trade-offs | Doc review (`.planning/phases/23-visual-regression-infra/23-ADR-*.md` exists, references the alternatives compared) | manual artifact check | ❌ Wave 0 — ADR file |
| VISREG-02 | 5 surfaces × Light appearance baselines | snapshot | `swift test --filter VisualRegressionTests/contentViewLight` (etc., 5 tests) | ❌ Wave 0 — `VisualRegressionTests.swift` |
| VISREG-03 | 5 surfaces × Dark appearance baselines | snapshot | `swift test --filter VisualRegressionTests/contentViewDark` (etc., 5 tests) | ❌ Wave 0 |
| VISREG-04 | 5 surfaces × System appearance baselines (NSApp.appearance pinned to .aqua) | snapshot | `swift test --filter VisualRegressionTests/contentViewSystem` (etc., 5 tests) | ❌ Wave 0 |
| VISREG-05 | CI runs snapshot tests on PR; failure blocks merge | integration (smoke against actual GitHub Actions run) | Open a test PR, observe `Build Check / build` step fails on intentional baseline mutation | ❌ Wave 0 — `.github/workflows/build-check.yml` extension |
| VISREG-06 | Regen workflow doc exists in TESTING.md AND CONTRIBUTING.md | doc review (file exists, contains the `SNAPSHOT_TESTING_RECORD=all swift test --filter VisualRegression` incantation verbatim) | `grep -q 'SNAPSHOT_TESTING_RECORD=all' .planning/codebase/TESTING.md && grep -q 'SNAPSHOT_TESTING_RECORD=all' CONTRIBUTING.md` | ❌ Wave 0 — TESTING.md refresh + CONTRIBUTING.md create |

### Sampling Rate

- **Per task commit:** `swift test --filter VisualRegression` — runs only the 15 visual regression tests (~10–30s expected at strict precision), giving fast local feedback.
- **Per wave merge:** `swift test` — full suite, including all existing 18+ test files. Confirms no regression to neighboring tests from the new dependency.
- **Phase gate:** Full suite green on `macos-26` runner via `Build Check` workflow before `/gsd-verify-work`.

### Wave 0 Gaps

- [ ] `PSTranscribe/Tests/PSTranscribeTests/VisualRegressionTests.swift` — covers VISREG-02..04 (15 @Test methods)
- [ ] `PSTranscribe/Tests/PSTranscribeTests/SnapshotFixtures.swift` — shared stub builders (AppSettings, LibraryStore, NotionService, SessionCoordinator, ModelUpdateService, SaveDestinations, withAppearance helper)
- [ ] `PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/*.png` — 15 baseline PNGs (auto-generated on first run via `SNAPSHOT_TESTING_RECORD=missing swift test`)
- [ ] `PSTranscribe/Package.swift` — add `swift-snapshot-testing` to `dependencies` and to the test target's `dependencies`
- [ ] `.github/workflows/build-check.yml` — extend with `swift test` step + `SNAPSHOT_ARTIFACTS` env + record-mode guard step + `actions/upload-artifact` on failure (covers VISREG-05)
- [ ] `.planning/codebase/TESTING.md` — refresh to remove "no test targets" claim; add visual regression section with regen incantation (covers VISREG-06 part 1)
- [ ] `CONTRIBUTING.md` — CREATE new file with snapshot regen + general PR workflow guidance (covers VISREG-06 part 2)
- [ ] `.planning/phases/23-visual-regression-infra/23-ADR-snapshot-framework.md` (or similar) — Nygard-style ADR documenting the swift-snapshot-testing choice + alternatives considered (covers VISREG-01)

Framework install: handled by SwiftPM on first `swift build` after Package.swift edit. No separate install step.

## Project Constraints (from CLAUDE.md and rules)

The following directives from `~/.claude/CLAUDE.md` and `~/.claude/rules/*.md` apply to this phase. The planner MUST verify compliance:

- **No emojis in code or docs unless user requests.** RESEARCH.md and the planned ADR / TESTING.md / CONTRIBUTING.md additions stay emoji-free (the `Code Examples` section above uses only ASCII / Unicode arrow drawings, no emoji).
- **No em dashes — use double hyphens (`--`).** RESEARCH.md text-prose body uses `--` per global communication rule. Code blocks and table columns use whatever syntax the source language requires.
- **Verify before claiming done.** The Validation Architecture section above defines the verification surface; tasks must run `swift test --filter VisualRegression` and observe green before marking complete.
- **No git commit attribution.** When the planner produces git-commit instructions for SUMMARY/PLAN docs or test code, no `Co-Authored-By: Claude` trailer, no robot footer, no Generated-with footer.
- **Inspect before proposing.** This research read all in-scope source files (Package.swift, build-check.yml, all 5 view files, DictationWindowController, PSTranscribeApp, AppSettings, LibraryStore, TranscriptStore, both example test files). Future plan / discuss-phase work should not relitigate decisions already verified here.
- **Build only what's requested.** No tests for out-of-scope surfaces (TranscriptView, NotionTagSheet, etc.). No multi-size variants. No git LFS adoption. No CI matrix expansion.
- **Test target only.** swift-snapshot-testing must be added to `.testTarget` dependencies, NOT to `.executableTarget`. Production binary stays unchanged in size and dependency surface.

## Sources

### Primary (HIGH confidence)

- `/pointfreeco/swift-snapshot-testing` (Context7 / ctx7) — Swift Testing trait, withSnapshotTesting, record modes, assertSnapshot signatures, NSView image strategy, env var parsing
- GitHub API `https://api.github.com/repos/pointfreeco/swift-snapshot-testing/releases?per_page=8` — version verification 1.19.2 (2026-03-30) is latest; full release history confirms NO v2.x exists
- `https://github.com/pointfreeco/swift-snapshot-testing/blob/main/Sources/SnapshotTesting/Snapshotting/NSView.swift` (raw GitHub) — verified `image(precision:perceptualPrecision:size:)` signature and the `bitmapImageRepForCachingDisplay` rendering path (no NSWindow involvement)
- `https://github.com/pointfreeco/swift-snapshot-testing/blob/main/Sources/SnapshotTesting/AssertSnapshot.swift` (raw GitHub) — verified `__record` env var initializer reads `SNAPSHOT_TESTING_RECORD` and parses via `Record(rawValue:)` accepting `all|failed|missing|never`; verified `$SNAPSHOT_ARTIFACTS` env-var-or-NSTemporaryDirectory failure-write path
- `https://github.com/pointfreeco/swift-snapshot-testing/releases/tag/1.17.0` — release notes confirm Swift Testing trait (Beta) introduction + env var support
- `https://github.com/pointfreeco/swift-snapshot-testing/releases/tag/1.19.0` — release notes confirm Swift Testing attachment support + `record: Record?` parameter
- `/swiftlang/swift-testing` (Context7 / ctx7) — `.serialized` trait scope (within-suite only), init/deinit setUp/tearDown migration pattern
- `https://github.blog/changelog/2026-02-26-macos-26-is-now-generally-available-for-github-hosted-runners/` — macos-26 runner GA confirmation
- All in-scope source files in `PSTranscribe/Sources/...` and `PSTranscribe/Tests/...` and `.github/workflows/build-check.yml` — read directly during research

### Secondary (MEDIUM confidence)

- `https://dev.to/d4g4/our-swiftui-snapshot-tests-passed-locally-but-failed-on-ci-heres-the-actual-fix-5fhd` — CI flake debugging technique (sips dimension diff). Note: the article's NSWindow-title-bar root cause is iOS-specific; the *debugging technique* (sips comparison) generalizes.
- `https://github.com/pointfreeco/swift-snapshot-testing/discussions/922` — community confirmation of `SNAPSHOT_TESTING_RECORD` env var name (cross-checks the source verification)
- `https://github.com/actions/runner-images/issues/13143` — known macos-26 + Xcode 26 hang issue confirmed iOS-Simulator-specific, not native macOS swift test

### Tertiary (LOW confidence)

- `https://adr.github.io/adr-templates/` and `https://arxiv.org/html/2604.27333` — ADR template comparison. Recommendations in Open Question #2 are based on these but the choice between MADR / Nygard / inline-in-PLAN is ultimately style preference.

## Metadata

**Confidence breakdown:**

- Standard stack: **HIGH** — version 1.19.2 verified via GitHub API; API surface verified via direct source inspection; Swift Testing trait verified via release notes 1.17.0
- Architecture (NSHostingView pattern, NSApp.appearance fixture, env var contract): **HIGH** — all primitives verified in source code or Apple/Swift documentation
- Pitfalls (#1, #2, #3, #4): **HIGH** — derived from documented source behavior. Pitfall #5 (strict precision flake on macos-26): **MEDIUM** — based on dev.to article's macOS observations + general SwiftUI subpixel rendering knowledge; specific macos-26 runner behavior not directly verified. Pitfall #8 (cross-suite parallel bleed): **MEDIUM** — verified `.serialized` only scopes within-suite, but the actual cross-suite bleed risk hasn't been reproduced.
- ADR location guidance (Open Q #2): **LOW** — style preference; defer to user/planner

**Research date:** 2026-05-02
**Valid until:** 2026-06-02 (30 days for stable library + macOS toolchain). swift-snapshot-testing has been releasing roughly monthly in 2026-Q1, so the recommended pin (`1.19.2`) may need a minor bump on review. Re-check the latest release if planning is delayed past June.

## RESEARCH COMPLETE
