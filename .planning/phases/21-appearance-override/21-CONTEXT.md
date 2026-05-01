# Phase 21: appearance-override - Context

**Gathered:** 2026-05-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Add a three-way `AppearancePreference` (`.system` / `.light` / `.dark`) to `SettingsView` that overrides the macOS system color scheme app-wide. Default `.system` preserves Phase 20's system-following behavior byte-for-byte. Preference persists via `AppSettings` → `UserDefaults` and is applied at every SwiftUI scene root in `PSTranscribeApp.body`; `DictationWindowController` mirrors the preference onto its NSPanel via `NSAppearance` because the HUD lives outside the SwiftUI scene graph. SPEC.md locks 6 requirements; this phase ratifies implementation choices only.

</domain>

<spec_lock>
## Requirements (locked via SPEC.md)

**6 requirements are locked.** See `21-SPEC.md` for full requirements, boundaries, and acceptance criteria.

Downstream agents MUST read `21-SPEC.md` before planning or implementing. Requirements are not duplicated here.

**In scope (from SPEC.md):**
- New `AppearancePreference` enum (likely in `AppSettings.swift` or sibling under `Settings/`)
- New `appearancePreference` property on `AppSettings` with `UserDefaults` persistence
- New `Section("Appearance")` + `Picker` in `SettingsView`
- Single conceptual `.preferredColorScheme(_:)` reading from `AppSettings` at app root (see D-05 for actual call-site count)
- Manual UAT covering: Settings picker change without restart, persistence across relaunch, default-state visual parity with Phase 20

**Out of scope (from SPEC.md):**
- Per-window or per-feature appearance overrides
- Appearance-aware accessibility settings (Increase Contrast, Reduce Transparency, High Contrast)
- WCAG / contrast ratio re-verification
- Marketing site (`/website`) appearance toggle
- Custom theme editor / palette picker / accent-color customization
- Auto-schedule (light during work hours, dark at night)
- DictationHUD vibrancy override (`.hudWindow` material is system-controlled and adapts via the chosen `colorScheme`)
- Settings IA restructuring beyond adding the new section
- AppSettings refactor to a Codable settings struct

</spec_lock>

<decisions>
## Implementation Decisions

### Milestone placement

- **D-01:** Phase 21 ships as part of **v1.2** (extending the milestone before tagging the release). v1.2's STATE.md is currently marked `completed`; that flips back to `in_progress` while Phase 21 is open and re-flips to `completed` when Phase 21 closes. Reasoning: dark-mode parity (Phase 20) and user-controlled appearance preference are one product story; shipping them together avoids a v1.2 → v1.2.1 → v1.3 sequence that would split the dark-mode narrative across releases. Roadmap entry must be added under v1.2 alongside Phase 20.

### Picker style + section placement

- **D-02:** `Picker` uses default `.menu` (dropdown) style — no `.pickerStyle(.segmented)`. Matches the adjacent `Microphone` Picker on the same screen. Same `.font(.system(size: 12))` modifier as adjacent rows for typographic consistency.
- **D-03:** New `Section("Appearance")` is the **first** section in `SettingsView` Form, **above** `Section("Audio Input")`. Highest discoverability; sets app-wide UI tone before per-feature settings. SPEC's "between Audio Input and Local File" suggestion is rejected in favor of top placement.

### Copy

- **D-04:** Section title: **"Appearance"**. Picker label: **"Appearance"**. Option labels: **"System"**, **"Light"**, **"Dark"** (in that order). Matches SPEC's default. "System" chosen over "Auto" or "Match macOS" — most explicit per-app override semantic; avoids confusion with macOS `Auto` (sunset/sunrise schedule).

### App-root scene plumbing

- **D-05:** `.preferredColorScheme(settings.appearancePreference.colorScheme)` is applied at **each Scene's root inside `PSTranscribeApp.body`** — `WindowGroup { ContentView(...) }`, `Settings { SettingsView(...) }`, and the `MenuBarExtra` `label:` content. Three call-sites, all in `PSTranscribeApp.swift`, all reading from the same `AppSettings` source of truth. **No view-level overrides** — only `PSTranscribeApp.body` is permitted to call `.preferredColorScheme(`.

