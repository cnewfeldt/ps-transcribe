import Testing
import Foundation
import CryptoKit
@testable import PSTranscribe

@Suite("ModelUpdateService", .serialized)
struct ModelUpdateServiceTests {

    // UserDefaults keys touched by Phase 17 Plan 01 tests.
    private static let v17Keys = ["modelAutoUpdateEnabled", "installedModelVersion", "modelLastCheckedDate"]

    fileprivate static func clearV17Keys() {
        for k in v17Keys { UserDefaults.standard.removeObject(forKey: k) }
    }

    // MARK: - Helpers

    /// Returns a manifest JSON Data with configurable version and min_app_version.
    private func manifestData(version: String = "20260601",
                              minAppVersion: String = "1.0.0",
                              releasedAt: String? = nil) -> Data {
        let releasedAtField: String
        if let ra = releasedAt {
            releasedAtField = ",\"released_at\":\"\(ra)\""
        } else {
            releasedAtField = ""
        }
        let json = """
        {
            "model_id": "parakeet-tdt-0.6b-v3-coreml",
            "version": "\(version)",
            "min_app_version": "\(minAppVersion)",
            "total_size_bytes": 545312000\(releasedAtField),
            "files": [
                { "name": "encoder.mlpackage", "url": "https://huggingface.co/a/c", "sha256": "def456", "size": 234567890 }
            ]
        }
        """
        return Data(json.utf8)
    }

