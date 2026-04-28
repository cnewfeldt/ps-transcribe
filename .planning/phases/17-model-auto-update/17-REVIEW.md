---
phase: 17-model-auto-update
reviewed: 2026-04-27T00:00:00Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift
  - PSTranscribe/Sources/PSTranscribe/App/SessionCoordinator.swift
  - PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift
  - PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift
  - PSTranscribe/Sources/PSTranscribe/Transcription/TranscriptionEngine.swift
  - PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift
  - PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift
  - PSTranscribe/Tests/PSTranscribeTests/AppSettingsTests.swift
  - PSTranscribe/Tests/PSTranscribeTests/MockURLProtocol.swift
  - PSTranscribe/Tests/PSTranscribeTests/ModelManifestTests.swift
  - PSTranscribe/Tests/PSTranscribeTests/ModelUpdateServiceTests.swift
  - PSTranscribe/Tests/PSTranscribeTests/SessionCoordinatorTests.swift
  - PSTranscribe/Tests/PSTranscribeTests/TestTags.swift
  - PSTranscribe/Tests/PSTranscribeTests/TranscriptionEngineReloadModelsTests.swift
  - Scripts/generate-model-manifest.swift
findings:
  critical: 0
  warning: 4
  info: 8
  total: 12
status: issues_found
---

# Phase 17: Code Review Report

**Reviewed:** 2026-04-27T00:00:00Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

Phase 17's model auto-update pipeline is implemented at a high standard. Concurrency boundaries are well thought through (single MainActor isolation across the service, cancellation correctly propagated via `Task.checkCancellation()` and `URLError.cancelled`, weak captures in stored providers), the rollback path is symmetric and well-tested, and the test surface is thorough — covering happy path, checksum mismatch, disk-space gate, path traversal, cancel mid-download, session-active deferral, D-14 backfill, and prior failed-staging rotation.

The intentional `moveItem` use over `replaceItem` is correctly applied (the directory replacement semantics differ — `replaceItem` is documented to drop the backup item on directories, breaking rollback). The hardcoded manifest URL and HTTPS+GitHub trust model align with D-04 (no EdDSA, no telemetry headers).

Findings below are mostly Warning and Info — defensive gaps and minor quality items rather than correctness bugs. No Critical issues found.

## Warnings

### WR-01: `downloadFile` accepts but never verifies `expectedSize`

**File:** `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift:317-370`
**Issue:** `downloadFile` takes an `expectedSize: Int64` parameter (passed `file.size` from the manifest) but never compares `bytesWritten` against it after the stream completes. The SHA-256 check would normally catch a truncated or padded file, but there are two edge cases worth defending against:
1. A server that returns a different body than the manifest declares but for which the manifest sha256 was computed incorrectly during release tooling — size mismatch is a cheaper, earlier signal than a SHA mismatch on multi-GB files.
2. The progress UI reports `completedBytes / total_size_bytes` based on cumulative `bytesWritten`. If a file's actual size differs from declared, progress > 1.0 is possible (math handled by `max(total, 1)`, but display goes weird).

**Fix:**
```swift
// After the loop, before computing digest:
guard bytesWritten == expectedSize else {
    throw ModelUpdateError.httpError(
        url: url.absoluteString,
        statusCode: 0
    )  // Or add a dedicated .sizeMismatch case
}
```

### WR-02: `applySwap` has no cancellation checkpoints; cancel during `.applying` is silently ignored

**File:** `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift:397-473`
**Issue:** `applySwap` runs synchronously through the directory swap and reload steps with no `try Task.checkCancellation()` calls. The session-end wait loop (lines 399-401) uses `try? await Task.sleep(...)` which swallows cancellation entirely. While the SettingsView's Cancel button is only rendered during `.downloading` (so this isn't a UI bug today), the deferral loop can spin indefinitely if a session never ends and there is no escape hatch. A future Phase 18 (hotkey dictation) interleaving could keep `anySessionActive` true for arbitrarily long.

