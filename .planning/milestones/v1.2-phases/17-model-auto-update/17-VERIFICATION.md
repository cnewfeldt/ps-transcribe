---
phase: 17-model-auto-update
verified: 2026-04-27T00:00:00Z
status: human_needed
score: 4/5 must-haves verified (SC-5 machine-verified; SC-1/SC-2/SC-3/SC-4 require live manifest for full confirmation)
overrides_applied: 0
human_verification:
  - test: "Open Settings > Speech Model and click Check for Updates with live manifest published"
    expected: "Shows 'Speech Model: v20260427 · Apr 27, 2026' or 'Speech Model: v{installed} → v{available}' with inline Update available pill, no modal"
    why_human: "Requires live manifest URL to return 200 -- pre-publish returns 404 which exercises .failed path only"
  - test: "Click Install Update, observe progress bar, click Cancel mid-download, verify active model unchanged"
    expected: "Progress bar fills incrementally, Cancel restores updateAvailable state, model files in parakeet-tdt-0.6b-v3/ are untouched"
    why_human: "Requires a real downloadable model file update; current manifest URL is unpublished"
  - test: "Complete a full update cycle: Install Update → download → apply → verify hot-swap"
    expected: "Next transcription session uses new model without app restart; installedModelVersion updated in UserDefaults"
    why_human: "Requires live manifest + real model files to download; unit tests stub the reload handler"
  - test: "Toggle 'Automatically check for new speech models' OFF, quit and relaunch; confirm auto-check does not fire in Console.app"
    expected: "No [ModelUpdate] log activity ~10s after launch; manual Check for Updates still works"
    why_human: "Requires running the app; cannot verify Console.app output programmatically"
---

# Phase 17: Model Auto-Update Verification Report

**Phase Goal:** Users can check for and install FluidAudio model updates from Settings without waiting for a Sparkle app release.
**Verified:** 2026-04-27
**Status:** human_needed
**Re-verification:** No -- initial verification

---

## Existing Verification Content (Plans 17-01 through 17-05)

The content below through the RELEASE PREREQUISITE section was written by the plan executors during Plans 17-04 and 17-05. It is preserved verbatim.

**Phase:** 17-model-auto-update
**Started:** 2026-04-27
**Status:** code-complete; release smoke deferred

### Success Criteria (from ROADMAP.md Phase 17)

- [ ] **SC-1:** User opens Settings > Model and sees the currently installed model version string alongside the latest available version
- [ ] **SC-2:** When a newer model is available, a non-intrusive badge appears in Settings > Model with no modal alerts or push notifications
- [ ] **SC-3:** User taps "Install Update," sees a progress bar, and can cancel mid-download; the active model is unaffected by a cancelled download
- [ ] **SC-4:** After a completed update, the app hot-swaps the model without restarting; the next transcription session uses the new model
- [ ] **SC-5:** A partial or checksum-failing download is rejected; the prior model remains active and the UI surfaces a clear failure reason

### Requirement Coverage (MODEL-01..10)

| Req | Covered by | Test | Status |
|-----|------------|------|--------|
| MODEL-01 | Plan 17-01 | `ModelUpdateServiceTests/throttleSuppressesNonForcedCheck` | pending |
| MODEL-02 | Plan 17-01 + 17-04 | `.../updateAvailableState` + manual UI smoke | pending |
| MODEL-03 | Plan 17-01 | `.../checkDoesNotDownload` | pending |
| MODEL-04 | Plan 17-02 + 17-04 | `.../downloadProgress`, `.../cancelCleanup` + manual UI smoke | pending |
| MODEL-05 | Plan 17-03 | `.../persistsVersion` | pending |
| MODEL-06 | Plan 17-02 + 17-03 | `.../checksumMismatchRollsBack`, `.../applySwapAtomicallyReplaces`, `.../failedReloadRollsBack` | pending |
| MODEL-07 | Plan 17-03 | `.../applyDoesNotProceedWithSessionActive` + `SessionCoordinatorTests/trueWhenModelUpdateApplying` | pending |
| MODEL-08 | Plan 17-04 | manual UI smoke (4 states) | pending |
| MODEL-09 | Plan 17-01 + 17-04 | `.../blockedByMinAppVersion` + manual UI smoke for blocked state | pending |
| MODEL-10 | Plan 17-02 + 17-04 | `.../insufficientDiskSpace` + manual UI smoke (low-disk simulation if feasible) | pending |

