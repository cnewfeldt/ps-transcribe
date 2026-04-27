# Phase 3: Session Management + Recording Naming - Research

**Researched:** 2026-04-02
**Domain:** macOS SwiftUI -- persistent library, session lifecycle, file-backed recording index, NavigationSplitView, inline rename
**Confidence:** HIGH

## Summary

Phase 3 transforms the app from a single-session tool into a multi-session library with a persistent sidebar. The core challenge is architectural: ContentView is a single-column VStack at 280-360px -- it must become a NavigationSplitView (sidebar + detail) at a wider minimum width. All session data is currently ephemeral (in-memory TranscriptStore) with crash recovery as the only persistence. A new library index must be added, built on the existing Actor pattern, stored as JSON in Application Support alongside the existing sessions directory.

The naming subsystem extends TranscriptLogger's existing rename infrastructure (`sanitizedFilenameComponent`, `atomicRewrite`, `finalizeFrontmatter`) to accept a user-provided name at any lifecycle point. The top bar becomes a dual-mode element: brand label when idle, editable TextField during/after a session. Inline rename in the sidebar is a click-to-edit pattern standard in macOS apps.

Obsidian deep link integration (`obsidian://open?vault=NAME&file=PATH`) requires only vault name configuration -- no SDK, no process launch, just `NSWorkspace.shared.open(url)` with a custom URL scheme. Markdown parsing for loading past transcripts is straightforward regex against the known format.

**Primary recommendation:** Build a `LibraryStore` actor for JSON index persistence, a `LibraryEntry` struct as the canonical model, and restructure ContentView around NavigationSplitView. Extend TranscriptLogger with a `setName()` method that renames on disk and updates the library index.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Library is a persistent sidebar on the left side of the main window. Transcript/recording view is on the right. Similar to Notes.app layout. Window min width will need to expand beyond current 280-360px.
- **D-02:** Each library entry shows: recording name (or type+date fallback), date, duration, session type icon (mic/phone), file status indicator (missing badge if file moved/deleted), first-line transcript preview, and source app tag (Teams, Zoom, etc.).
- **D-03:** Library sorted most recent first, chronological descending.
- **D-04:** Empty library shows an actionable prompt: "No recordings yet -- start a call capture or voice memo" with guidance toward controls.
- **D-05:** Name input is inline in the top bar. The top bar (currently "TOME" + timer) becomes an editable text field. Placeholder text like "Name this recording" when empty. Editable before, during, and after recording.
- **D-06:** Renaming from library uses click-to-edit inline on the name in the sidebar entry. Click the name, it becomes a text field, press Enter or click away to confirm. File on disk renames immediately.
- **D-07:** Unnamed recordings fall back to "Call Recording -- Apr 2, 2026" or "Voice Memo -- Apr 2, 2026" format, matching the session type.
- **D-08:** After stopping, the transcript stays visible in the right panel. The new library entry appears in the sidebar and is auto-selected. No jarring clear. Save confirmation shown inline.
- **D-09:** Starting a new recording while viewing a past transcript switches the right panel to the live recording view immediately -- no confirmation dialog. The new recording appears at top of sidebar as active entry. Past transcripts remain accessible via sidebar.
- **D-10:** Clicking a library entry parses the markdown file and renders utterances in TranscriptView. Full in-app reading experience -- user doesn't leave the app.
- **D-11:** User configures Obsidian vault name as a text field in Settings alongside existing vault path fields. One-time setup. No auto-detection.
- **D-12:** Each library sidebar entry has a small Obsidian icon button. Click opens the transcript in Obsidian via `obsidian://open?vault=NAME&file=RELATIVE_PATH`. Disabled/hidden if vault name not configured.

