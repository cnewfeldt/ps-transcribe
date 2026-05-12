# Phase 25: Nyquist Sweep -- v1.2 - Pattern Map

**Mapped:** 2026-05-07
**Files analyzed:** 2 VALIDATION.md (new) + 3 Swift Testing surfaces (1 extension, 2 new) + 7 cross-referenced existing tests = 12 file-level decisions
**Analogs found:** 12 / 12 (every Phase 25 surface has a strong in-house precedent; Phase 24 wrote the playbook end-to-end)

Phase 25 is mechanical audit work that inherits Phase 24's playbook wholesale. Every new test follows an established Swift Testing shape that already lives in `PSTranscribe/Tests/PSTranscribeTests/`, and every VALIDATION.md row mirrors the column shape locked by Phase 24's `01/02/03/08/10-VALIDATION.md` files. The two amendments to Phase 24's playbook (D-02 PARTIAL `a/b` row split, D-03 forward cross-ref to Phase 26) are additive: they don't change row formatting or test shape, only the *content* of specific rows.

Two patterns are net-new for the test target -- both are extensions of existing precedents:

- **NSColor bridging from `Color(light:dark:)`** for runtime color resolution -- new pattern, but uses a stable AppKit API (`NSColor(_ swiftUIColor: SwiftUI.Color)` + `usingColorSpace(.sRGB)?.redComponent`) that fits cleanly into the existing `Color` extension in `DesignTokens.swift`. Surface rationale documented in §"No Analog Found".
- **Swift source-file grep gates** that span `PSTranscribeApp.swift` + `SettingsView.swift` + `TranscriptView.swift` + `DesignTokens.swift` -- the read-source-as-String shape is already in `WorkflowSecretsTests.swift` (workflow YAML) and `RebrandInfoPlistTests.swift` (Info.plist via `Data(contentsOf:)`); Phase 25 transposes the pattern to `Sources/PSTranscribe/**/*.swift` files. Mirrors Phase 24's `ErrorPathLoggingTests.swift` precedent.

---

## File Classification

### New / Extended Swift Testing Files (D-04 inherited from Phase 24: flat layout, behavior-named)

| File | Status | Role | Data Flow | Closest Analog | Match Quality |
|------|--------|------|-----------|----------------|---------------|
| `PSTranscribe/Tests/PSTranscribeTests/AppSettingsTests.swift` | extend | test (unit, persistence) | request-response (UD round-trip) + file-I/O (UserDefaults plist) | self -- existing `roundTrip_*` cluster | exact (self-extension) |
| `PSTranscribe/Tests/PSTranscribeTests/PreferredColorSchemeGrepGateTests.swift` | new | test (unit, static source assertion) | file-I/O (read `Sources/PSTranscribe/**/*.swift` as String) | `WorkflowSecretsTests.swift` (Phase 24, peer pattern) + `ErrorPathLoggingTests.swift` (Phase 24, source-grep precedent) | exact |
| `PSTranscribe/Tests/PSTranscribeTests/DesignTokensAdaptivePaletteTests.swift` | new | test (unit, color resolution) | request-response (NSColor bridging via `NSColor(SwiftUI.Color)`) | `ObsidianURLTests.swift` (pure-function I/O assertion shape) -- NSColor bridging itself is net-new | role-match (shape exact, technique new) |

### New VALIDATION.md Files (created from scratch -- no draft exists, unlike Phase 24 which edited drafts)

| File | Status | Role | Data Flow | Closest Analog | Match Quality |
|------|--------|------|-----------|----------------|---------------|
| `.planning/milestones/v1.2-phases/20-dark-mode-parity/20-VALIDATION.md` | new | doc (frontmatter + per-task verification map) | transform (SPEC reqs -> approved Nyquist contract) | `.planning/milestones/v1.0-phases/01-rebrand/01-VALIDATION.md` (post-Phase-24 shape with Test Type column + WITHDRAWN rows + 2026-05-05 audit block) | exact |
| `.planning/milestones/v1.2-phases/21-appearance-override/21-VALIDATION.md` | new | doc | transform | `01-VALIDATION.md` post-2026-05-05 + Phase 24 D-03 lenient WITHDRAWN policy | exact |

### Cross-Referenced Existing Tests (no edits, just citations in VALIDATION.md rows)

| Existing Test File | Reqs Cited | Reason |
|--------------------|-----------|--------|
| `WorkflowSecretsTests.swift` | n/a in Phase 25 directly | Read-only precedent for source-grep mechanics in `PreferredColorSchemeGrepGateTests.swift` |
| `RebrandInfoPlistTests.swift` | n/a in Phase 25 directly | Read-only precedent for cwd-relative file IO + `try #require(!data.isEmpty)` smoke check |
| `AppSettingsTests.swift` (existing rows, pre-Phase-25) | n/a | Read-only precedent for `@Suite(.serialized)` + `@MainActor` + `clearV12Keys()` helper pattern; Phase 25 extends this file |

---

## Pattern Assignments

### Plan 25-01: `21-VALIDATION.md` + AppearancePreference tests (lands first, smaller)

#### `AppSettingsTests.swift` extension -- AppearancePreference UD round-trip (REQ-21.1, REQ-21.6)

**Reqs covered:** REQ-21.1 (enum + UD round-trip), REQ-21.6 (missing-key fallback)
**Analog:** Self -- existing `roundTrip_*` and `Defaults` clusters in the same file (lines 26-135)

**Existing imports + suite header pattern** (lifted from `AppSettingsTests.swift:1-23`):

```swift
import Testing
import Foundation
@testable import PSTranscribe

@Suite("AppSettings v1.2 keys", .serialized)
struct AppSettingsTests {

    private static let v12Keys = [
        "dictationHotkeyMode",
        "clipboardRestoreDelay",
        // ... (Phase 25 ADDS "appearancePreference" to this list)
    ]

    fileprivate static func clearV12Keys() {
        for key in v12Keys { UserDefaults.standard.removeObject(forKey: key) }
    }
```

