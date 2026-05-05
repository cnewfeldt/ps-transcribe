# Phase 24: Nyquist Sweep — v1.0 - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-05
**Phase:** 24-nyquist-sweep-v1-0
**Areas discussed:** Phase 1 re-audit posture, Coverage depth, Untestable / removed-code policy, Test file organization

---

## Phase 1 re-audit posture

| Option | Description | Selected |
|--------|-------------|----------|
| Leave Phase 1 alone | Already `status: approved` / `nyquist_compliant: true` since 2026-04-27. Phase 24 covers only 02/03/08/10 (4 sub-plans). Add a one-line note explaining the exclusion. | |
| Re-audit Phase 1 with real tests | Write Swift Testing assertions for the testable parts (Info.plist bundle ID, app name string, executable name, workflow greps). Skip REBR-08 (code deleted). Bumps `last_audited`; 5 sub-plans total. | ✓ |
| Light pass on Phase 1 | No new tests. Re-stamp `last_audited` and add references to the now-existing test target. Documents new infrastructure context without writing tests. | |

**User's choice:** Re-audit Phase 1 with real tests
**Notes:** Captured in CONTEXT.md as **D-01**. The 2026-04-27 build+grep approval was sufficient when no test target existed; now that one does, Phase 24 closes that gap and produces uniform `nyquist_compliant: true` evidence across all five v1.0 phases.

---

## Coverage depth

| Option | Description | Selected |
|--------|-------------|----------|
| Per requirement (≈30–40 tests) | One `@Test` per testable requirement ID. Matches existing draft VALIDATION.md per-row table structure. Highest signal; matches Nyquist's "sampling continuity" goal. | ✓ |
| Per success criterion (≈5–10 tests) | One `@Test` per phase-level area as worded in the roadmap. Smaller suite; loses requirement-level granularity. | |
| Per behavior cluster (≈15–20 tests) | Group requirements that share a code path. Middle ground; bias toward tests that exercise distinct behavior. | |

**User's choice:** Per requirement (≈30–40 tests)
**Notes:** Captured as **D-02**. The existing draft VALIDATION.md tables in each v1.0 phase already enumerate per-requirement task rows — choosing per-requirement coverage matches the structure those drafts were authored for. Final test count lands at ~30 after D-03 withdrawals.

---

## Untestable / removed-code policy

| Option | Description | Selected |
|--------|-------------|----------|
| Mixed: salvage + manual-only fallback | Per req: prefer salvaged public-API regression test → fallback to Manual-Only entry → drop only for provably deleted code. Matches the established 2026-04-27 audit precedent. | |
| Strict: every requirement must have an automated test | Force every requirement to have an executable `@Test`. Write integration tests using temp dirs + simulated state for runtime-only reqs. Highest coverage; significant scaffolding; flake risk. | |
| Lenient: drop everything not unit-testable | Mark untestable requirements as WITHDRAWN/out-of-scope in VALIDATION.md — no Manual-Only entries. Smaller surface; `nyquist_compliant: true` covers the unit-testable subset only. | ✓ |

**User's choice:** Lenient: drop everything not unit-testable
**Notes:** Captured as **D-03**. The decision sharpens what `nyquist_compliant: true` means — automated coverage of the unit-testable subset, not a documentation index of every requirement. The v1.0 audit already locked the WITHDRAWN reqs as satisfied via `*-VERIFICATION.md`; that evidence is preserved upstream and not duplicated here. Pure-function corners of "runtime-flavored" reqs (filename sanitization, midnight offset math, deep-link URL construction) still get unit tests.

---

## Test file organization

| Option | Description | Selected |
|--------|-------------|----------|
| Phase-scoped subdirectories | `Tests/PSTranscribeTests/Phase01/`, `Phase02/`, etc. Mirrors existing `Phase18/` / `Phase18.1/` convention. | |
| Flat with phase-prefixed names | New flat files at top of `Tests/PSTranscribeTests/` named by behavior (`RebrandInfoPlistTests.swift`, `FilenameSanitizationTests.swift`). Matches older v1.0 flat convention. | ✓ |
| Single Phase24/ directory | One umbrella directory containing all new tests, with internal phase-prefixed filenames. Cleanest "this is the sweep" boundary. | |

**User's choice:** Flat with phase-prefixed names (note: behavior-named, not phase-prefixed — see CONTEXT.md D-04 for the actual naming convention)
**Notes:** Captured as **D-04**. Tests cover surviving product behavior, not original code paths — naming files by what they exercise (`FilenameSanitizationTests.swift`) rather than by audit phase keeps them readable as ordinary tests. Phase18-style subdirectories were rejected because that pattern was created during *active* Phase 18+ development, where phase boundary coincided with code authorship; here it would overstate the connection.

---

## Claude's Discretion

The following implementation choices were intentionally left to the planner / executor:

- Per-test temp-dir / fixture pattern (inline vs shared helper file)
- `@Suite(.serialized)` annotation per suite (required for shared-state mutation, not for pure functions)
- Exact test names + `#expect` vs `#require` selection
- Info.plist read approach (`Bundle.main` runtime vs file-IO fixture)
- Plan splitting: 5 plans (one per v1.0 phase audited) vs grouped by behavior cluster — bias toward 5 plans, mirrors `/gsd-validate-phase <N>` natural unit
- Order of plans within the phase — bias smallest-first
- WITHDRAWN row exact column shape in VALIDATION.md (must include Test Type: WITHDRAWN, requirement ID, one-line reason, pointer to `*-VERIFICATION.md`)

---

## Deferred Ideas

- Manual-Only / integration-test scaffold for force-quit / SIGKILL / runtime entitlement scenarios — only if a future production regression demands it
- Phase 4 (Mic Button), Phase 7 (Notion), Phase 9 (Verification Sweep) Nyquist sweep — those directories live only in git history; opt-in if needed later
- Post-Phase-24 cleanup: move restored v1.0 phase directories from `.planning/phases/` to `.planning/milestones/v1.0-phases/` (per the restoration commit 23f3949 plan)
- Phase 23-VALIDATION.md own approval flip — separate concern, not v1.0 scope
- Snapshot tests for v1.0 surfaces beyond Phase 23's 5-surface roster — future visual-regression phase
- Backfilling `requirements-completed` frontmatter on v1.0 SUMMARY.md files — v1.0 audit marked "not worth the churn"
- Centralized `Phase24Fixtures.swift` shared helper — introduce only if 3+ tests share fixture code
- Cross-phase CI splitting via `--filter` per phase — unnecessary infrastructure for the test count
