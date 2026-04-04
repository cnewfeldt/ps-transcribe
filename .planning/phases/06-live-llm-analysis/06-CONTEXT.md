# Phase 6: Live LLM Analysis - Context

**Gathered:** 2026-04-04
**Status:** Ready for planning

<domain>
## Phase Boundary

During a recording session, surface a live side panel with AI-generated summary, action items, and key topics that update as the conversation progresses. Panel also displays saved analysis when reviewing past sessions. Analysis results are appended to the transcript markdown file when the session ends. Ollama unavailability means no panel -- no error state, recording unaffected.

</domain>

<decisions>
## Implementation Decisions

### Panel Layout
- **D-01:** Analysis panel appears as a right-side column next to the transcript during recording -- three-column layout: Library Sidebar | Transcript | Analysis Panel
- **D-02:** Panel visibility is a manual toggle -- user clicks a button to show/hide. Not auto-shown
- **D-03:** Toggle button lives in the ControlBar, near recording controls
- **D-04:** Panel is available during live recording AND when reviewing past sessions that have saved analysis data
- **D-05:** When Ollama is not connected, the toggle button should be hidden or disabled -- no empty panel

### Update Strategy
- **D-06:** Analysis updates are triggered by utterance count threshold (e.g., every 5-10 new utterances)
- **D-07:** Minimum 30-second cooldown between analysis requests, even if utterance threshold is hit -- prevents hammering Ollama during rapid cross-talk
- **D-08:** If a generate() call is already in-flight, skip the trigger and wait for the next threshold hit after completion

### Prompt Design
- **D-09:** Single LLM call per update -- one prompt returns all three sections (summary, action items, key topics) in a structured format that gets parsed
- **D-10:** Full transcript sent with each request -- no rolling window. 16K context (OLMA-06) handles most meetings
- **D-11:** Response format should be parseable into three distinct sections for display in the panel

### Persistence
- **D-12:** Analysis results appended as `## Analysis` section at the end of the transcript markdown file when session ends
- **D-13:** Subsections: `### Summary`, `### Action Items` (with `- [ ]` checkbox format), `### Key Topics`
- **D-14:** Analysis is written once at session end using the final analysis state -- not incrementally during recording

### Claude's Discretion
- Exact utterance count threshold (5, 8, 10 -- whatever balances responsiveness with Ollama load)
- Prompt wording and structure for the LLM analysis request
- Parsing strategy for the structured LLM response
- Panel width and internal layout/styling
- How the analysis state is managed (new actor, @Observable class, etc.)
- OllamaService timeout handling for generate() calls (longer than 2s connection timeout)
- How past-session analysis is loaded for review mode display

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` -- LLMA-01 through LLMA-07

### Core Source Files
- `PSTranscribe/Sources/PSTranscribe/LLM/OllamaService.swift` -- Actor with `generate(prompt:model:)` method. 16K num_ctx, 2s connection timeout
- `PSTranscribe/Sources/PSTranscribe/LLM/OllamaState.swift` -- @Observable @MainActor bridge. Has `connectionStatus` and `refresh()`
- `PSTranscribe/Sources/PSTranscribe/LLM/OllamaModels.swift` -- OllamaGenerateRequest/Response types
- `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift` -- Main view with NavigationSplitView (sidebar + detail). Analysis panel integrates into detailView
- `PSTranscribe/Sources/PSTranscribe/Views/ControlBar.swift` -- Bottom bar with recording controls. Toggle button goes here
- `PSTranscribe/Sources/PSTranscribe/Views/TranscriptView.swift` -- Current transcript display. Will share detail area with analysis panel
- `PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift` -- @Observable + UserDefaults via didSet. May need `selectedOllamaModel` for generate calls
- `PSTranscribe/Sources/PSTranscribe/Transcription/TranscriptLogger.swift` -- Handles markdown file writing. Analysis section appended here at session end

### Patterns to Follow
- `.planning/codebase/CONVENTIONS.md` -- Naming patterns, concurrency patterns, SwiftUI patterns
- `.planning/codebase/ARCHITECTURE.md` -- Actor isolation model, @Observable patterns, data flow

### Prior Phase Context
- `.planning/phases/05-ollama-integration/05-CONTEXT.md` -- OllamaService architecture decisions, connection status patterns

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `OllamaService.generate(prompt:model:)` -- Ready to call for analysis. Returns `String` response
- `OllamaState` -- @Observable bridge with `connectionStatus` for checking Ollama availability
- `TranscriptStore.utterances` -- Live utterance array with `.count` changes observed via `.onChange` in ContentView
- `TranscriptLogger` -- Handles all markdown file I/O, including `finalizeFrontmatter()` at session end. Natural place to append analysis section
- `handleNewUtterance()` in ContentView -- Existing hook for when new utterances arrive. Could trigger analysis threshold check

### Established Patterns
- **Actor isolation:** OllamaService is a standalone actor. Analysis orchestration should follow same pattern
- **@Observable + MainActor:** OllamaState bridges actor state to SwiftUI. Analysis state needs similar bridge
- **NavigationSplitView:** ContentView uses sidebar + detail. Detail area needs to split into transcript + analysis during recording
- **`.task {}` polling loops:** ContentView has several `.task` blocks for audio level, silence timer, buffer flush. Analysis polling could follow this pattern
- **`handleNewUtterance()`:** Called on every new utterance. Natural integration point for counting toward threshold

### Integration Points
- **ContentView detailView:** Split into HStack(TranscriptView, AnalysisPanel) when panel is visible
- **ControlBar:** Add analysis panel toggle button (only visible/enabled when Ollama is connected)
- **TranscriptLogger.endSession() or finalizeFrontmatter():** Append `## Analysis` section to markdown file
- **OllamaState.connectionStatus:** Gate toggle button visibility on `.connected` status
- **AppSettings.selectedOllamaModel:** Pass to `generate(model:)` calls

</code_context>

<specifics>
## Specific Ideas

- Action items formatted as `- [ ]` checkboxes in markdown -- renders as interactive checkboxes in Obsidian
- Panel should feel like a live "meeting notes assistant" updating in the background
- Three-column layout matches the existing NavigationSplitView pattern -- sidebar | transcript | analysis

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope

</deferred>

---

*Phase: 06-live-llm-analysis*
*Context gathered: 2026-04-04*
