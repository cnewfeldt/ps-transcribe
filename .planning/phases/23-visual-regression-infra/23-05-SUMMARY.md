---
phase: 23-visual-regression-infra
plan: 05
subsystem: documentation
tags: [documentation, testing-docs, contributing-docs, visual-regression]

# Dependency graph
requires:
  - phase: 23-visual-regression-infra
    provides: "Plan 23-03 produced the VisualRegression suite + 15 baseline PNGs that this plan documents; Plan 23-04 produced the build-check.yml CI extension whose record-mode guard + artifact upload behavior is referenced verbatim"
provides:
  - Refreshed .planning/codebase/TESTING.md with current Swift Testing surface (replaces stale 'no test targets detected' status block) and a new ## Visual Regression section (surfaces, appearance trio, strict precision, baseline storage, regen incantation, env-var contract, CI behavior)
  - New repo-root CONTRIBUTING.md documenting the snapshot regen workflow, env-var contract, CI safety guard, strict-precision rationale, and a Commit Hygiene section forbidding AI attribution footers
  - Cross-linked doc surface: TESTING.md -> CONTRIBUTING.md (developer summary), CONTRIBUTING.md -> TESTING.md (testing patterns reference) + 23-ADR-snapshot-framework.md (framework choice)
affects: [future-contributors, future-AI-collaborators, future-ui-changes-requiring-baseline-regen]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Doc-canonical regen incantation: documented verbatim in both TESTING.md and CONTRIBUTING.md as `SNAPSHOT_TESTING_RECORD=all swift test --filter VisualRegression` -- single source of truth, no rephrasings that could drift"
    - "Four-value env-var enum table: behavior of all/failed/missing/never spelled out in both docs as a reference table, explicit callout that `true` is NOT accepted (guards against folk wisdom)"
    - "Cross-doc reference shape: TESTING.md is the deep reference (precision rationale, surface roster table, CI internals), CONTRIBUTING.md is the developer-facing summary (regen workflow + minimum env var info); both link to the Phase 23 ADR for the framework-choice rationale"

key-files:
  created:
    - CONTRIBUTING.md
  modified:
    - .planning/codebase/TESTING.md

key-decisions:
  - "TESTING.md status block fully replaced (not patched) -- the stale claims (no test targets, no test files, no test config) were tightly entangled with the surrounding paragraph about CI being build-only; cleaner to write the new state from scratch than try to surgically edit a misleading paragraph."
  - "Tome -> PSTranscribe sweep applied only to working-directory and source-path positions, not narrative -- per plan body guidance. The /tmp/tome.log filename is left intact because it's a runtime artifact path that did NOT change with the rebrand (DEBUG-only diagLog target path)."
  - "CONTRIBUTING.md placed at repo root (NOT inside .planning/) -- standard GitHub convention so the file appears in the new-PR sidebar and in the repo file listing; if it lived under .planning/ it would not be discovered by GitHub's contributor surface."
  - "Commit Hygiene section forbids AI attribution -- aligns with the user's global ~/.claude/CLAUDE.md rule that overrides any default skill template; documenting it in the repo so future Claude sessions cannot rationalize around it."

patterns-established:
  - "When refreshing .planning/codebase/ docs that contain stale status claims, replace the whole status block atomically rather than patching individual sentences -- avoids leaving contradictory phrasing where adjacent paragraphs describe different states."
  - "Repo-root CONTRIBUTING.md is now the canonical place for developer-facing workflow docs (regen incantations, PR conventions, commit hygiene); .planning/codebase/ remains the deep-reference surface for AI agents and longform context."

requirements-completed:
  - VISREG-06

# Metrics
duration: ~2min
completed: 2026-05-04
---

# Phase 23 Plan 05: Documentation Refresh Summary

**`.planning/codebase/TESTING.md` refreshed (stale `no test targets` claim removed, working-directory + source-path Tome references swept to PSTranscribe, `## Visual Regression` section appended). `CONTRIBUTING.md` created at repo root with snapshot regen workflow, env-var contract, CI safety guard, strict-precision rationale, and AI-attribution-forbidden Commit Hygiene rule.**

## Performance

- **Duration:** ~2 min (138s)
- **Started:** 2026-05-04T16:30:07Z
- **Completed:** 2026-05-04 (same session)
- **Tasks:** 2
- **Files modified:** 1
- **Files created:** 1

## Accomplishments

### Task 1: TESTING.md refresh

Three categories of edits applied in-place to `.planning/codebase/TESTING.md`:

