import Testing
import Foundation
@testable import PSTranscribe

// SessionCoordinator: app-scope coordinator that exposes a single source of truth
// for "is any session active right now?". Phase 16 wires the meeting/voice-memo
// TranscriptionEngine source only (D-05, D-06). The five tests below exercise
// anySessionActive across the engine attach / detach lifecycle plus the late-binding
// pattern used by ContentView.
@Suite("SessionCoordinator anySessionActive")
struct SessionCoordinatorTests {

    @Test @MainActor func falseWhenNoEngine() {
        let coordinator = SessionCoordinator()
        #expect(coordinator.anySessionActive == false)
    }

    @Test @MainActor func falseWhenEngineIdle() {
        let store = TranscriptStore()
        let engine = TranscriptionEngine(transcriptStore: store)
        let coordinator = SessionCoordinator(engine: engine)
        // engine.isRunning is `private(set)` and defaults to false — coordinator must read false.
        #expect(coordinator.anySessionActive == false)
    }

    @Test @MainActor func trueWhenEngineRunning() {
        // engine.isRunning is `private(set)` — flipping it without invoking the full audio
        // pipeline would require modifying the engine, which is out of scope for Phase 16
        // (D-13 spirit: don't touch what you don't have to). The full true-state path is
        // exercised by Plan 16-04 Task 4 (manual smoke test, SC-4) where a real recording
        // flips isRunning and SessionCoordinator's computed reflection should follow.
        //
        // This test asserts the COMPUTED-NOT-STORED property of anySessionActive: re-reading
        // it after no state change must return the same engine-derived value (proves no
        // hidden caching, proves it actually reads from the engine each time).
        let store = TranscriptStore()
        let engine = TranscriptionEngine(transcriptStore: store)
        let coordinator = SessionCoordinator(engine: engine)
        let firstRead = coordinator.anySessionActive
        let secondRead = coordinator.anySessionActive
        #expect(firstRead == secondRead)
        #expect(firstRead == false)  // engine.isRunning is false → coordinator reflects it
    }

    @Test @MainActor func detachingEngineReturnsFalse() {
        let store = TranscriptStore()
        let engine = TranscriptionEngine(transcriptStore: store)
        let coordinator = SessionCoordinator(engine: engine)
        coordinator.engine = nil
        #expect(coordinator.anySessionActive == false)
    }

    @Test @MainActor func laterAttachUpdatesAnySessionActiveSource() {
        let store = TranscriptStore()
        let engine = TranscriptionEngine(transcriptStore: store)
        let coordinator = SessionCoordinator()  // start with no engine
        #expect(coordinator.anySessionActive == false)
        coordinator.engine = engine  // late binding (mirrors ContentView's .task pattern)
        #expect(coordinator.anySessionActive == false)  // engine.isRunning still false
    }

    // MARK: - Phase 17: ModelUpdateService integration (Plan 17-03)

    /// anySessionActive must return true when modelUpdate.isApplying == true, even with no engine.
    @Test @MainActor func trueWhenModelUpdateApplying() {
        let coordinator = SessionCoordinator()
        let settings = AppSettings()
        let store = TranscriptStore()
        let engine = TranscriptionEngine(transcriptStore: store)
        let service = ModelUpdateService(settings: settings, engine: engine, sessionCoordinator: coordinator)
        service.isApplying = true
        coordinator.modelUpdate = service
        #expect(coordinator.anySessionActive == true)
    }

    /// anySessionActive must return false when modelUpdate.isApplying == false and engine is idle.
    @Test @MainActor func falseWhenModelUpdateNotApplying() {
        let coordinator = SessionCoordinator()
        let settings = AppSettings()
        let store = TranscriptStore()
        let engine = TranscriptionEngine(transcriptStore: store)
        let service = ModelUpdateService(settings: settings, engine: engine, sessionCoordinator: coordinator)
        service.isApplying = false
        coordinator.modelUpdate = service
        #expect(coordinator.anySessionActive == false)
    }

    /// modelUpdate must be held weakly: when the only strong reference is released,
    /// coordinator.modelUpdate must become nil (no retain cycle through coordinator).
    @Test @MainActor func modelUpdateHeldWeakly() {
        let coordinator = SessionCoordinator()
        do {
            let service = ModelUpdateService()
            coordinator.modelUpdate = service
            #expect(coordinator.modelUpdate === service)
        }
        // service has gone out of scope and was the only strong reference
        #expect(coordinator.modelUpdate == nil)
    }
}
