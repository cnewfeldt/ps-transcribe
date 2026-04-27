# PS Transcribe (formerly Tome)

## What This Is

A native macOS application for real-time audio transcription with dual-stream capture (microphone + system audio), on-device speech recognition via FluidAudio/Parakeet-TDT, post-session speaker diarization, and markdown transcript output. Fully offline-first -- all processing runs locally. Originally branded as "Tome", relaunched as "PS Transcribe" in v1.0 with a marketing website added in v1.1.

## Core Value

Users can record meetings and voice memos with accurate, private, on-device transcription. All processing stays on-device; no cloud APIs, no telemetry, no LLM analysis of transcript content.

## Requirements

### Validated

App fundamentals (existing):

- ✓ Dual-stream audio capture (mic + system)
- ✓ On-device ASR via FluidAudio/Parakeet-TDT
- ✓ Real-time streaming transcription with live text output
- ✓ Post-session speaker diarization
- ✓ Markdown transcript output with YAML frontmatter
- ✓ Configurable vault paths for meetings and voice memos
- ✓ Auto-update via Sparkle
- ✓ Privacy mode (hide from screen share)

v1.0 — PS Transcribe (shipped 2026-04-14):

- ✓ Rebrand from "Tome" to "PS Transcribe" across entire codebase — v1.0 (Phase 1)
- ✓ Security fixes (all 12 SCAN findings) — v1.0 (Phase 2)
- ✓ Crash recovery for incomplete sessions — v1.0 (Phase 2)
- ✓ Diarization timestamp bug fix (sessions crossing midnight) — v1.0 (Phase 2)
- ✓ Error suppression cleanup (replaced silent `try?` with proper error handling) — v1.0 (Phase 2)
- ✓ Session library (grid view, missing-file detection, Obsidian deep links) — v1.0 (Phases 3, 10)
- ✓ Proper session lifecycle (stop → clear → save to library) — v1.0 (Phase 3)
- ✓ Recording naming (before / during / after, date-based fallback) — v1.0 (Phase 3)
- ✓ Three-state mic button (idle / recording / error) — v1.0 (Phase 4)
- ✓ Simple model onboarding (download prompt, progress, success/fail) — v1.0 (Phase 4)
- ✓ Notion integration (on-demand export with property mapping) — v1.0 (Phase 7)

v1.1 — Marketing Website (shipped 2026-04-25):

- ✓ Claude Design brief — v1.1 (BRIEF-01)
- ✓ Next.js + Vercel scaffold at `/website`, preview URLs per PR, production deploy — v1.1 (SITE-01..05, Phase 11)
- ✓ Chronicle design system port (paper palette, Inter/Spectral/JetBrains Mono, primitives, light-only) — v1.1 (DESIGN-01..04, Phase 12)
- ✓ Landing page (hero with download CTA, feature blocks with mockups, shortcut grid, nav, footer) — v1.1 (LAND-01..07, Phase 13; LAND-06 amended to drop changelog link)
- ✓ Docs section (MDX pipeline, build-time sidebar, three-column layout, TOC scroll-spy, 6 pages) — v1.1 (DOCS-01..05, Phase 14)

### Active

_None — v1.1 shipped 2026-04-25. Run `/gsd-new-milestone` to seed the next milestone's requirements._

### Out of Scope

- LLM analysis of transcripts (live or post-hoc) — **removed 2026-04-04 scope reduction.** Ollama integration and live analysis panel were implemented under phases 5 and 6, then removed. Preserved at git tag `archive/llm-analysis-attempt`.
- Cloud-based LLM APIs — offline-first philosophy
- Mobile/iOS version — macOS only
- Real-time collaboration — single-user app
- Video recording — audio transcription only
- Multi-language simultaneous transcription — single locale per session
- Complex onboarding wizard — minimal setup, user owns troubleshooting
- Public changelog — **removed 2026-04-25.** `CHANGELOG.md` stays a developer-internal artifact; no `/changelog` route, RSS feed, or nav/footer link. Phase 15 was built and reverted.
- Custom domain (v1.1) — site shipped on `ps-transcribe-web.vercel.app`. Custom domain is a v1.2 candidate.
- Pricing page / commerce / newsletter / email capture (marketing site)
- Dark mode (marketing site) — light-only to match the macOS app
- Docs search (Cmd+K) and localization (marketing site)

## Current State

**Shipped:**