1. **Status block replaced.** Original lines 5-19 declared "No test targets detected" / "No test files in `Sources/Tome/`" / "No test configuration" -- false as of v1.2 ship and the Phase 19 rebrand. New status block enumerates: Swift Testing test target in PSTranscribe/Package.swift, 18+ test files in PSTranscribe/Tests/PSTranscribeTests/, framework + convention notes, current macOS build + test verification YAML.
2. **Tome path sweep.** All `working-directory: Tome` and `Sources/Tome/...` and the file-organization tree were updated to `PSTranscribe`. The DEBUG-only `/tmp/tome.log` runtime artifact path is intentionally left intact (it did not change with the rebrand). Verified `grep -cE 'working-directory: Tome|Sources/Tome|Tests/Tome' .planning/codebase/TESTING.md` returns 0.
3. **`## Visual Regression` section appended.** New top-level section (after "Validation Approach", before the trailing footer) covering: surface roster (5-row table mapping each surface to its source file and canonical frame), appearance variant mechanics (Light = `.preferredColorScheme(.light)`, Dark = `.preferredColorScheme(.dark)`, System = NSApp.appearance pinned to .aqua with the inheritance-path rationale), strict precision (1.0 / 0.99 with the per-test-loosening-only-with-justification rule and ADR pointer), baseline storage (PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/, no LFS, ~750 KB), regen incantation verbatim (`SNAPSHOT_TESTING_RECORD=all swift test --filter VisualRegression`), env-var contract table with all four values, CI behavior summary referencing build-check.yml and the deliberate non-extension of release-dmg.yml, and "See also" pointers to CONTRIBUTING.md and the Phase 23 ADR.

All 7 acceptance-criteria grep checks for Task 1 returned the expected values: `## Visual Regression`=1, regen incantation=1, stale claim=0, env enum=1, Tome path refs=0, CONTRIBUTING refs=1, `precision: 1.0`=1.

### Task 2: CONTRIBUTING.md creation

New file at repo root (`/Users/cary/Development/ai-development/ps-transcribe/CONTRIBUTING.md`). Sections:

- `# Contributing` -- one-paragraph framing (solo-development codebase, conventions exist for future-self + AI collaborators).
- `## Tests` -- full-suite + visual-regression-only run commands, CI gate description.
- `## Visual Regression Baselines` -- surface count + storage path; `### After a legitimate UI change` regen workflow with the verbatim incantation; `### Env var contract` four-value table with explicit "NOT true" callout; `### CI safety` describes the build-check.yml record-mode guard step from Plan 23-04; `### Strict precision` documents the 1.0 / 0.99 lock and the no-global-loosening rule; `### Read more` cross-links to TESTING.md and the Phase 23 ADR.
- `## Commit Hygiene` -- forbids AI attribution footers (Co-Authored-By: Claude, Generated with, robot emoji), enforces subject + body only, prefers one logical change per commit.

All 9 acceptance-criteria grep checks for Task 2 returned the expected values: file exists at repo root, `^# Contributing`=1, regen incantation=1, `^## Visual Regression Baselines`=1, env enum match=1, ADR link=1, TESTING xref=1, `precision: 1.0`=1, `Co-Authored-By` (in the forbiddance rule)=1.

## Task Commits

1. **Task 1: Refresh TESTING.md (remove stale claims, add Visual Regression section)** -- `361dbe4` (docs)
2. **Task 2: Create CONTRIBUTING.md at repo root** -- `14adefb` (docs)

**Plan metadata:** committed alongside this SUMMARY.md.

## Files Created/Modified

- `.planning/codebase/TESTING.md` -- 309 lines -> 355 lines. Status block replaced (line range ~5-25), Tome path references swept (4 occurrences), CI/CD section updated to reflect Phase 23-04 build-check.yml extensions, new Visual Regression section appended (~60 lines).
- `CONTRIBUTING.md` -- new file at repo root, 66 lines.

## Decisions Made

