# Phase 8: Code Defect Fixes - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix 5 code-level defects identified by the v1.0 audit and integration check: crash recovery path, diarized speaker label collapse, source/tome rebrand tag, stray print() calls on error paths, and tech debt (transcriptStore state cleanup + LibraryEntryRow per-render I/O). No new features -- strictly defect resolution.

</domain>

<decisions>
## Implementation Decisions

### Speaker data model
- **D-01:** Add a `.named(String)` case to the `Speaker` enum so diarized labels ("Speaker 2", "Speaker 3") survive the parse round-trip. TranscriptParser maps "You" to `.you`, "Them" to `.them`, and "Speaker N" to `.named("Speaker N")`.
- **D-02:** UI displays each `.named` speaker with a distinct colored badge to visually differentiate speakers in long transcripts. Color assignment by speaker index (Speaker 2 = first color, Speaker 3 = second, etc.).

### Crash recovery flow
- **D-03:** Recovered sessions show a yellow "Incomplete" badge in the library (consistent with existing badge pattern for missing files). The badge uses `isFinalized == false` as its signal.
- **D-04:** Recovered entries are fully functional -- rename, send to Notion, load transcript all work normally. The "Incomplete" badge is informational only, not a capability gate.
- **D-05:** The existing `scanIncompleteCheckpoints()` wiring at ContentView:218 is the implementation path. Verify it works end-to-end: checkpoint file on disk -> library entry with correct filePath -> selecting entry loads transcript content.

### LibraryEntryRow caching
- **D-06:** Replace the per-render `FileManager.default.fileExists(atPath:)` call at LibraryEntryRow:80 with a `@State` variable computed once in `.onAppear`. The check refreshes when the row re-appears (scroll away and back). Stops filesystem I/O on every SwiftUI body evaluation.

### Rebrand tag (source/tome)
- **D-07:** Change `source/tome` to `source/pstranscribe` in TranscriptLogger.swift frontmatter template (line 151). Also update README.md (line 103) to match.

### Error-path logging (print -> os.Logger)
- **D-08:** Replace 3 `print()` calls on error paths with `os.Logger` using the established Phase 2 pattern: `Logger(subsystem: "com.pstranscribe.app", category: TypeName)`. Files: SystemAudioCapture.swift:177, MicCapture.swift:95, SessionStore.swift:157.

### State cleanup on stop
- **D-09:** Stopping a recording must call `transcriptStore.clear()` to remove stale utterances from memory. Verify this is wired in the stop flow (ContentView stopRecording path).

### Claude's Discretion
- Exact color palette for speaker badges (pick from existing app color tokens)
- Whether `.named` Speaker case needs Codable/Sendable conformance adjustments
- Ordering of fixes within plans (dependency-aware sequencing)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Audit evidence
- `.planning/v1.0-MILESTONE-AUDIT.md` -- Defect inventory, tech debt list, requirement gap analysis

### Speaker label round-trip
- `PSTranscribe/Sources/PSTranscribe/Storage/TranscriptParser.swift` -- Parser that collapses Speaker N to .them (line 59)
- `PSTranscribe/Sources/PSTranscribe/Storage/TranscriptLogger.swift` -- rewriteWithDiarization writes Speaker labels (line 399+)
- `PSTranscribe/Sources/PSTranscribe/Models.swift` -- Speaker enum and Utterance struct

### Crash recovery
- `PSTranscribe/Sources/PSTranscribe/Storage/SessionStore.swift` -- scanIncompleteCheckpoints definition
- `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift` -- Launch wiring (line 218), loadTranscript (line 320), stopRecording flow

### Library UI
- `PSTranscribe/Sources/PSTranscribe/Views/LibraryEntryRow.swift` -- fileExists per-render (line 80), badge display

### Logging pattern (Phase 2 established)
- `PSTranscribe/Sources/PSTranscribe/Audio/SystemAudioCapture.swift` -- print() at line 177
- `PSTranscribe/Sources/PSTranscribe/Audio/MicCapture.swift` -- print() at line 95
- `PSTranscribe/Sources/PSTranscribe/Storage/SessionStore.swift` -- print() at line 157

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `atomicRewrite` in TranscriptLogger -- established safe file mutation pattern
- `Logger(subsystem:category:)` pattern from Phase 2 -- ready to use in all 3 print() replacement sites
- Yellow/red badge pattern in LibraryEntryRow -- extend for "Incomplete" badge

### Established Patterns
- Swift 6 strict concurrency: actors for mutable state, @MainActor for UI
- `@Observable` + `@Bindable` for SwiftUI state propagation
- Session-relative HH:mm:ss timestamps (STAB-02 canonical)
- `private(set)` for read-only external access

### Integration Points
- Speaker enum change affects: TranscriptParser, TranscriptLogger (rewriteWithDiarization), ContentView (display), any test files using Speaker
- LibraryEntry.isFinalized already exists -- used by crash recovery badge and typeIconName
- transcriptStore.clear() already called at ContentView:526 -- verify it's in the stop flow

</code_context>

<specifics>
## Specific Ideas

- Speaker badges should use distinct colors per speaker index for visual differentiation in long transcripts
- "Incomplete" badge follows the same visual pattern as the existing "missing file" badge (exclamationmark.triangle.fill) but with yellow coloring

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope

</deferred>

---

*Phase: 08-code-defect-fixes*
*Context gathered: 2026-04-06*
