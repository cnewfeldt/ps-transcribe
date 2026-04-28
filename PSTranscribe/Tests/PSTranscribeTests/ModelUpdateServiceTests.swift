import Testing
import Foundation
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

    // MARK: - Stub-pending tests for Plans 17-02 / 17-03

    // Plan 17-02 (download + cancel + disk-space):
    //   @Test func downloadProgress() async { ... }
    //   @Test func cancelCleanup() async { ... }
    //   @Test func checksumMismatchRollsBack() async { ... }
    //   @Test func insufficientDiskSpace() async { ... }
    //
    // Plan 17-03 (apply + reload + deferral):
    //   @Test func persistsVersion() async { ... }
    //   @Test func deferredApplyOnSession() async { ... }
}
