# Phase 20: dark-mode-parity - Context

**Gathered:** 2026-04-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Audit and fix dark-mode rendering across the macOS app so every surface (HUD, Settings, library, content views) matches the system appearance — by removing forced `.preferredColorScheme` overrides and converting the Chronicle design system to a unified light+dark token palette. Light-mode appearance must remain pixel-stable. Manual UAT only — no automated snapshot tests, no WCAG verification, no user-facing theme override.

</domain>

<spec_lock>
## Requirements (locked via SPEC.md)

**6 requirements are locked.** See `20-SPEC.md` for full requirements, boundaries, and acceptance criteria.

Downstream agents MUST read `20-SPEC.md` before planning or implementing. Requirements are not duplicated here.

**In scope (from SPEC.md):**
- Removing both forced `.preferredColorScheme` calls (`ContentView.swift:251`, `NotionTagSheet.swift:130`)
- Converting all 17 Chronicle tokens in `DesignTokens.swift` to `Color(light:dark:)`
- Moving the 11 legacy dark-only tokens out of `TranscriptView.swift` and into `DesignTokens.swift` as `Color(light:dark:)`
- Auditing and fixing color usage in: `ContentView`, `LibrarySidebar`, `TranscriptView`, `DetailsPane`, `CaptureDock`, `ControlBar`, `SettingsView`, `NotionTagSheet`, `OnboardingView`, `DictationHUD`
- Replacing the hardcoded `Color.orange.opacity(0.15)` warning chip in `SettingsView` with a tokenized adaptive color
- Manual UAT verifying System Settings > Appearance toggle re-renders all surfaces without app restart
- Manual visual regression check confirming light-mode pixel stability

**Out of scope (from SPEC.md):**
- Automated snapshot or visual-regression tests — manual UAT chosen as the verification mechanism
- WCAG / accessibility contrast ratio verification (4.5:1 / 3:1) — separate accessibility concern
- High-contrast / Increase Contrast / Reduce Transparency macOS accessibility settings — separate accessibility scope
- A user-facing app preference to override system appearance ("Force Light" / "Force Dark" toggle) — phase delivers system-following behavior only
- New design tokens, palette additions, or Chronicle redesign — scope is parity for the existing palette, not a design-system overhaul
- Custom HUD vibrancy material changes — system `.hudWindow` material handles adaptation
- Marketing site (`/website`) — Chronicle web port stays light-only by prior milestone decision

</spec_lock>

<decisions>
## Implementation Decisions

### Token API form

- **D-01:** Adaptive colors use a custom `Color(light:dark:)` extension init that takes two SwiftUI `Color` values and bridges to `NSColor(name:dynamicProvider:)` internally. Token defs read like:
  ```swift
  static let paper = Color(
      light: Color(red: 0xFA/255, green: 0xFA/255, blue: 0xF7/255),
      dark:  Color(red: 0x1A/255, green: 0x18/255, blue: 0x18/255)
  )
  ```
  Caller-side stays close to current shape, both palettes inline per-token, easiest review. No `.xcassets` migration. No NSColor exposure at call-sites.

- **D-02:** Init signature is `init(light: Color, dark: Color)` — takes existing SwiftUI `Color` literals, NOT packed hex `UInt32` and NOT explicit `NSColor` on both sides. Internal implementation extracts `NSColor` from each `Color` via `NSColor(_:)` bridge, then constructs `NSColor(name:dynamicProvider:)`. If extraction fails for any reason, the init falls back to the `light` value (preserves light-mode pixel stability as the hard constraint).

- **D-03:** The `Color(light:dark:)` extension lives at the top of `DesignTokens.swift`, immediately above the token definitions in the existing `extension Color` block. Single file owns the entire token system AND its helper. No new file under `Sources/PSTranscribe/Design/`.

### Dark hex pairs

- **D-04:** Dark backgrounds reuse the legacy palette family verbatim — no new color invention.
  - `paper.dark` = `#1A1818` (= legacy `bg0`)
  - `paperWarm.dark` = `#242120` (= legacy `bg2`)
  - `paperSoft.dark` = `#2E2B29` (= legacy `bg1`, the "glass base")
  These hexes are already in the codebase, already proven warm-not-slate, and already consumed by ControlBar / OnboardingView / NotionTagSheet so they need no re-validation.

- **D-05:** Dark foregrounds reuse the legacy fg1/fg2/fg3 cream scale — Chronicle's "warm cream on warm dark" identity.
  - `ink.dark` = `#F0EDE8` (= legacy `fg1`)
  - `inkMuted.dark` = `#8A8480` (= legacy `fg2`)
  - `inkFaint.dark` = `#5C5854` (= legacy `fg3`)
  - `inkGhost.dark` = ~`#3F3C39` (interpolated below `fg3` for the disabled tier; planner picks exact hex)