### Manual Smoke Test (Plan 17-04 Task 3)

Record the result of the 9-state checklist (A through I). To be filled in by the executor.

**Status from Plan 17-04:** Partially verified. Full end-to-end verification deferred to post-Plan-17-05 (manifest must be live).

**User response (2026-04-27):** `approved` -- 404 on manifest fetch acknowledged as expected pre-17-05 state.

#### Checklist Results

**A. Section ordering (D-06)**
- Deferred to post-17-05 manual run. Requires running the app with the live manifest published so the full "Updates -> Speech Model" sequence can be visually confirmed.

**B. Idle / up-to-date state**
- Deferred to post-17-05 manual run. The `installedModelVersion` empty path renders `Speech Model: v--` as expected when no manifest has been fetched. The `v{version} . {readableDate}` path cannot be confirmed until Plan 17-05 publishes the manifest.

**C. Manual "Check for Updates" button**
- Deferred to post-17-05 manual run. Pre-17-05, the manifest URL returns 404. The 404 is the documented expected state and transitions the UI to `.failed` (shows `Update failed: <reason>`). This is correct behavior -- no bug.
- 404 acknowledged by user as expected pre-17-05 publish state.

**D. Auto-update toggle**
- Deferred to post-17-05 manual run.

**E. Failed state (404 path)**
- Partially observable pre-17-05: clicking "Check for Updates" with the manifest unpublished should produce `Update failed: <reason>` with a "Retry" button. This is correct behavior for the pre-publish state.
- Deferred to post-17-05 for full confirmation of the "Retry" re-fires path.

**F. Auto-check trigger at launch (D-10)**
- Deferred to post-17-05 manual run. Throttle and toggle gate behavior requires a live manifest to distinguish "fetched and up-to-date" from "fetched and 404'd".

**G. AppSettings.modelAutoUpdateEnabled gate (D-13)**
- Deferred to post-17-05 manual run.

**H. SessionCoordinator integration (read-only check)**
- Deferred to post-17-05. Swap-deferral end-to-end cannot be verified without a live manifest delivering an actual downloadable update.
- Covered by Plan 17-03 unit tests (SessionCoordinatorTests + ModelUpdateServiceTests confirm the deferral logic).

**I. No regressions (P0)**
- User has not reported any regressions.
- Existing Settings flows (Audio, Obsidian, Notion, Privacy, Updates) are unmodified by Plans 17-01 through 17-04.
- Full test suite passes: `swift test` exits 0 with all ModelUpdateServiceTests, ModelManifestTests, SessionCoordinatorTests, AppSettingsTests passing.

### Plan 17-05 Backfill Smoke Test

**Unit-level verification (2026-04-27):** PASSED -- `swift test --filter "backfill"` runs 5 tests in `ModelUpdateServiceTests` and all pass:
- `backfillFiresWhenAllConditionsMet`
- `backfillDoesNotFireWhenInstalledIsSet`
- `backfillDoesNotFireOnSizeMismatch`
- `backfillDoesNotFireOnMissingFile`
- `backfillSurvivesAttributeReadFailure`

**End-to-end smoke (deferred to release):** requires UserDefaults manipulation against the v1.2 build with the live manifest published. Steps below are the runbook for the release-tag verification:
- [ ] On a copy of the v1.0 build, set `installedModelVersion = ""` in UserDefaults
- [ ] Confirm model files exist on disk at `~/Library/Application Support/FluidAudio/Models/parakeet-tdt-0.6b-v3/`
- [ ] Launch the v1.2 build (or run `checkForUpdate`)
- [ ] After the manifest fetch, confirm `installedModelVersion` equals the manifest's version (D-14)
- [ ] State should be `.upToDate(asOf:)` (NOT `.updateAvailable`)

### Manifest Generation Script Smoke Test (Plan 17-05 Task 4 / B)

**Verified 2026-04-27:** PASSED -- `swift scripts/generate-model-manifest.swift --version=20260427 --min-app=1.2.0` produced a manifest with:
- 23 files (>= 5 expected)
- `total_size_bytes`: 483,254,213 (~480-520 MB expected range)
- First entry SHA256: `4238c4e81ecd0dc94bd7dfbb60f7e2cc824107c1ffe0387b8607b72833dba350` (64-char hex)
- First entry name: `Decoder.mlmodelc/analytics/coremldata.bin` (proper leaf-file path)
- `model_id`: `parakeet-tdt-0.6b-v3-coreml`

