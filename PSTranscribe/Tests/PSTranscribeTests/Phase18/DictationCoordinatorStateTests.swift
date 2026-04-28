import Testing
import Foundation
@testable import PSTranscribe

@Suite("DictationCoordinatorStateTests")
struct DictationCoordinatorStateTests {

    @Test(.disabled("Pending Plan 18-04 -- DictationCoordinator skeleton"))
    @MainActor func initialStateIsIdle() {
        // After Wave 2: let coord = DictationCoordinator(...); #expect(coord.state == .idle)
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-04 -- isActive computed property"))
    @MainActor func isActiveReflectsListeningState() {
        // listening, cancellingPending, loadingModel -> isActive==true
        // idle, copied, blockedSessionActive -> isActive==false
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- toggle mode second tap commits"))
    @MainActor func toggleSecondTapStops() async {
        // begin, then end via second tap, state transitions through .copied
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- Esc <30s cancels immediately"))
    @MainActor func escUnder30sCancelsImmediately() async {
        // elapsed < 30s + Esc -> state == .idle
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- Esc >=30s enters cancellingPending"))
    @MainActor func escAtOrOver30sEntersCancellingPending() async {
        // elapsed >= 30s + Esc -> state == .cancellingPending(deadline:)
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- second Esc within window confirms cancel"))
    @MainActor func secondEscWithinWindowConfirmsCancel() async {
        // From .cancellingPending: second Esc -> state == .idle
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- cancellingPending reverts after 3s"))
    @MainActor func cancellingPendingRevertsToListeningAfterTimeout() async {
        // No second Esc -> after 3s -> state == .listening
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- press-and-hold release <1s cancels"))
    @MainActor func holdReleaseUnderOneSecondCancels() async {
        // hotkeyMode==.pressAndHold + release within 1s -> cancelDictation path
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-06 -- press-and-hold release >=1s commits"))
    @MainActor func holdReleaseAfterOneSecondCommits() async {
        // hotkeyMode==.pressAndHold + release after 1s -> endDictation path
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-04 -- partial text reflects transcript store"))
    @MainActor func partialTextReflectsTranscriptStore() async {
        // dictationStore.volatileYouText updates -> coord.partialText reflects it
        #expect(Bool(true))
    }

    @Test(.disabled("Pending Plan 18-04 -- beginDictation no-ops when session already active"))
    @MainActor func beginNoOpsWhenSessionAlreadyActive() async {
        // SessionCoordinator.anySessionActive == true (e.g. modelUpdate.isApplying)
        // beginDictation -> state == .blockedSessionActive briefly, then back to .idle
        #expect(Bool(true))
    }
}
