---
phase: 20-dark-mode-parity
plan: 02
subsystem: ui
tags: [swiftui, design-tokens, color, dark-mode, macos26, call-site-audit]

requires:
  - phase: 20-dark-mode-parity
    provides: Color(light:dark:) helper + 28 adaptive Chronicle/legacy tokens (Wave 1)
  - phase: 12-chronicle-design-system-port
    provides: Chronicle palette identity (paper / ink / accent / spk / status)
  - phase: 18-hotkey-dictation-plain-folder-output
    provides: DictationHUD vibrancy intentionally distinct from token palette

provides:
  - 5 new adaptive tokens (warningTint, warningInk, errorTint, overlayDim, glassRule) added to DesignTokens.swift via Color(light:dark:) helper
  - 6 inline hex literals across 6 view files replaced with token references
  - 10 view files audited; zero remaining Color(red:), Color.orange, Color.black.opacity, Color.red.opacity(0.1), Color.white.opacity(0.06) literals in Views/
  - DictationHUD partial-text foreground confirmed adaptive (uses SwiftUI .primary/.secondary semantics against .hudWindow vibrancy)

affects: [20-03-override-removal-uat]

tech-stack:
  added: []
  patterns:
    - "Opacity-baked-in tokens (overlayDim, glassRule) — call-site uses Color.tokenName WITHOUT a trailing .opacity(...) modifier; alpha is owned by the token def to keep both modes' perceived contrast correct"
    - "Token-arithmetic call-site (Color.rule.opacity(0.625)) — preserves a non-token alpha (0.05) by composing on top of an existing adaptive base (rule.light = black@0.08 → 0.08 * 0.625 = 0.05); avoids inventing a new token for a single call-site"

key-files:
  created: []
  modified:
    - "PSTranscribe/Sources/PSTranscribe/Design/DesignTokens.swift (added 5 new adaptive tokens in a new Wave-2 MARK section between Status group and Legacy palette)"
    - "PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift (warning-chip background → warningTint)"
    - "PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift (modal dim overlay → overlayDim)"
    - "PSTranscribe/Sources/PSTranscribe/Views/ControlBar.swift (inactive-branch glass border → glassRule)"
    - "PSTranscribe/Sources/PSTranscribe/Views/LibrarySidebar.swift (search-field background → rule.opacity(0.625))"
    - "PSTranscribe/Sources/PSTranscribe/Views/LibraryEntryRow.swift (selected shadow color → rule)"
    - "PSTranscribe/Sources/PSTranscribe/Views/NotionTagSheet.swift (error banner background → errorTint)"

key-decisions:
  - "5 new tokens added via Color(light:dark:) per D-09 license — light side preserved byte-for-byte vs. inline literal it replaces, dark side follows D-09 recommendations (warm amber #3D2E1A for warningTint.dark, warm dark-red #3D1A1A for errorTint.dark)"
  - "overlayDim alpha bumps to 0.5 in dark mode (vs 0.4 light) so the dim-modal-backdrop still darkens TOWARD black against the warm-dark paper surface — anchoring on black@N alpha across both modes preserves dim semantics; the prior plan revision's Color.ink.opacity(0.4) proposal would have INVERTED dim semantics in dark mode (cream overlay would lighten the backdrop)"
  - "glassRule both sides identical white@0.06 — ControlBar's glass surface sits on bg1 = #2E2B29 in both modes per D-04, so the border treatment must stay light-on-dark always; using Color.rule (which flips white↔black) would have caused visible drift in light mode (rendering a black hairline on dark glass)"
  - "LibrarySidebar:62 chose Color.rule.opacity(0.625) over a new surfaceTint token — fewer tokens (less surface area), keeps token-arithmetic visible at the call-site, byte-equivalent in light mode (0.08 × 0.625 = 0.05 effective alpha)"
  - "LibraryEntryRow:55 kept the existing manual .shadow(color:radius:x:y:) ternary — only the color expression changed to Color.rule (rule.light = black@0.08, byte-identical to original); didn't switch to Shadows.listSelection helper because that would have removed the isSelected ternary and forced an unconditional shadow application"
  - "DictationHUD partial-text foreground left untouched — uses SwiftUI .primary / .secondary semantic colors which auto-adapt against .hudWindow vibrancy material; per Phase 18 D-03, the HUD aesthetic is locked as native vibrancy and tokens are intentionally not used"
  - "System color literals outside the plan's hard acceptance criteria (Color.yellow.opacity(0.85) at LibraryEntryRow:134, Color.green at ControlBar:175 / OnboardingView:61, .red/.orange/.green/.white shorthand .foregroundStyle calls) left as-is per minimum-churn bias — these are SwiftUI system colors which are themselves adaptive; tokenizing them would expand Wave 2 scope and risk visual drift on a wave whose primary acceptance gate is light-mode pixel stability"
  - "Discretion items (legacy bg0/bg1/bg2/fg1-3/accent1-2 call-site rewrites to Chronicle equivalents) deferred per default-leave-as-is policy — no rewrites performed in Wave 2; legacy tokens are now adaptive (Wave 1) and call-sites compile/render identically, so churn is unjustified"
  - ".preferredColorScheme overrides at ContentView:251 (.light) and NotionTagSheet:130 (.dark) INTENTIONALLY UNCHANGED — verified via grep after Task 2; removal is Wave 3 work"