### RELEASE PREREQUISITE -- Manifest Publication

<!-- manifest publication procedure -- required before v1.2 tag -->

**Before tagging v1.2:**

1. On a developer machine with the v3 model installed (i.e., a machine that has launched any version >= v1.0):
   ```
   swift Scripts/generate-model-manifest.swift --version=20260427 --min-app=1.2.0 > model-manifest.json
   ```
2. Sanity-check the JSON:
   ```
   cat model-manifest.json | jq '.files | length'   # should be >= 5 (Encoder leaf files)
   cat model-manifest.json | jq '.total_size_bytes' # should be ~520_000_000
   ```
3. Push to `cnewfeldt/ps-transcribe-releases` repo, branch `main`, file `model-manifest.json`:
   ```
   cd /path/to/ps-transcribe-releases
   cp /path/to/model-manifest.json .
   git add model-manifest.json
   git commit -m "feat: initial model manifest (v20260427) for v1.2 launch"
   git push origin main
   ```
4. Verify the live URL responds 200:
   ```
   curl -I https://raw.githubusercontent.com/cnewfeldt/ps-transcribe-releases/main/model-manifest.json
   ```
5. From a fresh PS Transcribe install, click "Check for Updates" and confirm `Speech Model: v20260427 . Apr 27, 2026` renders.

**Without this step, the live channel returns 404 on day one.** Phase 17 ships in a code-complete state; the prerequisite gates v1.2's actual launch.

### Build & Test Verification

**Verified 2026-04-27 post-Plan-17-05:**
- [x] `cd PSTranscribe && swift build` exits 0 -- clean build
- [x] `cd PSTranscribe && swift test` exits 0 -- 114 tests in 17 suites pass
- [ ] `cd PSTranscribe && swift test --filter TranscriptionEngineReloadModelsTests` exits 0 (integration suite, deferred -- requires CoreML runtime in CI)
- [x] `! git diff --name-only HEAD | grep -E 'Package\.(swift|resolved)$'` -- PASS, no Package.swift changes
- [x] `! grep -E 'setValue.*forHTTPHeaderField|User-Agent|queryItems' PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift` -- PASS, no telemetry

---

*Phase 17 verification: code-complete. Deterministic gates pass. End-to-end UI/UX smoke test deferred to release-tag verification once manifest is published per the RELEASE PREREQUISITE section above.*

---

## Automated Verification Report (gsd-verifier, 2026-04-27)

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|---------|
| 1 | User opens Settings > Model and sees currently installed version alongside latest | VERIFIED (code) + human_needed (live manifest) | `upToDateRow` renders `"Speech Model: v{installed} · {date}"`; `updateAvailableRow` renders `"Speech Model: v{installed} → v{new}"`. Both wired to `settings.installedModelVersion`. |
| 2 | Non-intrusive badge in Settings, no modal alerts or push notifications | ✓ VERIFIED | Inline pill via `Capsule()` in `updateAvailableRow`. D-08 enforces inline-only. No `Alert`, no `UserNotifications` import. Switch on `updateState` never presents a sheet. |
| 3 | User taps "Install Update," sees progress bar, can cancel; active model unaffected | VERIFIED (code) + human_needed (live download) | `downloadingRow` shows `ProgressView(value: progress)` + Cancel button -> `cancelDownload()`. `cancelCleanup` test passes: staging wiped, state restored to `.updateAvailable`, production dir untouched. |
| 4 | After completed update, app hot-swaps model without restarting | VERIFIED (code) + human_needed (live run) | `applySwap()` calls `reloadModels()` which nils then reloads ASR+VAD. `persistsVersion` test passes with no-op reload stub. `TranscriptionEngine.reloadModels()` exists with explicit nil-out at lines 94-95. |
| 5 | Partial or checksum-failing download rejected; prior model active; UI shows failure reason | ✓ VERIFIED | `checksumMismatchRollsBack` test passes: SHA mismatch -> `.failed`, staging deleted. `failedRow` renders `"⚠️ Update failed: {message}"` with Retry button. |

