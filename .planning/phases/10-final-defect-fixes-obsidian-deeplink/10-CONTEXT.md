# Phase 10: Final Defect Fixes + Obsidian Deep-Link - Context

**Gathered:** 2026-04-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix three remaining code defects from the v1.0 audit (named speaker utterance removal, crash-recovered session type, SESS-04 requirement text) and implement the Obsidian deep-link feature (SESS-06). No other new features -- strictly defect resolution plus one scoped addition.

</domain>

<decisions>
## Implementation Decisions

### Obsidian deep-link
- **D-01:** Add "Open in Obsidian" as a context menu item on each library entry row, alongside "Show in Finder" and "Open in Notion". Uses `obsidian://open?vault=NAME&file=PATH` URL scheme.
- **D-02:** Vault name derived from the vault path -- extract from the directory structure of `vaultMeetingsPath`/`vaultVoicePath` (the vault root is the parent of those folders). No new settings field.
- **D-03:** Menu item shown disabled with tooltip ("Configure vault paths in Settings") when vault paths are empty/default or Obsidian isn't installed. Not hidden -- users should know the feature exists.

### Utterance removal fix
- **D-04:** Fix the speaker label mapping at ContentView.swift:449 only. Map `.you` to `"You"`, `.them` to `"Them"`, and `.named(label)` to its label string (e.g., `"Speaker 2"`). Minimal change -- no hardening of timestamp matching or fallback logic.

### Crash recovery session type
- **D-05:** Infer session type from transcript path during crash recovery (ContentView.swift:227). If `transcriptPath` contains `vaultVoicePath` -> `.voiceMemo`, if it contains `vaultMeetingsPath` -> `.callCapture`.
- **D-06:** Default to `.callCapture` if transcript path doesn't match either vault path (e.g., user changed settings after crash). Same as current behavior.

### SESS-04 requirement text
- **D-07:** Update SESS-04 description in REQUIREMENTS.md to reflect the accepted right-click "Show in Finder" implementation (per Phase 9 D-08). Change from clickable file path to right-click context menu action.

### Claude's Discretion
- Obsidian URI path encoding (percent-encoding for spaces, special chars)
- Exact tooltip wording for disabled Obsidian menu item
- Whether to add the `sessionType` field to `SessionCheckpoint` for future-proofing (not required for the path-inference fix)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Obsidian deep-link
- `PSTranscribe/Sources/PSTranscribe/Views/LibraryEntryRow.swift` -- Context menu (line 105+), existing "Show in Finder" and "Open in Notion" patterns
- `PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift` -- `vaultMeetingsPath` and `vaultVoicePath` settings (lines 18-50)
- `PSTranscribe/Sources/PSTranscribe/Models/Models.swift` -- `LibraryEntry` struct (line 60), `sessionType` field

### Utterance removal
- `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift` -- `removeUtterance` function (line 435), bug at line 449
- `PSTranscribe/Sources/PSTranscribe/Models/Models.swift` -- `Speaker` enum with `.you`, `.them`, `.named(String)` cases (line 3)

### Crash recovery
- `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift` -- crash recovery scan (lines 217-237), hardcoded `.callCapture` at line 227
- `PSTranscribe/Sources/PSTranscribe/Storage/SessionStore.swift` -- `SessionCheckpoint` struct (line 4), `scanIncompleteCheckpoints()` (line 97)

### Requirement tracking
- `.planning/REQUIREMENTS.md` -- SESS-04 description (line 47), SESS-06 checkbox (line 49)
- `.planning/v1.0-MILESTONE-AUDIT.md` -- Defect inventory and gap analysis

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Context menu pattern in LibraryEntryRow.swift -- "Open in Notion" uses `NSWorkspace.shared.open(url)`, exact same pattern for Obsidian
- `Speaker.displayName` computed property (Models.swift:48-50) -- returns `"you"`, `"them"`, or the label string. Could be used for the fix but needs capitalization
- Vault path settings already exist in AppSettings -- no new UserDefaults keys needed

### Established Patterns
- Swift 6 strict concurrency: actors for mutable state, @MainActor for UI
- Context menu items follow Button("Label") { action } pattern with optional Divider() separators
- `NSWorkspace.shared.open(url)` for external app launches (used for Notion)

### Integration Points
- LibraryEntryRow context menu -- add Obsidian item between "Show in Finder" and Notion section
- ContentView `removeUtterance` -- single-line fix at the speaker label mapping
- ContentView crash recovery `.task` block -- add vault path comparison before constructing LibraryEntry

</code_context>

<specifics>
## Specific Ideas

No specific requirements -- open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope

</deferred>

---

*Phase: 10-final-defect-fixes-obsidian-deeplink*
*Context gathered: 2026-04-07*
