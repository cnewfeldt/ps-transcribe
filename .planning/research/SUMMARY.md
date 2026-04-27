# Research Summary: PS Transcribe v1.2

**Project:** PS Transcribe v1.2 -- Standalone Dictation + Model Auto-Update
**Domain:** macOS native app -- global-hotkey dictation + independent ASR model update channel
**Researched:** 2026-04-27
**Confidence:** HIGH (hotkey mechanism, clipboard, file I/O); MEDIUM (model manifest hosting strategy, model-FluidAudio compatibility contract)

---

## Executive Summary

v1.2 adds two independent capability clusters to an existing, shipped macOS transcription app: (1) keyboard-triggered clipboard dictation and plain-folder output, and (2) an out-of-band ASR model update channel separate from Sparkle. Both clusters are additive -- they reuse the existing FluidAudio streaming pipeline, session library, and markdown writer, with no changes to the core recording state machine. The critical architectural decision is the global hotkey mechanism: `sindresorhus/KeyboardShortcuts` (wrapping Carbon `RegisterEventHotKey`) is the correct choice because it requires no Accessibility or Input Monitoring permissions, is App Store compatible, and ships a SwiftUI `Recorder` view out of the box. `CGEventTap` and `NSEvent.addGlobalMonitorForEvents` are rejected for v1.2 -- both require user-facing permission grants that create friction on every fresh install.

The model auto-update channel has one unresolved hosting decision: whether to use the HuggingFace refs API (lightweight, no infrastructure) or a project-owned manifest JSON on gh-pages (more control, enables SHA-256 per-file checksums, supports `min_app_version` compatibility gating). The Architecture researcher recommends the project-owned manifest; the Stack researcher validates HuggingFace refs as sufficient for version detection. Resolve this with an ADR before Phase B planning locks -- the manifest approach is safer long-term.

The build is structured as Phase A foundation (~5.5 hours), then Phase B (model update) and Phase C (dictation) in parallel (~9.5 and ~13.5 hours respectively), then Phase D integration and hardening. The main risks are: incomplete staging logic during model download, the model-FluidAudio compatibility contract (a new model version could require a newer FluidAudio SDK than the pinned commit), and NSPasteboard clipboard history pollution (write `org.nspasteboard.TransientType` markers or every dictation session lands in Alfred/Maccy history, contradicting the privacy proposition).

---

## Key Findings

### Stack Additions

The existing stack (Swift 6.2, SwiftUI, FluidAudio ea50062, Sparkle 2.9.0, @Observable / actors) is unchanged. v1.2 requires exactly one new SwiftPM dependency and several new files built on existing system frameworks.

**New dependency:**
- `KeyboardShortcuts` 2.4.0 (sindresorhus) -- global hotkey registration via Carbon `RegisterEventHotKey`. No Accessibility or Input Monitoring permission required. Includes a SwiftUI `Recorder` view for user-configurable shortcuts. App Store compatible. Default recommended shortcut: `Cmd+Shift+D` (avoids macOS 15+ Option-only restriction).

**New code built on existing frameworks (no new SwiftPM dependencies):**
- `DictationHotkeyController` -- KeyboardShortcuts wrapper (mirrors `AppUpdaterController.swift` pattern)
- `DictationLogger` actor -- plain markdown writer without YAML frontmatter (separate actor, not a mode flag on `TranscriptLogger`)
- `ModelUpdateService` actor -- URLSession poll against manifest or HuggingFace refs API; exposes `@Observable` `ModelUpdateState` enum
- `dictationFolderPath`, `installedModelVersion`, `modelLastCheckedDate` keys in `AppSettings`
- Dictation + Model Updates sections in `SettingsView`
- `NSPasteboard.general` write in dictation coordinator (no entitlement; writes are unrestricted in non-sandboxed apps)

**Explicitly excluded:**
- `CGEventTap` and `NSEvent.addGlobalMonitorForEvents` -- both require permission grants; rejected
- Security-scoped bookmarks -- app is not sandboxed; raw URL path access works across launches
- `swift-huggingface` library -- one `URLSession` call to the refs endpoint is sufficient
- Sparkle for model updates -- wrong tool; Sparkle updates app binaries, not model weight files
- Any cloud API or telemetry

**No entitlement changes needed.** Current `PSTranscribe.entitlements` (audio-input + screen-capture, no app-sandbox) is sufficient for all v1.2 capabilities.

### Feature Table Stakes vs Differentiators vs Anti-Features

