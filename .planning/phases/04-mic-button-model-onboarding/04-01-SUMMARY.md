---
phase: 04-mic-button-model-onboarding
plan: "01"
subsystem: transcription-engine, settings, onboarding
tags: [error-aggregation, retry, onboarding, settings, persistence]
dependency_graph:
  requires: []
  provides:
    - TranscriptionEngine.activeErrors
    - TranscriptionEngine.hasError
    - TranscriptionEngine prepareModels() retry-safe
    - AppSettings.lastUsedSessionType
    - OnboardingView failure state with retry
    - ContentView onRetry wiring
  affects:
    - PSTranscribe/Sources/PSTranscribe/Transcription/TranscriptionEngine.swift
    - PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift
    - PSTranscribe/Sources/PSTranscribe/Views/OnboardingView.swift
    - PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift
tech_stack:
  added: []
  patterns:
    - activeErrors computed property aggregating multiple error conditions
    - didSet/UserDefaults persistence pattern for lastUsedSessionType
    - three-branch conditional view (success/failure/downloading)
    - onRetry callback threading from ContentView to OnboardingView
key_files:
  created: []
  modified:
    - PSTranscribe/Sources/PSTranscribe/Transcription/TranscriptionEngine.swift
    - PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift
    - PSTranscribe/Sources/PSTranscribe/Views/OnboardingView.swift
    - PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift
decisions:
  - activeErrors aggregates mic permission denied, model download failed status, and lastError -- no deduplication needed beyond exact string match
  - prepareModels() retry enabled by nilifying asrManager and vadManager in catch block -- guard !modelsReady, asrManager == nil already handles re-entry correctly
  - lastUsedSessionType defaults to .callCapture per D-03
  - downloadFailed computed from modelStatus.lowercased().contains("failed") -- avoids coupling to specific error string
  - Button label weight changed from .medium to .semibold per UI-SPEC typography contract
metrics:
  duration_minutes: 1
  completed_date: "2026-04-04"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 4
---

# Phase 04 Plan 01: TranscriptionEngine Errors + OnboardingView Retry Summary

**One-liner:** Added activeErrors list with mic/model/lastError aggregation, retry-safe prepareModels() via manager nil-reset, lastUsedSessionType persisted in UserDefaults, and OnboardingView three-state failure/retry/success branch wired to ContentView.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | TranscriptionEngine activeErrors + retry-safe catch + AppSettings.lastUsedSessionType | 4b6e6ad | TranscriptionEngine.swift, AppSettings.swift |
| 2 | OnboardingView failure/retry branch + ContentView onRetry wiring | 6b60279 | OnboardingView.swift, ContentView.swift |

## What Was Built

### TranscriptionEngine.swift

Added `activeErrors: [String]` computed property that aggregates:
1. Mic permission denied/restricted (via AVCaptureDevice.authorizationStatus)
2. Model download failed (modelsReady == false && assetStatus contains "failed")
3. lastError string (deduplicated against already-added errors)

Added `hasError: Bool` convenience property.

Fixed `prepareModels()` catch block to set `self.asrManager = nil` and `self.vadManager = nil` before setting lastError and assetStatus. This enables clean retry -- the guard `guard !modelsReady, asrManager == nil` at the top of prepareModels() will now pass correctly after a failure.

### AppSettings.swift

Added `lastUsedSessionType: SessionType` with didSet persisting via UserDefaults key "lastUsedSessionType". Init reads the stored value with `.callCapture` as default (D-03).

### OnboardingView.swift

- Added `onRetry: () -> Void` parameter
- Added `downloadFailed` computed property: `!modelsReady && modelStatus.lowercased().contains("failed")`
- Replaced binary (ready/downloading) model step with three-branch view: success (checkmark.circle + green), failure (xmark.circle + recordRed + "Download Failed" + modelStatus text), downloading (arrow.down.circle + progress bar)
- Failure state shows "Try Again" button (semibold) calling onRetry()
- "Get Started" button updated to semibold per UI-SPEC typography contract
- Downloading state preserves ProgressView and status text

### ContentView.swift

OnboardingView instantiation now passes `onRetry: { Task { await transcriptionEngine?.prepareModels() } }` to wire retry through to the engine.

## Deviations from Plan

None -- plan executed exactly as written.

## Known Stubs

None -- all data is wired to live engine state.

## Self-Check: PASSED

Files verified:
- TranscriptionEngine.swift: activeErrors, hasError, asrManager = nil in catch -- FOUND
- AppSettings.swift: lastUsedSessionType, didSet UserDefaults, SessionType(rawValue:) init -- FOUND
- OnboardingView.swift: onRetry parameter, downloadFailed, "Download Failed", "Try Again", onRetry() call -- FOUND
- ContentView.swift: onRetry: closure with prepareModels() -- FOUND
- Commits 4b6e6ad, 6b60279 -- FOUND
- swift build: complete with no errors -- PASSED
