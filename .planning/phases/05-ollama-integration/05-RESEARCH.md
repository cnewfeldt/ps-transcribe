# Phase 5: Ollama Integration - Research

**Researched:** 2026-04-03
**Domain:** Ollama REST API, Swift actor concurrency, SwiftUI sheet/picker patterns
**Confidence:** HIGH

## Summary

Phase 5 adds a self-contained `OllamaService` actor that communicates with a locally-running Ollama instance over HTTP, surfaces connection status and model selection in SettingsView, and provides a clean async API for Phase 6 to consume. All communication is via Ollama's REST API on `localhost:11434`. The service is fully optional -- recording must never be affected by its presence or absence.

The Ollama REST API is simple and stable. The required endpoints (`GET /`, `GET /api/tags`, `POST /api/generate`) are well-documented and confirmed working on the dev machine (Ollama 0.18.3). The actor isolation pattern, @Observable bridging, and UserDefaults persistence patterns are all established in the codebase. No new Swift packages are needed -- URLSession covers all HTTP requirements.

**Primary recommendation:** Implement OllamaService as a standalone (non-MainActor) Swift actor using URLSession with a 2-second timeout configuration. Bridge its state to SwiftUI via a separate @MainActor @Observable wrapper class that OllamaService notifies via Task { @MainActor in }.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Connection & Detection**
- D-01: Connect to localhost:11434 only -- no configurable URL, no OLLAMA_HOST env var fallback
- D-02: On-demand status checks only -- check when Settings opens or when a recording starts. No background polling
- D-03: When Ollama is unavailable, show status indicator only ("Not found" / "Not running") -- no install hints, no action buttons
- D-04: Recording is never blocked by Ollama availability -- transcription pipeline operates identically with or without Ollama

**Settings UI**
- D-05: Ollama section placed after Audio Input section in SettingsView
- D-06: Section contains: connection status indicator + model picker dropdown to select which downloaded model to use
- D-07: Status indicator is a colored dot + text: green dot + "Connected" / red dot + "Not running" / gray dot + "Not found"
- D-08: Model browsing/pulling happens in a separate sheet opened via a "Browse Models" button in the Ollama section

**Model Management**
- D-09: Browse sheet shows only locally downloaded models (from GET /api/tags) -- no remote library browsing
- D-10: No in-app model pulling -- users manage downloads via `ollama pull` CLI. OLMA-04 descoped to "select from downloaded models"
- D-11: App recommends a specific model for analysis (e.g., llama3.2:3b) -- suggested as default selection when models are available

**Service Architecture**
- D-12: Single `OllamaService` actor -- owns HTTP communication, connection state, and exposes clean async API for Phase 6
- D-13: OllamaService lives in new `LLM/` directory: `PSTranscribe/Sources/PSTranscribe/LLM/OllamaService.swift`
- D-14: Standalone actor (not @MainActor) -- network I/O stays off main thread. UI reads state via async properties or @Observable wrapper
- D-15: Selected model name persists via AppSettings with UserDefaults didSet pattern (new `selectedOllamaModel` property)

### Claude's Discretion
- HTTP client implementation details (URLSession vs other)
- Exact error types and error handling patterns within OllamaService
- Model recommendation choice (specific model name for default suggestion)
- @Observable wrapper pattern for bridging standalone actor state to SwiftUI

