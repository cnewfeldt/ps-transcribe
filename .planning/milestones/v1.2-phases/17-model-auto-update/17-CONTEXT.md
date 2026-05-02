# Phase 17: Model Auto-Update - Context

**Gathered:** 2026-04-27
**Status:** Ready for planning (manifest hosting ADR resolved — research gate cleared)

<domain>
## Phase Boundary

Independent ASR model update channel separate from Sparkle. Delivers: a `ModelUpdateService` actor (manifest fetch, version compare, staged download, SHA-256 verify, atomic rename, rollback), `TranscriptionEngine.reloadModels()` for hot-swap, and a Settings > "Speech Model" section with version display, update-available pill, "Install Update" button with cancellable inline progress, and a "Check for Updates" manual trigger.

Phase 17 satisfies MODEL-01 through MODEL-10. It does NOT cover dictation (Phase 18) or end-to-end mutual-exclusion validation (Phase 19) — though it correctly wires `SessionCoordinator.modelUpdate` so Phase 19 can audit the integration.

</domain>

<decisions>
## Implementation Decisions

### Manifest Hosting & Authentication
- **D-01:** Manifest hosted at `https://raw.githubusercontent.com/cnewfeldt/ps-transcribe-releases/main/model-manifest.json` (project-owned, alongside the existing Sparkle `appcast.xml`). Rationale: per-file SHA-256 + `min_app_version` field unavailable from HuggingFace refs API. Live URL on `main` is acceptable; integrity comes from SHA-256 verification of the model files (D-02), not from manifest immutability.
- **D-02:** Model file downloads come from HuggingFace URLs declared inside the manifest. The manifest carries SHA-256 per file; the app verifies after download. No mirroring to GitHub Releases — HF is upstream source of truth and FluidAudio's `AsrModels.downloadAndLoad` already pulls from there.
- **D-03:** First published manifest declares the currently-shipped Parakeet-TDT v3 model as version `"20260427"` (date-shaped string). The channel ships wired but produces no "update available" until a real new model lands. This lets us dogfood the path before depending on it. **Release prerequisite:** publish the initial `model-manifest.json` to `ps-transcribe-releases:main` before tagging v1.2.
- **D-04:** Manifest authentication = HTTPS + GitHub trust only. No EdDSA signature on the JSON. Threat model: a manifest swap attacker would still need to ship a model file whose SHA-256 matches their tampered manifest, which means the model files are the actual attack surface and SHA-256 already covers them. Matches Sparkle's existing `appcast.xml` posture.
- **D-05:** Manifest schema:
  ```json
  {
    "model_id": "parakeet-tdt-0.6b-v3-coreml",
    "version": "20260427",
    "min_app_version": "1.2.0",
    "total_size_bytes": 545312000,
    "files": [
      { "name": "preprocessor.mlpackage", "url": "https://huggingface.co/...", "sha256": "<hex>", "size": 12345 },
      { "name": "encoder.mlpackage",      "url": "https://huggingface.co/...", "sha256": "<hex>", "size": 234567890 },
      { "name": "decoder.mlpackage",      "url": "https://huggingface.co/...", "sha256": "<hex>", "size": 78901234 },
      { "name": "joint.mlpackage",        "url": "https://huggingface.co/...", "sha256": "<hex>", "size": 5678901 }
    ]
  }
  ```
  `total_size_bytes` drives both determinate progress (D-09) and disk-space preflight. `url` per file allows future flexibility without a schema change.

