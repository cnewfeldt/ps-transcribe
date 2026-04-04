# Phase 4: Mic Button + Model Onboarding - Research

**Researched:** 2026-04-03
**Domain:** SwiftUI macOS animation, SF Symbols, state-driven UI, onboarding flow
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Mic Button Design**
- D-01: The mic icon replaces the waveform visualizer but does NOT replace the Call Capture / Voice Memo buttons. It is a clickable status indicator centered between the two start buttons in the control bar.
- D-02: Three states: idle (static mic icon), recording (green pulsing ring animation), error (red mic icon with circle/slash overlay).
- D-03: Idle click starts the most-recently-used recording type. Default for first-time use is Call Capture. Last-used type persisted in UserDefaults.
- D-04: Recording click stops the recording -- a second stop mechanism alongside the existing stop button in the control bar.
- D-05: Error click opens the Settings pane with the error message displayed.
- D-06: Icon size is 40-48pt, making it the visual centerpiece of the control bar. Control bar height grows to accommodate.
- D-07: Green pulsing ring animation radiates outward like a radar ping during recording.

**Error State**
- D-08: Four conditions trigger the red error state: mic permission denied, mic device disconnected, model not loaded (after failed download attempt), system audio permission denied.
- D-09: Hover tooltip shows ALL current errors listed (newline-separated), not just the most critical one.
- D-10: Error state is never silent -- if any of the four conditions is true, the mic icon is red regardless of other state.

**Onboarding**
- D-11: Keep the existing 3-step wizard (2 info slides + model download step). Do not strip the info slides.
- D-12: Add explicit success state with close/"Get Started" button per ONBR-03 (partially exists already).
- D-13: Failed download shows a retry button. User stays on the onboarding download step until the model download succeeds -- no way to dismiss to main UI without a model.
- D-14: Recording buttons disabled until model is downloaded (ONBR-05) -- already implemented via `modelsReady` gating in ControlBar.

**WaveformView Removal**
- D-15: WaveformView.swift is deleted entirely. The SpectrumVisualizer inside it is no longer used anywhere.
- D-16: The `audioLevel` property on TranscriptionEngine remains available but is no longer consumed by the UI for visualization.

### Claude's Discretion
- Exact SF Symbol names for mic icon states (e.g., `mic.fill`, `mic.slash`, `mic.badge.xmark`)
- Pulsing ring animation implementation (SwiftUI animation modifiers, timing curves)
- How the control bar layout restructures to center the mic icon between the two buttons
- Whether `audioLevel` is repurposed for the pulse ring intensity or purely timer-based
- Error aggregation logic implementation in TranscriptionEngine or a new observable
- Settings pane error display layout when opened from mic error click

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MICB-01 | Waveform visualizer replaced with a mic icon button | WaveformView removal from ContentView line 269; new MicButton view in ControlBar |
| MICB-02 | Idle state shows static mic icon; clicking starts recording | `mic.fill` SF Symbol + idle tap starts last-used session type via AppSettings.lastUsedSessionType |
| MICB-03 | Recording state shows green pulsing ring animation; clicking stops recording | SwiftUI `scaleEffect` + `opacity` animation with `.repeatForever`; onStop callback already in ControlBar |
| MICB-04 | Error state shows red mic icon with circle/slash overlay | `mic.slash` SF Symbol or `mic.fill` + `xmark.circle` overlay; drive from aggregated error state |
| MICB-05 | Clicking error state opens settings pane with error message displayed | `NSApp.sendAction(Selector("showSettingsWindow:"))` pattern already used in ControlBar gear button |
| MICB-06 | Hovering error state shows error message as tooltip | `.help()` modifier for native macOS tooltip behavior |
| ONBR-01 | First launch shows message to download transcription model before recording | Already implemented via `hasCompletedOnboarding` + `showOnboarding` + `OnboardingView` overlay |
| ONBR-02 | Download shows a loading/progress indicator | `ProgressView(value:)` already in OnboardingView download step |
| ONBR-03 | Successful download shows success message with close button | Partially exists -- "Get Started" button disabled until `modelsReady`; needs explicit success text |
| ONBR-04 | Failed download shows error message with close button | Does not exist -- `prepareModels()` sets `lastError` on failure but OnboardingView has no failure branch |
| ONBR-05 | Recording is disabled until model is successfully downloaded | Already implemented via `modelsReady` gating in ControlBar |
</phase_requirements>

