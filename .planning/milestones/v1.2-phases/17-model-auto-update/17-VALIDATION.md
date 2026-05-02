---
phase: 17
slug: model-auto-update
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-27
---

# Phase 17 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (Swift 6+, `import Testing`, `@Suite`, `@Test`, `#expect`) |
| **Config file** | None — Swift Testing auto-discovers via `PSTranscribe/Tests/PSTranscribeTests/` |
| **Quick run command** | `cd PSTranscribe && swift test --filter ModelUpdate` |
| **Full suite command** | `cd PSTranscribe && swift test` |
| **Estimated runtime** | Quick ~5s · Full ~30–45s (53+ existing suites) |

---

## Sampling Rate

- **After every task commit:** Run `cd PSTranscribe && swift test --filter ModelUpdate`
- **After every plan wave:** Run `cd PSTranscribe && swift test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 45 seconds

---

## Per-Task Verification Map

> Plans 17-01 through 17-05 will fill specific task IDs during planning. Below is the requirement → suite map the planner must wire into per-task `<automated>` blocks.

| Req ID | Plan | Wave | Behavior | Test Type | Automated Command | File Exists | Status |
|--------|------|------|----------|-----------|-------------------|-------------|--------|
| MODEL-01 | 17-01 | 1 | 24h throttle gate for auto/opportunistic checks (`modelLastCheckedDate > 24h`) | unit | `swift test --filter ModelUpdateServiceTests/throttle` | ❌ W0 | ⬜ pending |
| MODEL-02 | 17-01 | 1 | Inline badge state — no modal, no notification dispatched | unit (state machine) | `swift test --filter ModelUpdateServiceTests/updateAvailableState` | ❌ W0 | ⬜ pending |
| MODEL-03 | 17-01 | 1 | `checkForUpdate` never auto-invokes `downloadAndApply` | unit | `swift test --filter ModelUpdateServiceTests/checkDoesNotDownload` | ❌ W0 | ⬜ pending |
| MODEL-04 | 17-02 | 2 | Determinate progress callbacks fire; cancel deletes staging directory | integration (`MockURLProtocol`) | `swift test --filter ModelUpdateServiceTests/downloadProgress` and `…/cancelCleanup` | ❌ W0 | ⬜ pending |
| MODEL-05 | 17-03 | 2 | `installedModelVersion` written to UserDefaults after successful apply | unit (mock filesystem) | `swift test --filter ModelUpdateServiceTests/persistsVersion` | ❌ W0 | ⬜ pending |
| MODEL-06 | 17-02, 17-03 | 2 | Bad SHA-256 rejects swap; production model untouched | unit | `swift test --filter ModelUpdateServiceTests/checksumMismatchRollsBack` | ❌ W0 | ⬜ pending |
| MODEL-07 | 17-03 | 2 | Apply deferred when `anySessionActive == true`; applies on session end | unit (mock SessionCoordinator) | `swift test --filter ModelUpdateServiceTests/deferredApplyOnSession` | ❌ W0 | ⬜ pending |
| MODEL-08 | 17-04 | 3 | Settings shows current vs available — manual UI verification | manual UI | See 17-VERIFICATION.md "Speech Model section visual states" | n/a | ⬜ pending |
| MODEL-09 | 17-01, 17-04 | 1+3 | `min_app_version` gate — blocked-state UX with `[Check for App Update]` | unit (state machine) + manual UI | `swift test --filter ModelUpdateServiceTests/blockedByMinAppVersion` | ❌ W0 | ⬜ pending |
| MODEL-10 | 17-02, 17-04 | 2+3 | Disk-space preflight blocks Install when `available < total*2` | unit (mock `URL.resourceValues`) | `swift test --filter ModelUpdateServiceTests/insufficientDiskSpace` | ❌ W0 | ⬜ pending |

**Cross-cutting test suites (planner must include in Wave 0):**
- `ModelManifestTests.swift` — Codable round-trip, version compare with `.numeric`, `min_app_version` gating logic. PURE unit — no I/O.
- `TranscriptionEngineReloadModelsTests.swift` — exercises `reloadModels()` against an actual on-disk model directory. Slow; gate behind `@Test(.tags(.integration))` so default `swift test` stays under 30s.

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Test infrastructure to land in Plan 17-01 (Wave 1, before any production code paths under test):

- [ ] `PSTranscribe/Tests/PSTranscribeTests/ModelUpdateServiceTests.swift` — covers MODEL-01..07, MODEL-09, MODEL-10
- [ ] `PSTranscribe/Tests/PSTranscribeTests/ModelManifestTests.swift` — Codable + version compare
- [ ] `PSTranscribe/Tests/PSTranscribeTests/MockURLProtocol.swift` — shared URLSession test helper (or inline in `ModelUpdateServiceTests` if no other suite needs it)
- [ ] `PSTranscribe/Tests/PSTranscribeTests/TranscriptionEngineReloadModelsTests.swift` — `@Test(.tags(.integration))` slow path
- [ ] No framework install needed — Swift Testing is built-in (Swift 6.2+)

---

## Manual-Only Verifications

Aspects that cannot be deterministically asserted in `swift test`. Each row must appear as a checklist item in `17-VERIFICATION.md` once execution begins.

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Speech Model section appears in Settings between Updates and (future) Dictation | MODEL-08, D-06 | SwiftUI snapshot infra not in repo; visual ordering | Open app → Settings → confirm "Speech Model" header sits below "Updates" and above the Form's end |
| Inline pill `Update available · ~520 MB` renders correctly | MODEL-02, D-07 | Visual rendering | Stub manifest with newer version → open Settings → confirm pill text matches `Speech Model: vXXX → vYYY` and shows size in MB |
| Determinate progress bar updates smoothly during real download | MODEL-04 | Real network jitter | Click `[Install Update]` against a real-network manifest → confirm progress moves monotonically; cancel mid-download → confirm `<repo>-staging/` deleted from `~/Library/Application Support/FluidAudio/Models/` |
| Hot-swap activates without restart | success criterion #4 | End-to-end flow | After completed update, start a transcription session → confirm `installedModelVersion` UserDefaults equals new version AND a transcription completes |
| Disk-space advisory appears with "Free up space" guidance | MODEL-10 | Requires low-disk environment or mock | Either fill volume to <1.1 GB free, or use unit test's mocked path; manual confirmation that the inline `[Free up space]` button suggests Finder open |
| `min_app_version` blocked state shows `[Check for App Update]` invoking Sparkle | MODEL-09, D-16 | Visual + Sparkle integration | Stub manifest with `min_app_version` higher than current `Bundle.main.shortVersion` → confirm UI shows blocked copy and Sparkle's `SPUUpdater.checkForUpdates()` fires when button tapped |
| First-run backfill silently sets `installedModelVersion` for v1.0→v1.2 upgraders | D-14 | UserDefaults state plus on-disk file presence | Clear `installedModelVersion` UserDefaults; ensure model files present on disk; relaunch; confirm UserDefaults populated without UI prompt |
| Manifest publication round-trip | D-03, release prereq | External repo write | Run `Scripts/generate-model-manifest.sh` (Plan 17-05); confirm output JSON parseable by `ModelManifest` Codable; commit to `cnewfeldt/ps-transcribe-releases:main` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (4 new test files + 1 helper)
- [ ] No watch-mode flags (`swift test` only, no `--continuous`)
- [ ] Feedback latency < 45s
- [ ] `nyquist_compliant: true` set in frontmatter once plans land

**Approval:** pending
