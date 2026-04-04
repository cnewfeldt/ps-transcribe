# Phase 6: Live LLM Analysis - Research

**Researched:** 2026-04-04
**Domain:** Swift/SwiftUI macOS -- @Observable state orchestration, actor-based async task management, LLM prompt design
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Panel Layout:**
- D-01: Analysis panel appears as a right-side column next to the transcript during recording -- three-column layout: Library Sidebar | Transcript | Analysis Panel
- D-02: Panel visibility is a manual toggle -- user clicks a button to show/hide. Not auto-shown
- D-03: Toggle button lives in the ControlBar, near recording controls
- D-04: Panel is available during live recording AND when reviewing past sessions that have saved analysis data
- D-05: When Ollama is not connected, the toggle button should be hidden or disabled -- no empty panel

**Update Strategy:**
- D-06: Analysis updates are triggered by utterance count threshold (e.g., every 5-10 new utterances)
- D-07: Minimum 30-second cooldown between analysis requests, even if utterance threshold is hit -- prevents hammering Ollama during rapid cross-talk
- D-08: If a generate() call is already in-flight, skip the trigger and wait for the next threshold hit after completion

**Prompt Design:**
- D-09: Single LLM call per update -- one prompt returns all three sections (summary, action items, key topics) in a structured format that gets parsed
- D-10: Full transcript sent with each request -- no rolling window. 16K context (OLMA-06) handles most meetings
- D-11: Response format should be parseable into three distinct sections for display in the panel

**Persistence:**
- D-12: Analysis results appended as `## Analysis` section at the end of the transcript markdown file when session ends
- D-13: Subsections: `### Summary`, `### Action Items` (with `- [ ]` checkbox format), `### Key Topics`
- D-14: Analysis is written once at session end using the final analysis state -- not incrementally during recording

### Claude's Discretion
- Exact utterance count threshold (5, 8, 10 -- whatever balances responsiveness with Ollama load)
- Prompt wording and structure for the LLM analysis request
- Parsing strategy for the structured LLM response
- Panel width and internal layout/styling
- How the analysis state is managed (new actor, @Observable class, etc.)
- OllamaService timeout handling for generate() calls (longer than 2s connection timeout)
- How past-session analysis is loaded for review mode display

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LLMA-01 | During recording, a side panel displays alongside the transcript | Layout via HStack in detailView; AnalysisPanel view toggled by @State showAnalysisPanel |
| LLMA-02 | Side panel shows live-updating summary of the conversation so far | AnalysisState.summary published via @Observable; updated by AnalysisCoordinator on threshold trigger |
| LLMA-03 | Side panel shows accumulating action items extracted from the conversation | AnalysisState.actionItems array; parsed from structured LLM response |
| LLMA-04 | Side panel shows key topics discussed | AnalysisState.keyTopics array; parsed from structured LLM response |
| LLMA-05 | LLM analysis updates periodically as new transcript chunks arrive | Utterance counter + 30s cooldown logic in ContentView; OllamaService.generate() called asynchronously |
| LLMA-06 | If Ollama is not available, recording proceeds normally without the analysis panel | Toggle button gated on ollamaState.connectionStatus == .connected; AnalysisCoordinator errors silently skipped |
| LLMA-07 | Analysis results are saved alongside the transcript when the session ends | TranscriptLogger gains appendAnalysis() method; called from stopSession() using final AnalysisState snapshot |
</phase_requirements>

---

## Summary

Phase 6 adds a live AI analysis side panel to an existing Swift 6.2 macOS app with a well-established actor/Observable concurrency model. The infrastructure is nearly complete: `OllamaService.generate(prompt:model:)` exists and works, `AppSettings.selectedOllamaModel` is persisted, and `OllamaState.connectionStatus` provides the gate. What's missing is: (1) an `AnalysisState` observable to hold summary/action items/key topics; (2) an `AnalysisCoordinator` actor to manage the threshold+cooldown trigger logic and call generate(); (3) the `AnalysisPanel` SwiftUI view; (4) a toggle button in `ControlBar`; (5) `ContentView` wiring to split the detail area and pass utterance counts; and (6) `TranscriptLogger.appendAnalysis()` for persistence.

