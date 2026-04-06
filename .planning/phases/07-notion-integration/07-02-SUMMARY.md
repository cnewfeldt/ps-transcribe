---
phase: 07-notion-integration
plan: 02
subsystem: ui
tags: [swift, swiftui, notion, keychain, settings]

# Dependency graph
requires: []
provides:
  - Notion settings section in SettingsView with four UI states
  - KeychainHelper for secure API key storage
  - NotionService actor for Notion API auth, validation, and transcript export
  - AppSettings.notionDatabaseID property (UserDefaults-backed)
  - SettingsView accepts notionService parameter, instantiated once in PSTranscribeApp
affects:
  - 07-03-notion-send (uses NotionService and notionDatabaseID)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Actor-based service instantiated at App level and passed to Settings scene (matches OllamaState pattern from Phase 05)"
    - "Local @State drives async validation flow in SettingsView without polluting AppSettings"
    - "Notion URL parsing extracts 32-char hex ID via regex; API receives clean ID without dashes"

key-files:
  created:
    - PSTranscribe/Sources/PSTranscribe/Notion/KeychainHelper.swift
    - PSTranscribe/Sources/PSTranscribe/Notion/NotionService.swift
  modified:
    - PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift
    - PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift
    - PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift

key-decisions:
  - "NotionService and KeychainHelper created in this plan (07-02) since 07-01 runs in parallel in a separate worktree; this avoids a compilation dependency gap"
  - "SettingsView frame increased from height 520 to 640 to accommodate ~120pt of Notion section content"
  - "Auto-validate on appear: if API key exists in Keychain, testConnection() runs immediately without user interaction; if databaseID is stored, validateDatabase() follows"
  - "notionAPIKeyInput cleared after save (SecureField only used for paste-and-save; stored key is never re-displayed)"

patterns-established:
  - "NotionService instantiation: single actor instance at PSTranscribeApp level, passed into SettingsView -- matches OllamaState/OllamaService pattern"

requirements-completed: []

# Metrics
duration: 18min
completed: 2026-04-06
---

# Phase 07 Plan 02: Settings Notion Section Summary

**Notion settings section in SettingsView with four UI states (not configured / validating / connected / fully configured), KeychainHelper for Keychain-backed API key storage, and NotionService actor for connection validation and transcript export**

## Performance

- **Duration:** 18 min
- **Started:** 2026-04-06T00:00:00Z
- **Completed:** 2026-04-06T00:18:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `notionDatabaseID` to AppSettings (UserDefaults-backed, non-secret)
- Created KeychainHelper using SecItem APIs for save/read/delete operations
- Created NotionService actor with testConnection, validateDatabase, and sendTranscript
- Added Notion section to SettingsView with all four UI states and async validation flow
- Auto-validates on appear if API key exists in Keychain
- Parses Notion database URLs to extract 32-char hex ID
- Increased SettingsView frame height from 520 to 640 to accommodate new section
- Passed NotionService from PSTranscribeApp into SettingsView (single instance)

## Task Commits

1. **Task 1+2: AppSettings + SettingsView Notion section + frame height** - `39df0bb` (feat)

## Files Created/Modified

- `PSTranscribe/Sources/PSTranscribe/Notion/KeychainHelper.swift` - Keychain save/read/delete via SecItem APIs
- `PSTranscribe/Sources/PSTranscribe/Notion/NotionService.swift` - Notion API actor: auth, validation, send
- `PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift` - Added notionDatabaseID property
- `PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift` - Notion section with four states, height 640
- `PSTranscribe/Sources/PSTranscribe/App/PSTranscribeApp.swift` - notionService instance, pass to SettingsView

## Decisions Made

- NotionService created here (not waiting for 07-01) since parallel worktree execution requires self-contained compilation
- SettingsView height raised to 640 (from 520) -- Notion section adds ~120pt; 640 provides comfortable fit
- notionAPIKeyInput is cleared after successful save; the key is never re-fetched from Keychain for display (security best practice)
- Auto-validation on appear matches plan requirement: no user click needed if credentials are already stored

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Created KeychainHelper and NotionService in this plan**
- **Found during:** Task 1 (SettingsView Notion section)
- **Issue:** Plan 07-01 (which creates NotionService and KeychainHelper) runs in a parallel worktree and its commits are not present in this worktree. SettingsView cannot compile without these types.
- **Fix:** Implemented KeychainHelper and NotionService from the design document spec, creating the Notion/ directory and both files.
- **Files modified:** KeychainHelper.swift (new), NotionService.swift (new)
- **Verification:** `swift build` clean
- **Committed in:** 39df0bb (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (blocking dependency gap from parallel execution)
**Impact on plan:** Required to compile. Implementation matches the design document spec exactly. No scope creep.

## Issues Encountered

None beyond the parallel worktree dependency gap (handled above).

## Known Stubs

None -- all Notion section states are fully wired to NotionService. The API key and database validation flow is live (not mocked).

## Next Phase Readiness

- NotionService, KeychainHelper, AppSettings.notionDatabaseID, and SettingsView Notion section all ready for 07-03
- Plan 07-03 can read `settings.notionDatabaseID` and call `notionService.sendTranscript(...)` directly
- `notionStatus == .fullyConfigured` is the gate condition for enabling "Send to Notion" in library context menus

---
*Phase: 07-notion-integration*
*Completed: 2026-04-06*