- **D-06:** Accent palette in dark mode uses the legacy lavender (NOT the constant blue accentInk).
  - `accentInk.dark` = `#C4A0FF` (= legacy `accent1`, lavender)
  - `accentSoft.dark` and `accentTint.dark` are lower-saturation derivatives — planner picks exact hex during Wave 1
  - Speaker bubbles in dark mode reuse existing `spk2` family hexes adapted from current dark consumers (planner fills in: `spk2Bg.dark`, `spk2Fg.dark`, `spk2Rail.dark` based on the current speaker palette in TranscriptView consumers)
  - `youBg.dark` and `youFg.dark` flip automatically because they reference `Color.ink` and `Color.paper` (token-of-token chain)

- **D-07:** Status colors (`recRed`, `liveGreen`) and rule colors (`rule`, `ruleStrong`) get dark variants derived during Wave 1 — recommended starting points: `recRed.dark` = `#E85B5B` (= legacy `recordRed`); `liveGreen.dark` = lift current saturation +10%; `rule.dark` and `ruleStrong.dark` flip from black-with-opacity to white-with-opacity (preserving the same alpha values 0.08 / 0.14). Planner verifies pixel-stable in light + legible in dark before locking.

### Migration order

- **D-08:** Migration ships in three waves with verifiable gates between each:
  - **Wave 1 — Token system foundation:** Add `Color(light:dark:)` helper to `DesignTokens.swift`. Convert all 17 Chronicle tokens to adaptive. Promote all 11 legacy dark-only tokens (`bg0`, `bg1`, `bg2`, `fg1`, `fg2`, `fg3`, `accent1`, `accent2`, `recordRed`, `speakerTeal`, `speakerAmber`) from `TranscriptView.swift:207–228` into `DesignTokens.swift` as `Color(light:dark:)` defs. Delete the `extension Color` block at the bottom of `TranscriptView.swift`. Build clean, run app, verify light mode pixel-stable. **`.preferredColorScheme(.light)` and `.preferredColorScheme(.dark)` overrides remain in place for Wave 1.**
  - **Wave 2 — Call-site audit:** Walk every consumer (ContentView, LibrarySidebar, TranscriptView, DetailsPane, CaptureDock, ControlBar, SettingsView, NotionTagSheet, OnboardingView, DictationHUD). Replace any remaining hex literals with token references. Replace the `Color.orange.opacity(0.15)` warning chip in `SettingsView.swift:527` with a tokenized adaptive color (planner names — likely `warningTint` / `warningInk` or similar). Verify build clean and light-mode pixel-stable. Overrides STILL remain.
  - **Wave 3 — Override removal + UAT:** Delete `.preferredColorScheme(.light)` at `ContentView.swift:251`. Delete `.preferredColorScheme(.dark)` at `NotionTagSheet.swift:130`. Run the full UAT script (D-10). Fix any drift discovered. This is the wave where dark mode goes live.

- **D-09:** Light-mode pixel parity is verified at each wave gate via manual screenshot diff:
  - **Pre-Wave-1 baseline:** Capture light-mode screenshots of main window (with sidebar + transcript + details visible), capture dock (idle + recording state), Settings window (each tab), and the NotionTagSheet (currently forced-dark, so its baseline is its current dark state) — saved to `.planning/phases/20-dark-mode-parity/screenshots/baseline/`.
  - **Post-Wave-1 / Post-Wave-2:** Re-capture the same surfaces in light mode. Side-by-side compare. Reject any perceptible color drift. Saved to `screenshots/wave-1/` and `screenshots/wave-2/`.
  - **Post-Wave-3:** Capture both light AND dark equivalents. Verify light is still pixel-stable vs. baseline. Saved to `screenshots/wave-3/`.
  - Aligned with SPEC.md's explicit out-of-scope on automated snapshot tests.

- **D-10:** Wave 3 UAT script (the moment dark mode first goes live):
  1. Launch app while macOS is in **Light** appearance.
  2. Open every surface in this order: main window (ContentView with library + transcript + details), capture dock (idle + recording), ControlBar, SettingsView (every tab), NotionTagSheet (trigger via Notion send flow), OnboardingView (force first-run reset), DictationHUD (trigger via dictation hotkey).
  3. Open System Settings > Appearance and switch to **Dark**. Verify each surface re-renders correctly without app restart. No frozen light backgrounds, no clashing dark sheets, no missing tokens.
  4. Switch back to **Light**. Verify all surfaces revert and remain pixel-stable vs. the Wave-2 light screenshots.
  5. Switch to **Auto** appearance and trigger the macOS sunrise/sunset transition (or wait for it) to confirm mid-day appearance flips also propagate.
  6. Document any surface that fails in `20-VERIFICATION.md` as a deviation and re-run the loop.

