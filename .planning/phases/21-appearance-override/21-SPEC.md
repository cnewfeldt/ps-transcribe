# Phase 21: User-Controlled Appearance Preference — Specification

**Created:** 2026-05-01
**Ambiguity score:** 0.12 (gate: ≤ 0.20)
**Requirements:** 6 locked
**Status:** Draft — pending milestone placement (v1.2 polish vs v1.3 candidate)

## Goal

Add a three-way appearance preference (System / Light / Dark) to `SettingsView` that overrides the system color scheme app-wide. Default is `System`, which preserves Phase 20's system-following behavior byte-for-byte. The preference is persisted via `AppSettings` → `UserDefaults` and applied at the SwiftUI app root through `.preferredColorScheme(preference.colorScheme)` where `System` resolves to `nil` (no override).

## Background

Phase 20 (dark-mode-parity) shipped a unified light+dark token palette and removed all forced `.preferredColorScheme` overrides. The app now follows `System Settings > Appearance` everywhere, including Light / Dark / Auto.

Phase 20's SPEC explicitly excluded a user-facing override: *"A user-facing app preference to override system appearance ('Force Light' / 'Force Dark' toggle) — phase delivers system-following behavior only."*

Some users want to pin the app to one mode independent of the OS — e.g., dark editor, light app for screen-sharing. Phase 21 closes that gap. The token system from Phase 20 is the structural prerequisite (every surface already adapts correctly to `colorScheme`), so this phase is a thin UI + state-plumbing slice on top of an already-adaptive palette.

## Requirements

1. **Persisted preference enum**: A typed `AppearancePreference` enum with `.system`, `.light`, `.dark` cases is stored in `AppSettings` and survives app restart.
   - Current: No appearance preference exists in `AppSettings`; the app inherits whatever `colorScheme` SwiftUI passes from the system.
   - Target: `AppSettings` exposes `var appearancePreference: AppearancePreference` backed by `UserDefaults` key `"appearancePreference"` (raw string `"system" | "light" | "dark"`). The `didSet` writes through to `UserDefaults` matching the existing `AppSettings` pattern. Default value on first launch: `.system`.
   - Acceptance: `grep -n "appearancePreference" PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift` shows the property + UserDefaults read/write; quitting and relaunching preserves the user's selection.

2. **App-root override application**: The preference is applied at the SwiftUI scene root so every surface (main window, capture dock, Settings, NotionTagSheet, OnboardingView, DictationHUD) receives it.
   - Current: No `.preferredColorScheme(_:)` calls exist outside `#Preview` blocks (Phase 20 invariant).
   - Target: A single `.preferredColorScheme(settings.appearancePreference.colorScheme)` modifier is added at the SwiftUI scene/root view (likely `PSTranscribeApp.body` or `ContentView` root). `AppearancePreference.colorScheme` returns `nil` for `.system`, `.light` for `.light`, `.dark` for `.dark`. Passing `nil` is a no-op (no override), preserving Phase 20 behavior on default.
   - Acceptance: Setting preference to `.light` while macOS is in Dark mode forces the app to render light; setting to `.dark` while macOS is in Light mode forces dark; setting to `.system` immediately reverts to system-following without app restart.

3. **Settings UI — three-way Picker**: User can select the preference in `SettingsView` with no app restart required.
   - Current: `SettingsView.swift` has no appearance section.
   - Target: A new `Section("Appearance")` (placement: between "Audio Input" and existing "Local File" sections, or wherever fits the existing Settings information architecture) contains a `Picker` bound to `settings.appearancePreference` with three options: "System" (default, "Match macOS"), "Light", "Dark". Style: `.segmented` or `.menu` — pick whichever is consistent with adjacent pickers in the file (`Microphone` Picker uses default style, so match it).
   - Acceptance: Manual UAT — open Settings, change selection, every visible window re-renders immediately without quitting/relaunching the app.

4. **Phase 20 invariants preserved**: The grep gate from Phase 20 stays clean except for the single intentional new call-site.
   - Current: `grep -rn "preferredColorScheme(" PSTranscribe/Sources` returns zero hits outside `#Preview` blocks.
   - Target: `grep -rn "preferredColorScheme(" PSTranscribe/Sources` returns exactly ONE hit outside `#Preview` blocks — the new app-root override that reads from `settings.appearancePreference.colorScheme`. No other view, sheet, or panel adds its own `.preferredColorScheme` call.
   - Acceptance: Grep audit + manual review confirms the single new call-site is at the app root and reads from `AppSettings`, not a hardcoded value.

