# Architecture Research

**Domain:** macOS native transcription app with local LLM integration
**Researched:** 2026-03-31
**Confidence:** HIGH (existing codebase inspected, Ollama API verified against official docs and ollama-swift library)

## Standard Architecture

### System Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                        Presentation Layer                         │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────────┐  │
│  │ ContentView │  │ LibraryView  │  │    InsightsPanel       │  │
│  │ (session    │  │ (grid of     │  │  (live LLM output      │  │
│  │  lifecycle) │  │  past        │  │   during recording)    │  │
│  │             │  │  sessions)   │  │                        │  │
│  └──────┬──────┘  └──────┬───────┘  └──────────┬─────────────┘  │
│         │                │                      │                │
├─────────┴────────────────┴──────────────────────┴────────────────┤
│                        State Layer (@Observable, @MainActor)      │
│  ┌────────────────┐  ┌──────────────────┐  ┌──────────────────┐ │
│  │ TranscriptStore│  │  OllamaService   │  │  SessionLibrary  │ │
│  │ (utterances,   │  │  (@Observable    │  │  (@Observable    │ │
│  │  volatile text)│  │   status, chunks)│  │   session list)  │ │
│  └────────┬───────┘  └────────┬─────────┘  └────────┬─────────┘ │
│           │                   │                      │           │
├───────────┴───────────────────┴──────────────────────┴───────────┤
│                      Service / Engine Layer                       │
│  ┌────────────────┐  ┌──────────────────┐  ┌──────────────────┐ │
│  │TranscriptionEng│  │  OllamaClient    │  │ SessionIndexActor│ │
│  │  (MainActor)   │  │  (actor, HTTP +  │  │  (actor, JSONL   │ │
│  │                │  │   async stream)  │  │   index on disk) │ │
│  └────────┬───────┘  └────────┬─────────┘  └────────┬─────────┘ │
│           │                   │                      │           │
├───────────┴───────────────────┴──────────────────────┴───────────┤
│                      Infrastructure Layer                         │
│  ┌──────────────────────┐  ┌────────────────────────────────┐   │
│  │  Audio + FluidAudio  │  │  File System (vault + index)   │   │
│  │  (MicCapture,        │  │  (TranscriptLogger,            │   │
│  │   SystemAudioCapture,│  │   SessionStore,                │   │
│  │   StreamingTranscrib)│  │   SessionIndexActor)           │   │
│  └──────────────────────┘  └────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Communicates With |
|-----------|----------------|-------------------|
| `ContentView` | Session lifecycle, top-level layout, split-view toggle | `TranscriptStore`, `TranscriptionEngine`, `OllamaService`, `TranscriptLogger`, `SessionStore` |
| `InsightsPanel` | Display streaming LLM chunks during recording; show summary/actions/topics | `OllamaService` (read-only) |
| `LibraryView` | Grid of past sessions, missing-file detection, Obsidian deep links | `SessionLibrary` (read-only) |
| `TranscriptStore` | MainActor-isolated live utterances + volatile text | `TranscriptionEngine` writes; Views read |
| `OllamaService` | Observable state: connection status, current model, streaming chunks, accumulated insights | `OllamaClient` calls; Views bind |
| `SessionLibrary` | Observable list of `SessionEntry` structs from index file | `SessionIndexActor` loads/writes |
| `OllamaClient` | Actor. HTTP to local Ollama: health check, model list, streaming chat | URLSession bytes API |
| `SessionIndexActor` | Actor. Reads/writes `sessions-index.json` in AppSupport | FileManager |
| `TranscriptionEngine` | MainActor. Existing: dual-stream audio orchestration | Audio capture, FluidAudio, `TranscriptStore` |
| `TranscriptLogger` | Actor. Existing: markdown transcript file writes | FileManager |
| `SessionStore` | Actor. Existing: per-session JSONL for crash recovery | FileManager |

## Recommended Project Structure

