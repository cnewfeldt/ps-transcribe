# Phase 1: Rebrand - Research

**Researched:** 2026-04-01
**Domain:** macOS SwiftPM app rename -- bundle identity, UserDefaults migration, CI/CD, Sparkle appcast
**Confidence:** HIGH

## Summary

Phase 1 is a mechanical rename of "Tome" to "PS Transcribe" across every layer of the project: Swift source code, SwiftPM manifest, build scripts, GitHub Actions CI, and Info.plist. The rename is purely identity transformation -- no new features, no behavior changes.

The most operationally sensitive change is UserDefaults migration (REBR-08). The existing app writes settings into the `io.gremble.tome` app container (confirmed: keys exist on the dev machine). After the bundle ID changes to `com.pstranscribe.app`, macOS presents a new, empty defaults domain. Migration must read from the OLD domain and write to the NEW domain before any SwiftUI @Observable reads vault paths or device IDs. The migration runs in `TomeApp.init()` (now `PSTranscribeApp.init()`), synchronously, before `@State private var settings = AppSettings()` is initialized.

The Sparkle chain decision (D-09) means no appcast bridge is required. The old Gremble-io/Tome repo/appcast is abandoned; a new repo and gh-pages branch will serve the PS Transcribe appcast. This simplifies the CI changes to a straight find-and-replace on repo URLs and artifact names -- no dual-feed complexity.

**Primary recommendation:** Execute the rename in layered waves: (1) directory and file renames, (2) source content edits, (3) Package.swift and build scripts, (4) CI workflows, (5) UserDefaults migration code -- build-verify after each wave.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** New bundle ID is `com.pstranscribe.app` (replacing `io.gremble.tome`)
- **D-02:** Logger subsystem strings updated to `com.pstranscribe.app` (full clean break, no stale references to old ID)
- **D-03:** Migration runs synchronously in the app struct's `init()`, before any SwiftUI views or @Observable objects are created
- **D-04:** Old UserDefaults keys (from `io.gremble.tome` domain) are deleted immediately after successful copy to new domain -- no rollback support, clean break
- **D-05:** Swift module name is `PSTranscribe` (PascalCase, matches Swift convention)
- **D-06:** Source directory renamed from `Sources/Tome/` to `Sources/PSTranscribe/`
- **D-07:** Outer project directory renamed from `Tome/` to `PSTranscribe/` (contains Package.swift)
- **D-08:** Entitlements file renamed from `Tome.entitlements` to `PSTranscribe.entitlements`
- **D-09:** Clean break -- no Sparkle update path from Tome to PS Transcribe; existing Tome users must download PS Transcribe separately
- **D-10:** New GitHub repo created for PS Transcribe with its own gh-pages branch for the appcast
- **D-11:** Appcast URL in Info.plist updated to point to the new repo's gh-pages

### Claude's Discretion

- Exact migration key list (enumerate from AppSettings.swift UserDefaults keys)
- Order of rename operations (directory renames, Package.swift updates, CI workflow edits)
- Whether to use git mv or manual rename for directory operations
- Info.plist field updates beyond SUFeedURL (CFBundleName, CFBundleIdentifier, etc.)

### Deferred Ideas (OUT OF SCOPE)

None -- discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REBR-01 | App name changed from "Tome" to "PS Transcribe" in all user-facing strings | Swift source edits: TomeApp.swift (MenuBarExtra Text, Button), AppUpdaterController.swift (alert strings), OnboardingView.swift ("Welcome to Tome"), Info.plist (CFBundleName, CFBundleDisplayName, NSMicrophoneUsageDescription, NSScreenCaptureUsageDescription) |
| REBR-02 | Bundle identifier updated across project configuration | Info.plist CFBundleIdentifier: `io.gremble.tome` -> `com.pstranscribe.app`; build_swift_app.sh BUNDLE_ID var; Logger subsystem in StreamingTranscriber.swift |
| REBR-03 | Package.swift target names and module references updated | Package.swift: name, target name, path, exclude list all reference "Tome" |
| REBR-04 | Source directory structure renamed (Tome/ to PSTranscribe/) | Two-level rename: outer dir `Tome/` -> `PSTranscribe/`, inner dir `Sources/Tome/` -> `Sources/PSTranscribe/` |
| REBR-05 | CI/CD workflows (release-dmg.yml, build-check.yml) reference new names | release-dmg.yml: ~12 Tome/Gremble-io references; build-check.yml: working-directory, binary paths |
| REBR-06 | Sparkle update feed URL and appcast references updated | Info.plist SUFeedURL; release-dmg.yml appcast XML generation, DMG_URL, git clone URL |
| REBR-07 | Info.plist and entitlements updated with new app identity | Info.plist: CFBundleName, CFBundleDisplayName, CFBundleIdentifier, CFBundleExecutable, NSMicrophoneUsageDescription, NSScreenCaptureUsageDescription, SUFeedURL; entitlements file rename |
| REBR-08 | UserDefaults migration preserves existing user settings on first launch | Migration reads from `io.gremble.tome` domain, writes to `com.pstranscribe.app` domain, deletes old keys -- runs before AppSettings init |
</phase_requirements>

