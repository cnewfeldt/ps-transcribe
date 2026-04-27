# Phase 2: Security + Stability - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-04-02
**Phase:** 02-security-stability
**Areas discussed:** Error handling strategy, File permissions model, Crash recovery behavior, Debug logging approach

---

## Error Handling Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Audit each individually | Review every try? instance, categorize as safe vs dangerous, fix dangerous ones | ✓ |
| Fix data-path try? only | Focus on file I/O sequences where silent failure causes data loss | |
| Replace all with do/catch | Blanket replacement of every try? with proper error handling | |

**User's choice:** Audit each individually
**Notes:** Aligns with STATE.md blocker note about individual audit

### Error Surfacing

| Option | Description | Selected |
|--------|-------------|----------|
| Log + UI banner | Log via os.Logger AND show non-blocking banner/toast. Recording continues. | ✓ |
| Log only | Log for diagnostics, no user interruption | |
| Log + stop recording | Log and stop recording since transcript can't be saved reliably | |

**User's choice:** Log + UI banner

### TranscriptLogger Write Pattern

| Option | Description | Selected |
|--------|-------------|----------|
| Atomic write pattern | Write to temp, verify, atomically replace original | ✓ |
| Rollback with backup | Copy original to backup, restore on failure | |
| You decide | Claude picks based on code structure | |

**User's choice:** Atomic write pattern

---

## File Permissions Model

| Option | Description | Selected |
|--------|-------------|----------|
| POSIX 0600 uniformly | Owner read/write only on all transcript, session, and audio temp files | ✓ |
| 0600 + FileProtection | POSIX 0600 plus macOS FileProtectionType.complete | |
| You decide | Claude picks based on macOS sandboxing context | |

**User's choice:** POSIX 0600 uniformly

### Audio Temp File Location

| Option | Description | Selected |
|--------|-------------|----------|
| App container temp | Use Application Support/PSTranscribe/tmp/ | ✓ |
| System temp + 0600 | Keep in /tmp with 0600 permissions | |
| You decide | Claude picks based on sandbox conventions | |

**User's choice:** App container temp

---

## Crash Recovery Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Surface incomplete session | Detect incomplete sessions on launch, show as 'incomplete' in library with partial content | ✓ |
| Auto-recover and finalize | Detect and attempt to finalize -- write frontmatter, run diarization | |
| Surface + offer recovery | Show dialog offering recovery choice | |

**User's choice:** Surface incomplete session

### Finalization Protection

| Option | Description | Selected |
|--------|-------------|----------|
| Checkpoint-based | Write checkpoint after each finalization step, resume from last on crash | ✓ |
| Flush frequently | Flush transcript every N utterances, finalization only at end | |
| You decide | Claude picks based on existing lifecycle code | |

**User's choice:** Checkpoint-based

---

## Debug Logging Approach

| Option | Description | Selected |
|--------|-------------|----------|
| DEBUG-only | All diagnostic logging compiled out of release builds | |
| Release with hidden toggle | os.Logger at .debug level in release, user-activatable | ✓ |
| Tiered logging | Critical errors in release, diagnostic only in DEBUG | |

**User's choice:** Release with hidden toggle

### Toggle Mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| UserDefaults key | `defaults write com.pstranscribe.app enableVerboseLogging -bool true` | ✓ |
| Settings pane toggle | Hidden toggle in Settings view behind modifier key | |
| You decide | Claude picks simplest approach | |

**User's choice:** UserDefaults key

---

## Claude's Discretion

Claude has flexibility on: vault path validation approach, filename sanitization implementation, GitHub Actions SHA pinning, CI keychain mktemp, .gitignore patterns, audio buffer clearing, CI cleanup logging, MicCapture error propagation, diarization timestamp fix.

## Deferred Ideas

None -- discussion stayed within phase scope.
