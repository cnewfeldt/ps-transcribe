# Phase 24: Nyquist Sweep — v1.0 - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Backfill `*-VALIDATION.md` for v1.0 phases 1, 2, 3, 8, and 10 — flipping each from `status: draft` / `nyquist_compliant: false` to `status: approved` / `nyquist_compliant: true` with **real Swift Testing assertions** that run green in CI (`swift test` inside `build-check.yml`). Closes the partial/missing Nyquist coverage flagged in `milestones/v1.0-MILESTONE-AUDIT.md` for the four restored v1.0 phases plus a re-audit of Phase 1 (previously approved on 2026-04-27 via `swift build` + grep alone, before the test target existed).

**In scope:**
- Re-audit and update `01-VALIDATION.md` (Rebrand) — REBR-01..07 (REBR-08 deleted, see D-03)
- Update `02-VALIDATION.md` (Security + Stability) — SECR-01..12, STAB-01..04 (untestable subset withdrawn per D-03)
- Update `03-VALIDATION.md` (Session Library + Recording Naming) — SESS-01..05/07..09, NAME-01..05 (untestable subset withdrawn)
- Update `08-VALIDATION.md` (Code Defect Fixes) — DEFC-class requirements covered in `08-VERIFICATION.md`
- Update `10-VALIDATION.md` (Obsidian Deep-link + Defect Cleanup) — SESS-06 + remaining DEFC items
- New flat test files at `PSTranscribe/Tests/PSTranscribeTests/` named by the behavior they exercise (per D-04)
- ~30–40 `@Test` methods total (one per testable requirement, per D-02), all running under existing Swift Testing target with `import Testing`
- All new tests run green via `swift test` locally and in `build-check.yml` CI on macos-26
- Each VALIDATION.md gets `last_audited: 2026-05-XX` frontmatter stamp

**Out of scope:**
- Re-running v1.0 milestone audit (already passed 2026-04-27; this is opt-in hygiene, not a re-gate)
- Phase 4 (Mic Button) and Phase 7 (Notion) and Phase 9 (Verification Sweep) — those phase directories live only in git history (per audit); restoring them is a Phase 25-or-later question if it ever matters
- Phase 25 v1.2 sweep (NYQUIST-06, NYQUIST-07) — separate phase
- Manual-Only entries in VALIDATION.md (per D-03 — withdrawn requirements are out, not converted to manual)
- Adding integration-test scaffolding for force-quit / SIGKILL / runtime entitlement scenarios (per D-03)
- Restoring or rewriting REBR-08 UserDefaults migration code (deleted post-v1.0 in commit 4ef30e0; no surviving public API)
- New visual regression / snapshot tests (Phase 23 covers that surface; Phase 24 is unit/integration only)
- Moving restored v1.0 phase directories from `.planning/phases/` to `.planning/milestones/v1.0-phases/` — separate cleanup, captured in Deferred Ideas
- Extending coverage beyond the 5 restored v1.0 phases

</domain>

<decisions>
## Implementation Decisions

### Phase 1 re-audit posture

- **D-01:** Phase 24 covers all 5 v1.0 phases (1, 2, 3, 8, 10) — including Phase 1 even though `01-VALIDATION.md` was retroactively approved on 2026-04-27 via `swift build` + grep audit alone. Phase 1's approval predates the existence of a real `swift test` target; Phase 24 backfills genuine Swift Testing assertions for the testable parts of REBR-01..07 (Info.plist bundle ID, app name, executable rename, workflow secrets), bumps `last_audited` to the Phase 24 completion date, and keeps the existing `status: approved` / `nyquist_compliant: true`. Lean alternative ("leave Phase 1 alone") was rejected — uniform sweep is cleaner than carrying a permanent asterisk on Phase 1's audit basis.

### Coverage depth

- **D-02:** **One `@Test` per testable requirement ID.** REBR-01..07 each get a test; SECR-01..12 each get one (those that are automatable per D-03); STAB-01..04, SESS-01..09 minus 06, NAME-01..05, DEFC items same pattern. Matches the existing draft `02-VALIDATION.md` / `03-VALIDATION.md` per-row table structure (which was authored to be filled at this granularity). Phase-level coverage (5 tests for 5 success criteria) and behavior-cluster coverage (~15 tests grouped by code path) were rejected — both lose the requirement-level granularity that the existing draft VALIDATION tables already encode. Each test is small (assertion-level), so total suite size lands ~30–40 `@Test` methods after D-03 withdrawals.