**Action for Phase 25:** Add `"appearancePreference"` to the `v12Keys` array (line 12-18) so existing `clearV12Keys()` covers cleanup for the new tests.

**Defaults block extension pattern** (modeled on `AppSettingsTests.swift:26-62`):

```swift
@Suite("defaults", .serialized)
struct Defaults {
    @Test @MainActor func appearancePreferenceDefaultsToSystem() {
        AppSettingsTests.clearV12Keys()
        defer { AppSettingsTests.clearV12Keys() }
        let s = AppSettings()
        #expect(s.appearancePreference == .system)
    }
}
```

**Round-trip pattern** (modeled on `AppSettingsTests.swift:66-73` -- `roundTrip_dictationHotkeyMode`):

```swift
@Test @MainActor func roundTrip_appearancePreferenceLight() {
    Self.clearV12Keys()
    defer { Self.clearV12Keys() }
    let s1 = AppSettings()
    s1.appearancePreference = .light
    let s2 = AppSettings()
    #expect(s2.appearancePreference == .light)
}

@Test @MainActor func roundTrip_appearancePreferenceDark() {
    Self.clearV12Keys()
    defer { Self.clearV12Keys() }
    let s1 = AppSettings()
    s1.appearancePreference = .dark
    let s2 = AppSettings()
    #expect(s2.appearancePreference == .dark)
}
```

**Missing-key fallback pattern (REQ-21.6)** -- adapted from `AppSettingsTests.swift:107-116` (`modelLastCheckedDateNilClearsKey`):

```swift
@Test @MainActor func appearancePreferenceMissingKeyFallsBackToSystem() {
    Self.clearV12Keys()
    defer { Self.clearV12Keys() }
    // Simulate fresh-from-Phase-20 install: no "appearancePreference" in UserDefaults
    #expect(UserDefaults.standard.object(forKey: "appearancePreference") == nil)
    let s = AppSettings()
    #expect(s.appearancePreference == .system)
}
```

**Notes for planner:**
- Phase 25 D-04 Claude's Discretion explicitly recommends extending this file rather than creating `AppearancePreferenceTests.swift`. The existing `@Suite(.serialized)` already covers UD-mutation safety; the existing `@MainActor` already covers `AppSettings`-isolation.
- Three new `@Test` methods minimum: default, round-trip-light, round-trip-dark (plus optional missing-key explicit). Combined with REQ-21.6 = 3-4 `@Test` total here.
- The `AppearancePreference` enum itself (REQ-21.1 structural half) is asserted at compile-time by `@testable import PSTranscribe` resolving + the `.system / .light / .dark` literal references in the test bodies. No separate "enum cases exist" test needed.

---

#### `PreferredColorSchemeGrepGateTests.swift` (new file -- shared between Plan 25-01 and 25-02)

**Reqs covered (Plan 25-01 portion):** REQ-21.2a (three Scene-root call-site grep), REQ-21.3a (SettingsView Picker grep), REQ-21.4 (relaxed location/source grep -- single-source-of-call-site invariant)
**Reqs covered (Plan 25-02 portion):** REQ-20.1 (zero-`preferredColorScheme(.light)` grep outside `#Preview`), REQ-20.3 (`extension Color` block deletion grep on `TranscriptView.swift`), REQ-20.4a (per-view hex-literal grep)
**Analog:** `WorkflowSecretsTests.swift` (Phase 24, NYQUIST-02) -- canonical source-grep test shape with cwd-relative file IO

**File header doc-comment pattern** (modeled on `WorkflowSecretsTests.swift:1-21`):

