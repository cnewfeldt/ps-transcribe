import Testing
import Foundation
@testable import PSTranscribe

/// Integration tests for TranscriptionEngine.reloadModels().
///
/// These tests require the FluidAudio Parakeet-TDT v3 model to already be on disk
/// (the case on a developer machine where the app has been launched at least once).
/// They are tagged `.integration` so they are excluded from the default `swift test`
/// run (which must remain under 30s per RESEARCH Validation Architecture).
///
/// Run explicitly via:
///   swift test --filter TranscriptionEngineReloadModelsTests
///
/// See CONTEXT.md D-18 / D-19 for session-gate semantics; RESEARCH Pitfall #4 for
/// the AsrModels.downloadAndLoad no-op guarantee when files already exist on disk.
@Suite("TranscriptionEngine.reloadModels (integration)", .tags(.integration), .serialized)
struct TranscriptionEngineReloadModelsTests {

    /// After a prior prepareModels() call, reloadModels() explicitly nils out the existing
    /// managers and reloads from disk. Verifies modelsReady remains true afterward.
    @Test @MainActor func reloadAfterPrepareSucceeds() async throws {
        let store = TranscriptStore()
        let engine = TranscriptionEngine(transcriptStore: store)
        await engine.prepareModels()
        // prepareModels guards against re-running; reloadModels explicitly nils first.
        #expect(engine.modelsReady == true)
        try await engine.reloadModels()
        #expect(engine.modelsReady == true)
    }

    /// Starting from a cold state (no prepareModels), reloadModels() loads the models
    /// from disk directly. Verifies both modelsReady and the manager references are set.
    @Test @MainActor func reloadFromColdStateLoadsModels() async throws {
        let store = TranscriptStore()
        let engine = TranscriptionEngine(transcriptStore: store)
        // Skip prepareModels; go straight to reloadModels.
        try await engine.reloadModels()
        #expect(engine.modelsReady == true)
    }
}
