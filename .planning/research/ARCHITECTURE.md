# Architecture Research

**Domain:** macOS native audio transcription app -- v1.2 feature integration
**Researched:** 2026-04-27
**Confidence:** HIGH (all findings derived from direct source inspection)

---

## Scope

This document covers only the v1.2 integration surface. The base architecture (actor-based concurrency, @Observable state, dual-stream ASR pipeline, Sparkle update mechanism) is treated as fixed. The three new features are:

1. Keyboard-triggered clipboard dictation
2. Plain-folder dictation output
3. Model auto-update (independent channel from Sparkle)

---

## Existing Component Map (Integration Reference)

```
PSTranscribeApp.swift           -- @main, window/menubar/settings scene setup
AppDelegate (nested)            -- window lifecycle, screen-share visibility
  |
  +-- ContentView.swift         -- session orchestrator, all @State for live sessions
        |
        +-- TranscriptionEngine.swift   -- @Observable @MainActor, owns Tasks + FluidAudio
        |     +-- MicCapture.swift      -- AVAudioEngine tap, AsyncStream<AVAudioPCMBuffer>
        |     +-- SystemAudioCapture.swift -- ScreenCaptureKit, AsyncStream + WAV buffer
        |     +-- StreamingTranscriber.swift (x2) -- VAD+ASR worker per stream
        |
        +-- TranscriptStore.swift       -- @Observable @MainActor, utterances + volatile text
        +-- TranscriptLogger.swift      -- actor, markdown writer + frontmatter
        +-- SessionStore.swift          -- actor, JSONL crash-recovery checkpointing
        +-- LibraryStore.swift          -- actor, library.json index (ApplicationSupport)
        |
        +-- CaptureDock.swift           -- UI: record button, status, timer
        +-- LibrarySidebar.swift        -- UI: session list
        +-- TranscriptView.swift        -- UI: live + past transcript display

AppSettings.swift               -- @Observable @MainActor, UserDefaults-backed prefs
  -- vaultMeetingsPath, vaultVoicePath, transcriptionLocale, inputDeviceID, ...

OnboardingView.swift            -- model download prompt (shown when !hasCompletedOnboarding)
AppUpdaterController.swift      -- Sparkle SPUUpdater wrapper
```

**Model cache location:** `~/Library/Application Support/FluidAudio/Models/<repo-folderName>/`
(e.g. `parakeet-tdt-0.6b-v3-coreml/`)
**Library index:** `~/Library/Application Support/PSTranscribe/library.json`
**Session checkpoints:** `~/Library/Application Support/PSTranscribe/sessions/` (JSONL)

---

## Feature 1: Keyboard-Triggered Clipboard Dictation

### New Components Required

| Component | File | Type | Purpose |
|-----------|------|------|---------|
| `GlobalHotkeyService` | `Sources/PSTranscribe/Services/GlobalHotkeyService.swift` | `@Observable @MainActor final class` | Registers/deregisters a global hotkey via `CGEventTap` or `NSEvent.addGlobalMonitorForEvents`; publishes `hotkeyFired` callback on MainActor |
| `DictationHUD` | `Sources/PSTranscribe/Views/DictationHUD.swift` | `struct: View` | Compact floating NSPanel body -- shows live partial text + elapsed time + stop button |
| `DictationWindowController` | `Sources/PSTranscribe/App/DictationWindowController.swift` | `@MainActor final class` (NSWindowController subclass) | Owns the NSPanel lifecycle; opened and closed by `DictationCoordinator` |
| `DictationCoordinator` | `Sources/PSTranscribe/App/DictationCoordinator.swift` | `@Observable @MainActor final class` | Orchestrates the full dictation flow: hotkey-press -> engine start -> HUD open -> stop -> clipboard write -> library save |

### Existing Components Modified

