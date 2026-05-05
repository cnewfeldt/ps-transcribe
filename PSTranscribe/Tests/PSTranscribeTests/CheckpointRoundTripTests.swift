// CheckpointRoundTripTests
// Phase 24 (NYQUIST-02) -- Phase 02 STAB-01 + STAB-03 (round-trip portions).
//
// Asserts SessionStore.writeCheckpoint persists to disk, and a fresh SessionStore
// instance recovers the checkpoint via scanIncompleteCheckpoints. This is the
// data-layer half of crash recovery.
//
// The end-to-end crash-recovery user flow (force-quit, relaunch, UI surfaces incomplete
// session) is WITHDRAWN per Phase 24 D-03 -- force-quit/SIGKILL out of scope.
//
// Deviation from plan: SessionStore's `init()` takes NO parameters and hardcodes
// its checkpoints dir to ~/Library/Application Support/PSTranscribe/sessions/.checkpoints.
// The plan assumed `init(directory: URL)` for tempDir isolation. The actor's API
// surface doesn't expose the dir override and changing it is an architectural
// change (Rule 4), so this test instead writes a UUID-tagged checkpoint, scans
// for it specifically, asserts round-trip identity, and cleans up via
// finalizeCheckpoint to keep the on-disk directory tidy.

import Testing
import Foundation
@testable import PSTranscribe

@Suite("CheckpointRoundTripTests", .serialized)
struct CheckpointRoundTripTests {

    @Test func writeCheckpointAndReloadFromFreshInstance() async throws {
        let store1 = SessionStore()

        // Use a UUID-tagged sessionId so we can isolate this test's checkpoint
        // from any pre-existing checkpoints on the developer machine.
        let uniqueSessionId = "test-checkpoint-\(UUID().uuidString)"
        let checkpoint = SessionCheckpoint(
            sessionId: uniqueSessionId,
            sessionStartTime: Date(),
            transcriptPath: "/tmp/example-\(uniqueSessionId).md",
            completedSteps: ["transcript_written"],
            isFinalized: false
        )
        // Defer cleanup so the test never leaves on-disk noise even on failure.
        defer {
            // Synchronous best-effort removal -- file path mirrors the actor's
            // own filename scheme at SessionStore.swift:58.
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            let path = appSupport?
                .appendingPathComponent("PSTranscribe/sessions/.checkpoints/\(uniqueSessionId).checkpoint.json")
            if let path { try? FileManager.default.removeItem(at: path) }
        }

        // The actor's writeCheckpoint depends on the .checkpoints directory existing.
        // SessionStore.init does NOT create it -- only startSession() does (via
        // ensureCheckpointsDirectory). For a pure-checkpoint round-trip without
        // startSession, we make the dir ourselves to mirror the post-startSession
        // state. This is consistent with how the actor self-recovers from missing
        // dirs in production.
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let checkpointsDir = appSupport.appendingPathComponent("PSTranscribe/sessions/.checkpoints", isDirectory: true)
        try FileManager.default.createDirectory(at: checkpointsDir, withIntermediateDirectories: true)

        await store1.writeCheckpoint(checkpoint)

        // Fresh instance -- must recover from on-disk state
        let store2 = SessionStore()
        let recovered = await store2.scanIncompleteCheckpoints()

        // Filter to OUR unique sessionId so coincident checkpoints from other
        // tests/runs don't pollute the assertion.
        let ours = recovered.filter { $0.sessionId == uniqueSessionId }
        #expect(ours.count == 1, "Expected exactly one checkpoint with our unique sessionId")
        #expect(ours.first?.transcriptPath == checkpoint.transcriptPath)
        #expect(ours.first?.completedSteps == ["transcript_written"])
        #expect(ours.first?.isFinalized == false)
    }
}
