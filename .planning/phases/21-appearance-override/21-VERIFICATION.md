# Phase 21: User-Controlled Appearance Preference — Verification

**Date:** 2026-05-01
**Status:** AUTOMATED AUDIT PASSED — manual UAT pending (Task 2 of Plan 21-03)
**Build:** `2a88997` (HEAD at audit time)

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

(Filled in by Task 2.)

## SPEC.md Acceptance Criteria Status

(Filled in by Task 3.)
