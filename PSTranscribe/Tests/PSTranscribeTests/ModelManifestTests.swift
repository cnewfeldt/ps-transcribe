import Testing
import Foundation
@testable import PSTranscribe

@Suite("ModelManifest Codable + version compare", .serialized)
struct ModelManifestTests {

    // MARK: - Codable round-trip

    @Test func roundTripCompleteManifest() throws {
        let json = """
        {
            "model_id": "parakeet-tdt-0.6b-v3-coreml",
            "version": "20260427",
            "min_app_version": "1.2.0",
            "total_size_bytes": 545312000,
            "released_at": "2026-04-27T00:00:00Z",
            "files": [
                { "name": "preprocessor.mlpackage", "url": "https://huggingface.co/a/b", "sha256": "abc123", "size": 12345 },
                { "name": "encoder.mlpackage", "url": "https://huggingface.co/a/c", "sha256": "def456", "size": 234567890 },
                { "name": "decoder.mlpackage", "url": "https://huggingface.co/a/d", "sha256": "ghi789", "size": 78901234 }
            ]
        }
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(ModelManifest.self, from: data)

        #expect(decoded.model_id == "parakeet-tdt-0.6b-v3-coreml")
        #expect(decoded.version == "20260427")
        #expect(decoded.min_app_version == "1.2.0")
        #expect(decoded.total_size_bytes == 545312000)
        #expect(decoded.released_at == "2026-04-27T00:00:00Z")
        #expect(decoded.files.count == 3)
        #expect(decoded.files[0].name == "preprocessor.mlpackage")
        #expect(decoded.files[0].url == "https://huggingface.co/a/b")
        #expect(decoded.files[0].sha256 == "abc123")
        #expect(decoded.files[0].size == 12345)

        // Round-trip via encode then decode
        let encoded = try JSONEncoder().encode(decoded)
        let redecoded = try JSONDecoder().decode(ModelManifest.self, from: encoded)
        #expect(redecoded == decoded)
    }

    @Test func roundTripWithoutReleasedAt() throws {
        let json = """
        {
            "model_id": "parakeet-tdt-0.6b-v3-coreml",
            "version": "20260427",
            "min_app_version": "1.2.0",
            "total_size_bytes": 545312000,
            "files": [
                { "name": "encoder.mlpackage", "url": "https://huggingface.co/a/c", "sha256": "def456", "size": 234567890 }
            ]
        }
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(ModelManifest.self, from: data)
        #expect(decoded.released_at == nil)
    }

    // MARK: - Version comparison

    @Test func numericCompareDottedVersions() {
        #expect("1.10.0".compare("1.2.0", options: .numeric) == .orderedDescending)
        #expect("1.9.0".compare("1.10.0", options: .numeric) == .orderedAscending)
    }

    @Test func numericCompareDateVersions() {
        #expect("20260427".compare("20260601", options: .numeric) == .orderedAscending)
    }

    @Test func numericCompareMixedShape() {
        // This is the exact installed app vs manifest min_app_version case from Info.plist:14
        #expect("1.2.0".compare("2.1.1", options: .numeric) == .orderedAscending)
    }

    @Test func numericCompareEmptyOlderThanAnything() {
        #expect("".compare("20260427", options: .numeric) == .orderedAscending)
    }
}
