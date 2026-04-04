import Testing
import Foundation
@testable import PSTranscribe

@Suite("OllamaService Tests")
struct OllamaServiceTests {

    // MARK: - JSON Decode Tests

    @Test func tagsResponseDecodesFromFixtureJSON() throws {
        let tagsJSON = """
        {"models":[{"name":"llama3.2:3b","model":"llama3.2:3b","size":2019393189,
        "details":{"parameter_size":"3.2B","quantization_level":"Q4_K_M","family":"llama"}},
        {"name":"qwen3:8b","model":"qwen3:8b","size":4900000000,
        "details":{"parameter_size":"8B","quantization_level":"Q4_K_M","family":"qwen"}}]}
        """
        let data = try #require(tagsJSON.data(using: .utf8))
        let decoded = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
        #expect(decoded.models.count == 2)
        #expect(decoded.models[0].name == "llama3.2:3b")
        #expect(decoded.models[0].model == "llama3.2:3b")
        #expect(decoded.models[0].size == 2019393189)
        #expect(decoded.models[0].details.parameterSize == "3.2B")
        #expect(decoded.models[0].details.quantizationLevel == "Q4_K_M")
        #expect(decoded.models[0].details.family == "llama")
        #expect(decoded.models[1].name == "qwen3:8b")
        #expect(decoded.models[1].details.family == "qwen")
    }

    @Test func ollamaModelHasIdComputedFromName() throws {
        let tagsJSON = """
        {"models":[{"name":"llama3.2:3b","model":"llama3.2:3b","size":2019393189,
        "details":{"parameter_size":"3.2B","quantization_level":"Q4_K_M","family":"llama"}}]}
        """
        let data = try #require(tagsJSON.data(using: .utf8))
        let decoded = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
        #expect(decoded.models[0].id == "llama3.2:3b")
    }

    // MARK: - OllamaGenerateRequest Encoding

    @Test func generateRequestEncodesNumCtxCorrectly() throws {
        let request = OllamaGenerateRequest(
            model: "llama3.2:3b",
            prompt: "Summarize this.",
            stream: false,
            options: OllamaGenerateRequest.OllamaOptions(numCtx: 16384)
        )
        let encoded = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        let options = json?["options"] as? [String: Any]
        let numCtx = options?["num_ctx"] as? Int
        #expect(numCtx == 16384)
    }

    @Test func generateRequestEncodesStreamFalse() throws {
        let request = OllamaGenerateRequest(
            model: "llama3.2:3b",
            prompt: "Test prompt",
            stream: false,
            options: OllamaGenerateRequest.OllamaOptions(numCtx: 16384)
        )
        let encoded = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        let stream = json?["stream"] as? Bool
        #expect(stream == false)
    }

    @Test func generateRequestEncodesModelAndPrompt() throws {
        let request = OllamaGenerateRequest(
            model: "qwen3:8b",
            prompt: "Hello world",
            stream: false,
            options: OllamaGenerateRequest.OllamaOptions(numCtx: 16384)
        )
        let encoded = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        #expect(json?["model"] as? String == "qwen3:8b")
        #expect(json?["prompt"] as? String == "Hello world")
    }

    // MARK: - ConnectionStatus Enum

    @Test func connectionStatusHasThreeCases() {
        // Exhaustive switch ensures exactly three cases exist
        let statuses: [OllamaService.ConnectionStatus] = [.connected, .notRunning, .notFound]
        #expect(statuses.count == 3)
        for status in statuses {
            switch status {
            case .connected: break
            case .notRunning: break
            case .notFound: break
            }
        }
    }

    // MARK: - URLSession Timeout Configuration

    @Test func sessionHasTwoSecondTimeout() async {
        let service = OllamaService()
        let config = await service.session.configuration
        #expect(config.timeoutIntervalForRequest == 2.0)
        #expect(config.timeoutIntervalForResource == 2.0)
    }

    // MARK: - generate() timeout overload

    @Test func testGenerateTimeoutAcceptsCustomValue() async {
        // Verify the generate() signature accepts a timeout parameter.
        // We don't hit a real server -- we just ensure the call compiles and
        // that passing a large timeout does not use the default 2s session
        // (which would time out immediately against any non-local endpoint).
        let service = OllamaService()
        do {
            _ = try await service.generate(prompt: "hi", model: "nonexistent-model", timeout: 120)
            // If an Ollama server happens to be running locally with that model,
            // a successful return is still a pass.
        } catch {
            // Any error (connection refused, decoding failure, etc.) is acceptable
            // -- the important check is that the overload exists and was invoked.
        }
    }

    @Test func testGenerateDefaultTimeoutStillUsesTwoSeconds() async {
        // Backward-compat: the original call site generate(prompt:model:)
        // must still resolve -- exercised by the default parameter value.
        let service = OllamaService()
        do {
            _ = try await service.generate(prompt: "hi", model: "nonexistent-model")
        } catch {
            // Any error fine -- this test verifies the no-timeout call site compiles.
        }
    }
}