### Claude's Discretion
- Session index storage format and location (JSON in Application Support is the natural choice)
- Data model design for library entries (LibraryEntry struct or similar)
- Markdown parsing strategy for loading past transcripts into TranscriptView
- How incomplete sessions from Phase 2's checkpoint system appear in the library
- Sidebar width and resize behavior
- How the top bar layout adapts between "app title" mode and "name input" mode

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SESS-01 | User sees a library/grid view of all past recordings | LibraryStore actor + LibraryEntry model + NavigationSplitView sidebar |
| SESS-02 | Each library entry shows recording name, date, duration, and file status | LibraryEntry struct fields; file existence check on load |
| SESS-03 | Clicking a library entry loads the transcript content in the app | Markdown parser -> Utterance array; TranscriptView reuse |
| SESS-04 | Each library entry has a clickable file path to the transcript on disk | NSWorkspace.shared.selectFile() -- already used in save banner |
| SESS-05 | Library entries show "missing" indicator if transcript file has been moved/deleted | FileManager.default.fileExists() check on sidebar render |
| SESS-06 | Each library entry has an Obsidian deep link that opens the transcript in Obsidian | obsidian:// URL scheme via NSWorkspace.shared.open() |
| SESS-07 | Stopping a recording clears the transcript view and saves the session to the library | LibraryStore.addEntry() called from stopSession(); auto-select new entry |
| SESS-08 | Starting a new recording creates a fresh session (no overwriting previous content) | transcriptStore.clear() already in startSession(); new session creates new file |
| SESS-09 | Session index persists across app restarts | LibraryStore actor writes JSON to Application Support on every mutation |
| NAME-01 | User can set a recording name before starting a recording | Top bar TextField binding; name passed to TranscriptLogger.startSession() |
| NAME-02 | User can rename a recording during an active session | Top bar TextField onChange -> TranscriptLogger.setName() -> file rename |
| NAME-03 | User can rename a recording after it has been saved (from library) | Inline click-to-edit in sidebar entry -> TranscriptLogger or direct rename + LibraryStore update |
| NAME-04 | Unnamed recordings fall back to date-based filename | D-07 format: "Call Recording -- Apr 2, 2026" / "Voice Memo -- Apr 2, 2026" |
| NAME-05 | File on disk renames to match when user changes the recording name | TranscriptLogger.atomicRewrite() with newPath; LibraryStore entry path updated |
</phase_requirements>

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI NavigationSplitView | macOS 13+ (project targets macOS 26) | Sidebar + detail layout | Apple-standard two-column layout, used by Notes.app, Mail.app; auto handles sidebar collapse |
| Foundation JSONEncoder/JSONDecoder | stdlib | Library index persistence | Already used in SessionStore; Codable pattern established |
| NSWorkspace | AppKit (already imported) | Open files in Finder, open URLs (Obsidian) | Already used in ContentView saveBanner for "Show in Finder" |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| FileManager | stdlib | File existence checks, rename, move | SESS-05 file missing detection; NAME-05 rename on disk |
| NSRegularExpression | stdlib | Parse markdown transcript format | SESS-03 loading past transcripts into Utterance array |
| os.Logger | os | Logging in LibraryStore actor | Established pattern from Phase 2 |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| NavigationSplitView | HSplitView | NavigationSplitView handles sidebar collapse, keyboard navigation, macOS idioms automatically; HSplitView requires manual divider management. Use NavigationSplitView. |
| JSON file index | Core Data | Core Data is over-engineered for a flat list of ~hundreds of recordings. JSON file is simpler, portable, and matches the existing codebase pattern. |
| JSON file index | SQLite | Same reason as Core Data -- no query complexity justifies the dependency. |
| NSRegularExpression | Swift Regex | Both work. NSRegularExpression is already used in TranscriptLogger; consistent with existing codebase. |

**Installation:** No new dependencies required. All capabilities are in stdlib, SwiftUI, AppKit, and Foundation already in use.

---

## Architecture Patterns

### Recommended Project Structure (additions only)

