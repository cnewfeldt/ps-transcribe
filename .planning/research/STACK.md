# Stack Research: v1.2 New Features

**Domain:** macOS native app -- dictation tooling + out-of-band model update channel
**Researched:** 2026-04-27
**Confidence:** HIGH (global hotkey, clipboard, folder picker); MEDIUM (model update channel -- no FluidAudio-native version-check API exists, custom approach required)

---

## Scope

This document covers ONLY the stack additions required for v1.2's three new capabilities:

1. Keyboard-triggered clipboard dictation (global hotkey + NSPasteboard write)
2. Plain-folder dictation output (user-configurable OS folder, no Obsidian)
3. Model auto-update (out-of-band ASR model version checking, separate from Sparkle)

The existing validated stack (Swift 6.2, SwiftUI, FluidAudio, Sparkle, actor concurrency, @Observable) is NOT re-researched here.

---

## Existing Stack (Reference Only)

| Technology | Version | Role |
|------------|---------|------|
| Swift | 6.2 | Language |
| SwiftUI + AppKit | macOS 26.0+ | UI framework |
| FluidAudio | commit ea50062 | ASR / VAD / diarization |
| Sparkle | 2.9.0 | App binary auto-update |
| AVFoundation + ScreenCaptureKit | system | Audio capture |
| @Observable / actors | Swift stdlib | State + concurrency |

---

## Feature 1: Global Hotkey (Clipboard Dictation Trigger)

### Decision: KeyboardShortcuts by sindresorhus -- REQUIRED new SwiftPM dependency

**Package:** `https://github.com/sindresorhus/KeyboardShortcuts`
**Version:** `2.4.0` (released September 2025, latest verified as of 2026-04-27)
**SwiftPM declaration:**
```swift
.package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.4.0"),
```

**Why this over every alternative:**

| Approach | Requires Accessibility? | Sandbox OK? | User-configurable UI? | Verdict |
|----------|------------------------|-------------|----------------------|---------|
| `NSEvent.addGlobalMonitorForEvents` | YES | Breaks without it | No | REJECT |
| `CGEventTap` | YES (Input Monitoring) | Needs entitlement | No | REJECT |
| Carbon `RegisterEventHotKey` raw | No | Yes | No built-in UI | REJECT (bare) |
| soffes/HotKey | No | Unclear | No UI component | REJECT |
| **KeyboardShortcuts 2.4.0** | **No** | **Yes -- App Store compatible** | **Yes -- `Recorder` SwiftUI view** | **USE** |

**Key verified facts:**

- Wraps Carbon `RegisterEventHotKey` internally. Carbon is the ONLY macOS API for global hotkeys that requires no Accessibility or Input Monitoring permission. The narrow contract ("fire when THIS exact combo is pressed, nothing else") is why Apple does not gate it.
- `NSEvent.addGlobalMonitorForEvents` requires granting the app Accessibility in System Settings. That forces a manual user step on every install, adds an `com.apple.security.accessibility` entitlement, and blocks App Store distribution. Rejected.
- `CGEventTap` requires Input Monitoring permission -- same user-friction problem, different entitlement. Rejected.
- **macOS 15+ (Sequoia) modifier restriction:** `RegisterEventHotKey` no longer fires when the ONLY modifiers are Option or Option+Shift alone. Apple introduced this to prevent keystroke-logging malware. Any shortcut that includes Cmd, Ctrl, or Cmd+Option still works. Default dictation shortcut recommendation: `Cmd+Shift+D`.
- `KeyboardShortcuts.Recorder` is a native SwiftUI view -- drop it into `SettingsView` to let users reassign the hotkey without any custom UI work.

**Entitlement impact:** None. No new keys in `PSTranscribe.entitlements`.

**Integration point:** New `DictationHotkeyController.swift` in `Sources/PSTranscribe/App/`, following the exact pattern of `AppUpdaterController.swift`. Initialized in `PSTranscribeApp.swift`. On hotkey fire, calls into a new `DictationSession` coordinator (see below) on `@MainActor`.

---