### Deferred Ideas (OUT OF SCOPE)
- In-app model pulling -- OLMA-04 descoped from this phase
- Configurable Ollama URL -- Supporting remote Ollama instances or non-standard ports
- Model size/parameter display -- Showing model metadata in the browse sheet
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OLMA-01 | App detects whether Ollama is installed and running on the local machine | GET / returns "Ollama is running" (200) when running; connection refused or timeout when not. Two distinct error cases require two enum states. |
| OLMA-02 | Settings pane shows Ollama connection status (connected/not found/not running) | OllamaService exposes `connectionStatus` property; @Observable wrapper bridges to SettingsView. Three-state enum: connected, notRunning, notFound. |
| OLMA-03 | User can browse available Ollama models from within the app | GET /api/tags returns model list. Sheet view iterates `models` array. No remote fetch needed. |
| OLMA-04 | (DESCOPED per D-10) Select from downloaded models only | Model picker Picker in SettingsView section uses local models list from GET /api/tags. |
| OLMA-05 | Ollama operations use 2-second timeout and never block the recording pipeline | URLSessionConfiguration.ephemeral with timeoutIntervalForRequest = 2. OllamaService is a separate actor never in TranscriptionEngine's critical path. |
| OLMA-06 | Ollama requests explicitly set num_ctx to handle long transcripts (not default 4096) | POST /api/generate request body: `"options": { "num_ctx": N }`. Research shows 8192 or 16384 is appropriate for transcript-length context. |
</phase_requirements>

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| URLSession | System (Foundation) | HTTP requests to Ollama REST API | Already in use in the project; no extra package needed |
| Swift Testing | System (swift-tools-version 6.2) | Unit tests for OllamaService parsing logic | Already used in PSTranscribeTests |
| Foundation (JSONDecoder) | System | Decode Ollama JSON responses | Standard, already used throughout |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| os.Logger | System | Diagnostic logging in OllamaService | Follow established pattern: subsystem "com.pstranscribe.app", category "OllamaService" |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| URLSession | Alamofire / AsyncHTTPClient | No benefit -- Ollama calls are simple GET/POST with no auth headers or complex retry logic |
| Manual URLSessionConfiguration timeout | URLRequest.timeoutInterval | Both work; configuration-level timeout is cleaner for a service that always uses 2s |

**Installation:**
No new packages required. All dependencies are already present in Package.swift.

**Version verification:**
- Ollama 0.18.3 confirmed running on dev machine at localhost:11434
- GET / returns HTTP 200 with body "Ollama is running"
- GET /api/tags returns model list correctly
- GET /api/version returns `{"version":"0.18.3"}`

---

## Architecture Patterns

### Recommended Project Structure
```
PSTranscribe/Sources/PSTranscribe/
├── LLM/
│   ├── OllamaService.swift       # actor -- HTTP, connection state, model list
│   └── OllamaModels.swift        # Codable types for API responses
├── Settings/
│   └── AppSettings.swift         # add selectedOllamaModel property
└── Views/
    ├── SettingsView.swift         # add Section("Ollama") + OllamaSection subview
    └── OllamaModelBrowseSheet.swift  # sheet for browsing downloaded models
```

### Pattern 1: OllamaService Actor

**What:** Standalone actor wrapping all HTTP communication. Owns connection state and model list as internal state. Exposes async methods for status checks and model listing.

**When to use:** Any I/O-heavy service that needs to be decoupled from MainActor. Matches `SessionStore` and `TranscriptLogger` patterns already in the codebase.

**Example:**
```swift
// Source: established actor pattern from SessionStore.swift + TranscriptLogger.swift
actor OllamaService {
    private let baseURL = URL(string: "http://localhost:11434")!
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 2.0
        config.timeoutIntervalForResource = 2.0
        self.session = URLSession(configuration: config)
    }

    enum ConnectionStatus: Sendable {
        case connected
        case notRunning   // TCP refused -- Ollama installed but not started
        case notFound     // No response at all -- Ollama not installed
    }

    func checkConnection() async -> ConnectionStatus {
        do {
            let (_, response) = try await session.data(from: baseURL)
            if (response as? HTTPURLResponse)?.statusCode == 200 {
                return .connected
            }
            return .notRunning
        } catch let error as URLError where error.code == .cannotConnectToHost {
            return .notRunning
        } catch {
            return .notFound
        }
    }

    func fetchModels() async throws -> [OllamaModel] {
        let url = baseURL.appending(path: "/api/tags")
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
        return response.models
    }
}
```

### Pattern 2: @Observable Bridge Wrapper

**What:** A @MainActor @Observable final class that owns OllamaService, calls its async methods, and publishes results as @Observable properties for SwiftUI.

**When to use:** Whenever a standalone actor's state needs to drive SwiftUI views. Matches how TranscriptionEngine wraps lower-level actors.

