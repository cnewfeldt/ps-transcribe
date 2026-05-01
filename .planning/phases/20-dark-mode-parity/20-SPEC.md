# Phase 20: Dark Mode Parity — Specification

**Created:** 2026-04-30
**Ambiguity score:** 0.10 (gate: ≤ 0.20)
**Requirements:** 6 locked

## Goal

Remove all forced `.preferredColorScheme` overrides and convert the Chronicle design system to a unified light+dark token palette so every macOS surface (main window, capture dock, Settings, NotionTagSheet, OnboardingView, DictationHUD) re-renders correctly when the user toggles System Settings > Appearance, with the light-mode appearance remaining pixel-stable.

## Background

PS Transcribe today is hard-locked to light mode through a single line at `ContentView.swift:251` (`.preferredColorScheme(.light)`), and `NotionTagSheet.swift:130` then forces the opposite (`.preferredColorScheme(.dark)`) on its sheet. Chronicle design tokens in `DesignTokens.swift` (paper / paperWarm / paperSoft / ink / inkMuted / inkFaint / inkGhost / accentInk / accentSoft / accentTint / spk2Bg / spk2Fg / spk2Rail / youBg / youFg / recRed / liveGreen) are defined as fixed-hex `Color` literals with no light/dark variant. A second, dark-only legacy palette (`bg0 / bg1 / bg2 / fg1 / fg2 / fg3 / accent1 / accent2 / recordRed / speakerTeal / speakerAmber`) lives at the bottom of `TranscriptView.swift` (lines 207–228) and is consumed by `ControlBar`, `OnboardingView`, `CaptureDock`, and `NotionTagSheet`. The result is a mixed-mode UI that ignores the user's system appearance and renders inconsistently across surfaces. Users have reported broken dark-mode rendering on the main window and the Settings window. Phase 20 audits and fixes every surface to match system appearance while preserving Chronicle's warm-paper / warm-dark identity.

## Requirements

1. **Remove forced color-scheme overrides**: The app must respect the system color scheme everywhere.
   - Current: `ContentView.swift:251` calls `.preferredColorScheme(.light)`; `NotionTagSheet.swift:130` calls `.preferredColorScheme(.dark)`
   - Target: No source file (excluding tests and `#Preview` blocks) calls `.preferredColorScheme(_:)` on a non-preview view
   - Acceptance: `grep -rn "preferredColorScheme(" PSTranscribe/Sources` returns zero hits outside `#Preview { ... }` blocks

2. **Unified Chronicle token palette**: Every Chronicle paper/ink token has explicit light and dark hex variants in `DesignTokens.swift`.
   - Current: All 17 Chronicle tokens (`paper`, `paperWarm`, `paperSoft`, `rule`, `ruleStrong`, `ink`, `inkMuted`, `inkFaint`, `inkGhost`, `accentInk`, `accentSoft`, `accentTint`, `spk2Bg`, `spk2Fg`, `spk2Rail`, `recRed`, `liveGreen`) are single-value `Color(red:green:blue:)` literals
   - Target: Each is defined via `Color(light:dark:)` (or equivalent `NSColor`-bridged adaptive form). The light variant equals the current hex value verbatim; the dark variant inverts the warm-paper identity (warm-dark backgrounds in the `#1A1818` family, cream foregrounds in the `#F0EDE8` family)
   - Acceptance: Visual inspection of light mode shows zero pixel drift versus the pre-phase build; visual inspection of dark mode shows warm-dark backgrounds (not slate-blue) and cream foregrounds with legible contrast

3. **Promote legacy dark-only tokens into DesignTokens.swift**: The legacy palette must move to the unified token system.
   - Current: `bg0`, `bg1`, `bg2`, `fg1`, `fg2`, `fg3`, `accent1`, `accent2`, `recordRed`, `speakerTeal`, `speakerAmber` are defined inside the `extension Color` block at `TranscriptView.swift:207–228`
   - Target: All 11 legacy tokens are moved into `DesignTokens.swift` as `Color(light:dark:)` definitions; the `extension Color` block at the bottom of `TranscriptView.swift` is deleted; `TranscriptView.swift` ends at the last view-related line
   - Acceptance: `grep -n "extension Color" PSTranscribe/Sources/PSTranscribe/Views/TranscriptView.swift` returns no match; all call-sites still compile

