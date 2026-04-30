import Foundation
import SwiftUI
import Testing
@testable import PSTranscribe

@MainActor
@Suite("Phase 18.1 gap-08 -- DictationHUD live binding (UAT issue #2)")
struct DictationHUDLiveBindingTests {

    private func makeCoordinator() -> DictationCoordinator {
        let keys = ["localFileEnabled", "localFileRoot", "obsidianEnabled",
                    "obsidianFolderPath", "notionAutoSendEnabled", "notionDatabaseID"]
        for k in keys { UserDefaults.standard.removeObject(forKey: k) }
        let settings = AppSettings()
        let library = LibraryStore()
        let sessionCoord = SessionCoordinator()
        let saveDest = SaveDestinations(settings: settings, notionService: NotionService())
        return DictationCoordinator(
            settings: settings,
            sessionCoordinator: sessionCoord,
            libraryStore: library,
            saveDestinations: saveDest
        )
    }

    /// Extracts the (state, elapsed, partialText) tuple out of the DictationHUD
    /// produced by evaluating the wrapper's body. Uses Mirror because
    /// DictationHUD's properties are `let` and not directly readable from outside
    /// the module without breaking encapsulation.
    private func snapshotHUD(from binding: DictationHUDBinding) -> (state: DictationCoordinator.State, elapsed: TimeInterval, partialText: String)? {
        let body = binding.body
        let mirror = Mirror(reflecting: body)
        var state: DictationCoordinator.State?
        var elapsed: TimeInterval?
        var partial: String?
        for child in mirror.children {
            switch child.label {
            case "state": state = child.value as? DictationCoordinator.State
            case "elapsed": elapsed = child.value as? TimeInterval
            case "partialText": partial = child.value as? String
            default: break
            }
        }
        guard let s = state, let e = elapsed, let p = partial else { return nil }
        return (s, e, p)
    }

    @Test("Body re-evaluates when coordinator.state and elapsed mutate")
    func bodyTracksStateAndElapsed() {
        let coord = makeCoordinator()
        let binding = DictationHUDBinding(coordinator: coord)

        // Initial: idle, 0, ""
        guard let snap0 = snapshotHUD(from: binding) else {
            Issue.record("Could not introspect initial DictationHUD body")
            return
        }
        #expect(snap0.state == .idle)
        #expect(snap0.elapsed == 0)
        #expect(snap0.partialText == "")

        // Mutate via test surface, then re-evaluate body.
        coord._test_setState(.listening)
        coord._test_setElapsed(7)

        guard let snap1 = snapshotHUD(from: binding) else {
            Issue.record("Could not introspect mutated DictationHUD body")
            return
        }
        #expect(snap1.state == .listening, "HUD must re-render with updated state")
        #expect(snap1.elapsed == 7, "HUD must re-render with updated elapsed")
    }

    @Test("Body re-evaluates when dictationStore.volatileYouText mutates")
    func bodyTracksPartialText() {
        let coord = makeCoordinator()
        let binding = DictationHUDBinding(coordinator: coord)

        coord._test_setState(.listening)
        coord.dictationStore.volatileYouText = "the quick brown fox"

        guard let snap = snapshotHUD(from: binding) else {
            Issue.record("Could not introspect DictationHUD body for partialText assertion")
            return
        }
        #expect(snap.partialText == "the quick brown fox", "HUD must re-render with updated partial transcript")
    }

    @Test("DictationCoordinator.attach uses the binding wrapper, not a one-shot AnyView snapshot")
    func attachUsesBindingWrapper() {
        // Source-level grep: confirm the structural fix is in place. Prevents
        // a future refactor from silently re-introducing the snapshot pattern.
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()      // -> Phase18.1/
            .deletingLastPathComponent()      // -> PSTranscribeTests/
            .deletingLastPathComponent()      // -> Tests/
            .deletingLastPathComponent()      // -> PSTranscribe/
            .appendingPathComponent("Sources/PSTranscribe/App/DictationCoordinator.swift")
        let source = (try? String(contentsOf: url)) ?? ""
        #expect(source.contains("DictationHUDBinding(coordinator:"),
                "attach() must wire the live-binding wrapper, not the AnyView snapshot")
    }
}
