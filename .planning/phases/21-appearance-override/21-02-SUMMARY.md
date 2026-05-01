---
phase: 21-appearance-override
plan: 02
subsystem: app-shell
tags: [swiftui, appkit, nspanel, nsappearance, observable, colorscheme, appearance, menubarextra]

# Dependency graph
requires:
  - phase: 21-appearance-override
    plan: 01
    provides: AppearancePreference enum + AppSettings.appearancePreference stored property + colorScheme: ColorScheme? bridge
provides:
  - "Three .preferredColorScheme(settings.appearancePreference.colorScheme) call-sites at each Scene root in PSTranscribeApp.body (D-05)"
  - "DictationWindowController.applyAppearance(_:) helper mapping AppearancePreference → NSAppearance(named:) (D-07)"
  - "PSTranscribeApp re-arming withObservationTracking observeAppearance helper that mirrors AppSettings.appearancePreference onto the HUD NSPanel (D-07)"
  - "Section('Appearance') at the top of SettingsView's Form with default .menu-style Picker (D-02 / D-03 / D-04)"
affects: [21-03-PLAN]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Re-arming withObservationTracking continuation: tracked-block reads the @Observable property, onChange closure dispatches via Task { @MainActor in ... } and recursively re-calls the helper to capture the next mutation"
    - "Group { ... }.preferredColorScheme(...) wrapper for MenuBarExtra menu content closure — required because @ViewBuilder multi-statement bodies can't take a modifier directly"
    - "AppKit-bridge pattern for color scheme: NSAppearance(named: .aqua) / .darkAqua / nil mirrors the SwiftUI .preferredColorScheme behavior on AppKit-owned NSPanels that live outside the SwiftUI scene graph"

key-files:
  modified:
    - PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift -- 3 .preferredColorScheme call-sites at lines 163, 185, 197 (one per Scene root); MenuBarExtra menu content wrapped in Group at lines 188-196; observeAppearance helper at lines 215-232; init() wires initial sync apply + observation at lines 47-55
    - PSTranscribe/Sources/PSTranscribe/App/DictationWindowController.swift -- applyAppearance(_:) helper at lines 104-119 (doc comment 104-110, body 111-118)
    - PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift -- Section("Appearance") at lines 30-37 with Picker bound to $settings.appearancePreference and three Text-tag rows in System/Light/Dark order

key-decisions:
  - "MenuBarExtra menu content wrapped in Group { ... } so .preferredColorScheme attaches to the multi-statement view builder body (canonical pattern; SwiftUI rejected the bare attachment)"
  - "Status-bar Image label intentionally NOT modified — system-rendered NSStatusItem inherits NSApp.effectiveAppearance regardless of .preferredColorScheme; documented as tolerated gap per CONTEXT.md Claude's Discretion"
  - "Recursive observeAppearance call inside onChange closure rather than for-await/AsyncStream — @Observable doesn't expose AsyncSequence; withObservationTracking is the documented-by-Apple pattern (WWDC 2024 'Observation in Swift') and the loop is bounded by app lifetime"
  - "Task { @MainActor in ... } continuation in onChange rather than @MainActor.assumeIsolated — Swift 6.2 strict concurrency would reject assumeIsolated on a non-isolated closure context; Task hop is the conservative path that compiles cleanly with no measurable latency at human-click cadence"

patterns-established:
  - "Bridging an @Observable AppSettings property onto an AppKit window property: applyX(_:) helper on the controller + initial sync apply in PSTranscribeApp.init() + re-arming withObservationTracking helper. Reusable shape for any future 'AppKit-owned surface needs to mirror an AppSettings property' wiring."

requirements-completed: [SPEC.Req-2, SPEC.Req-3, SPEC.Req-4, D-02, D-03, D-04, D-05, D-06, D-07]

# Metrics
duration: ~3min
completed: 2026-05-01
---

# Phase 21 Plan 02: Wire AppearancePreference into all visible surfaces

**Three SwiftUI Scene roots in `PSTranscribeApp.body` get `.preferredColorScheme(settings.appearancePreference.colorScheme)`; the AppKit-owned Dictation HUD NSPanel observes `AppSettings.appearancePreference` and assigns `panel.appearance = NSAppearance(named:)` via a re-arming `withObservationTracking` loop; SettingsView gains a new `Section("Appearance")` at the TOP of the Form with a default `.menu`-style Picker bound to `settings.appearancePreference`.**

