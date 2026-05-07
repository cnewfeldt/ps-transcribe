# Phase 25: Nyquist Sweep — v1.2 - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Backfill `*-VALIDATION.md` for v1.2 phases 20 (Chronicle adaptive light/dark token palette) and 21 (User-Controlled `AppearancePreference`) — closing `NYQUIST-06` and `NYQUIST-07` and finishing the v1.2 half of the `NYQUIST-FUT-01` sweep that Phase 24 opened. Each new VALIDATION.md ships at `status: approved` / `nyquist_compliant: true` with **real Swift Testing assertions** that run green in CI (`swift test` inside `build-check.yml` on macos-26).

**In scope:**
- Create `20-VALIDATION.md` from scratch at `.planning/milestones/v1.2-phases/20-dark-mode-parity/` (no draft exists; Phase 24 worked from drafts, Phase 25 does not)
- Create `21-VALIDATION.md` from scratch at `.planning/milestones/v1.2-phases/21-appearance-override/`
- Per-task verification map covering: Phase 20 REQ-20.1..20.6, Phase 21 SPEC reqs 21.1..21.6 (the 6 originally locked in `21-SPEC.md`)
- New flat test files at `PSTranscribe/Tests/PSTranscribeTests/` (or new `@Test` methods inside existing files like `AppSettingsTests.swift` where the behavior cluster already exists), named by behavior (per Phase 24 D-04)
- ~11–12 `@Test` methods total across both VALIDATION.md files (smaller than Phase 24's ~30)
- Each VALIDATION.md gets `last_audited: 2026-05-XX` frontmatter stamp
- Tests run green via `swift test` locally and in `build-check.yml` CI

**Out of scope:**
- Phase 23-VALIDATION.md own approval — Phase 23 (Visual Regression Infra) just shipped; its own VALIDATION.md frontmatter still reads `status: draft`. If Phase 23 needs its own retroactive Nyquist approval, that's either a Phase 23 follow-up or part of the v1.3 milestone audit. Not Phase 25's job.
- Phase 21 post-fix titlebar bridge unit-tests (`applyChronicleTitlebar` / `observeChronicleTitlebar` from `197043b..ce79965`) — covered by D-03 below; cross-ref'd to Phase 26, no test code added.
- New snapshot tests — Phase 25 cites Phase 23's existing 15 baselines (per D-01) but adds none.
- Manual UAT execution — Phase 26 (`QA-FUT-01`) owns QA-01..09 including the four titlebar visual UAT scenarios (QA-06..09). Phase 25 produces audit contracts, not run UAT.
- WCAG / accessibility contrast verification — separate accessibility scope, Phase 20 SPEC explicitly excluded it.
- Re-verification of any v1.0 phase already closed by Phase 24 — Phase 25 is scoped to v1.2.
- Modifications to `VisualRegressionTests.swift` or Phase 23's `__Snapshots__` — read-only cross-reference.
- Adding new dependencies to `Package.swift` — reuses `swift-snapshot-testing` (Phase 23) only via cross-ref, no import needed in Phase 25 test files.

</domain>

<decisions>
## Implementation Decisions

### Snapshot infrastructure use

- **D-01:** **Cite-only.** Phase 25 stays unit/integration-only. The visual subset of REQs (Phase 20 REQ-20.5, REQ-20.6, plus the visual half of REQ-20.4; Phase 21 REQ-21.5, plus the visual halves of REQ-21.2 and REQ-21.3) becomes WITHDRAWN with `Source:` lines pointing at `.planning/milestones/v1.2-phases/20-dark-mode-parity/20-VERIFICATION.md` (Row groups A–F user attestations) or `.planning/milestones/v1.2-phases/21-appearance-override/21-VERIFICATION.md` (Manual UAT Scenarios A–H). Phase 23's 15 snapshot baselines (`PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/`) are real evidence that the unified palette renders correctly per appearance, but they belong to `23-VALIDATION.md`'s closure, not Phase 25's. Adding new snapshot tests (option B) was rejected because the structural prereq Phase 23 covers does not extend cleanly to "preference toggle re-renders without app restart" (a runtime state-change concern, not a static render); writing a parallel snapshot harness for transitions is its own project. Strict ignore (option C) was rejected because dropping the cross-ref to existing baselines wastes information that helps a future auditor trust the WITHDRAWN rows.

### Untestable / PARTIAL policy

- **D-02:** **Phase 24 D-03 carries forward verbatim** — WITHDRAWN rows cite `*-VERIFICATION.md` only (no broadened cross-ref to Phase 23). For PARTIAL reqs (`REQ-20.4`, `REQ-21.2`, `REQ-21.3`) — where the structural contract is unit-testable but the runtime visual outcome is not — the row gets **split into two**: one TESTABLE row for the structural half (e.g., `21.2a: app-root call-site grep`) and one WITHDRAWN row for the visual half (e.g., `21.2b: runtime override re-renders surfaces`). Both halves keep the original REQ-ID prefix with an `a` / `b` suffix so the SPEC.md acceptance bar is fully traceable. Collapsing PARTIAL into one TESTABLE row with a footnote (option C) was rejected — conflates two acceptance bars under one ID and obscures the WITHDRAWN policy. Broadening cross-refs (option B) was rejected to keep the policy crisp; auditors who want Phase 23 evidence can chase it through the Phase 26 cross-ref or the milestone audit.

### Phase 21 post-fix titlebar bridge

- **D-03:** **Cross-ref Phase 26 in `21-VALIDATION.md`, no test code added.** A short "Out of scope: post-fix titlebar bridge (CR-01)" section sits in `21-VALIDATION.md` (after the per-task verification map) with a one-paragraph note explaining that `applyChronicleTitlebar` / `observeChronicleTitlebar` are scope extensions added in `197043b..ce79965` after `21-SPEC.md` was locked, that they are code-verified per `21-VERIFICATION.md`'s re-verification block, and that visual UAT lives in Phase 26's `26-UAT.md` (QA-06..09). Encoding the audit as grep-based `@Test`s (option B) was rejected — the re-verification already runs that grep audit, and re-encoding it as a CI test buys little: the bridge code is tightly tied to AppKit invariants (`NSColor.labelColor` dynamic, `window.appearance` set, `bestMatch(from:)` gate) that don't regress silently. Defer entirely (option C) was rejected — losing the audit trail makes `21-VALIDATION.md` look incomplete to a future reader who knows the bridge exists.

### Plan splitting

- **D-04:** **Two plans, smallest-first.** Plan `25-01` closes `21-VALIDATION.md` (~6–7 tests: AppearancePreference enum cases + UserDefaults round-trip + missing-key fallback + relaxed D-06 grep gate location/source + app-root call-site grep + SettingsView Picker existence grep). Plan `25-02` closes `20-VALIDATION.md` (~4–5 tests: zero-`preferredColorScheme` grep gate + Chronicle token light/dark variant assertion + legacy `extension Color` block deletion grep + per-view hex-literal grep). Mirrors Phase 24 D-04 — one plan per VALIDATION.md, each plan atomically closes one file with its own tests + commit + CI green check. Single-plan bundling (option B) was rejected — a CI failure could be in palette plumbing or settings plumbing, harder to bisect, and conflates two unrelated code surfaces. Three-plan concern split (option C) was rejected — would split a single VALIDATION.md's tests across multiple plans, breaking the per-VALIDATION.md atomicity convention.

### Claude's Discretion

- **Test file naming and placement** — D-04 of Phase 24 locked the convention (flat in `PSTranscribeTests/`, named by behavior, not by phase). Planner picks final filenames within that convention. Strong candidates for Phase 25:
  - **Phase 21 tests:** extend `AppSettingsTests.swift` with the new `AppearancePreference` cases (matches the file's existing AppSettings-property test pattern) rather than spinning up a new `AppearancePreferenceTests.swift`. Add a separate `PreferredColorSchemeGrepGateTests.swift` (or similar) for the source-greps that span `PSTranscribeApp.swift` + `SettingsView.swift` since those are file-spanning grep tests, not AppSettings tests.
  - **Phase 20 tests:** new `DesignTokensAdaptivePaletteTests.swift` for token light/dark variant assertions; reuse the same `PreferredColorSchemeGrepGateTests.swift` (or a sibling) for the zero-hits grep gate. Planner decides whether the grep gate tests live in one shared file or split per phase.
- **Grep test mechanics** — Whether to read source files via `Bundle(for:).url(forResource:withExtension:subdirectory:)` (test-bundle resource), via `FileManager.default.contents(atPath:)` against a path string, or via embedding the source as a test-time string fixture. Existing `WorkflowSecretsTests.swift` (Phase 24) is the canonical precedent — planner reads it and copies the pattern.
- **`@Suite(.serialized)` annotation** — Phase 24 D-04 locked: `.serialized` for any test that mutates UserDefaults, `NSApp.appearance`, or shared FS paths; default parallelism for pure-function and source-grep tests. Planner annotates per suite. The new `AppearancePreference` UD round-trip tests must serialize (they touch `UserDefaults.standard`).
- **Color resolution test technique** — Asserting that a `Color(light:dark:)` token resolves differently across `colorScheme` traits requires either NSColor bridging (`NSColor(SwiftUI.Color(...)).usingColorSpace(.sRGB)?.redComponent` etc.) or a SwiftUI environment trait test (rendering into a host view with `.environment(\.colorScheme, .light)` and reading the tokenized color back). Both work; planner picks. Bias: NSColor bridging is simpler for unit tests and matches the existing `Color` extension pattern in `DesignTokens.swift`.
- **WITHDRAWN row formatting** — Phase 24 D-04 Claude's Discretion: row must include `Test Type: WITHDRAWN`, requirement ID, one-line reason, and a pointer (`Source: 20-VERIFICATION.md` or `21-VERIFICATION.md`). Planner picks exact column shape; should match Phase 24's `01/02/03/08/10-VALIDATION.md` shape verbatim for sweep consistency.
- **PARTIAL row labeling** — D-02 splits PARTIAL reqs into `Xa` / `Xb` halves. Planner picks whether the half-IDs live in two adjacent rows in the same per-task table (preferred — keeps the SPEC linkage visible) or in separate Testable / WITHDRAWN sections.
- **Plan ordering within Phase 25** — D-04 says smallest-first: 21 → 20. Planner can override if dependency analysis surfaces a hidden constraint, but no such constraint is expected (the two VALIDATION.md files are fully independent — no shared test files, no shared code surface).
- **Whether to update `.planning/codebase/TESTING.md`** — Phase 24 noted "may add a short 'Retroactive Nyquist tests' section but does not have to." Same posture for Phase 25. Bias: do NOT update; Phase 24 already established the precedent and TESTING.md was last refreshed for Phase 23.
- **WITHDRAWN reasons for Phase 20 REQ-20.5 / REQ-20.6 / REQ-20.4b** — `20-VERIFICATION.md` waived screenshot capture in favor of source-level byte-equality (light) and visual attestation (dark). The WITHDRAWN reason for 20.5 should reference both the byte-equality proof in `20-01-SUMMARY.md` / `20-02-SUMMARY.md` AND the user-attestation in `20-VERIFICATION.md` Row group D. Planner picks the one-line phrasing.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap, requirements, milestone state

- `.planning/ROADMAP.md` §"Phase 25: Nyquist Sweep — v1.2" — phase goal, success criteria 1–2, optional Phase 23 snapshot dep note.
- `.planning/REQUIREMENTS.md` §"Nyquist Validation Sweep (`NYQUIST-FUT-01`)" — `NYQUIST-06`, `NYQUIST-07` requirement IDs that this phase delivers.
- `.planning/PROJECT.md` — milestone v1.3 context; v1.2 was shipped 2026-05-01 as macOS app v2.2.0.
- `.planning/STATE.md` — v1.3 status (`ready_to_plan`).

### Phase 24 sweep playbook (Phase 25 inherits this wholesale)

- `.planning/phases/24-nyquist-sweep-v1-0/24-CONTEXT.md` — Phase 24 D-02 (one `@Test` per testable req), D-03 (lenient WITHDRAWN policy, no Manual-Only rows), D-04 (flat behavior-named test files; one plan per VALIDATION.md). Phase 25 D-01..D-04 are amendments / extensions of these — D-02 here cross-refs Phase 24 D-03 explicitly.
- `.planning/phases/24-nyquist-sweep-v1-0/24-RESEARCH.md` — Swift Testing infrastructure baseline (framework, target, runtime, sampling rate). Phase 25 inherits the same infrastructure.
- `.planning/phases/24-nyquist-sweep-v1-0/24-VALIDATION.md` — Phase 24's own validation contract; not a precedent that Phase 25 needs to update, but useful as an example of the per-task verification map shape.
- Existing v1.0 VALIDATION.md files at `.planning/milestones/v1.0-phases/{01-rebrand,02-security-stability,03-session-management-recording-naming,08-code-defect-fixes,10-final-defect-fixes-obsidian-deeplink}/{01,02,03,08,10}-VALIDATION.md` — closed by Phase 24 with the row formatting Phase 25 should mirror (Test Type column, WITHDRAWN rows with `Source:`).

### Phase 23 snapshot infrastructure (cited per D-01, NOT modified)

- `.planning/phases/23-visual-regression-infra/23-CONTEXT.md` — Phase 23 D-01 (Swift Testing exclusively), D-06 (`swift test` step on macos-26). Phase 25 inherits these.
- `.planning/phases/23-visual-regression-infra/23-VALIDATION.md` — `status: draft` at time of writing; cited by D-01 as the "real evidence the unified palette renders correctly per appearance" but NOT updated in Phase 25 (deferred — see Deferred Ideas).
- `PSTranscribe/Tests/PSTranscribeTests/VisualRegressionTests.swift` — Phase 23's snapshot harness; read-only reference.
- `PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/` — 15 baselines (5 surfaces × Light/Dark/System). Read-only reference.
- `PSTranscribe/Tests/PSTranscribeTests/SnapshotFixtures.swift` — Phase 23 fixture helper; read-only reference.

### Phase 20 input (target of Plan 25-02)

- `.planning/milestones/v1.2-phases/20-dark-mode-parity/20-SPEC.md` — REQ-20.1..20.6 + Boundaries + Constraints + Acceptance Criteria. Phase 25 must NOT modify; the 6 reqs are locked.
- `.planning/milestones/v1.2-phases/20-dark-mode-parity/20-CONTEXT.md` — Phase 20 implementation decisions (token palette format, surface roster, Chronicle warm-dark identity).
- `.planning/milestones/v1.2-phases/20-dark-mode-parity/20-VERIFICATION.md` — final-gate sign-off (PASS, 6/6); WITHDRAWN rows in `20-VALIDATION.md` cross-ref this file via `Source:` lines.
- `.planning/milestones/v1.2-phases/20-dark-mode-parity/20-VERIFIED.md` — REQ-by-REQ evidence with grep transcripts (REQ-20.1 zero-hits grep, REQ-20.2 token count). Useful precedent for the test assertions Plan 25-02 writes.
- `.planning/milestones/v1.2-phases/20-dark-mode-parity/20-01-SUMMARY.md` / `20-02-SUMMARY.md` — light-side hex byte-equality proof referenced by REQ-20.5's WITHDRAWN row.

### Phase 21 input (target of Plan 25-01)

- `.planning/milestones/v1.2-phases/21-appearance-override/21-SPEC.md` — 6 SPEC reqs locked at draft time + Acceptance Criteria. Phase 25 must NOT modify.
- `.planning/milestones/v1.2-phases/21-appearance-override/21-CONTEXT.md` — Phase 21 D-05 (three Scene roots receive `.preferredColorScheme`), D-06 (relaxed grep gate: location + source, not count), D-07 (`NSAppearance(named:)` for HUD), D-08 (enum lives in `AppSettings.swift`), D-09 (UserDefaults read with `?? .system` fallback).
- `.planning/milestones/v1.2-phases/21-appearance-override/21-VERIFICATION.md` — original 11/11 PASS + post-fix re-verification block (CR-01 fix `197043b..ce79965`). The "Re-verification scope" note in the frontmatter is the source for D-03's titlebar bridge cross-ref.
- `.planning/milestones/v1.2-phases/21-appearance-override/21-HUMAN-UAT.md` — final user-attestation 2026-05-01 confirming titlebar visual outcomes; cross-ref'd in `21-VALIDATION.md` D-03 out-of-scope section.
- `.planning/milestones/v1.2-phases/21-appearance-override/21-REVIEW.md` — code review report that surfaced CR-01.

### Phase 26 forward reference (cross-ref'd by D-03)

- `.planning/ROADMAP.md` §"Phase 26: QA Sweep + Visual UAT" — defines `QA-06`, `QA-07`, `QA-08`, `QA-09` (titlebar Light / Dark / System / unfocused-window scenarios). `21-VALIDATION.md`'s out-of-scope section names these IDs and the future `26-UAT.md` artifact.
- `.planning/REQUIREMENTS.md` §"QA Checklist (`QA-FUT-01`)" — same IDs; defines the human attestation contract that Phase 26 will execute.

### Application code under audit (paths to verify against, not modify)

- `PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift` — `AppearancePreference` enum (lines 14–30), `appearancePreference` property + UD didSet (lines 119–121), init-side decode + `?? .system` fallback (lines 196–198). Source for REQ-21.1 + REQ-21.6 tests.
- `PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift` — three `.preferredColorScheme(settings.appearancePreference.colorScheme)` call-sites at lines 173 / 195 / 207 (per CONTEXT.md D-05); `applyChronicleTitlebar` / `observeChronicleTitlebar` post-fix code (lines ~64, 275–290, 340–…) cited by D-03 but NOT tested in Phase 25. Source for REQ-21.2a + REQ-21.4 grep tests.
- `PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift` — `Section("Appearance")` + `Picker("Appearance", selection: $settings.appearancePreference)` (lines 30–31). Source for REQ-21.3a grep test.
- `PSTranscribe/Sources/PSTranscribe/App/DictationWindowController.swift` — `applyAppearance(_:)` mapping `AppearancePreference` to `panel.appearance` via `NSAppearance(named:)` (lines 108–116). Optional source for an extra REQ-21.2a-related test if the planner wants HUD-side coverage.
- `PSTranscribe/Sources/PSTranscribe/Design/DesignTokens.swift` — 17 Chronicle tokens via `Color(light:dark:)` (extension at lines 31–125), 11 legacy tokens (extension at lines 178–230). Source for REQ-20.2 + REQ-20.3 tests.
- `PSTranscribe/Sources/PSTranscribe/Views/TranscriptView.swift` — must NOT contain `extension Color` block at lines 207–228 (Phase 20 deleted it). Source for REQ-20.3 deletion-grep test.

### Test infrastructure (DO NOT modify in Phase 25)

- `PSTranscribe/Package.swift` — existing `.testTarget(name: "PSTranscribeTests", ...)` declaration; no new dependencies.
- `PSTranscribe/Tests/PSTranscribeTests/` — destination for new flat test files (per Phase 24 D-04). Existing convention: Swift Testing `@Suite` + `@Test`, `import Testing`, `@testable import PSTranscribe`.
- `PSTranscribe/Tests/PSTranscribeTests/AppSettingsTests.swift` — existing AppSettings test patterns; Plan 25-01 likely extends this file with `AppearancePreference` cases rather than spinning up a separate `AppearancePreferenceTests.swift` (Claude's Discretion).
- `PSTranscribe/Tests/PSTranscribeTests/WorkflowSecretsTests.swift` (Phase 24) — canonical precedent for source-grep tests that read `*.swift` files at test-time. Plan 25-01 + 25-02 reuse the pattern.
- `PSTranscribe/Tests/PSTranscribeTests/DictationLoggerTests.swift` — canonical `tempDir()` + `defer` cleanup pattern; not needed for Phase 25 (no FS-mutation tests expected) but available.
- `.github/workflows/build-check.yml` — `swift test` step (Phase 23 D-06). Phase 25 inherits verbatim; no workflow changes.

### Codebase intelligence

- `.planning/codebase/TESTING.md` — Swift Testing conventions; Phase 23 refresh. Phase 25 does NOT update this (Claude's Discretion in D-04).
- `.planning/codebase/STACK.md` — Swift 6.2, macOS 26, SwiftPM.
- `.planning/codebase/CONVENTIONS.md` — `@MainActor` isolation; `@Suite(.serialized)` precedent.

### Sweep-pattern reference

- `$HOME/.claude/get-shit-done/workflows/validate-phase.md` — workflow for the per-phase Nyquist audit. Phase 25's two plans operationalize this skill across 2 phases. State A (audit existing) + State B (create from scratch) both apply — Phase 20 + 21 each have a SPEC.md but no VALIDATION.md.
- `$HOME/.claude/agents/gsd-nyquist-auditor.md` — agent invoked by `/gsd-validate-phase`. Planner decides whether to spawn it per plan or write the tests inline; Phase 24 chose inline.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **Existing Swift Testing test target** at `PSTranscribe/Tests/PSTranscribeTests/` with ~30+ test files (post-Phase 24) including `WorkflowSecretsTests.swift` (the canonical source-grep precedent), `AppSettingsTests.swift` (the canonical AppSettings property test home), `MidnightOffsetTests.swift` (small pure-function test pattern), and Phase 23's `VisualRegressionTests.swift` + `__Snapshots__/` (referenced by D-01, not extended).
- **`AppSettingsTests.swift` extension pattern** — existing `@Test` methods inside `@Suite("AppSettings")` exercise UserDefaults round-trip for boolean and string properties. Plan 25-01 extends this with `AppearancePreference` rawValue round-trip + missing-key fallback. No new file required for that subset.
- **`WorkflowSecretsTests.swift` source-grep precedent** — reads `.github/workflows/release-dmg.yml` from disk at test-time and asserts presence of specific strings. Same pattern transposes to reading `PSTranscribeApp.swift` / `SettingsView.swift` / `TranscriptView.swift` / `DesignTokens.swift` and asserting grep-style invariants. Phase 25 grep tests follow this shape.
- **Phase 24 `RebrandInfoPlistTests.swift`** — alternative source-grep precedent that reads `Info.plist` via `Bundle.main`. Less applicable here because Phase 25's grep targets are Swift source files, not bundle resources.
- **NSColor bridging from `SwiftUI.Color`** — `NSColor(Color.paper)` works at test-time for resolving a `Color(light:dark:)` token to concrete RGB components per appearance. Pattern is not in the existing test suite yet but is a stable AppKit API; planner picks whether to use it or the SwiftUI environment-trait approach.

### Established Patterns

- **Swift Testing only** — no XCTest in the test target (Phase 16+ established, Phase 23 reaffirmed in D-01, Phase 24 D-04 reaffirmed). All Phase 25 tests use `import Testing` + `@Suite` + `@Test`.
- **`@Suite(.serialized)` for shared-state mutation** — UserDefaults, `NSApp.appearance`, shared FS paths. Phase 25 tests that mutate `UserDefaults.standard` (REQ-21.1 round-trip, REQ-21.6 missing-key fallback) MUST serialize. Pure-function and source-grep tests do not.
- **`@MainActor` for view-touching tests** — `AppSettings` is `@MainActor`-isolated; tests that instantiate it inherit the requirement. Source-grep tests do not need `@MainActor`.
- **`#expect` for non-blocking, `#require` for short-circuit** — existing convention.
- **Per-task verification map row format** — Phase 24's `01/02/03/08/10-VALIDATION.md` files lock the column shape: `Requirement`, `Test Type`, `Test File`, `Test Method`, `Source` (for WITHDRAWN). Plan 25-01 + 25-02 mirror this verbatim.
- **VALIDATION.md frontmatter contract** — `phase`, `slug`, `status: approved`, `nyquist_compliant: true`, `wave_0_complete: true`, `last_audited: 2026-05-XX`. Phase 25 produces 2 of these.

### Integration Points

- **`@testable import PSTranscribe`** — gives Phase 25 tests access to `AppearancePreference`, `AppSettings`, internal token definitions, and the `applyAppearance(_:)` helper on `DictationWindowController` if the planner wants HUD-side assertions.
- **CI failure surface** — `swift test` in `build-check.yml` fails the PR check on red. Phase 25 tests inherit that gate verbatim; no new workflow changes.
- **Source-grep tests as guardrails** — REQ-20.1, REQ-20.3, REQ-20.4a, REQ-21.2a, REQ-21.3a, REQ-21.4 are all source-grep guardrails. They turn the milestone's once-off grep audit (run during VERIFICATION) into a CI-runnable invariant. If a future PR re-introduces a `.preferredColorScheme(.light)` outside `#Preview` or re-introduces an `extension Color` block in `TranscriptView.swift`, the relevant `@Test` fails on PR check.
- **Cross-phase reference in `21-VALIDATION.md`** — D-03 inserts a forward pointer to Phase 26's `26-UAT.md`. That file does not exist yet (Phase 26 is pending). Format the cross-ref as a relative-path reference with a note like "(produced when Phase 26 ships)" so a reader who lands on `21-VALIDATION.md` before Phase 26 starts isn't confused.

</code_context>

<specifics>
## Specific Ideas

- **Phase 25 inherits Phase 24's playbook with two amendments.** D-02 splits PARTIAL reqs into `a`/`b` rows (Phase 24 had no PARTIAL reqs because v1.0 reqs cleaved on a different axis: pure-function vs runtime). D-03 adds a forward cross-ref to Phase 26 (Phase 24 had no cross-phase scope extensions because v1.0 phases were already closed). Both amendments are additive — they don't change Phase 24's canonical decisions; they extend them for Phase 25's specific shape.
- **Cite-only is the right snapshot posture.** D-01 keeps Phase 25 a pure unit/integration sweep. The reasoning: snapshot tests prove static palette correctness (which Phase 23 already certifies). They cannot prove runtime preference-toggle re-rendering (that's the visual half of REQ-20.4 / 21.2 / 21.3 / 21.5). Writing a parallel snapshot harness for transitions would be a Phase 23 extension, not a Phase 25 task. The existing `*-VERIFICATION.md` user attestations are the right `Source:` for those WITHDRAWN rows.
- **PARTIAL splitting preserves SPEC traceability.** Phase 20 SPEC and Phase 21 SPEC both phrase reqs as compound contracts ("the call-site exists AND it overrides at runtime"). The compound shape is fine for SPEC.md but doesn't survive Nyquist's "automated or WITHDRAWN, no Manual-Only" rule. Splitting into `21.2a` (testable structural half) and `21.2b` (WITHDRAWN visual half) preserves the SPEC link while honoring the policy. The `a`/`b` suffix convention is a Phase 25 introduction; future phases can pick it up if the same shape recurs.
- **Titlebar bridge is genuinely Phase 26's job, not Phase 25's.** The bridge code is a scope extension that landed AFTER `21-SPEC.md` was locked. `21-VERIFICATION.md` re-verification block already encodes the code-level audit (window.appearance set, NSColor.labelColor dynamic, observeChronicleTitlebar wired). Visual UAT is the genuine missing piece, and Phase 26 owns it via QA-06..09. Encoding the code-level audit as `@Test`s in Phase 25 (option B) would duplicate work without buying coverage; deferring entirely (option C) would leave a hole in `21-VALIDATION.md`'s narrative. The cross-ref split is the cleanest fit.
- **Plan ordering: 21 → 20 (smallest-first).** Plan 25-01 (Phase 21, ~6–7 tests) lands first because the AppSettings UD round-trip test is the smallest concrete unit and the grep gate is structural. Plan 25-02 (Phase 20, ~4–5 tests but fan-out across 4 source files) lands second. Same posture as Phase 24 D-04's "smallest first" suggestion.
- **Tests run green in CI is the hard gate** — every roadmap success criterion ends "tests run green." A Phase 25 plan is not done until `swift test` passes locally AND `build-check.yml` is green on the PR. Same hard gate as Phase 24.

</specifics>

<deferred>
## Deferred Ideas

- **Phase 23-VALIDATION.md own approval** — Still `status: draft` at time of writing. Phase 24's CONTEXT.md flagged the same; Phase 25 inherits the deferral. If Phase 23 needs its own retroactive Nyquist approval (e.g., to certify the snapshot-testing test target itself runs green and the baselines lock the right 15 surfaces), that's either a Phase 23 follow-up or part of the v1.3 milestone audit. Out of Phase 25 scope.
- **Snapshot tests for transition states** (preference toggle re-render, system appearance flip mid-session, titlebar bridge across light/dark/system) — Phase 23 covers static renders only. A future visual-regression phase could add a transition-state harness; Phase 25 does not. Captured here so a planner who reads D-01 understands what was deliberately not built.
- **Snapshot baselines for v1.2 surfaces beyond Phase 23's roster** — Phase 23 covers ContentView, LibraryView, SettingsView, RecordingView, DictationHUD. NotionTagSheet, OnboardingView, CaptureDock, ControlBar, DetailsPane, LibrarySidebar are not snapshot-covered. Adding baselines for these is a future visual-regression extension, not Phase 25's job.
- **Backfilling `requirements-completed` frontmatter on v1.2 SUMMARY.md files** — same posture as Phase 24: not worth the churn given v1.2 is shipped + archived. New Phase 25 plan SUMMARY.md files DO carry the field (PROCESS-01 from Phase 22 is in effect).
- **Manual-Only entries / integration tests for runtime-visual scenarios** — D-02 (carrying forward Phase 24 D-03) chose lenient WITHDRAWN. If a future production incident uncovers a regression in the runtime-visual subset (preference toggle, titlebar bridge under appearance flip), a follow-up phase could add an integration-test scaffold (subprocess spawn + NSWindow inspection, or AppKit-level UI test target). Out of Phase 25 scope.
- **Encoding the post-fix titlebar bridge re-verification grep audit as `@Test`s** — Option B from Area 3, rejected per D-03. If the bridge code is touched by a future PR (e.g., someone adds another hardcoded color), the rejection rationale ("re-verification already runs that grep audit") would weaken; consider promoting to TESTABLE in a future phase.
- **Restructuring `PSTranscribeTests/` into per-phase subdirectories** — Phase 18 / 18.1 already use that convention; Phase 24 D-04 chose flat for the v1.0 sweep on the basis that "tests cover surviving product behavior, not original code paths." Phase 25 inherits the flat convention. A future tooling cleanup could unify the layout (flatten Phase 18 / 18.1 subdirs OR re-bucket Phase 24 + 25 tests into per-phase subdirs); not Phase 25's job.
- **HUD-side runtime override coverage** — `DictationWindowController.applyAppearance(_:)` (lines 108–116) maps `AppearancePreference` to `panel.appearance` via `NSAppearance(named:)`. The mapping is deterministic (.system → nil, .light → .aqua, .dark → .darkAqua) and could be unit-tested with a real or mock NSPanel. Plan 25-01 picks whether to include this; if included, it's a small extra `@Test`. Captured here as Claude's Discretion in D-decisions, but worth flagging at the planner stage.

</deferred>

---

*Phase: 25-nyquist-sweep-v1-2*
*Context gathered: 2026-05-06*