### Claude's Discretion

- **Legacy token fate** (named gray area #4 from `present_gray_areas`, deferred at user's selection): planner decides per-call-site whether `ControlBar`/`OnboardingView`/`NotionTagSheet` keep writing `Color.bg1` / `Color.bg0` (now adaptive) or rewrite to `Color.paperSoft` / `Color.paper`. Both work after Wave 1 because legacy tokens become first-class adaptive tokens. Planner picks based on naming clarity at each call-site; bias toward minimal call-site churn unless a name is misleading (e.g., a view writing `Color.bg0` when it semantically wants "primary surface" should rewrite to `paper`).
- **Warning chip token name** in SettingsView:527 — planner picks the name (`warningTint`, `cautionBg`, etc.) and the dark variant hex (suggested: warm amber tint like `#3D2E1A` for dark, preserving warning legibility against bg0).
- **Exact `inkGhost.dark` hex** — interpolated below `fg3` per D-05; planner picks the exact value during Wave 1.
- **Exact dark variants for `accentSoft`, `accentTint`, `spk2*`, `liveGreen`, `rule`, `ruleStrong`** — derivation rules in D-06 / D-07; planner picks exact hexes during Wave 1.
- **DictationHUD partial-text foreground tokenization** — D-03 from Phase 18 locked HUD as native vibrancy; the partial-text overlay should use a token (likely `ink` post-migration, which auto-adapts) but planner confirms during Wave 2 audit.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 20 specs

- `.planning/phases/20-dark-mode-parity/20-SPEC.md` — Locked requirements, boundaries, acceptance criteria. **MUST read before planning.**

### Source files in scope

- `PSTranscribe/Sources/PSTranscribe/Design/DesignTokens.swift` — All 17 Chronicle tokens to convert to `Color(light:dark:)`; helper init lives here.
- `PSTranscribe/Sources/PSTranscribe/Views/TranscriptView.swift` lines 207–228 — Legacy `extension Color` block defining `bg0`/`bg1`/`bg2`/`fg1`/`fg2`/`fg3`/`accent1`/`accent2`/`recordRed`/`speakerTeal`/`speakerAmber`. To be moved into DesignTokens.swift and the entire block deleted from this file.
- `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift:251` — `.preferredColorScheme(.light)` to remove in Wave 3.
- `PSTranscribe/Sources/PSTranscribe/Views/NotionTagSheet.swift:130` — `.preferredColorScheme(.dark)` to remove in Wave 3.
- `PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift:527` — `Color.orange.opacity(0.15)` warning chip to replace with adaptive token.

### Surfaces requiring audit (10 total)

- `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift`
- `PSTranscribe/Sources/PSTranscribe/Views/LibrarySidebar.swift`
- `PSTranscribe/Sources/PSTranscribe/Views/TranscriptView.swift`
- `PSTranscribe/Sources/PSTranscribe/Views/DetailsPane.swift`
- `PSTranscribe/Sources/PSTranscribe/Views/CaptureDock.swift`
- `PSTranscribe/Sources/PSTranscribe/Views/ControlBar.swift`
- `PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift`
- `PSTranscribe/Sources/PSTranscribe/Views/NotionTagSheet.swift`
- `PSTranscribe/Sources/PSTranscribe/Views/OnboardingView.swift`
- `PSTranscribe/Sources/PSTranscribe/Views/DictationHUD.swift`

### Project planning context

- `.planning/PROJECT.md` — v1.2 milestone goal includes "full dark-mode parity so every surface respects the system appearance."
- `.planning/REQUIREMENTS.md` — v1.2 milestone goal (same as above).
- `.planning/ROADMAP.md` Phase 20 entry — "Audit and fix dark-mode rendering across the macOS app so every surface (HUD, Settings, library, content views) matches the system appearance."
- `.planning/codebase/CONVENTIONS.md` — Swift 6.2 + macOS 26 + strict concurrency (relevant: `NSColor(name:dynamicProvider:)` is available; `@MainActor` views; `@Observable` patterns unchanged by token migration).
- `.planning/codebase/STRUCTURE.md` — Views layout under `Sources/PSTranscribe/Views/`, design under `Sources/PSTranscribe/Design/`. (Note: this map predates the rebrand and references `Tome` paths in places — actual paths use `PSTranscribe`.)

### Prior phase context

- `.planning/phases/18-hotkey-dictation-plain-folder-output/18-CONTEXT.md` D-03 — Locks DictationHUD as native `.hudWindow` vibrancy, intentionally distinct from Chronicle paper. Phase 20 must NOT redesign the HUD aesthetic; only confirm partial-text foreground tokens render legibly against vibrancy in both system appearances.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **Legacy dark palette in TranscriptView.swift:209–228** — 11 dark hex values (bg0/bg1/bg2/fg1/fg2/fg3/accent1/accent2/recordRed/speakerTeal/speakerAmber) provide tested, in-use dark variants. Reusing them verbatim as the dark side of paper/ink/accentInk eliminates new color invention and ensures continuity with surfaces that already render dark (NotionTagSheet, OnboardingView, ControlBar).
- **DesignTokens.swift Chronicle palette** — 17 light tokens already organized into paper / ink / accent / speaker / status groups with hex comments. Adaptive conversion preserves the existing static-let shape; only the right-hand-side changes.
- **`Color.youBg = Color.ink` / `Color.youFg = Color.paper`** — these reference other tokens, so once `ink` and `paper` become adaptive, `youBg`/`youFg` flip automatically. Saves explicit dark variants for these two.

### Established Patterns

- **`@Observable` + `@MainActor` views** — token migration is purely cosmetic; no concurrency model change. SwiftUI `@Environment(\.colorScheme)` is automatically observed by views once `.preferredColorScheme` overrides are removed.
- **macOS 26 deployment** — `Color(NSColor(name:dynamicProvider:))` and `NSColor(name:dynamicProvider:)` both available without back-deployment guards.
- **Swift 6.2 strict concurrency** — `NSColor` is not Sendable but is only constructed in actor-isolated `static let` initializers, so no `Task` boundaries to navigate. Token defs at file scope are safe.

### Integration Points

- **Token call-sites** — every `.background(Color.X)`, `.foregroundStyle(Color.X)`, `Color.X.opacity(N)`, and `RoundedRectangle(...).fill(Color.X)` across the 10 surfaces. Migration is mechanical: existing calls keep working post-Wave-1 because the same identifier name now resolves to an adaptive Color. Inline `Color.orange`, `Color.black`, `Color.white`, `Color.red.opacity(...)` literals in views are the targets for tokenization (warning chip in SettingsView is the named example; `Color.black.opacity(0.4)` overlay in ContentView:268 and `Color.white.opacity(0.06)` border in ControlBar:213 are likely additional cases for planner audit).
- **No asset catalog** — SwiftPM project has no `.xcassets`. Color(light:dark:) approach explicitly chosen so no Resources bundle migration is needed.

</code_context>

<specifics>
## Specific Ideas

- **Inverted Chronicle, not slate, not material design.** User explicitly chose to invert the Chronicle warm-paper identity rather than adopt system-native semantic colors or a generic dark theme. Dark mode must FEEL like Chronicle — warm-dark backgrounds (#1A1818 family), cream-warm foregrounds (#F0EDE8 family), lavender accent (#C4A0FF). Reject any planner output that introduces slate-blue, pure black, or material-design-grey hexes as the dark side of paper/ink.
- **User-reported bugs were on main window + Settings.** All other surfaces (NotionTagSheet, OnboardingView, HUD) brought into scope as a one-shot full sweep at user direction (no second dark-mode phase later).
- **Pixel-stable light is a hard gate at every wave**, not just at the end. Manual screenshot diffs go in `screenshots/baseline/`, `screenshots/wave-1/`, `screenshots/wave-2/`, `screenshots/wave-3/`. Reject any perceptible drift.

</specifics>

<deferred>
## Deferred Ideas

- **WCAG / accessibility contrast verification** — Out of scope per SPEC.md. Future phase: dedicated accessibility pass covering contrast ratios, Increase Contrast / Reduce Transparency settings, VoiceOver labels.
- **High-contrast macOS appearance support** — Same future accessibility phase.
- **User-facing app theme override** ("Force Light" / "Force Dark" preference in Settings) — Explicit out-of-scope per SPEC.md. Capture for backlog if user demand emerges.
- **Automated snapshot / visual-regression tests** — Explicit out-of-scope per SPEC.md (manual UAT chosen). If regression risk grows, future phase could add `swift-snapshot-testing` or XCUITest screenshot pipeline.
- **Marketing site (`/website`) dark mode** — Web Chronicle port is light-only by prior milestone decision. Re-open only if the web identity strategy changes.
- **Designer dark-Chronicle pass** — Phase 20 reuses legacy hexes verbatim. If brand wants a more deliberate "dark Chronicle" palette later (slightly warmer than legacy bg0/bg1/bg2; designer-tuned accent saturation; paper-specific inkGhost.dark interpolation), capture as a follow-up design phase.

</deferred>

---

*Phase: 20-dark-mode-parity*
*Context gathered: 2026-04-30*