**Example:**
```swift
// Pattern from TranscriptionEngine -- @Observable @MainActor wrapper over actors
@Observable
@MainActor
final class OllamaState {
    var connectionStatus: OllamaService.ConnectionStatus = .notFound
    var models: [OllamaModel] = []
    var isCheckingConnection = false

    private let service = OllamaService()

    func refresh() async {
        isCheckingConnection = true
        connectionStatus = await service.checkConnection()
        if connectionStatus == .connected {
            models = (try? await service.fetchModels()) ?? []
        } else {
            models = []
        }
        isCheckingConnection = false
    }
}
```

### Pattern 3: Codable Response Types

**What:** Lightweight Codable structs matching the Ollama JSON schema.

**Example:**
```swift
// Source: Ollama API docs (https://github.com/ollama/ollama/blob/main/docs/api.md)
struct OllamaTagsResponse: Codable {
    let models: [OllamaModel]
}

struct OllamaModel: Codable, Identifiable {
    let name: String
    let model: String
    let size: Int
    let details: OllamaModelDetails

    var id: String { name }
}

struct OllamaModelDetails: Codable {
    let parameterSize: String
    let quantizationLevel: String
    let family: String

    enum CodingKeys: String, CodingKey {
        case parameterSize = "parameter_size"
        case quantizationLevel = "quantization_level"
        case family
    }
}
```

### Pattern 4: SettingsView Section Insertion

**What:** Add Section("Ollama") after the existing Section("Audio Input") block in SettingsView.

**Example:**
```swift
// After existing Section("Audio Input") { ... }
Section("Ollama") {
    HStack {
        Image(systemName: connectionDot)
            .foregroundStyle(connectionColor)
            .font(.system(size: 9))
        Text(connectionLabel)
            .font(.system(size: 12))
        Spacer()
    }

    if ollamaState.connectionStatus == .connected {
        Picker("Model", selection: $settings.selectedOllamaModel) {
            Text("None").tag("")
            ForEach(ollamaState.models) { model in
                Text(model.name).tag(model.name)
            }
        }
        .font(.system(size: 12))

        Button("Browse Models") {
            showModelBrowser = true
        }
        .font(.system(size: 12))
    }
}
.sheet(isPresented: $showModelBrowser) {
    OllamaModelBrowseSheet(models: ollamaState.models)
}
```

### Pattern 5: AppSettings selectedOllamaModel Property

**What:** Add `selectedOllamaModel: String` to AppSettings following the exact `didSet` UserDefaults pattern used for every other property.

**Example:**
```swift
// Exact same pattern as existing AppSettings properties
var selectedOllamaModel: String {
    didSet { UserDefaults.standard.set(selectedOllamaModel, forKey: "selectedOllamaModel") }
}

// In init():
self.selectedOllamaModel = defaults.string(forKey: "selectedOllamaModel") ?? ""
```

### Pattern 6: POST /api/generate with num_ctx

**What:** For OLMA-06, all generate calls must set `num_ctx` in the options dict. Ollama default is 4096 tokens which is too small for long transcripts. 16384 is a safe upper bound that fits most 8B models without OOM on modern Macs.

**Example:**
```swift
struct OllamaGenerateRequest: Codable {
    let model: String
    let prompt: String
    let stream: Bool
    let options: OllamaOptions

    struct OllamaOptions: Codable {
        let numCtx: Int
        enum CodingKeys: String, CodingKey {
            case numCtx = "num_ctx"
        }
    }
}

// Usage:
let request = OllamaGenerateRequest(
    model: model,
    prompt: prompt,
    stream: false,
    options: .init(numCtx: 16384)
)
```

### Anti-Patterns to Avoid
- **Polling from a .task loop:** D-02 prohibits background polling. Status is checked on-demand (onAppear of SettingsView, or at session start). Never schedule a Timer or Task.sleep loop.
- **Embedding OllamaService in TranscriptionEngine:** D-12/D-13 require a separate actor. TranscriptionEngine's critical path must not acquire OllamaService's actor.
- **Force-unwrapping Ollama responses:** The service may be absent or return unexpected JSON. Use `try?` or explicit do/catch, never force-unwrap decode results.
- **Blocking UI on model list fetch:** Always show the sheet immediately, load models async, show a ProgressView while loading.
- **Storing ConnectionStatus without .notFound default:** Default to .notFound -- the safe assumption when OllamaState is first initialized. Never assume connectivity.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTTP timeout enforcement | Custom deadline tracking | `URLSessionConfiguration.timeoutIntervalForRequest` | OS-level; works across task cancellation and backgrounding |
| JSON decode of Ollama responses | Manual string parsing | `JSONDecoder` + `Codable` structs | Ollama responses are clean JSON; manual parsing is error-prone |
| Connection state machine | Custom flags + timers | Swift actor + async/await | Actor serializes state mutations; no lock needed |
| Cancellation on view dismiss | Manual task tracking | SwiftUI `.task {}` modifier | Auto-cancelled when view disappears |