### Untestable / removed-code policy

- **D-03:** **Lenient policy — untestable requirements get `WITHDRAWN` status in VALIDATION.md.** No Manual-Only fallback rows. A requirement is WITHDRAWN-for-Nyquist (not WITHDRAWN-from-the-product, which the v1.0 audit already locked as satisfied) when it requires:
  - Code that no longer exists (REBR-08 — migration deleted in commit `4ef30e0`)
  - Force-quit / SIGKILL mid-process (STAB-01 crash recovery, SECR-09 atomic-write-under-kill)
  - Runtime entitlement state the test target can't simulate (STAB-04 mic permission denial)
  - Live UI / NSWorkspace interaction (SESS-04 right-click "Show in Finder")
  - Live FS side effects from a running app instance (SECR-02 `/tmp` log absence, SECR-04 audio temp location, SECR-06 file mode 0600 after a real session)
  
  WITHDRAWN rows stay in the Per-Task Verification Map with `Test Type: WITHDRAWN` and a one-line reason; they do NOT block `nyquist_compliant: true`. The validation contract becomes honest about what automation does and doesn't cover; the v1.0 milestone audit already accepted these as satisfied via manual evidence in `*-VERIFICATION.md`. This is a stricter posture than the 2026-04-27 Phase 1 audit (which kept manual entries as part of the approved bar) — chosen deliberately because Nyquist's purpose is automated feedback latency, and Manual-Only entries can't deliver it.
  
  Pure-function corners of "runtime-flavored" requirements get UNIT tests (e.g., SECR-10 filename sanitization helper, SESS-06 Obsidian deep-link URL construction, STAB-02 midnight offset math) — these are unit-testable even though the surrounding feature is runtime. Planner identifies which surviving public APIs exist per requirement during the audit step.

### Test file organization

- **D-04:** **Flat test files at the top of `PSTranscribe/Tests/PSTranscribeTests/`, named by the behavior they exercise**, NOT by phase. Examples:
  - `RebrandInfoPlistTests.swift` (REBR-01..04)
  - `WorkflowSecretsTests.swift` (REBR-05, SECR-01/05/07/12)
  - `FilenameSanitizationTests.swift` (SECR-10)
  - `MidnightOffsetTests.swift` (STAB-02)
  - `ObsidianDeepLinkTests.swift` (SESS-06)
  - `SessionNamingPolicyTests.swift` (NAME-01..05)
  - `SpeakerLabelCollapseTests.swift` (DEFC items from Phase 8/10)
  
  Matches the older v1.0 flat convention (`AppSettingsTests.swift`, `LibraryStoreTests.swift`, etc.). Phase-scoped subdirectory pattern (`Phase01/`, `Phase02/`, mirroring the existing `Phase18/` / `Phase18.1/` directories) was rejected — those subdirectories were created during *active* Phase 18+ development and overstate the connection here, where tests cover surviving code, not original code paths. Single `Phase24/` umbrella was also rejected — the tests are about product behavior, not about the audit phase that authored them. Final filenames are the planner's call within this convention.

### Claude's Discretion

- **Per-test temp-dir / fixture pattern** — Existing convention from `DictationLoggerTests.swift` (`private func tempDir()` + `defer { try? FileManager.default.removeItem(at: dir) }`) is reusable. Planner picks whether to lift that into a shared helper (e.g., `Phase24Fixtures.swift`) or inline per-test. Bias: inline unless three or more tests need it.
- **`@Suite(.serialized)` vs default parallelism** — Tests that mutate UserDefaults, `NSApp.appearance`, or shared FS paths must serialize (existing convention). Pure-function tests (URL construction, math, sanitization) do not. Planner annotates per suite.
- **Exact test names + assertion shapes** — Naming follows existing convention (`@Test func sanitizes_filenames_with_path_traversal()`). Planner picks between `#expect(condition)` and `#require(condition)` based on whether failure of one assertion should short-circuit the test.
- **Whether to read Info.plist via `Bundle.main` (runtime) vs file IO (build-time fixture)** — Both work for REBR-01..04. Planner picks the cleaner path; runtime via `Bundle(for: …)` matches how the app actually consumes it.
- **Plan splitting** — Planner picks whether Phase 24 is one plan per v1.0 phase audited (5 plans: 24-01 → 24-05, one per VALIDATION.md update + tests) or grouped by behavior cluster. Bias: 5 plans, one per phase, mirrors the `/gsd-validate-phase <N>` skill's natural unit and lets each plan close one VALIDATION.md atomically.
- **Order of plans within the phase** — Planner picks; suggested order is "smallest first": 01 (REBR), 10 (smallest defect set), 08, 03, 02 (largest with 16 reqs).
- **WITHDRAWN row formatting in VALIDATION.md** — Planner picks the exact column shape, but the row must include: `Test Type: WITHDRAWN`, requirement ID, one-line reason, and a pointer to where the v1.0 audit recorded the requirement as satisfied (e.g., `Source: 02-VERIFICATION.md`). Tests directory should not contain stub/empty test files for WITHDRAWN reqs.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap, requirements, milestone audit

