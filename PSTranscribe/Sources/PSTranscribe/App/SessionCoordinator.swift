import Foundation
import Observation

/// App-scope coordinator that exposes a single source of truth for "is any session active?"
///
/// Phase 16 wires the meeting/voice-memo `TranscriptionEngine` source only (D-05, D-06).
/// Phases 17 and 18 will additively wire their own subsystem references via the
/// commented-out Optional fields below — the Optionals make this additive without forcing
/// a SessionCoordinator API change in subsequent phases.
///
/// `anySessionActive` is a COMPUTED property (not a stored Bool — D-05 explicitly forbids
/// the stored variant). Reading the source of truth on demand eliminates the "stuck active"
/// failure mode where a code path forgets to clear a flag on session end.
@Observable
@MainActor
final class SessionCoordinator {
    /// The meeting / voice-memo recording engine. Late-bound by `ContentView` after the
    /// engine is constructed (the engine is created lazily in ContentView's `.task` block,
    /// so it does not exist at app init time). Held weakly to avoid retain cycles if a
    /// future phase wires a back-reference from engine to coordinator.
    weak var engine: TranscriptionEngine?

    /// Phase 17 (Model Auto-Update). Held weakly: ModelUpdateService is owned at app scope
    /// (PSTranscribeApp) and wired here via direct assignment in Plan 17-04.
    /// When isApplying == true, anySessionActive returns true so no concurrent session
    /// can start during the atomic swap+reload window (CONTEXT.md D-18 / D-19).
    weak var modelUpdate: ModelUpdateService?

    // Phase 18 (Hotkey Dictation) will add:
    //   weak var dictation: DictationCoordinator?
    //
    // anySessionActive will then also include:
    //   || (dictation?.isActive ?? false)

    /// Single source of truth for whether ANY app-scope session is active. Reads
    /// each subsystem on demand. Phase 17 adds the modelUpdate branch so a model
    /// swap in progress is treated as an active session (prevents interleaving).
    var anySessionActive: Bool {
        (engine?.isRunning ?? false) || (modelUpdate?.isApplying ?? false)
    }

    init(engine: TranscriptionEngine? = nil) {
        self.engine = engine
    }
}
