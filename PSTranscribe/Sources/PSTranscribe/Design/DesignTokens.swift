import SwiftUI

// MARK: - Colors

extension Color {
    // Paper surfaces
    static let paper      = Color(red: 0xFA/255, green: 0xFA/255, blue: 0xF7/255) // #FAFAF7 — window + transcript bg
    static let paperWarm  = Color(red: 0xF4/255, green: 0xF1/255, blue: 0xEA/255) // #F4F1EA — sidebar + secondary surfaces
    static let paperSoft  = Color(red: 0xEE/255, green: 0xEA/255, blue: 0xE0/255) // #EEEAE0 — hover / pressed

    // Rules (hairlines)
    static let rule         = Color(red: 30/255, green: 30/255, blue: 28/255).opacity(0.08)
    static let ruleStrong   = Color(red: 30/255, green: 30/255, blue: 28/255).opacity(0.14)

    // Ink (text)
    static let ink       = Color(red: 0x1A/255, green: 0x1A/255, blue: 0x17/255) // #1A1A17 — primary
    static let inkMuted  = Color(red: 0x59/255, green: 0x59/255, blue: 0x54/255) // #595954 — secondary
    static let inkFaint  = Color(red: 0x8A/255, green: 0x8A/255, blue: 0x82/255) // #8A8A82 — meta / labels
    static let inkGhost  = Color(red: 0xB8/255, green: 0xB8/255, blue: 0xAF/255) // #B8B8AF — disabled / tertiary

    // Accent (toggles, focus)
    static let accentInk   = Color(red: 0x2B/255, green: 0x4A/255, blue: 0x7A/255) // #2B4A7A
    static let accentSoft  = Color(red: 0xDF/255, green: 0xE6/255, blue: 0xF0/255) // #DFE6F0 — accent hover
    static let accentTint  = Color(red: 0xF1/255, green: 0xF4/255, blue: 0xF9/255) // #F1F4F9 — accent backgrounds

    // Speaker bubbles — others
    static let spk2Bg    = Color(red: 0xE6/255, green: 0xEC/255, blue: 0xEA/255) // #E6ECEA
    static let spk2Fg    = Color(red: 0x2D/255, green: 0x4A/255, blue: 0x43/255) // #2D4A43
    static let spk2Rail  = Color(red: 0x7F/255, green: 0xA0/255, blue: 0x93/255) // #7FA093

    // Speaker bubble — self
    static let youBg = Color.ink
    static let youFg = Color.paper

    // Status
    static let recRed    = Color(red: 0xC2/255, green: 0x4A/255, blue: 0x3E/255) // #C24A3E — record dot, destructive
    static let liveGreen = Color(red: 0x4A/255, green: 0x8A/255, blue: 0x5E/255) // #4A8A5E — ready / synced
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