- **D-06:** **SPEC #4 grep gate is relaxed.** Original wording ("exactly ONE hit outside `#Preview` blocks") was written before scene-graph fan-out was analyzed. Updated acceptance: `grep -rn "preferredColorScheme(" PSTranscribe/Sources` returns **N hits, all in `PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift`, all reading `settings.appearancePreference.colorScheme`**. Verifier checks **location + source**, not count. Intent unchanged: no view/sheet/panel adds its own override; the app root owns appearance entirely. Planner must update SPEC #4 acceptance language inline (or add a `21-VERIFICATION.md` note pointing to D-06).

### DictationHUD coverage

- **D-07:** `DictationWindowController` (`PSTranscribe/Sources/PSTranscribe/App/DictationWindowController.swift`) hosts `DictationHUD` via `NSHostingView` inside an `NSPanel` — outside the SwiftUI scene graph. Scene-root `.preferredColorScheme` from D-05 does **not** propagate to it. Coverage path: **NSPanel observes `AppSettings.appearancePreference` and sets `panel.appearance = NSAppearance(named:)`** — `.darkAqua` for `.dark`, `.aqua` for `.light`, `nil` for `.system` (panel inherits the app/system effective appearance). Native AppKit API for an AppKit-owned panel; vibrancy material (`.hudWindow`) flips correctly because `NSAppearance` drives material rendering. Zero new `.preferredColorScheme(` call-sites in HUD code.

### AppearancePreference enum + persistence

- **D-08:** `AppearancePreference` enum lives in `PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift` (sibling to `AppSettings` itself), not `Models.swift`. Reasoning: tightly coupled to `AppSettings` persistence; not used by other domain layers; matches Phase 16/18 pattern of placing settings-only enums next to `AppSettings`. Cases: `.system`, `.light`, `.dark`. Backing raw value: `String` (`"system"` / `"light"` / `"dark"`). Computed `var colorScheme: ColorScheme?` returns `nil` for `.system`, `.light` for `.light`, `.dark` for `.dark`.
- **D-09:** Persistence follows the existing `AppSettings` `didSet` → `UserDefaults.standard.set(_:forKey:)` pattern verbatim. UserDefaults key: `"appearancePreference"` (raw string). Read in `init()` via `UserDefaults.standard.string(forKey:)` with fallback to `.system` when key absent or rawValue invalid. Matches `dictationHotkeyMode` precedent (AppSettings.swift:78).

### Claude's Discretion

- **NSAppearance observation hookup site** — planner picks where in `DictationWindowController` (init, `setContent`, or a dedicated `applyAppearance` helper) the AppSettings observation is wired. Suggested: a small `applyAppearance(_ pref:)` helper invoked from init AND from a withObservationTracking loop / Combine sink driven by AppSettings changes; mirrors the existing `applyScreenShareVisibility` pattern in `PSTranscribeApp`.
- **MenuBarExtra label scope** — `.preferredColorScheme` on the `label:` view affects the menu's hosted SwiftUI content. If menu rendering looks wrong for some preference (it draws inside the system menu bar's own appearance), planner may scope the modifier narrower (drop the label-side application). Acceptance criterion is "every visible window/surface re-renders" — the menu bar icon itself is system-rendered, not app-controlled, so this is a tolerated gap.
- **Picker option order in code** — SPEC suggests `.system, .light, .dark` enum order; SettingsView Picker order matches. Planner may reorder if SwiftUI rendering surfaces an issue (no known issue).
- **`.system` resolution for NSPanel observation** — when preference is `.system`, panel.appearance is set to `nil` and the panel inherits `NSApp.effectiveAppearance`. Planner verifies via UAT that flipping macOS appearance live (System Settings > Appearance) re-renders the HUD without app restart. If not, planner falls back to explicit observation of `NSApp.effectiveAppearance` via KVO.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 21 specs

- `.planning/phases/21-appearance-override/21-SPEC.md` — Locked requirements, boundaries, acceptance criteria. **MUST read before planning.** Note: SPEC #4's "exactly ONE hit" gate is superseded by D-06 in this CONTEXT.md; planner updates SPEC inline or documents the deviation in 21-VERIFICATION.md.

### Source files in scope

