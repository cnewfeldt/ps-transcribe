---
phase: 16
plan: 02
subsystem: settings
tags: [appsettings, userdefaults, dictation, model-update, foundation]
dependency_graph:
  requires:
    - 16-01  # DictationOutputMode + DictationHotkeyMode enums
  provides:
    - AppSettings.dictationOutputMode
    - AppSettings.dictationFolderPath
    - AppSettings.dictationHotkeyMode
    - AppSettings.clipboardRestoreDelay
    - AppSettings.installedModelVersion
    - AppSettings.modelLastCheckedDate
  affects:
    - PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift
tech_stack:
  added: []
  patterns:
    - "didSet UserDefaults mirroring (per-property, matches existing eight keys)"
    - "object(forKey:) presence check for TimeInterval default-on-missing"
    - "removeObject(forKey:) for Optional Date nil-state"
key_files:
  created:
    - PSTranscribe/Tests/PSTranscribeTests/AppSettingsTests.swift
  modified:
    - PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift
decisions:
  - "Used Strategy A (save/restore real UserDefaults around each test) per plan; deferred suiteName-injection refactor to a future test-architecture pass."
  - "modelLastCheckedDate didSet uses removeObject when set to nil so a fresh AppSettings reads nil unambiguously instead of seeing a stale stored Date."
  - "dictationFolderPath default uses NSString.expandingTildeInPath to match the vaultMeetingsPath/vaultVoicePath pattern (consistent across all three folder-path settings)."
metrics:
  duration_minutes: 1
  completed_date: "2026-04-27"
  tests_added: 13
  files_changed: 2
requirements_completed:
  - SC-2
---

# Phase 16 Plan 02: AppSettings v1.2 Keys Summary

**One-liner:** Adds the six v1.2 `AppSettings` properties (dictation output mode/folder/hotkey/restore-delay + installed model version + last-checked date) using the existing `didSet` UserDefaults mirroring pattern, with 13 new tests covering defaults, round-trips, and nil-clear behavior.

## What Shipped

A single, atomic settings surface for all v1.2 features. Phases 17 (Model Auto-Update) and 18 (Hotkey Dictation + Plain-Folder Output) consume these keys read-only -- there will be zero AppSettings churn after this plan lands.

### Six new properties (verbatim Swift declarations)

```swift
// MARK: - v1.2 Dictation Settings (Phase 16, D-03 / D-04)

/// Dictation output destination. Default `.clipboard` (D-08): plain folder is opt-in.
var dictationOutputMode: DictationOutputMode {
    didSet { UserDefaults.standard.set(dictationOutputMode.rawValue, forKey: "dictationOutputMode") }
}

/// Plain-markdown output folder for hotkey dictation. Default `~/Documents/PS Transcribe Dictations`
/// (matches Phase 19 success criterion #4). Folder is created on first dictation save (Phase 18 owns creation),
/// not on app launch.
var dictationFolderPath: String {
    didSet { UserDefaults.standard.set(dictationFolderPath, forKey: "dictationFolderPath") }
}

/// Hotkey activation model. Default `.toggle` (research-locked).
var dictationHotkeyMode: DictationHotkeyMode {
    didSet { UserDefaults.standard.set(dictationHotkeyMode.rawValue, forKey: "dictationHotkeyMode") }
}

/// Seconds to wait after dictation paste before restoring the prior clipboard contents (DICT-06).
/// Default 3.0 seconds.
var clipboardRestoreDelay: TimeInterval {
    didSet { UserDefaults.standard.set(clipboardRestoreDelay, forKey: "clipboardRestoreDelay") }
}

// MARK: - v1.2 Model Auto-Update Settings (Phase 16, D-04)

/// SHA / version identifier of the currently installed FluidAudio model. Empty until first
/// successful download. Phase 17 reads/writes this; Phase 16 only declares it.
var installedModelVersion: String {
    didSet { UserDefaults.standard.set(installedModelVersion, forKey: "installedModelVersion") }
}

/// Last time the app checked the model manifest. nil = never checked. Drives the 24-hour
/// throttle in MODEL-01. Phase 17 reads/writes this; Phase 16 only declares it.
var modelLastCheckedDate: Date? {
    didSet {
        if let d = modelLastCheckedDate {
            UserDefaults.standard.set(d, forKey: "modelLastCheckedDate")
        } else {
            UserDefaults.standard.removeObject(forKey: "modelLastCheckedDate")
        }
    }
}
```

### Init clause additions (verbatim Swift)

