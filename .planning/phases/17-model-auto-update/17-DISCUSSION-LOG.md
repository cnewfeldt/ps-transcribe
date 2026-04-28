# Phase 17: Model Auto-Update - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-27
**Phase:** 17-model-auto-update
**Areas discussed:** Manifest hosting (gate), Settings > Model UX, Check trigger & cadence, First-run migration, min_app_version blocked-update UX

---

## Manifest Hosting (Gate)

### Q1: Where does the model manifest live?

| Option | Description | Selected |
|--------|-------------|----------|
| Releases repo /main | Project-owned JSON at raw.githubusercontent.com/cnewfeldt/ps-transcribe-releases/main/model-manifest.json. Per-file SHA-256, min_app_version, full control. Mutable branch URL (mitigated by SHA-256 verification of model files). | ✓ |
| Releases repo /tag | Project-owned JSON pinned to a release tag or attached as a Release asset. Immutable once published. Adds a release step every model update. | |
| HuggingFace refs API | https://huggingface.co/api/models/FluidInference/parakeet-tdt-0.6b-v3-coreml/refs. No infra. No per-file SHA-256, no min_app_version field. | |
| Hybrid | HF refs API for version detection only, project-owned manifest for SHA-256 + min_app_version when an update is detected. Two endpoints, two failure modes. | |

**User's choice:** Releases repo /main (Recommended)
**Notes:** Resolves the research-flagged manifest-hosting ADR for Phase B (Phase 17). Aligns with the existing Sparkle appcast.xml location.

---

### Q2: Where do the model FILE downloads come from?

| Option | Description | Selected |
|--------|-------------|----------|
| HuggingFace URLs in manifest | Manifest references HF download URLs. SHA-256 from manifest is the integrity gate. No mirroring. | ✓ |
| Mirrored to GitHub Releases | Re-host model weights as Release assets. Full control, but adds release-pipeline complexity. | |
| Manifest carries both, app falls back | Try HF first, fall back to mirror. Defensive but doubles maintenance. | |

**User's choice:** HuggingFace URLs in manifest (Recommended)
**Notes:** HF is upstream source of truth and FluidAudio's existing AsrModels.downloadAndLoad already pulls from there.

---

### Q3: Will the v3 model itself be the first thing the manifest publishes?

| Option | Description | Selected |
|--------|-------------|----------|
| Manifest declares current v3 as version 1 | First manifest documents the already-shipped Parakeet-TDT v3 model with version='20260427'. Channel dormant until a real new model lands. | ✓ |
| Wait until there's a real new model | Don't publish a manifest until FluidAudio ships a newer Parakeet model. App ships with the channel wired but inert. | |

**User's choice:** Manifest declares current v3 as version 1 (Recommended)
**Notes:** Lets us dogfood the update path before depending on it. Adds "publish initial manifest" to the v1.2 release prerequisites.

---

### Q4: How do we verify the manifest itself wasn't tampered with?

| Option | Description | Selected |
|--------|-------------|----------|
| Trust HTTPS + GitHub | raw.githubusercontent.com over HTTPS pinned to our specific repo. SHA-256 in the manifest gates the model files. Matches Sparkle's appcast.xml posture. | ✓ |
| EdDSA-sign the manifest | Sign model-manifest.json with the existing Sparkle EdDSA key. Reuses keypair we already manage. Adds a signing step to every model release. | |
| Pin manifest SHA-256 in app binary | Sparkle-style: app embeds a known manifest SHA. Defeats the point of independent model channel. | |

**User's choice:** Trust HTTPS + GitHub (Recommended)
**Notes:** Threat model: a manifest-swap attacker would still need to ship a model whose SHA-256 matches the tampered manifest. Model files are the actual attack surface; SHA-256 already covers them.

---

## Settings > Model UX

### Q1: How is the Speech Model section organized in Settings?

