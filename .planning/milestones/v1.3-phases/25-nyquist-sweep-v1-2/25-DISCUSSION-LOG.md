# Phase 25: Nyquist Sweep — v1.2 - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-06
**Phase:** 25-nyquist-sweep-v1-2
**Areas discussed:** Snapshot test integration, Untestable policy carry-forward, Titlebar bridge coverage, Plan splitting strategy

---

## Snapshot test integration

| Option | Description | Selected |
|--------|-------------|----------|
| Cite-only | Phase 25 stays unit/integration-only. Visual reqs are WITHDRAWN with `Source: 23-VALIDATION.md` (palette-correctness baselines) + cross-ref to `20-VERIFICATION.md` / `21-VERIFICATION.md` for live-toggle attestations. Cleanest scope, matches Phase 24 posture. Phase 26 still owns titlebar visual UAT. | ✓ |
| Cite + extend with override snapshots | Add ~3-5 new snapshot tests proving the override path works: SettingsView with `appearancePreference=.dark` while system=Light, ContentView same, etc. Adds new fixtures to `VisualRegressionTests.swift` or a sibling file. Tighter coverage; expands Phase 25 scope by ~1 wave of work. | |
| Strictly unit-only, ignore Phase 23 | Don't reference Phase 23 in Phase 25. Visual reqs are WITHDRAWN with generic 'visual UAT' reason. Cleanest separation but loses information — Phase 23's baselines are real evidence that the unified palette renders correctly per appearance. | |

**User's choice:** Cite-only (Recommended).
**Notes:** Drives D-01. The "cite + extend" option was tempting because Phase 23's baselines don't cover transition states (preference toggle re-render), but writing a parallel snapshot harness for transitions is its own project — out of Phase 25 scope. Strict-ignore was rejected to preserve audit-trail richness for future readers chasing WITHDRAWN rows.

---

## Untestable policy carry-forward

| Option | Description | Selected |
|--------|-------------|----------|
| Carry verbatim + split PARTIAL into two rows | WITHDRAWN rows cite `*-VERIFICATION.md` only (Phase 24 D-03 verbatim). For PARTIAL reqs (20.4, 21.2, 21.3): emit TWO rows — one TESTABLE row for the structural half (e.g., '21.2a: app-root call-site grep'), one WITHDRAWN row for the visual half (e.g., '21.2b: runtime override re-renders surfaces') with `Source: 21-VERIFICATION.md`. Stays atomic per req-half. | ✓ |
| Broaden cross-ref to include Phase 23 snapshots | WITHDRAWN rows cite BOTH `*-VERIFICATION.md` AND `23-VALIDATION.md` (specific snapshot baselines that prove the palette renders correctly per appearance). PARTIAL reqs handled the same way as option 1, but visual-half WITHDRAWN rows get the richer cross-ref. More information for a future reader, slightly more text per row. | |
| Carry verbatim + collapse PARTIAL into one TESTABLE row with a note | WITHDRAWN rows cite `*-VERIFICATION.md` only. PARTIAL reqs (20.4, 21.2, 21.3) become a single TESTABLE row covering the structural half, with a one-line trailing note like '¹ Visual portion attested in 21-VERIFICATION.md Row group A.' Tighter but conflates two different acceptance bars under one req ID. | |

**User's choice:** Carry verbatim + split PARTIAL into two rows (Recommended).
**Notes:** Drives D-02. Introduces an `a` / `b` suffix convention for PARTIAL req-IDs (e.g., `21.2a` testable, `21.2b` WITHDRAWN). Phase 24 had no PARTIAL reqs, so this is an additive amendment to Phase 24 D-03 rather than a redefinition. Broadening cross-refs was rejected to keep the policy crisp; collapsing was rejected because it conflates two acceptance bars under one ID and obscures the WITHDRAWN policy.

---

## Titlebar bridge coverage

| Option | Description | Selected |
|--------|-------------|----------|
| Cross-ref Phase 26 | Add a short 'Out of scope: post-fix titlebar bridge (CR-01)' section to 21-VALIDATION.md with a cross-ref to QA-06..09 in Phase 26's `26-UAT.md`. No test code added. Acknowledges the scope extension without bloating Phase 25. Auditor sees the pointer; future readers know the bridge has visual coverage in flight. | ✓ |
| Encode code-level audit as grep `@Test`s | Add 2-3 small `@Test` methods that re-run the grep-based audit Phase 21 re-verification did: assert `window.appearance =` is set in `applyChronicleTitlebar`, assert `NSColor.labelColor` is referenced (not hardcoded), assert `observeChronicleTitlebar` re-applies on settings changes. Encodes the audit as CI-runnable tests; catches code-level regressions even though it doesn't prove visual rendering. | |
| Defer entirely to Phase 26 | 21-VALIDATION.md covers only the original 6 SPEC reqs. No mention of the titlebar bridge at all — the bridge is a scope extension that Phase 26 audits in full. Strictest reading of 'Phase 25 backfills VALIDATION for 21-SPEC.md reqs'. Cleanest but loses the audit trail — a future reader of 21-VALIDATION.md won't know the bridge exists. | |

