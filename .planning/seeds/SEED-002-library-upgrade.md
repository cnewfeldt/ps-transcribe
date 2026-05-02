---
created: 2026-05-01
title: Library upgrade — make session history actually useful
trigger_when: Considering a milestone focused on transcript discovery, library UX, or post-recording workflows; hearing complaints about finding old transcripts; library accumulating to 100+ entries
planted_during: v1.3 milestone planning (carry-forward from v1.2 close decision)
---

# SEED-002: Library upgrade

## The Idea

Today's session library (v1.0 Phase 3 + Phase 10) is a grid of cards with missing-file detection and Obsidian deep-links. As the library grows past ~50 entries, finding a specific transcript becomes scroll-hunting. Upgrade:

- **Full-text search** across all transcripts — query box at top of library; results highlight matches; live filter as user types. Local SQLite FTS5 index over markdown bodies, refreshed on save.
- **Tags** — manual tag application from Library card right-click; tag chip filter row; tag-based grouping toggle.
- **Smart filters** — filter row by date range, duration band (short/medium/long), source type (meeting / voice memo / dictation), destination (saved-to-Notion / saved-to-Obsidian / local-only).
- **Pinned / favorites** — star icon on each card; pinned section pinned to top of grid.
- **Audio scroll-sync** — open a session, click play, watch transcript text scroll-highlight in lockstep with audio playhead. Speaker-aware (highlight current speaker).
- **Speaker rename** — bulk rename "SPEAKER_00 → Cary" across an entire transcript; persist into the markdown body.
- **Redact** — select a span, replace text with `[REDACTED]`, optionally mute the audio span if the source recording is still on disk.

## Why This Matters

The Library is currently the only persistent user surface in the app, but it's read-only-ish. As users accumulate hundreds of transcripts, search + tags + filters become the difference between "useful archive" and "graveyard". Audio scroll-sync is the one feature that makes a transcript app feel like a transcript *editor* rather than a dump.

Speaker rename + redact specifically address the privacy-sensitive use case (recording a meeting, then needing to share a clean version externally).

FTS5 fits the on-device philosophy — no cloud index, no embedding service.

## When to Surface

- Milestone planning around transcript discovery, post-recording workflows, or library UX
- User feedback complaining about finding old transcripts ("I know I recorded that meeting last month but can't find it")
- Library accumulates past ~50-100 entries and scrolling becomes painful
- Considering audio playback features (audio scroll-sync requires playhead infra anyway)
- Privacy-sensitive use cases come up (redact + speaker rename are differentiators)

## Notes / Constraints

- FTS5 is built into SQLite stdlib on macOS — no new dep
- Audio scroll-sync requires the source audio file still being on disk; today we delete after diarization in some flows. May need retention policy decision.
- Speaker rename touches the diarization output format (markdown speaker labels)
- Tags storage decision: per-file frontmatter vs. central index (frontmatter preserves portability if user edits in Obsidian)
