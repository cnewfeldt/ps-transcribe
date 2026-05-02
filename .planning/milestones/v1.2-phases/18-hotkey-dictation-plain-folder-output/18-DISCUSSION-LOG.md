# Phase 18: Hotkey Dictation + Plain-Folder Output - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-27
**Phase:** 18-hotkey-dictation-plain-folder-output
**Areas discussed:** HUD content & visual density, Cancel & second-hotkey semantics, Library entry handling for dictations, Cold-start & failure UX

---

## HUD content & visual density

### Q1 — What should the floating HUD display during dictation?

| Option | Description | Selected |
|--------|-------------|----------|
| Text + timer + stop button | Live partial transcript, elapsed time (0:12), visible Stop button. SuperWhisper / Voxt pattern. Most discoverable for first-time users. | ✓ |
| Text + timer (no stop button) | Live partial transcript + elapsed time. No visible button — user uses hotkey or Escape. Smaller, less distracting. | |
| Live text only (sparsest) | Just live partial transcript. macOS Dictation feedback style. Cleanest, but no visual session length. | |
| Verbose (text + timer + stop + word count + cancel) | Full controls and stats. Power-user dense. Risks feeling busy for the dictation use case. | |

**User's choice:** Text + timer + stop button.

### Q2 — On stop, before HUD dismisses, what feedback?

| Option | Description | Selected |
|--------|-------------|----------|
| 'Copied to clipboard' for ~1.0s, then fade | ROADMAP success criterion #2 explicitly says 'briefly shows Copied to clipboard'. | ✓ |
| Instant dismiss, no message | HUD vanishes the instant stop is hit. Lowest friction. Ambient. | |
| Show output destinations briefly | 1.5s pill showing what was written: 'Copied + saved to ~/Documents/...'. Useful in `.both` mode. | |

**User's choice:** 'Copied to clipboard' for ~1.0s, then fade.

### Q3 — Visual style of the HUD panel?

| Option | Description | Selected |
|--------|-------------|----------|
| Match Chronicle aesthetic (paper bg, navy accent) | Same paper palette + navy as the main app. Visual cohesion. | |
| Native macOS HUD (vibrancy blur, system look) | NSVisualEffectView with .hudWindow material. Familiar macOS feel. | ✓ |
| Minimal neutral (dark gray translucent) | macOS Dictation feedback style — dark rounded pill. | |

**User's choice:** Native macOS HUD (vibrancy blur, system look).

### Q4 — HUD position on screen?

| Option | Description | Selected |
|--------|-------------|----------|
| Bottom-center (SuperWhisper / macOS Dictation default) | Vertically centered across the bottom ~quarter of the active screen. | ✓ |
| Top-center (notification-style) | Top-center, just under the menu bar. Less likely to overlap with text fields. | |
| Bottom-right (status-overlay style) | Tucked into the bottom-right corner. Out of the way. Risks being missed. | |

**User's choice:** Bottom-center.

---

## Cancel & second-hotkey semantics

### Q1 — In toggle mode, what does a SECOND hotkey tap do?

| Option | Description | Selected |
|--------|-------------|----------|
| Stop & commit (write to clipboard / file) | Symmetric with 1st tap = start. Escape is the only cancel. | ✓ |
| Stop & cancel (no clipboard write) | 2nd tap = scrap. Confusing — contradicts symmetry. | |
| Stop & commit if ≥1s, cancel if <1s | Quick double-tap = cancel; intentional 2nd tap = commit. | |

**User's choice:** Stop & commit. Escape is the only way to cancel-without-commit.

### Q2 — Where does the 30s 'Cancel recording?' confirmation appear?

| Option | Description | Selected |
|--------|-------------|----------|
| Inline in HUD ('Press Esc again to cancel') | HUD reuses its existing space — no new window, no focus steal. | ✓ |
| Modal NSAlert dialog | Standard 'Cancel recording?' alert. Forces explicit confirmation but steals focus. | |
| Banner toast (auto-confirms after timeout) | Bottom-of-screen toast with auto-dismiss. | |

**User's choice:** Inline in HUD.

### Q3 — Press-and-hold mode — what triggers cancel?

| Option | Description | Selected |
|--------|-------------|----------|
| Release < 1s = silent cancel; ≥1s = commit | Treats accidental brief taps as no-op. Research-backed (FEATURES.md / Voxt). | ✓ |
| Any release commits; Escape during hold cancels | Strict press-and-hold: every release commits. | |
| Release < 1s = commit; >30s also requires confirmation | No accidental-tap filter; same 30s confirm threshold across modes. | |

**User's choice:** <1s = silent cancel, ≥1s = commit.

### Q4 — Cancel cleanup behavior — what gets discarded?

| Option | Description | Selected |
|--------|-------------|----------|
| No clipboard write, no library entry, plain-folder file deleted if started | Atomic cancel — nothing persists. | ✓ |
| No clipboard write, no library entry, plain-folder file kept (truncated/marked cancelled) | Preserves file as forensic evidence. | |
| No clipboard write, library entry kept (marked cancelled), file kept | Library shows cancelled sessions for transparency. | |

**User's choice:** Atomic cancel — nothing persists.

---

## Library entry handling for dictations

### Q1 — Does every dictation save a library entry?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, every successful dictation — even one-word | Maximum recoverability. | ✓ |
| Only if ≥5 words OR ≥2s of audio | Filters trivial/accidental dictations. | |
| Configurable threshold (default ≥5 words) | Setting under Dictation. | |
| Only when output mode includes plain folder | .clipboard mode = ephemeral, no library row. | |