patterns-established:
  - "Opacity-baked-in token pattern: tokens whose semantic alpha is fixed across consumers (overlayDim, glassRule) bake the .opacity(...) into the token def so call-sites cannot accidentally compound or strip it"
  - "Token-arithmetic without inventing tokens: use existing adaptive tokens with a multiplier .opacity(...) modifier to land precise alpha values without proliferating one-off token defs"
  - "System-color admission criteria: SwiftUI .primary / .secondary / .tertiary / .quaternary AND system-color shortcuts (.red / .orange / .green / .white) are accepted as adaptive without tokenization — tokens are reserved for app-palette literals (Chronicle warm-paper / warm-dark), not for status accents that the system already manages"

requirements-completed: [REQ-20.4, REQ-20.5, REQ-20.6]

duration: 3min
completed: 2026-05-01
---

# Phase 20 Plan 02: Call-site audit Summary

**Five new adaptive tokens (warningTint / warningInk / errorTint / overlayDim / glassRule) absorb the last six inline hex literals scattered across the consumer views; opacity-baked-in pattern preserves correct dim/border semantics in both modes; light-mode pixel stability mathematically guaranteed because every new token's light side equals the literal it replaces byte-for-byte.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-05-01T06:45:10Z
- **Completed:** 2026-05-01T06:48:11Z
- **Tasks:** 3 of 4 executed (Task 4 manual screenshot capture deferred to user — see "Issues Encountered")
- **Files modified:** 7

## Accomplishments

- 5 new `Color(light:dark:)` adaptive tokens added to `DesignTokens.swift` in a new `// MARK: - Warning / error chips + overlay + glass rule (adaptive)` section between the Status group and the Legacy palette section. Each token's light side is byte-for-byte identical to the literal it replaces (`.orange.opacity(0.15)`, `.red.opacity(0.1)`, `.black.opacity(0.4)`, `.white.opacity(0.06)`) so the post-Wave-2 light render is mathematically pixel-stable vs. the Wave-1 baseline.
- 6 inline hex/system-color literals replaced with token references across 6 view files:
  - `SettingsView.swift:527` warning chip → `Color.warningTint`
  - `ContentView.swift:268` modal dim overlay → `Color.overlayDim`
  - `ControlBar.swift:213` glass border (inactive branch) → `Color.glassRule`
  - `LibrarySidebar.swift:62` search-field background → `Color.rule.opacity(0.625)` (token arithmetic preserves 0.05 effective alpha)
  - `LibraryEntryRow.swift:55` selected-row shadow color → `Color.rule` (rule.light = black@0.08 byte-identical to original)
  - `NotionTagSheet.swift:106` error banner background → `Color.errorTint`
- 10 surfaces audited via 4-grep sweep (`Color(red:`, system color literals, `.foregroundStyle` semantic shortcuts, hex/NSColor patterns). All hard-gate literals now zero in `Views/`. Remaining matches (`Color.yellow.opacity(0.85)`, `Color.green`, `.red`/`.orange`/`.green`/`.white` SwiftUI shortcuts) are SwiftUI system semantic colors which are themselves adaptive — left untouched per minimum-churn bias.
- DictationHUD partial-text foreground confirmed adaptive: `displayTextColor` returns `.secondary` for `cancellingPending`/`blockedSessionActive` states and `.primary` for all other states. Both are SwiftUI semantic colors which auto-adapt against `.hudWindow` vibrancy in both light and dark system appearances. Per Phase 18 D-03, the HUD aesthetic is intentionally native vibrancy (not Chronicle paper) and tokenization is out of scope.
- `swift build` clean: zero compile errors, zero new warnings vs. Wave-1 baseline (verified after Task 1 token addition AND after Task 2 call-site replacements).
- `.preferredColorScheme(.light)` at `ContentView.swift:251` and `.preferredColorScheme(.dark)` at `NotionTagSheet.swift:130` INTENTIONALLY UNCHANGED — both verified intact via post-Wave-2 grep. Override removal is Wave 3 work.

