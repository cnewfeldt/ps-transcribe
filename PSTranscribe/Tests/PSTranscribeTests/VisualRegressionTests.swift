import Testing
import SnapshotTesting
import SwiftUI
import AppKit
import Sparkle
@testable import PSTranscribe

/// Visual regression baselines for the 5 in-scope macOS surfaces (CONTEXT D-03)
/// across Light / Dark / System appearances (CONTEXT D-05).
///
/// Per RESEARCH + PATTERNS: `final class` (not `struct`) is preserved per the must_haves.
/// The plan originally specified an `init`/`deinit` capture-and-restore for
/// `NSApp.appearance` as a belt-and-suspenders backstop, but Swift 6.3 + swift-testing's
/// `@Test` macro expansion rejects stored properties + init on a `@Suite` class:
/// the macro emits a `private nonisolated static let ... : Testing.__TestContentRecord`
/// that must be a compile-time constant, and a class with stored state cannot satisfy
/// the `@const` / `@section` requirement that emerged in the 6.3 toolchain.
/// Per RESEARCH Pitfall #2 the per-test `defer { NSApp.appearance = prior }` (here
/// centralized via `SnapshotFixtures.withAppearance(.aqua) { ... }`) is the PRIMARY
/// restore primitive; the suite-level lifecycle was always belt-and-suspenders only.
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

    // MARK: - Snapshot helper

    /// Renders `view` at `size`, forces an NSHostingView layout pass (per Pitfall #1),
    /// and asserts against the named baseline at strict precision.
    /// `precision: 1.0`, `perceptualPrecision: 0.99` per CONTEXT D-02. Per-test loosening
    /// is forbidden globally; if a specific test needs an override, document the
    /// justification in the test body comment per CONTEXT D-02.
    @MainActor
    private func snapshot<V: View>(
        _ view: V,
        size: CGSize,
        named name: String,
        appearance: NSAppearance.Name? = nil,
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        function: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let host = NSHostingView(rootView: view.frame(width: size.width, height: size.height))
        host.frame = NSRect(x: 0, y: 0, width: size.width, height: size.height)
        // .preferredColorScheme on a SwiftUI view does not reach NSHostingView's
        // resolved appearance during off-screen bitmap capture. Set the host's
        // NSAppearance directly for Light/Dark; pass nil to inherit from
        // NSApp.appearance (set by SnapshotFixtures.withAppearance for System).
        if let appearance {
            host.appearance = NSAppearance(named: appearance)
        }
        // Pitfall #1: NSHostingView lays out lazily. Force a layout pass before the
        // snapshot strategy reads bitmap, otherwise first-run baselines clip or use
        // SwiftUI default sizing.
        host.layoutSubtreeIfNeeded()
        assertSnapshot(
            of: host,
            as: .image(
                precision: 1.0,
                perceptualPrecision: 0.99,
                size: size
            ),
            named: name,
            fileID: fileID,
            file: filePath,
            testName: function,
            line: line,
            column: column
        )
    }

    // MARK: - ContentView (3 tests)

    @Test @MainActor func contentViewLight() async {
        let settings = SnapshotFixtures.stubAppSettings()
        let notion = SnapshotFixtures.stubNotionService()
        let coord = SnapshotFixtures.stubSessionCoordinator()
        let library = await SnapshotFixtures.stubLibraryStore(seedEntries: 3)
        let modelUpdate = SnapshotFixtures.stubModelUpdateService(
            settings: settings,
            sessionCoordinator: coord
        )
        let saveDest = SnapshotFixtures.stubSaveDestinations(
            settings: settings,
            notionService: notion
        )
        let view = ContentView(
            settings: settings,
            notionService: notion,
            libraryStore: library,
            sessionCoordinator: coord,
            modelUpdateService: modelUpdate,
            saveDestinations: saveDest
        )
        .preferredColorScheme(.light)
        snapshot(view, size: SnapshotFixtures.contentViewFrame, named: "ContentView-Light", appearance: .aqua)
    }

    @Test @MainActor func contentViewDark() async {
        let settings = SnapshotFixtures.stubAppSettings()
        let notion = SnapshotFixtures.stubNotionService()
        let coord = SnapshotFixtures.stubSessionCoordinator()
        let library = await SnapshotFixtures.stubLibraryStore(seedEntries: 3)
        let modelUpdate = SnapshotFixtures.stubModelUpdateService(
            settings: settings,
            sessionCoordinator: coord
        )
        let saveDest = SnapshotFixtures.stubSaveDestinations(
            settings: settings,
            notionService: notion
        )
        let view = ContentView(
            settings: settings,
            notionService: notion,
            libraryStore: library,
            sessionCoordinator: coord,
            modelUpdateService: modelUpdate,
            saveDestinations: saveDest
        )
        .preferredColorScheme(.dark)
        snapshot(view, size: SnapshotFixtures.contentViewFrame, named: "ContentView-Dark", appearance: .darkAqua)
    }

    @Test @MainActor func contentViewSystem() async {
        // D-05: System variant pins NSApp.appearance to .aqua, NO .preferredColorScheme.
        // Verifies that views resolve colorScheme from NSApp.effectiveAppearance when
        // no explicit override is set (the inheritance path).
        let settings = SnapshotFixtures.stubAppSettings()
        let notion = SnapshotFixtures.stubNotionService()
        let coord = SnapshotFixtures.stubSessionCoordinator()
        let library = await SnapshotFixtures.stubLibraryStore(seedEntries: 3)
        let modelUpdate = SnapshotFixtures.stubModelUpdateService(
            settings: settings,
            sessionCoordinator: coord
        )
        let saveDest = SnapshotFixtures.stubSaveDestinations(
            settings: settings,
            notionService: notion
        )
        let view = ContentView(
            settings: settings,
            notionService: notion,
            libraryStore: library,
            sessionCoordinator: coord,
            modelUpdateService: modelUpdate,
            saveDestinations: saveDest
        )
        // No .preferredColorScheme -- intentional per D-05.
        SnapshotFixtures.withAppearance(.aqua) {
            snapshot(view, size: SnapshotFixtures.contentViewFrame, named: "ContentView-System")
        }
    }

    // MARK: - LibrarySidebar (3 tests)

    @Test @MainActor func librarySidebarLight() {
        let entries = SnapshotFixtures.stubLibraryEntries(count: 3)
        let view = LibrarySidebarHarness(entries: entries)
            .preferredColorScheme(.light)
        snapshot(view, size: SnapshotFixtures.librarySidebarFrame, named: "LibrarySidebar-Light", appearance: .aqua)
    }

    @Test @MainActor func librarySidebarDark() {
        let entries = SnapshotFixtures.stubLibraryEntries(count: 3)
        let view = LibrarySidebarHarness(entries: entries)
            .preferredColorScheme(.dark)
        snapshot(view, size: SnapshotFixtures.librarySidebarFrame, named: "LibrarySidebar-Dark", appearance: .darkAqua)
    }

    @Test @MainActor func librarySidebarSystem() {
        let entries = SnapshotFixtures.stubLibraryEntries(count: 3)
        let view = LibrarySidebarHarness(entries: entries)
        // No .preferredColorScheme -- inheritance verification per D-05.
        SnapshotFixtures.withAppearance(.aqua) {
            snapshot(view, size: SnapshotFixtures.librarySidebarFrame, named: "LibrarySidebar-System")
        }
    }

    // MARK: - SettingsView (3 tests)
    //
    // SettingsView declares `var updater: SPUUpdater` (Sources/PSTranscribe/Views/SettingsView.swift:14).
    // Sparkle 2.7+ supports headless construction via SPUStandardUpdaterController(startingUpdater: false, ...);
    // the underlying SPUUpdater is not started, so no scheduled checks, no network IO, no background timers.
    // This is the documented Sparkle test pattern -- no protocol abstraction or test stub required.

    @Test @MainActor func settingsViewLight() {
        let settings = SnapshotFixtures.stubAppSettings()
        let notion = SnapshotFixtures.stubNotionService()
        let coord = SnapshotFixtures.stubSessionCoordinator()
        let modelUpdate = SnapshotFixtures.stubModelUpdateService(
            settings: settings,
            sessionCoordinator: coord
        )
        let updater = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        ).updater
        let view = SettingsView(
            settings: settings,
            updater: updater,
            notionService: notion,
            modelUpdateService: modelUpdate
        )
        .preferredColorScheme(.light)
        snapshot(view, size: SnapshotFixtures.settingsViewFrame, named: "SettingsView-Light", appearance: .aqua)
    }

    @Test @MainActor func settingsViewDark() {
        let settings = SnapshotFixtures.stubAppSettings()
        let notion = SnapshotFixtures.stubNotionService()
        let coord = SnapshotFixtures.stubSessionCoordinator()
        let modelUpdate = SnapshotFixtures.stubModelUpdateService(
            settings: settings,
            sessionCoordinator: coord
        )
        let updater = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        ).updater
        let view = SettingsView(
            settings: settings,
            updater: updater,
            notionService: notion,
            modelUpdateService: modelUpdate
        )
        .preferredColorScheme(.dark)
        snapshot(view, size: SnapshotFixtures.settingsViewFrame, named: "SettingsView-Dark", appearance: .darkAqua)
    }

    @Test @MainActor func settingsViewSystem() {
        let settings = SnapshotFixtures.stubAppSettings()
        let notion = SnapshotFixtures.stubNotionService()
        let coord = SnapshotFixtures.stubSessionCoordinator()
        let modelUpdate = SnapshotFixtures.stubModelUpdateService(
            settings: settings,
            sessionCoordinator: coord
        )
        let updater = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        ).updater
        let view = SettingsView(
            settings: settings,
            updater: updater,
            notionService: notion,
            modelUpdateService: modelUpdate
        )
        SnapshotFixtures.withAppearance(.aqua) {
            snapshot(view, size: SnapshotFixtures.settingsViewFrame, named: "SettingsView-System")
        }
    }

    // MARK: - ControlBar (3 tests)

    @Test @MainActor func controlBarLight() {
        let view = ControlBar(
            isRecording: true,
            activeSessionType: .callCapture,
            audioLevel: 0.4,
            detectedApp: "Zoom",
            silenceSeconds: 5,
            statusMessage: "Recording",
            errorMessage: nil,
            modelsReady: true,
            hasError: false,
            activeErrors: [],
            onStartCallCapture: {},
            onStartVoiceMemo: {},
            onStop: {}
        )
        .preferredColorScheme(.light)
        snapshot(view, size: SnapshotFixtures.controlBarFrame, named: "ControlBar-Light", appearance: .aqua)
    }

    @Test @MainActor func controlBarDark() {
        let view = ControlBar(
            isRecording: true,
            activeSessionType: .callCapture,
            audioLevel: 0.4,
            detectedApp: "Zoom",
            silenceSeconds: 5,
            statusMessage: "Recording",
            errorMessage: nil,
            modelsReady: true,
            hasError: false,
            activeErrors: [],
            onStartCallCapture: {},
            onStartVoiceMemo: {},
            onStop: {}
        )
        .preferredColorScheme(.dark)
        snapshot(view, size: SnapshotFixtures.controlBarFrame, named: "ControlBar-Dark", appearance: .darkAqua)
    }

    @Test @MainActor func controlBarSystem() {
        let view = ControlBar(
            isRecording: true,
            activeSessionType: .callCapture,
            audioLevel: 0.4,
            detectedApp: "Zoom",
            silenceSeconds: 5,
            statusMessage: "Recording",
            errorMessage: nil,
            modelsReady: true,
            hasError: false,
            activeErrors: [],
            onStartCallCapture: {},
            onStartVoiceMemo: {},
            onStop: {}
        )
        SnapshotFixtures.withAppearance(.aqua) {
            snapshot(view, size: SnapshotFixtures.controlBarFrame, named: "ControlBar-System")
        }
    }

    // MARK: - DictationHUD (3 tests)
    //
    // Per Phase 18-05 STATE: DictationHUD is parameter-only (NOT @Observable-bound).
    // Constructed directly with stub state -- the runtime DictationWindowController
    // and NSPanel chrome are out of scope per CONTEXT D-03.

    @Test @MainActor func dictationHUDLight() {
        let view = DictationHUD(
            state: .listening,
            elapsed: 12.5,
            partialText: "This is a test partial transcript",
            onStop: {}
        )
        .preferredColorScheme(.light)
        snapshot(view, size: SnapshotFixtures.dictationHUDFrame, named: "DictationHUD-Light", appearance: .aqua)
    }

    @Test @MainActor func dictationHUDDark() {
        let view = DictationHUD(
            state: .listening,
            elapsed: 12.5,
            partialText: "This is a test partial transcript",
            onStop: {}
        )
        .preferredColorScheme(.dark)
        snapshot(view, size: SnapshotFixtures.dictationHUDFrame, named: "DictationHUD-Dark", appearance: .darkAqua)
    }

    @Test @MainActor func dictationHUDSystem() {
        let view = DictationHUD(
            state: .listening,
            elapsed: 12.5,
            partialText: "This is a test partial transcript",
            onStop: {}
        )
        SnapshotFixtures.withAppearance(.aqua) {
            snapshot(view, size: SnapshotFixtures.dictationHUDFrame, named: "DictationHUD-System")
        }
    }
}

// MARK: - LibrarySidebar harness
//
// LibrarySidebar requires a `@Binding var selectedID: UUID?`. Tests cannot construct
// a SwiftUI binding from a let, so a tiny harness wrapper holds the @State and
// passes the binding down. Mirrors the standard SwiftUI test pattern; harness is
// file-private to this test file so it does not leak into production discovery.
@MainActor
private struct LibrarySidebarHarness: View {
    let entries: [LibraryEntry]
    @State private var selectedID: UUID? = nil

    var body: some View {
        LibrarySidebar(
            entries: entries,
            selectedID: $selectedID,
            activeEntryID: nil
        )
    }
}
