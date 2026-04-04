import Foundation

// MARK: - Tags Response

struct OllamaTagsResponse: Codable, Sendable {
    let models: [OllamaModel]
}

// MARK: - Model

struct OllamaModel: Codable, Identifiable, Equatable, Sendable {
    let name: String
    let model: String
    let size: Int
    let details: OllamaModelDetails

    var id: String { name }
}

// MARK: - Model Details

struct OllamaModelDetails: Codable, Equatable, Sendable {
    let parameterSize: String
    let quantizationLevel: String
    let family: String

    enum CodingKeys: String, CodingKey {
        case parameterSize = "parameter_size"
        case quantizationLevel = "quantization_level"
        case family
    }
}

// MARK: - Generate Request

struct OllamaGenerateRequest: Codable, Sendable {
    let model: String
    let prompt: String
    let stream: Bool
    let options: OllamaOptions

    struct OllamaOptions: Codable, Sendable {
        let numCtx: Int

        enum CodingKeys: String, CodingKey {
            case numCtx = "num_ctx"
        }
    }
}

// MARK: - Generate Response

struct OllamaGenerateResponse: Codable, Sendable {
    let model: String
    let response: String
}
