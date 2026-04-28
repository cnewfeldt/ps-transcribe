# Phase 18: Hotkey Dictation + Plain-Folder Output - Context

**Gathered:** 2026-04-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire up hotkey-triggered standalone dictation: a global keyboard shortcut starts a dictation session from any app, a floating HUD shows the live partial transcript, and on stop the final text lands on the system clipboard (with privacy markers) and/or in a user-configured plain folder as clean markdown. Builds entirely on top of Phase 16's foundation — `DictationLogger` actor, `SessionCoordinator`, all six v1.2 `AppSettings` keys, and `SessionType.dictation` are already in place.

Phase 18 satisfies DICT-01 through DICT-11 and FOLDER-01 through FOLDER-05 (16 requirements). It does NOT cover model-update integration testing (Phase 19) or any LLM cleanup of dictated text (out of scope).

</domain>

<decisions>
## Implementation Decisions

### HUD Content & Visual Design
- **D-01:** HUD displays live partial transcript + elapsed timer (`mm:ss`) + visible Stop button. Three blocks in a single horizontal panel. (preview: `● 0:12   the quick brown fox…   [Stop]`)
- **D-02:** On stop, before dismiss, show a "Copied to clipboard" pill for ~1.0s, then fade. Satisfies ROADMAP Phase 18 success criterion #2 verbatim.
- **D-03:** Visual style is **native macOS HUD** — `NSVisualEffectView` with `.hudWindow` material, vibrancy blur, system-default appearance. NOT the Chronicle paper aesthetic (intentionally distinct from the main app, matches macOS conventions).
- **D-04:** Position is bottom-center of the active screen (`NSScreen.main`). Vertically centered across the bottom ~quarter. Matches SuperWhisper / macOS Dictation default. No user configuration in v1.2.

### Cancel & Hotkey Semantics
- **D-05:** **Toggle mode** — second hotkey tap = stop & commit (clipboard write + library save + plain-folder finalize per `DictationOutputMode`). Symmetric with first tap = start. Escape is the **only** way to cancel-without-commit.
- **D-06:** **30s cancel confirmation appears INLINE in HUD.** When Escape is pressed and session duration ≥ 30s, HUD subtitle changes to "Press Esc again to cancel" for ~3s. Second Esc within that window confirms cancel; otherwise revert to listening. No modal alert, no banner. Stays in the user's flow.
- **D-07:** **Press-and-hold mode** — release < 1s = silent cancel (treats accidental tap as no-op, avoids transcribing 200ms blips per FEATURES.md research / Voxt pattern). Release ≥ 1s = commit. The 30s confirmation threshold from D-06 still applies.
- **D-08:** **Cancel cleanup is atomic.** Cancel → no clipboard write, no library entry, AND if `DictationLogger.startSession()` already opened a plain-folder file, that file is **deleted** (not truncated, not marked-cancelled). Nothing persists. The `DictationLogger` API needs a `discardSession()` companion to `endSession()`.

### Library Entry Handling
- **D-09:** **Every successful dictation gets a library entry.** No minimum word count, no minimum duration filter. Even one-word dictations land in the library. (Filtering is explicitly rejected — see Deferred Ideas.)
- **D-10:** **Auto-name from first ~5 words** of the final transcript. Truncate at ~50 chars, break on word boundary, append `…` if truncated, strip leading/trailing punctuation. Falls back to `Dictation YYYY-MM-DD HH:mm` if transcript is empty/whitespace-only.
- **D-11:** **Inline alongside meetings + voice memos**, distinguished by a `mic.fill` SF Symbol (or simple "D" badge) in `LibraryEntryRow`. No separate "Dictations" filter section. Single timeline view sorted by date. Library UI keeps the existing v1.0 Phase 3 + Phase 10 structure.
- **D-12:** **Library row points at the plain-folder file directly** (single source of truth, same missing-file UX as v1.0 Phase 10) when `DictationOutputMode` is `.plainFolder` or `.both`. When mode is `.clipboard` only, library row stores the transcript text inline in `library.json` with no `filePath` (matches the existing `LibraryEntry` shape if it tolerates an empty path; verify during planning and adjust if needed).

