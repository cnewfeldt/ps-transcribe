---
phase: 10
slug: final-defect-fixes-obsidian-deeplink
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-07
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`import Testing`) |
| **Config file** | PSTranscribe/Package.swift |
| **Quick run command** | `cd PSTranscribe && swift test` |
| **Full suite command** | `cd PSTranscribe && swift test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd PSTranscribe && swift test`
- **After every plan wave:** Run `cd PSTranscribe && swift test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | SESS-06 | — | N/A | unit | `cd PSTranscribe && swift test --filter ObsidianURLTests` | ❌ W0 | ⬜ pending |
| 10-01-02 | 01 | 1 | SESS-06 | — | N/A | unit | `cd PSTranscribe && swift test --filter ObsidianURLTests` | ❌ W0 | ⬜ pending |
| 10-01-03 | 01 | 1 | SESS-06 | — | N/A | unit | `cd PSTranscribe && swift test --filter ObsidianURLTests` | ❌ W0 | ⬜ pending |
| 10-02-01 | 02 | 1 | D-04 | — | N/A | unit | `cd PSTranscribe && swift test --filter TranscriptParserTests` | Partial | ⬜ pending |
| 10-03-01 | 03 | 1 | D-05 | — | N/A | manual | N/A | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `PSTranscribe/Tests/PSTranscribeTests/ObsidianURLTests.swift` — stubs for SESS-06 URL construction (normal path, subdirectory, empty vault, file not under vault root, vault name extraction)
- [ ] Add `.named` speaker case to existing `TranscriptParserTests.swift`

*TranscriptParserTests.swift already exists -- add `.named` speaker case to existing suite, no new file needed*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Obsidian opens to correct note | SESS-06 | Requires Obsidian app running | Click "Open in Obsidian" on a library entry with vault paths configured |
| Disabled menu tooltip shows | D-03 | macOS UI interaction | Right-click library entry without vault paths configured, verify tooltip |
| Crash-recovered session type icon | D-05 | Requires simulated crash state | Create a checkpoint file, relaunch app, verify icon matches original type |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
