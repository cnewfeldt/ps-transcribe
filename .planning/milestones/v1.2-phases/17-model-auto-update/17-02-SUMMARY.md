---
phase: 17
plan: 02
subsystem: model-auto-update
tags: [swift, download, cryptokit, sha256, cancellation, disk-space, staging, tdd, wave-2]
dependency_graph:
  requires: [17-01-ModelUpdateService-skeleton]
  provides: [downloadAndApply-body, cancelDownload-body, stagingDirectory, diskSpaceProvider, modelsRootOverride]
  affects: [ModelUpdateService, ModelUpdateServiceTests]
tech_stack:
  added: [CryptoKit.SHA256 incremental hashing, URLSession.bytes streaming, FileHandle chunk writes]
  patterns: [TDD red-green, semaphore-blocked mock responder for cancel determinism, injectable closures for disk-space + models root]
key_files:
  modified:
    - PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift
    - PSTranscribe/Tests/PSTranscribeTests/ModelUpdateServiceTests.swift
decisions:
  - "URLError.cancelled treated as user-initiated cancel alongside CancellationError -- URLSession throws URLError when its task is cancelled via Swift Concurrency Task cancellation"
  - "Semaphore-blocked mock responder used in cancelCleanup test for deterministic cancel timing -- synchronous MockURLProtocol delivers all bytes instantly so a semaphore blocks between files"
  - "diskSpaceProvider injectable closure defaults to real volumeAvailableCapacityForImportantUsageKey lookup; tests inject { _ in 100 } for low-disk simulation"
  - "modelsRootOverride sandboxes all file I/O to a temp directory in tests -- avoids touching real ~/Library/Application Support/FluidAudio/Models/"
  - "Path traversal guard in runDownload rejects any manifest file name containing '..' or starting with '/' (T-17-02-05)"
  - "7th test pathTraversalRejected added per threat model T-17-02-05 verification requirement"
metrics:
  duration_minutes: 5
  completed_date: "2026-04-28"
  tasks_completed: 2
  tasks_total: 2
  files_created: 0
  files_modified: 2
  tests_added: 7
  tests_total: 99
requirements-completed: [MODEL-04, MODEL-06, MODEL-10]
---

# Phase 17 Plan 02: Download Pipeline Summary

**One-liner:** Streaming URLSession.bytes download pipeline with incremental CryptoKit SHA-256, 64KB chunk buffering, Task-cancellation-driven staging cleanup, disk-space preflight, and path-traversal guard -- all verified by 7 new GREEN tests.

## What Was Built

### downloadAndApply() -- full body

- Guards on `.updateAvailable` state; re-fetches manifest to get per-file details
- Disk-space preflight via `checkDiskSpace(needed:)` -- uses `volumeAvailableCapacityForImportantUsageKey`, requires `needed * 2` free bytes (staging + production coexistence)
- Wipes any pre-existing staging directory (clean slate for retry)
- Emits `.downloading(progress: 0, completedBytes: 0, totalBytes:)` before spawning download task
- Spawns `downloadTask: Task<Void, Error>` so `cancelDownload()` can target it
- On success: sets `updateState = .verifying` (Plan 17-03 takes over for atomic swap)
- On `CancellationError` or `URLError.cancelled`: wipes staging, restores `.updateAvailable` for retry
- On any other error: wipes staging, sets `.failed(message:)`

### cancelDownload()

- Calls `downloadTask?.cancel()` only; state transition and cleanup happen in `downloadAndApply`'s catch block
- Does NOT directly mutate state (avoids double-transition races)

### runDownload(_ manifest:)

- Iterates `manifest.files`; calls `Task.checkCancellation()` at top of each file
- T-17-02-05 path-traversal guard: rejects any `file.name` containing `".."` or starting with `"/"`
- Resolves destination to `stagingDirectory.appendingPathComponent(file.name)` with `createDirectory(withIntermediateDirectories: true)`
- Calls `downloadFile(from:to:expectedSize:expectedSHA256:onChunk:)` per file
- `onChunk` closure accumulates `completedBytes` across files and emits `.downloading` state updates

### downloadFile(from:to:expectedSize:expectedSHA256:onChunk:)

- Uses `URLSession.bytes(for:)` for streaming (not `dataTask`)
- Verifies HTTP 200..299; throws `httpError` otherwise
- Creates file at destination via `FileManager.createFile` + `FileHandle(forWritingTo:)`
- Buffers in 64KB chunks: `write + SHA256.update + MainActor.run { onChunk }` per flush
- Calls `Task.checkCancellation()` at top of each byte loop iteration
- On stream end: finalizes `SHA256.finalize()`, compares hex (case-insensitive); throws `checksumMismatch` on mismatch
- `defer { try? handle.close() }` ensures handle is always released

### checkDiskSpace(needed:)

- Uses injectable `diskSpaceProvider: @Sendable (URL) throws -> Int64` closure
- Required = `needed * 2` (staging + production directory coexistence during swap window)
- Throws `ModelUpdateError.insufficientDiskSpace(needed:available:)` when insufficient

### wipeStaging()

- Best-effort `try FileManager.default.removeItem(at: stagingDirectory)` (idempotent -- checks `fileExists` first)

### Computed URLs