- `.planning/ROADMAP.md` §"Phase 24: Nyquist Sweep — v1.0" — phase goal, success criteria 1–5, "optional benefit from Phase 22" dependency note.
- `.planning/REQUIREMENTS.md` §"Nyquist Validation Sweep (`NYQUIST-FUT-01`)" — NYQUIST-01..05 requirement IDs that this phase delivers.
- `.planning/PROJECT.md` — milestone v1.3 context.
- `.planning/milestones/v1.0-MILESTONE-AUDIT.md` — declares v1.0 audit-passed (2026-04-27); enumerates partial/missing Nyquist phases; explicitly frames this sweep as "opt-in retroactive hygiene." Section "Nyquist Compliance" lists per-phase status; section "Tech Debt" notes Phase 4/7/9 directories live only in git history (out of scope here).
- `.planning/milestones/v1.0-REQUIREMENTS.md` — v1.0 requirement IDs (REBR, SECR, STAB, SESS, NAME, DEFC) that the per-task map references.

### Existing v1.0 VALIDATION.md drafts (Phase 24 input — to be updated in place)

- `.planning/phases/01-rebrand/01-VALIDATION.md` — `status: approved` (2026-04-27, build+grep basis), `nyquist_compliant: true`. Phase 24 re-audits and adds real tests; bumps `last_audited`.
- `.planning/phases/02-security-stability/02-VALIDATION.md` — `status: draft`, 16 requirement rows, all currently `pending`.
- `.planning/phases/03-session-management-recording-naming/03-VALIDATION.md` — `status: draft`.
- `.planning/phases/08-code-defect-fixes/08-VALIDATION.md` — `status: draft`.
- `.planning/phases/10-final-defect-fixes-obsidian-deeplink/10-VALIDATION.md` — `status: draft`.

### Existing v1.0 VERIFICATION.md (cross-reference for "originally satisfied" evidence)

- `.planning/phases/01-rebrand/01-VERIFICATION.md` — confirms REBR-01..08 satisfied; REBR-08 verified live 2026-04-14.
- `.planning/phases/02-security-stability/02-VERIFICATION.md` — confirms SECR-01..12 + STAB-01..04 satisfied; the WITHDRAWN-for-Nyquist set per D-03 references this file.
- `.planning/phases/03-session-management-recording-naming/03-VERIFICATION.md`
- `.planning/phases/08-code-defect-fixes/08-VERIFICATION.md`
- `.planning/phases/10-final-defect-fixes-obsidian-deeplink/10-VERIFICATION.md`

### Test infrastructure (Phase 16 + Phase 23 baseline — DO NOT modify in this phase)

- `PSTranscribe/Package.swift` — `.testTarget(name: "PSTranscribeTests", ...)` already declared; adding `pointfreeco/swift-snapshot-testing` 1.19.2 was Phase 23. Phase 24 does NOT add new dependencies.
- `PSTranscribe/Tests/PSTranscribeTests/` — destination for new flat test files (per D-04). Existing convention: Swift Testing `@Suite` + `@Test`, `import Testing`, `@testable import PSTranscribe`.
- `PSTranscribe/Tests/PSTranscribeTests/DictationLoggerTests.swift` — canonical example of `tempDir()` + `defer` cleanup pattern reusable in Phase 24 tests that touch the FS.
- `.github/workflows/build-check.yml` — `swift test` step added in Phase 23 (D-06). Phase 24 piggybacks; no workflow changes needed. CI runs on macos-26 / Xcode 26.

### Codebase intelligence

