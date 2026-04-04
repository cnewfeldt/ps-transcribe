---
phase: 6
slug: live-llm-analysis
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-04
---

# Phase 6 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (swift-testing, built into Swift 6.2) |
| **Config file** | PSTranscribe/Package.swift testTarget "PSTranscribeTests" |
| **Quick run command** | `cd PSTranscribe && swift test --filter PSTranscribeTests 2>&1` |
| **Full suite command** | `cd PSTranscribe && swift test 2>&1` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd PSTranscribe && swift test --filter PSTranscribeTests 2>&1`
- **After every plan wave:** Run `cd PSTranscribe && swift test 2>&1`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 0 | LLMA-05 | unit | `swift test --filter AnalysisCoordinatorTests` | No -- Wave 0 | ⬜ pending |
| 06-01-02 | 01 | 0 | LLMA-07 | unit | `swift test --filter TranscriptLoggerAnalysisTests` | No -- Wave 0 | ⬜ pending |
| 06-01-03 | 01 | 0 | D-09 | unit | `swift test --filter AnalysisCoordinatorTests` | No -- Wave 0 | ⬜ pending |
| 06-02-01 | 02 | 1 | LLMA-05 | unit | `swift test --filter AnalysisCoordinatorTests` | ❌ W0 | ⬜ pending |
| 06-02-02 | 02 | 1 | LLMA-05 | unit | `swift test --filter AnalysisCoordinatorTests` | ❌ W0 | ⬜ pending |
| 06-02-03 | 02 | 1 | LLMA-07 | unit | `swift test --filter TranscriptLoggerAnalysisTests` | ❌ W0 | ⬜ pending |
| 06-03-01 | 03 | 1 | LLMA-01..04 | manual | Visual inspection during recording | N/A | ⬜ pending |
| 06-03-02 | 03 | 1 | LLMA-06 | manual | Disconnect Ollama, verify panel hidden | N/A | ⬜ pending |
| 06-04-01 | 04 | 2 | D-09 | unit | `swift test --filter AnalysisCoordinatorTests` | ❌ W0 | ⬜ pending |
| 06-04-02 | 04 | 2 | timeout | unit | `swift test --filter OllamaServiceTests` | Partial | ⬜ pending |
| 06-04-03 | 04 | 2 | past-session | unit | `swift test --filter TranscriptParserTests` | Partial | ⬜ pending |

*Status: ⬜ pending . ✅ green . ❌ red . ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `Tests/PSTranscribeTests/AnalysisCoordinatorTests.swift` -- stubs for threshold, cooldown, in-flight guard, response parsing (LLMA-05, D-08, D-09)
- [ ] `Tests/PSTranscribeTests/TranscriptLoggerAnalysisTests.swift` -- stubs for appendAnalysis output, empty-state guard (LLMA-07, D-14)
- [ ] New tests in existing `Tests/PSTranscribeTests/OllamaServiceTests.swift` -- generate() timeout parameter behavior
- [ ] New tests in existing `Tests/PSTranscribeTests/TranscriptParserTests.swift` -- parseAnalysis() from file with ## Analysis section

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Panel displays summary, action items, key topics | LLMA-01..04 | SwiftUI visual layout requires human eye | Start recording, speak 10+ utterances, verify panel shows all three sections |
| No error state when Ollama unavailable | LLMA-06 | Requires Ollama service state manipulation | Disconnect Ollama, start recording, verify panel toggle hidden and no errors shown |
| Panel toggle visibility | D-02, D-05 | UI state depends on Ollama connection | Connect/disconnect Ollama, verify toggle shows/hides in ControlBar |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