---

## Standard Stack

### Core (no new dependencies required)
This phase adds no new libraries. All work is source editing and structural renaming.

| Tool | Version | Purpose | Notes |
|------|---------|---------|-------|
| SwiftPM | 6.2 | Build system | Package.swift target rename |
| Sparkle | 2.7.0+ | Auto-update | SUFeedURL update only; no API change |
| Swift | 6.2 | Language | Strict concurrency maintained |

### Key macOS APIs Used by Migration

| API | Purpose | Notes |
|-----|---------|-------|
| `UserDefaults.standard` | Reads existing Tome settings | Keys confirmed in `io.gremble.tome` domain |
| `UserDefaults(suiteName:)` | NOT used -- app uses `.standard` | `.standard` domain is keyed to bundle ID |
| `Bundle.main.bundleIdentifier` | NOT available during migration (init() runs before bundle is fully bound) | Use string literal for old domain ID |

**Critical insight:** `UserDefaults.standard` resolves to the CURRENT app's bundle ID domain. After the bundle ID changes to `com.pstranscribe.app`, `.standard` will be an empty domain. To read the OLD keys, migration must use `UserDefaults(suiteName: "io.gremble.tome")` -- this is the named-domain form that directly targets the old plist.

---

## Architecture Patterns

### Recommended Rename Execution Order

Wave 1 -- Filesystem (git mv):
```
git mv Tome/Sources/Tome PSTranscribe/Sources/PSTranscribe
git mv Tome PSTranscribe
```
Note: git mv preserves history. After directory renames, ALL path references in source become broken -- fix in Wave 2.

Wave 2 -- Source content edits (Swift files):
- Package.swift: name, target name, path, exclude list
- TomeApp.swift -> PSTranscribeApp.swift: struct name, MenuBarExtra strings, app name strings
- AppUpdaterController.swift -> PSTranscribeUpdaterController.swift (or keep name): TomeUserDriver -> PSTranscribeUserDriver, alert strings
- StreamingTranscriber.swift: Logger subsystem string
- TranscriptionEngine.swift: diagLog path `/tmp/tome.log` -> `/tmp/pstranscribe.log`
- SessionStore.swift: `Tome/sessions` -> `PSTranscribe/sessions` app support path
- AppSettings.swift: default vault paths `~/Documents/Tome/` -> `~/Documents/PSTranscribe/`
- OnboardingView.swift: "Welcome to Tome" string

Wave 3 -- Migration code added to PSTranscribeApp.init() (new code):
```swift
// Runs before AppSettings() is created
migrateUserDefaultsIfNeeded()
```

Wave 4 -- Build scripts:
- build_swift_app.sh: APP_NAME, BUNDLE_ID, SWIFT_DIR, binary path, entitlements path
- make_dmg.sh: APP_PATH, DMG_PATH, volname, AppleScript disk name, item position labels

Wave 5 -- CI workflows:
- release-dmg.yml: PLIST path, artifact name, DMG paths, Sparkle find path, DMG_URL, git clone URL, appcast XML content
- build-check.yml: working-directory

Wave 6 -- Info.plist and entitlements:
- Info.plist: CFBundleName, CFBundleDisplayName, CFBundleIdentifier, CFBundleExecutable, NSMicrophoneUsageDescription, NSScreenCaptureUsageDescription, SUFeedURL
- PSTranscribe.entitlements: no content change, file already renamed in Wave 1

### UserDefaults Migration Pattern

