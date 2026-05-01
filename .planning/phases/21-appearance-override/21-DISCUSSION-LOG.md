# Phase 21: appearance-override - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-01
**Phase:** 21-appearance-override
**Areas discussed:** Milestone placement, Picker style + section placement, Copy / labels, App-root scene + HUD coverage, Grep-gate reconciliation

---

## Milestone placement

| Option | Description | Selected |
|--------|-------------|----------|
| Bundle into v1.2 | Reopen v1.2 (currently `completed` in STATE.md). Adds a 6th phase before tagging. Ships dark-mode-parity + user override as one v1.2 story. | ✓ |
| v1.3 polish milestone (Recommended) | Tag v1.2 as-is, open v1.3 with Phase 21 first. SPEC's default suggestion. | |
| Standalone hotfix outside milestones | Treat as v1.2.1 point release without opening v1.3. Lighter ceremony. | |

**User's choice:** Bundle into v1.2.
**Notes:** User overrode the recommended option. Dark-mode parity and user appearance override are one product story; shipping them together is preferred over splitting v1.2/v1.3.

---

## Picker style

| Option | Description | Selected |
|--------|-------------|----------|
| `.menu` (Recommended) | Dropdown matching Microphone Picker; consistent typography (12pt). SPEC default. | ✓ |
| `.segmented` | Three buttons in a row, faster to scan/click. New control type to Settings. | |

**User's choice:** `.menu`.
**Notes:** Consistency with adjacent Microphone Picker won.

---

## Section placement

| Option | Description | Selected |
|--------|-------------|----------|
| Top — above Audio Input | First section visible. Highest discoverability. | ✓ |
| After Audio Input (Recommended) | Between Audio Input and Local File. SPEC default. | |
| Adjacent to Privacy | Group with Privacy as 'app-level system behavior.' | |
| Bottom — below Dictation | Last section. Tail preference. | |

**User's choice:** Top — above Audio Input.
**Notes:** User overrode the recommended option. Discoverability over SPEC's IA suggestion.

---

## Copy / labels

| Option | Description | Selected |
|--------|-------------|----------|
| System / Light / Dark (SPEC default) | "Appearance" section/picker, options "System", "Light", "Dark". | ✓ |
| Match macOS / Light / Dark | "Match macOS" instead of "System" for the default. | |
| Apple convention: Light / Dark / Auto | Mirror System Settings ordering and "Auto" wording. | |

**User's choice:** System / Light / Dark.
**Notes:** Avoids confusion with macOS `Auto` (sunset/sunrise schedule); explicit per-app override semantic.

---

## App-root call-site location

| Option | Description | Selected |
|--------|-------------|----------|
| PSTranscribeApp.body — each Scene's root (Recommended) | Apply `.preferredColorScheme(...)` to ContentView (WindowGroup), SettingsView (Settings scene), and MenuBarExtra label. Three call-sites, all in PSTranscribeApp.swift. | ✓ |
| PSTranscribeApp.body — single shared modifier | Wrap each Scene's content in an `AppearanceContainer` helper that applies `.preferredColorScheme` once internally. Grep returns literally 1 hit. | |
| ContentView root only | Match the location Phase 20 removed (ContentView.swift:251). Does NOT cover Settings or MenuBarExtra. | |

**User's choice:** Each Scene's root in PSTranscribeApp.body.
**Notes:** No new abstraction added; trade-off was accepting N grep hits in exchange for simpler call-sites. Reconciled with SPEC #4 in the next discussion turn.

---

## DictationHUD coverage

| Option | Description | Selected |
|--------|-------------|----------|
| NSPanel.appearance observation (Recommended) | Set `panel.appearance = NSAppearance(named:)` from AppSettings observation. Native AppKit API for AppKit-owned panel; vibrancy material flips correctly. | ✓ |
| Environment injection on rootView | Wrap `rootView.environment(\.colorScheme, resolvedScheme)` at NSHostingView mount. Pure SwiftUI path; `.environment(\.colorScheme)` doesn't drive NSPanel vibrancy. | |
| Mount HUD as a SwiftUI Window scene | Convert DictationWindowController to a SwiftUI Window. Significant Phase 18 refactor. | |

**User's choice:** NSPanel.appearance observation.
**Notes:** Right hammer for the AppKit-owned panel; preserves Phase 18 D-04/D-05 (NSPanel + .nonactivatingPanel + .hudWindow vibrancy).

---

## Grep-gate reconciliation

| Option | Description | Selected |
|--------|-------------|----------|
| Relax SPEC #4 — N hits, all at app root (Recommended) | Update acceptance: grep returns N hits, ALL inside PSTranscribeApp.body, ALL reading `settings.appearancePreference.colorScheme`. Verifier checks location + source, not count. | ✓ |
| Single shared modifier — 1 hit, helper view | Introduce `AppearanceContainer { content }` ViewModifier with `.preferredColorScheme` once internally. Honors SPEC #4 verbatim; adds abstraction. | |

**User's choice:** Relax SPEC #4.
**Notes:** SPEC #4 was written before scene-graph fan-out was analyzed. Intent ("no view-level overrides") preserved; gate becomes location+source check. Planner updates SPEC inline or documents in 21-VERIFICATION.md.

---

## Claude's Discretion

- **NSAppearance observation hookup site** in DictationWindowController — planner picks init / setContent / dedicated `applyAppearance` helper. Suggested: mirror existing `applyScreenShareVisibility` pattern.
- **MenuBarExtra label scope** — `.preferredColorScheme` on the label affects the SwiftUI menu content; the status-bar icon itself is system-rendered. Planner may scope narrower if the label-side application looks wrong; menu bar icon glyph is a tolerated gap.
- **Picker option order in code** — matches enum order `.system, .light, .dark`. Reorder permitted if rendering surfaces an issue.
- **`.system` resolution on NSPanel** — `panel.appearance = nil` should inherit `NSApp.effectiveAppearance`. UAT verifies live macOS appearance flips re-render the HUD; KVO fallback if not.

## Deferred Ideas

- Per-window / per-feature appearance overrides (Dark sidebar, light editor) — backlog.
- Auto-schedule (light during work hours, dark at night) — covered by macOS `Auto` + `.system`.
- Custom theme editor / palette picker / accent-color customization — backlog.
- Per-app hotkey / per-app appearance — different feature class.
- Designer-tuned dark Chronicle pass — deferred from Phase 20, still deferred.
- WCAG / High Contrast / Reduce Transparency / Increase Contrast support — accessibility phase.
- Automated visual-regression tests for the override — manual UAT only this phase.
- Marketing site (`/website`) appearance toggle — light-only by milestone decision.
