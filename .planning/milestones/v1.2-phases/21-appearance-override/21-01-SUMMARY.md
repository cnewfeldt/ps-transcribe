---
phase: 21-appearance-override
plan: 01
subsystem: settings
tags: [swiftui, userdefaults, appsettings, observable, colorscheme, appearance]

# Dependency graph
requires:
  - phase: 20-dark-mode-parity
    provides: token system + adaptive Color(light:dark:) helper across all 10 surfaces -- the substrate that .preferredColorScheme will steer in Plan 21-02
provides:
  - AppearancePreference enum (.system/.light/.dark, String rawValue, Identifiable + CaseIterable + Sendable, colorScheme: ColorScheme? bridge with nil-for-system)
  - AppSettings.appearancePreference stored property with didSet UserDefaults persistence under key "appearancePreference"
  - AppSettings.init() decode chain with .system fallback (handles missing key, invalid rawValue, fresh install) -- Req 6 invisible migration satisfied at the state layer
affects: [21-02-PLAN, 21-03-PLAN]

# Tech tracking
tech-stack:
  added: [SwiftUI imported into AppSettings.swift]
  patterns:
    - "Re-applies the dictationHotkeyMode precedent verbatim: file-scope String-rawValue enum + didSet UserDefaults write + init-side string + ?? defaultRawValue + init(rawValue:) + ?? .default decode"
    - "First file-scope type declared in AppSettings.swift -- previously the file held only the AppSettings class. The enum sits between the import block (line 5) and the @Observable class declaration (line 32)."

key-files:
  modified:
    - PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift -- enum AppearancePreference (lines 7-30), import SwiftUI (line 5), stored property (lines 113-121), init read (lines 195-198)

key-decisions:
  - "Sendable conformance added to AppearancePreference (free for String-backed enums under Swift 6.2 strict concurrency; harmless if removed)"
  - "Enum sits at file scope above final class AppSettings (D-08 lock); not nested, not extracted to Models.swift"
  - "Init read positioned between clipboardRestoreDelay (last v1.2 dictation key) and installedModelVersion (first v1.2 model-update key) so the v1.2 settings groups read top-to-bottom in the same order as their MARK sections"

patterns-established:
  - "AppearancePreference.colorScheme returns nil for .system -- a SwiftUI no-op when fed to .preferredColorScheme(_:) -- which is the primitive Plan 21-02 will use to bypass overrides without a separate code branch for the .system case"

requirements-completed: [SPEC.Req-1, SPEC.Req-2, SPEC.Req-6, D-08, D-09]

# Metrics
duration: ~5min
completed: 2026-05-01
---

# Phase 21 Plan 01: AppearancePreference enum + AppSettings.appearancePreference property

**File-scope `AppearancePreference` enum (.system/.light/.dark) and `@Observable`-backed `AppSettings.appearancePreference` stored property persisted to UserDefaults under key `"appearancePreference"`, with `colorScheme: ColorScheme?` SwiftUI bridge that returns `nil` for `.system` to preserve Phase 20's system-following behavior byte-for-byte.**

## Performance

- **Duration:** ~5 min (active execution; full 43min wall-clock window from plan-creation commit `43a1db8` includes context gathering)
- **Started:** 2026-05-01T18:26:30Z
- **Completed:** 2026-05-01T18:29:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- `AppearancePreference` enum lives at file scope in `PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift` (lines 7-30) with three cases (`.system`/`.light`/`.dark`), `String` rawValues, `Identifiable` + `CaseIterable` + `Sendable` conformance, and a `colorScheme: ColorScheme?` computed property returning `nil` / `.light` / `.dark`
- `AppSettings.appearancePreference: AppearancePreference` stored property (lines 119-121) under a new `// MARK: - v1.2 Appearance Override (Phase 21, D-08 / D-09)` section, with the established `didSet → UserDefaults.standard.set(_:forKey:)` write pattern
- `AppSettings.init()` reads the key (lines 195-198) with the `string-or-default-rawValue + ?? .system` decode chain, satisfying Req 6 invisible migration at the state layer (missing key, invalid rawValue, fresh install all resolve to `.system`)
- `import SwiftUI` added to the file (line 5) to resolve `ColorScheme?` at file scope
- `swift build` clean, all 221 pre-existing tests pass across 40 suites

## Task Commits

Each task was committed atomically:

1. **Task 1: Add AppearancePreference enum + appearancePreference stored property to AppSettings.swift** — `cea6cb6` (feat)

## Files Created/Modified

- `PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift` — Added `import SwiftUI` (line 5), `AppearancePreference` enum at file scope (lines 7-30), `appearancePreference` stored property under new MARK section (lines 113-121), and init-side decode (lines 195-198). +41 lines, 0 deletions.

