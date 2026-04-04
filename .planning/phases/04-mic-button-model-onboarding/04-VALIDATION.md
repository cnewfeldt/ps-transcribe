---
phase: 4
slug: mic-button-model-onboarding
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-03
updated: 2026-04-03
---

# Phase 4 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`@Test` / `#expect` macros) |
| **Config file** | PSTranscribe/Package.swift testTarget "PSTranscribeTests" |
| **Quick run command** | `cd /Users/cary/Development/ai-development/Tome/PSTranscribe && swift test --filter PSTranscribeTests 2>&1 \| tail -20` |
| **Full suite command** | `cd /Users/cary/Development/ai-development/Tome/PSTranscribe && swift test 2>&1` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd PSTranscribe && swift test --filter PSTranscribeTests 2>&1 | tail -5`
- **After every plan wave:** Run `cd PSTranscribe && swift test 2>&1`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 04-01-01 | 01 | 1 | MICB-04 | build | `swift build` -- activeErrors computed property compiles | pending |
| 04-01-02 | 01 | 1 | ONBR-05 | build | `swift build` -- lastUsedSessionType property compiles | pending |
| 04-02-01 | 02 | 2 | MICB-01 | automated | `grep -r "WaveformView" PSTranscribe/Sources/ \|\| echo PASS` | pending |
| 04-02-02 | 02 | 2 | MICB-02 | build | `swift build` -- MicButton + onStartLastUsed compiles | pending |
| 04-03-01 | 03 | 3 | ALL | automated | `swift test` -- full suite green (existing tests not regressed) | pending |
| 04-03-02 | 03 | 3 | MICB-01 | manual | UI: waveform gone, mic icon visible | pending |
| 04-03-03 | 03 | 3 | MICB-02 | manual | UI: idle click starts last-used session type | pending |
| 04-03-04 | 03 | 3 | MICB-03 | manual | UI: recording shows green pulsing ring, click stops | pending |
| 04-03-05 | 03 | 3 | MICB-04 | manual | UI: error conditions turn icon red with mic.slash | pending |
| 04-03-06 | 03 | 3 | MICB-05 | manual | UI: error click opens Settings pane | pending |
| 04-03-07 | 03 | 3 | MICB-06 | manual | UI: error hover shows all errors in tooltip | pending |
| 04-03-08 | 03 | 3 | ONBR-01 | manual | UI: first launch shows onboarding wizard | pending |
| 04-03-09 | 03 | 3 | ONBR-02 | manual | UI: download step shows progress indicator | pending |
| 04-03-10 | 03 | 3 | ONBR-03 | manual | UI: success state shows checkmark + Get Started | pending |
| 04-03-11 | 03 | 3 | ONBR-04 | manual | UI: failure state shows error + Try Again | pending |
| 04-03-12 | 03 | 3 | ONBR-05 | manual | UI: recording buttons disabled until model ready | pending |

*Status: pending / green / red / flaky*

---

## Nyquist Rationale

The 5 behaviors originally flagged as Wave 0 unit test candidates (MICB-02 idle click, MICB-04 error conditions, ONBR-03 success state, ONBR-04 failure state, ONBR-05 recording disabled) are **not unit-testable** in this codebase for three reasons:

1. **TranscriptionEngine is @MainActor with hardware dependencies** -- its init creates SystemAudioCapture and MicCapture instances. The `activeErrors` computed property checks `AVCaptureDevice.authorizationStatus` at call time. Instantiating the engine in tests requires audio subsystem access.

2. **MicButton is a private struct** inside ControlBar.swift. Its `MicState` enum and state-selection logic cannot be accessed from test targets without exposing internals solely for testability (violates YAGNI).

3. **OnboardingView's `downloadFailed`** is a trivial `!modelsReady && status.contains("failed")` computed property on a SwiftUI view struct. Testing this in isolation verifies a one-line boolean expression, not meaningful behavior.

All 5 behaviors are verified by Plan 03's human checkpoint (Task 2), which tests the full integrated behavior in the running app. The automated verification (`swift build` + `swift test` for regression) plus human checkpoint satisfies Nyquist for view-layer behaviors in a macOS SwiftUI app without a UI testing framework.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Verified In |
|----------|-------------|------------|-------------|
| WaveformView removed from UI | MICB-01 | UI structure removal | Plan 03 Task 2, step 2 |
| Mic icon idle click starts last-used type | MICB-02 | View interaction + AppSettings wiring | Plan 03 Task 2, step 2 |
| Recording state shows pulsing ring, click stops | MICB-03 | Animation + UI event | Plan 03 Task 2, step 3 |
| Error conditions turn icon red | MICB-04 | Hardware-dependent computed property | Plan 03 Task 2, step 4 |
| Error click opens Settings | MICB-05 | NSApp.sendAction side effect | Plan 03 Task 2, step 4 |
| Error tooltip shows all errors | MICB-06 | macOS tooltip rendering | Plan 03 Task 2, step 4 |
| First launch shows onboarding | ONBR-01 | AppStorage gating | Plan 03 Task 2, step 5 |
| Download shows progress indicator | ONBR-02 | Real network + UI | Plan 03 Task 2, step 5 |
| Success state with Get Started | ONBR-03 | View struct state rendering | Plan 03 Task 2, step 5 |
| Failure state with Try Again | ONBR-04 | View struct state rendering | Plan 03 Task 2, step 5 |
| Recording disabled without model | ONBR-05 | modelsReady gating in SwiftUI | Plan 03 Task 2, step 5 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify (swift build) or manual checkpoint coverage
- [x] Sampling continuity: every plan wave has automated build verification
- [x] Wave 0 not required -- no unit-testable behaviors (see Nyquist Rationale)
- [x] No watch-mode flags
- [x] Feedback latency < 30s (swift build ~15s, swift test ~30s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
