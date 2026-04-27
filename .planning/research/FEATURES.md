# Feature Research

**Domain:** macOS quick-capture dictation + separate model update channel
**Researched:** 2026-04-27
**Confidence:** HIGH for hotkey/clipboard patterns (verified across 6+ shipping apps); MEDIUM for plain-folder output (few apps do this explicitly); MEDIUM for model update channel (macMLX sidecar pattern is current best reference, FluidAudio API verified)

> **Scope note:** This file covers only the three net-new v1.2 capabilities: (1) keyboard-triggered clipboard dictation, (2) plain-folder dictation output, (3) ASR model auto-update. Existing PS Transcribe features (dual-stream capture, FluidAudio ASR pipeline, session library, Notion export, Sparkle updates) are already shipped and are dependencies -- not subjects -- of this research.

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist in a dictation-to-clipboard tool. Missing = product feels broken or unfinished.

#### Feature Group: Keyboard-Triggered Clipboard Dictation

| Feature | Why Expected | Complexity | Dependencies |
|---------|--------------|------------|--------------|
| Single global hotkey activates dictation from any app | Every competitor (SuperWhisper, Wispr Flow, Axii, Voxt, MacWhisper Global) uses this pattern as the primary entry point. Users will look for it immediately. | S | Existing: CGEventTap / `MASShortcut` / `KeyboardShortcuts` for global hotkey registration. New: the dictation session type. |
| Both toggle AND press-and-hold modes supported | SuperWhisper, Voxt, and Wispr Flow all ship both. Toggle suits typing-style dictation (hands free between words). Hold suits burst dictation (quick phrase, release). Single-mode apps get user complaints. | S | Hotkey subsystem; same underlying recording start/stop. |
| Minimal visual indicator that recording is active | Users need to know the hotkey worked. The orange macOS mic dot alone is insufficient -- users file bugs assuming the app didn't respond. Menu bar icon change (pulsing / color change) is the minimum bar. | S | Menu bar extra (already present in PS Transcribe) |
| Live transcription visible during dictation | All leading apps (SuperWhisper mini window, Voxt floating overlay, Wispr Flow inline preview) show the partial transcript as you speak. Absence feels like the app is "black boxing" the audio. | M | Existing: FluidAudio streaming ASR already emits partial results. New: floating HUD window to display them in any app context. |
| Final text placed on clipboard on stop | The named feature. Users expect to hit hotkey, speak, stop, then Cmd+V. Must be reliable -- if the paste fails silently once, users abandon the feature. | S | `NSPasteboard.general.setString()` -- trivial. |
| Previous clipboard content restored after paste | Wispr Flow and SuperWhisper both do this. SuperWhisper added it in v1.19.0 after user demand. Without it, the dictation trashes whatever the user had copied. Configurable delay (SuperWhisper uses 3 seconds). | S | Save clipboard before recording, restore after paste completes. |
| Transcript saved to session library | PS Transcribe already has a session library. Users expect dictation sessions to appear there alongside full recordings. Absence creates the perception that dictation sessions are "lost." | S | Existing: session persistence pipeline. New: dictation session type distinct from meeting recordings. |
| Escape or second hotkey tap cancels without output | Standard cancel behavior. SuperWhisper's cancel policy: under 30 seconds cancels immediately; over 30 seconds shows a confirmation prompt to prevent accidental cancel. | S | Session abort path; no clipboard write on cancel. |

#### Feature Group: Plain-Folder Dictation Output

| Feature | Why Expected | Complexity | Dependencies |
|---------|--------------|------------|--------------|
| User-configurable output folder (any OS folder, not vault-specific) | PS Transcribe currently requires an Obsidian vault path. Users without Obsidian have no folder-based output. Plain-folder output is the expected analog for non-Obsidian users. | S | Existing: configurable path logic. New: a second path type that omits Obsidian frontmatter. |
| Transcripts written as clean markdown (no YAML frontmatter) | Frontmatter (`---` blocks) is Obsidian-specific. Dropping into a plain folder -- iCloud Drive, Dropbox, a Logseq directory, a local `notes/` folder -- means the file will be read by editors that don't understand YAML. Plain markdown is the universal format. | S | Existing: markdown writer. New: a no-frontmatter rendering path. |
| Filename follows a predictable, human-readable convention | `YYYY-MM-DD HH-mm dictation.md` or similar. Users dropping files into a plain folder will organize them by date in Finder. Opaque UUIDs break this expectation. | S | Existing: date-based naming logic. |
| Folder path persisted across app restarts | Users configure it once and expect it to stick. | S | Existing: UserDefaults / Settings model. |

