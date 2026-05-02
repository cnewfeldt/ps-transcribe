# Roadmap

## Shipped Milestones

- **v1.0 — PS Transcribe** (2026-04-02 → 2026-04-14): Full rebrand from Tome, security/stability hardening, session library + recording naming, three-state mic button + model onboarding, Notion integration, Obsidian deep-link, defect cleanup. 8 active phases, 45 requirements, 28 plans. Archived: [`milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md) · Requirements: [`milestones/v1.0-REQUIREMENTS.md`](milestones/v1.0-REQUIREMENTS.md) · Tag: `v1.0`.
- **v1.1 — Marketing Website** (2026-04-21 → 2026-04-25): Next.js + Vercel scaffold, Chronicle design system port, landing page, MDX docs section (6 pages). Phase 15 (Changelog) reverted — public release notes out of scope. 4 phases, 22 requirements, 16 plans. Production: `ps-transcribe-web.vercel.app`. Archived: [`milestones/v1.1-ROADMAP.md`](milestones/v1.1-ROADMAP.md) · Requirements: [`milestones/v1.1-REQUIREMENTS.md`](milestones/v1.1-REQUIREMENTS.md) · Tag: `v1.1`.
- **v1.2 — Standalone Dictation + Model Auto-Update + Dark Mode Parity** (2026-04-27 → 2026-05-01): Hotkey-triggered dictation with floating HUD + clipboard write + Local File output, FluidAudio model auto-update with manifest-based staging download, Chronicle adaptive light/dark token palette, three-way `AppearancePreference` (System/Light/Dark) override. Phase 18.1 inserted to refactor save destinations into top-level shared layer. Phase 19 removed from scope (QA checklist deferred to `QA-FUT-01`). 6 executed phases, 32 plans, ~33 requirements. Released as v2.2.0 macOS app. Archived: [`milestones/v1.2-ROADMAP.md`](milestones/v1.2-ROADMAP.md) · Requirements: [`milestones/v1.2-REQUIREMENTS.md`](milestones/v1.2-REQUIREMENTS.md) · Audit: [`milestones/v1.2-MILESTONE-AUDIT.md`](milestones/v1.2-MILESTONE-AUDIT.md) · Tag: `v1.2`.

## Current Milestone — v1.3 Polish & Validation

**Goal:** Close deferred backlog from v1.0-1.2 — ship custom marketing-site domain (`gogglebox.com`), complete the Phase 19 "Looks Done But Isn't" QA checklist, backfill Nyquist validation across 7 phases (v1.0 1/2/3/8/10 + v1.2 20/21), and standardize SUMMARY.md frontmatter + visual regression infra.

**Phases:** Continue numbering from v1.2 → v1.3 starts at Phase 22. **6 phases · 31 requirements · all mapped.**

### Progress

| # | Phase | Status |
|---|-------|--------|
| 22 | Process & Frontmatter Standard | [x] Complete 2026-05-02 |
| 23 | Visual Regression Infra | [ ] Pending |
| 24 | Nyquist Sweep — v1.0 | [ ] Pending |
| 25 | Nyquist Sweep — v1.2 | [ ] Pending |
| 26 | QA Sweep + Visual UAT | [ ] Pending |
| 27 | Custom Domain — gogglebox.com | [ ] Pending |

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

### Phase 25: Nyquist Sweep — v1.2

**Goal:** Backfill `*-VALIDATION.md` for the two v1.2 phases that shipped without Nyquist coverage (Wave 0 RED scaffolding pattern was retired post-18.1).

**Requirements:** NYQUIST-06, NYQUIST-07

**Success criteria:**

1. `20-VALIDATION.md` exists for v1.2 Phase 20 with assertions covering token color resolution per appearance, removal of `.preferredColorScheme(.light)` overrides, 17 Chronicle tokens + 11 legacy tokens — tests run green
2. `21-VALIDATION.md` exists for v1.2 Phase 21 with assertions covering `colorScheme: ColorScheme?` bridge, AppSettings persistence, three Scene-root call-sites, `DictationWindowController.NSAppearance(named:)` mirror, Chronicle titlebar bridge — tests run green

**Dependencies:** Phase 23 snapshot infra (optional — VALIDATION tests are unit/integration, but visual regression complements them for the appearance bridge).

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

### Phase 27: Custom Domain — gogglebox.com

**Goal:** Replace the `ps-transcribe-web.vercel.app` slug fallback with `gogglebox.com` as the canonical marketing-site domain.

**Requirements:** DOMAIN-01, DOMAIN-02, DOMAIN-03, DOMAIN-04, DOMAIN-05, DOMAIN-06

**Success criteria:**

1. `gogglebox.com` resolves over HTTPS and serves the marketing site (Vercel-issued cert valid)
2. `ps-transcribe-web.vercel.app` returns a 308 permanent redirect to `gogglebox.com` preserving the path
3. All canonical URLs (`og:url`, `<link rel="canonical">`, `sitemap.xml`, MDX internal links) point to `gogglebox.com`
4. README, PROJECT.md, in-app links, and GitHub repo description updated to reference `gogglebox.com`
5. Production deploy verified via browser smoke test (landing + at least 2 docs pages render correctly under the new domain)

**Why last:** Marketing site content is stable post-v1.1; doing the domain switch after the milestone's other work means a single clean cutover with no in-flight changes to chase.

## Backlog

Future feature directions captured as seeds in `.planning/seeds/` (surfaced by `/gsd-new-milestone` when goals match):

- **SEED-001** Dictation extensions — history pane, voice commands, format-as-you-speak, multi-hotkey, direct-paste
- **SEED-002** Library upgrade — full-text search (FTS5), tags, smart filters, audio scroll-sync, speaker rename, redact
- **SEED-003** Transcript editing surface — inline correction, speaker rename + bulk, redact w/ audio mute, merge/split, undo
- **SEED-004** Format reach — DOCX / PDF / SRT / VTT / JSON / TXT, per-destination presets, Notion property mapping refresh
