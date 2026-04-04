---
phase: 04-mic-button-model-onboarding
plan: "02"
subsystem: ui, control-bar, mic-button
tags: [mic-button, waveform-removal, three-state-ui, animation, settings-wiring]
dependency_graph:
  requires:
    - TranscriptionEngine.activeErrors (from 04-01)
    - TranscriptionEngine.hasError (from 04-01)
    - AppSettings.lastUsedSessionType (from 04-01)
  provides:
    - MicButton struct with idle/recording/error states
    - ControlBar restructured layout (MicButton centered between record buttons)
    - WaveformView removed
    - onStartLastUsed callback wired to lastUsedSessionType
  affects:
    - PSTranscribe/Sources/PSTranscribe/Views/ControlBar.swift
    - PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift
    - PSTranscribe/Sources/PSTranscribe/Views/WaveformView.swift (deleted)
tech_stack:
  added: []
  patterns:
    - MicButton as always-present view (never conditionally removed -- preserves @State animation)
    - Radar ping animation via scaleEffect + opacity with repeatForever(autoreverses: false)
    - micTapped() routing to three different actions by state
    - NSApp.sendAction for settings window (macOS 14+ / pre-14 branch)
key_files:
  created: []
  modified:
    - PSTranscribe/Sources/PSTranscribe/Views/ControlBar.swift
    - PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift
  deleted:
    - PSTranscribe/Sources/PSTranscribe/Views/WaveformView.swift
decisions:
  - MicButton always in view hierarchy (never conditional) to prevent @State animation loss on insertion
  - Gear button moved to its own HStack row below idle state buttons (not in same row as record buttons)
  - micTapped() dispatches to onStartLastUsed / onStop / showSettingsWindow based on micState
  - settings.lastUsedSessionType persisted at top of startSession() before async Task block
metrics:
  duration_minutes: 3
  completed_date: "2026-04-04"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 2
  files_deleted: 1
---

# Phase 04 Plan 02: MicButton + ControlBar Restructure + WaveformView Removal Summary

**One-liner:** Three-state MicButton struct with radar-ping animation centered between record buttons in idle state, pulsing green ring in recording state, red mic.slash with tooltip in error state -- WaveformView deleted, ControlBar restructured, ContentView wired to lastUsedSessionType.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | MicButton struct + ControlBar layout restructure | a3318ca | ControlBar.swift |
| 2 | ContentView wiring -- WaveformView removal + ControlBar new params + lastUsedSessionType | 7d2fe3a | ContentView.swift, WaveformView.swift (deleted) |

## What Was Built

### ControlBar.swift

Added `private struct MicButton: View` with:
- `enum MicState { case idle, recording, error }` embedded in struct
- `iconName` computed property: `mic.fill` for idle/recording, `mic.slash` for error
- `iconColor` computed property: `Color.fg2` idle, `Color.green` recording, `Color.recordRed` error
- Green pulsing ring: `Circle().stroke` with `scaleEffect(ringScale)` and `opacity(ringOpacity)`, animated via `.easeOut(duration: 1.4).repeatForever(autoreverses: false)` from 1.0->1.8 scale and 0.6->0.0 opacity
- `.disabled(state == .idle && !modelsReady)` with `0.4` opacity when disabled
- `.help()` showing `errorTooltip` (newline-joined activeErrors) when in error state
- `startPulse()` triggered by `.onChange(of: state)` and `.onAppear` when recording

Added to `ControlBar` struct:
- `let hasError: Bool` -- drives micState
- `let activeErrors: [String]` -- joined for tooltip
- `let onStartLastUsed: () -> Void` -- called when mic tapped in idle state
- `micState: MicButton.MicState` computed property (error > recording > idle priority)
- `micTapped()` method routing: idle->onStartLastUsed, recording->onStop, error->showSettingsWindow

Restructured `ControlBar.body`:
- **Idle:** VStack with HStack `[Call Capture] [MicButton] [Voice Memo]` + HStack gear row below
- **Recording:** VStack with stop bar button + `MicButton` centered below
- `MicButton` always rendered in both branches (never conditionally inserted/removed)

### ContentView.swift

Updated `ControlBar` call site to pass:
- `hasError: transcriptionEngine?.hasError ?? false`
- `activeErrors: transcriptionEngine?.activeErrors ?? []`
- `onStartLastUsed: { let type = settings.lastUsedSessionType; startSession(type: type) }`

Removed `WaveformView(isRecording: isRunning, audioLevel: audioLevel)` from `detailView` live recording VStack.

Added `settings.lastUsedSessionType = type` at the start of `startSession(type:)` -- ensures every session start (from any trigger) persists the type for the mic button's next idle tap.

### WaveformView.swift

Deleted entirely. The `SpectrumVisualizer` component inside it is no longer referenced anywhere.

## Deviations from Plan

None -- plan executed exactly as written.

## Known Stubs

None -- MicButton states are wired to live TranscriptionEngine computed properties. Animation fires on real recording state changes.

## Self-Check: PASSED

Files verified:
- ControlBar.swift: `struct MicButton`, `enum MicState`, `let hasError`, `let activeErrors`, `let onStartLastUsed`, `mic.fill`, `mic.slash`, `repeatForever(autoreverses: false)`, `showSettingsWindow`, `scaleEffect(ringScale)` -- FOUND
- WaveformView.swift: does not exist on disk -- CONFIRMED
- ContentView.swift: no `WaveformView` reference -- CONFIRMED
- ContentView.swift: `hasError: transcriptionEngine?.hasError ?? false` -- FOUND
- ContentView.swift: `activeErrors: transcriptionEngine?.activeErrors ?? []` -- FOUND
- ContentView.swift: `onStartLastUsed:` -- FOUND
- ContentView.swift: `settings.lastUsedSessionType = type` -- FOUND
- Commits a3318ca, 7d2fe3a -- FOUND
- swift build: Build complete! -- PASSED