## Performance

- **Duration:** ~3 min (active execution wall-clock)
- **Started:** 2026-05-01T18:32:35Z
- **Completed:** 2026-05-01T18:36:10Z
- **Tasks:** 3
- **Files modified:** 3 (PSTranscribeApp.swift, DictationWindowController.swift, SettingsView.swift)

## Accomplishments

- **Three Scene-root .preferredColorScheme call-sites** wired in `PSTranscribeApp.body`:
  - `WindowGroup { ContentView ... }.preferredColorScheme(...)` at line 163
  - `Settings { SettingsView ... }.preferredColorScheme(...)` at line 185
  - `MenuBarExtra { Group { ... }.preferredColorScheme(...) }` at line 197
  All three read from `settings.appearancePreference.colorScheme`. None hardcode `.light` / `.dark` / `.none`.
- **DictationWindowController.applyAppearance(_:)** helper at lines 111-118 maps the three `AppearancePreference` cases to `NSAppearance(named: .aqua)` / `NSAppearance(named: .darkAqua)` / `nil` and assigns to `panel.appearance`. Switch is exhaustive over the three enum cases.
- **observeAppearance helper** at PSTranscribeApp.swift lines 215-232 — `@MainActor private func` that re-arms `withObservationTracking` after each `onChange` fire. Initial sync apply at line 54 (`initialWindowCtrl.applyAppearance(initialSettings.appearancePreference)`); observation install at line 55 (`observeAppearance(controller: initialWindowCtrl, settings: initialSettings)`).
- **SettingsView Section("Appearance")** at lines 30-37 — first section of the Form (line number 30 is strictly less than line 39 where Section("Audio Input") begins). Default `.menu` style Picker bound to `$settings.appearancePreference` with three rows: `Text("System").tag(.system)`, `Text("Light").tag(.light)`, `Text("Dark").tag(.dark)` in that exact order. `.font(.system(size: 12))` mirrors the adjacent Microphone Picker typography.
- **swift build clean** with zero new warnings across all three files.
- **swift test green** — all 221 tests across 40 suites pass; no regressions (`Test run with 221 tests in 40 suites passed`).

## Task Commits

Each task was committed atomically:

1. **Task 1: Three .preferredColorScheme call-sites at Scene roots (D-05)** — `70eb18f` (feat)
2. **Task 2: NSPanel.appearance observation in DictationWindowController (D-07)** — `0bed62d` (feat)
3. **Task 3: Section('Appearance') with Picker in SettingsView (D-02 / D-03 / D-04)** — `c1c21bf` (feat)

## Files Created/Modified

- **PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift** — Added 3 `.preferredColorScheme` call-sites (lines 163, 185, 197), wrapped MenuBarExtra menu content in `Group { ... }` (lines 188-196), wired initial sync apply + observation in `init()` (lines 47-55), added `observeAppearance` `@MainActor private func` helper (lines 215-232). +28 lines, -6 lines.
- **PSTranscribe/Sources/PSTranscribe/App/DictationWindowController.swift** — Added `applyAppearance(_ preference: AppearancePreference)` helper at lines 104-119 (after `setContent(_:)`, before `positionAtBottomCenter()`). +16 lines.
- **PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift** — Added `Section("Appearance")` block at lines 30-37 above `Section("Audio Input")`. +9 lines.

### Exact placement (for Plan 21-03 UAT reference)

| Element | File | Lines |
|---------|------|-------|
| WindowGroup .preferredColorScheme | PSTranscribeApp.swift | 163 |
| Settings scene .preferredColorScheme | PSTranscribeApp.swift | 185 |
| MenuBarExtra Group + .preferredColorScheme | PSTranscribeApp.swift | 188-196 / 197 (modifier line) |
| Initial sync apply (init()) | PSTranscribeApp.swift | 54 |
| observeAppearance install (init()) | PSTranscribeApp.swift | 55 |
| observeAppearance helper definition | PSTranscribeApp.swift | 215-232 |
| applyAppearance helper definition | DictationWindowController.swift | 104-119 (doc comment 104-110, body 111-118) |
| panel.appearance switch arms | DictationWindowController.swift | 114 (.system → nil), 115 (.light → .aqua), 116 (.dark → .darkAqua) |
| Section("Appearance") | SettingsView.swift | 30 |
| Picker("Appearance", selection: $settings.appearancePreference) | SettingsView.swift | 31 |
| Three Text-tag option rows | SettingsView.swift | 32 (System), 33 (Light), 34 (Dark) |
| .font(.system(size: 12)) on new Picker | SettingsView.swift | 36 |

