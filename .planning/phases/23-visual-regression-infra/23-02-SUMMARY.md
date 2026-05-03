---
phase: 23-visual-regression-infra
plan: 02
subsystem: testing
tags: [adr, snapshot-testing, swift-snapshot-testing, documentation, nygard]

# Dependency graph
requires:
  - phase: 23-visual-regression-infra
    provides: CONTEXT.md decisions D-01 (library + scope) and D-02 (precision lock); RESEARCH.md v1.19.2 reconciliation and three-alternative comparison surface
provides:
  - Nygard-style ADR (`23-ADR-snapshot-framework.md`) capturing why pointfreeco/swift-snapshot-testing 1.19.2 was chosen and three rejected alternatives (custom XCTest+CGImage hash, snapshotpreviews, XCUITest)
  - Reconciliation note resolving CONTEXT.md "v2.x" wording vs the actual 1.19.2 latest release
  - Operational rules captured durably (strict precision never loosened globally; `SNAPSHOT_TESTING_RECORD=all` regen incantation; CI guard)
affects: [23-04, 23-05, future-snapshot-related-phases, future-ADR-introductions]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Nygard short-form ADR (Status / Context / Decision / Alternatives Considered / Consequences) authored inline at phase folder rather than introducing a new top-level `.planning/adr/` directory"

key-files:
  created:
    - .planning/phases/23-visual-regression-infra/23-ADR-snapshot-framework.md
  modified: []

key-decisions:
  - "ADR location: inline at phase folder (`.planning/phases/23-visual-regression-infra/23-ADR-snapshot-framework.md`) rather than a new `.planning/adr/` top-level directory -- single ADR doesn't justify a new convention. Future phases may promote the location if more ADRs accumulate."
  - "Operational version pin recorded as 1.19.2 with explicit reconciliation paragraph addressing CONTEXT.md D-01's `v2.x` wording (no v2 release exists; library has been on 1.x since 2019)."
  - "Strict precision (precision: 1.0, perceptualPrecision: 0.99) explicitly framed as 'tightened only, never loosened globally' in the Decision section so future maintainers see the constraint without re-reading CONTEXT.md."

patterns-established:
  - "Nygard-style ADR template for this repo: H1 'ADR <REQ-ID>: <Title>'; bold Status/Decider/Supersedes lines; H2 sections in fixed order (Context, Decision, Alternatives Considered, Consequences, References); each rejected alternative is an H3 with `(rejected)` suffix and bulleted rationale."

requirements-completed: [VISREG-01]

# Metrics
duration: ~4min
completed: 2026-05-02
---

# Phase 23 Plan 02: ADR Snapshot Framework Summary

**Nygard-style ADR documenting the swift-snapshot-testing 1.19.2 choice and three rejected alternatives (custom XCTest+CGImage hash, snapshotpreviews, XCUITest), with version reconciliation against CONTEXT.md D-01's `v2.x` wording.**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-05-03T00:00:43Z
- **Completed:** 2026-05-03T00:04:43Z
- **Tasks:** 1
- **Files modified:** 1 (created)

## Accomplishments

- Authored `.planning/phases/23-visual-regression-infra/23-ADR-snapshot-framework.md` (81 lines) capturing the framework decision verbatim from the plan body. ADR satisfies all 11 acceptance criteria from the plan: file exists, contains `# ADR VISREG-01` title, has all 5 Nygard sections (Context, Decision, Alternatives Considered, Consequences, plus Status/Decider preamble), names `pointfreeco/swift-snapshot-testing` + `1.19.2`, names all three rejected alternatives (`XCUITest`, `snapshotpreviews`, `CGImage` hash), and contains zero em-dashes per project communication rules.
- Recorded explicit reconciliation paragraph clarifying that CONTEXT.md D-01's `v2.x` wording resolves to operational pin `1.19.2` (verified via GitHub API in RESEARCH.md).
- Captured the strict-precision constraint (`precision: 1.0`, `perceptualPrecision: 0.99`, never loosened globally) inside the Decision section so the rule is durable beyond CONTEXT.md.

## Task Commits

1. **Task 1: Write ADR-snapshot-framework Nygard-style** -- bundled into commit `48086ad` by a parallel-execution race (see Deviations).

**Plan metadata:** to be committed by this SUMMARY.md write.

## Files Created/Modified