---

## Summary

Phase 4 is a UI polish and resilience phase operating entirely within the existing SwiftUI codebase. No new frameworks or packages are required. The work divides cleanly into two tracks: (1) replace WaveformView with a three-state MicButton component in ControlBar, and (2) add explicit success/fail/retry branches to the existing OnboardingView download step.

The codebase is well-structured for these changes. ControlBar already receives `isRecording`, `audioLevel`, `errorMessage`, and `modelsReady` as parameters -- the mic button can use all of them. `TranscriptionEngine.lastError` is already the unified error sink for mic permission failures, model failures, and device disconnects; the only gap is that it stores only one error at a time and does not distinguish error categories (the four D-08 conditions). Error aggregation needs to either extend `TranscriptionEngine` with a computed property that inspects multiple conditions, or build a lightweight computed property inside ControlBar using its existing inputs.

OnboardingView already covers the success path (disabled "Get Started" button). The gap is the failure path: when `prepareModels()` sets `lastError` and `assetStatus = "Model download failed"`, OnboardingView has no branch for this -- it stays on the downloading spinner indefinitely. A failure detection pattern based on `assetStatus` matching "failed" is the cleanest hook since `modelsReady` stays false in both "still downloading" and "failed" states.

**Primary recommendation:** Build `MicButton` as a standalone SwiftUI view struct in ControlBar.swift (following the PulsingDot precedent), extend ControlBar's init to accept a `onStartLastUsed` callback, and add a `downloadFailed` computed property to OnboardingView derived from `assetStatus`.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | macOS 26 SDK | Declarative UI for MicButton, animations, layout | Already the entire UI layer |
| SF Symbols | macOS 26 SDK | Mic icon states, system-standard iconography | Used throughout ControlBar (`phone.fill`, `mic.fill`, `gearshape`) |
| UserDefaults | macOS 26 SDK | Persist `lastUsedSessionType` | Established pattern in AppSettings via `didSet` |
| AVCaptureDevice | macOS 26 SDK | Mic permission status query | Already used in `TranscriptionEngine.ensureMicrophonePermission()` |

### No New Dependencies

This phase adds no packages. All tools are in the existing SDK.

---

## Architecture Patterns

### Recommended Project Structure

No new files are strictly required. Changes are contained to:

```
PSTranscribe/Sources/PSTranscribe/
├── Views/
│   ├── ControlBar.swift         -- MicButton struct added, ControlBar layout refactored
│   ├── OnboardingView.swift     -- failure branch + retry button added
│   ├── ContentView.swift        -- WaveformView reference removed, onStartLastUsed callback wired
│   └── WaveformView.swift       -- DELETED
├── Settings/
│   └── AppSettings.swift        -- lastUsedSessionType: SessionType property added
```

### Pattern 1: MicButton as Nested Struct in ControlBar.swift

**What:** A private `MicButton` struct below `PulsingDot` in ControlBar.swift. Follows the exact same file-scoped component pattern established by `PulsingDot`.

**When to use:** Small, single-use component that is only needed by one parent view.

```swift
// Source: existing PulsingDot pattern in ControlBar.swift
private struct MicButton: View {
    enum MicState { case idle, recording, error }

    let state: MicState
    let audioLevel: Float      // optional: modulate ring scale
    let onTap: () -> Void

    @State private var ringScale: CGFloat = 1.0
    @State private var ringOpacity: Double = 0.6

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Green pulsing ring (recording only)
                if state == .recording {
                    Circle()
                        .stroke(Color.green, lineWidth: 2)
                        .frame(width: 56, height: 56)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)
                }
                // Mic icon
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundStyle(iconColor)
                    .frame(width: 44, height: 44)
            }
        }
        .buttonStyle(.plain)
        .focusable(false)
        .help(state == .error ? errorTooltip : "")
        .onAppear { startPulse() }
        .onChange(of: state) { startPulse() }
    }
}
```