**Must have (P1 -- dictation is not credible without these):**
- Single global hotkey activates dictation from any app (Cmd+Shift+D default, user-configurable)
- Both toggle and press-and-hold modes; default to toggle
- Menu bar icon change (pulsing) while dictation is active
- Floating HUD showing live partial transcript during dictation
- Final transcript placed on `NSPasteboard.general` on stop, with clipboard history exclusion markers
- Previous clipboard content restored after paste (3-second delay, configurable)
- Transcript saved to session library alongside meeting recordings
- Escape or second hotkey tap cancels without clipboard write (30-second confirmation threshold)
- User-configurable output folder (plain OS folder, not vault-specific)
- Clean markdown output -- no YAML frontmatter
- Date-based filename with millisecond or UUID component: `2026-04-27-103045-ABC123.md`
- `DictationOutputMode` enum: `.clipboard`, `.plainFolder`, `.both`

**Should have (P2 -- model update channel):**
- Version check on launch + 24-hour repeating timer
- "Update available" badge in Settings > Model (no blocking alerts)
- User-initiated download with progress (reuses v1.0 Phase 4 model download UI)
- Installed version record in UserDefaults
- Disk space preflight before download (`volumeAvailableCapacityForImportantUsage` vs `manifest.modelSizeBytes * 2`)

**Competitive differentiators:**
- On-device dictation, zero cloud dependency -- "Cmd+V, private" positioning
- Every dictation session recoverable from session library (fire-and-forget apps discard audio)
- Streaming live transcript in floating HUD -- visibly faster than cloud competitors
- Plain-folder output -- vault-agnostic, supports Logseq/Bear/plain `notes/` workflows
- Model update independent of app release

**Anti-features (out of scope):**
- Cloud ASR fallback -- violates privacy proposition
- LLM cleanup/reformatting of dictated text -- removed 2026-04-04 scope reduction
- Auto-paste via accessibility API -- fragile, requires broader permissions, breaks in sandboxed apps
- Silent background model installation -- large binary, hostile on metered connections
- Telemetry / usage analytics -- hard constraint: none

### Architecture Integration

The integration surface is clean. v1.2 adds three new service-layer actors and one new HUD window. `LibraryStore` is lifted from `ContentView` to `PSTranscribeApp` scope so the dictation path can share it. A new shared `anySessionActive: Bool` flag at app scope provides mutual exclusion between meeting recordings, dictation sessions, and model update applies. The existing `TranscriptionEngine` is not modified for dictation -- `DictationCoordinator` owns a separate mic-only engine instance (Option B from Architecture research, preferred over modifying the existing state machine).

**New components:**
1. `DictationHotkeyController` -- KeyboardShortcuts wrapper; fires `onHotkey` on MainActor
2. `DictationCoordinator` -- orchestrates hotkey press -> engine start -> HUD -> stop -> clipboard write -> library save
3. `DictationWindowController` + `DictationHUD` -- NSPanel (`.nonactivatingPanel`, level `.floating`, joins all spaces, `sharingType = .none`)
4. `ModelUpdateService` -- manifest fetch, version compare, download-to-staging, SHA-256 verify, atomic rename, rollback

**Existing components modified:**
- `PSTranscribeApp.swift` -- lift `LibraryStore`, add `anySessionActive`, instantiate new services
- `AppSettings.swift` -- add dictation + model update keys
- `TranscriptLogger.swift` -- add `startPlainSession` + `finalizePlain` (~40 lines)
- `TranscriptionEngine.swift` -- add `reloadModels()` for post-update hot-swap
- `ContentView.swift` -- accept injected `LibraryStore`; add NotificationCenter listener for library refresh
- `SettingsView.swift` -- add Dictation section and Model Updates section
- `Models.swift` -- add `SessionType.dictation` and `DictationOutputMode` enum

### Critical Pitfalls

18 pitfalls were researched. The CGEventTap pitfalls (1-4) are preserved as **conditional warnings only** -- they apply if hold-to-talk or modifier-only hotkeys are ever required in a future version. The v1.2 KeyboardShortcuts/`RegisterEventHotKey` path avoids all of them by design.

**Active pitfalls for v1.2 (must be addressed in implementation):**

1. **NSPasteboard clipboard history pollution** (Pitfall 5) -- every dictation without `org.nspasteboard.TransientType` marker ends up in Alfred/Maccy/Pasta history, directly contradicting the privacy proposition. Write both `TransientType` and `AutoGeneratedType` markers alongside the text on every clipboard write. Non-breaking additive change. HIGH confidence.

2. **Model file partial download corrupts app state** (Pitfall 11) -- download to staging directory (`<repo>-staging/`), verify SHA-256 per file against manifest checksums, then perform atomic APFS rename into production. If app relaunches with a staging file and no completed checksum record, delete it and re-trigger download. HIGH confidence.

3. **New model version breaks ASR API compatibility with pinned FluidAudio** (Pitfall 12) -- FluidAudio v0.13.7 and v0.13.2.5 both had breaking model structure changes. Model manifest must include `min_app_version` (or `min_fluid_audio_version`). If required SDK version exceeds bundled FluidAudio, defer update until Sparkle ships a new app build. HIGH confidence.