## Feature 2: Clipboard Write (NSPasteboard)

### Decision: First-party NSPasteboard -- no new dependency

**API:** `NSPasteboard.general` (AppKit, already available via `import AppKit`).

**Write pattern (Swift 6 / @MainActor safe):**

```swift
@MainActor
func writeTranscriptToClipboard(_ text: String) {
    let pb = NSPasteboard.general
    pb.clearContents()
    pb.setString(text, forType: .string)
}
```

`NSPasteboard` is AppKit-owned and inherently main-thread-bound. Calling it from `@MainActor`-isolated code has no Swift 6 concurrency issues.

**macOS 26 clipboard privacy warning (verified and resolved):**

Apple introduced iOS-style clipboard privacy in macOS 15.4 (developer preview) and macOS 26. The permission prompt fires when an app READS the clipboard without a user-initiated paste action. **Writing to the clipboard does NOT trigger the prompt.** PS Transcribe places text on the clipboard and never reads it back. No impact on this feature.

The privacy change was "absent by default in macOS 26" unless the developer preview flag is set, per community investigation as of late 2025. No entitlement or user-facing permission required.

**Entitlement impact:** None. Non-sandboxed apps write to `NSPasteboard.general` freely.

**Integration point:** Called at the end of a dictation session's `onFinal` callback chain in the dictation coordinator, after the final transcript is assembled from `TranscriptStore`. Same execution path that currently saves to vault files.

---

## Feature 3: Plain-Folder Dictation Output

### Decision: Raw URL paths + NSOpenPanel -- no new dependency, no security-scoped bookmarks

**Why no security-scoped bookmarks:** Security-scoped bookmarks are a sandbox mechanism. The existing `PSTranscribe.entitlements` (verified by direct inspection) contains only `com.apple.security.device.audio-input` and `com.apple.security.device.screen-capture` -- the `com.apple.security.app-sandbox` key is ABSENT. The app is NOT sandboxed. Raw `URL(fileURLWithPath:)` access works without any bookmark infrastructure, exactly as the existing `vaultMeetingsPath` / `vaultVoicePath` implementation already does.

**Implementation pattern:** Identical to the existing Obsidian folder configuration in `SettingsView.swift` (the `obsidianFolderRow` pattern at line 135):

1. `NSOpenPanel` with `canChooseDirectories = true`, `canChooseFiles = false` presents the picker.
2. User selects a folder; the absolute path string is written to `UserDefaults`.
3. New `AppSettings` key: `dictationFolderPath` (String, default `""` = disabled, save to library only).
4. A new `DictationLogger` actor in `Sources/PSTranscribe/Storage/` writes clean markdown without YAML frontmatter. This is a new actor (not a mode parameter on the existing `TranscriptLogger`) to keep the clean-output path isolated from the YAML-heavy meeting transcript path.

**Output format for plain folder:** Markdown filename `YYYY-MM-DD-HH-mm-ss.md`, body is the verbatim transcript text, no frontmatter. Optionally: an H1 heading with the timestamp if file names alone are too sparse.

**Entitlement impact:** None.

**Integration point:** `AppSettings` gets one new persisted property. `SettingsView` gets a new "Dictation" section with a folder picker row. New `DictationLogger` actor in `Storage/` is called from the dictation session coordinator after transcription completes.

---

## Feature 4: Model Auto-Update Channel

### Decision: Custom HuggingFace refs API poll via URLSession -- no new library

**Why not Sparkle:** Sparkle updates the app binary (`.app` bundle). The FluidAudio Parakeet-TDT CoreML model files (~2.7 GB) are downloaded separately by `AsrModels.downloadAndLoad(version: .v3)` on first run and cached in the user's local directory. Model weights and app binaries have completely different update cycles. Wrong tool.

**Why no FluidAudio-native version API (verified):** Inspection of `ModelRegistry.swift` at commit `ea50062` confirms that FluidAudio's registry layer exposes only URL construction helpers (HuggingFace download paths). There is no `checkForModelUpdate()` method, no local version manifest, and no cached commit hash tracking. `AsrModels.downloadAndLoad` resolves to `{baseURL}/{repoPath}/resolve/main/{filePath}` -- it always pulls from `main` but does not do a lightweight version-check before potentially re-downloading.

