# Stack Research

**Domain:** macOS native app -- Ollama LLM integration, session library UI, animated SwiftUI components
**Researched:** 2026-03-31
**Confidence:** MEDIUM-HIGH (core choices HIGH, some SwiftData/Swift 6 interaction details MEDIUM)

## Existing Stack (Do Not Revisit)

| Technology | Version | Role |
|------------|---------|------|
| Swift | 6.2 | Language |
| SwiftUI + AppKit | macOS 26.0+ | UI framework |
| FluidAudio | commit ea50062 | ASR / VAD / diarization |
| Sparkle | 2.9.0 | Auto-update |
| AVFoundation + ScreenCaptureKit | system | Audio capture |
| @Observable / actors | Swift stdlib | State + concurrency |

## Recommended Stack (New Capabilities Only)

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| mattt/ollama-swift | 1.8.0 | Ollama API client | Zero dependencies, swift-tools-version 6.0, AsyncSequence streaming, macOS 13+. Written by a respected Swift community author. Simpler and more maintained than OllamaKit for this use case. |
| SwiftData | macOS 14+ (bundled) | Session library persistence | Native Apple framework, @Model macro eliminates boilerplate, integrates cleanly with @Observable and SwiftUI. Correct choice for a new, single-device app on macOS 26. |
| SwiftUI LazyVGrid | macOS 11+ (bundled) | Grid view for session library | Native, zero-dependency, lazy rendering handles large session lists without extra libraries. .adaptive column sizing gives responsive grid automatically. |
| SF Symbols symbolEffect() | macOS 14+ (bundled) | Three-state mic button animation | Built-in, no import needed. `.symbolEffect(.pulse)` for recording state, `.symbolEffect(.appear/.disappear)` for transitions. Compile-time safe. Introduced WWDC23, expanded in SF Symbols 6 and 7. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| mattt/ollama-swift | 1.8.0 | Ollama HTTP client with streaming | All Ollama interactions -- model listing, chat streaming, server detection |
| Foundation URLSession | system | Fallback HTTP for Ollama health check | Use `GET http://localhost:11434/` to detect server running; returns "Ollama is running" with 200. Can be done directly or via ollama-swift. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Swift Package Manager | Dependency management | Already in use. Add ollama-swift via `Package.swift` with `.upToNextMajor(from: "1.8.0")`. |
| Xcode Instruments (Time Profiler) | LLM streaming performance | Token-by-token updates to `@Observable` state need profiling to ensure main thread isn't blocked during rapid token arrival. |

## Installation

```swift
// In Package.swift dependencies array:
.package(url: "https://github.com/mattt/ollama-swift", from: "1.8.0"),

// In target dependencies:
.product(name: "Ollama", package: "ollama-swift"),
```