**Animation approach (radar ping):** Two-phase animation -- scale from 1.0 to 1.6 while opacity drops from 0.6 to 0, then reset and repeat. This creates the "radiates outward" effect distinct from `PulsingDot`'s opacity-only pulse.

```swift
private func startPulse() {
    guard state == .recording else {
        ringScale = 1.0
        ringOpacity = 0.6
        return
    }
    withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
        ringScale = 1.6
        ringOpacity = 0.0
    }
}
```

**Note on `autoreverses: false`:** This is the key difference from `PulsingDot`'s `autoreverses: true`. A non-reversing animation that resets at the end is what produces the outward-radiating ping effect rather than a back-and-forth pulse.

### Pattern 2: Error Aggregation via Computed Property

**What:** A computed property `activeErrors: [String]` on `TranscriptionEngine` (or derived in ControlBar) that collects the four D-08 conditions.

**When to use:** Multiple independent boolean/string conditions that must all be visible in one tooltip.

```swift
// In TranscriptionEngine (preferred -- keeps error logic out of ControlBar)
var activeErrors: [String] {
    var errors: [String] = []
    // Condition 1: mic permission denied
    let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    if micStatus == .denied || micStatus == .restricted {
        errors.append("Microphone access denied. Enable in System Settings > Privacy > Microphone.")
    }
    // Condition 2: model not loaded after failed attempt
    if !modelsReady && assetStatus.lowercased().contains("failed") {
        errors.append("Speech model download failed. Check your internet connection.")
    }
    // Condition 3: lastError from mic/system audio capture
    if let err = lastError, !errors.contains(err) {
        errors.append(err)
    }
    return errors
}

var hasError: Bool { !activeErrors.isEmpty }
```

**Alternative:** Compute `hasError` and `errorTooltip` directly in ControlBar using the `errorMessage` string it already receives. This is simpler and keeps TranscriptionEngine unchanged. The tradeoff is that ControlBar doesn't have direct access to `AVCaptureDevice.authorizationStatus` without it being passed in. Recommend extending `TranscriptionEngine` with `activeErrors` since it already owns all four error-producing systems.

### Pattern 3: ControlBar Layout Restructure

**What:** The current ControlBar has two branches -- `isRecording` shows a stop button (full-width), and `!isRecording` shows an HStack of [CallCapture] [VoiceMemo] [Gear]. The mic icon needs to be centered between the two record buttons in the idle state, and centered alone in the recording state.

**Current structure:**
```
[Call Capture] [Voice Memo] [Gear]
```

**New idle structure:**
```
[Call Capture] [MicButton 44pt] [Voice Memo]
```
Gear moves -- see below.

**Recording state:** The full-width stop button row stays but MicButton appears below/above it, or MicButton replaces the stop button entirely (D-04 says mic click is a *second* stop mechanism, meaning the original stop button also persists).

**Recommended layout for recording state:**
```
[Stop Recording (full-width HStack with PulsingDot)] 
centered MicButton (recording ring) beneath or above
```

Given D-06 (mic icon is the visual centerpiece, 40-48pt), and that the stop button is a full-width bar, the cleanest solution is to embed the MicButton inside the stop recording row as its own centered element, and demote the text "Stop Recording" to a label. Or: show MicButton centered in its own row above the stop label row. The context says "control bar height grows to accommodate" -- so adding a row is acceptable.

**Gear button placement:** During idle state, gear can be removed from the HStack and placed as a small icon in the top-right corner of the control bar, or kept at far right if the MicButton + two buttons fit. With 40-48pt MicButton between two ~36pt buttons, the HStack may be wide enough without the gear. The gear could move to a persistent fixed position independent of recording state.

### Pattern 4: OnboardingView Failure Detection

**What:** Detect download failure by inspecting `assetStatus` for the "failed" string, since `modelsReady` is false in both downloading and failed states.

**When to use:** When a boolean flag (`modelsReady`) is insufficient to distinguish "in progress" vs. "failed" states.

