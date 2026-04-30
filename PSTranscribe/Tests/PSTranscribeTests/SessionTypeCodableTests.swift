import Testing
import Foundation
@testable import PSTranscribe

@Suite("SessionType + DictationHotkeyMode Codable round-trips")
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

    // 18.1: DictationOutputMode enum was deleted in Plan 18.1-01 along with the
    // settings.dictationOutputMode key. The Codable round-trip suite for that
    // enum is no longer applicable (the enum no longer exists in the codebase).

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