4. **Model swap during active recording session** (Pitfall 13) -- CoreML model files held open by FluidAudio are not safe to rename mid-session. Gate atomic rename on `anySessionActive == false`. Set `updatePending: Bool`; apply on next session stop. HIGH confidence.

5. **Plain-folder file naming collision** (Pitfall 9) -- dictation sessions can be seconds apart; second-granularity timestamps collide. Append millisecond component or UUID suffix. HIGH confidence.

6. **Obsidian frontmatter leaking into plain-folder output** (Pitfall 10) -- existing serializer writes YAML frontmatter unconditionally. Add `TranscriptFormat` enum (`.obsidian` / `.plain`); `DictationLogger` always uses `.plain`. HIGH confidence.

7. **HUD not covered by privacy mode** (Pitfall 17) -- apply `sharingType = .none` to the HUD NSPanel at creation. Note documented limitation: ScreenCaptureKit (Zoom, Teams, OBS) captures the composited display regardless of `sharingType`. This is an unfixable macOS API limitation; document it explicitly.

**Conditional pitfalls (CGEventTap path only -- not applicable with KeyboardShortcuts):**
- CGEventTap silently disabled after re-sign -- irrelevant; `RegisterEventHotKey` does not use TCC
- Wrong permission type (Accessibility vs. Input Monitoring) -- irrelevant; no permission required
- Tap callback blocks event thread causing timeout -- irrelevant; Carbon callback is lightweight

---

## Implications for Roadmap

### Phase A: Foundation

**Rationale:** Shared data model changes and `LibraryStore` lift are required by both Phase B and Phase C. Nothing in B or C can compile cleanly without these.
**Delivers:** No user-visible change. Internal scaffolding.
**Implements:** `SessionType.dictation`, `DictationOutputMode` enum in `Models.swift`; all v1.2 keys in `AppSettings`; `anySessionActive` flag at app scope; `LibraryStore` lifted to `PSTranscribeApp`; `TranscriptLogger.startPlainSession` + `finalizePlain`.
**Avoids:** State machine fragmentation (Pitfall 16), frontmatter leak (Pitfall 10).
**Estimated:** ~5.5 hours.
**Research flag:** Standard Swift patterns. Skip research phase.

### Phase B: Model Auto-Update (parallel with C)

**Rationale:** Fully independent of dictation. Can start immediately after Phase A. Resolve the manifest hosting ADR before writing download code -- the decision gates the checksum approach.
**Delivers:** Settings > Model section with current version, "Check for Updates" button, download progress, and update badge.
**Implements:** `ModelUpdateService` (manifest fetch, version compare, staging download, SHA-256 verify, atomic rename, rollback), `TranscriptionEngine.reloadModels()`, SettingsView model section, OnboardingView model version display.
**Avoids:** Partial download corruption (Pitfall 11), FluidAudio incompatibility (Pitfall 12), swap during active session (Pitfall 13), disk space exhaustion (Pitfall 14).
**Estimated:** ~9.5 hours.
**Research flag:** Manifest hosting strategy needs an ADR before Phase B planning locks. Everything else is standard.

### Phase C: Dictation (parallel with B)

**Rationale:** The headline feature of v1.2. Fully independent of model update. NSPanel HUD and coordinator can be built in parallel once the hotkey controller is wired.
**Delivers:** Global hotkey (`Cmd+Shift+D`) activates dictation from any app. Floating HUD shows live partial transcript. Final text written to clipboard with privacy markers. Optionally written to plain OS folder. Session saved to library.
**Implements:** `DictationHotkeyController` (KeyboardShortcuts), `DictationCoordinator`, `DictationWindowController`, `DictationHUD`, `DictationLogger`, clipboard write with `TransientType` markers, NSOpenPanel plain-folder picker in settings, hotkey recorder in Settings via `KeyboardShortcuts.Recorder`.
**Avoids:** Clipboard history pollution (Pitfall 5), filename collision (Pitfall 9), frontmatter leak (Pitfall 10), HUD privacy mode gap (Pitfall 17), settings bloat (Pitfall 18).
**Estimated:** ~13.5 hours.
**Research flag:** All decisions locked. Skip research phase.

### Phase D: Integration and Hardening

**Rationale:** End-to-end validation of feature interactions: mutual exclusion between recording and model update, model update deferred by active dictation, rollback path, SettingsView UX audit. Required before shipping.
**Delivers:** Verified e2e flows. QA checklist from PITFALLS.md "Looks Done But Isn't" section completed.
**Addresses:** Concurrent session guard, model update rollback simulation, SettingsView three-folder-picker audit (default `~/Documents/PS Transcribe Dictations/` so folder picker is an override not a requirement).
**Research flag:** Standard patterns. Skip research phase.