4. **Forced-dark and dark-only-token call-sites adapt**: Every view currently relying on forced dark or legacy tokens renders correctly in both color schemes.
   - Current: `NotionTagSheet` (forced `.dark` + uses `bg0`/`bg1`), `OnboardingView` (uses `bg0` and `accent1`), `ControlBar` (uses `bg1`/`accent1`), `CaptureDock` (uses `paper`/`paperWarm`), `SettingsView` (hardcoded `Color.orange.opacity(0.15)` background, paper/ink tokens), `DictationHUD` (relies on `.hudWindow` vibrancy material)
   - Target: Each view reads only from the unified palette in `DesignTokens.swift`; no view contains hex `Color(red:green:blue:)` literals as a foreground or background; the `Color.orange.opacity` warning chip in `SettingsView.swift:527` becomes a tokenized warning color with light+dark variants
   - Acceptance: Manual UAT — toggle System Settings > Appearance from Light → Dark → Light while the app is running; `ContentView`, `LibrarySidebar`, `TranscriptView`, `DetailsPane`, `CaptureDock`, `ControlBar`, `SettingsView`, `NotionTagSheet`, `OnboardingView`, and the `DictationHUD` panel all re-render correctly without app restart

5. **Light-mode pixel stability**: The light-mode appearance is preserved exactly.
   - Current: Light-mode rendering is the only rendering today (forced by override)
   - Target: After Phase 20, light-mode renders identically to the pre-phase build for the main window (ContentView + sidebar + transcript + details), the capture dock, and the Settings window
   - Acceptance: Side-by-side visual comparison (manual screenshot diff) of the main window, capture dock, and Settings window before vs. after Phase 20 in light mode shows no perceptible difference in background, text, or accent colors

6. **DictationHUD vibrancy adapts**: The HUD panel renders correctly in both modes via vibrancy material, not forced colors.
   - Current: `DictationHUD.swift` does not reference `Color` directly; the panel uses `NSPanel`'s `.hudWindow` material set in `DictationWindowController`
   - Target: The HUD panel re-renders correctly when system appearance toggles (vibrancy adapts automatically); any state-string foreground colors (e.g. partial-text overlay) use unified tokens
   - Acceptance: Manual UAT — trigger the dictation hotkey while in dark mode and again in light mode; HUD background is the system HUD vibrancy in both cases; partial-text foreground is legible against both vibrancies

## Boundaries

**In scope:**
- Removing both forced `.preferredColorScheme` calls (`ContentView.swift:251`, `NotionTagSheet.swift:130`)
- Converting all 17 Chronicle tokens in `DesignTokens.swift` to `Color(light:dark:)`
- Moving the 11 legacy dark-only tokens out of `TranscriptView.swift` and into `DesignTokens.swift` as `Color(light:dark:)`
- Auditing and fixing color usage in: `ContentView`, `LibrarySidebar`, `TranscriptView`, `DetailsPane`, `CaptureDock`, `ControlBar`, `SettingsView`, `NotionTagSheet`, `OnboardingView`, `DictationHUD`
- Replacing the hardcoded `Color.orange.opacity(0.15)` warning chip in `SettingsView` with a tokenized adaptive color
- Manual UAT verifying System Settings > Appearance toggle re-renders all surfaces without app restart
- Manual visual regression check confirming light-mode pixel stability

**Out of scope:**
- Automated snapshot or visual-regression tests — manual UAT chosen as the verification mechanism for this phase; lower-cost path that the user explicitly preferred
- WCAG / accessibility contrast ratio verification (4.5:1 / 3:1) — separate accessibility concern, not part of system-appearance parity
- High-contrast / Increase Contrast / Reduce Transparency macOS accessibility settings — separate accessibility scope
- A user-facing app preference to override system appearance ("Force Light" / "Force Dark" toggle) — phase delivers system-following behavior only
- New design tokens, palette additions, or Chronicle redesign — scope is parity for the existing palette, not a design-system overhaul
- Custom HUD vibrancy material changes — system `.hudWindow` material handles adaptation; no override added
- Marketing site (`/website`) — Chronicle web port stays light-only by prior milestone decision

**Adjacent but excluded:**
- Phase 19 (Integration & Hardening) UAT checklist updates beyond what Phase 20 needs — Phase 19 owns its own scope; Phase 20 only adds the dark-mode toggle UAT step inside Phase 20's plan
- Settings UI restructuring (three-folder-picker coherence audit, copy edits) — owned by Phase 19

## Constraints