```
PSTranscribe/Sources/PSTranscribe/
├── Models/
│   ├── Models.swift                 # Add LibraryEntry struct here
│   └── TranscriptStore.swift        # Unchanged
├── Storage/
│   ├── LibraryStore.swift           # NEW: actor for JSON index persistence
│   ├── SessionStore.swift           # Extend: integrate with library on session end
│   └── TranscriptLogger.swift       # Extend: setName(), rename integration
├── Views/
│   ├── ContentView.swift            # Restructure: NavigationSplitView
│   ├── LibrarySidebar.swift         # NEW: sidebar list + empty state
│   ├── LibraryEntryRow.swift        # NEW: single library row view
│   ├── RecordingNameField.swift     # NEW: top bar dual-mode name field
│   ├── TranscriptView.swift         # Unchanged (reused for both live + loaded)
│   ├── ControlBar.swift             # Unchanged
│   └── SettingsView.swift           # Extend: Obsidian vault name field
└── Settings/
    └── AppSettings.swift            # Extend: obsidianVaultName property
```

### Pattern 1: LibraryEntry Data Model

**What:** A Codable struct representing one library entry, stored in the JSON index.
**When to use:** Every session creation, rename, and stop event.

```swift
// File: PSTranscribe/Sources/PSTranscribe/Models/Models.swift

struct LibraryEntry: Identifiable, Codable {
    let id: UUID
    var name: String?                    // nil = use date-based fallback
    let sessionType: SessionType
    let startDate: Date
    var duration: TimeInterval           // seconds; 0 until session ends
    var filePath: String                 // absolute path to markdown file
    let sourceApp: String
    var isFinalized: Bool                // false during active session

    // Computed -- not stored
    var displayName: String {
        if let name, !name.isEmpty { return name }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d, yyyy"
        let dateStr = fmt.string(from: startDate)
        return sessionType == .callCapture
            ? "Call Recording -- \(dateStr)"
            : "Voice Memo -- \(dateStr)"
    }
}
```

**Note:** `SessionType` is defined in AppSettings.swift. It must either be moved to Models.swift or made Codable. Currently it is `enum SessionType: String` -- adding `: Codable` costs nothing.

### Pattern 2: LibraryStore Actor

**What:** Actor for thread-safe reads/writes of the JSON library index.
**When to use:** Session start (create entry), stop (finalize entry), rename (update entry), app launch (load).

```swift
// File: PSTranscribe/Sources/PSTranscribe/Storage/LibraryStore.swift

actor LibraryStore {
    private let indexPath: URL
    private(set) var entries: [LibraryEntry] = []
    private let log = Logger(subsystem: "com.pstranscribe.app", category: "LibraryStore")

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("PSTranscribe", isDirectory: true)
        indexPath = dir.appendingPathComponent("library.json")
        // Load on init (synchronous -- called before any UI appears)
        loadFromDisk()
    }

    func addEntry(_ entry: LibraryEntry) {
        entries.insert(entry, at: 0)  // newest first
        saveToDisk()
    }

    func updateEntry(id: UUID, transform: (inout LibraryEntry) -> Void) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        transform(&entries[idx])
        saveToDisk()
    }

    private func saveToDisk() { /* JSON encode + atomicRewrite */ }
    private func loadFromDisk() { /* JSON decode, handle missing file */ }
}
```

**Persistence location:** `~/Library/Application Support/PSTranscribe/library.json`
**File permissions:** 0o600 (matching Phase 2 pattern)

### Pattern 3: NavigationSplitView Layout

**What:** Replace VStack in ContentView with NavigationSplitView.
**When to use:** ContentView restructure.

```swift
// Conceptual structure for ContentView body:
NavigationSplitView {
    LibrarySidebar(
        entries: libraryStore.entries,
        selectedID: $selectedEntryID,
        activeEntry: activeLibraryEntryID
    )
} detail: {
    if let activeSession = activeSessionType {
        // Live recording view
        VStack(spacing: 0) {
            RecordingNameField(name: $sessionName, isRecording: isRunning)
            TranscriptView(...)
            ControlBar(...)
        }
    } else if let entry = selectedEntry {
        // Loaded past transcript
        VStack(spacing: 0) {
            loadedTranscriptHeader(entry: entry)
            TranscriptView(utterances: loadedUtterances, ...)
        }
    } else {
        // No selection
        emptyDetailState
    }
}
.navigationSplitViewStyle(.balanced)
.frame(minWidth: 640, minHeight: 400)
```

