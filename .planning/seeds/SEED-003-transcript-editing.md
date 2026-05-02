---
created: 2026-05-01
title: Transcript editing surface — inline correction, speaker rename, redact, merge/split
trigger_when: Considering a milestone for post-recording editing, accuracy improvements, or sharing/export workflows; user requests to fix ASR errors without leaving the app
planted_during: v1.3 milestone planning (carry-forward from v1.2 close decision)
---

# SEED-003: Transcript editing surface

## The Idea

PS Transcribe today writes a markdown transcript and then becomes read-only. To fix an ASR mistake, rename a speaker, or clean up a transcript before sharing, the user has to leave the app and edit the file in Obsidian / Notion / a text editor. Build first-party editing:

- **Inline correction** — click any word in a transcript view, replace it. Maintain timestamp anchors so the underlying segment metadata stays correct. Track edits as a diff layer (so original ASR output is preserved for audit).
- **Speaker rename + bulk reassignment** — select all "SPEAKER_00" segments, rename to "Cary". Per-segment override too (this specific block is actually the other speaker, fix the diarization mistake).
- **Redact with audio mute** — select a span, replace text with `[REDACTED]`, optionally apply a silence/beep to the underlying audio file in that time range. Useful for recordings that contain PII or accidental sensitive content.
- **Merge / split sessions** — combine two adjacent recordings into one transcript (e.g., "the meeting actually started 10 minutes earlier in a different session"); split a long recording into chapters at user-chosen timestamps.
- **Undo history** — every edit reversible; per-session history pane.
- **Export edited copy** — when re-saving, produce both `original.md` (raw ASR) and `edited.md` (user-cleaned) so the audit trail is preserved.

## Why This Matters

ASR is good but not perfect. Diarization is even less perfect — speaker mis-attribution is the #1 quality complaint with on-device speaker models. Without an in-app fix flow, every user develops their own external workflow (Obsidian regex find-replace, manual Notion cleanup). That fragments the value proposition: "PS Transcribe gives you a transcript, but you have to use another tool to actually use it."

First-party editing closes that loop. Audio mute on redact is genuinely differentiated — almost no transcript tool offers it because it requires actual audio file rewrite.

## When to Surface

- Milestone planning around accuracy, post-recording workflows, or sharing/export
- User requests to fix ASR errors or speaker mistakes without leaving the app
- Privacy/redaction use cases come up
- Considering chapter markers, navigation, or timestamp anchoring features
- Alongside SEED-002 (Library upgrade) — speaker rename is shared between them

## Notes / Constraints

- Timestamp anchor preservation is the hard part — naive markdown editing breaks alignment with audio
- Audio mute requires the source audio still on disk + a writeable copy (decide: in-place vs. clone-and-mute)
- Diff layer storage decision: extended frontmatter vs. sidecar `.edits.json`
- Undo across edits + redacts + speaker renames needs a unified undo stack
- May overlap with SEED-002 speaker rename — plan together if both are scoped in same milestone
