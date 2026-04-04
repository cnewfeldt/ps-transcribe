---
phase: 06-live-llm-analysis
plan: 01
subsystem: LLM / live analysis
tags: [ollama, analysis, actor, tdd, swift-testing]
requires:
  - OllamaService actor (Phase 05)
  - OllamaGenerateRequest / OllamaGenerateResponse models (Phase 05)
provides:
  - AnalysisState @Observable @MainActor bridge
  - AnalysisResult Sendable struct
  - AnalysisCoordinator actor (threshold + cooldown + in-flight guard)
  - OllamaService.generate(prompt:model:timeout:) overload
affects:
  - PSTranscribe/Sources/PSTranscribe/LLM/OllamaService.swift
tech-stack:
  added: []
  patterns:
    - Actor with private(set) properties for test observability
    - Ephemeral URLSession for per-call timeout tuning
key-files:
  created:
    - PSTranscribe/Sources/PSTranscribe/LLM/AnalysisState.swift
    - PSTranscribe/Sources/PSTranscribe/LLM/AnalysisCoordinator.swift
    - PSTranscribe/Tests/PSTranscribeTests/AnalysisCoordinatorTests.swift
  modified:
    - PSTranscribe/Sources/PSTranscribe/LLM/OllamaService.swift
    - PSTranscribe/Tests/PSTranscribeTests/OllamaServiceTests.swift
decisions:
  - "AnalysisCoordinator exposes utterancesSinceLastUpdate, lastUpdateTime, isGenerating as private(set) -- lets tests observe state transitions without adding a protocol or test-only accessor"
  - "Used default-parameter overload func generate(prompt:model:timeout:TimeInterval = 2.0) rather than a second function -- backward compatible with all existing call sites while keeping one canonical implementation"
  - "When timeout != 2.0, AnalysisCoordinator gets a fresh ephemeral URLSession per call rather than mutating the long-lived health-check session -- avoids leaking analysis timeouts into future connection checks"
  - "parseAnalysisResponse treats the literal string 'None' (case-insensitive) as an empty list rather than a parse failure, matching the prompt's instructions to the model"
  - "Executed Task 2 (OllamaService timeout) before Task 1 (AnalysisCoordinator) because the coordinator's generate() call site depends on the new timeout parameter -- deviation tracked below"
metrics:
  duration_minutes: 3
  tasks_completed: 2
  files_created: 3
  files_modified: 2
  tests_added: 12
  tests_passing: 19
  completed: 2026-04-04
---

# Phase 06 Plan 01: Analysis Coordination Engine Summary

## One-liner

AnalysisCoordinator actor with 8-utterance threshold, 30s cooldown, in-flight guard, plus an OllamaService.generate() timeout overload -- the brain of the live LLM analysis feature.

## What Was Built

### AnalysisState.swift

`@Observable @MainActor` bridge so SwiftUI can render live analysis results without crossing actor boundaries on reads. Holds `summary`, `actionItems`, `keyTopics`, `isUpdating`, plus a computed `hasData` flag. `apply(_:)` writes a result atomically and `clear()` resets everything for session restart. `AnalysisResult` is a `Sendable` struct so the actor can return it across isolation domains.

### AnalysisCoordinator.swift

Actor that owns the decision logic for when to call Ollama:

- `utteranceThreshold = 8` (D-06) -- minimum new utterances before firing
- `cooldownSeconds = 30` (D-07) -- wall-clock gap between successful triggers
- `isGenerating` guard (D-08) -- never overlap generate() calls
- `generateTimeout = 120` -- Ollama call budget, far longer than the 2s health-check default

`onNewUtterance(transcript:model:)` increments the counter, checks all three gates, and only then calls `service.generate(...)`. On success it parses the delimited response and returns an `AnalysisResult`. On failure it logs a warning and returns `nil` per LLMA-06 (silent-fail -- recording continues unperturbed).

`buildPrompt(_:)` produces the literal `SUMMARY:` / `ACTION_ITEMS:` / `KEY_TOPICS:` format. `parseAnalysisResponse(_:)` extracts each section with a range-based helper and parses the list blocks by filtering `- ` prefixed lines and dropping literal "None" entries. Both are non-private so tests can exercise them directly without network.