**Key insight:** Ollama's REST API is intentionally minimal. The entire integration is URLSession + JSON decode. No OAuth, no streaming complexity (use `"stream": false`), no retry logic needed for the settings panel use case.

---

## Runtime State Inventory

> Not applicable -- this is a greenfield feature addition, not a rename/refactor/migration phase.

None -- no existing stored data, live service config, OS-registered state, secrets, or build artifacts are affected by this phase.

---

## Common Pitfalls

### Pitfall 1: Confusing "not running" with "not installed"
**What goes wrong:** Both states result in a failed HTTP connection, but the error type differs. If Ollama is installed but not running, macOS returns `ECONNREFUSED` (URLError.cannotConnectToHost). If the binary doesn't exist, there is no listener and the behavior is the same -- both look like a refused connection from URLSession's perspective.
**Why it happens:** "Not installed" and "not running" are semantically different to users but produce identical TCP behavior.
**How to avoid:** Per D-03, the UI only shows three states. "Not found" covers both "not installed" and "not running but no process". The URLError code `.cannotConnectToHost` maps to "Not running". Any other URLError (timeout, etc.) maps to "Not found". This is a pragmatic simplification -- users who see "Not found" when Ollama is installed but not started will simply run `ollama serve`.
**Warning signs:** Don't add process-listing code (via `ps aux` subprocess) to distinguish installed vs. not -- that's out of scope and adds entitlement requirements.

### Pitfall 2: Actor reentrancy with connection state
**What goes wrong:** An async method in OllamaService checks `connectionStatus`, awaits a network call, and then updates `connectionStatus`. If two callers enter simultaneously (e.g., SettingsView onAppear and a session start), the second call sees stale state at the check point.
**Why it happens:** Swift actors serialize access but allow interleaving at every `await` suspension point.
**How to avoid:** Either (a) use a simple "fire and forget" pattern where each `checkConnection()` call is independent and the caller takes the last result, or (b) add an `isChecking` guard that early-returns if a check is already in flight. Option (a) is simpler and correct for this use case since concurrent checks are idempotent.

### Pitfall 3: Sheet loading models before connection is confirmed
**What goes wrong:** OllamaModelBrowseSheet appears and immediately calls `fetchModels()`, which throws if Ollama is not running, showing an error state in the sheet.
**Why it happens:** The sheet can only be opened via "Browse Models" button which only appears when status is .connected (per D-07 pattern), but connection state can change between check and button press.
**How to avoid:** Always show the sheet with a loading state, catch the fetch error, and display "Unable to connect" inline rather than blocking sheet presentation. The sheet should be resilient to Ollama disappearing mid-display.

### Pitfall 4: num_ctx value causing model OOM
**What goes wrong:** Setting `num_ctx` too high (e.g., 32768) on smaller models (3B-7B quantized) can cause Ollama to run out of metal memory and fail silently or crash.
**Why it happens:** `num_ctx` sets the KV cache size which scales with context length. Q4_K_M quantized 8B models typically support 16k-32k depending on available VRAM.
**How to avoid:** Use 16384 as the default. This handles transcripts up to approximately 12,000 words (about 4 hours of dense conversation). Phase 6 can expose this as a configurable value if needed.

### Pitfall 5: SwiftUI Picker with empty model list
**What goes wrong:** `Picker` with `ForEach(ollamaState.models)` renders an empty dropdown when models list is empty but picker is still visible, confusing users.
**Why it happens:** Model list is populated async after connection check.
**How to avoid:** Only show the Picker section when `connectionStatus == .connected && !models.isEmpty`. Show a "No models found -- run 'ollama pull llama3.2:3b'" hint when connected but empty.

---

## Code Examples

