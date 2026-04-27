---
gsd_state_version: 1.0
milestone: v1.2
milestone_name: Standalone Dictation + Model Auto-Update
status: in-progress
stopped_at: null
last_updated: "2026-04-27T00:00:00.000Z"
last_activity: 2026-04-27
progress:
  total_phases: 4
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-27)

**Core value:** Users can record meetings and voice memos with accurate, private, on-device transcription. All processing stays on-device.
**Current focus:** v1.2 — Standalone Dictation + Model Auto-Update. Roadmap defined; ready to plan Phase 16.

**Shipped milestones:**
- v1.0 PS Transcribe (2026-04-14) — see `milestones/v1.0-ROADMAP.md`
- v1.1 Marketing Website (2026-04-25) — see `milestones/v1.1-ROADMAP.md`

**2026-04-04 scope reduction:** Phases 5 (Ollama Integration) and 6 (Live LLM Analysis) were abandoned in v1.0. PS Transcribe is scoped to transcription only; LLM analysis of transcripts is not part of the product. Implementation preserved at git tag `archive/llm-analysis-attempt`.

**2026-04-25 scope reduction:** Phase 15 (Changelog Page) was scoped, planned, built, and then reverted in v1.1. No public release-notes surface; `CHANGELOG.md` stays a developer-internal artifact.

## Current Position

Phase: 16 — Foundation
Plan: Not started
Status: Roadmap defined; ready to plan
Last activity: 2026-04-27 -- v1.2 roadmap created (Phases 16–19, 26 requirements mapped)

Progress: [          ] 0%

## Performance Metrics

**Velocity (cumulative):**

- v1.0 plans completed: 28
- v1.1 plans completed: 16
- Total plans (v1.0 + v1.1): 44

**By Milestone:**

| Milestone | Phases | Plans | Shipped |
|-----------|--------|-------|---------|
| v1.0 — PS Transcribe | 8 active (5/6 abandoned) | 28 | 2026-04-14 |
| v1.1 — Marketing Website | 4 (15 reverted) | 16 | 2026-04-25 |
| v1.2 — Standalone Dictation + Model Auto-Update | 4 (in progress) | TBD | TBD |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table. Recent milestone-level decisions:

- v1.1 phases continued v1.0's numbering (first v1.1 phase was 11)
- v1.2 phases continue from v1.1's last phase: Phases 16–19 (phase 15 was reverted, so 16 is the correct next number)
- Backlog phase 999.1 (keyboard-triggered clipboard dictation) promoted into v1.2 as DICT-01..11 + FOLDER-01..05; removed from backlog
- Marketing site lives in `/website` subdirectory of this repo (not a separate repo)
- Chronicle design system ported to web, light-only — no web-specific redesign
- Vercel subdomain fallback to `ps-transcribe-web.vercel.app` (canonical slug claimed); custom domain deferred post-v1.2
- No public changelog — decided after building and reverting a page in phase 15
- Build-time sidebar codegen from MDX `doc` exports (drift-by-construction in phase 14)
- Global hotkey mechanism: `sindresorhus/KeyboardShortcuts` via `RegisterEventHotKey` (no Accessibility or Input Monitoring permissions required; App Store compatible)
- Dictation uses a separate `TranscriptionEngine` instance owned by `DictationCoordinator` (Option B from architecture research), not a forked state machine
- **Manifest hosting strategy ADR is a research gate for Phase 17** — resolve before Phase 17 planning locks; SUMMARY.md recommends project-owned manifest on gh-pages for per-file SHA-256 + `min_app_version` support

### Pending Todos

v1.2 phases ready to plan:
- [ ] Phase 16: Foundation — lift LibraryStore, anySessionActive flag, Models.swift enums, AppSettings keys, TranscriptLogger plain methods
- [ ] Phase 17: Model Auto-Update — ModelUpdateService, reloadModels(), Settings > Model section
- [ ] Phase 18: Hotkey Dictation + Plain-Folder Output — DictationHotkeyController, DictationCoordinator, DictationHUD, clipboard write, folder picker, DictationLogger
- [ ] Phase 19: Integration & Hardening — mutual exclusion, rollback simulation, QA checklist

Deferred to a later milestone (see PROJECT.md "Future Candidate Goals"):
- [ ] Custom domain for marketing site
- [ ] Nyquist validation sweep across v1.0 phases 1, 2, 3, 8, 10
- [ ] `requirements_completed` frontmatter on future SUMMARY.md files (process improvement)

### Blockers/Concerns

**Research gate (Phase 17):** Manifest hosting strategy ADR must be resolved before Phase 17 planning locks. Options: HuggingFace refs API (lightweight, no infrastructure) vs. project-owned JSON manifest on gh-pages (enables per-file SHA-256 checksums and `min_app_version` compatibility gating). Recommendation in SUMMARY.md: project-owned manifest.

## Session Continuity

Last session: 2026-04-27T00:00:00.000Z
Stopped at: v1.2 roadmap created — Phases 16–19 defined, 26 requirements mapped, ready to plan Phase 16
Resume file: .planning/ROADMAP.md
