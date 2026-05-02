---
created: 2026-05-01
title: Format reach — export beyond Markdown
trigger_when: Considering an export-focused milestone; users requesting DOCX / PDF / SRT / VTT outputs; integration partners asking for structured JSON; Notion property mapping needs a refresh
planted_during: v1.3 milestone planning (carry-forward from v1.2 close decision)
---

# SEED-004: Format reach

## The Idea

PS Transcribe today writes Markdown with YAML frontmatter to disk + Notion + Obsidian. Markdown covers ~80% of personal/note-taking workflows but blocks several real use cases:

- **DOCX** — share with non-technical collaborators (legal, journalism, academic transcription)
- **PDF** — fixed-format archive, shareable without rendering dependencies
- **SRT / VTT** — video captioning workflows (someone records a talk + uploads to YouTube/Vimeo, needs subtitles)
- **JSON** — programmatic consumers (LLM pipelines, downstream tooling, integration partners)
- **Plain TXT** — lossless text-only fallback for everything that doesn't speak Markdown

Build out:

- **Export as…** menu on each Library entry → format picker → save dialog
- **Per-destination format presets** in SaveDestinations — e.g., the Local File destination could fan out a session into all 6 formats, or only DOCX, depending on user setting
- **Shared format renderers** — single source of truth for "transcript → format X"; reused across export menu, destination fan-out, and any future programmatic API
- **Notion property mapping refresh** — current mapping is fixed (title, date, duration). Add: speaker count, source type, tags, transcript length, model version. Make mapping user-editable in Settings.

## Why This Matters

Format is the cheapest way to reach new user segments. Every format unlocks a new workflow without changing the core product. SRT/VTT specifically reaches the entire video-creator audience with zero new ASR work — same transcript, different render.

JSON unlocks programmatic consumption — third-party Raycast extensions, Alfred workflows, custom shell scripts that grep across transcripts. Today users have to parse Markdown.

Shared renderers prevent format-explosion code duplication and align with the Phase 18.1 "fan out, don't fork" architectural principle.

## When to Surface

- Milestone planning around exports, sharing, or integration partners
- User requests for DOCX / PDF / SRT / VTT
- Video creator / podcaster use cases come up
- Programmatic consumer (LLM pipelines, Raycast/Alfred) requests
- Notion integration needs a refresh
- Considering a public API or scripting surface

## Notes / Constraints

- DOCX requires a third-party Swift library or shelling to LibreOffice/pandoc — research needed
- PDF can be done via NSPrintOperation + custom view rendering (no new dep)
- SRT/VTT need timestamp data per segment — this is already in the diarization output, just not exposed
- JSON schema decision: stable contract (versioned) vs. structural-output-of-internal-types
- Notion property mapping change is breaking for existing users — needs migration thinking
- Shared renderer architecture decision aligns with SaveDestinations pattern from Phase 18.1
