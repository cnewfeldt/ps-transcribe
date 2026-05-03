import Testing
import SnapshotTesting
import SwiftUI
import AppKit
@testable import PSTranscribe

/// Visual regression baselines for the 5 in-scope macOS surfaces (CONTEXT D-03)
/// across Light / Dark / System appearances (CONTEXT D-05).
///
/// Wave 0 (Plan 23-01) commits this skeleton: 5 stub @Test methods that compile and
/// are discoverable, but record an Issue.record so they fail loudly if executed
/// before Plan 23-03 fills in the real assertions. This guarantees:
///   1. Plans 03 and 04 both target the same suite name + test method names
///   2. `swift test --list-tests` can prove the suite exists from Wave 0
///   3. CI (added in Plan 23-04) will surface the stub-fail until Plan 23-03 lands
///
/// Per RESEARCH + PATTERNS: `final class` (not `struct`) is preserved per the must_haves.
/// The plan originally specified an `init`/`deinit` capture-and-restore for
/// `NSApp.appearance` as a belt-and-suspenders backstop, but Swift 6.3 + swift-testing's
/// `@Test` macro expansion rejects stored properties + init on a `@Suite` class:
/// the macro emits a `private nonisolated static let ... : Testing.__TestContentRecord`
/// that must be a compile-time constant, and a class with stored state cannot satisfy
/// the `@const` / `@section` requirement that emerged in the 6.3 toolchain.
/// (Deviation [Rule 3 - Blocking issue]: see SUMMARY.) Per RESEARCH Pitfall #2 the
/// per-test `defer { NSApp.appearance = prior }` inside each System @Test is the
/// PRIMARY restore primitive; the suite-level lifecycle was always belt-and-suspenders
/// only. Plan 23-03 adds the per-test `defer` pair when filling in the System variants.
///
/// `.serialized` is non-negotiable -- `NSApp.appearance` is process-global. `@MainActor`
/// is applied per-method (matching existing AppSettingsTests / SessionCoordinatorTests
/// pattern) because `NSHostingView`, `NSApp`, and SwiftUI views are all
/// MainActor-isolated.
///
/// `record: .missing` is the default-safe mode: writes a baseline the first time
/// a test runs (no PNG on disk), fails on diff thereafter. Local regen incantation
/// is `SNAPSHOT_TESTING_RECORD=all swift test --filter VisualRegression` -- documented
/// in CONTRIBUTING.md (Plan 23-05).
@Suite("VisualRegression", .serialized, .snapshots(record: .missing))
final class VisualRegressionTests {

    // MARK: - Stubs (Plan 23-03 replaces bodies with real assertSnapshot calls)
    //
    // These five stubs cover the per-surface dimension. Plan 03 expands each into
    // 3 @Test methods (Light / Dark / System) for a total of 15 tests.
    //
    // The pre-Plan-03 contract: every stub records an Issue so the suite is
    // visibly red until Plan 03 lands. This forces Plan 03 to actually replace
    // each body rather than ship a green-but-empty suite.

    @Test @MainActor func contentViewLight() {
        Issue.record("Pending Plan 23-03: ContentView Light snapshot not yet implemented")
    }

    @Test @MainActor func librarySidebarLight() {
        Issue.record("Pending Plan 23-03: LibrarySidebar Light snapshot not yet implemented")
    }

    @Test @MainActor func settingsViewLight() {
        Issue.record("Pending Plan 23-03: SettingsView Light snapshot not yet implemented")
    }

    @Test @MainActor func controlBarLight() {
        Issue.record("Pending Plan 23-03: ControlBar Light snapshot not yet implemented")
    }

    @Test @MainActor func dictationHUDLight() {
        Issue.record("Pending Plan 23-03: DictationHUD Light snapshot not yet implemented")
    }
}
