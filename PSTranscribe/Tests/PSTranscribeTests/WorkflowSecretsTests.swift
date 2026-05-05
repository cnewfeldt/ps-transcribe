// WorkflowSecretsTests
// Phase 24 (NYQUIST-02) -- Phase 02 SECR-01/05/07/08/12 + Phase 01 REBR-05.
//
// Static source assertions on workflow YAML files and .gitignore. Reads the
// committed files as Strings and verifies invariants:
//   - No 'Tome' / 'Gremble' / 'x-access-token' / '2>/dev/null' substrings
//   - 'gh repo clone' present (no embedded GH_TOKEN in URLs)
//   - 'mktemp' used for keychain creation (no fixed-name keychain files)
//   - All `actions/...@<ref>` references are 40-char commit SHAs
//   - .gitignore blocks all 7 standard secret-file patterns
//
// Working-directory assumption: `swift test` runs from `PSTranscribe/` (the
// SwiftPM package root). Workflow files live at `../.github/workflows/...`,
// .gitignore at `../.gitignore`. The helper `readRepoRootFile(_:)` includes a
// `try #require(!content.isEmpty)` smoke check so a wrong cwd fails fast
// with a clear message instead of silently passing absence assertions.
//
// SECR-07 (SHA-pin) was fixed inline in Plan 24-05 Task 1: build-check.yml:56
// was `actions/upload-artifact@v4` (Phase 23 regression); restored to
// `actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02 # v4`.

import Testing
import Foundation

@Suite("WorkflowSecretsTests")
struct WorkflowSecretsTests {

    private func readRepoRootFile(_ relativePath: String) throws -> String {
        // cwd at swift-test time is PSTranscribe/; repo root is ../
        let url = URL(fileURLWithPath: "../\(relativePath)")
        let content = try String(contentsOf: url, encoding: .utf8)
        try #require(!content.isEmpty,
                     "Read empty content from \(relativePath); is the test cwd PSTranscribe/?")
        return content
    }

    @Test func noTomeOrTokenOrSuppressionInBuildCheck() throws {
        let yaml = try readRepoRootFile(".github/workflows/build-check.yml")
        #expect(!yaml.contains("Tome"))
        #expect(!yaml.contains("Gremble"))
        #expect(!yaml.contains("x-access-token"))
        #expect(!yaml.contains("2>/dev/null"))
        #expect(yaml.contains("working-directory: PSTranscribe"))
    }

    @Test func noTokenInReleaseDmgAndGhCloneUsed() throws {
        let yaml = try readRepoRootFile(".github/workflows/release-dmg.yml")
        #expect(!yaml.contains("x-access-token"))
        #expect(yaml.contains("gh repo clone"))
        #expect(!yaml.contains("2>/dev/null"))
    }

    @Test func keychainUsesMktemp() throws {
        let yaml = try readRepoRootFile(".github/workflows/release-dmg.yml")
        #expect(yaml.contains("mktemp /tmp/keychain."),
                "release-dmg.yml must use `mktemp /tmp/keychain.XXXXXX.keychain-db` for SECR-05")
    }

    @Test func actionsAreSHAPinned() throws {
        let workflows = ["build-check.yml", "release-dmg.yml", "lint-summaries.yml"]
        // Regex: `uses: actions/<name>@<ref>` -- capture the ref (group 1)
        let pattern = try NSRegularExpression(pattern: #"uses:\s+actions/[^@]+@(\S+)"#)
        for name in workflows {
            let yaml = try readRepoRootFile(".github/workflows/\(name)")
            let nsYaml = yaml as NSString
            let matches = pattern.matches(in: yaml, range: NSRange(location: 0, length: nsYaml.length))
            for m in matches {
                let ref = nsYaml.substring(with: m.range(at: 1))
                #expect(ref.range(of: #"^[a-f0-9]{40}$"#, options: .regularExpression) != nil,
                        "\(name): action ref '\(ref)' is not a 40-char SHA")
            }
        }
    }

    @Test func gitignoreBlocksSecretFilePatterns() throws {
        let gitignore = try readRepoRootFile(".gitignore")
        let required = [".env", "*.p12", "*.cer", "*.pem", "*.key", "*.keychain", "*.keychain-db"]
        for pattern in required {
            #expect(gitignore.contains(pattern),
                    ".gitignore must block '\(pattern)' (SECR-08)")
        }
    }
}