### Cold-Start & Failure UX
- **D-13:** **Eager pre-warm at app launch.** A separate `TranscriptionEngine` instance owned by `DictationCoordinator` is instantiated at app scope and `prepareModels()` runs in the background at launch (not on first hotkey press). First hotkey is instant; cost is ~500MB resident memory always. Architecture Option B (separate engine) from research is preserved — meeting engine and dictation engine remain independent.
- **D-14:** **Hotkey pressed during an active meeting recording** → HUD appears briefly with "Recording in progress — dictation unavailable", auto-dismisses after ~1.5s. Satisfies ROADMAP Phase 18 success criterion #5 ("no-op or shows a brief dismissible notice"). Mutual exclusion gate is `SessionCoordinator.anySessionActive`.
- **D-15:** **Plain-folder write failure** (permissions, missing folder, disk full, security-scoped bookmark stale) → silent fallback to clipboard-only. Log to `os_log` for Console.app diagnostics. Library entry is still created (with empty `filePath`). User isn't blocked; their clipboard paste still works. Don't surface the error in the HUD — too disruptive for a flow that succeeded from the user's perspective.
- **D-16:** **Models still loading when hotkey pressed** → HUD shows "Loading model…" state, transitions to live listening when `modelsReady = true`. Recording starts only when models are ready (may lose first 1-2s of speech before transition). Honest about the wait. With D-13 (eager pre-warm) this state is rare; it covers the case where pre-warm fails or is still in flight.

