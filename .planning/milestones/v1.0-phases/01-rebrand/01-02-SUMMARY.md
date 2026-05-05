---
phase: 01-rebrand
plan: 02
subsystem: infra
tags: [swift, github-actions, sparkle, codesign, dmg, plist, ci-cd]

# Dependency graph
requires:
  - phase: 01-rebrand/01-01
    provides: PSTranscribe Swift package directory structure with renamed source files

provides:
  - Info.plist fully updated with com.pstranscribe.app bundle ID and PS Transcribe display name
  - build_swift_app.sh produces PS Transcribe.app with correct paths and bundle ID
  - make_dmg.sh produces PS Transcribe.dmg with correct volume name and AppleScript references
  - CI workflows reference PSTranscribe paths with no residual Tome/Gremble references
  - Placeholder OWNER/ps-transcribe URLs documented with TODO comments for future repo creation

affects: [release, distribution, sparkle, ci-cd]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Placeholder pattern: OWNER/ps-transcribe used in URLs pending GitHub repo creation, marked with TODO comments"

key-files:
  created: []
  modified:
    - PSTranscribe/Sources/PSTranscribe/Info.plist
    - scripts/build_swift_app.sh
    - scripts/make_dmg.sh
    - .github/workflows/build-check.yml
    - .github/workflows/release-dmg.yml

key-decisions:
  - "SUFeedURL placeholder uses OWNER/ps-transcribe per open question in Research -- exact repo URL TBD when new GitHub repo created"
  - "DMG_URL in release workflow uses URL-encoded PS%20Transcribe.dmg to handle filename with spaces"

patterns-established:
  - "Placeholder pattern: TODO comments mark OWNER placeholder in CI workflow for when actual GitHub repo URL is known"

requirements-completed: [REBR-05, REBR-06, REBR-07]

# Metrics
duration: 15min
completed: 2026-04-01
---

# Phase 01 Plan 02: Build and CI Rebrand Summary

**Info.plist, build scripts, and CI workflows updated to reference com.pstranscribe.app and PS Transcribe artifact names with placeholder OWNER URLs pending new GitHub repo creation**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-04-01T00:00:00Z
- **Completed:** 2026-04-01T00:15:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Info.plist SUFeedURL updated from Gremble-io/Tome to OWNER/ps-transcribe placeholder
- build_swift_app.sh and make_dmg.sh fully rebranded -- no residual Tome references in any build script
- Both CI workflows (build-check.yml, release-dmg.yml) updated to PSTranscribe paths and PS Transcribe artifact names
- Placeholder OWNER/ps-transcribe URLs documented with TODO comments across Info.plist and release-dmg.yml

## Task Commits

Each task was committed atomically:

1. **Task 1: Update Info.plist and build scripts** - `056a4b7` (feat)
2. **Task 2: Update CI workflows** - `e6feb1f` (feat)

## Files Created/Modified

- `PSTranscribe/Sources/PSTranscribe/Info.plist` - Updated SUFeedURL to OWNER/ps-transcribe placeholder
- `scripts/build_swift_app.sh` - SWIFT_DIR, APP_NAME, BUNDLE_ID, BINARY_PATH, all path refs rebranded
- `scripts/make_dmg.sh` - APP_PATH, DMG_PATH, TEMP_DMG, volname, AppleScript disk/item refs rebranded
- `.github/workflows/build-check.yml` - working-directory: Tome -> PSTranscribe
- `.github/workflows/release-dmg.yml` - PLIST path, artifact name, DMG paths, Sparkle find path, appcast content, repo URLs all updated

## Decisions Made

- SUFeedURL in Info.plist uses placeholder `https://raw.githubusercontent.com/OWNER/ps-transcribe/gh-pages/appcast.xml` per open question in Research -- exact URL set when new GitHub repo is created
- DMG_URL in release workflow uses URL-encoded `PS%20Transcribe.dmg` to handle the space in the filename correctly in URLs

## Deviations from Plan

None -- plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None -- no external service configuration required. The OWNER placeholder in Info.plist and release-dmg.yml must be replaced with the actual GitHub org/user when the ps-transcribe repo is created. TODO comments mark each location.

## Next Phase Readiness

- All build and CI infrastructure is rebranded; no Tome or Gremble references remain in build/CI files
- Scripts will produce `PS Transcribe.app` and `PS Transcribe.dmg` artifacts
- Sparkle URL placeholder must be resolved when new GitHub repo is created before the release workflow can publish appcast updates
- Phase 01 plan 03 (UserDefaults migration) can proceed immediately

---
*Phase: 01-rebrand*
*Completed: 2026-04-01*