**Score:** 5/5 truths have verified backing code; 4 require human confirmation with live manifest. Machine-only verified: SC-2 (inline-only badge), SC-5 (checksum rejection).

### Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift` | ✓ VERIFIED | 646 lines; `@MainActor @Observable final class ModelUpdateService`; all state machine, download, apply, backfill methods present |
| `PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift` | ✓ VERIFIED | `modelAutoUpdateEnabled` with default-true presence-check logic at lines 147-151; `installedModelVersion` and `modelLastCheckedDate` also present |
| `PSTranscribe/Tests/PSTranscribeTests/MockURLProtocol.swift` | ✓ VERIFIED | URLProtocol subclass; `URLSession.mocked()` extension |
| `PSTranscribe/Tests/PSTranscribeTests/ModelManifestTests.swift` | ✓ VERIFIED | 6 tests including numeric compare cases |
| `PSTranscribe/Tests/PSTranscribeTests/ModelUpdateServiceTests.swift` | ✓ VERIFIED | 25 `@Test` declarations covering Plans 17-01 through 17-05 |
| `PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift` | ✓ VERIFIED | `Section("Speech Model")` after `Section("Updates")`; all 4 UI states; verbatim D-07/D-09/D-11/D-12/D-16 strings |
| `PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift` | ✓ VERIFIED | `@State private var modelUpdateService: ModelUpdateService`; constructed in `init()`; injected to SettingsView and ContentView |
| `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift` | ✓ VERIFIED | `sessionCoordinator.modelUpdate = modelUpdateService`; `bindTranscriptionEngine(transcriptionEngine)`; 10s auto-check Task |
| `PSTranscribe/Sources/PSTranscribe/App/SessionCoordinator.swift` | ✓ VERIFIED | `weak var modelUpdate: ModelUpdateService?`; `anySessionActive` aggregates `engine?.isRunning || modelUpdate?.isApplying` |
| `PSTranscribe/Sources/PSTranscribe/Transcription/TranscriptionEngine.swift` | ✓ VERIFIED | `func reloadModels() async throws` with `asrManager = nil; vadManager = nil` nil-out at lines 94-95 |
| `Scripts/generate-model-manifest.swift` | ✓ VERIFIED | Executable; shebang `#!/usr/bin/env swift`; CryptoKit SHA-256; walks `parakeet-tdt-0.6b-v3`; HuggingFace URL pattern |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `ModelUpdateService` | `AppSettings.installedModelVersion` + `modelLastCheckedDate` + `modelAutoUpdateEnabled` | `settings?.` reads + writes | ✓ WIRED | Lines 126, 139, 156, 468, 531-549 in ModelUpdateService.swift |
| `ModelUpdateService` | manifest URL (`raw.githubusercontent.com/.../model-manifest.json`) | `urlSession.data(for: URLRequest(url: modelManifestURL))` | ✓ WIRED | Line 176; no custom headers, no query params confirmed by grep |
| `ModelUpdateService` | `CryptoKit.SHA256` | incremental `update(data:)` per 64KB chunk | ✓ WIRED | Lines 334-368; `var hasher = SHA256()` + `hasher.update(data: buffer)` + `hasher.finalize()` |
| `ModelUpdateService` | `stagingDirectory` | `URLSession.bytes(for:)` + `FileHandle` writes | ✓ WIRED | `downloadFile()` function; `parakeet-tdt-0.6b-v3-staging` path |
| `ModelUpdateService` | `TranscriptionEngine.reloadModels()` | `transcriptionEngine?.reloadModels()` after atomic swap | ✓ WIRED | Line 450 in applySwap; late-bound via `bindTranscriptionEngine()` in ContentView.task |
| `ModelUpdateService` | `FileManager.moveItem` (atomic swap) | `modelDirectory` <- `stagingDirectory` | ✓ WIRED | Lines 422-443; note: `moveItem` (not `replaceItem` as planned -- intentional deviation, same atomicity via rename(2)) |
| `SessionCoordinator` | `ModelUpdateService.isApplying` | `modelUpdate?.isApplying` in `anySessionActive` | ✓ WIRED | SessionCoordinator.swift line 39; `trueWhenModelUpdateApplying` test passes |
| `SettingsView` | `ModelUpdateService.updateState` | `@Bindable var modelUpdateService` switch on `updateState` | ✓ WIRED | SettingsView.swift lines 426-448 |
| `SettingsView` | `ModelUpdateService.downloadAndApply / cancelDownload / checkForUpdate` | Button actions | ✓ WIRED | Lines 509, 524, 454; all three call sites present |
| `SettingsView` | `SPUUpdater.checkForUpdates()` | blocked-state button | ✓ WIRED | Line 537: `updater.checkForUpdates()` |
| `ContentView .task` | `ModelUpdateService.checkForUpdate(force: false)` | 10s delayed Task | ✓ WIRED | Lines 312-315: `Task.sleep(for: .seconds(10))` then `checkForUpdate(force: false)` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|-------------------|--------|
| `SettingsView.speechModelSectionContent` | `modelUpdateService.updateState` | `@Observable` ModelUpdateService; `checkForUpdate()` writes state | Yes (from manifest fetch; pre-publish returns .failed) | ✓ FLOWING |
| `SettingsView.upToDateRow` | `settings.installedModelVersion` | `AppSettings` reads from UserDefaults; `applySwap` writes on success | Yes | ✓ FLOWING |
| `SettingsView.updateAvailableRow` | `version`, `sizeBytes` from `.updateAvailable` enum case | Set by `checkForUpdate()` after manifest decode | Yes | ✓ FLOWING |
| `SettingsView.downloadingRow` | `progress`, `completed`, `total` from `.downloading` enum case | Set by `runDownload()` `onChunk` callback | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