```swift
// In PSTranscribeApp struct, called synchronously before AppSettings() is created
private func migrateUserDefaultsIfNeeded() {
    let oldDomain = "io.gremble.tome"
    let migrationSentinelKey = "hasMigratedFromTome"

    // Already migrated -- skip
    guard !UserDefaults.standard.bool(forKey: migrationSentinelKey) else { return }

    guard let oldDefaults = UserDefaults(suiteName: oldDomain) else { return }
    let oldDict = oldDefaults.dictionaryRepresentation()

    // Only migrate the keys AppSettings actually reads
    let keysToMigrate = [
        "transcriptionLocale",
        "inputDeviceID",
        "vaultMeetingsPath",
        "vaultVoicePath",
        "hideFromScreenShare",
        "hasCompletedOnboarding",
    ]

    let newDefaults = UserDefaults.standard
    for key in keysToMigrate {
        if let value = oldDict[key] {
            newDefaults.set(value, forKey: key)
        }
    }

    // Mark migration complete
    newDefaults.set(true, forKey: migrationSentinelKey)
    newDefaults.synchronize()

    // Delete old keys (D-04: clean break)
    for key in keysToMigrate {
        oldDefaults.removeObject(forKey: key)
    }
    oldDefaults.synchronize()
}
```

**Why `UserDefaults(suiteName:)` for old domain:** macOS stores each app's `UserDefaults.standard` data in a plist named after the bundle ID (e.g., `~/Library/Preferences/io.gremble.tome.plist`). After the bundle ID changes, `.standard` targets a new empty plist. `UserDefaults(suiteName: "io.gremble.tome")` opens the old plist directly for reading. This is a standard macOS migration technique (HIGH confidence -- confirmed against Apple docs pattern).

### Package.swift After Rename

```swift
let package = Package(
    name: "PSTranscribe",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(url: "https://github.com/FluidInference/FluidAudio.git", revision: "ea500621819cadc46d6212af44624f2b45ab3240"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.7.0"),
    ],
    targets: [
        .executableTarget(
            name: "PSTranscribe",
            dependencies: [
                .product(name: "FluidAudio", package: "FluidAudio"),
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources/PSTranscribe",
            exclude: ["Info.plist", "PSTranscribe.entitlements", "Assets"]
        ),
    ]
)
```

### Anti-Patterns to Avoid

- **Do not** use `sed -i '' 's/Tome/PSTranscribe/g'` globally -- "Tome" also appears in app-visible strings that should read "PS Transcribe" (not "PSTranscribe"), in Sparkle framework internals that must not be touched, and in git history references that are irrelevant.
- **Do not** rename the git repo root directory `/Tome` (the outer workspace) -- that is the git repo folder name, not the SwiftPM project root. Only the inner `Tome/` directory (containing Package.swift) is renamed to `PSTranscribe/`.
- **Do not** run migration with `UserDefaults.standard` as both source and destination -- they become the same object after the bundle ID changes, causing self-overwrite.
- **Do not** call `newDefaults.synchronize()` before all keys are written -- write all keys first, then synchronize once.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| UserDefaults domain access | Custom plist reader | `UserDefaults(suiteName:)` | Standard API; handles thread safety, encoding, fallback |
| Appcast XML generation | Custom XML serializer | Heredoc string in CI (already used) | XML is static per release; no dynamic structure |
| DMG Finder layout | Custom AppleScript | Existing make_dmg.sh pattern | Already works; just update name strings |

---

## Runtime State Inventory

