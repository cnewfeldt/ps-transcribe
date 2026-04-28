# Phase 17: Model Auto-Update - Research

**Researched:** 2026-04-27
**Domain:** macOS native app — out-of-band ASR model update channel (separate from Sparkle)
**Confidence:** HIGH on Swift 6 concurrency patterns, CryptoKit, FileManager.replaceItem, and SessionCoordinator integration; MEDIUM on the manifest file-enumeration strategy because the existing on-disk model layout differs from CONTEXT.md D-05's assumed schema (see Open Question #1).

## Summary

Phase 17 ships an independent ASR model update channel — a `ModelUpdateService` actor that fetches a JSON manifest, compares versions, downloads model files to a staging directory with cancel + SHA-256 verification, atomically swaps in the new model directory, calls `TranscriptionEngine.reloadModels()` for hot-swap, and rolls back on failure. The Settings > Speech Model section gives the user a version display, an inline determinate progress UI, and a manual Check for Updates button. SessionCoordinator's `modelUpdate` reference (already commented in at `SessionCoordinator.swift:23-31`) is wired so the swap step gates on `anySessionActive == false`.

19 decisions in CONTEXT.md are locked, including manifest URL, hosting strategy (GitHub raw on `cnewfeldt/ps-transcribe-releases:main`), HTTPS+SHA-256 integrity (no EdDSA), `String.compare(_:options:.numeric)` for version comparison, apply-deferral on active session, and `@Observable @MainActor final class` shape for the service. The remaining unknowns the planner needs are (a) URLSession concurrency pattern, (b) SHA-256 streaming vs. post-download, (c) atomic rename failure modes, (d) cancellation determinism, (e) HuggingFace `.mlmodelc` file structure, (f) `reloadModels()` behavior with already-on-disk files, (g) test strategy for actor + URLSession, (h) disk-space preflight API, and (i) plan decomposition. All are answered below.

**One CONTEXT.md correction surfaced by code+source inspection:** the on-disk folder name is `parakeet-tdt-0.6b-v3` (NOT `parakeet-tdt-0.6b-v3-coreml`) — FluidAudio's `Repo.folderName` strips the `-coreml` suffix at `ModelNames.swift:139`. And the on-disk model artifacts are `.mlmodelc` directories (compiled), NOT `.mlpackage` directories — meaning the D-05 manifest schema needs adjustment before the first manifest is published (see Open Question #1).

**Primary recommendation:** Use Swift Concurrency's `URLSession.bytes(for:delegate:)` (with a custom delegate for cancel + progress) rather than the older `URLSessionDownloadTask` callback API. Hash incrementally as bytes arrive (`SHA256.update(bufferPointer:)` per chunk). Use `FileManager.replaceItem(at:withItemAt:backupItemName:options:resultingItemURL:)` for the atomic swap with `.usingNewMetadataOnly` option. Cancel-by-Task-cancellation gives deterministic cleanup. Decompose into 5 plans (skeleton → download+verify → swap+reload → UI → tests+manifest publication).

## User Constraints (from CONTEXT.md)

### Locked Decisions

**Manifest Hosting & Authentication**
- D-01: Manifest at `https://raw.githubusercontent.com/cnewfeldt/ps-transcribe-releases/main/model-manifest.json`
- D-02: Model files come from HuggingFace URLs declared inside the manifest; SHA-256 per file; no GitHub mirror
- D-03: First manifest declares the v3 model already shipped in v1.0 as version `"20260427"`. Release prerequisite: publish before tagging v1.2
- D-04: Manifest auth = HTTPS + GitHub trust only. NO EdDSA. SHA-256 on files is the integrity gate
- D-05: Manifest schema (model_id, version, min_app_version, total_size_bytes, files[name, url, sha256, size])

**Settings UX**
- D-06: New top-level `Section("Speech Model")` between `Section("Updates")` (line 54) and end of Form (line 60)
- D-07: Display: `Speech Model: v20260427 · Apr 27, 2026`. Update available: `Speech Model: v20260427 → v20260601` with pill `Update available · ~520 MB` and `[Install Update]` button
- D-08: Inline only — no sidebar dot, no menu-bar badge, no system notification
- D-09: Inline determinate progress: `[Install Update]` morphs to `[==45%====] Installing... 240/520 MB  [Cancel]` then `✓ Updated to v20260601 · active` or `⚠️ Update failed: <reason>  [Retry]`. NO modal sheet

**Check Trigger**
- D-10: Auto-check ~10s after launch IF >24h since last check. Opportunistic check on opening Settings > Speech Model IF >24h. NO long-running timer
- D-11: NEW AppSettings key `modelAutoUpdateEnabled: Bool` default `true`, key `"modelAutoUpdateEnabled"`, label `"Automatically check for new speech models"`
- D-12: Manual `[Check for Updates]` button always visible; forces fetch regardless of throttle and `modelAutoUpdateEnabled`. Updates `modelLastCheckedDate` on success. Status: "Checking..." → "Up to date as of {date}" or "Update available: v{new}"
- D-13: When `modelAutoUpdateEnabled == false`, auto + opportunistic checks suppressed; manual still works

**Migration & Rollback**
- D-14: First-run backfill — IF `installedModelVersion == ""` AND every `manifest.files[*].name` exists on disk AND first file's size matches `manifest.files[0].size`, silently set `installedModelVersion = manifest.version`. Size-only check, no SHA on launch
- D-15: Rollback retention — failed staging directory renamed to `<repo>-failed-{ISO8601}/`. Delete previous `*-failed-*/` on next successful update. One cycle of forensic visibility
- D-16: Blocked update UX — when `manifest.min_app_version > Bundle.main.shortVersion`, show `New v20260601 requires PS Transcribe ≥ 1.3.0. [Check for App Update]` calling `SPUUpdater.checkForUpdates()`. NO `[Install Update]` button. Third UI state distinct from up-to-date and update-available

**Comparison & Concurrency**
- D-17: `String.compare(_:options:.numeric)` for both `min_app_version` and `version` comparisons
- D-18: `ModelUpdateService` is `@Observable @MainActor final class`. Exposes `var updateState: ModelUpdateState`, `var isApplying: Bool`. Wires `SessionCoordinator.modelUpdate = service` per the additive Optional pattern at `SessionCoordinator.swift:23-31`. `anySessionActive` becomes `(engine?.isRunning ?? false) || (modelUpdate?.isApplying ?? false)`
- D-19: Apply-deferral — download may proceed regardless of session state; the **swap step** is gated on `sessionCoordinator.anySessionActive == false`. If active when download completes, set `updatePending = true` and apply on next session-stop notification

### Claude's Discretion

- Internal AppSettings key naming beyond the three locked keys (e.g., `updatePending` is in-memory only — not persisted)
- Disk-space preflight UX: if `volumeAvailableCapacityForImportantUsage < manifest.total_size_bytes * 2`, show inline `Update available — needs ~1.1 GB free, 600 MB available · [Free up space]` and disable Install. Doubling factor accounts for staging + production coexistence
- Cancellation semantics: Cancel deletes `<repo>-staging/` contents; restores `[Install Update]`. Active model untouched (only swap moves it)
- NO telemetry, NO query params, NO User-Agent customization on the manifest fetch (HARD project constraint)
- `reloadModels()` implementation — nil out `asrManager`/`vadManager` first (so ARC drops MLModel refs before rename), then call `AsrModels.downloadAndLoad(version: .v3)` (reads from disk since files are now in place), then re-instantiate managers and set `modelsReady = true`. Mirrors `prepareModels()` at `TranscriptionEngine.swift:79-103`
- File location: `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift` (creates new `Services/` directory)

### Deferred Ideas (OUT OF SCOPE)

