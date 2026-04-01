# Feature Research

**Domain:** macOS local transcription app with on-device LLM integration
**Researched:** 2026-03-31
**Confidence:** MEDIUM -- competitor feature details from public sources; some LLM UX patterns from direct product inspection, others from reviews

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Session history / recording library | Every recorder app has "past recordings" -- absence feels like data loss | MEDIUM | MacWhisper has "Recordings tab", Granola has searchable history, Meetily has "Previous Meetings" dashboard. Grid or list both acceptable. |
| Persistent session naming | Users need to identify what a recording was about -- date-only filenames feel raw and unfinished | LOW | Most apps auto-name from calendar event title, meeting title, or date. Manual rename at any time is the floor expectation. |
| Clear recording state indicator | Users must know if the app is recording, stopped, or broken -- ambiguity causes double-starts and silent failures | LOW | Granola shows a live recording dot. macOS orange indicator dot is confusing as sole signal. A dedicated in-app state indicator is required. |
| Transcript output in readable format | A wall of text with no structure is unusable -- markdown or structured notes is the baseline | LOW | Already implemented (markdown + YAML frontmatter). |
| File export / open-in-finder | Users need to get their files out -- if there's no path to the file, the app feels like a black box | LOW | Obsidian vault path support partially covers this. A "show in Finder" or open-file action is expected. |
| Graceful error messaging | Silent failures -- permission denied, model not loaded, device unavailable -- destroy trust. Users expect to know why something failed. | LOW | macOS mic permission silent failures are well-documented as a UX gap competitors fall into. |
| Model download with progress | On-device AI apps require model downloads. Users expect a visible, cancellable progress indicator -- not a spinner with no feedback. | LOW | WhisperKit docs recommend this explicitly. MacWhisper and OpenWhispr both implement it. |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Live LLM analysis panel (summary, action items, key topics) | Most local recorders analyze post-session. Live analysis during recording is the frontier -- Otter does it but via cloud. Doing it fully offline is a genuine differentiator. | HIGH | Meetily implements this with Ollama (section summary, key decisions, action items). Pensieve connects to local Ollama post-session. Live-during-recording is rare offline. Requires Ollama integration + chunked analysis on transcript deltas. |
| Obsidian deep link integration | High overlap between power-user note-takers (Obsidian) and people who care about local AI and privacy. A direct obsidian:// link from the session library is a retention hook for this audience. | LOW | Obsidian URL format: `obsidian://open?vault=...&file=...`. No competitor in the local-first space explicitly targets this workflow. |
| Dual-stream capture (mic + system audio) | Most local Mac apps only capture one stream. System audio capture is blocked in many screen recorders without separate virtual device setup. Already implemented -- but should be surfaced explicitly. | HIGH (already built) | Competitors like Granola and MacWhisper record only system audio or only mic, not both independently diarized. |
| Three-state recording button with error surface | The market default is a binary button (record / stop) with errors swallowed silently. A clearly distinguished error state (red, icon change) that tells the user exactly what's wrong is rare and appreciated. | LOW | macOS recording apps frequently cited for "silent failure" UX problems -- orange dot disappears, recording was never happening, no feedback. |
| Ollama model browser with in-app download | Ollama integration usually requires CLI setup. A model browser inside the app that shows available models, sizes, and lets you pull from within the UI lowers the technical barrier significantly. | MEDIUM | No local macOS transcription app currently ships this. Meetily assumes Ollama is pre-installed and configured separately. |
| Missing-file detection in session library | As sessions accumulate and vault paths change, broken links create silent gaps. Showing "file missing" vs "recording available" in the library prevents confusion and supports recovery. | LOW | Not implemented in any competitor reviewed. Standard file management discipline but rare in this category. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Cloud backup / sync | "I don't want to lose my recordings" | Violates offline-first philosophy. Introduces privacy risk. Adds cloud infra cost and complexity. The target user chose this app to avoid cloud. | Educate on local backup strategies. Let the vault path be a cloud-synced folder (iCloud, Dropbox) -- user controls that, not the app. |
| Calendar integration / auto-start on meeting | "Granola does it -- why not you?" | Requires calendar permissions (privacy surface). Requires background process. Complexity outweighs value when users intentionally start recordings. Scope creep that delays real differentiators. | Let users name sessions after the fact using date-based fallback with optional rename. |
| Multi-language simultaneous transcription | Power users ask for it | ASR model (Parakeet-TDT) is English-optimized. Supporting multiple languages requires model switching or multiple concurrent models, which multiplies memory/CPU requirements. Already explicitly out of scope. | Single locale per session. Document this clearly. |
| Real-time waveform visualizer | "Shows the app is listening" | Cosmetically satisfying but computationally expensive and adds UI complexity. Being replaced by three-state button intentionally. | Three-state button (idle/recording/error) provides the same "app is active" signal more clearly. |
| Cloud LLM APIs (OpenAI, Anthropic) | "GPT-4 is better than local models" | Defeats the entire offline-first privacy proposition. Adds API key management complexity. Creates ongoing cost for users. | Ollama only. Document the tradeoff. |
| Team sharing / collaboration features | "Granola has Spaces now" | Single-user app. Adding sharing requires auth, backend, access control -- a product pivot, not a feature. | Focus on local export formats (markdown, Obsidian) that users can share via their own channels. |
| Video recording alongside audio | "I want full meeting capture" | Out of scope. Audio + transcript is the product. Video adds file size, storage, and capture complexity with no benefit to the transcription/LLM pipeline. | Audio only. The transcript IS the record. |

