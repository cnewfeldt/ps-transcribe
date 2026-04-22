---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: — Marketing Website
status: planning
stopped_at: Phase 11 context gathered
last_updated: "2026-04-22T19:09:48.074Z"
last_activity: 2026-04-21 — Roadmap for v1.1 created, 25 requirements mapped across 5 phases
progress:
  total_phases: 5
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-21)

**Core value:** Users can record conversations and voice memos with accurate, private, on-device transcription. All processing stays on-device.
**Current focus:** v1.1 Marketing Website — landing + docs + changelog on Next.js/Vercel at `ps-transcribe.vercel.app`, reusing Chronicle design. Subdirectory `/website` inside this repo.

**2026-04-04 scope reduction:** Phases 5 (Ollama Integration) and 6 (Live LLM Analysis) were abandoned in v1.0. PS Transcribe is scoped to transcription only; LLM analysis of transcripts is not part of the product. Implementation preserved at git tag `archive/llm-analysis-attempt`.

## Current Position

Phase: 11 of 15 (Website Scaffolding & Vercel Deployment) — v1.1 phases are 11–15
Plan: — (none yet)
Status: Ready to plan
Last activity: 2026-04-21 — Roadmap for v1.1 created, 25 requirements mapped across 5 phases

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity (v1.0 cumulative):**

- Total plans completed (v1.0): 28
- v1.1 plans completed: 0
- Average duration: --
- Total execution time: --

**By Phase (v1.0 historical):**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| v1.0 (1–10) | 28 | — | — |
| 11–15 (v1.1) | 0 | — | — |

*Updated after each plan completion.*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- v1.1 phases continue v1.0 numbering — first v1.1 phase is 11, not 1
- Website lives in `/website` subdirectory of the existing repo, separate `package.json` from the Swift package — no new repo
- Chronicle design system ported from the macOS app, not redesigned for web; light mode only, matches app's aesthetic
- Vercel subdomain (`ps-transcribe.vercel.app`) only in v1.1; custom domain deferred
- Download CTA points at GitHub Releases DMG — no pricing page, no commerce, no email capture

### Pending Todos

- [ ] Model update strategy: Add automatic speech model version checking so users get newer FluidAudio ASR models without waiting for an app release. Current approach ties model updates to Sparkle app updates, which works but delays model improvements.
- [ ] OWNER placeholder replacement in `SUFeedURL` and `release-dmg.yml` (carried from v1.0)

### Blockers/Concerns

None blocking v1.1 scaffolding. Phase 11 is independent of the macOS app codebase — no Swift-side dependencies.

## Session Continuity

Last session: 2026-04-22T19:09:48.072Z
Stopped at: Phase 11 context gathered
Resume file: .planning/phases/11-website-scaffolding-vercel-deployment/11-CONTEXT.md