The critical design challenge is the OllamaService URLSession timeout. The existing session uses a hard 2-second `timeoutIntervalForRequest` that is correct for `checkConnection()` and `fetchModels()`, but generate() calls for long transcripts can take 15-60+ seconds on modest hardware. The AnalysisCoordinator must use a separate URLSession configured with a longer timeout, or the `generate()` call must be overloaded to accept a timeout parameter.

The update trigger sits at `handleNewUtterance()` in ContentView -- the existing `.onChange(of: transcriptStore.utterances.count)` hook. Adding a counter increment and threshold check there is the minimal-touch integration point.

**Primary recommendation:** Introduce `AnalysisState` (@Observable @MainActor) for UI binding, `AnalysisCoordinator` (actor) for generation logic, and wire them through ContentView's existing utterance handler. Extend `OllamaService` to accept a per-call timeout to avoid hardcoding a second URLSession.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | macOS 26 SDK | Panel view, animation, state binding | Already the entire UI layer |
| Observation (Swift macro) | Swift 6.2 | @Observable for AnalysisState | Established pattern -- OllamaState, TranscriptStore both use it |
| Foundation (actors) | Swift 6.2 | AnalysisCoordinator concurrency isolation | Established pattern -- OllamaService, TranscriptLogger, SessionStore all actors |
| URLSession | macOS SDK | HTTP to Ollama localhost | Already used by OllamaService |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| NSRegularExpression | Foundation | Parse structured LLM response into sections | Same pattern as rewriteWithDiarization and TranscriptParser |
| os.Logger | macOS SDK | Structured logging for analysis errors | Established pattern -- file-level Logger per type |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| NSRegularExpression for response parsing | String.split / range(of:) | Split on known delimiters is simpler and sufficient if prompt returns exact section headers |
| Actor for AnalysisCoordinator | @Observable @MainActor class | Actor gives true isolation for the in-flight guard and cooldown timestamps; MainActor class works but requires manual reentrancy guards |

**Installation:** No new packages. All dependencies are already in Package.swift.

---

## Architecture Patterns

### Recommended File Layout

New files for this phase:

```
PSTranscribe/Sources/PSTranscribe/LLM/
  OllamaModels.swift        -- existing
  OllamaService.swift       -- existing (extend with timeout parameter)
  OllamaState.swift         -- existing
  AnalysisState.swift       -- NEW: @Observable @MainActor, holds summary/actionItems/keyTopics/isUpdating
  AnalysisCoordinator.swift -- NEW: actor, owns threshold counter, cooldown timestamp, in-flight guard, generate() call

PSTranscribe/Sources/PSTranscribe/Views/
  AnalysisPanel.swift       -- NEW: scrollable panel view, consumes AnalysisState
  ContentView.swift         -- modified: split detailView, add showAnalysisPanel state, pass coordinator
  ControlBar.swift          -- modified: add toggle button parameter
```

### Pattern 1: @Observable State Bridge (established)

`AnalysisState` follows the exact same pattern as `OllamaState` -- @Observable @MainActor final class, no actor keyword, wraps async interaction with the coordinator actor.

```swift
// Source: OllamaState.swift pattern
@Observable
@MainActor
final class AnalysisState {
    var summary: String = ""
    var actionItems: [String] = []
    var keyTopics: [String] = []
    var isUpdating: Bool = false
    var hasData: Bool { !summary.isEmpty || !actionItems.isEmpty || !keyTopics.isEmpty }
}
```

### Pattern 2: Actor for Generation Coordination (established)

`AnalysisCoordinator` follows the `OllamaService`/`TranscriptLogger`/`SessionStore` actor pattern. It owns mutable state (counter, last update time, in-flight flag) in an actor-isolated context, eliminating data races without NSLock.

