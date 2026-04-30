import Foundation
import Testing
@testable import PSTranscribe

@MainActor
@Suite("Phase 18.1 gap-09 -- D-20 lastError auto-clear (UAT issue #3)")
struct D20RecoveryAutoClearTests {

    /// Mirrors the predicate inside ContentView's
    /// `.onChange(of: saveDestinations.isAnyDestinationEnabled)` block. This
    /// helper exists so the test exercises the SAME logic without mounting
    /// SwiftUI. If the production handler diverges from this predicate, the
    /// source-grep tests below catch it; behavioral coverage stays here.
    private func runAutoClearHandler(isEnabled: Bool, lastError: inout String?) {
        guard isEnabled,
              lastError == DestinationGuardErrors.noDestinationsConfigured
        else { return }
        lastError = nil
    }

    @Test("D-20 message clears when destinations re-enable")
    func d20MessageClearsOnEnable() {
        var lastError: String? = DestinationGuardErrors.noDestinationsConfigured
        runAutoClearHandler(isEnabled: true, lastError: &lastError)
        #expect(lastError == nil, "D-20 recovery: lastError must be cleared when isAnyDestinationEnabled becomes true")
    }

    @Test("Mic permission error is preserved (not over-cleared)")
    func micPermissionErrorPreserved() {
        let micErr = "Microphone access denied. Enable in System Settings > Privacy > Microphone."
        var lastError: String? = micErr
        runAutoClearHandler(isEnabled: true, lastError: &lastError)
        #expect(lastError == micErr, "auto-clear must NOT match unrelated errors (regression-defense)")
    }

    @Test("Save-failure error is preserved")
    func saveFailureErrorPreserved() {
        let saveErr = "Failed to write Local File transcript: permission denied"
        var lastError: String? = saveErr
        runAutoClearHandler(isEnabled: true, lastError: &lastError)
        #expect(lastError == saveErr)
    }

    @Test("Already-nil lastError is unchanged when destinations toggle on")
    func nilErrorIsIdempotent() {
        var lastError: String? = nil
        runAutoClearHandler(isEnabled: true, lastError: &lastError)
        #expect(lastError == nil)
    }

    @Test("Disabling destinations does not act (handler only runs on enable transitions)")
    func disableTransitionIsNoOp() {
        var lastError: String? = DestinationGuardErrors.noDestinationsConfigured
        runAutoClearHandler(isEnabled: false, lastError: &lastError)
        #expect(lastError == DestinationGuardErrors.noDestinationsConfigured,
                "auto-clear gates on isEnabled == true; false transitions are no-ops")
    }

    // ─── Source-grep tests (drift defense) ───

    private var saveDestinationsSource: String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()         // -> Phase18.1/
            .deletingLastPathComponent()         // -> PSTranscribeTests/
            .deletingLastPathComponent()         // -> Tests/
            .deletingLastPathComponent()         // -> PSTranscribe/ (package root)
            .appendingPathComponent("Sources/PSTranscribe/Services/SaveDestinations.swift")
        return (try? String(contentsOf: url)) ?? ""
    }

    private var contentViewSource: String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/PSTranscribe/Views/ContentView.swift")
        return (try? String(contentsOf: url)) ?? ""
    }

    @Test("DestinationGuardErrors.noDestinationsConfigured exists in SaveDestinations.swift")
    func constantIsCentralized() {
        #expect(saveDestinationsSource.contains("static let noDestinationsConfigured"))
        #expect(saveDestinationsSource.contains(
            "No save destination configured. Enable Local File, Obsidian, or Notion in Settings."))
    }

    @Test("ContentView producer references the constant (not the literal)")
    func contentViewProducerUsesConstant() {
        #expect(contentViewSource.contains("DestinationGuardErrors.noDestinationsConfigured"))
        let literal = "No save destination configured. Enable Local File, Obsidian, or Notion in Settings."
        #expect(!contentViewSource.contains(literal),
                "The D-20 message literal must live ONLY in SaveDestinations.swift")
    }

    @Test("ContentView contains the auto-clear .onChange wired to isAnyDestinationEnabled")
    func contentViewHasAutoClearHandler() {
        #expect(contentViewSource.contains(".onChange(of: saveDestinations.isAnyDestinationEnabled"))
    }

    @Test("Auto-clear is exact-match scoped (== to constant, not hasPrefix or contains)")
    func contentViewAutoClearIsExactMatch() {
        // Anti-broadening guard: the .onChange body must compare lastError ==
        // DestinationGuardErrors.noDestinationsConfigured, NOT use hasPrefix or contains.
        #expect(contentViewSource.contains("transcriptionEngine?.lastError == DestinationGuardErrors.noDestinationsConfigured"),
                "auto-clear predicate must use exact equality with the constant")
    }
}