**Fix:** Replace the `try?` with proper cancellation propagation, and add a checkpoint before each destructive move:
```swift
while anySessionActiveProvider() {
    try await Task.sleep(for: .milliseconds(500))  // propagate cancel
}
try Task.checkCancellation()
isApplying = true
defer { isApplying = false }
// ...before each moveItem call:
try Task.checkCancellation()
```
And mark `applySwap` as `throws` (the existing call site in `downloadAndApply` already lives inside a do/catch block).

### WR-03: `generate-model-manifest.swift` silently records size 0 on `fileSize` lookup failure

**File:** `Scripts/generate-model-manifest.swift:127`
**Issue:**
```swift
let size = (try leaf.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
```
If `fileSize` returns nil (filesystem error, dangling symlink, race with deletion), this records the file as 0 bytes in the manifest. Downstream clients would compute `total_size_bytes` short, fail the disk-space preflight incorrectly (too lenient), and the download progress denominator would be wrong. Worse, the SHA would still pass for any actual content, masking the size error end-to-end.

**Fix:**
```swift
guard let rawSize = try leaf.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
    FileHandle.standardError.write(
        "ERROR: could not read size for \(leaf.path)\n".data(using: .utf8) ?? Data()
    )
    exit(1)
}
let size = Int64(rawSize)
```

### WR-04: `waitForSessionEnd` is dead code, but its existence suggests a refactor was abandoned mid-flight

**File:** `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift:475-481`
**Issue:** `private func waitForSessionEnd() async` is declared but never called — `applySwap` inlines an identical poll loop at lines 399-401. The risk: a future maintainer fixes the inline loop (e.g., per WR-02) but forgets to update `waitForSessionEnd`, or vice versa, leading to behavior drift. Given the comment at line 476 ("Called by applySwap when a session is active at apply time (D-19)") which is factually wrong, this is also documentation rot.

**Fix:** Either delete the dead helper, or refactor `applySwap` to call it (preferred, as it would centralize the cancellation-propagation fix from WR-02):
```swift
private func waitForSessionEnd() async throws {
    while anySessionActiveProvider() {
        try await Task.sleep(for: .milliseconds(500))
    }
}
// In applySwap:
try await waitForSessionEnd()
```

## Info

### IN-01: `downloadFile` byte-by-byte iteration is O(n) Swift overhead per byte

**File:** `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift:339-350`
**Issue:** `for try await byte in bytes` iterates one byte at a time, appending each to a `Data` buffer. For a ~545 MB model that's >500 million async-iteration suspensions plus 500M `buffer.append(byte)` calls before each 64 KB flush. The `URLSession.bytes` API exposes `AsyncBytes.lines` and similar, but for raw bytes the idiomatic pattern is collecting in larger chunks. Performance is explicitly out of v1 scope, so logging this as Info — but it's worth knowing for v1.3.

**Fix:** Consider switching to the `download` task API (`URLSession.download(for:)`) which writes to a tmp file natively and gives URLSession control over chunk granularity. Then SHA-256 the file via a single FileHandle pass. Out of v1 scope.

### IN-02: `MainActor.run { onChunk(snapshot) }` is redundant

**File:** `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift:347, 358`
**Issue:** `downloadFile` is implicitly `@MainActor` (called from MainActor-isolated `runDownload`/`downloadAndApply`). The `onChunk` parameter is annotated `@MainActor @Sendable`. Wrapping the call in `await MainActor.run` adds a needless suspension hop on every chunk.
**Fix:** Replace `await MainActor.run { onChunk(snapshot) }` with just `onChunk(snapshot)`. The closure is already MainActor-isolated, no hop needed.

### IN-03: Duplicated ISO8601 timestamp construction across rollback/forensics paths

