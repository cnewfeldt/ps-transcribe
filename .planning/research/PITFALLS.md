# Pitfalls Research

**Domain:** macOS on-device dictation app -- adding global hotkey dictation, plain-folder output, and independent ASR model update channel to an existing Swift 6.2 / SwiftUI / actor-based transcription app
**Researched:** 2026-04-27
**Confidence:** HIGH (per-pitfall confidence noted inline)

---

## Critical Pitfalls

### Pitfall 1: CGEventTap Silently Disabled After Re-Sign or Dock Launch

**What goes wrong:**
The event tap is created without error, `tapIsEnabled()` returns true, but keyboard callbacks never fire. This happens when TCC (Transparency, Consent, and Control) invalidates a prior Input Monitoring grant because the app binary's code identity changed -- from a re-sign, a build number bump, or launching via Finder/Dock rather than the CLI. The tap appears healthy; it is not.

**Why it happens:**
TCC decisions are keyed to code identity, not just bundle ID. After any re-sign or when Launch Services performs identity checks, a previously-granted Input Monitoring permission may require re-evaluation. The CGEventTap API reports success regardless -- there is no error returned when the tap is installed but silently suppressed by TCC.

**How to avoid:**
- Call `CGPreflightListenEventAccess()` before creating the tap; if it returns false, prompt the user before attempting tap creation.
- Use `listenOnly` tap option (`kCGEventTapOptionListenOnly`) to request Input Monitoring (not Accessibility) -- the permission is less invasive, works in non-sandboxed apps distributed outside the App Store, and is the correct permission for a hotkey trigger that only reads events.
- Add a health-check timer (fire every 5 seconds) that calls `CGEventTapIsEnabled()` and calls `CGEventTapEnable(tap, true)` to re-enable the tap if it has been silently disabled. Also handle the `kCGEventTapDisabledByTimeout` pseudo-event in the callback to re-enable immediately without waiting for the timer.
- Log a warning to the console whenever a re-enable is triggered so the developer can observe stability during QA.

**Warning signs:**
- Hotkey registered, no callbacks, no error in console
- Works when launched from Terminal, fails when launched from Dock or via `open`
- Works on first launch after granting permission, stops after app update

**Phase to address:**
Hotkey dictation phase -- the health-check loop and permission preflight must be part of the initial implementation, not a follow-up.
**Confidence:** HIGH (confirmed by documented CGEventTap behavior and developer post-mortem from 2026-02)

---

### Pitfall 2: Wrong Permission Requested -- Accessibility vs. Input Monitoring

**What goes wrong:**
Using a `defaultTap` (active tap, can suppress or modify events) rather than a `listenOnly` tap triggers the Accessibility permission dialog instead of Input Monitoring. Accessibility is a far more invasive permission -- it allows the app to control the computer. Users are more reluctant to grant it, system policies (MDM, corporate lockdown) block it, and it is harder to pass an App Store review. For a dictation app that only needs to detect a hotkey, this is a trust and distribution red flag.

**Why it happens:**
Copying example code that uses `defaultTap` because the developer wants to "handle" the event (suppress it so the key combo does not reach other apps). But the correct pattern is to detect the hotkey with a `listenOnly` tap and then begin recording -- not to suppress the event.

**How to avoid:**
Use `kCGEventTapOptionListenOnly` exclusively. Accept that the hotkey will also pass through to whatever app is frontmost (this is usually fine -- a dedicated hotkey like `Cmd+Shift+D` rarely conflicts and the dictation overlay context makes the pass-through harmless). If suppression is truly required, document why and request Accessibility permission with a clear usage description in `NSAccessibilityUsageDescription`.

**Warning signs:**
- System presents "PS Transcribe wants to control this computer" dialog (Accessibility) instead of "wants to monitor keyboard input" dialog (Input Monitoring)
- App works for developer (who granted Accessibility) but fails for users on managed machines
- GitHub Releases download drops sharply after launch (users deny the Accessibility prompt)

**Phase to address:**
Hotkey dictation phase -- permission type decision must be locked in at architecture level.
**Confidence:** HIGH (CGEventTap documentation; Apple Developer Forum thread 122492)

---

### Pitfall 3: Hotkey Conflicts with System-Reserved and Competing-App Shortcuts

**What goes wrong:**
The chosen hotkey silently fires in both PS Transcribe and another app simultaneously. Worse, some combinations are reserved at the system level (macOS Dictation is `Fn Fn` or double-`Fn`; Spotlight is `Cmd+Space`; Screenshot tools use `Cmd+Shift+3/4/5`) and will be consumed before the event tap sees them. The user's chosen shortcut may already be claimed by 1Password, Raycast, or another dictation tool running in the background.

**Why it happens:**
Global hotkeys are first-come, first-served at the CGEventTap layer. There is no conflict detection API. Developers pick a shortcut that works in their environment and never test with a realistic user's installed-app ecosystem.