- **Light-mode pixel stability is a hard constraint.** The light variant of every `Color(light:dark:)` definition must equal the current literal byte-for-byte; verifier compares pre-/post-phase screenshots of the main window, capture dock, and Settings window in light mode and rejects any drift.
- **Single source of truth for color tokens.** After Phase 20, `DesignTokens.swift` is the only file containing `Color(red:green:blue:)` literals or `Color(light:dark:)` definitions for app palette. The `extension Color` block at `TranscriptView.swift:207–228` is deleted entirely.
- **Dark variant preserves Chronicle warmth.** Dark hex pairs reuse the legacy palette family (warm-dark `#1A1818` / `#2E2B29` backgrounds, cream `#F0EDE8` foregrounds) — not slate-blue, not pure black, not material-design-grey.
- **No `#Preview` blocks need to drop their `.preferredColorScheme` calls** — preview previews are dev-tool-only and out of the grep gate scope.
- **macOS deployment target unchanged.** `Color(light:dark:)` and equivalent NSColor-bridged forms must work on the project's existing minimum macOS version; no minimum-OS bump permitted.

## Acceptance Criteria

- [ ] `grep -rn "preferredColorScheme(" PSTranscribe/Sources` returns zero matches outside `#Preview { ... }` blocks
- [ ] `grep -n "extension Color" PSTranscribe/Sources/PSTranscribe/Views/TranscriptView.swift` returns no match
- [ ] All 17 Chronicle tokens and all 11 promoted legacy tokens are defined in `DesignTokens.swift` using `Color(light:dark:)` (or equivalent adaptive form)
- [ ] App compiles cleanly with `swift build` and `xcodebuild` (no warnings introduced by token migration)
- [ ] Manual UAT — toggling System Settings > Appearance from Light → Dark → Light while the app is running re-renders ContentView, LibrarySidebar, TranscriptView, DetailsPane, CaptureDock, ControlBar, SettingsView, NotionTagSheet, OnboardingView, and DictationHUD correctly without app restart
- [ ] Manual visual regression — pre- vs. post-phase screenshots of the main window, capture dock, and Settings window in light mode show no perceptible color drift
- [ ] Manual UAT — DictationHUD partial-text foreground is legible against `.hudWindow` vibrancy in both light and dark system appearance
- [ ] `SettingsView.swift:527` warning chip background uses a tokenized adaptive color (no remaining `Color.orange.opacity(0.15)` literal)

## Ambiguity Report

| Dimension          | Score | Min  | Status | Notes                                                            |
|--------------------|-------|------|--------|------------------------------------------------------------------|
| Goal Clarity       | 0.95  | 0.75 | ✓      | Remove overrides + retoken Chronicle, dark = inverted Chronicle  |
| Boundary Clarity   | 0.90  | 0.70 | ✓      | All surfaces in; explicit out-of-scope on tests / WCAG / preview |
| Constraint Clarity | 0.85  | 0.65 | ✓      | Light-mode pixel parity is a hard constraint                     |
| Acceptance Criteria| 0.85  | 0.70 | ✓      | Grep gate + manual UAT toggle + visual regression                |
| **Ambiguity**      | 0.10  | ≤0.20| ✓      |                                                                  |

## Interview Log

| Round | Perspective       | Question summary                              | Decision locked                                                                 |
|-------|-------------------|-----------------------------------------------|---------------------------------------------------------------------------------|
| 1     | Researcher        | What triggers Phase 20?                       | User-reported dark-mode bugs (not aspirational, not App-Store)                  |
| 1     | Researcher        | What is dark mode supposed to look like?      | Inverted Chronicle palette — warm-dark, not system-native, not slate            |
| 2     | Researcher        | Which surfaces had reported bugs?             | Main window + capture dock + Settings (NOT Notion sheet, onboarding, HUD)       |
| 2     | Simplifier        | Minimum viable scope?                         | Remove forced overrides + retoken Chronicle (full unification)                  |
| 3     | Boundary Keeper   | Adjacent surfaces in or out?                  | All in — one full sweep including Notion sheet, onboarding, HUD                 |
| 3     | Boundary Keeper   | Done state?                                   | Every view respects system colorScheme; manual UAT only, no snapshots, no WCAG  |
| 4     | Failure Analyst   | Fate of legacy bg0/bg1/fg1 etc.?              | Promote to unified `Color(light:dark:)` in DesignTokens.swift; delete origin    |
| 4     | Failure Analyst   | Worst broken-version a verifier should reject?| No remaining forced overrides AND no light-mode regression — both gates         |

---

*Phase: 20-dark-mode-parity*
*Spec created: 2026-04-30*
*Next step: /gsd-discuss-phase 20 — implementation decisions (Color(light:dark:) vs NSColor bridging, plan-wave breakdown, file-by-file migration order)*
