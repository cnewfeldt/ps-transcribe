---
phase: 22-process-frontmatter-standard
plan: 04
subsystem: tooling
tags: [bash, yq, lint, ci, frontmatter]

# Dependency graph
requires:
  - phase: 22-01
    provides: canonical hyphen vocab in REQUIREMENTS.md
  - phase: 22-02
    provides: templates carrying requirements-completed
  - phase: 22-03
    provides: generator/agent contract paragraph
provides:
  - scripts/lint-summaries.sh — bash + yq lint enforcing C1/C2/C3/C4
affects: [22-05, 22-06, 23+]

# Tech tracking
tech-stack:
  added: [yq (developer/CI dependency, brew install)]
  patterns: [yaml-presence-grep-fallback-when-yq-parse-fails]

key-files:
  created: [scripts/lint-summaries.sh]
  modified: []

key-decisions:
  - "yq parse failures fall back to grep-based presence checks. Some legacy v1.2 SUMMARYs (18-03 and others) contain unquoted colons inside list values — yq rejects the YAML and would otherwise abort the script mid-loop under set -euo pipefail."
  - "C2 underscore detection uses awk (frontmatter range scan) — cheaper than yq and survives YAML parse failures."
  - "Reworded D-10 banner comment from 'no npm, no Python' → 'no other interpreters or package managers' to satisfy AC #10 literal grep -E 'python|node|npm|npx' returns 0."

patterns-established:
  - "Lint scripts targeting a heterogeneous archive must tolerate parse errors and fall back to text-level checks rather than aborting mid-loop"

requirements-completed: [PROCESS-03]

# Metrics
duration: 12min
completed: 2026-05-02
---

# Phase 22 Plan 04: Lint Script Summary

**`scripts/lint-summaries.sh` — Bash + yq lint enforcing the four-rule SUMMARY frontmatter contract (C1 missing, C2 underscore, C3 subset, C4 sibling-warn). Pre-migration: 36 files checked, 19 failures, 6 warnings, exit 1.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-05-02T18:47Z
- **Completed:** 2026-05-02T18:59Z
- **Tasks:** 1
- **Files modified:** 1 (created)

## Accomplishments
- `scripts/lint-summaries.sh` written, executable, with `--help` text covering all four check IDs
- Brew-installed `yq` v4.53.2 (was missing locally — added as dev/CI dependency)
- Per-file AC verified: 18-01 → exit 0 + WARN C4; 16-01 → exit 1 + FAIL C2 + FAIL C1; 17-01 → exit 1 + FAIL C1
- Full-tree run: 36 SUMMARY files checked, 19 failures (12 C1 + 7 C2), 6 warnings (C4), exit 1 — correct pre-migration classification

## Task Commits

1. **Task 1: Implement scripts/lint-summaries.sh** — `9b24ea6` (feat)

## Files Created/Modified
- `scripts/lint-summaries.sh` — 180 lines, bash+yq, four checks with grep fallback for yq parse failures

## Decisions Made
- See key-decisions frontmatter. Two notable items: (a) yq parse fallback added to handle legacy SUMMARYs with unquoted colons; (b) D-10 banner comment reworded to satisfy AC #10 literal grep.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule: AC supersedes literal action text] D-10 banner comment reworded**
- **Found during:** Task 1 verification
- **Issue:** Plan <action> literal contained the comment string `# D-10: implementation = bash + yq (no npm, no Python).` but AC #10 required `grep -E 'python|node|npm|npx' scripts/lint-summaries.sh` to return 0 matches. The "no npm, no Python" doc string would falsely match.
- **Fix:** Reworded the comment to `# D-10: implementation = bash + yq only (no other interpreters or package managers).`. Intent preserved (D-10 lock); AC satisfied (zero false matches).
- **Files modified:** scripts/lint-summaries.sh
- **Verification:** `grep -E 'python|node|npm|npx' scripts/lint-summaries.sh | wc -l` returns 0.
- **Committed in:** 9b24ea6 (squashed into Task 1 commit since the fix landed before commit)

**2. [Rule: Robustness] Added yq parse-failure fallback**
- **Found during:** Initial smoke test — full-tree run aborted after only 7 lines of output
- **Issue:** `set -euo pipefail` + `yq_fm` returning non-zero on YAML parse error (legacy SUMMARYs with unquoted colons in values, e.g., `provides: DictationLogger actor (5-method API: init, ...)`) caused the script to die silently mid-loop. C2 underscore checks for 7 files were never reached.
- **Fix:** Added `|| true` inside `yq_fm` so parse errors return empty string instead of failing. Added a new `fm_has_key_grep` helper that scans the frontmatter range with awk for the literal key. C1 and C4 fall back to the grep helper when yq returns empty.
- **Files modified:** scripts/lint-summaries.sh
- **Verification:** Full-tree run now completes — 36 files checked, all 19 failures + 6 warnings emitted.
- **Committed in:** 9b24ea6

---

**Total deviations:** 2 auto-fixed (1 AC literal mismatch, 1 missing-robustness edge case)
**Impact on plan:** Both fixes essential. The fallback in particular prevented the lint from ever passing the AC's full-tree exit-1-with-classified-failures requirement.

## Issues Encountered
- yq not installed locally on this Mac; ran `brew install yq` (v4.53.2).
- Several legacy v1.2 SUMMARYs have invalid YAML (unquoted colons in list values). The script tolerates this via the grep fallback — Plan 22-06 migration does not need to reformat these files; lint just needs to detect missing/wrong keys regardless.

## User Setup Required
None for the lint to run on a developer machine that already has Homebrew + yq. The CI workflow in Plan 22-05 installs yq automatically.

## Next Phase Readiness
- Plan 22-05 wires this script into CI as a path-filtered macos-26 workflow.
- Plan 22-06 migrates the archived SUMMARYs so the same script reaches `0 failures, 0 warnings`.

---
*Phase: 22-process-frontmatter-standard*
*Completed: 2026-05-02*