- `PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift` — Add `AppearancePreference` enum + `appearancePreference: AppearancePreference` property with `didSet` → UserDefaults write, init read with `.system` fallback. Pattern reference: `dictationHotkeyMode` at line 77–78.
- `PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift` — Add `.preferredColorScheme(settings.appearancePreference.colorScheme)` to ContentView (WindowGroup), SettingsView (Settings scene), and MenuBarExtra label (lines 142, 168, 176 region). Three call-sites total, all in this file.
- `PSTranscribe/Sources/PSTranscribe/App/DictationWindowController.swift` — Wire NSPanel.appearance observation against `AppSettings.appearancePreference`. NSHostingView root is set at line 66; `setContent(_:)` at line 95 is reused, but appearance lives on the NSPanel container, not the SwiftUI rootView.
- `PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift` — Insert `Section("Appearance")` at the top of the `Form` (before line 30's `Section("Audio Input")`). Picker style = default `.menu`, `.font(.system(size: 12))`.

### Project planning context

- `.planning/PROJECT.md` — v1.2 milestone goal includes "full dark-mode parity so every surface respects the system appearance." Phase 21 extends v1.2 with user override (D-01).
- `.planning/REQUIREMENTS.md` — v1.2 milestone goal (same).
- `.planning/STATE.md` — Currently shows `milestone: v1.2 status: completed`. D-01 reopens it for Phase 21.
- `.planning/ROADMAP.md` — Phase 21 entry must be added under v1.2 by `/gsd-plan-phase` orchestrator (or manually before planning).
- `.planning/codebase/CONVENTIONS.md` — Swift 6.2 + macOS 26 + strict concurrency. `NSAppearance(named:)` and `NSWindow.appearance` available without back-deployment guards.

### Prior phase context

- `.planning/phases/20-dark-mode-parity/20-CONTEXT.md` — Locks the unified light+dark token palette and the override-removal invariant Phase 21 builds on. D-08 there ("Migration ships in three waves...") established the post-Wave-3 baseline (zero `.preferredColorScheme` calls outside `#Preview`) which Phase 21 deliberately augments with N call-sites at app root.
- `.planning/phases/20-dark-mode-parity/20-CONTEXT.md` `<deferred>` — explicitly captures "User-facing app theme override ('Force Light' / 'Force Dark' preference in Settings) — Explicit out-of-scope per SPEC.md. Capture for backlog if user demand emerges." Phase 21 is the closing of that backlog item.
- `.planning/phases/18-hotkey-dictation-plain-folder-output/18-CONTEXT.md` D-03 — Locks DictationHUD as native `.hudWindow` vibrancy. D-07 here uses `NSAppearance` (the AppKit-native API for AppKit-owned panels) so vibrancy material adapts correctly; HUD aesthetic is preserved.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`AppSettings` `didSet` → UserDefaults pattern** (Settings/AppSettings.swift:6–115) — every existing typed property follows the same shape. `appearancePreference` slots in unchanged. Init-side decode: `UserDefaults.standard.string(forKey:)` + `AppearancePreference(rawValue:)` + `?? .system`.
- **`dictationHotkeyMode` precedent** (Settings/AppSettings.swift:77–78) — String-rawValue enum stored in UserDefaults via the same `didSet` pattern. Phase 21 mirrors this verbatim, no new persistence machinery.
- **Phase 20 `Color(light:dark:)` token system** (Design/DesignTokens.swift, Phase 20 D-01) — every surface already adapts correctly to `colorScheme`. Phase 21 only adds the OVERRIDE that drives `colorScheme`; no token churn, no DesignTokens.swift edits.
- **`applyScreenShareVisibility` observation pattern** (PSTranscribeApp.swift:152) — established pattern for AppSettings → AppKit window mutation. D-07's NSPanel.appearance hookup mirrors this shape.

### Established Patterns

- **`@Observable` `AppSettings` injected at app scope** — `PSTranscribeApp` constructs `AppSettings()` once (line 21) and passes it to ContentView/SettingsView. New `appearancePreference` reads/writes flow through the same instance; SwiftUI re-renders on change automatically.
- **Three-Scene SwiftUI app** — `WindowGroup` (main) + `Settings` (Cmd+,) + `MenuBarExtra` (status item). `.preferredColorScheme` applies per-Scene; D-05 covers all three uniformly.
- **AppKit-owned auxiliary windows** — `DictationWindowController` is the precedent for app-managed windows outside the SwiftUI scene graph. Same pattern (observe AppSettings → mutate NSWindow property) is the AppKit-native escape hatch that D-07 uses for appearance.
- **macOS 26 / SwiftUI 6 / Swift 6.2 strict concurrency** — `.preferredColorScheme(_:)`, `NSAppearance(named:)`, `NSWindow.appearance`, `NSApp.effectiveAppearance` all available without back-deployment guards. `@MainActor`-isolated `AppSettings` reads from any view body are safe.

### Integration Points

- **Settings → AppSettings → SwiftUI scene root** — user picks in SettingsView Picker; `didSet` writes UserDefaults; `@Observable` re-emits; PSTranscribeApp.body re-evaluates each Scene with new `colorScheme`; SwiftUI re-renders all views in WindowGroup + Settings.
- **AppSettings → DictationWindowController NSPanel** — D-07 observation. When AppSettings.appearancePreference changes, controller computes `NSAppearance?` and assigns `panel.appearance`. Live, no app restart.
- **MenuBarExtra label** — `.preferredColorScheme` on the SwiftUI label view affects the SwiftUI content rendered inside the menu (when opened). The status-bar icon itself is rendered by AppKit's status bar machinery, which respects `NSApp.effectiveAppearance`; no per-preference rendering is expected for the icon glyph (acknowledged in Claude's Discretion).
- **`#Preview` blocks** — unaffected. Phase 20 invariant ("zero `preferredColorScheme(` outside `#Preview`") becomes "zero outside `#Preview` AND outside `PSTranscribeApp.swift`."