### Phase Ordering Rationale

- A must precede B and C: shared data model is a compile-time dependency.
- B and C are fully independent: no shared code, different concerns. Parallelize for speed.
- D only starts when B and C are complete: integration testing requires both features to exist.
- If parallelism is not available, build B before C -- it is simpler and establishes the `anySessionActive` guard that C also depends on for mutual exclusion.

### Research Flags

**Needs resolution before Phase B begins:**
- **Manifest hosting strategy** -- HuggingFace refs API (no infrastructure, no per-file checksums) vs. project-owned JSON on gh-pages (enables SHA-256 per file and `min_app_version`). Write an ADR in `.planning/` before Phase B planning.

**Needs confirmation before Phase C begins:**
- **Model locale support** -- confirm Parakeet-TDT v3 coreml is English-only. If `transcriptionLocale` in `AppSettings` is exposed as a user setting, `DictationCoordinator` must inherit it correctly.

**Standard patterns (skip research phase):**
- Phase A: data model changes, settings keys
- Phase C dictation mechanics: KeyboardShortcuts, NSPanel, NSPasteboard -- all well-documented, decisions locked
- Phase D integration testing: follows existing v1.0 QA patterns

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | KeyboardShortcuts 2.4.0 verified; Carbon behavior verified; HuggingFace refs API live-verified 2026-04-27; NSPasteboard write unaffected by macOS 26 clipboard privacy |
| Features | HIGH (dictation), MEDIUM (model update) | Dictation patterns verified across 6+ shipping apps; model update UX has macMLX as closest reference only |
| Architecture | HIGH | All findings from direct codebase inspection 2026-04-27; component map reflects actual files |
| Pitfalls | HIGH (model integrity, session guard, clipboard markers), MEDIUM (manifest hosting, FluidAudio compatibility) | CGEventTap pitfalls real but conditional -- not applicable to chosen mechanism |

**Overall confidence:** HIGH for the dictation track; MEDIUM for the model update track pending manifest hosting decision.

### Gaps to Address

- **Manifest hosting strategy** -- resolve before Phase B. Recommendation: project-owned manifest on gh-pages to support per-file SHA-256 checksums and `min_app_version` gating. Write ADR.
- **FluidAudio model locale** -- confirm whether Parakeet-TDT v3 supports locales beyond English. Low risk if app currently only supports English; confirm before Phase C to avoid a late-breaking constraint.
- **DictationOutputMode default** -- decide whether `.clipboard` or `.both` is the out-of-box default. Research supports `.clipboard` as the simplest first-run experience.
- **HUD position** -- lock to bottom-center for v1.2 (matches SuperWhisper default, mirrors macOS Dictation feedback window). Configuration deferred to v2+.

---

## Sources

### Primary (HIGH confidence)

- `sindresorhus/KeyboardShortcuts` README + Package.swift -- v2.4.0 verified; no Accessibility required; SwiftUI Recorder included
- `FluidInference/FluidAudio` source (commit ea50062) -- `ModelRegistry.swift` inspected; no native version-check API
- `https://huggingface.co/api/models/FluidInference/parakeet-tdt-0.6b-v3-coreml/refs` -- live API response verified 2026-04-27
- Apple Developer Forum thread 735223 -- `RegisterEventHotKey` correct for sandboxed global shortcuts
- Direct codebase inspection: `PSTranscribe/Sources/PSTranscribe/` (2026-04-27)
- `nspasteboard.org` -- `org.nspasteboard.TransientType` and `AutoGeneratedType` marker spec; confirmed by Alfred/Maccy behavior
- FluidAudio GitHub Releases (v0.13.7, v0.13.2.5) -- breaking model structure changes confirmed across minor versions

### Secondary (MEDIUM confidence)

- macMLX -- model update UX reference: `.macmlx-meta.json` sidecar, orange badge, 24h throttle
- SuperWhisper changelog -- clipboard restore at 3s, cancel threshold at 30s, per-mode shortcuts
- mjtsai.com/blog/2025/05/12 -- macOS 15.4 clipboard privacy preview: reads trigger alert, writes do not
- GitHub issue feedback-assistant/reports#552 -- macOS 15 Option-only modifier restriction for `RegisterEventHotKey`
- Apple Developer Forums thread 792152 -- NSWindowSharingType bypass by ScreenCaptureKit (documented limitation)

### Tertiary (informational)

- Wispr Flow, MacWhisper Global, Axii, Voxt documentation -- competitive feature matrix validation
- danielraffel.me TIL 2026-02-19 -- CGEventTap silent disable after re-sign (conditional risk only, not applicable to v1.2 path)

---

*Research completed: 2026-04-27*
*Ready for roadmap: yes*