## Feature Dependencies

```
Session Library (grid view)
    └──requires──> Session Lifecycle Management (stop -> save -> index)
                       └──requires──> File persistence with stable paths

Recording Naming
    └──enhances──> Session Library (named entries are more navigable)
    └──can occur at──> any lifecycle stage (before/during/after)

Obsidian Deep Links
    └──requires──> Session Library (needs indexed sessions with file paths)
    └──requires──> Known vault path (already configurable)

Missing-File Detection
    └──requires──> Session Library (needs indexed file paths to check)

Ollama LLM Integration (detect/configure)
    └──required by──> Live LLM Analysis Panel
    └──required by──> Ollama Model Browser

Live LLM Analysis Panel
    └──requires──> Ollama Integration
    └──requires──> Transcript stream available during recording
    └──enhances──> Session Library (analysis stored alongside transcript)

Model Onboarding (ASR model download)
    └──independent of──> Ollama (separate concern: ASR model vs LLM model)
    └──required by──> Any transcription feature

Three-State Mic Button
    └──replaces──> Waveform visualizer (UI swap, no new dependencies)
    └──requires──> Error state propagation from TranscriptionEngine

Crash Recovery
    └──requires──> Session Lifecycle Management (temp file preservation)
    └──enhances──> Session Library (can surface recovered sessions)
```

### Dependency Notes

- **Session Library requires Session Lifecycle Management:** The library can only index sessions reliably if the stop-clear-save lifecycle is deterministic. The current "overwrite in place" pattern must be resolved first.
- **Live LLM Analysis Panel requires Ollama Integration:** Ollama detection/configuration must be shipped before the analysis panel can be wired up. These are distinct sub-features even within the same milestone.
- **Recording Naming can occur at any lifecycle stage:** Before (pre-name before starting), during (rename while recording), after (rename before/after save). The date-based fallback handles the case where users skip naming entirely.
- **Missing-file detection requires file paths in the library index:** The library must store the file path at save time. Detection is then a stat() check at display time -- cheap but dependent on having the path.

## MVP Definition

This is a milestone addition to an existing v1.2.1 shipped product. "MVP" here means minimum viable milestone -- what makes the new features ship-worthy.

### Ship With (this milestone)

- [ ] Session library with grid view and file paths -- without this, session naming and Obsidian links have nowhere to surface
- [ ] Proper session lifecycle (stop -> save, no silent overwrite) -- prerequisite for reliable library
- [ ] Recording naming (before/during/after, date-based fallback) -- naming is the session library's UX anchor
- [ ] Three-state mic button (idle/recording/error) -- replaces waveform, surfaces the error state that currently swallows failures
- [ ] ASR model onboarding (download prompt on first launch, progress, success/fail) -- new installs are broken without this
- [ ] Missing-file detection in library -- very low cost, high trust value
- [ ] Obsidian deep links from library -- low complexity, high value for target users
- [ ] Security hardening (12 findings from SECURITY-SCAN.md) -- these are pre-launch blockers

### Add After Initial Milestone Shipped

- [ ] Ollama detection/configuration + model browser -- complex enough to be a discrete sub-feature
- [ ] Live LLM analysis panel -- depends on Ollama integration being stable first
- [ ] Crash recovery for incomplete sessions -- important but doesn't block the UX improvements above