- Cellular-network warning before large download (NWPathMonitor) — defer to v1.3 polish or Phase 19
- Sidebar/menu-bar badge for update-available — rejected (inline-only matches MODEL-02)
- EdDSA signing of `model-manifest.json` — rejected (SHA-256 on model files is the integrity gate)
- Mirroring model files to GitHub Releases — rejected (HF is upstream source of truth)
- Model rollback UI / version pinning — explicitly out of scope per REQUIREMENTS.md
- SHA-compare migration (alternative to D-14) — rejected (5–30s launch latency unacceptable)
- Long-running 24h background timer — rejected per D-10
- Hardcoding `INITIAL_MODEL_VERSION` constant — rejected per D-14

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MODEL-01 | App checks for newer model versions in background, no more than once per 24 hours | Auto-check at launch + opportunistic on settings open per D-10. `Date().timeIntervalSince(modelLastCheckedDate) > 24*60*60` gate. AppSettings key `modelLastCheckedDate` already in place from Phase 16 D-04 |
| MODEL-02 | Update-available shows non-intrusive badge in Settings > Model (no modals, no notifications) | D-08 inline-only. Render via SwiftUI conditional `Text("Update available · ~520 MB")` with `.foregroundStyle(.orange)` or similar pill — no `NSAlert`, no `UNUserNotificationCenter` |
| MODEL-03 | User explicitly initiates download (no silent auto-install) | `[Install Update]` button is the only path that triggers `downloadAndApply()`. Auto-check only updates state; never starts download |
| MODEL-04 | Download shows progress and is cancellable | D-09 inline determinate progress. Implementation: URLSession + custom delegate for byte-progress callbacks; Task cancellation propagates to URLSessionTask via Task.isCancelled check + `task.cancel()` |
| MODEL-05 | Downloaded version persisted | `AppSettings.installedModelVersion` is the persisted SHA/version string. Already in place from Phase 16 D-04. Written after successful swap+reload completes |
| MODEL-06 | Failed/partial downloads do not corrupt active model (staging, verify, atomic swap) | Staging directory `<repo>-staging/`. SHA-256 per file before swap. Atomic rename via `FileManager.replaceItem(at:withItemAt:...)`. Active model only moved during the swap step itself |
| MODEL-07 | Swap deferred when session active; applies after session ends | D-19. Swap gated on `sessionCoordinator.anySessionActive == false`. `updatePending` flag (in-memory) drives reapply on session-stop notification |
| MODEL-08 | Settings shows installed vs available version | D-07. Format: `Speech Model: v20260427 · Apr 27, 2026` or `v20260427 → v20260601` |
| MODEL-09 | Manifest carries `min_app_version` so model requiring newer SDK isn't applied until app updates | D-05 (`min_app_version` field). D-16 gate using `String.compare(_:options:.numeric)`. Blocked-state UI offers `[Check for App Update]` invoking `SPUUpdater.checkForUpdates()` |
| MODEL-10 | Disk-space preflight before download | `URL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])` from `~/Library/Application Support/FluidAudio/Models/`. Compare against `manifest.total_size_bytes * 2`. If insufficient, show advisory and disable Install |

## Project Constraints (from CLAUDE.md)

No project-level `./CLAUDE.md` exists in the repository root. Project conventions are documented in `.planning/codebase/CONVENTIONS.md` and reflected here:

- **Swift 6.2 strict concurrency.** All shared mutable state behind actors or `@MainActor`. Callbacks marked `@Sendable`. Background work via `Task.detached` or `Task.init` then explicit `await MainActor.run { … }` for UI state mutation
- **`@Observable @MainActor final class`** is the canonical shape for app-scope service classes (matches `AppSettings`, `TranscriptionEngine`, `AppUpdaterController`, `SessionCoordinator`)
- **No silent error suppression.** Use `try?` only for non-critical operations (file cleanup, optional inits). Critical paths throw to caller; caller sets `lastError` state for UI
- **No `print()`.** Use `os.Logger(subsystem: "com.pstranscribe.app", category: "ModelUpdate")` for permanent logging; gate verbose tracing behind `UserDefaults.bool(forKey: "enableVerboseLogging")` mirroring `diagLog()` at `TranscriptionEngine.swift:9-13`
- **AppSettings pattern: `didSet` UserDefaults mirroring** — `var foo: T { didSet { UserDefaults.standard.set(foo, forKey: "foo") } }`. NEVER `@AppStorage`
- **No new SwiftPM dependency for Phase 17.** STACK.md confirms URLSession + CryptoKit + FluidAudio (already pinned at `ea50062`) is sufficient
- **No telemetry, ever.** Hard project constraint reiterated in PROJECT.md and CONTEXT.md Claude's-Discretion: NO query params on the manifest URL, NO User-Agent customization, NO Authorization headers (the manifest is public)
- **Tests use Swift Testing** (`import Testing`, `@Suite`, `@Test`, `#expect`) — confirmed by `Tests/PSTranscribeTests/AppSettingsTests.swift` and `SessionCoordinatorTests.swift`. NOT XCTest

## Standard Stack

### Core (already in target — no new deps)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Foundation `URLSession` | system (macOS 26) | HTTP fetch (manifest) and download (model files) with progress + cancel | First-party, no entitlement needed (app is non-sandboxed; existing `NotionService.swift:556` uses URLSession) [VERIFIED: NotionService.swift] |
| `CryptoKit.SHA256` | system (macOS 10.15+) | SHA-256 streaming hash for verification | First-party, hardware-accelerated on Apple Silicon, supports incremental `update(data:)` + `finalize()` for files too large to hold in memory [CITED: developer.apple.com/documentation/cryptokit/sha256] |
| `Foundation.FileManager` | system | Atomic directory rename for staging→production swap | `replaceItem(at:withItemAt:backupItemName:options:resultingItemURL:)` is the documented atomic-replace API on Apple platforms; partial-failure-safe [CITED: developer.apple.com/documentation/foundation/filemanager/itemreplacementoptions] |
| `Sparkle` `SPUUpdater` | 2.7.0+ (already pinned) | App update trigger from blocked-update UX (D-16) | Already wired via `AppUpdaterController.updater` at `PSTranscribeApp.swift:11`, exposed to `SettingsView` parameter |
| `FluidAudio` | commit `ea50062` (already pinned) | `AsrModels.downloadAndLoad(version: .v3)` for `reloadModels()` post-swap | Pre-existing dependency. **Critical:** `downloadAndLoad` is a no-op when files exist on disk in the expected layout — verified via `AsrModels.swift:198-204` (the `allModelsExist` short-circuit in `loadModelsOnce`). The `reloadModels()` implementation can call this safely after the swap [VERIFIED: FluidAudio/.build/checkouts/FluidAudio/Sources/FluidAudio/DownloadUtils.swift:198-204] |
| `Observation` | system | `@Observable` macro for SwiftUI bindings | Already used across `AppSettings`, `TranscriptionEngine`, `SessionCoordinator` |
| `Swift Testing` | system (Swift 6+) | Unit tests | Tests already use `import Testing`, `@Suite`, `@Test` per `AppSettingsTests.swift`. NOT XCTest |

### Supporting (built on stdlib — no installs)

| Pattern | Usage | When to Use |
|---------|-------|-------------|
| `JSONDecoder` | Parse `model-manifest.json` into a Codable struct | Always. The manifest is a 4–8 KB JSON document |
| Custom `URLSessionTaskDelegate` | Receive `urlSession(_:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)` (uploads) and `urlSession(_:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)` (downloads) progress callbacks. Bridge to `@MainActor` via `Task { @MainActor in self.updateState = .downloading(progress: p) }` | When you need byte-level progress and cancellation control |
| `URL.resourceValues(forKeys:)` | Read `volumeAvailableCapacityForImportantUsageKey` for disk preflight | Once before each download attempt |
| `ISO8601DateFormatter` | Format `<repo>-failed-{timestamp}/` directory names | Per D-15 rollback retention |
| `URLProtocol` subclass + `URLSessionConfiguration.protocolClasses` | Inject mock HTTP responses in tests | Standard pattern for testing `URLSession` code without network. The `NotionService` tests at `Tests/PSTranscribeTests/NotionServiceTests.swift` should be checked for an existing pattern; if absent, introduce a test-only `MockURLProtocol` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `URLSession.shared.data(for:)` for the manifest | A custom session with timeout configuration | The manifest is 4–8 KB. The default 60s timeout is fine. Use `URLSession.shared.data(for: URLRequest(url:))` directly. Future flexibility (proxy, custom timeout) → switch to dedicated `URLSession` if needed [CITED: NotionService.swift uses `URLSession.shared.data(for:)`] |
| Old-style `URLSessionDownloadTask` with delegate callback closures | `URLSession.bytes(for:delegate:)` returning `(URLSession.AsyncBytes, URLResponse)` | The async sequence approach is cleaner under Swift 6.2: cancellation propagates through `Task.cancel()`, and the bytes can be hashed incrementally as they arrive. The download delegate is still useful for byte-progress callbacks (`urlSession(_:dataTask:didReceive:)`) — wire it through a `nonisolated` URLSessionDataDelegate that posts to `@MainActor` |
| Two `moveItem` calls (`mv prod backup` + `mv staging prod`) | `FileManager.replaceItem(at:withItemAt:backupItemName:options:resultingItemURL:)` | `replaceItem` is documented atomic on the same volume on APFS (which is the case — both directories are under `~/Library/Application Support/FluidAudio/Models/`). Two-step `moveItem` is *not* atomic — a process kill between the two leaves no production directory. `replaceItem` is the correct primitive [CITED: developer.apple.com/documentation/foundation/filemanager/itemreplacementoptions] |
| Hash-after-download (read whole file, hash, then move) | Hash-as-you-write (CryptoKit incremental update during download) | For 425 MB Encoder.mlmodelc, hashing after download adds ~5–15s of disk read on a Mac with cold caches. Hash-as-you-write costs ~0ms because the bytes are already in CPU cache from the download path. CryptoKit `SHA256.update(bufferPointer:)` per chunk is the standard pattern [CITED: developer.apple.com/documentation/cryptokit/sha256] |

### Installation

No new SwiftPM dependencies — Phase 17 ships entirely on first-party frameworks already in the target. **No `Package.swift` changes.**

```swift
// New imports needed in ModelUpdateService.swift:
import Foundation
import CryptoKit       // SHA256 streaming hash
import Observation     // @Observable
import FluidAudio      // AsrModels (for reloadModels invocation, not direct use here)
import os              // Logger
```

### Version verification

