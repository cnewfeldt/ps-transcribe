import SwiftUI
import AppKit

// MARK: - Adaptive Color helper
//
// Bridges two SwiftUI Color literals into a single dynamic Color that
// resolves per the active NSAppearance. On extraction failure, falls
// back to the `light` value to preserve light-mode pixel stability
// (the Phase 20 hard constraint).

extension Color {
    init(light: Color, dark: Color) {
        let lightNS = NSColor(light)
        let darkNS = NSColor(dark)
        let dynamic = NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
            return isDark ? darkNS : lightNS
        }
        self = Color(nsColor: dynamic)
    }
}

// MARK: - Colors
//
// All Chronicle tokens are adaptive via Color(light:dark:). The light side
// equals the pre-Phase-20 hex literal byte-for-byte (light-mode pixel-stability
// gate per D-09). The dark side reuses the legacy warm-dark family (D-04 / D-05)
// and the legacy lavender accent (D-06) — explicitly NOT slate-blue, NOT pure
// black, NOT material-design-grey. Dark hexes are locked per Plan 20-01 truths.

extension Color {
    // Paper surfaces — warm-paper light / warm-dark dark
    static let paper = Color(
        light: Color(red: 0xFA/255, green: 0xFA/255, blue: 0xF7/255),  // #FAFAF7
        dark:  Color(red: 0x1A/255, green: 0x18/255, blue: 0x18/255)   // #1A1818 (= legacy bg0)
    ) // window + transcript bg
    static let paperWarm = Color(
        light: Color(red: 0xF4/255, green: 0xF1/255, blue: 0xEA/255),  // #F4F1EA
        dark:  Color(red: 0x24/255, green: 0x21/255, blue: 0x20/255)   // #242120 (= legacy bg2)
    ) // sidebar + secondary surfaces
    static let paperSoft = Color(
        light: Color(red: 0xEE/255, green: 0xEA/255, blue: 0xE0/255),  // #EEEAE0
        dark:  Color(red: 0x2E/255, green: 0x2B/255, blue: 0x29/255)   // #2E2B29 (= legacy bg1, glass base)
    ) // hover / pressed

    // Rules (hairlines) — opacity preserved; dark flips from black to white
    static let rule = Color(
        light: Color(red: 30/255, green: 30/255, blue: 28/255).opacity(0.08),
        dark:  Color.white.opacity(0.08)
    )
    static let ruleStrong = Color(
        light: Color(red: 30/255, green: 30/255, blue: 28/255).opacity(0.14),
        dark:  Color.white.opacity(0.14)
    )

    // Ink (text) — warm cream scale on dark side (D-05, = legacy fg1/fg2/fg3)
    static let ink = Color(
        light: Color(red: 0x1A/255, green: 0x1A/255, blue: 0x17/255),  // #1A1A17
        dark:  Color(red: 0xF0/255, green: 0xED/255, blue: 0xE8/255)   // #F0EDE8 (= legacy fg1)
    ) // primary
    static let inkMuted = Color(
        light: Color(red: 0x59/255, green: 0x59/255, blue: 0x54/255),  // #595954
        dark:  Color(red: 0x8A/255, green: 0x84/255, blue: 0x80/255)   // #8A8480 (= legacy fg2)
    ) // secondary
    static let inkFaint = Color(
        light: Color(red: 0x8A/255, green: 0x8A/255, blue: 0x82/255),  // #8A8A82
        dark:  Color(red: 0x5C/255, green: 0x58/255, blue: 0x54/255)   // #5C5854 (= legacy fg3)
    ) // meta / labels
    static let inkGhost = Color(
        light: Color(red: 0xB8/255, green: 0xB8/255, blue: 0xAF/255),  // #B8B8AF
        dark:  Color(red: 0x3F/255, green: 0x3C/255, blue: 0x39/255)   // #3F3C39 (interpolated below fg3 per D-05)
    ) // disabled / tertiary