### Defer (Later Milestone or Never)

- [ ] Calendar integration -- out of scope, adds complexity, not aligned with use case
- [ ] Cloud sync -- violates offline-first, defer indefinitely
- [ ] Video recording -- permanently out of scope

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Session library (grid view, file paths) | HIGH | MEDIUM | P1 |
| Proper session lifecycle (stop/save) | HIGH | MEDIUM | P1 |
| ASR model onboarding | HIGH | LOW | P1 |
| Three-state mic button | HIGH | LOW | P1 |
| Recording naming (before/during/after) | HIGH | LOW | P1 |
| Missing-file detection | MEDIUM | LOW | P1 |
| Obsidian deep links | MEDIUM | LOW | P1 |
| Security hardening (12 findings) | HIGH | MEDIUM | P1 |
| Ollama detection / configuration | HIGH | MEDIUM | P2 |
| Ollama model browser (in-app) | MEDIUM | MEDIUM | P2 |
| Live LLM analysis panel | HIGH | HIGH | P2 |
| Crash recovery for incomplete sessions | MEDIUM | HIGH | P2 |

**Priority key:**
- P1: Must have for milestone to ship
- P2: Should have, add when P1 is stable
- P3: Nice to have, future consideration

## Competitor Feature Analysis

| Feature | MacWhisper | Granola | Meetily (local) | Our Approach |
|---------|------------|---------|-----------------|--------------|
| Session library | Recordings tab (list) | Searchable history, unlimited on paid | "Previous Meetings" dashboard with timestamps | Grid view with file paths, Obsidian deep links |
| Session naming | Names from configured participant labels | Auto-names from calendar event | Date + duration shown | Optional at any point, date fallback |
| Recording state feedback | Recording control in main window | Live recording dot | Live transcription timestamp indicator | Three-state button: idle / recording / error |
| LLM analysis | None (ASR only) | AI notes post-session (cloud-processed) | Post-session via Ollama (section summary, decisions, action items) | Live-during-recording side panel via Ollama |
| First-launch model setup | Model download in-app | No model setup (cloud) | Assumes Whisper and Ollama pre-installed | Guided download prompt on first launch |
| Offline / local | Yes (fully local) | Partially local (audio on device, analysis via cloud) | Yes (fully local with Ollama) | Yes (fully local -- Parakeet + Ollama) |
| Obsidian integration | Not present | Not present | Not present | Deep links from session library |
| Missing-file detection | Not present | N/A (cloud-managed) | Not present | Flagged in library grid |
| Error state surfacing | Weak (silent failures documented) | Weak (silent permission failures) | Weak | Explicit error state on mic button |
| Dual-stream capture | Single stream | System audio only | Mic only | Both mic + system, separately diarized |

## Sources

- [MacWhisper automatic meetings recording docs](https://macwhisper.helpscoutdocs.com/article/30-record-meetings)
- [MacWhisper GitHub discussion (features overview)](https://github.com/ggml-org/whisper.cpp/discussions/420)
- [Meetily local AI meeting assistant](https://meetily.ai/)
- [Granola AI notes -- free vs paid features](https://www.granola.ai/blog/granola-free-vs-paid-features-each-plan)
- [Granola in-depth review 2026](https://www.bluedothq.com/bluedothq.com/blog/granola-review)
- [Fireflies vs Otter AI comparison 2026](https://thebusinessdive.com/fireflies-ai-vs-otter-ai)
- [Talat: local AI meeting notes (TechCrunch, March 2026)](https://techcrunch.com/2026/03/24/talats-ai-meeting-notes-stay-on-your-machine-not-in-the-cloud/)
- [WhisperKit macOS onboarding patterns](https://www.helrabelo.dev/blog/whisperkit-on-macos-integrating-on-device-ml)
- [Meetily open source local AI meeting assistant](https://dev.to/zackriya/local-meeting-notes-with-whisper-transcription-ollama-summaries-gemma3n-llama-mistral--2i3n)
- [Obsidian external integration / deep links](https://deepwiki.com/obsidianmd/obsidian-help/8-external-integration)
- [Best macOS transcription apps 2026 roundup](https://www.meetjamie.ai/blog/transcription-software-for-mac)
- [7 Best MacWhisper alternatives 2026](https://screenapp.io/alternatives/macwhisper)

---
*Feature research for: macOS local transcription app with on-device LLM (PS Transcribe)*
*Researched: 2026-03-31*