This is a rename/refactor phase -- the inventory is mandatory.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data -- UserDefaults | `io.gremble.tome.plist`: keys `inputDeviceID=103`, `vaultMeetingsPath`, `vaultVoicePath`, `transcriptionLocale` (absent, defaults to en-US), `hideFromScreenShare` (absent, defaults to true), `hasCompletedOnboarding=1`, plus Sparkle keys (SUHasLaunchedBefore, SULastCheckTime, etc.) | Migration code in PSTranscribeApp.init() reads old domain, writes to new domain, deletes old keys (D-03, D-04) |
| Stored data -- App Support | `~/Library/Application Support/Tome/sessions/` -- 10+ JSONL session files present | SessionStore.swift path updated to `PSTranscribe/sessions`; existing Tome session files are NOT auto-migrated (they stay under Tome/sessions; crash recovery for Phase 2 is out of scope here). The old directory is not deleted. |
| Stored data -- vault | User's vault is at `/Users/cary/Obsidian Vault/C2YN6T/0-Inbox/Meeting Transcripts - TOME` (custom path set by user) -- NOT the default `~/Documents/Tome/`. | No action -- vault path is stored in UserDefaults and migrated with other keys. Default fallback in AppSettings.swift updated to `~/Documents/PSTranscribe/` but user's custom path is preserved. |
| Stored data -- `Tome.plist` | `~/Library/Preferences/Tome.plist` exists with NSWindow frame and `hasCompletedOnboarding`. This plist is from when the app ran WITHOUT a bundle ID (bare executable), not the sandboxed domain. Window frame keys are SwiftUI-generated and contain the type name "Tome.ContentView" -- these will regenerate automatically when the view type name changes to "PSTranscribe.ContentView". | No migration needed -- SwiftUI regenerates window frame prefs under the new type name. |
| Live service config | None -- no external services, no n8n, no Datadog, no Cloudflare. | None |
| OS-registered state | None -- no launchd plists, no Login Items, no Task Scheduler equivalents found. | None |
| Secrets/env vars | GitHub Actions secrets: `MACOS_CERTIFICATE`, `MACOS_CERTIFICATE_PWD`, `APPLE_ID`, `APPLE_TEAM_ID`, `APPLE_APP_PASSWORD`, `SPARKLE_EDDSA_KEY`, `GH_TOKEN` (implicit). These are stored in the GitHub repo settings under Gremble-io/Tome. | The new PS Transcribe repo must have the same secrets configured. CI workflows reference these by name -- names do not change, only the repo changes. This is a manual GitHub repo setup step (not a code edit). |
| Build artifacts | `Tome/.build/` -- SwiftPM build artifacts including `release/Tome` binary and `artifacts/sparkle/` Sparkle XPC services. After directory rename to `PSTranscribe/`, `.build/` moves with the directory. Binary name changes from `Tome` to `PSTranscribe` (matches the target name in Package.swift). | Clean `.build/` after rename: `swift package clean` from the new PSTranscribe/ directory. |

**The canonical question answer:** After all files are updated, the following runtime state still has the old name:
1. `~/Library/Application Support/Tome/sessions/` -- old JSONL files remain; app will no longer write here (no migration, Phase 2 concern)
2. `~/Library/Preferences/io.gremble.tome.plist` -- persists after migration but old keys are deleted (D-04)
3. GitHub repo secrets are under Gremble-io/Tome -- must be re-added to new PS Transcribe repo manually

---

## Common Pitfalls

### Pitfall 1: UserDefaults.standard Self-Reference
**What goes wrong:** Migration code uses `UserDefaults.standard` to read old keys AND write new keys. After the bundle ID changes, both operations target the same (new, empty) domain -- old settings are lost.
**Why it happens:** Developers assume `.standard` is a stable global; it is actually bundle-ID-scoped.
**How to avoid:** Read from `UserDefaults(suiteName: "io.gremble.tome")`, write to `UserDefaults.standard`. These are different objects after the bundle ID change.
**Warning signs:** Migration completes with no error, but all settings revert to defaults.

### Pitfall 2: Migration Fires After @Observable Reads
**What goes wrong:** `AppSettings.init()` runs before migration, reads empty new domain, and populates properties with defaults. Migration then writes correct values, but @Observable has already published the wrong values and the UI may not re-read them.
**Why it happens:** SwiftUI `@State private var settings = AppSettings()` initializes during scene body evaluation; if migration is in `onAppear` or `.task`, it's too late.
**How to avoid:** Call `migrateUserDefaultsIfNeeded()` as the FIRST line of `PSTranscribeApp.init()`, before `@State var settings` is declared. (D-03 locks this approach.)
**Warning signs:** App launches with default vault paths even though UserDefaults plist shows correct values.

### Pitfall 3: Package.swift exclude List Not Updated
**What goes wrong:** `exclude: ["Info.plist", "Tome.entitlements", "Assets"]` -- after the entitlements file is renamed, SwiftPM will fail to build because it can't find `Tome.entitlements` to exclude and the old path is invalid.
**Why it happens:** The exclude list contains the literal filename. Renaming the file without updating the exclude list breaks the build.
**How to avoid:** Update exclude to `["Info.plist", "PSTranscribe.entitlements", "Assets"]` in the same commit that renames the file.
**Warning signs:** `error: 'exclude' contains an invalid path 'Tome.entitlements'`.