| Component | File | What Changes |
|-----------|------|--------------|
| `PSTranscribeApp.swift` | existing | Instantiate `GlobalHotkeyService` + `DictationCoordinator` + `ModelUpdateService` at app scope; lift `LibraryStore` to app scope |
| `AppSettings.swift` | existing | Add `dictationHotkey: KeyCombo` (stored in UserDefaults), `dictationOutputMode: DictationOutputMode` enum, `dictationFolderPath: String` |
| `SettingsView.swift` | existing | Add Dictation section: hotkey recorder, output mode picker, plain-folder path chooser |
| `TranscriptionEngine.swift` | existing | Add `reloadModels()` async method (for model update); dictation flow uses a separate engine instance owned by `DictationCoordinator` -- no changes to start/stop |
| `TranscriptLogger.swift` | existing | Add `startPlainSession(vaultPath:)` + `finalizePlain()` methods that write clean markdown without YAML frontmatter |
| `Models.swift` | existing | Add `case dictation` to `SessionType` enum; add `DictationOutputMode` enum |
| `ContentView.swift` | existing | Accept `LibraryStore` as injected parameter (lifted from `@State` to app scope); add `NotificationCenter` listener for library refresh when dictation session ends |
| `Tome.entitlements` | existing | Add accessibility entitlement if using global `CGEventTap` (`com.apple.security.temporary-exception.accessibility`) |

### Recording State Machine: Shared vs Separate Engine

The existing `TranscriptionEngine` is `@MainActor` and designed for dual-stream (mic + system). Dictation needs mic only.

**Option A -- Reuse same engine:** Add `startDictation()` to the existing `TranscriptionEngine` that skips `SystemAudioCapture`. Risk: `isRunning` is shared; a dictation session and a normal session cannot coexist. Requires mutual exclusion enforced from outside.

**Option B -- Separate engine instance owned by `DictationCoordinator`:** `DictationCoordinator` holds its own `TranscriptionEngine(transcriptStore: dictationStore)` where `dictationStore` is a private `TranscriptStore`. No changes to the existing state machine. Mutual exclusion enforced by `DictationCoordinator.beginDictation()` checking a shared "any session active" flag.

**Recommendation: Option B.** Safer -- the existing recording state machine is not modified. `DictationCoordinator` checks `ContentView.isRunning` (exposed via a shared `@Observable` flag or `NotificationCenter`) before starting. The two engines cannot run simultaneously.

### Shared "Session Active" Guard

Lift a boolean flag `anySessionActive: Bool` to `PSTranscribeApp` scope as `@Observable`. Both `ContentView.startSession()` and `DictationCoordinator.beginDictation()` set it on start and clear it on stop. Each checks the flag before starting. This replaces checking `isRunning` on a specific engine instance.

### Data Flow: Hotkey Press to Clipboard Paste to Library Save

```
User presses hotkey
    |
GlobalHotkeyService fires on MainActor
    |
DictationCoordinator.beginDictation()
    |-- guard anySessionActive == false
    |-- anySessionActive = true
    |-- DictationWindowController.show()        -- NSPanel appears (floating)
    |-- dictationStore.clear()
    |-- [if file output] transcriptLogger.startPlainSession(dictationFolderPath)
    |-- dictationEngine.start(locale:, inputDeviceID:)   -- mic only, no ScreenCaptureKit
    |
    +-- [utterances arrive via dictationStore.utterances]
    |       DictationHUD shows volatileYouText (live partials)
    |       DictationCoordinator.handleNewUtterance()
    |           -> transcriptLogger.append(...)     [if file output enabled]
    |
User presses hotkey again (toggle) OR taps stop button in HUD
    |
DictationCoordinator.endDictation()
    |-- dictationEngine.stop()
    |-- [if file output] transcriptLogger.endSession() + finalizePlain()
    |-- [if clipboard or both]
    |       let text = dictationStore.utterances.map { $0.text }.joined(separator: " ")
    |       NSPasteboard.general.clearContents()
    |       NSPasteboard.general.setString(text, forType: .string)
    |-- LibraryStore.addEntry(LibraryEntry(sessionType: .dictation, ...))
    |-- anySessionActive = false
    |-- DictationWindowController.close()
    |-- NotificationCenter.default.post(name: .dictationSessionEnded, object: nil)
    |       -> ContentView.refreshLibrary()
```

**NSPasteboard write** is a single synchronous call on MainActor after `stop()` returns. No entitlement needed -- pasteboard write is always permitted in a macOS app.

**HUD dismiss timing:** Dismiss the HUD immediately on stop, then run the async finalization (endSession, finalizePlain) as a `Task`. Do not block the user waiting for file finalization.

---

## Feature 2: Plain-Folder Dictation Output

### Components

No new actor required. Add two methods to the existing `TranscriptLogger` actor:

- `startPlainSession(vaultPath: String)` -- creates a `.md` file with a simple date/time header, no YAML frontmatter, no Obsidian tags
- `finalizePlain()` -- no-op (file was written utterance-by-utterance); closes the file handle

**File format (plain output):**

```markdown
# Dictation -- 2026-04-27 14:30

**You** (14:30:01)
First utterance text.

**You** (14:30:08)
Second utterance text.
```

### Existing Components Modified

| Component | File | What Changes |
|-----------|------|--------------|
| `TranscriptLogger.swift` | existing | `startPlainSession(vaultPath:)` + `finalizePlain()` -- ~40 lines |
| `AppSettings.swift` | existing | `dictationFolderPath: String` (separate from vaultMeetingsPath/vaultVoicePath) |
| `SettingsView.swift` | existing | Folder chooser for dictation plain output path in Dictation section |

### DictationOutputMode Coexistence

```swift
enum DictationOutputMode: String, Codable {
    case clipboard     // NSPasteboard only, no file
    case plainFolder   // file only, no clipboard
    case both          // file AND clipboard
}
```

`DictationCoordinator.endDictation()` checks `settings.dictationOutputMode` and executes the appropriate paths. The file write and the clipboard write are independent operations -- both can run, either can be skipped.

---

## Feature 3: Model Auto-Update

### Background

FluidAudio's `AsrModels.downloadAndLoad(version:)` pulls from HuggingFace (`FluidInference/parakeet-tdt-0.6b-v3-coreml`). Models cache to `~/Library/Application Support/FluidAudio/Models/parakeet-tdt-0.6b-v3-coreml/`. There is no built-in version-check -- `downloadAndLoad` only downloads if models are absent. The app must implement check-download-verify-swap-rollback.

### New Components Required

| Component | File | Type | Purpose |
|-----------|------|------|---------|
| `ModelUpdateService` | `Sources/PSTranscribe/Services/ModelUpdateService.swift` | `@Observable @MainActor final class` | Version check, download, verify, swap, rollback; exposes `updateState: ModelUpdateState` |
| `ModelUpdateState` | same file | enum | `.idle`, `.checking`, `.updateAvailable(version: String)`, `.downloading(progress: Double)`, `.verifying`, `.applying`, `.failed(String)`, `.upToDate` |
| Model version manifest | hosted JSON (gh-pages) | external | Small JSON at a stable URL, published alongside `appcast.xml`, declaring the current model version identifier and per-file SHA-256 checksums |

### Version Manifest Format

Hosted at a raw URL on the `gh-pages` branch, parallel to `appcast.xml`:

```json
{
  "model_id": "parakeet-tdt-0.6b-v3-coreml",
  "version": "20260427",
  "min_app_version": "1.2.0",
  "files": [
    { "name": "preprocessor.mlpackage", "sha256": "<hex>" },
    { "name": "encoder.mlpackage",      "sha256": "<hex>" },
    { "name": "decoder.mlpackage",      "sha256": "<hex>" },
    { "name": "joint.mlpackage",        "sha256": "<hex>" }
  ]
}
```

The app compares `manifest.version` against `AppSettings.installedModelVersion`. If manifest is newer AND `manifest.min_app_version` is satisfied, an update is available.

### Existing Components Modified

| Component | File | What Changes |
|-----------|------|--------------|
| `AppSettings.swift` | existing | Add `installedModelVersion: String`, `modelAutoUpdateEnabled: Bool`, `modelLastCheckedDate: Date?` |
| `SettingsView.swift` | existing | Add "Model Updates" section: current version string, "Check for Updates" button, auto-update toggle, last-checked date |
| `TranscriptionEngine.swift` | existing | Add `reloadModels() async` -- nils `asrManager`/`vadManager`, calls `AsrModels.downloadAndLoad()` against the existing cache dir, reassigns both managers, sets `modelsReady = true` |
| `OnboardingView.swift` | existing | Show `ModelUpdateService.updateState` in addition to `TranscriptionEngine.assetStatus` during first-run model download |
| `PSTranscribeApp.swift` | existing | Instantiate `ModelUpdateService` at app scope; pass to `SettingsView` and `OnboardingView` |

### Data Flow: Version Check to Hot-Swap