Step 7b: SKIPPED for network-dependent checks (requires live manifest URL and real model download). Unit-test suite substitutes:

| Behavior | Test | Result |
|----------|------|--------|
| 24h throttle suppresses non-forced check | `throttleSuppressesNonForcedCheck` | ✓ PASS (55/55 suite) |
| `checkForUpdate` never calls `downloadAndApply` | `checkDoesNotDownload` | ✓ PASS |
| Checksum mismatch rolls back staging, state .failed | `checksumMismatchRollsBack` | ✓ PASS |
| Cancel wipes staging, restores .updateAvailable | `cancelCleanup` | ✓ PASS |
| Disk preflight blocks on insufficient space | `insufficientDiskSpace` | ✓ PASS |
| Atomic swap replaces production directory | `applySwapAtomicallyReplaces` | ✓ PASS |
| Version persisted after successful apply | `persistsVersion` | ✓ PASS |
| Reload failure rolls back swap | `failedReloadRollsBack` | ✓ PASS |
| Apply deferred while session active | `applyDoesNotProceedWithSessionActive` | ✓ PASS |
| D-14 backfill fires when all conditions met | `backfillFiresWhenAllConditionsMet` | ✓ PASS |

Full test run: 55/55 Phase 17 tests pass (`swift test --filter "ModelManifestTests|ModelUpdateServiceTests|AppSettingsTests|SessionCoordinatorTests"`).

### Requirements Coverage

| Requirement | Description | Implementation Evidence | Status |
|-------------|-------------|------------------------|--------|
| MODEL-01 | 24h throttle on auto-check | `modelCheckThrottleInterval` gate in `checkForUpdate`; `throttleSuppressesNonForcedCheck` test | ✓ SATISFIED |
| MODEL-02 | Non-intrusive badge, no modal/notification | Inline Capsule pill in `updateAvailableRow`; no Alert/UserNotifications; D-08 inline-only | ✓ SATISFIED |
| MODEL-03 | User explicitly initiates download | `downloadAndApply()` only called from button action; `checkDoesNotDownload` test passes | ✓ SATISFIED |
| MODEL-04 | Progress bar, cancellable download | `downloadingRow` with `ProgressView(value:)` + Cancel; `cancelCleanup` test | ✓ SATISFIED (UI human-needed) |
| MODEL-05 | Version persisted after update | `settings?.installedModelVersion = manifest.version` in `applySwap`; `persistsVersion` test | ✓ SATISFIED |
| MODEL-06 | Failed/partial downloads don't corrupt active model | Staging-only writes; SHA-256 verify; atomic swap; `checksumMismatchRollsBack` + `failedReloadRollsBack` tests | ✓ SATISFIED |
| MODEL-07 | Swap deferred during active session | `anySessionActiveProvider()` gate with 500ms poll; `isApplying` feeds back into `anySessionActive`; `applyDoesNotProceedWithSessionActive` test | ✓ SATISFIED |
| MODEL-08 | Settings shows installed vs available version | `upToDateRow` shows installed; `updateAvailableRow` shows both with arrow | ✓ SATISFIED (UI human-needed) |
| MODEL-09 | `min_app_version` gate blocks incompatible model | `minAppVersionBlockedRow` with Sparkle update button; `blockedByMinAppVersion` test | ✓ SATISFIED (UI human-needed) |
| MODEL-10 | Disk-space preflight | `checkDiskSpace(needed: total)` requiring 2x free space; `insufficientDiskSpace` test | ✓ SATISFIED (UI human-needed) |

