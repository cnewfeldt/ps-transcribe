import Testing
import Foundation
import SwiftUI
@testable import PSTranscribe

@Suite("DictationHUDLiveTranscriptTests")
struct DictationHUDLiveTranscriptTests {

    /// DICT-04 -- the HUD body must render the live partialText while listening.
    /// Approach: source-grep for the displayText switch arms that reference partialText
    /// and produce the locked HUD strings (per CONTEXT.md D-01/D-02/D-14/D-16).

    private let hudSourcePath = "Sources/PSTranscribe/Views/DictationHUD.swift"

    @Test(.disabled("Pending Plan 18-08 -- HUD listening arm renders partialText"))
    func hudListeningArmRendersPartialText() throws {
        // let source = try String(contentsOfFile: hudSourcePath, encoding: .utf8)
        // #expect(source.contains("partialText.isEmpty ? \"Listening...\" : partialText"))
        _ = hudSourcePath
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-08 -- HUD has all 6 state arms (D-01/02/14/16)"))
    func hudHasAllSixStateArms() throws {
        // let source = try String(contentsOfFile: hudSourcePath, encoding: .utf8)
        // #expect(source.contains("Loading model..."))
        // #expect(source.contains("Press Esc again to cancel"))
        // #expect(source.contains("Copied to clipboard"))
        // #expect(source.contains("Recording in progress -- dictation unavailable"))
        _ = hudSourcePath
        #expect(Bool(true))
    }
}
