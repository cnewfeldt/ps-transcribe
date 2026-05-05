# Phase 1: Rebrand - Context

**Gathered:** 2026-04-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Rename "Tome" to "PS Transcribe" across all code, configuration, CI/CD, and user settings. Zero data loss for existing users upgrading from Tome. No new features, no behavior changes -- purely identity transformation.

</domain>

<decisions>
## Implementation Decisions

### Bundle Identifier
- **D-01:** New bundle ID is `com.pstranscribe.app` (replacing `io.gremble.tome`)
- **D-02:** Logger subsystem strings updated to `com.pstranscribe.app` (full clean break, no stale references to old ID)

### UserDefaults Migration
- **D-03:** Migration runs synchronously in the app struct's `init()`, before any SwiftUI views or @Observable objects are created -- guarantees settings are available before any observer reads vault paths
- **D-04:** Old UserDefaults keys (from `io.gremble.tome` domain) are deleted immediately after successful copy to new domain -- no rollback support, clean break

### Directory and Module Naming
- **D-05:** Swift module name is `PSTranscribe` (PascalCase, matches Swift convention)
- **D-06:** Source directory renamed from `Sources/Tome/` to `Sources/PSTranscribe/`
- **D-07:** Outer project directory renamed from `Tome/` to `PSTranscribe/` (contains Package.swift)
- **D-08:** Entitlements file renamed from `Tome.entitlements` to `PSTranscribe.entitlements`

### Sparkle Update Chain
- **D-09:** Clean break -- no Sparkle update path from Tome to PS Transcribe. Existing Tome users must download PS Transcribe separately
- **D-10:** New GitHub repo created for PS Transcribe with its own gh-pages branch for the appcast
- **D-11:** Appcast URL in Info.plist updated to point to the new repo's gh-pages

### Claude's Discretion
- Exact migration key list (enumerate from AppSettings.swift UserDefaults keys)
- Order of rename operations (directory renames, Package.swift updates, CI workflow edits)
- Whether to use git mv or manual rename for directory operations
- Info.plist field updates beyond SUFeedURL (CFBundleName, CFBundleIdentifier, etc.)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### App Configuration
- `PSTranscribe/Sources/PSTranscribe/Info.plist` -- Bundle metadata, SUFeedURL, CFBundleIdentifier (post-rename path)
- `PSTranscribe/Sources/PSTranscribe/PSTranscribe.entitlements` -- Sandbox permissions (post-rename path)
- `PSTranscribe/Package.swift` -- SwiftPM manifest with target names and dependencies (post-rename path)

### Current State (pre-rename paths for reference)
- `Tome/Sources/Tome/Settings/AppSettings.swift` -- All UserDefaults keys that need migration
- `Tome/Sources/Tome/App/TomeApp.swift` -- App entry point where migration must run
- `Tome/Sources/Tome/Transcription/StreamingTranscriber.swift` -- Logger subsystem string (`io.gremble.tome`)

### CI/CD
- `.github/workflows/release-dmg.yml` -- DMG signing, appcast generation, gh-pages push (all references to Tome/Gremble-io)
- `.github/workflows/build-check.yml` -- Build verification workflow

### Security Context
- `SECURITY-SCAN.md` -- 12 findings; Phase 1 should not introduce new issues but may touch files referenced here

### Codebase Analysis
- `.planning/codebase/STRUCTURE.md` -- Full directory layout and file purposes
- `.planning/codebase/CONVENTIONS.md` -- Naming patterns and coding standards to follow during rename

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None directly reusable -- this phase is a rename operation, not feature work

### Established Patterns
- **UserDefaults via didSet:** AppSettings.swift uses `didSet` observers to sync to UserDefaults with plain string keys ("transcriptionLocale", "inputDeviceID", "vaultMeetingsPath", "vaultVoicePath"). Migration must copy all of these.
- **Actor isolation:** Storage actors (TranscriptLogger, SessionStore) and @Observable classes (TranscriptionEngine, TranscriptStore, AppSettings) are all MainActor-isolated. Migration must complete before any of these initialize.
- **Logger subsystem:** `Logger(subsystem: "io.gremble.tome", category: "StreamingTranscriber")` in StreamingTranscriber.swift -- needs update to `com.pstranscribe.app`
- **diagLog path:** `/tmp/tome.log` in TranscriptionEngine.swift -- update to `/tmp/pstranscribe.log`

### Integration Points
- **Package.swift:** Target name "Tome" referenced in both the executable target and the exclude list
- **CI workflows:** Both workflows reference `Tome/` paths and `Gremble-io/Tome` repo
- **Sparkle appcast:** Generated in release-dmg.yml with hardcoded repo URL and pushed to gh-pages branch
- **App Support directory:** `~/Library/Application Support/Tome/sessions/` -- session JSONL files may need path migration or graceful fallback

</code_context>

<specifics>
## Specific Ideas

No specific requirements -- standard mechanical rename with the decisions above as constraints.

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope.

</deferred>

---

*Phase: 01-rebrand*
*Context gathered: 2026-04-01*
