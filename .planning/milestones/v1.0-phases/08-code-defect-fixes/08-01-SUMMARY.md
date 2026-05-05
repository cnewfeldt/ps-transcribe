---
phase: 08-code-defect-fixes
plan: 01
subsystem: speaker-model
tags: [speaker-enum, codable, transcript-parser, transcript-view, tdd]
dependency_graph:
  requires: []
  provides: [Speaker.named, namedSpeakerColor, SpeakerCodableTests]
  affects: [Models.swift, TranscriptParser.swift, TranscriptView.swift, ContentView.swift]
tech_stack:
  added: []
  patterns: [associated-value-codable, backward-compat-decoder, swift-testing]
key_files:
  created:
    - PSTranscribe/Tests/PSTranscribeTests/SpeakerCodableTests.swift
  modified:
    - PSTranscribe/Sources/PSTranscribe/Models/Models.swift
    - PSTranscribe/Sources/PSTranscribe/Storage/TranscriptParser.swift
    - PSTranscribe/Sources/PSTranscribe/Views/TranscriptView.swift
    - PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift
    - PSTranscribe/Tests/PSTranscribeTests/TranscriptParserTests.swift
decisions:
  - Speaker enum uses manual Codable with singleValueContainer legacy path to preserve existing JSONL session files
  - rawValue computed property added to Speaker for logging compatibility in StreamingTranscriber
  - namedSpeakerColor extracted as file-scope private function so both UtteranceBubble and VolatileIndicator can share it
metrics:
  duration_minutes: 25
  completed_date: "2026-04-07"
  tasks_completed: 2
  files_modified: 5
requirements:
  - STAB-01
  - STAB-03
---

# Phase 08 Plan 01: Speaker Label Collapse Fix Summary

Speaker enum extended with `.named(String)` case and backward-compatible Codable so diarized labels ("Speaker 2", "Speaker 3") survive parse round-trips, with teal/amber colored badge display in TranscriptView.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add Speaker.named(String) with backward-compat Codable and fix TranscriptParser | 98f1740 | Models.swift, TranscriptParser.swift, SpeakerCodableTests.swift, TranscriptParserTests.swift |
| 2 | Update TranscriptView display, VolatileIndicator, and ContentView speakerName | 91ec1af | TranscriptView.swift, ContentView.swift |

## What Was Built

**Task 1:** Changed `Speaker` from `enum Speaker: String, Codable` (raw value) to manual `Codable` with an associated-value `.named(String)` case. The decoder handles both the old bare-string JSON format (`"you"`, `"them"`) for backward compatibility with existing JSONL session files, and the new keyed-container format (`{"type":"named","label":"Speaker 2"}`). TranscriptParser now maps "You" -> `.you`, "Them" -> `.them`, and anything else (e.g. "Speaker 2", "Speaker 3") -> `.named(speakerStr)` instead of collapsing to `.them`.

**Task 2:** TranscriptView.swift updated with two new color tokens (`speakerTeal`, `speakerAmber`), a file-scope `namedSpeakerColor` helper that picks from the palette by speaker index, exhaustive switch statements in `UtteranceBubble.accentColor` and `VolatileIndicator.accentColor`, a `speakerDisplayName` computed property replacing the hardcoded `"You"/"Them"` ternary, and alignment guards changed from `== .them` to `!= .you` so named speakers align left. ContentView `handleNewUtterance` updated to an exhaustive switch for the speaker name passed to `transcriptLogger.append`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added rawValue computed property to Speaker for StreamingTranscriber logging**

- **Found during:** Task 1 GREEN phase (build error after Models.swift change)
- **Issue:** `StreamingTranscriber.swift` used `speaker.rawValue` for diagnostic logging in 5 places. Removing `String` raw value from the enum broke these call sites with "value of type 'Speaker' has no member 'rawValue'" errors.
- **Fix:** Added `var rawValue: String` computed property to `Speaker` returning `"you"`, `"them"`, or the label string. This preserves all logging call sites without modification.
- **Files modified:** Models.swift
- **Commit:** 98f1740

**2. [Rule 1 - Bug] Fixed parsesSampleTranscriptCorrectly test assertion**

- **Found during:** Task 1 TranscriptParser tests (1 failure after parser fix)
- **Issue:** The existing `parsesSampleTranscriptCorrectly` test asserted `utterances[1].speaker == .them` for "Speaker 2". After the parser fix, "Speaker 2" correctly maps to `.named("Speaker 2")`, so the assertion was wrong.
- **Fix:** Updated assertion to `#expect(utterances[1].speaker == .named("Speaker 2"))`.
- **Files modified:** TranscriptParserTests.swift
- **Commit:** 98f1740

## Known Stubs

None -- all speaker data flows from TranscriptParser through to TranscriptView with real values.

## Threat Flags

None beyond what was already in the plan's threat model. The `rawValue` computed property added for logging only exposes speaker type strings ("you", "them", label), not transcript content.

## Verification Results

- `swift test --filter SpeakerCodableTests`: 6/6 passed
- `swift test --filter TranscriptParserTests`: 7/7 passed
- `swift build`: Build complete, no errors
- `swift test` (full suite): 31/31 passed, 0 failures

## Self-Check: PASSED

Files exist:
- PSTranscribe/Sources/PSTranscribe/Models/Models.swift -- contains `case named(String)`, `enum CodingKeys`, `singleValueContainer`
- PSTranscribe/Sources/PSTranscribe/Storage/TranscriptParser.swift -- contains `.named(speakerStr)`, old ternary removed
- PSTranscribe/Sources/PSTranscribe/Views/TranscriptView.swift -- contains `speakerTeal`, `speakerAmber`, `namedSpeakerColor`
- PSTranscribe/Tests/PSTranscribeTests/SpeakerCodableTests.swift -- 6 @Test functions

Commits exist:
- 98f1740 -- feat(08-01): add Speaker.named(String) with backward-compat Codable and fix TranscriptParser
- 91ec1af -- feat(08-01): update TranscriptView and ContentView display for .named speakers
