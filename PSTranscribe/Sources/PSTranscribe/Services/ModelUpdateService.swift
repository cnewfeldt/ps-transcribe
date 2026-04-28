/// ModelUpdateService.swift
/// Phase 17 — Model Auto-Update channel (independent of Sparkle).
///
/// Key decisions honored here:
///   D-01 Manifest at raw.githubusercontent.com/cnewfeldt/ps-transcribe-releases/main/model-manifest.json
///   D-04 HTTPS + GitHub trust only; NO EdDSA, no custom request headers, no query params (telemetry constraint)
///   D-05 Manifest schema: model_id, version, min_app_version, total_size_bytes, released_at?, files[]
///   D-13 modelAutoUpdateEnabled == false suppresses auto/opportunistic checks; force always proceeds
///   D-16 min_app_version gate produces .blocked(.minAppVersion(...)) state
///   D-17 String.compare(_:options:.numeric) for all version comparisons

import CryptoKit
import Foundation
import Observation
import os

// MARK: - Constants

/// Per CONTEXT.md D-01. Hardcoded — paired with Sparkle's SUFeedURL infrastructure (Info.plist:29-30).
/// No flexibility intended.
private let modelManifestURL = URL(string: "https://raw.githubusercontent.com/cnewfeldt/ps-transcribe-releases/main/model-manifest.json")!

/// 24h throttle gate per MODEL-01 / D-10.
private let modelCheckThrottleInterval: TimeInterval = 24 * 60 * 60

// MARK: - ModelUpdateService

@MainActor
@Observable
final class ModelUpdateService {
    var updateState: ModelUpdateState = .idle
    var isApplying: Bool = false

    private weak var settings: AppSettings?
    // Wired by Plans 17-03 / 17-04:
    private weak var sessionCoordinator: SessionCoordinator?
    private weak var transcriptionEngine: TranscriptionEngine?

    private let log = Logger(subsystem: "com.pstranscribe.app", category: "ModelUpdate")
    private let urlSession: URLSession
    /// The installed app version string, injected for testability. Defaults to reading
    /// CFBundleShortVersionString from Bundle.main at init time (the production value).
    private let installedAppVersion: String

    // MARK: - Plan 17-02: download pipeline injection points

    /// Test-only override for the models root directory. Defaults to nil (real path used).
    /// Unit tests set this to a temp directory to sandbox all file I/O.
    var modelsRootOverride: URL?

    /// Per RESEARCH Pitfall #2: on-disk folder is `parakeet-tdt-0.6b-v3` (NOT `-coreml` suffixed).
    /// FluidAudio's `Repo.folderName` strips the suffix at ModelNames.swift:139.
    ///
    /// Test-only override: unit tests set `modelsRootOverride` to a temp directory so staging
    /// paths sandbox to ephemeral storage. Plan 17-03 also consumes this for swap-rollback tests.
    private var modelsRoot: URL {
        if let override = modelsRootOverride { return override }
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("FluidAudio/Models")
    }

    private var modelDirectory: URL {
        modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3")
    }

    private var stagingDirectory: URL {
        modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3-staging")
    }

    /// Test-injectable disk-space provider. Default: real URL.resourceValues lookup.
    /// Tests override via `service.diskSpaceProvider = { _ in 100 }` for low-disk simulation.
    var diskSpaceProvider: @Sendable (URL) throws -> Int64 = { url in
        let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return Int64(values.volumeAvailableCapacityForImportantUsage ?? 0)
    }

    // MARK: - Plan 17-03: apply-step injection points

    /// Test-injectable reload handler. Default nil → real path via transcriptionEngine.reloadModels().
    /// Tests set this to a closure that simulates success or failure without requiring real FluidAudio models.
    var reloadHandler: (@MainActor () async throws -> Void)?

    /// Test-injectable session-active gate. Default delegates to sessionCoordinator.anySessionActive.
    /// Tests override to simulate apply-deferral on active session (D-19).
    var anySessionActiveProvider: @MainActor () -> Bool = { false }

    /// Stored task handle so `cancelDownload()` can propagate cancellation.
    private var downloadTask: Task<Void, Error>?

    init(settings: AppSettings? = nil,
         engine: TranscriptionEngine? = nil,
         sessionCoordinator: SessionCoordinator? = nil,
         session: URLSession = .shared,
         appVersion: String? = nil) {
        self.settings = settings
        self.transcriptionEngine = engine
        self.sessionCoordinator = sessionCoordinator
        self.urlSession = session
        self.installedAppVersion = appVersion
            ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
            ?? ""
        // Wire the default anySessionActiveProvider to read from the coordinator.
        // Tests can replace this closure to simulate apply-deferral without a real session.
        self.anySessionActiveProvider = { [weak sessionCoordinator] in
            sessionCoordinator?.anySessionActive ?? false
        }
    }

