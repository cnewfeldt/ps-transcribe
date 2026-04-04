# Phase 5: Ollama Integration - Context

**Gathered:** 2026-04-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Detect and connect to a local Ollama instance, expose its downloaded models for selection, and provide a stable decoupled LLM service actor that Phase 6 (Live LLM Analysis) will consume. No in-app model downloading -- users manage models via `ollama pull` in their terminal. Ollama is fully optional and never blocks recording.

</domain>

<decisions>
## Implementation Decisions

### Connection & Detection
- **D-01:** Connect to localhost:11434 only -- no configurable URL, no OLLAMA_HOST env var fallback
- **D-02:** On-demand status checks only -- check when Settings opens or when a recording starts. No background polling
- **D-03:** When Ollama is unavailable, show status indicator only ("Not found" / "Not running") -- no install hints, no action buttons
- **D-04:** Recording is never blocked by Ollama availability -- transcription pipeline operates identically with or without Ollama

### Settings UI
- **D-05:** Ollama section placed after Audio Input section in SettingsView (groups input sources together)
- **D-06:** Section contains: connection status indicator + model picker dropdown to select which downloaded model to use
- **D-07:** Status indicator is a colored dot + text: green dot + "Connected" / red dot + "Not running" / gray dot + "Not found"
- **D-08:** Model browsing/pulling happens in a separate sheet opened via a "Browse Models" button in the Ollama section

### Model Management
- **D-09:** Browse sheet shows only locally downloaded models (from `GET /api/tags`) -- no remote library browsing
- **D-10:** No in-app model pulling -- users manage downloads via `ollama pull` CLI. OLMA-04 descoped to "select from downloaded models"
- **D-11:** App recommends a specific model for analysis (e.g., llama3.2:3b) -- suggested as default selection when models are available

### Service Architecture
- **D-12:** Single `OllamaService` actor -- owns HTTP communication, connection state, and exposes clean async API for Phase 6
- **D-13:** OllamaService lives in new `LLM/` directory: `PSTranscribe/Sources/PSTranscribe/LLM/OllamaService.swift`
- **D-14:** Standalone actor (not @MainActor) -- network I/O stays off main thread. UI reads state via async properties or @Observable wrapper
- **D-15:** Selected model name persists via AppSettings with UserDefaults didSet pattern (new `selectedOllamaModel` property)

### Claude's Discretion
- HTTP client implementation details (URLSession vs other)
- Exact error types and error handling patterns within OllamaService
- Model recommendation choice (specific model name for default suggestion)
- @Observable wrapper pattern for bridging standalone actor state to SwiftUI

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` -- OLMA-01 through OLMA-06 (note: OLMA-04 descoped per D-10)

### Core Source Files
- `PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift` -- @Observable + UserDefaults via didSet pattern. Add `selectedOllamaModel` here
- `PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift` -- Form with .formStyle(.grouped). Add Ollama section after Audio Input
- `PSTranscribe/Sources/PSTranscribe/Transcription/TranscriptionEngine.swift` -- Central coordinator. OllamaService should NOT be embedded here -- separate actor

### Patterns to Follow
- `.planning/codebase/CONVENTIONS.md` -- Naming patterns, concurrency patterns, SwiftUI patterns
- `.planning/codebase/ARCHITECTURE.md` -- Actor isolation model, @Observable patterns, data flow

### Prior Phase Context
- `.planning/phases/04-mic-button-model-onboarding/04-CONTEXT.md` -- Model download progress pattern (OnboardingView), error aggregation pattern (activeErrors)
- `.planning/phases/02-security-stability/02-CONTEXT.md` -- os.Logger pattern, error handling standards

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `OnboardingView` progress pattern -- informs how model browse sheet could display download state (though in-app pull is descoped)
- `AppSettings` UserDefaults via didSet -- exact pattern for `selectedOllamaModel` persistence
- `os.Logger(subsystem: "com.pstranscribe.app", category: "OllamaService")` -- logging pattern

### Established Patterns
- **Actor isolation:** SessionStore, TranscriptLogger are standalone actors for I/O. OllamaService follows this pattern
- **@Observable + MainActor:** TranscriptionEngine, TranscriptStore, AppSettings. May need a MainActor @Observable wrapper to bridge OllamaService state to SwiftUI
- **UserDefaults via didSet:** AppSettings syncs all preferences this way
- **Form sections:** SettingsView uses `Section("Title") { ... }` with `.formStyle(.grouped)`
- **2-second timeout:** OLMA-05 requirement -- all Ollama HTTP requests must timeout at 2s

### Integration Points
- **SettingsView:** Add Section("Ollama") after Section("Audio Input") with status dot, model picker, browse button
- **AppSettings:** Add `selectedOllamaModel: String` with UserDefaults persistence
- **New directory:** `PSTranscribe/Sources/PSTranscribe/LLM/` for OllamaService.swift and related types
- **Phase 6 surface:** OllamaService exposes async methods (e.g., `generate(prompt:model:)`) that Phase 6's analysis panel will call

</code_context>

<specifics>
## Specific Ideas

No specific requirements -- open to standard approaches guided by the decisions above.

</specifics>

<deferred>
## Deferred Ideas

- **In-app model pulling** -- OLMA-04 descoped from this phase. Could be re-added as a future enhancement if users find CLI-only pull too cumbersome
- **Configurable Ollama URL** -- Supporting remote Ollama instances or non-standard ports. Could be added later if requested
- **Model size/parameter display** -- Showing model metadata (parameter count, quantization, size) in the browse sheet. Nice-to-have for future iteration

</deferred>

---

*Phase: 05-ollama-integration*
*Context gathered: 2026-04-03*
