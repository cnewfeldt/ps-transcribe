import Testing
import Foundation
@testable import PSTranscribe

@Suite("MenuBarIndicatorTests")
struct MenuBarIndicatorTests {

    /// Path to PSTranscribeApp.swift relative to the test runner's CWD (the package root).
    private let appSwiftPath = "Sources/PSTranscribe/App/PSTranscribeApp.swift"

    @Test func menuBarSymbolIsMicFillWhenDictationActive() throws {
        let source = try String(contentsOfFile: appSwiftPath, encoding: .utf8)
        // The MenuBarExtra label must contain the conditional symbol selection bound to
        // dictationCoordinator.isActive — DICT-03.
        #expect(
            source.contains(#"dictationCoordinator.isActive ? "mic.fill" : "book.closed""#),
            "MenuBarExtra label must use mic.fill when dictation is active and book.closed otherwise"
        )
    }

    @Test func symbolEffectPulseBoundToIsActive() throws {
        let source = try String(contentsOfFile: appSwiftPath, encoding: .utf8)
        #expect(
            source.contains(".symbolEffect(.pulse, isActive: dictationCoordinator.isActive)"),
            "MenuBarExtra label must apply .symbolEffect(.pulse, isActive:) bound to dictationCoordinator.isActive"
        )
    }
}
