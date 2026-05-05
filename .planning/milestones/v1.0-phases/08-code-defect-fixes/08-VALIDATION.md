---
phase: 8
slug: code-defect-fixes
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-06
---

# Phase 8 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (swift-testing package) |
| **Config file** | Package.swift -- test target defined |
| **Quick run command** | `swift test --filter TranscriptParserTests` |
| **Full suite command** | `swift test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `swift test --filter` on the relevant test file
- **After every plan wave:** Run `swift test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 08-01-01 | 01 | 1 | D-01 | -- | Speaker.named round-trips through Codable | unit | `swift test --filter SpeakerCodableTests` | ❌ W0 | ⬜ pending |
| 08-01-02 | 01 | 1 | D-01 | -- | Legacy raw-string Speaker decodes correctly | unit | `swift test --filter SpeakerCodableTests` | ❌ W0 | ⬜ pending |
| 08-01-03 | 01 | 1 | D-01 | -- | TranscriptParser maps "Speaker N" to .named | unit | `swift test --filter TranscriptParserTests` | ✅ (add cases) | ⬜ pending |
| 08-02-01 | 02 | 1 | STAB-03 | -- | stopSession clears transcriptStore state | unit | `swift test --filter TranscriptStoreTests` | ❌ W0 | ⬜ pending |
| 08-03-01 | 03 | 1 | REBR-03 | -- | Frontmatter writes source/pstranscribe | unit | `swift test --filter TranscriptLoggerTests` | ❌ W0 (or grep) | ⬜ pending |
| 08-04-01 | 04 | 1 | STAB-01 | -- | Crash recovery surfaces incomplete session | integration | manual -- requires crash simulation | N/A (manual) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `Tests/PSTranscribeTests/SpeakerCodableTests.swift` -- covers Speaker Codable round-trip and legacy decode
- [ ] `Tests/PSTranscribeTests/TranscriptStoreTests.swift` -- covers clear() called on stop
- [ ] Existing `TranscriptParserTests` extended with diarized speaker test cases

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Crash recovery end-to-end | STAB-01 | Requires crash simulation mid-session | 1. Start recording 2. Force-kill app 3. Relaunch 4. Verify incomplete session appears in library with yellow badge 5. Select it and verify transcript loads |
| Speaker colored badges display | D-02 | Visual verification | 1. Load diarized transcript 2. Verify Speaker 2/3 have distinct colored badges |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