## Decisions Made

- **MenuBarExtra menu content wrapped in `Group { ... }`** — confirmed needed. SwiftUI's `@ViewBuilder` multi-statement closure body cannot accept a modifier directly; `Group` is the canonical zero-overhead wrapper for this case. The status-bar `Image` `label:` closure was deliberately NOT wrapped — the system-rendered NSStatusItem inherits `NSApp.effectiveAppearance` regardless of `.preferredColorScheme`, so wrapping would be a no-op. Documented as tolerated gap per CONTEXT.md.
- **Recursive `observeAppearance` continuation pattern** — chose the `Task { @MainActor in ... }` + recursive re-call shape over `Task { for-await ... }` because `@Observable` does not expose an `AsyncSequence`. The recursive shape matches Apple's WWDC 2024 "Observation in Swift" guidance for multi-mutation tracking. Loop is bounded by the app's lifetime.
- **`@MainActor.assumeIsolated` rejected** — Swift 6.2 strict concurrency would not accept it inside the non-isolated `onChange` closure. The `Task { @MainActor in ... }` hop is the conservative path. Compiles cleanly, no Sendable warnings, no measurable latency at human-click cadence.
- **Three explicit `Text("...").tag(...)` rows in the Picker** — chose hard-coded triplet over `ForEach(AppearancePreference.allCases)` because D-04 locks both the order (System / Light / Dark) and the exact label strings. Three lines is clearer at this scale and resilient to future enum-case reordering.

## Verification Results

| Check | Expected | Actual |
|-------|----------|--------|
| `swift build` exit code | 0, no new warnings | 0, no warnings (`Build complete! (1.67s)` final) |
| `grep -c '\.preferredColorScheme(settings\.appearancePreference\.colorScheme)' PSTranscribeApp.swift` | 3 | 3 |
| `grep -rn 'preferredColorScheme(' PSTranscribe/Sources --include='*.swift' \| grep -v '#Preview' \| grep -v 'PSTranscribeApp.swift' \| grep -v '///' \| wc -l` (relaxed D-06) | 0 | 0 |
| Hardcoded `.light` / `.dark` / `.none` in PSTranscribeApp.swift | 0 | 0 |
| `Group {` wrapping MenuBarExtra content | 1+ | 1 (line 188) |
| `func applyAppearance(_ preference: AppearancePreference)` count | 1 | 1 |
| `panel.appearance` runtime assignments (excluding doc comment) | 3 | 3 (lines 114, 115, 116) |
| `NSAppearance(named: .aqua)` count | 1 | 1 |
| `NSAppearance(named: .darkAqua)` count | 1 | 1 |
| `withObservationTracking` runtime call (excluding doc comments) | 1 | 1 (line 219) |
| `observeAppearance(controller:` invocations (call-site + recursive) | 2 | 2 |
| `initialWindowCtrl.applyAppearance(initialSettings.appearancePreference)` | 1 | 1 |
| KVO usage (`NSKeyValueObservation`, `addObserver(self,`) | 0 | 0 |
| Section("Appearance") count | 1 | 1 (line 30) |
| Section("Appearance") line < Section("Audio Input") line | true | 30 < 39 ✓ |
| Picker bound to `$settings.appearancePreference` | 1 | 1 (line 31) |
| Three options in System/Light/Dark order | 3 | 3 (lines 32, 33, 34) |
| `.pickerStyle(.segmented)` count | 0 | 0 |
| `.preferredColorScheme(` in SettingsView.swift | 0 | 0 |
| Pre-existing test suite | 221 tests / 40 suites pass | 221 / 40 pass — no regressions |

### Relaxed D-06 grep gate audit

```
$ grep -rn 'preferredColorScheme(' PSTranscribe/Sources --include='*.swift' | grep -v '#Preview' | grep -v 'PSTranscribeApp.swift'
PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift:9:/// `.system` is the default and resolves to `nil` so `.preferredColorScheme(nil)`
```