```swift
// v1.2 Dictation keys (Phase 16, D-04)
let dictationModeRaw = defaults.string(forKey: "dictationOutputMode")
    ?? DictationOutputMode.clipboard.rawValue
self.dictationOutputMode = DictationOutputMode(rawValue: dictationModeRaw) ?? .clipboard

self.dictationFolderPath = defaults.string(forKey: "dictationFolderPath")
    ?? NSString("~/Documents/PS Transcribe Dictations").expandingTildeInPath

let hotkeyModeRaw = defaults.string(forKey: "dictationHotkeyMode")
    ?? DictationHotkeyMode.toggle.rawValue
self.dictationHotkeyMode = DictationHotkeyMode(rawValue: hotkeyModeRaw) ?? .toggle

// TimeInterval (Double) -- UserDefaults.double returns 0.0 for missing keys, so check object presence.
if defaults.object(forKey: "clipboardRestoreDelay") == nil {
    self.clipboardRestoreDelay = 3.0
} else {
    self.clipboardRestoreDelay = defaults.double(forKey: "clipboardRestoreDelay")
}

// v1.2 Model Update keys (Phase 16, D-04) -- declared only; Phase 17 wires consumption.
self.installedModelVersion = defaults.string(forKey: "installedModelVersion") ?? ""
self.modelLastCheckedDate = defaults.object(forKey: "modelLastCheckedDate") as? Date
```

## Tasks Executed

| Task | Description                                                            | Commit  |
| ---- | ---------------------------------------------------------------------- | ------- |
| 1    | (RED) Add 13 failing tests in AppSettingsTests.swift                   | fcab85f |
| 2    | (GREEN) Add six properties + init clauses; all 13 tests pass           | db2ecae |

## Verification Results

- `swift build`: zero errors, zero new warnings on `AppSettings.swift`.
- `swift test --filter AppSettingsTests`: 13 / 13 passing in 0.006s.
- `swift test` (full suite): 61 / 61 passing across 12 suites in 0.036s. No pre-existing test regressed.
- Acceptance counts (verified):
  - 6 new property declarations, each appearing exactly once.
  - 1 `removeObject(forKey: "modelLastCheckedDate")` call (correct nil-clear).
  - 0 `@AppStorage` annotations (anti-pattern not introduced).
  - 0 `createDirectory` calls in AppSettings (folder creation correctly deferred to Phase 18).

## Default Values (D-04 Compliance)

| Key                    | Type                  | Default                                                                       | Verified |
| ---------------------- | --------------------- | ----------------------------------------------------------------------------- | -------- |
| dictationOutputMode    | DictationOutputMode   | `.clipboard`                                                                  | ✓        |
| dictationFolderPath    | String                | `NSString("~/Documents/PS Transcribe Dictations").expandingTildeInPath`       | ✓        |
| dictationHotkeyMode    | DictationHotkeyMode   | `.toggle`                                                                     | ✓        |
| clipboardRestoreDelay  | TimeInterval          | `3.0`                                                                         | ✓        |
| installedModelVersion  | String                | `""`                                                                          | ✓        |
| modelLastCheckedDate   | Date?                 | `nil`                                                                         | ✓        |

No deviations from the canonical D-04 default values.

## Confirmation: No Folder Creation in AppSettings

Verified via `grep -c createDirectory PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift` -> `0`. Phase 18 will own dictation directory creation on first dictation save.

## Confirmation: No Warnings on AppSettings.swift

Verified via `swift build 2>&1 | grep -c "warning:.*AppSettings.swift"` -> `0`. SC-2 ("All v1.2 `AppSettings` keys are present and compile without warnings") is satisfied.

## Deviations from Plan

None -- plan executed exactly as written. Both tasks landed on the first attempt with no auto-fix iterations needed.

The plan's RED-state verification command (`swift build 2>&1 | grep -c "has no member"`) only surfaces those errors when test compilation is invoked; `swift build` alone compiles only the main target. Confirmed RED via `swift build --build-tests` instead, which produced 6+ "has no member" diagnostics as expected. This was a documentation nit in the plan, not a functional deviation -- final acceptance held.

## Threat Surface Scan

No new threat surface beyond what the plan's `<threat_model>` already accepts. The six new keys are storage-only declarations consumed in Phases 17 and 18; no new network calls, clipboard access, entitlements, IPC, URL handlers, or file-system writes were introduced in this plan.

No `## Threat Flags` section needed.

## Self-Check: PASSED

- File `PSTranscribe/Tests/PSTranscribeTests/AppSettingsTests.swift`: FOUND
- File `PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift`: FOUND
- Commit `fcab85f` (test): FOUND
- Commit `db2ecae` (feat): FOUND
- 13 / 13 AppSettingsTests passing: FOUND
- 0 errors, 0 new warnings on AppSettings.swift: FOUND