**Window min width:** 640px (sidebar ~220px + detail ~420px). Sidebar width is handled automatically by NavigationSplitView.

### Pattern 4: Markdown Transcript Parser

**What:** Parse existing transcript file format into `[Utterance]` for TranscriptView.
**When to use:** SESS-03 -- clicking a library entry.

```swift
// File: PSTranscribe/Sources/PSTranscribe/Storage/TranscriptParser.swift (new utility)

func parseTranscript(at url: URL) throws -> [Utterance] {
    let content = try String(contentsOf: url, encoding: .utf8)
    // Skip YAML frontmatter (--- ... ---)
    // Match pattern: **Speaker** (HH:mm:ss)\ntext\n\n
    let pattern = #"\*\*(You|Speaker \d+|Them)\*\* \((\d{2}:\d{2}:\d{2})\)\n(.*?)(?=\n\n|\Z)"#
    // Build Utterance array with synthetic timestamps from HH:mm:ss offsets
    // Speaker "You" -> Speaker.you, others -> Speaker.them
}
```

**Format is well-defined** (TranscriptLogger.flushBuffer writes it): `**Speaker** (HH:mm:ss)\ntext\n\n`. YAML frontmatter ends at the second `---`.

### Pattern 5: Obsidian Deep Link

**What:** Open transcript in Obsidian via custom URL scheme.
**When to use:** SESS-06 Obsidian icon button in library entry.

```swift
// No SDK needed. obsidian:// is a registered URL scheme.
func openInObsidian(entry: LibraryEntry, vaultName: String) {
    let vaultURL = URL(fileURLWithPath: entry.filePath)
    // Derive relative path from vault root
    // URL-encode the relative path
    let urlStr = "obsidian://open?vault=\(vaultName.urlEncoded)&file=\(relativePath.urlEncoded)"
    if let url = URL(string: urlStr) {
        NSWorkspace.shared.open(url)
    }
}
```

**Vault name configuration:** `AppSettings.obsidianVaultName: String` with `didSet { UserDefaults.standard.set(...) }` -- identical to all other AppSettings properties.

### Pattern 6: Inline Click-to-Edit Name (NAME-03)

**What:** Clicking library entry name makes it editable; pressing Enter or clicking away commits.
**When to use:** Sidebar entry rename.

```swift
// LibraryEntryRow.swift
@State private var isEditing = false
@State private var editText = ""

// In body:
if isEditing {
    TextField("", text: $editText)
        .onSubmit { commitRename() }
        .onExitCommand { isEditing = false }
        .focused($isFocused)
} else {
    Text(entry.displayName)
        .onTapGesture { 
            editText = entry.name ?? ""
            isEditing = true
        }
}
```

**Rename triggers file rename on disk** via `atomicRewrite` in TranscriptLogger (or directly in LibraryStore for post-session entries). Update LibraryStore entry's `filePath` after rename.

### Anti-Patterns to Avoid

- **Loading all transcript files on sidebar render:** Only check `FileManager.default.fileExists()` for the missing indicator; don't read file contents until user taps an entry (SESS-03). Eager file reading of many transcripts = slow sidebar.
- **Storing utterances in LibraryEntry:** The JSON index stores metadata only. Full transcript content stays in the markdown file. LibraryEntry.filePath is the source of truth for content.
- **Storing absolute paths without migration path:** `filePath` in LibraryEntry is absolute. This is fine for now (single machine, user can re-point vault). Note that vault path changes won't auto-migrate library entries -- out of scope for this phase.
- **Calling TranscriptLogger.atomicRewrite from MainActor:** It's an actor method -- call with `await`. All rename paths must go through the actor to avoid races.
- **Reinventing the TranscriptLogger rename logic:** `finalizeFrontmatter` already handles context-based rename with `atomicRewrite`. Extend it rather than duplicating rename logic.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Two-column sidebar layout | Custom HSplitView with drag handles | NavigationSplitView | Handles sidebar collapse, keyboard nav, standard macOS behavior automatically |
| Obsidian URL launching | AppleScript, process spawn | NSWorkspace.shared.open(URL) | obsidian:// is a registered custom URL scheme; NSWorkspace handles it natively |
| File rename with safety | Manual copy/delete sequence | Existing atomicRewrite() in TranscriptLogger | Already handles temp file, original preservation, POSIX permissions |
| Filename sanitization | Custom character filter | Existing sanitizedFilenameComponent() in TranscriptLogger | Already whitelist-based (SECR-10 compliant) |
| Show in Finder | NSWorkspace.activateFileViewerSelecting | NSWorkspace.shared.selectFile() | Already used in saveBanner -- just move it to library entry context |