    // MARK: - Public API

    /// Fetch manifest, compare versions, set updateState. NEVER triggers download (MODEL-03).
    ///
    /// - Parameter force: `true` bypasses the 24h throttle and `modelAutoUpdateEnabled` gate
    ///   (used by the manual [Check for Updates] button, D-12). `false` respects both gates.
    func checkForUpdate(force: Bool = false) async {
        // Step 1 — disabled flag gate (D-13)
        if !force, settings?.modelAutoUpdateEnabled == false { return }

        // Step 2 — 24h throttle gate (MODEL-01 / D-10)
        if !force,
           let lastChecked = settings?.modelLastCheckedDate,
           Date().timeIntervalSince(lastChecked) < modelCheckThrottleInterval {
            return
        }

        updateState = .checking

        do {
            let manifest = try await fetchManifest()
            settings?.modelLastCheckedDate = Date()

            // Step 3 — min_app_version gate (MODEL-09 / D-16 / D-17)
            if installedAppVersion.compare(manifest.min_app_version, options: .numeric) == .orderedAscending {
                updateState = .blocked(reason: .minAppVersion(
                    required: manifest.min_app_version,
                    installed: installedAppVersion,
                    newModelVersion: manifest.version
                ))
                return
            }

            // Step 4 — version comparison (MODEL-02 / D-07 / D-17)
            let installedModel = settings?.installedModelVersion ?? ""
            if installedModel.compare(manifest.version, options: .numeric) == .orderedAscending {
                let releasedAt = parseReleasedAt(manifest)
                updateState = .updateAvailable(
                    version: manifest.version,
                    sizeBytes: manifest.total_size_bytes,
                    releasedAt: releasedAt
                )
            } else {
                updateState = .upToDate(asOf: Date())
            }
        } catch {
            updateState = .failed(message: error.localizedDescription)
            log.error("checkForUpdate failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Fetch and decode the model manifest. Exposed for tests.
    /// Throws `ModelUpdateError` on network or decode failure.
    func fetchManifest() async throws -> ModelManifest {
        let (data, response) = try await urlSession.data(for: URLRequest(url: modelManifestURL))
        guard let http = response as? HTTPURLResponse else {
            throw ModelUpdateError.manifestFetchFailed(statusCode: nil)
        }
        guard (200...299).contains(http.statusCode) else {
            throw ModelUpdateError.manifestFetchFailed(statusCode: http.statusCode)
        }
        do {
            return try JSONDecoder().decode(ModelManifest.self, from: data)
        } catch {
            throw ModelUpdateError.manifestDecodeFailed(String(describing: error))
        }
    }

    // MARK: - Download pipeline (Plan 17-02)

    func downloadAndApply() async {
        // Only proceed if state is .updateAvailable — capture the version + size for later restore.
        guard case .updateAvailable(let targetVersion, let totalBytes, _) = updateState else {
            log.debug("downloadAndApply called in state \(String(describing: self.updateState), privacy: .public) — ignoring")
            return
        }

        // Re-fetch the manifest to get per-file details (state stores only version+size).
        let manifest: ModelManifest
        do {
            manifest = try await fetchManifest()
        } catch {
            updateState = .failed(message: "Manifest re-fetch failed: \(error.localizedDescription)")
            return
        }
        guard manifest.version == targetVersion else {
            updateState = .failed(message: "Manifest version changed during download. Try again.")
            return
        }

        // Disk-space preflight (MODEL-10 / Pitfall #14).
        do {
            try FileManager.default.createDirectory(at: modelsRoot, withIntermediateDirectories: true)
            try checkDiskSpace(needed: totalBytes)
        } catch let ModelUpdateError.insufficientDiskSpace(needed, available) {
            updateState = .blocked(reason: .insufficientDiskSpace(needed: needed, available: available))
            return
        } catch {
            updateState = .failed(message: error.localizedDescription)
            return
        }

        // Wipe any pre-existing staging directory from a previous interrupted run.
        try? wipeStaging()

        do {
            try FileManager.default.createDirectory(at: stagingDirectory, withIntermediateDirectories: true)
        } catch {
            updateState = .failed(message: "Could not create staging directory: \(error.localizedDescription)")
            return
        }

        updateState = .downloading(progress: 0, completedBytes: 0, totalBytes: manifest.total_size_bytes)

        // Spawn the download task so cancellation can target it independently.
        downloadTask = Task { [weak self] in
            try await self?.runDownload(manifest)
        }

        do {
            try await downloadTask?.value
            // All files downloaded and SHA-256 verified.
            // Transition through .verifying then hand off to applySwap for the atomic swap.
            updateState = .verifying
            await applySwap(manifest)
        } catch {
            try? wipeStaging()
            // Treat both Swift CancellationError and URLError.cancelled as user-initiated cancel.
            // URLSession throws URLError(.cancelled) when its underlying task is cancelled via
            // Task cancellation propagation (the URLSession task is cancelled from Swift Concurrency).
            let isCancellation = error is CancellationError
                || (error as? URLError)?.code == .cancelled
                || downloadTask?.isCancelled == true
            if isCancellation {
                // Restore .updateAvailable so the user can retry.
                let releasedAt = parseReleasedAt(manifest)
                updateState = .updateAvailable(
                    version: manifest.version,
                    sizeBytes: manifest.total_size_bytes,
                    releasedAt: releasedAt
                )
            } else {
                updateState = .failed(message: error.localizedDescription)
            }
        }
        downloadTask = nil
    }

    func cancelDownload() {
        downloadTask?.cancel()
        // State transition and staging cleanup happen inside downloadAndApply's catch block.
    }

    // MARK: - Private download helpers

    private func runDownload(_ manifest: ModelManifest) async throws {
        var totalCompleted: Int64 = 0
        for file in manifest.files {
            try Task.checkCancellation()

            // T-17-02-05: reject path traversal names (containing ".." or starting with "/").
            guard !file.name.contains(".."), !file.name.hasPrefix("/") else {
                throw ModelUpdateError.httpError(url: file.url, statusCode: 0)
            }

            guard let url = URL(string: file.url) else {
                throw ModelUpdateError.httpError(url: file.url, statusCode: 0)
            }

            let destination = stagingDirectory.appendingPathComponent(file.name)
            try FileManager.default.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            let completedBeforeThisFile = totalCompleted
            try await downloadFile(
                from: url,
                to: destination,
                expectedSize: file.size,
                expectedSHA256: file.sha256,
                onChunk: { [weak self] bytesThisFile in
                    guard let self else { return }
                    let running = completedBeforeThisFile + bytesThisFile
                    self.updateState = .downloading(
                        progress: Double(running) / Double(max(manifest.total_size_bytes, 1)),
                        completedBytes: running,
                        totalBytes: manifest.total_size_bytes
                    )
                }
            )
            totalCompleted += file.size
        }
    }

    private func downloadFile(
        from url: URL,
        to destination: URL,
        expectedSize: Int64,
        expectedSHA256 hex: String,
        onChunk: @MainActor @Sendable (Int64) -> Void
    ) async throws {
        let (bytes, response) = try await urlSession.bytes(for: URLRequest(url: url))
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw ModelUpdateError.httpError(url: url.absoluteString, statusCode: code)
        }

        FileManager.default.createFile(atPath: destination.path, contents: nil)
        let handle = try FileHandle(forWritingTo: destination)
        defer { try? handle.close() }

        var hasher = SHA256()
        var bytesWritten: Int64 = 0
        var buffer = Data()
        buffer.reserveCapacity(64 * 1024)

        for try await byte in bytes {
            try Task.checkCancellation()
            buffer.append(byte)
            if buffer.count >= 64 * 1024 {
                try handle.write(contentsOf: buffer)
                hasher.update(data: buffer)
                bytesWritten += Int64(buffer.count)
                let snapshot = bytesWritten
                await MainActor.run { onChunk(snapshot) }
                buffer.removeAll(keepingCapacity: true)
            }
        }

        // Flush remaining bytes.
        if !buffer.isEmpty {
            try handle.write(contentsOf: buffer)
            hasher.update(data: buffer)
            bytesWritten += Int64(buffer.count)
            let snapshot = bytesWritten
            await MainActor.run { onChunk(snapshot) }
        }

        let digest = hasher.finalize()
        let actualHex = digest.map { String(format: "%02x", $0) }.joined()
        guard actualHex.lowercased() == hex.lowercased() else {
            throw ModelUpdateError.checksumMismatch(
                file: destination.lastPathComponent,
                expected: hex.lowercased(),
                actual: actualHex.lowercased()
            )
        }
    }

    private func checkDiskSpace(needed: Int64) throws {
        let available = try diskSpaceProvider(modelsRoot)
        let required = needed * 2   // staging + production coexistence (CONTEXT.md Claude's-Discretion)
        guard available >= required else {
            throw ModelUpdateError.insufficientDiskSpace(needed: required, available: available)
        }
    }

    private func wipeStaging() throws {
        if FileManager.default.fileExists(atPath: stagingDirectory.path) {
            try FileManager.default.removeItem(at: stagingDirectory)
        }
    }

    // MARK: - Plan 17-03: Apply step (atomic swap + reload + persist + rollback)

    /// Performs the apply step: waits for any active session to end, atomically swaps the
    /// staging directory into production via FileManager.replaceItem, calls reloadModels()
    /// for hot-swap, persists installedModelVersion, and rotates prior failed-staging dirs.
    ///
    /// On reload failure: rolls back by swapping the backup back to production, moves the
    /// broken new model to a `*-failed-{ISO8601}` forensic directory (D-15), sets .failed.
    ///
    /// Per CONTEXT.md D-18 / D-19: isApplying is true ONLY during the swap+reload window
    /// (after .verifying succeeds, before .applied). False at all other times.
    func applySwap(_ manifest: ModelManifest) async {
        // 1. Apply-deferral gate (D-19 / MODEL-07): wait until no session is active.
        while anySessionActiveProvider() {
            try? await Task.sleep(for: .milliseconds(500))
        }

        isApplying = true
        defer { isApplying = false }
        updateState = .applying

        // 2. Rotate any prior failed-staging directory (D-15 — keep one cycle of forensics).
        rotatePriorFailedStaging()

        // 3. Atomic directory swap via moveItem (uses rename(2) on APFS — atomic per T-17-03-01).
        //    Strategy: move production -> backup, move staging -> production.
        //    On reload failure: move production (broken) -> failed dir, move backup -> production.
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "")
        let backupURL = modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3-backup-\(timestamp)")

        // Move production to backup (preserves old model for rollback).
        // If production does not exist yet (fresh install path), skip the backup move.
        let productionExisted = FileManager.default.fileExists(atPath: modelDirectory.path)
        if productionExisted {
            do {
                try FileManager.default.moveItem(at: modelDirectory, to: backupURL)
            } catch {
                log.error("Could not move production to backup: \(error.localizedDescription, privacy: .public)")
                moveStagingToFailed(error: error)
                updateState = .failed(message: "Swap failed (backup step): \(error.localizedDescription)")
                return
            }
        }

        // Move staging into production position.
        do {
            try FileManager.default.moveItem(at: stagingDirectory, to: modelDirectory)
        } catch {
            // Staging move failed — restore backup if it was created.
            log.error("Could not move staging to production: \(error.localizedDescription, privacy: .public)")
            if productionExisted {
                try? FileManager.default.moveItem(at: backupURL, to: modelDirectory)
            }
            moveStagingToFailed(error: error)
            updateState = .failed(message: "Swap failed (staging step): \(error.localizedDescription)")
            return
        }

        // 4. Hot-swap models (CONTEXT.md D-18; RESEARCH reloadModels pattern).
        do {
            if let handler = reloadHandler {
                try await handler()
            } else {
                try await transcriptionEngine?.reloadModels()
            }
        } catch {
            // Reload failed — roll back the swap so the previous model is restored (T-17-03-02).
            log.error("reloadModels failed after swap; rolling back: \(error.localizedDescription, privacy: .public)")
            do {
                try rollbackSwap(backupURL: backupURL, productionExisted: productionExisted)
            } catch let rollbackError {
                log.error("Rollback also failed: \(rollbackError.localizedDescription, privacy: .public)")
            }
            updateState = .failed(message: "Reload failed: \(error.localizedDescription)")
            return
        }

        // 5. Cleanup the backup directory (best-effort; production is stable, backup is stale).
        try? FileManager.default.removeItem(at: backupURL)

        // 6. Persist new version (MODEL-05). Written LAST — only after reload succeeds (T-17-03-08).
        settings?.installedModelVersion = manifest.version

        // 7. Transition to .applied.
        updateState = .applied(version: manifest.version)
        log.info("Model update applied successfully: \(manifest.version, privacy: .public)")
    }

    /// Polls every 500ms until anySessionActiveProvider returns false.
    /// Called by applySwap when a session is active at apply time (D-19).
    private func waitForSessionEnd() async {
        while anySessionActiveProvider() {
            try? await Task.sleep(for: .milliseconds(500))
        }
    }

    /// Removes any existing `parakeet-tdt-0.6b-v3-failed-*` directory under modelsRoot
    /// so at most one forensic directory exists at any time (D-15 — one cycle of visibility).
    private func rotatePriorFailedStaging() {
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: modelsRoot, includingPropertiesForKeys: nil) else { return }
        for entry in entries where entry.lastPathComponent.hasPrefix("parakeet-tdt-0.6b-v3-failed-") {
            try? FileManager.default.removeItem(at: entry)
        }
    }

