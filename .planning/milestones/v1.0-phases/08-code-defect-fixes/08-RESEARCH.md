# Phase 8: Code Defect Fixes - Research

**Researched:** 2026-04-06
**Domain:** Swift/SwiftUI defect repair -- Speaker enum extension, crash recovery wiring, YAML frontmatter tag, os.Logger migration, SwiftUI render optimization
**Confidence:** HIGH

## Summary

Phase 8 is a pure defect-fix phase with no new features. Five discrete bugs are being repaired: (1) crash recovery is wired but never fires because `scanIncompleteCheckpoints()` is called at app launch but the resulting entries are not connected to the library correctly when the transcript file path doesn't exist on disk, (2) diarized speaker labels collapse to `.them` on reload because `TranscriptParser` maps every non-"You" speaker to `.them` with no `.named` case on the `Speaker` enum, (3) YAML frontmatter writes `source/tome` instead of `source/pstranscribe`, (4) three error-path `print()` calls need to migrate to the `os.Logger` pattern established in Phase 2, and (5) `transcriptStore.clear()` is called on session start but not on session stop, leaving stale utterances in memory.

All five bugs have exact file and line-number attribution from the audit. No library research is required -- the stack is Swift 6 strict concurrency with `@Observable` state, actors, and SwiftUI. The implementation path is unambiguous for each defect. The Speaker enum extension is the highest-complexity change because it propagates through four files (Models.swift, TranscriptParser.swift, TranscriptLogger.swift, ContentView/TranscriptView display).

The crash recovery flow is already 90% implemented. `scanIncompleteCheckpoints()` is called at ContentView line 218 and already synthesizes `LibraryEntry` objects with `isFinalized: false`. The remaining gap is verifying that selecting such an entry loads transcript content -- the `loadTranscript` path at line 326 guards on `FileManager.default.fileExists`, which will return false if the crash happened before the transcript file was created, producing an empty view. The plan must account for this edge case.

**Primary recommendation:** Sequence the fixes from safest to riskiest -- logging fixes first (isolated, no behavior change), then frontmatter tag (single-line), then transcriptStore.clear() wiring verification, then LibraryEntryRow caching, then Speaker enum last (highest fan-out).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Add a `.named(String)` case to the `Speaker` enum so diarized labels ("Speaker 2", "Speaker 3") survive the parse round-trip. TranscriptParser maps "You" to `.you`, "Them" to `.them`, and "Speaker N" to `.named("Speaker N")`.
- **D-02:** UI displays each `.named` speaker with a distinct colored badge to visually differentiate speakers in long transcripts. Color assignment by speaker index (Speaker 2 = first color, Speaker 3 = second, etc.).
- **D-03:** Recovered sessions show a yellow "Incomplete" badge in the library (consistent with existing badge pattern for missing files). The badge uses `isFinalized == false` as its signal.
- **D-04:** Recovered entries are fully functional -- rename, send to Notion, load transcript all work normally. The "Incomplete" badge is informational only, not a capability gate.
- **D-05:** The existing `scanIncompleteCheckpoints()` wiring at ContentView:218 is the implementation path. Verify it works end-to-end: checkpoint file on disk -> library entry with correct filePath -> selecting entry loads transcript content.
- **D-06:** Replace the per-render `FileManager.default.fileExists(atPath:)` call at LibraryEntryRow:80 with a `@State` variable computed once in `.onAppear`. The check refreshes when the row re-appears (scroll away and back). Stops filesystem I/O on every SwiftUI body evaluation.
- **D-07:** Change `source/tome` to `source/pstranscribe` in TranscriptLogger.swift frontmatter template (line 151). Also update README.md (line 103) to match.
- **D-08:** Replace 3 `print()` calls on error paths with `os.Logger` using the established Phase 2 pattern: `Logger(subsystem: "com.pstranscribe.app", category: TypeName)`. Files: SystemAudioCapture.swift:177, MicCapture.swift:95, SessionStore.swift:157.
- **D-09:** Stopping a recording must call `transcriptStore.clear()` to remove stale utterances from memory. Verify this is wired in the stop flow (ContentView stopRecording path).