### Pitfall 4: build_swift_app.sh Signs with Wrong Entitlements Path
**What goes wrong:** Script hardcodes `ENTITLEMENTS="$SWIFT_DIR/Sources/Tome/Tome.entitlements"`. After rename, this path does not exist -- codesign fails silently or with a misleading error.
**Why it happens:** Shell scripts don't get renamed when files move; they must be edited explicitly.
**How to avoid:** Update ENTITLEMENTS path in build_swift_app.sh as part of Wave 4.
**Warning signs:** `build_swift_app.sh: line 89: /PSTranscribe/Sources/Tome/Tome.entitlements: No such file or directory`.

### Pitfall 5: CI release-dmg.yml Sparkle sign_update Path
**What goes wrong:** `find Tome/.build/artifacts/sparkle` -- after directory rename, this path is `PSTranscribe/.build/artifacts/sparkle`. CI step silently finds nothing and exits 1 with "sign_update not found".
**Why it happens:** CI hardcodes the directory name.
**How to avoid:** Update the find path in the Sign DMG step.

### Pitfall 6: Hasty Global String Replace Corrupts Swift Type Names
**What goes wrong:** Replacing all occurrences of "Tome" produces `PSTranscribe.app` (wrong -- should be `PS Transcribe`), `PSTranscribeUserDriver` (correct), and `"Welcome to PSTranscribe"` (wrong -- should be "PS Transcribe").
**Why it happens:** Internal type names use PascalCase concatenation; user-visible strings use the full spaced name.
**How to avoid:** Replace in three passes: (1) bundle ID and subsystem strings (`io.gremble.tome` -> `com.pstranscribe.app`), (2) Swift type names (`Tome` prefix -> `PSTranscribe`), (3) user-visible strings (`"Tome"` -> `"PS Transcribe"`). Review each pass before committing.

### Pitfall 7: NSWindow Frame UserDefaults Key Contains Old Type Name
**What goes wrong:** The key `"NSWindow Frame SwiftUI.ModifiedContent<Tome.ContentView, ...>"` is stored in the old UserDefaults domain. After rename, SwiftUI looks for `"NSWindow Frame SwiftUI.ModifiedContent<PSTranscribe.ContentView, ...>"` -- new key, window opens at default position.
**Why it happens:** SwiftUI generates window frame keys from the type name.
**How to avoid:** This is expected and acceptable -- window position will reset once after launch. Do not attempt to migrate this key (type-mangled keys are SwiftUI internals). Document in implementation notes.

---

## Code Examples

### Migration Function (verified pattern)

```swift
// Source: Apple Developer Documentation -- UserDefaults(suiteName:) API
// In PSTranscribeApp.swift, called before AppSettings() is initialized

struct PSTranscribeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var settings: AppSettings

    init() {
        migrateUserDefaultsIfNeeded()
        _settings = State(initialValue: AppSettings())
    }

    private func migrateUserDefaultsIfNeeded() {
        let oldDomain = "io.gremble.tome"
        let sentinelKey = "hasMigratedFromTome"

        guard !UserDefaults.standard.bool(forKey: sentinelKey) else { return }
        guard let oldDefaults = UserDefaults(suiteName: oldDomain) else { return }

        let keysToMigrate = [
            "transcriptionLocale",
            "inputDeviceID",
            "vaultMeetingsPath",
            "vaultVoicePath",
            "hideFromScreenShare",
            "hasCompletedOnboarding",
        ]

        let newDefaults = UserDefaults.standard
        for key in keysToMigrate {
            if let value = oldDefaults.object(forKey: key) {
                newDefaults.set(value, forKey: key)
            }
        }

        newDefaults.set(true, forKey: sentinelKey)
        newDefaults.synchronize()

        for key in keysToMigrate {
            oldDefaults.removeObject(forKey: key)
        }
        oldDefaults.synchronize()
    }
    // ...
}
```

Note: `_settings = State(initialValue: AppSettings())` syntax is required to initialize a `@State` property in `init()` -- you cannot use `self.settings = AppSettings()` directly.

### AppSettings Default Vault Path Update

```swift
// AppSettings.swift -- update default paths for new app name
self.vaultMeetingsPath = defaults.string(forKey: "vaultMeetingsPath")
    ?? NSString("~/Documents/PSTranscribe/Meetings").expandingTildeInPath
self.vaultVoicePath = defaults.string(forKey: "vaultVoicePath")
    ?? NSString("~/Documents/PSTranscribe/Voice").expandingTildeInPath
```

### SessionStore App Support Path

```swift
// SessionStore.swift
sessionsDirectory = appSupport.appendingPathComponent("PSTranscribe/sessions", isDirectory: true)
```

### Logger Subsystem Update

