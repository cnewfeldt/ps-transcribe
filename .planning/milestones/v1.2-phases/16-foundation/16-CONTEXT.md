# Phase 16: Foundation - Context

**Gathered:** 2026-04-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Internal scaffolding so Phases 17 (Model Auto-Update) and 18 (Hotkey Dictation + Plain-Folder Output) can compile cleanly without conflicts. No user-visible change. Pure compiler-level prerequisite.

Specifically: lift `LibraryStore` to app scope, expose a single `anySessionActive` flag, add `SessionType.dictation` + `DictationOutputMode` to `Models.swift`, add all six v1.2 `AppSettings` keys, and add a new `DictationLogger` actor for plain-markdown dictation output.

</domain>

<decisions>
## Implementation Decisions

### Logger Architecture
- **D-01:** Add a new `DictationLogger` actor in `PSTranscribe/Sources/PSTranscribe/Storage/DictationLogger.swift` instead of extending `TranscriptLogger` with `startPlainSession`/`finalizePlain`.
  - Rationale: keeps each actor single-purpose, eliminates frontmatter-leak risk (PITFALLS.md #10), mirrors the existing one-actor-per-concern pattern (`TranscriptLogger`, `SessionStore`, `LibraryStore`).
  - Implication: the `Phase 16: Foundation` line in ROADMAP.md currently reads "add `TranscriptLogger.startPlainSession` + `finalizePlain`" — the planner should update it to "add `DictationLogger` actor (plain markdown writer, no YAML frontmatter)" before Phase 16 plans are written.
- **D-02:** `DictationLogger` writes plain markdown only — no YAML frontmatter, no diarization patches, no speaker tracking, no post-session finalization. Append-only during the session, atomic write on stop.

### AppSettings Key Scope
- **D-03:** All six v1.2 keys land in Phase 16, with sensible defaults and `UserDefaults` `didSet` mirroring the existing pattern in `AppSettings.swift`. Phases 17 and 18 only consume them — zero AppSettings churn after this.
- **D-04:** Keys to add (names locked):
  - `dictationOutputMode: DictationOutputMode` — default `.clipboard` (see D-08).
  - `dictationFolderPath: String` — default `NSString("~/Documents/PS Transcribe Dictations").expandingTildeInPath` (matches Phase 19 success criterion #4).
  - `dictationHotkeyMode: DictationHotkeyMode` — enum `{ toggle, pressAndHold }`, default `.toggle` (research-locked).
  - `clipboardRestoreDelay: TimeInterval` — default `3.0` (DICT-06 default).
  - `installedModelVersion: String` — default `""` (empty until first successful download).
  - `modelLastCheckedDate: Date?` — default `nil` (drives MODEL-01's 24-hour throttle).

### `anySessionActive` Design
- **D-05:** Implement as a computed `@Observable` property on a new `SessionCoordinator` type at app scope. Reads truth from each subsystem on demand: `engine.isRunning || dictation?.isActive ?? false || modelUpdate?.isApplying ?? false`. No separately-tracked Bool, no NotificationCenter broadcast.
  - Rationale: single source of truth, no synchronization risk, no risk of getting stuck "active" if a code path forgets to clear a flag.
- **D-06:** Phase 16 wires the engine source only; Phases 17 and 18 add their own subsystem references when those services land. The Optional fields on `SessionCoordinator` make this additive.
- **D-07:** `SessionCoordinator` is `@MainActor` `@Observable` and owned by `PSTranscribeApp` (`@State` in app init). Injected into `ContentView` alongside `LibraryStore`.

### Default `DictationOutputMode`
- **D-08:** Default to `.clipboard` only on first install. Plain folder is opt-in — user has to choose `.plainFolder` or `.both` in Settings before anything is written to disk.
  - Rationale: matches SuperWhisper first-run UX, lowest-surprise default, no files appear on disk without explicit action.

### Models.swift Additions
- **D-09:** Add `case dictation` to existing `SessionType` enum.
- **D-10:** Add `DictationOutputMode` enum to `Models.swift`: `case clipboard, plainFolder, both`. Codable, Sendable, `String` raw value to match existing `SessionType` pattern.
- **D-11:** Add `DictationHotkeyMode` enum to `Models.swift`: `case toggle, pressAndHold`. Codable, Sendable, String raw value.

### LibraryStore Lift
- **D-12:** Move `LibraryStore` instantiation from `ContentView` (`@State private var libraryStore = LibraryStore()` at line 37) to `PSTranscribeApp.swift` (`@State` in app init). Inject into `ContentView` via initializer.
- **D-13:** No behavioral change to `LibraryStore` itself — it stays an `actor` with the existing `entries` / `addEntry` / `updateEntry` / `removeEntry` API.

### Claude's Discretion
- Exact file/symbol names where they're not enumerated above (helper types, internal method names).
- Whether `SessionCoordinator` lives in `App/` or `Models/` (recommend `App/` since it owns app-lifecycle references).
- Whether to introduce a `TranscriptFormat` enum for future-proofing (recommended NO — YAGNI; `DictationLogger` is single-purpose).
- Test scaffolding shape — Phase 16 has no user-visible behavior, so unit tests are limited to enum codability and AppSettings persistence round-trips.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements
- `.planning/ROADMAP.md` §"Phase 16: Foundation" — phase goal, depends-on, success criteria (5 items)
- `.planning/REQUIREMENTS.md` — v1.2 requirements DICT-01..11, FOLDER-01..05, MODEL-01..10 (Phase 16 has no direct requirement mappings; this is the compiler-level prereq)
- `.planning/PROJECT.md` — v1.2 milestone goal, scope boundaries, out-of-scope list

### Research
- `.planning/research/SUMMARY.md` — overall v1.2 architecture, stack additions, phase ordering rationale, manifest hosting ADR (note: SUMMARY.md is internally inconsistent on logger architecture — D-01 above resolves it)
- `.planning/research/ARCHITECTURE.md` — `LibraryStore` lift, `anySessionActive` flag, `SessionCoordinator` pattern, separate engine for dictation
- `.planning/research/PITFALLS.md` — Pitfalls #10 (frontmatter leak), #16 (state machine fragmentation), #11 (model file partial download), #13 (model swap during active session)
- `.planning/research/STACK.md` — KeyboardShortcuts dependency, NSPasteboard markers, no entitlement changes
- `.planning/research/FEATURES.md` — DictationOutputMode default rationale (`.clipboard` for first-run UX)

### Source files Phase 16 modifies
- `PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift` — add `LibraryStore` and `SessionCoordinator` at app scope
- `PSTranscribe/Sources/PSTranscribe/Models/Models.swift` — add `SessionType.dictation`, `DictationOutputMode`, `DictationHotkeyMode`
- `PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift` — add six v1.2 keys with defaults + `didSet`
- `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift` — accept injected `LibraryStore` and `SessionCoordinator`; remove `@State` initializer
- `PSTranscribe/Sources/PSTranscribe/Storage/DictationLogger.swift` — NEW file (actor, plain markdown, no frontmatter)

### Project conventions
- `.planning/codebase/CONVENTIONS.md` — Swift 6.2 patterns, actor isolation, `@Observable` MainActor classes
- `.planning/codebase/STRUCTURE.md` — directory layout (note: STRUCTURE.md still references `Tome/` — actual code is at `PSTranscribe/Sources/PSTranscribe/`)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `actor LibraryStore` at `Storage/LibraryStore.swift:4` — already an actor with the right API; only its ownership scope changes in Phase 16.
- `enum SessionType` at `Models/Models.swift:55` — `case callCapture, voiceMemo`; Phase 16 adds `case dictation`.
- `@Observable @MainActor final class AppSettings` at `Settings/AppSettings.swift:6-90` — established pattern for `UserDefaults`-backed keys with `didSet`. New keys mirror this exactly.
- `actor TranscriptLogger` at `Storage/TranscriptLogger.swift:14` — reference pattern for the new `DictationLogger` actor (file handle, sanitized filename component, atomic rewrite). `DictationLogger` is simpler — no diarization, no frontmatter, no checkpoint integration.
- `private(set) var isRunning = false` at `Transcription/TranscriptionEngine.swift:19` — the source-of-truth Bool that the new `SessionCoordinator.anySessionActive` reads from.

### Established Patterns
- Actors for I/O and persistence (`TranscriptLogger`, `SessionStore`, `LibraryStore`).
- `@Observable` `@MainActor` classes for UI-bound state (`AppSettings`, `TranscriptionEngine`).
- `UserDefaults` keys via `didSet` on `AppSettings` properties — single source of truth, no separate `@AppStorage`.
- Filename sanitization via `sanitizedFilenameComponent` in `TranscriptLogger` — `DictationLogger` will need its own (timestamps + millisecond/UUID suffix per FOLDER-03 / Pitfall #9).

### Integration Points
- `PSTranscribeApp.swift:12-14` (`init`) — where `LibraryStore` and `SessionCoordinator` get instantiated.
- `PSTranscribeApp.swift:36` (`ContentView(settings: settings, notionService: notionService)`) — `ContentView` initializer signature gains `libraryStore:` and `sessionCoordinator:` parameters.
- `ContentView.swift:37` — current `@State private var libraryStore = LibraryStore()` is removed; `libraryStore` becomes a constructor-injected `let`.
- `ContentView.swift:795-796` — current `private var isRunning: Bool { transcriptionEngine?.isRunning ?? false }` becomes a read of `sessionCoordinator.anySessionActive` once the coordinator owns the engine reference (or remains for backward-compat in Phase 16; the planner can decide whether to migrate the call sites in this phase or leave for Phase 18).

</code_context>

<specifics>
## Specific Ideas

- The roadmap line for Phase 16 (currently "add `TranscriptLogger.startPlainSession` + `finalizePlain`") needs to be updated to "add `DictationLogger` actor (plain markdown writer)" before the planner writes Phase 16 plans. Flag this explicitly in PLAN.md or as a roadmap correction commit.
- Plain-folder default path should be created with `FileManager.default.createDirectory(withIntermediateDirectories: true)` on first dictation save — not on app launch. Phase 16 only sets the AppSettings default string; Phase 18 owns the directory creation.
- Phase 16 success criteria #4 says "no behavioral regression in the existing session library" — exercise the lift by running an existing meeting-recording flow end-to-end before declaring Phase 16 done.

</specifics>

<deferred>
## Deferred Ideas

- Per-app hotkey behavior (DICT-FUT-03) — deferred beyond v1.2.
- Configurable HUD position (DICT-FUT-01) — locked to bottom-center for v1.2.
- Multi-locale dictation (DICT-FUT-02) — inherits app's existing single locale.
- `TranscriptFormat` enum on `TranscriptLogger` — explicitly rejected (D-01); revisit only if a third writer ever appears.
- Migrating `ContentView.isRunning` call sites to read `sessionCoordinator.anySessionActive` — Claude's discretion in Phase 16 vs. defer to Phase 18 when dictation/model-update sources are added.

</deferred>

---

*Phase: 16-foundation*
*Context gathered: 2026-04-27*
