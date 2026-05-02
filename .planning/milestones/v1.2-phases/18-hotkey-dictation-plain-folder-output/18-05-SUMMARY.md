---
phase: 18-hotkey-dictation-plain-folder-output
plan: 05
subsystem: hud-window-controller
tags: [hud, nspanel, swiftui, nsvisualeffectview, screen-share-privacy, vibrancy, bottom-center, dictation]

# Dependency graph
requires:
  - phase: 18-hotkey-dictation-plain-folder-output
    plan: 04
    provides: DictationCoordinator.State enum (6 cases) -- DictationHUD switches on this
provides:
  - DictationWindowController -- @MainActor NSWindowController owning a borderless non-activating NSPanel with hudWindow vibrancy, sharingType = .none, bottom-center positioning with width clamping for narrow screens, show()/hide()/setContent() lifecycle
  - DictationHUD -- SwiftUI body with state-driven displayText/displayTextColor/showsStopButton/recordingIndicator covering all 6 DictationCoordinator.State cases; mm:ss timer formatter; 5 #Preview blocks
  - 3 GREEN window-controller tests (un-disabled): panelHasNoneSharingType, panelHasFloatingLevelAndCanJoinAllSpaces, panelPositionsAtBottomCenter
affects: [18-06, 18-08]
# Plan 18-06 (Wave 4) calls windowController.show()/hide()/setContent and binds the SwiftUI body to live coordinator state
# Plan 18-08 (PSTranscribeApp) instantiates the controller at app scope and pairs it with DictationCoordinator

# Tech tracking
tech-stack:
  added: []  # No new SwiftPM deps; built on AppKit + SwiftUI + Observation already in project
  patterns:
    - "@MainActor NSWindowController subclass owning an NSPanel constructed inside init (not from a XIB/storyboard)"
    - "NSVisualEffectView (.hudWindow / .behindWindow / .active) as the panel content backdrop, with NSHostingView<AnyView> layered on top via Auto Layout container"
    - "Bottom-center positioning math: vertically centered within the bottom quarter of NSScreen.main.visibleFrame; width clamps to min(default, screen.width - 2*margin) with a hard floor"
    - "SwiftUI HUD body parameterized by an enum-typed `state: DictationCoordinator.State` plus elapsed/partialText/onStop -- pure render, no @Observable subscriptions in this view (Wave 4 owns the binding closure)"

key-files:
  created:
    - PSTranscribe/Sources/PSTranscribe/App/DictationWindowController.swift
    - PSTranscribe/Sources/PSTranscribe/Views/DictationHUD.swift
  modified:
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/DictationWindowControllerTests.swift

key-decisions:
  - "panel.sharingType = .none set INLINE in init() before super.init, NOT relying on the AppDelegate didBecomeKeyNotification observer (PSTranscribeApp.swift:116-131). RESEARCH Pitfall #4: .nonactivatingPanel never becomes the key window, so the observer never fires for the HUD. Belt-and-suspenders explicit set is the only reliable path. Test panelHasNoneSharingType enforces."
  - "Width clamping floor at 280pt with margin of 20pt per edge (Open Question §4 resolution). Default 420pt is preserved when screen width >= 460pt; otherwise panel shrinks. Floor avoids unreadable HUD on extreme narrow displays."
  - "NSHostingView identified by container.subviews[1] (subviews[0] is the NSVisualEffectView). setContent() updates host.rootView in place rather than recreating the NSHostingView -- avoids tearing down the panel hierarchy on each state-bind change. Wave 4 pattern: install the binding closure once, let SwiftUI Observation propagate state changes."
  - "Test fix: NSWindow.SharingType.none must be fully qualified in #expect comparison. Bare `.none` resolves to Optional.none (nil) due to Swift type-inference preference for Optional when both members are reachable through the same dot syntax. Documented inline in the test."
  - "DictationHUD does NOT subscribe to @Observable state directly. It accepts state/elapsed/partialText/onStop as inputs. Wave 4 (Plan 18-06) supplies the closure to setContent() that reads coordinator state and rebuilds the view -- @Observable's tracking handles re-renders. This keeps the view side-effect-free and trivially previewable."

# Requirements traceability
# supports: [DICT-04, DICT-10]  # historical sibling field, retired in Phase 22
requirements-completed: []  # DICT-04 (HUD live partial transcription) and DICT-10 (HUD privacy mode) are NOT yet user-visible. The window+view land in this plan; user-facing show/hide/state-binding ships in Plan 18-06 (Wave 4) + Plan 18-08 (app-scope instantiation).