**Key insight:** The rename and filesystem safety infrastructure already exists in TranscriptLogger. Phase 3 should extend it, not build parallel rename code.

---

## Runtime State Inventory

> Omitted -- this is a greenfield feature phase, not a rename/refactor/migration phase.

---

## Common Pitfalls

### Pitfall 1: SessionType is not Codable

**What goes wrong:** LibraryEntry encodes fine but crashes on decode because `SessionType: String` does not conform to `Codable`.
**Why it happens:** SessionType is defined as `enum SessionType: String` without explicit Codable conformance. Swift's `String` raw value gives `RawRepresentable` but not automatic `Codable` unless explicitly declared.
**How to avoid:** Add `: Codable` to `enum SessionType: String, Codable` in AppSettings.swift before defining LibraryEntry.
**Warning signs:** JSONDecoder throws `keyNotFound` or `typeMismatch` for the sessionType field at app launch.

### Pitfall 2: NavigationSplitView Window Size Regression

**What goes wrong:** Existing users (or the developer) have a saved window frame at 280-360px. NavigationSplitView at minWidth: 640 clips or gets stuck in an unusable state.
**Why it happens:** macOS restores the last window frame. If the stored frame is narrower than the new minimum, the window opens at the old size and can't be resized to use the sidebar.
**How to avoid:** In TomeApp.swift, set `defaultSize` on the WindowGroup to at least 720x500. Also handle `.navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)` on the sidebar column so NavigationSplitView knows the minimum acceptable width.
**Warning signs:** Sidebar appears as collapsed/zero-width on first launch after update.

### Pitfall 3: Library Index Grows Unbounded With Missing Files

**What goes wrong:** User deletes transcript files from Finder. Library index still references them (SESS-05: show "missing" badge). Index grows forever.
**Why it happens:** We never prune entries for missing files -- by design for SESS-05.
**How to avoid:** Check `FileManager.default.fileExists(atPath:)` per entry when rendering the sidebar row. Show missing badge. Do NOT auto-delete entries -- user may have moved the file temporarily. This is correct behavior.
**Warning signs:** Showing an entry as missing when the file exists (path encoding bug) or crashing when trying to read a missing file (SESS-03 must guard against nil content).

### Pitfall 4: Rename Race Between Active Session and Name Edit

**What goes wrong:** User starts a session, types a name in the top bar quickly, and the name write races with TranscriptLogger's internal state.
**Why it happens:** TranscriptLogger.updateContext() (the existing name-setting path) reads + rewrites the file while a fileHandle is open. If called too rapidly (every keystroke), multiple overlapping async calls queue up.
**How to avoid:** Debounce the top bar TextField onChange before calling TranscriptLogger. 500ms debounce is sufficient. Only commit the rename when the text field resigns focus or recording stops, not on every keystroke.
**Warning signs:** Corrupted markdown files or "file not found" errors after rapid typing.

### Pitfall 5: Markdown Parser Breaks on Edge Cases

**What goes wrong:** Transcripts with empty sessions (no utterances), sessions with only "You" speaker, or sessions with special characters in speaker names fail to parse.
**Why it happens:** Regex matching `**You** (HH:mm:ss)\ntext` fails if the text field is empty or if there are extra blank lines.
**How to avoid:** Parser should handle empty transcript gracefully (return `[]`). The known format is `**Speaker** (HH:mm:ss)\ntext\n\n` -- use a multiline regex with non-greedy match. Test against files written by TranscriptLogger.flushBuffer specifically.
**Warning signs:** Crash or empty transcript view when loading past recordings.