```
Sources/Tome/
├── App/
│   ├── TomeApp.swift
│   └── AppDelegate.swift
├── Audio/
│   ├── MicCapture.swift
│   └── SystemAudioCapture.swift
├── LLM/                            # NEW -- Ollama integration
│   ├── OllamaClient.swift          # actor: raw HTTP, streaming
│   └── OllamaService.swift         # @Observable: state exposed to UI
├── Models/
│   ├── Models.swift                # existing Utterance, SessionRecord
│   └── SessionEntry.swift          # NEW -- library index entry
├── Settings/
│   └── AppSettings.swift
├── Storage/
│   ├── TranscriptLogger.swift      # existing
│   ├── SessionStore.swift          # existing
│   └── SessionIndexActor.swift     # NEW -- library index persistence
├── Transcription/
│   ├── TranscriptionEngine.swift
│   └── StreamingTranscriber.swift
└── Views/
    ├── ContentView.swift           # modified -- adds split-view, mic button
    ├── ControlBar.swift            # modified -- three-state mic button
    ├── InsightsPanel.swift         # NEW -- LLM side panel
    ├── LibraryView.swift           # NEW -- session grid
    ├── TranscriptView.swift        # existing
    ├── WaveformView.swift          # existing (or removed if replaced)
    ├── OnboardingView.swift        # existing
    ├── SettingsView.swift          # existing
    └── CheckForUpdatesView.swift   # existing
```

### Structure Rationale

- **LLM/:** Isolates Ollama-specific code. `OllamaClient` is a pure HTTP actor; `OllamaService` is the @Observable bridge to UI. Separation matches the existing pattern of `TranscriptionEngine` (MainActor observable) on top of `StreamingTranscriber` (actor).
- **Storage/SessionIndexActor.swift:** Follows the existing actor-per-file-type pattern (TranscriptLogger for markdown, SessionStore for JSONL, SessionIndexActor for the library index JSON).
- **Models/SessionEntry.swift:** Library entry is a distinct model with different lifecycle than `SessionRecord` (which is per-utterance crash recovery). Keep them separate.

## Architectural Patterns

### Pattern 1: Actor + @Observable Service Pair

**What:** A raw actor handles all I/O and side effects. A @MainActor @Observable wrapper exposes state to SwiftUI and calls into the actor.

**When to use:** Any I/O-bound subsystem that also needs to drive UI. Already used for TranscriptionEngine. Use the same pattern for Ollama.

**Trade-offs:** Small boilerplate overhead for the wrapper; pays off in Swift 6 strict concurrency -- no @unchecked Sendable needed.

**Example:**
```swift
// Actor layer -- isolated I/O
actor OllamaClient {
    private let baseURL: URL

    func checkHealth() async throws -> Bool { ... }
    func listModels() async throws -> [String] { ... }
    func streamChat(model: String, messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> { ... }
}

// Observable layer -- UI state
@Observable
@MainActor
final class OllamaService {
    private(set) var isConnected = false
    private(set) var availableModels: [String] = []
    private(set) var streamingChunks: String = ""
    private(set) var accumulatedInsights: LLMInsights?

    private let client: OllamaClient

    func connect() async {
        isConnected = await (try? client.checkHealth()) ?? false
        if isConnected {
            availableModels = (try? await client.listModels()) ?? []
        }
    }

    func analyzeTranscript(utterances: [Utterance]) async { ... }
}
```

### Pattern 2: URLSession.bytes for NDJSON Streaming

**What:** Use `URLSession.bytes(for:)` + `.lines` to consume Ollama's newline-delimited JSON stream as an `AsyncSequence<String>`. Decode each line independently.

**When to use:** Any Ollama endpoint with `"stream": true`. This is the canonical Swift pattern for NDJSON; Ollama's response is one JSON object per line with a `done` boolean.

**Trade-offs:** More manual than the third-party `ollama-swift` library, but zero additional dependency. Given the existing codebase uses no Ollama wrapper, rolling a thin client in ~80 lines avoids a dependency for a simple integration.

**Example:**
```swift
func streamChat(model: String, messages: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
    AsyncThrowingStream { continuation in
        Task {
            let request = buildRequest(endpoint: "/api/chat", body: ...)
            let (asyncBytes, _) = try await URLSession.shared.bytes(for: request)
            for try await line in asyncBytes.lines {
                guard !line.isEmpty else { continue }
                let chunk = try JSONDecoder().decode(OllamaChatChunk.self, from: Data(line.utf8))
                if let token = chunk.message?.content {
                    continuation.yield(token)
                }
                if chunk.done { continuation.finish(); return }
            }
            continuation.finish()
        }
    }
}
```

### Pattern 3: Split-View with Programmatic Visibility Toggle

**What:** Use SwiftUI's `HStack` + `withAnimation` + a `@State var showInsights: Bool` to slide the `InsightsPanel` in/out. Avoid `NavigationSplitView` for this use case -- it imposes navigation semantics that don't match a recording tool's layout.

**When to use:** A secondary panel that appears/disappears during a session, rather than a persistent navigation sidebar. The app window is small (280--360pt) and the panel should be additive, expanding the window width.

