# Phase 10: Final Defect Fixes + Obsidian Deep-Link - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-04-07
**Phase:** 10-final-defect-fixes-obsidian-deeplink
**Areas discussed:** Obsidian deep-link UX, Utterance removal fix scope, Crash recovery session type

---

## Obsidian Deep-Link UX

| Option | Description | Selected |
|--------|-------------|----------|
| Context menu item | Add 'Open in Obsidian' to right-click context menu alongside 'Show in Finder' and 'Open in Notion'. Consistent with existing patterns. | ✓ |
| Visible button on each row | Small Obsidian icon/button always visible on each library entry row. More discoverable but adds visual clutter. | |
| Both -- button + context menu | Icon button on the row for quick access, plus context menu entry for discoverability. | |

**User's choice:** Context menu item (Recommended)
**Notes:** Follows existing pattern in LibraryEntryRow

### Vault Name Resolution

| Option | Description | Selected |
|--------|-------------|----------|
| Derive from vault path | Extract vault name from directory structure of vaultMeetingsPath/vaultVoicePath. No new settings needed. | ✓ |
| New setting field | Add a dedicated 'Obsidian Vault Name' text field in Settings. More explicit but one more thing to configure. | |
| You decide | Claude picks the simplest approach. | |

**User's choice:** Derive from vault path (Recommended)

### Fallback Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Hide the menu item | Don't show 'Open in Obsidian' if vault paths are empty/default. | |
| Show disabled with tooltip | Show grayed-out 'Open in Obsidian' with tooltip guidance. Teaches users the feature exists. | ✓ |
| Always show, alert on failure | Always show, alert with guidance on click failure. | |

**User's choice:** Show disabled with tooltip

---

## Utterance Removal Fix Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Fix speaker label only | Just fix .you/.them/.named mapping at line 449. Minimal change, minimal risk. | ✓ |
| Harden entire removal function | Also add fallback matching (e.g., match by text content). More robust but larger scope. | |

**User's choice:** Fix speaker label only (Recommended)
**Notes:** The timestamp logic works fine -- only the speaker label mapping is wrong.

---

## Crash Recovery Session Type

| Option | Description | Selected |
|--------|-------------|----------|
| Infer from vault path | If transcriptPath contains vaultVoicePath -> .voiceMemo, else .callCapture. No checkpoint migration. | ✓ |
| Add sessionType to checkpoint | Extend SessionCheckpoint struct. Requires backward compat handling. | |
| Parse transcript frontmatter | Read YAML frontmatter from transcript file. Requires file I/O during scan. | |

**User's choice:** Infer from vault path (Recommended)

### Fallback When Path Doesn't Match

| Option | Description | Selected |
|--------|-------------|----------|
| Default to .callCapture | Same as current behavior. Call capture is more common. | ✓ |
| Default to .voiceMemo | Simpler, less misleading if wrong. | |
| You decide | Claude picks the most sensible default. | |

**User's choice:** Default to .callCapture

---

## Claude's Discretion

- Obsidian URI path encoding details
- Exact tooltip wording for disabled menu item
- Whether to future-proof SessionCheckpoint with sessionType field

## Deferred Ideas

None -- discussion stayed within phase scope
