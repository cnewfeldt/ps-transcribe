---
phase: 22-process-frontmatter-standard
plan: 06
subsystem: docs-migration
tags: [migration, frontmatter, lint-green, dogfood]

# Dependency graph
requires:
  - phase: 22-04
    provides: scripts/lint-summaries.sh
  - phase: 22-05
    provides: .github/workflows/lint-summaries.yml
provides:
  - All 18 archived SUMMARYs canonicalised; lint exits 0/0/0 across the entire archive
  - Migration script body preserved in git history at commit 9983038
affects: [23+]

# Tech tracking
tech-stack:
  added: []
  patterns: [two-commit-migration-with-script-removal, perl-i-portable-edit]

key-files:
  created: []
  modified:
    - .planning/milestones/v1.2-phases/16-foundation/16-01-SUMMARY.md
    - .planning/milestones/v1.2-phases/16-foundation/16-02-SUMMARY.md
    - .planning/milestones/v1.2-phases/16-foundation/16-03-SUMMARY.md
    - .planning/milestones/v1.2-phases/16-foundation/16-04-SUMMARY.md
    - .planning/milestones/v1.2-phases/17-model-auto-update/17-01-SUMMARY.md
    - .planning/milestones/v1.2-phases/17-model-auto-update/17-02-SUMMARY.md
    - .planning/milestones/v1.2-phases/17-model-auto-update/17-03-SUMMARY.md
    - .planning/milestones/v1.2-phases/17-model-auto-update/17-05-SUMMARY.md
    - .planning/milestones/v1.2-phases/18-hotkey-dictation-plain-folder-output/18-01-SUMMARY.md
    - .planning/milestones/v1.2-phases/18-hotkey-dictation-plain-folder-output/18-02-SUMMARY.md
    - .planning/milestones/v1.2-phases/18-hotkey-dictation-plain-folder-output/18-03-SUMMARY.md
    - .planning/milestones/v1.2-phases/18-hotkey-dictation-plain-folder-output/18-04-SUMMARY.md
    - .planning/milestones/v1.2-phases/18-hotkey-dictation-plain-folder-output/18-05-SUMMARY.md
    - .planning/milestones/v1.2-phases/18-hotkey-dictation-plain-folder-output/18-07-SUMMARY.md
    - .planning/milestones/v1.2-phases/18-hotkey-dictation-plain-folder-output/18-09-SUMMARY.md
    - .planning/milestones/v1.2-phases/18.1-shared-save-destinations-local-file/18.1-07-SUMMARY.md
    - .planning/milestones/v1.2-phases/18.1-shared-save-destinations-local-file/18.1-08-SUMMARY.md
    - .planning/milestones/v1.2-phases/18.1-shared-save-destinations-local-file/18.1-09-SUMMARY.md

key-decisions:
  - "Split migration into 2 commits (script-add → migration+script-rm) to satisfy both D-13 reproducibility and AC step 8 'git show HEAD shows script removed'. Single commit add+delete nets to zero in git, defeating reproducibility."
  - "Group C inline-flow preservation: read PLAN frontmatter raw via awk+sed when source is `requirements: [A, B, C]` to avoid yq's habit of re-bracketing. yq fallback only for block-list source."
  - "Migration script accepts 18 explicit file lists (no globbing) so the diff is reviewable and the script self-documents per D-13."

patterns-established:
  - "Ephemeral migration scripts ship as 2-commit pairs (add → use+remove) when reproducibility-via-history is required"

requirements-completed: [PROCESS-01, PROCESS-02, PROCESS-03]

# Metrics
duration: 25min
completed: 2026-05-02
---

# Phase 22 Plan 06: Migration Summary

**18 archived SUMMARYs canonicalised — 7 renames, 6 sibling-strips with D-06 inline-comment preservation, 5 add-missing from sibling PLAN.requirements. `bash scripts/lint-summaries.sh` exits 0 with `38 SUMMARY files checked, 0 failures, 0 warnings`. Phase 22 ships green.**

## Performance

- **Duration:** ~25 min (script authoring + 2 iterations + 2-commit split + verification)
- **Started:** 2026-05-02T19:03Z
- **Completed:** 2026-05-02T19:28Z
- **Tasks:** 2
- **Files modified:** 18 SUMMARY files; 1 ephemeral script committed then removed

## Accomplishments
- All three groups landed with no manual touch-ups required
- Lint went from `19 failures, 6 warnings, exit 1` to `0 failures, 0 warnings, exit 0`
- Migration script preserved in git history at commit `9983038` for full reproducibility
- 18-01 spot-check: D-06 sibling comment + Wave 0 inline rationale both intact
- 16-01 spot-check: `requirements-completed: [SC-1]` (rename preserved value)
- 17-01 spot-check: `requirements-completed: [MODEL-01, MODEL-02, MODEL-03, MODEL-09]` (added from sibling PLAN)

## Task Commits

