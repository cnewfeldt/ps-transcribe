# Phase 22: Process & Frontmatter Standard - Context

**Gathered:** 2026-05-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Standardize the `requirements-completed` YAML frontmatter field across all SUMMARY.md templates and archived files; auto-populate it during plan execution; enforce presence + ID-subset correctness via a CI lint gate. Phase produces v1.3's own SUMMARYs in the canonical format (dogfood from day one).

**In scope:**
- Canonicalize `requirements-completed` (hyphen) across `templates/summary.md`, `summary-standard.md`, `summary-minimal.md`
- Update `REQUIREMENTS.md` PROCESS-01..03 to use the hyphenated key
- Update `gsd-doc-writer` agent + `execute-plan.md` `<step name="create_summary">` to emit the field verbatim from PLAN.md `requirements:`
- New CI workflow `.github/workflows/lint-summaries.yml` running `scripts/lint-summaries.sh` (Bash + yq, macos-26)
- One-time migration of 33 archived SUMMARYs (v1.0 + v1.2) via ephemeral `scripts/migrate-summary-frontmatter.sh`

**Out of scope:**
- Cross-checking IDs against milestone REQUIREMENTS.md catalog (lint stops at PLAN.md subset)
- Pre-commit hook (CI-only enforcement)
- Canonizing richer vocabulary (`-scaffolded`, `-supports`, `-touched-but-not-completed`) — stripped during migration, content preserved as YAML comments
- Generator inferring delivered-vs-declared from commit history
- Promoting migration script to a permanent `--fix` flag on lint

</domain>

<decisions>
## Implementation Decisions

### Field name canonical form
- **D-01:** Canonical key is `requirements-completed` (hyphen). Matches existing repo YAML convention (`tech-stack`, `key-files`, `key-decisions`) and 24 of 29 archived files.
- **D-02:** Update `REQUIREMENTS.md` PROCESS-01, PROCESS-02, PROCESS-03 wording (currently underscore) to hyphen as the first task of the phase, before any other change. Single source of truth.
- **D-03:** All three SUMMARY templates carry the field: `templates/summary.md`, `summary-standard.md`, `summary-minimal.md`. Lint applies uniformly; minimal stays minimal but never optional on traceability.
- **D-04:** Empty list `requirements-completed: []` is valid (plan delivered no user-visible requirements). Inline `# rationale` comment encouraged but not required by lint.

### Field semantics
- **D-05:** Strict — only `requirements-completed` is canonical. Sibling fields (`requirements-scaffolded`, `requirements-supports`, `requirements-touched-but-not-completed`) used in v1.2 phase 18 are NOT canonized. Generator never emits them; lint flags them as deprecated.
- **D-06:** During migration, sibling fields are stripped from YAML and re-attached as inline comments above `requirements-completed`. Format: `# scaffolded: [DICT-02, DICT-03]  # historical sibling field, retired in Phase 22`. Preserves archival nuance as human-readable note.
- **D-07:** Lint depth = presence + subset check. `SUMMARY.requirements-completed ⊆ PLAN.requirements`. Catches typos and copy-paste drift without coupling to milestone REQUIREMENTS.md catalog.
- **D-08:** Auto-population copies PLAN.md `requirements:` verbatim into SUMMARY `requirements-completed:`. Author edits down if not all declared IDs were delivered. Matches Phase 18-01 reality where author wrote `[]` after scaffolding-only realization.

### Enforcement gate
- **D-09:** CI-only gate. New workflow `.github/workflows/lint-summaries.yml` runs on PRs that touch `**/*-SUMMARY.md` or `**/*-PLAN.md`. No pre-commit hook (avoids `--no-verify` escape and per-developer install friction).
- **D-10:** Lint implementation = Bash + `yq` in `scripts/lint-summaries.sh`. No npm, no Python toolchain. `yq` installed via Homebrew on the runner.
- **D-11:** Workflow runs on `macos-26` (matches `build-check.yml`). Separate workflow file (not appended to build-check.yml) so doc-only PRs don't wait on `swift build`. Path-filtered to skip when no SUMMARY/PLAN changed.

### Backfill scope
- **D-12:** Full migration — all 33 archived SUMMARYs (v1.0 + v1.2) brought to canonical. Lint runs against entire repo with no path filter. v1.3+ files compliant from creation.
- **D-13:** Migration mechanics = single ephemeral script `scripts/migrate-summary-frontmatter.sh` doing rename (5 files) + sibling-stripping with comment preservation (~6 files) + add-missing-field (4 files). One commit: `chore(planning): migrate SUMMARY frontmatter to canonical requirements-completed`. Script `git rm`'d in same commit (reproducibility lives in git history).
- **D-14:** For the 4 SUMMARYs missing the field entirely, the migration script reads each sibling PLAN.md `requirements:` and emits `requirements-completed:` matching it verbatim. Trusts original plan declaration; no manual audit required.

### Claude's Discretion
- Lint error message format (warnings vs hard fails, multi-file reporting, exit codes)
- yq query syntax (e.g., `yq eval '.requirements-completed'` vs `yq -r`)
- Migration script's exact comment format for stripped sibling fields (only the format is at discretion; the preserve-as-comment principle is locked in D-06)
- Order of script operations (rename-first vs add-missing-first vs strip-siblings-first) — script is single-pass, internal order doesn't surface to reviewers
- Whether to emit a one-time migration report (text summary of files touched, IDs added) inside the migration commit message body

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Spec & milestone context
- `.planning/REQUIREMENTS.md` — PROCESS-01..03 (target of D-02 rewording); definition of v1.3 phases.
- `.planning/ROADMAP.md` §"Phase 22: Process & Frontmatter Standard" — goal, success criteria, dogfooding rationale.

