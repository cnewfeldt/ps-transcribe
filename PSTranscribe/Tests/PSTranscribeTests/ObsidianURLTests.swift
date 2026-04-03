import Testing
import Foundation
@testable import PSTranscribe

@Suite("Obsidian URL Tests")
struct ObsidianURLTests {
    @Test func returnsNilForMismatchedPrefix() {
        let url = obsidianURL(
            for: "/Users/other/path/file.md",
            vaultRoot: "/Users/cary/vault",
            vaultName: "MyVault"
        )
        #expect(url == nil)
    }

    @Test func stripsMdExtension() {
        let url = obsidianURL(
            for: "/Users/cary/vault/transcript.md",
            vaultRoot: "/Users/cary/vault",
            vaultName: "MyVault"
        )
        #expect(url != nil)
        let urlStr = url!.absoluteString
        #expect(!urlStr.contains(".md"))
    }

    @Test func buildsCorrectURL() {
        let url = obsidianURL(
            for: "/Users/cary/vault/subfolder/transcript.md",
            vaultRoot: "/Users/cary/vault",
            vaultName: "MyVault"
        )
        #expect(url != nil)
        #expect(url!.absoluteString == "obsidian://open?vault=MyVault&file=subfolder/transcript")
    }

    @Test func urlEncodesVaultNameWithSpaces() {
        let url = obsidianURL(
            for: "/Users/cary/vault/file.md",
            vaultRoot: "/Users/cary/vault",
            vaultName: "My Vault"
        )
        #expect(url != nil)
        let urlStr = url!.absoluteString
        #expect(urlStr.contains("My%20Vault") || urlStr.contains("My+Vault"))
    }

    @Test func urlEncodesPathWithSpaces() {
        let url = obsidianURL(
            for: "/Users/cary/vault/my folder/my transcript.md",
            vaultRoot: "/Users/cary/vault",
            vaultName: "MyVault"
        )
        #expect(url != nil)
        let urlStr = url!.absoluteString
        // Path should be percent-encoded
        #expect(!urlStr.contains("my folder/my transcript"))
    }
}
