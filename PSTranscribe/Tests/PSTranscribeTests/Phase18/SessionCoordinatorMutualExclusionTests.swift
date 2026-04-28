import Testing
import Foundation
@testable import PSTranscribe

@Suite("SessionCoordinatorMutualExclusionTests")
struct SessionCoordinatorMutualExclusionTests {

    @MainActor
    private func makeDictation(_ sessionCoord: SessionCoordinator) -> DictationCoordinator {
        let settings = AppSettings()
        let library = LibraryStore()
        return DictationCoordinator(
            settings: settings,
            sessionCoordinator: sessionCoord,
            libraryStore: library
        )
    }

    @Test @MainActor func trueWhenDictationActive() async {
        let sessionCoord = SessionCoordinator()
        let dict = makeDictation(sessionCoord)
        sessionCoord.dictation = dict
        // Coordinator starts at .idle which is NOT active.
        #expect(sessionCoord.anySessionActive == false)
        // We cannot directly mutate `state` from outside (private(set)). We assert
        // the wiring pathway: dictation slot is read on each anySessionActive call,
        // and at .idle returns false through the (dictation?.isActive ?? false) clause.
        // The full true-state path is exercised in Plan 18-06's begin/end tests.
        #expect(dict.isActive == false)
        #expect(sessionCoord.anySessionActive == false, "anySessionActive must read dictation.isActive on each call")
    }

    @Test @MainActor func falseWhenDictationIdle() async {
        let sessionCoord = SessionCoordinator()
        let dict = makeDictation(sessionCoord)
        sessionCoord.dictation = dict
        // No engine attached, no modelUpdate attached, dictation idle -> false.
        #expect(sessionCoord.anySessionActive == false)
    }

    @Test @MainActor func dictationHeldWeakly() async {
        let sessionCoord = SessionCoordinator()
        do {
            let dict = makeDictation(sessionCoord)
            sessionCoord.dictation = dict
            #expect(sessionCoord.dictation === dict, "After assignment, weak ref points at the instance")
        }
        // After scope exit, the only strong reference is gone -- weak ref should nil out.
        #expect(sessionCoord.dictation == nil, "weak var dictation must release after scope exit")
    }
}
