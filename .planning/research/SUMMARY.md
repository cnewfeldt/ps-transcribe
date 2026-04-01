# Project Research Summary

**Project:** PS Transcribe (formerly Tome) -- macOS local transcription app
**Domain:** macOS native audio transcription with on-device LLM integration
**Researched:** 2026-03-31
**Confidence:** HIGH (architecture grounded in real codebase; stack and pitfalls verified against official sources)

## Executive Summary

PS Transcribe is a shipped macOS native app (v1.2.1) that captures dual-stream audio (mic + system) and transcribes it locally using Parakeet-TDT via FluidAudio. The next milestone adds three major capabilities: a session library (grid of past recordings with metadata), an Ollama-powered live LLM analysis panel, and a series of security and UX hardening items identified in a codebase audit. The recommended approach follows the existing architectural pattern: Swift 6 actors for I/O, @Observable @MainActor wrappers for UI state, and SwiftUI views bound to those observables. All new capabilities fit cleanly into this pattern without requiring new frameworks or major structural changes.

The most important architectural decision is that LLM analysis must be completely decoupled from the transcription pipeline. Ollama runs on localhost as an external process; if it is not running, the recording and transcription features must be unaffected. The session library requires a new lightweight index file (sessions-index.json in AppSupport) rather than repurposing the existing per-session JSONL crash recovery files. Both are greenfield additions with no required changes to existing audio or transcription code.

The highest-risk work is the rebrand and security hardening, not the new features. A bundle ID change silently destroys UserDefaults (vault paths, all settings) for existing users and can break the Sparkle update chain permanently if not handled before the first renamed release ships. The security audit identified 12 findings that must be resolved before launch. These are pre-launch blockers that must come before the feature work, not after.

## Key Findings

### Recommended Stack

The existing Swift 6 / SwiftUI / FluidAudio / Sparkle stack is solid and does not need replacement. New capabilities require one optional new dependency (mattt/ollama-swift for Ollama HTTP with NDJSON streaming) and three built-in system frameworks (SwiftData for persistence, LazyVGrid for the library grid, SF Symbols symbolEffect() for mic button animation). Architecture research noted that rolling a thin ~80-line OllamaClient actor using URLSession.bytes is also viable and avoids the dependency entirely -- the tradeoff favors the dependency-free approach given the codebase's pattern of direct URLSession usage elsewhere.

**Core technologies:**
- `mattt/ollama-swift` (optional): Ollama HTTP client -- zero dependencies, swift-tools-version 6.0, AsyncSequence streaming. Alternative: URLSession.bytes + JSONDecoder in ~80 lines.
- `SwiftData`: Session library persistence -- @Model macro, @Query reactivity in views, @ModelActor for background writes. Target is macOS 26, well within SwiftData's macOS 14+ requirement.
- `SwiftUI LazyVGrid`: Session library grid -- native, lazy-rendered, .adaptive column sizing. No third-party grid library needed.
- `SF Symbols symbolEffect()`: Three-state mic button animation -- .pulse for recording state, .replace transition between symbols. Available macOS 14+, target is macOS 26.

### Expected Features

The research draws a clear line between features that must ship in this milestone (P1) and features that require Ollama integration to stabilize first (P2). The session library and lifecycle fixes are P1 because they are prerequisites for everything else -- naming, Obsidian links, missing-file detection, and LLM analysis storage all depend on sessions being reliably indexed.

**Must have (table stakes for this milestone):**
- Session library with grid view and stable file paths -- users expect a history of recordings; absence feels like data loss
- Proper session lifecycle (stop -> save -> index, no silent overwrite) -- prerequisite for reliable library
- Recording naming (before/during/after, date fallback) -- the library's UX anchor
- Three-state mic button (idle/recording/error) -- surfaces the silent failure state competitors are criticized for
- ASR model onboarding (download prompt, progress, success/fail) -- new installs are broken without this
- Missing-file detection in library -- low cost, high trust value
- Obsidian deep links from library -- low complexity, high value for the target audience
- Security hardening (12 findings from SECURITY-SCAN.md) -- pre-launch blockers

**Should have (differentiators, P2 after P1 is stable):**
- Ollama detection/configuration + model browser -- must be discrete and stable before the analysis panel is wired up
- Live LLM analysis panel (summary, action items, key topics during recording) -- the primary differentiator; no competitor does this fully offline