SwiftData, LazyVGrid, and symbolEffect are system frameworks -- no installation needed.

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| mattt/ollama-swift | kevinhermawan/OllamaKit (v5.0.8) | OllamaKit is fine if you need its higher-level abstractions (it powers the Ollamac app). For this project, ollama-swift is leaner, has no transitive dependencies, and uses swift-tools-version 6.0 matching the project's Swift 6.2 toolchain. |
| mattt/ollama-swift | Raw URLSession + JSONDecoder | Acceptable if you want zero new dependencies. The streaming implementation is non-trivial (chunked JSON decoding of Ollama's NDJSON format). Not worth building in-house. |
| SwiftData | CoreData | Use CoreData only if you need NSCompoundPredicate, NSFetchedResultsController, or iOS 16 support. This project targets macOS 26 only, so SwiftData's Swift-native API is strictly better. |
| SwiftData | SQLite.swift or GRDB | Use only if SwiftData's query capabilities prove insufficient. The session library schema is simple (id, name, date, path, duration) -- SwiftData handles this easily. |
| SF Symbols symbolEffect() | Lottie / custom CALayer animation | Use Lottie only for animations that cannot be expressed as symbol effects or SwiftUI phase animations. Three-state mic button is well within SF Symbols' built-in repertoire (.record.circle, .mic.fill, .exclamationmark.triangle). |
| SwiftUI LazyVGrid | NSCollectionView | NSCollectionView is more powerful for complex data sources, but LazyVGrid with @Observable state is sufficient for a session grid. Avoid AppKit unless SwiftUI's grid has a concrete, demonstrated limitation. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| CloudKit sync for session library | App is explicitly offline-first. Adding CloudKit couples the session library to iCloud account state and network availability -- violates the product's core constraint. | Local SwiftData store with configurable vault path (already established pattern in app). |
| Combine publishers for Ollama streaming | The codebase uses async/await actors, not Combine pipelines. Mixing paradigms creates cognitive overhead and actor boundary confusion in Swift 6. | AsyncSequence (what ollama-swift provides natively). |
| OpenAI-compatible wrapper libraries | These add an abstraction layer above Ollama that implies cloud API patterns (rate limits, API keys, error shapes). Ollama-specific libraries have cleaner ergonomics for local server use. | mattt/ollama-swift directly. |
| @MainActor everywhere on SwiftData models | @ModelActor is the correct isolation primitive for background persistence operations (e.g., saving session records during recording). @MainActor on model access creates UI jank if called during heavy transcription. | @ModelActor for write operations, main context for read/display. |
| Third-party grid libraries (GridStack, etc.) | Unmaintained or minimal update cadence. LazyVGrid covers the use case with zero extra surface area. | SwiftUI LazyVGrid with .adaptive(minimum: 180) columns. |

## Stack Patterns by Variant

**For Ollama server detection:**
- Poll `GET http://localhost:11434/` on app launch and on settings open
- Use a 2-second timeout URLRequest so UI doesn't hang
- Store server reachability as `@Observable` state so views react automatically

**For streaming LLM analysis during recording:**
- Use `@ModelActor` for session persistence (background)
- Use `@MainActor`-isolated `@Observable` for live token accumulation in the UI
- Bridge via `PersistentIdentifier` -- never pass `@Model` instances across actor boundaries

**For the session library grid:**
- Use `@Query` macro in the view for automatic SwiftData reactivity
- Sort by `createdAt` descending by default
- Detect missing files with `FileManager.default.fileExists(atPath:)` -- do not store file existence state in the model, check on-demand at render time

**For three-state mic button animation:**
- Use an enum (`idle / recording / error`) as the button's state type
- Bind `symbolEffect(.pulse, isActive: state == .recording)` for the recording pulse
- Use `.contentTransition(.symbolEffect(.replace))` when switching between symbols for smooth morphing
- All three states map to existing SF Symbols: `mic` (idle), `record.circle.fill` (recording), `exclamationmark.microphone` (error)

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| mattt/ollama-swift 1.8.0 | Swift 6.0+, macOS 13+ | swift-tools-version 6.0 aligns with project's Swift 6.2. No known issues. |
| SwiftData | macOS 14+ | Project targets macOS 26 -- well within compatibility range. @ModelActor weirdness (implicit context threading) is documented; use explicit init pattern. |
| SF Symbols symbolEffect() | macOS 14+ (SF Symbols 5+) | symbolEffect(.pulse) requires macOS 14. Draw animations (SF Symbols 7) require macOS 26. Both safe given macOS 26+ target. |
| OllamaKit 5.0.8 | Swift 5.9+, macOS unspecified | Not chosen, but confirmed active as of March 2025. |

## Sources

- https://github.com/mattt/ollama-swift (Package.swift inspected directly -- HIGH confidence)
- https://github.com/kevinhermawan/OllamaKit (README inspected -- MEDIUM confidence)
- https://developer.apple.com/documentation/swiftui/lazyvgrid (official docs -- HIGH confidence)
- https://developer.apple.com/videos/play/wwdc2023/10258/ (SF Symbols animation API -- HIGH confidence)
- https://fatbobman.com/en/posts/concurret-programming-in-swiftdata/ (SwiftData @ModelActor patterns -- MEDIUM confidence, community source)
- https://www.hackingwithswift.com/quick-start/swiftdata/how-swiftdata-works-with-swift-concurrency (SwiftData concurrency -- MEDIUM confidence)
- https://github.com/ollama/ollama/issues/1378 (Ollama health check GET / endpoint -- HIGH confidence, official repo issue)
- SwiftData vs CoreData comparison: multiple community sources 2025 -- MEDIUM confidence

---
*Stack research for: PS Transcribe -- Ollama integration, session library, animated mic button*
*Researched: 2026-03-31*