    /// After the swap succeeds but reloadModels fails, reverses the swap:
    /// moves the broken new model from production to a `*-failed-{ISO}` forensic dir,
    /// then moves the backup (prior good model) back to production.
    /// If `productionExisted` is false (fresh install path), the backup does not exist —
    /// in that case we just move the broken model to failed and leave production absent.
    private func rollbackSwap(backupURL: URL, productionExisted: Bool) throws {
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "")
        let failedDir = modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3-failed-\(timestamp)")
        // Move broken new model out of production into forensic dir
        try FileManager.default.moveItem(at: modelDirectory, to: failedDir)
        // Restore prior good model from backup (if one existed)
        if productionExisted {
            try FileManager.default.moveItem(at: backupURL, to: modelDirectory)
        }
    }

    /// Moves the staging directory to a `*-failed-{ISO}` forensic path when the swap itself
    /// fails (production is untouched in this case). Staging remains as the failed artifact.
    private func moveStagingToFailed(error: Error) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "")
        let failedDir = modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3-failed-\(timestamp)")
        if FileManager.default.fileExists(atPath: stagingDirectory.path) {
            try? FileManager.default.moveItem(at: stagingDirectory, to: failedDir)
        }
    }

    // MARK: - Private helpers

    /// Parse `released_at` field; fall back to parsing `version` as yyyyMMdd; otherwise nil.
    /// Per RESEARCH Open Question #3.
    private func parseReleasedAt(_ manifest: ModelManifest) -> Date? {
        if let released = manifest.released_at {
            let iso = ISO8601DateFormatter()
            if let d = iso.date(from: released) { return d }
        }
        // Fallback: parse version string as yyyyMMdd
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.date(from: manifest.version)
    }
}

