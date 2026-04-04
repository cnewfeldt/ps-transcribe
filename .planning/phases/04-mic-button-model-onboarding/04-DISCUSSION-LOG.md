# Phase 4: Mic Button + Model Onboarding - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-04-03
**Phase:** 04-mic-button-model-onboarding
**Areas discussed:** Recording type selection, Onboarding rework, Error state triggers & behavior, Mic button placement & animation

---

## Recording Type Selection

### How should the user choose between Call Capture and Voice Memo with a single mic button?

| Option | Description | Selected |
|--------|-------------|----------|
| Default + modifier | Mic button defaults to one type. Hold Shift or Option-click for the other. | |
| Context menu on long-press | Click starts most recently used type. Long-press shows menu. | |
| Keep two buttons, replace waveform only | Mic button is a status icon. Call Capture and Voice Memo buttons stay separate. | ✓ |

**User's choice:** Keep two buttons, replace waveform only
**Notes:** The mic button requirement means replacing the waveform visualizer with a status icon, not consolidating the start buttons.

### During recording, should clicking the mic status icon stop the recording?

| Option | Description | Selected |
|--------|-------------|----------|
| Clickable stop button | Clicking mic icon stops recording -- second way to stop. | ✓ |
| Visual indicator only | Not interactive. All start/stop in control bar. | |
| Clickable for error only | Only clickable in error state to open settings. | |

**User's choice:** Clickable stop button
**Notes:** Mic icon is fully interactive across all states.

### When idle, should clicking the mic icon do anything?

| Option | Description | Selected |
|--------|-------------|----------|
| No action | Idle mic is decorative. | |
| Start default recording | Click starts most recently used recording type. | ✓ |

**User's choice:** Start default recording

### What's the default recording type for first-time use?

| Option | Description | Selected |
|--------|-------------|----------|
| Voice Memo | Simpler default, no system audio permissions needed upfront. | |
| Call Capture | Primary use case of the app -- dual-stream transcription. | ✓ |
| You decide | Claude picks. | |

**User's choice:** Call Capture
**Notes:** Reflects the app's primary purpose.

---

## Onboarding Rework

### Should the onboarding flow keep info slides or simplify?

| Option | Description | Selected |
|--------|-------------|----------|
| Keep current 3-step wizard | Welcome + Live Transcript + Model download. Already built. | ✓ |
| Model download only | Strip info slides. Straight to download prompt. | |
| Inline model banner | No separate view. Persistent banner in main UI. | |

**User's choice:** Keep current 3-step wizard
**Notes:** Existing wizard is already functional. Just add explicit success/fail states.

### When model download fails, what happens after close?

| Option | Description | Selected |
|--------|-------------|----------|
| Return to main UI, disabled | Close dismisses onboarding. Recording disabled. Retry in settings. | |
| Stay on download step with retry | Retry button replaces close. User stays until success. | ✓ |
| You decide | Claude picks. | |

**User's choice:** Stay on download step with retry
**Notes:** No escape without a working model.

---

## Error State Triggers & Behavior

### Which conditions trigger the red error state?

| Option | Description | Selected |
|--------|-------------|----------|
| Mic permission denied | macOS mic permission not granted or revoked. | ✓ |
| Mic device disconnected | Selected audio input device removed or unavailable. | ✓ |
| Model not loaded | modelsReady is false after a failed download attempt. | ✓ |
| System audio permission denied | Screen recording permission not granted. | ✓ |

**User's choice:** All four conditions
**Notes:** Mic icon becomes the single health indicator for the entire recording pipeline.

### When multiple errors exist, what does the tooltip show?

| Option | Description | Selected |
|--------|-------------|----------|
| Most critical first | Tooltip shows highest-priority error. Settings shows all. | |
| All errors listed | Tooltip lists all errors separated by newlines. | ✓ |
| You decide | Claude picks. | |

**User's choice:** All errors listed

---

## Mic Button Placement & Animation

### Where should the mic status icon live?

| Option | Description | Selected |
|--------|-------------|----------|
| Same spot as waveform | Between transcript and control bar. | |
| Center of control bar | Between Call Capture and Voice Memo buttons. | ✓ |
| Above transcript | Top of detail pane, next to recording name field. | |

**User's choice:** Center of control bar
**Notes:** Mic icon becomes the visual centerpiece of the control bar.

### How large should the mic icon be?

| Option | Description | Selected |
|--------|-------------|----------|
| Large prominent icon (40-48pt) | Centerpiece. Green ring pulses outward like radar. | ✓ |
| Medium icon (28-32pt) | Toolbar-button size. Subtle glow pulse. | |
| You decide | Claude picks sizing. | |

**User's choice:** Large prominent icon (40-48pt)
**Notes:** Green ring radiates outward like a radar ping. Control bar grows to accommodate.

---

## Claude's Discretion

- SF Symbol names for mic states
- Pulsing ring animation implementation details
- Control bar layout restructuring
- Whether audioLevel modulates ring intensity
- Error aggregation logic placement
- Settings pane error display layout

## Deferred Ideas

None -- discussion stayed within phase scope.