- `modelsRoot`: uses `modelsRootOverride` when set (test injection), otherwise `~/Library/Application Support/FluidAudio/Models/`
- `modelDirectory`: `modelsRoot/parakeet-tdt-0.6b-v3` (no `-coreml` suffix per RESEARCH Pitfall #2)
- `stagingDirectory`: `modelsRoot/parakeet-tdt-0.6b-v3-staging`

### New Tests (all GREEN)

| Test | What it verifies |
|------|-----------------|
| `downloadProgress` | `.verifying` state + staging files present after success |
| `downloadFileWritesToStagingPath` | Per-file path inside staging dir (including subdirectory names) |
| `cancelCleanup` | Staging wiped + state restored to `.updateAvailable` after cancel |
| `checksumMismatchRollsBack` | Bad SHA causes `.failed` + staging deleted + production dir untouched |
| `insufficientDiskSpace` | `diskSpaceProvider = { _ in 100 }` triggers `.blocked(.insufficientDiskSpace(...))` |
| `progressIsMonotonic` | Progress values only increase across all `.downloading` states observed |
| `pathTraversalRejected` | `../../../etc/passwd` filename causes `.failed`; staging does not escape sandbox |

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 -- RED tests | `45d8bd9` | 7 failing tests + stub property declarations (modelsRootOverride, diskSpaceProvider) |
| 2 -- GREEN implementation | `477ca04` | Full downloadAndApply pipeline; all 7 tests GREEN; 99/99 suite passing |

## Test Results

```
Test run with 99 tests in 16 suites passed
```

- ModelUpdateServiceTests: 15/15 (8 from Plan 17-01 + 7 new)
- Full suite: 99/99

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] URLError.cancelled not caught by `catch is CancellationError`**
- **Found during:** Task 2 -- `cancelCleanup` test was landing in `.failed(message: "cancelled")` instead of `.updateAvailable`
- **Issue:** When Swift Concurrency Task cancellation propagates to a URLSession.bytes stream, URLSession throws `URLError(.cancelled)` (not `CancellationError`). The plan's sample code only caught `CancellationError`.
- **Fix:** Unified catch block checks `error is CancellationError || (error as? URLError)?.code == .cancelled || downloadTask?.isCancelled == true`
- **Files modified:** `ModelUpdateService.swift`
- **Commit:** `477ca04`

**2. [Rule 1 - Bug] Synchronous MockURLProtocol made cancelCleanup non-deterministic**
- **Found during:** Task 2 -- cancellation fired after download completed (no in-flight window with synchronous mock)
- **Issue:** MockURLProtocol delivers all bytes synchronously in `startLoading()`. With 5 small files, all complete before `Task.yield()` lets the cancel fire.
- **Fix:** Redesigned test to use a `DispatchSemaphore` blocking the second file's responder. Test calls `cancelDownload()` then signals the semaphore, guaranteeing cancel lands before the second file returns.
- **Files modified:** `ModelUpdateServiceTests.swift`
- **Commit:** `477ca04`

## Plan 17-03 Callout

`<repo>-staging/` is populated and SHA-256 verified when `updateState == .verifying`. Plan 17-03 takes ownership from this state to perform the atomic `replaceItem` swap, call `TranscriptionEngine.reloadModels()`, and update `AppSettings.installedModelVersion`. The `modelDirectory` and `stagingDirectory` computed properties are already accessible (Plan 17-03 can read them via the same `modelsRootOverride` injection point for its swap-rollback tests).

## Known Stubs

None -- all stub bodies from Plan 17-01 have been filled.

## Threat Surface Scan

All T-17-02 mitigations implemented and verified:

| Threat | Status |
|--------|--------|
| T-17-02-01 Tampering (in-flight bytes) | SHA-256 verified per file; mismatch wipes staging, `.failed` state |
| T-17-02-02 DoS (partial download) | Staging-only writes; any error wipes staging; production untouched |
| T-17-02-03 DoS (disk exhaustion) | `volumeAvailableCapacityForImportantUsage * 2` preflight; `.blocked` on insufficient |
| T-17-02-04 Info Disclosure (telemetry) | `URLRequest(url:)` only; no headers, no query params; verified by grep |
| T-17-02-05 Tampering (path traversal) | `runDownload` rejects `".."` and `/`-prefixed names; `pathTraversalRejected` test passes |
| T-17-02-06 Repudiation (silent failure) | Only `wipeStaging` and `handle.close` use `try?`; all download errors propagate to `.failed` |
| T-17-02-07 DoS (infinite file / slow-loris) | 64KB max buffer; disk preflight bounds total; SHA mismatch catches size lies |
| T-17-02-08 EoP (cancel mid-swap) | No swap in this plan; cancel only touches staging |

## Self-Check: PASSED

| Item | Result |
|------|--------|
| PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift | FOUND |
| PSTranscribe/Tests/PSTranscribeTests/ModelUpdateServiceTests.swift | FOUND |
| Commit 45d8bd9 (RED tests) | FOUND |
| Commit 477ca04 (GREEN implementation) | FOUND |
| Full test suite: 99/99 passing | VERIFIED |
| import CryptoKit in service | VERIFIED |
| urlSession.bytes in service | VERIFIED |
| SHA256() in service | VERIFIED |
| volumeAvailableCapacityForImportantUsage in service | VERIFIED |
| parakeet-tdt-0.6b-v3-staging in service | VERIFIED |
| modelsRootOverride in service | VERIFIED |
| Task.checkCancellation in service | VERIFIED |
| No -coreml in directory paths | VERIFIED |
| No telemetry surface | VERIFIED |
| No Package.swift/Package.resolved changes | VERIFIED |
