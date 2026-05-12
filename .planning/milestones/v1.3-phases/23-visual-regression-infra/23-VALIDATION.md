---
phase: 23
slug: visual-regression-infra
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-02
---

# Phase 23 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`import Testing`) + `pointfreeco/swift-snapshot-testing` 1.19.2 |
| **Config file** | `PSTranscribe/Package.swift` (test target dep added by Wave 0) |
| **Quick run command** | `cd PSTranscribe && swift test --filter VisualRegression` |
| **Full suite command** | `cd PSTranscribe && swift test` |
| **Estimated runtime** | ~30s (snapshot suite alone), ~60-90s (full suite) |

---

## Sampling Rate

- **After every task commit:** Run `swift test --filter VisualRegression` (snapshot suite only)
- **After every plan wave:** Run `swift test` (full suite)
- **Before `/gsd-verify-work`:** Full suite must be green AND `.github/workflows/build-check.yml` `swift test` step must run green on at least one PR check
- **Max feedback latency:** 90 seconds (full suite on `macos-26` runner expected ~60-90s)

---

## Per-Task Verification Map

> Filled in once plans land. Each PLAN task references its requirement, the automated `swift test --filter` command that proves it, and the file path that must exist post-task.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| (populated by planner) | — | — | VISREG-01..06 | — | N/A (test infra) | snapshot / build / docs | `swift test --filter ...` | — | ⬜ pending |

---

## Wave 0 Requirements

- [ ] `PSTranscribe/Package.swift` — `pointfreeco/swift-snapshot-testing` 1.19.2 added to `dependencies` and to `.testTarget("PSTranscribeTests").dependencies`
- [ ] `PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/` — empty directory created (will populate on first record run)
- [ ] `PSTranscribe/Tests/PSTranscribeTests/SnapshotFixtures.swift` (or chosen filename) — shared fixture for `NSApp.appearance` capture/restore + canonical-frame helpers
- [ ] `PSTranscribe/Tests/PSTranscribeTests/VisualRegressionTests.swift` (or split files per planner's choice) — empty `@Suite` skeleton ready for per-surface tests

*Wave 0 success criterion: `swift build` succeeds and `swift test --list-tests | grep VisualRegression` returns the test stubs.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Baseline PNG correctness on first record | VISREG-02 | Visual judgment — automation can't decide whether a PNG "looks right" | Reviewer eyeballs each of 15 generated PNGs in PR diff and confirms they reflect intended UI |
| Diff PNG artifact accessible from failed CI run | VISREG-04 | Requires triggering an actual CI failure (e.g., one-time PR with broken token) and verifying `actions/upload-artifact` produces a downloadable diff | Push a deliberate token break on a sandbox branch, observe failed `swift test` step, download artifact, confirm diff PNG present |
| `SNAPSHOT_TESTING_RECORD` CI guard fires | VISREG-04 | Requires temporarily setting the env var in workflow to confirm the build fails | Add `env: SNAPSHOT_TESTING_RECORD: all` to a sandbox PR's workflow step, confirm CI exits non-zero before any test runs |
| Documentation discoverable | VISREG-06 | Reading comprehension test — automation can grep for headings but not for "developer can find this in 30 seconds" | Reviewer follows `.planning/codebase/TESTING.md` and CONTRIBUTING.md regen instructions and successfully regenerates one baseline locally |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (Package.swift dep, fixture file, snapshot suite skeleton)
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
