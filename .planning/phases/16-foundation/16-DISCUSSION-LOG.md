# Phase 16: Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-27
**Phase:** 16-foundation
**Areas discussed:** Logger architecture, AppSettings key scope, anySessionActive design, DictationOutputMode default

---

## Logger Architecture

| Option | Description | Selected |
|--------|-------------|----------|
| Separate DictationLogger | New actor in Storage/DictationLogger.swift. Single-purpose: plain markdown, no frontmatter, no diarization, no speaker tracking. Zero risk of frontmatter leaking into plain-folder output. Mirrors existing one-actor-per-concern pattern. | ✓ |
| Extend TranscriptLogger | Add startPlainSession and finalizePlain methods to existing actor (per current roadmap line). Smaller code surface, but actor tracks two distinct session shapes and risks accidentally writing frontmatter to plain output. | |
| Both: shared base + two actors | Extract a base TranscriptWriter protocol; have both TranscriptLogger and DictationLogger conform. More upfront design work; pays off later if a third writer is ever added. | |

**User's choice:** Separate DictationLogger (Recommended)
**Notes:** Resolves contradiction between ROADMAP.md (says extend TranscriptLogger) and SUMMARY.md (says separate DictationLogger). Roadmap line for Phase 16 needs update.

---

## AppSettings Key Scope

| Option | Description | Selected |
|--------|-------------|----------|
| All six v1.2 keys upfront | Phase 16 adds dictationOutputMode, dictationFolderPath, dictationHotkeyMode, clipboardRestoreDelay, installedModelVersion, modelLastCheckedDate. Each gets default + UserDefaults didSet. Phases 17/18 only consume them. | ✓ |
| Models-level minimum only | Phase 16 adds only dictationOutputMode and dictationFolderPath. Phases 17/18 add their own keys. AppSettings.swift gets touched in three phases instead of one. | |
| All dictation keys + defer model keys | Phase 16 adds the four dictation/folder keys; Phase 17 adds model keys when ModelUpdateService lands. Argues model keys are tightly coupled to ModelUpdateService. | |

**User's choice:** All six v1.2 keys upfront (Recommended)
**Notes:** Matches roadmap success criterion #2 literally. One focused diff to AppSettings.swift, zero churn after.

---

## anySessionActive Design

| Option | Description | Selected |
|--------|-------------|----------|
| Computed @Observable property | SessionCoordinator at app scope owns engine + (later) dictation + (later) modelUpdate references. anySessionActive is computed on demand. Single source of truth, no synchronization risk. | ✓ |
| Separately-tracked @State Bool | PSTranscribeApp owns a Bool that meeting/dictation/model-update each set explicitly. Simpler at app scope. Higher risk of getting stuck "active" if a code path forgets cleanup. | |
| Notification-based broadcast | Each subsystem posts SessionStarted/SessionEnded events; observer at app scope tracks count. Decoupled but harder to reason about — race conditions if events arrive out of order. | |

**User's choice:** Computed @Observable property (Recommended)
**Notes:** Phase 16 wires the engine source only; 17/18 add their sources via Optional fields. SessionCoordinator is @MainActor @Observable, owned by PSTranscribeApp.

---

## DictationOutputMode Default

| Option | Description | Selected |
|--------|-------------|----------|
| .clipboard only | Default to clipboard-only. Matches SuperWhisper first-run UX. Plain folder is opt-in. Lowest surprise — nothing lands on disk by default. | ✓ |
| .both | Default to writing to both. Folder defaults to ~/Documents/PS Transcribe Dictations/. Surfaces the feature immediately. But files start landing on disk without explicit setup. | |
| Defer to first-dictation prompt | Phase 16 ships with no default — first dictation triggers an inline picker. More work in Phase 18; Phase 16 adds the AppSettings key as Optional. | |

**User's choice:** .clipboard only (Recommended)
**Notes:** Matches SuperWhisper. No surprise files on disk for users who never visit Settings.

---

## Claude's Discretion

- Exact file/symbol names where not enumerated in CONTEXT.md
- Whether SessionCoordinator lives in App/ or Models/ (recommend App/)
- Test scaffolding shape — limited to enum codability and AppSettings persistence round-trips since no user-visible behavior

## Deferred Ideas

- Per-app hotkey behavior (DICT-FUT-03) — beyond v1.2
- Configurable HUD position (DICT-FUT-01) — beyond v1.2
- TranscriptFormat enum on TranscriptLogger — rejected by D-01; revisit only if a third writer ever appears
- ContentView.isRunning call site migration — Claude's discretion in Phase 16 vs. defer to Phase 18
