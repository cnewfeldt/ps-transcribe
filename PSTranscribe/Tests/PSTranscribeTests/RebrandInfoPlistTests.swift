// RebrandInfoPlistTests
// Phase 24 (NYQUIST-01) -- re-audit of v1.0 Phase 1 Rebrand requirements REBR-01/02/04/06/07.
//
// Reads Info.plist via direct file IO from the package root (`Sources/PSTranscribe/Info.plist`).
// Bundle.main is intentionally NOT used: in a Swift Testing target, Bundle.main is the test
// runner's bundle, not the app bundle, and the app's CFBundleName/CFBundleIdentifier may not
// be present. Working-directory assumption: `swift test` runs from `PSTranscribe/` (the SwiftPM
// package root). The first `try #require(!data.isEmpty)` per test fails fast with a clear
// message if that assumption breaks.
//
// REBR-08 (UserDefaults migration from io.gremble.tome) is WITHDRAWN per Phase 24 D-03 --
// code deleted in commit 4ef30e0 post-v1.0 ship; no surviving API. See 01-VALIDATION.md.

import Testing
import Foundation

@Suite("RebrandInfoPlistTests")
struct RebrandInfoPlistTests {

    private func loadInfoPlist() throws -> [String: Any] {
        let url = URL(fileURLWithPath: "Sources/PSTranscribe/Info.plist")
        let data = try Data(contentsOf: url)
        try #require(!data.isEmpty)  // Risk #3: fail fast if cwd is not PSTranscribe/
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        return try #require(plist)
    }

    @Test func bundleNameIsPSTranscribe() throws {
        let plist = try loadInfoPlist()
        let name = try #require(plist["CFBundleName"] as? String)
        #expect(name == "PS Transcribe")
    }

    @Test func bundleIdentifierIsPSTranscribe() throws {
        let plist = try loadInfoPlist()
        let id = try #require(plist["CFBundleIdentifier"] as? String)
        #expect(id == "com.pstranscribe.app")
    }

    @Test func executableNameIsPSTranscribe() throws {
        let plist = try loadInfoPlist()
        let exec = try #require(plist["CFBundleExecutable"] as? String)
        #expect(exec == "PSTranscribe")  // exact, no spaces
    }

    @Test func sparkleFeedURLPointsAtPSTranscribe() throws {
        let plist = try loadInfoPlist()
        let feed = try #require(plist["SUFeedURL"] as? String)
        #expect(feed.contains("ps-transcribe"))
        #expect(feed.contains("appcast.xml"))
        #expect(!feed.contains("Tome"))
        #expect(!feed.contains("Gremble"))
        #expect(!feed.contains("OWNER"))  // resolved tech debt -- no placeholder
    }

    @Test func displayNameAndMicUsageMentionPSTranscribe() throws {
        let plist = try loadInfoPlist()
        let displayName = try #require(plist["CFBundleDisplayName"] as? String)
        #expect(displayName == "PS Transcribe")
        let micUsage = try #require(plist["NSMicrophoneUsageDescription"] as? String)
        #expect(micUsage.contains("PS Transcribe"))
    }
}
