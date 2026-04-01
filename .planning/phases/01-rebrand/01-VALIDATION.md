---
phase: 1
slug: rebrand
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-01
---

# Phase 1 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None -- no project-level test target exists in Package.swift |
| **Config file** | None |
| **Quick run command** | `cd PSTranscribe && swift build` |
| **Full suite command** | `cd PSTranscribe && swift build` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd PSTranscribe && swift build`
- **After every plan wave:** Run `swift build` + grep audit for residual "Tome" strings
- **Before `/gsd:verify-work`:** Full build must be green + manual launch verification
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | REBR-01 | manual | `swift build` (build smoke) | N/A | pending |
| 01-01-02 | 01 | 1 | REBR-02 | automated | `grep com.pstranscribe.app PSTranscribe/Sources/PSTranscribe/Info.plist` | pending | pending |
| 01-01-03 | 01 | 1 | REBR-03 | automated | `cd PSTranscribe && swift build` | pending | pending |
| 01-01-04 | 01 | 1 | REBR-04 | automated | `ls PSTranscribe/Sources/PSTranscribe/` | pending | pending |
| 01-01-05 | 01 | 1 | REBR-05 | automated | `grep -c "Tome" .github/workflows/*.yml` should be 0 | pending | pending |
| 01-01-06 | 01 | 1 | REBR-06 | automated | `grep pstranscribe PSTranscribe/Sources/PSTranscribe/Info.plist` | pending | pending |
| 01-01-07 | 01 | 1 | REBR-07 | automated | `grep "PS Transcribe" PSTranscribe/Sources/PSTranscribe/Info.plist` | pending | pending |
| 01-01-08 | 01 | 1 | REBR-08 | manual | Launch app with existing Tome UserDefaults | N/A | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- No test framework to install -- validation relies on `swift build` and grep checks

*Existing infrastructure (build system) covers automated phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| User-facing strings show "PS Transcribe" | REBR-01 | Requires visual UI inspection | Launch app, check window title, menu bar, About dialog |
| UserDefaults migration preserves settings | REBR-08 | Requires live app launch with existing Tome prefs | 1. Confirm ~/Library/Preferences/io.gremble.tome.plist exists with settings. 2. Launch PS Transcribe. 3. Verify vault paths, device ID, locale are populated in Settings. |

*Two behaviors require manual verification due to no test target.*

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
