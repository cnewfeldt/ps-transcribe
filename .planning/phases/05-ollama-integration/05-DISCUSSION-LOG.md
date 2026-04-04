# Phase 5: Ollama Integration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-04-03
**Phase:** 05-ollama-integration
**Areas discussed:** Connection & detection, Settings UI, Model management, Service architecture

---

## Connection & Detection

### Discovery Method

| Option | Description | Selected |
|--------|-------------|----------|
| Localhost default only | Always connect to localhost:11434. Simple, covers 99% of users. | ✓ |
| Configurable URL | Default to localhost:11434 but allow custom URL in Settings. | |
| Auto-detect + configurable | Try localhost, fall back to OLLAMA_HOST env var, plus manual override. | |

**User's choice:** Localhost default only
**Notes:** None

### Polling Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| On-demand only | Check when Settings opens or recording starts. No background polling. | ✓ |
| Periodic background poll | Check every 30-60s in background. | |
| On-demand + event-driven | Check on Settings open / recording start, plus re-check on failure. | |

**User's choice:** On-demand only
**Notes:** None

### Unavailable State Display

| Option | Description | Selected |
|--------|-------------|----------|
| Status indicator only | Show 'Not found' or 'Not running' in Settings. No prompts or install links. | ✓ |
| Status + install hint | Status plus 'Install Ollama at ollama.com' text. | |
| Status + action button | Status plus 'Get Ollama' button opening ollama.com. | |

**User's choice:** Status indicator only
**Notes:** None

### Recording Gating

| Option | Description | Selected |
|--------|-------------|----------|
| Never block | Recording always works. Ollama is optional. | ✓ |
| Warn but allow | Show brief warning that LLM features won't be available, then proceed. | |

**User's choice:** Never block
**Notes:** None

---

## Settings UI

### Section Placement

| Option | Description | Selected |
|--------|-------------|----------|
| After Audio Input | Groups input sources together. Logical flow before Privacy. | ✓ |
| At the bottom | After Updates. Keeps it as an 'advanced' feature. | |
| At the top | Before Output Folders. Makes Ollama prominent. | |

**User's choice:** After Audio Input
**Notes:** None

### Section Content

| Option | Description | Selected |
|--------|-------------|----------|
| Status + model picker | Connection status indicator plus picker to select which model to use. | ✓ |
| Status only | Just connection status. Model selection elsewhere. | |
| Status + model picker + model browser | Status, picker, AND inline model browser within Settings. | |

**User's choice:** Status + model picker
**Notes:** None

### Status Indicator Style

| Option | Description | Selected |
|--------|-------------|----------|
| Colored dot + text | Green/red/gray dot with status text. Matches minimal UI style. | ✓ |
| Icon + text | SF Symbol icons with status text. More visually distinct. | |
| You decide | Claude picks based on existing UI patterns. | |

**User's choice:** Colored dot + text
**Notes:** None

### Model Browser Location

| Option | Description | Selected |
|--------|-------------|----------|
| Separate sheet/modal | 'Browse Models' button opens sheet with available models. Keeps Settings clean. | ✓ |
| Inline expandable | Disclosure group in Settings that expands to show models. | |
| Dedicated window | Separate window for model management. | |

**User's choice:** Separate sheet/modal
**Notes:** None

---

## Model Management

### Model List Source

| Option | Description | Selected |
|--------|-------------|----------|
| Live from Ollama API | Fetch available models from Ollama's library API. | |
| Curated list + custom | Hand-picked recommended models plus text field for custom names. | |
| Downloaded only | Only show models already downloaded locally. User pulls via CLI. | ✓ |

**User's choice:** Downloaded only
**Notes:** Users manage model downloads via `ollama pull` in terminal. App just selects from what's available.

### Model Recommendation

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, suggest one | Recommend a good general-purpose model for meeting analysis. | ✓ |
| No recommendation | Show all models equally. | |
| You decide | Claude picks best approach. | |

**User's choice:** Yes, suggest one
**Notes:** None

### Scope Confirmation (OLMA-03/OLMA-04)

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, local only | Browse = list downloaded. No in-app pull. | ✓ |
| Local + pull capability | Browse local AND allow pulling from app. | |
| Let me explain | Different idea for model management. | |

**User's choice:** Yes, local only
**Notes:** OLMA-04 effectively descoped -- no in-app model pulling

### Download Progress

| Option | Description | Selected |
|--------|-------------|----------|
| Skip -- no in-app pull | Consistent with downloaded-only choice. No progress UI needed. | ✓ |
| Progress bar in sheet | If pull is kept, progress bar per model in browse sheet. | |
| You decide | Claude picks based on scope decision. | |

**User's choice:** Skip -- no in-app pull
**Notes:** None

---

## Service Architecture

### Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Single OllamaService actor | One actor owning HTTP, state, and async API for Phase 6. | ✓ |
| Split: Client + Service | Thin OllamaClient (HTTP) + OllamaService (state). More separation. | |
| You decide | Claude picks based on codebase patterns. | |

**User's choice:** Single OllamaService actor
**Notes:** None

### Source Tree Location

| Option | Description | Selected |
|--------|-------------|----------|
| New LLM/ directory | PSTranscribe/Sources/PSTranscribe/LLM/OllamaService.swift | ✓ |
| In Transcription/ | Alongside TranscriptionEngine. | |
| In Models/ | With other data types. | |

**User's choice:** New LLM/ directory
**Notes:** None

### Actor Isolation

| Option | Description | Selected |
|--------|-------------|----------|
| Standalone actor | Own executor. Network I/O off main thread. | ✓ |
| @MainActor | Simpler SwiftUI binding but network calls need detaching. | |
| You decide | Claude picks based on concurrency patterns. | |

**User's choice:** Standalone actor
**Notes:** None

### Model Persistence

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, via AppSettings | Add selectedOllamaModel to AppSettings with UserDefaults didSet. | ✓ |
| Yes, separate storage | Own UserDefaults key managed by OllamaService. | |
| No persistence | User selects each session. | |

**User's choice:** Yes, via AppSettings
**Notes:** None

---

## Claude's Discretion

- HTTP client implementation details
- Error types and handling patterns within OllamaService
- Model recommendation choice (specific model name)
- @Observable wrapper for bridging actor state to SwiftUI

## Deferred Ideas

- In-app model pulling (OLMA-04 descoped)
- Configurable Ollama URL for remote instances
- Model metadata display (parameter count, quantization, size)