    // Accent (toggles, focus) — lavender on dark per D-06 (NOT the constant blue)
    static let accentInk = Color(
        light: Color(red: 0x2B/255, green: 0x4A/255, blue: 0x7A/255),  // #2B4A7A
        dark:  Color(red: 0xC4/255, green: 0xA0/255, blue: 0xFF/255)   // #C4A0FF (= legacy accent1, lavender)
    )
    static let accentSoft = Color(
        light: Color(red: 0xDF/255, green: 0xE6/255, blue: 0xF0/255),  // #DFE6F0
        dark:  Color(red: 0x3A/255, green: 0x2E/255, blue: 0x50/255)   // #3A2E50 (lavender-tinted dim surface)
    ) // accent hover
    static let accentTint = Color(
        light: Color(red: 0xF1/255, green: 0xF4/255, blue: 0xF9/255),  // #F1F4F9
        dark:  Color(red: 0x2A/255, green: 0x22/255, blue: 0x30/255)   // #2A2230 (deepest lavender-tinted bg)
    ) // accent backgrounds

    // Speaker bubbles — others (D-06 derived warm-dark teal family)
    static let spk2Bg = Color(
        light: Color(red: 0xE6/255, green: 0xEC/255, blue: 0xEA/255),  // #E6ECEA
        dark:  Color(red: 0x2A/255, green: 0x3A/255, blue: 0x35/255)   // #2A3A35 (warm-dark teal bubble)
    )
    static let spk2Fg = Color(
        light: Color(red: 0x2D/255, green: 0x4A/255, blue: 0x43/255),  // #2D4A43
        dark:  Color(red: 0x9C/255, green: 0xC2/255, blue: 0xB5/255)   // #9CC2B5 (cream-teal foreground)
    )
    static let spk2Rail = Color(
        light: Color(red: 0x7F/255, green: 0xA0/255, blue: 0x93/255),  // #7FA093
        dark:  Color(red: 0x5E/255, green: 0x7E/255, blue: 0x72/255)   // #5E7E72 (rail/divider tone)
    )

    // Speaker bubble — self (token-of-token chain; auto-flips because ink/paper are adaptive)
    static let youBg = Color.ink
    static let youFg = Color.paper

    // Status — D-07
    static let recRed = Color(
        light: Color(red: 0xC2/255, green: 0x4A/255, blue: 0x3E/255),  // #C24A3E
        dark:  Color(red: 0xE8/255, green: 0x5B/255, blue: 0x5B/255)   // #E85B5B (= legacy recordRed)
    ) // record dot, destructive
    static let liveGreen = Color(
        light: Color(red: 0x4A/255, green: 0x8A/255, blue: 0x5E/255),  // #4A8A5E
        dark:  Color(red: 0x5F/255, green: 0xA8/255, blue: 0x75/255)   // #5FA875 (saturation lifted ~+10% per D-07)
    ) // ready / synced
}

// MARK: - Warning / error chips + overlay + glass rule (adaptive)
//
// Wave 2 additions per Plan 20-02 truths. Each token's light side is byte-for-byte
// identical to the inline literal it replaces (light-mode pixel-stability gate).
// Dark sides follow D-09 license: warm amber/red tints harmonized with paper.dark.
// overlayDim and glassRule bake opacity INTO the token def — call-sites use them
// directly with NO `.opacity(...)` modifier.

extension Color {
    /// Background for warning chips (e.g. SettingsView Notion-mismatch warning).
    /// Light side preserved as `.orange.opacity(0.15)` literal (NOT a hex equivalent)
    /// so the resolved color stays bit-identical to today even if system `.orange`
    /// shifts in a future macOS update.
    static let warningTint = Color(
        light: Color.orange.opacity(0.15),
        dark:  Color(red: 0x3D/255, green: 0x2E/255, blue: 0x1A/255).opacity(0.6)
    ) // light: orange@0.15 / dark: warm amber #3D2E1A@0.6

    /// Foreground/text on warning chips. Light side inlines ink.light (#1A1A17)
    /// rather than referencing Color.ink to avoid a token-of-token chain THROUGH
    /// the adaptive helper (which would complicate dynamic resolution).
    static let warningInk = Color(
        light: Color(red: 0x1A/255, green: 0x1A/255, blue: 0x17/255), // = ink.light
        dark:  Color(red: 0xE8/255, green: 0xC4/255, blue: 0x80/255)
    ) // light: ink / dark: warm amber-cream