| Option | Description | Selected |
|--------|-------------|----------|
| New 'Speech Model' section | Section('Speech Model') below 'Updates'. Visually distinct from Sparkle's app-update toggle. | ✓ |
| Nested inside Updates section | One 'Updates' section with two subsections (App + Speech Model). Reads as 'all updates in one place' but mixes Sparkle's toggle with model-specific UI. | |
| Top-level rename to 'Software' | Combine into 'Software' covering both. Cleanest mental model but breaks the existing 'Updates' label. | |

**User's choice:** New 'Speech Model' section (Recommended)
**Notes:** Avoids Settings bloat (PITFALLS #18) by keeping concerns visually separate.

---

### Q2: How is the model version displayed?

| Option | Description | Selected |
|--------|-------------|----------|
| Manifest version + readable date | 'Speech Model: v20260427 · Apr 27, 2026'. Manifest version is canonical; date is for humans. | ✓ |
| Just the manifest version | 'Speech Model: 20260427'. Compact, technical. | |
| Semver from manifest | 'Speech Model: 3.0.1'. Requires defining a semver scheme for models — version-management overhead with no benefit. | |

**User's choice:** Manifest version + readable date (Recommended)

---

### Q3: How does the 'update available' state surface?

| Option | Description | Selected |
|--------|-------------|----------|
| Inline pill + Install button | Inside the section: 'Update available: v20260601 · ~520 MB' + [Install Update]. No badges in sidebar/menu. | ✓ |
| Sidebar dot + inline pill | Add an orange dot to the Settings menu bar item AND show the inline pill. More discoverable but borders on intrusive. | |
| Inline only, no pill | Just text: 'New version v20260601 available' followed by [Install Update]. | |

**User's choice:** Inline pill + Install button (Recommended)
**Notes:** Matches MODEL-02 'non-intrusive, no modal alerts'.

---

### Q4: What does the download UI look like during 'Install Update'?

| Option | Description | Selected |
|--------|-------------|----------|
| Inline determinate progress + Cancel | [Install Update] button morphs into '[==45%====] Installing... 240/520 MB [Cancel]'. Determinate from manifest size. | ✓ |
| Modal sheet like OnboardingView | Reuse the existing onboarding download sheet (indeterminate spinner). Matches MODEL-04 literally. | |
| Inline indeterminate | Inline ProgressView (circular spinner) + status text only. Loses determinate feedback. | |

**User's choice:** Inline determinate progress + Cancel (Recommended)
**Notes:** Reuses the v1.0 Phase 4 download flow's underlying mechanics (URLSession + status text) but presents it as ambient state rather than a modal.

---

## Check Trigger & Cadence

### Q1: When does the automatic check fire?

| Option | Description | Selected |
|--------|-------------|----------|
| On app launch + opportunistic | Check fires ~10 seconds after launch IF >24h since modelLastCheckedDate. Also opportunistically on Settings > Speech Model open IF >24h. No background timer. | ✓ |
| On launch only | Only checks at launch (with 24h throttle). | |
| Launch + 24h periodic timer | DispatchSourceTimer fires every 24h while app runs. | |

**User's choice:** On app launch + opportunistic (Recommended)
**Notes:** Avoids long-running timer that has to survive sleep/wake cleanly.

---

### Q2: Can the user disable automatic checks?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, toggle in Speech Model section | 'Automatically check for new speech models' toggle, default ON. Mirrors the existing Sparkle toggle. | ✓ |
| No, always check (just throttled) | No toggle. Background check always runs (24h throttle). | |

**User's choice:** Yes, toggle in Speech Model section (Recommended)
**Notes:** Adds a NEW AppSettings key 'modelAutoUpdateEnabled: Bool' (default true). Phase 16 D-04 did NOT include this — Phase 17 adds it.

---

### Q3: How does the manual 'Check for Updates' button behave?

| Option | Description | Selected |
|--------|-------------|----------|
| Always present, bypasses 24h throttle | Button always shown. Forces a manifest fetch regardless of last-checked date. | ✓ |
| Hidden when auto-check is enabled and recent | Button only appears if auto-check is OFF or last check was >24h ago. | |

**User's choice:** Always present, bypasses 24h throttle (Recommended)
**Notes:** Matches macMLX behavior. Updates modelLastCheckedDate on success.

---

## First-run Migration

### Q1: How does Phase 17 backfill installedModelVersion for existing v1.0 users?

| Option | Description | Selected |
|--------|-------------|----------|
| Trust file presence + manifest match | On first manifest fetch after upgrade, IF installedModelVersion=='' AND all manifest.files[*].name exist on disk AND first file size matches manifest — silently set installedModelVersion = manifest.version. Cheap, deterministic, no hashing. | ✓ |
| SHA-compare existing files | Hash every existing model file against manifest checksums. Bulletproof but spends 5-30 seconds hashing on first launch after upgrade. | |
| Leave empty, force first user-initiated update | Show 'Update available' on first launch. User redownloads ~520MB they already have. Honest but wasteful and confusing. | |
| Hardcode initial version in binary | Bake INITIAL_MODEL_VERSION='20260427' into Phase 17 code. Brittle. | |

**User's choice:** Trust file presence + manifest match (Recommended)
**Notes:** Conjunctive check (empty version + all files present + first-file size match). Any 'no' reverts to normal flow.

---

### Q2: After a rollback, what happens to the <repo>-failed/ directory?

| Option | Description | Selected |
|--------|-------------|----------|
| Keep until next successful update | Rename to <repo>-failed-<timestamp>/. Delete on the NEXT successful update. One cycle of forensic visibility. | ✓ |
| Delete immediately on rollback | Free disk space the second the rollback completes. Loses diagnostic data. | |
| Keep forever, manual cleanup | Never auto-delete. User has to clean up. Disk-bloat risk. | |

**User's choice:** Keep until next successful update (Recommended)

---

## Blocked Update UX (Pitfall #12)

### Q: When manifest.min_app_version exceeds the installed app version, what does the user see?

| Option | Description | Selected |
|--------|-------------|----------|
| Inform + nudge to app update | Speech Model section shows: 'New v20260601 requires PS Transcribe ≥ 1.3.0. [Check for App Update]' — button calls Sparkle's checkForUpdates(). | ✓ |
| Hide entirely, fall through silently | If min_app_version unsatisfied, treat manifest as 'no update available'. Clean but invisible. | |
| Show but disable Install with tooltip | Greyed-out [Install Update] with tooltip. Information without action. | |

**User's choice:** Inform + nudge to app update (Recommended)
**Notes:** Single-click recovery path. Distinct UI state from 'up to date' and 'update available'.

---

## Claude's Discretion

Decisions deferred to Claude's judgment during research/planning:
- Disk-space preflight UX detail (Pitfall #14, MODEL-10): inline message + disabled Install when free space < `manifest.total_size_bytes * 2`.
- Cancellation semantics: `URLSessionDownloadTask.cancel()` + delete `<repo>-staging/` contents + restore [Install Update] button. Active model never moved during download (only during swap).
- `reloadModels()` implementation: nil out `asrManager`/`vadManager` first (ARC drop), then `AsrModels.downloadAndLoad(version: .v3)` (reads from disk), re-instantiate managers, set `modelsReady = true`.
- File-system location for `ModelUpdateService`: `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift` (creates new `Services/` directory).
- Internal `updatePending: Bool` flag — likely in-memory only; user can re-trigger after relaunch if app dies between download-complete and apply.
- Telemetry/identifying parameters on manifest fetch: NONE. Plain URLSession dataTask, no User-Agent customization, no headers beyond defaults.

---

## Deferred Ideas

Ideas raised during research/discussion that belong in other phases or future work:
- Cellular-network warning before large download (NWPathMonitor) — could fold into Phase 19 hardening or v1.3 polish.
- Sidebar/menu-bar badge for update available (macMLX-style) — rejected for v1.2 per inline-only decision.
- EdDSA signing of `model-manifest.json` — rejected; SHA-256 on model files is the meaningful integrity gate.
- Mirroring model files to GitHub Releases — rejected; HF is upstream source of truth.
- Model rollback UI / version pinning — explicitly out of scope per REQUIREMENTS.md.
- SHA-compare migration alternative — rejected for D-14 in favor of size+presence check.
- Long-running 24h background timer — rejected per D-10.
