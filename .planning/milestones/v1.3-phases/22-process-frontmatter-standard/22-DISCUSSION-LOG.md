# Phase 22: Process & Frontmatter Standard - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-02
**Phase:** 22-process-frontmatter-standard
**Areas discussed:** Field name canonical form, Field semantics — strict vs nuanced, Enforcement gate location, Backfill scope — migrate vs grandfather

---

## Field name canonical form

### Q1 — Which key wins as the canonical name?

| Option | Description | Selected |
|--------|-------------|----------|
| `requirements-completed` (hyphen) | Matches existing template + 24/29 archived files + repo YAML convention. Update REQUIREMENTS.md PROCESS-01 to reflect actual canon. Lowest churn — 5 files migrate. | ✓ |
| `requirements_completed` (underscore) | Matches REQUIREMENTS.md PROCESS-01 spec verbatim. Breaks repo YAML convention; 24 archived files migrate. | |
| Accept both — lint normalizes | Lint accepts either form, generator emits hyphen. No archival migration. Risk: indefinite split. | |

**User's choice:** `requirements-completed` (hyphen)
**Notes:** Aligns with the dominant existing pattern; spec is the outlier and gets corrected.

### Q2 — Spec drift: fix REQUIREMENTS.md PROCESS-01..03?

| Option | Description | Selected |
|--------|-------------|----------|
| Update REQUIREMENTS.md PROCESS-01 + 02 + 03 to hyphen | Resolve drift in this phase. Tiny commit at start. | ✓ |
| Leave spec text, document equivalence in ADR | Treat spec as user-intent, hyphen as canonical key. | |

**User's choice:** Update REQUIREMENTS.md
**Notes:** Single source of truth wins.

### Q3 — Which templates carry the field?

| Option | Description | Selected |
|--------|-------------|----------|
| All three (full/standard/minimal) | Every SUMMARY profile carries the field. Lint applies uniformly. | ✓ |
| Full + standard, skip minimal | Minimal stays minimal; lint exempts files generated from minimal template. | |
| Full only, deprecate the other two | Consolidate to one canonical template. Larger ripple. | |

**User's choice:** All three.

### Q4 — Empty-state contract for plans delivering no requirements?

| Option | Description | Selected |
|--------|-------------|----------|
| `requirements-completed: []` allowed, comment optional | Empty list is valid declaration. Lint passes. Author may add `# rationale` comment. | ✓ |
| `requirements-completed: []` REQUIRES inline rationale comment | Lint demands `# <reason>`. Forces authors to think before declaring nothing. | |
| Empty list forbidden — must list ID or use `requirements-scaffolded` sibling | Strictest. Highest discipline, highest friction. | |

**User's choice:** Empty list allowed, comment optional.
**Notes:** Aligns with v1.2 phase 18 pattern where authors voluntarily added rationale comments.

---

## Field semantics — strict vs nuanced

### Q1 — Canonize richer vocabulary or stay strict?

| Option | Description | Selected |
|--------|-------------|----------|
| Strict — only `requirements-completed` | One field. If a plan only scaffolds, list `[]` and explain in body. Existing siblings retired during migration. | ✓ |
| Two-tier — `completed` + `supports` | Canonize `requirements-supports` for partial-delivery plans. | |
| Full vocabulary — completed/scaffolded/supports/touched | All four canonized with documented semantics. | |

**User's choice:** Strict.

### Q2 — What happens to non-canonical sibling fields during migration?

| Option | Description | Selected |
|--------|-------------|----------|
| Strip on migration, preserve as comments | Migrator removes sibling fields, attaches content as inline `# scaffolded: [...]` comment. | ✓ |
| Strip without preserving | Sibling fields deleted. Nuance lives in body text only. | |
| Keep siblings as deprecated/tolerated | Lint ignores them. Generator never emits. | |

**User's choice:** Strip + preserve as comment.

### Q3 — Lint depth?

| Option | Description | Selected |
|--------|-------------|----------|
| Presence only | Lint fails when field absent. Empty list passes. | |
| Presence + IDs match PLAN.md `requirements:` (subset) | Lint reads sibling PLAN.md, asserts subset. Catches typos. | ✓ |
| Presence + IDs exist in REQUIREMENTS.md | Strongest — validates against milestone catalog. | |

**User's choice:** Presence + subset of PLAN.requirements.

### Q4 — Auto-population semantics for plans that overdeclare?