### SUMMARY templates (write targets)
- `~/.claude/get-shit-done/templates/summary.md` line 41 — current `requirements-completed: []` (already correct; needs documentation tightening + remove conflicting underscore reference in D-08 path).
- `~/.claude/get-shit-done/templates/summary-standard.md` — currently lacks the field; D-03 adds it.
- `~/.claude/get-shit-done/templates/summary-minimal.md` — currently lacks the field; D-03 adds it.

### Generator pathways
- `~/.claude/get-shit-done/workflows/execute-plan.md` line 333-345 (`<step name="create_summary">`) — populates SUMMARY frontmatter; line 336 already says `MUST copy `requirements` array from PLAN.md frontmatter verbatim` — verify generator code path matches the spec text.
- `~/.claude/agents/gsd-doc-writer.md` — alternate SUMMARY emission path; needs same verbatim-copy contract.

### Consumer pathways (don't break)
- `~/.claude/get-shit-done/workflows/audit-milestone.md` line 114, 118, 331 — already reads `requirements-completed`; D-01 is consistent with this.
- `~/.claude/get-shit-done/bin/lib/commands.cjs` line 464 (`summary-extract` command) — already normalizes hyphen→underscore in JS output; no change required.

### Archive (migration targets)
- `.planning/milestones/v1.0-phases/` — historical SUMMARYs (where present)
- `.planning/milestones/v1.2-phases/16-foundation/16-01..04-SUMMARY.md` — 4 files using `requirements_completed` (underscore, rename targets)
- `.planning/milestones/v1.2-phases/17-model-auto-update/17-01..05-SUMMARY.md` — mixed compliance
- `.planning/milestones/v1.2-phases/18-hotkey-dictation-plain-folder-output/18-01..09-SUMMARY.md` — primary source of `-scaffolded`, `-supports`, `-touched-but-not-completed` siblings (D-06 strip+comment targets)
- `.planning/milestones/v1.2-phases/18-hotkey-dictation-plain-folder-output/18-09-SUMMARY.md` — uses `requirements_completed` (underscore, rename target)

### CI infra
- `.github/workflows/build-check.yml` — pattern reference for the new `lint-summaries.yml`. macos-26 runner, single Swift step. New workflow mirrors structure but installs `yq` and runs the lint script.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `gsd-tools.cjs summary-extract` (`bin/lib/commands.cjs:464`) — parses SUMMARY frontmatter and exposes `requirements_completed` as a normalized JS field. Lint script can shell out to this for parsing (`gsd-tools summary-extract <path> --pick requirements_completed`) instead of reinventing YAML parsing — reduces yq dependency surface, but binds lint to the gsd-tools install. Trade-off for planner: standalone yq vs reusing gsd-tools.
- `execute-plan.md:336` already documents the verbatim-copy contract from PLAN.md → SUMMARY. Generator code path likely already conforms; phase work is mostly verifying + reinforcing.

### Established Patterns
- YAML frontmatter convention: hyphenated keys (`tech-stack`, `key-files`, `key-decisions`, `dependency-graph` in some files). Mixed casing exists (some files use `tech_stack` with underscores). D-01 stays in the hyphen camp; if a future cleanup wants whole-frontmatter consistency, that's a separate phase.
- Existing CI workflow style: single-purpose macos-26 runner, minimal step list, branch trigger on PRs to `main`. New lint workflow follows the same shape.
- One-shot migration scripts: precedent unclear (no `scripts/migrate-*` exists currently). D-13's discard-after-commit pattern is novel for this repo but standard practice.

### Integration Points
- Phases 23-27 (v1.3) will produce SUMMARY.md files via `execute-plan.md` — they're the dogfooding test. After Phase 22 ships, every Phase 23+ SUMMARY must pass the lint or CI blocks the merge.
- `audit-milestone.md` runs at milestone close and extracts `requirements-completed` from every SUMMARY. After full migration, the audit covers v1.0 + v1.2 + v1.3 uniformly with no special-cased parsers.

</code_context>

<specifics>
## Specific Ideas

- Empty-list rationale comment style observed in v1.2 phase 18 (e.g., `requirements-completed: []  # Wave 0 ships test scaffolding only -- no requirement is delivered until its implementing wave (18-02..08) lands and un-disables the corresponding @Suite.`) is the gold standard. Generator should not emit this comment automatically, but documentation should reference 18-01 as the canonical example for plans that legitimately deliver nothing.
- For migration commit message body: include a per-file disposition table (rename / sibling-strip / add-missing) so the diff is self-documenting on review.

</specifics>

<deferred>
## Deferred Ideas

- Cross-checking listed IDs against active milestone `REQUIREMENTS.md` catalog (rejected as too tightly coupled; lives in `audit-milestone.md` instead).
- Pre-commit hook in addition to CI (rejected as friction without enough additional safety; CI is the gate).
- Promoting `lint-summaries.sh` to a `--fix` flag mode (rejected — keeps lint and migration concerns separate; revisit if a second migration ever becomes necessary).
- Whole-frontmatter casing audit (some archived files use `tech_stack` underscore vs `tech-stack` hyphen). Belongs in its own future phase if pursued.
- Visual / text-format report from `audit-milestone.md` showing requirement-to-SUMMARY traceability heatmap. Out of scope here; could land as a v1.4+ tooling improvement.

</deferred>

---

*Phase: 22-process-frontmatter-standard*
*Context gathered: 2026-05-02*