### Exact placement (for Plan 21-02 reference)

| Element | File | Lines |
|---------|------|-------|
| `import SwiftUI` | AppSettings.swift | 5 |
| `enum AppearancePreference` (file-scope, above `final class AppSettings`) | AppSettings.swift | 7-30 |
| `case system` / `case light` / `case dark` | AppSettings.swift | 15 / 16 / 17 |
| `var id: String { rawValue }` | AppSettings.swift | 19 |
| `var colorScheme: ColorScheme?` | AppSettings.swift | 23-29 |
| `// MARK: - v1.2 Appearance Override (Phase 21, D-08 / D-09)` | AppSettings.swift | 113 |
| `var appearancePreference: AppearancePreference { didSet { ... } }` | AppSettings.swift | 119-121 |
| Init read (`appearanceRaw` + `?? .system`) | AppSettings.swift | 195-198 |

## Decisions Made

- **`Sendable` conformance added** beyond what D-08 strictly requires. Free for `String`-backed enums under Swift 6.2 strict concurrency; preempts any future capture-list noise when the enum crosses `Task` boundaries. Harmless to remove if it ever becomes a constraint.
- **Init read placement: between dictation block and model-update block.** This keeps the `init()` body's v1.2 settings groups in the same top-to-bottom order as their MARK sections in the property declarations: SaveDestinations → Dictation → Appearance → ModelUpdate. (The plan suggested "alongside the dictation reads"; placing it strictly after the dictation block honors the section grouping while staying within the requested region.)
- **Doc comment in enum mentions `.preferredColorScheme(nil)` as a SwiftUI no-op.** This is documentation only -- not a runtime call-site -- and satisfies the acceptance criterion (greps for `preferredColorScheme(` excluding `///` lines return zero hits).

## Verification Results

| Check | Expected | Actual |
|-------|----------|--------|
| `swift build` exit code | 0, no new warnings | 0, no warnings (`Build complete! (3.28s)`) |
| 3 enum case lines | 3 | 3 (lines 15, 16, 17) |
| `var colorScheme: ColorScheme?` | 1+ | 1 (line 23) |
| `var appearancePreference: AppearancePreference` | 1 | 1 (line 119) |
| `forKey: "appearancePreference"` | 2 (didSet + init read) | 2 (lines 120, 196) |
| `AppearancePreference(rawValue:.*) ?? .system` | 1 | 1 (line 198) |
| `^import SwiftUI$` | 1 | 1 (line 5) |
| `enum AppearancePreference: String` count | 1 | 1 |
| `.preferredColorScheme(` runtime call-sites (excluding `///` doc comments) | 0 | 0 |
| Pre-existing test suite | green (no regressions) | 221 tests / 40 suites pass |
| `git diff --stat` scope | exactly 1 file (AppSettings.swift) | 1 file, +41/-0 |

## Deviations from Plan

None -- plan executed exactly as written. Sub-edit ordering, MARK placement, doc-comment text, decode chain shape, and conformance list all match the plan verbatim. The `Sendable` conformance was already in the plan body (line 152 of `21-01-PLAN.md`); adding it was a plan instruction, not an executor deviation.

## Issues Encountered

None. Single-file additive edit, three sub-edits, clean build on first attempt.

## User Setup Required

None. The new UserDefaults key `"appearancePreference"` populates lazily on first write; no migration step, no environment variable, no external service.

## Next Phase Readiness

**Plan 21-02 unblocked.** It can compile against the following symbols immediately on top of commit `cea6cb6`:

- `settings.appearancePreference` -- read access for the `.preferredColorScheme(settings.appearancePreference.colorScheme)` modifier at three Scene roots (D-05) and for the `NSAppearance(named:)` mapping in `DictationWindowController` (D-07)
- `settings.appearancePreference = .light` (or `.dark`, `.system`) -- write access for the `SettingsView` Picker binding (D-06)
- `AppearancePreference.allCases` -- iteration source for the Picker (`CaseIterable`)
- `AppearancePreference.id` -- `Identifiable` conformance for the Picker's `ForEach`
- `AppearancePreference.colorScheme` -- the SwiftUI bridge; returns `nil` for `.system` so `.preferredColorScheme(nil)` is a no-op and Phase 20's behavior is preserved when the user picks System

The `Sendable` conformance is forward-compatible if the dictation HUD's NSPanel observation (D-07) ends up reading the preference from a `Task` context.

## Self-Check: PASSED

- `21-01-SUMMARY.md` exists at `.planning/phases/21-appearance-override/21-01-SUMMARY.md`
- `AppSettings.swift` exists at `PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift`
- Commit `cea6cb6` exists in git history (verified via `git log --oneline --all | grep cea6cb6`)

---
*Phase: 21-appearance-override*
*Completed: 2026-05-01*
