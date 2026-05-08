---
phase: 25-nyquist-sweep-v1-2
reviewed: 2026-05-08T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - PSTranscribe/Tests/PSTranscribeTests/AppSettingsTests.swift
  - PSTranscribe/Tests/PSTranscribeTests/DesignTokensAdaptivePaletteTests.swift
  - PSTranscribe/Tests/PSTranscribeTests/PreferredColorSchemeGrepGateTests.swift
findings:
  critical: 0
  warning: 5
  info: 4
  total: 9
status: issues_found
---

# Phase 25: Code Review Report

**Reviewed:** 2026-05-08
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

All three test files implement the Phase 25 backfill coverage for Phase 20 (dark-mode parity) and Phase 21 (appearance override) and the assertions are, by and large, correctly aimed at the requirements they cite. Test isolation is handled correctly for the parts that matter (`.serialized` on the suite that mutates `NSAppearance.current`; per-test `clearV12Keys` defer pairs).

No blockers. Findings cluster around: (1) brittle grep/regex patterns that work today but silently mis-classify tomorrow, (2) hardcoded rosters that under-cover the actual surface they claim to gate, and (3) a couple of duplicated/loose assertions worth tightening. None of these affect correctness of the current pass/fail signal — they affect the suite's ability to keep catching regressions after future refactors.

The most impactful items are WR-01 (regex breaks on nested parens), WR-02 (Wave 2 adaptive tokens not covered despite suite name implying broad coverage), and WR-03 (`stripPreviewBlocks` brace counter ignores braces inside string literals).

## Warnings

### WR-01: `preferredColorSchemeOnlyAtAppRootReadingFromSettings` regex fails on nested parens

**File:** `PSTranscribe/Tests/PSTranscribeTests/PreferredColorSchemeGrepGateTests.swift:113`

**Issue:** The pattern `\.preferredColorScheme\(([^)]+)\)` uses a negated character class `[^)]+` to capture the argument. Today every call site passes `settings.appearancePreference.colorScheme` (no parens), so the gate passes. But any future refactor that introduces a function call inside the argument, e.g.:

```swift
.preferredColorScheme(resolveScheme(settings))
```

…will cause the regex to capture only `resolveScheme(settings` (stopping at the first `)`), which:
1. Still contains `settings`, so the `arg.contains("settings.appearancePreference.colorScheme")` assertion will *fail* — but the failure message will misleadingly say the call doesn't read from AppSettings even though it might (via a helper).
2. More dangerously, a refactor like `.preferredColorScheme(scheme(from: settings.appearancePreference))` would capture `scheme(from: settings.appearancePreference` which DOES contain the magic substring and would *pass* the gate even though `colorScheme` is no longer being read directly.

