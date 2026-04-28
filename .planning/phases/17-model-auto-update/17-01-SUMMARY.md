---
phase: 17
plan: 01
subsystem: model-auto-update
tags: [swift, testing, app-settings, model-update, wave-0]
dependency_graph:
  requires: [phase-16-foundation]
  provides: [ModelUpdateService-skeleton, MockURLProtocol, ModelManifest-codable, modelAutoUpdateEnabled-key]
  affects: [AppSettings, SessionCoordinator (future 17-02), SettingsView (future 17-04)]
tech_stack:
  added: [Services/ directory, Swift Testing suite for model update]
  patterns: [URLProtocol mock injection, appVersion injectable init, didSet UserDefaults mirroring]
key_files:
  created:
    - PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift
    - PSTranscribe/Tests/PSTranscribeTests/MockURLProtocol.swift
    - PSTranscribe/Tests/PSTranscribeTests/ModelManifestTests.swift
    - PSTranscribe/Tests/PSTranscribeTests/ModelUpdateServiceTests.swift
  modified:
    - PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift
    - PSTranscribe/Tests/PSTranscribeTests/AppSettingsTests.swift
decisions:
  - "Injected appVersion into ModelUpdateService.init() for test determinism; Bundle.main.shortVersionString returns empty string in test runner"
  - "modelAutoUpdateEnabled default-true uses object(forKey:) presence check, not bool(forKey:) which returns false for missing keys"
metrics:
  duration_minutes: 35
  completed_date: "2026-04-28"
  tasks_completed: 3
  tasks_total: 3
  files_created: 4
  files_modified: 2
  tests_added: 17
  tests_total: 92
---

# Phase 17 Plan 01: ModelUpdateService Skeleton + Wave 0 Test Infrastructure Summary

**One-liner:** ModelUpdateService @Observable @MainActor class with manifest fetch, numeric version compare, 24h throttle, min_app_version gate, and full Wave 0 test infrastructure (MockURLProtocol + 14 new Swift Testing tests).

## What Was Built

### ModelUpdateService (new Services/ directory)
- `@MainActor @Observable final class ModelUpdateService` at `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift`
- `checkForUpdate(force:)` implements the full check state machine: disabled-flag gate (D-13), 24h throttle gate (MODEL-01), manifest fetch, `min_app_version` gate (MODEL-09/D-16), version comparison (MODEL-02/D-17)
- `fetchManifest()` uses `URLSession` with no custom headers, no query params, no User-Agent override (D-04 hard telemetry constraint)
- All version comparisons use `String.compare(_:options:.numeric)` (D-17) -- correctly handles `"1.10.0" > "1.2.0"`
- `downloadAndApply()` and `cancelDownload()` are stubs (Plan 17-02 lands their bodies)
- `appVersion` injectable via `init(appVersion:)` for test determinism (Bundle.main returns empty string in test runner)
- Manifest URL hardcoded: `https://raw.githubusercontent.com/cnewfeldt/ps-transcribe-releases/main/model-manifest.json` (D-01)

### ModelUpdateState + enums
- `ModelUpdateState`: 10 cases -- `.idle`, `.checking`, `.upToDate(asOf:)`, `.updateAvailable(version:sizeBytes:releasedAt:)`, `.blocked(reason:)`, `.downloading(progress:completedBytes:totalBytes:)`, `.verifying`, `.applying`, `.applied(version:)`, `.failed(message:)`
- `BlockedReason`: `.minAppVersion(required:installed:newModelVersion:)`, `.insufficientDiskSpace(needed:available:)`
- `ModelUpdateError`: 8 cases with `LocalizedError` descriptions
- `ModelManifest`: Codable/Sendable/Equatable with nested `ManifestFile`; snake_case property names match JSON keys directly

### AppSettings.modelAutoUpdateEnabled (Phase 17 D-11)
- New `var modelAutoUpdateEnabled: Bool` with `didSet` UserDefaults mirroring (key `"modelAutoUpdateEnabled"`)
- Default `true` using `object(forKey:) == nil` presence check -- `bool(forKey:)` returns `false` for missing keys, which would incorrectly default to disabled

