# Roadmap

## Shipped Milestones

- **v1.0 — PS Transcribe** (2026-04-02 → 2026-04-14): Full rebrand from Tome, security/stability hardening, session library + recording naming, three-state mic button + model onboarding, Notion integration, Obsidian deep-link, defect cleanup. 8 active phases, 45 requirements, 28 plans. Archived: [`milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md) · Requirements: [`milestones/v1.0-REQUIREMENTS.md`](milestones/v1.0-REQUIREMENTS.md) · Tag: `v1.0`.
- **v1.1 — Marketing Website** (2026-04-21 → 2026-04-25): Next.js + Vercel scaffold, Chronicle design system port, landing page, MDX docs section (6 pages). Phase 15 (Changelog) reverted — public release notes out of scope. 4 phases, 22 requirements, 16 plans. Production: `ps-transcribe-web.vercel.app`. Archived: [`milestones/v1.1-ROADMAP.md`](milestones/v1.1-ROADMAP.md) · Requirements: [`milestones/v1.1-REQUIREMENTS.md`](milestones/v1.1-REQUIREMENTS.md) · Tag: `v1.1`.
- **v1.2 — Standalone Dictation + Model Auto-Update + Dark Mode Parity** (2026-04-27 → 2026-05-01): Hotkey-triggered dictation with floating HUD + clipboard write + Local File output, FluidAudio model auto-update with manifest-based staging download, Chronicle adaptive light/dark token palette, three-way `AppearancePreference` (System/Light/Dark) override. Phase 18.1 inserted to refactor save destinations into top-level shared layer. Phase 19 removed from scope (QA checklist deferred to `QA-FUT-01`). 6 executed phases, 32 plans, ~33 requirements. Released as v2.2.0 macOS app. Archived: [`milestones/v1.2-ROADMAP.md`](milestones/v1.2-ROADMAP.md) · Requirements: [`milestones/v1.2-REQUIREMENTS.md`](milestones/v1.2-REQUIREMENTS.md) · Audit: [`milestones/v1.2-MILESTONE-AUDIT.md`](milestones/v1.2-MILESTONE-AUDIT.md) · Tag: `v1.2`.

## Current Milestone — v1.3 Polish & Validation

**Goal:** Close deferred backlog from v1.0-1.2 — complete the Phase 19 "Looks Done But Isn't" QA checklist, backfill Nyquist validation across 7 phases (v1.0 1/2/3/8/10 + v1.2 20/21), and standardize SUMMARY.md frontmatter + visual regression infra.

**Phases:** Continue numbering from v1.2 → v1.3 starts at Phase 22. **5 phases · 25 requirements · all mapped.**

### Progress

| # | Phase | Status |
|---|-------|--------|
| 22 | Process & Frontmatter Standard | [x] Complete 2026-05-02 |
| 23 | Visual Regression Infra | [x] Complete 2026-05-04 |
| 24 | Nyquist Sweep — v1.0 | [x] Complete 2026-05-05 |
| 25 | Nyquist Sweep — v1.2 | [ ] Pending |
| 26 | QA Sweep + Visual UAT | [ ] Pending |

### Phase 22: Process & Frontmatter Standard

**Goal:** Add `requirements-completed` field (canonical hyphen form per Phase 22 D-01) to the SUMMARY.md template + generation flow + CI lint, so v1.3's own SUMMARY.md files (and every future milestone's) carry mechanical requirement traceability.

**Requirements:** PROCESS-01, PROCESS-02, PROCESS-03

**Success criteria:**

1. SUMMARY.md template (`$HOME/.claude/get-shit-done/templates/...`) includes `requirements-completed` field with documented schema
2. SUMMARY.md generation flow (gsd-doc-writer agent + manual workflows) populates the field automatically by parsing PLAN.md requirement references
3. CI or pre-commit lint check fails when SUMMARY.md is committed without `requirements-completed`
4. v1.3 phases 23-27 produce SUMMARY.md files that include `requirements-completed`

**Why first:** Every subsequent v1.3 phase produces a SUMMARY.md. Landing the template change first means this milestone's own artifacts use the new format — dogfooding from day one.

**Plans:** 6 plans

Plans:
**Wave 1**
- [x] 22-01-PLAN.md — Reword REQUIREMENTS.md PROCESS-01..03 from underscore to canonical hyphen form

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 22-02-PLAN.md — Add `requirements-completed: []` to summary-standard.md and summary-minimal.md; tighten doc in summary.md
- [x] 22-03-PLAN.md — Tighten `<step name="create_summary">` contract in execute-plan.md and add cross-reference in gsd-doc-writer.md

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 22-04-PLAN.md — Implement scripts/lint-summaries.sh (Bash + yq, presence + subset checks)

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 22-05-PLAN.md — Wire .github/workflows/lint-summaries.yml (macos-26, path-filtered) as the CI gate

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 22-06-PLAN.md — One-shot migration of 18 archived SUMMARYs to canonical form; ephemeral migrate-summary-frontmatter.sh git-rm'd in same commit

### Phase 23: Visual Regression Infra

**Goal:** Stand up snapshot testing for primary surfaces (Light/Dark/System appearance) and wire it into CI so future appearance changes can't silently break the UI.

**Requirements:** VISREG-01, VISREG-02, VISREG-03, VISREG-04, VISREG-05, VISREG-06

**Success criteria:**

1. Snapshot test framework chosen with ADR documenting trade-offs (likely `pointfreeco/swift-snapshot-testing` v2.x)
2. Snapshot baselines exist for ContentView, LibraryView, SettingsView, RecordingView, DictationHUD across Light + Dark + System appearances
3. Snapshot test target runs locally with one command and produces a clear pass/fail report
4. Snapshot tests run in CI as a pre-merge gate (existing `release-dmg.yml` or new test workflow)
5. Update workflow documented in CONTRIBUTING / `.planning/codebase/` — when and how to regenerate baselines

**Dependencies:** None — independent infra work.

**Plans:** 5/5 plans complete

Plans:
**Wave 0** *(parallel)*
- [x] 23-01-PLAN.md — Add swift-snapshot-testing 1.19.2 dep + empty test suite skeleton + SnapshotFixtures helper
- [x] 23-02-PLAN.md — Write ADR documenting framework choice and rejected alternatives (Nygard short-form)

**Wave 1** *(parallel; both depend on 23-01)*
- [x] 23-03-PLAN.md — Implement 15 @Test methods (5 surfaces × 3 appearances) and record/commit 15 baseline PNGs
- [x] 23-04-PLAN.md — Extend build-check.yml with swift test + record-mode guard + diff-artifact upload

**Wave 2** *(depends on 23-03 + 23-04)*
- [x] 23-05-PLAN.md — Refresh TESTING.md and create CONTRIBUTING.md with regen workflow

### Phase 24: Nyquist Sweep — v1.0

**Goal:** Backfill `*-VALIDATION.md` for v1.0 phases that shipped without Nyquist test coverage (Phase 1 Rebrand, Phase 2 Security/Stability, Phase 3 Library, Phase 8 Defects, Phase 10 Obsidian/Cleanup).

**Requirements:** NYQUIST-01, NYQUIST-02, NYQUIST-03, NYQUIST-04, NYQUIST-05

**Success criteria:**

1. `01-VALIDATION.md` exists for v1.0 Phase 1 with assertions covering UserDefaults migration, bundle ID change, app name, executable rename — tests run green
2. `02-VALIDATION.md` exists for v1.0 Phase 2 with assertions covering the 12 SCAN findings, crash recovery path, diarization midnight-cross bug fix — tests run green
3. `03-VALIDATION.md` exists for v1.0 Phase 3 with assertions covering library grid, missing-file detection, naming policy, session lifecycle — tests run green
4. `08-VALIDATION.md` exists for v1.0 Phase 8 with assertions covering crash recovery path, speaker label collapse, source/tome tag removal, print() removal — tests run green
5. `10-VALIDATION.md` exists for v1.0 Phase 10 with assertions covering Obsidian deep-link URL construction, missing-file UX, "Show in Finder" — tests run green

**Dependencies:** Optional benefit from Phase 22 (SUMMARY frontmatter) but not blocked by it.

**Plans:** 5/5 plans complete

Plans:
**Wave 1** *(all 5 plans roughly independent — each touches a separate `*-VALIDATION.md` and a different test file roster; smallest-first execution recommended)*
- [x] 24-01-PLAN.md — Re-audit Phase 1 Rebrand (NYQUIST-01): RebrandInfoPlistTests + 01-VALIDATION.md last_audited bump per D-01
- [x] 24-02-PLAN.md — Backfill Phase 10 Obsidian (NYQUIST-05): RecoveredSessionTypeTests + lift `recoveredSessionType()` helper from ContentView; cross-ref ObsidianURLTests
- [x] 24-03-PLAN.md — Backfill Phase 8 Defects (NYQUIST-04): TranscriptStoreClearTests + FrontmatterSourceTagTests; cross-ref SpeakerCodableTests + TranscriptParserTests
- [x] 24-04-PLAN.md — Backfill Phase 3 Session+Naming (NYQUIST-03): TranscriptRenameTests; cross-ref LibraryStoreTests + LibraryEntryTests + TranscriptParserTests + ObsidianURLTests
- [x] 24-05-PLAN.md — Backfill Phase 2 Security+Stability (NYQUIST-02): WorkflowSecretsTests + TranscriptLoggerSecurityTests + MidnightOffsetTests + CheckpointRoundTripTests + ErrorPathLoggingTests + SHA-pin regression fix on build-check.yml:56 (largest plan, 16 reqs, 1 human-verify CI checkpoint)

### Phase 25: Nyquist Sweep — v1.2

**Goal:** Backfill `*-VALIDATION.md` for the two v1.2 phases that shipped without Nyquist coverage (Wave 0 RED scaffolding pattern was retired post-18.1).

**Requirements:** NYQUIST-06, NYQUIST-07

**Success criteria:**

1. `20-VALIDATION.md` exists for v1.2 Phase 20 with assertions covering token color resolution per appearance, removal of `.preferredColorScheme(.light)` overrides, 17 Chronicle tokens + 11 legacy tokens — tests run green
2. `21-VALIDATION.md` exists for v1.2 Phase 21 with assertions covering `colorScheme: ColorScheme?` bridge, AppSettings persistence, three Scene-root call-sites, `DictationWindowController.NSAppearance(named:)` mirror, Chronicle titlebar bridge — tests run green

**Dependencies:** Phase 23 snapshot infra (optional — VALIDATION tests are unit/integration, but visual regression complements them for the appearance bridge).

**Plans:** 2/2 plans complete

Plans:
**Wave 1**
- [x] 25-01-PLAN.md — Backfill Phase 21 AppearancePreference (NYQUIST-07): AppSettingsTests extension + PreferredColorSchemeGrepGateTests creation + 21-VALIDATION.md with PARTIAL a/b split + Phase 26 cross-ref (smallest-first per D-04)

**Wave 2** *(extends shared PreferredColorSchemeGrepGateTests.swift created in 25-01)*
- [x] 25-02-PLAN.md — Backfill Phase 20 Dark Mode Parity (NYQUIST-06): PreferredColorSchemeGrepGateTests extension + DesignTokensAdaptivePaletteTests creation + 20-VALIDATION.md with PARTIAL a/b split

### Phase 26: QA Sweep + Visual UAT

**Goal:** Execute the deferred Phase 19 "Looks Done But Isn't" QA checklist plus the deferred Phase 21 titlebar visual UAT. Document results; spawn fix plans for any failures.

**Requirements:** QA-01, QA-02, QA-03, QA-04, QA-05, QA-06, QA-07, QA-08, QA-09

**Success criteria:**

1. All 9 QA scenarios executed against a current build with documented PASS/FAIL per item in a `26-UAT.md` artifact
2. Maccy + Alfred live tests confirm clipboard exclusion under privacy markers (or surface concrete bugs to fix)
3. Multi-monitor HUD positioning passes across primary/secondary-left/secondary-right/vertical configurations
4. Security-scoped bookmark survival across relaunch and reboot is confirmed (or bug filed)
5. Phase 21 titlebar visual UAT (QA-06..09) passes for Light/Dark/System preference switches and unfocused-window edge cases
6. Any failures generate todos in `.planning/todos/pending/` or fix plans inside Phase 26

**Dependencies:** None — operates against the current shipped build.

**Plans:** 2/2 plans complete

Plans:
**Wave 1**
- [x] 26-01-PLAN.md — Single execution plan covering full 9-scenario sweep (QA-01..QA-09) + 26-UAT.md authoring per D-04. QA-03 splits into 03a (single-display PASS) + 03b (multi-monitor UNTESTABLE-this-cycle); QA-04 WITHDRAWN with codebase-verified non-sandboxed reasoning; QA-06..09 are citation rows pointing at 21-HUMAN-UAT.md (passed 2026-05-01). Batch-triage + conditional fix routing per D-02.

## Backlog

Future feature directions captured as seeds in `.planning/seeds/` (surfaced by `/gsd-new-milestone` when goals match):

- **SEED-001** Dictation extensions — history pane, voice commands, format-as-you-speak, multi-hotkey, direct-paste
- **SEED-002** Library upgrade — full-text search (FTS5), tags, smart filters, audio scroll-sync, speaker rename, redact
- **SEED-003** Transcript editing surface — inline correction, speaker rename + bulk, redact w/ audio mute, merge/split, undo
- **SEED-004** Format reach — DOCX / PDF / SRT / VTT / JSON / TXT, per-destination presets, Notion property mapping refresh
- **SEED-005** Recording preflight guardrails — block silent recordings, missing-mic alert, live input level meter, permission preflight

### Phase 26.1: Close gap: PROCESS-03 lint-summaries failure on v1.0 archive (INSERTED)

**Goal:** Restore `scripts/lint-summaries.sh` to exit 0 against the full SUMMARY corpus (currently fails C1 on 8 v1.0-archive files), unblocking the `Lint Summaries` CI gate so any PR touching SUMMARY/PLAN files can pass. Closes the only v1.3-milestone-audit blocker (PROCESS-03 `passed-then-regressed`).
**Requirements**: PROCESS-03
**Depends on:** Phase 26
**Plans:** 1/1 plans complete

Plans:
- [x] 26.1-01-PLAN.md — Add `requirements-completed: []` to 8 v1.0-archive SUMMARYs; verify lint exits 0; commit atomically