    /// Installs a mock HTTP 200 response carrying `data` for any URL.
    private func installResponder(data: Data, statusCode: Int = 200) {
        MockURLProtocol.responder = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (response, data)
        }
    }

    // MARK: - Active tests (must be GREEN after Task 2)

    @Test @MainActor func initialStateIsIdle() {
        let service = ModelUpdateService()
        #expect(service.updateState == .idle)
        #expect(service.isApplying == false)
    }

    @Test @MainActor func updateAvailableState() async {
        Self.clearV17Keys()
        defer {
            Self.clearV17Keys()
            MockURLProtocol.responder = nil
        }

        let settings = AppSettings()
        settings.installedModelVersion = "20260427"
        installResponder(data: manifestData(version: "20260601", minAppVersion: "1.0.0",
                                            releasedAt: "2026-06-01T00:00:00Z"))

        // Inject appVersion "2.1.1" (matches Info.plist) so min_app_version "1.0.0" does not block.
        let service = ModelUpdateService(settings: settings, session: .mocked(), appVersion: "2.1.1")
        await service.checkForUpdate(force: true)

        if case .updateAvailable(let ver, let sizeBytes, _) = service.updateState {
            #expect(ver == "20260601")
            #expect(sizeBytes == 545312000)
        } else {
            Issue.record("Expected .updateAvailable, got \(service.updateState)")
        }
    }

    @Test @MainActor func checkDoesNotDownload() async {
        Self.clearV17Keys()
        defer {
            Self.clearV17Keys()
            MockURLProtocol.responder = nil
        }

        let settings = AppSettings()
        settings.installedModelVersion = "20260427"
        installResponder(data: manifestData(version: "20260601", minAppVersion: "1.0.0"))

        // Inject appVersion so min_app_version "1.0.0" does not block.
        let service = ModelUpdateService(settings: settings, session: .mocked(), appVersion: "2.1.1")
        await service.checkForUpdate(force: true)

        // Assert state is NOT one of the download/apply states
        switch service.updateState {
        case .downloading, .verifying, .applying, .applied:
            Issue.record("checkForUpdate must not trigger download/apply; got \(service.updateState)")
        default:
            break  // any non-download state is acceptable
        }
    }

    @Test @MainActor func blockedByMinAppVersion() async {
        Self.clearV17Keys()
        defer {
            Self.clearV17Keys()
            MockURLProtocol.responder = nil
        }

        let settings = AppSettings()
        settings.installedModelVersion = "20260427"
        // min_app_version "99.0.0" is greater than injected appVersion "2.1.1" — must block.
        installResponder(data: manifestData(version: "20260601", minAppVersion: "99.0.0"))

        let service = ModelUpdateService(settings: settings, session: .mocked(), appVersion: "2.1.1")
        await service.checkForUpdate(force: true)

        if case .blocked(.minAppVersion(let req, _, _)) = service.updateState {
            #expect(req == "99.0.0")
        } else {
            Issue.record("Expected .blocked(.minAppVersion(...)), got \(service.updateState)")
        }
    }

    @Test @MainActor func throttleSuppressesNonForcedCheck() async {
        Self.clearV17Keys()
        defer {
            Self.clearV17Keys()
            MockURLProtocol.responder = nil
        }

        let settings = AppSettings()
        // Set last checked to now -- within 24h throttle window
        settings.modelLastCheckedDate = Date()

        var responderInvoked = false
        MockURLProtocol.responder = { request in
            responderInvoked = true
            let response = HTTPURLResponse(url: request.url!, statusCode: 200,
                                          httpVersion: "HTTP/1.1", headerFields: nil)!
            return (response, self.manifestData())
        }

        let service = ModelUpdateService(settings: settings, session: .mocked())
        await service.checkForUpdate(force: false)

        #expect(responderInvoked == false, "Throttle should suppress check within 24h")
    }

    @Test @MainActor func forcedCheckBypassesThrottle() async {
        Self.clearV17Keys()
        defer {
            Self.clearV17Keys()
            MockURLProtocol.responder = nil
        }

        let settings = AppSettings()
        // Set last checked to now -- within 24h throttle window
        settings.modelLastCheckedDate = Date()
        settings.installedModelVersion = "20260427"

        var responderInvokedCount = 0
        MockURLProtocol.responder = { request in
            responderInvokedCount += 1
            let response = HTTPURLResponse(url: request.url!, statusCode: 200,
                                          httpVersion: "HTTP/1.1", headerFields: nil)!
            return (response, self.manifestData())
        }

        let service = ModelUpdateService(settings: settings, session: .mocked(), appVersion: "2.1.1")
        await service.checkForUpdate(force: true)

        #expect(responderInvokedCount == 1, "Forced check should bypass throttle and invoke responder once")
    }

    @Test @MainActor func disabledFlagSuppressesAutoCheck() async {
        Self.clearV17Keys()
        defer {
            Self.clearV17Keys()
            MockURLProtocol.responder = nil
        }

        let settings = AppSettings()
        settings.modelAutoUpdateEnabled = false
        // Set last checked to distant past so throttle doesn't apply
        settings.modelLastCheckedDate = Date(timeIntervalSince1970: 0)

        var responderInvoked = false
        MockURLProtocol.responder = { request in
            responderInvoked = true
            let response = HTTPURLResponse(url: request.url!, statusCode: 200,
                                          httpVersion: "HTTP/1.1", headerFields: nil)!
            return (response, self.manifestData())
        }

        let service = ModelUpdateService(settings: settings, session: .mocked())
        await service.checkForUpdate(force: false)

        #expect(responderInvoked == false, "Disabled flag should suppress non-forced auto check")
    }

    @Test @MainActor func disabledFlagDoesNotSuppressForcedCheck() async {
        Self.clearV17Keys()
        defer {
            Self.clearV17Keys()
            MockURLProtocol.responder = nil
        }

        let settings = AppSettings()
        settings.modelAutoUpdateEnabled = false
        settings.modelLastCheckedDate = Date(timeIntervalSince1970: 0)
        settings.installedModelVersion = "20260427"

        var responderInvoked = false
        MockURLProtocol.responder = { request in
            responderInvoked = true
            let response = HTTPURLResponse(url: request.url!, statusCode: 200,
                                          httpVersion: "HTTP/1.1", headerFields: nil)!
            return (response, self.manifestData())
        }

        let service = ModelUpdateService(settings: settings, session: .mocked(), appVersion: "2.1.1")
        await service.checkForUpdate(force: true)

        #expect(responderInvoked == true, "Forced check must bypass disabled flag")
    }

    // MARK: - Plan 17-02 tests: download pipeline, cancel, checksum, disk-space

    // MARK: - Helpers for Plan 17-02 tests

    /// Computes the lowercase hex SHA-256 of a Data blob.
    fileprivate func sha256Hex(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Builds a `ModelManifest` with N files of the given test bodies. Computes correct SHAs.
    fileprivate func makeManifest(
        files: [(name: String, body: Data)],
        version: String = "20260601",
        minAppVersion: String = "1.0.0"
    ) -> ModelManifest {
        let manifestFiles = files.map { f in
            ModelManifest.ManifestFile(
                name: f.name,
                url: "https://huggingface.co/test/resolve/main/\(f.name)",
                sha256: sha256Hex(f.body),
                size: Int64(f.body.count)
            )
        }
        let total = files.reduce(Int64(0)) { $0 + Int64($1.body.count) }
        return ModelManifest(
            model_id: "parakeet-tdt-0.6b-v3-coreml",
            version: version,
            min_app_version: minAppVersion,
            total_size_bytes: total,
            released_at: nil,
            files: manifestFiles
        )
    }

    /// Deletes the staging directory from ~/Library/Application Support/FluidAudio/Models/ tree.
    fileprivate static func cleanupStagingDir(modelsRoot: URL? = nil) {
        let root: URL
        if let override = modelsRoot {
            root = override
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            root = appSupport.appendingPathComponent("FluidAudio/Models")
        }
        let staging = root.appendingPathComponent("parakeet-tdt-0.6b-v3-staging")
        try? FileManager.default.removeItem(at: staging)
    }

    /// Creates a sandboxed temp models root directory for tests that do file I/O.
    fileprivate func makeTempModelsRoot() throws -> URL {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("ModelUpdateServiceTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        return tmp
    }

    /// Installs a MockURLProtocol responder that:
    /// - Returns the encoded manifest JSON for the manifest URL
    /// - Returns the matching body Data for each file URL
    fileprivate func installManifestAndFileResponder(manifest: ModelManifest, fileBodies: [(name: String, body: Data)]) {
        let manifestURL = "https://raw.githubusercontent.com/cnewfeldt/ps-transcribe-releases/main/model-manifest.json"
        let encodedManifest = try! JSONEncoder().encode(manifest)
        let fileMap: [String: Data] = Dictionary(uniqueKeysWithValues: fileBodies.map { f in
            ("https://huggingface.co/test/resolve/main/\(f.name)", f.body)
        })

        MockURLProtocol.responder = { request in
            let urlStr = request.url!.absoluteString
            if urlStr == manifestURL {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200,
                                              httpVersion: "HTTP/1.1", headerFields: nil)!
                return (response, encodedManifest)
            } else if let body = fileMap[urlStr] {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200,
                                              httpVersion: "HTTP/1.1", headerFields: nil)!
                return (response, body)
            } else {
                throw URLError(.badURL)
            }
        }
    }

    // MARK: - Plan 17-02 actual tests

    @Test @MainActor func downloadProgress() async throws {
        Self.clearV17Keys()
        let modelsRoot = try makeTempModelsRoot()
        defer {
            Self.clearV17Keys()
            MockURLProtocol.responder = nil
            try? FileManager.default.removeItem(at: modelsRoot)
        }

        let fileA = Data(repeating: 0xAA, count: 2048)
        let fileB = Data(repeating: 0xBB, count: 2048)
        let files: [(name: String, body: Data)] = [
            ("fileA.bin", fileA),
            ("fileB.bin", fileB)
        ]
        let manifest = makeManifest(files: files)

        let settings = AppSettings()
        settings.installedModelVersion = "20260427"
        installManifestAndFileResponder(manifest: manifest, fileBodies: files)

        let service = ModelUpdateService(settings: settings, session: .mocked(), appVersion: "2.1.1")
        service.modelsRootOverride = modelsRoot
        service.updateState = .updateAvailable(
            version: manifest.version,
            sizeBytes: manifest.total_size_bytes,
            releasedAt: nil
        )

        // Track states during download
        var sawDownloadingWithProgress = false
        var lastProgress = -1.0

        // Observe state changes during download by polling in a concurrent task
        let observeTask = Task {
            for _ in 0..<200 {
                await Task.yield()
                let state = await service.updateState
                if case .downloading(let progress, _, _) = state {
                    if progress > 0 { sawDownloadingWithProgress = true }
                    if progress >= lastProgress { lastProgress = progress }
                }
            }
        }

        await service.downloadAndApply()
        observeTask.cancel()

        // After completion, state should be .verifying (Plan 17-03 takes over for swap)
        if case .verifying = service.updateState {
            // Expected
        } else {
            Issue.record("Expected .verifying after successful download, got \(service.updateState)")
        }

        // Staging directory should exist and contain both files
        let stagingDir = modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3-staging")
        #expect(FileManager.default.fileExists(atPath: stagingDir.path))
        #expect(FileManager.default.fileExists(atPath: stagingDir.appendingPathComponent("fileA.bin").path))
        #expect(FileManager.default.fileExists(atPath: stagingDir.appendingPathComponent("fileB.bin").path))
    }

    @Test @MainActor func downloadFileWritesToStagingPath() async throws {
        Self.clearV17Keys()
        let modelsRoot = try makeTempModelsRoot()
        defer {
            Self.clearV17Keys()
            MockURLProtocol.responder = nil
            try? FileManager.default.removeItem(at: modelsRoot)
        }

        let fileA = Data(repeating: 0x11, count: 1024)
        let fileB = Data(repeating: 0x22, count: 1024)
        let files: [(name: String, body: Data)] = [
            ("model/weights.bin", fileA),
            ("config.json", fileB)
        ]
        let manifest = makeManifest(files: files)

        let settings = AppSettings()
        settings.installedModelVersion = "20260427"
        installManifestAndFileResponder(manifest: manifest, fileBodies: files)

        let service = ModelUpdateService(settings: settings, session: .mocked(), appVersion: "2.1.1")
        service.modelsRootOverride = modelsRoot
        service.updateState = .updateAvailable(
            version: manifest.version,
            sizeBytes: manifest.total_size_bytes,
            releasedAt: nil
        )

        await service.downloadAndApply()

        let stagingDir = modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3-staging")
        // Each file should be at stagingDirectory.appendingPathComponent(manifest.files[i].name)
        for f in files {
            let dest = stagingDir.appendingPathComponent(f.name)
            #expect(FileManager.default.fileExists(atPath: dest.path),
                    "Expected staging file at \(dest.path)")
        }
    }

    @Test @MainActor func cancelCleanup() async throws {
        Self.clearV17Keys()
        let modelsRoot = try makeTempModelsRoot()
        defer {
            Self.clearV17Keys()
            MockURLProtocol.responder = nil
            try? FileManager.default.removeItem(at: modelsRoot)
        }

        // Use two files. The responder blocks on a semaphore before returning the second file,
        // giving the test a deterministic window to fire cancelDownload() mid-download.
        let fileA = Data(repeating: 0xAA, count: 512)
        let fileB = Data(repeating: 0xBB, count: 512)
        let files: [(name: String, body: Data)] = [
            ("fileA.bin", fileA),
            ("fileB.bin", fileB)
        ]
        let manifest = makeManifest(files: files)

        // Semaphore: starts at 0. Test signals it after calling cancelDownload().
        // Responder waits on it before returning the second file, ensuring cancel always wins.
        let blockSem = DispatchSemaphore(value: 0)
        let manifestURL = "https://raw.githubusercontent.com/cnewfeldt/ps-transcribe-releases/main/model-manifest.json"
        let encodedManifest = try JSONEncoder().encode(manifest)
        var requestCount = 0
        MockURLProtocol.responder = { request in
            let urlStr = request.url!.absoluteString
            if urlStr == manifestURL {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200,
                                              httpVersion: "HTTP/1.1", headerFields: nil)!
                return (response, encodedManifest)
            } else if urlStr.contains("fileA.bin") {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200,
                                              httpVersion: "HTTP/1.1", headerFields: nil)!
                return (response, fileA)
            } else {
                // Block before returning fileB, giving the test time to call cancelDownload().
                requestCount += 1
                blockSem.wait()
                let response = HTTPURLResponse(url: request.url!, statusCode: 200,
                                              httpVersion: "HTTP/1.1", headerFields: nil)!
                return (response, fileB)
            }
        }

        let settings = AppSettings()
        settings.installedModelVersion = "20260427"
        let service = ModelUpdateService(settings: settings, session: .mocked(), appVersion: "2.1.1")
        service.modelsRootOverride = modelsRoot
        service.updateState = .updateAvailable(
            version: manifest.version,
            sizeBytes: manifest.total_size_bytes,
            releasedAt: nil
        )

        // Start download in a detached task (avoids blocking the @MainActor test body).
        let downloadTask = Task.detached { await service.downloadAndApply() }

        // Give the download task time to start and begin waiting on the semaphore
        // (fileA completes quickly; fileB blocks on blockSem).
        try await Task.sleep(for: .milliseconds(100))

        // Cancel before unblocking the responder -- cancellation lands before fileB returns.
        await service.cancelDownload()

        // Unblock the responder so the URLSession thread doesn't deadlock.
        blockSem.signal()

        await downloadTask.value

        // After cancellation: state should be .idle or .updateAvailable.
        let state = await service.updateState
        switch state {
        case .idle, .updateAvailable:
            break // Expected
        default:
            Issue.record("Expected .idle or .updateAvailable after cancel, got \(state)")
        }

        // Staging directory must NOT exist after cancellation.
        let stagingDir = modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3-staging")
        #expect(!FileManager.default.fileExists(atPath: stagingDir.path),
                "Staging directory must be wiped after cancellation")
    }

    @Test @MainActor func checksumMismatchRollsBack() async throws {
        Self.clearV17Keys()
        let modelsRoot = try makeTempModelsRoot()
        defer {
            Self.clearV17Keys()
            MockURLProtocol.responder = nil
            try? FileManager.default.removeItem(at: modelsRoot)
        }

        let realBody = Data(repeating: 0xCC, count: 1024)
        // Build manifest with a deliberately wrong SHA-256
        let badManifestFiles = [
            ModelManifest.ManifestFile(
                name: "weights.bin",
                url: "https://huggingface.co/test/resolve/main/weights.bin",
                sha256: String(repeating: "a", count: 64), // wrong checksum
                size: Int64(realBody.count)
            )
        ]
        let manifest = ModelManifest(
            model_id: "parakeet-tdt-0.6b-v3-coreml",
            version: "20260601",
            min_app_version: "1.0.0",
            total_size_bytes: Int64(realBody.count),
            released_at: nil,
            files: badManifestFiles
        )
        let encodedManifest = try JSONEncoder().encode(manifest)
        let manifestURL = "https://raw.githubusercontent.com/cnewfeldt/ps-transcribe-releases/main/model-manifest.json"

        MockURLProtocol.responder = { request in
            let urlStr = request.url!.absoluteString
            if urlStr == manifestURL {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200,
                                              httpVersion: "HTTP/1.1", headerFields: nil)!
                return (response, encodedManifest)
            } else if urlStr == "https://huggingface.co/test/resolve/main/weights.bin" {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200,
                                              httpVersion: "HTTP/1.1", headerFields: nil)!
                return (response, realBody) // Real body won't match the bad SHA
            } else {
                throw URLError(.badURL)
            }
        }

        // Snapshot production model directory (should be untouched)
        let productionDir = modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3")
        let productionExistedBefore = FileManager.default.fileExists(atPath: productionDir.path)

        let settings = AppSettings()
        settings.installedModelVersion = "20260427"
        let service = ModelUpdateService(settings: settings, session: .mocked(), appVersion: "2.1.1")
        service.modelsRootOverride = modelsRoot
        service.updateState = .updateAvailable(
            version: manifest.version,
            sizeBytes: manifest.total_size_bytes,
            releasedAt: nil
        )

        await service.downloadAndApply()

        // State must be .failed
        if case .failed(let message) = service.updateState {
            let lower = message.lowercased()
            #expect(lower.contains("integrity") || lower.contains("checksum"),
                    "Failure message should mention integrity or checksum: '\(message)'")
        } else {
            Issue.record("Expected .failed after checksum mismatch, got \(service.updateState)")
        }

        // Staging directory must NOT exist (rolled back)
        let stagingDir = modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3-staging")
        #expect(!FileManager.default.fileExists(atPath: stagingDir.path),
                "Staging directory must be wiped after checksum failure")

        // Production directory untouched
        let productionExistsAfter = FileManager.default.fileExists(atPath: productionDir.path)
        #expect(productionExistedBefore == productionExistsAfter,
                "Production model directory must not be modified")
    }

    @Test @MainActor func insufficientDiskSpace() async throws {
        Self.clearV17Keys()
        let modelsRoot = try makeTempModelsRoot()
        defer {
            Self.clearV17Keys()
            MockURLProtocol.responder = nil
            try? FileManager.default.removeItem(at: modelsRoot)
        }

        let fileBody = Data(repeating: 0xFF, count: 512)
        let files: [(name: String, body: Data)] = [("model.bin", fileBody)]
        let manifest = makeManifest(files: files)
        installManifestAndFileResponder(manifest: manifest, fileBodies: files)

        let settings = AppSettings()
        settings.installedModelVersion = "20260427"
        let service = ModelUpdateService(settings: settings, session: .mocked(), appVersion: "2.1.1")
        service.modelsRootOverride = modelsRoot
        service.updateState = .updateAvailable(
            version: manifest.version,
            sizeBytes: manifest.total_size_bytes,
            releasedAt: nil
        )

        // Override disk-space provider to simulate very limited free space (100 bytes)
        service.diskSpaceProvider = { _ in 100 }

        await service.downloadAndApply()

        if case .blocked(.insufficientDiskSpace(let needed, let available)) = service.updateState {
            #expect(needed > available, "needed (\(needed)) should exceed available (\(available))")
        } else {
            Issue.record("Expected .blocked(.insufficientDiskSpace(...)), got \(service.updateState)")
        }
    }

    @Test @MainActor func progressIsMonotonic() async throws {
        Self.clearV17Keys()
        let modelsRoot = try makeTempModelsRoot()
        defer {
            Self.clearV17Keys()
            MockURLProtocol.responder = nil
            try? FileManager.default.removeItem(at: modelsRoot)
        }

        // Use files bigger than 64KB to get multiple chunk callbacks
        let fileA = Data(repeating: 0xAA, count: 80 * 1024)
        let fileB = Data(repeating: 0xBB, count: 80 * 1024)
        let files: [(name: String, body: Data)] = [
            ("fileA.bin", fileA),
            ("fileB.bin", fileB)
        ]
        let manifest = makeManifest(files: files)
        installManifestAndFileResponder(manifest: manifest, fileBodies: files)

        let settings = AppSettings()
        settings.installedModelVersion = "20260427"
        let service = ModelUpdateService(settings: settings, session: .mocked(), appVersion: "2.1.1")
        service.modelsRootOverride = modelsRoot
        service.updateState = .updateAvailable(
            version: manifest.version,
            sizeBytes: manifest.total_size_bytes,
            releasedAt: nil
        )

        var progressHistory: [Double] = []

        // Poll state during the download in a concurrent task
        let monitorTask = Task { @MainActor in
            for _ in 0..<1000 {
                if case .downloading(let p, _, _) = service.updateState {
                    progressHistory.append(p)
                }
                await Task.yield()
            }
        }

        await service.downloadAndApply()
        monitorTask.cancel()

        // Verify monotonicity: each value >= previous
        for i in 1..<progressHistory.count {
            #expect(progressHistory[i] >= progressHistory[i - 1],
                    "Progress must be non-decreasing: \(progressHistory[i - 1]) -> \(progressHistory[i]) at index \(i)")
        }
    }

    @Test @MainActor func pathTraversalRejected() async throws {
        Self.clearV17Keys()
        let modelsRoot = try makeTempModelsRoot()
        defer {
            Self.clearV17Keys()
            MockURLProtocol.responder = nil
            try? FileManager.default.removeItem(at: modelsRoot)
        }

        // Manifest with a path-traversal filename
        let realBody = Data(repeating: 0xDD, count: 256)
        let maliciousFiles = [
            ModelManifest.ManifestFile(
                name: "../../../etc/passwd",
                url: "https://huggingface.co/test/resolve/main/%2E%2E/evil.bin",
                sha256: sha256Hex(realBody),
                size: Int64(realBody.count)
            )
        ]
        let manifest = ModelManifest(
            model_id: "parakeet-tdt-0.6b-v3-coreml",
            version: "20260601",
            min_app_version: "1.0.0",
            total_size_bytes: Int64(realBody.count),
            released_at: nil,
            files: maliciousFiles
        )
        let encodedManifest = try JSONEncoder().encode(manifest)
        let manifestURL = "https://raw.githubusercontent.com/cnewfeldt/ps-transcribe-releases/main/model-manifest.json"

        MockURLProtocol.responder = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200,
                                          httpVersion: "HTTP/1.1", headerFields: nil)!
            return (response, encodedManifest)
        }

        let settings = AppSettings()
        settings.installedModelVersion = "20260427"
        _ = manifestURL // silence unused warning
        let service = ModelUpdateService(settings: settings, session: .mocked(), appVersion: "2.1.1")
        service.modelsRootOverride = modelsRoot
        service.updateState = .updateAvailable(
            version: manifest.version,
            sizeBytes: manifest.total_size_bytes,
            releasedAt: nil
        )

        await service.downloadAndApply()

        // Must NOT succeed -- path traversal must produce .failed state
        if case .failed = service.updateState {
            // Expected -- path traversal was rejected
        } else if case .verifying = service.updateState {
            Issue.record("Path traversal filename was accepted -- staging should not contain files outside staging root")
        }

        // The passwd file must NOT exist at the traversal target
        let etcPasswd = URL(fileURLWithPath: "/etc/passwd")
        // We can't actually modify /etc/passwd (no permission) -- just verify staging is clean
        let stagingDir = modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3-staging")
        if FileManager.default.fileExists(atPath: stagingDir.path) {
            // If staging exists, any file inside it must be within the staging subtree
            let passwdInStaging = stagingDir.appendingPathComponent("../../../etc/passwd")
            let resolvedPath = passwdInStaging.standardized.path
            #expect(resolvedPath.hasPrefix(stagingDir.standardized.path),
                    "Path traversal file must not escape staging directory")
        }
        _ = etcPasswd
    }

    // MARK: - Stub-pending tests for Plan 17-03

    // Plan 17-03 (apply + reload + deferral):
    //   @Test func persistsVersion() async { ... }
    //   @Test func deferredApplyOnSession() async { ... }
}