### Claude's Discretion
- Exact HUD dimensions, font sizes, padding (research suggests ~360-440pt wide, but final values within native HUD style conventions).
- Exact Settings layout for the Dictation section — flat list vs sub-grouped (Hotkey | Output | Behavior). Phase 17 D-06 locks the section ORDER (…Speech Model → Dictation); internal layout is Claude's call within Pitfall #18 guardrails.
- Hotkey-recorder validation: warn-but-allow on system-reserved combinations (per FEATURES.md guidance), or hard-block. Lean: warn-but-allow.
- Clipboard restore semantics with `NSPasteboard.changeCount` race (Pitfall #6): use changeCount as a guard (skip restore if user copied something else during the window), don't fail loudly on mismatch.
- Pre-warm error handling — if dictation engine's `prepareModels()` fails at launch, defer to lazy load on first hotkey (D-16 path).
- Menu bar pulsing-mic icon design (DICT-03) — specific animation and SF Symbol choice.
- Engine pre-warm error path and any retry semantics.
- Whether `DictationCoordinator` needs its own `TranscriptStore` instance or can share a private utterance accumulator.
- Settings UI shape for `clipboardRestoreDelay` — slider, stepper, or hidden defaults-only.
- "First ~5 words" tokenization details (whitespace split, stop-word filtering, etc.).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements
- `.planning/ROADMAP.md` §"Phase 18: Hotkey Dictation + Plain-Folder Output" — phase goal, depends-on (Phase 16), 5 success criteria, 16 requirement mappings (DICT-01..11 + FOLDER-01..05)
- `.planning/REQUIREMENTS.md` §"Dictation -- Hotkey + Clipboard" — DICT-01 through DICT-11 with acceptance text
- `.planning/REQUIREMENTS.md` §"Dictation -- Plain-Folder Output" — FOLDER-01 through FOLDER-05
- `.planning/REQUIREMENTS.md` §"Out of Scope" — confirms no auto-paste via accessibility, no LLM cleanup, no dictation history search, no telemetry
- `.planning/PROJECT.md` — v1.2 milestone goal, 2026-04-04 scope reduction (no LLM analysis), constraints

### Research
- `.planning/research/SUMMARY.md` §"Phase C: Dictation" — build order, dependencies on Phase A foundation; "Stack Additions" confirms KeyboardShortcuts 2.4.0 as the only new SwiftPM dep
- `.planning/research/ARCHITECTURE.md` §"Feature 1: Keyboard-Triggered Clipboard Dictation" + §"Feature 2: Plain-Folder Dictation Output" — component map, data flow diagrams, Option B (separate engine) recommendation
- `.planning/research/PITFALLS.md` — Pitfalls #5 (clipboard pollution markers), #6 (change-count race), #7 (macOS 26 pasteboard alert — writes only, no reads), #8 (security-scoped bookmark not needed; app is non-sandboxed), #9 (filename collision — already handled by DictationLogger ms-suffix), #10 (frontmatter leak — already handled by DictationLogger), #16 (state machine fork — Option B mitigates), #17 (HUD privacy mode — `sharingType = .none` on NSPanel), #18 (Settings bloat — section grouping per Phase 17 D-06); "Looks Done But Isn't" checklist (dictation items)
- `.planning/research/STACK.md` — `sindresorhus/KeyboardShortcuts` 2.4.0; NSPasteboard markers `org.nspasteboard.TransientType` + `AutoGeneratedType`; no entitlement changes (`PSTranscribe.entitlements` already supports audio input + screen capture)
- `.planning/research/FEATURES.md` — HUD position default (bottom-center), toggle vs hold default (toggle), 30s cancel-confirmation threshold, filename convention `YYYY-MM-DD HH-mm Dictation.md`, "first N words" auto-naming pattern

### Phase 16 (predecessor)
- `.planning/phases/16-foundation/16-CONTEXT.md` — D-01 (`DictationLogger` actor design), D-04 (six AppSettings keys with defaults), D-05/D-06/D-07 (`SessionCoordinator` pattern, weak Optional fields for additive integration, owned by `PSTranscribeApp`), D-08 (default `.clipboard` mode), D-09/D-10/D-11 (Models.swift enums: `SessionType.dictation`, `DictationOutputMode`, `DictationHotkeyMode`), D-12 (`LibraryStore` lifted to app scope)
- `.planning/phases/16-foundation/16-03-SUMMARY.md` — `DictationLogger` implementation (filename: `yyyy-MM-dd HH-mm-ss-SSS Dictation.md`, header `# Dictation -- yyyy-MM-dd HH:mm`, no YAML frontmatter, owner-only 0o600 perms, atomic file open via FileHandle)
- `.planning/phases/16-foundation/16-04-SUMMARY.md` — `SessionCoordinator` wiring details, `weak var engine: TranscriptionEngine?` already in place, computed `anySessionActive`

### Phase 17 (peer)
- `.planning/phases/17-model-auto-update/17-CONTEXT.md` — D-06 (Settings section order locks: …Updates → Speech Model → **Dictation**); D-18 (additive Optional pattern in `SessionCoordinator`); confirms Phase 18 fills `weak var dictation: DictationCoordinator?` slot at lines 29-32
- `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift` — pattern reference for "external service that wraps a system framework as `@Observable @MainActor final class`"

### Source files Phase 18 modifies or creates
- `PSTranscribe/Sources/PSTranscribe/Services/GlobalHotkeyService.swift` — **NEW.** KeyboardShortcuts wrapper. `@Observable @MainActor final class`. Mirrors `AppUpdaterController.swift` shape. Exposes `onHotkey: () -> Void` callback fired on MainActor.
- `PSTranscribe/Sources/PSTranscribe/App/DictationCoordinator.swift` — **NEW.** `@Observable @MainActor final class`. Owns dictation `TranscriptionEngine` instance, lifecycle (begin/end/cancel), clipboard write with privacy markers + restore, library save, NSPanel show/hide, mutual-exclusion guard, 30s cancel-confirmation state machine.
- `PSTranscribe/Sources/PSTranscribe/App/DictationWindowController.swift` — **NEW.** `@MainActor final class` (NSWindowController subclass). Owns `NSPanel` lifecycle. `.nonactivatingPanel` style mask, `.floating` level, `.canJoinAllSpaces`, `sharingType = .none`, bottom-center positioning logic.
- `PSTranscribe/Sources/PSTranscribe/Views/DictationHUD.swift` — **NEW.** SwiftUI view. Hosted in NSPanel via `NSHostingView`. Renders state: idle/loading/listening/cancelling/copied. Native HUD vibrancy via `NSVisualEffectView` representable.
- `PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift` — **MODIFIED.** Instantiate `globalHotkeyService` and `dictationCoordinator` at app scope (`@State`). Wire `sessionCoordinator.dictation = dictationCoordinator`. Update `MenuBarExtra` block (lines 82-93) to show pulsing-mic icon when `dictationCoordinator.isActive == true` (DICT-03).
- `PSTranscribe/Sources/PSTranscribe/App/SessionCoordinator.swift` — **MODIFIED.** Replace the comment stub at lines 29-32 with `weak var dictation: DictationCoordinator?`. Update `anySessionActive` body to `(engine?.isRunning ?? false) || (modelUpdate?.isApplying ?? false) || (dictation?.isActive ?? false)`.
- `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift` — **MODIFIED.** Add NotificationCenter listener for `.dictationSessionEnded` to refresh library if not already covered by `@Observable` propagation through the lifted `LibraryStore`.
- `PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift` — **MODIFIED.** Append new `Section("Dictation")` AFTER the Speech Model section (per Phase 17 D-06). Contains: `KeyboardShortcuts.Recorder` for the hotkey, hotkey mode picker (`.toggle` / `.pressAndHold`), output mode picker (`.clipboard` / `.plainFolder` / `.both`), plain-folder picker (reuses existing `chooseFolder` helper at line 585), clipboard restore delay control.
- `PSTranscribe/Sources/PSTranscribe/Views/LibraryEntryRow.swift` — **MODIFIED.** Add SF Symbol indicator for `SessionType.dictation` rows (mic.fill or "D" badge per D-11).
- `PSTranscribe/Sources/PSTranscribe/Storage/LibraryStore.swift` — possibly **MODIFIED** depending on `LibraryEntry` model. May need to support entries with no `filePath` (clipboard-only mode per D-12). Verify during planning.
- `PSTranscribe/Sources/PSTranscribe/Storage/DictationLogger.swift` — **MODIFIED.** Add `discardSession()` API alongside existing `endSession()` to support D-08 (delete file on cancel).

### New SwiftPM dependency
- `sindresorhus/KeyboardShortcuts` 2.4.0 — add to `PSTranscribe/Package.swift`. Wraps Carbon `RegisterEventHotKey`. No Accessibility / Input Monitoring permission. App Store compatible. Includes SwiftUI `KeyboardShortcuts.Recorder` view. Default suggested name `dictateGlobal`.

### Project conventions
- `.planning/codebase/CONVENTIONS.md` — Swift 6.2 actor patterns, `@Observable @MainActor` classes, error handling without silent `try?`
- `.planning/codebase/STRUCTURE.md` — directory layout (note: still references `Tome/` in places; actual code at `PSTranscribe/Sources/PSTranscribe/`)
- `.planning/codebase/STACK.md` — Swift package patterns, dependency pinning policy
- `.planning/codebase/INTEGRATIONS.md` — existing menu bar extra structure, NotificationCenter conventions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `actor DictationLogger` at `Storage/DictationLogger.swift:31` — already supplies `startSession(folderPath:)`, `append(text:timestamp:)`, `endSession() -> URL?`. Phase 18 wires its lifecycle into `DictationCoordinator` and adds `discardSession()` for cancel cleanup (D-08).
- `@Observable @MainActor final class SessionCoordinator` at `App/SessionCoordinator.swift:14` — additive Optional pattern documented at lines 29-32. Phase 18 fills the `weak var dictation: DictationCoordinator?` slot. The `anySessionActive` computed property is pre-spelled-out to OR in `dictation?.isActive ?? false`.
- `actor LibraryStore` (lifted to `PSTranscribeApp` scope in Phase 16, D-12) — already an actor with `entries` / `addEntry` / `updateEntry` / `removeEntry` API. `DictationCoordinator.endDictation()` calls `addEntry` after successful clipboard write or file finalization.
- `class TranscriptionEngine` at `Transcription/TranscriptionEngine.swift` — Phase 18 instantiates a SECOND instance owned by `DictationCoordinator` (Option B from research). The existing instance continues meeting/voice memo flows untouched. Existing `prepareModels()` at lines 79-103 is the pattern; dictation engine's `prepareModels()` runs at app launch in background per D-13.
- `@Observable @MainActor final class AppSettings` at `Settings/AppSettings.swift:6` — already has `dictationOutputMode`, `dictationFolderPath`, `dictationHotkeyMode`, `clipboardRestoreDelay` (Phase 16, D-04). Phase 18 only consumes; no AppSettings changes.
- Existing menu bar extra in `PSTranscribeApp.swift:82-93` — DICT-03 ("menu bar indicator while dictation is recording") plumbs a recording-pulse SF Symbol variant into this existing entry.
- `AppDelegate` at `PSTranscribeApp.swift:99-166` — `applicationDidFinishLaunching` walks `NSApp.windows` and applies `sharingType` from `hideFromScreenShare`. The `didBecomeKeyNotification` observer at lines 116-131 catches new windows automatically — the new NSPanel inherits privacy mode without extra wiring (Pitfall #17 mitigation). For belt-and-suspenders, `DictationWindowController` should still set `panel.sharingType = .none` at creation.
- `chooseFolder(message:onSelect:)` at `Views/SettingsView.swift:585` — existing folder picker helper. Reuse for the plain-folder picker in the new Dictation section.
- `AppUpdaterController.swift` — pattern reference for wrapping a system framework as an `@Observable @MainActor` service.

### Established Patterns
- One actor / `@Observable @MainActor` class per concern (`TranscriptLogger`, `LibraryStore`, `SessionStore`, `SessionCoordinator`, `ModelUpdateService`); `DictationCoordinator` and `GlobalHotkeyService` are the next instances.
- AppSettings keys via `didSet` UserDefaults sync — single source of truth, no `@AppStorage`. KeyboardShortcuts uses its own `Defaults` system internally; the user's hotkey selection persists via the library (no manual UserDefaults plumbing required).
- `Form { Section { ... } }` composition in SettingsView — drop-in pattern for the new Dictation section.
- NotificationCenter for cross-component refresh signals — used for library refresh after meeting sessions; Phase 18 reuses with `.dictationSessionEnded`.
- Privacy mode applied to ALL `NSWindow` + `NSPanel` via the `AppDelegate` observer. The new HUD inherits automatically.

### Integration Points
- `PSTranscribeApp.swift` `init()` (lines 15-28) — instantiate `globalHotkeyService` and `dictationCoordinator`; wire `sessionCoordinator.dictation = dictationCoordinator` after instantiation.
- `PSTranscribeApp.swift` body (lines 48-94) — pass `dictationCoordinator` into `ContentView` if needed for menu-bar reactivity (or use `@Environment` injection — Claude's discretion).
- `MenuBarExtra` block at `PSTranscribeApp.swift:82-93` — toggle SF Symbol between `book.closed` and a pulsing mic variant based on `dictationCoordinator.isActive`.
- `SessionCoordinator.swift:29-32` — replace comment stub with `weak var dictation: DictationCoordinator?` and update `anySessionActive` body.
- `SettingsView.swift` end of Form — append new `Section("Dictation")` AFTER Speech Model.
- `LibraryStore.addEntry()` — called from `DictationCoordinator.endDictation()` after successful commit.
- `ContentView.swift` — verify whether the lifted `LibraryStore` already triggers re-render on append; if not, add NotificationCenter listener.

</code_context>

<specifics>
## Specific Ideas

- **Pre-warm at launch ≠ start meeting engine.** A SEPARATE `TranscriptionEngine` instance for dictation (Architecture Option B, locked). The dictation engine's `prepareModels()` runs in background at app launch (D-13). Meeting engine continues its existing lazy-load behavior. Two engines never run audio-capture simultaneously — `SessionCoordinator.anySessionActive` enforces mutual exclusion before either can `start()`.
- **KeyboardShortcuts.Recorder must allow user to clear/disable the hotkey.** When cleared, the global hotkey is deregistered and the dictation pre-warm at launch can be skipped (privacy-conscious users who never use dictation shouldn't pay the memory cost). Treat empty-hotkey as the explicit opt-out signal.
- **Clipboard restore (DICT-06) with changeCount guard:** save previous pasteboard contents and `NSPasteboard.general.changeCount` BEFORE writing transcript. After `clipboardRestoreDelay` (default 3.0s), check changeCount — if it has incremented beyond what we set with the dictation write, the user (or another app) copied something else; **skip restore** to avoid trampling their manual copy. Mitigates Pitfall #6 race.
- **30s cancel-confirmation state machine:** when Esc is pressed and session duration ≥ 30s, transition HUD to `cancellingPending` state with subtitle "Press Esc again to cancel" for ~3s. Second Esc within window → `cancelled`. No second Esc → revert to `listening`. Implement as a small state enum on `DictationCoordinator`.
- **HUD privacy belt-and-suspenders:** Pitfall #17 says new windows are caught by the existing `didBecomeKeyNotification` observer. In addition, explicitly set `panel.sharingType = .none` at NSPanel creation in `DictationWindowController.init`. Document the ScreenCaptureKit limitation (Phase 19 success criterion #3) in code comments — `sharingType = .none` only protects against legacy `CGWindowListCreateImage`; ScreenCaptureKit (Zoom, Teams, OBS, QuickTime) still captures the composited display. This is a known unfixable macOS API limitation.
- **ROADMAP roadmap line for Phase 18** must align with the realized architecture. Currently reads: "DictationHotkeyController (KeyboardShortcuts/RegisterEventHotKey, no permissions needed), DictationCoordinator, DictationWindowController + DictationHUD NSPanel, clipboard write with privacy markers, NSOpenPanel folder picker, DictationLogger plain-markdown writer, hotkey recorder UI, dictation settings section." Update to: replace `DictationHotkeyController` → `GlobalHotkeyService`; remove `DictationLogger` from new-files list (already exists from Phase 16). Flag in PLAN.md.
- **Library entry name auto-generation (D-10):** tokenize on whitespace, take first 5 tokens, join with single spaces, truncate to 50 chars on word boundary, append `…` if truncated, strip ASCII punctuation from leading/trailing. If empty after stripping, fallback to `Dictation YYYY-MM-DD HH:mm`.
- **`DictationLogger.discardSession()` (new method, supports D-08):** close file handle (if open), delete the file at `currentFilePath` if it exists, clear session state. Idempotent. Mirrors `endSession()` but deletes instead of returning the URL.
- **No reads from `NSPasteboard.general` in the dictation flow** (Pitfall #7 — macOS 26 pasteboard privacy alert). Save the previous clipboard contents BEFORE the user triggers dictation? No — that would require continuous polling. Instead: save at the moment the user triggers the hotkey (single read), then never read again. Acceptable per FEATURES.md research.
- **Default hotkey name registration:** in KeyboardShortcuts, register a `KeyboardShortcuts.Name` constant (e.g., `Name.dictateGlobal`) with default `Shortcut(.d, modifiers: [.command, .shift])`. The library handles persistence via `Defaults`. UserDefaults key namespace: `KeyboardShortcuts_dictateGlobal`.

</specifics>

<deferred>
## Deferred Ideas

- **Configurable HUD position** (DICT-FUT-01) — locked to bottom-center for v1.2.
- **Multi-locale dictation** (DICT-FUT-02) — inherits app's existing single locale.
- **Per-app hotkey behavior** (DICT-FUT-03) — deferred beyond v1.2.
- **Auto-paste via accessibility API** — explicitly out of scope (REQUIREMENTS.md).
- **Direct-inject text via accessibility** — explicitly out of scope (REQUIREMENTS.md).
- **Dictation history search** — out of scope for v1.2 (REQUIREMENTS.md).
- **LLM cleanup of dictated text** — out of scope (2026-04-04 scope reduction, archive/llm-analysis-attempt).
- **Configurable cancel threshold** (default 30s in toggle, 1s accidental-tap in hold) — keep hardcoded for v1.2; revisit if user requests.
- **Min-words filter for library entries** — explicitly rejected per D-09 (every dictation logged).
- **Settings UI for `clipboardRestoreDelay`** — Phase 16 added the AppSettings key; whether to expose it as a Settings control or leave as defaults-only is Claude's discretion in planning.
- **Configurable HUD content density** (just text vs text+timer+stop) — locked to text+timer+stop per D-01.
- **Configurable HUD visual style** (Chronicle paper vs native HUD vs minimal) — locked to native HUD per D-03.
- **Separate "Dictations" filter / view in library** — rejected per D-11; inline alongside meetings.
- **Library entry as a copy in app storage when plain-folder is configured** — rejected per D-12; library row points at plain-folder file directly.
- **Hard-block on system-reserved hotkeys** (Pitfall #3) — Claude's discretion: warn-but-allow per FEATURES.md.

</deferred>

---

*Phase: 18-hotkey-dictation-plain-folder-output*
*Context gathered: 2026-04-27*