```
App launch (or periodic check, or user taps "Check for Updates")
    |
ModelUpdateService.checkForUpdate()
    |-- updateState = .checking
    |-- URLSession.data(from: modelManifestURL)
    |-- decode ModelVersionManifest
    |-- guard manifest.min_app_version <= current app version
    |-- compare manifest.version vs AppSettings.installedModelVersion
    |
    +-- [up to date]
    |       updateState = .upToDate
    |       AppSettings.modelLastCheckedDate = now
    |
    +-- [update available]
            updateState = .updateAvailable(version: manifest.version)
            |
            [if autoUpdateEnabled OR user taps "Install Update"]
            |-- guard anySessionActive == false
            |           (surface "Stop recording before updating" if active)
            |
            ModelUpdateService.downloadAndApply()
                |-- updateState = .downloading(progress: 0)
                |-- download each model file to staging dir:
                |       ~/Library/Application Support/FluidAudio/Models/<repo>-staging/
                |   (reuse FluidAudio's DownloadUtils or roll URLSession download)
                |-- updateState = .verifying
                |-- SHA-256 each downloaded file against manifest.files[*].sha256
                |-- [checksum mismatch] --> rm staging, updateState = .failed("Checksum mismatch")
                |
                |-- updateState = .applying
                |-- backup current model dir:
                |       mv <repo>/ -> <repo>-backup/
                |-- rename staging to active:
                |       mv <repo>-staging/ -> <repo>/
                |-- TranscriptionEngine.reloadModels()
                |       asrManager = nil; vadManager = nil
                |       AsrModels.downloadAndLoad() -- hits disk (files already present)
                |       asrManager = AsrManager(...); vadManager = VadManager()
                |       modelsReady = true
                |-- AppSettings.installedModelVersion = manifest.version
                |-- AppSettings.modelLastCheckedDate = now
                |-- rm <repo>-backup/
                |-- updateState = .idle
                |
                [on failure after backup but before successful reload]
                |-- mv <repo>/ -> <repo>-failed/   (preserve for diagnostics)
                |-- mv <repo>-backup/ -> <repo>/
                |-- TranscriptionEngine.reloadModels()   -- restore prior version
                |-- updateState = .failed("Update failed -- previous version restored")
```

**Constraint:** `anySessionActive == false` is required before apply. The "Install Update" button and auto-update path both check this. If a session starts after the download completes but before apply, the apply is deferred until the session ends.

**Entitlement concern:** All directory operations occur within `~/Library/Application Support/FluidAudio/` and `~/Library/Application Support/PSTranscribe/`, both of which are already accessible. No additional entitlements needed.

---

## Component Interaction Map

```
PSTranscribeApp.swift (app scope)
  |
  +-- @State settings: AppSettings            [existing -- stays here]
  +-- @State libraryStore: LibraryStore       [LIFTED from ContentView to app scope]
  +-- @State anySessionActive: Bool           [NEW shared flag]
  +-- @State globalHotkeyService: ...         [NEW]
  +-- @State dictationCoordinator: ...        [NEW]
  |     +-- owns: TranscriptionEngine (dictation instance, mic-only)
  |     +-- owns: TranscriptStore (dictation)
  |     +-- owns: TranscriptLogger (dictation)
  |     +-- refs: LibraryStore (shared, injected from app scope)
  |     +-- refs: AppSettings (shared)
  |     +-- refs: anySessionActive flag
  |
  +-- @State modelUpdateService: ...          [NEW]
  |     +-- refs: AppSettings (installedModelVersion)
  |     +-- refs: anySessionActive flag (guard before apply)
  |     +-- refs: transcriptionEngine (main instance, for reloadModels)
  |
  +-- ContentView(settings:, libraryStore:, anySessionActive:, ...)
        +-- @State transcriptionEngine: ...    [existing -- stays in ContentView]
        +-- sets anySessionActive on start/stop
```

**LibraryStore lift:** Currently initialized as `@State private var libraryStore = LibraryStore()` inside `ContentView`. Must move to `PSTranscribeApp` so `DictationCoordinator` can share the same instance. Pass it into `ContentView` via initializer parameter, following the existing pattern for `AppSettings` and `NotionService`.

---

## Architectural Patterns for New Components

### GlobalHotkeyService: Permission Tradeoffs

Two approaches:

