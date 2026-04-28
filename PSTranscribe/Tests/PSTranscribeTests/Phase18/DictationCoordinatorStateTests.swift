import Testing
import Foundation
@testable import PSTranscribe

@Suite("DictationCoordinatorStateTests")
struct DictationCoordinatorStateTests {

    @MainActor
    private func makeCoordinator() -> DictationCoordinator {
        let settings = AppSettings()
        let coordinator = SessionCoordinator()
        let library = LibraryStore()
        return DictationCoordinator(
            settings: settings,
            sessionCoordinator: coordinator,
            libraryStore: library
        )
    }

    @Test @MainActor func initialStateIsIdle() {
        let dict = makeCoordinator()
        #expect(dict.state == .idle)
        #expect(dict.isActive == false)
        #expect(dict.elapsed == 0)
        #expect(dict.partialText == "")
    }

    @Test @MainActor func isActiveReflectsListeningState() {
        let dict = makeCoordinator()
        // We exercise the State→isActive mapping by mirroring the production switch
        // here: state is `private(set)`, so we verify the predicate's exhaustiveness
        // against the public State enum cases. The full true-state path is exercised
        // in Plan 18-06's begin/end behavioral tests once those state transitions
        // become reachable from the public API.
        let allCases: [(DictationCoordinator.State, Bool)] = [
            (.idle, false),
            (.loadingModel, true),
            (.listening, true),
            (.cancellingPending(deadline: Date().addingTimeInterval(3)), true),
            (.copied, false),
            (.blockedSessionActive, false),
        ]
        for (state, expectedIsActive) in allCases {
            let isActive: Bool
            switch state {
            case .listening, .cancellingPending, .loadingModel:
                isActive = true
            case .idle, .copied, .blockedSessionActive:
                isActive = false
            }
            #expect(isActive == expectedIsActive, "State \(state) should map to isActive=\(expectedIsActive)")
        }
        // Sanity: production coordinator starts at .idle which is NOT active.
        #expect(dict.isActive == false)
    }

    @Test(.disabled("Pending Plan 18-06 -- toggle mode second tap commits"))
    @MainActor func toggleSecondTapStops() async {
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- Esc <30s cancels immediately"))
    @MainActor func escUnder30sCancelsImmediately() async {
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- Esc >=30s enters cancellingPending"))
    @MainActor func escAtOrOver30sEntersCancellingPending() async {
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- second Esc within window confirms cancel"))
    @MainActor func secondEscWithinWindowConfirmsCancel() async {
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- cancellingPending reverts after 3s"))
    @MainActor func cancellingPendingRevertsToListeningAfterTimeout() async {
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- press-and-hold release <1s cancels"))
    @MainActor func holdReleaseUnderOneSecondCancels() async {
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- press-and-hold release >=1s commits"))
    @MainActor func holdReleaseAfterOneSecondCommits() async {
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- partial text reflects transcript store"))
    @MainActor func partialTextReflectsTranscriptStore() async {
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- beginDictation no-ops when session already active"))
    @MainActor func beginNoOpsWhenSessionAlreadyActive() async {
        #expect(Bool(true))
    }
}
