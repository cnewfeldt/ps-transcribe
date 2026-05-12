# Roadmap

## Shipped Milestones

- **v1.0 — PS Transcribe** (2026-04-02 → 2026-04-14): Full rebrand from Tome, security/stability hardening, session library + recording naming, three-state mic button + model onboarding, Notion integration, Obsidian deep-link, defect cleanup. 8 active phases, 45 requirements, 28 plans. Archived: [`milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md) · Requirements: [`milestones/v1.0-REQUIREMENTS.md`](milestones/v1.0-REQUIREMENTS.md) · Tag: `v1.0`.
- **v1.1 — Marketing Website** (2026-04-21 → 2026-04-25): Next.js + Vercel scaffold, Chronicle design system port, landing page, MDX docs section (6 pages). Phase 15 (Changelog) reverted — public release notes out of scope. 4 phases, 22 requirements, 16 plans. Production: `ps-transcribe-web.vercel.app`. Archived: [`milestones/v1.1-ROADMAP.md`](milestones/v1.1-ROADMAP.md) · Requirements: [`milestones/v1.1-REQUIREMENTS.md`](milestones/v1.1-REQUIREMENTS.md) · Tag: `v1.1`.
- **v1.2 — Standalone Dictation + Model Auto-Update + Dark Mode Parity** (2026-04-27 → 2026-05-01): Hotkey-triggered dictation with floating HUD + clipboard write + Local File output, FluidAudio model auto-update with manifest-based staging download, Chronicle adaptive light/dark token palette, three-way `AppearancePreference` (System/Light/Dark) override. Phase 18.1 inserted to refactor save destinations into top-level shared layer. Phase 19 removed from scope (QA checklist deferred to `QA-FUT-01`). 6 executed phases, 32 plans, ~33 requirements. Released as v2.2.0 macOS app. Archived: [`milestones/v1.2-ROADMAP.md`](milestones/v1.2-ROADMAP.md) · Requirements: [`milestones/v1.2-REQUIREMENTS.md`](milestones/v1.2-REQUIREMENTS.md) · Audit: [`milestones/v1.2-MILESTONE-AUDIT.md`](milestones/v1.2-MILESTONE-AUDIT.md) · Tag: `v1.2`.
- **v1.3 — Polish & Validation** (2026-05-01 → 2026-05-12): SUMMARY frontmatter standard + CI lint gate (`requirements-completed:`), swift-snapshot-testing visual-regression infra with 15 baselines across 5 surfaces × 3 appearances, Nyquist `*-VALIDATION.md` backfill for v1.0 phases 1/2/3/8/10 + v1.2 phases 20/21, Phase 19 QA checklist sweep + Phase 21 titlebar visual UAT. Phase 26.1 inserted to close PROCESS-03 lint-gate regression. 6 phases, 21 plans, 25 requirements (22 satisfied · 3 retired-with-context · 1 deferred-with-todo). Suite grew 236 → 268 tests / 42 → 52 suites. Archived: [`milestones/v1.3-ROADMAP.md`](milestones/v1.3-ROADMAP.md) · Requirements: [`milestones/v1.3-REQUIREMENTS.md`](milestones/v1.3-REQUIREMENTS.md) · Audit: [`milestones/v1.3-MILESTONE-AUDIT.md`](milestones/v1.3-MILESTONE-AUDIT.md) · Tag: `v1.3`.

## Current Milestone

_No active milestone — run `/gsd-new-milestone` to start v1.4._

## Backlog

Future feature directions captured as seeds in `.planning/seeds/` (surfaced by `/gsd-new-milestone` when goals match):

- **SEED-001** Dictation extensions — history pane, voice commands, format-as-you-speak, multi-hotkey, direct-paste
- **SEED-002** Library upgrade — full-text search (FTS5), tags, smart filters, audio scroll-sync, speaker rename, redact
- **SEED-003** Transcript editing surface — inline correction, speaker rename + bulk, redact w/ audio mute, merge/split, undo
- **SEED-004** Format reach — DOCX / PDF / SRT / VTT / JSON / TXT, per-destination presets, Notion property mapping refresh
- **SEED-005** Recording preflight guardrails — block silent recordings, missing-mic alert, live input level meter, permission preflight

### Deferred from v1.3 (high-priority tech debt)

- **`ci-build-check-failing-on-main.md`** — Swift 6 strict-concurrency errors at `TranscriptionEngine.swift:238,342` fail `build-check.yml` on macos-26. Blocks Phase 24 CI green attestation.
- **`model-manifest-url-404.md`** — Model manifest URL returns HTTP 404; `ModelUpdateService.checkForUpdate()` always fails. Blocks QA-05 reachability and prevents any model update from shipping until the manifest is republished.
- **REQUIREMENTS.md traceability bookkeeping convention** — Phase 26 human-decision #1; either update traceability table mid-phase or document the milestone-close convention explicitly. One-pass edit.
- **QA-03b sub-scenario disposition** — Phase 26 human-decision #2; accept absorption (current state) or split into deferred-todo for secondary-left / secondary-right / vertical / mid-recording-disconnect. One-pass edit.
- **lint-summaries.sh scope extension** to `.planning/phases/`; SettingsView snapshot Dictation crop; 25-REVIEW WR-01..05 advisory; Phase 25 WR-02 adaptive-token roster gap — see `milestones/v1.3-MILESTONE-AUDIT.md` Tech Debt Summary.