    /// Background for error chips (e.g. NotionTagSheet error banner).
    static let errorTint = Color(
        light: Color.red.opacity(0.1),
        dark:  Color(red: 0x3D/255, green: 0x1A/255, blue: 0x1A/255).opacity(0.6)
    ) // light: red@0.1 / dark: warm dark-red #3D1A1A@0.6

    /// Modal/sheet dim-backdrop overlay. Opacity baked in — call-site uses
    /// `Color.overlayDim` with NO `.opacity(...)` modifier. Both modes darken
    /// TOWARD black; dark mode uses slightly higher alpha so the perceived
    /// contrast stays equivalent against the warm-dark paper surface.
    static let overlayDim = Color(
        light: Color.black.opacity(0.4),
        dark:  Color.black.opacity(0.5)
    ) // light: black@0.4 / dark: black@0.5 — dim semantics preserved across modes

    /// Subtle hairline border on dark-glass surfaces (e.g. ControlBar inactive
    /// branch). Both sides identical white@0.06 because the underlying glass
    /// surface (bg1 = #2E2B29) is warm-dark in BOTH modes per D-04 — the
    /// border treatment must stay light-on-dark always. Do NOT swap to
    /// `Color.rule` here (would flip white↔black across modes — visible drift).
    /// Opacity baked in — call-site uses `Color.glassRule` with NO `.opacity(...)` modifier.
    static let glassRule = Color(
        light: Color.white.opacity(0.06),
        dark:  Color.white.opacity(0.06)
    ) // light: white@0.06 / dark: white@0.06 — light-on-glass regardless of mode
}

// MARK: - Legacy palette (kept until call-sites migrate to Chronicle tokens — Wave 2)
//
// Promoted from TranscriptView.swift:207-228. Light side = dark side = current
// legacy hex (preserves bit-exact current visible behavior since `.preferredColorScheme`
// overrides force light everywhere except NotionTagSheet today). Wave 2 may rewrite
// specific call-sites to paper/paperSoft (which IS adaptive); the legacy tokens
// themselves stay both-sides-equal in Wave 1 to keep the gate trivially passable.

extension Color {
    // Backgrounds — warm
    static let bg0 = Color(
        light: Color(red: 0.10, green: 0.09, blue: 0.09),
        dark:  Color(red: 0.10, green: 0.09, blue: 0.09)
    ) // #1A1818
    static let bg1 = Color(
        light: Color(red: 0.18, green: 0.17, blue: 0.16),
        dark:  Color(red: 0.18, green: 0.17, blue: 0.16)
    ) // #2E2B29 (glass base)
    static let bg2 = Color(
        light: Color(red: 0.14, green: 0.13, blue: 0.12),
        dark:  Color(red: 0.14, green: 0.13, blue: 0.12)
    ) // #242120

    // Foregrounds — warm cream
    static let fg1 = Color(
        light: Color(red: 0.94, green: 0.93, blue: 0.91),
        dark:  Color(red: 0.94, green: 0.93, blue: 0.91)
    ) // #F0EDE8
    static let fg2 = Color(
        light: Color(red: 0.54, green: 0.52, blue: 0.50),
        dark:  Color(red: 0.54, green: 0.52, blue: 0.50)
    ) // #8A8480
    static let fg3 = Color(
        light: Color(red: 0.36, green: 0.34, blue: 0.33),
        dark:  Color(red: 0.36, green: 0.34, blue: 0.33)
    ) // #5C5854

    // Accent — lavender
    static let accent1 = Color(
        light: Color(red: 0.77, green: 0.63, blue: 1.0),
        dark:  Color(red: 0.77, green: 0.63, blue: 1.0)
    ) // #C4A0FF
    static let accent2 = Color(
        light: Color(red: 0.58, green: 0.47, blue: 0.75),
        dark:  Color(red: 0.58, green: 0.47, blue: 0.75)
    ) // dimmer lavender

    // Recording red
    static let recordRed = Color(
        light: Color(red: 0.91, green: 0.36, blue: 0.36),
        dark:  Color(red: 0.91, green: 0.36, blue: 0.36)
    ) // #E85B5B

    // Named speaker palette
    static let speakerTeal = Color(
        light: Color(red: 0.60, green: 0.85, blue: 0.75),
        dark:  Color(red: 0.60, green: 0.85, blue: 0.75)
    )
    static let speakerAmber = Color(
        light: Color(red: 0.95, green: 0.75, blue: 0.45),
        dark:  Color(red: 0.95, green: 0.75, blue: 0.45)
    )
}

