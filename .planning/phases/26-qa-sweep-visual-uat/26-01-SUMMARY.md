---
phase: 26-qa-sweep-visual-uat
plan: 01
status: complete
requirements-completed: [QA-03, QA-06, QA-07, QA-08, QA-09]
requirements-retired: [QA-01, QA-02, QA-04]
requirements-deferred: [QA-05]
created: 2026-05-11
---

## What shipped

- `.planning/phases/26-qa-sweep-visual-uat/26-UAT.md` — manual UAT artifact, 10 row IDs (QA-01, QA-02, QA-03a, QA-03b, QA-04, QA-05, QA-06, QA-07, QA-08, QA-09 — QA-03 split into 03a/03b per the Phase 24/25 PARTIAL convention). Terminal status `approved-with-debt` (one untestable-this-cycle row at QA-05).
- `.planning/todos/pending/model-manifest-url-404.md` — incidental finding from QA-05 attempt: the production model manifest URL returns HTTP 404, blocking `ModelUpdateService.downloadAndApply()` end-to-end. Tracked as a release/deployment-process gap rather than a code defect.
- `.planning/REQUIREMENTS.md` — QA-01 and QA-02 marked retired (mirrors the DICT-06 retirement pattern from 26-02): strikethrough text + retirement note + traceability table flipped from `Not started` to `Retired (Phase 26)`.

Intra-phase fix plan that landed mid-sweep (separate plan, separate commits — referenced for completeness):
- `.planning/phases/26-qa-sweep-visual-uat/26-02-PLAN.md` + `26-02-SUMMARY.md` — DICT-06 (clipboard restore) retired after the smoke test in Task 2 of 26-01 surfaced that the 3-second restore window broke the dictation -> paste user flow. Routed in-phase per D-02 (5 small commits, ≤7 files touched, ≤1hr scope). Smoke test re-run on the rebuilt binary at `51212c1` PASSED. See 26-02-SUMMARY.md for details.

## Disposition summary

| Row | Disposition | Notes |
| --- | --- | --- |
| QA-01 | WITHDRAWN (retired) | D-01 evolved: PS Transcribe not positioned as a Maccy-friendly tool. |
| QA-02 | WITHDRAWN (retired) | Same reasoning as QA-01 — Alfred installed but not used or offered. |
| QA-03a | pass | Single-display HUD positioning matches `NSScreen.main.visibleFrame` math. |
| QA-03b | pass | Multi-monitor primary-screen sub-scenario tested (rig present); remaining matrix items absorbed into the same row, not split further. Contradicts the original plan's UNTESTABLE-this-cycle prediction — D-01's hardware-availability assumption was wrong. |
| QA-04 | WITHDRAWN | Codebase-verified: app is non-sandboxed (no `app-sandbox` entitlement key); folder paths persist as plain `String` in `UserDefaults` (`AppSettings.swift:81/82` + `:96/97`); zero hits for `withSecurityScope` / `startAccessing` / `stopAccessing` across `PSTranscribe/Sources`. The PITFALLS.md line 519 premise was speculative about a sandboxed scenario that did not materialize. |
| QA-05 | untestable-this-cycle | Disk-space preflight unreachable end-to-end because upstream `fetchManifest()` fails first with HTTP 404. Tracked in `model-manifest-url-404.md`. |
| QA-06..QA-09 | pass (citation) | Cited from `21-HUMAN-UAT.md` Tests 1-4 (passed 2026-05-01, user attestation) per D-03 — no re-execution. |

## Decisions referenced

