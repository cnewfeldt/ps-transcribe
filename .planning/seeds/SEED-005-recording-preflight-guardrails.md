---
created: 2026-05-06
title: Recording preflight guardrails — never let "record" start without a working input
trigger_when: Considering a reliability/UX milestone, hearing user reports of silent recordings, missing voice tracks, or mic-source confusion. Also when scoping any change to the recording start flow.
planted_during: v1.3 milestone (carry-forward — surfaced after user lost recordings due to no mic source selected)
---

# SEED-005: Recording preflight guardrails

## The Idea

Block or warn at recording-start when the input chain isn't actually capturing the user's voice. Today the user can hit Record, the app appears to record, and nothing useful is captured because no mic source is selected (or the wrong one is). Capture the broader pattern as "preflight checks", with the missing-mic case as the anchor:

- **Missing input source guard** — if no mic source is selected, surface a blocking alert at record-start with a one-click picker. Don't let recording proceed silently.
- **Default-on-launch behavior** — if the app launches with no remembered mic, auto-select the system default input rather than starting in a "no source" state.
- **Live input level meter** — a small VU/level indicator near the record button so the user can see their voice register *before* committing. If level stays at zero for N seconds after record starts, raise a non-blocking warning.
- **Permission preflight** — if microphone permission is missing or revoked, catch it at record-start (not mid-recording) with a direct path to System Settings.
- **Source change mid-session warning** — if the selected mic disconnects (Bluetooth dropout, USB unplug) during recording, alert the user instead of silently continuing.
- **Post-recording validation** — if the saved audio file is silent / below a noise floor for >X% of duration, flag the session in the Library with a "no audio detected" indicator so it isn't discovered hours later.

## Why This Matters

Silent recordings are the worst possible failure mode for a transcription app — they're discovered late (after the meeting is over), they can't be recovered, and they erode trust faster than any other bug class. The user already lost recordings to this. Every other feature in the app assumes a usable audio file exists; a preflight layer protects all of them at once.

This compounds with v1.2's dictation work too — the same input chain underlies hotkey dictation, so the same guardrails carry over. A user who trusts the recorder will use it more aggressively; a user who's been burned once second-guesses every session.

## When to Surface

- Reliability / hardening milestone is being scoped
- User reports a silent or partially-silent recording
- Considering changes to `RecordingService` / input device selection / `AVAudioEngine` setup
- Library improvements that involve flagging or filtering bad sessions
- Onboarding redesign — preflight is a natural moment to teach the input model
- Comparing against competitors that have explicit "test your mic" onboarding (Zoom, Loom, Riverside)

## Notes / Constraints

- The blocking alert needs to be *fast* — if the user is hitting record because something just happened (a meeting started), a multi-step modal will get muscle-memory'd past. One-click default + escape hatch.
- "Silent file" detection is heuristic — a long quiet pause in a real meeting could false-positive. Tune threshold against real recordings before shipping.
- Mid-session disconnect handling overlaps with crash-recovery / checkpointing logic — confirm whether the existing recovery path already covers this or needs an extension.
- Permission state can change between launches; cache stale, always re-check at record-start.
- Live level meter is a 60Hz UI update during recording — confirm it doesn't interfere with the AVAudioEngine tap or transcription pipeline.
- Mic selection UI already exists somewhere in Settings; the question is whether the record-start guard reuses that picker inline or pops a dedicated modal.