### Settings > Speech Model UX
- **D-06:** New top-level `Section("Speech Model")` in `SettingsView`. Order: Audio Input → Obsidian → Notion → Privacy → Updates → **Speech Model** → [Dictation, Phase 18]. Visually distinct from the Sparkle "Updates" section. Avoids the `Section("Updates")` reuse trap (D-08 in PITFALLS #18 — Settings bloat).
- **D-07:** Version display uses manifest version + readable date: `Speech Model: v20260427 · Apr 27, 2026`. When an update is available: `Speech Model: v20260427 → v20260601` with an inline pill showing `Update available · ~520 MB` and an `[Install Update]` button. Manifest version is the canonical machine-readable string; the date is for humans.
- **D-08:** Update-available state is **inline only**. No sidebar dot, no menu-bar badge, no system notification. User sees the state when they're already in Settings. Matches MODEL-02 "non-intrusive, no modal alerts, no notifications."
- **D-09:** Download UI is **inline determinate**. The `[Install Update]` button morphs in place to `[==45%====] Installing... 240/520 MB  [Cancel]`. After verify+swap completes: `✓ Updated to v20260601 · active`. Failure: `⚠️ Update failed: <reason>  [Retry]`. **No modal sheet** — unlike `OnboardingView` (which is a one-time first-run gate), an in-app update should remain ambient.

### Check Trigger & Cadence
- **D-10:** Auto-check fires ~10 seconds after app launch IF `Date().timeIntervalSince(modelLastCheckedDate) > 24h`. Also opportunistically when the user opens Settings > Speech Model IF >24h since last check. **No long-running background timer** (no `DispatchSourceTimer`) — most users launch daily; the cost of a periodic timer that has to survive sleep/wake cleanly is not worth the marginal coverage.
- **D-11:** **NEW AppSettings key** `modelAutoUpdateEnabled: Bool` (default `true`). UserDefaults key: `"modelAutoUpdateEnabled"`. UI label: `"Automatically check for new speech models"` (mirrors Sparkle's wording). **This key was NOT added in Phase 16** — Phase 16 D-04 wired `installedModelVersion` and `modelLastCheckedDate` only. Phase 17 adds the toggle. Privacy-conscious users (matches our offline-first proposition) can disable cloud calls entirely; only the manual button works when off.
- **D-12:** Manual `[Check for Updates]` button is always present in the Speech Model section. Clicking forces a manifest fetch regardless of `modelLastCheckedDate` and regardless of `modelAutoUpdateEnabled`. Updates `modelLastCheckedDate` on success. Status line: "Checking..." → "Up to date as of {date}" or "Update available: v{new}".
- **D-13:** When `modelAutoUpdateEnabled == false`, the auto-check at launch and the opportunistic check on settings open are both suppressed. Manual button still works.

### Migration & Rollback
- **D-14:** **First-run backfill** for existing v1.0 users: on first manifest fetch after upgrading to v1.2, IF `installedModelVersion == ""` AND every `manifest.files[*].name` exists on disk in `~/Library/Application Support/FluidAudio/Models/parakeet-tdt-0.6b-v3-coreml/` AND the first file's size matches `manifest.files[0].size`, **silently set** `installedModelVersion = manifest.version`. No download, no UI, no SHA-256 hashing on launch. Size-only check is the cheap-but-deterministic compromise against a 5-30s SHA scan of ~520MB.
- **D-15:** **Rollback retention.** After a verify-or-reload failure, rename the failed staging directory to `<repo>-failed-{ISO8601-timestamp}/` (e.g., `parakeet-tdt-0.6b-v3-coreml-failed-20260427T143022/`). Delete the previous `*-failed-*/` directory on the **next** successful update. One cycle of forensic visibility for developer support without unbounded disk growth.
- **D-16:** **Blocked update (Pitfall #12 — `min_app_version` exceeded)** UX: when `manifest.min_app_version` > current `Bundle.main.shortVersion`, the Speech Model section shows: `New v20260601 requires PS Transcribe ≥ 1.3.0. [Check for App Update]`. The `[Check for App Update]` button calls Sparkle's `SPUUpdater.checkForUpdates()`. **No** model `[Install Update]` button is shown. This is a third UI state distinct from "up to date" and "update available."

### Compatibility Comparison Semantics
- **D-17:** Use Foundation's `String.compare(_:options:.numeric)` for `min_app_version` and `version` comparisons — handles `"1.10.0" > "1.2.0"` correctly. Avoid lexicographic string compare. Apply to both manifest version comparison and `min_app_version` gate.

### Concurrency & Mutual Exclusion
- **D-18:** `ModelUpdateService` is `@Observable @MainActor final class` (matches `AppUpdaterController.swift` pattern). Exposes `var updateState: ModelUpdateState` and `var isApplying: Bool`. Phase 17 wires `SessionCoordinator.modelUpdate = service` per the additive Optional pattern documented at `SessionCoordinator.swift:23-31`. After wiring, `anySessionActive` becomes `(engine?.isRunning ?? false) || (modelUpdate?.isApplying ?? false)`.
- **D-19:** **Apply-deferral on active session.** `ModelUpdateService.downloadAndApply()` may proceed with download regardless of session state, but the **atomic swap step** (`mv <repo>/ → <repo>-backup/`, `mv <repo>-staging/ → <repo>/`, `reloadModels()`) is gated on `sessionCoordinator.anySessionActive == false`. If a session is active when download completes, set `updatePending = true` and apply on next session-stop notification. Satisfies MODEL-07 directly.

### Claude's Discretion
- Exact AppSettings key naming for any internal state beyond the three keys named above (e.g., serializing `updatePending` flag to UserDefaults vs in-memory only — likely in-memory; user can re-trigger after relaunch).
- **Disk-space preflight UX** (Pitfall #14, MODEL-10): if `volumeAvailableCapacityForImportantUsage` < `manifest.total_size_bytes * 2`, show inline `Update available — needs ~1.1 GB free, 600 MB available · [Free up space]` and disable Install. The doubling factor accounts for staging + production directory coexistence during swap.
- **Cancellation semantics** (Phase 17 success criterion #3): Cancel button calls `URLSessionDownloadTask.cancel()`, deletes `<repo>-staging/` contents, restores `[Install Update]` button. Active model untouched. The active model is never even temporarily moved during download — only during the swap step (D-19), which cancellation never reaches.
- **Telemetry / identifying parameters on the manifest fetch:** NONE. Hard project constraint. URLSession `dataTask` to a known host with no query params, no User-Agent customization, no headers beyond defaults.
- **`reloadModels()` implementation detail:** nil out `asrManager` and `vadManager` first (so ARC drops MLModel refs before the rename), then call `AsrModels.downloadAndLoad(version: .v3)` (which reads from disk since files are now in place), then re-instantiate the managers and set `modelsReady = true`. Pattern mirrors `prepareModels()` at `TranscriptionEngine.swift:79-103`.
- **Where `ModelUpdateService` lives in the file tree:** `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift` (creates the new `Services/` directory if it doesn't already exist; ARCHITECTURE.md prescribes this).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements
- `.planning/ROADMAP.md` §"Phase 17: Model Auto-Update" — phase goal, depends-on (Phase 16), 5 success criteria, 10 requirement mappings
- `.planning/REQUIREMENTS.md` §"Model Auto-Update" — MODEL-01 through MODEL-10 with acceptance text
- `.planning/REQUIREMENTS.md` §"Out of Scope" — confirms no cloud ASR, no LLM cleanup, no silent install, no rollback UI, no telemetry
- `.planning/PROJECT.md` — v1.2 milestone goal, "Out of Scope" list (no telemetry, no cloud APIs ever), constraints

### Research
- `.planning/research/SUMMARY.md` — overall v1.2 architecture, "Phase B: Model Auto-Update" build order, "Critical Pitfalls" #11/#12/#13/#14, "Manifest hosting strategy" gap (now resolved by D-01)
- `.planning/research/ARCHITECTURE.md` §"Feature 3: Model Auto-Update" — `ModelUpdateService`, `ModelUpdateState` enum, manifest format, full data-flow diagram for check → download → verify → swap → rollback, "Component Interaction Map", "Build Order Phase B"
- `.planning/research/PITFALLS.md` — Pitfall #11 (partial download corruption), Pitfall #12 (FluidAudio compat / `min_app_version`), Pitfall #13 (swap during active session), Pitfall #14 (disk-space exhaustion), Pitfall #15 (FluidAudio telemetry leak — design constraint), "Looks Done But Isn't" checklist (model items)
- `.planning/research/STACK.md` — confirms no new SwiftPM dependency for model update; URLSession + existing FluidAudio is sufficient
- `.planning/research/FEATURES.md` — macMLX UX reference for badge placement and 24h throttle; SuperWhisper reference for inline status

### Phase 16 (precedes Phase 17)
- `.planning/phases/16-foundation/16-CONTEXT.md` — D-04 (AppSettings keys `installedModelVersion`, `modelLastCheckedDate` already wired); D-05/D-06 (SessionCoordinator pattern with weak Optional fields for additive integration); D-07 (SessionCoordinator owned by `PSTranscribeApp` and injected into `ContentView`)
- `.planning/phases/16-foundation/16-04-SUMMARY.md` — SessionCoordinator wiring details; `weak var engine: TranscriptionEngine?` already in place

### Source files Phase 17 modifies or creates
- `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift` — **NEW.** `@Observable @MainActor final class` with `updateState: ModelUpdateState`, `isApplying: Bool`, `checkForUpdate()`, `downloadAndApply()`, `cancelDownload()`, applyDeferred update on session-end notification
- `PSTranscribe/Sources/PSTranscribe/Transcription/TranscriptionEngine.swift` — ADD `func reloadModels() async throws` (~30 lines mirroring `prepareModels()` at lines 79-103); `asrManager` and `vadManager` are already `private` (lines 61-62), `modelsReady` is `private(set)` (line 20)
- `PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift` — **ADD** `modelAutoUpdateEnabled: Bool` (default `true`, didSet UserDefaults mirroring per existing pattern at lines 76-89). NOT yet present from Phase 16.
- `PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift` — ADD `Section("Speech Model")` between current `Section("Updates")` (line 54) and end of Form (line 60). Inject `modelUpdateService: ModelUpdateService` parameter into `SettingsView`.
- `PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift` — instantiate `ModelUpdateService` at app scope (`@State`), inject into `SettingsView`, wire `sessionCoordinator.modelUpdate = modelUpdateService`
- `PSTranscribe/Sources/PSTranscribe/App/SessionCoordinator.swift` — uncomment lines 23-31; add `weak var modelUpdate: ModelUpdateService?`; update `anySessionActive` body to `(engine?.isRunning ?? false) || (modelUpdate?.isApplying ?? false)`

### Manifest publication (separate repo, release prerequisite)
- `cnewfeldt/ps-transcribe-releases:main/model-manifest.json` — **MUST be authored and pushed before v1.2 release tag.** First manifest declares the v3 Parakeet model already shipped in v1.0. Without this, the manifest fetch returns 404 and the Speech Model section perpetually shows "Checking…" or an error.
- `PSTranscribe/Sources/PSTranscribe/Info.plist:29-30` — `SUFeedURL` confirms the releases repo location: `https://raw.githubusercontent.com/cnewfeldt/ps-transcribe-releases/main/appcast.xml`. Model manifest sits beside it on the same branch.

### Project conventions
- `.planning/codebase/CONVENTIONS.md` — Swift 6.2 actor patterns, `@Observable @MainActor` classes, error handling without silent `try?`
- `.planning/codebase/STRUCTURE.md` — directory layout (note: still references `Tome/` in places; actual code is at `PSTranscribe/Sources/PSTranscribe/`)
- `PSTranscribe/Sources/PSTranscribe/App/AppUpdaterController.swift` — reference implementation for "external service that wraps a version-fetching system and exposes user-initiated install" — `ModelUpdateService` follows the same shape

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `private(set) var modelsReady = false` (`TranscriptionEngine.swift:20`), `asrManager: AsrManager?` (`:61`), `vadManager: VadManager?` (`:62`) — already nullable; ARC-drop pattern works for hot-swap. `reloadModels()` nils both before the directory rename.
- `AsrModels.downloadAndLoad(version: .v3)` — already called at `TranscriptionEngine.swift:83` and `:123`. No-op when files already exist on disk. `reloadModels()` reuses this; the staging→production rename ensures files are in place before the call returns.
- `@Observable @MainActor final class AppSettings` (`AppSettings.swift:6`) — established pattern with `didSet` UserDefaults mirroring; D-04 already added the two model keys we depend on; Phase 17 adds `modelAutoUpdateEnabled` per the same pattern.
- `SessionCoordinator.swift:23-31` — comment block explicitly documents the `weak var modelUpdate: ModelUpdateService?` extension point Phase 17 fills. The additive `(modelUpdate?.isApplying ?? false)` clause is pre-spelled-out in the comment.
- `Info.plist:29-30` — `SUFeedURL` confirms `cnewfeldt/ps-transcribe-releases` as the canonical hosting location. Model manifest URL parallels the Sparkle one.
- `AppUpdaterController.swift` — pattern reference for the "fetch metadata + offer user-initiated install" service shape. ModelUpdateService mirrors this.

### Established Patterns
- One actor / `@Observable @MainActor` class per concern (`TranscriptLogger`, `LibraryStore`, `SessionStore`, `SessionCoordinator`); `ModelUpdateService` is the next instance.
- AppSettings keys use `didSet` UserDefaults sync — single source of truth, no `@AppStorage`.
- `SettingsView` uses `Form { Section { … } }` composition — drop-in pattern for the new "Speech Model" section.
- `@Bindable var settings: AppSettings` injection for any view that reads/writes settings — Phase 17 SettingsView additions follow this.
- Apply / start operations check guards against shared state (`guard !modelsReady` at `TranscriptionEngine.swift:79`); `ModelUpdateService` checks `sessionCoordinator.anySessionActive` before swap.

### Integration Points
- `TranscriptionEngine.swift:79-103` (`prepareModels()`) and `:107-145` (`start()`) — both load models. New `reloadModels()` mirrors `prepareModels()` plus an explicit `asrManager = nil; vadManager = nil` step before reload.
- `PSTranscribeApp.swift` — SessionCoordinator and LibraryStore already at app scope (Phase 16 D-07, D-12). Phase 17 adds `@State modelUpdateService: ModelUpdateService` and wires `sessionCoordinator.modelUpdate = modelUpdateService` after both exist.
- `SettingsView.swift:11-25` — initializer takes `settings`, `updater: SPUUpdater`, `notionService`. Phase 17 adds `modelUpdateService: ModelUpdateService` parameter.
- `ContentView` does NOT need changes for Phase 17 — its only relevant read is `transcriptionEngine.isRunning`, which `SessionCoordinator.anySessionActive` already wraps.

</code_context>

<specifics>
## Specific Ideas

- **Release-tooling note (release prerequisite):** Before v1.2 ship, author the initial `model-manifest.json` and push it to `cnewfeldt/ps-transcribe-releases:main`. Otherwise the Speech Model section's first manifest fetch 404s and the channel looks broken on day one. Add this to the v1.2 release checklist (suggested location: a section in `.planning/STATE.md` or `milestones/v1.2-ROADMAP.md` once it exists).
- **Numeric version comparison:** Use `String.compare(_:options:.numeric) == .orderedAscending` for both manifest version comparison and `min_app_version` gating. String lexicographic compare incorrectly orders `"1.10.0" < "1.2.0"`. This applies in both directions: `installedModelVersion < manifest.version` (update available?) and `Bundle.main.shortVersion < manifest.min_app_version` (blocked?).
- **Manifest URL is hardcoded** in the app binary (`let modelManifestURL = URL(string: "https://raw.githubusercontent.com/cnewfeldt/ps-transcribe-releases/main/model-manifest.json")!`). No flexibility intended — the value is paired with the project's release infrastructure.
- **Migration check (D-14) safety:** if `installedModelVersion` is empty AND model files are missing or partial, the migration backfill must NOT fire — the user genuinely needs a fresh download. The check is conjunctive: empty version + all files present + size-match-on-first-file. Any "no" reverts to normal "update available" / "fresh install" flow.
- **Pitfall #15 boundary:** Phase 17 must NOT update or unpin the FluidAudio Swift package. Only model weight files (CoreML `.mlpackage` directories) are updated through this channel. The FluidAudio commit pin (`ea50062`) only changes via Sparkle. Verify in code review: no `Package.swift` or `Package.resolved` changes touch FluidAudio under Phase 17 plans.

</specifics>

<deferred>
## Deferred Ideas

- **Cellular-network warning before large download (NWPathMonitor)** — Pitfall noted in PITFALLS.md "Performance Traps" table. Not blocking for any MODEL-* requirement; defer to v1.3 polish or fold into Phase 19 hardening if cheap.
- **Sidebar/menu-bar badge for update available (macMLX-style)** — Considered, rejected for v1.2. Inline-only matches MODEL-02's "non-intrusive, no modal alerts."
- **EdDSA signing of `model-manifest.json`** — Considered, rejected. SHA-256 on individual model files is the integrity gate that matters most; manifest signing adds release-pipeline complexity for a marginal threat-model improvement (an attacker who can MITM `raw.githubusercontent.com` over HTTPS in 2026 has bigger leverage than swapping a model manifest). Revisit only if we ever serve manifest from an untrusted CDN.
- **Mirroring model files to GitHub Releases** — Rejected. HuggingFace is upstream source of truth; mirroring doubles bandwidth + maintenance with no functional win.
- **Model rollback UI / version pinning** — Explicitly out of scope per `REQUIREMENTS.md` Out-of-Scope table. Users who don't want a new model leave auto-update off OR don't click Install. The internal `<repo>-backup/` rollback (D-15) is for recovery from failed APPLIES, not user-driven downgrades.
- **SHA-compare migration (alternative to D-14)** — Rejected. Adds 5-30s of launch latency to handle a vanishingly rare edge case (FluidAudio's `downloadAndLoad` already retries partial downloads; truly corrupt installs are not in the v1.0 field reports).
- **Long-running 24h background timer (`DispatchSourceTimer`)** — Rejected per D-10. Apple has had recurring sleep/wake bugs with periodic timers; opportunistic check-on-launch + check-on-settings-open covers daily users without the maintenance burden.
- **Hardcoding `INITIAL_MODEL_VERSION` constant in the binary as a Phase 16 retrofit** — Rejected per D-14. The migration backfill (file-presence + size match) is more flexible and doesn't require Phase 16's D-04 default to change.

</deferred>

---

*Phase: 17-model-auto-update*
*Context gathered: 2026-04-27*