// MARK: - ModelUpdateState

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

// MARK: - BlockedReason

enum BlockedReason: Equatable, Sendable {
    case minAppVersion(required: String, installed: String, newModelVersion: String)
    case insufficientDiskSpace(needed: Int64, available: Int64)
}

// MARK: - ModelUpdateError

enum ModelUpdateError: LocalizedError, Equatable, Sendable {
    case manifestFetchFailed(statusCode: Int?)
    case manifestDecodeFailed(String)
    case insufficientDiskSpace(needed: Int64, available: Int64)
    case checksumMismatch(file: String, expected: String, actual: String)
    case httpError(url: String, statusCode: Int)
    case swapFailed(String)
    case reloadFailed(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .manifestFetchFailed(let code):
            if let code {
                return "Failed to fetch model manifest (HTTP \(code))."
            }
            return "Failed to fetch model manifest."
        case .manifestDecodeFailed:
            return "Model manifest could not be read. Please try again later."
        case .insufficientDiskSpace(let needed, let available):
            let neededMB = needed / 1_048_576
            let availableMB = available / 1_048_576
            return "Not enough disk space available. Needs \(neededMB) MB, \(availableMB) MB free."
        case .checksumMismatch:
            return "Downloaded model integrity check failed."
        case .httpError(_, let code):
            return "HTTP error \(code) while downloading model."
        case .swapFailed(let msg):
            return "Model update installation failed: \(msg)"
        case .reloadFailed(let msg):
            return "Model reload failed after update: \(msg)"
        case .cancelled:
            return "Model update cancelled."
        }
    }
}

// MARK: - ModelManifest

struct ModelManifest: Codable, Sendable, Equatable {
    let model_id: String
    let version: String
    let min_app_version: String
    let total_size_bytes: Int64
    let released_at: String?    // optional ISO8601 -- RESEARCH Open Question #3
    let files: [ManifestFile]

    struct ManifestFile: Codable, Sendable, Equatable {
        let name: String      // relative path inside <repo>/, may include slashes (RESEARCH Pitfall #1)
        let url: String       // absolute HuggingFace resolve URL
        let sha256: String    // hex string, lowercase
        let size: Int64
    }
}
