import Testing
import Foundation
@testable import PSTranscribe

@Suite("LibraryEntryRowDictationIconTests")
struct LibraryEntryRowDictationIconTests {

    /// Source-grep tests for D-11. SwiftUI views are not directly introspectable in unit tests,
    /// so the production-code contract is verified by source-level pattern checks.
    /// (Pattern matches existing MenuBarIndicatorTests source-grep approach.)

    private let rowSourcePath = "Sources/PSTranscribe/Views/LibraryEntryRow.swift"

    @Test func libraryEntryRowHandlesDictationCase() throws {
        let source = try String(contentsOfFile: rowSourcePath, encoding: .utf8)
        #expect(source.contains("case .dictation:"), "LibraryEntryRow must handle SessionType.dictation (D-11)")
    }

    @Test func libraryEntryRowUsesMicFillForDictation() throws {
        let source = try String(contentsOfFile: rowSourcePath, encoding: .utf8)
        #expect(source.contains("mic.fill"), "LibraryEntryRow must reference mic.fill SF Symbol for dictation entries (D-11)")
    }
}