- **Status block fully replaced rather than patched.** The original 15-line block claimed three contradictory-with-current-reality facts in close succession (no test targets / no test files / no test config). Patching one sentence at a time would have left adjacent paragraphs in disagreement. The new block was written from scratch using the plan's verbatim recommended replacement text.
- **`/tmp/tome.log` intentionally retained.** The DEBUG-only `diagLog` runtime path uses `/tmp/tome.log` in the actual source code (Sources/PSTranscribe/Transcription/TranscriptionEngine.swift). Sweeping the doc reference would create a doc-vs-code divergence that future debugging would have to reconcile. Source-path positions (`Sources/Tome/...`) and CI working-directory positions were swept; runtime artifact paths and narrative references to the historical rebrand were left intact, per the plan's explicit guidance.
- **CONTRIBUTING.md placed at repo root, not inside `.planning/`.** GitHub surfaces a repo's CONTRIBUTING.md in the new-PR sidebar and contributor flow only when it lives at the root, in `docs/`, or in `.github/`. Placing it under `.planning/` would hide it from the GitHub surface even though the GSD ecosystem keeps most context there. Repo root is the standard.
- **Commit Hygiene section codifies the no-AI-attribution rule in-repo.** The user's global `~/.claude/CLAUDE.md` already forbids AI attribution footers, but documenting it in the repo means: (a) future Claude sessions opening this codebase encounter the rule via project context too, (b) any human contributor who reads CONTRIBUTING.md learns the convention, (c) the rule is auditable in git history rather than only in user-private global config.
- **`requirements-completed: [VISREG-06]`** -- this plan completes the doc deliverable for VISREG-06 (regen workflow documented in TESTING.md AND CONTRIBUTING.md). VISREG-01..05 were completed by Plans 23-02..04.

## Deviations from Plan

None -- plan executed exactly as written. All acceptance-criteria grep checks returned expected counts on first commit; no auto-fix iterations needed; no architectural decisions surfaced.

## Issues Encountered

- **No CLAUDE.md at repo root.** The `<files_to_read>` list included `./CLAUDE.md` as conditional. Verified absent (`test -f ./CLAUDE.md` returned MISSING). Skipped per the conditional read; user-global CLAUDE.md was loaded from `~/.claude/CLAUDE.md` and applied (specifically: no em dashes -- using `--`, no AI attribution in commit messages -- omitted Co-Authored-By trailer per user's global rule).

## User Setup Required

None -- pure documentation change. Both files are immediately useful to any contributor (human or AI) reading the repo.

## Next Phase Readiness

- VISREG-06 is complete on disk: regen workflow documented verbatim in both TESTING.md and CONTRIBUTING.md, with the four-value env-var contract spelled out in both.
- The phase's documentation surface is now coherent: TESTING.md (deep reference for AI agents and longform context), CONTRIBUTING.md (repo-root developer surface), 23-ADR-snapshot-framework.md (decision rationale). All three cross-link.
- No follow-up plans expected within Phase 23. The phase's verification gate (`/gsd-verify-work`) can run against the full phase deliverables now that the doc deliverable is in place.
- No blockers.

## Self-Check

**Files claimed:**
- `.planning/codebase/TESTING.md` -- FOUND (modified in commit `361dbe4`).
- `CONTRIBUTING.md` -- FOUND at repo root (created in commit `14adefb`).

**Commits claimed:**
- `361dbe4` -- FOUND (`docs(23-05): refresh TESTING.md and add Visual Regression section`).
- `14adefb` -- FOUND (`docs(23-05): create CONTRIBUTING.md at repo root`).

**Acceptance criteria recheck (post-commit):**

Task 1 (`.planning/codebase/TESTING.md`):
- `## Visual Regression` count = 1: PASS
- `SNAPSHOT_TESTING_RECORD=all swift test --filter VisualRegression` count >= 1: PASS (1)
- `No test targets detected` count = 0: PASS
- `all | failed | missing | never` count >= 1: PASS (1)
- `working-directory: Tome|Sources/Tome|Tests/Tome` count = 0: PASS
- `CONTRIBUTING` count >= 1: PASS (1)
- `precision: 1.0` count >= 1: PASS (1)

Task 2 (`CONTRIBUTING.md` at repo root):
- File exists at repo root: PASS
- `^# Contributing` count = 1: PASS
- `SNAPSHOT_TESTING_RECORD=all swift test --filter VisualRegression` count >= 1: PASS (1)
- `^## Visual Regression Baselines` count = 1: PASS
- `all.*failed.*missing.*never` count >= 1: PASS (1)
- `23-ADR-snapshot-framework` count >= 1: PASS (1)
- `TESTING.md` count >= 1: PASS (1)
- `precision: 1.0` count >= 1: PASS (1)
- `Co-Authored-By` count >= 1 (forbiddance rule): PASS (1)

## Self-Check: PASSED

---
*Phase: 23-visual-regression-infra*
*Plan: 05*
*Completed: 2026-05-04*