`swift package show-dependencies` was not run because Phase 17 introduces no new packages. CryptoKit `SHA256` is available macOS 10.15+; the project targets macOS 26 — no minimum-OS conflict. `FileManager.replaceItem` is documented stable since macOS 10.6.

## Architecture Patterns

### Recommended File Structure

```
PSTranscribe/Sources/PSTranscribe/
├── App/
│   ├── PSTranscribeApp.swift             # MODIFIED: instantiate ModelUpdateService, wire SessionCoordinator
│   ├── SessionCoordinator.swift          # MODIFIED: uncomment lines 23-31, add weak var modelUpdate
│   └── AppUpdaterController.swift        # UNCHANGED (reference shape only)
├── Services/                             # NEW directory
│   └── ModelUpdateService.swift          # NEW: @Observable @MainActor final class
├── Settings/
│   └── AppSettings.swift                 # MODIFIED: add modelAutoUpdateEnabled
├── Transcription/
│   └── TranscriptionEngine.swift         # MODIFIED: add reloadModels()
├── Views/
│   └── SettingsView.swift                # MODIFIED: add Section("Speech Model"), inject modelUpdateService
└── (tests in PSTranscribe/Tests/PSTranscribeTests/)
    ├── ModelUpdateServiceTests.swift     # NEW: state-machine + manifest parsing tests
    ├── ModelManifestTests.swift          # NEW: Codable round-trip + version compare
    └── (existing tests untouched)
```

### Pattern 1: `@Observable @MainActor` Service Class with Background Work

**What:** Service mutates state on MainActor; offloads I/O to detached tasks; updates state via `await MainActor.run`.

**When to use:** Always, for any service that exposes `@Observable` state to SwiftUI but performs network/file/CPU work.

**Example** — mirrors `AppUpdaterController` at `PSTranscribe/Sources/PSTranscribe/App/AppUpdaterController.swift`:

```swift
import Observation
import os

@Observable
@MainActor
final class ModelUpdateService {
    // Exposed state (read by SwiftUI, written only on MainActor)
    var updateState: ModelUpdateState = .idle
    var isApplying: Bool = false

    // Phase 17 D-19: in-memory pending flag, cleared on apply
    private var updatePending: ManifestSnapshot?

    private weak var sessionCoordinator: SessionCoordinator?
    private weak var transcriptionEngine: TranscriptionEngine?
    private weak var settings: AppSettings?

    private let log = Logger(subsystem: "com.pstranscribe.app", category: "ModelUpdate")
    private let session = URLSession.shared    // manifest fetch only
    private var downloadTask: Task<Void, Error>?

    init(settings: AppSettings,
         engine: TranscriptionEngine,
         sessionCoordinator: SessionCoordinator) {
        self.settings = settings
        self.transcriptionEngine = engine
        self.sessionCoordinator = sessionCoordinator
    }

    func checkForUpdate(force: Bool = false) async { /* ... */ }
    func downloadAndApply() async { /* ... */ }
    func cancelDownload() { downloadTask?.cancel() }
}

enum ModelUpdateState: Equatable, Sendable {
    case idle
    case checking
    case upToDate(asOf: Date)
    case updateAvailable(version: String, sizeBytes: Int64, releasedAt: Date?)
    case blocked(reason: BlockedReason)
    case downloading(progress: Double, completedBytes: Int64, totalBytes: Int64)
    case verifying
    case applying
    case applied(version: String)
    case failed(message: String)
}

enum BlockedReason: Equatable, Sendable {
    case minAppVersion(required: String, installed: String)
    case insufficientDiskSpace(needed: Int64, available: Int64)
}
```

### Pattern 2: URLSession Download with Incremental SHA-256 + Cancel

**What:** Use `URLSession.bytes(for:)` to stream bytes; feed each chunk into both file write and `SHA256.update()`; check `Task.isCancelled` between chunks for prompt cancellation.

**When to use:** For each model file in `manifest.files`. The total expected pattern is 4–6 files (Preprocessor, Encoder, Decoder, JointDecision, vocab.json, config.json).

**Example:**

```swift
// Source: developer.apple.com/documentation/foundation/urlsession/bytes(for:delegate:)
//         developer.apple.com/documentation/cryptokit/sha256
private func downloadFile(
    from url: URL,
    to destination: URL,
    expectedSize: Int64,
    expectedSHA256: String,
    onProgress: @MainActor @Sendable (Int64) -> Void
) async throws {
    let (bytes, response) = try await session.bytes(for: URLRequest(url: url))
    guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
        throw ModelUpdateError.httpError(url: url)
    }

    FileManager.default.createFile(atPath: destination.path, contents: nil)
    let handle = try FileHandle(forWritingTo: destination)
    defer { try? handle.close() }

    var hasher = SHA256()
    var bytesWritten: Int64 = 0
    var buffer = Data()
    buffer.reserveCapacity(64 * 1024)

    for try await byte in bytes {
        try Task.checkCancellation()    // throws CancellationError if Task.cancel() was called
        buffer.append(byte)
        if buffer.count >= 64 * 1024 {
            try handle.write(contentsOf: buffer)
            hasher.update(data: buffer)
            bytesWritten += Int64(buffer.count)
            await onProgress(bytesWritten)
            buffer.removeAll(keepingCapacity: true)
        }
    }
    if !buffer.isEmpty {
        try handle.write(contentsOf: buffer)
        hasher.update(data: buffer)
        bytesWritten += Int64(buffer.count)
        await onProgress(bytesWritten)
    }

    let digest = hasher.finalize()
    let actualHex = digest.map { String(format: "%02x", $0) }.joined()
    guard actualHex.lowercased() == expectedSHA256.lowercased() else {
        throw ModelUpdateError.checksumMismatch(file: destination.lastPathComponent,
                                                expected: expectedSHA256, actual: actualHex)
    }
}
```

**Cancellation determinism:** `Task.checkCancellation()` throws on the next loop iteration after `Task.cancel()`. The `bytes` AsyncSequence also throws on cancellation. The destination file is then deleted in a `do { try await … } catch is CancellationError` handler. Net: cancel → file gone within one chunk's worth of latency (~1–10 ms), deterministically before the cancel button can be re-tapped or Install button re-shown.

### Pattern 3: Atomic Directory Swap with `FileManager.replaceItem`

**What:** Replace `<repo>/` with `<repo>-staging/` atomically. The previous directory is preserved as a backup; on success, the backup is removed; on the next failed update, it's renamed to `<repo>-failed-{ISO8601}/`.

**When to use:** Only after every file in `<repo>-staging/` has passed SHA-256 verification AND `sessionCoordinator.anySessionActive == false`.

**Example:**

```swift
// Source: developer.apple.com/documentation/foundation/filemanager/itemreplacementoptions
private func atomicSwap(
    productionDir: URL,    // ~/Library/Application Support/FluidAudio/Models/parakeet-tdt-0.6b-v3
    stagingDir: URL,       // ~/Library/Application Support/FluidAudio/Models/parakeet-tdt-0.6b-v3-staging
    backupBasename: String // "parakeet-tdt-0.6b-v3-backup-20260427T143022"
) throws -> URL? {
    var resultingURL: NSURL?
    try FileManager.default.replaceItem(
        at: productionDir,
        withItemAt: stagingDir,
        backupItemName: backupBasename,
        options: [.usingNewMetadataOnly],
        resultingItemURL: &resultingURL
    )
    // The backup is at productionDir.deletingLastPathComponent().appendingPathComponent(backupBasename)
    let parent = productionDir.deletingLastPathComponent()
    let backupURL = parent.appendingPathComponent(backupBasename)
    return FileManager.default.fileExists(atPath: backupURL.path) ? backupURL : nil
}
```

**Failure modes (verified via Apple docs):**
- If the operation cannot be made atomic, `replaceItem` throws WITHOUT touching either directory. The production directory is intact; the user retries.
- If the rename succeeds but the backup-cleanup fails, the production directory is the new content (success). Cleanup is best-effort (`try?`).
- If a process kill happens *during* `replaceItem` itself: the API uses `rename(2)`-family atomicity on APFS, so the destination is either entirely the old content or entirely the new content. There is no partial-swap state. (See LWN / Apple docs.)
- Cross-volume calls fail at the API boundary — both URLs must be on the same volume. Both staging and production are inside `~/Library/Application Support/FluidAudio/Models/`, so this is guaranteed.

### Pattern 4: SessionCoordinator Wiring (Apply-Deferral)

**What:** `ModelUpdateService.downloadAndApply()` reaches the swap step, then checks `sessionCoordinator.anySessionActive`. If true, sets `updatePending = manifest` and returns; subscribes to a session-end signal; when signal fires, retries the swap step.

**Example:**

```swift
// Wires in PSTranscribeApp.swift after both services exist:
sessionCoordinator.modelUpdate = modelUpdateService

// In SessionCoordinator.swift (uncomment + extend):
weak var modelUpdate: ModelUpdateService?

var anySessionActive: Bool {
    (engine?.isRunning ?? false)
    || (modelUpdate?.isApplying ?? false)
}
```

**Session-end notification:** The simplest path is to have `ModelUpdateService` use a `@MainActor` polling task (`for await _ in Timer.publish(every: 1, on: .main, in: .common)`) checking `anySessionActive`. But the cleaner pattern uses an Observation withObservationTracking loop:

```swift
private func waitForSessionEnd() async {
    while sessionCoordinator?.anySessionActive ?? false {
        try? await Task.sleep(for: .milliseconds(500))
    }
}
```

This is acceptable since the loop runs only when an update is pending and a session is active — likely seconds, at most session-duration minutes.

### Anti-Patterns to Avoid

- **Don't use `URLSessionDownloadTask` with completion handlers** — the closure-based API does not interop cleanly with Swift Concurrency cancellation. Use `URLSession.bytes(for:)` for new code.
- **Don't write the model file at the production path and then verify** — that defeats the staging directory's purpose. Files MUST land in `<repo>-staging/` first.
- **Don't run two `moveItem` calls** for the swap — use `replaceItem`. Two-step is non-atomic and a process kill between them leaves no production directory (Pitfall #11 territory).
- **Don't add a User-Agent or query parameters to the manifest URL** — hard project constraint (CONTEXT.md Claude's Discretion). Plain `URLSession.shared.data(for: URLRequest(url: manifestURL))`.
- **Don't expose `reloadModels()` as a public API on `TranscriptionEngine`** — it should be `internal` and called only by `ModelUpdateService`. The risk is a future caller invoking it during an active session.
- **Don't persist `updatePending` to UserDefaults** — Claude's Discretion in CONTEXT.md says in-memory only. The user can re-trigger after relaunch via the Install button.
- **Don't hash with `SHA256.hash(data: try Data(contentsOf:))`** for files >100 MB — that loads the whole file into memory. Use the incremental `update(data:)` pattern shown above.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTTP fetch with timeout, redirects, TLS | Custom socket code | `URLSession.shared.data(for:)` | First-party, already used in `NotionService.swift`; handles redirects automatically (HuggingFace serves `Location:` headers to its CDN — verified by FluidAudio's `DownloadUtils.downloadRepo` succeeding without manual redirect logic) |
| SHA-256 hashing | `Data(contentsOf:)` + manual hashing loop | `CryptoKit.SHA256` with incremental `update(data:)` + `finalize()` | Hardware-accelerated on Apple Silicon; cryptographically reviewed; supports streaming |
| Atomic directory swap | Two `moveItem` calls or `link`/`unlink` shenanigans | `FileManager.replaceItem(at:withItemAt:...)` | Documented atomic on APFS; partial-failure-safe; idiomatic |
| Version comparison (`"1.10.0" vs "1.2.0"`) | Manual numeric split | `String.compare(_:options:.numeric)` | D-17 locked. Handles edge cases (date-shaped strings, mixed dotted versions) without rolling a SemVer parser |
| Disk-space query | `statfs(2)` | `URL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])` | Apple-recommended API since macOS 10.13; respects iCloud purgeable space accounting |
| File-progress UI | Custom `Progress` object | A simple `Double` progress + computed bytes-completed/total in `ModelUpdateState` | The `Progress` class is overkill for an inline determinate bar; SwiftUI binds directly to the enum's associated values |
| App-update trigger from blocked-update UX | `NSWorkspace.open` with appcast URL | `updaterController.updater.checkForUpdates()` (already in app) | Sparkle is wired; reuse it |
| Mock URLSession in tests | `MockURLSession` subclass | `URLProtocol` subclass + `URLSessionConfiguration.protocolClasses` | Standard, intercepts at the right layer, no need to subclass URLSession itself |

**Key insight:** Phase 17 is heavy on integration of *existing* primitives. The temptation is to write a "smart" download manager. Resist it — every primitive has an Apple-blessed answer.

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | (1) `~/Library/Application Support/FluidAudio/Models/parakeet-tdt-0.6b-v3/` — the active model directory holding compiled `.mlmodelc` directories. (2) `UserDefaults` keys: `installedModelVersion` (set on apply), `modelLastCheckedDate` (set on every check), `modelAutoUpdateEnabled` (NEW, set by user toggle) | The active model directory is created by FluidAudio on first run; Phase 17 will read/write a parallel `<repo>-staging/` directory and a transient `<repo>-failed-{ISO8601}/` directory. UserDefaults keys 1+2 are pre-existing from Phase 16 D-04; key 3 is added in Phase 17 |
| Live service config | None. The manifest is hosted on a public GitHub repo; no service to configure | None — verified by D-04 (HTTPS + GitHub trust) |
| OS-registered state | None. `ModelUpdateService` registers no OS-level resources (no LaunchAgents, no scheduled tasks, no file system events). Sparkle's existing scheduled checks are unaffected | None |
| Secrets/env vars | None. The manifest URL and HuggingFace download URLs are unauthenticated; no API key, no token. Note: FluidAudio's `DownloadUtils` reads `HF_TOKEN` from environment — but Phase 17 does NOT use `DownloadUtils` for the actual download (it uses `URLSession` directly per D-02), so no env-var dependency | None |
| Build artifacts | None — `Sources/PSTranscribe/Services/` is a new directory but has no build-output side effects. The Swift Package Manager test target picks up new files automatically | None |

**The canonical question — after every file in the repo is updated, what runtime systems still have the old string cached, stored, or registered?** N/A — this is a greenfield feature, not a rename/refactor. Phase 17 introduces new state; it does not migrate existing state away from old names.

## Common Pitfalls

### Pitfall 1: Manifest schema vs. on-disk file structure mismatch (CRITICAL)

**What goes wrong:** CONTEXT.md D-05 declares the manifest's `files` array with entries like `preprocessor.mlpackage`, `encoder.mlpackage`. But the *actual on-disk* artifacts for parakeet-v3 are `.mlmodelc` directories (compiled), each containing 3 files (`coremldata.bin`, `metadata.json`, `model.mil`) plus 2 subdirectories (`analytics/`, `weights/`). HuggingFace serves these as individual files via `resolve/main/{path}`. Per the existing on-disk layout at `~/Library/Application Support/FluidAudio/Models/parakeet-tdt-0.6b-v3/`:
- `Decoder.mlmodelc/` (23 MB total — coremldata.bin + metadata.json + model.mil + weights/weight.bin)
- `Encoder.mlmodelc/` (425 MB)
- `JointDecision.mlmodelc/` (12 MB)
- `Preprocessor.mlmodelc/` (520 KB)
- `parakeet_v3_vocab.json` (151 KB)
- `parakeet_vocab.json` (151 KB)
- `config.json` (2 bytes)

**Why it happens:** The manifest schema was drafted assuming each top-level model is a single file. In reality each is a *directory* of small files.

**How to avoid:** Two options for the planner to choose:
- **Option A (RECOMMENDED): Manifest enumerates files inside each `.mlmodelc`.** Each manifest entry is a leaf file with a relative path like `Encoder.mlmodelc/weights/weight.bin`, `Encoder.mlmodelc/coremldata.bin`, etc. The download recreates the directory tree. ~15–20 manifest entries per model. Per-file SHA-256 is exact.
- **Option B: Manifest enumerates `.mlmodelc` directories with a manifest-of-manifests.** Each entry is a directory, with a SHA-256 computed over `tar` of the directory. Cleaner manifest, but requires tar/untar logic in the app and is non-standard. Not recommended.

The planner should pick Option A and update the D-05 manifest schema example before authoring the first manifest in plan 05. The 4-entry example in CONTEXT.md is illustrative, not prescriptive.

**Warning signs:** First manifest is published; download starts; the app expects `Encoder.mlpackage` but HuggingFace 404s the URL because the actual path is `Encoder.mlmodelc/weights/weight.bin`. [VERIFIED via direct inspection of `~/Library/Application Support/FluidAudio/Models/parakeet-tdt-0.6b-v3/` and HuggingFace tree listing 2026-04-27]

### Pitfall 2: On-disk folder name in CONTEXT.md is wrong

**What goes wrong:** CONTEXT.md (multiple sections) and ARCHITECTURE.md state the model lives at `~/Library/Application Support/FluidAudio/Models/parakeet-tdt-0.6b-v3-coreml/`. The actual on-disk folder is `parakeet-tdt-0.6b-v3` (no `-coreml` suffix). FluidAudio's `Repo.folderName` strips `-coreml` per the default branch at `ModelNames.swift:139` (`return name.replacingOccurrences(of: "-coreml", with: "")`).

**Why it happens:** CONTEXT.md was written from the HuggingFace repo slug rather than from the FluidAudio cache layout.

**How to avoid:** Plans must reference the actual cache directory. The constant should be derived from FluidAudio's `Repo.parakeet.folderName`, not hardcoded. Suggested:

```swift
private var modelDirectory: URL {
    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    return appSupport.appendingPathComponent("FluidAudio/Models/parakeet-tdt-0.6b-v3")
}
```

The staging directory is `parakeet-tdt-0.6b-v3-staging` (no `-coreml`). The failed-rollback directory pattern is `parakeet-tdt-0.6b-v3-failed-{ISO8601}`.

**Warning signs:** Migration backfill (D-14) checks for `manifest.files[*].name` at `parakeet-tdt-0.6b-v3-coreml/...` and finds nothing → fires a fresh download for an already-installed v1.0 user. [VERIFIED: ModelNames.swift:115-141, Repo.folderName default case]

