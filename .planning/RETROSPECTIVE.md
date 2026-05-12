# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.3 — Polish & Validation

**Shipped:** 2026-05-12
**Phases:** 6 (22 / 23 / 24 / 25 / 26 / 26.1) | **Plans:** 21 | **Timeline:** 11 days (2026-05-01 → 2026-05-11)

### What Was Built

- **SUMMARY frontmatter standard** — `requirements-completed:` (hyphen) key in 3 templates + `execute-plan.md` 4-rule contract + `scripts/lint-summaries.sh` (Bash + yq) + `.github/workflows/lint-summaries.yml` CI gate. 18 archived SUMMARYs canonicalised via ephemeral migration. (Phase 22, regression closure in 26.1)
- **Visual regression infra** — swift-snapshot-testing 1.19.2, 15 baselines × 5 surfaces × 3 appearances (Light/Dark/System), `build-check.yml` integration with record-mode env-var guard + failure-only diff-PNG artifact upload, Nygard ADR + `CONTRIBUTING.md`. (Phase 23)
- **Nyquist `*-VALIDATION.md` backfill** for v1.0 phases 1/2/3/8/10 (Phase 24) + v1.2 phases 20/21 (Phase 25). 10 new test files / 26 net-new @Test methods. Suite grew 236 → 274 / 42 → 53. (Phases 24 + 25)
- **Phase 19 QA checklist sweep + Phase 21 titlebar visual UAT** — 10 row dispositions in `26-UAT.md`, terminal status `approved-with-debt`. QA-01/02/04 WITHDRAWN with codebase-verified reasoning, QA-05 UNTESTABLE-this-cycle deferred to todo. DICT-06 retired mid-phase after smoke-test UX regression. (Phase 26)

### What Worked

- **D-03 lenient Nyquist policy.** WITHDRAWN-with-cited-source rows let VALIDATION.md reflect codebase reality without forcing fake-coverage tests. Phases 24 + 25 both used this; produced honest validation artifacts faster than insisting every original requirement get a green @Test.
- **Codebase-verified WITHDRAWAL during Phase 26.** Rather than execute QA-04 (security-scoped bookmark survival) blind, the phase ran a grep across `PSTranscribe/Sources` for `withSecurityScope|startAccessing|stopAccessing` — zero hits — and confirmed `PSTranscribe.entitlements` has no `app-sandbox` key. WITHDRAWN with citation; saved an entire UAT loop on a non-existent code path.
- **Phase 26.1 as a structural insertion.** When Phase 24's restore-the-v1.0-archive sub-step regressed the Phase 22 lint gate, the response was a new decimal phase (26.1, single 1-task plan), not a force-push or amend. Reproducible-via-history. Inserted after the audit identified the gap; closed in <30 min.
- **Smoke-test-driven retirement (DICT-06).** Phase 26-02 surfaced a real UX problem with the 3s clipboard restore during dictation→paste. The fix was retirement, not a forward toggle or "fix later" backlog item. 268/268 tests pass post-retirement.

### What Was Inefficient

- **`one_liner: null` in Phase 26 SUMMARYs.** The milestone.complete CLI builds the MILESTONES.md key-accomplishments list from `summary-extract --fields one_liner`. Phase 26's two SUMMARYs both had `one_liner: null`, so the CLI's flat list dropped Phase 26 entirely. Had to backfill the MILESTONES entry by hand from VERIFICATION.md + the milestone audit. Fix going forward: lint the `one_liner` field as required (non-null) in `summary-standard.md`, or post-process null one-liners during summary creation.
- **lint-summaries.sh scope blind spot.** `DEFAULT_ROOT=.planning/milestones` doesn't cover `.planning/phases/` (active phases). No current violation, but the CI workflow path filter triggers on active-phase SUMMARY files while the script ignores them. Latent footgun for the next milestone — would have caught Phase 26.1's `requirements-completed: []` requirement earlier if the script scanned both trees.
- **CI build-check.yml strict-concurrency regression discovered late.** Phase 24's Plan 24-05 added a push-to-main trigger; the macos-26 runner's fallback Xcode revealed pre-existing Swift 6 strict-concurrency errors at `TranscriptionEngine.swift:238,342` (from 2026-04-02). Local builds passed; toolchain divergence masked the issue for ~6 weeks. Tracked as `ci-build-check-failing-on-main.md`; blocks Phase 24 CI green attestation.
- **MILESTONES.md CLI output is a flat list, not phase-grouped.** Had to manually rewrite the v1.3 entry to match the v1.2 phase-grouped numbered-list style. Future improvement: have `milestone.complete` accept a `--style phase-grouped` flag or post-process by phase prefix in the SUMMARY path.

