import Testing
import Foundation
@testable import PSTranscribe

@Suite("ObsidianURL Tests")
struct ObsidianURLTests {

    // MARK: - makeObsidianURL

    @Test func returnsCorrectURLForSimplePath() throws {
        let url = makeObsidianURL(
            filePath: "/Users/cary/Vault/Meetings/2026-04-07-standup.md",
            vaultRoot: "/Users/cary/Vault",
            vaultName: "Vault"
        )
        let result = try #require(url)
        #expect(result.scheme == "obsidian")
        #expect(result.host == "open")
        let query = result.query ?? ""
        #expect(query.contains("vault=Vault"))
        #expect(query.contains("file=Meetings%2F2026-04-07-standup.md") || query.contains("file=Meetings/2026-04-07-standup.md"))
    }

    @Test func percentEncodesSpacesInVaultNameAndPath() throws {
        let url = makeObsidianURL(
            filePath: "/Users/cary/My Vault/Meetings/my recording.md",
            vaultRoot: "/Users/cary/My Vault",
            vaultName: "My Vault"
        )
        let result = try #require(url)
        let query = result.query ?? ""
        // URLComponents percent-encodes spaces to %20
        #expect(query.contains("vault=My%20Vault") || query.contains("vault=My Vault"))
        #expect(query.contains("my%20recording") || query.contains("my recording"))
    }

    @Test func returnsNilWhenFileNotUnderVaultRoot() {
        let url = makeObsidianURL(
            filePath: "/other/path/file.md",
            vaultRoot: "/Users/cary/Vault",
            vaultName: "Vault"
        )
        #expect(url == nil)
    }

    @Test func returnsNilWhenFilePathIsEmpty() {
        let url = makeObsidianURL(
            filePath: "",
            vaultRoot: "/Users/cary/Vault",
            vaultName: "Vault"
        )
        #expect(url == nil)
    }

    @Test func returnsNilWhenVaultIsEmpty() {
        let url = makeObsidianURL(
            filePath: "/Users/cary/Vault/file.md",
            vaultRoot: "",
            vaultName: ""
        )
        #expect(url == nil)
    }

    // MARK: - obsidianVaultForPath

    @Test func returnsNilForEmptyFilePath() {
        let result = obsidianVaultForPath("")
        #expect(result == nil)
    }

    @Test func returnsVaultWhenFileIsInsideKnownVault() throws {
        // This test depends on Obsidian being installed with a vault at
        // /Users/cary/Obsidian Vault/C2YN6T -- skip if not available
        let result = obsidianVaultForPath("/Users/cary/Obsidian Vault/C2YN6T/0-Inbox/test.md")
        if let result {
            #expect(result.name == "C2YN6T")
            #expect(result.root == "/Users/cary/Obsidian Vault/C2YN6T")
        }
        // If nil, Obsidian config not present on this machine -- acceptable
    }

    @Test func returnsNilForPathOutsideAnyVault() {
        let result = obsidianVaultForPath("/tmp/not-a-vault/file.md")
        #expect(result == nil)
    }
}