**Trade-offs:** Manual layout control vs. NavigationSplitView's built-in sidebar collapse. Manual is better here because the window geometry is already tightly constrained and NavigationSplitView on macOS enforces minimum column widths that break this app's compact UI.

**Example:**
```swift
// In ContentView body
HStack(spacing: 0) {
    mainContent  // existing VStack, fixed ~340pt
    if showInsights {
        Divider()
        InsightsPanel(service: ollamaService)
            .frame(width: 280)
            .transition(.move(edge: .trailing).combined(with: .opacity))
    }
}
.animation(.easeInOut(duration: 0.2), value: showInsights)
```

## Data Flow

### Ollama Streaming During Recording

```
TranscriptStore.utterances (updated by TranscriptionEngine)
    ↓ onChange (ContentView observes utterance count)
ContentView.handleNewUtterance()
    ↓ every N utterances OR on threshold (e.g., 5 new utterances)
OllamaService.analyzeTranscript(recentUtterances)
    ↓ async Task
OllamaClient.streamChat()  →  POST /api/chat  →  Ollama HTTP server (localhost:11434)
    ↓ AsyncThrowingStream<String>
OllamaService.streamingChunks += token  (on MainActor)
    ↓ @Observable binding
InsightsPanel re-renders with partial LLM output
    ↓ on done
OllamaService.accumulatedInsights updated with parsed summary/actions/topics
```

### Session Library Load

```
App launch / LibraryView.onAppear
    ↓
SessionLibrary.load()  →  SessionIndexActor.readIndex()
    ↓ reads sessions-index.json from AppSupport/Tome/
[SessionEntry] decoded (Codable)
    ↓
SessionLibrary.sessions updated (MainActor)
    ↓ @Observable binding
LibraryView renders grid
    ↓
For each entry: FileManager.fileExists() → sets .missing flag
```

### Session Save and Index Update

```
TranscriptLogger.finalizeFrontmatter() returns URL
    ↓ (already on ContentView Task)
SessionIndexActor.appendEntry(SessionEntry(...))
    ↓ reads existing index, appends, writes atomically
sessions-index.json updated
    ↓
ContentView calls SessionLibrary.reload()
    ↓
LibraryView reflects new session
```

### Ollama Health Check Flow

```
App launch (ContentView .task) OR Settings change
    ↓
OllamaService.connect()
    ↓
OllamaClient.checkHealth()  →  GET http://localhost:11434/
    Response "Ollama is running" (plain text, 200)  →  isConnected = true
    Connection refused / timeout  →  isConnected = false
    ↓ if connected
OllamaClient.listModels()  →  GET /api/tags
    →  OllamaService.availableModels populated
    ↓
InsightsPanel shows model selector or "Ollama not running" notice
```

## Component Boundaries

| Boundary | Communication | Rule |
|----------|---------------|------|
| `ContentView` → `OllamaService` | Direct property access (@Observable) | ContentView triggers analysis; reads state for InsightsPanel toggle |
| `OllamaService` → `OllamaClient` | `await client.method()` | OllamaService is the only caller of OllamaClient |
| `ContentView` → `SessionLibrary` | Direct property access (@Observable) | ContentView appends after session ends; LibraryView reads |
| `SessionLibrary` → `SessionIndexActor` | `await actor.method()` | SessionLibrary is the only caller of SessionIndexActor |
| `TranscriptStore` → `InsightsPanel` | Via `OllamaService` only | InsightsPanel never reads TranscriptStore directly -- it only displays what OllamaService has processed |
| `TranscriptLogger` → `SessionIndexActor` | Never directly | ContentView coordinates both after session end; actors don't know about each other |

## Suggested Build Order

Build order is driven by dependencies. Later components depend on earlier ones.

1. **SessionEntry model + SessionIndexActor** -- No dependencies on new code. Pure data + file I/O. Unblocks LibraryView.

2. **SessionLibrary (@Observable)** -- Wraps SessionIndexActor. Unblocks LibraryView.

3. **LibraryView** -- Reads SessionLibrary. Can be built and tested with seed data before any recording changes.

4. **OllamaClient (actor)** -- Pure HTTP, no UI dependencies. Can be built and unit-tested against a running Ollama instance independently.

5. **OllamaService (@Observable)** -- Wraps OllamaClient. Unblocks InsightsPanel.

6. **InsightsPanel** -- Reads OllamaService. Standalone view with no session lifecycle coupling.

7. **ContentView split-view layout + mic button** -- Integrates InsightsPanel and new session lifecycle (stop → save → index). All dependencies exist by this point.