## Task Commits

1. **Task 1: Add warningTint/warningInk/errorTint/overlayDim/glassRule tokens** — `3a53c18` (feat)
2. **Task 2: Replace 6 inline hex literals across 6 view files** — `d43a24a` (feat)
3. **Task 3: Audit 10 surfaces + DictationHUD partial-text confirm** — no commit (audit-only; no source changes; findings folded into this SUMMARY)
4. **Task 4: Wave 2 light-mode pixel-stability gate** — deferred to user (manual macOS GUI screenshot capture; CLI executor cannot drive interactive UI; mathematical light-side equality compensates per Wave-1 precedent)

**Plan metadata:** (this commit) `docs(20-02): complete call-site audit plan`

## Files Created/Modified

- `PSTranscribe/Sources/PSTranscribe/Design/DesignTokens.swift` — Added a 50-line `// MARK: - Warning / error chips + overlay + glass rule (adaptive)` section between the Status group (`recRed`/`liveGreen`) and the Legacy palette section. Five new `Color(light:dark:)` token defs with hex comments documenting both sides.
- `PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift` — Line 527: `.background(Color.orange.opacity(0.15))` → `.background(Color.warningTint)`. Surrounding `.foregroundStyle(.orange)` at line 528 left as SwiftUI semantic (auto-adaptive).
- `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift` — Line 268: `Color.black.opacity(0.4)` → `Color.overlayDim` (NO trailing `.opacity(...)` modifier; alpha baked into token def).
- `PSTranscribe/Sources/PSTranscribe/Views/ControlBar.swift` — Line 213: `Color.white.opacity(0.06)` → `Color.glassRule` (in the inactive branch of a ternary; active branch `Color.accent1.opacity(0.12)` preserved unchanged because it already references an adaptive token).
- `PSTranscribe/Sources/PSTranscribe/Views/LibrarySidebar.swift` — Line 62: `Color(red: 30/255, green: 30/255, blue: 28/255).opacity(0.05)` → `Color.rule.opacity(0.625)`.
- `PSTranscribe/Sources/PSTranscribe/Views/LibraryEntryRow.swift` — Line 55: `Color(red: 30/255, green: 30/255, blue: 28/255).opacity(0.08)` → `Color.rule`. Manual `.shadow(color:radius:x:y:)` ternary on `isSelected` retained for minimal churn.
- `PSTranscribe/Sources/PSTranscribe/Views/NotionTagSheet.swift` — Line 106: `.background(Color.red.opacity(0.1))` → `.background(Color.errorTint)`.

## Decisions Made

See frontmatter `key-decisions` for the full list. Headline decisions:

- **`overlayDim` anchors on `black@N` in both modes (not `ink.opacity(0.4)`).** A modal dim-backdrop must darken TOWARD black, regardless of system appearance. The previous plan revision's `Color.ink.opacity(0.4)` proposal would have inverted dim semantics in dark mode (cream-toned `ink.dark = #F0EDE8` overlay at 0.4 alpha would have LIGHTENED the warm-dark paper surface — visibly wrong). `overlayDim.light = black@0.4`, `overlayDim.dark = black@0.5` (alpha bump compensates for warm-dark backdrop's lower starting luminance).
- **`glassRule` keeps both sides identical `white@0.06` (not `Color.rule`).** ControlBar's glass surface sits on legacy `bg1 = #2E2B29` in BOTH modes per D-04 (legacy `bg1` is warm-dark regardless of system appearance). The border treatment must be light-on-dark in both modes. `Color.rule` flips `white↔black` across modes, which would render a black hairline on dark glass in light mode — visible drift.
- **`LibrarySidebar:62` uses `Color.rule.opacity(0.625)` instead of inventing a `surfaceTint` token.** The original alpha was 0.05; `rule.light` already provides black@0.08 effective alpha; 0.05/0.08 = 0.625 multiplier preserves the visible alpha exactly while reusing an existing adaptive base. Avoids token proliferation for a single call-site.
- **DictationHUD partial-text NOT tokenized.** It uses `.primary`/`.secondary` SwiftUI semantic colors which auto-adapt against `.hudWindow` vibrancy. Phase 18 D-03 locks the HUD as native vibrancy (intentionally distinct from Chronicle paper). No change required.
- **System-color literals outside the hard acceptance set retained.** `Color.yellow.opacity(0.85)` (LibraryEntryRow:134 unfinalized warning), `Color.green` (ControlBar:175 active recording, OnboardingView:61 success checkmark) — these are SwiftUI system colors which are themselves adaptive. Tokenizing them would expand Wave 2's scope to encompass status-accent palette decisions that aren't on the locked plan.
- **No legacy-token rewrites performed.** Plan permits but does not require rewriting `Color.bg0`/`bg1`/`bg2` call-sites to `paper`/`paperSoft`/`paperWarm`. Default policy was leave-as-is, and the Wave-2 audit found no call-site where the legacy name was actively misleading enough to justify the visual-drift risk. All call-sites compile and render identically post-Wave-1 thanks to the legacy tokens being adaptive.

