import Foundation
import Testing
@testable import PSTranscribe

@MainActor
@Suite("Phase 18.1 -- AppSettings destination keys round-trip via UserDefaults")
struct AppSettingsDestinationPersistenceTests {

    private static let keys = [
        "localFileEnabled",
        "localFileRoot",
        "obsidianEnabled",
        "obsidianFolderPath",
    ]

    private func clearKeys() {
        for k in Self.keys { UserDefaults.standard.removeObject(forKey: k) }
    }

    @Test("localFileEnabled round-trips false then true")
    func localFileEnabledRoundTrips() {
        clearKeys()
        defer { clearKeys() }

        let s1 = AppSettings()
        s1.localFileEnabled = false
        #expect(UserDefaults.standard.bool(forKey: "localFileEnabled") == false)

        let s2 = AppSettings()
        #expect(s2.localFileEnabled == false)
        s2.localFileEnabled = true
        #expect(UserDefaults.standard.bool(forKey: "localFileEnabled") == true)

        let s3 = AppSettings()
        #expect(s3.localFileEnabled == true)
    }

    @Test("localFileEnabled defaults to true (D-06) when key absent")
    func localFileEnabledDefaultIsTrue() {
        clearKeys()
        defer { clearKeys() }

        let s = AppSettings()
        #expect(s.localFileEnabled == true, "D-06: meetings/memos work out of the box")
    }

    @Test("localFileRoot round-trips a custom path")
    func localFileRootRoundTrips() {
        clearKeys()
        defer { clearKeys() }

        let s1 = AppSettings()
        s1.localFileRoot = "/tmp/test-pstranscribe-root"
        #expect(UserDefaults.standard.string(forKey: "localFileRoot") == "/tmp/test-pstranscribe-root")

        let s2 = AppSettings()
        #expect(s2.localFileRoot == "/tmp/test-pstranscribe-root")
    }

    @Test("localFileRoot default expands to ~/Documents/PSTranscribe when key absent (D-06)")
    func localFileRootDefaultExpandsTilde() {
        clearKeys()
        defer { clearKeys() }

        let s = AppSettings()
        #expect(s.localFileRoot.hasSuffix("/Documents/PSTranscribe"))
        #expect(!s.localFileRoot.hasPrefix("~"), "tilde must be expanded at init time")
    }

    @Test("obsidianEnabled round-trips true then false")
    func obsidianEnabledRoundTrips() {
        clearKeys()
        defer { clearKeys() }

        let s1 = AppSettings()
        s1.obsidianEnabled = true
        #expect(UserDefaults.standard.bool(forKey: "obsidianEnabled") == true)

        let s2 = AppSettings()
        #expect(s2.obsidianEnabled == true)
        s2.obsidianEnabled = false
        #expect(UserDefaults.standard.bool(forKey: "obsidianEnabled") == false)

        let s3 = AppSettings()
        #expect(s3.obsidianEnabled == false)
    }

    @Test("obsidianEnabled defaults to false (D-10) when key absent")
    func obsidianEnabledDefaultIsFalse() {
        clearKeys()
        defer { clearKeys() }

        let s = AppSettings()
        #expect(s.obsidianEnabled == false, "D-10: Obsidian is opt-in")
    }

    @Test("obsidianFolderPath round-trips a custom path")
    func obsidianFolderPathRoundTrips() {
        clearKeys()
        defer { clearKeys() }

        let s1 = AppSettings()
        s1.obsidianFolderPath = "/tmp/test-vault"
        #expect(UserDefaults.standard.string(forKey: "obsidianFolderPath") == "/tmp/test-vault")

        let s2 = AppSettings()
        #expect(s2.obsidianFolderPath == "/tmp/test-vault")
    }

    @Test("obsidianFolderPath defaults to empty string (D-10) when key absent")
    func obsidianFolderPathDefaultIsEmpty() {
        clearKeys()
        defer { clearKeys() }

        let s = AppSettings()
        #expect(s.obsidianFolderPath == "")
    }
}
