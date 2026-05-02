---
status: partial
phase: 17-model-auto-update
source: [17-VERIFICATION.md]
started: 2026-04-27T00:00:00Z
updated: 2026-04-27T00:00:00Z
---

## Current Test

[awaiting human testing — gated on manifest publication per RELEASE PREREQUISITE in 17-VERIFICATION.md]

## Tests

### 1. Settings > Speech Model version display (SC-1, MODEL-08)
expected: With live manifest published, Settings > Speech Model shows `Speech Model: v20260427 · Apr 27, 2026` (or `v{installed} → v{available}` with inline "Update available" pill); no modal alerts
result: [pending]
why_human: Requires live manifest URL to return 200; pre-publish returns 404 which exercises only the `.failed` path

### 2. Download progress and cancel (SC-3, MODEL-04)
expected: Click "Install Update" against a real update — progress bar fills incrementally; click Cancel mid-download — state restores to `.updateAvailable`; files in `parakeet-tdt-0.6b-v3/` are unchanged
result: [pending]
why_human: Requires a real downloadable model file update; current manifest URL is unpublished

### 3. Hot-swap without restart (SC-4, MODEL-05, MODEL-07)
expected: Complete a full update cycle (Install Update → download → apply); next transcription session uses the new model with no app restart; `installedModelVersion` updated in UserDefaults
result: [pending]
why_human: Requires live manifest + real model files; unit tests stub the reload handler

### 4. Auto-check throttle and toggle (D-10, D-13)
expected: Toggle "Automatically check for new speech models" OFF, quit and relaunch — no `[ModelUpdate]` Console.app log activity at +10s; manual "Check for Updates" still works with toggle OFF
result: [pending]
why_human: Requires running the app and observing Console.app output; cannot verify programmatically

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps

None — these are deferred-by-design items pending the manifest publication step in 17-VERIFICATION.md > RELEASE PREREQUISITE. Run `/gsd-verify-work 17` after publishing the manifest to capture results.