```swift
// In OnboardingView
private var downloadFailed: Bool {
    !modelsReady && modelStatus.lowercased().contains("failed")
}
```

**Failure branch UI additions:**
- Icon: `xmark.circle` in red
- Title: "Download Failed"
- Body: error detail from `modelStatus` string
- Button: "Try Again" -- calls `prepareModels()` again via a new `onRetry: () -> Void` callback on `OnboardingView`

**Retry wiring in ContentView:**
```swift
OnboardingView(
    isPresented: $showOnboarding,
    modelStatus: transcriptionEngine?.assetStatus ?? "Waiting...",
    modelsReady: transcriptionEngine?.modelsReady ?? false,
    onRetry: {
        Task { await transcriptionEngine?.prepareModels() }
    }
)
```

`prepareModels()` already guards with `guard !modelsReady, asrManager == nil else { return }` -- this guard must be updated to allow retry when `modelsReady` is false and `asrManager == nil`. Currently if `asrManager` was set to a partial/failed state, the guard would block retry. Inspect whether a failed `prepareModels()` leaves `asrManager` non-nil; if it does, add a `downloadFailed` state flag or reset `asrManager = nil` in the catch block.

### Anti-Patterns to Avoid

- **Don't use `.animation(_:value:)` on a non-changing value for the ring.** The ring animation must trigger on `state == .recording` appearing, not on `audioLevel` changes. Use `.onAppear` and `.onChange(of: state)` to imperatively start/stop the animation.
- **Don't add `lastError` for multiple errors simultaneously.** The existing `lastError: String?` stores one string. For MICB-06's multi-error tooltip, use the `activeErrors: [String]` computed approach and join them with `"\n"` for `.help()`. Don't replace `lastError` -- it is used throughout the codebase.
- **Don't gate `finish()` on anything.** OnboardingView's `finish()` sets `isPresented = false` which sets `hasCompletedOnboarding = true`. Per D-13, the user cannot dismiss to main UI without a model. This means: the "Get Started" button must remain `.disabled(!modelsReady)` and there must be no other dismiss path (no "Skip" on the model step, no swipe-to-dismiss). Verify the sheet's `isPresented` binding cannot be cleared by system gestures.
- **Don't start the ring animation when `state != .recording`.** The `onAppear` handler should be a no-op for idle/error states. Only call `withAnimation` when `state == .recording`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tooltip on hover | Custom hover-detection overlay | `.help("message")` | Native macOS tooltip behavior, accessibility-compliant, zero code |
| Settings window open | Custom window management | `NSApp.sendAction(Selector("showSettingsWindow:"), to: nil, from: nil)` | Already in ControlBar gear button; identical pattern for mic error tap |
| Mic permission check | Custom AVCapture query wrapper | `AVCaptureDevice.authorizationStatus(for: .audio)` | Already called in `ensureMicrophonePermission()` |
| Repeating animation | Timer-based manual updates | `.animation(.easeOut(duration:).repeatForever(autoreverses: false), value:)` | SwiftUI handles frame-level timing; no Timer needed |
| Last-used session type persistence | Custom file storage | `AppSettings` `didSet`/UserDefaults pattern | Established pattern; one new property in AppSettings |

---

## Common Pitfalls

### Pitfall 1: `repeatForever(autoreverses: false)` resets on re-render

**What goes wrong:** The ring scale/opacity values are SwiftUI `@State`. On any parent view re-render, `@State` may reset, killing the animation mid-cycle.

**Why it happens:** SwiftUI recreates view structs on every re-render. `@State` is preserved across re-renders of the same view identity, but if the parent conditionally shows/hides `MicButton`, the state is lost.