**File:** `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift:413-414, 499-500, 513-514`
**Issue:** The same three-line ISO8601 timestamp (with colon stripping) appears in `applySwap`, `rollbackSwap`, and `moveStagingToFailed`. Easy to drift if format requirements change.
**Fix:** Extract:
```swift
private static func forensicTimestamp() -> String {
    ISO8601DateFormatter().string(from: Date())
        .replacingOccurrences(of: ":", with: "")
}
```

### IN-04: Path-traversal guard rejects legitimate filenames containing `..`

**File:** `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift:283`
**Issue:**
```swift
guard !file.name.contains(".."), !file.name.hasPrefix("/") else { ... }
```
This rejects any filename containing `..` anywhere — e.g., `weights..bin`, `model.v1..final.mlmodelc/data.bin`. The intent is to block the path component `..` (parent dir traversal). Today's manifest has no such names, so the guard works in practice, but a more precise check resists false positives if naming conventions evolve.
**Fix:**
```swift
let components = file.name.split(separator: "/")
guard !components.contains(".."), !file.name.hasPrefix("/") else {
    throw ModelUpdateError.httpError(url: file.url, statusCode: 0)
}
```
Also consider validating the resolved destination path stays within `stagingDirectory` after `appendingPathComponent` + `standardized`:
```swift
let destination = stagingDirectory.appendingPathComponent(file.name).standardized
guard destination.path.hasPrefix(stagingDirectory.standardized.path) else { throw ... }
```

### IN-05: `httpError(statusCode: 0)` overloaded for both URL parse failure and path traversal

**File:** `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift:284, 288`
**Issue:** Both the path-traversal guard and the `URL(string: file.url)` failure throw `ModelUpdateError.httpError(url: file.url, statusCode: 0)`. The user-facing message becomes "HTTP error 0 while downloading model." which is misleading for both cases (no HTTP exchange happened). Minor diagnostic noise.
**Fix:** Add dedicated cases (e.g., `.invalidManifestEntry(name: String, reason: String)`) or use `swapFailed` / a new `.invalidPath`.

### IN-06: `ContentView`'s 10s post-launch check task is unbound to view lifecycle

**File:** `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift:312-315`
**Issue:** A bare `Task { @MainActor in try? await Task.sleep(...); await modelUpdateService.checkForUpdate(force: false) }` is fired inside a `.task {}` block. The outer .task completes immediately after spawning, so this inner task is detached from view lifecycle and outlives the view. In practice the view is the only window of the app and this is harmless, but it's a small sharp edge — if ContentView ever gets recreated, you'd schedule duplicate checks.
**Fix:** Move the sleep into the same outer `.task { }` block (so it gets cancelled if the view goes away), or call it from `PSTranscribeApp.init` / `.onAppear` at app scope.

### IN-07: Unused locals and `_ = manifestURL` test plumbing

**File:** `PSTranscribe/Tests/PSTranscribeTests/ModelUpdateServiceTests.swift:720, 749`
**Issue:** The `pathTraversalRejected` test has `_ = manifestURL // silence unused warning` and `_ = etcPasswd` at the end. This is symptomatic of code written speculatively (planning to use the variable, then not). Minor cleanup opportunity.
**Fix:** Delete `manifestURL` (the responder doesn't dispatch by URL — it just returns the manifest for any request). Delete `etcPasswd` and its trailing `_ =`.

### IN-08: `installedAppVersion` defaults to `""` on missing CFBundleShortVersionString — masks bundle problem

**File:** `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift:99-101`
**Issue:**
```swift
self.installedAppVersion = appVersion
    ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
    ?? ""
```
If the bundle key is missing (corrupt build), every manifest will compare `"".compare(min_app_version)` as `.orderedAscending` → `.blocked(.minAppVersion(...))`, so users see "Install update" blocked indefinitely with no clue why. Probably not a real-world issue, but worth a `log.error` if the fallback fires.
**Fix:**
```swift
if appVersion == nil,
   (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) == nil {
    log.error("CFBundleShortVersionString missing from main bundle; installedAppVersion defaulted to \"\" — all model updates will be blocked")
}
```

---

_Reviewed: 2026-04-27T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
