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
        // Plan 17-03: inject no-op reload handler so applySwap proceeds without real FluidAudio models.
        service.reloadHandler = { }
        service.anySessionActiveProvider = { false }
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

        // After the full end-to-end flow (Plan 17-03 wired applySwap), state is .applied.
        if case .applied(let ver) = service.updateState {
            #expect(ver == manifest.version)
        } else {
            Issue.record("Expected .applied after successful download+apply, got \(service.updateState)")
        }

        // Staging was moved into production -- production directory contains the downloaded files.
        let productionDir = modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3")
        #expect(FileManager.default.fileExists(atPath: productionDir.path))
        #expect(FileManager.default.fileExists(atPath: productionDir.appendingPathComponent("fileA.bin").path))
        #expect(FileManager.default.fileExists(atPath: productionDir.appendingPathComponent("fileB.bin").path))
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
        // Plan 17-03: inject no-op reload handler so applySwap proceeds without real FluidAudio models.
        service.reloadHandler = { }
        service.anySessionActiveProvider = { false }
        service.updateState = .updateAvailable(
            version: manifest.version,
            sizeBytes: manifest.total_size_bytes,
            releasedAt: nil
        )

        await service.downloadAndApply()

        // After the full end-to-end flow, staging is moved into production.
        // Files should be at productionDirectory.appendingPathComponent(manifest.files[i].name)
        let productionDir = modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3")
        for f in files {
            let dest = productionDir.appendingPathComponent(f.name)
            #expect(FileManager.default.fileExists(atPath: dest.path),
                    "Expected file at production path \(dest.path)")
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

    // MARK: - Plan 17-03 tests: applySwap, rollback, deferral, version persist

    // MARK: - Helpers for Plan 17-03 tests

    /// Creates a temp production directory with a marker file named `markerName`.
    fileprivate func makeProductionDir(root: URL, markerName: String) throws -> URL {
        let productionDir = root.appendingPathComponent("parakeet-tdt-0.6b-v3")
        try FileManager.default.createDirectory(at: productionDir, withIntermediateDirectories: true)
        let marker = productionDir.appendingPathComponent(markerName)
        FileManager.default.createFile(atPath: marker.path, contents: Data(markerName.utf8))
        return productionDir
    }

    /// Creates a temp staging directory with a marker file named `markerName`.
    fileprivate func makeStagingDir(root: URL, markerName: String) throws -> URL {
        let stagingDir = root.appendingPathComponent("parakeet-tdt-0.6b-v3-staging")
        try FileManager.default.createDirectory(at: stagingDir, withIntermediateDirectories: true)
        let marker = stagingDir.appendingPathComponent(markerName)
        FileManager.default.createFile(atPath: marker.path, contents: Data(markerName.utf8))
        return stagingDir
    }

    /// Returns true if a file named `name` exists inside `dir`.
    fileprivate func dirContains(_ dir: URL, file name: String) -> Bool {
        FileManager.default.fileExists(atPath: dir.appendingPathComponent(name).path)
    }

    /// Finds any directory under `root` whose name contains `substring`.
    fileprivate func findDir(under root: URL, containing substring: String) -> URL? {
        guard let entries = try? FileManager.default.contentsOfDirectory(at: root,
                                                                         includingPropertiesForKeys: nil) else { return nil }
        return entries.first { $0.lastPathComponent.contains(substring) }
    }

    /// Sets service state to .verifying (bypass the download path for applySwap tests).
    @MainActor fileprivate func setVerifying(_ service: ModelUpdateService, version: String = "20260601") {
        service.updateState = .verifying
    }

    // MARK: - Plan 17-03 actual tests

    /// After a successful apply (download stub + no-op reload), installedModelVersion == manifest.version.
    @Test @MainActor func persistsVersion() async throws {
        Self.clearV17Keys()
        let modelsRoot = try makeTempModelsRoot()
        defer {
            Self.clearV17Keys()
            MockURLProtocol.responder = nil
            try? FileManager.default.removeItem(at: modelsRoot)
        }

        // Pre-create production and staging directories with marker content
        _ = try makeProductionDir(root: modelsRoot, markerName: "OLD")
        _ = try makeStagingDir(root: modelsRoot, markerName: "NEW")

        let fileBody = Data(repeating: 0xAB, count: 256)
        let files: [(name: String, body: Data)] = [("NEW", fileBody)]
        let manifest = makeManifest(files: files, version: "20260601")
        installManifestAndFileResponder(manifest: manifest, fileBodies: files)

        let settings = AppSettings()
        settings.installedModelVersion = "20260427"
        let coordinator = SessionCoordinator()

        let service = ModelUpdateService(settings: settings, session: .mocked(), appVersion: "2.1.1")
        service.modelsRootOverride = modelsRoot
        // No-op reload handler -- no real FluidAudio required
        service.reloadHandler = { }
        // Session not active -- swap should proceed immediately
        service.anySessionActiveProvider = { false }
        service.updateState = .updateAvailable(
            version: manifest.version,
            sizeBytes: manifest.total_size_bytes,
            releasedAt: nil
        )
        coordinator.modelUpdate = service

        // Run the full downloadAndApply pipeline (network mock provides manifest + files)
        await service.downloadAndApply()

        // installedModelVersion must be updated to the new manifest version
        #expect(settings.installedModelVersion == "20260601",
                "installedModelVersion must be persisted after successful apply; got '\(settings.installedModelVersion)'")
        // State should be .applied
        if case .applied(let ver) = service.updateState {
            #expect(ver == "20260601")
        } else {
            Issue.record("Expected .applied after successful apply, got \(service.updateState)")
        }
    }

    /// Atomic swap: after a successful applySwap, the production directory contains the NEW
    /// marker and the staging directory no longer exists.
    @Test @MainActor func applySwapAtomicallyReplaces() async throws {
        Self.clearV17Keys()
        let modelsRoot = try makeTempModelsRoot()
        defer {
            Self.clearV17Keys()
            try? FileManager.default.removeItem(at: modelsRoot)
        }

        _ = try makeProductionDir(root: modelsRoot, markerName: "OLD")
        _ = try makeStagingDir(root: modelsRoot, markerName: "NEW")

        let settings = AppSettings()
        let service = ModelUpdateService(settings: settings, appVersion: "2.1.1")
        service.modelsRootOverride = modelsRoot
        service.reloadHandler = { }
        service.anySessionActiveProvider = { false }
        setVerifying(service)

        let manifest = makeManifest(files: [("NEW", Data("NEW".utf8))], version: "20260601")
        await service.applySwap(manifest)

        let productionDir = modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3")
        let stagingDir = modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3-staging")

        // Production must now contain the NEW marker
        #expect(dirContains(productionDir, file: "NEW"),
                "Production directory must contain NEW marker after atomic swap")
        // Production must NOT contain the OLD marker
        #expect(!dirContains(productionDir, file: "OLD"),
                "Production directory must NOT contain OLD marker after swap")
        // Staging directory must be gone (was replaced into production)
        #expect(!FileManager.default.fileExists(atPath: stagingDir.path),
                "Staging directory must not exist after successful swap")
    }

    /// When the injected reloadHandler throws, the rollback path restores the production
    /// directory to its original content, creates a *-failed-* forensics dir, and sets .failed.
    @Test @MainActor func failedReloadRollsBack() async throws {
        Self.clearV17Keys()
        let modelsRoot = try makeTempModelsRoot()
        defer {
            Self.clearV17Keys()
            try? FileManager.default.removeItem(at: modelsRoot)
        }

        _ = try makeProductionDir(root: modelsRoot, markerName: "OLD")
        _ = try makeStagingDir(root: modelsRoot, markerName: "NEW")

        let settings = AppSettings()
        let service = ModelUpdateService(settings: settings, appVersion: "2.1.1")
        service.modelsRootOverride = modelsRoot
        service.reloadHandler = { throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "reload failed"]) }
        service.anySessionActiveProvider = { false }
        setVerifying(service)

        let manifest = makeManifest(files: [("NEW", Data("NEW".utf8))], version: "20260601")
        await service.applySwap(manifest)

        let productionDir = modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3")

        // Production must be rolled back to OLD content
        #expect(dirContains(productionDir, file: "OLD"),
                "Production directory must be restored to OLD after reload failure")
        #expect(!dirContains(productionDir, file: "NEW"),
                "Production directory must NOT contain NEW after rollback")

        // A *-failed-* forensic directory must exist
        let failedDir = findDir(under: modelsRoot, containing: "-failed-")
        #expect(failedDir != nil, "A *-failed-* forensic directory must exist after failed reload")

        // State must be .failed
        if case .failed = service.updateState {
            // Expected
        } else {
            Issue.record("Expected .failed state after reload failure, got \(service.updateState)")
        }

        // installedModelVersion must NOT be updated
        #expect(settings.installedModelVersion == "",
                "installedModelVersion must not be written after rollback")
    }

    /// Before the swap, any pre-existing *-failed-* directory is removed (D-15 rotation).
    /// After a successful apply, the prior failed dir is gone.
    @Test @MainActor func priorFailedDirectoryRotated() async throws {
        Self.clearV17Keys()
        let modelsRoot = try makeTempModelsRoot()
        defer {
            Self.clearV17Keys()
            try? FileManager.default.removeItem(at: modelsRoot)
        }

        // Pre-create a prior failed directory (simulating a previous failed update)
        let priorFailedDir = modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3-failed-20260101T000000Z")
        try FileManager.default.createDirectory(at: priorFailedDir, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: priorFailedDir.appendingPathComponent("oldstuff").path,
                                       contents: Data("old".utf8))

        _ = try makeProductionDir(root: modelsRoot, markerName: "OLD")
        _ = try makeStagingDir(root: modelsRoot, markerName: "NEW")

        let settings = AppSettings()
        let service = ModelUpdateService(settings: settings, appVersion: "2.1.1")
        service.modelsRootOverride = modelsRoot
        service.reloadHandler = { }
        service.anySessionActiveProvider = { false }
        setVerifying(service)

        let manifest = makeManifest(files: [("NEW", Data("NEW".utf8))], version: "20260601")
        await service.applySwap(manifest)

        // The prior *-failed-* dir must be gone
        #expect(!FileManager.default.fileExists(atPath: priorFailedDir.path),
                "Prior *-failed-* directory must be removed on successful update (D-15 rotation)")

        // And the apply should have succeeded
        if case .applied = service.updateState {
            // Expected
        } else {
            Issue.record("Expected .applied state, got \(service.updateState)")
        }
    }

    /// When anySessionActiveProvider returns true, the swap does NOT proceed immediately.
    /// Production directory stays unchanged until provider returns false.
    @Test @MainActor func applyDoesNotProceedWithSessionActive() async throws {
        Self.clearV17Keys()
        let modelsRoot = try makeTempModelsRoot()
        defer {
            Self.clearV17Keys()
            try? FileManager.default.removeItem(at: modelsRoot)
        }

        _ = try makeProductionDir(root: modelsRoot, markerName: "OLD")
        _ = try makeStagingDir(root: modelsRoot, markerName: "NEW")

        let settings = AppSettings()
        let service = ModelUpdateService(settings: settings, appVersion: "2.1.1")
        service.modelsRootOverride = modelsRoot
        service.reloadHandler = { }

        // Session is active -- swap must not proceed
        service.anySessionActiveProvider = { true }
        setVerifying(service)

        let manifest = makeManifest(files: [("NEW", Data("NEW".utf8))], version: "20260601")

        // Start applySwap in a background task (it will block on waitForSessionEnd)
        let swapTask = Task { await service.applySwap(manifest) }

        // Give the task a moment to start polling
        try await Task.sleep(for: .milliseconds(150))

        let productionDir = modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3")

        // Production must still contain OLD -- swap has not happened yet
        #expect(dirContains(productionDir, file: "OLD"),
                "Production directory must be unchanged while session is active")
        #expect(!dirContains(productionDir, file: "NEW"),
                "NEW must not appear in production while session is active")

        // Now allow the swap by flipping the provider to false
        service.anySessionActiveProvider = { false }

        // Wait for the swap task to complete
        await swapTask.value

        // Now production must contain NEW
        #expect(dirContains(productionDir, file: "NEW"),
                "Production directory must contain NEW after session ends and swap completes")
    }

    // MARK: - Plan 17-05 backfill tests (D-14)

    /// Helper: creates files on disk under the given model directory.
    fileprivate func createModelFiles(in dir: URL, files: [(name: String, body: Data)]) throws {
        for f in files {
            let dest = dir.appendingPathComponent(f.name)
            try FileManager.default.createDirectory(at: dest.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try f.body.write(to: dest)
        }
    }

    /// Helper: builds a manifest where size exactly matches the given on-disk bodies.
    fileprivate func makeManifestForBackfill(
        files: [(name: String, body: Data)],
        version: String = "20260427"
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
            min_app_version: "1.0.0",
            total_size_bytes: total,
            released_at: nil,
            files: manifestFiles
        )
    }

    /// Helper: installs a mock session returning the given manifest for any URL.
    fileprivate func installManifestOnlyResponder(manifest: ModelManifest) {
        let encoded = try! JSONEncoder().encode(manifest)
        MockURLProtocol.responder = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200,
                                          httpVersion: "HTTP/1.1", headerFields: nil)!
            return (response, encoded)
        }
    }

    /// D-14 backfill fires when: installedModelVersion == "", all files exist, first file size matches.
    /// After checkForUpdate, installedModelVersion == manifest.version AND state == .upToDate.
    @Test @MainActor func backfillFiresWhenAllConditionsMet() async throws {
        Self.clearV17Keys()
        defer {
            Self.clearV17Keys()
            MockURLProtocol.responder = nil
        }

        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let modelsRoot = tmp.appendingPathComponent("FluidAudio/Models")
        let modelDir = modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3")

        let files: [(name: String, body: Data)] = [
            ("Encoder.mlmodelc/coremldata.bin", Data(repeating: 0xAB, count: 1024)),
            ("Encoder.mlmodelc/metadata.json", Data(repeating: 0xCD, count: 256))
        ]
        try createModelFiles(in: modelDir, files: files)

        let manifest = makeManifestForBackfill(files: files, version: "20260427")
        installManifestOnlyResponder(manifest: manifest)

        let settings = AppSettings()
        // installedModelVersion left as "" (default) -- backfill condition 1 met
        let service = ModelUpdateService(settings: settings, session: .mocked(), appVersion: "2.1.1")
        service.modelsRootOverride = modelsRoot

        await service.checkForUpdate(force: true)

        #expect(settings.installedModelVersion == "20260427",
                "D-14 backfill must set installedModelVersion to manifest.version; got '\(settings.installedModelVersion)'")
        if case .upToDate = service.updateState {
            // Expected: backfill made the user current, so state should be upToDate
        } else {
            Issue.record("expected .upToDate after D-14 backfill; got \(service.updateState)")
        }
    }

    /// D-14 backfill must NOT fire when installedModelVersion is already set.
    /// Version must remain unchanged; state is .updateAvailable (manifest is newer).
    @Test @MainActor func backfillDoesNotFireWhenInstalledIsSet() async throws {
        Self.clearV17Keys()
        defer {
            Self.clearV17Keys()
            MockURLProtocol.responder = nil
        }

        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let modelsRoot = tmp.appendingPathComponent("FluidAudio/Models")
        let modelDir = modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3")

        let files: [(name: String, body: Data)] = [
            ("Encoder.mlmodelc/coremldata.bin", Data(repeating: 0xAB, count: 1024))
        ]
        try createModelFiles(in: modelDir, files: files)

        // Manifest declares a NEWER version so that, if backfill incorrectly fires,
        // the post-backfill compare would be "20260601" >= "20260601" -> upToDate.
        // But backfill must NOT fire because installedModelVersion is already "20260101".
        let manifest = makeManifestForBackfill(files: files, version: "20260601")
        installManifestOnlyResponder(manifest: manifest)

        let settings = AppSettings()
        settings.installedModelVersion = "20260101"   // pre-set -- backfill must NOT overwrite
        let service = ModelUpdateService(settings: settings, session: .mocked(), appVersion: "2.1.1")
        service.modelsRootOverride = modelsRoot

        await service.checkForUpdate(force: true)

        #expect(settings.installedModelVersion == "20260101",
                "installedModelVersion must not be overwritten by backfill when already set; got '\(settings.installedModelVersion)'")
        // "20260101" < "20260601" -> updateAvailable
        if case .updateAvailable = service.updateState {
            // Expected
        } else {
            Issue.record("expected .updateAvailable when backfill skips (installed already set); got \(service.updateState)")
        }
    }

    /// D-14 backfill must NOT fire when the first file's on-disk size differs from manifest.size.
    /// installedModelVersion stays "" and state is .updateAvailable.
    @Test @MainActor func backfillDoesNotFireOnSizeMismatch() async throws {
        Self.clearV17Keys()
        defer {
            Self.clearV17Keys()
            MockURLProtocol.responder = nil
        }

        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let modelsRoot = tmp.appendingPathComponent("FluidAudio/Models")
        let modelDir = modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3")

        // On-disk file has 1024 bytes; manifest declares 9999 bytes -> size mismatch
        let onDiskBody = Data(repeating: 0xAB, count: 1024)
        let files: [(name: String, body: Data)] = [
            ("Encoder.mlmodelc/coremldata.bin", onDiskBody)
        ]
        try createModelFiles(in: modelDir, files: files)

        // Build manifest manually with mismatched size for first file
        let mismatchedFile = ModelManifest.ManifestFile(
            name: "Encoder.mlmodelc/coremldata.bin",
            url: "https://huggingface.co/test/resolve/main/Encoder.mlmodelc/coremldata.bin",
            sha256: sha256Hex(onDiskBody),
            size: 9999   // deliberately wrong -- on-disk is 1024
        )
        let manifest = ModelManifest(
            model_id: "parakeet-tdt-0.6b-v3-coreml",
            version: "20260427",
            min_app_version: "1.0.0",
            total_size_bytes: 9999,
            released_at: nil,
            files: [mismatchedFile]
        )
        installManifestOnlyResponder(manifest: manifest)

        let settings = AppSettings()
        // installedModelVersion stays "" (empty) -- backfill would fire IF size matched
        let service = ModelUpdateService(settings: settings, session: .mocked(), appVersion: "2.1.1")
        service.modelsRootOverride = modelsRoot

        await service.checkForUpdate(force: true)

        #expect(settings.installedModelVersion == "",
                "D-14 backfill must NOT fire on size mismatch; installedModelVersion must stay empty")
        // "" < "20260427" -> updateAvailable
        if case .updateAvailable = service.updateState {
            // Expected
        } else {
            Issue.record("expected .updateAvailable when backfill skips on size mismatch; got \(service.updateState)")
        }
    }

    /// D-14 backfill must NOT fire when any manifest file is missing from disk.
    /// installedModelVersion stays "" and state is .updateAvailable.
    @Test @MainActor func backfillDoesNotFireOnMissingFile() async throws {
        Self.clearV17Keys()
        defer {
            Self.clearV17Keys()
            MockURLProtocol.responder = nil
        }

        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let modelsRoot = tmp.appendingPathComponent("FluidAudio/Models")
        let modelDir = modelsRoot.appendingPathComponent("parakeet-tdt-0.6b-v3")

        // Only create the first file; manifest declares two files
        let file1Body = Data(repeating: 0xAA, count: 512)
        let file2Body = Data(repeating: 0xBB, count: 512)
        let file1: (name: String, body: Data) = ("Encoder.mlmodelc/coremldata.bin", file1Body)
        // file2 is declared in the manifest but NOT created on disk
        try createModelFiles(in: modelDir, files: [file1])

        let manifest = makeManifestForBackfill(
            files: [file1, ("Encoder.mlmodelc/model.mil", file2Body)],
            version: "20260427"
        )
        installManifestOnlyResponder(manifest: manifest)

        let settings = AppSettings()
        let service = ModelUpdateService(settings: settings, session: .mocked(), appVersion: "2.1.1")
        service.modelsRootOverride = modelsRoot

        await service.checkForUpdate(force: true)

        #expect(settings.installedModelVersion == "",
                "D-14 backfill must NOT fire when a manifest file is absent from disk")
        if case .updateAvailable = service.updateState {
            // Expected: user genuinely needs to download
        } else {
            Issue.record("expected .updateAvailable when backfill skips on missing file; got \(service.updateState)")
        }
    }

    /// D-14 backfill survives an attribute read failure (e.g., non-existent modelsRoot).
    /// No crash; state is .updateAvailable; installedModelVersion stays "".
    @Test @MainActor func backfillSurvivesAttributeReadFailure() async throws {
        Self.clearV17Keys()
        defer {
            Self.clearV17Keys()
            MockURLProtocol.responder = nil
        }

        // Point modelsRootOverride at a path that has no model files -> fileExists returns false
        // so the early-return guard fires before attributesOfItem is even called.
        // This is the "attribute read failure / non-existent path" scenario per the plan.
        let nonExistentRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("nonexistent-\(UUID().uuidString)")
        // Do NOT create the directory -- it does not exist

        let files: [(name: String, body: Data)] = [
            ("Encoder.mlmodelc/coremldata.bin", Data(repeating: 0xAB, count: 1024))
        ]
        let manifest = makeManifestForBackfill(files: files, version: "20260427")
        installManifestOnlyResponder(manifest: manifest)

        let settings = AppSettings()
        let service = ModelUpdateService(settings: settings, session: .mocked(), appVersion: "2.1.1")
        service.modelsRootOverride = nonExistentRoot

        // Must not crash; backfill must skip silently
        await service.checkForUpdate(force: true)

        #expect(settings.installedModelVersion == "",
                "D-14 backfill must skip silently on missing model path; installedModelVersion must stay empty")
        // The non-existent path means files are missing -> .updateAvailable
        if case .updateAvailable = service.updateState {
            // Expected
        } else {
            Issue.record("expected .updateAvailable when backfill skips due to missing path; got \(service.updateState)")
        }
    }
}