### OllamaService.generate(prompt:model:timeout:) overload

Added a default-parameter `timeout: TimeInterval = 2.0`. When the caller passes anything other than `2.0`, the method builds a fresh ephemeral `URLSessionConfiguration` with the requested timeout; otherwise it falls through to the existing shared 2s session. Zero behavior change for existing call sites.

### Tests

**AnalysisCoordinatorTests.swift (10 @Test cases):**

- `onNewUtteranceReturnsNilBelowThreshold` -- 7 calls all return nil, counter reaches 7
- `resetClearsAllState` -- counter, lastUpdateTime, isGenerating all cleared
- `parseAnalysisResponseExtractsSummary`
- `parseAnalysisResponseExtractsActionItems`
- `parseAnalysisResponseExtractsKeyTopics`
- `parseAnalysisResponseHandlesNoneSections`
- `parseAnalysisResponseHandlesMissingSections`
- `buildPromptIncludesAllMarkers`
- `analysisStateAppliesResult` (+hasData flip)
- `analysisStateClearResetsAll`

**OllamaServiceTests.swift (2 new @Test cases):**

- `testGenerateTimeoutAcceptsCustomValue`
- `testGenerateDefaultTimeoutStillUsesTwoSeconds`

## Test Results

```
Test run with 19 tests in 2 suites passed after 0.030 seconds.
```

Filter: `swift test --filter "AnalysisCoordinatorTests|OllamaServiceTests"` (parallel executor 06-02 owns other test files still in flight during the wave).

## Commits

| Task | Commit  | Message                                                                  |
| ---- | ------- | ------------------------------------------------------------------------ |
| 2    | 51f64a5 | feat(06-01): add timeout parameter to OllamaService.generate()           |
| 1    | eeae3b1 | feat(06-01): add AnalysisState, AnalysisResult, and AnalysisCoordinator actor |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking dependency] Executed Task 2 before Task 1**

- **Found during:** Task 1 RED/GREEN phase
- **Issue:** Task 1's `AnalysisCoordinator` calls `service.generate(prompt:model:timeout:120)`, but the `timeout:` parameter is introduced by Task 2. Committing Task 1 first would have produced a non-building commit.
- **Fix:** Reordered execution -- ran Task 2 (OllamaService timeout) to completion first, committed it, then ran Task 1. TDD cycle preserved for both tasks independently (RED -> GREEN -> verify).
- **Files modified:** same as plan -- only execution order changed.
- **Commits:** 51f64a5 (Task 2), eeae3b1 (Task 1).

No other deviations. Both tasks implemented exactly as specified in the plan.

## Authentication Gates

None. Plan is pure source / test work; no auth required.

## Deferred Issues

None.

## Known Stubs

None. All new code is fully wired. The coordinator is not yet invoked from the recording session loop -- that integration is owned by Plan 06-03, which is explicitly noted in the phase plan as the wiring step.

## Parallel Execution Note

This plan ran as a parallel executor alongside plan 06-02 (TranscriptLogger.appendAnalysis + TranscriptParser.parseAnalysis). Scope was strictly limited to LLM/ and the two test files listed in the plan frontmatter. Commits used `--no-verify` per the parallel protocol; full hook validation will run once the wave completes.

## Self-Check: PASSED

Files verified on disk:

- FOUND: PSTranscribe/Sources/PSTranscribe/LLM/AnalysisState.swift
- FOUND: PSTranscribe/Sources/PSTranscribe/LLM/AnalysisCoordinator.swift
- FOUND: PSTranscribe/Tests/PSTranscribeTests/AnalysisCoordinatorTests.swift
- FOUND: PSTranscribe/Sources/PSTranscribe/LLM/OllamaService.swift (modified)
- FOUND: PSTranscribe/Tests/PSTranscribeTests/OllamaServiceTests.swift (modified)

Commits verified in git log:

- FOUND: 51f64a5 feat(06-01): add timeout parameter to OllamaService.generate()
- FOUND: eeae3b1 feat(06-01): add AnalysisState, AnalysisResult, and AnalysisCoordinator actor
