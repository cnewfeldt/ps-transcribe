import Foundation
import os

private let log = Logger(subsystem: "com.pstranscribe.app", category: "OllamaService")

actor OllamaService {

    // Internal (not private) so tests can verify configuration
    let baseURL = URL(string: "http://localhost:11434")!  // D-01: localhost only
    let session: URLSession

    // MARK: - Connection Status

    enum ConnectionStatus: Sendable {
        case connected
        case notRunning    // TCP refused -- Ollama installed but not started
        case notFound      // timeout or other error -- Ollama not installed/reachable
    }

    // MARK: - Init

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 2.0   // OLMA-05
        config.timeoutIntervalForResource = 2.0  // OLMA-05
        self.session = URLSession(configuration: config)
    }

    /// Allow injecting a custom URLSession for testing
    init(session: URLSession) {
        self.session = session
    }

    // MARK: - API

    func checkConnection() async -> ConnectionStatus {
        do {
            let (_, response) = try await session.data(from: baseURL)
            if (response as? HTTPURLResponse)?.statusCode == 200 {
                log.info("Connection check: connected")
                return .connected
            }
            log.warning("Connection check: unexpected status code")
            return .notRunning
        } catch let error as URLError where error.code == .cannotConnectToHost {
            log.info("Connection check: not running (connection refused)")
            return .notRunning
        } catch {
            log.info("Connection check: not found (\(error.localizedDescription))")
            return .notFound
        }
    }

    func fetchModels() async throws -> [OllamaModel] {
        let url = baseURL.appending(path: "/api/tags")
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
        log.info("Fetched \(response.models.count) models")
        return response.models
    }

    func generate(prompt: String, model: String) async throws -> String {
        var request = URLRequest(url: baseURL.appending(path: "/api/generate"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = OllamaGenerateRequest(
            model: model,
            prompt: prompt,
            stream: false,
            options: OllamaGenerateRequest.OllamaOptions(numCtx: 16384)  // OLMA-06
        )
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await session.data(for: request)
        let decoded = try JSONDecoder().decode(OllamaGenerateResponse.self, from: data)
        return decoded.response
    }
}