| Option | Description | Selected |
|--------|-------------|----------|
| Always copy verbatim, author edits down | Generator emits exact PLAN.md list. Author trims if not all delivered. | ✓ |
| Copy + flag with `# verify` comment | Generator emits list with `# verify each ID actually delivered` comment. | |
| Generator asks executor which IDs were delivered | Executor inspects task commits + verification artifacts. Most accurate. | |

**User's choice:** Copy verbatim, author edits.

---

## Enforcement gate location

### Q1 — Where does the lint gate run?

| Option | Description | Selected |
|--------|-------------|----------|
| CI workflow only | New `lint-summaries.yml` runs on PRs touching SUMMARY/PLAN files. | ✓ |
| Pre-commit hook only | `.git/hooks/pre-commit` shell script blocks bad commits locally. | |
| Both — hook + CI redundancy | Pre-commit blocks locally; CI is final gate. | |

**User's choice:** CI only.

### Q2 — Lint implementation language?

| Option | Description | Selected |
|--------|-------------|----------|
| Bash + yq | Shell script `scripts/lint-summaries.sh` using `yq`. | ✓ |
| Python + PyYAML | `scripts/lint_summaries.py`. | |
| Swift CLI tool | Swift command-line target. | |
| Node/TypeScript | Adds JS toolchain to non-JS repo. | |

**User's choice:** Bash + yq.

### Q3 — Which CI runner runs the lint?

| Option | Description | Selected |
|--------|-------------|----------|
| Separate `lint-summaries.yml` on macos-26 | New workflow, path-filtered. Parallel with build-check.yml. | ✓ |
| Add lint step to existing build-check.yml | One workflow file. Lint runs after `swift build`. | |

**User's choice:** Separate workflow on macos-26.
**Notes:** Original options included Ubuntu — user pushed back ("This is a mac application"). Reformulated to macOS-only options before answering.

---

## Backfill scope — migrate vs grandfather

### Q1 — How wide is the backfill?

| Option | Description | Selected |
|--------|-------------|----------|
| Full migration — all 33 archived SUMMARYs | Rename 5 underscore→hyphen. Add field to 4 missing. Strip + comment-preserve sibling fields on ~6 phase-18 files. | ✓ |
| Forward-only — grandfather all v1.0 + v1.2 | Lint path-filters to v1.3+ only. | |
| Targeted — add field to 4 missing files only | Rename underscore. Skip sibling stripping. | |

**User's choice:** Full migration.

### Q2 — Migration mechanics?

| Option | Description | Selected |
|--------|-------------|----------|
| Single migration script + one commit | `scripts/migrate-summary-frontmatter.sh` does all 33 files. One commit. Reproducible diff. | ✓ |
| Per-milestone commits | Three commits: v1.0, v1.2, missing-field. | |
| Per-file manual edits | Author edits each individually. Highest quality, slowest. | |

**User's choice:** Single migration script + one commit.

### Q3 — Source of IDs for the 4 SUMMARYs missing the field?

| Option | Description | Selected |
|--------|-------------|----------|
| Read sibling PLAN.md `requirements:` and copy verbatim | Trusts original plan declaration. | ✓ |
| Author manually inspects each, edits to actually-delivered | More accurate; requires reading 4 SUMMARYs + 4 PLANs. | |
| Emit empty `[]` with rationale comment, defer accuracy | Migration sets `[]  # backfilled — not audited`. | |

**User's choice:** Read PLAN verbatim.

### Q4 — Migration script disposition?

| Option | Description | Selected |
|--------|-------------|----------|
| Discard after migration commit | Script `git rm`'d in same commit. Reproducibility via git history. | ✓ |
| Keep in `scripts/` as one-shot tool | Available for future emergency use. | |
| Promote to permanent `scripts/lint-summaries.sh --fix` mode | Lint gains `--fix` flag. | |

**User's choice:** Discard after migration.

---

## Claude's Discretion

- Lint error message format (warnings vs hard fails, multi-file reporting, exit codes)
- yq query syntax
- Migration script's exact comment format for stripped sibling fields (preserve-as-comment principle is locked; format wording is discretion)
- Internal order of script operations (rename / strip / add-missing) — single-pass, doesn't surface to reviewers
- Whether to emit a one-time migration report inside the migration commit message body

## Deferred Ideas

- Cross-checking listed IDs against active milestone REQUIREMENTS.md catalog
- Pre-commit hook in addition to CI
- Promoting `lint-summaries.sh` to a `--fix` flag mode
- Whole-frontmatter casing audit (`tech_stack` underscore vs `tech-stack` hyphen across archived files)
- Visual / text-format requirement-to-SUMMARY traceability report from `audit-milestone.md`
