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

    // MARK: - Plan 17-02 injection points (stubs; bodies land in Task 2)

    /// Test-only override for the models root directory. Defaults to nil (real path used).
    /// Tests set this to a temp directory to sandbox file I/O.
    var modelsRootOverride: URL?

    /// Test-injectable disk-space provider. Default: real URL.resourceValues lookup.
    /// Tests override via `service.diskSpaceProvider = { _ in 100 }` for low-disk simulation.
    var diskSpaceProvider: @Sendable (URL) throws -> Int64 = { url in
        let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return Int64(values.volumeAvailableCapacityForImportantUsage ?? 0)
    }

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

    /// Plan 17-02 lands the body.
    func downloadAndApply() async {
        log.debug("downloadAndApply not yet implemented (Plan 17-02)")
    }

    /// Plan 17-02 lands the body.
    func cancelDownload() {
        log.debug("cancelDownload not yet implemented (Plan 17-02)")
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
