import Testing
import Foundation
@testable import PSTranscribe

@Suite("SessionType + DictationOutputMode + DictationHotkeyMode Codable round-trips")
struct SessionTypeCodableTests {

    private func roundTrip<T: Codable & Equatable>(_ value: T) throws -> T {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(T.self, from: data)
    }

    @Test func sessionTypeDictationRoundTrips() throws {
        let decoded = try roundTrip(SessionType.dictation)
        #expect(decoded == .dictation)
    }

    @Test func sessionTypeDictationRawValueIsLowerCamel() {
        #expect(SessionType.dictation.rawValue == "dictation")
    }

    @Suite("dictationOutputMode")
    struct DictationOutputModeTests {
        private func roundTrip<T: Codable & Equatable>(_ value: T) throws -> T {
            let data = try JSONEncoder().encode(value)
            return try JSONDecoder().decode(T.self, from: data)
        }

        @Test func clipboard() throws {
            let decoded = try roundTrip(DictationOutputMode.clipboard)
            #expect(decoded == .clipboard)
            #expect(DictationOutputMode.clipboard.rawValue == "clipboard")
        }

        @Test func plainFolder() throws {
            let decoded = try roundTrip(DictationOutputMode.plainFolder)
            #expect(decoded == .plainFolder)
            #expect(DictationOutputMode.plainFolder.rawValue == "plainFolder")
        }

        @Test func both() throws {
            let decoded = try roundTrip(DictationOutputMode.both)
            #expect(decoded == .both)
            #expect(DictationOutputMode.both.rawValue == "both")
        }

        @Test func decodingUnknownRawValueFails() {
            let bogus = Data("\"bogus\"".utf8)
            #expect(throws: DecodingError.self) {
                _ = try JSONDecoder().decode(DictationOutputMode.self, from: bogus)
            }
        }
    }

    @Suite("dictationHotkeyMode")
    struct DictationHotkeyModeTests {
        private func roundTrip<T: Codable & Equatable>(_ value: T) throws -> T {
            let data = try JSONEncoder().encode(value)
            return try JSONDecoder().decode(T.self, from: data)
        }

        @Test func toggle() throws {
            let decoded = try roundTrip(DictationHotkeyMode.toggle)
            #expect(decoded == .toggle)
            #expect(DictationHotkeyMode.toggle.rawValue == "toggle")
        }

        @Test func pressAndHold() throws {
            let decoded = try roundTrip(DictationHotkeyMode.pressAndHold)
            #expect(decoded == .pressAndHold)
            #expect(DictationHotkeyMode.pressAndHold.rawValue == "pressAndHold")
        }

        @Test func decodingUnknownRawValueFails() {
            let bogus = Data("\"bogus\"".utf8)
            #expect(throws: DecodingError.self) {
                _ = try JSONDecoder().decode(DictationHotkeyMode.self, from: bogus)
            }
        }
    }
}
