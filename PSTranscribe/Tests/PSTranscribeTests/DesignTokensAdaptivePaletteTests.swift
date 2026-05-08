// DesignTokensAdaptivePaletteTests
// Phase 25 (NYQUIST-06) -- Phase 20 REQ-20.2.
//
// Asserts that the 17 Chronicle tokens in DesignTokens.swift resolve to
// DIFFERENT RGB triples under .aqua vs .darkAqua appearance, proving each
// token is defined as Color(light:dark:) (not a single-hex literal).
//
// Technique: bridge SwiftUI.Color -> NSColor via `NSColor(_ color: Color)`,
// resolve under explicit appearances via
// `NSAppearance(named:)?.performAsCurrentDrawingAppearance`, convert to sRGB
// and compare redComponent/greenComponent/blueComponent.
//
// This exercises the same dynamic-NSColor mechanism DesignTokens.swift uses
// internally (see DesignTokens.swift:11-21) -- the test resolves the same
// closure-based resolution path through `performAsCurrentDrawingAppearance`.
//
// `.serialized` is MANDATORY: `performAsCurrentDrawingAppearance` mutates
// `NSAppearance.current`, which is process-global. Two parallel tests setting
// different appearances would race. (Phase 25 D-04 Claude's Discretion lock.)
//
// Token roster (17 tokens, from DesignTokens.swift lines 31-115 directly-defined
// Color(light:dark:) entries -- youBg/youFg are token-of-token aliases over
// ink/paper and are not separately tested; their adaptiveness derives from
// paper/ink, which ARE tested).

import Testing
import Foundation
import AppKit
import SwiftUI
@testable import PSTranscribe

@Suite("DesignTokensAdaptivePaletteTests", .serialized)
struct DesignTokensAdaptivePaletteTests {

    /// Resolves a SwiftUI Color under an explicit NSAppearance.Name and returns
    /// the sRGB RGB triple. Returns nil if the appearance can't be created
    /// (caller should `try #require` the result to fail fast on unsupported
    /// macOS appearance names).
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

    @Test func allChronicleTokensHaveDistinctLightAndDarkVariants() throws {
        // 17 directly-defined Chronicle tokens (Phase 20 REQ-20.2)
        let tokens: [(name: String, color: Color)] = [
            ("paper",      .paper),
            ("paperWarm",  .paperWarm),
            ("paperSoft",  .paperSoft),
            ("rule",       .rule),
            ("ruleStrong", .ruleStrong),
            ("ink",        .ink),
            ("inkMuted",   .inkMuted),
            ("inkFaint",   .inkFaint),
            ("inkGhost",   .inkGhost),
            ("accentInk",  .accentInk),
            ("accentSoft", .accentSoft),
            ("accentTint", .accentTint),
            ("spk2Bg",     .spk2Bg),
            ("spk2Fg",     .spk2Fg),
            ("spk2Rail",   .spk2Rail),
            ("recRed",     .recRed),
            ("liveGreen",  .liveGreen),
        ]
        #expect(tokens.count == 17,
                "Phase 20 REQ-20.2 specifies 17 Chronicle tokens; roster has \(tokens.count)")

        for (name, color) in tokens {
            let light = try #require(rgb(of: color, under: .aqua),
                                     "\(name): light variant unresolvable under .aqua")
            let dark = try #require(rgb(of: color, under: .darkAqua),
                                    "\(name): dark variant unresolvable under .darkAqua")
            // Compound inequality: at least one component must differ. Single-hex
            // tokens would resolve identically under both appearances.
            let identical = (light.r == dark.r) && (light.g == dark.g) && (light.b == dark.b)
            #expect(!identical,
                    "\(name): light \(light) and dark \(dark) variants are identical -- token must be defined as Color(light:dark:) (Phase 20 REQ-20.2)")
        }
    }
}
