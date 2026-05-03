---
phase: 23-visual-regression-infra
plan: 04
subsystem: infra
tags: [ci, github-actions, snapshot-testing, swift-snapshot-testing, build-check]

# Dependency graph
requires:
  - phase: 23-visual-regression-infra
    provides: Plan 23-01 added the swift-snapshot-testing test-target dependency that the new `swift test` step now exercises; CONTEXT.md D-06 (no path filter) and RESEARCH.md "CI workflow extension" canonical shape
provides:
  - PR-merge gate that runs `swift test` after `swift build` on the macos-26 runner via the existing build-check.yml workflow
  - CI fails fast (before swift test) if `SNAPSHOT_TESTING_RECORD` is set to anything other than `never` in the runner environment
  - Failure-only artifact upload step that surfaces snapshot diff PNGs from `$RUNNER_TEMP/snapshot-failures/` via `actions/upload-artifact@v4` (7-day retention, `if-no-files-found: ignore`)
  - `SNAPSHOT_ARTIFACTS` env var on the build job pointing the snapshot library at the path the upload step reads
affects: [23-03, 23-05, future-test-additions, future-CI-policy-changes]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "GitHub Actions failure-only artifact upload: `if: failure()` step with `actions/upload-artifact@v4`, `if-no-files-found: ignore`, fixed retention -- keeps the workflow green when failures are non-snapshot (e.g. compile errors with no PNGs to upload)"
    - "Record-mode env-var guard step BEFORE build/test: shell conditional that exits non-zero if `SNAPSHOT_TESTING_RECORD` is set to anything other than `never` -- defends against accidental record-mode leakage via repo Variables/Secrets silently overwriting baselines"
    - "Mixed action-pinning style accepted: existing `actions/checkout` is SHA-pinned for security, new `actions/upload-artifact@v4` uses tag form (matches `lint-summaries.yml` precedent)"

key-files:
  created: []
  modified:
    - .github/workflows/build-check.yml

key-decisions:
  - "No path filter on build-check.yml (per CONTEXT D-06) -- swift test is cheap relative to swift build already paid for, and a path filter would risk skipping tests on a PR that touches an indirect dependency."
  - "actions/upload-artifact@v4 used in tag form rather than SHA-pinned -- matches lint-summaries.yml precedent and RESEARCH guidance; existing checkout SHA-pin retained verbatim. If a project-wide pin policy emerges, can be tightened later."
  - "release-dmg.yml deliberately left untouched (per CONTEXT canonical_refs) -- release path remains build-only; tests gate PR merge, not release."
  - "Comment about `if: failure()` reworded to avoid duplicating the literal string in non-step text, keeping `grep -c 'if: failure()'` at exactly 1 (matches plan acceptance criterion)."

patterns-established:
  - "Phase-23 snapshot CI surface: env block (SNAPSHOT_ARTIFACTS) + record-mode guard step + swift build + swift test + failure-only upload-artifact step. All four elements live in one workflow file (build-check.yml); no separate snapshot workflow."

requirements-completed: [VISREG-04, VISREG-05]

# Metrics
duration: ~2min
completed: 2026-05-03
---

# Phase 23 Plan 04: CI Workflow Extension Summary

**`build-check.yml` extended with `swift test` step (PR-merge gate), record-mode env-var guard, `SNAPSHOT_ARTIFACTS` env, and failure-only `upload-artifact@v4` step that surfaces snapshot diff PNGs to the reviewer.**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-05-03T00:12:05Z
- **Completed:** 2026-05-03T00:14:13Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Added 4 new elements to `.github/workflows/build-check.yml` per the plan body verbatim: `env:` block on `jobs.build` (`SNAPSHOT_ARTIFACTS: ${{ runner.temp }}/snapshot-failures`), "Guard against snapshot record mode" step before build, "Test" step after build (`swift test`, same nested `working-directory: PSTranscribe`), and "Upload snapshot failure artifacts" step with `if: failure()` and `actions/upload-artifact@v4`.
- All 11 acceptance-criteria grep counts hit their exact expected values: `swift test`=1, `swift build`=1, `SNAPSHOT_TESTING_RECORD`=3 (>=2 required), `SNAPSHOT_ARTIFACTS`=2 (>=1 required), `actions/upload-artifact@v4`=1, `if: failure()`=1, `macos-26`=1, `working-directory: PSTranscribe`=2, `paths:`=0.
- YAML validated cleanly via both `yq eval` and `python3 -c "import yaml; yaml.safe_load(...)"` (after a one-time `pip3 install --user pyyaml`).
- `release-dmg.yml` untouched (`git diff --stat` empty).

## Task Commits

