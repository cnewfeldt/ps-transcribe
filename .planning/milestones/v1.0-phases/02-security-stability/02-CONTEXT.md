# Phase 2: Security + Stability - Context

**Gathered:** 2026-04-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Resolve all 12 security scan findings (SCAN-001 through SCAN-012) and fix 4 stability bugs (STAB-01 through STAB-04). No new features, no UX changes beyond error surfacing. The app should be hardened and reliable before any feature work ships.

</domain>

<decisions>
## Implementation Decisions

### Error Handling Strategy
- **D-01:** Audit all 29 try? instances individually -- categorize each as safe (cleanup) or dangerous (data path) before changing anything
- **D-02:** Data-path file operation failures surface via os.Logger AND a non-blocking UI banner/toast. Recording continues despite the error.
- **D-03:** TranscriptLogger's write-remove-move sequence (SCAN-009) replaced with atomic write pattern: write to temp file, verify contents, atomically rename to replace original. If anything fails, original file is untouched.

### File Permissions Model
- **D-04:** All transcript, session, and audio temp files created with POSIX 0600 (owner read/write only). No FileProtectionType -- just POSIX permissions uniformly.
- **D-05:** Audio temp files (SCAN-004) moved from system /tmp to Application Support/PSTranscribe/tmp/. Sandboxed, auto-cleaned on uninstall, restricted permissions.

### Crash Recovery
- **D-06:** On next launch after crash, detect incomplete sessions (no finalization marker). Surface them in the library as "incomplete" with whatever transcript was flushed to disk. No auto-recovery attempt, no dialog -- just show what exists.
- **D-07:** Session finalization (STAB-03) uses checkpoint-based approach: write checkpoint file after each step (frontmatter done, diarization done, move done). On crash, resume from last completed checkpoint on next launch.

### Debug Logging
- **D-08:** Replace /tmp file logging (diagLog) with os.Logger. Logging available in release builds at .debug level (suppressed by default in Console.app).
- **D-09:** Hidden toggle via UserDefaults key: `defaults write com.pstranscribe.app enableVerboseLogging -bool true`. No UI toggle needed -- power-user mechanism documented in README or help.
- **D-10:** Existing diagLog calls converted to os.Logger equivalents, not removed. Function signature can change but call sites preserved.

### Claude's Discretion
- Exact POSIX permission API calls (FileManager attributes vs. POSIX chmod)
- Vault path traversal validation approach (SCAN-003) -- whitelist, resolve symlinks, or sandbox check
- Filename sanitization implementation (SCAN-010) -- whitelist vs blocklist character approach
- GitHub Actions SHA pinning -- look up current commit SHAs for actions/checkout@v4 and actions/upload-artifact@v4
- CI keychain mktemp pattern (SCAN-005) -- standard mktemp usage
- .gitignore secret patterns (SCAN-008) -- standard security patterns
- Audio buffer memory clearing (SCAN-011) -- removeAll(keepingCapacity: false) is straightforward
- CI cleanup error logging (SCAN-012) -- replace 2>/dev/null with logged cleanup
- MicCapture error propagation to UI (STAB-04) -- implementation via TranscriptionEngine.lastError
- Diarization timestamp fix (STAB-02) -- session-relative offsets instead of clock time

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Security Scan
- `SECURITY-SCAN.md` -- All 12 findings with exact file locations, code snippets, CWE categories, and severity ratings. The authoritative source for what needs fixing.

### Affected Source Files (post-rename paths)
- `PSTranscribe/Sources/PSTranscribe/Transcription/TranscriptionEngine.swift` -- diagLog function (SCAN-002), transcription pipeline
- `PSTranscribe/Sources/PSTranscribe/Storage/TranscriptLogger.swift` -- Vault path validation (SCAN-003), file permissions (SCAN-006), error suppression (SCAN-009), filename sanitization (SCAN-010)
- `PSTranscribe/Sources/PSTranscribe/Storage/SessionStore.swift` -- Session file permissions (SCAN-006), session records
- `PSTranscribe/Sources/PSTranscribe/Audio/SystemAudioCapture.swift` -- Audio temp files (SCAN-004)
- `PSTranscribe/Sources/PSTranscribe/Transcription/StreamingTranscriber.swift` -- Audio buffer memory (SCAN-011)
- `PSTranscribe/Sources/PSTranscribe/Audio/MicCapture.swift` -- Error propagation (STAB-04)

### CI/CD
- `.github/workflows/release-dmg.yml` -- GH_TOKEN exposure (SCAN-001), keychain temp (SCAN-005), unpinned actions (SCAN-007), cleanup suppression (SCAN-012)
- `.github/workflows/build-check.yml` -- Unpinned actions (SCAN-007)

### Codebase Analysis
- `.planning/codebase/CONCERNS.md` -- Detailed security concern analysis with recommendations
- `.planning/codebase/CONVENTIONS.md` -- Coding patterns to follow during fixes
- `.planning/codebase/ARCHITECTURE.md` -- Actor isolation model that affects error propagation design

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None directly reusable -- this phase is fixing existing code, not building new features

### Established Patterns
- **Actor isolation:** TranscriptLogger, SessionStore, and TranscriptionEngine are all MainActor-isolated. Error handling must respect actor boundaries.
- **@Observable state:** AppSettings and TranscriptionEngine use @Observable. Error state (STAB-04) should follow the same pattern via published properties.
- **UserDefaults via didSet:** AppSettings syncs to UserDefaults with didSet observers. The new enableVerboseLogging key should follow this pattern.
- **os.Logger subsystem:** Already updated to `com.pstranscribe.app` in Phase 1 (StreamingTranscriber.swift). New Logger instances should use the same subsystem with different categories.

### Integration Points
- **TranscriptionEngine.lastError:** STAB-04 requires a new error property that MicCapture errors flow into. ContentView already observes TranscriptionEngine.
- **Session library:** STAB-01 (crash recovery) surfaces incomplete sessions -- this connects to Phase 3's session library, but Phase 2 only needs to mark them, not display them in a grid.
- **Checkpoint files:** D-07 introduces checkpoint files in Application Support. These are new artifacts that Phase 3's session lifecycle will need to understand.

</code_context>

<specifics>
## Specific Ideas

- STATE.md has a blocker note: "try? replacements in TranscriptLogger must be audited individually -- bulk replacement without audit will cause data loss." This aligns with D-01.
- The checkpoint-based finalization (D-07) should write checkpoint files alongside the session data in Application Support/PSTranscribe/, not in /tmp.

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope.

</deferred>

---

*Phase: 02-security-stability*
*Context gathered: 2026-04-02*
