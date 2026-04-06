# Notion Integration Design

**Date:** 2026-04-05
**Status:** Approved
**Version:** 1.3.0+

## Summary

On-demand export of finalized transcripts from PS Transcribe to a Notion database. Each transcript becomes a database row with structured properties (title, date, duration, source app, session type, speakers, tags) and the full transcript as the page body in Notion block format.

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| When to send | On demand (context menu) | User controls what ships; avoids pushing garbage transcripts automatically |
| Destination | Notion database (table) | Structured rows with properties; filterable, sortable, queryable; prerequisite for Notion AI/automations |
| Authentication | Internal integration (API key) | Personal-use tool; 60-second setup, token never expires, no OAuth complexity |
| API key storage | macOS Keychain | Not UserDefaults -- prevents leaking in defaults exports or backups |
| Database ID storage | UserDefaults | Not a secret; just a configuration value |
| Tag workflow | User assigns tags in a sheet before sending; previously-used tags shown as chips | Zero-friction for repeat workflows; freeform so no upfront schema needed |

## Database Schema

| Property | Notion Type | Source | Example |
|---|---|---|---|
| Title | Title | `entry.displayName` or filename | "Sprint Planning" |
| Date | Date | `entry.startDate` | Apr 4, 2026 |
| Duration | Text | `entry.duration` formatted | "12m 30s" |
| Source App | Select | `entry.sourceApp` | Teams, Zoom, Voice Memo |
| Session Type | Select | `entry.sessionType` | Call Capture, Voice Memo |
| Speakers | Multi-select | Auto-extracted from transcript | You, Speaker 2 |
| Tags | Multi-select | User-assigned in tag sheet | engineering, sprint |
| Transcript | Page content (blocks) | Full markdown transcript body | (paragraphs, speaker labels, timestamps) |

## Architecture

### New Files

**`PSTranscribe/Sources/PSTranscribe/Notion/NotionService.swift`**

Actor handling auth, API calls, and markdown-to-Notion-block conversion.

```swift
actor NotionService {
    private let baseURL = "https://api.notion.com/v1"
    private let apiVersion = "2022-06-28"

    // Keychain operations
    func apiKey() -> String?
    func setApiKey(_ key: String) throws
    func deleteApiKey() throws

    // Validation
    func testConnection() async throws -> String        // returns workspace name
    func validateDatabase(id: String) async throws -> String  // returns database title

    // Send
    func sendTranscript(
        databaseID: String,
        title: String,
        date: Date,
        duration: TimeInterval,
        sourceApp: String,
        sessionType: String,
        speakers: [String],
        tags: [String],
        transcriptMarkdown: String
    ) async throws -> URL  // returns Notion page URL
}
```

API calls per send: **1** -- `POST /v1/pages` with both `properties` and `children` (block content). For transcripts exceeding 100 blocks, a follow-up `PATCH /v1/blocks/{id}/children` appends the remainder.

**`PSTranscribe/Sources/PSTranscribe/Notion/KeychainHelper.swift`**

Minimal Keychain utility (no third-party dependency):

```swift
enum KeychainHelper {
    static func save(key: String, service: String, data: Data) throws
    static func read(key: String, service: String) -> Data?
    static func delete(key: String, service: String) throws
}
```

Service: `"com.pstranscribe.app"`, Key: `"notion-api-key"`.
Uses `SecItemAdd` / `SecItemCopyMatching` / `SecItemDelete` directly.

**`PSTranscribe/Sources/PSTranscribe/Views/NotionTagSheet.swift`**

Lightweight SwiftUI sheet presented before send:

- Shows recording title + date for confirmation
- Freeform tag input with "Add" button
- "Previously used" section with clickable chips (last ~10 unique tags, stored in UserDefaults as `[String]`)
- Cancel / Send buttons
- Send button triggers `NotionService.sendTranscript(...)` with inline spinner and error display

### Modified Files

**`AppSettings.swift`**
- Add `notionDatabaseID: String` (UserDefaults-backed, not a secret)

**`SettingsView.swift`**
- New "Notion" section with:
  - API key field (secure, Keychain-backed, shows last 4 chars when set)
  - Database ID / URL paste field (validates on submit via `validateDatabase()`)
  - Connection status indicator (Connected / Not configured / Error)
  - Inline setup guidance text

**`LibraryEntry.swift`**
- Add `notionPageURL: String?` for duplicate prevention

**`LibraryEntryRow.swift`**
- Context menu: add "Send to Notion" (when `notionPageURL == nil` and Notion is configured)
- Context menu: add "Open in Notion" (when `notionPageURL != nil`, opens URL in browser)
- Context menu: add "Resend to Notion" as secondary option when already sent

**`ContentView.swift`**
- Sheet presentation state for `NotionTagSheet`
- Send handler that reads transcript from disk, calls `NotionService`, updates `LibraryEntry` with returned page URL

## Settings UI States

1. **Not configured** -- API key field empty. Database field hidden. Setup guidance shown. "Send to Notion" hidden from library context menus.
2. **Validating** -- spinner next to status while `testConnection()` runs.
3. **Connected, no database** -- workspace name shown. Database field appears.
4. **Fully configured** -- workspace name + database title shown. "Send to Notion" enabled in context menus.

## Markdown to Notion Blocks

The transcript follows a controlled format from `TranscriptLogger`:

```
**You** (00:01:23)
Hello world

**Speaker 2** (00:01:30)
Hi there
```

Conversion rules:
- `**Speaker** (timestamp)` lines become bold text blocks
- Plain text lines become paragraph blocks
- `---` becomes a divider block
- YAML frontmatter is stripped (metadata captured in database properties)
- No generic markdown parser needed -- format is controlled by our own writer

## Error Handling

| Scenario | Detection | User sees | Recovery |
|---|---|---|---|
| No API key | `apiKey() == nil` | "Send to Notion" hidden | Open Settings |
| Key invalid/revoked | 401 from `testConnection()` | "Authentication failed" in Settings | Re-enter key |
| Database not shared | 404 from `validateDatabase()` | "Database not found -- share it with your integration" | Share in Notion, retry |
| Database ID wrong format | Client-side validation | Inline field error | Re-paste |
| Network error during send | URLError | Tag sheet: "Network error -- try again" | Retry button |
| Rate limited (429) | Response code | "Notion is busy" | Auto-retry once after 1s, then surface |
| Transcript too large | >100 blocks | Transparent batching | Auto-handled |
| Already sent | `notionPageURL != nil` | "Open in Notion" replaces "Send" | "Resend" secondary option |

## Out of Scope

- Syncing edits back from Notion to local files
- Pulling transcripts from Notion
- OAuth / public integration flow
- Automatic send on session end (future toggle if needed)
- Creating Notion databases from within the app
- Obsidian vault integration (removed in v1.3.0; transcripts are still local .md files)
