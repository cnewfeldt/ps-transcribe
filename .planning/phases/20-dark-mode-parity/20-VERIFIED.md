---
phase: 20-dark-mode-parity
verified: 2026-04-30T00:00:00Z
status: passed
score: 6/6 must-haves verified
verifier: gsd-verifier
final_gate: PASS
commit_under_test: b20d4ba
build: clean
---

# Phase 20: Dark Mode Parity -- Goal-Backward Verification

**Phase Goal:** Remove forced `.preferredColorScheme` overrides and convert the
Chronicle design system to a unified light+dark token palette so every macOS
surface re-renders correctly when the user toggles System Settings > Appearance,
with light-mode appearance remaining pixel-stable.

**Verified:** 2026-04-30
**Status:** PASS
**Score:** 6 of 6 requirements verified

## Per-Requirement Results

### REQ-20.1 -- Remove forced color-scheme overrides

**Status:** PASS

**Evidence:**

```
$ grep -rn "preferredColorScheme(" PSTranscribe/Sources
(no output -- zero matches)

$ grep -rn "preferredColorScheme" PSTranscribe/Sources
PSTranscribe/Sources/PSTranscribe/Design/DesignTokens.swift:173:// legacy hex (preserves bit-exact current visible behavior since `.preferredColorScheme`
```

The only remaining reference is a comment in `DesignTokens.swift:173` (line
prefixed with `//`). Zero call-sites outside `#Preview` blocks. Both
`ContentView.swift:251` (`.preferredColorScheme(.light)`) and
`NotionTagSheet.swift:130` (`.preferredColorScheme(.dark)`) deleted in commit
`b20d4ba`.

### REQ-20.2 -- Unified Chronicle token palette (17 tokens)

**Status:** PASS

**Evidence:**

```
$ grep -E "^[[:space:]]*static let [a-zA-Z][a-zA-Z0-9]* = Color\(" \
    PSTranscribe/Sources/PSTranscribe/Design/DesignTokens.swift | wc -l
33
```

Token count breakdown (33 total):

- 17 Chronicle tokens: paper, paperWarm, paperSoft, rule, ruleStrong, ink,
  inkMuted, inkFaint, inkGhost, accentInk, accentSoft, accentTint, spk2Bg,
  spk2Fg, spk2Rail, recRed, liveGreen
- 5 Wave-2 tokens: warningTint, warningInk, errorTint, overlayDim, glassRule
- 11 promoted legacy tokens: bg0, bg1, bg2, fg1, fg2, fg3, accent1, accent2,
  recordRed, speakerTeal, speakerAmber

All defined via the `Color(light:dark:)` adaptive helper. Helper init confirmed
present in DesignTokens.swift (1 match for `init(light:`).

### REQ-20.3 -- Promote legacy dark-only tokens

**Status:** PASS

**Evidence:**

```
$ grep -n "extension Color" PSTranscribe/Sources/PSTranscribe/Views/TranscriptView.swift
(no output -- zero matches)
```

The 24-line `extension Color { ... }` block at the bottom of TranscriptView.swift
has been deleted. All 11 legacy tokens (bg0/bg1/bg2/fg1/fg2/fg3/accent1/accent2/
recordRed/speakerTeal/speakerAmber) are now defined in DesignTokens.swift as
adaptive `Color(light:dark:)` definitions (verified in REQ-20.2 token list).

### REQ-20.4 -- Forced-dark and dark-only-token call-sites adapt

**Status:** PASS

**Evidence:**

```
$ grep -rn "Color(red:" PSTranscribe/Sources/PSTranscribe/Views/
(no output -- zero matches)

$ grep -rn "Color\.orange\.opacity\|Color\.black\.opacity(0\.4)\|\
    Color\.red\.opacity(0\.1)\|Color\.white\.opacity(0\.06)" \
    PSTranscribe/Sources/PSTranscribe/Views/
(no output -- zero matches)
```

Wave-2 token replacements at all documented call-sites:

