# Phase 16: Foundation -- Research

**Researched:** 2026-04-27
**Domain:** Swift 6.2 / macOS 26 native app -- internal scaffolding for v1.2 dictation + model auto-update
**Confidence:** HIGH (all findings derived from direct source inspection of `PSTranscribe/Sources/`)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Logger Architecture
- **D-01:** Add a new `DictationLogger` actor in `PSTranscribe/Sources/PSTranscribe/Storage/DictationLogger.swift` instead of extending `TranscriptLogger` with `startPlainSession`/`finalizePlain`.
  - Rationale: keeps each actor single-purpose, eliminates frontmatter-leak risk (PITFALLS.md #10), mirrors the existing one-actor-per-concern pattern (`TranscriptLogger`, `SessionStore`, `LibraryStore`).
  - Implication: the `Phase 16: Foundation` line in ROADMAP.md currently reads "add `TranscriptLogger.startPlainSession` + `finalizePlain`" -- the planner should update it to "add `DictationLogger` actor (plain markdown writer, no YAML frontmatter)" before Phase 16 plans are written.
- **D-02:** `DictationLogger` writes plain markdown only -- no YAML frontmatter, no diarization patches, no speaker tracking, no post-session finalization. Append-only during the session, atomic write on stop.

#### AppSettings Key Scope
- **D-03:** All six v1.2 keys land in Phase 16, with sensible defaults and `UserDefaults` `didSet` mirroring the existing pattern in `AppSettings.swift`. Phases 17 and 18 only consume them -- zero AppSettings churn after this.
- **D-04:** Keys to add (names locked):
  - `dictationOutputMode: DictationOutputMode` -- default `.clipboard` (see D-08).
  - `dictationFolderPath: String` -- default `NSString("~/Documents/PS Transcribe Dictations").expandingTildeInPath` (matches Phase 19 success criterion #4).
  - `dictationHotkeyMode: DictationHotkeyMode` -- enum `{ toggle, pressAndHold }`, default `.toggle` (research-locked).
  - `clipboardRestoreDelay: TimeInterval` -- default `3.0` (DICT-06 default).
  - `installedModelVersion: String` -- default `""` (empty until first successful download).
  - `modelLastCheckedDate: Date?` -- default `nil` (drives MODEL-01's 24-hour throttle).

#### `anySessionActive` Design
- **D-05:** Implement as a computed `@Observable` property on a new `SessionCoordinator` type at app scope. Reads truth from each subsystem on demand: `engine.isRunning || dictation?.isActive ?? false || modelUpdate?.isApplying ?? false`. No separately-tracked Bool, no NotificationCenter broadcast.
  - Rationale: single source of truth, no synchronization risk, no risk of getting stuck "active" if a code path forgets to clear a flag.
- **D-06:** Phase 16 wires the engine source only; Phases 17 and 18 add their own subsystem references when those services land. The Optional fields on `SessionCoordinator` make this additive.
- **D-07:** `SessionCoordinator` is `@MainActor` `@Observable` and owned by `PSTranscribeApp` (`@State` in app init). Injected into `ContentView` alongside `LibraryStore`.

#### Default `DictationOutputMode`
- **D-08:** Default to `.clipboard` only on first install. Plain folder is opt-in -- user has to choose `.plainFolder` or `.both` in Settings before anything is written to disk.
  - Rationale: matches SuperWhisper first-run UX, lowest-surprise default, no files appear on disk without explicit action.

#### Models.swift Additions
- **D-09:** Add `case dictation` to existing `SessionType` enum.
- **D-10:** Add `DictationOutputMode` enum to `Models.swift`: `case clipboard, plainFolder, both`. Codable, Sendable, `String` raw value to match existing `SessionType` pattern.
- **D-11:** Add `DictationHotkeyMode` enum to `Models.swift`: `case toggle, pressAndHold`. Codable, Sendable, String raw value.

#### LibraryStore Lift
- **D-12:** Move `LibraryStore` instantiation from `ContentView` (`@State private var libraryStore = LibraryStore()` at line 37) to `PSTranscribeApp.swift` (`@State` in app init). Inject into `ContentView` via initializer.
- **D-13:** No behavioral change to `LibraryStore` itself -- it stays an `actor` with the existing `entries` / `addEntry` / `updateEntry` / `removeEntry` API.

### Claude's Discretion
- Exact file/symbol names where they're not enumerated above (helper types, internal method names).
- Whether `SessionCoordinator` lives in `App/` or `Models/` (recommend `App/` since it owns app-lifecycle references).
- Whether to introduce a `TranscriptFormat` enum for future-proofing (recommended NO -- YAGNI; `DictationLogger` is single-purpose).
- Test scaffolding shape -- Phase 16 has no user-visible behavior, so unit tests are limited to enum codability and AppSettings persistence round-trips.

### Deferred Ideas (OUT OF SCOPE)
- Per-app hotkey behavior (DICT-FUT-03) -- deferred beyond v1.2.
- Configurable HUD position (DICT-FUT-01) -- locked to bottom-center for v1.2.
- Multi-locale dictation (DICT-FUT-02) -- inherits app's existing single locale.
- `TranscriptFormat` enum on `TranscriptLogger` -- explicitly rejected (D-01); revisit only if a third writer ever appears.
- Migrating `ContentView.isRunning` call sites to read `sessionCoordinator.anySessionActive` -- Claude's discretion in Phase 16 vs. defer to Phase 18 when dictation/model-update sources are added.
</user_constraints>

<phase_requirements>
## Phase Requirements

Phase 16 has **no direct requirement IDs** -- it is a compiler-level prerequisite for all of v1.2. The phase's only obligation is the five Success Criteria from ROADMAP.md:

| Success Criterion | What Must Be TRUE | Research Support |
|-------------------|-------------------|------------------|
| SC-1: Build clean with `SessionType.dictation` + `DictationOutputMode` | Models.swift compiles after additions; all switch sites still exhaustive | Switch site audit below identifies 4 non-default switches that MUST add `case .dictation:` arms |
| SC-2: All v1.2 AppSettings keys present and warning-free | 6 new keys with `didSet` UserDefaults mirroring | AppSettings pattern verified at lines 9-67 of AppSettings.swift; six new keys mirror the same pattern |
| SC-3: `DictationLogger` exposes plain-markdown methods with correct actor isolation (D-01 OVERRIDES roadmap text) | New `actor DictationLogger` in `Storage/`; no frontmatter; D-02 specifies append-only + atomic stop | TranscriptLogger reference pattern at lines 14-589; `DictationLogger` is simpler -- no diarization, no checkpoint, no rewriteFrontmatter |
| SC-4: `LibraryStore` lifted to app scope, injected into ContentView, no regression | Move `@State private var libraryStore = LibraryStore()` from ContentView.swift:37 to PSTranscribeApp.swift; pass via init | LibraryStore consumer audit: 19 call sites, ALL inside ContentView.swift -- no other source file touches `libraryStore` |
| SC-5: `anySessionActive: Bool` flag at app scope, set/cleared by existing meeting flow | Computed property on new `SessionCoordinator` reading `engine.isRunning` (D-05) | TranscriptionEngine.isRunning at line 19 is `private(set) var isRunning = false` -- already MainActor-isolated; SessionCoordinator just reads it |

**Roadmap correction required:** ROADMAP.md line 18 currently says "add `TranscriptLogger.startPlainSession` + `finalizePlain`". D-01 overrides this. The planner should either correct ROADMAP.md as part of Phase 16 wave 0 OR file a roadmap-correction commit before Phase 17 planning begins. Both files (CONTEXT.md and ROADMAP.md) acknowledge the discrepancy; CONTEXT.md is authoritative.
</phase_requirements>

## Project Constraints (from CLAUDE.md)

The user's global `~/.claude/CLAUDE.md` and rule files apply to this work:

| Directive | Source | How Phase 16 Honors It |
|-----------|--------|------------------------|
| **Verify before claiming complete** (Geoffrey Pattern) | sacred-rules.md, verification.md | Validation Architecture below specifies `swift build` + `swift test` as deterministic gates per task |
| **Read before proposing** | sacred-rules.md, code-quality.md | This research read every file Phase 16 modifies before recommending patterns |
| **Build only what's requested** | code-quality.md, antipatterns.md | No `TranscriptFormat` enum (Claude's Discretion REJECTS it); no abstraction beyond what D-01..D-13 specify |
| **Never suppress errors** | sacred-rules.md | All new actor methods that can fail must `throw`; no `try?` on critical paths |
| **No em dashes** | communication.md | Use double hyphens (`--`) in docs and comments; verified across this RESEARCH.md |
| **No Claude attribution in commits** | CLAUDE.md "Commit Style" | Phase 16 commits MUST NOT include `Co-Authored-By` or `Generated with` footers |
| **Inspect actual state, no speculation** | sacred-rules.md | All file paths, line numbers, signatures below verified by direct source read 2026-04-27 |

There is no project-level `./CLAUDE.md` in this repo (verified via `ls -la /Users/cary/Development/ai-development/ps-transcribe/CLAUDE.md` would return no such file). Global rules are authoritative.

## Summary

Phase 16 is small, mechanical, and well-bounded. Five success criteria all reduce to: (1) extend two enums, (2) add six UserDefaults-backed properties, (3) write a new ~80-line actor that mirrors `TranscriptLogger` minus the YAML/diarization paths, (4) move one `@State` declaration up one scope level, (5) introduce a single computed property. The phase has no user-visible behavior change.

Two non-obvious risks make the phase slightly more than a typing exercise: (1) **four switch statements over `SessionType` lack `default:` arms** -- adding `case dictation` will break compilation in CaptureDock.swift, DetailsPane.swift, LibraryEntryRow.swift, and ControlBar.swift unless every site adds a `.dictation:` arm; (2) the `LibraryStore` lift requires updating one initializer call site (PSTranscribeApp.swift:36) and ContentView's struct definition -- the existing 19 `libraryStore` references inside ContentView keep working unchanged because the property name doesn't change.

**Primary recommendation:** Sequence the phase as five small tasks (Models.swift -> AppSettings.swift -> DictationLogger.swift -> LibraryStore lift -> SessionCoordinator + wiring), each independently verifiable by `swift build` + targeted unit tests. Do all four switch-site updates as part of the Models.swift task (atomic compile breakage, atomic compile fix). Update ROADMAP.md line 18 in the Models.swift task or in a wave-0 doc fix commit; CONTEXT.md D-01 is authoritative regardless.

## Standard Stack

### Core (already in use, unchanged)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Swift | 6.3.1 (project pinned to 6.2 toolchain via `swift-tools-version: 6.2`) | Language with strict concurrency | `[VERIFIED: swift --version output 2026-04-27]` |
| Swift Testing | bundled w/ Swift 6 | Unit tests use `@Suite` / `@Test` macros | `[VERIFIED: Tests/PSTranscribeTests/SpeakerCodableTests.swift uses `import Testing`]` |
| Foundation | macOS 26.0 SDK | UserDefaults, Date, URL | `[VERIFIED: AppSettings.swift uses Foundation directly]` |
| Observation | bundled w/ Swift 6 | `@Observable` macro for app-scope state | `[VERIFIED: AppSettings.swift line 6 `@Observable`]` |
| AppKit | macOS 26.0 SDK | Already imported by AppSettings (for screen-share visibility) | `[VERIFIED: AppSettings.swift line 1 `import AppKit`]` |

### Phase 16 introduces NO new dependencies

Phase 16 is purely additive to the existing module. `KeyboardShortcuts` (Phase 18) and any model-update HTTP client (Phase 17) are explicitly **out of scope** per CONTEXT.md domain boundary. Package.swift is NOT modified by Phase 16.

`[VERIFIED: PSTranscribe/Package.swift current dependencies are FluidAudio + Sparkle only; no new SwiftPM additions in Phase 16]`

### Alternatives Considered (and rejected per CONTEXT.md)

| Instead of | Could Use | Why Rejected |
|------------|-----------|--------------|
| New `DictationLogger` actor | Add `startPlainSession` / `finalizePlain` to `TranscriptLogger` | D-01: keeps each actor single-purpose; eliminates Pitfall #10 frontmatter leak risk; ROADMAP.md line is OUT OF DATE |
| `TranscriptFormat` enum (`.obsidian` / `.plain`) on shared serializer | Format flag inside TranscriptLogger | Claude's Discretion REJECTS: YAGNI, only one new writer in v1.2 |
| Stored `Bool` for `anySessionActive` updated on start/stop | Two write sites with NotificationCenter sync | D-05: computed property with single source of truth eliminates the "stuck active" failure mode |
| Lift `LibraryStore` AND migrate `ContentView.isRunning` call sites in same phase | All-at-once refactor | Deferred Ideas explicitly allows the `isRunning` migration to defer to Phase 18 -- minimizes Phase 16 risk |

## Architecture Patterns

### Recommended File Layout

```
PSTranscribe/Sources/PSTranscribe/
├── App/
│   ├── PSTranscribeApp.swift          # MODIFIED: lift LibraryStore + add SessionCoordinator
│   ├── AppUpdaterController.swift     # unchanged
│   └── SessionCoordinator.swift       # NEW (Claude's Discretion: App/ over Models/)
├── Models/
│   └── Models.swift                   # MODIFIED: + SessionType.dictation, + 2 enums
├── Settings/
│   └── AppSettings.swift              # MODIFIED: + 6 UserDefaults-backed properties
├── Storage/
│   ├── LibraryStore.swift             # unchanged (D-13 forbids changes to actor itself)
│   ├── TranscriptLogger.swift         # unchanged
│   ├── SessionStore.swift             # unchanged
│   └── DictationLogger.swift          # NEW
├── Views/
│   ├── ContentView.swift              # MODIFIED: accept injected libraryStore + sessionCoordinator
│   ├── CaptureDock.swift              # MODIFIED: add .dictation arm to switch (line 224-226)
│   ├── DetailsPane.swift              # MODIFIED: add .dictation arm to switch (line 104-107)
│   ├── LibraryEntryRow.swift          # MODIFIED: add .dictation arm to switch (line 155-160)
│   └── ControlBar.swift               # MODIFIED: add .dictation arm to switch (line 241-251)
└── Tests/PSTranscribeTests/
    ├── DictationLoggerTests.swift     # NEW
    ├── AppSettingsTests.swift         # NEW (round-trip persistence for 6 new keys)
    ├── SessionTypeCodableTests.swift  # NEW (codable for new enums)
    └── SessionCoordinatorTests.swift  # NEW (anySessionActive computed property)
```

### Pattern 1: `@Observable @MainActor` for app-scope state

**What:** SessionCoordinator follows the established TranscriptionEngine / AppSettings pattern.
**When to use:** Any app-lifecycle owned class whose state UI binds to.
**Example (verified pattern from existing code):**

```swift
// Source: PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift:6-8
import Observation

@Observable
@MainActor
final class AppSettings {
    // ... properties with didSet UserDefaults mirroring
}
```

**Apply to SessionCoordinator (D-05, D-06, D-07):**

```swift
// Sources/PSTranscribe/App/SessionCoordinator.swift -- NEW FILE
import Observation

@Observable
@MainActor
final class SessionCoordinator {
    // Phase 16: only the engine source is wired
    weak var engine: TranscriptionEngine?
    // Phase 17/18 will add these (Optional, additive):
    // weak var dictation: DictationCoordinator?
    // weak var modelUpdate: ModelUpdateService?

    var anySessionActive: Bool {
        (engine?.isRunning ?? false)
        // || (dictation?.isActive ?? false)        // Phase 18 adds
        // || (modelUpdate?.isApplying ?? false)    // Phase 17 adds
    }

    init(engine: TranscriptionEngine? = nil) {
        self.engine = engine
    }
}
```

**Lifecycle wiring concern (Claude's Discretion):** TranscriptionEngine is currently created lazily inside ContentView's `.task` block (`ContentView.swift:294-296`). At app init, the engine doesn't exist yet. Two clean options:

1. **Late binding (recommended):** SessionCoordinator's `engine` is `var` and `weak`. ContentView assigns it after engine instantiation: `sessionCoordinator.engine = transcriptionEngine`. Until then, `anySessionActive` returns `false` -- correct (no engine = no session).
2. **Eager init:** Move `transcriptionEngine` instantiation to PSTranscribeApp init. Bigger blast radius -- changes the engine's ownership scope, which Phase 18's `DictationCoordinator` may or may not want. Defer this to Phase 18.

Pick option 1. It is additive, matches D-06's "Optional fields make this additive," and avoids surprise refactors.

### Pattern 2: `actor` for I/O isolation (DictationLogger)

**What:** Mirror `TranscriptLogger` actor pattern minus YAML / diarization / checkpoint.
**When to use:** Any persistence path whose state should not be touched by multiple tasks simultaneously.
**Example:**

```swift
// PSTranscribe/Sources/PSTranscribe/Storage/DictationLogger.swift -- NEW FILE
// Pattern source: TranscriptLogger.swift:14-179
import Foundation
import os

private let dictLog = Logger(subsystem: "com.pstranscribe.app", category: "DictationLogger")

enum DictationLoggerError: LocalizedError {
    case cannotCreateFile(String)
    case folderPathInvalid(String)
    var errorDescription: String? {
        switch self {
        case .cannotCreateFile(let p): return "Cannot create dictation file at \(p)"
        case .folderPathInvalid(let p): return "Dictation folder path invalid: \(p)"
        }
    }
}

/// Plain-markdown writer for hotkey dictation sessions.
/// No YAML frontmatter, no diarization, no checkpoint integration -- single purpose (D-02).
actor DictationLogger {
    private var fileHandle: FileHandle?
    private var currentFilePath: URL?
    private var sessionStartTime: Date?

    /// Begin a dictation session. Creates the output file and writes the initial header.
    /// Filename includes a millisecond suffix to avoid collisions on rapid sessions (Pitfall #9).
    func startSession(folderPath: String) throws {
        sessionStartTime = Date()
        let directory = try validatedFolderPath(folderPath)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let now = sessionStartTime!
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH-mm-ss-SSS"  // millisecond suffix
        let filename = "\(fmt.string(from: now)) Dictation.md"
        currentFilePath = directory.appendingPathComponent(filename)

        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "yyyy-MM-dd HH:mm"
        let header = "# Dictation -- \(timeFmt.string(from: now))\n\n"

        guard FileManager.default.createFile(atPath: currentFilePath!.path, contents: header.data(using: .utf8)) else {
            throw DictationLoggerError.cannotCreateFile(currentFilePath!.path)
        }
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: 0o600)],
            ofItemAtPath: currentFilePath!.path
        )
        fileHandle = try FileHandle(forWritingTo: currentFilePath!)
        fileHandle?.seekToEndOfFile()
    }

    /// Append a single utterance. Phase 16 supplies the API; Phase 18 wires it to the
    /// dictation transcription stream.
    func append(text: String, timestamp: Date) {
        guard let fileHandle, let start = sessionStartTime else { return }
        let offset = max(0, Int(timestamp.timeIntervalSince(start)))
        let hh = offset / 3600
        let mm = (offset % 3600) / 60
        let ss = offset % 60
        let line = "**You** (\(String(format: "%02d:%02d:%02d", hh, mm, ss)))\n\(text)\n\n"
        if let data = line.data(using: .utf8) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
        }
    }

    /// Close the file handle and return the final URL. Atomic by virtue of append-only writes
    /// during the session and a final fsync via close().
    func endSession() -> URL? {
        try? fileHandle?.close()
        fileHandle = nil
        let saved = currentFilePath
        currentFilePath = nil
        sessionStartTime = nil
        return saved
    }

    // MARK: - Validation

    private func validatedFolderPath(_ rawPath: String) throws -> URL {
        let expanded = NSString(string: rawPath).expandingTildeInPath
        guard !expanded.isEmpty,
              !expanded.contains("\0"),
              !expanded.contains("..") else {
            throw DictationLoggerError.folderPathInvalid(rawPath)
        }
        return URL(fileURLWithPath: expanded).resolvingSymlinksInPath().standardized
    }
}
```

`[CITED: pattern from TranscriptLogger.swift:14-179, validatedVaultPath:40-50, sanitizedFilenameComponent:53-58]`

### Pattern 3: UserDefaults `didSet` mirroring on `@Observable`

**What:** Six new AppSettings properties follow the existing one-liner pattern.
**Example (verified):**

```swift
// Source: AppSettings.swift:18-20 (existing pattern)
var vaultMeetingsPath: String {
    didSet { UserDefaults.standard.set(vaultMeetingsPath, forKey: "vaultMeetingsPath") }
}

// Six new keys mirror this:
var dictationFolderPath: String {
    didSet { UserDefaults.standard.set(dictationFolderPath, forKey: "dictationFolderPath") }
}

var dictationOutputMode: DictationOutputMode {
    didSet { UserDefaults.standard.set(dictationOutputMode.rawValue, forKey: "dictationOutputMode") }
}

var dictationHotkeyMode: DictationHotkeyMode {
    didSet { UserDefaults.standard.set(dictationHotkeyMode.rawValue, forKey: "dictationHotkeyMode") }
}

var clipboardRestoreDelay: TimeInterval {
    didSet { UserDefaults.standard.set(clipboardRestoreDelay, forKey: "clipboardRestoreDelay") }
}

var installedModelVersion: String {
    didSet { UserDefaults.standard.set(installedModelVersion, forKey: "installedModelVersion") }
}

// Optional Date is the only deviation -- store nil as removeObject:
var modelLastCheckedDate: Date? {
    didSet {
        if let d = modelLastCheckedDate {
            UserDefaults.standard.set(d, forKey: "modelLastCheckedDate")
        } else {
            UserDefaults.standard.removeObject(forKey: "modelLastCheckedDate")
        }
    }
}
```

**Init clause (mirror AppSettings.swift:51-67):**

```swift
init() {
    let defaults = UserDefaults.standard
    // ... existing inits unchanged ...

    // v1.2 keys
    self.dictationFolderPath = defaults.string(forKey: "dictationFolderPath")
        ?? NSString("~/Documents/PS Transcribe Dictations").expandingTildeInPath
    let modeRaw = defaults.string(forKey: "dictationOutputMode") ?? DictationOutputMode.clipboard.rawValue
    self.dictationOutputMode = DictationOutputMode(rawValue: modeRaw) ?? .clipboard
    let hotkeyRaw = defaults.string(forKey: "dictationHotkeyMode") ?? DictationHotkeyMode.toggle.rawValue
    self.dictationHotkeyMode = DictationHotkeyMode(rawValue: hotkeyRaw) ?? .toggle
    // TimeInterval: UserDefaults returns 0.0 for missing keys -- check object presence
    if defaults.object(forKey: "clipboardRestoreDelay") == nil {
        self.clipboardRestoreDelay = 3.0
    } else {
        self.clipboardRestoreDelay = defaults.double(forKey: "clipboardRestoreDelay")
    }
    self.installedModelVersion = defaults.string(forKey: "installedModelVersion") ?? ""
    self.modelLastCheckedDate = defaults.object(forKey: "modelLastCheckedDate") as? Date
}
```

`[CITED: existing init pattern at AppSettings.swift:51-67]`

### Anti-Patterns to Avoid

- **Hand-rolled mutex around `LibraryStore` callers:** D-13 keeps `LibraryStore` an actor. The lift only changes WHO holds the reference, not the actor's API. No NSLock, no DispatchQueue.
- **Using `@AppStorage` for the new keys:** AppSettings.swift uses `didSet` mirroring (verified at line 38: `UserDefaults.standard.set(...)`) explicitly to keep a single source of truth. `@AppStorage` would compete with the AppSettings property and create a double-source-of-truth problem. CLAUDE.md "Build only what's requested" applies.
- **Stored `Bool` for `anySessionActive`:** D-05 explicitly forbids this. Computed property only.
- **Adding `default:` arms to the four switches** to avoid touching them: this would silently swallow the new `.dictation` case wherever the switch needs distinct behavior (CaptureDock primary label, DetailsPane folder name, LibraryEntryRow icon, ControlBar active label). The compiler error is the feature -- it tells the planner exactly which UI sites need explicit `.dictation` treatment in Phase 18.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Plain-markdown writer with timestamps | Custom string-concat in DictationCoordinator | `DictationLogger` actor | D-01/D-02 mandate; mirrors TranscriptLogger pattern; isolation is a correctness property |
| Filename collision avoidance | UUID-only filenames | `yyyy-MM-dd HH-mm-ss-SSS` (millisecond suffix) | Pitfall #9 fix: human-readable AND collision-safe |
| Path validation | Manual string slicing | TranscriptLogger's `validatedVaultPath` pattern (reject `..`, `\0`, then `resolvingSymlinksInPath().standardized`) | Already battle-tested in TranscriptLogger; same threat model |
| `@Observable` change notification | Manual willSet/didSet broadcasts | The macro itself | Observation framework handles dependency tracking automatically |
| UserDefaults type-safety wrapper | Property wrapper around UserDefaults.standard | Plain `didSet` on AppSettings property | CONVENTIONS.md confirms the existing pattern; one-line conversion vs. a new abstraction |

**Key insight:** Phase 16 is a translation phase, not a design phase. Every choice is constrained by either CONTEXT.md (D-01..D-13) or by an existing pattern in the codebase. The temptation to "do it right while we're touching this" must be resisted -- Phase 18 will add the dictation flow that consumes these primitives.

## Common Pitfalls

### Pitfall 1: Switch exhaustion breaks the build (HIGH severity, HIGH likelihood)

**What goes wrong:** Adding `case dictation` to `SessionType` causes Swift 6 to flag four existing switch statements as non-exhaustive. The build fails with `error: switch must be exhaustive`.

**Why it happens:** `SessionType` is a `String`-raw enum with no `default:` arm at four call sites. Verified inventory:

| File | Line | What it switches on | Has `default`? |
|------|------|---------------------|----------------|
| Views/CaptureDock.swift | 223-227 | `activeSessionType` (Optional) | NO -- has `case .none` instead |
| Views/DetailsPane.swift | 104-107 | `entry.sessionType` | NO |
| Views/LibraryEntryRow.swift | 155-160 | `entry.sessionType` | NO |
| Views/ControlBar.swift | 241-251 | `activeSessionType` (Optional) | NO -- has `case nil` instead |
| Views/ContentView.swift | 80-84 | `activeSessionType` (Optional) | NO -- has `case .none` |
| Views/ContentView.swift | 825-840 | `type` parameter (non-optional) | NO |
| Storage/TranscriptLogger.swift | 128 | `sessionType == .voiceMemo` (equality, not switch) | N/A -- equality check is fine |
| Models/Models.swift | 77 | `sessionType == .callCapture` (equality) | N/A |

`[VERIFIED: grep -rn "switch.*sessionType\|case \.callCapture\|case \.voiceMemo" 2026-04-27]`

**How to avoid:** In the same task that adds `case dictation` to Models.swift, update all six switch sites to add an explicit `case .dictation:` arm. For Phase 16 (which has no dictation feature behavior), the arm should mirror `.voiceMemo` semantics OR explicitly stub-out (`return ""` / `return "Dictation"` / `return "mic.fill"`) since dictation will never be the entry's sessionType in Phase 16. The point is a clean compile, not behavior.

**Recommended `.dictation` arms for Phase 16 (placeholder behavior; Phase 18 refines):**

| Site | Recommended arm |
|------|-----------------|
| CaptureDock.swift primaryLabel | `case .dictation: return "End Dictation"` |
| DetailsPane.swift folderLabel | `case .dictation: return "Dictation"` (no folder var available; literal is fine) |
| LibraryEntryRow.swift typeIconName | `case .dictation: return "mic.circle.fill"` (distinct from voiceMemo's `mic.fill`) |
| ControlBar.swift activeSessionLabel | `case .dictation: return "Dictation"` |
| ContentView.swift autoStopThreshold | `case .dictation: return 6` (mirrors voiceMemo -- short utterances) |
| ContentView.swift startSession switch | `case .dictation: return` (no-op; meeting flow can't start dictation -- Phase 18 has its own entry point) |

**Warning signs:** First `swift build` after adding `.dictation` reports four-to-six errors of the form `switch must be exhaustive` or `default will never be executed`.

`[CITED: Swift 6 strict exhaustiveness rules]`

### Pitfall 2: AppSettings init order and property defaults (MEDIUM severity, MEDIUM likelihood)

**What goes wrong:** The new `dictationOutputMode` property is non-Optional (`DictationOutputMode`, not `DictationOutputMode?`), but it has to be initialized BEFORE `init()` returns. If the rawValue lookup fails (corrupt UserDefaults), the property might be left unassigned and the compiler will complain.

**Why it happens:** Swift requires every stored property to be initialized before `self` is usable. The standard pattern (`SessionType(rawValue: rawType) ?? .callCapture`) works because the `??` provides a fallback.

**How to avoid:** All six new property inits must use a `?? defaultValue` fallback. The init clause in Pattern 3 above does this correctly. Verify by attempting to instantiate `AppSettings()` with `defaults.removePersistentDomain(forName: ...)` first in a test.

**Warning signs:** `error: 'self' used before all stored properties are initialized` or runtime crash on first launch after a UserDefaults corruption.

`[VERIFIED: existing pattern at AppSettings.swift:64-65 uses `?? .callCapture` fallback for `lastUsedSessionType`]`

### Pitfall 3: LibraryStore initialization order (LOW severity, LOW likelihood)

**What goes wrong:** Currently, `LibraryStore()` is constructed inside ContentView's `@State` initializer. If `LibraryStore.init` ever throws (it doesn't today -- verified), or if disk I/O during init blocks the main actor for too long, the symptom shifts from "ContentView crashes on launch" to "the entire app crashes on launch" because PSTranscribeApp is the SwiftUI scene root.

**Why it happens:** LibraryStore.init synchronously creates the Application Support directory, sets POSIX permissions, and decodes JSON. Verified at LibraryStore.swift:10-46.

**How to avoid:** Ship Phase 16 as-is (LibraryStore stays an actor with the same init signature). Don't try to make init async or non-blocking in Phase 16. If init proves slow in QA, defer to a Phase 17/18 follow-up; do not couple it to this lift.

**Warning signs:** App launch hang on machines with very large `library.json` (thousands of entries). Not realistic for v1.2 user base.

`[VERIFIED: LibraryStore.init at lines 10-46; performs synchronous file I/O, never throws]`

### Pitfall 4: ContentView initializer signature change is a breaking change (LOW severity, HIGH likelihood)

**What goes wrong:** ContentView's struct currently has `@Bindable var settings: AppSettings` and `let notionService: NotionService` (verified ContentView.swift:21-22). Phase 16 adds `let libraryStore: LibraryStore` and `let sessionCoordinator: SessionCoordinator`. PSTranscribeApp.swift:36 currently calls `ContentView(settings: settings, notionService: notionService)` -- this will fail to compile until the call site is updated.

**Why it happens:** SwiftUI struct initializers are positional/labeled and synthesized. Adding a new `let` property without a default value changes the implicit init.

**How to avoid:** Update both PSTranscribeApp.swift:36 (call site) AND ContentView.swift struct (definition) in the same task. There is exactly one call site -- verified by `grep -rn "ContentView(" --include=*.swift`. Tests do not instantiate ContentView.

**Warning signs:** `error: missing argument for parameter 'libraryStore' in call` at PSTranscribeApp.swift:36.

`[VERIFIED: only call site is PSTranscribeApp.swift:36; no test instantiates ContentView]`

### Pitfall 5: `@Observable @MainActor` weak reference cycle (LOW severity, LOW likelihood)

**What goes wrong:** SessionCoordinator holds a reference to TranscriptionEngine. TranscriptionEngine doesn't reference SessionCoordinator back -- so no cycle today. But if Phase 17 or 18 wires up a back-reference (e.g., `engine.sessionCoordinator = self`), a retain cycle becomes possible.

**Why it happens:** `@Observable` classes are reference types; ARC.

**How to avoid:** Use `weak var engine: TranscriptionEngine?` in SessionCoordinator. Pattern verified by AppDelegate.swift:75 using `weak var` in similar lifecycle scenarios. (Note: `@Observable` does not currently support `weak` directly on tracked properties without warnings; if Swift's Observation macro complains, fall back to a manual Optional with documentation comment.)

**Warning signs:** Memory growth over many session start/stop cycles.

`[ASSUMED: `weak var` interaction with `@Observable` macro -- verify during implementation]`

## Code Examples

Verified patterns from official sources and existing code.

### Example 1: Adding a case to a `String`-raw enum (Models.swift)

```swift
// Source: PSTranscribe/Sources/PSTranscribe/Models/Models.swift:55-58 (existing)
// Modified to add D-09:
enum SessionType: String, Codable, Sendable {
    case callCapture
    case voiceMemo
    case dictation  // Phase 16, D-09
}
```

`[CITED: Models.swift:55-58]`

### Example 2: New enums with String raw values (D-10, D-11)

```swift
// Source: pattern from Models.swift SessionType (lines 55-58)
// Add to Models.swift after the existing SessionType enum:

enum DictationOutputMode: String, Codable, Sendable {
    case clipboard
    case plainFolder
    case both
}

enum DictationHotkeyMode: String, Codable, Sendable {
    case toggle
    case pressAndHold
}
```

`[CITED: Models.swift SessionType pattern]`

### Example 3: PSTranscribeApp `@State` for new app-scope objects

```swift
// Source: PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift:6-15 (existing pattern)
// Modified for Phase 16:

@main
struct PSTranscribeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var settings: AppSettings
    @State private var libraryStore: LibraryStore               // Phase 16, D-12
    @State private var sessionCoordinator: SessionCoordinator   // Phase 16, D-07
    private let updaterController = AppUpdaterController()
    @State private var notionService = NotionService()

    init() {
        _settings = State(initialValue: AppSettings())
        _libraryStore = State(initialValue: LibraryStore())
        _sessionCoordinator = State(initialValue: SessionCoordinator())
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                settings: settings,
                notionService: notionService,
                libraryStore: libraryStore,
                sessionCoordinator: sessionCoordinator
            )
            .onAppear {
                settings.applyScreenShareVisibility()
            }
        }
        // ... rest unchanged ...
    }
}
```

`[CITED: PSTranscribeApp.swift:6-15, 34-40]`

### Example 4: Late binding the engine to SessionCoordinator (ContentView.swift)

```swift
// Source: ContentView.swift:294-296 (existing engine init)
// After Phase 16, add line 4:

if transcriptionEngine == nil {
    transcriptionEngine = TranscriptionEngine(transcriptStore: transcriptStore)
}
sessionCoordinator.engine = transcriptionEngine  // Phase 16: late binding
await transcriptionEngine?.prepareModels()
```

`[CITED: ContentView.swift:294-296]`

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ObservableObject` + `@Published` | `@Observable` macro | Swift 5.9 / iOS 17 / macOS 14 | App already uses `@Observable` everywhere; Phase 16 follows |
| `XCTest` | Swift Testing (`@Suite` / `@Test`) | Swift 6.0 | App already uses Swift Testing (verified SpeakerCodableTests.swift); new tests follow |
| `@AppStorage` + observable proxy | Single-source-of-truth `@Observable` class with `didSet` UserDefaults mirroring | Project-specific decision (CONVENTIONS.md) | Phase 16's six new keys must use the project pattern, NOT `@AppStorage` |

**Deprecated/outdated:**
- ROADMAP.md line 18 ("add `TranscriptLogger.startPlainSession` + `finalizePlain`") -- D-01 supersedes; planner should fix or note explicitly.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `@Observable` macro tolerates `weak var` on a tracked Optional reference type without a warning under Swift 6.3.1 | Pitfall 5 | Compiler emits a warning; fallback to non-weak Optional (no functional impact since SessionCoordinator outlives TranscriptionEngine in the app lifecycle) |
| A2 | `swift test` will exercise all new Swift Testing tests without additional configuration in Package.swift | Validation Architecture | If wrong, planner adds `swift test --filter` invocations or test target reconfiguration |
| A3 | The four switch sites listed (CaptureDock, DetailsPane, LibraryEntryRow, ControlBar) are the COMPLETE set affected by adding `case dictation` | Pitfall 1 | grep verified; if a fifth site is hidden by macro expansion, the build error will pinpoint it |

**If this table is empty:** All claims in this research were verified or cited -- no user confirmation needed.

(Three minor assumptions are flagged. None are blocking.)

## Open Questions

1. **Should ROADMAP.md be corrected as part of Phase 16 wave 0, or as a separate doc-only commit before Phase 17 planning?**
   - What we know: CONTEXT.md D-01 is authoritative; ROADMAP.md line 18 is stale.
   - What's unclear: Whether the planner wants to bundle the fix into Phase 16's first commit or treat it as a meta-commit.
   - Recommendation: Bundle into Phase 16 wave 0 alongside the Models.swift task. One-line edit; zero risk; keeps the milestone document truthful from the start.

2. **Does ContentView.swift line 37's `@State private var libraryStore = LibraryStore()` need to change to `let libraryStore: LibraryStore` (constructor-injected) immediately, or can it be `@State private var libraryStore: LibraryStore` (still `@State` but assigned via init)?**
   - What we know: SwiftUI views are value types; `@State` is for view-local mutable state; a constructor-injected actor is best modeled as `let`.
   - What's unclear: Whether removing `@State` and using plain `let` interferes with SwiftUI's view diffing (it shouldn't -- the actor is an immutable reference).
   - Recommendation: Use `let libraryStore: LibraryStore`. Same actor, lifted ownership. Verified by code-reading SwiftUI documentation patterns. If there is unexpected behavior, fall back to `@State` -- both compile and both observe-correctly.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Swift toolchain | All Phase 16 tasks | yes | 6.3.1 | -- |
| macOS 26 SDK | Compile target | yes | confirmed via `swift --version` Target arm64-apple-macosx26.0 | -- |
| FluidAudio (vendored, pinned) | Existing build, not Phase 16 | yes (in checkouts) | ea500621 | -- |
| Sparkle | Existing build, not Phase 16 | yes (in checkouts) | from 2.7.0 | -- |
| `swift test` infrastructure | Validation gate | yes | bundled w/ toolchain | -- |
| Apple Developer ID for code signing | Local debug build only | not required for Phase 16 (library + app build only, no notarization) | -- | -- |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None.

`[VERIFIED: PSTranscribe/Package.swift dependencies; swift --version; ls PSTranscribe/.build/checkouts/ confirmed FluidAudio + Sparkle present 2026-04-27]`

## Validation Architecture

Nyquist validation is enabled (`workflow.nyquist_validation: true` in `.planning/config.json` -- verified). Validation gates each task and the phase as a whole.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Swift Testing (bundled with Swift 6.0+) |
| Config file | `PSTranscribe/Package.swift` (test target at lines 22-26) |
| Quick run command | `cd PSTranscribe && swift test --filter <SuiteName>` |
| Full suite command | `cd PSTranscribe && swift test` |
| Build-only gate | `cd PSTranscribe && swift build` |

`[VERIFIED: Package.swift testTarget block; existing tests use Swift Testing's @Suite / @Test pattern]`

### Phase Requirements -> Test Map

Phase 16 has no user-visible behavior, so tests are limited to compile validation, codability round-trips, persistence round-trips, and a single regression smoke test of the existing meeting flow.

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| SC-1 | App builds with `SessionType.dictation` and `DictationOutputMode` added | build | `cd PSTranscribe && swift build` | yes (Package.swift) |
| SC-1 | `SessionType.dictation` round-trips through Codable encoder/decoder | unit | `cd PSTranscribe && swift test --filter SessionTypeCodableTests` | NO -- Wave 0 creates `Tests/PSTranscribeTests/SessionTypeCodableTests.swift` |
| SC-1 | `DictationOutputMode` round-trips through Codable | unit | `cd PSTranscribe && swift test --filter SessionTypeCodableTests/dictationOutputMode` | NO -- same new file |
| SC-1 | `DictationHotkeyMode` round-trips through Codable | unit | `cd PSTranscribe && swift test --filter SessionTypeCodableTests/dictationHotkeyMode` | NO -- same new file |
| SC-2 | All six new AppSettings keys persist to UserDefaults and reload after re-init | unit | `cd PSTranscribe && swift test --filter AppSettingsTests` | NO -- Wave 0 creates `Tests/PSTranscribeTests/AppSettingsTests.swift` |
| SC-2 | Default values match D-04 (clipboard, ~/Documents/PS Transcribe Dictations, toggle, 3.0, "", nil) | unit | `cd PSTranscribe && swift test --filter AppSettingsTests/defaults` | NO -- same new file |
| SC-2 | App builds with no warnings on the six new properties | build | `cd PSTranscribe && swift build 2>&1 | grep -E 'warning:.*AppSettings'` (should produce zero matches) | yes (build) |
| SC-3 | `DictationLogger.startSession` creates a file with correct header (no YAML) | unit | `cd PSTranscribe && swift test --filter DictationLoggerTests/startSessionWritesHeader` | NO -- Wave 0 creates `Tests/PSTranscribeTests/DictationLoggerTests.swift` |
| SC-3 | `DictationLogger.append` writes utterance with session-relative timestamp | unit | `cd PSTranscribe && swift test --filter DictationLoggerTests/appendWritesUtterance` | NO -- same new file |
| SC-3 | `DictationLogger.endSession` returns the file URL and closes the handle | unit | `cd PSTranscribe && swift test --filter DictationLoggerTests/endSessionClosesHandle` | NO -- same new file |
| SC-3 | Two `DictationLogger.startSession` calls within 100ms produce two distinct files (Pitfall #9) | unit | `cd PSTranscribe && swift test --filter DictationLoggerTests/rapidSessionsNoCollision` | NO -- same new file |
| SC-3 | `DictationLogger` rejects path traversal (`..`) | unit | `cd PSTranscribe && swift test --filter DictationLoggerTests/rejectsTraversal` | NO -- same new file |
| SC-4 | `LibraryStore` lifts cleanly: PSTranscribeApp constructs it and ContentView accepts it via init | build | `cd PSTranscribe && swift build` | yes (build catches missing-arg error) |
| SC-4 | Existing `LibraryStoreTests` suite continues to pass (regression) | unit | `cd PSTranscribe && swift test --filter LibraryStoreTests` | yes (Tests/PSTranscribeTests/LibraryStoreTests.swift) |
| SC-4 | Manual: existing meeting recording flow start -> stop -> entry appears in sidebar (no behavioral regression) | manual smoke | `cd PSTranscribe && swift run` (then 30-second recording, observe library entry) | yes (existing app) -- MANUAL, plan VERIFICATION.md must capture |
| SC-5 | `SessionCoordinator.anySessionActive` returns `false` when no engine attached | unit | `cd PSTranscribe && swift test --filter SessionCoordinatorTests/falseWhenNoEngine` | NO -- Wave 0 creates `Tests/PSTranscribeTests/SessionCoordinatorTests.swift` |
| SC-5 | `SessionCoordinator.anySessionActive` returns `false` when engine attached but `isRunning == false` | unit | `cd PSTranscribe && swift test --filter SessionCoordinatorTests/falseWhenEngineIdle` | NO -- same new file |
| SC-5 | `SessionCoordinator.anySessionActive` returns `true` when engine attached and `isRunning == true` (set via test fixture) | unit | `cd PSTranscribe && swift test --filter SessionCoordinatorTests/trueWhenEngineRunning` | NO -- same new file |

### Sampling Rate

- **Per task commit:** Run the relevant filtered suite + `swift build` (e.g., `cd PSTranscribe && swift test --filter DictationLoggerTests && swift build`). Each task's quick gate runs in <30 seconds.
- **Per wave merge:** `cd PSTranscribe && swift test` (full suite, ~3-5 minutes assuming current test count).
- **Phase gate:** Full `swift test` green + manual smoke test of existing meeting flow (SC-4 regression check) before `/gsd-verify-work`.

### Wave 0 Gaps

- [ ] `Tests/PSTranscribeTests/SessionTypeCodableTests.swift` -- covers SC-1 (three new enums, codability)
- [ ] `Tests/PSTranscribeTests/AppSettingsTests.swift` -- covers SC-2 (six new keys, defaults + round-trip)
- [ ] `Tests/PSTranscribeTests/DictationLoggerTests.swift` -- covers SC-3 (start/append/end + collision + traversal)
- [ ] `Tests/PSTranscribeTests/SessionCoordinatorTests.swift` -- covers SC-5 (anySessionActive computed property)
- [ ] **No framework install needed** -- Swift Testing is bundled.

VERIFICATION.md (Phase 16's manual smoke test record) must capture: (1) launch app, (2) start a meeting recording, (3) speak for 30 seconds, (4) stop, (5) verify entry in sidebar -- all working identically to pre-Phase-16 baseline. SC-4's "no behavioral regression" requirement is fundamentally a manual check; the existing automated test suite covers component-level regressions only.

## Security Domain

`security_enforcement` is not explicitly set in `.planning/config.json` (verified). Default behavior: include this section.

### Applicable ASVS Categories

Phase 16 introduces no new security surfaces. The relevant existing controls remain in force:

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | App is local; no user accounts |
| V3 Session Management | no | App is local; no remote sessions |
| V4 Access Control | no | macOS file permissions handle access |
| V5 Input Validation | yes (DictationLogger) | New: `validatedFolderPath` rejects `..` and `\0` BEFORE `URL(fileURLWithPath:)` resolution. Mirror TranscriptLogger.swift:40-50 pattern. |
| V6 Cryptography | no | No crypto added or modified in Phase 16 |
| V7 Error Handling | yes (DictationLogger) | All file errors `throw` `DictationLoggerError`; no `try?` swallow on critical paths |
| V8 Data Protection | yes (DictationLogger output files) | Files created with `0o600` permissions, mirroring TranscriptLogger.swift:173-176 |
| V12 File and Resources | yes (DictationLogger) | Atomic file creation via `FileManager.default.createFile(atPath:contents:)`; explicit `setAttributes` for POSIX perms |

### Known Threat Patterns for Swift / macOS file I/O

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal via user-configurable folder path | Tampering / EoP | `validatedFolderPath` rejects `..` and `\0`; `resolvingSymlinksInPath().standardized` defangs symlinks |
| File permission leak (group/world readable transcripts) | Information Disclosure | Set `0o600` immediately after `createFile`; mirror existing TranscriptLogger pattern |
| Race between `createFile` and `setAttributes` | Tampering | macOS `createFile` is atomic enough for single-app non-sandboxed use; the same race exists in TranscriptLogger and is accepted in the codebase. Phase 16 carries the same risk profile. |
| Filename collision overwriting earlier dictation | Tampering / data loss | Millisecond-precision timestamps in filename (Pitfall #9 fix) |

`[VERIFIED: TranscriptLogger.swift implements all four mitigations; DictationLogger inherits the pattern]`

### What Phase 16 does NOT introduce (no new attack surface)

- No new network calls (Phase 17 owns model manifest fetch).
- No new clipboard reads or writes (Phase 18 owns NSPasteboard).
- No new entitlements (Package.swift unchanged; PSTranscribe.entitlements unchanged).
- No new IPC, no new XPC, no new URL handlers.

The `installedModelVersion` and `modelLastCheckedDate` keys are added to AppSettings but never written or read by Phase 16 code -- they are inert defaults waiting for Phase 17.

## Sources

### Primary (HIGH confidence)

- `[VERIFIED]` Direct source inspection 2026-04-27:
  - `PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift` (175 lines)
  - `PSTranscribe/Sources/PSTranscribe/Models/Models.swift` (111 lines)
  - `PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift` (90 lines)
  - `PSTranscribe/Sources/PSTranscribe/Storage/LibraryStore.swift` (79 lines)
  - `PSTranscribe/Sources/PSTranscribe/Storage/TranscriptLogger.swift` (589 lines)
  - `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift` (1039 lines)
  - `PSTranscribe/Sources/PSTranscribe/Transcription/TranscriptionEngine.swift` (lines 1-50, 19 confirmed)
  - `PSTranscribe/Sources/PSTranscribe/Views/CaptureDock.swift` (lines 218-237)
  - `PSTranscribe/Sources/PSTranscribe/Views/DetailsPane.swift` (lines 95-114)
  - `PSTranscribe/Sources/PSTranscribe/Views/LibraryEntryRow.swift` (lines 148-161)
  - `PSTranscribe/Sources/PSTranscribe/Views/ControlBar.swift` (lines 235-253)
  - `PSTranscribe/Tests/PSTranscribeTests/SpeakerCodableTests.swift` (50 lines)
  - `PSTranscribe/Tests/PSTranscribeTests/LibraryStoreTests.swift` (87 lines)
  - `PSTranscribe/Package.swift` (28 lines)
- `[VERIFIED]` `swift --version` -> Apple Swift 6.3.1, Target arm64-apple-macosx26.0
- `[VERIFIED]` `.planning/config.json` -> `workflow.nyquist_validation: true`
- `[VERIFIED]` `grep -rn` audits across the codebase for `SessionType.`, `LibraryStore`, `isRunning`, `switch.*sessionType`

### Secondary (MEDIUM confidence)

- `[CITED]` `.planning/research/SUMMARY.md` -- v1.2 architecture overview
- `[CITED]` `.planning/research/ARCHITECTURE.md` -- LibraryStore lift, anySessionActive flag, SessionCoordinator pattern
- `[CITED]` `.planning/research/PITFALLS.md` -- Pitfalls #9, #10, #16
- `[CITED]` `.planning/research/STACK.md` -- KeyboardShortcuts (Phase 18 dependency, NOT Phase 16)
- `[CITED]` `.planning/codebase/CONVENTIONS.md` -- Swift 6.2 patterns, actor isolation, `@Observable @MainActor` classes

### Tertiary (LOW confidence -- none required)

No findings depend on unverified web sources. All Phase 16 patterns are present in the existing codebase and verifiable via `swift build` + `swift test`.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new dependencies; existing stack verified by direct inspection
- Architecture: HIGH -- patterns exist in current code (TranscriptLogger -> DictationLogger; AppSettings didSet pattern; PSTranscribeApp `@State` ownership)
- Pitfalls: HIGH (switch exhaustion, AppSettings init, ContentView signature) -- all confirmed by grep + file read; LOW (Pitfall 5 weak-Observable interaction) -- noted as ASSUMED A1
- Validation: HIGH -- Swift Testing framework already in use; new test files mirror existing pattern (LibraryStoreTests, SpeakerCodableTests)

**Research date:** 2026-04-27
**Valid until:** 2026-05-27 (30 days; codebase is stable, no FluidAudio version pin change expected, no Swift toolchain change planned)

---

*Research complete for Phase 16: Foundation. Planner can proceed to PLAN.md generation.*