**How to avoid:** Ensure `MicButton` is always present in the view hierarchy (don't use `if state == .recording { MicButton(...) }`). Always render MicButton; pass the `state` enum as a parameter and branch internally. Use `.onChange(of: state)` to restart animation when entering recording state.

**Warning signs:** Animation stops after the first recording session ends and a new one starts.

### Pitfall 2: `prepareModels()` guard blocks retry

**What goes wrong:** After a failed download, `asrManager` might be `nil` (models never loaded) but `modelsReady` is also false. The current guard is `guard !modelsReady, asrManager == nil else { return }`. If we add a "reset and retry" flow, this guard passes correctly. However if the download partially succeeds (asrManager assigned but vad fails), `asrManager != nil` blocks retry.

**Why it happens:** The current code assigns `asrManager` before `vadManager`. If the vad load throws, `asrManager` is non-nil but `modelsReady` is false.

**How to avoid:** In the catch block of `prepareModels()`, reset both `asrManager = nil` and `vadManager = nil` before setting `lastError`. This ensures retry can proceed from a clean state.

**Warning signs:** Retry button tap does nothing (the guard returns immediately).

### Pitfall 3: Multi-line `.help()` tooltip

**What goes wrong:** `.help()` on macOS renders its string as-is. Newline characters (`\n`) may or may not render as line breaks depending on macOS version.

**Why it happens:** NSToolTip rendering of multiline strings is platform-dependent.

**How to avoid:** Test with two concurrent error conditions on the actual hardware. If newlines don't render, use " | " as separator instead. The requirement (D-09) says "newline-separated" -- confirm visually during QA.

**Warning signs:** Tooltip shows `\n` literal instead of a line break.

### Pitfall 4: ControlBar layout shift when switching recording states

**What goes wrong:** The control bar height increases to accommodate the 40-48pt MicButton. When switching from idle (two buttons + MicButton) to recording (stop bar + MicButton), the height should be stable. If heights differ, the window jerks.

**Why it happens:** Each branch renders different components with different natural heights.

**How to avoid:** Set a fixed `.frame(height:)` on the entire ControlBar VStack, or ensure both recording and idle branches produce identical total height. The existing stop button row uses `padding(.vertical, 10)` and the idle row also uses `padding(.vertical, 10)`. With the MicButton added, use a consistent outer frame.

**Warning signs:** Window height changes briefly when starting/stopping recording.

### Pitfall 5: `isPresented` sheet dismissed via window close

**What goes wrong:** On macOS, overlays with an `isPresented` binding can sometimes be dismissed by the user pressing Cmd-W or clicking outside.

**Why it happens:** The overlay is an `.overlay { }` modifier, not a sheet -- so it does NOT respond to Cmd-W. However, since it sets `hasCompletedOnboarding = true` in the `onChange(of: showOnboarding)` handler, ANY dismissal path (including programmatic) would mark onboarding complete without a model.

**How to avoid:** The `finish()` function in OnboardingView only fires when the "Get Started" button is enabled (`!modelsReady` keeps it disabled). The overlay approach means there is no system dismiss gesture. Verify during testing that nothing in ContentView can set `showOnboarding = false` except the binding passed to OnboardingView.

---

## Code Examples

### Radar Ping Animation (SwiftUI)

```swift
// Source: SwiftUI animation docs + existing PulsingDot pattern in ControlBar.swift
// Key: autoreverses: false produces a ring that scales out and disappears, then restarts
@State private var ringScale: CGFloat = 1.0
@State private var ringOpacity: Double = 0.6

Circle()
    .stroke(Color.green.opacity(0.7), lineWidth: 2.5)
    .frame(width: 52, height: 52)
    .scaleEffect(ringScale)
    .opacity(ringOpacity)
    .onAppear {
        withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
            ringScale = 1.8
            ringOpacity = 0.0
        }
    }
```

### SF Symbol Selection for Mic States

```swift
// Source: SF Symbols app + current codebase usage
// Idle:     "mic.fill"         -- already used in Voice Memo button
// Recording: "mic.fill"        -- same icon, distinguished by green ring
// Error:    "mic.slash"        -- built-in "mic with slash" symbol
// Alt error: "mic.fill" with xmark.circle badge overlay if more visible
var iconName: String {
    switch state {
    case .idle, .recording: return "mic.fill"
    case .error:             return "mic.slash"
    }
}
var iconColor: Color {
    switch state {
    case .idle:      return Color.fg2
    case .recording: return Color.green
    case .error:     return Color.recordRed
    }
}
```

### lastUsedSessionType in AppSettings

```swift
// Source: AppSettings.swift didSet pattern
var lastUsedSessionType: SessionType {
    didSet {
        UserDefaults.standard.set(lastUsedSessionType.rawValue, forKey: "lastUsedSessionType")
    }
}
// In init():
let rawType = defaults.string(forKey: "lastUsedSessionType") ?? SessionType.callCapture.rawValue
self.lastUsedSessionType = SessionType(rawValue: rawType) ?? .callCapture
```

**Requirement:** `SessionType` must be `RawRepresentable` with `String` rawValue. Check Models.swift -- it is `Codable` + `Sendable` but may not have explicit `rawValue`. Verify and add `String` rawValue if absent.

### OnboardingView Retry Callback

```swift
// Source: existing OnboardingView init pattern + ContentView wiring
struct OnboardingView: View {
    @Binding var isPresented: Bool
    let modelStatus: String
    let modelsReady: Bool
    let onRetry: () -> Void   // NEW

    private var downloadFailed: Bool {
        !modelsReady && modelStatus.lowercased().contains("failed")
    }
}

// In ContentView:
OnboardingView(
    isPresented: $showOnboarding,
    modelStatus: transcriptionEngine?.assetStatus ?? "Waiting...",
    modelsReady: transcriptionEngine?.modelsReady ?? false,
    onRetry: { Task { await transcriptionEngine?.prepareModels() } }
)
```

### Settings Window from Mic Error Tap

```swift
// Source: ControlBar.swift gear button (line 147-151)
// Identical pattern for mic error state tap
Button {
    if #available(macOS 14, *) {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    } else {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
} label: { ... }
```

### Error Display in Settings on Mic Click

Per D-05, clicking the error mic opens Settings with the error displayed. The Settings window is a separate `NSWindow` -- it cannot directly receive a SwiftUI binding. The cleanest approach: store the error in `AppSettings` (which is accessible globally) as a transient display property, and show it in SettingsView as a top-of-form banner. Alternatively, rely on the user seeing the error tooltip (D-09) before clicking, and simply open the Settings window -- the error context is in the tooltip.

Given implementation complexity, the simpler approach is: error click opens Settings (done via `sendAction`), and the error is already visible in the ControlBar error text above the buttons. Settings does not need to repeat it unless the user lost track. This decision is Claude's discretion.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Waveform spectrum visualizer (WaveformView.swift) | Mic status icon button | This phase | Simpler UI, less CPU (no animation per audio frame), clearer status |
| Single error string (lastError: String?) | Multi-condition error aggregation | This phase | All four D-08 conditions visible simultaneously |
| Passive error text above buttons | Actionable error mic button | This phase | Error is interactive, not just informational |
| OnboardingView: disabled "Get Started" on failure | OnboardingView: explicit failure + retry | This phase | User knows why they're stuck and can act |

---

## Open Questions

1. **[RESOLVED] SessionType has a String rawValue.**
   - Verified: `enum SessionType: String, Codable, Sendable` in Models.swift. `lastUsedSessionType` in AppSettings can use `.rawValue` directly for UserDefaults storage. No change to Models.swift needed.

2. **[RESOLVED] `prepareModels()` leaves `asrManager` non-nil after a partial failure.**
   - Verified: In TranscriptionEngine.swift, `self.asrManager = asr` executes before the `VadManager()` call. If VadManager initialization throws, `asrManager` is non-nil but `vadManager` is nil and `modelsReady` is false. The planner MUST add `self.asrManager = nil; self.vadManager = nil` in the `prepareModels()` catch block to enable retry.

3. **Control bar height with 40-48pt mic icon: how much does it grow?**
   - What we know: Current control bar uses `padding(.vertical, 10)` on the inner row. A 44pt icon + padding would need ~64pt total height vs the current ~44pt.
   - What's unclear: Whether the window's `minHeight: 400` and `defaultSize: 720x500` accommodate this growth gracefully.
   - Recommendation: Implement and visually verify. No code blocker.

---

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified -- this phase is pure SwiftUI/Swift changes within the existing macOS project).

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Swift Testing (swift-testing, `@Test` / `#expect` macros) |
| Config file | Package.swift testTarget "PSTranscribeTests" at Tests/PSTranscribeTests/ |
| Quick run command | `cd /Users/cary/Development/ai-development/Tome/PSTranscribe && swift test --filter PSTranscribeTests 2>&1 | tail -20` |
| Full suite command | `cd /Users/cary/Development/ai-development/Tome/PSTranscribe && swift test 2>&1` |