**User's choice:** Cross-ref Phase 26 (Recommended).
**Notes:** Drives D-03. The forward cross-ref to `26-UAT.md` will land before Phase 26 ships, so `21-VALIDATION.md` should annotate the path with "(produced when Phase 26 ships)" or similar. Option B was tempting but redundant with the `21-VERIFICATION.md` re-verification block; option C was rejected because it leaves an unexplained gap in `21-VALIDATION.md`.

---

## Plan splitting strategy

| Option | Description | Selected |
|--------|-------------|----------|
| 2 plans, one per VALIDATION.md | Mirror Phase 24 D-04. Plan 25-01 = Phase 21 (smaller, ~6-7 tests, AppearancePreference + AppSettings + grep gate). Plan 25-02 = Phase 20 (~4-5 tests, palette tokens + legacy block). Smallest-first execution. Each plan atomically closes one VALIDATION.md with its own tests + commit + CI green. | ✓ |
| 1 plan covering both | Single 25-01-PLAN.md covers ~11-12 tests + both VALIDATION.md flips. Less ceremony, single PR, single CI run. Loses per-phase atomicity — a CI failure could be in either palette plumbing or settings plumbing, harder to bisect. | |
| 3 plans split by concern | (1) AppearancePreference enum + AppSettings persistence tests, (2) Token palette + legacy block tests, (3) Grep-gate tests (Phase 20 + 21 grep tests in one place). Doesn't align with Phase 24's per-VALIDATION.md natural unit; would split a single VALIDATION.md's tests across multiple plans, breaking atomicity. | |

**User's choice:** 2 plans, one per VALIDATION.md (Recommended).
**Notes:** Drives D-04. Plan 25-01 = Phase 21 (smallest first), Plan 25-02 = Phase 20. Mirrors Phase 24 D-04's "one plan per VALIDATION.md" convention; preserves per-phase atomic close + clean PR-level audit trail.

---

## Claude's Discretion

- Test file naming and placement (extend `AppSettingsTests.swift` vs. spin up `AppearancePreferenceTests.swift`; new `DesignTokensAdaptivePaletteTests.swift` for palette tests; shared vs. per-phase `PreferredColorSchemeGrepGateTests.swift`).
- Grep test mechanics (`Bundle(for:).url(...)` vs. raw `FileManager.contents(atPath:)` vs. embedded fixture string) — `WorkflowSecretsTests.swift` is the canonical precedent.
- `@Suite(.serialized)` annotation per suite (UD-mutating tests must serialize; pure-function and source-grep do not).
- Color resolution test technique (NSColor bridging vs. SwiftUI environment trait) for REQ-20.2 token light/dark variant assertions.
- WITHDRAWN row formatting and PARTIAL `a`/`b` row layout (adjacent rows in same per-task table preferred).
- Plan ordering within Phase 25 (smallest-first 21 → 20 unless dependency analysis surfaces a constraint).
- Whether to update `.planning/codebase/TESTING.md` (bias: do NOT; Phase 23 already refreshed it).
- WITHDRAWN reason phrasing for REQ-20.5 / 20.6 / 20.4b (cross-ref both `20-01-SUMMARY.md` byte-equality proof AND `20-VERIFICATION.md` Row group D user attestation).
- Whether to add a small HUD-side test for `DictationWindowController.applyAppearance(_:)` (.system → nil, .light → .aqua, .dark → .darkAqua mapping). Captured in Deferred Ideas; planner picks at plan-phase.

## Deferred Ideas

- Phase 23-VALIDATION.md own approval (still `status: draft`; Phase 24 inherited the deferral, Phase 25 inherits it again).
- Snapshot tests for transition states (preference toggle re-render, system flip mid-session, titlebar bridge under appearance change).
- Snapshot baselines for v1.2 surfaces beyond Phase 23's 5-surface roster (NotionTagSheet, OnboardingView, CaptureDock, ControlBar, DetailsPane, LibrarySidebar).
- Backfilling `requirements-completed` frontmatter on v1.2 SUMMARY.md files (not worth churn; v1.2 archived).
- Manual-Only entries / integration tests for runtime-visual scenarios (lenient WITHDRAWN policy chosen; promote only on production incident).
- Encoding the post-fix titlebar bridge re-verification grep audit as `@Test`s (rejected as D-03 option B; revisit if bridge code is regressed by a future PR).
- Restructuring `PSTranscribeTests/` into per-phase subdirectories vs. flattening Phase 18 / 18.1 subdirs (tooling cleanup, not Phase 25's job).
- HUD-side runtime override coverage via `DictationWindowController.applyAppearance(_:)` unit-test (small extra `@Test`; planner picks).