**Defer to later milestone or never:**
- Calendar integration -- scope creep, privacy surface, not aligned with intentional-recording UX
- Cloud sync -- violates offline-first contract; let the vault path be a cloud-synced folder if users want it
- Video recording -- permanently out of scope

### Architecture Approach

The new components follow the existing actor + @Observable service pair pattern. Each I/O subsystem gets a raw actor (OllamaClient, SessionIndexActor) and a @MainActor @Observable wrapper (OllamaService, SessionLibrary) that views bind to. The InsightsPanel is a read-only consumer of OllamaService state -- it never touches TranscriptStore or the transcription pipeline directly. ContentView coordinates the session lifecycle (stop -> TranscriptLogger.finalizeFrontmatter -> SessionIndexActor.appendEntry) and triggers Ollama analysis on utterance batch thresholds.

**Major components:**
1. `SessionIndexActor` (actor) -- reads/writes sessions-index.json in AppSupport; one lightweight SessionEntry per completed session
2. `SessionLibrary` (@Observable, @MainActor) -- wraps SessionIndexActor; drives LibraryView via @Query-like pattern
3. `LibraryView` -- SwiftUI grid using LazyVGrid; reads SessionLibrary; checks FileManager.fileExists per entry at render time
4. `OllamaClient` (actor) -- raw HTTP to localhost:11434; health check, model list, streaming chat via URLSession.bytes + .lines
5. `OllamaService` (@Observable, @MainActor) -- wraps OllamaClient; exposes connection status, available models, streaming chunks, accumulated insights
6. `InsightsPanel` -- SwiftUI view; reads OllamaService only; shown/hidden via HStack + withAnimation in ContentView
7. `ContentView` (modified) -- adds split-view layout, wires session lifecycle to SessionIndexActor, triggers OllamaService.analyzeTranscript on utterance batches

### Critical Pitfalls

1. **UserDefaults silently lost on bundle ID change** -- Implement a migration at first launch that copies keys from the old domain (group.Tome / io.github.gremble.Tome) to the new domain before anything reads settings. This must ship in the first rebrand release. Recovery after the fact requires asking users to re-enter vault paths.

2. **Sparkle appcast breaks after rebrand** -- Never reset CFBundleVersion. The SUFeedURL must stay consistent or existing installs must receive a transitional update pointing to the new feed before the old feed is retired. Test end-to-end with a staging appcast before any public release.

3. **Sequential try? fixes cause data loss** -- The TranscriptLogger.swift write/remove/move sequence has no rollback. Bulk-replacing try? with try + catch without auditing each call site will lose transcripts on mid-sequence failure. Fix cleanup-type try? instances first (safe), then tackle file I/O sequences with explicit rollback.

4. **Ollama unavailability hangs the recording pipeline** -- Always health-check GET http://127.0.0.1:11434/ with a 2-second timeout before any generation request. LLM analysis failure must never affect transcript capture. Never initiate a streaming request unless health check passes.

5. **Ollama context window silently truncates long transcripts** -- Always set num_ctx explicitly (minimum 16384 for live transcription use). The default 2048-4096 token window means summaries of meetings longer than ~15 minutes are silently wrong. Use a sliding window strategy for very long sessions.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Rebrand and Security Hardening
**Rationale:** The bundle ID change and 12 security findings are pre-launch blockers that affect every user. These must be addressed before any feature work ships. Doing this first prevents the catastrophic UserDefaults data loss scenario and fixes the Sparkle update chain while the user base is still small.
**Delivers:** Clean bundle ID, migrated UserDefaults, hardened file I/O, fixed CI keychain, pinned GitHub Actions, correct FileProtectionType attributes, Sparkle migration plan locked in.
**Addresses:** Security hardening (P1 in feature research), all 12 SECURITY-SCAN.md findings.
**Avoids:** Pitfalls 1 (UserDefaults loss), 2 (Sparkle break), 3 (try? data loss), security mistakes table in PITFALLS.md.