**How to avoid:**
- Make the hotkey user-configurable with a keyboard shortcut recorder in Settings. Never ship a hardcoded default that the user cannot change.
- Default to a three-modifier combination that avoids common conflicts: `Cmd+Shift+Option+D` is distinctive enough to rarely collide.
- At Settings save time, validate the shortcut against a known list of system-reserved keys (F-keys used by macOS Dictation, media keys, Spotlight).
- Display a non-blocking warning ("This shortcut may conflict with other apps") but allow the user to keep it -- the app cannot resolve conflicts in other processes.
- Do not suppress the event (`listenOnly` tap, see Pitfall 2) -- if two apps both use `listenOnly`, both receive the event without breaking each other.

**Warning signs:**
- Hotkey fires recording but also triggers 1Password autofill
- Hotkey does nothing on the developer's machine but works elsewhere (Raycast consuming it silently)
- macOS Dictation activates simultaneously with PS Transcribe dictation

**Phase to address:**
Hotkey dictation phase -- configurable shortcut recorder and validation required from day one.
**Confidence:** MEDIUM (WebSearch; Apple forums; no official API for conflict detection)

---

### Pitfall 4: CGEventTap Callback Blocked by Audio Session Startup Latency

**What goes wrong:**
The hotkey callback is on a low-latency event tap thread. If the callback directly calls into the ASR actor or starts an AVAudioSession, it blocks the event tap thread. macOS monitors the event tap callback latency and will disable the tap with `kCGEventTapDisabledByTimeout` if the callback takes too long. In the worst case, the tap disables itself on the first keypress -- the user presses the hotkey and nothing happens.

**Why it happens:**
The callback is wired directly to `RecordingActor.startRecording()`, which may block on FluidAudio model readiness, AVAudioEngine startup, or actor isolation queue contention. Each of those can take tens to hundreds of milliseconds.

**How to avoid:**
- Keep the event tap callback as thin as possible: set a flag or post a notification to the main actor. The callback should never call into the ASR pipeline directly.
- Pattern: `Task { @MainActor in await recordingActor.startDictation() }` dispatched from a minimal callback function that immediately returns.
- The re-enable health check from Pitfall 1 also catches this: if the callback times out, the health check loop re-enables the tap within 5 seconds.

**Warning signs:**
- Hotkey works on first press after launch but stops working mid-session
- Console shows `CGEventTapCreate: kCGEventTapDisabledByTimeout` in logs
- Adding a `Thread.sleep` in the callback immediately reproduces the issue

**Phase to address:**
Hotkey dictation phase -- architectural constraint must be specified in the task's acceptance criteria.
**Confidence:** HIGH (documented CGEventTap timeout behavior; confirmed by multiple open-source hotkey libraries)

---

### Pitfall 5: NSPasteboard Write Pollutes Clipboard History with Transcriptions

**What goes wrong:**
Every dictation result is written to the system clipboard and therefore captured by all clipboard history managers (Alfred, Pasta, Clipboard Manager, etc.). Users who dictate sensitive content -- medical notes, legal text, personal communications -- may be surprised to find that content persisted in their clipboard history indefinitely. This directly contradicts PS Transcribe's privacy-first positioning.

**Why it happens:**
`NSPasteboard.general.setString()` writes with no metadata markers. Clipboard history managers capture every change count increment.

**How to avoid:**
- Write the transcription text to the pasteboard alongside the `org.nspasteboard.TransientType` marker. This signals to compliant clipboard history managers (Alfred, Pasta, Maccy, Clipboard Manager) that the item should not be recorded.
- Optionally also set `org.nspasteboard.AutoGeneratedType` to indicate the user did not initiate a manual Copy action.
- This is an additive, non-breaking change: apps that don't check these markers simply ignore them; apps that do respect them exclude the item.

Implementation:
```swift
let pasteboard = NSPasteboard.general
pasteboard.clearContents()
pasteboard.setString(transcriptionText, forType: .string)
// Suppress capture by clipboard history managers
pasteboard.setData(Data(), forType: NSPasteboard.PasteboardType("org.nspasteboard.TransientType"))
pasteboard.setData(Data(), forType: NSPasteboard.PasteboardType("org.nspasteboard.AutoGeneratedType"))
```

**Warning signs:**
- QA step: open Alfred clipboard history immediately after a dictation; if the transcription appears there, the markers are not set
- User feedback: "my clipboard history is full of dictation output"

**Phase to address:**
Hotkey dictation phase -- must be in the initial NSPasteboard write implementation.
**Confidence:** HIGH (nspasteboard.org specification; confirmed by Alfred, Maccy, and Yoink source code behavior)

---

### Pitfall 6: NSPasteboard Change-Count Race on Fast Dictations

**What goes wrong:**
The app records a change count before writing, then checks it to confirm the write succeeded. If another app (another dictation tool, a text expander) writes to the clipboard in the same window, the app either: (a) overwrites the other app's content silently, or (b) reads back the wrong change count and falsely believes its write was overwritten. For the user, the result is the dictation text never reaches their target field even though the HUD dismissed normally.

**Why it happens:**
`NSPasteboard.changeCount` is a global system counter. A read-then-write sequence is not atomic. Under load (multiple background apps touching the clipboard), the count between read and write can shift.