5. **Default-state pixel stability**: With preference set to `.system` (the default), the app is visually indistinguishable from the post-Phase-20 build.
   - Current: Post-Phase-20 build follows system appearance everywhere with no override.
   - Target: First launch (preference = `.system`) and any subsequent launch with preference = `.system` renders identically to the post-Phase-20 baseline. `.preferredColorScheme(nil)` is the SwiftUI no-op contract.
   - Acceptance: Manual side-by-side — launch the post-Phase-20 build and the post-Phase-21 build with default settings; toggle System Settings > Appearance Light → Dark → Light on both; rendering is identical on every surface.

6. **Migration is invisible**: Existing users (post-Phase-20 installs without `appearancePreference` in their UserDefaults) see no behavior change after the Phase 21 update.
   - Current: Existing installs have no `appearancePreference` key in UserDefaults.
   - Target: `AppSettings` reads the key with a default of `.system` if missing. Users who never open Settings see Phase 20 behavior unchanged. Users who DO open Settings see the new picker pre-selected to "System".
   - Acceptance: Launch the Phase 21 build with a fresh-from-Phase-20 UserDefaults plist (or a wiped plist); no crash, no visible change, picker shows "System".

## Boundaries

**In scope:**
- New `AppearancePreference` enum (likely in `AppSettings.swift` or a sibling file under `Settings/`)
- New `appearancePreference` property on `AppSettings` with `UserDefaults` persistence
- New `Section("Appearance")` + `Picker` in `SettingsView`
- Single `.preferredColorScheme(_:)` call at app root reading from settings
- Manual UAT covering: Settings picker change without restart, persistence across relaunch, default-state visual parity with Phase 20

**Out of scope:**
- Per-window or per-feature appearance overrides (e.g., "Dark sidebar, light editor") — single app-wide preference only
- Appearance-aware accessibility settings (Increase Contrast, Reduce Transparency, High Contrast mode) — separate accessibility scope
- WCAG / contrast ratio re-verification — Phase 20's palette already passes within Chronicle's design intent; user-facing override does not change contrast within either mode
- Marketing site (`/website`) appearance toggle — marketing site stays light-only by milestone decision
- Custom theme editor / palette picker / accent-color customization — scope is mode override only, not theme authoring
- Auto-schedule (e.g., "Light during work hours, Dark at night") — macOS Auto already provides sunset/sunrise; users can use System mode + macOS Auto to get this for free
- DictationHUD vibrancy override — `.hudWindow` material is system-controlled and adapts via the chosen `colorScheme`; no separate HUD-only override

**Adjacent but excluded:**
- Settings IA restructuring beyond adding the new section — owned by future polish phases
- AppSettings refactor to a Codable settings struct — out of scope; new property follows existing `didSet` → `UserDefaults.set(_:forKey:)` pattern

## Constraints

- **Phase 20 invariant: exactly one `.preferredColorScheme` call-site outside `#Preview` blocks.** The new override at app root is the single permitted exception. No view-level or sheet-level overrides may be added.
- **Default = `.system`.** First-run users and existing installs without the key see Phase 20 behavior, byte-for-byte.
- **Live application — no relaunch required.** Changing the picker updates SwiftUI state immediately; the app re-renders all surfaces without quitting.
- **Persistence path matches existing AppSettings convention.** Use `UserDefaults.standard.set(...)` in `didSet` and read with `UserDefaults.standard.string(forKey:)` (or equivalent typed accessor) in init. No separate persistence layer.
- **macOS deployment target unchanged.** `.preferredColorScheme(_:)` and the underlying SwiftUI scene plumbing must work on the project's existing minimum macOS version.
- **No telemetry on preference changes.** Hard project constraint — no telemetry, ever.

## Acceptance Criteria

- [ ] `AppearancePreference` enum defined with `.system`, `.light`, `.dark` cases and a `colorScheme: ColorScheme?` computed property (returns `nil` for `.system`)
- [ ] `AppSettings.appearancePreference` property exists, persists via UserDefaults key `"appearancePreference"`, defaults to `.system` when key absent
- [ ] `grep -rn "preferredColorScheme(" PSTranscribe/Sources` returns exactly ONE hit outside `#Preview` blocks; that hit reads from `settings.appearancePreference.colorScheme`
- [ ] `SettingsView` shows an "Appearance" section with a three-option Picker bound to the settings property
- [ ] `swift build` clean, zero new warnings
- [ ] Manual UAT — change picker to Light while macOS is Dark: app renders Light immediately, no restart
- [ ] Manual UAT — change picker to Dark while macOS is Light: app renders Dark immediately, no restart
- [ ] Manual UAT — change picker back to System: app reverts to following macOS appearance immediately
- [ ] Manual UAT — quit + relaunch with non-System preference: app launches in the chosen mode
- [ ] Manual UAT — first launch with no `appearancePreference` key (simulate via `defaults delete`): app launches in System mode, picker shows "System"
- [ ] Visual parity — with preference = System, post-Phase-21 build matches post-Phase-20 build on all 10 surfaces in both light and dark macOS settings