### Phase 2: Session Lifecycle and Library
**Rationale:** The session library is the foundational UI surface that all other new features depend on. Recording naming, Obsidian links, missing-file detection, and LLM analysis storage all require indexed sessions with stable file paths. Fix the lifecycle (stop -> save -> index) before building the grid that displays it.
**Delivers:** SessionIndexActor, SessionEntry model, SessionLibrary observable, LibraryView grid, recording naming (before/during/after), missing-file detection, Obsidian deep links.
**Uses:** SwiftData (or JSONL index -- architecture research recommends a lightweight sessions-index.json over SwiftData for this simple schema), SwiftUI LazyVGrid.
**Implements:** SessionIndexActor + SessionLibrary architecture components; ContentView session lifecycle modifications.
**Avoids:** Anti-pattern of repurposing JSONL crash recovery files as the library index (ARCHITECTURE.md anti-pattern 3).

### Phase 3: UX Polish and Onboarding
**Rationale:** The three-state mic button and ASR model onboarding are table-stakes items that are relatively self-contained. They do not depend on the session library or Ollama. Shipping them with Phase 2 is possible but keeping them discrete makes each phase verifiable independently.
**Delivers:** Three-state mic button (idle/recording/error with SF Symbols symbolEffect), ASR model download prompt with progress on first launch, graceful error messaging throughout.
**Uses:** SF Symbols symbolEffect() (.pulse, .replace), existing TranscriptionEngine error propagation.
**Implements:** ControlBar modifications, OnboardingView updates.
**Avoids:** UX pitfall of removing waveform with no replacement confidence indicator (PITFALLS.md UX pitfalls).

### Phase 4: Ollama Integration
**Rationale:** Ollama integration is its own discrete product surface. It requires a health check architecture, model browser, and decoupled async design that must be solid before the live analysis panel is wired to the recording pipeline. Separating Ollama setup from the analysis panel allows each to be validated independently.
**Delivers:** OllamaClient actor, OllamaService observable, Ollama server detection with OllamaState enum (.notInstalled / .notRunning / .modelNotLoaded / .ready), in-app model browser with download progress, Settings UI for Ollama endpoint configuration.
**Uses:** URLSession.bytes + .lines for NDJSON streaming (or mattt/ollama-swift 1.8.0 -- decision to be made at phase start).
**Implements:** OllamaClient + OllamaService architecture components; Ollama health check flow.
**Avoids:** Pitfall 4 (Ollama hangs recording pipeline), anti-pattern 1 (HTTP calls on MainActor), integration gotchas table (URLSession.data vs URLSession.bytes, /api/tags vs / for health check).

### Phase 5: Live LLM Analysis Panel
**Rationale:** The differentiating feature of the product. Depends on Phase 4 (Ollama) being stable and Phase 2 (session lifecycle) being reliable. Wire the OllamaService into the recording pipeline only after both are independently verified.
**Delivers:** InsightsPanel view (summary, action items, key topics), split-view layout in ContentView, utterance batch threshold triggering, in-flight task cancellation on new utterance batch, accumulated insights stored alongside session.
**Implements:** InsightsPanel component, ContentView split-view layout, OllamaService.analyzeTranscript wired to handleNewUtterance.
**Avoids:** Pitfall 5 (context truncation -- set num_ctx minimum 16384), anti-pattern 2 (trigger on every utterance -- debounce with 5-utterance or 30-second threshold), NavigationSplitView for the panel (use HStack + withAnimation).

### Phase Ordering Rationale