The single non-PSTranscribeApp.swift hit is a `///` doc comment in `AppSettings.swift` (introduced by Plan 21-01) — not a runtime call. After excluding `///` lines, the gate returns 0.

```
$ grep -rn 'preferredColorScheme(' PSTranscribe/Sources --include='*.swift' | grep -v '#Preview' | grep -v 'PSTranscribeApp.swift' | grep -v '///' | wc -l
0
```

All three runtime `.preferredColorScheme` call-sites in `PSTranscribe/Sources` (outside `#Preview` blocks and `///` doc comments) live in `PSTranscribeApp.swift`, and each reads `settings.appearancePreference.colorScheme`. **D-06 invariant satisfied.**

## Deviations from Plan

None — plan executed exactly as written. Specifically:

- **Group { ... } wrapping for MenuBarExtra menu content was needed** (the plan's open question). Confirmed by inspection: the bare multi-statement `MenuBarExtra { Text + Divider + Button }` body cannot accept `.preferredColorScheme` directly without the `Group` wrapper. Implementation matches the plan's pre-written `Group` shape verbatim.
- **No Sendable / strict-concurrency concessions required.** The `Task { @MainActor in ... }` continuation in `observeAppearance.onChange` compiled cleanly under Swift 6.2 with zero warnings on the first attempt; no capture-list adjustments, no `@MainActor.assumeIsolated` workarounds, no `nonisolated(unsafe)` annotations.
- **Plan recommended the `applyAppearance` helper land between `setContent(_:)` (line 102) and `positionAtBottomCenter()` (line 107).** Implementation lands at lines 104-119, exactly in that gap — confirmed via `grep -n` on the file. (Pre-existing line numbers shifted by 17 due to the new method's footprint, which is expected.)

## Issues Encountered

None. Three additive Swift edits, three commits, clean build on first attempt for each task. Full test suite green.

## User Setup Required

None. The Picker in Settings populates from existing `@Observable` plumbing; the `withObservationTracking` loop installs at app launch; the initial sync apply uses the value already loaded by `AppSettings.init()` from UserDefaults.

## Next Phase Readiness

**Plan 21-03 (UAT) unblocked.** It can run all SPEC.md acceptance criteria + the relaxed D-06 grep audit on the cumulative state after this plan ships:

- **Live toggle test:** open Settings → Appearance, switch System / Light / Dark. The main window, Settings window, MenuBarExtra menu content, and Dictation HUD (when shown via hotkey) should all re-render to the chosen scheme without restart.
- **System reversion test:** with macOS in Dark mode, set preference to Light; main app surfaces flip Light. Set preference back to System; surfaces revert to following macOS.
- **HUD parity test:** trigger the dictation hotkey while preference is Light; the `.hudWindow` material should render with Light vibrancy. Switch to Dark; the panel re-renders with Dark vibrancy via the `withObservationTracking` re-arm.
- **Persistence test:** quit and relaunch the app; the chosen preference round-trips from UserDefaults (verified at the AppSettings.init layer in Plan 21-01).
- **D-06 grep audit:** UAT can run `grep -rn 'preferredColorScheme(' PSTranscribe/Sources --include='*.swift' | grep -v '#Preview' | grep -v 'PSTranscribeApp.swift' | grep -v '///'` and confirm 0 hits.

The status-bar icon's appearance behavior (tolerated gap) is documented in CONTEXT.md and reflected in the threat model (T-21-07); UAT should NOT flag it as a defect.

## Self-Check: PASSED

- `21-02-SUMMARY.md` exists at `.planning/phases/21-appearance-override/21-02-SUMMARY.md` ✓
- `PSTranscribeApp.swift` modified at `PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift` ✓
- `DictationWindowController.swift` modified at `PSTranscribe/Sources/PSTranscribe/App/DictationWindowController.swift` ✓
- `SettingsView.swift` modified at `PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift` ✓
- Commit `70eb18f` exists in git history (Task 1) ✓
- Commit `0bed62d` exists in git history (Task 2) ✓
- Commit `c1c21bf` exists in git history (Task 3) ✓

---
*Phase: 21-appearance-override*
*Completed: 2026-05-01*
