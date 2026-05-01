# Phase 21: User-Controlled Appearance Preference — Verification

**Date:** 2026-05-01
**Status:** ALL PASS — Phase 21 verified end-to-end (Plan 21-03 Tasks 1-3 complete)
**Build:** `f4b2faf` (Plan 21-03 Task 1 audit commit; Plan 21-02 implementation HEAD `2a88997`)

## Automated Audit

### Relaxed D-06 Grep Gate

CONTEXT.md **D-06** explicitly relaxes SPEC.md acceptance criterion **#4** from "exactly ONE hit outside `#Preview` blocks" to **"N hits, all inside `PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift`, all reading `settings.appearancePreference.colorScheme`."** Verifier audits **location + source**, not count.

This deviation is intentional and locked. Phase 21 ships with three call-sites in `PSTranscribeApp.swift` (one per Scene root: `WindowGroup` ContentView, `Settings` scene, `MenuBarExtra` menu content) — see CONTEXT.md **D-05** for the rationale.

A single non-runtime hit also exists in `AppSettings.swift:9` — a `///` doc comment inside the `AppearancePreference` enum's documentation block, introduced by Plan 21-01. Doc comments are not runtime call-sites; the relaxed gate's intent is that no view, sheet, or panel adds its own override. After excluding `///` lines the gate returns zero hits outside `PSTranscribeApp.swift`. Both forms (with and without `///` exclusion) are captured below for transparency.

#### Audit transcript

```
$ grep -rn 'preferredColorScheme(' PSTranscribe/Sources --include='*.swift' | grep -v '#Preview' | grep -v 'PSTranscribeApp.swift' || echo "[no matches — relaxed D-06 gate passes]"
PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift:9:/// `.system` is the default and resolves to `nil` so `.preferredColorScheme(nil)`
```

```
$ grep -rn 'preferredColorScheme(' PSTranscribe/Sources --include='*.swift' | grep -v '#Preview' | grep -v 'PSTranscribeApp.swift' | grep -v '///' || echo "[no matches — relaxed D-06 gate passes after /// exclusion]"
[no matches — relaxed D-06 gate passes after /// exclusion]
```

```
$ grep -n '\.preferredColorScheme(settings\.appearancePreference\.colorScheme)' PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift
163:                .preferredColorScheme(settings.appearancePreference.colorScheme)
185:            .preferredColorScheme(settings.appearancePreference.colorScheme)
197:            .preferredColorScheme(settings.appearancePreference.colorScheme)
```

Three runtime call-sites in `PSTranscribeApp.swift`, all reading `settings.appearancePreference.colorScheme` (D-05 satisfied).

```
$ grep -rnE '\.preferredColorScheme\(\s*\.(light|dark)\s*\)' PSTranscribe/Sources --include='*.swift' | grep -v '#Preview' || echo "[no hardcoded overrides outside #Preview — passes]"
[no hardcoded overrides outside #Preview — passes]
```

No hardcoded `.preferredColorScheme(.light)` / `.preferredColorScheme(.dark)` runtime call-sites anywhere outside `#Preview` blocks. Every override flows through `settings.appearancePreference.colorScheme`.

### Structural greps

```
$ grep -n 'enum AppearancePreference: String' PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift
14:enum AppearancePreference: String, CaseIterable, Identifiable, Sendable {
```

`AppearancePreference` enum lives in `AppSettings.swift` at file scope (D-08 satisfied), with `String` raw values + `CaseIterable` + `Identifiable` + `Sendable` conformance.

```
$ grep -n 'appearancePreference' PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift
118:    /// UserDefaults key `"appearancePreference"`.
119:    var appearancePreference: AppearancePreference {
120:        didSet { UserDefaults.standard.set(appearancePreference.rawValue, forKey: "appearancePreference") }
121:    }
196:        let appearanceRaw = defaults.string(forKey: "appearancePreference")
198:        self.appearancePreference = AppearancePreference(rawValue: appearanceRaw) ?? .system
```

`AppSettings.appearancePreference` stored property at line 119 with `didSet` UserDefaults write at line 120 under key `"appearancePreference"`. Init-side decode at lines 196 + 198 with `?? .system` fallback (D-09 + Req 6 invisible migration satisfied).