## Plan Sketch (Pre-Discuss)

This is a one-plan phase, autonomous except for the final UAT step. Possible breakdown for `/gsd-discuss-phase` to ratify:

- **Plan 21-01 (autonomous):** Add `AppearancePreference` enum, extend `AppSettings`, add app-root `.preferredColorScheme` modifier, add SettingsView picker. Atomic commits per concern. `swift build` clean.
- **UAT (non-autonomous):** Manual verification of live-toggle, persistence, default-state parity, fresh-install behavior. Recorded in `21-VERIFICATION.md`.

If `/gsd-discuss-phase` surfaces a real complexity (e.g., scene-graph plumbing in a multi-window app), split into Wave 1 (state + plumbing) and Wave 2 (UI + UAT).

## Ambiguity Report

| Dimension          | Score | Min  | Status | Notes                                                                                |
|--------------------|-------|------|--------|--------------------------------------------------------------------------------------|
| Goal Clarity       | 0.95  | 0.75 | ✓      | Three-way picker, app-root override, default = System, structural prereqs met        |
| Boundary Clarity   | 0.90  | 0.70 | ✓      | Single override only; per-window / theme-editor / auto-schedule explicitly out       |
| Constraint Clarity | 0.85  | 0.65 | ✓      | One `.preferredColorScheme` call-site, default = System, no relaunch, live update    |
| Acceptance Criteria| 0.85  | 0.70 | ✓      | Grep gate + persistence test + 3-way live-toggle UAT + fresh-install simulation      |
| **Ambiguity**      | 0.12  | ≤0.20| ✓      |                                                                                      |

## Open Questions for /gsd-discuss-phase

1. **Milestone placement.** Phase 21 in v1.2 (alongside 19/20) or v1.3 (post-ship polish)? v1.2 is feature-complete; this is small but adds scope. Default suggestion: defer to v1.3 unless user wants it bundled with the dark-mode-parity ship.
2. **Picker style.** `.segmented` (3 buttons in a row, fast) vs `.menu` (dropdown, matches Microphone picker). Both work; consistency suggests `.menu`.
3. **Section placement in SettingsView.** Right after "Audio Input" (top of Settings, high visibility) or in an "Advanced" / "General" section if one is later added? D-call.
4. **Copy.** "Appearance" / "Match macOS / Light / Dark" vs "Theme" / "Auto / Light / Dark"? Apple's own Settings uses "Appearance: Light / Dark / Auto" in System Settings — match that convention.
5. **App-root location.** `PSTranscribeApp.body` (cleanest) vs `ContentView` root (matches removed override location). Either works; `PSTranscribeApp.body` covers all WindowGroups and standalone windows uniformly, which is the right call for the dictation HUD + capture dock.

## Interview Log

| Round | Perspective       | Question summary                                                | Decision locked                                                                            |
|-------|-------------------|-----------------------------------------------------------------|--------------------------------------------------------------------------------------------|
| 1     | Researcher        | Why now? Phase 20 was system-following only.                    | User-requested follow-up after Phase 20 close-out (2026-05-01); explicitly out-of-scope of 20 |
| 1     | Researcher        | What surfaces need the override?                                | All — single app-root override applies app-wide; no per-surface granularity                |
| 2     | Simplifier        | Minimum viable scope?                                           | Three-way picker, AppSettings persistence, single app-root modifier; no theme editor       |
| 2     | Boundary Keeper   | Does this touch DesignTokens.swift?                             | No — Phase 20's `Color(light:dark:)` foundation is reused unchanged                        |
| 3     | Failure Analyst   | What's the regression risk?                                     | Default-state visual parity with Phase 20; covered by acceptance gate + fresh-install UAT  |
| 3     | Failure Analyst   | Worst broken-version a verifier should reject?                  | More than one new `.preferredColorScheme` call-site, OR default-state diverges from Phase 20|
| 4     | Boundary Keeper   | Auto-schedule (light during day / dark at night)?               | Out — macOS Auto + System preference covers it for free                                    |
| 4     | Boundary Keeper   | Per-window or per-feature overrides?                            | Out — single app-wide preference only                                                       |

---

*Phase: 21-appearance-override*
*Spec created: 2026-05-01*
*Depends on: Phase 20 (dark-mode-parity) — token foundation + override-removal invariant*
*Next step: `/gsd-discuss-phase 21` to ratify milestone placement (v1.2 polish vs v1.3), picker style, section placement, copy, and app-root location*