**CGEventTap (global, background):** Works when the app is not frontmost. Requires Accessibility permission (`System Settings > Privacy & Security > Accessibility`). The permission dialog is one extra step users must approve. Tap must be created on a background dispatch queue; events forwarded to MainActor via `Task { @MainActor in ... }`. Wrap in a class conforming to `@unchecked Sendable` with an NSLock, matching the `MicCapture`/`AudioLevel` pattern.

**NSEvent.addGlobalMonitorForEvents (simpler, same permission):** Available on macOS without entitlement changes, but still requires the same Accessibility permission in practice. Slightly simpler API than CGEventTap. Less control over event consumption.

**Fallback: menu bar action only:** If permission friction is unacceptable, the HUD can also be triggered from the menu bar extra or a menu item with a keyboard shortcut registered only while the app is active. This requires no special permissions. Offer this as the default, with global hotkey as an opt-in setting.

**Recommendation:** Ship with menu bar trigger as default (zero permission friction). Add global hotkey as a Settings toggle with a clear "requires Accessibility access" label. This avoids a permission prompt on first launch.

### DictationHUD: NSPanel

Use `NSPanel` with `.nonactivatingPanel` style mask so it floats without stealing focus from whatever the user is typing into. Set `window.level = .floating` and `window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`. Use `NSHostingView<DictationHUD>` as the content. Apply the same `sharingType` logic as the main window (respects `hideFromScreenShare`).

Position: vertically centered on the bottom quarter of the screen (mirroring macOS Dictation feedback window placement).

### ModelUpdateService: Concurrency

`ModelUpdateService` is `@Observable @MainActor`. Download work runs in `Task { ... }` (not `Task.detached` -- no Sendable issues since the actor boundary handles isolation). Progress updates from URLSession delegate are forwarded to MainActor using `await MainActor.run { self.updateState = .downloading(progress: p) }`.

The directory rename (`FileManager.moveItem`) is synchronous and runs directly on MainActor after verification. It is fast (APFS rename is O(1) on the same volume) and does not require offloading.

---

## Full Data Flow Diagrams

### Flow 1: Dictation (Complete Path)

```
User presses global hotkey
    |
GlobalHotkeyService.onHotkey fires on MainActor
    |
DictationCoordinator.beginDictation()
    |-- guard anySessionActive == false
    |-- anySessionActive = true
    |-- DictationWindowController.show()         -- NSPanel appears
    |-- dictationStore.clear()
    |-- [if .plainFolder or .both]
    |       transcriptLogger.startPlainSession(settings.dictationFolderPath)
    |-- dictationEngine.start(locale: settings.locale, inputDeviceID: settings.inputDeviceID)
    |
    +-- [utterances flow: StreamingTranscriber -> dictationStore -> DictationHUD]
    |       DictationCoordinator.handleNewUtterance(utterance)
    |           [if file output] transcriptLogger.append(...)
    |
User toggles hotkey again (or taps HUD stop button)
    |
DictationCoordinator.endDictation()
    |-- [if file output] transcriptLogger.endSession()
    |-- dictationEngine.stop()
    |-- [if file output] transcriptLogger.finalizePlain()
    |-- [if .clipboard or .both]
    |       let text = dictationStore.utterances.map { $0.text }.joined(separator: " ")
    |       NSPasteboard.general.clearContents()
    |       NSPasteboard.general.setString(text, forType: .string)
    |-- [if file output]
    |       LibraryStore.addEntry(LibraryEntry(sessionType: .dictation, filePath: ..., ...))
    |-- anySessionActive = false
    |-- DictationWindowController.close()
    |-- NotificationCenter.post(.dictationSessionEnded)
            --> ContentView receives notification --> refreshLibrary()
```

### Flow 2: Plain Folder Write

```
TranscriptLogger.startPlainSession(vaultPath: dictationFolderPath)
    -- creates: <dictationFolderPath>/2026-04-27 14-30-00 Dictation.md
    -- writes header only: "# Dictation -- 2026-04-27 14:30\n\n"
    -- opens file handle, seeks to end

TranscriptLogger.append(speaker: "You", text: "...", timestamp: ...)
    -- appends: "**You** (14:30:01)\nText here.\n\n"

TranscriptLogger.finalizePlain()
    -- closes file handle
    -- no frontmatter rewrite (there is no frontmatter)
    -- returns currentFilePath
```

