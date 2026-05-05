// RecoveredSessionTypeTests
// Phase 24 (NYQUIST-05) -- Phase 10 D-05: crash-recovered session type icon inference.
//
// Asserts the pure-function helper extracted from ContentView.swift in Plan 24-02 Task 1.
// The helper maps a transcript path under a vault VoiceMemos prefix to .voiceMemo, else
// .callCapture. No view harness; pure string-prefix logic.

import Testing
import Foundation
@testable import PSTranscribe

@Suite("RecoveredSessionTypeTests")
struct RecoveredSessionTypeTests {

    @Test func voiceMemoPathInferredFromVaultPrefix() {
        let result = recoveredSessionType(
            transcriptPath: "/Users/cary/Vault/VoiceMemos/2026-04-07-foo.md",
            vaultVoicePath: "/Users/cary/Vault/VoiceMemos"
        )
        #expect(result == .voiceMemo)
    }

    @Test func callCaptureFallbackWhenNotUnderVaultPrefix() {
        let result = recoveredSessionType(
            transcriptPath: "/Users/cary/Vault/Calls/2026-04-07-bar.md",
            vaultVoicePath: "/Users/cary/Vault/VoiceMemos"
        )
        #expect(result == .callCapture)
    }
}