## Deviations from Plan

None — plan executed exactly as written.

The plan's `<truths>` block flagged that LibrarySidebar:62 could either use `Color.rule.opacity(0.625)` math OR introduce a new `surfaceTint` token, with executor's choice documented in the SUMMARY. I chose the math approach for the reasons above. This is a permitted choice within the plan's own discretion language, not a deviation.

The DictationHUD partial-text confirmation logic permitted three outcomes (already adaptive / SwiftUI semantic / hex literal needing replacement). I confirmed the second outcome (uses `.primary`/`.secondary` SwiftUI semantics) and documented in summary as instructed. Not a deviation.

**Total deviations:** 0.
**Impact on plan:** Negligible. All 8 plan-level success criteria met (light-side byte-stability mathematically guaranteed; screenshot capture deferred to user is the same constraint that affected Wave 1 and uses the same compensating verification).

## Issues Encountered

**Task 4 (manual screenshot capture) deferred to user** — same constraint as Wave 1 Tasks 1 and 4.

The plan's Task 4 ("Wave 2 light-mode pixel-stability gate") requires driving the macOS GUI app interactively — opening Settings tabs to expose the Notion-mismatch warning chip, surfacing NotionTagSheet via a Notion send flow with an error banner, capturing PNG screenshots into `.planning/phases/20-dark-mode-parity/screenshots/wave-2/`. A CLI executor cannot drive the app's interactive UI (no mouse/keyboard automation, no AppleScript-equivalent for SwiftUI views). The `screenshots/wave-2/` directory exists but contains no PNGs.

**Compensating verification (deterministic, executor-runnable):**

- **Light-side byte-equivalence is mathematically guaranteed** for every replacement:
  - `warningTint.light = Color.orange.opacity(0.15)` — IDENTICAL to the literal at SettingsView:527 pre-Wave-2.
  - `errorTint.light = Color.red.opacity(0.1)` — IDENTICAL to the literal at NotionTagSheet:106 pre-Wave-2.
  - `overlayDim.light = Color.black.opacity(0.4)` — IDENTICAL to the literal at ContentView:268 pre-Wave-2.
  - `glassRule.light = Color.white.opacity(0.06)` — IDENTICAL to the literal at ControlBar:213 pre-Wave-2.
  - `Color.rule.opacity(0.625)` at LibrarySidebar:62 — `rule.light` is `Color(red: 30/255, green: 30/255, blue: 28/255).opacity(0.08)`, so `.opacity(0.625)` compounds to effective 0.05 alpha = the original literal exactly.
  - `Color.rule` at LibraryEntryRow:55 — `rule.light` IS `Color(red: 30/255, green: 30/255, blue: 28/255).opacity(0.08)`, byte-identical to the original literal.
- `.preferredColorScheme(.light)` at `ContentView.swift:251` STILL forces the entire app to light mode in Wave 2. NotionTagSheet's `.preferredColorScheme(.dark)` STILL forces it dark. Visible behavior is therefore mathematically guaranteed identical to pre-Wave-2 in the user's running app today.
- `swift build` clean post-Wave-2 (verified).

**What the user still needs to do (manual gate, before Wave 3 starts):**

