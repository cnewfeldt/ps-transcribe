# Phase 4: Mic Button + Model Onboarding - Context

**Gathered:** 2026-04-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace the waveform visualizer with a three-state mic status icon centered in the control bar, and refine the existing onboarding wizard to include explicit success/fail/retry states for model download. The Call Capture and Voice Memo buttons remain as separate controls. No new recording types, no new capabilities beyond what MICB-01 through MICB-06 and ONBR-01 through ONBR-05 define.

</domain>

<decisions>
## Implementation Decisions

### Mic Button Design
- **D-01:** The mic icon replaces the waveform visualizer but does NOT replace the Call Capture / Voice Memo buttons. It's a clickable status indicator centered between the two start buttons in the control bar.
- **D-02:** Three states: idle (static mic icon), recording (green pulsing ring animation), error (red mic icon with circle/slash overlay).
- **D-03:** Idle click starts the most-recently-used recording type. Default for first-time use is Call Capture. Last-used type persisted in UserDefaults.
- **D-04:** Recording click stops the recording -- a second stop mechanism alongside the existing stop button in the control bar.
- **D-05:** Error click opens the Settings pane with the error message displayed.
- **D-06:** Icon size is 40-48pt, making it the visual centerpiece of the control bar. Control bar height grows to accommodate.
- **D-07:** Green pulsing ring animation radiates outward like a radar ping during recording.

### Error State
- **D-08:** Four conditions trigger the red error state: mic permission denied, mic device disconnected, model not loaded (after failed download attempt), system audio permission denied.
- **D-09:** Hover tooltip shows ALL current errors listed (newline-separated), not just the most critical one.
- **D-10:** Error state is never silent -- if any of the four conditions is true, the mic icon is red regardless of other state.

### Onboarding
- **D-11:** Keep the existing 3-step wizard (2 info slides + model download step). Do not strip the info slides.
- **D-12:** Add explicit success state with close/"Get Started" button per ONBR-03 (partially exists already).
- **D-13:** Failed download shows a retry button. User stays on the onboarding download step until the model download succeeds -- no way to dismiss to main UI without a model.
- **D-14:** Recording buttons disabled until model is downloaded (ONBR-05) -- this is already implemented via `modelsReady` gating in ControlBar.

### WaveformView Removal
- **D-15:** WaveformView.swift is deleted entirely. The SpectrumVisualizer inside it is no longer used anywhere.
- **D-16:** The `audioLevel` property on TranscriptionEngine remains available (used by SystemAudioCapture/MicCapture) but is no longer consumed by the UI for visualization.

### Claude's Discretion
- Exact SF Symbol names for mic icon states (e.g., `mic.fill`, `mic.slash`, `mic.badge.xmark`)
- Pulsing ring animation implementation (SwiftUI animation modifiers, timing curves)
- How the control bar layout restructures to center the mic icon between the two buttons
- Whether `audioLevel` is repurposed for the pulse ring intensity or purely timer-based
- Error aggregation logic implementation in TranscriptionEngine or a new observable
- Settings pane error display layout when opened from mic error click

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` -- MICB-01 through MICB-06, ONBR-01 through ONBR-05

### Core Source Files
- `PSTranscribe/Sources/PSTranscribe/Views/ControlBar.swift` -- Current control bar with Call Capture / Voice Memo buttons, error display, modelsReady gating. Mic icon will be added here.
- `PSTranscribe/Sources/PSTranscribe/Views/WaveformView.swift` -- Being deleted. Read to understand what it currently does (audio level visualization).
- `PSTranscribe/Sources/PSTranscribe/Views/OnboardingView.swift` -- Existing 3-step wizard with model download progress. Needs success/fail/retry state additions.
- `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift` -- References WaveformView at line 269 and OnboardingView. Session start/stop logic, `hasCompletedOnboarding` AppStorage.
- `PSTranscribe/Sources/PSTranscribe/Transcription/TranscriptionEngine.swift` -- `prepareModels()`, `modelsReady`, `assetStatus`, `lastError`, `audioLevel`. Model download lifecycle and error state source.
- `PSTranscribe/Sources/PSTranscribe/Audio/MicCapture.swift` -- Mic permission and device errors that feed into error state.
- `PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift` -- Settings pane that mic error click opens.

### Prior Phase Context
- `.planning/phases/03-session-management-recording-naming/03-CONTEXT.md` -- D-01: Library sidebar on left, transcript on right. ControlBar stays in bottom area.
- `.planning/phases/02-security-stability/02-CONTEXT.md` -- D-08/D-09: os.Logger pattern, verbose logging toggle.

### Codebase Analysis
- `.planning/codebase/CONVENTIONS.md` -- Naming patterns, SwiftUI patterns, concurrency patterns
- `.planning/codebase/ARCHITECTURE.md` -- Actor isolation model, @Observable patterns, data flow

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ControlBar` -- Already has `modelsReady` gating, `errorMessage` display, `onStop` callback. Mic icon integrates here.
- `PulsingDot` -- Existing pulsing animation component in ControlBar.swift. Pattern reusable for the green pulsing ring.
- `OnboardingView` -- Already has 3-step wizard with model download progress bar and stage-based progress mapping. Needs fail/retry additions.
- `TranscriptionEngine.lastError` -- Already captures model download failures and mic errors. Can be extended to aggregate multiple error sources.
- `TranscriptionEngine.assetStatus` -- String-based status used by OnboardingView's `downloadProgress` computed property.

### Established Patterns
- **@Observable + MainActor:** TranscriptionEngine, TranscriptStore, AppSettings. New error aggregation should follow this.
- **UserDefaults via didSet/AppStorage:** `hasCompletedOnboarding` uses @AppStorage. Last-used recording type should use the same pattern.
- **os.Logger:** `Logger(subsystem: "com.pstranscribe.app", category: "TypeName")` for any new logging.
- **Button styling:** `.buttonStyle(.plain)` + `.focusable(false)` throughout ControlBar. Mic button follows this.

### Integration Points
- **ContentView line 269:** `WaveformView(isRecording: isRunning, audioLevel: audioLevel)` -- remove this, mic icon moves to ControlBar.
- **ControlBar.init parameters:** Already receives `isRecording`, `audioLevel`, `errorMessage`, `modelsReady`, `onStop`. Mic icon can use all of these.
- **OnboardingView.init parameters:** Already receives `modelStatus`, `modelsReady`. Retry needs to call `prepareModels()` again.
- **AppSettings:** Add `lastUsedSessionType` persisted property for mic idle-click behavior.

</code_context>

<specifics>
## Specific Ideas

- The mic icon should feel like the "hero element" of the control bar -- 40-48pt, larger than the flanking buttons.
- Green pulsing ring animation radiates outward like a radar ping, not just opacity pulsing. Consider reusing `audioLevel` to modulate the ring intensity for an organic feel.
- The existing `PulsingDot` component (6-10pt red dot) is a smaller version of the same concept -- the green ring is its larger counterpart.
- Error tooltip should use `.help()` modifier for native macOS tooltip behavior.

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope.

</deferred>

---

*Phase: 04-mic-button-model-onboarding*
*Context gathered: 2026-04-03*
