// PreferredColorSchemeGrepGateTests
// Phase 25 (NYQUIST-07) -- Phase 21 REQ-21.2a / REQ-21.3a / REQ-21.4.
// (Plan 25-02 extends this file with REQ-20.1 / REQ-20.3 / REQ-20.4a tests.)
//
// Static source assertions on Swift source files under Sources/PSTranscribe/.
// Reads the committed files as Strings and verifies invariants:
//   - Phase 21 REQ-21.2a / REQ-21.4: every `.preferredColorScheme(...)` call in
//     PSTranscribeApp.swift OUTSIDE `#Preview { ... }` blocks reads from
//     `settings.appearancePreference.colorScheme` (relaxed grep per Phase 21
//     D-06: location + source contract, not exact count).
//   - Phase 21 REQ-21.2a forbidden-elsewhere: no other view source file under
//     Sources/PSTranscribe/Views/ contains `.preferredColorScheme(` outside
//     `#Preview` blocks (refactor tripwire).
//   - Phase 21 REQ-21.3a: SettingsView.swift contains a `Section("Appearance")`
//     + `Picker` bound to `$settings.appearancePreference`.
//
// Working-directory assumption: `swift test` runs from `PSTranscribe/` (the
// SwiftPM package root). Source files live at `Sources/PSTranscribe/...`. The
// helper `readSource(_:)` includes a `try #require(!content.isEmpty)` smoke
// check so a wrong cwd fails fast with a clear message instead of silently
// passing absence assertions.
//
// The `stripPreviewBlocks(_:)` helper is a Phase-25-introduced utility (no
// in-house analog). It removes `#Preview { ... }` blocks before grep-style
// assertions so dev-tool-only preview code does not pollute production-code
// contracts. Implementation: linear scan with brace counting (not regex --
// regex with balanced braces is fragile in Swift's NSRegularExpression).

import Testing
import Foundation

@Suite("PreferredColorSchemeGrepGateTests")
struct PreferredColorSchemeGrepGateTests {

    private func readSource(_ relativePath: String) throws -> String {
        // cwd at `swift test` time is PSTranscribe/; source root is Sources/PSTranscribe/
        let url = URL(fileURLWithPath: "Sources/PSTranscribe/\(relativePath)")
        let content = try String(contentsOf: url, encoding: .utf8)
        try #require(!content.isEmpty,
                     "Read empty content from \(relativePath); is the test cwd PSTranscribe/?")
        return content
    }

    /// Returns `.swift` files under `Sources/PSTranscribe/<subdir>` as relative
    /// paths suitable for `readSource(_:)` (e.g. `["Views/CaptureDock.swift",
    /// "Views/ContentView.swift", ...]`). Used for refactor-tripwire tests so
    /// new view files added by future PRs are automatically in scope (W-01 fix --
    /// hardcoded rosters under-cover the actual surface).
    private func swiftFilesUnder(_ subdir: String) throws -> [String] {
        let path = "Sources/PSTranscribe/\(subdir)"
        let names = try FileManager.default
            .contentsOfDirectory(atPath: path)
            .filter { $0.hasSuffix(".swift") }
            .sorted()
        try #require(!names.isEmpty,
                     "No Swift files found under Sources/PSTranscribe/\(subdir); is the test cwd PSTranscribe/?")
        return names.map { "\(subdir)/\($0)" }
    }

    /// Strips `#Preview { ... }` and `#Preview("name") { ... }` blocks from source
    /// so grep gates inspect only production code. Linear scan with brace counting.
    /// Limitation: does not support nested `#Preview` (codebase does not use this).
    private func stripPreviewBlocks(_ source: String) -> String {
        var result = ""
        var i = source.startIndex
        while i < source.endIndex {
            // Look for `#Preview` token
            if source[i...].hasPrefix("#Preview") {
                // Skip to first `{` after the macro literal
                var j = source.index(i, offsetBy: "#Preview".count)
                while j < source.endIndex && source[j] != "{" { j = source.index(after: j) }
                if j == source.endIndex { break }  // malformed; bail to safety
                // Brace-balance from `{`
                var depth = 0
                while j < source.endIndex {
                    if source[j] == "{" { depth += 1 }
                    else if source[j] == "}" {
                        depth -= 1
                        if depth == 0 {
                            j = source.index(after: j)
                            break
                        }
                    }
                    j = source.index(after: j)
                }
                i = j
            } else {
                result.append(source[i])
                i = source.index(after: i)
            }
        }
        return result
    }

    // MARK: - REQ-21.2a + REQ-21.4 (one @Test satisfies both per Phase 21 D-06)

    @Test func preferredColorSchemeOnlyAtAppRootReadingFromSettings() throws {
        let appSrc = try readSource("App/PSTranscribeApp.swift")
        let stripped = stripPreviewBlocks(appSrc)
        // Match `.preferredColorScheme(<arg>)` -- leading `\.` so doc-comment hits in
        // other files don't false-positive (here we read PSTranscribeApp.swift only).
        let pattern = try NSRegularExpression(pattern: #"\.preferredColorScheme\(([^)]+)\)"#)
        let nsStripped = stripped as NSString
        let matches = pattern.matches(in: stripped, range: NSRange(location: 0, length: nsStripped.length))
        #expect(matches.count >= 1,
                "PSTranscribeApp.swift must contain at least one Scene-root .preferredColorScheme call (Phase 21 D-05 / REQ-21.2a)")
        for m in matches {
            let arg = nsStripped.substring(with: m.range(at: 1))
            #expect(arg.contains("settings.appearancePreference.colorScheme"),
                    "Every .preferredColorScheme call outside #Preview must read from AppSettings (Phase 21 REQ-21.4); got: \(arg)")
        }
    }

    // MARK: - REQ-21.2a forbidden-elsewhere (refactor tripwire)

    @Test func noPreferredColorSchemeOutsideAppRoot() throws {
        // W-01 fix: walk Views/ at test time so any future-added view file is
        // automatically in scope. The app-root file (PSTranscribeApp.swift) lives
        // in Sources/PSTranscribe/App/ and is not enumerated here by design.
        let surfaces = try swiftFilesUnder("Views")
        for path in surfaces {
            let stripped = stripPreviewBlocks(try readSource(path))
            #expect(!stripped.contains(".preferredColorScheme("),
                    "\(path) must not call .preferredColorScheme outside #Preview (Phase 21 REQ-21.2a single-app-root invariant)")
        }
    }

    // MARK: - REQ-21.3a

    @Test func settingsViewContainsAppearancePicker() throws {
        let src = try readSource("Views/SettingsView.swift")
        #expect(src.contains(#"Section("Appearance")"#),
                "SettingsView.swift must contain Section(\"Appearance\") (Phase 21 REQ-21.3a)")
        #expect(src.contains("Picker"),
                "SettingsView.swift Appearance section must contain a Picker (Phase 21 REQ-21.3a)")
        #expect(src.contains("selection: $settings.appearancePreference"),
                "SettingsView.swift Picker must bind to $settings.appearancePreference (Phase 21 REQ-21.3a)")
    }
}
