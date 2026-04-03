---
phase: 02-security-stability
plan: "03"
subsystem: storage
tags: [swift, file-io, security, atomic-writes, posix-permissions, path-validation]

requires:
  - phase: 02-02
    provides: os.Logger pattern established (file-level Logger with subsystem com.pstranscribe.app)

provides:
  - Vault path traversal validation (validatedVaultPath rejects '..' and null bytes)
  - POSIX 0600 permissions on all transcript files at creation
  - atomicRewrite helper consolidating all write-remove-move sequences
  - Whitelist filename sanitization (alphanumeric + space/hyphen/underscore/period)
  - Explicit do/catch error handling replacing 14 DANGEROUS try? instances
  - os.Logger error logging on all converted data-path sites

affects:
  - 02-04 (SessionStore hardening follows same try? conversion pattern)
  - 02-05 (SystemAudioCapture try? conversion uses same pattern)

tech-stack:
  added: []
  patterns:
    - "atomicRewrite: write-to-temp -> set 0600 -> remove-original -> move-to-dest, abort on any step failure"
    - "rewriteFrontmatter refactored from static to instance method to use atomicRewrite"
    - "try? on fileHandle.close() and NSRegularExpression with hardcoded pattern remain SAFE"
    - "Thrown errors from TranscriptLogger data-path methods surface via os.Logger AND propagate to caller"

key-files:
  created: []
  modified:
    - PSTranscribe/Sources/PSTranscribe/Storage/TranscriptLogger.swift
    - PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift

key-decisions:
  - "rewriteFrontmatter converted from static to instance method so it can call atomicRewrite -- cleaner than duplicating the atomic write logic inline"
  - "sanitizedFilenameComponent used in both finalizeFrontmatter and rewriteFrontmatter to eliminate the duplicate inline whitelist blocks"
  - "updateContext and rewriteWithDiarization now throw -- ContentView call site wraps rewriteWithDiarization in do/catch setting lastError per D-02"

patterns-established:
  - "atomicRewrite(at:newPath:content:): canonical write-remove-move with os.Logger at each failure point"
  - "5 SAFE try? remaining: 2x fileHandle.close() cleanup, 1x NSRegularExpression hardcoded, 2x atomicRewrite error-path cleanup"

requirements-completed: [SECR-03, SECR-06, SECR-09, SECR-10]

duration: 25min
completed: 2026-04-03
---

# Phase 02 Plan 03: TranscriptLogger Security Hardening Summary

**TranscriptLogger hardened with vault path traversal rejection, POSIX 0600 permissions, atomicRewrite helper replacing all 3 write-remove-move sequences, and whitelist filename sanitization -- 14 DANGEROUS try? converted to explicit do/catch with os.Logger**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-04-03T04:30:00Z
- **Completed:** 2026-04-03T04:55:00Z
- **Tasks:** 2 (implemented together in one cohesive file rewrite)
- **Files modified:** 3

## Accomplishments

- SCAN-003 resolved: `validatedVaultPath()` rejects paths containing `..` or null bytes before any createDirectory/createFile call
- SCAN-006 resolved: transcript files created with `setAttributes(.posixPermissions: 0o600)` immediately after createFile
- SCAN-009 resolved: `atomicRewrite()` helper consolidates all three write-remove-move sequences; original file is always preserved on partial failure
- SCAN-010 resolved: `sanitizedFilenameComponent()` whitelist (alphanumeric + space/hyphen/underscore/period) replaces the old blocklist (only stripped `/` and `:`)
- All 14 DANGEROUS try? instances converted to do/catch with os.Logger error logging; 5 SAFE try? remain (all cleanup-only paths)

## Task Commits

1. **Task 1 + Task 2: Add helpers and convert all dangerous try? instances** - `9081668` (feat)

## Files Created/Modified

- `PSTranscribe/Sources/PSTranscribe/Storage/TranscriptLogger.swift` - Full hardening: os.Logger, validatedVaultPath, sanitizedFilenameComponent, atomicRewrite, POSIX 0600, all dangerous try? converted
- `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift` - Fixed rewriteWithDiarization call site (now throws, wrapped in do/catch setting lastError)
- `PSTranscribe/Package.resolved` - Unchanged content, dependency resolution artifact

## Decisions Made

- `rewriteFrontmatter` refactored from `private static func` to `private func` so it can call `atomicRewrite` -- avoids duplicating 20+ lines of atomic write logic in a static context
- `sanitizedFilenameComponent` used in both `finalizeFrontmatter` and `rewriteFrontmatter` replacing two copies of the inline whitelist filter
- `updateContext` and `rewriteWithDiarization` changed to `throws` -- ContentView wraps `rewriteWithDiarization` in do/catch per D-02 (os.Logger logs AND caller surfaces error via `lastError`)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed ContentView call site for rewriteWithDiarization**
- **Found during:** Task 2 verification (swift build)
- **Issue:** rewriteWithDiarization was changed to `throws` but the ContentView call site was `await transcriptLogger.rewriteWithDiarization(...)` without try/catch -- compile error
- **Fix:** Wrapped in do/catch setting `transcriptionEngine?.lastError = error.localizedDescription` per D-02
- **Files modified:** PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift
- **Verification:** swift build succeeded
- **Committed in:** 9081668 (Task commit)

**2. [Rule 1 - Refactor] Converted rewriteFrontmatter from static to instance method**
- **Found during:** Task 2 implementation (try? count exceeded 5)
- **Issue:** rewriteFrontmatter was `private static func`, meaning it couldn't call `atomicRewrite` (instance method). Leaving it static required duplicating the full write-remove-move logic inline, producing 3 extra try? cleanup instances
- **Fix:** Changed to `private func`, updated the one call site in `finalizeFrontmatter` from `await Self.rewriteFrontmatter(...)` to `await rewriteFrontmatter(...)`
- **Files modified:** PSTranscribe/Sources/PSTranscribe/Storage/TranscriptLogger.swift
- **Verification:** swift build succeeded; try? count reduced to 5 (all SAFE)
- **Committed in:** 9081668 (Task commit)

---

**Total deviations:** 2 auto-fixed (1 blocking compile error, 1 refactor to eliminate duplication)
**Impact on plan:** Both necessary. No scope creep. The static-to-instance refactor was required to achieve the plan's goal of using atomicRewrite in all three rewrite sites.

## Issues Encountered

None beyond the deviations above.

## User Setup Required

None -- no external service configuration required.

## Next Phase Readiness

- TranscriptLogger is fully hardened. SECR-03, SECR-06, SECR-09, SECR-10 resolved.
- Plan 02-04 (SessionStore) and Plan 02-05 (SystemAudioCapture) can proceed with try? conversions using the same do/catch + os.Logger pattern.
- The atomicRewrite helper is private to TranscriptLogger -- if SessionStore needs similar hardening, it would need its own implementation or a shared utility.

## Known Stubs

None -- all changes are behavioral security hardening with no placeholder data.

---
*Phase: 02-security-stability*
*Completed: 2026-04-03*