```
$ grep -n 'panel\.appearance\|NSAppearance(named:' PSTranscribe/Sources/PSTranscribe/App/DictationWindowController.swift
108:    /// `panel.appearance` flips both the chrome and the `NSVisualEffectView`'s
114:        case .system: panel.appearance = nil
115:        case .light:  panel.appearance = NSAppearance(named: .aqua)
116:        case .dark:   panel.appearance = NSAppearance(named: .darkAqua)
```

`DictationWindowController.applyAppearance(_:)` maps the three `AppearancePreference` cases to `panel.appearance` via `NSAppearance(named:)` (D-07 satisfied). `.system` → `nil` (panel inherits `NSApp.effectiveAppearance`), `.light` → `.aqua`, `.dark` → `.darkAqua`.

```
$ grep -n 'Section("Appearance")\|Picker("Appearance"' PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift
30:            Section("Appearance") {
31:                Picker("Appearance", selection: $settings.appearancePreference) {
```

`SettingsView` has `Section("Appearance")` at line 30 containing a `Picker("Appearance", selection: $settings.appearancePreference)` at line 31 (D-02 / D-04 satisfied).

```
$ APPEARANCE_LINE=$(grep -n 'Section("Appearance")' PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift | head -1 | cut -d: -f1)
$ AUDIO_LINE=$(grep -n 'Section("Audio Input")' PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift | head -1 | cut -d: -f1)
$ echo "Appearance section at line $APPEARANCE_LINE; Audio Input section at line $AUDIO_LINE"
Appearance section at line 30; Audio Input section at line 39
$ [ "$APPEARANCE_LINE" -lt "$AUDIO_LINE" ] && echo "PASS: Appearance is above Audio Input" || echo "FAIL: ordering wrong"
PASS: Appearance is above Audio Input
```

`Section("Appearance")` (line 30) is strictly above `Section("Audio Input")` (line 39) — D-03 top-placement invariant satisfied.

### Build status

```
$ cd PSTranscribe && swift build 2>&1 | tail -5
[0/1] Planning build
Building for debugging...
[0/3] Write swift-version--58304C5D6DBC2206.txt
Build complete! (0.26s)
```

`swift build` exits 0 with zero errors and zero new warnings. Phase 21's incremental build over Plan 21-02's HEAD is a no-op (`0.26s`), confirming no source files have drifted since the last green build.

## Manual UAT

Performed against build `f4b2faf` on 2026-05-01. User response: **approved** (all eight scenarios pass).

- [x] **Scenario A** — Live toggle while macOS in Dark mode: setting Appearance to Light flipped the main window, Settings window, DictationHUD vibrancy, and MenuBarExtra menu content within ~1s. PASS.
- [x] **Scenario B** — Live toggle while macOS in Light mode: setting Appearance to Dark flipped all four surfaces within ~1s. PASS.
- [x] **Scenario C** — Revert to System: reverts immediately; macOS Light↔Dark toggles propagate live to all surfaces. PASS.
- [x] **Scenario D** — Persistence across relaunch: quit + relaunch with Dark/Light preference launches in chosen mode immediately, Picker reflects stored value. PASS.
- [x] **Scenario E** — Fresh-install / wiped UserDefaults: `defaults delete com.newfeldt.PSTranscribe appearancePreference` followed by relaunch shows System mode, Picker reads "System", no crash. Req 6 invisible migration confirmed. PASS.
- [x] **Scenario F** — Default-state pixel stability: with preference = System, post-Phase-21 build is visually indistinguishable from post-Phase-20 baseline (commit `f9f2139`) across light/dark macOS settings. PASS.
- [x] **Scenario G** — DictationHUD live re-render: HUD flips vibrancy live (`.system` → `.light` → `.dark` → `.system`) without dismiss/re-show; `.system` path correctly inherits `NSApp.effectiveAppearance` on live macOS toggle (no KVO fallback needed). PASS.
- [x] **Scenario H** — MenuBarExtra menu content: dropdown content flips per preference. Status bar icon glyph (system-rendered) is the tolerated gap per CONTEXT.md Claude's Discretion — not a failure. PASS.

## SPEC.md Acceptance Criteria Status

