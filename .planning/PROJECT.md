# PS Transcribe (formerly Tome)

## What This Is

A native macOS application for real-time audio transcription with dual-stream capture (microphone + system audio), on-device speech recognition via FluidAudio/Parakeet-TDT, post-session speaker diarization, and markdown transcript output. Fully offline-first -- all processing runs locally. Being rebranded from "Tome" to "PS Transcribe" with significant UX improvements and security hardening.

## Core Value

Users can record meetings and voice memos with accurate, private, on-device transcription. All processing stays on-device; no cloud APIs, no telemetry, no LLM analysis of transcript content.

## Requirements

### Validated

- ✓ Dual-stream audio capture (mic + system) -- existing
- ✓ On-device ASR via FluidAudio/Parakeet-TDT -- existing
- ✓ Real-time streaming transcription with live text output -- existing
- ✓ Post-session speaker diarization -- existing
- ✓ Markdown transcript output with YAML frontmatter -- existing
- ✓ Configurable vault paths for meetings and voice memos -- existing
- ✓ Auto-update via Sparkle -- existing
- ✓ Privacy mode (hide from screen share) -- existing

### Active

- [x] Rebrand from "Tome" to "PS Transcribe" across entire codebase -- Validated in Phase 1: Rebrand (2026-04-02)
- [x] Security fixes (all 12 SCAN findings from SECURITY-SCAN.md) -- Validated in Phase 2: Security + Stability (2026-04-03)
- [x] Crash recovery for incomplete sessions -- Validated in Phase 2: Security + Stability (2026-04-03)
- [x] Diarization timestamp bug fix (sessions crossing midnight) -- Validated in Phase 2: Security + Stability (2026-04-03)
- [x] Error suppression cleanup (replace silent try? with proper error handling) -- Validated in Phase 2: Security + Stability (2026-04-03)
- [ ] Session library (grid view of past recordings with file paths, missing-file detection, Obsidian deep links)
- [ ] Proper session lifecycle (stop → clear → save to library, no silent overwrite)
- [ ] Recording naming (optional at any time -- before/during/after, date-based fallback)
- [ ] Three-state mic button (idle/recording/error) replacing waveform visualizer
- [ ] Simple model onboarding (download prompt on first launch, progress indicator, success/fail)

### Out of Scope

- LLM analysis of transcripts (live or post-hoc) -- **removed 2026-04-04 scope reduction.** Ollama integration and live analysis panel were implemented under phases 5 and 6, then removed. Preserved at git tag `archive/llm-analysis-attempt`.
- Cloud-based LLM APIs -- offline-first philosophy
- Mobile/iOS version -- macOS only
- Real-time collaboration -- single-user app
- Video recording -- audio transcription only
- Multi-language simultaneous transcription -- single locale per session
- Complex onboarding wizard -- minimal setup, user owns troubleshooting

## Current State