### Pitfall 6: Obsidian Relative Path Construction

**What goes wrong:** Obsidian deep link fails to open the file because the relative path is wrong. Obsidian uses the path relative to the vault root, not the absolute path.
**Why it happens:** `obsidian://open?vault=NAME&file=PATH` expects PATH relative to the vault root. If you pass an absolute path or a path that doesn't match the vault structure, Obsidian silently fails to open anything.
**How to avoid:** Derive relative path by stripping the vault path prefix from the absolute filePath. Use `URL.relativePath` or simple string prefix stripping. URL-encode the result.
**Warning signs:** Obsidian opens but shows "file not found" inside the app, or opens the vault root instead of the specific file.

---

## Code Examples

### LibraryEntry JSON storage (Application Support path)

```swift
// Source: established pattern from SessionStore.swift (Phase 2)
// File: ~/Library/Application Support/PSTranscribe/library.json

// LibraryStore.saveToDisk() -- called after every mutation
private func saveToDisk() {
    do {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(entries)
        try data.write(to: indexPath)
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: 0o600)],
            ofItemAtPath: indexPath.path
        )
    } catch {
        log.error("LibraryStore: failed to save: \(error.localizedDescription, privacy: .public)")
    }
}
```

### File missing indicator check

```swift
// Source: FileManager stdlib -- no library needed
// In LibraryEntryRow.swift
private var fileExists: Bool {
    FileManager.default.fileExists(atPath: entry.filePath)
}

// In view body:
if !fileExists {
    Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(.orange)
        .font(.system(size: 10))
        .help("File has been moved or deleted")
}
```

### Obsidian deep link construction

```swift
// Source: Obsidian URI scheme documentation (obsidian.md/help/advanced-topics/using-obsidian-uri)
func obsidianURL(for filePath: String, vaultRoot: String, vaultName: String) -> URL? {
    guard filePath.hasPrefix(vaultRoot) else { return nil }
    var relative = String(filePath.dropFirst(vaultRoot.count))
    if relative.hasPrefix("/") { relative = String(relative.dropFirst()) }
    // Remove .md extension -- Obsidian handles it
    if relative.hasSuffix(".md") { relative = String(relative.dropLast(3)) }
    let encoded = relative.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? relative
    let vaultEncoded = vaultName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? vaultName
    return URL(string: "obsidian://open?vault=\(vaultEncoded)&file=\(encoded)")
}
```

### Top bar dual-mode name field

```swift
// Source: SwiftUI TextField patterns (standard)
// In RecordingNameField.swift or inline in ContentView topBar

@Binding var sessionName: String
let isSessionActive: Bool  // true when recording or post-recording

var body: some View {
    if isSessionActive {
        TextField("Name this recording", text: $sessionName)
            .font(.system(size: 14, weight: .medium))
            .textFieldStyle(.plain)
            .foregroundStyle(Color.fg1)
    } else {
        Text("PS TRANSCRIBE")
            .font(.system(size: 14, weight: .heavy))
            .tracking(3)
            .foregroundStyle(Color.fg1)
    }
}
```

### Integrating incomplete checkpoints into the library