// MARK: - Spacing

enum Spacing {
    static let x4:  CGFloat = 4
    static let x6:  CGFloat = 6
    static let x8:  CGFloat = 8
    static let x10: CGFloat = 10
    static let x14: CGFloat = 14
    static let x18: CGFloat = 18
    static let x22: CGFloat = 22
    static let x28: CGFloat = 28
    static let x40: CGFloat = 40
}

// MARK: - Radii

enum Radius {
    static let input:  CGFloat = 4   // form controls
    static let button: CGFloat = 6   // list items, buttons
    static let card:   CGFloat = 10  // cards
    static let bubble: CGFloat = 12  // chat bubbles
    static let bubbleJoin: CGFloat = 4 // flattened corner when same speaker continues
    static let pill:   CGFloat = 999 // pill shapes
}

// MARK: - Shadows

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

enum Shadows {
    /// Selected list-item lift.
    static let listSelection = ShadowStyle(
        color: Color(red: 30/255, green: 30/255, blue: 28/255).opacity(0.08),
        radius: 3, x: 0, y: 1
    )
    /// Primary (Capture call) button depth.
    static let primaryButton = ShadowStyle(
        color: Color(red: 30/255, green: 30/255, blue: 28/255).opacity(0.20),
        radius: 2, x: 0, y: 1
    )
    /// Floating capture pill — used if we ever lift the dock off-canvas.
    static let capturePill = ShadowStyle(
        color: Color(red: 30/255, green: 30/255, blue: 28/255).opacity(0.12),
        radius: 24, x: 0, y: 8
    )
}

extension View {
    func shadow(_ style: ShadowStyle) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}

// MARK: - Typography
//
// Spec calls for Inter / Spectral / JetBrains Mono with native fallbacks
// (SF Pro / New York / SF Mono). We start on native fallbacks so the design
// lands without font-bundling complexity; swap in bundled fonts later by
// changing only these helpers.

extension Font {
    /// Sans-serif (SF Pro on macOS by default).
    static func chronicleSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// Serif (New York on macOS). Used for window titles + empty-state headlines.
    static func chronicleSerif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// Monospaced (SF Mono). Used for meta labels, timestamps, shortcuts.
    static func chronicleMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Text Styles
//
// Reusable styles drawn directly from the README spec so call sites read
// declaratively (`.chronicleMetaLabel()`) instead of re-deriving font+color
// at every site.

struct ChronicleMetaLabel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.chronicleMono(10, weight: .semibold))
            .tracking(0.5)
            .textCase(.uppercase)
            .foregroundStyle(Color.inkFaint)
    }
}

struct ChronicleMetaValue: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.chronicleMono(11))
            .foregroundStyle(Color.inkFaint)
    }
}

struct ChronicleBody: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.chronicleSans(13))
            .foregroundStyle(Color.ink)
    }
}

struct ChronicleTitle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.chronicleSans(15, weight: .semibold))
            .foregroundStyle(Color.ink)
    }
}

struct ChronicleHeadline: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.chronicleSerif(22, weight: .medium))
            .foregroundStyle(Color.ink)
    }
}

extension View {
    func chronicleMetaLabel() -> some View { modifier(ChronicleMetaLabel()) }
    func chronicleMetaValue() -> some View { modifier(ChronicleMetaValue()) }
    func chronicleBody()       -> some View { modifier(ChronicleBody()) }
    func chronicleTitle()      -> some View { modifier(ChronicleTitle()) }
    func chronicleHeadline()   -> some View { modifier(ChronicleHeadline()) }
}

// MARK: - Animation presets
//
// Durations drawn from §7 so we don't sprinkle magic numbers everywhere.

enum ChronicleAnimation {
    /// Toggle knob slide — 150ms ease-out.
    static let toggle: Animation = .easeOut(duration: 0.15)
    /// Selection state change — 80ms (instant-feel).
    static let selection: Animation = .easeOut(duration: 0.08)
    /// Dock state transition (idle → recording) — 200ms ease-in-out.
    static let dockState: Animation = .easeInOut(duration: 0.20)
}
