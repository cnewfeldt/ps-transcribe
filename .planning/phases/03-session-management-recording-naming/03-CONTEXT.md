# Phase 3: Session Management + Recording Naming - Context

**Gathered:** 2026-04-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Users get a persistent, browsable library of past recordings with reliable session lifecycle, flexible naming, and direct Obsidian access. The library is a sidebar that's always visible. Sessions save to the library on stop, and new recordings never overwrite old ones. Users can name recordings at any time -- before, during, or after -- with date-based fallback for unnamed recordings.

</domain>

<decisions>
## Implementation Decisions

### Library Presentation
- **D-01:** Library is a persistent sidebar on the left side of the main window. Transcript/recording view is on the right. Similar to Notes.app layout. Window min width will need to expand beyond current 280-360px.
- **D-02:** Each library entry shows: recording name (or type+date fallback), date, duration, session type icon (mic/phone), file status indicator (missing badge if file moved/deleted), first-line transcript preview, and source app tag (Teams, Zoom, etc.).
- **D-03:** Library sorted most recent first, chronological descending.
- **D-04:** Empty library shows an actionable prompt: "No recordings yet -- start a call capture or voice memo" with guidance toward controls.

### Naming Interaction
- **D-05:** Name input is inline in the top bar. The top bar (currently "TOME" + timer) becomes an editable text field. Placeholder text like "Name this recording" when empty. Editable before, during, and after recording.
- **D-06:** Renaming from library uses click-to-edit inline on the name in the sidebar entry. Click the name, it becomes a text field, press Enter or click away to confirm. File on disk renames immediately.
- **D-07:** Unnamed recordings fall back to "Call Recording -- Apr 2, 2026" or "Voice Memo -- Apr 2, 2026" format, matching the session type.

### Session Lifecycle
- **D-08:** After stopping, the transcript stays visible in the right panel. The new library entry appears in the sidebar and is auto-selected. No jarring clear. Save confirmation shown inline.
- **D-09:** Starting a new recording while viewing a past transcript switches the right panel to the live recording view immediately -- no confirmation dialog. The new recording appears at top of sidebar as active entry. Past transcripts remain accessible via sidebar.
- **D-10:** Clicking a library entry parses the markdown file and renders utterances in TranscriptView. Full in-app reading experience -- user doesn't leave the app.

### Obsidian Deep Links
- **D-11:** User configures Obsidian vault name as a text field in Settings alongside existing vault path fields. One-time setup. No auto-detection.
- **D-12:** Each library sidebar entry has a small Obsidian icon button. Click opens the transcript in Obsidian via `obsidian://open?vault=NAME&file=RELATIVE_PATH`. Disabled/hidden if vault name not configured.

### Claude's Discretion
- Session index storage format and location (JSON in Application Support is the natural choice)
- Data model design for library entries (LibraryEntry struct or similar)
- Markdown parsing strategy for loading past transcripts into TranscriptView
- How incomplete sessions from Phase 2's checkpoint system appear in the library
- Sidebar width and resize behavior
- How the top bar layout adapts between "app title" mode and "name input" mode

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` -- SESS-01 through SESS-09, NAME-01 through NAME-05

### Core Source Files
- `PSTranscribe/Sources/PSTranscribe/Storage/SessionStore.swift` -- Actor for session JSONL + checkpoint system. Currently has NO library concept -- only crash recovery. New library index will likely live alongside or extend this.
- `PSTranscribe/Sources/PSTranscribe/Storage/TranscriptLogger.swift` -- Writes markdown transcripts to vault paths. Has `sanitizedFilenameComponent()`, `atomicRewrite()`, and context-based file rename in `finalizeFrontmatter()`. The naming/rename logic connects here.
- `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift` -- Main UI orchestrator. Session start/stop logic, save banner, transcript binding. Will need major restructuring to add sidebar layout.
- `PSTranscribe/Sources/PSTranscribe/Models/Models.swift` -- Speaker, Utterance, SessionRecord types. Library entry model will be added here or in a new file.
- `PSTranscribe/Sources/PSTranscribe/Models/TranscriptStore.swift` -- @Observable transcript state. Loading past transcripts will interact with this.
- `PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift` -- User preferences with didSet/UserDefaults sync. Obsidian vault name setting goes here.

### Views
- `PSTranscribe/Sources/PSTranscribe/Views/ControlBar.swift` -- Record button + status. Controls stay in the bottom area.
- `PSTranscribe/Sources/PSTranscribe/Views/TranscriptView.swift` -- Scrollable utterance list. Will be reused for both live and loaded transcripts.
- `PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift` -- Preferences UI. Obsidian vault name field added here.

### Codebase Analysis
- `.planning/codebase/ARCHITECTURE.md` -- Actor isolation model, data flow, state management patterns
- `.planning/codebase/CONVENTIONS.md` -- Naming patterns, concurrency patterns, SwiftUI patterns to follow
- `.planning/codebase/STRUCTURE.md` -- Directory layout and where to add new code

### Prior Phase Context
- `.planning/phases/02-security-stability/02-CONTEXT.md` -- D-06/D-07: checkpoint-based crash recovery surfaces incomplete sessions. Library must display these.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `TranscriptLogger.sanitizedFilenameComponent()` -- whitelist-based filename sanitization, already handles NAME-05 rename safety
- `TranscriptLogger.atomicRewrite()` -- safe file rewrite pattern for rename operations
- `TranscriptLogger.finalizeFrontmatter()` -- already renames files based on context, pattern to extend for user-provided names
- `TranscriptView` -- existing scrollable utterance display, reusable for both live and loaded transcripts
- `SessionStore.scanIncompleteCheckpoints()` -- returns incomplete sessions from prior crashes, library should surface these
- `ControlBar` -- existing record controls, will remain in bottom bar area

### Established Patterns
- **Actor isolation:** SessionStore and TranscriptLogger are actors. New library index persistence should follow the same actor pattern.
- **@Observable + MainActor:** TranscriptStore, AppSettings, TranscriptionEngine are @Observable @MainActor. Library state model should follow this pattern.
- **UserDefaults via didSet:** AppSettings syncs preferences this way. Obsidian vault name should use same pattern.
- **os.Logger:** `Logger(subsystem: "com.pstranscribe.app", category: "TypeName")` established in Phase 2.
- **POSIX permissions:** 0o600 on files, 0o700 on directories. New library index file follows this.

### Integration Points
- **ContentView restructuring:** Currently a single-column VStack (280-360px). Needs to become a NavigationSplitView or HSplitView with sidebar + detail.
- **Top bar modification:** Currently shows "TOME" text + timer. Becomes an editable TextField for recording name.
- **Session start/stop:** `startSession()` and `stopSession()` in ContentView need to create/update library entries.
- **TranscriptLogger connection:** When user sets a name (top bar), it needs to flow to TranscriptLogger's context/filename. `updateContext()` method already exists for this.

</code_context>

<specifics>
## Specific Ideas

- The sidebar layout is similar to Notes.app -- library list on left, content on right. This is a common macOS pattern with NavigationSplitView.
- The top bar name field is a dual-purpose element: shows "PS TRANSCRIBE" branding when no recording, becomes editable TextField during/after sessions.
- Library entries should include the full file path so the "Show in Finder" action (currently in save banner) can move to the library entry context.
- The markdown parsing for loading past transcripts needs to handle the existing format: YAML frontmatter + `**Speaker** (HH:mm:ss)\ntext\n\n` pattern.

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope.

</deferred>

---

*Phase: 03-session-management-recording-naming*
*Context gathered: 2026-04-02*