**Shipped:** v1.0 PS Transcribe (2026-04-14). Full rebrand from Tome, all 12 security findings resolved, crash recovery + diarization fixes, session library with right-click "Show in Finder" and Obsidian deep-link, recording naming + lifecycle, three-state mic button, model onboarding, Notion integration. 8 active phases, 45 requirements satisfied, 28 plans shipped. See [`milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md).

**In progress — v1.1 Marketing Website:** Phases 11-13 complete. Phase 11 (2026-04-22) — Next.js 16 scaffold at `/website` deployed to https://ps-transcribe-web.vercel.app. Phase 12 (2026-04-22) — Chronicle design system ported (paper palette, Spectral/Inter/JetBrains Mono, navy/sage accents). Phase 13 (2026-04-23) — Landing page shipped: hero with product screenshot + release-aware download CTA, three pillar cards, four feature blocks with mini-mockups (DualStream / ChatBubble / ObsidianVault / Notion), keyboard shortcut grid, FinalCTA, sticky Nav with scroll state, Footer with version stamp. LAND-01..LAND-07 satisfied, 5/5 plans executed, human UAT approved 5/5. Phase 14 (Docs section) is next.

## Current Milestone: v1.1 Marketing Website

**Goal:** Build and ship a marketing website at `ps-transcribe-web.vercel.app` — landing, docs, and changelog — using Next.js on Vercel, reusing the Chronicle design system for visual cohesion with the app.

> Note: the canonical `ps-transcribe.vercel.app` slug was already claimed by another Vercel account at phase 11 setup time (2026-04-22), so the fallback slug `ps-transcribe-web.vercel.app` is the production host. A custom domain (v1.2 candidate) will supersede this.

**Target features:**
- Landing page — hero, feature highlights, product screenshots, download CTA pointing at GitHub Releases
- Docs / help section — getting started, keyboard shortcuts, FAQ, troubleshooting (MDX content)
- Changelog page — styled release-notes sourced from `CHANGELOG.md`
- Chronicle design-system port — paper palette, Spectral/Inter/JetBrains Mono typography, navy accent, sage speaker-green
- Vercel deployment — preview URLs per commit, production on `ps-transcribe-web.vercel.app` (see note above on slug fallback)
- Repo layout — `/website` subdirectory in this repo (separate `package.json` from the Swift package)
- Claude Design brief — source document used to generate the site's design mocks

**Scope boundaries:**
- No custom domain (Vercel subdomain only; custom domain deferred)
- No pricing page, no commerce — download CTA points at GitHub Releases
- No blog, no newsletter
- No analytics stack decision in this milestone (default Vercel Analytics if enabled)

## Next Milestone Goals

Candidate areas for v1.2+ informed by v1.0 deferrals and tech debt:
- OWNER placeholder in SUFeedURL and release-dmg.yml — replace with the real GitHub repo URL once finalized.
- Nyquist validation gaps across phases 1/2/3/8/10 (full `/gsd-validate-phase` sweep).
- Process improvement: `requirements_completed` frontmatter on future SUMMARY.md files.
- Custom domain for marketing site.

<details>
<summary>Archived: v1.0 milestone goal</summary>

**Goal:** Rebrand from Tome, harden security/stability, add session management and recording UX.

**Target features:**
- ~~Rebrand to "PS Transcribe" across entire codebase~~ (Phase 1 complete)
- ~~Security fixes for all 12 SCAN findings~~ (Phase 2 complete)
- ~~Stability -- crash recovery, diarization fix, error handling~~ (Phase 2 complete)
- ~~Session library with grid view, naming, lifecycle~~ (Phase 3 complete)
- ~~Three-state mic button + model onboarding~~ (Phase 4 complete)
- ~~Ollama integration + live LLM analysis panel~~ (abandoned 2026-04-04 scope reduction)
- ~~Notion integration~~ (Phase 7 complete)
- ~~Obsidian deep-link + final defect cleanup~~ (Phase 10 complete)
</details>

## Context

- Existing brownfield codebase: Swift 6.2, SwiftUI, macOS 26.0+
- Codebase mapped on 2026-03-30 (see .planning/codebase/)
- Security scan completed 2026-03-30 with 12 findings (2 critical, 4 high, 4 medium, 2 low)
- Known architectural concerns: file I/O race conditions, silent error suppression (29 try? instances), unbounded temp audio files
- FluidAudio is a custom dependency from https://github.com/FluidInference/FluidAudio.git (commit ea50062)
- Distributed via GitHub Releases with Sparkle updates and EdDSA signing
- CI/CD via GitHub Actions (release-dmg.yml)

## Constraints

- **Platform**: macOS 26.0+ only, Swift 6.2, SwiftUI
- **Privacy**: All processing must remain on-device (ASR only -- no LLM, no cloud)
- **Architecture**: Actor-based concurrency, @Observable state management -- follow existing patterns
- **Dependencies**: FluidAudio for ASR/VAD/diarization, Sparkle for updates
- **Distribution**: GitHub Releases with Sparkle appcast, EdDSA signed

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Rebrand to "PS Transcribe" | User decision, new identity for the app | -- Pending |
| Keep Parakeet-TDT for ASR | Good enough quality, proven in existing app | -- Pending |
| No LLM analysis of transcripts | Scope reduction 2026-04-04; product focus is distraction-free transcription, not AI-generated insights | Abandoned after implementation (tag archive/llm-analysis-attempt) |
| Library/grid view for session history | Better than current "overwrite in place" UX | -- Pending |
| Three-state mic button replaces waveform | Cleaner UX, single interaction point for recording | -- Pending |
| Minimal onboarding | No wizard -- just model download prompt with progress | -- Pending |
| Security fixes before feature work | Solid foundation before adding capabilities | -- Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check -- still the right priority?
3. Audit Out of Scope -- reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-21 — v1.1 marketing website milestone started.*