```swift
// Source: OllamaService.swift pattern
actor AnalysisCoordinator {
    private let service = OllamaService()
    private var utterancesSinceLastUpdate: Int = 0
    private var lastUpdateTime: Date = .distantPast
    private var isGenerating: Bool = false

    private let utteranceThreshold = 8      // Claude's discretion: D-06
    private let cooldownSeconds: TimeInterval = 30  // D-07

    /// Called from ContentView on each new utterance. Returns analysis if threshold triggered.
    func onNewUtterance(transcript: String, model: String) async -> AnalysisResult? {
        utterancesSinceLastUpdate += 1
        guard utterancesSinceLastUpdate >= utteranceThreshold else { return nil }
        guard !isGenerating else { return nil }                        // D-08
        guard Date().timeIntervalSince(lastUpdateTime) >= cooldownSeconds else { return nil }  // D-07

        isGenerating = true
        utterancesSinceLastUpdate = 0
        lastUpdateTime = Date()

        defer { isGenerating = false }

        do {
            let response = try await service.generate(prompt: buildPrompt(transcript), model: model, timeout: 120)
            return parseAnalysisResponse(response)
        } catch {
            // Silent skip -- D-08 / LLMA-06
            return nil
        }
    }

    func reset() {
        utterancesSinceLastUpdate = 0
        lastUpdateTime = .distantPast
        isGenerating = false
    }
}
```

### Pattern 3: Timeout Override for generate()

The existing `OllamaService.generate()` uses the 2-second session timeout. This WILL time out on typical LLM calls (15-60s on llama3.2:3b / qwen3:8b). The cleanest solution consistent with the existing codebase is to add a timeout parameter to generate() and create a one-off URLSession when a longer timeout is needed:

```swift
// Extend OllamaService.generate() -- source: existing OllamaService.swift pattern
func generate(prompt: String, model: String, timeout: TimeInterval = 2.0) async throws -> String {
    let callSession: URLSession
    if timeout != 2.0 {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        callSession = URLSession(configuration: config)
    } else {
        callSession = session
    }
    // ... rest of existing generate() body using callSession
}
```

This avoids introducing a second stored URLSession on the actor and keeps the existing 2s default for connection checks and model fetches.

### Pattern 4: ContentView Integration

The utterance hook is already in place. The coordinator call goes in `handleNewUtterance()`, matching the existing `Task { }` pattern:

```swift
// Modified handleNewUtterance() in ContentView.swift
private func handleNewUtterance() {
    guard let last = transcriptStore.utterances.last else { return }
    silenceSeconds = 0

    Task {
        await transcriptLogger.append(speaker: ..., text: ..., timestamp: ...)
    }
    Task {
        await sessionStore.appendRecord(...)
    }

    // NEW: trigger analysis if panel is visible and Ollama connected
    if showAnalysisPanel, ollamaState.connectionStatus == .connected,
       !settings.selectedOllamaModel.isEmpty {
        let fullTranscript = transcriptStore.utterances.map { "\($0.speaker == .you ? "You" : "Them"): \($0.text)" }.joined(separator: "\n")
        let model = settings.selectedOllamaModel
        Task {
            analysisState.isUpdating = true
            if let result = await analysisCoordinator.onNewUtterance(transcript: fullTranscript, model: model) {
                analysisState.summary = result.summary
                analysisState.actionItems = result.actionItems
                analysisState.keyTopics = result.keyTopics
            }
            analysisState.isUpdating = false
        }
    }
}
```

### Pattern 5: DetailView Split

```swift
// In ContentView.detailView -- extends existing HStack pattern from diarization banner
if activeSessionType != nil || isRunning {
    HStack(spacing: 0) {
        TranscriptView(...)
            .frame(maxWidth: .infinity)
        if showAnalysisPanel && ollamaState.connectionStatus == .connected {
            AnalysisPanel(state: analysisState)
                .transition(.move(edge: .trailing).combined(with: .opacity))
        }
    }
    .animation(.spring(duration: 0.35, bounce: 0.15), value: showAnalysisPanel)
}
```

### Pattern 6: LLM Prompt Structure (Claude's discretion)