**Recommended mechanism: HuggingFace refs API**

HuggingFace exposes a stable, unauthenticated, lightweight REST endpoint that returns the current commit SHA for any model repo's main branch:

```
GET https://huggingface.co/api/models/FluidInference/parakeet-tdt-0.6b-v3-coreml/refs
```

Live response verified 2026-04-27:
```json
{
  "branches": [
    {
      "name": "main",
      "ref": "refs/heads/main",
      "targetCommit": "775be920d492d20e9e522ee0a969414fd6e6e0f7"
    }
  ]
}
```

The model repo has no explicit version file (the `config.json` is 2 bytes, carries no version). Model artifacts are updated in place on `main`. The `targetCommit` SHA is the definitive signal that content changed -- this is the same approach HuggingFace's own Swift client (`swift-huggingface`) uses for cache invalidation.

**Version check flow:**

1. On app launch AND on a 24-hour repeating Task timer, fetch the refs endpoint via `URLSession.shared.data(from:)`.
2. Decode the JSON with `JSONDecoder` -- trivial struct with `branches: [Branch]`, `Branch` has `name: String` and `targetCommit: String`.
3. Compare `targetCommit` for `name == "main"` against the last-known SHA stored in `UserDefaults` key `fluidAudioModelCommitSHA`.
4. If different (or if the UserDefaults key is absent -- first run), set an `@Observable` flag `modelUpdateAvailable = true` on `TranscriptionEngine` or a new `ModelUpdateChecker` observable.
5. Surface a non-blocking "Speech model update available" banner in the UI. User explicitly taps "Update" to trigger re-download via the existing `AsrModels.downloadAndLoad(version: .v3)` call path.
6. On successful re-download, write the new SHA to `UserDefaults`.

**Why user-initiated, not silent download:** The model is ~2.7 GB. Silent background download on a metered connection is hostile. Show a banner, let the user choose when to download.

**Network access:** The app is not sandboxed, so outbound `URLSession` calls require no entitlement. The existing Notion integration (`NotionService.swift`) already makes outbound HTTP calls in production -- the same `URLSession` pattern applies.

**New code required:** A single `ModelUpdateChecker` actor in `Sources/PSTranscribe/App/` (or `Transcription/`). Roughly 60-80 lines. No new SwiftPM dependency.

**Entitlement impact:** None.

**Integration point:** `ModelUpdateChecker` is initialized in `PSTranscribeApp.swift` alongside `AppUpdaterController`. It publishes `modelUpdateAvailable: Bool` as an `@Observable` property. The UI layer (likely `ControlBar` or a new banner) reacts to this flag.

---

## Full Stack Change Summary

### REQUIRED

| Addition | Type | Priority |
|----------|------|----------|
| `KeyboardShortcuts` 2.4.0 (sindresorhus) | New SwiftPM dependency | REQUIRED |
| `DictationHotkeyController` | New file -- `App/` | REQUIRED |
| `DictationLogger` actor | New file -- `Storage/` | REQUIRED |
| `dictationFolderPath` in `AppSettings` | Code change -- existing file | REQUIRED |
| `ModelUpdateChecker` actor | New file -- `App/` or `Transcription/` | REQUIRED |
| Dictation section in `SettingsView` | Code change -- existing file | REQUIRED |
| `NSPasteboard.general` write call | Code change -- in dictation session coordinator | REQUIRED |

### NOT NEEDED / EXPLICITLY EXCLUDED

| Excluded | Reason |
|----------|--------|
| `NSEvent.addGlobalMonitorForEvents` | Requires Accessibility permission -- user-hostile, blocked by sandbox |
| `CGEventTap` | Requires Input Monitoring entitlement -- same problem |
| `com.apple.security.accessibility` entitlement | Only needed by NSEvent approach; that approach is rejected |
| Security-scoped bookmarks | Sandbox feature only; app is not sandboxed |
| `swift-huggingface` library | A full HuggingFace client; one URLSession call to the refs endpoint is sufficient |
| Sparkle for model updates | Wrong tool; Sparkle updates app binaries, not model weight files |
| CloudKit / iCloud sync | Hard constraint: offline-first, on-device only |
| Any cloud LLM API | Hard constraint: offline-first |
| Replacing or upgrading FluidAudio | Pinned to ea50062; model update channel is separate from FluidAudio version |