# Metrics
duration: 3min
completed: 2026-04-28
---

# Phase 18 Plan 05: DictationWindowController + DictationHUD Summary

**Two atomic commits land Wave 3 of Phase 18: the floating NSPanel host (DictationWindowController, ~140 lines) and the state-driven SwiftUI body (DictationHUD, ~180 lines including 5 #Preview blocks). 3 RED tests un-disabled and GREEN: panel knobs, sharingType privacy gate, bottom-center positioning math. Full suite: 175 tests passed across 33 suites, zero failures, zero regressions. swift build clean.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-04-28T18:02:28Z
- **Completed:** 2026-04-28T18:05:43Z
- **Tasks:** 2 (TDD on Task 1; pure-view on Task 2)
- **Files created:** 2 (DictationWindowController.swift, DictationHUD.swift)
- **Files modified:** 1 (DictationWindowControllerTests.swift -- un-disabled + real assertions)

## Accomplishments

### DictationWindowController.swift (`PSTranscribe/Sources/PSTranscribe/App/`, ~140 lines)

`@MainActor final class DictationWindowController: NSWindowController` constructed by:

- Building an `NSPanel(contentRect: 420x56, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)`
- Setting privacy-gate properties INLINE before `super.init`:
  - `panel.sharingType = .none` (DICT-10 / Pitfall #4)
  - `panel.level = .floating`
  - `panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]`
  - `panel.hidesOnDeactivate = false`, `isReleasedWhenClosed = false`, `isMovableByWindowBackground = false`
  - `backgroundColor = .clear`, `hasShadow = true`, `isOpaque = false`
- Layering an `NSVisualEffectView` (`.hudWindow` material, `.behindWindow` blending, `.active` state, 12pt cornerRadius, masksToBounds) under an `NSHostingView<AnyView>(rootView:)`
- Wiring both into a parent `NSView` container via Auto Layout (top/leading/trailing/bottom anchors equal to container)

Lifecycle methods:

- `setContent(_ rootView: AnyView)` -- replaces the hosting view's `rootView` in place (used by Wave 4 to rebind to live coordinator state)
- `positionAtBottomCenter()` -- clamps width to `min(420, screenFrame.width - 40)` with floor at 280pt; positions vertically centered within the bottom quarter of `NSScreen.main.visibleFrame`
- `show()` -- repositions then `orderFrontRegardless()` (re-call on each show in case screen config changed)
- `hide()` -- `orderOut(nil)` without releasing, so the same panel instance is reused

### DictationHUD.swift (`PSTranscribe/Sources/PSTranscribe/Views/`, ~180 lines)

`struct DictationHUD: View` with four inputs: `state: DictationCoordinator.State`, `elapsed: TimeInterval`, `partialText: String`, `onStop: () -> Void`.

Three-block layout per D-01:
```
[recording dot] [0:12 timer] [partial transcript or status]   [Stop]
```

State -> displayText mapping (locked verbatim from CONTEXT.md D-14, D-16):

| State                  | displayText                                       | dot                                            | Stop visible |
|------------------------|---------------------------------------------------|------------------------------------------------|--------------|
| `.idle`                | `""` (empty -- panel hides anyway)                | gray dim circle                                | no           |
| `.loadingModel`        | `"Loading model…"`                                | orange circle                                  | yes          |
| `.listening`           | `partialText` or `"Listening…"` if empty          | red circle, `.symbolEffect(.pulse, isActive:)` | yes          |
| `.cancellingPending`   | `"Press Esc again to cancel"` (secondary color)   | orange circle                                  | yes          |
| `.copied`              | `"Copied to clipboard"`                           | green checkmark.circle.fill                    | no           |
| `.blockedSessionActive`| `"Recording in progress — dictation unavailable"` (secondary) | exclamationmark.circle (secondary) | no |

mm:ss timer uses `String(format: "%d:%02d", mm, ss)` with `Int(seconds)` floor and `max(0, ...)` clamp.

5 `#Preview` blocks render each non-idle state at 420x56 over `.regularMaterial`. Idle is excluded because the panel is hidden in idle by design.

### Tests (`PSTranscribe/Tests/PSTranscribeTests/Phase18/DictationWindowControllerTests.swift`)

Un-disabled all three previously-disabled tests, replaced placeholder bodies with real assertions:

| Test | Asserts |
|------|---------|
| `panelHasNoneSharingType` | `ctrl.window?.sharingType == NSWindow.SharingType.none` (fully qualified to disambiguate Optional.none) |
| `panelHasFloatingLevelAndCanJoinAllSpaces` | `panel.level == .floating`; `collectionBehavior` contains `.canJoinAllSpaces` AND `.fullScreenAuxiliary`; `styleMask` contains `.borderless` AND `.nonactivatingPanel` |
| `panelPositionsAtBottomCenter` | After `show()`: `abs(frame.midX - visible.midX) <= 1.0`; `frame.minY >= visible.minY`; `frame.maxY <= visible.minY + visible.height/2` |

All three GREEN: `swift test --filter DictationWindowControllerTests` -> 3/3 passed in ~0.08s each.

Full suite regression: `swift test` -> 175 tests in 33 suites passed, 0 failed.

## Task Commits

1. **Task 1: DictationWindowController + un-disable window tests** -- `246883f` (feat)
2. **Task 2: DictationHUD SwiftUI body** -- `c88998f` (feat)

Plan-metadata commit (this SUMMARY + STATE/ROADMAP) follows.

## Files Created/Modified

| File | Status | Δ |
|---|---|---|
| `PSTranscribe/Sources/PSTranscribe/App/DictationWindowController.swift` | Created | +138 lines |
| `PSTranscribe/Sources/PSTranscribe/Views/DictationHUD.swift` | Created | +180 lines |
| `PSTranscribe/Tests/PSTranscribeTests/Phase18/DictationWindowControllerTests.swift` | Modified | +33 / -16 lines (un-disabled traits removed; placeholder bodies replaced with real assertions; one Type.none disambiguation comment) |

### Public API surface (DictationWindowController)

```swift
@MainActor
final class DictationWindowController: NSWindowController {
    init(rootView: AnyView)
    func setContent(_ rootView: AnyView)
    func positionAtBottomCenter()
    func show()
    func hide()
}
```

### Public API surface (DictationHUD)

```swift
struct DictationHUD: View {
    let state: DictationCoordinator.State
    let elapsed: TimeInterval
    let partialText: String
    let onStop: () -> Void
}
```

### Bottom-center positioning math (D-04)

```
let screenFrame = NSScreen.main.visibleFrame
let availableWidth = screenFrame.width - (2 * 20)              // 20pt edge margin per side
let targetWidth = min(420, max(280, availableWidth))           // clamp to default; floor at 280

let bottomBandTop = screenFrame.minY + (screenFrame.height / 4) // top of bottom-quarter band
let bottomBandMid = (screenFrame.minY + bottomBandTop) / 2     // vertical center of band
let x = screenFrame.midX - (targetWidth / 2)                   // horizontal center
let y = bottomBandMid - (panelHeight / 2)
```

For a typical 1440-tall display with 23pt menu bar (visibleFrame.minY = 23, visibleFrame.maxY = 1440 - dock):

- Band top: ~23 + (1417 / 4) = ~377
- Band mid: (23 + 377) / 2 = ~200
- Panel y: 200 - 28 = ~172 from bottom of visibleFrame

Result: panel sits comfortably above the Dock, in the lower third of the screen, vertically centered within the bottom-quarter band -- matches macOS Dictation / SuperWhisper conventions.

## Decisions Made

See frontmatter `key-decisions` for the canonical list. Highlights:

- **panel.sharingType = .none INLINE at init.** RESEARCH Pitfall #4 documents that .nonactivatingPanel never becomes the key window, so the existing AppDelegate didBecomeKeyNotification observer (PSTranscribeApp.swift:116-131) does not fire for the HUD. The explicit set is the only reliable privacy gate. `panelHasNoneSharingType` test enforces.
- **Width clamping floor at 280pt.** Open Question §4 resolution: keep default 420pt when screen is wide enough; clamp to `min(default, screen.width - 40)` with a hard 280pt floor for very narrow displays. Avoids unreadable text overflow.
- **setContent() updates host.rootView in place.** Wave 4 will install a binding closure once; the host view is identified by `container.subviews[1]` (subviews[0] is the visualEffect). Avoids tearing down the NSPanel hierarchy on each state change.
- **DictationHUD is parameterized, not @Observable-bound.** The view accepts `state: DictationCoordinator.State` etc. as plain inputs. Wave 4 supplies the closure that reads coordinator state inside `setContent`. Keeps the view side-effect-free and trivially previewable -- the 5 `#Preview` blocks render without instantiating a coordinator.
- **NSWindow.SharingType.none disambiguation.** Bare `.none` in `#expect(... == .none)` resolves to `Optional<SharingType>.none` (nil) instead of `SharingType.none` (rawValue 0). Use the fully-qualified form. Documented inline in the test.

## Patterns Established

- **NSWindowController-as-stable-host.** The panel and its NSVisualEffectView + NSHostingView live for the lifetime of the controller. Show/hide just toggles `orderFrontRegardless()` / `orderOut(nil)`; the SwiftUI tree stays mounted between sessions, eliminating mount/unmount cost.
- **Native HUD vibrancy via NSVisualEffectView + clear panel background.** `panel.backgroundColor = .clear` + visual-effect view as the bottom layer with `.hudWindow` material + 12pt cornerRadius + masksToBounds is the canonical recipe for a native macOS HUD look. NSWindow's own background is intentionally clear so the vibrancy material reads through.
- **Width-clamp-with-floor.** `min(default, max(floor, available))` keeps the HUD legible across screen sizes from compact-mode external displays up to the standard 27" iMac. Width re-evaluates on every `show()` so screen-config changes (display sleep, switching displays) are picked up automatically.
- **State enum -> displayText switch in pure SwiftUI.** Each State case has exactly one displayText, one indicator graphic, and one Stop-button visibility. The view's correctness is structural (exhaustive switch on the enum) -- if Wave 4 adds a State case, the `@ViewBuilder` would refuse to compile until all branches are handled.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Disambiguated NSWindow.SharingType.none in test**

- **Found during:** Task 1 GREEN run -- test compiled and ran but failed with `Expectation failed: (ctrl.window?.sharingType → NSWindowSharingType(rawValue: 0)) == (.none → nil)`
- **Issue:** Swift's type-inference for `#expect(ctrl.window?.sharingType == .none)` resolved `.none` to `Optional<NSWindow.SharingType>.none` (i.e. nil) instead of `NSWindow.SharingType.none` (rawValue 0). The two are name-collisions through the same dot syntax; Optional wins.
- **Fix:** Replaced `.none` with `NSWindow.SharingType.none` in the test, with an inline comment documenting the trap so future tests don't fall in.
- **Files modified:** `PSTranscribe/Tests/PSTranscribeTests/Phase18/DictationWindowControllerTests.swift`
- **Commit:** `246883f` (Task 1)
- **Why this is Rule 1, not a plan defect:** The plan's action spec wrote `.none` verbatim. The defect is in the test code, not the production code. Fixing the test rather than working around it on the production side keeps the production code idiomatic.

### Other adjustments (not Rule-1-4)

- **Internal subview lookup uses index-based access in setContent.** The plan's action spec used `container.subviews.first(where: { $0 is NSHostingView<AnyView> }) as? NSHostingView<AnyView>`. Switched to `container.subviews[1] as? NSHostingView<AnyView>` (with bounds guard) because (a) we control the construction order in init -- index 0 is always the NSVisualEffectView, index 1 is always the NSHostingView -- and (b) the `is NSHostingView<AnyView>` predicate doesn't compose well with generic specialization in Swift 6.2 (compile-time concern). Behavior identical; test panelPositionsAtBottomCenter exercises the path.

---

**Total deviations:** 1 auto-fix (Rule 1 -- test code disambiguation); 1 mechanical adjustment (subview lookup pattern).
**Impact on plan:** None. Both atomic, both verified by the existing acceptance criteria.

## Issues Encountered

None beyond the auto-fixed Rule 1 above.

## Authentication Gates

None -- pure local Swift compilation and AppKit + SwiftUI test execution.

## User Setup Required

None.

## Self-Check: PASSED

All acceptance criteria verified deterministically.

| Check | Expected | Actual | Pass |
|---|---|---|---|
| `[ -f PSTranscribe/Sources/PSTranscribe/App/DictationWindowController.swift ]` | exists | exists | yes |
| `grep -c "@MainActor" DictationWindowController.swift` | >= 1 | 1 | yes |
| `grep -c "final class DictationWindowController: NSWindowController"` | 1 | 1 | yes |
| `grep -c "panel.sharingType = .none"` | 1 | 1 | yes |
| `grep -c "[.borderless, .nonactivatingPanel]"` | 1 | 1 | yes |
| `grep -c "panel.level = .floating"` | 1 | 1 | yes |
| `grep -c "canJoinAllSpaces"` | >= 1 | 2 | yes |
| `grep -c "fullScreenAuxiliary"` | >= 1 | 2 | yes |
| `grep -c "NSVisualEffectView()"` | >= 1 | 1 | yes |
| `grep -c "material = .hudWindow"` | 1 | 1 | yes |
| `grep -c "NSHostingView"` | >= 1 | 3 | yes |
| `grep -c "func positionAtBottomCenter"` | 1 | 1 | yes |
| width clamping (`min(Self.defaultWidth`) | >= 1 | 1 | yes |
| `func show \| func hide` | >= 2 | 2 | yes |
| Test file un-disabled (`grep -c '\.disabled('`) | 0 | 0 | yes |
| Window tests pass | 3/3 | 3/3 | yes |
| `[ -f PSTranscribe/Sources/PSTranscribe/Views/DictationHUD.swift ]` | exists | exists | yes |
| `grep -c "struct DictationHUD: View"` | 1 | 1 | yes |
| `grep -c "DictationCoordinator.State"` | >= 1 | 1 | yes |
| 6 state cases handled | >= 6 | 14 (multi-switch) | yes |
| `grep -c "Loading model…"` | >= 1 | 1 | yes |
| `grep -c "Listening…"` | >= 1 | 1 | yes |
| `grep -c "Press Esc again to cancel"` | >= 1 | 1 | yes |
| `grep -c "Copied to clipboard"` | >= 1 | 1 | yes |
| `grep -c "Recording in progress — dictation unavailable"` | >= 1 | 1 | yes |
| `grep -c 'Button("Stop"'` | 1 | 1 | yes |
| `grep -c '"%d:%02d"'` | 1 | 1 | yes |
| `grep -c "#Preview"` | >= 1 | 5 | yes |
| `swift build` exits 0 | yes | yes | yes |
| Full suite green (`swift test`) | 0 failed | 0 failed | yes |
| Commit `246883f` exists | yes | yes | yes |
| Commit `c88998f` exists | yes | yes | yes |

## Threat Flags

None. Plan 18-05 introduces only the threats already enumerated in PLAN.md `<threat_model>` (T-18-05-01..04). All addressed:

- **T-18-05-01 (Information Disclosure -- HUD content visible in legacy CGWindowListCreateImage):** mitigated by inline `panel.sharingType = .none` in init. Test `panelHasNoneSharingType` enforces. ScreenCaptureKit limitation is documented in DictationWindowController's class doc-comment as an unfixable macOS API constraint.
- **T-18-05-02 (Information Disclosure -- create->sharingType-set window):** mitigated. The set happens INLINE before `super.init`, so the panel is never live with anything other than `.none`. The AppDelegate observer is irrelevant for non-activating panels (Pitfall #4).
- **T-18-05-03 (Tampering -- off-screen positioning on multi-monitor):** accept. `NSScreen.main` is the active mouse-cursor screen by Apple convention. `positionAtBottomCenter()` is re-invoked on each `show()` so screen-config changes are picked up.
- **T-18-05-04 (Denial of Service -- panel grows beyond narrow screen bounds):** mitigated by `min(default, screen.width - 40)` with 280pt floor. Open Question §4 resolution.

## Next Phase Readiness

- **Plan 18-06 (Wave 4) unblocked.** `DictationWindowController.show()`, `.hide()`, `.setContent(rootView: AnyView)` are stable callable surfaces. Wave 4 will:
  1. Inject the controller into `DictationCoordinator` (constructor parameter or property)
  2. Call `windowController.setContent(...)` with an `AnyView(DictationHUD(state: coordinator.state, elapsed: coordinator.elapsed, partialText: coordinator.partialText, onStop: { Task { await coordinator.endDictation() } }))` once at coordinator init, before any show
  3. Call `windowController.show()` from `beginDictation()` and `windowController.hide()` from the `.copied`-dismiss task / `cancelDictation()`
  4. Rely on `@Observable` propagation -- when `coordinator.state` mutates, SwiftUI re-renders the hosted body
- **Plan 18-08 unblocked.** PSTranscribeApp can instantiate the controller via `let controller = DictationWindowController(rootView: AnyView(EmptyView()))` and pass it into `DictationCoordinator(... windowController: controller)`. The controller owns the panel for app lifetime.
- **DictationHUD's State -> displayText mapping is contractually frozen** for downstream waves. If Wave 4 needs additional copy variants (e.g. truncated-error state), it adds a State case in DictationCoordinator.swift and the HUD's exhaustive switch enforces compile-time coverage.

The window+view layer is complete. Wave 4 owns the wiring.

---
*Phase: 18-hotkey-dictation-plain-folder-output*
*Completed: 2026-04-28*