### Patterns Established

- **Decimal-phase insertion for in-milestone regression closure.** Phase 26.1 = the canonical example. Don't amend or force-push; insert a numbered phase, run the standard discuss/plan/execute chain (or a fast `/gsd-quick` for trivial fixes), commit atomically. Preserves git history as the source of truth.
- **Codebase-verified WITHDRAWAL for QA.** Before executing a QA scenario, grep for the code path it tests. If the path doesn't exist, WITHDRAW with citation rather than fake the test. Faster, more honest, and produces a better audit trail.
- **Ephemeral migration scripts ship as 2-commit pair.** Phase 22-06 pattern: commit-add the script, run it, commit-remove the script alongside the migrated files. Single-commit add+delete nets to zero in git and defeats D-13 reproducibility-via-history.
- **`requirements-completed: []` for closure phases.** Frontmatter-only phases that touch zero requirement surface (Phase 26.1) need the empty-list form to satisfy lint C1. Documented as Phase 22 D-04.

### Key Lessons

1. **Make summary one-liners required, not optional.** A null one-liner in a SUMMARY silently drops the phase from milestone roll-ups. The lint script should treat `one_liner: null` (or missing) the same way it treats missing `requirements-completed:`.
2. **CI runner divergence kills "local build green" as a quality signal.** When a CI gate exists, run it locally with the same toolchain (or pin Xcode versions in `build-check.yml`). The Swift 6 strict-concurrency regression survived for ~6 weeks because local builds used a different Xcode than the macos-26 runner's fallback.
3. **Audit gaps with status `tech_debt` are safe to close on.** The milestone audit explicitly states "The milestone is not blocked" when all goal-level pillars are closed and remaining items are deferred-with-todo or accepted tech debt. Don't conflate `tech_debt` with `gaps_found`; the latter blocks close, the former carries forward.
4. **Retire requirements that the codebase has moved past.** QA-01/02 (Maccy/Alfred positioning), QA-04 (security-scoped bookmarks), DICT-06 (clipboard restore) — all retired during v1.3 because reality contradicted the original requirement language. Retirement-with-citation > fake-green tests > silently-failing scope.

### Cost Observations

- Model mix: Predominantly Opus 4.6 (Phase 22 + 24 + 25 + 26 planning/execution); Sonnet 4.6 for high-volume edits (Phase 22-06 migration, Phase 23-03 baseline recording); Haiku 4.5 for quick lookups during audit cross-references.
- Sessions: ~12 (one or two per phase, Phase 24 spread across 3 due to CI-debt discovery and the 5-plan scope).
- Notable: The audit-then-close cadence ran twice — initial audit found `gaps_found` (PROCESS-03 regression), insert Phase 26.1, re-audit, then close. Both audits used <100k tokens; both produced actionable closure paths. The pattern is cheap and high-leverage.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | ~30+ | 8 active (5/6 abandoned) | Initial milestone; introduced ROADMAP.md split + decimal phase insertion |
| v1.1 | ~10 | 4 (15 reverted) | Marketing site under `/website`; revert as a first-class outcome |
| v1.2 | ~15 | 6 executed (19 removed) | Phase 18.1 architectural pivot pattern; shared save-destinations layer |
| v1.3 | ~12 | 6 (26.1 inserted) | Decimal-phase regression closure; D-03 lenient Nyquist policy; CI lint gate for SUMMARY frontmatter |

### Cumulative Quality

| Milestone | Tests | Suites | New @Test methods this milestone |
|-----------|-------|--------|----------------------------------|
| v1.2 close | 236 | 42 | — (baseline) |
| v1.3 Phase 24 | 262 | 51 | +26 (Phase 24) |
| v1.3 Phase 25 | 274 | 53 | +12 (Phase 25) |
| v1.3 close | 268 | 52 | net −6 (DICT-06 retirement reduced) |

### Top Lessons (Verified Across Milestones)

1. **Decimal-phase insertion for in-milestone surprises.** Phase 18.1 (v1.2, architectural pivot), Phase 26.1 (v1.3, regression closure). Both produced clean git history; both inserted after audit/feedback, not as desperate amends.
2. **Retire scope rather than fake-green it.** Phase 15 (v1.1 changelog) reverted; Phase 19 (v1.2 hardening) removed at close; DICT-06 + QA-01/02/04 retired in v1.3. Retirement is a first-class outcome; the project ships more honestly than it would with WONTFIX backlog rot.
3. **Pre-existing tech debt surfaces during validation phases.** v1.3 Phase 24 surfaced CI strict-concurrency debt from April 2026; v1.2 surfaced 4 Phase 18.1 architectural warnings. Validation milestones aren't free — budget time for the debt they discover.