**Note on MODEL-04:** The requirement mentions "reusing the existing v1.0 Phase 4 model onboarding download UI." The implementation uses a new inline progress row in SettingsView rather than the onboarding sheet UI. CONTEXT.md D-09 explicitly specifies inline determinate progress without a modal sheet, which supersedes the MODEL-04 phrasing. This is an intentional design decision documented in D-09.

### Anti-Patterns Found

Scan of modified files for stubs and placeholders:

| File | Pattern | Severity | Assessment |
|------|---------|---------|------------|
| `ModelUpdateService.swift` | None found | -- | Clean |
| `SettingsView.swift` | None found | -- | Clean |
| `ContentView.swift` | None found | -- | Clean |
| `SessionCoordinator.swift` | None found | -- | Clean |
| `AppSettings.swift` | None found | -- | Clean |

**Notable deviation (documented, not a gap):** `FileManager.moveItem` is used instead of `FileManager.replaceItem` for the atomic directory swap. This is documented in 17-03-SUMMARY.md as an auto-fixed bug: `replaceItem` silently drops the backup directory on APFS, making rollback impossible. `moveItem` uses `rename(2)` with the same atomicity guarantee. The plan's acceptance criterion grep `grep -q 'FileManager.default.replaceItem'` would fail -- but the implementation is more correct.

### Human Verification Required

The following items cannot be verified programmatically. All require the manifest URL to return HTTP 200 (i.e., the RELEASE PREREQUISITE must be satisfied first).

#### 1. Settings > Speech Model version display (SC-1)

**Test:** Publish the manifest, launch the app, open Settings > Speech Model.
**Expected:** Shows `Speech Model: v20260427 · Apr 27, 2026` with a green dot in the idle/upToDate state. After checking and a newer version is available, shows `Speech Model: v{old} → v{new}` with the Update available pill.
**Why human:** Requires a live HTTP 200 manifest response to exercise the `.upToDate` and `.updateAvailable` UI paths.

#### 2. Download progress and cancel (SC-3)

**Test:** With a live downloadable model update, click Install Update; observe progress bar; click Cancel.
**Expected:** Progress bar increments; Cancel restores the section to the updateAvailable state; the production model directory (`parakeet-tdt-0.6b-v3/`) is unchanged.
**Why human:** Requires a real multi-file download; `MockURLProtocol` delivers synchronously in tests.

#### 3. Hot-swap without restart (SC-4)

**Test:** Complete a full update cycle; immediately start a transcription session.
**Expected:** The transcription engine uses the new model files; no app restart required; `installedModelVersion` in UserDefaults reflects the new version.
**Why human:** Requires real FluidAudio model reload on the developer machine with real model files.

#### 4. Auto-check throttle and toggle gate (SC-2 partial, D-10, D-13)

**Test:** Toggle OFF, quit, relaunch; observe Console.app for `[ModelUpdate]` category; confirm no auto-check fires at +10s.
**Expected:** No manifest fetch activity in Console within 10s of launch when toggle is OFF.
**Why human:** Cannot inspect Console.app output programmatically in a unit test context.

### Gaps Summary

No implementation gaps were found. All code is substantive, wired, and tested. The `human_needed` status reflects the requirement for a live manifest (the RELEASE PREREQUISITE) to complete the end-to-end smoke test, not any missing implementation.

The only noteworthy deviation from the plans is the `moveItem` vs `replaceItem` swap -- this was an intentional bug fix documented in 17-03-SUMMARY.md and produces more correct behavior.

---

_Verified: 2026-04-27_
_Verifier: Claude (gsd-verifier)_