- Phase 1 (rebrand/security) must come first because a bundle ID change after features ship doubles the migration complexity and creates two cohorts of users with different stored state.
- Phase 2 (session library) unblocks Phase 5 (LLM analysis storage) -- without indexed sessions, there is nowhere to persist analysis results.
- Phase 4 (Ollama integration) must be stable and decoupled before Phase 5 wires it into the recording loop -- a flaky Ollama integration in the recording pipeline is worse than no integration.
- Phases 3 (UX polish) and 4 (Ollama) are independent and could run in parallel if multiple developers are available.
- The build order in ARCHITECTURE.md (SessionEntry -> SessionIndexActor -> SessionLibrary -> LibraryView -> OllamaClient -> OllamaService -> InsightsPanel -> ContentView integration) should be followed within each phase.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 4 (Ollama Integration):** Decision between mattt/ollama-swift and a hand-rolled URLSession client needs to be made with current package inspection. The architecture research recommends hand-rolling (~80 lines) but this should be confirmed against the current ollama-swift API surface if structured outputs are anticipated.
- **Phase 5 (Live LLM Analysis):** The sliding window strategy for long transcripts (>16K tokens) needs a concrete implementation design. The right chunking approach (fixed token count vs. utterance-boundary-aware) affects analysis quality and is non-trivial.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Security Hardening):** All findings are documented with specific fixes in PITFALLS.md and SECURITY-SCAN.md. No new research needed.
- **Phase 2 (Session Library):** LazyVGrid, SessionIndexActor pattern, and file-based index approach are well-documented with working examples in ARCHITECTURE.md.
- **Phase 3 (UX Polish):** SF Symbols symbolEffect() API is stable and documented. The three-state enum pattern is well-established.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Core choices are built-in system frameworks. ollama-swift inspected directly. SwiftData patterns verified against Apple docs and community sources. |
| Features | MEDIUM | Competitor feature details from public sources; some LLM UX patterns from product reviews. The P1/P2 split is well-reasoned but competitor feature parity claims should be validated. |
| Architecture | HIGH | Existing codebase inspected directly. Ollama HTTP API verified against official docs. All architectural recommendations are grounded in actual code, not speculation. |
| Pitfalls | HIGH (codebase) / MEDIUM (Ollama) | Rebrand and security pitfalls derived from direct codebase audit -- HIGH confidence. Ollama-specific pitfalls (context truncation, timeout behavior) from community sources -- MEDIUM confidence. |

**Overall confidence:** HIGH

### Gaps to Address

- **SwiftData vs. JSONL for session index:** Architecture research recommends a lightweight sessions-index.json (JSONL/JSON array) over SwiftData for the simple session library schema. Stack research recommends SwiftData. These should be reconciled at Phase 2 planning -- the JSONL approach avoids SwiftData's @ModelActor threading complexity for a simple 5-field struct, but SwiftData provides @Query reactivity. Decision point: if @Query reactivity is wanted, use SwiftData; if simplicity and explicit control are preferred, use a JSON array with SessionIndexActor.
- **ollama-swift dependency vs. URLSession direct:** Commit to one approach at Phase 4 start. Architecture research leans toward URLSession direct (dependency-minimal, ~80 lines, matches existing codebase patterns). Stack research recommends ollama-swift. The deciding factor should be whether structured outputs or tool calling are anticipated -- if yes, take the dependency; if no, roll thin client.
- **Rebrand timing relative to feature work:** PITFALLS.md is unambiguous that rebrand must ship before features, but it is not clear from research whether the bundle ID change is already planned for the next release or a later one. This should be confirmed at roadmap creation.

## Sources

### Primary (HIGH confidence)
- Existing codebase (`ContentView.swift`, `TranscriptStore.swift`, `SessionStore.swift`, `TranscriptLogger.swift`, `Models.swift`) -- architecture and pitfall grounding
- https://github.com/mattt/ollama-swift -- Package.swift and API inspected directly
- https://developer.apple.com/documentation/swiftui/lazyvgrid -- LazyVGrid API
- https://developer.apple.com/videos/play/wwdc2023/10258/ -- SF Symbols symbolEffect() API
- https://docs.ollama.com/api/streaming -- Ollama HTTP API
- https://developer.apple.com/documentation/foundation/urlsession/asyncbytes -- URLSession.bytes pattern
- https://sparkle-project.org/documentation/publishing/ -- Sparkle version comparison behavior
- https://docs.ollama.com/faq -- Ollama context window defaults

### Secondary (MEDIUM confidence)
- https://fatbobman.com/en/posts/concurret-programming-in-swiftdata/ -- SwiftData @ModelActor patterns
- https://www.hackingwithswift.com/quick-start/swiftdata/how-swiftdata-works-with-swift-concurrency -- SwiftData concurrency
- MacWhisper, Granola, Meetily public feature documentation -- competitor feature analysis
- https://www.arsturn.com/blog/what-happens-when-you-exceed-the-token-context-limit-in-ollama -- Ollama context truncation behavior
- https://useyourloaf.com/blog/swiftui-tasks-blocking-the-mainactor/ -- SwiftUI main actor task blocking

### Tertiary (LOW confidence)
- Sparkle version numbering issue: https://github.com/openclaw/openclaw/issues/26965 -- referenced for rebrand version reset pitfall; needs validation against current Sparkle 2.9.0 behavior

---
*Research completed: 2026-03-31*
*Ready for roadmap: yes*
