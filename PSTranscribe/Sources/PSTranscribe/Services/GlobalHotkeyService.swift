import Foundation
import Observation
import KeyboardShortcuts

/// `@Observable @MainActor` wrapper around the KeyboardShortcuts library.
///
/// Phase 18 D-01 (Cmd+Shift+D default) / D-05 (toggle mode is the default; coordinator
/// interprets onKeyDown as begin/end). Mirrors the project's existing service-wrapper
/// pattern (ModelUpdateService, AppUpdaterController).
///
/// The library handles persistence internally via its `Defaults` system, so user
/// hotkey changes survive across launches with no extra UserDefaults plumbing.
/// UserDefaults key namespace: `KeyboardShortcuts_dictateGlobal`.
@Observable
@MainActor
final class GlobalHotkeyService {
    /// Set by `DictationCoordinator` at app init. Fires on `MainActor` when the user
    /// presses the registered hotkey. In `.toggle` mode this is begin-or-end.
    /// In `.pressAndHold` mode this is begin.
    var onKeyDown: (@MainActor () -> Void)?

    /// Set by `DictationCoordinator` at app init. Fires on `MainActor` when the user
    /// releases the registered hotkey. Used in `.pressAndHold` mode to drive the
    /// release-time semantics (D-07): release < 1s -> silent cancel, release >= 1s -> commit.
    /// Ignored in `.toggle` mode.
    var onKeyUp: (@MainActor () -> Void)?

    /// True when the user has a hotkey assigned (the library returns nil from
    /// `getShortcut(for:)` after the user clears the Recorder field). Coordinator
    /// can read this to short-circuit pre-warm for users who never set a hotkey.
    var hotkeyAssigned: Bool {
        KeyboardShortcuts.getShortcut(for: .dictateGlobal) != nil
    }

    init() {
        // Wire library callbacks once. The library guarantees these fire on MainActor
        // (verified in 18-RESEARCH.md Assumption A6 -- the library's example code does
        // direct UI updates from the callback). The `[weak self]` capture prevents a
        // retain cycle if the service ever outlives a transient owner.
        KeyboardShortcuts.onKeyDown(for: .dictateGlobal) { [weak self] in
            self?.onKeyDown?()
        }
        KeyboardShortcuts.onKeyUp(for: .dictateGlobal) { [weak self] in
            self?.onKeyUp?()
        }
    }
}

extension KeyboardShortcuts.Name {
    /// Default `Cmd+Shift+D`. Phase 18 D-01.
    /// The library auto-persists user changes to UserDefaults under
    /// `KeyboardShortcuts_dictateGlobal`. Cleared state (user hits Delete in the
    /// Recorder) maps to `getShortcut(for:) == nil`, exposed via `hotkeyAssigned`.
    static let dictateGlobal = Self(
        "dictateGlobal",
        default: .init(.d, modifiers: [.command, .shift])
    )
}