1. **Task 1: Extend build-check.yml with env, record-mode guard, swift test step, and failure-only artifact upload** -- `ddcec6a` (ci)

**Plan metadata:** committed alongside this SUMMARY.md.

## Files Created/Modified

- `.github/workflows/build-check.yml` -- existing 20-line workflow extended to 60 lines: added `env:` block, record-mode guard step, `swift test` step, and `if: failure()` artifact upload step. Existing trigger, runner, checkout, Xcode-select, and build steps preserved verbatim.

## Decisions Made

- **Comment phrasing tweaked to keep grep count exact:** Plan acceptance criterion required `grep -c 'if: failure()'` to return exactly 1. Initial draft included the literal `if: failure()` substring inside an explanatory comment as well, producing count 2. Reworded the comment to "The conditional below only runs if an earlier step in this job failed." -- semantically identical, satisfies strict count check. Documented under deviations.
- **No new dependencies installed beyond pyyaml for verification:** `yq` was already on the host; `pip3 install --user pyyaml` was needed to satisfy the plan's exact verification command literally. Both linters returned OK.
- **Tag-form `actions/upload-artifact@v4`** used per RESEARCH guidance and `lint-summaries.yml` precedent. Existing checkout SHA-pin (`34e114876b0b...`) retained.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Comment text increased `if: failure()` grep count above plan's strict expectation of 1**

- **Found during:** Task 1 verification (grep acceptance checks).
- **Issue:** First-pass comment block contained "if: failure() only runs if an earlier step in this job failed" as natural-language explanation. `grep -c 'if: failure()'` returned 2 instead of the plan's expected 1.
- **Fix:** Reworded the comment to "The conditional below only runs if an earlier step in this job failed." -- preserves the explanation without repeating the literal token.
- **Files modified:** `.github/workflows/build-check.yml`
- **Verification:** Re-ran all grep counts; `if: failure()` now returns exactly 1. YAML still valid via yq + pyyaml.
- **Committed in:** `ddcec6a` (Task 1 commit -- fix applied before commit).

---

**Total deviations:** 1 auto-fixed (1 blocking-on-acceptance-criterion).
**Impact on plan:** Cosmetic; no behavioral change to the workflow. Rewording matched the plan's strict grep contract.

## Issues Encountered

- **`pyyaml` not in Python stdlib:** Plan's verification command `python3 -c "import yaml; yaml.safe_load(...)"` failed initially because system Python had no `yaml` module. Resolved by `pip3 install --user pyyaml` (one-time, no project-level dep added). `yq` (already on host via Homebrew) provided a parallel validation surface; both reported OK after the install.
- **`actionlint` not installed on host:** Plan's optional actionlint check skipped. yq + pyyaml are sufficient for syntactic validation; runtime semantics will be exercised on the next PR run.

## User Setup Required

None -- pure CI workflow change. The workflow takes effect on the next pull request opened against `main`.

## Next Phase Readiness

- VISREG-04 (record-mode guard + failure artifact surface) and VISREG-05 (PR-merge gate runs `swift test`) are complete on disk.
- The new `swift test` step will exercise the snapshot suite produced by Plan 23-03 once that lands. The two plans are independent and can land in either order; the CI gate is no-op for VISREG until the test files exist (it just runs the existing 18+ test files).
- Plan 23-05 (docs refresh -- TESTING.md + CONTRIBUTING.md regen incantation) can proceed; it depends on the workflow shape captured here for the "CI never sets `SNAPSHOT_TESTING_RECORD`" sentence.
- No blockers.

## Self-Check

**Files claimed:**
- `.github/workflows/build-check.yml` -- FOUND (60 lines after extension; 41 insertions in commit `ddcec6a`).

**Commits claimed:**
- `ddcec6a` -- FOUND (`ci(23-04): extend build-check.yml with swift test, record-mode guard, and failure artifacts`); verified via `git log --oneline | grep ddcec6a`.

**Acceptance criteria recheck (post-commit):**
- YAML parses (yq + pyyaml): PASS
- `swift test` count = 1: PASS
- `swift build` count = 1: PASS
- `SNAPSHOT_TESTING_RECORD` count = 3 (>=2): PASS
- `SNAPSHOT_ARTIFACTS` count = 2 (>=1): PASS
- `actions/upload-artifact@v4` count = 1: PASS
- `if: failure()` count = 1: PASS
- `macos-26` count = 1: PASS
- `working-directory: PSTranscribe` count = 2: PASS
- `paths:` count = 0: PASS
- `release-dmg.yml` unchanged: PASS (`git diff --stat` empty)

## Self-Check: PASSED

---
*Phase: 23-visual-regression-infra*
*Plan: 04*
*Completed: 2026-05-03*