#### Feature Group: ASR Model Auto-Update

| Feature | Why Expected | Complexity | Dependencies |
|---------|--------------|------------|--------------|
| App checks for a newer ASR model without shipping a new app binary | Ollama and macMLX establish this as the expected pattern for local-AI apps: the model can update independently of the app. Users who care about ASR quality will expect this once they know newer models exist. | M | FluidAudio API (`AsrModels.downloadAndLoad(version:)` fetches from HuggingFace); new: version manifest or HF commit SHA comparison. |
| Check is silent and non-blocking | Background check on launch (or periodically). No modal dialogs, no blocking UI. macMLX throttles to once per 24h. Ollama's macOS client checks on its own schedule and shows "Restart to update" in the menu bar. | S | URLSession background task or async Task at launch. |
| Update available surfaced as a non-intrusive badge or indicator | macMLX uses an orange "Update available" badge on the Models tab. Sparkle uses a sheet. The right pattern here is a subtle badge in Settings > Model rather than an interruptive alert. | S | Settings view; badge on the model row. |
| User explicitly initiates the download (not auto-installed silently) | Models are large (hundreds of MB). Silent auto-installation of a large binary is a bad experience -- disk space, time, unexpected network traffic. SuperWhisper and macMLX both make model downloads user-initiated. | S | Download confirmation UI. |
| Download progress shown with cancellation | Users expect a progress indicator for large downloads. The existing model onboarding (Phase 4, v1.0) already implements this -- reuse that component. | S | Existing: model download progress UI from v1.0 Phase 4. |
| Downloaded model version persisted so check is not repeated unnecessarily | The macMLX sidecar approach: record the HuggingFace commit SHA of the installed model in a local metadata file or UserDefaults. Compare against the current HEAD SHA from the HF API. No SHA change = skip download. | S | HF API: `GET https://huggingface.co/api/models/FluidInference/parakeet-tdt-0.6b-v3-coreml` returns `sha` field. |

---

### Differentiators (Competitive Advantage)

Where PS Transcribe can stand out given its on-device privacy posture and existing FluidAudio pipeline.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| On-device dictation with zero cloud dependency | Wispr Flow is cloud-only. SuperWhisper supports cloud models and defaults to them in some contexts. PS Transcribe can market global-hotkey dictation as "Cmd+V, private" -- the audio never leaves the Mac. This is a genuine differentiator for the privacy-aware user. | S (already true -- just surface it) | Existing FluidAudio pipeline does the work. Marketing position, not implementation work. |
| Dictation transcript always saved (clipboard + library) | Most lightweight dictation apps (Axii, Voxt, basic mode) are fire-and-forget: the text goes to clipboard, the audio is gone. PS Transcribe's session library means every dictation session is recoverable -- you can re-read what you said even if you pasted into the wrong field or closed the window. | S | Existing session library. New: dictation session type. |
| Streaming live transcription in floating HUD (on-device, no latency spike) | Cloud-based apps introduce 500--2000ms latency before words appear. FluidAudio's streaming ASR gives near-real-time partial results on-device. A floating HUD showing live words is viscerally faster than cloud alternatives. | M | Existing streaming ASR. New: always-on-top floating window during dictation. |
| Plain-folder output makes PS Transcribe vault-agnostic | No other on-device dictation app in this space explicitly supports "save to a plain folder with no vault required." This positions PS Transcribe for users who prefer Logseq, Obsidian Sync alternative folders, Bear (via file imports), or just a dated notes folder. | S | New path type alongside existing vault paths. |
| Model update separate from app update (no app-store delay) | Sparkle distributes the app binary. Model updates follow HuggingFace, which moves independently. Users get improved ASR accuracy without waiting for an app release. Transparent versioning (shows installed vs available version) builds trust. | M | New version-check + download flow. Reuses existing download UI. |
| Configurable hold vs toggle per user preference | Power users have strong opinions. SuperWhisper ships both. PS Transcribe matching this gives users control without complexity -- one preference toggle in Settings. | S | Hotkey subsystem change only. |

---

### Anti-Features (Explicitly Out of Scope)