1. **Task 1: Write scripts/migrate-summary-frontmatter.sh** — `9983038` (chore — script alone, preserves body in history per D-13)
2. **Task 2: Run migration, verify lint passes, commit, git-rm script** — `7f19d54` (chore(planning): migrate SUMMARY frontmatter to canonical requirements-completed — 18 SUMMARYs + script deletion)

## Files Created/Modified
- 18 archived SUMMARYs in `.planning/milestones/v1.2-phases/` migrated (see frontmatter `key-files.modified`)
- `scripts/migrate-summary-frontmatter.sh` — created in commit `9983038`, removed in commit `7f19d54`

## Decisions Made
- See key-decisions frontmatter. The Group C inline-flow handling was a real bug discovered on first migration attempt: yq returned `[MODEL-01, MODEL-02, ...]` literal which then got re-bracketed → `[[MODEL-01, ...]]`. Fix: prefer raw frontmatter awk+sed extraction; fall back to yq only for non-inline lists.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule: Robustness] Group C inline-flow re-bracketing bug**
- **Found during:** Initial migration smoke test (first run, before reset)
- **Issue:** Plan's <action> reproducer for Group C used `yq --front-matter=extract eval '.requirements' "$plan"` then sed-converted to flow form. For inline-source PLANs (17-* all use `requirements: [MODEL-01, MODEL-02, ...]`) yq returned the literal flow form, sed then double-bracketed.
- **Fix:** Preferred path is now an awk-on-frontmatter regex extracting `\[[^]]*\]` from the raw `requirements:` line; only falls back to yq when no inline form exists.
- **Files modified:** scripts/migrate-summary-frontmatter.sh (committed as `9983038`)
- **Verification:** Re-run produced single-bracket `[MODEL-01, MODEL-02, MODEL-03, MODEL-09]` for all four 17-* and 18.1-09.
- **Committed in:** `9983038` (script body), applied in `7f19d54`

**2. [Rule: Reproducibility-via-history] Two-commit split**
- **Found during:** Pre-commit AC review
- **Issue:** Plan asked for "single commit" with `git rm` of script. But a single commit with file added-then-removed nets to zero — git stores trees, so the script body would be lost from history. AC step 8 `git show HEAD | head -30 shows scripts/migrate-summary-frontmatter.sh removed` requires the file to be in HEAD~1 to be removable.
- **Fix:** Split into 2-commit sequence:
  - `9983038` — script added alone (D-13 reproducibility lives here)
  - `7f19d54` — 18 SUMMARY edits + script `git rm` (AC step 8 satisfied)
- **Files modified:** N/A — workflow change only
- **Verification:** `git show HEAD~1` reproduces full script body; `git show HEAD` shows 18 SUMMARYs modified + script deleted; `test ! -f scripts/migrate-summary-frontmatter.sh` succeeds.
- **Committed in:** `9983038` + `7f19d54`

**3. [Rule: AC scope clarification] grep canonical-key count includes 22-02-PLAN.md**
- **Found during:** AC equality check
- **Issue:** AC #5 expected `find .planning/milestones -name '*-SUMMARY.md' | wc -l` to equal `grep -rln '^requirements-completed:' .planning/milestones/ | wc -l`. The grep returned 39 vs 38 SUMMARYs — extra hit was `22-02-PLAN.md` (this phase's own plan file mentions the canonical key in its action prose).
- **Fix:** Filtered the grep to SUMMARY scope only: `find .planning/milestones -name '*-SUMMARY.md' -exec grep -l '^requirements-completed:' {} \;` returns 38 = SUMMARY count. Intent satisfied (every SUMMARY has the key once); literal AC failed only because grep was over-broad relative to intent.
- **Files modified:** N/A
- **Verification:** Filtered count: 38 SUMMARYs, 38 with key. AC intent satisfied.
- **Committed in:** N/A (verification-only)

---

**Total deviations:** 3 auto-fixed (1 real bug, 1 commit-structure adaptation, 1 AC-scope clarification)
**Impact on plan:** All locked decisions (D-04..D-14) satisfied. Lint green across entire archive. Phase ships dogfood-from-day-one.

## Issues Encountered
- First migration attempt produced double-bracketed `[[MODEL-01,...]]` lists for Group C. Reverted with `git checkout -- .planning/milestones/`, fixed script, re-ran cleanly.
- Initial script-staging followed by stash dance polluted commit boundaries; recovered via `git reset --soft HEAD~1` + `git restore --staged` + clean re-commit.

## User Setup Required
None — yq is installed locally; CI runner installs via Homebrew per Plan 22-05.

## Next Phase Readiness
- Lint gate is green across the archive. Every Phase 23+ SUMMARY now mechanically participates in the same contract.
- ROADMAP success criteria #1-#4 all satisfied. Phase 22 verification can complete and v1.3 can advance to Phase 23.

---
*Phase: 22-process-frontmatter-standard*
*Completed: 2026-05-02*
