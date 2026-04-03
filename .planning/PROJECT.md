# PS Transcribe (formerly Tome)

## What This Is

A native macOS application for real-time audio transcription with dual-stream capture (microphone + system audio), on-device speech recognition via FluidAudio/Parakeet-TDT, post-session speaker diarization, and markdown transcript output. Fully offline-first -- all processing runs locally. Being rebranded from "Tome" to "PS Transcribe" with significant UX improvements, local LLM integration via Ollama, and security hardening.

## Core Value

Users can record conversations and voice memos with accurate, private, on-device transcription and get live AI-powered insights without anything leaving their machine.

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
- [ ] Session library (grid view of past recordings with file paths, missing-file detection, Obsidian deep links)
- [ ] Proper session lifecycle (stop → clear → save to library, no silent overwrite)
- [ ] Recording naming (optional at any time -- before/during/after, date-based fallback)
- [ ] Three-state mic button (idle/recording/error) replacing waveform visualizer
- [ ] Simple model onboarding (download prompt on first launch, progress indicator, success/fail)
- [ ] Ollama integration (detect/configure local Ollama, model browser/download)
- [ ] Live LLM analysis panel (summary, action items, key topics alongside transcript during recording)
- [ ] Security fixes (all 12 SCAN findings from SECURITY-SCAN.md)
- [ ] Crash recovery for incomplete sessions
- [ ] Diarization timestamp bug fix (sessions crossing midnight)
- [ ] Error suppression cleanup (replace silent try? with proper error handling)

### Out of Scope

- Cloud-based LLM APIs -- offline-first philosophy, Ollama only
- Mobile/iOS version -- macOS only
- Real-time collaboration -- single-user app
- Video recording -- audio transcription only
- Multi-language simultaneous transcription -- single locale per session
- Complex onboarding wizard -- minimal setup, user owns troubleshooting

## Current Milestone: v1.0 PS Transcribe

**Goal:** Rebrand from Tome, harden security/stability, add session management and recording UX, integrate local LLM via Ollama for live analysis.

**Target features:**
- ~~Rebrand to "PS Transcribe" across entire codebase~~ (Phase 1 complete)
- Security fixes for all 12 SCAN findings
- Stability -- crash recovery, diarization fix, error handling
- Session library with grid view, naming, lifecycle
- Three-state mic button + model onboarding
- Ollama integration + live LLM analysis panel

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
- **Privacy**: All processing must remain on-device (ASR + LLM via Ollama)
- **Architecture**: Actor-based concurrency, @Observable state management -- follow existing patterns
- **Dependencies**: FluidAudio for ASR/VAD/diarization, Sparkle for updates, Ollama for LLM (new)
- **Distribution**: GitHub Releases with Sparkle appcast, EdDSA signed

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Rebrand to "PS Transcribe" | User decision, new identity for the app | -- Pending |
| Keep Parakeet-TDT for ASR | Good enough quality, proven in existing app | -- Pending |
| Ollama for LLM (not cloud APIs) | Preserves offline-first philosophy, no API keys needed | -- Pending |
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
*Last updated: 2026-04-01 after milestone v1.0 start*