| Anti-Feature | Why It Gets Requested | Why It's Out of Scope | What to Do Instead |
|--------------|----------------------|----------------------|-------------------|
| Cloud ASR fallback for dictation ("use OpenAI Whisper API when on-device is slow") | Wispr Flow offers this. Some users expect it. | Violates the core privacy proposition. Adds API key management, network dependency, cost. | Document clearly: "On-device, always. No cloud." |
| LLM cleanup / reformatting of dictated text | SuperWhisper's "AI modes" post-process dictated text via LLM. Wispr Flow does the same. Users may request it. | LLM analysis is explicitly out of scope (removed in 2026-04-04 scope reduction, archived at `archive/llm-analysis-attempt`). Re-adding it here would reopen the can. | Raw transcript only. Clipboard text is unmodified. Users can pipe it through their own LLM tool. |
| Auto-paste directly into the focused field (bypassing clipboard) | Wispr Flow's default behavior is to type the text directly into the focused field using accessibility APIs, bypassing clipboard. Some users prefer this. | Accessibility API usage requires broader permissions and is fragile across apps (password fields, sandboxed apps, remote desktops all break it). Clipboard-only is simpler, more reliable, and privacy-safe. | Clipboard-only. Document: "Text goes to clipboard; paste with Cmd+V." |
| Dictation history search | MacWhisper has full-text search across transcripts. | Out of scope for v1.2. Session library already shows dictation sessions. Full-text search is a future milestone feature. | Session library covers basic history. |
| Watch folder (drop audio file, auto-transcribe) | MacWhisper's watch folder auto-transcribes files. Some users want batch processing. | Different use case (file transcription vs live dictation). Adds complexity without serving the dictation-to-clipboard use case. | Not planned. |
| Telemetry / usage analytics | Often requested by developers to understand usage patterns. | Project's hard constraint: no telemetry. | None. |
| Silent background model installation | Would reduce friction for model updates. | Large binary, unknown disk space, unexpected network usage. Violates user trust for privacy-aware users. | User-initiated download with explicit progress. |
| Model rollback UI | Advanced users might want to pin an older ASR version. | Low demand, high complexity. The version-check channel serves the majority case (stay current). | Pin by not tapping "Update." Document that the prior model remains until the user updates. |

---

## Feature Dependencies

```
Keyboard Dictation (new session type)
    └──reuses──> FluidAudio streaming ASR pipeline (existing)
    └──reuses──> Session library + persistence (existing)
    └──reuses──> Model onboarding / download UI (existing, Phase 4 v1.0)
    └──requires──> Global hotkey registration (new)
    └──requires──> Floating HUD window for live preview (new)
    └──requires──> Clipboard write on stop (new, trivial)
    └──requires──> Clipboard restore after paste (new, trivial)

Plain-Folder Output (new path type)
    └──reuses──> Markdown writer (existing, minus frontmatter)
    └──reuses──> Configurable path logic in Settings (existing)
    └──enhances──> Keyboard Dictation (dictation sessions land in the folder)
    └──independent of──> Obsidian vault path (runs alongside it, not replacing it)

ASR Model Auto-Update (new channel)
    └──reuses──> Model download progress UI (existing, Phase 4 v1.0)
    └──reuses──> FluidAudio AsrModels.downloadAndLoad(version:) (existing)
    └──requires──> HuggingFace API version check (new: fetch commit SHA)
    └──requires──> Installed version record (new: UserDefaults or sidecar file)
    └──independent of──> Sparkle app update channel (runs alongside it)
    └──independent of──> Keyboard dictation feature (separate concern)
```

### Dependency Notes

- **Keyboard dictation reuses the full FluidAudio streaming pipeline.** The dictation session is structurally identical to a meeting recording -- it starts the ASR engine, receives partial results, and stops on hotkey release or second tap. The only new code is: hotkey registration, the floating HUD window, and the clipboard write at stop. No new ASR work required.
- **Plain-folder output is a rendering variant, not a new pipeline.** The markdown writer already produces the content. A new output mode strips frontmatter and uses a date-based filename instead of the vault path convention. One new `SettingsPath` enum case and a conditional in the transcript writer.
- **Model auto-update is independent of the dictation features.** It can be implemented in any order. It shares no code with dictation flow. The shared dependency is the existing model download UI component.
- **If no model update channel is implemented, dictation still works.** The user stays on their current ASR model. The update channel is a quality-of-life improvement, not a prerequisite.

---

## Behavior Patterns -- Named Specifics