A structured prompt that returns clearly delimited sections is easier to parse than free-form text. Section delimiter parsing with `range(of:)` is simpler and more reliable than regex for well-structured responses:

```
Analyze this conversation transcript and respond with EXACTLY this format:

SUMMARY:
[2-3 sentence summary of the conversation]

ACTION_ITEMS:
- item 1
- item 2

KEY_TOPICS:
- topic 1
- topic 2
- topic 3

Transcript:
{transcript}
```

Parsing by splitting on `SUMMARY:`, `ACTION_ITEMS:`, `KEY_TOPICS:` delimiter strings and trimming whitespace. This approach tolerates minor LLM formatting variation better than requiring exact markdown headers.

### Pattern 7: Past-Session Analysis Loading

When a library entry is selected, `parseTranscript()` already reads the file. A new `parseAnalysis(from:)` free function in `TranscriptParser.swift` reads the same file and extracts the `## Analysis` section. Called in the same `onChange(of: selectedEntryID)` handler in ContentView, setting `loadedAnalysis` state alongside `loadedUtterances`. The `AnalysisPanel` renders this when `activeSessionType == nil`.

### Anti-Patterns to Avoid

- **Sharing the 2-second URLSession for generate() calls:** Will reliably time out on first real LLM call. Must use a longer timeout for generate().
- **Storing isGenerating on AnalysisState (@MainActor) instead of AnalysisCoordinator (actor):** Creates a race condition where multiple Task { } blocks can see isGenerating=false simultaneously before any sets it to true. The actor's serial execution guarantees only one trigger proceeds.
- **Calling generate() directly from the MainActor (ContentView):** Blocks the main thread during the LLM call even with async/await if the continuation resumes on MainActor. Route through the coordinator actor.
- **Writing analysis to disk incrementally:** D-14 explicitly prohibits this. Write once at session end from the final state.
- **Showing an error state in the panel when Ollama times out:** LLMA-06 and CONTEXT.md both say silent skip. Don't surface errors in the panel.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Timeout for LLM generate calls | Custom retry/timeout wrapper | URLSessionConfiguration.timeoutIntervalForRequest on a per-call URLSession | URLSession handles task cancellation cleanly; retry logic is not required (silent skip on error) |
| Thread-safe mutable state for counter/cooldown | NSLock wrapper | actor keyword | Already established pattern in this codebase; actors are Swift 6 idiomatic |
| Response section parsing | Full JSON schema / structured output / streaming | String delimiter parsing on known section headers | Ollama's non-streaming generate is already used; delimiter parsing is 10 lines and sufficient |
| Animation for panel slide-in | Custom UIKit/AppKit transition | `.transition(.move(edge: .trailing).combined(with: .opacity))` + `.animation(.spring(...))` | Matches existing ControlBar animation pattern already in place |

**Key insight:** The project already has all infrastructure needed. This phase is orchestration and UI, not new infrastructure.

---

## Common Pitfalls

### Pitfall 1: OllamaService 2-Second Timeout Kills Every generate() Call
**What goes wrong:** `OllamaService.generate()` uses the same `URLSession` as `checkConnection()` and `fetchModels()`, which has `timeoutIntervalForRequest = 2.0`. LLM inference on llama3.2:3b takes 10-60 seconds. Every generate() call times out immediately.
**Why it happens:** The 2-second timeout was set for OLMA-05 (connection checks must never block). `generate()` was added to the same actor and reuses the same session.
**How to avoid:** Add a `timeout` parameter to `generate()` (default 2.0 for existing callers). Create a per-call URLSession with the specified timeout inside the method. Use 120 seconds for analysis calls.
**Warning signs:** `URLError.timedOut` in test logs within 2 seconds of any generate() call.