### Check connection (confirmed against live Ollama 0.18.3)
```swift
// GET / returns 200 with text body "Ollama is running"
let url = URL(string: "http://localhost:11434")!
let (_, response) = try await session.data(from: url)
let code = (response as? HTTPURLResponse)?.statusCode  // 200
```

### Fetch local models
```swift
// GET /api/tags response shape (verified against live instance):
// {"models":[{"name":"llama3.2:3b","model":"llama3.2:3b","size":2019393189,
//   "details":{"parameter_size":"3.2B","quantization_level":"Q4_K_M",...}},...]}
let url = URL(string: "http://localhost:11434/api/tags")!
let (data, _) = try await session.data(from: url)
let decoded = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
```

### URLSession with 2-second timeout (OLMA-05)
```swift
let config = URLSessionConfiguration.ephemeral
config.timeoutIntervalForRequest = 2.0
config.timeoutIntervalForResource = 2.0
let session = URLSession(configuration: config)
// URLError.timedOut is thrown if Ollama takes > 2s to respond
```

### Generate with num_ctx (OLMA-06)
```swift
// POST /api/generate
var req = URLRequest(url: baseURL.appending(path: "/api/generate"))
req.httpMethod = "POST"
req.setValue("application/json", forHTTPHeaderField: "Content-Type")
let body = OllamaGenerateRequest(
    model: model,
    prompt: prompt,
    stream: false,
    options: .init(numCtx: 16384)
)
req.httpBody = try JSONEncoder().encode(body)
let (data, _) = try await session.data(for: req)
```

