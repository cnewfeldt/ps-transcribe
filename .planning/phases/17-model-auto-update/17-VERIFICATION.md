# Phase 17 Verification -- Model Auto-Update

**Phase:** 17-model-auto-update
**Started:** 2026-04-27
**Status:** code-complete; release smoke deferred

## Success Criteria (from ROADMAP.md Phase 17)

- [ ] **SC-1:** User opens Settings > Model and sees the currently installed model version string alongside the latest available version
- [ ] **SC-2:** When a newer model is available, a non-intrusive badge appears in Settings > Model with no modal alerts or push notifications
- [ ] **SC-3:** User taps "Install Update," sees a progress bar, and can cancel mid-download; the active model is unaffected by a cancelled download
- [ ] **SC-4:** After a completed update, the app hot-swaps the model without restarting; the next transcription session uses the new model
- [ ] **SC-5:** A partial or checksum-failing download is rejected; the prior model remains active and the UI surfaces a clear failure reason

## Requirement Coverage (MODEL-01..10)

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

## Manual Smoke Test (Plan 17-04 Task 3)

Record the result of the 9-state checklist (A through I). To be filled in by the executor.

**Status from Plan 17-04:** Partially verified. Full end-to-end verification deferred to post-Plan-17-05 (manifest must be live).

**User response (2026-04-27):** `approved` -- 404 on manifest fetch acknowledged as expected pre-17-05 state.

### Checklist Results

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

## Plan 17-05 Backfill Smoke Test

**Unit-level verification (2026-04-27):** PASSED — `swift test --filter "backfill"` runs 5 tests in `ModelUpdateServiceTests` and all pass:
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

## Manifest Generation Script Smoke Test (Plan 17-05 Task 4 / B)

**Verified 2026-04-27:** PASSED — `swift scripts/generate-model-manifest.swift --version=20260427 --min-app=1.2.0` produced a manifest with:
- 23 files (≥ 5 expected)
- `total_size_bytes`: 483,254,213 (~480-520 MB expected range)
- First entry SHA256: `4238c4e81ecd0dc94bd7dfbb60f7e2cc824107c1ffe0387b8607b72833dba350` (64-char hex)
- First entry name: `Decoder.mlmodelc/analytics/coremldata.bin` (proper leaf-file path)
- `model_id`: `parakeet-tdt-0.6b-v3-coreml`

## RELEASE PREREQUISITE -- Manifest Publication

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

## Build & Test Verification

**Verified 2026-04-27 post-Plan-17-05:**
- [x] `cd PSTranscribe && swift build` exits 0 — clean build
- [x] `cd PSTranscribe && swift test` exits 0 — 114 tests in 17 suites pass
- [ ] `cd PSTranscribe && swift test --filter TranscriptionEngineReloadModelsTests` exits 0 (integration suite, deferred — requires CoreML runtime in CI)
- [x] `! git diff --name-only HEAD | grep -E 'Package\.(swift|resolved)$'` — PASS, no Package.swift changes
- [x] `! grep -E 'setValue.*forHTTPHeaderField|User-Agent|queryItems' PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift` — PASS, no telemetry

---

*Phase 17 verification: code-complete. Deterministic gates pass. End-to-end UI/UX smoke test deferred to release-tag verification once manifest is published per the RELEASE PREREQUISITE section above.*