### Pitfall 3: URLSession actor-isolation deadlock from delegate callbacks

**What goes wrong:** Old pattern: `URLSessionDownloadTask` with `URLSessionDownloadDelegate.urlSession(_:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)` callback fires on a delegate queue. Inside the callback, the developer writes `await self.updateState = …` which under Swift 6 strict concurrency creates a Sendable closure boundary the compiler rejects, OR creates an unbounded number of MainActor hops that backlog.

**Why it happens:** The delegate API predates Swift Concurrency.

**How to avoid:** Use `URLSession.bytes(for:delegate:)` (no delegate needed for progress because the byte count is incremental in the loop) — see Pattern 2 above. If a delegate is needed for something specific, mark it `nonisolated` and dispatch with `Task { @MainActor [weak self] in self?.updateState = … }`.

**Warning signs:** Compiler warnings about non-Sendable closure capture in delegate methods; UI updates that lag behind the actual download progress by many seconds.

### Pitfall 4: `reloadModels()` re-fires network download

**What goes wrong:** `TranscriptionEngine.reloadModels()` calls `AsrModels.downloadAndLoad(version: .v3)`. If this re-triggers a network fetch of the model files, the user has just downloaded ~520 MB and the app immediately downloads it again.

**Why it happens:** `downloadAndLoad` is named ambiguously — it does both (download if missing, then load). If the swap-in directory doesn't satisfy FluidAudio's "models present" check, FluidAudio re-downloads.

**How to avoid:** Verified safe by inspection of `FluidAudio/.build/checkouts/FluidAudio/Sources/FluidAudio/DownloadUtils.swift:192-204`:

```swift
// loadModelsOnce() pseudo:
let allModelsExist = requiredModels.allSatisfy { model in
    let modelPath = repoPath.appendingPathComponent(model)
    return FileManager.default.fileExists(atPath: modelPath.path)
}
if !allModelsExist { try await downloadRepo(repo, ...) } else { /* read from disk */ }
```

So as long as `<repo>/Decoder.mlmodelc`, `<repo>/Encoder.mlmodelc`, `<repo>/JointDecision.mlmodelc`, `<repo>/Preprocessor.mlmodelc`, and the vocab JSON exist after the swap, `downloadAndLoad` is a no-op for the network portion. Plans must verify the staging directory contains the *exact* file names FluidAudio expects (per `ModelNames.ASR.requiredModels`).

**Warning signs:** Network activity indicator after a successful "apply" step; download progress bar reappears after the user thought update was complete. [VERIFIED via DownloadUtils.swift:192-204, AsrModels.swift:457-475]

### Pitfall 5: Migration backfill (D-14) misfires on partial install

**What goes wrong:** D-14 says backfill `installedModelVersion` if the version is empty AND every `manifest.files[*].name` exists AND first file's size matches. If the user has a corrupt or partial v1.0 install (e.g., missing `JointDecision.mlmodelc/`), backfill correctly skips. But if all files are present but the *content* differs from the manifest (a v1.1 binary the manifest doesn't know about), backfill silently sets `installedModelVersion = manifest.version` and the user is stuck on stale weights.

**Why it happens:** D-14 explicitly trades SHA verification (5–30s launch latency) for size-only verification.

**How to avoid:** Acceptable risk per CONTEXT.md `<specifics>`. The size-mismatch path correctly disqualifies the most likely failure mode (size differs across model versions). For deeper verification, the user can manually trigger Check for Updates which will fetch a new manifest; if the manifest is already current, nothing changes. If a future model has the same size as the current one but different content (rare), the SHA-256 path still kicks in on the next actual update.

**Warning signs:** Edge case — silently inaccurate `installedModelVersion`. Will self-correct on the next legitimate update.

### Pitfall 6: Cancellation race between download and apply

**What goes wrong:** Download completes; SHA-256 verification passes; `isApplying = true`; the swap begins (`replaceItem` is mid-operation); user taps a hypothetical Cancel. The cancel cannot un-do an atomic rename mid-flight; if the cancel handler also deletes the staging directory, you may delete a valid `<repo>-backup-{ts}/` and lose recovery.

**Why it happens:** Cancel button needs to be disabled during the irreversible swap window.

**How to avoid:** UI states:
- During `.downloading` and `.verifying`: Cancel button visible and active
- During `.applying`: Cancel button HIDDEN (or disabled with a brief "Finalizing…" label)
- After `.applied`: Cancel button gone; show confirmation
- After `.failed`: Show Retry, no Cancel

The swap step (`replaceItem` + `reloadModels()`) takes <500 ms typically — `replaceItem` is O(1) on APFS, `reloadModels` re-instantiates `AsrManager` and `VadManager` from disk in roughly 1–3 seconds. So the cancel-disabled window is short.

### Pitfall 7: `Bundle.main.shortVersion` vs `manifest.min_app_version` mismatch shape

**What goes wrong:** Info.plist `CFBundleShortVersionString` is `"2.1.1"` (verified via Info.plist:14). The manifest's `min_app_version` per D-05 is `"1.2.0"`. `String.compare(_:options:.numeric)` between `"1.2.0"` and `"2.1.1"` returns `.orderedAscending` (correct: 1.2.0 < 2.1.1). But if a future manifest declares `"1.10.0"` and the app is `"1.9.0"`, naive lexicographic compare orders 1.10.0 < 1.9.0 (wrong). D-17 already mandates `.numeric`. Verify this compiles in the implementation; don't slip back to `<` operator on String.

**How to avoid:** Use D-17's mandated API exactly:

```swift
let order = installedAppVersion.compare(manifest.min_app_version, options: .numeric)
let blocked = (order == .orderedAscending)
```

[VERIFIED: D-17, Info.plist:14]

### Pitfall 8: Pre-existing pitfalls already documented (do not re-research)

PITFALLS.md #11–#15 cover this domain. Phase 17 plans must address (with VERIFICATION.md cross-references):

- **#11 Partial download corruption** — staging directory + per-file SHA-256 mandated by D-02
- **#12 FluidAudio compat / `min_app_version`** — D-05 schema includes the field; D-16 specifies the blocked-state UX
- **#13 Swap during active session** — D-19 apply-deferral
- **#14 Disk-space exhaustion** — Claude's-Discretion preflight using `volumeAvailableCapacityForImportantUsage * 2`
- **#15 FluidAudio telemetry leak** — Phase 17 ONLY updates model weights, NOT the FluidAudio Swift package. Verify `Package.swift` and `Package.resolved` are unchanged in plan reviews

## Code Examples

### Manifest decoding

```swift
// Source: Foundation Codable + CONTEXT.md D-05
struct ModelManifest: Codable, Sendable {
    let model_id: String
    let version: String
    let min_app_version: String
    let total_size_bytes: Int64
    let files: [ManifestFile]
    let released_at: String?    // ISO8601, optional — for D-07 readable date

    struct ManifestFile: Codable, Sendable {
        let name: String          // relative path inside <repo>/, e.g. "Encoder.mlmodelc/weights/weight.bin"
        let url: String           // absolute HuggingFace resolve URL
        let sha256: String        // hex string, lowercase
        let size: Int64
    }
}
```

### Manifest fetch (no telemetry, no custom headers)

```swift
// Source: NotionService.swift:556 pattern, no headers per Claude's-Discretion D-tele
private func fetchManifest() async throws -> ModelManifest {
    let url = URL(string: "https://raw.githubusercontent.com/cnewfeldt/ps-transcribe-releases/main/model-manifest.json")!
    let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))
    guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
        throw ModelUpdateError.manifestFetchFailed
    }
    return try JSONDecoder().decode(ModelManifest.self, from: data)
}
```

### Disk-space preflight

```swift
// Source: developer.apple.com/documentation/foundation/urlresourcekey/volumeavailablecapacityforimportantusagekey
private func availableBytes(at url: URL) throws -> Int64 {
    let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
    return values.volumeAvailableCapacityForImportantUsage ?? 0
}

private func checkDiskSpace(needed: Int64) throws {
    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    let modelsRoot = appSupport.appendingPathComponent("FluidAudio/Models")
    try FileManager.default.createDirectory(at: modelsRoot, withIntermediateDirectories: true)
    let available = try availableBytes(at: modelsRoot)
    let required = needed * 2    // staging + production coexistence per Claude's-Discretion
    guard available >= required else {
        throw ModelUpdateError.insufficientDiskSpace(needed: required, available: available)
    }
}
```

### Version compare (D-17)

```swift
// Source: D-17, Foundation String.compare(_:options:.numeric)
extension String {
    /// Returns true if `self` is older than `other` per numeric (not lexicographic) comparison.
    /// Handles "1.10.0" > "1.2.0" correctly, and date-shaped strings like "20260427" < "20260601".
    func isOlderThan(_ other: String) -> Bool {
        compare(other, options: .numeric) == .orderedAscending
    }
}
```

### `reloadModels()` skeleton (mirrors `prepareModels()`)