```swift
// StreamingTranscriber.swift
private let log = Logger(subsystem: "com.pstranscribe.app", category: "StreamingTranscriber")
```

### diagLog Path Update

```swift
// TranscriptionEngine.swift
func diagLog(_ msg: String) {
    #if DEBUG
    let line = "\(Date()): \(msg)\n"
    let path = "/tmp/pstranscribe.log"
    // ...
    #endif
}
```

---

## Complete String Reference (all occurrences enumerated)

### Swift Source Files

| File | Old String | New String | Type |
|------|-----------|-----------|------|
| TomeApp.swift | `struct TomeApp` | `struct PSTranscribeApp` | type name |
| TomeApp.swift | `Text("Tome")` | `Text("PS Transcribe")` | user-visible |
| TomeApp.swift | `Button("Quit Tome")` | `Button("Quit PS Transcribe")` | user-visible |
| AppUpdaterController.swift | `class TomeUserDriver` | `class PSTranscribeUserDriver` | type name |
| AppUpdaterController.swift | `userDriver: TomeUserDriver` | `userDriver: PSTranscribeUserDriver` | type name |
| AppUpdaterController.swift | `userDriver = TomeUserDriver(...)` | `userDriver = PSTranscribeUserDriver(...)` | type name |
| AppUpdaterController.swift | `"...latest version of Tome..."` | `"...latest version of PS Transcribe..."` | user-visible |
| StreamingTranscriber.swift | `"io.gremble.tome"` | `"com.pstranscribe.app"` | subsystem |
| TranscriptionEngine.swift | `"/tmp/tome.log"` (x2) | `"/tmp/pstranscribe.log"` | path |
| SessionStore.swift | `"Tome/sessions"` | `"PSTranscribe/sessions"` | path |
| AppSettings.swift | `"~/Documents/Tome/Meetings"` | `"~/Documents/PSTranscribe/Meetings"` | path default |
| AppSettings.swift | `"~/Documents/Tome/Voice"` | `"~/Documents/PSTranscribe/Voice"` | path default |
| OnboardingView.swift | `"Welcome to Tome"` | `"Welcome to PS Transcribe"` | user-visible |

### Info.plist

| Key | Old Value | New Value |
|-----|----------|----------|
| CFBundleName | `Tome` | `PS Transcribe` |
| CFBundleDisplayName | `Tome` | `PS Transcribe` |
| CFBundleIdentifier | `io.gremble.tome` | `com.pstranscribe.app` |
| CFBundleExecutable | `Tome` | `PSTranscribe` |
| NSMicrophoneUsageDescription | `"Tome needs microphone..."` | `"PS Transcribe needs microphone..."` |
| NSScreenCaptureUsageDescription | `"Tome needs screen capture..."` | `"PS Transcribe needs screen capture..."` |
| SUFeedURL | `https://raw.githubusercontent.com/Gremble-io/Tome/gh-pages/appcast.xml` | New PS Transcribe repo gh-pages URL |

### Package.swift

| Old | New |
|-----|-----|
| `name: "Tome"` | `name: "PSTranscribe"` |
| `name: "Tome"` (target) | `name: "PSTranscribe"` |
| `path: "Sources/Tome"` | `path: "Sources/PSTranscribe"` |
| `exclude: [..., "Tome.entitlements", ...]` | `exclude: [..., "PSTranscribe.entitlements", ...]` |

### build_swift_app.sh

| Old | New |
|-----|-----|
| `SWIFT_DIR="$ROOT_DIR/Tome"` | `SWIFT_DIR="$ROOT_DIR/PSTranscribe"` |
| `APP_NAME="Tome"` | `APP_NAME="PS Transcribe"` |
| `BUNDLE_ID="io.gremble.tome"` | `BUNDLE_ID="com.pstranscribe.app"` |
| `BINARY_PATH=".build/release/Tome"` | `BINARY_PATH=".build/release/PSTranscribe"` |
| `"$APP_DIR/Contents/MacOS/Tome"` (x2) | `"$APP_DIR/Contents/MacOS/PSTranscribe"` |
| `"$SWIFT_DIR/Sources/Tome/Info.plist"` | `"$SWIFT_DIR/Sources/PSTranscribe/Info.plist"` |
| `"$SWIFT_DIR/Sources/Tome/Assets/AppIcon.icns"` | `"$SWIFT_DIR/Sources/PSTranscribe/Assets/AppIcon.icns"` |
| `"$SWIFT_DIR/Sources/Tome/Tome.entitlements"` | `"$SWIFT_DIR/Sources/PSTranscribe/PSTranscribe.entitlements"` |