| # | Criterion (verbatim from SPEC.md) | Verified by | Status |
|---|------------------------------------|-------------|--------|
| 1 | `AppearancePreference` enum defined with `.system`, `.light`, `.dark` cases and a `colorScheme: ColorScheme?` computed property (returns `nil` for `.system`) | Plan 21-01 grep gate (Task 1 audit transcript: enum + colorScheme greps) | [x] |
| 2 | `AppSettings.appearancePreference` property exists, persists via UserDefaults key `"appearancePreference"`, defaults to `.system` when key absent | Plan 21-01 grep gate (`appearancePreference` property + `didSet` + init `?? .system` greps) + Manual UAT Scenario E (fresh install) | [x] |
| 3 | `grep -rn "preferredColorScheme(" PSTranscribe/Sources` returns exactly ONE hit outside `#Preview` blocks; that hit reads from `settings.appearancePreference.colorScheme` | **SUPERSEDED by D-06** — see Relaxed D-06 Grep Gate above. Audit confirms 3 runtime hits, all in `PSTranscribeApp.swift` (lines 163, 185, 197), all reading `settings.appearancePreference.colorScheme` | [x] (note: see D-06 relaxation — location+source, not count) |
| 4 | `SettingsView` shows an "Appearance" section with a three-option Picker bound to the settings property | Task 1 audit transcript (`Section("Appearance")` at line 30 + `Picker("Appearance", selection: $settings.appearancePreference)` at line 31) + Manual UAT pre-flight | [x] |
| 5 | `swift build` clean, zero new warnings | Task 1 audit (build transcript: `Build complete! (0.26s)`, exit 0, zero warnings) | [x] |
| 6 | Manual UAT — change picker to Light while macOS is Dark: app renders Light immediately, no restart | Manual UAT Scenario A | [x] |
| 7 | Manual UAT — change picker to Dark while macOS is Light: app renders Dark immediately, no restart | Manual UAT Scenario B | [x] |
| 8 | Manual UAT — change picker back to System: app reverts to following macOS appearance immediately | Manual UAT Scenario C | [x] |
| 9 | Manual UAT — quit + relaunch with non-System preference: app launches in the chosen mode | Manual UAT Scenario D | [x] |
| 10 | Manual UAT — first launch with no `appearancePreference` key (simulate via `defaults delete`): app launches in System mode, picker shows "System" | Manual UAT Scenario E | [x] |
| 11 | Visual parity — with preference = System, post-Phase-21 build matches post-Phase-20 build on all 10 surfaces in both light and dark macOS settings | Manual UAT Scenario F | [x] |

## Phase 21 Sign-Off

- **Build:** `f4b2faf` (Plan 21-03 Task 1 audit commit; implementation HEAD `2a88997`)
- **Date:** 2026-05-01
- **Outcome:** **ALL PASS**
- **Notes / deferred items:**
  - **Tolerated gap (per CONTEXT.md Claude's Discretion):** The MenuBarExtra status bar icon glyph (`mic.fill` / `book.closed`) is system-rendered by AppKit's `NSStatusItem` machinery and inherits `NSApp.effectiveAppearance`, not the per-app `.preferredColorScheme`. Glyph does not flip when the preference diverges from macOS appearance. The dropdown menu *content* (Text/Divider/Quit) does flip correctly. This was an acknowledged gap in CONTEXT.md and is not a regression.
  - **NSPanel `.system` resolution:** Scenario G step 8 confirmed that `panel.appearance = nil` on the DictationHUD correctly inherits `NSApp.effectiveAppearance` on live macOS Light↔Dark toggle without any additional plumbing. The KVO fallback option flagged in CONTEXT.md Claude's Discretion was **not needed**.
  - **Deferred to backlog (carried forward from CONTEXT.md `<deferred>`):** Automated visual-regression / snapshot testing for the override; designer-tuned dark Chronicle pass. Both remain backlog items; Phase 21 verification stays manual UAT only as planned.

## D-01 milestone state update

Per CONTEXT.md **D-01**, with Phase 21 complete the milestone v1.2 state flips from `in_progress` back to `completed`. The orchestrator owns the following follow-up writes (NOT this plan's responsibility):

- [ ] Update `.planning/STATE.md` frontmatter `status: completed` and increment plan counters (33/33 = 100%)
- [ ] Update `.planning/ROADMAP.md` Phase 21 row to `[x] Complete` with completion date `2026-05-01`; tick `21-03-PLAN.md` checkbox in the Phase 21 Plans list; update Progress Table row to `3/3 Complete 2026-05-01`
- [ ] Tag `v1.2` in git when the milestone is ready to release (separate ship gate; not part of this plan)

(These follow-ups are captured here so the orchestrator picks them up after Plan 21-03's metadata commit lands.)