```swift
// Source: TranscriptionEngine.swift:79-103 (prepareModels) — mirror with explicit nil-out
extension TranscriptionEngine {
    /// Hot-swap ASR + VAD models after the on-disk directory has been replaced atomically.
    /// MUST be called only when isRunning == false (caller is responsible for the guard).
    func reloadModels() async throws {
        // 1. Drop existing managers so ARC frees the MLModel handles before the new instances load.
        asrManager = nil
        vadManager = nil
        modelsReady = false

        // 2. Re-read from disk. AsrModels.downloadAndLoad short-circuits when files are present
        // (verified: DownloadUtils.swift:192-204 allModelsExist gate).
        let models = try await AsrModels.downloadAndLoad(version: .v3)
        let asr = AsrManager(config: .default)
        try await asr.loadModels(models)
        self.asrManager = asr

        let vad = try await VadManager()
        self.vadManager = vad

        modelsReady = true
        assetStatus = "Ready"
    }
}
```

### Test pattern: `URLProtocol` mock

```swift
// Source: Apple URLProtocol docs, standard pattern
import Foundation

final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responder: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let responder = MockURLProtocol.responder else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try responder(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// Setup in test:
let config = URLSessionConfiguration.ephemeral
config.protocolClasses = [MockURLProtocol.self]
let session = URLSession(configuration: config)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `URLSessionDownloadTask` with closure callbacks | `URLSession.bytes(for:)` AsyncSequence | Swift 5.5 (2021) | Cleaner cancellation via Task; trivial incremental hashing during read; no delegate-isolation gymnastics |
| `XCTest` | Swift Testing (`@Suite`, `@Test`, `#expect`) | Swift 6.0 (2024) | The repo already uses Swift Testing per AppSettingsTests.swift. New tests MUST use it; do not introduce XCTest |
| Hash file with `SHA256.hash(data: try Data(contentsOf: url))` | Incremental `SHA256.update(data:)` per chunk | Always available | Loading 425 MB into memory unnecessary; incremental matches the streaming download |
| Two-step `mv` swap | `FileManager.replaceItem(at:withItemAt:...)` | macOS 10.6 (2009) | Atomic on APFS; partial-failure-safe |

