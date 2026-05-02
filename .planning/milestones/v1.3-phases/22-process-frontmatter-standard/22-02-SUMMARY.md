---
phase: 22-process-frontmatter-standard
plan: 02
subsystem: docs
tags: [templates, frontmatter, gsd]

# Dependency graph
requires:
  - phase: 22-01
    provides: canonical hyphenated key vocabulary
provides:
  - All three SUMMARY templates carry `requirements-completed:` (D-03)
  - Tightened doc block in summary.md (D-04, D-05, references 18-01 canonical example)
affects: [22-03, 22-04, 22-06, 23+]

# Tech tracking
tech-stack:
  added: []
  patterns: [yaml-comment-doc-block, dogfood-from-day-one]

key-files:
  created: []
  modified:
    - $HOME/.claude/get-shit-done/templates/summary.md
    - $HOME/.claude/get-shit-done/templates/summary-standard.md
    - $HOME/.claude/get-shit-done/templates/summary-minimal.md

key-decisions:
  - "Files live outside the project repo — edits affect global gsd install; SUMMARY records the change but no git commit lands for the template files themselves"
  - "summary.md doc-block expansion preserves a separate `requirements-completed: []` line so populated SUMMARYs still emit the field literally"

patterns-established:
  - "Template files all carry the canonical key with identical inline comment"

requirements-completed: [PROCESS-01]

# Metrics
duration: 3min
completed: 2026-05-02
---

# Phase 22 Plan 02: SUMMARY Templates Summary

**All three SUMMARY templates (`summary.md`, `summary-standard.md`, `summary-minimal.md`) now emit the canonical `requirements-completed:` key; summary.md gains a multi-line YAML-comment doc block documenting empty-list validity and sibling-field deprecation.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-02T18:38Z
- **Completed:** 2026-05-02T18:41Z
- **Tasks:** 2
- **Files modified:** 3 (all in `~/.claude/get-shit-done/templates/`)

## Accomplishments
- summary-standard.md: `requirements-completed: []` inserted between `key-decisions:` and `duration:` with canonical inline comment
- summary-minimal.md: same insertion, same comment
- summary.md: existing single-line comment expanded into multi-line YAML doc block referencing 18-01 canonical example and naming all three deprecated sibling fields

## Task Commits

Template files live in `$HOME/.claude/get-shit-done/templates/` (outside the project repo). No git commit lands in this repo for the template edits themselves; the changes are visible in the user's global gsd install. Only the SUMMARY artifact is committed in this repo.

1. **Task 1: Add requirements-completed: [] to summary-standard + summary-minimal** — no repo commit (out-of-repo files)
2. **Task 2: Tighten requirements-completed doc in summary.md** — no repo commit (out-of-repo file)
3. **Plan SUMMARY** — committed in this repo

## Files Created/Modified
- `$HOME/.claude/get-shit-done/templates/summary.md` — line 41 single-line comment replaced with multi-line YAML doc block + preserved `requirements-completed: []` literal
- `$HOME/.claude/get-shit-done/templates/summary-standard.md` — `requirements-completed: []` inserted between `key-decisions:` and `duration:`
- `$HOME/.claude/get-shit-done/templates/summary-minimal.md` — `requirements-completed: []` inserted between `key-decisions: []` and `duration:`

## Decisions Made
- Out-of-repo template edits accepted as not-committable; SUMMARY artifact captures the change for traceability. Plan was pre-aware of the file location — `$HOME/.claude/get-shit-done/templates/` is the documented target in `files_modified`.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None.

## Next Phase Readiness
- All v1.3+ SUMMARYs generated from these templates carry the canonical key by construction.
- Plan 22-03 can now reference the templates as "canonical-key carriers" when tightening the generator contract.

---
*Phase: 22-process-frontmatter-standard*
*Completed: 2026-05-02*