- `.planning/phases/23-visual-regression-infra/23-ADR-snapshot-framework.md` -- new ADR (Nygard short-form) for VISREG-01 framework choice.

## Decisions Made

- ADR placed inline at phase folder (per RESEARCH Open Q #2 resolution); avoids introducing a new top-level convention for one record.
- Pinned version recorded as `1.19.2` with explicit reconciliation note rather than blocking on the user to amend CONTEXT.md's `v2.x` wording -- RESEARCH already verified no v2 exists.

## Deviations from Plan

**1. [Parallel-execution artifact] ADR commit bundled into Plan 23-01's commit by concurrent executor**

- **Found during:** Task 1 commit phase (after `git add` of the ADR file).
- **Issue:** This executor was prompted as a "PARALLEL executor in git worktree" but actually ran on `main` branch in the main checkout. Plan 23-01's executor was running concurrently and committed during the small window between this plan's `git add` and intended `git commit`. As a result, the ADR file was swept into commit `48086ad` (`feat(23-01): add swift-snapshot-testing 1.19.2 to test target`) instead of receiving its own atomic `docs(23-02): ...` commit.
- **What was checked:** Hooks directory contains only `.sample` files (no active hooks). `git worktree list` confirmed this checkout is the main repo at `/Users/cary/Development/ai-development/ps-transcribe`, not a worktree under `.worktrees/`. The expected base `25aab21` matched `git merge-base HEAD 25aab21`, so the no-op early-exit branch of the worktree-base check fired correctly.
- **Outcome:** ADR file landed on `main` intact (verified `git show HEAD -- 23-ADR-snapshot-framework.md`, 81 lines, all acceptance criteria still pass). The Phase 23 ARTIFACT objective is satisfied; only the commit-attribution invariant was violated.
- **Verification:** All 11 acceptance criteria PASS against the on-disk file; ADR contents are byte-for-byte the plan-specified text.
- **Committed in:** `48086ad` (bundled).
- **Recommended follow-up:** Orchestrator should be aware that `48086ad` mixes 23-01 (Package.swift, Package.resolved) and 23-02 (ADR) work. No remediation attempted from this executor because rewriting `48086ad` would race the 23-01 executor's accounting.

---

**Total deviations:** 1 parallel-execution artifact.
**Impact on plan:** ADR artifact correct and present on `main`. Atomic-commit-per-plan invariant violated for 23-02 only; remediation deferred to orchestrator.

## Issues Encountered

- **Worktree assumption mismatch:** The orchestrator prompt stated this is a parallel worktree executor, but the working directory is the main checkout. Combined with concurrent execution of Plan 23-01 against the same git index, a race produced the bundled commit described above. No data loss; ADR content is correct.

## User Setup Required

None -- pure documentation artifact.

## Next Phase Readiness

- VISREG-01 requirement (framework choice + ADR) is complete on disk.
- Plans 23-03 (test code), 23-04 (CI workflow), 23-05 (docs refresh) can proceed; this ADR is referenced by Plan 23-05 as the canonical decision record for the `SNAPSHOT_TESTING_RECORD=all` regen incantation and the precision-lock rule.
- No blockers.

## Self-Check

**Files claimed:**
- `.planning/phases/23-visual-regression-infra/23-ADR-snapshot-framework.md` -- FOUND (81 lines, all acceptance criteria pass)

**Commits claimed:**
- `48086ad` -- FOUND (`feat(23-01): add swift-snapshot-testing 1.19.2 to test target`); contains the ADR file under `git show HEAD --stat`.

**Acceptance criteria recheck:**
- Title present (`# ADR VISREG-01`): PASS (1)
- `## Context`: PASS (1)
- `## Decision`: PASS (1)
- `## Alternatives Considered`: PASS (1)
- `## Consequences`: PASS (1)
- `pointfreeco/swift-snapshot-testing` mention: PASS (5 occurrences)
- `1.19.2` mention: PASS (2 occurrences)
- `XCUITest` mention: PASS (1)
- `snapshotpreviews` mention: PASS (1)
- `CGImage` mention: PASS (1)
- Em-dashes: PASS (0)

## Self-Check: PASSED (with the parallel-execution-bundling caveat documented above)

---
*Phase: 23-visual-regression-infra*
*Plan: 02*
*Completed: 2026-05-02*
