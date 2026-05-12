---
phase: 24
slug: nyquist-sweep-v1-0
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-05
---

# Phase 24 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
>
> **Note on recursion:** Phase 24's deliverable is itself the Nyquist validation backfill for v1.0 phases 1, 2, 3, 8, 10. This file is the contract for Phase 24's *own* execution — it tells the executor when each Phase 24 plan task can be considered green. The 5 `*-VALIDATION.md` files at `.planning/milestones/v1.0-phases/{NN-name}/` are produced AS the deliverable.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`import Testing`, `@testable import PSTranscribe`) |
| **Config file** | `PSTranscribe/Package.swift` (existing `testTarget(name: "PSTranscribeTests")`) |
| **Quick run command** | `cd PSTranscribe && swift test --filter <SuiteName>` |
| **Full suite command** | `cd PSTranscribe && swift test` |
| **Estimated runtime** | ~30 seconds full suite (existing ~30s + Phase 24 adds ~26 fast tests) |

---

## Sampling Rate

- **After every task commit:** Run `swift test --filter <SuiteName>` for the suite this task created/modified
- **After every plan wave:** Run full `swift test` to confirm no cross-suite regressions
- **Before `/gsd-verify-work`:** Full suite green locally AND `build-check.yml` green on PR
- **Max feedback latency:** ~30 seconds (full suite)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 24-01-* | 01 | 1 | NYQUIST-01 | T-24-01 | n/a (audit-only) | unit | `swift test --filter RebrandInfoPlistTests` | ❌ W0 | ⬜ pending |
| 24-02-* | 02 | 1 | NYQUIST-05 | T-24-01 | n/a (audit-only) | unit | `swift test --filter RecoveredSessionTypeTests` | ❌ W0 | ⬜ pending |
| 24-03-* | 03 | 1 | NYQUIST-04 | T-24-01 | n/a (audit-only) | unit | `swift test --filter "TranscriptStoreClearTests\|FrontmatterSourceTagTests"` | ❌ W0 | ⬜ pending |
| 24-04-* | 04 | 1 | NYQUIST-03 | T-24-01 | n/a (audit-only) | unit | `swift test --filter TranscriptRenameTests` | ❌ W0 | ⬜ pending |
| 24-05-* | 05 | 1 | NYQUIST-02 | T-24-01, T-24-03 | SHA-pin invariant on workflow YAML | unit | `swift test --filter "WorkflowSecretsTests\|TranscriptLoggerSecurityTests\|MidnightOffsetTests\|CheckpointRoundTripTests\|ErrorPathLoggingTests"` | ❌ W0 | ⬜ pending |
| 24-final | all | 1 | NYQUIST-01..05 | — | full-suite green + CI green on PR | integration | `swift test` (locally) AND `gh run view --log <PR>` (CI) | ✅ existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Per-task granularity is encoded in each plan's task `<automated>` blocks; this table summarizes by plan.*

---

## Wave 0 Requirements

Each plan creates new test files at `PSTranscribe/Tests/PSTranscribeTests/` (no shared Wave 0 scaffolding because the existing test target already provides framework, fixtures pattern, and CI gate):

- [ ] `RebrandInfoPlistTests.swift` (Plan 24-01)
- [ ] `RecoveredSessionTypeTests.swift` (Plan 24-02) + `recoveredSessionType` lift in `ContentView.swift`
- [ ] `TranscriptStoreClearTests.swift`, `FrontmatterSourceTagTests.swift` (Plan 24-03)
- [ ] `TranscriptRenameTests.swift` (Plan 24-04)
- [ ] `WorkflowSecretsTests.swift`, `TranscriptLoggerSecurityTests.swift`, `MidnightOffsetTests.swift`, `CheckpointRoundTripTests.swift`, `ErrorPathLoggingTests.swift` (Plan 24-05) + SHA-pin fix on `build-check.yml:56`

*Existing infrastructure (Swift Testing target, `tempDir()` pattern from `DictationLoggerTests.swift`, `MockURLProtocol.swift`, `build-check.yml swift test` step) covers all framework needs. No new dependencies.*

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

Per CONTEXT.md D-03: untestable v1.0 requirements (force-quit, NSWorkspace, mic permission, deleted code, live FS side effects) are marked WITHDRAWN in the corresponding `*-VALIDATION.md` files — they are not migrated to manual rows here. Phase 24's own execution has no manual-only steps; the only human gate is the CI green checkpoint at the end of Plan 24-05.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies (verified by gsd-plan-checker on 2026-05-05)
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify (verified)
- [ ] Wave 0 covers all MISSING references (each plan creates its own test files)
- [ ] No watch-mode flags (`swift test --filter` is focused, not watching)
- [ ] Feedback latency < 30s (full suite ~30s)
- [ ] `nyquist_compliant: true` set in frontmatter (set after Phase 24 execution + verification)

**Approval:** pending — flips to `approved YYYY-MM-DD` when all 5 plans pass `swift test` locally AND `build-check.yml` is green on the PR.
