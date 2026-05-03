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

    // MARK: - Stub state (Plan 03 fills these in with real factories)

    /// Plan 03 implements the real stub builders. Plan 01 commits the contract.
    /// AppSettings, LibraryStore, NotionService, SessionCoordinator,
    /// ModelUpdateService, SaveDestinations factories live here.
    ///
    /// LibraryStore is an `actor`, so any seeding builder is `async`.
}
