# Phase 20: dark-mode-parity - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-30
**Phase:** 20-dark-mode-parity
**Areas discussed:** Token API form, Dark hex pairs, Migration order

---

## Gray Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| Token API form | How to encode adaptive colors (Color(light:dark:) vs NSColor inline vs asset catalog) | ✓ |
| Dark hex pairs | What dark variant of each Chronicle token actually is | ✓ |
| Migration order | How to roll changes without breaking light mode | ✓ |
| Legacy token fate | Whether bg0/bg1 stay first-class tokens or call-sites rewrite to paperSoft/inkMuted | |

**User's choice:** Token API form, Dark hex pairs, Migration order. Legacy token fate deferred to Claude's discretion at planner level.

---

## Token API form

### Q1: Adaptive color encoding form

| Option | Description | Selected |
|--------|-------------|----------|
| Color(light:dark:) custom init | Color extension wrapping NSColor(name:dynamicProvider:); inline-readable token defs | ✓ |
| Direct NSColor(name:dynamicProvider:) inline | Verbose AppKit-style per-token | |
| Asset catalog (.xcassets) | IDE-driven; would require SwiftPM Resources migration | |

**User's choice:** Color(light:dark:) custom init.
**Notes:** Matches existing static-let pattern; no new dependencies; both palettes inline per token.

### Q2: Init signature

| Option | Description | Selected |
|--------|-------------|----------|
| init(light: Color, dark: Color) | Takes SwiftUI Color values; bridges to NSColor internally | ✓ |
| init(lightHex: UInt32, darkHex: UInt32) | Tightest defs; needs custom hex parser | |
| init(light: NSColor, dark: NSColor) | Explicit sRGB color space; verbose | |

**User's choice:** init(light: Color, dark: Color).
**Notes:** Internal extraction to NSColor with .light fallback if extraction fails — preserves light pixel stability constraint.

### Q3: Helper home

| Option | Description | Selected |
|--------|-------------|----------|
| DesignTokens.swift, top of file | Single file owns token system + helper | ✓ |
| New file: Design/ColorAdaptive.swift | Separation if more adaptive helpers added later | |
| Inline (no helper) | NSColor calls per token, ~5 lines each | |

**User's choice:** DesignTokens.swift, top of file.

---

## Dark hex pairs

### Q1: Dark backgrounds

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse legacy bg0/bg1/bg2 verbatim | paper.dark = #1A1818, paperWarm.dark = #242120, paperSoft.dark = #2E2B29 | ✓ |
| Slightly warmer than legacy | Lift warmth to #1C1A18 family; needs designer eye | |
| Defer to designer | Don't pick hex values in spec; planner blocks pending design pass | |

**User's choice:** Reuse legacy bg0/bg1/bg2 verbatim.
**Notes:** Already in codebase, already proven warm-not-slate, already consumed by ControlBar/OnboardingView/NotionTagSheet.

### Q2: Dark ink scale

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse legacy fg1/fg2/fg3 | ink.dark = #F0EDE8, inkMuted = #8A8480, inkFaint = #5C5854 | ✓ |
| Higher contrast cream | ink.dark = #F4F1EC, mild WCAG bump | |
| Pure SF system labels | NSColor.labelColor — drops Chronicle warmth in foreground | |

**User's choice:** Reuse legacy fg1/fg2/fg3.

### Q3: Accent + speaker palette

| Option | Description | Selected |
|--------|-------------|----------|
| Lavender accent (legacy accent1) | accentInk.dark = #C4A0FF; speaker bubbles reuse spk2 family | ✓ |
| Keep accentInk blue (#2B4A7A) constant | Brand-constant accent across modes; risk dim on warm-dark | |
| Pick at planner stage | Defer accent + speaker to Wave 1 execution | |

**User's choice:** Lavender accent (legacy accent1).
**Notes:** youBg.dark = ink.dark, youFg.dark = paper.dark — flip automatically via token-of-token chain.

---

## Migration order

### Q1: Wave structure

| Option | Description | Selected |
|--------|-------------|----------|
| Tokens-first, override-last (3 waves) | W1 tokens; W2 call-site audit; W3 remove forced overrides | ✓ |
| Big-bang | Single PR all changes; no staged gates | |
| Surface-by-surface (override stays) | Migrate one view at a time; defeats "visible at each gate" | |

**User's choice:** Tokens-first, override-last (3 waves).

### Q2: Light-mode regression verification

| Option | Description | Selected |
|--------|-------------|----------|
| Manual screenshot diff at each wave | screenshots/baseline + wave-1 + wave-2 + wave-3 | ✓ |
| Pixel-perfect XCUITest snapshots | Stronger gate; contradicts SPEC.md no-automated-snapshots | |
| No light-mode regression check between waves | Trust migration; verify only at end | |

**User's choice:** Manual screenshot diff at each wave.

### Q3: Wave 3 UAT script

| Option | Description | Selected |
|--------|-------------|----------|
| System Settings toggle script | Light → Dark → Light + Auto mid-day switch verification across all 10 surfaces | ✓ |
| Light → Dark only | Skips return-trip and Auto-mode test | |
| Defer UAT script to plan-phase | Don't lock script in CONTEXT.md | |

**User's choice:** System Settings toggle script.

---

## Claude's Discretion

- **Legacy token fate** — call-site keep-vs-rewrite decision deferred to planner per-call-site judgment.
- **Warning chip semantic name + dark hex** in SettingsView:527 — planner picks token name and dark variant.
- **Exact `inkGhost.dark` hex** — interpolated below fg3.
- **Exact dark variants for `accentSoft`, `accentTint`, `spk2*`, `liveGreen`, `rule`, `ruleStrong`** — derivation rules locked in CONTEXT.md D-06/D-07; planner picks exact hexes during Wave 1.
- **DictationHUD partial-text foreground tokenization** — planner confirms during Wave 2 audit.

## Deferred Ideas

- WCAG / accessibility contrast verification — out of scope per SPEC.md, future accessibility phase.
- High-contrast macOS appearance support — same future accessibility phase.
- User-facing app theme override ("Force Light" / "Force Dark" preference) — explicit out-of-scope per SPEC.md.
- Automated snapshot / visual-regression tests — explicit out-of-scope per SPEC.md.
- Marketing site (`/website`) dark mode — web Chronicle port is light-only by prior milestone decision.
- Designer dark-Chronicle pass — Phase 20 reuses legacy hexes; future design phase could tune dark-Chronicle hexes deliberately.
