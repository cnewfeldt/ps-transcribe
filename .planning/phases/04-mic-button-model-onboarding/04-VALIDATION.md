---
phase: 4
slug: mic-button-model-onboarding
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-03
---

# Phase 4 — Validation Strategy

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

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 0 | MICB-02 | unit | `swift test --filter MicButtonTests/testIdleClick` | ❌ W0 | ⬜ pending |
| 04-01-02 | 01 | 0 | MICB-04 | unit | `swift test --filter MicButtonTests/testErrorStateConditions` | ❌ W0 | ⬜ pending |
| 04-01-03 | 01 | 0 | ONBR-03 | unit | `swift test --filter OnboardingTests/testSuccessState` | ❌ W0 | ⬜ pending |
| 04-01-04 | 01 | 0 | ONBR-04 | unit | `swift test --filter OnboardingTests/testFailureState` | ❌ W0 | ⬜ pending |
| 04-01-05 | 01 | 0 | ONBR-05 | unit | `swift test --filter OnboardingTests/testRecordingDisabledWithoutModel` | ❌ W0 | ⬜ pending |
| 04-xx-xx | xx | 1+ | MICB-01 | manual-only | n/a -- UI structure removal | N/A | ⬜ pending |
| 04-xx-xx | xx | 1+ | MICB-03 | manual-only | n/a -- animation + UI event | N/A | ⬜ pending |
| 04-xx-xx | xx | 1+ | MICB-05 | manual-only | n/a -- NSApp.sendAction side effect | N/A | ⬜ pending |
| 04-xx-xx | xx | 1+ | MICB-06 | manual-only | n/a -- macOS tooltip rendering | N/A | ⬜ pending |
| 04-xx-xx | xx | 1+ | ONBR-01 | manual-only | n/a -- AppStorage gating | N/A | ⬜ pending |
| 04-xx-xx | xx | 1+ | ONBR-02 | manual-only | n/a -- real network + UI | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `Tests/PSTranscribeTests/MicButtonTests.swift` -- stubs for MICB-02 (idle click starts last-used type), MICB-04 (error state on four conditions)
- [ ] `Tests/PSTranscribeTests/OnboardingTests.swift` -- stubs for ONBR-03 (success state), ONBR-04 (failure/retry state), ONBR-05 (recording disabled without model)

*Existing tests (LibraryEntryTests, LibraryStoreTests, ObsidianURLTests, TranscriptParserTests) need no changes.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| WaveformView removed from ContentView | MICB-01 | UI structure, no headless test | Build app, verify no waveform visible; grep for WaveformView in ContentView returns no matches |
| Recording state shows pulsing ring, click stops | MICB-03 | Animation + UI event | Start recording, verify green ring animates; click mic icon, verify recording stops |
| Error click opens Settings | MICB-05 | NSApp.sendAction side effect | Simulate error condition, click red mic icon, verify Settings pane opens |
| Error tooltip shows all errors | MICB-06 | macOS tooltip rendering | Simulate multiple errors, hover mic icon, verify tooltip lists all errors newline-separated |
| First launch shows onboarding | ONBR-01 | AppStorage gating | Delete defaults, launch app, verify onboarding wizard appears |
| Download shows progress indicator | ONBR-02 | Real network + UI | Delete model files, trigger onboarding, verify progress bar renders during download |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