```swift
// PreferredColorSchemeGrepGateTests
// Phase 25 (NYQUIST-06 + NYQUIST-07) -- Phase 20 REQ-20.1/20.3/20.4a + Phase 21 REQ-21.2a/21.3a/21.4.
//
// Static source assertions on Swift source files under Sources/PSTranscribe/.
// Reads the committed files as Strings and verifies invariants:
//   - Phase 20 REQ-20.1: zero `.preferredColorScheme(` calls in any source file
//     OUTSIDE `#Preview { ... }` blocks, EXCEPT the three Phase-21 Scene-root
//     call-sites in PSTranscribeApp.swift (REQ-21.2a / REQ-21.4).
//   - Phase 20 REQ-20.3: `TranscriptView.swift` does not contain an
//     `extension Color { ... }` block (legacy palette deleted).
//   - Phase 20 REQ-20.4a: target views contain zero `Color(red: green: blue:)`
//     hex literals as foreground/background (palette is fully tokenized).
//   - Phase 21 REQ-21.2a: PSTranscribeApp.swift contains exactly three
//     `.preferredColorScheme(settings.appearancePreference.colorScheme)` call-sites
//     (WindowGroup root + Settings root + MenuBarExtra root, per Phase 21 D-05).
//   - Phase 21 REQ-21.3a: SettingsView.swift contains a `Section("Appearance")` +
//     `Picker(...selection: $settings.appearancePreference)` block.
//
// Working-directory assumption: `swift test` runs from `PSTranscribe/` (the
// SwiftPM package root). Source files live at `Sources/PSTranscribe/...`. The
// helper `readSource(_:)` includes a `try #require(!content.isEmpty)` smoke
// check so a wrong cwd fails fast with a clear message instead of silently
// passing absence assertions.

import Testing
import Foundation
```

**Suite shape -- pure file reads, no `.serialized` needed** (modeled on `WorkflowSecretsTests.swift:25-26`):

```swift
@Suite("PreferredColorSchemeGrepGateTests")
struct PreferredColorSchemeGrepGateTests {

    private func readSource(_ relativePath: String) throws -> String {
        // cwd at swift-test time is PSTranscribe/; source root is Sources/PSTranscribe/
        let url = URL(fileURLWithPath: "Sources/PSTranscribe/\(relativePath)")
        let content = try String(contentsOf: url, encoding: .utf8)
        try #require(!content.isEmpty,
                     "Read empty content from \(relativePath); is the test cwd PSTranscribe/?")
        return content
    }
```

**Three-call-site count pattern (REQ-21.2a + REQ-21.4)** -- this is the centerpiece of Plan 25-01's grep gate. Phase 21 D-06 locked "relaxed grep gate: location + source, not count", so the assertion is structural: assert the call-sites live in `PSTranscribeApp.swift` AND that they read from `settings.appearancePreference.colorScheme`. The exact count of 3 is currently true (lines 173, 195, 207) but the contract is "every call-site reads from settings" -- not "exactly 3 exist". Phase 25 follows D-06 and asserts on source/location, with a `>= 1` floor on count.

```swift
@Test func preferredColorSchemeOnlyAtAppRootReadingFromSettings() throws {
    let appSrc = try readSource("App/PSTranscribeApp.swift")
    // Strip #Preview blocks so they don't pollute the count
    let stripped = stripPreviewBlocks(appSrc)
    // Every preferredColorScheme call in PSTranscribeApp.swift (outside #Preview)
    // must read from settings.appearancePreference.colorScheme (REQ-21.4 source contract)
    let pattern = try NSRegularExpression(pattern: #"\.preferredColorScheme\((.+?)\)"#)
    let nsStripped = stripped as NSString
    let matches = pattern.matches(in: stripped, range: NSRange(location: 0, length: nsStripped.length))
    #expect(matches.count >= 1, "PSTranscribeApp.swift must contain at least one Scene-root .preferredColorScheme call")
    for m in matches {
        let arg = nsStripped.substring(with: m.range(at: 1))
        #expect(arg.contains("settings.appearancePreference.colorScheme"),
                "Every .preferredColorScheme call outside #Preview must read from AppSettings; got: \(arg)")
    }
}
```

**Forbidden-call-site pattern (REQ-20.1)** -- assert OTHER source files have zero `.preferredColorScheme(` outside `#Preview`. Phase 20 verified `ContentView.swift:251` (`.preferredColorScheme(.light)`) and `NotionTagSheet.swift:130` (`.preferredColorScheme(.dark)`) were deleted; this test is a refactor tripwire.

```swift
@Test func noPreferredColorSchemeOutsideAppRoot() throws {
    let surfaces = [
        "Views/ContentView.swift",
        "Views/NotionTagSheet.swift",
        "Views/SettingsView.swift",
        "Views/TranscriptView.swift",
        "Views/OnboardingView.swift",
        // ... full roster from Phase 20 SPEC Boundaries
    ]
    for path in surfaces {
        let stripped = stripPreviewBlocks(try readSource(path))
        #expect(!stripped.contains(".preferredColorScheme("),
                "\(path) must not call .preferredColorScheme outside #Preview (Phase 20 REQ-20.1)")
    }
}
```

**`extension Color` deletion pattern (REQ-20.3)** -- modeled on `WorkflowSecretsTests.swift:37-44` substring-absence shape:

```swift
@Test func transcriptViewDoesNotDefineExtensionColor() throws {
    let src = try readSource("Views/TranscriptView.swift")
    #expect(!src.contains("extension Color"),
            "TranscriptView.swift must not define `extension Color` (Phase 20 REQ-20.3 -- legacy palette moved to DesignTokens.swift)")
}
```

**SettingsView Picker existence pattern (REQ-21.3a)** -- substring assertion shape:

```swift
@Test func settingsViewContainsAppearancePicker() throws {
    let src = try readSource("Views/SettingsView.swift")
    #expect(src.contains(#"Section("Appearance")"#))
    #expect(src.contains("Picker"))
    #expect(src.contains("selection: $settings.appearancePreference"))
}
```

**`#Preview`-stripping helper** -- the one piece of mechanism that does NOT have an in-house precedent; Phase 25 introduces it. Bias: write it as a tiny private helper in this same file rather than as a new fixture.

```swift
/// Strips `#Preview { ... }` blocks (and `#Preview("name") { ... }` variants)
/// from source so that grep gates only inspect production code paths.
/// Naive but sufficient: matches the macro literal + balanced-brace block.
private func stripPreviewBlocks(_ source: String) -> String {
    // ... (planner picks: regex-with-balanced-braces OR multi-pass scanner)
}
```

**Notes for planner:**
- The `stripPreviewBlocks` helper is the only net-new mechanism in this file. Document it clearly in a doc-comment so a future maintainer knows it's a Phase-25-introduced utility (parallel to Phase 24's `readWorkflow` / `readSource` helpers).
- All `@Test` methods in this file are pure-function source reads -- NO `.serialized`, NO `@MainActor`. Default parallelism is correct.
- The shared file spans both plans (D-04). Plan 25-01 creates the file with REQ-21.2a/21.3a/21.4 tests; Plan 25-02 extends with REQ-20.1/20.3/20.4a tests. Same Git-history shape as Phase 24's `WorkflowSecretsTests.swift` (created in 24-05, extended/cited in 24-01).
- Per-view hex-literal grep (REQ-20.4a) follows the same shape as `noPreferredColorSchemeOutsideAppRoot` -- iterate over surfaces, assert `Color(red:` substring absence in each non-DesignTokens file.

---

### Plan 25-02: `20-VALIDATION.md` + DesignTokens adaptive palette tests (lands second, slightly fewer tests but more files involved)

#### `DesignTokensAdaptivePaletteTests.swift` (new)

**Reqs covered:** REQ-20.2 (17 Chronicle tokens defined as `Color(light:dark:)`)
**Analog:** `ObsidianURLTests.swift` (pure-function I/O assertion shape) -- but the NSColor bridging technique itself is net-new in the test target; flagged in §"No Analog Found"

**Imports + Suite header pattern** (lifted from any pure-function test, modeled on `ObsidianURLTests.swift`):

```swift
// DesignTokensAdaptivePaletteTests
// Phase 25 (NYQUIST-06) -- Phase 20 REQ-20.2.
//
// Asserts that the 17 Chronicle tokens in DesignTokens.swift resolve to
// DIFFERENT RGB triples under .aqua vs .darkAqua appearance, proving each
// token is defined as Color(light:dark:) (not a single-hex literal).
//
// Technique: bridge SwiftUI.Color -> NSColor via `NSColor(_ color: Color)`,
// then resolve under explicit appearances via `NSAppearance(named:)?.performAsCurrentDrawingAppearance`,
// converting to sRGB and comparing redComponent/greenComponent/blueComponent.
// This is the same dynamic-NSColor mechanism DesignTokens.swift uses internally
// (see DesignTokens.swift:11-21) -- the test exercises the same code path.

import Testing
import Foundation
import AppKit
import SwiftUI
@testable import PSTranscribe

@Suite("DesignTokensAdaptivePaletteTests", .serialized)  // .serialized: NSAppearance.current mutation
struct DesignTokensAdaptivePaletteTests {
```

**Core pattern -- resolve a Color under both appearances and assert variance** (net-new shape; bridging is documented in `DesignTokens.swift:11-21`):

```swift
private func rgb(of color: Color, under appearanceName: NSAppearance.Name) -> (r: CGFloat, g: CGFloat, b: CGFloat)? {
    guard let appearance = NSAppearance(named: appearanceName) else { return nil }
    var result: (CGFloat, CGFloat, CGFloat)?
    appearance.performAsCurrentDrawingAppearance {
        let nsColor = NSColor(color)
        guard let srgb = nsColor.usingColorSpace(.sRGB) else { return }
        result = (srgb.redComponent, srgb.greenComponent, srgb.blueComponent)
    }
    return result
}

@Test func paperTokenHasDistinctLightAndDarkVariants() throws {
    let light = try #require(rgb(of: Color.paper, under: .aqua))
    let dark = try #require(rgb(of: Color.paper, under: .darkAqua))
    // Light: #FAFAF7 -- (250/255, 250/255, 247/255)
    // Dark:  #1A1818 -- (26/255, 24/255, 24/255)
    #expect(abs(light.r - 250.0/255.0) < 0.005)
    #expect(abs(dark.r - 26.0/255.0) < 0.005)
    #expect(light.r != dark.r)  // catches "both variants accidentally same hex"
}
```

**Tokenized-iteration pattern** (one assertion per token; alternative to per-token `@Test` methods):

```swift
@Test func allChronicleTokensHaveDistinctLightDarkVariants() throws {
    let tokens: [(name: String, color: Color)] = [
        ("paper", .paper), ("paperWarm", .paperWarm), ("paperSoft", .paperSoft),
        ("rule", .rule), ("ruleStrong", .ruleStrong),
        ("ink", .ink), ("inkMuted", .inkMuted), ("inkFaint", .inkFaint), ("inkGhost", .inkGhost),
        ("accentInk", .accentInk), ("accentSoft", .accentSoft), ("accentTint", .accentTint),
        ("spk2Bg", .spk2Bg), ("spk2Fg", .spk2Fg), ("spk2Rail", .spk2Rail),
        ("recRed", .recRed), ("liveGreen", .liveGreen),
        // 17 total per Phase 20 REQ-20.2
    ]
    for (name, color) in tokens {
        let light = try #require(rgb(of: color, under: .aqua), "\(name): light variant unresolvable")
        let dark = try #require(rgb(of: color, under: .darkAqua), "\(name): dark variant unresolvable")
        #expect(light != dark, "\(name): light and dark variants must differ (REQ-20.2)")
    }
}
```

**Notes for planner:**
- `.serialized` is mandatory here -- `performAsCurrentDrawingAppearance` mutates `NSAppearance.current`, which is process-global. Two parallel tests setting different appearances would race.
- `youBg` / `youFg` (defined as `Color.ink` / `Color.paper` -- see `DesignTokens.swift:103-104`) auto-flip because the underlying tokens are adaptive; tests on these are redundant with ink/paper tests. Planner picks: include for completeness (17/17) or omit (15/17 + transitive proof). Bias: include for the "17 Chronicle tokens" SPEC contract.
- The `rgb(of:under:)` helper is a *net-new in-house pattern*. Document its rationale in a doc-comment: it exercises the same `NSAppearance(name: nil) { appearance in ... }` mechanism that `DesignTokens.swift:14-18` uses internally.
- Phase 25 D-04 Claude's Discretion: bias toward NSColor bridging over SwiftUI environment-trait rendering. NSColor bridging is simpler, doesn't require a host view, and matches the existing `Color(light:dark:)` extension style.

---

### `20-VALIDATION.md` (new from scratch -- Plan 25-02 owns)

**Reqs covered (full SPEC roster):** REQ-20.1, REQ-20.2, REQ-20.3, REQ-20.4 (split a/b per D-02), REQ-20.5 (WITHDRAWN), REQ-20.6 (WITHDRAWN)
**Analog:** `.planning/milestones/v1.0-phases/01-rebrand/01-VALIDATION.md` post-2026-05-05 audit shape (Phase 24 NYQUIST-01)

**Frontmatter pattern** (modeled on `01-VALIDATION.md:1-9`):

```yaml
---
phase: 20
slug: dark-mode-parity
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-07
last_audited: 2026-05-07
---
```

**Note:** Phase 25's VALIDATION.md files are CREATED 2026-05-07 (no draft existed). `created` and `last_audited` are the same date. Phase 24's edits were `created: 2026-04-XX` + `last_audited: 2026-05-05` because drafts existed. Mirror Phase 24's *shape*, not its *dates*.

**Per-Task Verification Map row pattern -- UNIT row** (modeled on `01-VALIDATION.md:42-48`):

```markdown
| 25-02-01 | 20 | 1 | REQ-20.1 | unit | `cd PSTranscribe && swift test --filter PreferredColorSchemeGrepGateTests/noPreferredColorSchemeOutsideAppRoot` | green |
| 25-02-02 | 20 | 1 | REQ-20.2 | unit | `cd PSTranscribe && swift test --filter DesignTokensAdaptivePaletteTests/allChronicleTokensHaveDistinctLightDarkVariants` | green |
| 25-02-03 | 20 | 1 | REQ-20.3 | unit | `cd PSTranscribe && swift test --filter PreferredColorSchemeGrepGateTests/transcriptViewDoesNotDefineExtensionColor` | green |
| 25-02-04 | 20 | 1 | REQ-20.4a | unit | `cd PSTranscribe && swift test --filter PreferredColorSchemeGrepGateTests/perViewHexLiteralGrep` | green | Structural half (D-02 split): per-view `Color(red:` literal absence |
```

**WITHDRAWN row pattern (D-02: PARTIAL `a/b` split)** -- modeled on `01-VALIDATION.md:49`:

```markdown
| 25-02-05 | 20 | 1 | REQ-20.4b | WITHDRAWN | n/a -- WITHDRAWN | withdrawn | Visual half (D-02 split): runtime appearance-toggle re-renders surfaces. Manual UAT covers; no automated harness for transition states (Phase 25 D-01 cite-only). Source: 20-VERIFICATION.md Row groups A-F. |
| 25-02-06 | 20 | 1 | REQ-20.5 | WITHDRAWN | n/a -- WITHDRAWN | withdrawn | Light-mode pixel stability gate. Source-level byte-equality already proven via Plan 20-01/02 SUMMARY hex transcripts; visual attestation in 20-VERIFICATION.md Row group D. No CI-runnable visual diff in scope (Phase 25 D-01). Source: 20-01-SUMMARY.md + 20-02-SUMMARY.md + 20-VERIFICATION.md. |
| 25-02-07 | 20 | 1 | REQ-20.6 | WITHDRAWN | n/a -- WITHDRAWN | withdrawn | DictationHUD vibrancy adapts via NSPanel `.hudWindow` material; system-controlled, not a SwiftUI invariant. Visual attestation in 20-VERIFICATION.md Row group F. Source: 20-VERIFICATION.md. |
```

**Validation Audit section pattern** (modeled on `01-VALIDATION.md:110-131` -- 2026-05-05 audit block):

```markdown
## Validation Audit 2026-05-07 (Phase 25 -- NYQUIST-06)

| Metric | Count |
|--------|-------|
| Gaps found | 0 (no MISSING test coverage; Phase 20 shipped with manual UAT only -- Phase 25 backfills automated coverage for the structural half of every REQ) |
| Resolved | 4 (REQ-20.1 grep gate; REQ-20.2 17-token light/dark variance; REQ-20.3 extension-Color deletion; REQ-20.4a per-view hex-literal grep) |
| Withdrawn | 4 (REQ-20.4b visual half + REQ-20.5 + REQ-20.6 per D-01 cite-only + D-02 PARTIAL split) |
| Escalated | 0 |
| Document updates | New 20-VALIDATION.md created at `status: approved` / `nyquist_compliant: true`; created 2026-05-07. |

### Audit Method

- Created `PSTranscribe/Tests/PSTranscribeTests/PreferredColorSchemeGrepGateTests.swift` ... [list `@Test` methods]
- Created `PSTranscribe/Tests/PSTranscribeTests/DesignTokensAdaptivePaletteTests.swift` ... [list `@Test` methods]
- Ran `cd PSTranscribe && swift test --filter PreferredColorSchemeGrepGateTests` -- exits 0
- Ran `cd PSTranscribe && swift test --filter DesignTokensAdaptivePaletteTests` -- exits 0
- Ran full `cd PSTranscribe && swift test` -- exits 0

### Notes

- D-01 cite-only posture: Phase 23's 15 snapshot baselines (`PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/`) prove static palette correctness across light/dark/system but are NOT extended in Phase 25. WITHDRAWN rows for REQ-20.5/20.6 cite `20-VERIFICATION.md` per D-02.
- D-02 PARTIAL `a/b` split: REQ-20.4 cleaved into `20.4a` (testable structural half: per-view hex-literal grep) and `20.4b` (WITHDRAWN visual half: runtime appearance-toggle re-render).
```

**Validation Sign-Off pattern** (modeled on `01-VALIDATION.md:67-75`):

```markdown
- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (no missing references -- existing infra suffices)
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-07 (Phase 25 NYQUIST-06 -- Swift Testing-backed)
```

---

### `21-VALIDATION.md` (new from scratch -- Plan 25-01 owns)

**Reqs covered (full SPEC roster):** REQ-21.1, REQ-21.2 (split a/b per D-02), REQ-21.3 (split a/b per D-02), REQ-21.4, REQ-21.5 (WITHDRAWN), REQ-21.6
**Analog:** `01-VALIDATION.md` post-2026-05-05 audit shape

**Frontmatter:** Same as `20-VALIDATION.md` (different `phase` / `slug` values).

**Per-Task Verification Map -- 5 UNIT + 3 WITHDRAWN rows:**

```markdown
| 25-01-01 | 21 | 1 | REQ-21.1 | unit | `cd PSTranscribe && swift test --filter AppSettingsTests/roundTrip_appearancePreferenceLight` | green |
| 25-01-02 | 21 | 1 | REQ-21.2a | unit | `cd PSTranscribe && swift test --filter PreferredColorSchemeGrepGateTests/preferredColorSchemeOnlyAtAppRootReadingFromSettings` | green | Structural half (D-02 split): app-root call-site grep + source contract |
| 25-01-03 | 21 | 1 | REQ-21.2b | WITHDRAWN | n/a -- WITHDRAWN | withdrawn | Visual half (D-02 split): runtime override re-renders all 10 surfaces without app restart. Manual UAT covers. Source: 21-VERIFICATION.md Manual UAT Scenarios A-H + 21-HUMAN-UAT.md. |
| 25-01-04 | 21 | 1 | REQ-21.3a | unit | `cd PSTranscribe && swift test --filter PreferredColorSchemeGrepGateTests/settingsViewContainsAppearancePicker` | green | Structural half (D-02 split): SettingsView Picker existence + binding source |
| 25-01-05 | 21 | 1 | REQ-21.3b | WITHDRAWN | n/a -- WITHDRAWN | withdrawn | Visual half (D-02 split): user changes selection in Settings, every visible window re-renders immediately. Manual UAT covers. Source: 21-VERIFICATION.md. |
| 25-01-06 | 21 | 1 | REQ-21.4 | unit | `cd PSTranscribe && swift test --filter PreferredColorSchemeGrepGateTests/preferredColorSchemeOnlyAtAppRootReadingFromSettings` | green | Same `@Test` as REQ-21.2a -- one assertion satisfies both reqs (location AND source contract per D-06) |
| 25-01-07 | 21 | 1 | REQ-21.5 | WITHDRAWN | n/a -- WITHDRAWN | withdrawn | Default-state pixel stability with preference = .system. Pure visual UAT against post-Phase-20 baseline. Source: 21-VERIFICATION.md + 21-HUMAN-UAT.md. |
| 25-01-08 | 21 | 1 | REQ-21.6 | unit | `cd PSTranscribe && swift test --filter AppSettingsTests/appearancePreferenceMissingKeyFallsBackToSystem` | green | Migration: missing UD key falls back to .system |
```

**Out-of-scope section -- D-03 cross-ref to Phase 26** (net-new section, no in-house analog -- Phase 25 establishes it):

```markdown
## Out of scope: Post-fix titlebar bridge (CR-01)

The `applyChronicleTitlebar(_:)` and `observeChronicleTitlebar(controller:settings:)` helpers in `PSTranscribeApp.swift` (lines ~64, 275-340 -- introduced in commits `197043b..ce79965` after `21-SPEC.md` was locked) are scope extensions outside the original Phase 21 SPEC. The bridge is verified at the code level by `21-VERIFICATION.md`'s re-verification block (NSColor.labelColor dynamic, `window.appearance` set, `bestMatch(from:)` gate). Visual UAT for titlebar Light / Dark / System / unfocused-window scenarios lives in **Phase 26's `26-UAT.md` (QA-06, QA-07, QA-08, QA-09)** -- produced when Phase 26 ships.

Phase 25 deliberately does not encode the bridge audit as `@Test`s: the bridge code is tightly tied to AppKit invariants that don't regress silently, and the re-verification grep audit in `21-VERIFICATION.md` already certifies the code-level invariants (per Phase 25 D-03).
```

**Notes for planner:**
- The cross-ref points to a file (`26-UAT.md`) that does not yet exist. Format the cross-ref as a relative path with the phrase "produced when Phase 26 ships" so a future reader who lands here pre-Phase-26 isn't confused (per CONTEXT.md `<code_context>` guidance).
- Both REQ-21.2a and REQ-21.4 cite the SAME `@Test` method (`preferredColorSchemeOnlyAtAppRootReadingFromSettings`). This is intentional per Phase 21 D-06 ("relaxed grep gate: location + source, not count") -- one assertion proves both contracts.

---

## Shared Patterns

### `readSource(_:)` cwd-relative source-file helper

**Source:** `WorkflowSecretsTests.swift:28-35` (canonical) and `RebrandInfoPlistTests.swift:20-26` (Info.plist variant)
**Apply to:** `PreferredColorSchemeGrepGateTests.swift` (REQ-20.1, REQ-20.3, REQ-20.4a, REQ-21.2a, REQ-21.3a, REQ-21.4)

```swift
private func readSource(_ relativePath: String) throws -> String {
    let url = URL(fileURLWithPath: "Sources/PSTranscribe/\(relativePath)")
    let content = try String(contentsOf: url, encoding: .utf8)
    try #require(!content.isEmpty,
                 "Read empty content from \(relativePath); is the test cwd PSTranscribe/?")
    return content
}
```

**Notes:**
- The `try #require(!content.isEmpty)` smoke check is non-negotiable -- it converts a wrong-cwd silent pass into a fast loud failure (Phase 24 D-04 Claude's Discretion locked this idiom for source-grep tests).
- `swift test` cwd is `PSTranscribe/`. Source files live at `Sources/PSTranscribe/...`. Workflow files live at `../.github/workflows/...` (Phase 24's `WorkflowSecretsTests.swift` uses `../`-prefixed paths).

### `clearV12Keys()` UserDefaults cleanup helper

**Source:** `AppSettingsTests.swift:12-22` (canonical -- already exists)
**Apply to:** `AppSettingsTests.swift` extension (Plan 25-01) -- ADD `"appearancePreference"` to the `v12Keys` array

```swift
// Existing (Phase 18.1+):
private static let v12Keys = [
    "dictationHotkeyMode",
    "clipboardRestoreDelay",
    "installedModelVersion",
    "modelLastCheckedDate",
    "modelAutoUpdateEnabled",
]

// After Phase 25 Plan 25-01:
private static let v12Keys = [
    "dictationHotkeyMode",
    "clipboardRestoreDelay",
    "installedModelVersion",
    "modelLastCheckedDate",
    "modelAutoUpdateEnabled",
    "appearancePreference",  // <- Phase 25 NYQUIST-07
]
```

### `@Suite(.serialized)` for shared-state mutation

**Source:** `AppSettingsTests.swift:5` (UserDefaults), Phase 24 `TranscriptLoggerSecurityTests.swift` (FS via tempDir), `DictationLoggerTests.swift:5` (FS + actor)
**Apply to:**
- `AppSettingsTests.swift` extension -- yes (UserDefaults.standard, already serialized)
- `DesignTokensAdaptivePaletteTests.swift` -- **YES** (NSAppearance.current mutation via `performAsCurrentDrawingAppearance`)
- `PreferredColorSchemeGrepGateTests.swift` -- **NO** (pure file reads, no shared state)

### `@MainActor` annotation for `AppSettings`-touching tests

**Source:** `AppSettingsTests.swift:28-135` -- every `@Test` carries `@Test @MainActor`
**Apply to:**
- `AppSettingsTests.swift` extension (REQ-21.1, REQ-21.6) -- **YES** (instantiates `AppSettings`)
- `DesignTokensAdaptivePaletteTests.swift` -- **NO** (does not instantiate `AppSettings`; only reads `Color` static members + AppKit)
- `PreferredColorSchemeGrepGateTests.swift` -- **NO** (pure file reads)

### `try #require(...)` for "must succeed before further assertion"

**Source:** `RebrandInfoPlistTests.swift:23, 25, 30` and `ObsidianURLTests.swift:16` (canonical)
**Apply to:**
- `DesignTokensAdaptivePaletteTests.swift` -- yes, on `rgb(of:under:)?` results before component comparison
- `PreferredColorSchemeGrepGateTests.swift` -- yes, on `readSource` smoke check (`try #require(!content.isEmpty)`)

```swift
let light = try #require(rgb(of: Color.paper, under: .aqua))
#expect(abs(light.r - 250.0/255.0) < 0.005)
```

### Per-Task Verification Map row format with Test Type column + WITHDRAWN

**Source:** `01-VALIDATION.md:40-49` (canonical post-Phase-24 shape)
**Apply to:** Both `20-VALIDATION.md` and `21-VALIDATION.md`

Column shape: `| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status | Notes |`

- UNIT rows use `Test Type: unit` and a fully-formed `cd PSTranscribe && swift test --filter ...` command
- WITHDRAWN rows use `Test Type: WITHDRAWN`, `Automated Command: n/a -- WITHDRAWN`, `Status: withdrawn`, and a `Notes` cell ending with `Source: NN-VERIFICATION.md` (per Phase 24 D-03 + Phase 25 D-02)

### PARTIAL `a/b` row split (D-02, net-new in Phase 25)

**Source:** None -- Phase 25 establishes this convention (Phase 24 had no PARTIAL reqs)
**Apply to:** REQ-20.4 (split into 20.4a UNIT + 20.4b WITHDRAWN), REQ-21.2 (split into 21.2a UNIT + 21.2b WITHDRAWN), REQ-21.3 (split into 21.3a UNIT + 21.3b WITHDRAWN)

- Both halves keep the original REQ-ID prefix with `a` (testable structural) or `b` (WITHDRAWN visual) suffix
- Adjacent rows in the same Per-Task Verification Map preserve SPEC linkage
- The `b` row's `Notes` cell explains what visual contract is deferred and points at `*-VERIFICATION.md`

---

## No Analog Found

Three patterns in Phase 25 establish or extend in-house conventions. Each warrants a header doc-comment in its test file explaining the rationale.

| File / Pattern | Why No Analog | Recommendation |
|----------------|---------------|----------------|
| `DesignTokensAdaptivePaletteTests.swift` -- NSColor bridging via `NSAppearance.performAsCurrentDrawingAppearance` | The test target has never resolved a SwiftUI `Color(light:dark:)` to RGB components under explicit appearances. Existing `Color`-touching tests (none, really -- DesignTokens has no test coverage today) would have used compile-time identity. The technique itself is documented in `DesignTokens.swift:14-18` (the production `Color(light:dark:)` extension uses `NSColor(name: nil) { appearance in ... }`); the test exercises the same closure-based dynamic resolution path through `performAsCurrentDrawingAppearance`. | Header doc-comment explaining that the technique mirrors `DesignTokens.swift:11-21` and that `.serialized` is mandatory because `NSAppearance.current` is process-global. Use `try #require(rgb(of:under:))` to fail fast if appearance resolution fails (e.g., on a future macOS that drops `.aqua`). |
| `PreferredColorSchemeGrepGateTests.swift` -- `stripPreviewBlocks(_:)` helper | The grep gate must NOT count `#Preview { ... .preferredColorScheme(...) }` calls (Phase 20 SPEC explicitly excludes preview blocks from the grep gate). No existing test in the target strips macro blocks before string-matching. | Header doc-comment explaining the `#Preview`-stripping rationale + a brief note on the implementation choice (regex with balanced-brace handling vs. multi-pass scanner). Bias: a small private regex-based scanner sufficient for the macro-literal `#Preview` form is more readable than a complex regex; document the limitation (no nested `#Preview` support, which the codebase doesn't use anyway). |
| `21-VALIDATION.md` "Out of scope: Post-fix titlebar bridge (CR-01)" section + cross-ref to Phase 26's `26-UAT.md` | Phase 24's VALIDATION.md files had no cross-phase scope extensions because v1.0 phases were already closed. Phase 21 added `applyChronicleTitlebar` / `observeChronicleTitlebar` AFTER its SPEC was locked; the audit trail for that scope extension lives outside `21-VALIDATION.md`'s primary table. | Insert a dedicated `## Out of scope: ...` section after the Per-Task Verification Map. Format the cross-ref as a relative path with "(produced when Phase 26 ships)" so a pre-Phase-26 reader isn't confused. Phase 25 establishes this section shape; future phases with post-SPEC scope extensions can copy it. |
| PARTIAL `a/b` row split convention | Phase 24 had no PARTIAL reqs (v1.0 reqs cleaved on pure-function vs runtime axis, not compound contracts). Phase 25 introduces the split. | The `a` (testable structural) / `b` (WITHDRAWN visual) suffix convention is a Phase-25 introduction. Document briefly in the `## Validation Audit 2026-05-07` Notes subsection of both VALIDATION.md files so future auditors understand the SPEC-traceability rationale. |

---

## Cross-Reference Citations (existing tests, no new code)

Phase 25 has no full-test cross-references like Phase 24 did (no existing test covers AppearancePreference or DesignTokens variance). The closest "cite-don't-duplicate" use is:

| Existing Test File | Reqs It Could Cite | Phase 25 Plan(s) That Could Cite It |
|--------------------|--------------------|--------------------------------------|
| `WorkflowSecretsTests.swift` | None directly (pattern reference only) | Both plans -- as the canonical source-grep precedent |
| `AppSettingsTests.swift` (pre-Phase-25 rows) | None directly (pattern reference only) | Plan 25-01 -- as the canonical UD round-trip + `.serialized` + `@MainActor` precedent |
| `VisualRegressionTests.swift` + `__Snapshots__/` | None testable; cited in WITHDRAWN rows | Both plans -- per Phase 25 D-01 cite-only posture, the 15 baselines back the WITHDRAWN reasons for REQ-20.5/20.6/20.4b/21.2b/21.3b/21.5 (alongside `*-VERIFICATION.md`) |

---

## Plan-Level Pattern Summary

Per Phase 25 D-04 (smallest-first plan ordering, mirrors Phase 24 D-04):

| Plan | VALIDATION.md Audited | New / Extended Test Files | Test Count Estimate |
|------|----------------------|---------------------------|---------------------|
| 25-01 | `21-VALIDATION.md` (created) | `AppSettingsTests.swift` (extend with 3-4 `@Test`); `PreferredColorSchemeGrepGateTests.swift` (create with 3 `@Test`) | ~6-7 `@Test` |
| 25-02 | `20-VALIDATION.md` (created) | `DesignTokensAdaptivePaletteTests.swift` (create with 1-2 `@Test`); `PreferredColorSchemeGrepGateTests.swift` (extend with 3 `@Test`) | ~4-5 `@Test` |

**Note on file creation order:** `PreferredColorSchemeGrepGateTests.swift` is created in Plan 25-01 (smallest first) with REQ-21.2a / REQ-21.3a / REQ-21.4 tests, and EXTENDED in Plan 25-02 with REQ-20.1 / REQ-20.3 / REQ-20.4a tests. Mirrors Phase 24's "skeleton-then-extend" convention for files spanning multiple plans (Phase 24 used the same shape for `TranscriptLoggerSecurityTests.swift` and `ErrorPathLoggingTests.swift`). Net effect: each plan ships an atomic green CI run before the next plan begins.

---

## Metadata

**Analog search scope:**
- `PSTranscribe/Tests/PSTranscribeTests/` (flat layout -- 30+ files including Phase 24 additions)
- `PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift`
- `PSTranscribe/Sources/PSTranscribe/Design/DesignTokens.swift`
- `PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift`
- `PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift`
- `PSTranscribe/Sources/PSTranscribe/Views/TranscriptView.swift` (verified `extension Color` deletion)
- `.planning/milestones/v1.0-phases/01-rebrand/01-VALIDATION.md` (canonical post-Phase-24 shape)
- `.planning/phases/24-nyquist-sweep-v1-0/24-PATTERNS.md` (Phase 24 playbook -- inherited wholesale)
- `.planning/phases/24-nyquist-sweep-v1-0/24-RESEARCH.md` (Swift Testing infrastructure baseline)
- `.planning/milestones/v1.2-phases/20-dark-mode-parity/20-SPEC.md` (REQ roster, locked)
- `.planning/milestones/v1.2-phases/21-appearance-override/21-SPEC.md` (REQ roster, locked)

**Files scanned:** 11 (`AppSettingsTests.swift`, `WorkflowSecretsTests.swift`, `RebrandInfoPlistTests.swift`, `AppSettings.swift`, `DesignTokens.swift`, `PSTranscribeApp.swift`, `SettingsView.swift`, `TranscriptView.swift` (line count + grep), `01-VALIDATION.md`, `24-PATTERNS.md`, `24-RESEARCH.md`)

**Verified source-state at audit:**
- `PSTranscribeApp.swift:173, 195, 207` -- three `.preferredColorScheme(settings.appearancePreference.colorScheme)` call-sites confirmed (REQ-21.2a / REQ-21.4 grep target)
- `SettingsView.swift:30-37` -- `Section("Appearance")` + `Picker(... selection: $settings.appearancePreference)` confirmed (REQ-21.3a grep target)
- `AppSettings.swift:14-30` -- `AppearancePreference` enum confirmed; lines 119-121 property + `didSet`; lines 195-198 init-side decode + `?? .system` fallback (REQ-21.1 / REQ-21.6 source)
- `DesignTokens.swift:31-115` -- 17 Chronicle tokens via `Color(light:dark:)` confirmed (REQ-20.2 source); `extension Color` definitions at lines 11, 31, 125, 178 (light:dark: helper + Chronicle tokens + warning chips + legacy promoted)
- `TranscriptView.swift` -- 203 lines total, NO `extension Color` block (REQ-20.3 deletion confirmed)
- `grep -rn "preferredColorScheme(" PSTranscribe/Sources` -- 3 production call-sites in `PSTranscribeApp.swift` + 1 doc-comment in `AppSettings.swift:9` (the doc-comment is a comment, not a SwiftUI modifier, so the grep gate must distinguish via line context or use the `\.` regex prefix)

**Pattern extraction date:** 2026-05-07