- `.planning/codebase/TESTING.md` — refreshed in Phase 23-05; describes Swift Testing conventions and visual regression patterns. Phase 24 may add a short "Retroactive Nyquist tests" section but does not have to.
- `.planning/codebase/STACK.md` — Swift 6.2, macOS 26, SwiftPM.
- `.planning/codebase/CONVENTIONS.md` — `@MainActor` isolation rules; `@Suite(.serialized)` precedent for shared-state mutation.

### Sweep-pattern reference

- `$HOME/.claude/get-shit-done/workflows/validate-phase.md` — workflow for the per-phase Nyquist audit. Phase 24's plans operationalize this skill across 5 phases. State A (audit existing) applies to all 5 since each has a draft or approved VALIDATION.md.
- `$HOME/.claude/agents/gsd-nyquist-auditor.md` — agent invoked by `/gsd-validate-phase`. Planner decides whether to spawn it per plan, or just write the tests directly inline.

### Prior phase context (for the visual regression infra Phase 24 leans on)

- `.planning/phases/23-visual-regression-infra/23-CONTEXT.md` — Phase 23 D-01 (Swift Testing exclusively), D-06 (`swift test` step in `build-check.yml` on macos-26), test target conventions. Phase 24 inherits these wholesale.
- `.planning/phases/23-visual-regression-infra/23-VALIDATION.md` — recently approved Nyquist VALIDATION.md (`status: draft` at time of writing, but Phase 23 just completed; Phase 24 may also touch this file en passant if Phase 23's own Nyquist validation needs the same approval flip — but that's a separate concern, not Phase 24's primary scope).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **Existing Swift Testing test target** at `PSTranscribe/Tests/PSTranscribeTests/` with ~22 test files, including 18 in flat layout and 24 inside `Phase18/` + `Phase18.1/` subdirectories. Phase 24 adds new flat files; does not restructure the target.
- **`DictationLoggerTests.swift` `tempDir()` pattern** — canonical FS-fixture shape (capture, defer cleanup). Reused by any Phase 24 test that writes a file to assert on it (e.g., filename sanitization that wants to confirm the result actually round-trips through `FileManager`).
- **`MockURLProtocol.swift`** — already in the test target; reusable for any HTTP-shaped assertion (probably not needed here, but available).
- **Phase 23 `SnapshotFixtures.swift`** — establishes the pattern of grouping fixture helpers in their own file. Phase 24 may follow the same pattern (e.g., `Phase24Fixtures.swift`) only if three+ tests share helpers; otherwise inline.
- **`Bundle(for: AnyClass.self)` access at test runtime** — already used by existing tests for resource loads. Phase 24's `Bundle.main` reads (REBR-01..04 Info.plist assertions) follow the same shape.

### Established Patterns

- **Swift Testing only** — no XCTest in the test target (Phase 16+ established, Phase 23 reaffirmed in D-01). All Phase 24 tests use `import Testing` + `@Suite` + `@Test`.
- **`@Suite(.serialized)` for shared-state mutation** — UserDefaults, file system, NSApp.appearance. Phase 24 tests that mutate UserDefaults (any AppSettings interaction) must be serialized.
- **`@MainActor` for view-touching tests** — most Phase 24 tests are pure-function or FS, so this is rarely needed; flag if a planner picks an assertion that invokes a SwiftUI view.
- **`#expect` for non-blocking assertions, `#require` for short-circuit** — existing convention.
- **No XCTest legacy** — `assertSnapshot(of:as:)` form is Phase 23-only via swift-snapshot-testing's Swift Testing integration. Phase 24 does NOT use snapshot assertions (visual UAT is Phase 23's domain).

### Integration Points

- **`@testable import PSTranscribe`** — visual regression tests can construct any view + observable state directly. Phase 24 tests can read `Bundle.main`, instantiate `URL` extensions, exercise `AppSettings` migration helpers (whatever is left of them post-cleanup), and import private types if needed. No public API surface needs to change.
- **CI failure surface** — `swift test` in `build-check.yml` fails the PR check on red. Phase 24 tests inherit that gate verbatim. No new workflow changes.
- **VALIDATION.md frontmatter contract** — `status: approved`, `nyquist_compliant: true`, `wave_0_complete: true`, `last_audited: <date>`. Phase 24 produces 5 of these. Frontmatter format already established by Phase 1's 2026-04-27 approval and Phase 23's draft.

</code_context>

<specifics>
## Specific Ideas