**User's choice:** Every successful dictation — no filtering.

### Q2 — How should dictation entries be NAMED in the library?

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-name from first ~5 words of transcript | 'Quick reminder to email Sarah about…' — instantly scannable. | ✓ |
| Date-based generic name ('Dictation 2026-04-27 14:32') | Predictable, sortable, never surprises. | |
| Auto-name from first words, fallback to date if < 5 words | Best of both. | |

**User's choice:** Auto-name from first ~5 words.

### Q3 — Where do dictation entries appear in the library UI?

| Option | Description | Selected |
|--------|-------------|----------|
| Inline alongside meetings, with a 'D' or mic-fill icon | Single timeline view. | ✓ |
| Separate section/filter ('Dictations') | LibrarySidebar gains a top-level filter pill. | |
| Inline + filter pill (both) | Default mixed; user can filter. | |

**User's choice:** Inline alongside meetings, distinguished by a `mic.fill` icon.

### Q4 — Plain-folder output — does the library row LINK to the plain-folder file, or to a copy in app storage?

| Option | Description | Selected |
|--------|-------------|----------|
| Library row points at the plain-folder file directly | Single source of truth. User-deleted files trigger existing missing-file UX. | ✓ |
| Always copy to app storage; plain folder is just additional output | Library has its own copy. | |
| Clipboard-only mode — no file at all, library shows transcript inline | Mixed model based on mode. | |

**User's choice:** Library row points at plain-folder file directly. (When mode is `.clipboard`-only, library row stores transcript inline since there is no file.)

---

## Cold-start & failure UX

### Q1 — FluidAudio model warm-up strategy?

| Option | Description | Selected |
|--------|-------------|----------|
| Eager: pre-warm at app launch (load models in background) | First hotkey is instant. Cost: ~500MB resident memory always. | ✓ |
| Lazy: load on first hotkey press; HUD shows 'Loading model…' | No memory cost when not dictating. First-press latency 5-30s. | |
| Smart-eager: pre-warm only if dictation hotkey is set/configured | Honors privacy-conscious users who disable dictation. | |
| Reuse existing engine if available; pre-warm only if no main engine yet | Conditional sharing of the meeting engine. | |

**User's choice:** Eager pre-warm at app launch.

### Q2 — Hotkey pressed during a meeting recording — what happens?

| Option | Description | Selected |
|--------|-------------|----------|
| HUD appears briefly: 'Recording in progress — dictation unavailable' | Auto-dismisses after ~1.5s. | ✓ |
| Silent no-op (nothing happens visually) | Lowest noise. Risk: user thinks hotkey is broken. | |
| Menu bar icon flashes briefly to acknowledge press | Subtle. No floating UI. | |

**User's choice:** HUD appears briefly with the unavailable notice.

### Q3 — Plain-folder write fails (permissions, missing folder, disk full)?

| Option | Description | Selected |
|--------|-------------|----------|
| Fall back silently to clipboard-only; log error; library entry still created | Maximum graceful degradation. | ✓ |
| HUD shows error 'Couldn't save to folder — copied to clipboard'; library entry created | Informs user but doesn't block. | |
| Abort dictation; HUD shows error; no clipboard, no library entry | Strictest — full abort. | |

**User's choice:** Silent fallback to clipboard-only, error logged to os_log.

### Q4 — Models still loading when user hits hotkey — what happens?

| Option | Description | Selected |
|--------|-------------|----------|
| Show HUD with 'Loading model…' state; transition to listening when ready | Honest about the wait. Recording starts only after models ready. | ✓ |
| Show HUD; queue audio buffer in memory; transcribe once models load | Captures from t=0. Higher complexity, memory cost. | |
| Block hotkey: brief notice 'Models loading, try again in a moment' | Hotkey is no-op until models ready. Simplest. | |

**User's choice:** HUD shows 'Loading model…', transitions to listening when ready (may lose first 1-2s of speech).

---

## Claude's Discretion

- HUD dimensions / typography / padding within native HUD style
- Settings section internal layout (flat vs sub-grouped)
- Hotkey-recorder validation: warn-but-allow vs hard-block on system-reserved combinations
- `NSPasteboard.changeCount` race handling (skip restore on mismatch)
- Pre-warm error path — fall back to lazy on first hotkey if launch-time `prepareModels()` fails
- Menu bar pulsing-mic icon design (DICT-03)
- `DictationCoordinator` storage shape — own `TranscriptStore` instance or simpler accumulator
- Settings UI for `clipboardRestoreDelay` (slider, stepper, defaults-only)
- "First ~5 words" tokenization specifics

## Deferred Ideas

- Configurable HUD position (DICT-FUT-01)
- Multi-locale dictation (DICT-FUT-02)
- Per-app hotkey behavior (DICT-FUT-03)
- Auto-paste via accessibility API (out of scope per REQUIREMENTS.md)
- LLM cleanup of dictated text (out of scope per 2026-04-04 scope reduction)
- Dictation history search (out of scope for v1.2)
- Configurable cancel threshold
- Min-words filter for library entries (rejected — every dictation logged)
- Configurable HUD content density / visual style
- Separate "Dictations" filter view in library
- Library copy in app storage when plain-folder configured
- Hard-block system-reserved hotkeys