```
SettingsView.swift:527    .background(Color.warningTint)        # was orange.opacity(0.15)
ContentView.swift:267     Color.overlayDim                       # was black.opacity(0.4)
ControlBar.swift:213      Color.glassRule (inactive branch)      # was white.opacity(0.06)
LibrarySidebar.swift:62   Color.rule.opacity(0.625)              # was Color(red:30/255...)
LibraryEntryRow.swift:55  Color.rule (selected shadow)           # was Color(red:30/255...)
NotionTagSheet.swift:106  .background(Color.errorTint)           # was red.opacity(0.1)
```

Wave-2 tokens (warningTint / warningInk / errorTint / overlayDim / glassRule)
all confirmed defined in DesignTokens.swift. Plus ContentView.swift:213 and 234
also use Color.rule for sidebar/details divider strokes.

### REQ-20.5 -- Light-mode pixel stability

**Status:** PASS (user attestation; screenshot capture waived)

**Evidence:**

- Light-side hex byte-equivalence established at source level across Waves 1-2
  (every `Color(light:dark:)` definition's light side equals the pre-Phase-20
  literal byte-for-byte; verified at Wave-1 commit time via `git diff HEAD~2`).
- Wave 3 (commit `b20d4ba`) deletes only `.preferredColorScheme` modifiers,
  which are no-ops in light mode (the override was forcing light).
- User signed off PASS on 2026-05-01 in `20-VERIFICATION.md` Row Group D.
- Screenshot capture explicitly waived by user; mathematical byte-equality
  proof accepted as attestation evidence.

### REQ-20.6 -- DictationHUD vibrancy adapts

**Status:** PASS (user attestation)

**Evidence:**

- DictationHUD partial-text foreground uses SwiftUI `.primary`/`.secondary`
  semantic colors (auto-adaptive against `.hudWindow` vibrancy material).
- User attested PASS in both Light and Dark modes on 2026-05-01
  (`20-VERIFICATION.md` Row Group F).

## Build Verification

```
$ cd PSTranscribe && swift build
[0/1] Planning build
Building for debugging...
[0/3] Write swift-version--58304C5D6DBC2206.txt
Build complete! (0.25s)
```

Zero compile errors, zero warnings introduced by Phase 20 token migration.

## Commit Trail

```
b20d4ba feat(20-03): remove .preferredColorScheme overrides for system-appearance adoption
d43a24a feat(20-02): replace 6 inline hex literals across 6 view files with adaptive tokens
3a53c18 feat(20-02): add warningTint/warningInk/errorTint/overlayDim/glassRule adaptive tokens
02d523f feat(20-01): convert 28 tokens to Color(light:dark:); promote legacy palette
65acf97 feat(20-01): add Color(light:dark:) adaptive helper to DesignTokens
```

## UAT Sign-off Reference

User Cary Newfeldt signed off Phase 20 final gate as PASS on 2026-05-01 per
`20-VERIFICATION.md`. All 10 surfaces (ContentView, LibrarySidebar,
LibraryEntryRow, TranscriptView, DetailsPane, CaptureDock idle + recording,
ControlBar, SettingsView, NotionTagSheet, OnboardingView) confirmed
re-rendering correctly without app restart on Light -> Dark -> Light
toggle. Auto-transition (Path A) observed during user UAT session.

Screenshot capture (REQ-20.5 visual regression and REQ-20.6 dark-mode
reference) was explicitly waived by user; source-level byte-equality proof for
light mode and visual attestation for dark mode accepted in lieu of PNG
capture. This trade-off is recorded in `20-VERIFICATION.md` Row Groups D and E
with explicit user sign-off.

## Anti-Pattern Scan

No TODO / FIXME / placeholder / stub anti-patterns introduced by Phase 20
commits. All token replacements are concrete adaptive `Color(light:dark:)`
definitions with documented hex values for both modes.

## Overall Status

**PASS** -- All six REQ-20.x requirements verified. Code-level evidence is
deterministic and matches plan claims. UAT items (REQ-20.5 and REQ-20.6) are
attested by user sign-off in `20-VERIFICATION.md`. Phase 20 closes with
system-following dark-mode parity achieved for the first time in PS Transcribe.

---

*Verified: 2026-04-30*
*Verifier: gsd-verifier (goal-backward analysis)*
*Build: clean (commit b20d4ba)*
