# Phase 1: Rebrand - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-04-01
**Phase:** 01-rebrand
**Areas discussed:** New bundle identifier, UserDefaults migration strategy, Directory and module naming, Sparkle update chain

---

## New Bundle Identifier

| Option | Description | Selected |
|--------|-------------|----------|
| com.pstranscribe.app | Clean reverse-domain format, establishes PS Transcribe as its own brand | ✓ |
| io.gremble.pstranscribe | Keeps gremble namespace, consistent with existing io.gremble.tome | |
| com.gremble.pstranscribe | Hybrid -- gremble org with com prefix | |

**User's choice:** com.pstranscribe.app
**Notes:** None

### Follow-up: Logger subsystem

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, update everything | Logger subsystem becomes com.pstranscribe.app. Clean break. | ✓ |
| Keep logger subsystem as-is | Less churn but inconsistency in Console.app | |

**User's choice:** Yes, update everything
**Notes:** None

---

## UserDefaults Migration Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| App init, before any view loads | Synchronous in app struct init(). Guarantees settings available. | ✓ |
| AppDelegate applicationDidFinishLaunching | Slightly later in lifecycle. Views may already be initializing. | |
| Lazy on first read | Each UserDefaults read checks for migration. Distributed logic. | |

**User's choice:** App init, before any view loads
**Notes:** None

### Follow-up: Old key cleanup

| Option | Description | Selected |
|--------|-------------|----------|
| Keep old keys for one version | Safer rollback if user downgrades | |
| Delete old keys immediately | Clean state, no lingering data | ✓ |
| You decide | Claude picks | |

**User's choice:** Delete old keys immediately
**Notes:** None

---

## Directory and Module Naming

| Option | Description | Selected |
|--------|-------------|----------|
| PSTranscribe | PascalCase, matches Swift convention | ✓ |
| PsTranscribe | Lowercase 's', valid but less acronym-like | |
| PS_Transcribe | Underscore, unusual in Swift module names | |

**User's choice:** PSTranscribe
**Notes:** None

### Follow-up: Outer repo directory

| Option | Description | Selected |
|--------|-------------|----------|
| Rename to PSTranscribe/ | Consistent top to bottom | ✓ |
| Keep as Tome/ | Less git churn, doesn't affect builds | |

**User's choice:** Rename to PSTranscribe/
**Notes:** None

---

## Sparkle Update Chain

| Option | Description | Selected |
|--------|-------------|----------|
| Final Tome release points to new appcast | Seamless transition via one last Tome version | |
| GitHub repo redirect | Rename repo, GitHub auto-redirects old URLs | |
| Clean break, no migration | PS Transcribe is a fresh download | ✓ |

**User's choice:** Clean break, no migration
**Notes:** User asked to clarify what Sparkle is before deciding. After explanation of the framework and current setup (appcast on gh-pages of Gremble-io/Tome repo), chose clean break.

### Follow-up: New appcast hosting

| Option | Description | Selected |
|--------|-------------|----------|
| New repo for PS Transcribe | Fresh repo, fresh gh-pages. Clean separation. | ✓ |
| Rename existing Gremble-io/Tome repo | Same repo, new name. GitHub redirects temporarily. | |
| You decide | Claude picks simplest for CI | |

**User's choice:** New repo for PS Transcribe
**Notes:** None

---

## Claude's Discretion

- Exact migration key list (enumerate from AppSettings.swift)
- Order of rename operations
- git mv vs manual rename for directories
- Info.plist field updates beyond SUFeedURL

## Deferred Ideas

None -- discussion stayed within phase scope.
