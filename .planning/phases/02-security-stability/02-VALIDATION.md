---
phase: 2
slug: security-stability
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-02
---

# Phase 02 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None -- no test targets in Package.swift |
| **Config file** | None |
| **Quick run command** | `swift build` |
| **Full suite command** | `swift build` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `swift build`
- **After every plan wave:** Run `swift build`
- **Before `/gsd:verify-work`:** Full build must be green + manual verification checklist
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| TBD | 01 | 1 | SECR-01 | CI diff inspection | n/a | -- | ⬜ pending |
| TBD | 01 | 1 | SECR-05 | CI diff inspection | n/a | -- | ⬜ pending |
| TBD | 01 | 1 | SECR-07 | CI diff inspection | n/a | -- | ⬜ pending |
| TBD | 01 | 1 | SECR-08 | `git check-ignore -v test.p12` | Manual | ⬜ pending |
| TBD | 01 | 1 | SECR-12 | CI diff inspection | n/a | -- | ⬜ pending |
| TBD | 02 | 1 | SECR-02 | Manual: run debug build, check /tmp | n/a | -- | ⬜ pending |
| TBD | 02 | 1 | SECR-03 | Manual: set malformed vault path | n/a | -- | ⬜ pending |
| TBD | 02 | 1 | SECR-04 | Manual: check file location + `ls -la` | n/a | -- | ⬜ pending |
| TBD | 02 | 1 | SECR-06 | Manual: create session, `ls -la` vault | n/a | -- | ⬜ pending |
| TBD | 02 | 1 | SECR-09 | Manual: force-kill mid-write, verify file | n/a | -- | ⬜ pending |
| TBD | 02 | 1 | SECR-10 | Manual: set context with `../evil` | n/a | -- | ⬜ pending |
| TBD | 02 | 1 | SECR-11 | Code inspection | n/a | -- | ⬜ pending |
| TBD | 03 | 2 | STAB-01 | Manual: force-quit mid-session, relaunch | n/a | -- | ⬜ pending |
| TBD | 03 | 2 | STAB-02 | Manual: verify offset math | n/a | -- | ⬜ pending |
| TBD | 03 | 2 | STAB-03 | Manual: inspect App Support after session | n/a | -- | ⬜ pending |
| TBD | 03 | 2 | STAB-04 | Manual: deny mic permission, start recording | n/a | -- | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No test target exists and adding one is out of scope for Phase 2. Verification relies on `swift build` compilation gate + manual spot checks.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GH_TOKEN not in URLs | SECR-01 | CI workflow diff, not runtime | Inspect release-dmg.yml for `${{ secrets.GITHUB_TOKEN }}` in download URLs |
| No /tmp log file | SECR-02 | Requires running app | Build debug, run, check no `/tmp/Tome*.log` or `/tmp/PSTranscribe*.log` created |
| Vault path traversal blocked | SECR-03 | Requires runtime path input | Set vault path with `..` via UserDefaults, verify app rejects |
| Audio temp in App Support | SECR-04 | Requires runtime check | Start recording, check `~/Library/Application Support/PSTranscribe/tmp/` |
| Transcript files 0600 | SECR-06 | Requires runtime check | Create session, `ls -la` vault directory |
| Atomic write safety | SECR-09 | Requires force-kill test | Force-quit mid-session, verify transcript intact |
| Filename sanitization | SECR-10 | Requires runtime input | Set meeting context with special chars, verify sanitized filename |
| Incomplete session recovery | STAB-01 | Requires crash simulation | Force-quit mid-session, relaunch, verify session visible |
| Midnight timestamps | STAB-02 | Requires time manipulation | Record near midnight boundary, verify positive offsets |
| Checkpoint persistence | STAB-03 | Requires runtime inspection | Complete session, inspect `.checkpoints/` directory |
| Mic error visible | STAB-04 | Requires permission denial | Deny mic permission, start recording, verify error banner |

---

## Validation Sign-Off

- [ ] All tasks have automated verify (swift build) or manual verification listed
- [ ] Sampling continuity: swift build after every commit
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