**Deprecated/outdated:** None for this phase — the stack is current.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | HuggingFace serves redirected URLs to its CDN; default `URLSession` redirect handling (10 hops) suffices | Standard Stack > URLSession | Low — FluidAudio's `DownloadUtils.downloadRepo` works without manual redirect logic on the same URL pattern, so the assumption is well-founded but not strictly verified for this exact code path. If wrong, downloads fail with HTTP 302 → mitigation: `URLSessionTaskDelegate.urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)` is straightforward to add later |
| A2 | The on-disk `parakeet-tdt-0.6b-v3` folder name is stable for the FluidAudio commit pinned at `ea50062` | Pitfall 2 | Low — verified by reading the actual ModelNames.swift in `.build/checkouts/`. Stable until the FluidAudio package is bumped (which Phase 17 is FORBIDDEN from doing per Pitfall #15) |
| A3 | The first plan's manifest schema can be adjusted (Option A in Pitfall 1) without re-litigating CONTEXT.md D-05 | Pitfall 1 | Medium — the planner should validate this with the user during the discuss-phase (or deemed in-scope as a refinement of the locked decision since D-05 says "files[]" structure is illustrative, not the final wire format). If the user disagrees, plan 05 (manifest publication) blocks until clarified |
| A4 | `volumeAvailableCapacityForImportantUsage` reflects the same volume as `~/Library/Application Support/FluidAudio/Models/` | Standard Stack > Disk preflight | Low — both are on the user's primary boot volume. Cross-volume model storage is not a documented configuration |
| A5 | Phase 17 SHOULD NOT touch the FluidAudio package (Pitfall #15 boundary) | Specifics > Pitfall #15 | High if violated — would re-introduce the privacy risk PITFALLS.md #15 calls out. The plan reviewer must verify `Package.swift` and `Package.resolved` are not in any plan's `key-files.modified` |

**If this table is empty:** It isn't — see above. Two MEDIUM-impact assumptions (A3, A5) need to be flagged for the planner's attention.

## Open Questions

1. **Manifest schema details (CRITICAL — affects plan 05).**
   - **What we know:** D-05 declares the wire schema with `files[].name` of `.mlpackage`. The actual on-disk artifacts are `.mlmodelc` directories with sub-files (Pitfall 1).
   - **What's unclear:** Is the planner authorized to refine D-05 to enumerate leaf files rather than directories? Or should plan 05 first surface this back to the user via a discuss-phase?
   - **Recommendation:** The planner should treat this as a refinement (not a contradiction) of D-05 since the locked decision is "manifest carries SHA-256 per file" and the actual file granularity is forced by the on-disk layout. Document this in plan 05's CONTEXT.md or research notes; do not re-open the discuss-phase. If the user dissents, plan 05 fails review and we cycle back.

2. **Session-end notification mechanism.**
   - **What we know:** `SessionCoordinator.anySessionActive` is the truth. No `NotificationCenter` post is currently emitted on session end.
   - **What's unclear:** Should `ModelUpdateService` poll `anySessionActive` (simple), or should `SessionCoordinator` post a Notification when transitioning to false (cleaner)?
   - **Recommendation:** Polling at 500 ms is fine — the loop only runs while an update is pending and `anySessionActive` is true (rare, brief). Simpler than introducing a new Notification name.

3. **`released_at` field in manifest (D-07 readable date).**
   - **What we know:** D-07 wants to display "v20260427 · Apr 27, 2026". The `version` is a date-shaped string, so the readable date can be parsed from it without an extra field.
   - **What's unclear:** Is the version always date-shaped, or could a future manifest use semantic versioning (`"3.1.0"`)?
   - **Recommendation:** Add an OPTIONAL `released_at` ISO8601 string to the manifest schema. If absent, attempt to parse `version` as `yyyyMMdd`. If neither yields a date, render version-only without a date suffix.

4. **Test fixture for the manifest publication step.**
   - **What we know:** Plan 05 will author the first manifest and instruct the developer to push it to `cnewfeldt/ps-transcribe-releases:main`.
   - **What's unclear:** Where does the SHA-256 list come from? Each `.mlmodelc/coremldata.bin`, etc. needs a hex digest.
   - **Recommendation:** Plan 05 includes a developer-side script (Swift CLI invocation, `shasum -a 256`, or a small Swift script) that walks `~/Library/Application Support/FluidAudio/Models/parakeet-tdt-0.6b-v3/` and emits the manifest JSON. Treat as part of the release tooling. Land this as a `Scripts/` folder if it doesn't already exist.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Swift toolchain | Build | ✓ | 6.3.1 (per Phase 16 SUMMARY) | — |
| FluidAudio package | reloadModels | ✓ | commit `ea50062` (pinned) | — |
| HuggingFace `huggingface.co` | Model file downloads | ✓ (assume — public unauthenticated) | n/a | None — phase fails gracefully with `.failed("Network error")` |
| GitHub `raw.githubusercontent.com` | Manifest fetch | ✓ (assume — public unauthenticated) | n/a | None — phase fails gracefully; user re-tries |
| `~/Library/Application Support/FluidAudio/Models/` | Model directory | ✓ (verified — exists with v3 model) | n/a | App creates the directory if missing |
| Sparkle (already in target) | Blocked-update UX (D-16) | ✓ | 2.7.0+ | — |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None.

This phase is online-only by definition (it's a remote update channel). Network failures surface as user-facing errors; they do not block the rest of the app.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Swift Testing (Swift 6+, `import Testing`, `@Suite`, `@Test`, `#expect`) |
| Config file | None — Swift Testing auto-discovers via `Tests/PSTranscribeTests/` |
| Quick run command | `cd PSTranscribe && swift test --filter ModelUpdate` |
| Full suite command | `cd PSTranscribe && swift test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MODEL-01 | 24h throttle gate for auto/opportunistic checks | unit | `swift test --filter ModelUpdateServiceTests/throttle` | ❌ Wave 0 (`ModelUpdateServiceTests.swift`) |
| MODEL-02 | Inline badge state (no modal/notification triggered) | unit (state machine) | `swift test --filter ModelUpdateServiceTests/updateAvailableState` | ❌ Wave 0 |
| MODEL-03 | `downloadAndApply()` only runs when explicitly invoked, never auto | unit | `swift test --filter ModelUpdateServiceTests/checkDoesNotDownload` | ❌ Wave 0 |
| MODEL-04 | Progress callbacks fire; cancel deletes staging | integration (URLProtocol mock) | `swift test --filter ModelUpdateServiceTests/downloadProgress` and `…/cancelCleanup` | ❌ Wave 0 |
| MODEL-05 | `installedModelVersion` written after successful apply | unit (with mock filesystem) | `swift test --filter ModelUpdateServiceTests/persistsVersion` | ❌ Wave 0 |
| MODEL-06 | Bad SHA-256 rejects swap; production untouched | unit | `swift test --filter ModelUpdateServiceTests/checksumMismatchRollsBack` | ❌ Wave 0 |
| MODEL-07 | Apply deferred when `anySessionActive == true`; applies on session end | unit (mock SessionCoordinator) | `swift test --filter ModelUpdateServiceTests/deferredApplyOnSession` | ❌ Wave 0 |
| MODEL-08 | Settings shows current vs available — manual UI verification (snapshot test optional) | manual UI / integration | Manual smoke test in 17-VERIFICATION.md | n/a |
| MODEL-09 | `min_app_version` gate — blocked state UX | unit (state machine) + manual UI | `swift test --filter ModelUpdateServiceTests/blockedByMinAppVersion` | ❌ Wave 0 |
| MODEL-10 | Disk-space preflight blocks Install when insufficient | unit (with mock `URL.resourceValues`) | `swift test --filter ModelUpdateServiceTests/insufficientDiskSpace` | ❌ Wave 0 |

**Cross-cutting tests:**
- `ModelManifestTests.swift` — Codable round-trip, version compare with `.numeric`, blocked-by-min-app-version logic. PURE unit test; no I/O.
- `TranscriptionEngineReloadModelsTests.swift` — exercises `reloadModels()` against an actual on-disk model directory (slow; gate behind `@Test(.tags(.integration))` so the default `swift test` runs in <30s).

### Sampling Rate

- **Per task commit:** `swift test --filter ModelUpdate` (just the new suites — should be <5s)
- **Per wave merge:** `swift test` (full 53+ suite run — current passes, must remain green)
- **Phase gate:** Full suite green before `/gsd-verify-work` + manual smoke test for MODEL-04 (cancel button), MODEL-08 (UI display), MODEL-10 (low-disk advisory)

### Wave 0 Gaps

- [ ] `PSTranscribe/Tests/PSTranscribeTests/ModelUpdateServiceTests.swift` — new file covering MODEL-01..07, MODEL-09..10
- [ ] `PSTranscribe/Tests/PSTranscribeTests/ModelManifestTests.swift` — new file for Codable + version compare
- [ ] `PSTranscribe/Tests/PSTranscribeTests/MockURLProtocol.swift` — shared test helper for URLSession mocking (or inline in ModelUpdateServiceTests if no other suite needs it)
- [ ] No framework install needed — Swift Testing is built-in

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V1 Architecture | yes | Threat-model documented in PITFALLS.md #11–#15. Manifest hosting on cnewfeldt/ps-transcribe-releases:main matches Sparkle's existing posture |
| V2 Authentication | no | The manifest and model files are public — no credentials |
| V3 Session Management | no | No user sessions in this phase |
| V4 Access Control | no | No multi-user concerns |
| V5 Input Validation | yes | Manifest JSON parsed via Codable (rejects malformed); SHA-256 verified per file (rejects tampered downloads); `min_app_version` gated (rejects incompatible) |
| V6 Cryptography | yes | `CryptoKit.SHA256` — first-party, hardware-accelerated, never hand-roll a hash |
| V7 Error Handling | yes | All errors surface to user via `updateState = .failed(message:)`; no silent swallow; failed staging directories preserved per D-15 for forensics |
| V8 Data Protection | yes | Model weights are public artifacts (no PII). The downloaded files contain no user data. SHA-256 ensures binary integrity |
| V9 Communications | yes | HTTPS-only enforced by URL scheme. App Transport Security default config blocks any HTTP fallback. No certificate pinning (matches Sparkle's posture) |
| V10 Malicious Code | yes | The threat is a malicious manifest swap → wrong model file. Mitigation: HTTPS+GitHub trust covers MITM; SHA-256 covers post-host tampering. EdDSA on the manifest is rejected per D-04 with rationale (manifest is on a project-controlled GitHub repo) |
| V11 Business Logic | yes | "Apply only when no session active" (D-19) is a business rule enforced by `sessionCoordinator.anySessionActive` gate |
| V12 Files & Resources | yes | Disk-space preflight (MODEL-10); atomic swap (MODEL-06); failed-staging retention with one-cycle rotation (D-15) |
| V13 API | n/a | No new authenticated APIs |
| V14 Configuration | yes | Manifest URL hardcoded in binary (CONTEXT.md `<specifics>`). No mutable runtime configuration of update endpoint |

### Known Threat Patterns for macOS native + URLSession + CryptoKit

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Manifest swap (attacker modifies JSON) | Tampering | HTTPS to a GitHub-controlled URL + SHA-256 verification of every model file in the manifest |
| Model file tampering on the wire | Tampering | SHA-256 verify after download, before swap |
| Partial download on network failure | Denial of Service | Staging directory + verify before swap; production model untouched |
| Disk-space exhaustion via repeated downloads | Denial of Service | Preflight `volumeAvailableCapacityForImportantUsage * 2`; Cancel deletes staging |
| Incompatible model version applied to incompatible SDK | Tampering / DoS | `min_app_version` gate (MODEL-09, D-16) |
| Process kill mid-swap | DoS | `FileManager.replaceItem` is atomic on APFS — either old or new, never partial |
| Replay attack with stale manifest | Tampering | Out of scope — the threat model accepts that a stale manifest just delays an update; it cannot install a worse model because of SHA-256 |
| Telemetry leak via custom headers | Information Disclosure | NO custom headers, NO User-Agent, NO query params (Claude's Discretion D-tele) |

## Plan Decomposition Recommendation

Five plans, executed in this order. Each plan is sized to fit a single executor session (~30–60 min) with clear acceptance criteria.

### Plan 17-01: ModelUpdateService skeleton + manifest fetch + version compare (Wave 1)

**Scope:**
- Create `PSTranscribe/Sources/PSTranscribe/Services/` directory
- New file `ModelUpdateService.swift` with `@Observable @MainActor final class`, the `ModelUpdateState` enum, the `ModelManifest` Codable struct, error type
- New file `ModelManifestTests.swift` covering Codable round-trip + version compare with `.numeric`
- Implement `checkForUpdate(force:)` — fetch manifest, decode, compare versions, set state
- AppSettings: add `modelAutoUpdateEnabled` key with `didSet` UserDefaults mirroring (default `true`)
- AppSettingsTests: add round-trip test for the new key

**Acceptance:**
- `swift build` clean
- `swift test --filter ModelManifestTests` 4–6 tests pass
- `swift test --filter ModelUpdateServiceTests/check` 3–4 tests pass (via `MockURLProtocol`)
- AppSettingsTests grow by one round-trip test
- All existing 53+ tests still pass

**Provides to next plan:** `ModelUpdateService` shell with `updateState`, `checkForUpdate()`, `ModelManifest` struct.

### Plan 17-02: Download + SHA-256 + cancel + disk-space preflight (Wave 2)

**Scope:**
- Implement `downloadAndApply()` *up to but not including the swap step* — disk-space preflight, per-file URL session bytes-loop with incremental SHA-256, staging directory creation, file-progress state updates, Task-cancellation-driven cleanup
- Test fixtures using `MockURLProtocol` returning byte streams of various sizes; assert SHA mismatch path; assert cancel deletes the staging directory
- Add tests for MODEL-04 progress + cancel, MODEL-06 checksum failure, MODEL-10 disk-space preflight

**Acceptance:**
- `swift test --filter ModelUpdateServiceTests/download` ~6–8 tests pass
- Manual smoke test (in 17-VERIFICATION.md): swap a real network call to a small fake manifest with a 100 KB test file, verify download → verify → fail SHA stop → cancel-mid-download deletes staging
- No leaks of `<repo>-staging/` after cancel or fail

**Provides to next plan:** Download pipeline with verified bytes on disk in `<repo>-staging/`.

### Plan 17-03: Atomic swap + reloadModels() + apply-deferral + rollback (Wave 2)

**Scope:**
- Add `func reloadModels() async throws` to `TranscriptionEngine` (mirrors `prepareModels()` at lines 79-103, with explicit nil-out + reload pattern)
- `TranscriptionEngineReloadModelsTests.swift` with `.tags(.integration)` exercising real on-disk reload
- Implement the swap step in `ModelUpdateService.downloadAndApply()` — `FileManager.replaceItem`, then `await transcriptionEngine.reloadModels()`, then write `installedModelVersion`, then cleanup the previous `*-failed-*` directory
- Implement apply-deferral: gate on `sessionCoordinator.anySessionActive == false`; if blocked, set `updatePending`, return; poll until clear, then run the swap step
- Implement rollback: on `reloadModels` throwing, rename the new directory to `<repo>-failed-{ISO8601}`, restore from the backup
- SessionCoordinator: uncomment lines 23-31, add `weak var modelUpdate: ModelUpdateService?`, update `anySessionActive` body
- Tests: MODEL-05 persistsVersion, MODEL-06 mismatch rolls back, MODEL-07 deferred apply, MODEL-09 min_app_version blocked

**Acceptance:**
- `swift test --filter ModelUpdate` ~14+ tests pass
- `swift test --filter TranscriptionEngineReloadModelsTests` 1–2 tests pass (slow; tagged integration)
- Full suite still green
- Code review confirms `Package.swift` / `Package.resolved` UNCHANGED (Pitfall #15 boundary)

**Provides to next plan:** A working ModelUpdateService end-to-end at the model layer; UI not yet wired.

### Plan 17-04: SettingsView UI + AppSettings wiring + PSTranscribeApp instantiation (Wave 3)

**Scope:**
- `PSTranscribeApp.swift`: instantiate `@State modelUpdateService: ModelUpdateService`; pass to SettingsView; assign `sessionCoordinator.modelUpdate = modelUpdateService` after both exist
- `SettingsView.swift`: add `Section("Speech Model")` per D-06 ordering; render the four states from D-07/D-08/D-09/D-16 (idle/up-to-date, update-available, downloading, blocked); the manual `[Check for Updates]` button per D-12
- `AppUpdaterController` reference threaded through for the blocked-state `[Check for App Update]` button
- `Info.plist`: no changes (manifest URL hardcoded in `ModelUpdateService.swift`, parallel to Sparkle's `SUFeedURL`)
- ContentView: wire the auto-check trigger — fire `Task { await modelUpdateService.checkForUpdate() }` ~10s after launch IF `modelLastCheckedDate > 24h ago` AND `modelAutoUpdateEnabled`

**Acceptance:**
- App launches; Settings > Speech Model section visible in correct order; ordering verified by manual UI step in 17-VERIFICATION.md
- Manual smoke test: Click Check for Updates → see "Up to date as of …"; modify mock manifest in plan tests to declare a newer version → see badge + Install button + ~520 MB size + click Install → see progress bar
- Auto-check fires once per 24h verifiable via `modelLastCheckedDate` UserDefaults inspection
- No regression in existing Settings flows (Audio, Obsidian, Notion, Privacy, Updates)

**Provides to next plan:** Phase 17 is functionally complete in the binary; the only remaining work is data publication.

### Plan 17-05: First-run backfill + manifest publication script + release prerequisite (Wave 3)

**Scope:**
- Implement D-14 first-run backfill in `ModelUpdateService.checkForUpdate()` — silent set of `installedModelVersion` if conditions met
- New script `Scripts/generate-model-manifest.sh` (or `.swift`) that walks `~/Library/Application Support/FluidAudio/Models/parakeet-tdt-0.6b-v3/`, computes SHA-256 per file, emits `model-manifest.json` to stdout (or to a chosen path)
- Author the FIRST manifest declaring v3 model as version `"20260427"` per D-03; commit it to `cnewfeldt/ps-transcribe-releases:main` (handled outside the worktree as a release prerequisite)
- 17-VERIFICATION.md: add a release checklist item — "publish first model-manifest.json before tagging v1.2"
- Update STATE.md or a `milestones/v1.2-ROADMAP.md` to capture this prerequisite

**Acceptance:**
- Script executes; produces valid JSON parseable by `ModelManifest.Codable`
- 17-VERIFICATION.md updated with manifest publication step + ticked SC-* items per actual verification
- The 5 success criteria in ROADMAP.md "Phase 17" all pass via the appropriate test or smoke-test step
- All 26 v1.2 requirements traceable to plans (MODEL-01..10 to plans 17-01..17-05)

**Provides:** Phase 17 ready for `/gsd-verify-work`. The manifest itself is the release prerequisite; without it, the live channel is broken.

**Dependency wave summary:**
- **Wave 1 (parallelizable but only one plan):** 17-01
- **Wave 2 (must run sequentially after 17-01):** 17-02, then 17-03 (17-03 depends on 17-02's staging directory)
- **Wave 3 (parallelizable after 17-03):** 17-04, then 17-05 (17-05 depends on 17-04's wired UI to verify backfill works in-app)

Total estimate: ~9.5–11 hours across 5 plans (matches SUMMARY.md's "Phase B ~9.5 hr" estimate).

## Sources

### Primary (HIGH confidence)

- `PSTranscribe/Sources/PSTranscribe/App/SessionCoordinator.swift` (lines 4–42) — direct inspection 2026-04-27, confirms the additive Optional pattern and pre-spelled-out `anySessionActive` extension
- `PSTranscribe/Sources/PSTranscribe/App/AppUpdaterController.swift` (lines 1–36) — direct inspection, the reference shape for `ModelUpdateService` (`@MainActor final class`, init-time wiring, presentStartupError pattern)
- `PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift` (lines 76–94) — direct inspection, the `didSet` UserDefaults pattern with optional `Date?` clearing
- `PSTranscribe/Sources/PSTranscribe/Transcription/TranscriptionEngine.swift` (lines 79–103) — direct inspection, the `prepareModels()` pattern that `reloadModels()` mirrors
- `PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift` (lines 11–69) — direct inspection, the Form/Section composition the new "Speech Model" section follows
- `PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift` (lines 1–80) — direct inspection, where `ModelUpdateService` is instantiated and wired into SessionCoordinator
- `PSTranscribe/Sources/PSTranscribe/Info.plist` (lines 13–34) — direct inspection, `SUFeedURL` parallel and current `CFBundleShortVersionString = "2.1.1"`
- `PSTranscribe/.build/checkouts/FluidAudio/Sources/FluidAudio/ASR/Parakeet/AsrModels.swift` (lines 440–450) — direct inspection, `downloadAndLoad` does both download-if-missing and load-from-disk
- `PSTranscribe/.build/checkouts/FluidAudio/Sources/FluidAudio/DownloadUtils.swift` (lines 192–204) — direct inspection, the `allModelsExist` short-circuit that makes `reloadModels()` safe to call without re-downloading
- `PSTranscribe/.build/checkouts/FluidAudio/Sources/FluidAudio/ModelNames.swift` (lines 115–141) — direct inspection, `Repo.folderName` strips `-coreml` (CONTEXT.md folder-name correction)
- `PSTranscribe/Tests/PSTranscribeTests/AppSettingsTests.swift` and `SessionCoordinatorTests.swift` — direct inspection, Swift Testing conventions
- `~/Library/Application Support/FluidAudio/Models/parakeet-tdt-0.6b-v3/` — direct file system inspection, actual on-disk file structure (`.mlmodelc` directories, NOT `.mlpackage`)
- `https://huggingface.co/api/models/FluidInference/parakeet-tdt-0.6b-v3-coreml/tree/main` and `.../tree/main/Decoder.mlmodelc` — fetched 2026-04-27, confirms HuggingFace serves `.mlmodelc` directories with sub-files (not single archives)
- `.planning/phases/17-model-auto-update/17-CONTEXT.md` — full file, all 19 D-* decisions
- `.planning/phases/16-foundation/16-04-SUMMARY.md` — Phase 16 SessionCoordinator integration details
- `.planning/research/ARCHITECTURE.md` §"Feature 3: Model Auto-Update" — full data-flow diagram

### Secondary (MEDIUM confidence)

- [Apple Developer: SHA256 (CryptoKit)](https://developer.apple.com/documentation/cryptokit/sha256) — confirms incremental `update(data:)` + `finalize()` API
- [Apple Developer: FileManager.ItemReplacementOptions](https://developer.apple.com/documentation/foundation/filemanager/itemreplacementoptions) — confirms atomic semantics + cross-volume restriction
- [Apple Developer: replaceItem(at:withItemAt:backupItemName:options:resultingItemURL:)](https://rusutikaa.github.io/docs/developer.apple.com/documentation/foundation/filemanager/1412432-replaceitem.html) — function signature and behavior contract
- [Approachable Concurrency in Swift 6.2](https://www.avanderlee.com/concurrency/approachable-concurrency-in-swift-6-2-a-clear-guide/) — confirms the @MainActor-by-default pattern aligned with current codebase conventions
- [The Complete Guide to Swift Concurrency Swift 6](https://medium.com/@thakurneeshu280/the-complete-guide-to-swift-concurrency-from-threading-to-actors-in-swift-6-a9cf006a19ac) — concurrency patterns
- [URLSession in Swift: The Essential Guide](https://matteomanferdini.com/swift-urlsession/) — `URLSession.bytes(for:)` AsyncSequence usage
- [HuggingFace Hub File Downloads](https://huggingface.co/docs/huggingface_hub/guides/download) — confirms `resolve/main/{path}` URL pattern; the per-file URL pattern in the manifest is correct

### Tertiary (LOW confidence — flag for verification at implementation time)

- HuggingFace redirect handling for `resolve/main/{path}` URLs — assumed default URLSession 10-hop redirect handling suffices. Not strictly verified but consistent with `DownloadUtils.swift`'s working implementation against the same URL pattern.

## Metadata

**Confidence breakdown:**
- Locked decisions (D-01..D-19): HIGH — directly read from CONTEXT.md
- Standard stack (URLSession, CryptoKit, FileManager): HIGH — verified against Apple docs and existing codebase usage in NotionService.swift
- Architecture patterns (`@Observable @MainActor`, late-binding, weak references): HIGH — verified against Phase 16 SessionCoordinator and AppUpdaterController
- Pitfalls (manifest schema, folder name correction, FluidAudio reload): HIGH — verified by reading FluidAudio sources and on-disk layout
- Plan decomposition: MEDIUM — proposed structure honors the locked decisions and dependency waves; the user/planner may refine boundaries
- Test strategy: HIGH — verified Swift Testing is the project standard; URLProtocol mock pattern is well-established

**Research date:** 2026-04-27
**Valid until:** 2026-05-27 (30 days — Apple platform APIs are stable; the only fast-moving piece is the manifest schema, which is project-controlled)