</code_context>

<specifics>
## Specific Ideas

- **Bundle Phase 21 inside v1.2.** User chose to extend v1.2 rather than open v1.3 or ship as v1.2.1 hotfix. Dark-mode parity + user override ship as one milestone story (D-01).
- **Top placement, above Audio Input.** User chose maximum discoverability over SPEC's "between Audio Input and Local File" default. Appearance is the first thing the user sees when opening Settings (D-03).
- **`.menu` Picker, "System / Light / Dark" labels.** SPEC defaults preserved; explicit rejection of `.segmented` and of Apple's "Auto" wording. Matches Microphone Picker style and avoids `Auto`-as-schedule confusion.
- **NSAppearance is the right hammer for NSPanel.** User accepted that `.preferredColorScheme` is a SwiftUI-scene tool and `NSAppearance` is the AppKit-native equivalent for the AppKit-owned HUD panel. Two coverage paths, neither violates the "no view-level override" intent.
- **SPEC #4 wording acknowledged as overrestrictive.** D-06 explicitly relaxes the gate from "exactly one hit" to "all hits in PSTranscribeApp.swift, all reading AppSettings." Verifier audits source + location, not count.

</specifics>

<deferred>
## Deferred Ideas

- **Per-window / per-feature appearance overrides** — Out of scope per SPEC.md ("Dark sidebar, light editor"). Future phase if demand emerges.
- **Auto-schedule (light during work hours, dark at night)** — Out of scope; macOS `Auto` + `.system` preference cover it for free.
- **Custom theme editor / palette picker / accent-color customization** — Out of scope; Phase 21 is mode override only, not theme authoring.
- **Per-app hotkey / per-app appearance** — Different feature class; backlog.
- **Designer-tuned dark Chronicle pass** — Phase 20 deferred this. Still deferred. Phase 21 reuses the Phase 20 token system unchanged.
- **WCAG / accessibility-mode appearance support** (Increase Contrast, Reduce Transparency, High Contrast) — Out of scope per SPEC.md. Belongs in a dedicated accessibility phase.
- **Automated visual-regression tests for the override** — Phase 20 deferred snapshot testing. Phase 21 verification is manual UAT only (SPEC acceptance criteria).
- **Marketing site (`/website`) appearance toggle** — Marketing site stays light-only by milestone decision.

</deferred>

---

*Phase: 21-appearance-override*
*Context gathered: 2026-05-01*