```swift
// In ContentView.task on launch -- after scanning for incomplete checkpoints:
let incomplete = await sessionStore.scanIncompleteCheckpoints()
for checkpoint in incomplete {
    // Check if library already has an entry for this session
    let alreadyInLibrary = await libraryStore.entries.contains {
        $0.filePath == checkpoint.transcriptPath
    }
    if !alreadyInLibrary {
        // Create a stub library entry from the checkpoint
        let entry = LibraryEntry(
            id: UUID(),
            name: nil,
            sessionType: .callCapture,  // checkpoint doesn't store type; default to callCapture
            startDate: checkpoint.sessionStartTime,
            duration: 0,
            filePath: checkpoint.transcriptPath,
            sourceApp: "Recovered",
            isFinalized: false
        )
        await libraryStore.addEntry(entry)
    }
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| diagLog() to /tmp/tome.log | os.Logger (per-category) | Phase 2 | New actors use Logger pattern |
| Single-column VStack (280-360px) | NavigationSplitView (640px+) | Phase 3 (this phase) | Window size changes for all users |
| Ephemeral in-memory sessions | Persistent JSON library index | Phase 3 (this phase) | Sessions survive app restarts |
| Context-based file rename (finalizeFrontmatter) | User-named + context fallback + date fallback | Phase 3 (this phase) | Name flows from UI input, not auto-detected context |

**Deprecated/outdated:**
- Save banner ("Saved to X.md" in ContentView): Responsibility moves to the sidebar auto-selection on stop. The banner still shows inline confirmation per D-08, but the "Show in Finder" action moves to the library entry.

---

## Open Questions

1. **How to expose TranscriptLogger file path before finalizeFrontmatter completes**
   - What we know: `TranscriptLogger.finalizeFrontmatter()` is the only method that returns the final URL. During an active session, the current path is private.
   - What's unclear: To create the LibraryEntry at session START (so it appears in sidebar immediately as "active"), we need the file path at startSession time, before finalizeFrontmatter.
   - Recommendation: Add a read-only computed property `currentFilePath: URL?` to TranscriptLogger (exposed from actor context). Called immediately after `startSession()` succeeds to build the initial LibraryEntry with `isFinalized: false`.

2. **SessionType Codable -- where to define**
   - What we know: `SessionType` is currently in AppSettings.swift. LibraryEntry needs it Codable.
   - What's unclear: Whether to move it to Models.swift (more appropriate home for a shared type) or just add Codable to it in AppSettings.swift.
   - Recommendation: Move `SessionType` to Models.swift alongside `Speaker`, `Utterance`, `SessionRecord`. AppSettings.swift imports Models implicitly (same module). This is cleaner architecture and avoids circular-feeling references.

3. **Incomplete checkpoint -> library entry session type**
   - What we know: `SessionCheckpoint` stores sessionId, transcriptPath, startTime, completedSteps, isFinalized -- but NOT sessionType.
   - What's unclear: When surface incomplete sessions as library entries, we can't know if it was callCapture or voiceMemo from the checkpoint alone.
   - Recommendation: Add `sessionType: SessionType` to `SessionCheckpoint` struct. Set it in `SessionStore.startSession(type:)`. This is a one-line addition that solves the ambiguity cleanly. The existing checkpoint files on disk will fail to decode the new field -- use a default value: `var sessionType: SessionType = .callCapture`.

---

## Environment Availability

Step 2.6: SKIPPED -- this phase is purely Swift/SwiftUI code changes with no external CLI tools, databases, or services beyond what already exists in the project. Obsidian is a URL scheme consumer, not a dependency the app links against.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Swift Testing (built into Swift 6.2) or XCTest |
| Config file | None -- no test target exists yet (see Wave 0 Gaps) |
| Quick run command | `swift test --package-path PSTranscribe` (after Wave 0) |
| Full suite command | `swift test --package-path PSTranscribe` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SESS-09 | LibraryStore persists entries to disk and reloads on init | unit | `swift test --filter LibraryStoreTests` | Wave 0 |
| SESS-05 | Missing indicator appears when file doesn't exist | unit | `swift test --filter LibraryEntryTests` | Wave 0 |
| SESS-03 | Markdown parser produces correct Utterance array | unit | `swift test --filter TranscriptParserTests` | Wave 0 |
| NAME-04 | displayName uses date-based fallback when name is nil | unit | `swift test --filter LibraryEntryTests` | Wave 0 |
| NAME-05 | Rename updates filePath on disk via atomicRewrite | unit | `swift test --filter TranscriptLoggerTests` | Wave 0 |
| SESS-06 | Obsidian URL constructed correctly from vault + relative path | unit | `swift test --filter ObsidianURLTests` | Wave 0 |

**Note:** UI behavior (sidebar selection, top bar name field, NavigationSplitView layout) is manual-only -- SwiftUI previews are the practical verification mechanism for layout requirements.

### Sampling Rate
- **Per task commit:** `swift test --package-path PSTranscribe` (only after test target exists)
- **Per wave merge:** `swift test --package-path PSTranscribe`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] Add `.testTarget(name: "PSTranscribeTests", ...)` to `PSTranscribe/Package.swift`
- [ ] `PSTranscribe/Tests/PSTranscribeTests/LibraryStoreTests.swift` -- covers SESS-09
- [ ] `PSTranscribe/Tests/PSTranscribeTests/LibraryEntryTests.swift` -- covers SESS-05, NAME-04
- [ ] `PSTranscribe/Tests/PSTranscribeTests/TranscriptParserTests.swift` -- covers SESS-03
- [ ] `PSTranscribe/Tests/PSTranscribeTests/ObsidianURLTests.swift` -- covers SESS-06

---

## Project Constraints (from CLAUDE.md)

No `./CLAUDE.md` exists in this project. Constraints come from global `~/.claude/CLAUDE.md`:
- No extras, no unrequested abstractions (YAGNI)
- Type annotations on all function parameters and return types
- All function parameters typed; Codable used for persistence models
- Tests required for business logic and critical paths (LibraryStore persistence, markdown parser, URL construction)
- Naming: descriptive, consistent with existing codebase conventions
- os.Logger pattern: `Logger(subsystem: "com.pstranscribe.app", category: "TypeName")` established in Phase 2 -- all new actors follow this
- POSIX 0o600 on files, 0o700 on directories -- apply to library.json
- Actor isolation for all file I/O (LibraryStore must be an actor, not a class)
- No try? on file write sequences that are critical paths (SECR-09 pattern from Phase 2)

---

## Sources

### Primary (HIGH confidence)
- Direct inspection of `PSTranscribe/Sources/PSTranscribe/Storage/SessionStore.swift` -- actor patterns, JSONL persistence, Application Support path construction
- Direct inspection of `PSTranscribe/Sources/PSTranscribe/Storage/TranscriptLogger.swift` -- atomicRewrite, sanitizedFilenameComponent, finalizeFrontmatter, session lifecycle
- Direct inspection of `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift` -- current layout (VStack 280-360px), startSession/stopSession logic, saveBanner
- Direct inspection of `PSTranscribe/Sources/PSTranscribe/Models/Models.swift` -- existing types (Speaker, Utterance, SessionRecord)
- Direct inspection of `PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift` -- UserDefaults didSet pattern, vault path properties
- Direct inspection of `PSTranscribe/Sources/PSTranscribe/Views/SettingsView.swift` -- existing settings UI structure
- `.planning/codebase/CONVENTIONS.md` -- Swift 6.2, actor isolation, @Observable/@MainActor, os.Logger patterns
- `.planning/codebase/ARCHITECTURE.md` -- layer dependencies, data flow, entry points
- `.planning/phases/03-session-management-recording-naming/03-CONTEXT.md` -- all locked decisions

### Secondary (MEDIUM confidence)
- Obsidian URI scheme: `obsidian://open?vault=NAME&file=PATH` -- well-documented in Obsidian help (verified by understanding of how other macOS apps like Bear, Notion use URL schemes; standard NSWorkspace open pattern)
- NavigationSplitView for Notes.app-style layout -- standard Apple HIG pattern for macOS two-column layouts; introduced macOS 13 (well within macOS 26 target)

### Tertiary (LOW confidence)
- None -- all claims backed by code inspection or established Apple API patterns.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all in stdlib/SwiftUI/AppKit already in use
- Architecture: HIGH -- patterns derived directly from existing codebase, not inference
- Pitfalls: HIGH -- race condition and rename pitfalls derived from reading the actual code paths
- Validation: MEDIUM -- test commands assume Wave 0 test target creation; framework choice (Swift Testing vs XCTest) left to planner

**Research date:** 2026-04-02
**Valid until:** 2026-05-02 (stable -- no fast-moving external dependencies)