- **D-01 (hybrid environment):** Evolved mid-sweep. Original assumption was test under both Maccy and Alfred; user's actual posture is "does not use Maccy, does not use Alfred even though installed, does not advertise either as a supported integration." Result: QA-01 and QA-02 WITHDRAWN and retired in REQUIREMENTS.md. The DICT-09 privacy markers stay in the codebase as defensive nspasteboard.org standards compliance, but their behavior under any specific manager is no longer a phase-26 acceptance contract. Separately, the multi-monitor hardware-availability assumption was also wrong — the user does have a multi-monitor rig and tested the primary-monitor sub-scenario (QA-03b PASS), so the planned UNTESTABLE-this-cycle disposition for 03b was upgraded to PASS for the tested case.
- **D-02 (batch-triage size-based routing):** Honored. Smoke-test FAIL discovered in Task 2 (clipboard restore breaking dictation -> paste flow) routed in-phase as 26-02-PLAN.md (small focused fix, mechanical test follow-on). The QA-05 disk-space preflight blocker was routed to a deferred todo (`model-manifest-url-404.md`) because the fix is release/deployment-process work outside the codebase's source tree.
- **D-03 (text attestation, citation rows for QA-06..09):** Honored. No screenshots / recordings produced for any row. QA-06..09 cite `21-HUMAN-UAT.md` Tests 1-4 (passed 2026-05-01, user attestation) without re-execution. The four citation strings appear verbatim in 26-UAT.md row bodies and again in the Cross-References footer.
- **D-04 (single execution plan + 26-UAT.md filename + CI todo NOT folded):** Honored. One 26-01-PLAN.md drove the full sweep; the in-phase fix landed as a separate 26-02-PLAN.md (consistent with D-02 size routing, not a violation of D-04's single-plan intent). Artifact filename is `26-UAT.md` (matches ROADMAP success criterion 1). The CI infrastructure todo `ci-build-check-failing-on-main.md` was reviewed at score 0.6 by `gsd-sdk query todo.match-phase 26` and intentionally excluded from this phase — surface mismatch (Phase 26 tests user-facing app behavior, not CI infrastructure). It remains in `.planning/todos/pending/` for a future CI-focused phase.

## Build provenance

- Build: local debug from `main` HEAD via `swift build -c debug --package-path PSTranscribe`; not a Sparkle release.
- git SHA at sweep start: `1f54061`
- git SHA at 26-02 close (smoke-test re-run binary): `51212c1`
- macOS / Xcode versions not captured for the row.
- Working tree at sweep close: clean (the QA-05 debug-only `#if DEBUG` override of `diskSpaceProvider` in `PSTranscribeApp.swift` was applied and reverted; `git status --porcelain` returned only the pre-existing `M .planning/STATE.md`).

## Cross-references

- `.planning/phases/26-qa-sweep-visual-uat/26-UAT.md` — primary artifact (10 rows, terminal status `approved-with-debt`).
- `.planning/phases/26-qa-sweep-visual-uat/26-02-SUMMARY.md` — DICT-06 retirement (in-phase fix plan that resolved the smoke-test FAIL).
- `.planning/todos/pending/model-manifest-url-404.md` — incidental QA-05 blocker (release/deployment-process gap).
- `.planning/REQUIREMENTS.md` — QA-01 / QA-02 marked retired; QA-03..09 traceability row pending milestone close.
- `.planning/milestones/v1.2-phases/21-appearance-override/21-HUMAN-UAT.md` — citation source for QA-06..09 (passed 2026-05-01, user attestation).

## Self-Check: PASSED

Verification performed at SUMMARY.md write time:

- `test -f .planning/phases/26-qa-sweep-visual-uat/26-UAT.md` -> exists
- `grep -cE '^### [0-9]+(a|b)?\. QA-0[1-9]' .planning/phases/26-qa-sweep-visual-uat/26-UAT.md` -> 10
- `grep -c 'WITHDRAWN' .planning/phases/26-qa-sweep-visual-uat/26-UAT.md` -> 3 (QA-01, QA-02, QA-04)
- `grep -c 'passed 2026-05-01, user attestation' .planning/phases/26-qa-sweep-visual-uat/26-UAT.md` -> 5 (4 citation rows + 1 Cross-References footer mention)
- `test -f .planning/todos/pending/model-manifest-url-404.md` -> exists, `status: pending`, `source: phase-26`
- `grep '^| QA-01 ' .planning/REQUIREMENTS.md` -> shows `Retired (Phase 26)`
- `grep '^| QA-02 ' .planning/REQUIREMENTS.md` -> shows `Retired (Phase 26)`
- Commit hashes recorded below.

## Commits

- `8e5da2f` — feat(26-01): author 26-UAT.md with sweep dispositions
- `199a382` — docs(26): defer manifest-url-404 finding to backlog
- `b96c18e` — docs(26): retire QA-01 / QA-02 in v1.3 requirements
- (this commit) — docs(26-01): seal plan with sweep summary