The substring check `arg.contains("settings.appearancePreference.colorScheme")` is also vulnerable to drift in the property name (e.g., renaming `appearancePreference` → `appearanceOverride` would silently still match if the new name is a superstring of "appearancePreference" or if the test isn't updated).

**Fix:** Use balanced-paren matching (linear scan, same approach as `stripPreviewBlocks`) or assert structurally instead. A simpler hardening:

```swift
// Match .preferredColorScheme then balance parens to find the full arg.
// Fallback simple guard: assert .preferredColorScheme appears at all and that
// every line containing it ALSO contains "settings.appearancePreference"
// somewhere on that line or the next two lines.
for line in stripped.components(separatedBy: "\n") where line.contains(".preferredColorScheme(") {
    #expect(line.contains("settings.appearancePreference"),
            "every .preferredColorScheme call must read from AppSettings; got: \(line)")
}
```

### WR-02: `DesignTokensAdaptivePaletteTests` does not cover Wave 2 adaptive tokens

**File:** `PSTranscribe/Tests/PSTranscribeTests/DesignTokensAdaptivePaletteTests.swift:50-85`

**Issue:** The suite is named `DesignTokensAdaptivePaletteTests` and the file header asserts it covers "the 17 Chronicle tokens." But `DesignTokens.swift` defines additional adaptive `Color(light:dark:)` tokens in the Wave 2 block (lines 125-168): `warningTint`, `warningInk`, `errorTint`, `overlayDim`, `glassRule`. These tokens are real adaptive surface that the test name implies coverage for, and a regression where a future hand-edit collapses (e.g.) `warningTint` to a non-adaptive single literal would slip through this gate entirely.

The hardcoded 17-token roster is also brittle for the explicit reason called out in the file header: it requires manual update when new Chronicle tokens are added. The W-01-fix pattern in the grep-gate suite (directory walk + dynamic enumeration) was intentionally NOT applied here, but the Wave 2 tokens aren't gated by anything else either.

**Fix:** Either (a) extend the roster to include Wave 2 tokens with explicit comment about scope, or (b) loosen the test to enumerate `Color` static lets via a separate roster constant in the test target with an explicit "if you add a token, add it here" comment. Minimum:

```swift
// 17 Chronicle tokens (lines 31-115)
let chronicleTokens: [(name: String, color: Color)] = [ /* existing 17 */ ]

// 5 Wave 2 adaptive tokens (lines 125-168) -- Phase 20 D-09 license
let waveTwoTokens: [(name: String, color: Color)] = [
    ("warningTint", .warningTint),
    ("warningInk",  .warningInk),
    ("errorTint",   .errorTint),
    ("overlayDim",  .overlayDim),
    ("glassRule",   .glassRule),  // BOTH-SIDES-EQUAL by design (DesignTokens.swift:164-167)
]
```

Note: `glassRule` is intentionally `light: white@0.06 / dark: white@0.06` per the comment at DesignTokens.swift:164. If you include it, you'll need a per-token "expected adaptive?" flag; otherwise scope the test to the 4 tokens that ARE supposed to differ.

### WR-03: `stripPreviewBlocks` brace counter ignores braces in string literals

**File:** `PSTranscribe/Tests/PSTranscribeTests/PreferredColorSchemeGrepGateTests.swift:74-104`

**Issue:** The brace-balancing scan tracks `{` and `}` blindly without recognizing string-literal context. Today this is benign (no `#Preview` block contains a brace inside a string), but the moment someone writes:

```swift
#Preview {
    Text("\(viewModel.binding) updated")
        .onAppear { print("hi") }   // OK, balanced
}

#Preview {
    Text("braces in string: {}")   // depth jitters and could escape early
}
```

…the scan will either terminate the `#Preview` block prematurely (leaving the `}` from the literal as un-stripped production code) or escape the loop with mismatched depth. The downstream effect is that production-grep assertions either spuriously fail or, worse, spuriously *pass* by stripping real production code that follows the malformed match.

The file header acknowledges the regex-based approach is fragile and chose a linear scan, but the linear scan inherits the same blind spot for strings.

**Fix:** Either (a) document the limitation explicitly in the helper's docstring (currently only nesting is called out, not strings), or (b) add a minimal string-skip:

```swift
while j < source.endIndex {
    let c = source[j]
    if c == "\"" {
        // Skip string literal (handle escapes; not raw strings #"..."# -- if
        // those appear in #Preview, extend further).
        j = source.index(after: j)
        while j < source.endIndex && source[j] != "\"" {
            if source[j] == "\\" { j = source.index(after: j) }
            if j < source.endIndex { j = source.index(after: j) }
        }
    } else if c == "{" { depth += 1 }
    else if c == "}" {
        depth -= 1
        if depth == 0 { j = source.index(after: j); break }
    }
    if j < source.endIndex { j = source.index(after: j) }
}
```

Lower-effort alternative: add a guard test that verifies `stripPreviewBlocks` returns the empty string (or just whitespace) for a known-good `#Preview` block, and commit a sample with brace-in-string in the test fixture.

### WR-04: Date round-trip tolerance is too loose

**File:** `PSTranscribe/Tests/PSTranscribeTests/AppSettingsTests.swift:101-113`

**Issue:** `roundTrip_modelLastCheckedDate` writes a deterministic `Date(timeIntervalSince1970: 1_700_000_000)` and asserts the round-tripped value is within `< 1.0` second of the original. UserDefaults stores `Date` as `NSDate` with full precision — the round-trip should be exact, or at worst differ by sub-microsecond bit-pattern noise. A 1-second tolerance is large enough to mask a real bug (e.g., accidental `Int(timeIntervalSince1970)` truncation, or a future migration that re-encodes the date through a string formatter).

**Fix:** Tighten to bit-exact equality:

```swift
#expect(restored == known)
// or, defensively: < 0.001 (millisecond tolerance for floating-point edge cases)
```

### WR-05: `swiftFilesUnder("Views")` is non-recursive — silent under-coverage if subdirs are added

**File:** `PSTranscribe/Tests/PSTranscribeTests/PreferredColorSchemeGrepGateTests.swift:60-69`

**Issue:** `FileManager.contentsOfDirectory(atPath:)` returns only the top-level entries. Today `Sources/PSTranscribe/Views/` is flat (verified). But the file header explicitly says this is the W-01 fix to "automatically include future-added view files" — that promise breaks the moment someone adds `Views/Sheets/SomeSheet.swift`, and the gate falls silent without warning.

The test passes `try #require(!names.isEmpty, ...)` which only fires on a fully empty directory; a partially populated subtree still evaluates true.

**Fix:** Either (a) document the flat-directory assumption explicitly in the helper's docstring as a load-bearing constraint, or (b) walk recursively:

```swift
private func swiftFilesUnder(_ subdir: String) throws -> [String] {
    let root = "Sources/PSTranscribe/\(subdir)"
    guard let enumerator = FileManager.default.enumerator(atPath: root) else {
        throw ... // or #require fail
    }
    let relativePaths = enumerator
        .compactMap { $0 as? String }
        .filter { $0.hasSuffix(".swift") }
        .sorted()
    try #require(!relativePaths.isEmpty, "...")
    return relativePaths.map { "\(subdir)/\($0)" }
}
```

If you keep it flat by design, add a guard test:

```swift
@Test func viewsDirectoryIsFlat() throws {
    let entries = try FileManager.default.contentsOfDirectory(atPath: "Sources/PSTranscribe/Views")
    for name in entries {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: "Sources/PSTranscribe/Views/\(name)", isDirectory: &isDir)
        #expect(!isDir.boolValue, "Views/ must stay flat -- swiftFilesUnder is non-recursive (PreferredColorSchemeGrepGateTests:60)")
    }
}
```

## Info

### IN-01: `appearancePreferenceDefaultsToSystem` and `appearancePreferenceMissingKeyFallsBackToSystem` are near-duplicates

**File:** `PSTranscribe/Tests/PSTranscribeTests/AppSettingsTests.swift:64-69, 165-172`

**Issue:** Both tests:
1. Call `clearV12Keys()` (which removes `appearancePreference`).
2. Construct `AppSettings()`.
3. Assert `appearancePreference == .system`.

The "missing key" variant adds a defensive `#expect(UserDefaults.standard.object(forKey: "appearancePreference") == nil)` before construction, but `clearV12Keys` already guarantees that. Net unique signal: ~zero.

**Fix:** Delete one, or merge the explicit nil-check into the `Defaults.appearancePreferenceDefaultsToSystem` test as a pre-condition. Minor; not a correctness issue.

### IN-02: `clearV12Keys` is private but accessed via `AppSettingsTests.clearV12Keys()` from a nested struct

**File:** `PSTranscribe/Tests/PSTranscribeTests/AppSettingsTests.swift:21-23, 30-31, etc.`

**Issue:** `clearV12Keys()` is declared `fileprivate static`. The nested `Defaults` suite accesses it as `AppSettingsTests.clearV12Keys()`. Outer-scope tests access it as `Self.clearV12Keys()`. This works (fileprivate covers the file), but the inconsistency between `Self.` and `AppSettingsTests.` is mild noise. The `private static let v12Keys` array is even tighter than fileprivate, but the iteration happens inside `clearV12Keys` so it's reachable indirectly. Fine, just slightly inconsistent style.

**Fix:** Optional. Pick one form (`Self.clearV12Keys()` reads more clearly inside nested types when the outer name is long).

### IN-03: `legacyTokens.count == 11` self-check is tautological

**File:** `PSTranscribe/Tests/PSTranscribeTests/PreferredColorSchemeGrepGateTests.swift:202-203`

**Issue:** The assertion `#expect(legacyTokens.count == 11, "Phase 20 REQ-20.3 specifies 11 promoted legacy tokens; roster has \(legacyTokens.count)")` checks that a hardcoded array of 11 elements has 11 elements. This will never fail unless someone edits the array literal directly above the assertion — at which point the per-token `for name in legacyTokens` loop above (which iterates the same array) will detect any actual breakage. The roster-count check is documentation-as-assertion.

The same pattern appears at `DesignTokensAdaptivePaletteTests.swift:71` (`#expect(tokens.count == 17, ...)`). Same tautology.

**Fix:** Optional. If the intent is "guard against accidental future edits," keep it but note that it doesn't guard against the failure mode it appears to (an under-the-hood drift where the spec changes from 11 to 12 tokens). To gate against spec drift you'd need to read the spec file.

### IN-04: Magic-substring assertions on raw string equality (`"selection: $settings.appearancePreference"`)

**File:** `PSTranscribe/Tests/PSTranscribeTests/PreferredColorSchemeGrepGateTests.swift:147-148`

**Issue:** `src.contains("selection: $settings.appearancePreference")` will silently fail (i.e., the test fails) on any innocuous reformatting:
- Extra space: `selection:  $settings.appearancePreference`
- Multi-line break: `selection: $settings\n    .appearancePreference`
- `selection:$settings.appearancePreference` (no space, valid Swift)

This brittleness is acceptable for a "structural sanity gate" but the failure mode is high noise (tests turn red on whitespace edits to SettingsView). Three of the four `contains(...)` checks in `settingsViewContainsAppearancePicker` have this property.

**Fix:** Optional. If you keep the substring approach, normalize whitespace before checking:

```swift
let normalized = src.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
#expect(normalized.contains("selection: $settings.appearancePreference"))
```

Or accept the brittleness as the cost of a pure-grep gate — but document it in the test docstring so the next maintainer doesn't mistake a whitespace-induced failure for a real regression.

---

_Reviewed: 2026-05-08_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
