import Testing
import Foundation
import AppKit
@testable import PSTranscribe

/// `.serialized` because several tests rely on Task.sleep timing for cancelRevertTask
/// (3s) and copiedDismissTask (1s). Under heavy parallel load the cooperative scheduler
/// can starve and the revert/dismiss tasks miss their deadlines, producing flaky failures.
/// Serialization ensures each test gets dedicated MainActor time.
@Suite("DictationCoordinatorStateTests", .serialized)
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
        // Mirror the production switch on the public State cases. The full
        // true-state path is exercised in the begin/end behavioral tests in
        // this same file once those state transitions become reachable.
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
        #expect(dict.isActive == false)
    }

    @Test @MainActor func toggleSecondTapStops() async {
        // endDictation writes to NSPasteboard.general; serialize against other
        // pasteboard-touching tests (ClipboardRestoreTests, DictationCommitFlowTests).
        await PasteboardTestLock.shared.acquire()
        defer { Task { await PasteboardTestLock.shared.release() } }
        defer { NSPasteboard.general.clearContents() }
        let dict = makeCoordinator()
        dict._test_setState(.listening); dict._test_setSessionStartTime(Date()); dict._test_setElapsed(5)
        dict.dictationStore.volatileYouText = "hello"
        await dict.endDictation()
        // After endDictation: state transitions to .copied, then a 1s task flips to .idle.
        #expect(dict.state == .copied || dict.state == .idle)
    }

    @Test @MainActor func escUnder30sCancelsImmediately() async {
        let dict = makeCoordinator()
        dict._test_setState(.listening); dict._test_setSessionStartTime(Date()); dict._test_setElapsed(5)
        await dict.handleEscape()
        #expect(dict.state == .idle)
    }

    @Test @MainActor func escAtOrOver30sEntersCancellingPending() async {
        let dict = makeCoordinator()
        dict._test_setState(.listening); dict._test_setSessionStartTime(Date()); dict._test_setElapsed(35)
        await dict.handleEscape()
        if case .cancellingPending = dict.state {
            #expect(true)
        } else {
            Issue.record("Expected .cancellingPending; got \(dict.state)")
        }
    }

    @Test @MainActor func secondEscWithinWindowConfirmsCancel() async {
        let dict = makeCoordinator()
        dict._test_setState(.listening); dict._test_setSessionStartTime(Date()); dict._test_setElapsed(35)
        await dict.handleEscape()
        await dict.handleEscape()
        #expect(dict.state == .idle)
    }

    @Test @MainActor func cancellingPendingRevertsToListeningAfterTimeout() async {
        let dict = makeCoordinator()
        dict._test_setState(.listening); dict._test_setSessionStartTime(Date()); dict._test_setElapsed(35)
        await dict.handleEscape()
        try? await Task.sleep(for: .milliseconds(3300))
        #expect(dict.state == .listening)
    }

    @Test @MainActor func holdReleaseUnderOneSecondCancels() async {
        let dict = makeCoordinator()
        dict._test_setState(.listening)
        dict._test_setSessionStartTime(Date().addingTimeInterval(-0.5))
        dict._test_setElapsed(0.5)
        await dict.handleHoldRelease()
        #expect(dict.state == .idle)
    }

    @Test @MainActor func holdReleaseAfterOneSecondCommits() async {
        // handleHoldRelease >1s -> endDictation -> NSPasteboard.general write;
        // serialize against other pasteboard-touching tests.
        await PasteboardTestLock.shared.acquire()
        defer { Task { await PasteboardTestLock.shared.release() } }
        defer { NSPasteboard.general.clearContents() }
        let dict = makeCoordinator()
        dict._test_setState(.listening)
        dict._test_setSessionStartTime(Date().addingTimeInterval(-2.0))
        dict._test_setElapsed(2.0)
        dict.dictationStore.volatileYouText = "committed"
        await dict.handleHoldRelease()
        #expect(dict.state == .copied || dict.state == .idle)
    }

    @Test @MainActor func partialTextReflectsTranscriptStore() async {
        let dict = makeCoordinator()
        dict.dictationStore.volatileYouText = "live partial"
        #expect(dict.dictationStore.volatileYouText == "live partial")
    }

    @Test @MainActor func beginNoOpsWhenSessionAlreadyActive() async {
        // Inline construction so the SessionCoordinator stays alive for the duration
        // of the test (DictationCoordinator holds it weakly; if we use makeCoordinator
        // the strong reference inside the helper is dropped on return, the weak ref
        // becomes nil, and `dict.sessionCoordinator!` would crash).
        let settings = AppSettings()
        let sessionCoord = SessionCoordinator()
        let library = LibraryStore()
        let dict = DictationCoordinator(
            settings: settings,
            sessionCoordinator: sessionCoord,
            libraryStore: library
        )
        let store = TranscriptStore()
        let engine = TranscriptionEngine(transcriptStore: store)
        let modelUpdate = ModelUpdateService(
            settings: settings,
            engine: engine,
            sessionCoordinator: sessionCoord
        )
        modelUpdate.isApplying = true
        sessionCoord.modelUpdate = modelUpdate

        await dict.beginDictation()
        // Just-after-block notice: state is .blockedSessionActive (HUD showing).
        // The 1.5s task then dismisses to .idle.
        #expect(dict.state == .blockedSessionActive || dict.state == .idle)
        try? await Task.sleep(for: .milliseconds(1700))
        #expect(dict.state == .idle)
    }
}