### Claude's Discretion

- Exact color palette for speaker badges (pick from existing app color tokens)
- Whether `.named` Speaker case needs Codable/Sendable conformance adjustments
- Ordering of fixes within plans (dependency-aware sequencing)

### Deferred Ideas (OUT OF SCOPE)

None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STAB-01 | App recovers incomplete sessions on next launch (marks as incomplete, surfaces in library) | D-03, D-04, D-05 -- wiring verified at ContentView:218; edge case documented below |
| STAB-03 | Session finalization (endSession + frontmatter + diarization) is atomic or recoverable | D-09 -- transcriptStore.clear() on stop; atomicRewrite already in place |
| REBR-03 | Package.swift target names and module references updated | D-07 -- `source/tome` -> `source/pstranscribe` in TranscriptLogger.swift:151 |
</phase_requirements>

## Standard Stack

No new libraries are required. All fixes use existing project infrastructure.

### Core (Existing -- Verified in Codebase)
| Component | Location | Purpose |
|-----------|----------|---------|
| `Speaker` enum | Models/Models.swift:3 | Speaker identity model -- needs `.named(String)` case added |
| `os.Logger` | Already imported in SessionStore.swift:2 | Structured logging -- established Phase 2 pattern |
| `@State` + `.onAppear` | SwiftUI stdlib | One-time file-exists check in LibraryEntryRow |
| `atomicRewrite` | TranscriptLogger.swift | Safe file mutation -- already used for frontmatter |
| `scanIncompleteCheckpoints()` | SessionStore.swift:97 | Returns incomplete `SessionCheckpoint` array -- already called at ContentView:218 |

**Installation:** No new packages needed. [VERIFIED: codebase inspection]

## Architecture Patterns

### Speaker Enum Extension (D-01, D-02)

**Current state** -- `Speaker` has two cases, `you` and `them`, both with raw String values for Codable. [VERIFIED: Models/Models.swift:3-6]

```swift
// CURRENT (Models/Models.swift)
enum Speaker: String, Codable, Sendable {
    case you
    case them
}
```

Adding `.named(String)` requires switching from `RawRepresentable` string enum to manual `Codable` conformance because associated values cannot be encoded with a raw value. The encoding strategy must round-trip cleanly through the JSONL session file format.

```swift
// TARGET PATTERN [ASSUMED -- no prior precedent in codebase for associated-value Codable enum]
enum Speaker: Codable, Sendable, Equatable {
    case you
    case them
    case named(String)

    // Manual Codable required -- associated values cannot use RawRepresentable
    enum CodingKeys: String, CodingKey { case type, label }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "you":   self = .you
        case "them":  self = .them
        case "named": self = .named(try c.decode(String.self, forKey: .label))
        default:      self = .them  // graceful degradation for unknown values
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .you:          try c.encode("you",  forKey: .type)
        case .them:         try c.encode("them", forKey: .type)
        case .named(let l): try c.encode("named", forKey: .type); try c.encode(l, forKey: .label)
        }
    }
}
```

**Critical risk:** Existing JSONL session files encode `Speaker` as a bare string (`"you"` / `"them"`) via the old raw-value strategy. After the enum change, `SessionRecord.speaker` decoding will fail for historical files that use the old format. The decoder must handle both old raw-string and new keyed-container formats, or historical session files become unreadable.

**Backward-compat decoder pattern:**

```swift
// In Speaker init(from decoder:) -- handle legacy raw-string format
init(from decoder: Decoder) throws {
    // First try legacy single-value (raw string) format
    if let sv = try? decoder.singleValueContainer(),
       let raw = try? sv.decode(String.self) {
        switch raw {
        case "you":  self = .you
        case "them": self = .them
        default:     self = .them
        }
        return
    }
    // Then try new keyed format
    let c = try decoder.container(keyedBy: CodingKeys.self)
    ...
}
```

### TranscriptParser Fix (D-01)

The parser regex already matches `Speaker \d+` at line 39 but maps every non-"You" result to `.them` at line 59. [VERIFIED: TranscriptParser.swift:39,59]

