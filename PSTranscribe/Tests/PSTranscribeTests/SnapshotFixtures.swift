import Foundation
import SwiftUI
import AppKit
@testable import PSTranscribe

/// Shared snapshot test fixtures: appearance helper, canonical frame sizes,
/// deterministic stub state for the views under test.
///
/// Per CONTEXT.md (Phase 23, D-Discretion): one helper enum, file-level. Consumed by
/// `VisualRegressionTests.swift`. No `@Suite` decoration. `@MainActor` because every
/// caller is `@MainActor` (NSHostingView + NSApp + SwiftUI views).
@MainActor
enum SnapshotFixtures {

    // MARK: - Appearance helper (D-05)

    /// Run `body` with `NSApp.appearance` set to `name`, restore prior in defer.
    /// Used by the System-appearance @Test methods to pin appearance to .aqua
    /// for inheritance verification (D-05). Per RESEARCH Pitfall #2, the defer
    /// inside the test body is the canonical primitive -- this helper centralizes
    /// the capture/restore pair so callers cannot accidentally skip restore.
    static func withAppearance<R>(_ name: NSAppearance.Name?, body: () throws -> R) rethrows -> R {
        let prior = NSApp.appearance
        if let name { NSApp.appearance = NSAppearance(named: name) }
        defer { NSApp.appearance = prior }
        return try body()
    }

    // MARK: - Canonical frame sizes (D-04)

    /// Per-surface canonical frame in points. Sized against PSTranscribeApp.swift
    /// `.defaultSize(width: 1280, height: 820)` for the WindowGroup root, with
    /// per-surface tuning per CONTEXT D-04 suggested ranges. Plan 03 (and only
    /// Plan 03) is allowed to fine-tune these against the actual rendered output.
    static let contentViewFrame    = CGSize(width: 1280, height: 820)
    static let librarySidebarFrame = CGSize(width: 280,  height: 600)
    static let settingsViewFrame   = CGSize(width: 520,  height: 400)
    static let controlBarFrame     = CGSize(width: 800,  height: 56)
    static let dictationHUDFrame   = CGSize(width: 560,  height: 120)

    // MARK: - Stub state factories (Plan 23-03)

    /// Clean-default AppSettings. Pre-clears keys this phase's views read so prior-test
    /// state does not bleed into the snapshot. Mirrors the AppSettingsTests
    /// `defer { clearV12Keys() }` pattern but applied at construction time.
    /// The cleared key list mirrors the v1.2 keys actually exercised by the 5 surfaces
    /// (Settings appearance/folder pickers, dictation prefs, screen-share guard).
    static func stubAppSettings() -> AppSettings {
        let defaults = UserDefaults.standard
        for key in [
            "appearancePreference",
            "localFileEnabled",
            "localFileRoot",
            "obsidianEnabled",
            "obsidianFolderPath",
            "notionDatabaseID",
            "notionAutoSendEnabled",
            "dictationHotkeyMode",
            "clipboardRestoreDelay",
            "hideFromScreenShare",
            "modelAutoUpdateEnabled",
            "installedModelVersion",
            "modelLastCheckedDate",
            "transcriptionLocale",
            "inputDeviceID",
            "lastUsedSessionType",
        ] {
            defaults.removeObject(forKey: key)
        }
        return AppSettings()
    }

    /// LibraryStore seeded with `seedEntries` deterministic entries in a per-test temp dir.
    /// Mirrors DictationLoggerTests.tempDir() pattern so library.json never bleeds into
    /// the user's app support dir during test runs.
    /// `async` because LibraryStore is an `actor` and addEntry is isolated.
    static func stubLibraryStore(seedEntries: Int = 3) async -> LibraryStore {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("VisRegLibrary-\(UUID().uuidString)", isDirectory: true)
        let store = LibraryStore(directory: tmp)
        for i in 0..<seedEntries {
            await store.addEntry(makeStubEntry(index: i))
        }
        return store
    }

    /// NotionService with no API key configured. Per RESEARCH Pitfall #7, the production
    /// type handles a missing key gracefully (no auto-validate-on-init network call).
    /// NotionService is an `actor` with no required init args -- synthesized init is fine.
    static func stubNotionService() -> NotionService {
        return NotionService()
    }

    /// Default SessionCoordinator. Engine left nil -- the dictation/coordinator linkage
    /// is not exercised by snapshot tests (Phase 18 STATE: SessionCoordinator gates mutual
    /// exclusion; views don't introspect its internals at render).
    static func stubSessionCoordinator() -> SessionCoordinator {
        return SessionCoordinator()
    }

    /// Stub ModelUpdateService. Engine is nil -- mirrors PSTranscribeApp.swift init shape
    /// (engine late-bound in ContentView .task). Snapshot is taken before the .task fires
    /// per RESEARCH Pitfall #7. The `appVersion: "1.0.0"` argument is supplied so the
    /// service does not read CFBundleShortVersionString from a test-host bundle that
    /// does not have one set.
    static func stubModelUpdateService(
        settings: AppSettings,
        sessionCoordinator: SessionCoordinator
    ) -> ModelUpdateService {
        return ModelUpdateService(
            settings: settings,
            engine: nil,
            sessionCoordinator: sessionCoordinator,
            appVersion: "1.0.0"
        )
    }

    /// Stub SaveDestinations. Mirrors PSTranscribeApp.swift init shape; default
    /// LocalFileWriter and ObsidianWriter are constructed inline by the production
    /// type's default-arg initializer.
    static func stubSaveDestinations(
        settings: AppSettings,
        notionService: NotionService
    ) -> SaveDestinations {
        return SaveDestinations(
            settings: settings,
            notionService: notionService
        )
    }

    /// Convenience: build a deterministic LibraryEntry array directly (no actor / no async)
    /// for LibrarySidebar's `entries: [LibraryEntry]` parameter -- the view does not require
    /// a LibraryStore, only an array.
    static func stubLibraryEntries(count: Int = 3) -> [LibraryEntry] {
        var result: [LibraryEntry] = []
        result.reserveCapacity(count)
        for i in 0..<count {
            result.append(makeStubEntry(index: i))
        }
        return result
    }

    /// Single-entry helper. Extracted from stubLibraryEntries to keep the per-element
    /// `LibraryEntry(...)` initializer call type-checkable in reasonable time --
    /// inlining the full memberwise init inside a `(0..<count).map { ... }` expression
    /// hit Swift's expression-complexity limiter on the 6.2 toolchain.
    private static func makeStubEntry(index i: Int) -> LibraryEntry {
        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
        let id = UUID(uuidString: "00000000-0000-0000-0000-00000000000\(i)") ?? UUID()
        return LibraryEntry(
            id: id,
            name: "Snapshot Entry \(i)",
            sessionType: i % 2 == 0 ? .callCapture : .voiceMemo,
            startDate: baseDate.addingTimeInterval(TimeInterval(i * 3600)),
            duration: TimeInterval(120 + i * 60),
            filePath: "",
            sourceApp: "Test",
            isFinalized: true,
            firstLinePreview: "Sample preview \(i)"
        )
    }
}