### Flow 3: Model Auto-Update

```
ModelUpdateService.checkForUpdate()
    |-- URLSession fetch --> parse ModelVersionManifest
    |-- compare manifest.version vs AppSettings.installedModelVersion
    |
    +-- [same] updateState = .upToDate
    |
    +-- [newer] updateState = .updateAvailable(version: "20260501")
    |
    [if autoUpdate OR user taps Install]
    ModelUpdateService.downloadAndApply()
        |-- guard anySessionActive == false
        |-- download each file to <repo>-staging/ with progress updates
        |-- verify SHA-256 per file
        |-- [fail] rm staging, updateState = .failed(...)
        |-- mv <repo>/ -> <repo>-backup/
        |-- mv <repo>-staging/ -> <repo>/
        |-- await transcriptionEngine.reloadModels()
        |       -- asrManager = nil; vadManager = nil
        |       -- let models = try await AsrModels.downloadAndLoad(version: .v3)
        |             (reads from disk -- no network needed)
        |       -- asrManager = AsrManager(config: .default); try await asr.loadModels(models)
        |       -- vadManager = try await VadManager()
        |       -- modelsReady = true
        |-- AppSettings.installedModelVersion = manifest.version
        |-- rm <repo>-backup/
        |-- updateState = .idle
        |
        [if reloadModels() throws after swap]
        |-- mv <repo>/ -> <repo>-failed/
        |-- mv <repo>-backup/ -> <repo>/
        |-- await transcriptionEngine.reloadModels()   -- reload from restored backup
        |-- updateState = .failed("Updated rolled back -- prior version restored")
```

---

## New vs Modified: Quick Reference

| Component | Status | File |
|-----------|--------|------|
| `GlobalHotkeyService` | NEW | `Sources/PSTranscribe/Services/GlobalHotkeyService.swift` |
| `DictationCoordinator` | NEW | `Sources/PSTranscribe/App/DictationCoordinator.swift` |
| `DictationWindowController` | NEW | `Sources/PSTranscribe/App/DictationWindowController.swift` |
| `DictationHUD` | NEW | `Sources/PSTranscribe/Views/DictationHUD.swift` |
| `ModelUpdateService` | NEW | `Sources/PSTranscribe/Services/ModelUpdateService.swift` |
| `Models.swift` | MODIFIED | add `SessionType.dictation`, `DictationOutputMode` |
| `AppSettings.swift` | MODIFIED | add dictation + model update keys |
| `PSTranscribeApp.swift` | MODIFIED | lift `LibraryStore`, add new services at app scope |
| `ContentView.swift` | MODIFIED | accept injected `LibraryStore`; add notification listener |
| `TranscriptLogger.swift` | MODIFIED | add `startPlainSession` + `finalizePlain` |
| `TranscriptionEngine.swift` | MODIFIED | add `reloadModels()` |
| `SettingsView.swift` | MODIFIED | add Dictation section + Model Updates section |
| `OnboardingView.swift` | MODIFIED | show model version from `ModelUpdateService` |
| `Tome.entitlements` | MODIFIED (maybe) | add accessibility entitlement if using global CGEventTap |

---

## Build Order