### Phase Requirements -- Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MICB-01 | WaveformView removed from ContentView | manual-only | n/a -- UI structure, no headless test | N/A |
| MICB-02 | Idle click starts last-used session type | unit | `swift test --filter MicButtonTests/testIdleClick` | Wave 0 |
| MICB-03 | Recording state shows ring; click stops | manual-only | n/a -- animation + UI event | N/A |
| MICB-04 | Error state icon on four conditions | unit | `swift test --filter MicButtonTests/testErrorStateConditions` | Wave 0 |
| MICB-05 | Error click opens Settings | manual-only | n/a -- NSApp.sendAction side effect | N/A |
| MICB-06 | Error tooltip shows all errors | manual-only | n/a -- macOS tooltip rendering | N/A |
| ONBR-01 | First launch shows onboarding | manual-only | n/a -- AppStorage gating | N/A |
| ONBR-02 | Download shows progress indicator | manual-only | n/a -- real network + UI | N/A |
| ONBR-03 | Success state shows close button enabled | unit | `swift test --filter OnboardingTests/testSuccessState` | Wave 0 |
| ONBR-04 | Failure state shows retry button | unit | `swift test --filter OnboardingTests/testFailureState` | Wave 0 |
| ONBR-05 | Recording disabled until model ready | unit | `swift test --filter OnboardingTests/testRecordingDisabledWithoutModel` | Wave 0 |