---

## Package.swift Change (the only change needed)

```swift
// In dependencies array -- add ONE line:
.package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.4.0"),

// In PSTranscribe target dependencies array -- add ONE line:
.product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
```

All other additions (NSPasteboard, URLSession, NSOpenPanel, UserDefaults) use frameworks already imported in the existing codebase.

---

## Entitlements

No changes to `PSTranscribe.entitlements`. The current file (`audio-input` + `screen-capture`, no `app-sandbox`) is sufficient for all three v1.2 features:

| Capability | Entitlement needed? | Reason |
|------------|-------------------|--------|
| `RegisterEventHotKey` (via KeyboardShortcuts) | No | Carbon API, no permission gate |
| `NSPasteboard.general` write | No | Non-sandboxed, writes are unrestricted |
| NSOpenPanel + raw path file write | No | Non-sandboxed, user-selected path |
| URLSession to HuggingFace refs API | No | Non-sandboxed, outbound network unrestricted |

---

## Version Compatibility

| Technology | macOS Target | Notes |
|-----------|-------------|-------|
| KeyboardShortcuts 2.4.0 | macOS 10.15+ | Well within macOS 26 target |
| Carbon `RegisterEventHotKey` | All macOS | Deprecated but stable; Apple has not shipped a replacement |
| macOS 15+ modifier restriction | macOS 15+ | Option-only shortcuts disabled; use Cmd+Shift+D as default |
| `NSPasteboard` write (no prompt) | macOS 26 | Write path confirmed unaffected by new clipboard privacy rules |
| HuggingFace refs API | n/a | Live-verified 2026-04-27; unauthenticated; stable pattern |

---

## Sources

- https://github.com/sindresorhus/KeyboardShortcuts -- README + Package.swift inspected; v2.4.0 confirmed; Mac App Store + sandbox compatible; no Accessibility required -- HIGH confidence
- https://developer.apple.com/forums/thread/735223 -- Apple Developer Forum: `RegisterEventHotKey` is the correct approach for sandboxed global shortcuts -- HIGH confidence
- https://github.com/feedback-assistant/reports/issues/552 -- macOS 15 Option/Option+Shift modifier restriction for `RegisterEventHotKey` -- HIGH confidence (corroborated by Apple forum thread 763878)
- https://github.com/blackboardsh/electrobun/issues/334 -- NSEvent vs RegisterEventHotKey Accessibility requirement analysis -- MEDIUM confidence (community, consistent with Apple docs)
- https://mjtsai.com/blog/2025/05/12/pasteboard-privacy-preview-in-macos-15-4/ -- Clipboard privacy changes affect READs only, not writes -- MEDIUM confidence (developer blog, corroborated by MacRumors/9to5Mac reports)
- https://huggingface.co/api/models/FluidInference/parakeet-tdt-0.6b-v3-coreml/refs -- Live API response verified 2026-04-27; `targetCommit` SHA present and current -- HIGH confidence
- https://github.com/FluidInference/FluidAudio `Sources/FluidAudio/ModelRegistry.swift` (at commit ea50062) -- No native version-check API; URL construction only -- HIGH confidence (direct source inspection)
- https://github.com/FluidInference/FluidAudio -- Current FluidAudio release: v0.14.1 (April 2026); AsrModels supports `.v2` and `.v3` enum cases -- HIGH confidence
- https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v3-coreml/tree/main -- Repo file listing; 68 commits; no version manifest file; `config.json` is 2 bytes -- HIGH confidence

---

*Stack research for: PS Transcribe v1.2 -- Standalone Dictation + Model Auto-Update*
*Researched: 2026-04-27*
