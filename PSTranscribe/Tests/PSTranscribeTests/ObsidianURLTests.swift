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

    // MARK: - obsidianVaultName

    @Test func derivesVaultNameFromSubPath() {
        let name = obsidianVaultName(from: "/Users/cary/Documents/MyVault/Meetings")
        #expect(name == "MyVault")
    }

    @Test func returnsNilForEmptyPath() {
        let name = obsidianVaultName(from: "")
        #expect(name == nil)
    }
}
