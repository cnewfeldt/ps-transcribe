---
created: 2026-05-01
title: Dictation extensions — compound on the v1.2 hotkey win
trigger_when: Considering a dictation-focused milestone, or hearing user feedback about clipboard-only output, lack of voice control, or wanting multiple hotkey profiles
planted_during: v1.3 milestone planning (carry-forward from v1.2 close decision)
---

# SEED-001: Dictation extensions

## The Idea

Extend the v1.2 hotkey dictation primitive (`Cmd+Shift+D`, floating HUD, clipboard write) with capabilities that compound on the win:

- **Dictation history pane** — last N captures in a list, recall + recopy + delete. Library entries already exist (DICT-09); this surfaces them as a quick-access tray instead of forcing a Library-window roundtrip.
- **Voice commands** — inline directives recognized during transcription: "new line", "new paragraph", "period", "comma", "delete that", "scratch that", "all caps". Either via post-process pass on the assembled text or via the ASR model's grammar.
- **Format-as-you-speak** — auto punctuation insertion, sentence-case auto-cap, smart quotes, em-dash conversion. Off by default; opt-in setting.
- **Multiple hotkey profiles** — register N hotkeys, each with distinct destination/format combo (e.g. `Cmd+Shift+D` → clipboard, `Cmd+Shift+M` → Obsidian meeting note, `Cmd+Shift+J` → Local File journal).
- **Direct paste into focused app** — bypass clipboard via Accessibility API simulating keystrokes or AX text insertion. Optional, requires Accessibility permission opt-in (deviates from v1.2's no-permission stance).
- **Push-to-talk variants** — function-key tap, dedicated F-key, foot-pedal HID device support.

## Why This Matters

v1.2 shipped a working dictation primitive with no permission requirements. Each extension here either (a) reduces friction further (history, direct paste) or (b) unlocks workflows that today require external apps (voice commands replace BetterTouchTool macros; multi-hotkey replaces TextExpander). The shared save-destinations architecture from Phase 18.1 means new destinations or formats fan out cleanly without per-feature plumbing.

Direct paste is the most likely user request — clipboard is the default but cursor-position insertion is what most dictation users actually want.

## When to Surface

- A milestone is being planned that's centered on dictation refinement or ASR features
- User feedback flags clipboard-only output as a friction point
- User asks about voice commands, dictation macros, or per-hotkey routing
- Considering Accessibility permission flow (direct-paste forces this conversation)
- Comparing PS Transcribe to commercial dictation tools (Dragon, Wispr Flow, Whisper.cpp wrappers)

## Notes / Constraints

- Direct paste breaks v1.2's "no Accessibility/Input Monitoring permission" promise — call it out explicitly in any milestone scope
- Format-as-you-speak should be off by default to preserve raw-transcript guarantee
- Voice commands need design pass: visible feedback for "command detected vs. literal text"
- Multiple hotkey profiles touch GlobalHotkeyService + AppSettings persistence model
