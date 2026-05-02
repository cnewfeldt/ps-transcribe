---
phase: 22-process-frontmatter-standard
plan: 01
subsystem: docs
tags: [requirements, frontmatter, process]

# Dependency graph
requires:
  - phase: v1.3-discuss
    provides: D-01/D-02 canonical hyphen lock
provides:
  - REQUIREMENTS.md PROCESS-01..03 worded with canonical `requirements-completed` (hyphen)
affects: [22-02, 22-03, 22-04, 22-05, 22-06]

# Tech tracking
tech-stack:
  added: []
  patterns: [single-source-of-truth-vocabulary]

key-files:
  created: []
  modified: [.planning/REQUIREMENTS.md]

key-decisions:
  - "PROCESS-01 + PROCESS-03 reworded; PROCESS-02 already field-name agnostic, no edit"
  - "Diff scope: 2 line edits, no surrounding text touched"

patterns-established:
  - "Vocabulary fix lands FIRST in a phase that canonicalises a key string"

requirements-completed: [PROCESS-01]

# Metrics
duration: 2min
completed: 2026-05-02
---

# Phase 22 Plan 01: REQUIREMENTS.md Hyphen Rewording Summary

**PROCESS-01 + PROCESS-03 bullets in REQUIREMENTS.md now use the canonical hyphenated key `requirements-completed` — single-source-of-truth vocab fix lands before any template/generator/lint plan touches the same string.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-02T18:35Z
- **Completed:** 2026-05-02T18:37Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- PROCESS-01 bullet flipped underscore → hyphen
- PROCESS-03 bullet flipped underscore → hyphen
- PROCESS-02 verified field-name agnostic (no edit needed)
- Zero `requirements_completed` underscore tokens remain in REQUIREMENTS.md

## Task Commits

1. **Task 1: Reword PROCESS-01..03 from underscore to hyphen in REQUIREMENTS.md** — `c6ceb40` (docs)

## Files Created/Modified
- `.planning/REQUIREMENTS.md` — PROCESS-01 + PROCESS-03 bullets reworded (2 line edits)

## Decisions Made
- None beyond what CONTEXT.md D-01/D-02 already locked. Edits used the Edit tool (not sed) for clean reviewable diff.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None.

## Next Phase Readiness
- Wave 2 plans (22-02 templates + 22-03 generator/agent contract) can now read the canonical key from REQUIREMENTS.md.
- Vocabulary is locked at the source; no risk of downstream plans canonicalising different forms.

---
*Phase: 22-process-frontmatter-standard*
*Completed: 2026-05-02*
