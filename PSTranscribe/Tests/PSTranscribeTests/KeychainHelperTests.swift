import Testing
import Foundation
@testable import PSTranscribe

@Suite("KeychainHelper Tests")
struct KeychainHelperTests {
    // Use a test-specific service name to avoid polluting the real Keychain
    let testService = "com.pstranscribe.tests"
    let testKey = "test-key-\(UUID().uuidString)"

    func cleanup(key: String) {
        try? KeychainHelper.delete(key: key, service: testService)
    }

    @Test func saveAndReadReturnsData() throws {
        let key = "test-save-read-\(UUID().uuidString)"
        defer { cleanup(key: key) }

        let original = "secret-value-12345"
        let data = original.data(using: .utf8)!

        try KeychainHelper.save(key: key, service: testService, data: data)

        let retrieved = KeychainHelper.read(key: key, service: testService)
        #expect(retrieved != nil)
        let retrievedString = String(data: retrieved!, encoding: .utf8)
        #expect(retrievedString == original)
    }

    @Test func readMissingKeyReturnsNil() {
        let key = "nonexistent-key-\(UUID().uuidString)"
        let result = KeychainHelper.read(key: key, service: testService)
        #expect(result == nil)
    }

    @Test func deleteRemovesSavedData() throws {
        let key = "test-delete-\(UUID().uuidString)"

        let data = "to-be-deleted".data(using: .utf8)!
        try KeychainHelper.save(key: key, service: testService, data: data)

        // Verify it was saved
        #expect(KeychainHelper.read(key: key, service: testService) != nil)

        // Delete and verify gone
        try KeychainHelper.delete(key: key, service: testService)
        #expect(KeychainHelper.read(key: key, service: testService) == nil)
    }
}