### Pitfall 2: MainActor Reentrancy on isGenerating Flag
**What goes wrong:** Storing `isGenerating` on `AnalysisState` (@MainActor) and checking it in a Task { } closure. Multiple tasks see `isGenerating = false` before any sets it to `true` because they're all queued on MainActor.
**Why it happens:** Async Task closures on MainActor interleave at `await` points. The check-and-set is not atomic.
**How to avoid:** Store `isGenerating`, counter, and lastUpdateTime exclusively inside `AnalysisCoordinator` (actor). Actor serial execution makes check-and-set atomic.
**Warning signs:** Multiple simultaneous generate() calls firing at the same utterance count.

### Pitfall 3: Transcript Serialization for Prompt Is Slow
**What goes wrong:** Building the full transcript string from `transcriptStore.utterances` (potentially hundreds of entries) on every utterance trigger, even when the threshold isn't met.
**Why it happens:** Naive implementation builds the string in `handleNewUtterance()` before the threshold check.
**How to avoid:** Move transcript serialization inside `AnalysisCoordinator.onNewUtterance()` -- only build the string after the threshold/cooldown/in-flight checks pass. Pass the `[Utterance]` array or a pre-formatted string only when generation is actually going to happen.
**Warning signs:** UI lag on every new utterance when session has 100+ utterances.

### Pitfall 4: Analysis Written to Disk When No Analysis Was Generated
**What goes wrong:** `appendAnalysis()` in TranscriptLogger writes a skeleton `## Analysis` section even when `AnalysisState` is empty (Ollama unavailable, session too short).
**Why it happens:** Unconditional call at session end.
**How to avoid:** Guard on `analysisState.hasData` before calling `appendAnalysis()`. If no data, omit the section entirely (UI-SPEC: "If no analysis was generated... the ## Analysis section is omitted entirely").
**Warning signs:** Transcript files containing empty `## Analysis` sections.

### Pitfall 5: Past-Session Analysis Not Loading in Review Mode
**What goes wrong:** Panel shows empty state when reviewing a past session that has saved analysis, because the analysis-loading code path isn't triggered on `selectedEntryID` change.
**Why it happens:** The `onChange(of: selectedEntryID)` handler only calls `parseTranscript()`. No parallel call to `parseAnalysis()`.
**How to avoid:** Add `loadedAnalysis` state to ContentView. In the `onChange(of: selectedEntryID)` handler, call both `parseTranscript()` and `parseAnalysis()`. Pass `loadedAnalysis` to `AnalysisPanel` when `activeSessionType == nil`.
**Warning signs:** Panel shows empty state for past sessions, even when the file contains `## Analysis`.

### Pitfall 6: ControlBar Toggle Button Requires OllamaState Access
**What goes wrong:** ControlBar currently takes all state as value-type parameters. Adding `ollamaState.connectionStatus` as a direct dependency requires passing it or restructuring.
**Why it happens:** ControlBar is a stateless view receiving all its inputs as let properties.
**How to avoid:** Add `isOllamaConnected: Bool` and `showAnalysisPanel: Bool` and `onToggleAnalysis: () -> Void` parameters to ControlBar. ContentView computes `isOllamaConnected` from `ollamaState.connectionStatus == .connected` and passes it in. Maintains the existing pass-through pattern.
**Warning signs:** Attempting to pass `OllamaState` or `@Environment` into ControlBar.

---

## Code Examples

### AnalysisResult value type

```swift
// New type in AnalysisCoordinator.swift or AnalysisState.swift
struct AnalysisResult: Sendable {
    let summary: String
    let actionItems: [String]
    let keyTopics: [String]
}
```

### Response parsing (delimiter-based)

```swift
// Inside AnalysisCoordinator -- Claude's discretion, D-11
private func parseAnalysisResponse(_ response: String) -> AnalysisResult {
    func extractSection(after marker: String, before nextMarker: String) -> String {
        guard let start = response.range(of: marker)?.upperBound else { return "" }
        let fromStart = String(response[start...])
        if let end = fromStart.range(of: nextMarker)?.lowerBound {
            return String(fromStart[..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return fromStart.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    let summaryText = extractSection(after: "SUMMARY:", before: "ACTION_ITEMS:")
    let actionBlock = extractSection(after: "ACTION_ITEMS:", before: "KEY_TOPICS:")
    let topicsBlock = extractSection(after: "KEY_TOPICS:", before: "\0")

    let items = actionBlock
        .components(separatedBy: "\n")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { $0.hasPrefix("- ") }
        .map { String($0.dropFirst(2)) }
        .filter { !$0.isEmpty }

    let topics = topicsBlock
        .components(separatedBy: "\n")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { $0.hasPrefix("- ") }
        .map { String($0.dropFirst(2)) }
        .filter { !$0.isEmpty }

    return AnalysisResult(summary: summaryText, actionItems: items, keyTopics: topics)
}
```