**How to avoid:**
- Do not treat the change count as a guard. Write directly and trust that `clearContents()` + `setString()` is a best-effort atomic pair (it is, within a single app's write -- it is not cross-process atomic).
- Show the HUD briefly after write, then dismiss. Do not try to verify that your write "survived" by re-reading the pasteboard -- this creates a secondary read that itself changes the UX.
- If telemetry were allowed, you could track change-count discrepancy. Since this app has no telemetry, log it to `os_log` at debug level for developer QA only.

**Warning signs:**
- Dictation text does not appear when user pastes immediately after HUD dismisses
- Issue only reproducible with Espanso or another text expander running in the background

**Phase to address:**
Hotkey dictation phase.
**Confidence:** MEDIUM (NSPasteboard behavior is well-documented; race condition is real but low-frequency in practice)

---

### Pitfall 7: macOS Pasteboard Privacy Alert Friction (macOS 26+)

**What goes wrong:**
macOS 26 (Tahoe) introduced per-app pasteboard access controls. While the initial rollout has the alert disabled by default (developer preview flag required), Apple has signaled intent to ship this broadly. If PS Transcribe *reads* the pasteboard at launch or speculatively (e.g., checking what is already there before writing), it will trigger a user-visible permission dialog asking whether the app can access clipboard content -- which is confusing for a dictation tool that should only be *writing* to the clipboard.

**Why it happens:**
An eager implementation reads the pasteboard to detect context (e.g., "what was the user working on before triggering dictation?") or reads it speculatively to implement undo. Any `NSPasteboard.general.string(forType:)` call that is not a direct response to a Paste keyboard shortcut triggers the new alert.

**How to avoid:**
- Never read from `NSPasteboard.general` in the dictation flow. Write only.
- If undo-last-dictation is ever added, implement it by storing the transcript in the app's own state, not by reading back from the clipboard.
- Use the new `detect` API (iOS/macOS 26 SDK) for type-checking without triggering access alerts when investigating pasteboard content becomes necessary.

**Warning signs:**
- macOS displays "PS Transcribe wants to access your clipboard" during dictation session -- the app should never cause this dialog
- Enabling the developer preview flag `com.apple.NSPasteboard.PrivacyPreview` in defaults and seeing an alert during normal dictation workflow

**Phase to address:**
Hotkey dictation phase -- pasteboard writes only, no reads, enforced as an architectural constraint.
**Confidence:** MEDIUM (macOS 15.4 developer preview confirmed; macOS 26 status as of research date is "disabled by default but signaled as future")

---

### Pitfall 8: Security-Scoped Bookmark Not Persisted for Plain-Folder Output

**What goes wrong:**
The user selects a plain folder (e.g., `~/Documents/Dictation`) via `NSOpenPanel`. The transcript writes succeed -- but only until the app is relaunched. On next launch, the bookmark data is gone (stored only in memory, never written to UserDefaults or a persisted store), the app loses access to the folder, and writes silently fail or fall back to a default location with no error surfaced.

**Why it happens:**
`NSOpenPanel` returns a URL that works for the current app session. Developers test write/read in the same launch and conclude it works. The security-scoped bookmark that would survive across launches is an additional step that is easy to skip.

**How to avoid:**
- When the user selects a folder, immediately call `url.bookmarkData(options: .withSecurityScope, ...)` and store the resulting `Data` in `UserDefaults` (or another persistent store).
- On app launch, restore the bookmark via `URL(resolvingBookmarkData:options:.withSecurityScope:...)` before any write attempt. Call `url.startAccessingSecurityScopedResource()` before writing and `url.stopAccessingSecurityScopedResource()` after.
- If the bookmark is stale (returns `isStale == true`), prompt the user to re-select the folder via `NSOpenPanel`.

**Warning signs:**
- Transcripts are written correctly on first launch after folder selection
- After relaunch, transcripts silently go to the wrong location or a write-error is swallowed

**Phase to address:**
Plain-folder output phase -- bookmark persistence must be the first thing implemented, not a follow-up.
**Confidence:** HIGH (Apple documentation; common bug in macOS sandboxed and non-sandboxed apps)

---

### Pitfall 9: File-Naming Collision in High-Frequency Dictation

**What goes wrong:**
Two rapid dictation sessions (e.g., user triggers hotkey twice in 5 seconds, or app is backgrounded and resumes mid-session) generate filenames based on date/time at second granularity: `2026-04-27-10-30-45.md`. Both sessions produce the same filename and one silently overwrites the other. The earlier transcript is lost.

**Why it happens:**
The existing app uses date-based naming because meeting sessions are far apart. Dictation sessions can be seconds apart. The naming scheme from the meeting flow is reused without adapting for higher frequency.

**How to avoid:**
- For dictation output files, append a millisecond component or a UUID suffix: `2026-04-27-103045-ABC123.md`.
- Alternatively, use `FileManager.default.fileExists(atPath:)` before writing and append `-2`, `-3`, etc. if the name is taken.
- Atomic write using `Data.write(to:options:.atomic)` ensures the write is not partial even if the name is unique -- partial writes from a crash are worse than collisions.

**Warning signs:**
- QA step: trigger 5 dictation sessions in rapid succession; verify 5 separate files exist in the output folder
- Users reporting "some dictations are missing"

**Phase to address:**
Plain-folder output phase.
**Confidence:** HIGH (deterministic based on date-based naming + high-frequency usage pattern)

---

### Pitfall 10: Plain-Folder Output Writes Obsidian Frontmatter by Mistake

**What goes wrong:**
The existing transcript serialization path writes YAML frontmatter (Obsidian-style: `---\ntags: ...\ncreated: ...\n---`). When the plain-folder path reuses the same serializer, every dictation output has Obsidian frontmatter even though the user explicitly chose plain folder to avoid Obsidian. In plain text editors, this looks like garbled output at the top of every file.

**Why it happens:**
The serializer is shared between vault (Obsidian) and plain-folder outputs as a convenience. The Obsidian-specific frontmatter is not behind a flag.

**How to avoid:**
- Extract a `TranscriptFormat` enum: `.obsidian` (with frontmatter), `.plain` (markdown only, no frontmatter). The serializer checks this flag.
- The dictation hotkey flow always uses `.plain`. Vault sessions use `.obsidian`.
- Verify in QA that a dictation session output in plain folder contains no `---` YAML block.

**Warning signs:**
- Dictation output opens in Bear/Drafts/iA Writer with a block of YAML metadata at the top
- User reports "the file starts with `---` and some code"

**Phase to address:**
Plain-folder output phase -- format branching must be explicit in the serializer from the start.
**Confidence:** HIGH (direct consequence of existing codebase architecture where all outputs go through the same serializer)

---

### Pitfall 11: Model File Partially Downloaded Leaves App in Broken State

**What goes wrong:**
The model update channel downloads a new model weights file. The download is interrupted midway (network drop, battery low, user quits app). On next launch, the app finds a partially-written file at the model path, attempts to load it into FluidAudio, and either crashes or produces garbage transcription results. The user does not know the model is corrupt -- transcription "runs" but accuracy is zero.

**Why it happens:**
The download writes directly to the model's final path rather than to a staging location. There is no integrity check before swapping the new file into use.

**How to avoid:**
- Download to a staging file: `model.mlmodelc.download` in the app's temp container.
- After download completes, verify integrity: at minimum, check file size against the declared size from the manifest; ideally verify a SHA-256 checksum provided in the model manifest JSON.
- Only rename/move to the production model path if the checksum passes. This atomic rename (`FileManager.moveItem`) is the swap.
- If the app launches and finds a staging file but no completed checksum record, delete the staging file and flag model as needing re-download.

**Warning signs:**
- FluidAudio throws on model load after an interrupted update
- App produces no transcription output with no error surfaced to user
- A file exists at the model path but is smaller than expected

**Phase to address:**
Model auto-update phase -- download-to-staging and checksum verification must be designed before writing any download code.
**Confidence:** HIGH (standard software update hygiene; high risk for large binary model files)

---

### Pitfall 12: New Model Version Breaks ASR API Compatibility with Current FluidAudio Pinned Commit

**What goes wrong:**
The model auto-update channel downloads a new Parakeet-TDT weights file. The new model requires a different CoreML model structure (new input tensor shapes, new output head format, different file naming convention) that is only supported by a newer FluidAudio version. The app is pinned to commit `ea50062` and does not update FluidAudio as part of model update. Result: FluidAudio fails to load the new model silently or crashes.

**Why it happens:**
FluidAudio has already demonstrated this pattern -- v0.13.7 required version-specific filenames (`Decoderv2.mlmodelc`, `Jointerv2.mlmodelc`) and v0.13.2.5 reorganized the ASR directory structure by model family. Model files and the Swift SDK are co-versioned but the app treats them as independent.

**How to avoid:**
- The model manifest JSON (served from GitHub Releases or a separate manifest endpoint) must include a `minimum_fluid_audio_commit` or `minimum_fluid_audio_version` field.
- The model auto-updater checks this field against the bundled FluidAudio version before downloading. If the required FluidAudio version exceeds what is bundled, the update is deferred until the app itself is updated via Sparkle.
- Version the model manifest strictly: the manifest for model version X must only list weights files compatible with the FluidAudio commit currently bundled in the app.

**Warning signs:**
- Model updates silently download but ASR quality drops to zero after restart
- FluidAudio logs show model load errors referencing unknown tensor names or missing files
- App works on developer machine (newer FluidAudio) but fails on user machines (pinned commit)

**Phase to address:**
Model auto-update phase -- compatibility contract between model version and FluidAudio version must be designed before the first model manifest is published.
**Confidence:** HIGH (directly observed in FluidAudio release history; v0.13.7 and v0.13.2.5 both had breaking model structure changes)

---

### Pitfall 13: Model Update Starts During an Active Transcription Session

**What goes wrong:**
The model auto-updater detects a new version and begins downloading/swapping in the background while a meeting recording or dictation session is active. The swap renames the model file at the path FluidAudio holds open. Depending on how CoreML handles in-flight model references, this causes a crash, a silent failure, or the remainder of the session transcribes with the old (or new, partially loaded) model.

**Why it happens:**
The update checker is a background task and has no knowledge of whether ASR is active. Downloads complete at unpredictable times.

**How to avoid:**
- The model updater must check `RecordingActor.isRecording` before initiating the swap step. The download can proceed in the background, but the atomic rename to the production path must be deferred until no session is active.
- Implement a `updatePending: Bool` flag: when a download completes and a session is active, set the flag and perform the swap on the next session stop.
- Add a brief user-visible notice after the session ends: "Model updated. New accuracy improvements active."

**Warning signs:**
- App crash during long recording sessions that coincide with background downloads
- Transcription quality changes mid-session (different model loaded)
- FluidAudio throws on inference after a model file move

**Phase to address:**
Model auto-update phase -- the swap must be gated on recording state from the start.
**Confidence:** HIGH (CoreML model files held open by the framework are not safe to rename; this is a known issue with hot-swapping CoreML models)

---

### Pitfall 14: Model Update Exhausts Disk Space Without Warning

**What goes wrong:**
The Parakeet-TDT model is ~600 MB--2 GB depending on variant. The model auto-updater downloads a new version alongside the current one (both on disk simultaneously during the staging process), temporarily doubling the required disk space. On machines with limited free space, this fails mid-download or causes macOS to start aggressively purging caches. The staging file is left behind, the old model is intact, but the app may report a generic error or no error at all.

**Why it happens:**
The download is treated as a background operation with no disk-space preflight.

**How to avoid:**
- Before starting a model download, check `FileManager.default.volumeAvailableCapacityForImportantUsage` against `manifest.modelSizeBytes * 2` (headroom for staging + production copies simultaneously).
- If insufficient space, defer the download and show a non-modal notification: "Model update available. Free up X GB to install."
- After a successful swap, immediately delete the staging file to recover the space.

**Warning signs:**
- Download starts, progress reaches ~50%, then fails with a file I/O error
- `/tmp` or the app container grows to unexpected size
- User reports "my disk is full after a PS Transcribe update"

**Phase to address:**
Model auto-update phase.
**Confidence:** HIGH (model size is large enough for this to be a real-world failure mode)

---

### Pitfall 15: Model Update Introduces Telemetry or Network Calls via New FluidAudio Code

**What goes wrong:**
A future FluidAudio update (if the app ever unpins its commit as part of a model update) includes new telemetry, network calls, or cloud fallback logic in the Swift SDK. Since FluidAudio is a third-party dependency, these changes arrive silently. PS Transcribe's privacy guarantee -- "all processing on-device, no network calls during transcription" -- is violated without any change to the app's own code.

**Why it happens:**
The FluidAudio commit is pinned (`ea50062`), which prevents this now. But if the model auto-update path ever updates the FluidAudio Swift package version alongside the model weights, new SDK behaviors are pulled in.

**How to avoid:**
- Strictly separate model weights updates (CoreML `.mlmodelc` files downloaded from GitHub Releases) from FluidAudio SDK updates (Swift package, requires app binary update + Sparkle).
- Never update the FluidAudio Swift package outside of a Sparkle app release. Model weights are data; the SDK is code.
- Before unpinning a FluidAudio commit, audit the diff for any new `URLSession`, `Network.framework`, or analytics calls.
- Add a network monitoring test to CI: launch the app, run a short transcription, assert that no outbound network connections were made to non-GitHub-Releases hosts.

**Warning signs:**
- Introducing FluidAudio SDK version bump alongside a model download
- Any new `import Network` or `URLSession` usage appearing in FluidAudio diff
- CI network test detects unexpected outbound connection during transcription

**Phase to address:**
Model auto-update phase (design constraint) / ongoing for FluidAudio SDK upgrades.
**Confidence:** MEDIUM (risk is speculative but high-impact given privacy positioning; FluidAudio is actively developed)

---

### Pitfall 16: Dictation Hotkey Flow Forks the Recording State Machine Instead of Reusing It

**What goes wrong:**
The hotkey dictation path creates its own parallel recording and ASR pipeline -- a second `AVAudioEngine`, a second FluidAudio inference instance, or a second set of `@Observable` state variables -- to avoid coupling with the existing session flow. This doubles the surface area for bugs: audio device conflicts, conflicting CoreML resource usage, two separate error paths, and a state machine that can get into impossible combinations (e.g., meeting recording active + dictation recording active simultaneously, which is undefined behavior for `AVAudioEngine`).

**Why it happens:**
The developer wants dictation to "feel fast" and thinks isolating it from the existing session infrastructure avoids regressions. The isolation is real but the cost is a fork that must be maintained in parallel.

**How to avoid:**
- Reuse the existing `RecordingActor` with a `sessionType` parameter: `.meeting`, `.voiceMemo`, `.dictation`. The dictation type skips diarization, disables system audio capture, and routes output to clipboard + plain folder instead of vault.
- Enforce mutual exclusion: `RecordingActor.isRecording` must be checked before starting a dictation session. If a meeting session is active, the hotkey is a no-op (or shows a brief HUD: "Recording already in progress").
- The existing recording state machine already handles start/stop/error transitions correctly. Reuse it.

**Warning signs:**
- Two `AVAudioEngine.start()` calls can exist simultaneously in the app
- The session library shows dictation items and meeting items with separate state management code
- A crash in dictation does not trigger the existing crash recovery path

**Phase to address:**
Hotkey dictation phase -- architecture decision must be made before any dictation code is written.
**Confidence:** HIGH (`AVAudioEngine` does not support two simultaneous instances on the same device; this is a definite crash path)

---

### Pitfall 17: Privacy Mode Does Not Cover the Dictation HUD

**What goes wrong:**
PS Transcribe has an existing privacy mode that hides the main window from screen share (via `sharingType = .none`). The new dictation HUD (floating `NSPanel`) is a new window that is not covered by the existing privacy mode logic. When screen sharing is active and the user triggers dictation, the HUD appears on the shared screen, revealing that the user is dictating -- and potentially showing the live transcription text as it appears in the HUD.

**Why it happens:**
Privacy mode was implemented on the main `NSWindow`. New windows created later do not inherit the setting.

**How to avoid:**
- Apply `sharingType = .none` to the dictation HUD `NSPanel` at creation time.
- Note the macOS limitation: `sharingType = .none` only protects against legacy `CGWindowListCreateImage()` capture. ScreenCaptureKit (used by Zoom, Teams, OBS, QuickTime) captures the final composited display and ignores `sharingType`. This is a known, unfixable limitation of the macOS API as of macOS 15.4. Document this limitation explicitly in the HUD's privacy behavior.
- For users who care about HUD privacy, recommend enabling the system-level "System Private Window Picker" (macOS Sequoia+) to exclude specific windows from screen sharing.

**Warning signs:**
- QA step: enable screen sharing in Zoom, trigger dictation, verify the HUD is not visible in the shared view (tests legacy path)
- Separate QA: use QuickTime screen recording, trigger dictation, check the recording -- expect HUD is visible (documents the ScreenCaptureKit limitation)

**Phase to address:**
Hotkey dictation phase -- `sharingType` must be set on the HUD panel at creation, alongside the existing privacy mode application.
**Confidence:** HIGH (NSWindowSharingType behavior is well-documented; ScreenCaptureKit bypass is confirmed in Apple Developer Forums thread 792152)

---

### Pitfall 18: Settings Bloat -- Three Separate Output Destination Configurations Confuse Users

**What goes wrong:**
v1.2 adds a plain-folder path alongside the existing meetings vault path and voice memos vault path. The Settings screen now has three folder pickers. For a dictation tool, the question "where does this dictation go?" becomes unanswerable at a glance. Users who just want quick clipboard dictation still see and must navigate three path configurations.

**Why it happens:**
Each new feature adds its own settings row without reviewing the overall settings coherence. The meeting vault and voice memo vault were added in v1.0 before dictation existed.

**How to avoid:**
- Separate dictation settings from meeting session settings visually. Dictation settings (hotkey, output destination, clipboard toggle) should form their own section.
- The plain-folder output should default to `~/Documents/PS Transcribe Dictations/` without requiring user configuration. Make the folder picker an override, not a required first-launch step.
- Conduct a Settings audit before shipping v1.2: count the total number of settings and trim anything that can be a sensible default.

**Warning signs:**
- Settings screen has more than 2 folder path pickers visible at once without section separation
- New users report being unsure which path controls dictation output during QA

**Phase to address:**
Plain-folder output phase (settings design) -- the UX audit should happen before the feature is considered "done."
**Confidence:** MEDIUM (judgment call on UX; confirmed risk pattern in productivity apps)

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hardcode default hotkey instead of making it configurable | Faster initial implementation | Conflicts with 1Password, Raycast, or other tools; no way to resolve without a Settings rebuild | Never -- hotkey must be configurable from day one |
| Skip NSPasteboard transient/auto-generated markers | Simpler write call | Every dictation pollutes user's clipboard history; privacy regression | Never |
| Write model download directly to production path | Avoids staging logic | Partial download leaves app broken; no rollback possible | Never |
| Reuse Obsidian serializer for plain-folder output | No new code | Every plain-folder file has YAML frontmatter visible in plain text editors | Never |
| Skip disk-space preflight before model download | Simpler download code | Silent failure on full-disk machines; staging file left behind | Never |
| Allow model swap while recording is active | Simpler update scheduler | Possible crash or quality change mid-session | Never |
| Store security-scoped bookmark only in memory | No UserDefaults boilerplate | Plain-folder access fails after relaunch | Never |
| Fork recording state machine for dictation | Faster iteration on dictation flow | Two audio engines conflict; crash recovery does not cover dictation path | Never |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| CGEventTap + existing RecordingActor | Calling `startRecording()` synchronously inside the tap callback | Post a notification or `Task { @MainActor in ... }` from the callback; never block the tap thread |
| NSPasteboard + plain-folder output | Writing to clipboard and then immediately writing to file in the same synchronous call | Clipboard write first (user is waiting to paste); file write can be async |
| FluidAudio model path + model updater | Passing the live model path to FluidAudio while the updater has a rename in flight | Gate the rename on `RecordingActor.isRecording == false`; hold a lock or use `updatePending` flag |
| Sparkle (app) + model updater (custom) | Using Sparkle's feed for model updates by embedding model weights in the DMG | Sparkle updates the app binary; model weights are separate data downloads; mixing them couples model release cadence to app release cadence |
| Security-scoped bookmark + iCloud Drive folder | Bookmarks to iCloud Drive folders may resolve differently after eviction | Test with both local and iCloud-backed folder selections; handle `isStale == true` on restore |
| Privacy mode (`sharingType`) + HUD panel | Applying privacy mode to `NSApp.mainWindow` only | Apply to every `NSWindow` and `NSPanel` the app creates; audit at window creation time |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Loading FluidAudio model on hotkey press | First dictation after app cold-start takes 5-30 seconds with no feedback | Pre-warm the model in the background on app launch; show loading state in HUD if model is not ready | Every cold-start |
| Clipboard write blocking main thread | HUD appears frozen for 200-500ms after dictation ends | `NSPasteboard` writes are synchronous but fast; the delay is more likely FluidAudio finalization -- profile before optimizing | Any dictation session |
| Model download on metered connection without user consent | Users on cellular hotspot get surprise large downloads | Respect `NWPathMonitor` status; warn and require user confirmation before downloading on non-WiFi | Any time model update triggers on cellular |
| File I/O for plain-folder output on slow NAS or network volume | Write appears to hang; HUD does not dismiss | Perform file writes off the main actor; show HUD dismissal immediately, write in background with silent retry on failure | Network volumes, slow USB drives |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| No signature verification on model manifest or model weights download | Attacker serves malicious CoreML model via MITM or GitHub compromise; model executes on Neural Engine with user data | Verify model SHA-256 against a value embedded in the app binary or signed manifest; reject downloads that fail verification |
| Model manifest fetched over HTTP | MITM can replace manifest with attacker-controlled model URL | Enforce HTTPS for all model manifest and download URLs; validate server certificate; reject HTTP |
| Pasteboard write containing raw transcription from a medical/legal dictation | No data sensitivity classification; content in clipboard history of all clipboard managers | Always write with `org.nspasteboard.TransientType` marker (see Pitfall 5); document this behavior in the app's privacy policy |
| Plain-folder path accepts symlink pointing outside intended directory | Path traversal: user or another app manipulates the folder symlink to redirect writes to a sensitive location | Resolve symlinks (`url.resolvingSymlinksInPath()`) and validate the canonical path is within user-writable space before writing |
| Model update channel fetches from a mutable branch URL (`/main/model.json`) | Attacker or accidental push can serve a new manifest with no release review | Pin manifest URL to GitHub Releases artifacts (immutable once released) rather than raw branch content |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No visible recording indicator during hotkey dictation | User cannot tell if dictation started; may speak without recording | Show a persistent HUD with a pulsing indicator immediately on hotkey press, before the audio engine is fully ready |
| HUD dismisses immediately on hotkey release (push-to-talk) vs. requires second press to stop | Friction if the chosen UX is push-to-talk but the user expected toggle | Pick one model (toggle is more natural for dictation) and document it clearly in Settings and onboarding |
| No indication when dictation is written to clipboard | User presses hotkey, speaks, HUD disappears -- now what? | HUD final state: brief "Copied to clipboard" confirmation for 1.5 seconds before dismissing |
| Accidental hotkey trigger while typing (hotkey too simple) | Unwanted recording session interrupts typing flow; garbled dictation in clipboard | Default to a three-modifier hotkey; require deliberate intent; do not start recording on ambiguous partial key combinations |
| Model update completes with no user feedback | User has no idea their ASR model improved | Show a one-time non-modal notification after the first session following a model update: "New ASR model active" |
| End-of-utterance detection cuts off too early | Last word of dictation is missing; user has to re-dictate | Use a generous silence timeout (1.5-2 seconds) rather than the minimum; allow user to adjust in Settings |
| Dictation session appears in the session library with no name | Library shows an unnamed entry for every clipboard dictation | Auto-generate a session name from the first N words of the transcription; filter very short dictations (< 5 words) from the library or show them in a separate "Quick Dictations" section |

---

## "Looks Done But Isn't" Checklist

- [ ] **Hotkey tap health check:** Trigger hotkey 20 times over 5 minutes; verify the tap never silently disables -- check with a `tapIsEnabled()` assertion in debug builds
- [ ] **Input Monitoring (not Accessibility):** Launch app fresh, trigger hotkey -- verify System Settings > Privacy > Input Monitoring (not Accessibility) is where the permission appears
- [ ] **Clipboard history exclusion:** Open Alfred/Pasta/Maccy, run a dictation session, verify the transcription does not appear in clipboard history
- [ ] **Pasteboard -- no reads:** Instrument `NSPasteboard.general` in a debug build; assert no reads from the dictation flow (only writes)
- [ ] **Security-scoped bookmark survives relaunch:** Select plain-folder destination, quit app, relaunch, run a dictation -- verify file appears in the same folder without re-prompting
- [ ] **File naming -- no collisions:** Trigger 10 rapid dictations with short utterances; verify 10 separate files in the plain-folder output
- [ ] **Plain-folder -- no frontmatter:** Open a dictation output file in a plain text editor; verify no `---` YAML block at the top
- [ ] **Model download staging:** Interrupt a model download mid-flight (kill process or network); relaunch; verify staging file is cleaned up and download restarts cleanly
- [ ] **Checksum verification:** Corrupt the staging model file; verify the app rejects it and does not swap it into production
- [ ] **No model swap during recording:** Start a meeting session; simultaneously trigger model update (manual trigger in debug); verify no crash and swap is deferred until session ends
- [ ] **Disk space preflight:** Set disk nearly full in a test; trigger model update; verify informative message is shown rather than a silent I/O failure
- [ ] **Privacy mode HUD:** Enable screen sharing (QuickTime); trigger dictation; document (in test notes) that HUD is visible in the recording (expected, ScreenCaptureKit limitation) -- verify it is at least not captured by legacy `CGWindowListCreateImage`
- [ ] **Mutual exclusion -- no double recording:** Start a meeting session; press dictation hotkey; verify hotkey is a no-op or shows a dismissible HUD explaining recording is already active

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| CGEventTap silently disabled | LOW (runtime) | Health check loop re-enables within 5 seconds; no user action required |
| Corrupt model file after interrupted download | MEDIUM | Delete staging file, re-trigger download; user loses one download cycle |
| Model incompatible with bundled FluidAudio | HIGH | Must ship a Sparkle app update with new FluidAudio commit; model channel must be locked until app update ships |
| Security-scoped bookmark stale after system event | LOW | Prompt user to re-select folder via NSOpenPanel; bookmark is re-created |
| Plain-folder file collision overwrites earlier dictation | HIGH -- data loss | No recovery once overwritten with atomic write; prevention (UUID suffix) is the only option |
| Model swap happened during active recording | HIGH -- crash or quality regression | Crash recovery path restores session if RecordingActor crash recovery is in place; model rollback requires keeping the prior model version on disk |
| Telemetry leak via new FluidAudio SDK code | HIGH -- privacy violation | Requires immediate Sparkle app update pinning back to last known clean FluidAudio commit |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| CGEventTap silently disabled | Hotkey dictation phase | Run 20-press stress test with health check logging enabled |
| Wrong permission (Accessibility vs. Input Monitoring) | Hotkey dictation phase | Fresh install permission dialog shows Input Monitoring |
| Hotkey conflict with system / other apps | Hotkey dictation phase | Configurable shortcut recorder ships with the feature |
| Tap callback blocks event thread | Hotkey dictation phase | No `kCGEventTapDisabledByTimeout` in console after 20 presses |
| Clipboard history pollution | Hotkey dictation phase | Alfred/Maccy clipboard history empty after dictation QA |
| Pasteboard change-count race | Hotkey dictation phase | Stress test with Espanso running concurrently |
| macOS 26 pasteboard read alert | Hotkey dictation phase | No pasteboard reads from dictation code path; confirmed by instrumentation |
| Security-scoped bookmark not persisted | Plain-folder output phase | Relaunch test after folder selection |
| File-naming collision | Plain-folder output phase | 10 rapid dictations produce 10 distinct files |
| Obsidian frontmatter in plain-folder output | Plain-folder output phase | Plain text editor inspection of output file |
| Partial model download corrupts app state | Model auto-update phase | Interrupted download test; staging file cleanup verification |
| New model incompatible with bundled FluidAudio | Model auto-update phase | Manifest compatibility check unit test; compatibility field in manifest |
| Model swap during active recording | Model auto-update phase | Concurrent session + update test; verify swap is deferred |
| Disk space exhaustion during model download | Model auto-update phase | Nearly-full disk test produces informative message |
| Telemetry leak via FluidAudio SDK update | Model auto-update phase (ongoing) | Network monitoring CI assertion on each FluidAudio pin change |
| Recording state machine forked for dictation | Hotkey dictation phase (architecture) | Code review: single RecordingActor with sessionType parameter |
| HUD not covered by privacy mode | Hotkey dictation phase | screen-share QA step on HUD panel |
| Settings bloat | Plain-folder output phase (settings UX audit) | Settings screen review before merge |

---

## Sources

- CGEventTap silent disable after re-sign: https://danielraffel.me/til/2026/02/19/cgevent-taps-and-code-signing-the-silent-disable-race/ -- HIGH confidence
- CGEventTap Input Monitoring vs. Accessibility: Apple Developer Forums thread 122492, thread 789896 -- HIGH confidence
- CGEventTap timeout / disabled by latency: Apple CoreGraphics documentation; multiple open-source hotkey libraries -- HIGH confidence
- NSPasteboard transient/concealed types: http://nspasteboard.org/ -- HIGH confidence
- macOS 26 pasteboard privacy preview: https://mjtsai.com/blog/2025/05/12/pasteboard-privacy-preview-in-macos-15-4/ -- MEDIUM confidence (feature disabled by default as of research date)
- Security-scoped bookmarks: Apple documentation https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox -- HIGH confidence
- FluidAudio breaking changes: https://github.com/FluidInference/FluidAudio/releases (v0.13.7, v0.13.2.5) -- HIGH confidence
- NSWindowSharingType limitations with ScreenCaptureKit: Apple Developer Forums thread 792152 -- HIGH confidence
- FluidAudio CoreML model structure (v2 vs. v3): https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v3-coreml -- MEDIUM confidence
- Global hotkey conflict patterns: GitHub issue block/goose#6488; 1Password community forum -- MEDIUM confidence

---
*Pitfalls research for: PS Transcribe v1.2 -- hotkey dictation, plain-folder output, model auto-update channel*
*Researched: 2026-04-27*