- **Phase 1 re-audit despite already-approved status.** User explicitly chose to bring Phase 1 into Phase 24's scope rather than skipping it. The 2026-04-27 build+grep approval was provisional — sufficient when no test target existed, not the final bar now that one does. Phase 24 closes that gap.
- **WITHDRAWN, not Manual-Only.** D-03 is the strictest of the three policies presented. The product invariant: Nyquist's promise is automated feedback latency. Manual-Only rows can't deliver that. Phase 24 makes `nyquist_compliant: true` mean "everything in the Per-Task map is automated and green," not "everything is documented." The v1.0 audit already proved the WITHDRAWN reqs are satisfied through other evidence; that evidence is preserved in `*-VERIFICATION.md`, not duplicated into Phase 24's tests.
- **Flat test layout, not phase-scoped.** D-04 chose the older v1.0 convention. The reasoning: tests cover surviving product behavior, not original code paths. A future reader looking at `FilenameSanitizationTests.swift` should not have to learn that those tests were "audit-era backfills" — they're tests of how sanitization works today.
- **REBR-08 migration code is gone.** Commit `4ef30e0` removed it post-v1.0 because the upgrade window had closed. There is no API to test. WITHDRAWN, with the reason "code deleted post-v1.0 (4ef30e0); upgrade window closed; v1.0 milestone audit verified live migration on 2026-04-14."
- **Five plans, one per phase audited.** Suggested by D-04's Claude's Discretion notes; matches the `/gsd-validate-phase <N>` natural unit. Lets each plan close one VALIDATION.md atomically with its own tests, commit, and CI green check. Planner confirms during plan-phase.
- **Tests run green in CI is the hard gate** — every roadmap success criterion ends "tests run green." A Phase 24 plan is not done until `swift test` passes locally AND `build-check.yml` is green on the PR.

</specifics>

<deferred>
## Deferred Ideas

- **Manual-Only entries / integration tests for force-quit / SIGKILL / runtime entitlement scenarios** — D-03 chose lenient WITHDRAWN. If a future production incident uncovers a regression in STAB-01 (crash recovery), SECR-09 (atomic write under kill), or STAB-04 (mic permission denial), a follow-up phase could add an integration-test scaffold (subprocess spawn, SIGKILL after N ms). Out of Phase 24 scope.
- **Phase 4 (Mic Button), Phase 7 (Notion), Phase 9 (Verification Sweep) Nyquist sweep** — those phase directories live only in git history per the v1.0 audit. Restoring + auditing them is a separate phase if it matters; the audit framed the v1.0 sweep as "opt-in hygiene" and did not call out 4/7/9 as gaps.
- **Move restored v1.0 phase directories from `.planning/phases/` to `.planning/milestones/v1.0-phases/`** — the restoration commit (23f3949) explicitly says "After the validation sweep completes, these directories will be moved into milestones/v1.0-phases/ where they should have lived all along." That cleanup is post-Phase 24 housekeeping; doesn't affect Phase 24's deliverables but should run before Phase 25 starts to avoid two parallel "where do v1.0 artifacts live" conventions.
- **Phase 23-VALIDATION.md own approval** — Phase 23 just completed; its own VALIDATION.md frontmatter still reads `status: draft`. If Phase 23 needs its own retroactive Nyquist approval, that's either a Phase 23 follow-up or part of the v1.3 milestone audit. Not Phase 24's job — Phase 24 is scoped to v1.0.
- **Snapshot tests for v1.0 surfaces beyond the Phase 23 5-surface roster** — Phase 23 deferred TranscriptView, NotionTagSheet, OnboardingView, DetailsPane, CaptureDock, LibraryEntryRow. Adding snapshot baselines for these is a future visual-regression phase, not Phase 24.
- **Backfilling `requirements-completed` frontmatter on v1.0 SUMMARY.md files** — v1.0 audit marked this "not worth the churn given the milestone is archived." Phase 24 does not add the frontmatter; new Phase 24 plan SUMMARY.md files DO carry it (PROCESS-01 from Phase 22 is already in effect).
- **Centralized `Phase24Fixtures.swift` shared helper** — only worth introducing if 3+ tests share fixture code. Planner decides during plan-phase. Captured here so it doesn't get force-introduced prematurely.
- **Cross-phase CI splitting** — single `build-check.yml` already runs the full suite. Splitting into per-phase test workflows (e.g., `--filter Phase01`) is unnecessary infrastructure for ~30 small tests.

</deferred>

---

*Phase: 24-nyquist-sweep-v1-0*
*Context gathered: 2026-05-05*
