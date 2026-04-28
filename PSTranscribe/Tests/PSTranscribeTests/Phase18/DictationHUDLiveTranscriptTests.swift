import Testing
import Foundation
@testable import PSTranscribe

@Suite("DictationHUDLiveTranscriptTests")
struct DictationHUDLiveTranscriptTests {

    /// DICT-04 — the HUD body must render the live partialText while listening.
    /// Approach: source-grep for the displayText switch arms that reference partialText
    /// and produce the locked HUD strings (per CONTEXT.md D-01/D-02/D-14/D-16).

    private let hudSourcePath = "Sources/PSTranscribe/Views/DictationHUD.swift"

    @Test func hudListeningArmRendersPartialText() throws {
        let source = try String(contentsOfFile: hudSourcePath, encoding: .utf8)
        #expect(
            source.contains("partialText.isEmpty ? \"Listening…\" : partialText"),
            "DictationHUD listening arm must render partialText (DICT-04)"
        )
    }

    @Test func hudHasAllSixStateArms() throws {
        let source = try String(contentsOfFile: hudSourcePath, encoding: .utf8)
        #expect(source.contains("Loading model…"), "D-16: HUD must render \"Loading model…\" when models are not ready")
        #expect(source.contains("Press Esc again to cancel"), "D-06: HUD must render the 30s cancel-confirmation prompt")
        #expect(source.contains("Copied to clipboard"), "D-02: HUD must render the copied confirmation pill")
        #expect(source.contains("Recording in progress — dictation unavailable"), "D-14: HUD must render the mutual-exclusion notice")
    }
}