- **v1.0 PS Transcribe** (2026-04-14). Full rebrand from Tome, all 12 security findings resolved, crash recovery + diarization fixes, session library with right-click "Show in Finder" and Obsidian deep-link, recording naming + lifecycle, three-state mic button, model onboarding, Notion integration. 8 active phases, 45 requirements satisfied, 28 plans shipped. See [`milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md).
- **v1.1 Marketing Website** (2026-04-25). Next.js 16 site at `ps-transcribe-web.vercel.app`, Chronicle design system port (paper palette, Spectral/Inter/JetBrains Mono, navy/sage accents, light-mode only), landing page (hero + product screenshot + release-aware download CTA, four feature blocks with mockups, shortcut grid, sticky Nav, version-stamped Footer), docs section (MDX pipeline with `@next/mdx` + custom rehype plugin, 7 custom MDX components, build-time sidebar codegen, three-column layout with TOC scroll-spy, 6 pages live: Getting Started, Keyboard Shortcuts, Configuring Your Vault, Notion Property Mapping, FAQ, Troubleshooting). Phase 15 (Changelog) reverted. 4 phases, 22 requirements, 16 plans, all human UAT approved. See [`milestones/v1.1-ROADMAP.md`](milestones/v1.1-ROADMAP.md).

> **Production slug fallback:** the canonical `ps-transcribe.vercel.app` was claimed by another Vercel account, so production lives at `ps-transcribe-web.vercel.app` until a custom domain replaces it.

## Next Milestone Goals

Run `/gsd-new-milestone` to capture the next milestone's scope. Candidate areas informed by v1.0 / v1.1 deferrals and tech debt:

- **Custom domain** for the marketing site (replaces the `ps-transcribe-web.vercel.app` slug fallback).
- **Nyquist validation gaps** across phases 1 / 2 / 3 / 8 / 10 (full `/gsd-validate-phase` sweep).
- **Process improvement:** `requirements_completed` frontmatter on future SUMMARY.md files (so requirement traceability is mechanical, not manual).
- **Model update strategy:** automatic speech-model version checking so users get newer FluidAudio ASR models without waiting for a Sparkle app release.

<details>
<summary>Archived: v1.1 Marketing Website goal</summary>

**Goal:** Build and ship a marketing website at `ps-transcribe.vercel.app` — landing and docs — using Next.js on Vercel, reusing the Chronicle design system for visual cohesion with the app.

**Outcome:** Shipped on `ps-transcribe-web.vercel.app` (slug fallback). Phase 15 (Changelog Page) was scoped, planned, built, and reverted on 2026-04-25 — public release notes are out of scope.

**Target features (delivered):**
- Landing page — hero, feature highlights, product screenshots, download CTA pointing at GitHub Releases ✓
- Docs / help section — MDX content, six pages ✓
- Chronicle design-system port — paper palette, Spectral/Inter/JetBrains Mono typography, navy accent, sage speaker-green ✓
- Vercel deployment — preview URLs per commit, production on the fallback slug ✓
- Repo layout — `/website` subdirectory in this repo (separate `package.json` from the Swift package) ✓
- Claude Design brief — source document used to generate the site's design mocks ✓
</details>

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
- Marketing website added in v1.1: Next.js 16 / TypeScript / Tailwind, MDX docs, deployed to Vercel under `/website`
- Security scan completed 2026-03-30 with 12 findings (resolved in v1.0 Phase 2)
- Known architectural concerns (app): some Nyquist validation gaps remain across v1.0 phases (1, 2, 3, 8, 10) — candidate sweep for the next milestone
- FluidAudio is a custom dependency from https://github.com/FluidInference/FluidAudio.git (commit ea50062)
- Distributed via GitHub Releases with Sparkle updates and EdDSA signing
- CI/CD via GitHub Actions (release-dmg.yml)

## Constraints

- **Platform**: macOS 26.0+ only, Swift 6.2, SwiftUI
- **Privacy**: All processing must remain on-device (ASR only -- no LLM, no cloud)
- **Architecture**: Actor-based concurrency, @Observable state management -- follow existing patterns
- **Dependencies**: FluidAudio for ASR/VAD/diarization, Sparkle for updates
- **Distribution**: GitHub Releases with Sparkle appcast, EdDSA signed
- **Marketing site**: light-only, no commerce, no email capture, no public changelog

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Rebrand to "PS Transcribe" | New identity for the app | ✓ Good — shipped v1.0, UserDefaults migrated cleanly |
| Keep Parakeet-TDT for ASR | Good enough quality, proven in existing app | ✓ Good — no regressions in v1.0 |
| No LLM analysis of transcripts | Scope reduction 2026-04-04; product focus is distraction-free transcription, not AI-generated insights | ✓ Good — abandoned cleanly (tag `archive/llm-analysis-attempt`) |
| Library/grid view for session history | Better than current "overwrite in place" UX | ✓ Good — Phase 3 |
| Three-state mic button replaces waveform | Cleaner UX, single interaction point for recording | ✓ Good — Phase 4 |
| Minimal onboarding | No wizard — just model download prompt with progress | ✓ Good — Phase 4 |
| Security fixes before feature work | Solid foundation before adding capabilities | ✓ Good — Phase 2 |
| Marketing site lives in `/website` of this repo | Tightly coupled to the macOS app's release cadence; one source of truth | ✓ Good — v1.1 |
| Port Chronicle design system to web (light-only) | Visual cohesion with the macOS app; no redesign cost | ✓ Good — Phase 12 |
| Vercel subdomain only in v1.1 (custom domain deferred) | Ship the site first; decide on domain after content settles | ⚠️ Revisit — slug had to fall back to `ps-transcribe-web.vercel.app` because the canonical was claimed; custom domain bumped to v1.2 |
| Build-time sidebar codegen from MDX `doc` exports | Drift-by-construction — sidebar can't desync from MDX files | ✓ Good — Phase 14 |
| No public changelog | Decided 2026-04-25 after a built page was reverted; release notes stay developer-internal | ✓ Good — phase 15 reverted, scope reduced |

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
*Last updated: 2026-04-27 after v1.1 milestone completion.*