### TranscriptLogger.appendAnalysis()

```swift
// New method on actor TranscriptLogger
func appendAnalysis(summary: String, actionItems: [String], keyTopics: [String]) {
    guard !summary.isEmpty || !actionItems.isEmpty || !keyTopics.isEmpty else { return }
    guard let filePath = lastSessionFilePath else { return }

    var content = "\n## Analysis\n\n### Summary\n\n\(summary)\n\n### Action Items\n\n"
    for item in actionItems {
        content += "- [ ] \(item)\n"
    }
    content += "\n### Key Topics\n\n"
    content += keyTopics.joined(separator: ", ")
    content += "\n"

    // Append to file -- open in append mode, write, close
    if let handle = try? FileHandle(forWritingAtPath: filePath.path) {
        handle.seekToEndOfFile()
        if let data = content.data(using: .utf8) {
            handle.write(data)
        }
        try? handle.close()
    }
}
```

### parseAnalysis() free function (for review mode)

```swift
// New function in TranscriptParser.swift -- mirrors parseTranscript() pattern
func parseAnalysis(at url: URL) -> AnalysisResult? {
    guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
    guard content.contains("## Analysis") else { return nil }
    // Extract ## Analysis section, then parse sub-sections
    // ... same delimiter-based extraction as AnalysisCoordinator
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Timer-based polling for LLM updates | Utterance-count threshold + cooldown | N/A (new design) | No unnecessary calls; naturally responsive to conversation pace |
| Streaming LLM responses (token by token) | Non-streaming generate (stream: false) | N/A (existing OllamaService design) | Simpler parsing; entire response arrives at once; no partial-render complexity |

**Not applicable for this phase:** No deprecated APIs, no library migrations.

---

## Open Questions

1. **OllamaState is instantiated at App level, but ContentView currently doesn't have access to it**
   - What we know: From STATE.md -- "OllamaState instantiated at PSTranscribeApp App level and passed to Settings scene". ContentView currently receives `AppSettings` via `@Bindable` but not `OllamaState`.
   - What's unclear: Does OllamaState need to be passed to ContentView as a parameter, or injected via `@Environment`?
   - Recommendation: Pass as a parameter matching the existing AppSettings pattern (`@Bindable var ollamaState: OllamaState`). Verify PSTranscribeApp.swift passes it -- this is a task 0 investigation step.

2. **generate() timeout for very large transcripts**
   - What we know: 16K context, full transcript per request (D-10). 120s covers most models at 3B-8B parameters on Apple Silicon.
   - What's unclear: Whether 120s is sufficient for an 8B model on a slower Mac.
   - Recommendation: Use 120s as the default for analysis calls. Silent failure on timeout means a too-slow machine just doesn't get updates -- acceptable per LLMA-06.

---

## Environment Availability

Step 2.6: SKIPPED (no new external dependencies -- Ollama already probed by OllamaState.refresh() at runtime; URLSession is an OS framework; no new CLI tools or databases required).

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Swift Testing (swift-testing, built into Swift 6.2) |
| Config file | Package.swift testTarget "PSTranscribeTests" |
| Quick run command | `swift test --filter PSTranscribeTests 2>&1` (from PSTranscribe/ directory) |
| Full suite command | `swift test 2>&1` (from PSTranscribe/ directory) |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LLMA-05 (threshold) | AnalysisCoordinator fires after N utterances | unit | `swift test --filter AnalysisCoordinatorTests 2>&1` | No -- Wave 0 |
| LLMA-05 (cooldown) | AnalysisCoordinator respects 30s cooldown | unit | `swift test --filter AnalysisCoordinatorTests 2>&1` | No -- Wave 0 |
| LLMA-05 (in-flight guard) | AnalysisCoordinator skips if generate() in-flight | unit | `swift test --filter AnalysisCoordinatorTests 2>&1` | No -- Wave 0 |
| LLMA-07 (persistence) | appendAnalysis writes ## Analysis section | unit | `swift test --filter TranscriptLoggerAnalysisTests 2>&1` | No -- Wave 0 |
| LLMA-07 (empty guard) | appendAnalysis omits section if no data | unit | `swift test --filter TranscriptLoggerAnalysisTests 2>&1` | No -- Wave 0 |
| LLMA-06 | No error state when Ollama unavailable | manual | Disconnect Ollama, verify panel hidden/absent | N/A |
| LLMA-01..04 | Panel displays correct sections | manual | Visual inspection during recording | N/A |
| D-09 (parsing) | parseAnalysisResponse extracts all three sections | unit | `swift test --filter AnalysisCoordinatorTests 2>&1` | No -- Wave 0 |
| past-session | parseAnalysis reads ## Analysis from saved file | unit | `swift test --filter TranscriptParserTests 2>&1` | Partial -- file exists, new test needed |
| timeout | generate() with 120s timeout does not use 2s session | unit | `swift test --filter OllamaServiceTests 2>&1` | Partial -- file exists, new test needed |

### Sampling Rate
- **Per task commit:** `swift test --filter AnalysisCoordinatorTests 2>&1`
- **Per wave merge:** `swift test 2>&1`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `Tests/PSTranscribeTests/AnalysisCoordinatorTests.swift` -- threshold, cooldown, in-flight guard, response parsing (LLMA-05, D-08, D-09)
- [ ] `Tests/PSTranscribeTests/TranscriptLoggerAnalysisTests.swift` -- appendAnalysis output, empty-state guard (LLMA-07, D-14)
- [ ] New tests in existing `Tests/PSTranscribeTests/OllamaServiceTests.swift` -- generate() timeout parameter behavior
- [ ] New tests in existing `Tests/PSTranscribeTests/TranscriptParserTests.swift` -- parseAnalysis() from file with ## Analysis section

---

## Sources

### Primary (HIGH confidence)
- Codebase direct inspection: `OllamaService.swift`, `OllamaState.swift`, `ContentView.swift`, `ControlBar.swift`, `TranscriptLogger.swift`, `AppSettings.swift`, `TranscriptParser.swift`, `OllamaModels.swift`
- `CONVENTIONS.md` -- naming, concurrency patterns, error handling patterns
- `ARCHITECTURE.md` -- actor isolation model, data flow, @Observable patterns
- `06-CONTEXT.md` -- all locked decisions D-01 through D-14
- `06-UI-SPEC.md` -- component structure, state machine, animation specs, persistence contract
- `REQUIREMENTS.md` -- LLMA-01 through LLMA-07

### Secondary (MEDIUM confidence)
- Apple Swift 6.2 actor model documentation (known from training, consistent with codebase patterns observed)
- URLSessionConfiguration timeout behavior (standard Foundation API, HIGH confidence from direct usage in existing OllamaService)

### Tertiary (LOW confidence)
- LLM inference timing estimates (15-60s range) -- based on general knowledge of llama3.2:3b / qwen3:8b on Apple Silicon; actual timing varies by hardware

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- entirely existing project dependencies, no new packages
- Architecture patterns: HIGH -- verified against actual source files; all patterns have precedents in existing code
- Pitfalls: HIGH for timeout (directly observed in source), MEDIUM for others (logical analysis of Swift 6 concurrency model)
- Prompt design: MEDIUM -- delimiter parsing is the correct approach but exact prompt wording is discretionary

**Research date:** 2026-04-04
**Valid until:** 2026-05-04 (stable stack; only risk is Ollama API changes)