### Wave 0 Test Infrastructure
- `MockURLProtocol`: URLProtocol subclass; `nonisolated(unsafe) static var responder`; `URLSession.mocked()` convenience extension
- `ModelManifestTests` (6 tests): Codable round-trip with/without `released_at`, numeric compare for dotted versions, date-shaped versions, mixed shapes, empty-older-than-anything
- `ModelUpdateServiceTests` (8 active tests): `initialStateIsIdle`, `updateAvailableState`, `checkDoesNotDownload`, `blockedByMinAppVersion`, `throttleSuppressesNonForcedCheck`, `forcedCheckBypassesThrottle`, `disabledFlagSuppressesAutoCheck`, `disabledFlagDoesNotSuppressForcedCheck`
- `AppSettingsTests` additions (3 tests): `modelAutoUpdateEnabled_defaultsTrue`, `roundTrip_modelAutoUpdateEnabledFalse`, `roundTrip_modelAutoUpdateEnabledRestoresTrue`

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 -- Wave 0 test infrastructure | `4e0ccbe` | MockURLProtocol, ModelManifestTests (6), ModelUpdateServiceTests (8) |
| 2 -- ModelUpdateService skeleton | `44fba6b` | ModelUpdateService class, enums, state machine, manifest fetch |
| 3 -- AppSettings key | `2d2fe23` | modelAutoUpdateEnabled with default-true logic + 3 AppSettings tests |

## Test Results

```
Test run with 92 tests in 16 suites passed
```

- ModelManifestTests: 6/6
- ModelUpdateServiceTests: 8/8
- AppSettingsTests (including 3 new): 16/16
- Full suite: 92/92

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] appVersion injectable via init for test determinism**
- **Found during:** Task 2 verification -- `updateAvailableState` test was landing in `.blocked(.minAppVersion(...))` instead of `.updateAvailable` because `Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")` returns `""` in the Swift test runner (not the app bundle)
- **Issue:** With empty `installedAppVersion`, `"".compare("1.0.0", .numeric) == .orderedAscending`, triggering the min_app_version block on every test that didn't use `"99.0.0"` as the requirement
- **Fix:** Added `appVersion: String? = nil` parameter to `ModelUpdateService.init()`; defaults to Bundle.main value at production; tests inject `appVersion: "2.1.1"` (matching Info.plist) to make comparisons deterministic
- **Files modified:** `ModelUpdateService.swift`, `ModelUpdateServiceTests.swift`
- **Commit:** `44fba6b`

**2. [Rule 1 - Bug] User-Agent string in doc comment triggered acceptance grep**
- **Found during:** Task 2 acceptance checks -- `! grep -q 'User-Agent'` failed because the doc comment at the top of the file contained the string "NO User-Agent"
- **Fix:** Replaced "NO User-Agent" in the header comment with "no custom request headers" (equivalent meaning, grep-safe)
- **Files modified:** `ModelUpdateService.swift`
- **Commit:** `44fba6b`

## Plan 17-02 Callout

`MockURLProtocol` is now available in the test bundle. Plan 17-02 can use it directly for `URLSession.bytes(for:delegate:)` integration tests covering download progress, cancellation, and checksum verification. The stub comments in `ModelUpdateServiceTests.swift` mark exactly where Plan 17-02/17-03 tests should be added.

## Known Stubs

| Stub | File | Reason |
|------|------|--------|
| `downloadAndApply()` body | `ModelUpdateService.swift:126` | Plan 17-02 lands the download + verify + swap logic |
| `cancelDownload()` body | `ModelUpdateService.swift:131` | Plan 17-02 lands the cancellation + cleanup logic |

These stubs are intentional and documented -- Plan 17-02 fills them without any scaffolding changes needed.

## Threat Surface Scan

No new threat surface beyond what the plan's threat model covers. All trust boundary mitigations are in place:

- T-17-01-01 (manifest tampering): HTTPS + JSONDecoder throws on malformed JSON → `.failed` state
- T-17-01-02 (telemetry/fingerprinting): verified by grep -- no `setValue(_:forHTTPHeaderField:)`, no `URLQueryItem`, no `User-Agent` in source
- T-17-01-04 (min_app_version bypass): numeric compare enforced, verified by `numericCompareDottedVersions` test
- T-17-01-05 (downloadAndApply auto-invocation): `checkDoesNotDownload` test asserts no download states reached

## Self-Check: PASSED

All created files exist on disk. All task commits confirmed in git log.

| Item | Result |
|------|--------|
| PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift | FOUND |
| PSTranscribe/Tests/PSTranscribeTests/MockURLProtocol.swift | FOUND |
| PSTranscribe/Tests/PSTranscribeTests/ModelManifestTests.swift | FOUND |
| PSTranscribe/Tests/PSTranscribeTests/ModelUpdateServiceTests.swift | FOUND |
| Commit 4e0ccbe (Wave 0 test infrastructure) | FOUND |
| Commit 44fba6b (ModelUpdateService skeleton) | FOUND |
| Commit 2d2fe23 (AppSettings modelAutoUpdateEnabled) | FOUND |
| Full test suite: 92/92 passing | VERIFIED |
