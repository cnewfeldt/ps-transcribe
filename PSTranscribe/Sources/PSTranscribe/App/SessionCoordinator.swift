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

    // Phase 17 (Model Auto-Update) will add:
    //   weak var modelUpdate: ModelUpdateService?
    // Phase 18 (Hotkey Dictation) will add:
    //   weak var dictation: DictationCoordinator?
    //
    // anySessionActive will then become:
    //   (engine?.isRunning ?? false)
    //   || (dictation?.isActive ?? false)
    //   || (modelUpdate?.isApplying ?? false)

    /// Single source of truth for whether ANY app-scope session is active. Reads
    /// each subsystem on demand. Phase 16: only the engine source is wired.
    var anySessionActive: Bool {
        engine?.isRunning ?? false
    }

    init(engine: TranscriptionEngine? = nil) {
        self.engine = engine
    }
}