These are the exact behavior choices that need to be made during implementation. Research-backed recommendations included.

### Hotkey Interaction Model

**Recommendation: Ship both toggle and hold; default to toggle.**

- **Toggle:** Press once to start, press again (or Escape) to stop. Best for longer dictation -- hands free while speaking. Used by: macOS built-in dictation, MacWhisper Global, most SuperWhisper modes.
- **Hold (push-to-talk):** Hold key while speaking, release to stop. Best for short bursts -- more intentional. Used by: Voxt (default fn combo), Wispr Flow (optional), SuperWhisper (optional per mode).
- Default to toggle. Power users who prefer hold can switch in Settings. One boolean preference: "Dictation hotkey mode: Toggle / Hold."

### Visual Indicator During Dictation

**Recommendation: Menu bar icon change + small floating HUD. No blocking window.**

- **Menu bar icon:** Change to a pulsing mic (or colored state) when dictation is active. This is visible from any app context and matches macOS conventions (orange dot for mic).
- **Floating HUD:** A small, always-on-top panel showing the live transcript partial. Dismisses on stop. Voxt and SuperWhisper both ship this; users strongly prefer seeing words appear vs. silence. Position it at the bottom-center of the screen (SuperWhisper's default; configurable later).
- Do NOT use a modal window or sheet. The dictation target is whatever the user was already working in.

### Output Behavior on Stop

**Recommendation: Clipboard-only, with automatic clipboard restore.**

- On stop: copy final transcript text to `NSPasteboard.general`. Do not auto-paste (no `NSEvent.postEvent` / accessibility simulation).
- Save clipboard content immediately before writing transcript. Restore it after a brief delay (3 seconds, matching SuperWhisper's proven default). Make delay configurable.
- No direct-inject via accessibility API. This breaks in password fields, sandboxed apps, and remote desktops. The clipboard-only model is universally compatible.

### Cancel Behavior

**Recommendation: Escape cancels without clipboard write. Hold-mode: releasing key under 1 second is treated as cancel.**

- Escape key always cancels cleanly regardless of mode.
- SuperWhisper's 30-second confirmation threshold for cancel is a good pattern -- adopt it: under 30 seconds of recorded audio, Escape cancels silently; over 30 seconds, show a brief confirmation ("Cancel recording? Your text won't be copied.").
- In hold mode: an accidental tap (< 1 second hold) should cancel rather than transcribe noise.

### Plain-Folder Filename Convention

**Recommendation: `YYYY-MM-DD HH-mm Dictation.md`**

- Example: `2026-04-27 14-32 Dictation.md`
- Colons are invalid in macOS filenames -- use hyphens for time.
- "Dictation" suffix distinguishes from full meeting recordings if the folder is shared with other outputs.
- No UUID, no hex hash -- files must be human-readable in Finder.

### Model Version Check Mechanism

**Recommendation: HuggingFace API commit SHA comparison, sidecar file for installed version, 24-hour throttle.**

- On launch (or once per 24 hours): fetch `https://huggingface.co/api/models/FluidInference/parakeet-tdt-0.6b-v3-coreml` -- the `sha` field is the current HEAD commit.
- Compare against stored SHA in UserDefaults (set at download time).
- If different: show an "Update available" badge in Settings > Model. No alert, no notification.
- User taps "Update" -- reuses existing model download progress UI.
- After successful download: update stored SHA.
- Throttle: record last-check timestamp in UserDefaults. Skip check if last check was under 24 hours ago.
- If HF API is unreachable (user offline): fail silently. No error shown.

---

## Feature Prioritization Matrix (v1.2 scope only)

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Global hotkey registration | HIGH | S | P1 |
| Clipboard write on stop | HIGH | S | P1 |
| Menu bar indicator during dictation | HIGH | S | P1 |
| Floating HUD with live transcript | HIGH | M | P1 |
| Toggle vs hold mode setting | MEDIUM | S | P1 |
| Clipboard restore after paste | HIGH | S | P1 |
| Dictation sessions in session library | MEDIUM | S | P1 |
| Cancel / Escape behavior | HIGH | S | P1 |
| Plain-folder path configuration | HIGH | S | P1 |
| Clean markdown output (no frontmatter) | HIGH | S | P1 |
| Date-based filename for plain-folder output | MEDIUM | S | P1 |
| HF commit SHA version check | MEDIUM | M | P2 |
| "Update available" badge in Settings | MEDIUM | S | P2 |
| Model download on user confirmation | MEDIUM | S | P2 -- reuses existing UI |
| Installed version SHA persistence | MEDIUM | S | P2 |
| 24-hour check throttle | LOW | S | P2 |

**Priority key:**
- P1: Required for the dictation feature to be credible at launch
- P2: Required for model auto-update to work; can follow dictation in a later phase

---

## Competitor Feature Analysis

| Feature | SuperWhisper | Wispr Flow | MacWhisper Global | Axii / Voxt | PS Transcribe v1.2 plan |
|---------|-------------|------------|-------------------|-------------|------------------------|
| Global hotkey | Yes (configurable) | Yes (fn / Ctrl+Opt default) | Yes (configurable) | Yes (Ctrl+Shift+Space / fn combo) | Yes (configurable, default TBD) |
| Toggle mode | Yes | Yes (tap twice for hands-free) | Yes | Yes (tap mode) | Yes (default) |
| Hold/push-to-talk mode | Yes | Yes (hold mode) | Not documented | Yes (long-press default in Voxt) | Yes (preference) |
| Live transcript HUD | Yes (mini window) | No (inline in focused field) | No (overlay shows after stop) | Yes (floating overlay in Voxt) | Yes (floating HUD) |
| Clipboard output | Yes (auto-copy option) | Via temp clipboard (then restores) | Yes (auto copy toggle) | Yes (also direct paste) | Yes (primary) |
| Direct-inject (accessibility) | Yes | Yes (default) | No | Yes (default in Axii) | No (clipboard only) |
| Clipboard restore | Yes (3s default, configurable) | Yes | Not documented | Not documented | Yes |
| Transcript saved to library | Yes (recordings stored in Documents/superwhisper/) | No | Yes | No | Yes (session library) |
| Privacy (on-device) | Optional (supports cloud models) | No (cloud-only) | Yes | Yes | Yes (always) |
| Plain-folder output | Configurable storage location | No | Watch folder (input, not output) | No | Yes (clean markdown) |
| Model updates separate from app | No (app bundles model) | N/A (cloud) | No (app bundles model) | No | Yes (HF version check) |

---

## Sources

- [SuperWhisper keyboard shortcuts docs](https://superwhisper.com/docs/get-started/settings-shortcuts)
- [SuperWhisper changelog -- clipboard restore, mini window, per-mode shortcuts](https://superwhisper.com/changelog)
- [Wispr Flow -- starting your first dictation](https://docs.wisprflow.ai/articles/6409258247-starting-your-first-dictation)
- [Wispr Flow -- fix text not pasting after dictation](https://docs.wisprflow.ai/articles/7971211038-fix-text-not-pasting-after-dictation)
- [MacWhisper dictation feature docs](https://macwhisper.helpscoutdocs.com/article/14-how-to-use-the-dictation-feature)
- [MacWhisper Global mode docs](https://macwhisper.helpscoutdocs.com/article/16-global)
- [Axii GitHub -- menu bar voice-to-text, Parakeet, no cloud](https://github.com/bwarzecha/Axii)
- [Voxt GitHub -- long-press and tap modes, floating overlay](https://github.com/hehehai/voxt)
- [Choosing the Right AI Dictation App -- output behavior comparison](https://afadingthought.substack.com/p/best-ai-dictation-tools-for-mac)
- [macMLX -- HF model-update detection via .macmlx-meta.json sidecar, orange badge, 24h throttle](https://macmlx.app/)
- [macMLX GitHub](https://github.com/magicnight/mac-mlx)
- [FluidAudio GitHub -- AsrModels.downloadAndLoad, ModelRegistry.baseURL](https://github.com/FluidInference/FluidAudio)
- [FluidInference/parakeet-tdt-0.6b-v3-coreml on HuggingFace](https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v3-coreml)
- [swift-huggingface -- URLSession download progress, modelRefs(), commit SHA](https://github.com/huggingface/swift-huggingface)
- [MacWhisper watch folder docs](https://macwhisper.helpscoutdocs.com/article/35-automatically-transcribing-files-in-watch-folders)
- [Ollama model update mechanism -- pull vs app update](https://insiderllm.com/guides/update-models-ollama/)

---
*Feature research for: PS Transcribe v1.2 -- keyboard-triggered clipboard dictation, plain-folder output, ASR model auto-update*
*Researched: 2026-04-27*
