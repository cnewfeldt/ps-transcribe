import Testing
import Foundation
@testable import PSTranscribe

@Suite("SpeakerCodableTests")
struct SpeakerCodableTests {

    // MARK: - Round-trip tests

    @Test func namedSpeakerRoundTrips() throws {
        let original = Speaker.named("Speaker 2")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Speaker.self, from: data)
        #expect(decoded == Speaker.named("Speaker 2"))
    }

    @Test func youRoundTrips() throws {
        let original = Speaker.you
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Speaker.self, from: data)
        #expect(decoded == Speaker.you)
    }

    @Test func themRoundTrips() throws {
        let original = Speaker.them
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Speaker.self, from: data)
        #expect(decoded == Speaker.them)
    }

    // MARK: - Legacy bare-string decode tests

    @Test func legacyYouDecodesCorrectly() throws {
        let data = Data("\"you\"".utf8)
        let decoded = try JSONDecoder().decode(Speaker.self, from: data)
        #expect(decoded == Speaker.you)
    }

    @Test func legacyThemDecodesCorrectly() throws {
        let data = Data("\"them\"".utf8)
        let decoded = try JSONDecoder().decode(Speaker.self, from: data)
        #expect(decoded == Speaker.them)
    }

    @Test func unknownLegacyStringDegradesGracefully() throws {
        let data = Data("\"unknown\"".utf8)
        let decoded = try JSONDecoder().decode(Speaker.self, from: data)
        #expect(decoded == Speaker.them)
    }
}