### make_dmg.sh

| Old | New |
|-----|-----|
| `APP_PATH="dist/Tome.app"` | `APP_PATH="dist/PS Transcribe.app"` |
| `DMG_PATH="dist/Tome.dmg"` | `DMG_PATH="dist/PS Transcribe.dmg"` |
| `TEMP_DMG="dist/Tome_temp.dmg"` | `TEMP_DMG="dist/PS_Transcribe_temp.dmg"` |
| `hdiutil create -volname "Tome"` | `hdiutil create -volname "PS Transcribe"` |
| `tell disk "Tome"` (AppleScript) | `tell disk "PS Transcribe"` |
| `set position of item "Tome.app"` | `set position of item "PS Transcribe.app"` |

### release-dmg.yml (CI)

| Old | New |
|-----|-----|
| `PLIST="Tome/Sources/Tome/Info.plist"` | `PLIST="PSTranscribe/Sources/PSTranscribe/Info.plist"` |
| `name: Tome-dmg` | `name: PS-Transcribe-dmg` |
| `path: dist/Tome.dmg` | `path: dist/PS Transcribe.dmg` |
| `dist/Tome.dmg --clobber` | `dist/PS Transcribe.dmg --clobber` |
| `DMG_PATH="dist/Tome.dmg"` | `DMG_PATH="dist/PS Transcribe.dmg"` |
| `find Tome/.build/artifacts/sparkle` | `find PSTranscribe/.build/artifacts/sparkle` |
| `DMG_URL="https://github.com/Gremble-io/Tome/releases/download/..."` | New PS Transcribe repo URL |
| `git clone ...Gremble-io/Tome.git /tmp/gh-pages` | New PS Transcribe repo URL |
| `<title>Tome Updates</title>` | `<title>PS Transcribe Updates</title>` |
| `<link>...Gremble-io/Tome/gh-pages/appcast.xml</link>` | New PS Transcribe URL |
| `<description>Most recent updates to Tome</description>` | `<description>Most recent updates to PS Transcribe</description>` |

### build-check.yml (CI)

| Old | New |
|-----|-----|
| `working-directory: Tome` | `working-directory: PSTranscribe` |

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|-----------------|--------|
| Xcode project file for macOS apps | SwiftPM executable target (Swift 6.2) | No .xcodeproj to update -- simpler rename |
| UserDefaults without domain scoping | `UserDefaults(suiteName:)` for cross-domain migration | Standard pattern; no third-party migration libraries needed |

---

## Open Questions

1. **New GitHub repo URL for PS Transcribe**
   - What we know: D-10 says a new repo will be created with its own gh-pages branch
   - What's unclear: The actual GitHub org/user and repo name (e.g., `cary-newfeldt/ps-transcribe` vs. `pstranscribe/app`)
   - Recommendation: Placeholder in CI workflows during Phase 1; fill in the actual URL when the repo is created. The planner should flag this as a manual step that precedes CI workflow changes.

2. **Sparkle EdDSA Public Key for new repo**
   - What we know: Current Info.plist has `SUPublicEDKey = LT2/oCSuJPmnri+6b62DV1WhHxSmWrJ1nZzbAK2ipV4=`
   - What's unclear: Whether the new PS Transcribe app will reuse the same EdDSA key pair or generate a new one
   - Recommendation: Reuse existing key pair if the developer still controls the private key (SPARKLE_EDDSA_KEY secret). The public key in Info.plist stays the same. If a new key pair is generated, both Info.plist (SUPublicEDKey) and the GitHub secret (SPARKLE_EDDSA_KEY) must be updated atomically.

3. **App name spacing in file paths**
   - What we know: App display name is "PS Transcribe" (with space); binary/module name is "PSTranscribe" (no space)
   - What's unclear: Whether the .app bundle and .dmg should use "PS Transcribe.app" (with space) or "PSTranscribe.app" (no space)
   - Recommendation: Use "PS Transcribe.app" and "PS Transcribe.dmg" for the user-facing bundle (matches CFBundleName convention); use "PSTranscribe" for the Mach-O binary name (matches target name in Package.swift). This is already consistent with how CFBundleExecutable works: it can differ from CFBundleName.

---

## Environment Availability

