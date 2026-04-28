import Testing
import Foundation
@testable import PSTranscribe

@Suite("SessionCoordinatorMutualExclusionTests")
struct SessionCoordinatorMutualExclusionTests {

    @Test(.disabled("Pending Plan 18-04 -- anySessionActive includes dictation"))
    @MainActor func trueWhenDictationActive() async {
        // coordinator.dictation = dictationCoordinator with isActive==true
        // #expect(coordinator.anySessionActive == true)
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-04 -- dictation slot held weakly"))
    @MainActor func dictationHeldWeakly() async {
        // Mirrors modelUpdateHeldWeakly pattern (SessionCoordinatorTests.swift:96-105)
        // After scope exit, coordinator.dictation == nil
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-04 -- false when dictation idle and no other sessions"))
    @MainActor func falseWhenDictationIdle() async {
        // dictation.isActive==false + no engine.isRunning + no modelUpdate.isApplying -> false
        #expect(Bool(true))
    }
}