### os.Logger in OllamaService
```swift
// Per Phase 2 pattern: file-level Logger
private let log = Logger(subsystem: "com.pstranscribe.app", category: "OllamaService")
log.info("Connection check: \(status)")
log.error("fetchModels failed: \(error.localizedDescription)")
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Polling for service availability | On-demand checks triggered by UI events | N/A for this codebase | No background CPU/power cost |
| Completion handler URLSession | async/await URLSession (iOS 15 / macOS 12+) | Swift 5.5 (2021) | Cleaner, no callback nesting |
| KVO-based Observable | @Observable macro | Swift 5.9 (2023) | Already used in this codebase |

**Deprecated/outdated:**
- `URLSession.shared`: Don't use the shared session -- it has no timeout configured. Always create a dedicated URLSession with explicit configuration.
- `ObservableObject` + `@Published`: This codebase uses `@Observable` macro (Swift 5.9+). Don't introduce `@Published` for OllamaState.

---

## Open Questions

1. **Recommended model default (D-11)**
   - What we know: `llama3.2:3b` is listed in CONTEXT.md as an example. The dev machine has `llama3.2:3b`, `qwen3:8b`, `qwen3.5:35b`, `llama3.2-vision:latest` installed.
   - What's unclear: Whether to suggest `llama3.2:3b` specifically or just default to the first model in the list.
   - Recommendation: Default `selectedOllamaModel` to `""` (empty). When the picker loads models and the stored value is empty or not in the list, select `llama3.2:3b` if present, otherwise the first model. This avoids hardcoding a model that might not be installed.

2. **OllamaState ownership**
   - What we know: SettingsView needs to call `refresh()` on appear. TranscriptionEngine may need connection status at session start (per D-02).
   - What's unclear: Whether OllamaState should live in AppSettings, ContentView, or a dedicated property on the app level.
   - Recommendation: Instantiate OllamaState at the ContentView level and pass it to SettingsView as a parameter, same pattern as AppSettings. This avoids global state while giving ContentView access for pre-session checks.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Ollama (localhost:11434) | OLMA-01 through OLMA-06 | ✓ | 0.18.3 | Show "Not found" status -- app works normally without it |
| URLSession | HTTP requests | ✓ | System | None needed |
| Swift Testing | Unit tests | ✓ | swift-tools-version 6.2 | None needed |
| Swift 6.2 / macOS 26 | Actor concurrency features | ✓ | As configured in Package.swift | None needed |

**Missing dependencies with no fallback:** None -- all required dependencies are present.

**Available models on dev machine (confirmed):** `llama3.2:3b`, `qwen3:8b`, `qwen3.5:35b`, `llama3.2-vision:latest`

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (swift-testing, bundled with Swift 6.2) |
| Config file | Package.swift testTarget "PSTranscribeTests" |
| Quick run command | `cd /Users/cary/Development/ai-development/Tome/PSTranscribe && swift test --filter OllamaServiceTests` |
| Full suite command | `cd /Users/cary/Development/ai-development/Tome/PSTranscribe && swift test` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OLMA-01 | `checkConnection()` returns .connected when Ollama running | unit (mock) | `swift test --filter OllamaServiceTests/checkConnection` | Wave 0 |
| OLMA-01 | `checkConnection()` returns .notRunning on ECONNREFUSED | unit (mock) | `swift test --filter OllamaServiceTests/checkConnectionRefused` | Wave 0 |
| OLMA-01 | `checkConnection()` returns .notFound on timeout | unit (mock) | `swift test --filter OllamaServiceTests/checkConnectionTimeout` | Wave 0 |
| OLMA-02 | ConnectionStatus enum has three cases | unit | included in OLMA-01 tests | Wave 0 |
| OLMA-03 | `fetchModels()` decodes GET /api/tags JSON correctly | unit (fixture) | `swift test --filter OllamaServiceTests/fetchModelsDecodesJSON` | Wave 0 |
| OLMA-05 | URLSession configured with 2s timeout | unit | `swift test --filter OllamaServiceTests/sessionTimeout` | Wave 0 |
| OLMA-06 | Generate request encodes num_ctx correctly | unit | `swift test --filter OllamaServiceTests/generateRequestNumCtx` | Wave 0 |
| OLMA-04 (descoped) | AppSettings.selectedOllamaModel persists via UserDefaults | unit | `swift test --filter AppSettingsTests/selectedOllamaModel` | Wave 0 |

**Manual-only (no automated test):**
- SettingsView UI rendering (colored dot, picker appearance) -- SwiftUI view test infrastructure not set up
- Sheet presentation and dismissal -- UI interaction
- OllamaState.refresh() triggering on Settings onAppear -- integration

**Note on test strategy:** OllamaService HTTP calls should be tested against mock URLSession responses (using fixture JSON) rather than requiring a live Ollama instance. The actual live integration is confirmed by manual smoke test during verification.

### Sampling Rate
- **Per task commit:** `swift test --filter OllamaServiceTests`
- **Per wave merge:** `swift test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `Tests/PSTranscribeTests/OllamaServiceTests.swift` -- covers OLMA-01, OLMA-03, OLMA-05, OLMA-06
- [ ] `Tests/PSTranscribeTests/AppSettingsOllamaTests.swift` -- covers selectedOllamaModel persistence
- [ ] JSON fixture file for OllamaTagsResponse decode test

*(Existing test infrastructure in PSTranscribeTests is sufficient -- no new framework config needed)*

---

## Sources

### Primary (HIGH confidence)
- Live Ollama instance (localhost:11434, v0.18.3) -- endpoints verified by direct curl
- `PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift` -- UserDefaults didSet pattern
- `PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift` -- Form section structure
- `.planning/codebase/CONVENTIONS.md` -- Actor patterns, @Observable, logging
- `.planning/codebase/ARCHITECTURE.md` -- Layer isolation, actor patterns
- `https://github.com/ollama/ollama/blob/main/docs/api.md` -- API endpoint schema

### Secondary (MEDIUM confidence)
- CONTEXT.md decisions D-01 through D-15 -- user locked decisions (authoritative for this phase)
- PSTranscribeTests existing test files -- Swift Testing framework patterns

### Tertiary (LOW confidence)
- num_ctx = 16384 recommendation -- based on known model KV cache sizing for Q4_K_M 8B models; specific value should be validated with Phase 6 analysis prompts

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- URLSession + Swift actors are already in use; no new packages needed
- Architecture: HIGH -- patterns directly match existing codebase actors; Ollama API verified live
- Pitfalls: HIGH -- verified against actual Ollama behavior and Swift 6 actor semantics
- num_ctx value: MEDIUM -- 16384 is well-reasoned but specific value is empirical

**Research date:** 2026-04-03
**Valid until:** 2026-05-03 (Ollama API is stable; Swift 6.2 patterns are stable)