```swift
// CURRENT (line 59)
let speaker: Speaker = speakerStr == "You" ? .you : .them

// TARGET
let speaker: Speaker
switch speakerStr {
case "You":  speaker = .you
case "Them": speaker = .them
default:     speaker = .named(speakerStr)  // "Speaker 2", "Speaker 3", etc.
}
```

### TranscriptView Display (D-02)

`TranscriptView.swift` has a hardcoded `"You" : "Them"` display string in `UtteranceBubble` at line 69 and uses `accentColor` that only handles two cases. Named speakers need:
1. Display label: use the associated string value directly
2. Color: indexed from a palette derived from existing design tokens

**Existing color tokens** [VERIFIED: TranscriptView.swift:144-161]:
- `accent1` = lavender `#C4A0FF` -- used for "You"
- `fg2` = muted warm gray `#8A8480` -- used for "Them"
- `recordRed` = `#E85B5B`
- `bg0`, `bg1`, `bg2`, `fg1`, `fg3`

No orange, teal, or green tokens exist. The planner must pick additional named-speaker colors from within the warm palette or define new tokens. Candidates [ASSUMED -- color selection is Claude's discretion per CONTEXT.md]:
- Speaker 2: `Color(red: 0.60, green: 0.85, blue: 0.75)` -- muted teal
- Speaker 3: `Color(red: 0.95, green: 0.75, blue: 0.45)` -- warm amber
- Additional speakers: cycle or fallback to `fg2`

```swift
// UtteranceBubble accentColor -- TARGET
private var accentColor: Color {
    switch utterance.speaker {
    case .you:       return .accent1
    case .them:      return .fg2
    case .named(let label):
        return Self.namedSpeakerColor(for: label)
    }
}

private static func namedSpeakerColor(for label: String) -> Color {
    // Extract speaker number from "Speaker N"
    let palette: [Color] = [
        Color(red: 0.60, green: 0.85, blue: 0.75),  // teal
        Color(red: 0.95, green: 0.75, blue: 0.45),  // amber
    ]
    if let n = label.split(separator: " ").last.flatMap({ Int($0) }), n >= 2 {
        return palette[(n - 2) % palette.count]
    }
    return .fg2
}
```

### Crash Recovery Badge (D-03)

`LibraryEntryRow` already uses `isFinalized` to select the icon at line 144-154 [VERIFIED: LibraryEntryRow.swift:144]:

```swift
private var typeIconName: String {
    if !entry.isFinalized {
        return "exclamationmark.circle"  // already shows a different icon
    }
    ...
}
```

The "Incomplete" yellow badge (D-03) needs to be added alongside the existing missing-file red badge. The existing missing-file badge is at line 80 [VERIFIED: LibraryEntryRow.swift:80]:

```swift
// EXISTING missing-file badge (line 80)
if !FileManager.default.fileExists(atPath: entry.filePath) {
    Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(Color.recordRed)
}

// NEW Incomplete badge -- add BEFORE missing-file check
if !entry.isFinalized {
    Image(systemName: "clock.badge.exclamationmark.fill")
        .foregroundStyle(Color.yellow.opacity(0.85))
        .help("Session was interrupted -- transcript may be incomplete")
        .padding(.top, 4)
}
```

Note: `entry.isFinalized` being false on crash-recovered entries only works if the scanned checkpoint produces a `LibraryEntry` with `isFinalized: false`. The ContentView wiring at line 224 already sets `isFinalized: false` on recovered entries [VERIFIED: ContentView.swift:224-235].

### Crash Recovery Load Path Edge Case (D-05)

When a crash-recovered entry is selected, the `onChange(of: selectedEntryID)` handler at ContentView:326 checks `FileManager.default.fileExists(atPath: entry.filePath)` before loading. If the crash happened before the transcript file was written, `filePath` will be the `transcriptPath` from the checkpoint (the JSONL session file in ApplicationSupport), not a vault markdown file.

**Verification needed:** Does the recovered entry's `filePath` point to the JSONL session file (which exists) or the vault markdown transcript (which may not exist)? If the JSONL file is used as `filePath`, `parseTranscript(at:)` will fail because JSONL is not markdown format.

Looking at ContentView:224-235 [VERIFIED]:
```swift
let entry = LibraryEntry(
    ...
    filePath: checkpoint.transcriptPath,  // this is the JSONL session file path
    ...
)
```

And `SessionCheckpoint.transcriptPath` is set in `SessionStore.startSession()` at line 140:
```swift
transcriptPath: currentFile!.path,  // currentFile is the session_YYYY-MM-DD.jsonl file
```

This means crash-recovered entries point to a JSONL file, not a markdown transcript. `parseTranscript(at:)` expects markdown format. The load will either error silently or produce empty utterances. The planner must address this: either the crash recovery creates a stub markdown file from the JSONL, or the load path detects JSONL and degrades gracefully, or the filePath is left empty and the "no file" badge fires.

Decision D-04 says recovered entries should "load transcript content" when selected -- this requires resolving the JSONL vs markdown conflict. [ASSUMED: leaving filePath empty and showing "no transcript" may be the pragmatic resolution -- user confirms via D-05 verify step.]

### LibraryEntryRow Caching (D-06)

```swift
// CURRENT (line 80) -- runs on every body evaluation
if !FileManager.default.fileExists(atPath: entry.filePath) { ... }

// TARGET -- @State cached, refreshes on re-appear
@State private var fileExists: Bool = true

var body: some View {
    // ... (use fileExists instead of inline call)
    if !fileExists { ... }
    // ...
}
.onAppear {
    fileExists = FileManager.default.fileExists(atPath: entry.filePath)
}
```

### Frontmatter Tag (D-07)

Single-line change in TranscriptLogger.swift:151 [VERIFIED: TranscriptLogger.swift:151]:

```swift
// CURRENT
  - source/tome

// TARGET
  - source/pstranscribe
```

### Logging Migration (D-08)

Three sites [VERIFIED by codebase inspection]:

**SystemAudioCapture.swift:177** -- `nonisolated func stream(_:didStopWithError:)` -- needs a `nonisolated` logger or a local `Logger` creation since `nonisolated` context cannot access actor-stored properties:

```swift
// Current (line 177)
print("SystemAudioCapture: stream stopped with error: \(error)")

// Target -- nonisolated context requires local Logger creation
nonisolated func stream(_ stream: SCStream, didStopWithError error: any Error) {
    let log = Logger(subsystem: "com.pstranscribe.app", category: "SystemAudioCapture")
    log.error("Stream stopped with error: \(error.localizedDescription, privacy: .public)")
    _sysContinuation.withLock { $0?.finish(); $0 = nil }
}
```

**MicCapture.swift:95** -- inside a closure, actor context likely available:

```swift
// Current
print("[MIC-8-FAIL] \(msg)")

// Target -- use file-level Logger instance (Phase 2 pattern)
log.error("Mic failed: \(error.localizedDescription, privacy: .public)")
```

**SessionStore.swift:157** -- inside `appendRecord()` actor method:

```swift
// Current
print("SessionStore: failed to write record: \(error)")

// Target -- SessionStore already has `let log = Logger(...)` at line 18
log.error("Failed to write record: \(error.localizedDescription, privacy: .public)")
```

Note: SystemAudioCapture needs to verify whether it already has a stored `log` property. If it does, accessing it from a `nonisolated` method requires it to be `nonisolated` too, or use a local `Logger` instance.

### transcriptStore.clear() Wiring (D-09)

`startSession()` calls `transcriptStore.clear()` at line 526 [VERIFIED: ContentView.swift:526]. The audit confirmed `stopSession()` does NOT call `clear()`. The stop flow at lines 619-703 [VERIFIED: ContentView.swift:619-703] ends with `refreshLibrary()` and `selectedEntryID = entryID` but never clears the store.

**Fix:** Add `transcriptStore.clear()` at the top of `stopSession()` -- or at the point where `activeSessionType` is set to nil (line 628), which is where the live recording view transitions to the library view. Calling clear before loading the final transcript ensures the transcript is populated from the parsed file rather than live state.

However: `stopSession()` then calls `loadedUtterances = try parseTranscript(at: finalURL)` at line 690. If `transcriptStore.clear()` is called in `stopSession()`, the `loadedUtterances` that were copied from `transcriptStore.utterances` at line 664 (`let firstLine = transcriptStore.utterances.first?.text`) must be captured BEFORE clearing.

**Safe sequence:**
1. Capture `firstLine = transcriptStore.utterances.first?.text` (line 664 -- already done before clear would happen)
2. Call `transcriptStore.clear()` after `activeSessionType = nil` (line 628)
3. Final `loadedUtterances` is set from `parseTranscript` at line 690, not from store

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Enum Codable with associated values | Custom JSON serialization | Swift's `Codable` with manual `CodingKeys` | Type safety, compiler-checked exhaustiveness |
| File mutation | Read-modify-write with temp file | `atomicRewrite` already in TranscriptLogger | Already solves write-failure atomicity |
| Speaker color palette | New design system | Extend existing `Color` extension in TranscriptView.swift | Keeps all design tokens in one place |
| Logger setup | New logging abstraction | `os.Logger(subsystem:category:)` directly | Phase 2 established this as canonical |

## Common Pitfalls

### Pitfall 1: Speaker Codable Backward Compatibility
**What goes wrong:** Changing `Speaker` from `enum Speaker: String` to a manual Codable breaks decoding of existing JSONL session files that stored `"you"` or `"them"` as bare strings.
**Why it happens:** Swift's `RawRepresentable` Codable encodes as a single value; manual `CodingKeys` container encodes as a dictionary -- completely different JSON shapes.
**How to avoid:** Implement a two-path `init(from decoder:)` that tries `singleValueContainer()` first (legacy) and falls back to `keyedContainer()` (new format).
**Warning signs:** Tests that decode an `Utterance` from a fixed JSON string -- they will fail if backward compat is broken.

### Pitfall 2: nonisolated Method Cannot Access Actor-Stored Logger
**What goes wrong:** `SystemAudioCapture` is an actor. `stream(_:didStopWithError:)` is `nonisolated` (required by `SCStreamDelegate`). An actor-stored `let log = Logger(...)` property cannot be accessed from a `nonisolated` function without hopping to the actor.
**Why it happens:** Swift 6 strict concurrency -- `nonisolated` methods cannot read actor-isolated stored properties.
**How to avoid:** Create a `Logger` instance inline inside the `nonisolated` method, or mark the `log` property `nonisolated` (safe since `Logger` is a struct and creating one is cheap).
**Warning signs:** Swift compiler error "actor-isolated property 'log' can not be referenced from a nonisolated context."

### Pitfall 3: Crash Recovery filePath Points to JSONL, Not Markdown
**What goes wrong:** `parseTranscript(at:)` expects markdown format. Crash-recovered entries set `filePath` to the JSONL session file. Selecting a recovered entry silently produces empty utterances.
**Why it happens:** `SessionCheckpoint.transcriptPath` stores the JSONL path, not the vault markdown path (which may not exist if the crash happened early).
**How to avoid:** Either: (a) leave `filePath` empty for recovered entries and rely on the "no file" guard, or (b) verify whether the markdown file was written by checking completedSteps, or (c) derive the expected markdown path from the checkpoint and check that path instead.
**Warning signs:** Selecting a crashed session shows blank transcript view with no error.

### Pitfall 4: transcriptStore.clear() Before firstLine Capture
**What goes wrong:** If `transcriptStore.clear()` is placed too early in `stopSession()`, `transcriptStore.utterances.first?.text` returns nil and `firstLinePreview` is lost.
**Why it happens:** `stopSession()` captures `firstLine` from the live store before the session file is parsed back.
**How to avoid:** Call `transcriptStore.clear()` AFTER capturing `firstLine` at line 664. The existing line order already captures first before clearing would happen if clear is placed at line 628 (before the Task block).

### Pitfall 5: Speaker enum Exhaustive Switch Exhaustion
**What goes wrong:** Adding `.named(String)` to `Speaker` breaks every `switch speaker` statement that previously had only `.you` / `.them`. Compiler will catch all of them, but there may be test files or view files that need updating.
**Why it happens:** Swift requires exhaustive switching on enums.
**How to avoid:** After adding the case, compile and fix all switch exhaustiveness errors. Files to check: TranscriptView.swift (UtteranceBubble.accentColor, VolatileIndicator.accentColor), ContentView.swift line 711 (`speakerName`), any test files.

## Code Examples

### Logger in nonisolated SCStreamDelegate method
```swift
// Source: Phase 2 established pattern (os.Logger) + Swift 6 nonisolated constraint
nonisolated func stream(_ stream: SCStream, didStopWithError error: any Error) {
    let log = Logger(subsystem: "com.pstranscribe.app", category: "SystemAudioCapture")
    log.error("Stream stopped with error: \(error.localizedDescription, privacy: .public)")
    _sysContinuation.withLock { $0?.finish(); $0 = nil }
}
```

### LibraryEntryRow file-exists caching
```swift
// Source: D-06 decision + SwiftUI @State pattern [ASSUMED pattern, standard SwiftUI]
struct LibraryEntryRow: View {
    // ... existing properties ...
    @State private var fileExists: Bool = true

    var body: some View {
        // ... replace inline FileManager call with fileExists variable ...
        if !fileExists && !entry.filePath.isEmpty {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.recordRed)
                .help("File has been moved or deleted")
                .padding(.top, 4)
        }
        // ...
    }
    .onAppear {
        guard !entry.filePath.isEmpty else { fileExists = true; return }
        fileExists = FileManager.default.fileExists(atPath: entry.filePath)
    }
}
```

## State of the Art

No external library changes. The state-of-the-art for this phase is internal codebase patterns.

| Pattern | Current State | Target State |
|---------|--------------|--------------|
| Speaker enum | `String` raw value, 2 cases | Manual Codable, 3 cases with backward compat |
| Error logging | Mix of `print()` and `os.Logger` | Uniform `os.Logger` on all error paths |
| LibraryEntryRow I/O | FileManager.fileExists per render | @State cached, refreshed on appear |
| Crash recovery | Wired but missing content load verification | End-to-end verified with edge case handled |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Crash-recovered `filePath` points to JSONL session file, not vault markdown | Architecture Patterns -- Crash Recovery Edge Case | If JSONL is parseable or filePath is set differently, the edge case is a non-issue |
| A2 | `SystemAudioCapture` does not already have a `nonisolated let log` property | Logging Migration pattern | If it does, no inline Logger needed |
| A3 | Speaker color candidates (teal, amber) for `.named` display | Architecture Patterns -- TranscriptView | Colors are Claude's discretion; any warm-palette extension is valid |
| A4 | `firstLine` capture at ContentView:664 happens outside the Task block | transcriptStore.clear() timing | Must verify Task block boundaries to confirm safe ordering |

## Open Questions

1. **Crash recovery -- JSONL vs markdown path**
   - What we know: `checkpoint.transcriptPath` stores the JSONL session file path (SessionStore.swift:140)
   - What's unclear: Whether the vault markdown file path is derivable from the checkpoint, and whether D-04 ("load transcript content works") requires actual transcript rendering or just surfacing the entry
   - Recommendation: Plan task must explicitly verify end-to-end by checking `completedSteps` -- if `"transcript_written"` is in completedSteps, a markdown file may exist at a predictable vault path; if not, show empty transcript gracefully

2. **Incomplete badge vs missing-file badge co-display**
   - What we know: Both badges live in the same HStack trailing region in LibraryEntryRow
   - What's unclear: Can both badges show simultaneously (isFinalized=false AND file missing)?
   - Recommendation: Show Incomplete badge when `!entry.isFinalized`; show missing-file badge only when `entry.isFinalized && !fileExists`. Incomplete sessions that have no file are just "incomplete", not "missing".

## Environment Availability

Step 2.6: SKIPPED -- phase is code-only changes, no external tools or services required beyond the existing Xcode toolchain.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (swift-testing package) |
| Config file | Package.swift -- test target defined |
| Quick run command | `swift test --filter TranscriptParserTests` |
| Full suite command | `swift test` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STAB-01 | Crash recovery surfaces incomplete session in library | Integration (manual) | manual -- requires crash simulation | N/A (manual) |
| STAB-03 | stopSession clears transcriptStore state | Unit | `swift test --filter TranscriptStoreTests` | ❌ Wave 0 |
| REBR-03 | Frontmatter writes `source/pstranscribe` | Unit | `swift test --filter TranscriptLoggerTests` | ❌ Wave 0 (or grep verify) |
| D-01 | Speaker.named round-trips through Codable | Unit | `swift test --filter SpeakerCodableTests` | ❌ Wave 0 |
| D-01 | Speaker legacy raw-string decodes correctly | Unit | `swift test --filter SpeakerCodableTests` | ❌ Wave 0 |
| D-01 | TranscriptParser maps "Speaker N" to .named | Unit | `swift test --filter TranscriptParserTests` | ✅ (existing file -- add cases) |

### Sampling Rate
- **Per task commit:** `swift test --filter` on the relevant test file
- **Per wave merge:** `swift test` (full suite)
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `Tests/PSTranscribeTests/SpeakerCodableTests.swift` -- covers Speaker Codable round-trip and legacy decode
- [ ] `Tests/PSTranscribeTests/TranscriptStoreTests.swift` -- covers clear() called on stop

*(The TranscriptParser test file already exists -- check for "Speaker N" test coverage and add if missing.)*

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | -- |
| V3 Session Management | no | -- |
| V4 Access Control | no | -- |
| V5 Input Validation | no | Parsing is internal; no external input |
| V6 Cryptography | no | -- |

**Note:** Replacing `print()` with `os.Logger` is itself a security improvement -- `os.Logger` with `privacy: .public` ensures sensitive data (transcript content, file paths) is not logged in plaintext to system logs. All three replacement sites use `error.localizedDescription` (not transcript content), so `privacy: .public` is appropriate.

## Sources

### Primary (HIGH confidence)
- `PSTranscribe/Sources/PSTranscribe/Models/Models.swift` -- Speaker enum current definition
- `PSTranscribe/Sources/PSTranscribe/Storage/TranscriptParser.swift` -- speaker mapping bug at line 59
- `PSTranscribe/Sources/PSTranscribe/Storage/TranscriptLogger.swift` -- frontmatter template at line 151, rewriteWithDiarization at line 399+
- `PSTranscribe/Sources/PSTranscribe/Storage/SessionStore.swift` -- scanIncompleteCheckpoints at line 97, appendRecord print() at line 157
- `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift` -- crash recovery wiring at line 218, stopSession at line 619, transcriptStore.clear() at line 526
- `PSTranscribe/Sources/PSTranscribe/Views/LibraryEntryRow.swift` -- fileExists per-render at line 80, badge display
- `PSTranscribe/Sources/PSTranscribe/Views/TranscriptView.swift` -- design tokens, UtteranceBubble speaker display
- `PSTranscribe/Sources/PSTranscribe/Audio/SystemAudioCapture.swift` -- print() at line 177
- `PSTranscribe/Sources/PSTranscribe/Audio/MicCapture.swift` -- print() at line 95
- `.planning/v1.0-MILESTONE-AUDIT.md` -- defect inventory and tech debt list
- `.planning/phases/08-code-defect-fixes/08-CONTEXT.md` -- locked decisions

### Secondary (MEDIUM confidence)
- Swift 6 documentation on actor isolation and nonisolated methods -- informs Logger placement in nonisolated delegate method
- Swift `Codable` documentation on associated-value enums -- informs backward-compat decoder strategy

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Defect identification: HIGH -- all five bugs have exact file+line attribution from codebase inspection and audit
- Fix patterns: HIGH for 4 of 5 bugs; MEDIUM for Speaker enum (backward-compat decoder is non-trivial, A1-A4 in assumptions log)
- Crash recovery edge case: MEDIUM -- JSONL vs markdown path conflict identified but resolution requires planner decision

**Research date:** 2026-04-06
**Valid until:** 2026-05-06 (stable codebase -- no fast-moving dependencies)