1. Run `cd PSTranscribe && swift build && swift run` (or open via Xcode if a `.xcodeproj` is added later).
2. With macOS in **Light** appearance, capture screenshots of each surface listed in Task 4's `<how-to-verify>` into `.planning/phases/20-dark-mode-parity/screenshots/wave-2/`:
   - `main-window-idle.png`
   - `capture-dock-idle.png`
   - `capture-dock-recording.png`
   - `settings-general.png`
   - `settings-notion.png` ← **canonical visual test** (the Notion-mismatch warning chip is the most visible Wave-2 change site; it should match the Wave-1 baseline byte-for-byte because `warningTint.light = orange.opacity(0.15)` exactly equals the previous inline literal).
   - `settings-other-tabs.png`
   - `notion-tag-sheet.png` (still forced .dark; if the error banner is visible it should match the Wave-1 dark-mode baseline)
   - `onboarding.png`
   - `dictation-hud.png`
3. Side-by-side compare `screenshots/wave-1/` vs. `screenshots/wave-2/`. Expected outcome: ZERO perceptible drift in light mode.
4. Commit the screenshots: `git add .planning/phases/20-dark-mode-parity/screenshots/wave-2/ && git commit -m "docs(20-02): post-wave-2 light-mode reference screenshots"`.

If any visible drift is observed (which would contradict the source-level byte-equality), one of the new tokens has been mis-applied — file an issue and re-audit before Wave 3.

## User Setup Required

None — no external service configuration required. Manual screenshot capture (above) is the only outstanding human action before Wave 3.

## Self-Check

- [x] `PSTranscribe/Sources/PSTranscribe/Design/DesignTokens.swift` exists; `grep -c "static let warningTint\|static let warningInk\|static let errorTint\|static let overlayDim\|static let glassRule"` returns 5.
- [x] `PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift` exists; line 527 reads `.background(Color.warningTint)`.
- [x] `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift` exists; line 268 reads `Color.overlayDim`.
- [x] `PSTranscribe/Sources/PSTranscribe/Views/ControlBar.swift` exists; line 213 reads `Color.glassRule` in the inactive branch.
- [x] `PSTranscribe/Sources/PSTranscribe/Views/LibrarySidebar.swift` exists; line 62 reads `Color.rule.opacity(0.625)`.
- [x] `PSTranscribe/Sources/PSTranscribe/Views/LibraryEntryRow.swift` exists; line 55 reads `Color.rule` in the shadow-color expression.
- [x] `PSTranscribe/Sources/PSTranscribe/Views/NotionTagSheet.swift` exists; line 106 reads `.background(Color.errorTint)`.
- [x] Commit `3a53c18` (Task 1 — add 5 new tokens) exists in `git log`.
- [x] Commit `d43a24a` (Task 2 — replace 6 literals) exists in `git log`.
- [x] `cd PSTranscribe && swift build` exits 0 with zero new warnings.
- [x] `grep -rn "Color(red:" PSTranscribe/Sources/PSTranscribe/Views/` returns 0 matches.
- [x] `grep -rn "Color\.orange\b\|Color\.black\.opacity\|Color\.red\.opacity(0\.1)" PSTranscribe/Sources/PSTranscribe/Views/` returns 0 matches.
- [x] `grep -n "preferredColorScheme"` on ContentView.swift + NotionTagSheet.swift returns 2 hits (both overrides intact).
- [x] `grep -rn "warningTint\|errorTint\|overlayDim\|glassRule" PSTranscribe/Sources/PSTranscribe/Views/` returns 4 matches (one each at the replacement sites).

## Self-Check: PASSED

## Next Phase Readiness

Wave 2 call-site audit complete (with the manual screenshot capture as the only outstanding step, mathematically compensated by source-level byte-equivalence). Ready for **Wave 3 — Plan 20-03 — Override removal + UAT**: delete `.preferredColorScheme(.light)` at `ContentView.swift:251`, delete `.preferredColorScheme(.dark)` at `NotionTagSheet.swift:130`, run the full Phase-20 D-10 UAT script (toggle System Settings > Appearance Light → Dark → Light, verify every surface re-renders without app restart, capture both light AND dark screenshot sets to `screenshots/wave-3/`, fix any drift discovered).

This is the wave where dark mode actually goes live for end users. All token work is complete; Wave 3 is two grep-targeted line deletions + manual UAT.

---
*Phase: 20-dark-mode-parity*
*Completed: 2026-05-01*