**Note on manual-only:** Animation, NSApp side effects, and tooltip rendering cannot be tested headlessly in a Swift Package test target without a running app. These are verified at the UI safety gate.

### Sampling Rate

- **Per task commit:** `swift test --filter PSTranscribeTests 2>&1 | tail -5`
- **Per wave merge:** `swift test 2>&1`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `Tests/PSTranscribeTests/MicButtonTests.swift` -- covers MICB-02, MICB-04 (AppSettings.lastUsedSessionType, error aggregation logic)
- [ ] `Tests/PSTranscribeTests/OnboardingTests.swift` -- covers ONBR-03, ONBR-04, ONBR-05 (downloadFailed computed property, modelsReady gating)

*(Existing tests: LibraryEntryTests, LibraryStoreTests, ObsidianURLTests, TranscriptParserTests -- no changes needed to these)*

---

## Sources

### Primary (HIGH confidence)

- Codebase direct inspection: ControlBar.swift, WaveformView.swift, OnboardingView.swift, ContentView.swift, TranscriptionEngine.swift, MicCapture.swift, SettingsView.swift, AppSettings.swift, AppDelegate/PSTranscribeApp.swift, CONVENTIONS.md, ARCHITECTURE.md
- CONTEXT.md locked decisions D-01 through D-16

### Secondary (MEDIUM confidence)

- SwiftUI animation documentation: `.repeatForever(autoreverses: false)` for outward-radiating ring vs. `autoreverses: true` for PulsingDot-style oscillation
- SF Symbols: `mic.fill`, `mic.slash` are confirmed present in SF Symbols 5+ (macOS 14+); `mic.badge.xmark` is available in SF Symbols 4+

### Tertiary (LOW confidence)

- Multi-line `.help()` tooltip rendering on macOS 26: not verified against physical device. The newline behavior in NSToolTip has historically been inconsistent. Flag for visual QA.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new dependencies, all in existing SDK
- Architecture: HIGH -- direct codebase inspection, patterns are clear and consistent
- Pitfalls: MEDIUM -- retry logic and animation state pitfalls derived from code reading and known SwiftUI patterns; not all verified by running the app
- Test coverage: MEDIUM -- framework confirmed, new test files identified but not yet written

**Research date:** 2026-04-03
**Valid until:** 2026-05-03 (stable SwiftUI/SF Symbols domain)