This phase is purely code/config edits with no new runtime dependencies. Build toolchain is already confirmed by the existing CI.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Swift 6.2 | Build | Assumed -- CI uses macos-26 runner | 6.2 | -- |
| git mv | Directory renames | Yes (standard git) | -- | -- |
| UserDefaults(suiteName:) | Migration | Yes (macOS API, no version constraint) | -- | -- |

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None -- no project-level test target exists in Package.swift |
| Config file | None |
| Quick run command | `swift build` from PSTranscribe/ |
| Full suite command | `swift build` from PSTranscribe/ |

No project test infrastructure exists. All tests in `.build/checkouts/` are FluidAudio dependency tests, not project tests.

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | Infrastructure |
|--------|----------|-----------|-------------------|----------------|
| REBR-01 | User-facing strings show "PS Transcribe" | Manual -- launch and inspect | `swift build` (build smoke) | No test target |
| REBR-02 | Bundle ID is `com.pstranscribe.app` | Automated -- grep plist | `grep com.pstranscribe.app PSTranscribe/Sources/PSTranscribe/Info.plist` | File exists |
| REBR-03 | Package.swift target name is PSTranscribe | Automated -- build succeeds | `cd PSTranscribe && swift build` | Build verifies |
| REBR-04 | Source directories renamed | Automated -- path exists | `ls PSTranscribe/Sources/PSTranscribe/` | File system |
| REBR-05 | CI workflows reference new names | Automated -- grep check | `grep -c "Tome" .github/workflows/` should be 0 | File exists |
| REBR-06 | SUFeedURL points to new appcast | Automated -- grep plist | `grep pstranscribe PSTranscribe/Sources/PSTranscribe/Info.plist` | File exists |
| REBR-07 | Info.plist and entitlements updated | Automated -- grep check | `grep "PS Transcribe" PSTranscribe/Sources/PSTranscribe/Info.plist` | File exists |
| REBR-08 | UserDefaults migration preserves settings | Manual -- requires live app launch with existing Tome prefs | -- | No test framework |

### Sampling Rate

- **Per task commit:** `cd PSTranscribe && swift build` (confirms Package.swift + source compiles)
- **Per wave merge:** `swift build` + grep audit for residual "Tome" strings in non-comment, non-legacy paths
- **Phase gate:** App launches as "PS Transcribe", settings from old domain preserved (manual verification on dev machine with existing `io.gremble.tome` UserDefaults)

### Wave 0 Gaps

- [ ] No project test target -- REBR-08 (UserDefaults migration) cannot be automated without one. Migration correctness must be verified by manual launch. Flag for Phase 2 test infrastructure if desired.

---

## Sources

### Primary (HIGH confidence)
- Direct source code inspection: `Tome/Sources/Tome/Settings/AppSettings.swift` -- all UserDefaults keys enumerated
- Direct source code inspection: `Tome/Sources/Tome/App/TomeApp.swift` -- app entry point structure
- Direct source code inspection: `Tome/Package.swift` -- target names, excludes list
- Direct source code inspection: `.github/workflows/release-dmg.yml` -- all Tome string occurrences
- Direct source code inspection: `scripts/build_swift_app.sh`, `scripts/make_dmg.sh` -- all Tome string occurrences
- Live UserDefaults inspection: `defaults read io.gremble.tome` -- confirmed keys and values on dev machine
- Live filesystem inspection: `~/Library/Application Support/Tome/` -- confirmed sessions directory with 10+ JSONL files
- Apple Developer Documentation (macOS): `UserDefaults(suiteName:)` for named-domain access -- standard API

### Secondary (MEDIUM confidence)
- SwiftUI `@State` init() pattern (`_settings = State(initialValue:)`) -- standard Swift pattern, verified against Swift Evolution proposals and common usage

### Tertiary (LOW confidence)
- App name spacing convention ("PS Transcribe.app" vs "PSTranscribe.app") -- judgment call based on CFBundleName/CFBundleExecutable split; not verified against an official Apple naming guide

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new dependencies; all tooling is existing and verified
- Architecture / rename order: HIGH -- based on direct source inspection and SwiftPM build model understanding
- UserDefaults migration: HIGH -- UserDefaults(suiteName:) is a stable macOS API; confirmed old keys exist on dev machine
- Pitfalls: HIGH -- all pitfalls derived from actual code inspection, not speculation
- CI changes: HIGH -- all occurrences enumerated from actual workflow files

**Research date:** 2026-04-01
**Valid until:** 2026-05-01 (stable domain -- no fast-moving dependencies)
