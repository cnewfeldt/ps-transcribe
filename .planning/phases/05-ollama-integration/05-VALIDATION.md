---
phase: 5
slug: ollama-integration
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-03
---

# Phase 5 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (bundled with Swift 6.2) |
| **Config file** | PSTranscribe/Package.swift testTarget "PSTranscribeTests" |
| **Quick run command** | `cd PSTranscribe && swift test --filter OllamaServiceTests` |
| **Full suite command** | `cd PSTranscribe && swift test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd PSTranscribe && swift test 2>&1 | tail -20`
- **After every plan wave:** Run `cd PSTranscribe && swift test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | OLMA-01 | unit (mock) | `swift test --filter OllamaServiceTests/checkConnection` | W0 | pending |
| 05-01-02 | 01 | 1 | OLMA-03 | unit (fixture) | `swift test --filter OllamaServiceTests/fetchModelsDecodesJSON` | W0 | pending |
| 05-01-03 | 01 | 1 | OLMA-05 | unit | `swift test --filter OllamaServiceTests/sessionTimeout` | W0 | pending |
| 05-01-04 | 01 | 1 | OLMA-06 | unit | `swift test --filter OllamaServiceTests/generateRequestNumCtx` | W0 | pending |
| 05-02-01 | 02 | 2 | OLMA-04 | unit | `swift test --filter AppSettingsOllamaTests` | Created by 05-02 Task 1 | pending |
| 05-02-02 | 02 | 2 | OLMA-02 | manual | SettingsView visual check | N/A | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `PSTranscribe/Tests/PSTranscribeTests/OllamaServiceTests.swift` -- stubs for OLMA-01, OLMA-03, OLMA-05, OLMA-06 (created by Plan 01 Task 1, TDD)
- [ ] JSON fixture data for OllamaTagsResponse decode test (inline in OllamaServiceTests.swift)
- [ ] `PSTranscribe/Tests/PSTranscribeTests/AppSettingsOllamaTests.swift` -- selectedOllamaModel persistence (created by Plan 02 Task 1)

*Existing Swift Testing infrastructure in PSTranscribeTests is sufficient -- no new framework config needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Settings Ollama section renders colored dot + label | OLMA-02 | SwiftUI view test infra not set up | Open Settings, verify green/red/gray dot with label |
| Model picker dropdown populates from Ollama | OLMA-03, OLMA-04 | Requires live Ollama instance | Start Ollama, open Settings, verify models in picker |
| Browse Models sheet opens and shows model list | OLMA-03 | UI interaction | Click "Browse Models" button, verify sheet content |
| OllamaState.refresh() triggers on Settings onAppear | OLMA-02 | Integration timing | Open Settings, observe status update |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [x] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
