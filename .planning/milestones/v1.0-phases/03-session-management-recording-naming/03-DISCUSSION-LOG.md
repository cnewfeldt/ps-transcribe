# Phase 3: Session Management + Recording Naming - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-04-02
**Phase:** 03-session-management-recording-naming
**Areas discussed:** Library presentation, Naming interaction, Session lifecycle flow, Obsidian deep links

---

## Library Presentation

### Layout Integration

| Option | Description | Selected |
|--------|-------------|----------|
| Sidebar | Persistent sidebar on left showing library list, transcript on right. Similar to Notes.app. Library always visible. | ✓ |
| Separate tab/view | Toggle between library grid and transcript view. Library is full-screen grid. Like Voice Memos.app. | |
| Overlay/sheet | Library appears as sheet/popover triggered by button. Transcript view stays primary. | |

**User's choice:** Sidebar
**Notes:** Natural macOS pattern. Window will need wider min width.

### Entry Information

| Option | Description | Selected |
|--------|-------------|----------|
| Name + date + duration | Recording name, date, duration. Type icon distinguishes call vs memo. | ✓ |
| File status indicator | Subtle "missing" badge if transcript file moved/deleted. | ✓ |
| First few words preview | 1-line snippet of transcript content below name. | ✓ |
| Source app tag | Which app was captured (Teams, Zoom, etc.) as small tag. | ✓ |

**User's choice:** All four options selected (multi-select)
**Notes:** Rich library entries with all available metadata.

### Sort Order

| Option | Description | Selected |
|--------|-------------|----------|
| Most recent first | Newest at top, chronological descending. | ✓ |
| Grouped by date | Section headers like "Today", "Yesterday", "This Week". | |
| You decide | Claude picks best approach. | |

**User's choice:** Most recent first

### Empty State

| Option | Description | Selected |
|--------|-------------|----------|
| Prompt to record | Message like "No recordings yet" with arrow pointing to controls. Friendly, actionable. | ✓ |
| Minimal placeholder | Just "No recordings" with no call to action. | |
| You decide | Claude picks based on existing empty state pattern. | |

**User's choice:** Prompt to record

---

## Naming Interaction

### Name Field Location

| Option | Description | Selected |
|--------|-------------|----------|
| Top bar inline | Top bar becomes editable text field during/after recording. Tap to type. Always visible. | ✓ |
| Library entry rename | No name field during recording. Name set by clicking title in sidebar after saving. | |
| Floating name bar | Separate small text field appears above transcript when recording starts. | |

**User's choice:** Top bar inline
**Notes:** Natural placement, no extra UI chrome. Placeholder "Name this recording" when empty.

### Library Rename UX

| Option | Description | Selected |
|--------|-------------|----------|
| Click-to-edit inline | Click name in sidebar, becomes text field. Enter or click away to confirm. File renames immediately. | ✓ |
| Context menu rename | Right-click entry, select "Rename". Text field appears inline. | |
| Both | Click-to-edit plus right-click context menu. | |

**User's choice:** Click-to-edit inline

### Fallback Name Format

| Option | Description | Selected |
|--------|-------------|----------|
| Type + date | E.g. "Call Recording -- Apr 2, 2026" or "Voice Memo -- Apr 2, 2026". | ✓ |
| Just date/time | E.g. "Apr 2, 2026 3:42 PM". Minimal, type shown via icon. | |
| You decide | Claude picks based on existing filename conventions. | |

**User's choice:** Type + date

---

## Session Lifecycle Flow

### After Stop Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Keep transcript, select in sidebar | Transcript stays visible. New library entry appears in sidebar, auto-selected. No jarring clear. | ✓ |
| Clear immediately, show library | Transcript clears right after stop. Main panel shows empty state. Clean break. | |
| Clear after delay | Transcript stays briefly with save banner, then fades to empty state. | |

**User's choice:** Keep transcript, select in sidebar
**Notes:** Smooth transition. User can browse away when ready.

### New Recording While Viewing Past Transcript

| Option | Description | Selected |
|--------|-------------|----------|
| Switch to live view | Right panel switches to live recording view immediately. No confirmation dialog. | ✓ |
| Confirm before switching | Brief confirmation dialog before starting new recording. | |
| You decide | Claude picks based on frictionless recording principle. | |

**User's choice:** Switch to live view

### Loading Past Transcripts

| Option | Description | Selected |
|--------|-------------|----------|
| Parse and render in-app | Read markdown, parse utterances, display in TranscriptView. Full in-app experience. | ✓ |
| Open in default editor | Click opens .md file in system default editor or Obsidian. Simpler but leaves app. | |
| Read-only text view | Show raw markdown in simple text view. No parsing into utterance format. | |

**User's choice:** Parse and render in-app

---

## Obsidian Deep Links

### Vault Name Discovery

| Option | Description | Selected |
|--------|-------------|----------|
| User configures in Settings | Text field in Settings alongside vault path fields. One-time setup. Simple, reliable. | ✓ |
| Auto-detect from .obsidian folder | Walk up directory tree looking for .obsidian/ directory. Automatic but fragile. | |
| Both with auto-detect fallback | Try auto-detection, fall back to user config. More complex. | |

**User's choice:** User configures in Settings

### Link Placement

| Option | Description | Selected |
|--------|-------------|----------|
| Icon button on entry | Small Obsidian icon on each sidebar entry. Click to open in Obsidian. Disabled if vault name not configured. | ✓ |
| In transcript header | "Open in Obsidian" button in right panel header when viewing past transcript. | |
| Both | Icon in sidebar AND button in transcript header. | |

**User's choice:** Icon button on entry

---

## Claude's Discretion

- Session index storage format and location
- Data model design for library entries
- Markdown parsing strategy for loaded transcripts
- How incomplete sessions from Phase 2 checkpoints appear in library
- Sidebar width and resize behavior
- Top bar layout adaptation between branding and name input modes

## Deferred Ideas

None -- discussion stayed within phase scope.