8. **Wire OllamaService into session lifecycle** -- The last step: connect `handleNewUtterance` → `OllamaService.analyzeTranscript`. Done last because it requires both OllamaService and the session lifecycle changes to be stable.

## Anti-Patterns

### Anti-Pattern 1: Putting HTTP Calls in @Observable Service

**What people do:** Call `URLSession` directly from `OllamaService` methods on the MainActor.

**Why it's wrong:** HTTP and MainActor don't mix. Blocking the main actor on I/O causes UI freezes. Swift 6 strict concurrency will also warn about this.

**Do this instead:** All URLSession calls live in `OllamaClient` (actor-isolated). `OllamaService` only calls actor methods with `await` and updates `@MainActor` state from the response.

### Anti-Pattern 2: Calling `OllamaService.analyzeTranscript` on Every Utterance

**What people do:** Trigger a new LLM request for every single transcription callback.

**Why it's wrong:** Ollama on consumer hardware takes 1-10 seconds per request. Firing a request every few seconds creates a queue backlog and the insights panel will always be showing stale analysis from 30+ requests ago.

**Do this instead:** Debounce with a threshold (e.g., minimum 5 new utterances or 30 seconds since last analysis, whichever comes first). Cancel the in-flight Task before starting a new one.

### Anti-Pattern 3: Storing Session Library State in SessionStore (JSONL)

**What people do:** Repurpose the existing per-session JSONL crash recovery files as the library index.

**Why it's wrong:** The JSONL files are per-session incremental logs -- they don't store the final file path (set only after `finalizeFrontmatter()` renames the file), the session title, or the duration. Scanning them at startup to build a library would require reading every file.

**Do this instead:** A separate `sessions-index.json` in AppSupport stores one lightweight `SessionEntry` per completed session (path, title, date, duration). Written once after `finalizeFrontmatter()` returns the final path.

### Anti-Pattern 4: NavigationSplitView for the Insights Panel

**What people do:** Wrap the recording UI in a `NavigationSplitView` to get "free" sidebar behavior.

**Why it's wrong:** `NavigationSplitView` on macOS enforces minimum column widths (~200pt+) and navigation semantics that conflict with the compact floating-window UX. The existing window is 280--360pt wide -- adding a 200pt sidebar column would require tripling the window width.

**Do this instead:** `HStack` with `withAnimation` conditional inclusion of the panel and programmatic `frame(width:)` to control the window size expansion.

## Integration Points

### Ollama HTTP API

| Endpoint | Method | Purpose | Notes |
|----------|--------|---------|-------|
| `GET /` | HTTP GET | Health check | Returns plain text "Ollama is running" on 200 |
| `GET /api/tags` | HTTP GET | List installed models | Returns `{ "models": [...] }` |
| `POST /api/chat` | HTTP POST, stream | LLM analysis | NDJSON stream, `done: true` marks end |

Connection: `http://localhost:11434` (default, configurable in Settings)

The `ollama-swift` package (github.com/mattt/ollama-swift) is an option but adds a dependency for ~80 lines of URLSession code. Recommend rolling a thin `OllamaClient` actor using `URLSession.bytes` + `.lines` to stay dependency-minimal. Revisit if structured outputs or tool calling are needed later.

### Session Index File

- Location: `ApplicationSupport/Tome/sessions-index.json`
- Format: JSON array of `SessionEntry` (Codable)
- Write strategy: Read existing array → append new entry → write atomically via temp file (matches existing TranscriptLogger pattern)
- Missing-file detection: Check `FileManager.fileExists()` per entry at load time, set a `isMissing: Bool` flag in memory (never mutate the index for missing files)

## Sources

- Existing codebase inspected: `ContentView.swift`, `TranscriptStore.swift`, `SessionStore.swift`, `TranscriptLogger.swift`, `Models.swift` -- HIGH confidence
- Ollama HTTP API: https://docs.ollama.com/api/streaming -- HIGH confidence (official docs)
- Ollama Swift client: https://github.com/mattt/ollama-swift -- HIGH confidence (inspected README/API)
- `URLSession.bytes` + `.lines` NDJSON pattern: https://developer.apple.com/documentation/foundation/urlsession/asyncbytes -- HIGH confidence (Apple docs)
- SwiftUI `NavigationSplitView` on macOS: https://developer.apple.com/documentation/swiftui/navigationsplitview -- HIGH confidence (Apple docs)
- Split-view panel pattern recommendation: derived from window geometry constraints in existing code -- MEDIUM confidence (validated against SwiftUI layout constraints)

---
*Architecture research for: macOS transcription app -- Ollama + session library + split-view UI*
*Researched: 2026-03-31*