```
Phase A: Foundation -- no v1.2 feature dependencies (build first, unblocks B + C)
  A1. Models.swift -- SessionType.dictation + DictationOutputMode enum        [30 min]
  A2. AppSettings.swift -- all v1.2 keys                                       [1 hr]
  A3. TranscriptLogger.swift -- startPlainSession + finalizePlain              [2 hr]
  A4. PSTranscribeApp.swift -- lift LibraryStore, add anySessionActive flag    [1 hr]
  A5. ContentView.swift -- accept injected LibraryStore (refactor, no new UX) [1 hr]

Phase B: Model Update Service (independent of dictation -- run in parallel with C)
  B1. ModelUpdateService -- manifest fetch, version compare                    [2 hr]
  B2. ModelUpdateService -- download, verify, staging directory management     [4 hr]
  B3. TranscriptionEngine.reloadModels()                                       [2 hr]
  B4. SettingsView Model Updates section                                       [1 hr]
  B5. OnboardingView -- show model version                                     [30 min]
  [total: ~9.5 hr]

Phase C: Dictation (depends on A -- run in parallel with B)
  C1. GlobalHotkeyService -- menu bar trigger (default) + optional CGEventTap  [3 hr]
  C2. DictationCoordinator -- engine lifecycle, begin/end flow                 [3 hr]
       (depends on A3, C1)
  C3. DictationHUD + DictationWindowController -- NSPanel + SwiftUI body       [3 hr]
       (can be built parallel to C2)
  C4. Wire C2 + C3 into PSTranscribeApp                                        [2 hr]
       (depends on C2, C3)
  C5. NSPasteboard write + plain folder output paths                           [1 hr]
       (depends on C4, A3)
  C6. LibraryStore.addEntry() from DictationCoordinator                        [1 hr]
  C7. ContentView: NotificationCenter listener for library refresh             [30 min]
  [total: ~13.5 hr]

Phase D: Integration + Hardening (depends on B + C complete)
  D1. End-to-end dictation: hotkey -> HUD -> clipboard -> library
  D2. End-to-end model update: manifest -> download -> reload
  D3. Concurrent session guard: normal session blocks dictation + model update
  D4. Model update rollback path (simulate bad checksum, simulate reload failure)
  D5. Permission flow: Accessibility prompt for global hotkey
  D6. SettingsView: hotkey recorder control (key combo capture via NSEvent)
```

**Parallelism:** Phases B and C are fully independent of each other; both can start as soon as Phase A is done (~5.5 hrs). B runs ~9.5 hrs; C runs ~13.5 hrs. Phase D starts when both are done. Total on a single track: ~28.5 hrs. With two parallel implementation slots (B and C overlapping): ~19 hrs to Phase D start.

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Global hotkey requires Accessibility permission -- friction on first launch | MEDIUM | Default to menu bar trigger; expose global hotkey as opt-in in Settings |
| Race: dictation starts while normal session starts (between guard and anySessionActive set) | MEDIUM | Both paths set `anySessionActive` on `@MainActor` -- Swift actor isolation prevents this race |
| Model swap while `AsrManager` holds loaded MLModels in memory | LOW | `reloadModels()` nils both managers before touching the directory; ARC drops MLModel refs before rename |
| HuggingFace download URL changes between model releases | MEDIUM | Version manifest controls the per-file download URLs; update manifest without app release |
| Plain-folder output path unset -- silent no-op | LOW | `DictationCoordinator.beginDictation()` validates `dictationFolderPath` before starting; surfaces error in HUD |
| LibraryStore lift breaks ContentView initialization | LOW | `LibraryStore` is an actor with no constructor side effects; lift is straightforward |
| `reloadModels()` called while engine is mid-session | HIGH | Guard on `anySessionActive` before apply; do not expose `reloadModels()` as public API except through `ModelUpdateService` |

---

## Hard Constraints Respected

- **Actor-based concurrency:** All new service classes are `@Observable @MainActor final class`; file I/O in actors; background work via `Task { ... }`; callbacks cross actor boundaries with `await MainActor.run { ... }`
- **@Observable state:** New service classes use `@Observable`, not `ObservableObject` / `@Published`
- **On-device only:** No new external API calls except the model version manifest fetch (a small JSON) and the model file downloads from HuggingFace (same source FluidAudio already uses)
- **No new heavy dependencies:** `NSPasteboard`, `CGEventTap`, `URLSession` are all system frameworks; no `Package.swift` additions needed for dictation or model update
- **Existing ASR pipeline unchanged:** Dictation reuses `TranscriptionEngine` / `StreamingTranscriber` / `MicCapture` without modifying their core logic

---

## Sources

- Direct inspection: all files under `PSTranscribe/Sources/PSTranscribe/` (confirmed 2026-04-27)
- FluidAudio internals: `AsrModels.swift`, `ModelNames.swift`, `MLModelConfigurationUtils.swift` (model cache at `~/Library/Application Support/FluidAudio/Models/<repo>/`)
- `.planning/codebase/ARCHITECTURE.md`, `STRUCTURE.md`, `CONVENTIONS.md`, `INTEGRATIONS.md`, `CONCERNS.md`, `STACK.md`
- `.planning/PROJECT.md` -- constraints and decisions

---
*Architecture research for: PS Transcribe v1.2 feature integration*
*Researched: 2026-04-27*
