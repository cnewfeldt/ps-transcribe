# Phase 10: Final Defect Fixes + Obsidian Deep-Link - Research

**Researched:** 2026-04-07
**Domain:** SwiftUI/macOS -- context menu extensions, URL scheme launching, markdown rewrite, crash recovery inference
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Add "Open in Obsidian" as a context menu item on each library entry row, alongside "Show in Finder" and "Open in Notion". Uses `obsidian://open?vault=NAME&file=PATH` URL scheme.
- **D-02:** Vault name derived from the vault path -- extract from the directory structure of `vaultMeetingsPath`/`vaultVoicePath` (the vault root is the parent of those folders). No new settings field.
- **D-03:** Menu item shown disabled with tooltip ("Configure vault paths in Settings") when vault paths are empty/default or Obsidian isn't installed. Not hidden -- users should know the feature exists.
- **D-04:** Fix the speaker label mapping at ContentView.swift:449 only. Map `.you` to `"You"`, `.them` to `"Them"`, and `.named(label)` to its label string (e.g., `"Speaker 2"`). Minimal change -- no hardening of timestamp matching or fallback logic.
- **D-05:** Infer session type from transcript path during crash recovery (ContentView.swift:227). If `transcriptPath` contains `vaultVoicePath` -> `.voiceMemo`, if it contains `vaultMeetingsPath` -> `.callCapture`.
- **D-06:** Default to `.callCapture` if transcript path doesn't match either vault path (e.g., user changed settings after crash). Same as current behavior.
- **D-07:** Update SESS-04 description in REQUIREMENTS.md to reflect the accepted right-click "Show in Finder" implementation (per Phase 9 D-08). Change from clickable file path to right-click context menu action.

### Claude's Discretion

- Obsidian URI path encoding (percent-encoding for spaces, special chars)
- Exact tooltip wording for disabled Obsidian menu item
- Whether to add the `sessionType` field to `SessionCheckpoint` for future-proofing (not required for the path-inference fix)

### Deferred Ideas (OUT OF SCOPE)

None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SESS-06 | Each library entry has an Obsidian deep link that opens the transcript in Obsidian | D-01/D-02/D-03 define the context menu item, URL scheme, vault name derivation, and disabled-state behavior. Implementation follows the existing "Open in Notion" pattern in LibraryEntryRow. |
</phase_requirements>

---

## Summary

Phase 10 is a four-item patch phase: one new feature (SESS-06 Obsidian deep-link), two code defect fixes (named speaker utterance removal, crash-recovered session type), and one documentation update (SESS-04 requirement text). Every change has a precise location -- no architectural decisions remain open.

The Obsidian deep-link is the most complex item. The `obsidian://open?vault=NAME&file=PATH` URL scheme is well-established. The file path must be relative to the vault root (not absolute), and both the vault name and the path segments must be percent-encoded. Vault name derivation from `vaultMeetingsPath`/`vaultVoicePath` requires stripping the terminal folder component to reach the vault root, then using the vault root's last path component as the vault name. The "Open in Notion" code pattern in `LibraryEntryRow.contextMenu` is the exact template.

The utterance removal bug is a one-line fix: replace the ternary `removed.speaker == .you ? "You" : "Them"` with a switch/case that maps `.named(let label)` to `label`. The crash recovery fix is also small -- add path-containment checks for `vaultVoicePath` and `vaultMeetingsPath` before constructing the `LibraryEntry` in ContentView's `.task` block at line 224-236. Both fixes are safe to make without behavior changes to the non-buggy paths.

**Primary recommendation:** Implement as four independent tasks (defect 1, defect 2, Obsidian feature, SESS-04 doc update) in that order; each is mergeable/verifiable independently.

---

## Standard Stack

No new dependencies required. All capabilities are in the Swift/macOS standard library and the existing project stack.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Foundation (URL, URLComponents) | macOS SDK | Constructing and percent-encoding `obsidian://` URLs | Built-in; correct percent-encoding via URLComponents |
| AppKit (NSWorkspace) | macOS SDK | Opening the Obsidian URL / detecting Obsidian install | Same API already used for "Show in Finder" and "Open in Notion" |
| SwiftUI (.contextMenu, Button, .disabled, .help) | macOS SDK | Context menu item with disabled state and tooltip | Matches project's existing context menu pattern |

**Installation:** None required. All standard SDK.

---

## Architecture Patterns

### Existing Context Menu Pattern (LibraryEntryRow.swift:105-145)

The Notion section is the direct template for the Obsidian item:

```swift
// Source: LibraryEntryRow.swift:122-139 [VERIFIED: codebase]
if isNotionConfigured {
    Divider()
    if entry.notionPageURL == nil {
        Button("Send to Notion...") { onSendToNotion?() }
    } else {
        Button("Open in Notion") {
            if let urlString = entry.notionPageURL,
               let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        }
        Button("Resend to Notion...") { onSendToNotion?() }
    }
}
```

For Obsidian, the pattern is simpler: one button, always shown, disabled when vault paths are unconfigured or Obsidian is not installed.

### Pattern 1: Obsidian URL construction via URLComponents

**What:** Build `obsidian://open?vault=NAME&file=PATH` using `URLComponents` + `URLQueryItem` so percent-encoding is handled automatically.

**When to use:** Always -- never hand-build query strings with string interpolation.

```swift
// Source: Obsidian URI scheme docs [CITED: help.obsidian.md/Extending+Obsidian/Obsidian+URI]
func obsidianURL(for filePath: String, vaultName: String, vaultRoot: String) -> URL? {
    // filePath must be relative to vault root
    guard filePath.hasPrefix(vaultRoot) else { return nil }
    let relativePath = String(filePath.dropFirst(vaultRoot.count + 1)) // strip leading "/"

    var components = URLComponents()
    components.scheme = "obsidian"
    components.host = "open"
    components.queryItems = [
        URLQueryItem(name: "vault", value: vaultName),
        URLQueryItem(name: "file", value: relativePath)
    ]
    return components.url
}
```

`URLComponents` percent-encodes query item values automatically per RFC 3986 (spaces become `%20`, not `+`). [VERIFIED: Apple docs -- URLQueryItem encoding is application/x-www-form-urlencoded-safe characters only; URLComponents.url applies percent encoding]

### Pattern 2: Vault name derivation from vault path (D-02)

**What:** Given `vaultMeetingsPath` or `vaultVoicePath` (the folder *inside* the vault), the vault root is one level up, and the vault name is the root folder's last component.

**Example:**
- `vaultMeetingsPath` = `/Users/cary/Documents/MyVault/Meetings`
- Vault root = `/Users/cary/Documents/MyVault`
- Vault name = `MyVault`

```swift
// [VERIFIED: codebase -- AppSettings.swift vaultMeetingsPath/vaultVoicePath structure]
func obsidianVaultName(from vaultSubPath: String) -> String? {
    guard !vaultSubPath.isEmpty else { return nil }
    let url = URL(fileURLWithPath: vaultSubPath)
    return url.deletingLastPathComponent().lastPathComponent
}
```

**Edge cases:**
- Empty string: return nil (maps to disabled state per D-03)
- Path is already a root or has no parent: `lastPathComponent` returns `""` or `"/"` -- treat as nil
- Both `vaultMeetingsPath` and `vaultVoicePath` exist: prefer the vault path that matches the entry's `sessionType` (.callCapture -> vaultMeetingsPath, .voiceMemo -> vaultVoicePath), falling back to whichever is non-empty.

### Pattern 3: Obsidian install detection

**What:** `NSWorkspace.shared.urlForApplication(withBundleIdentifier:)` returns non-nil if the app is installed. Obsidian's bundle ID is `md.obsidian`.

```swift
// [VERIFIED: runtime test -- swift -e 'import AppKit; print(NSWorkspace.shared.urlForApplication(withBundleIdentifier: "md.obsidian") as Any)' returns Optional(file:///Applications/Obsidian.app/)]
let isObsidianInstalled: Bool =
    NSWorkspace.shared.urlForApplication(withBundleIdentifier: "md.obsidian") != nil
```

### Pattern 4: Disabled context menu button with tooltip

**What:** SwiftUI `.disabled()` + `.help()` on a `Button` inside `.contextMenu`.

```swift
// [ASSUMED -- standard SwiftUI pattern; .help() on disabled buttons inside contextMenu works in macOS 13+]
Button("Open in Obsidian") {
    if let url = obsidianURL(for: entry.filePath, ...) {
        NSWorkspace.shared.open(url)
    }
}
.disabled(!isObsidianAvailable)
.help(isObsidianAvailable ? "" : "Configure vault paths in Settings")
```

**Note:** `.help()` tooltip on a disabled context menu item in `.contextMenu` -- behavior should be tested manually. If tooltip doesn't fire on disabled context menu items (a known macOS limitation), the planner should scope this to "best effort." [ASSUMED -- need manual test to confirm]

### Pattern 5: Speaker label mapping fix (D-04)

Replace the ternary at ContentView.swift:449 with a switch:

```swift
// Before (BUGGY) [VERIFIED: ContentView.swift:449]
let speakerLabel = removed.speaker == .you ? "You" : "Them"

// After (CORRECT)
let speakerLabel: String
switch removed.speaker {
case .you:             speakerLabel = "You"
case .them:            speakerLabel = "Them"
case .named(let lbl):  speakerLabel = lbl
}
```

The string `lbl` must match the header line format produced by `TranscriptLogger` -- confirmed in TranscriptParser.swift:63 that `.named(speakerStr)` comes from parsing `**Speaker N**` headers directly, so `lbl` == the exact string written to markdown. [VERIFIED: TranscriptParser.swift:60-64]

### Pattern 6: Crash recovery session type inference (D-05/D-06)

Replace the hardcoded `.callCapture` in ContentView.swift:227 with a path-containment check:

```swift
// Before (BUGGY) [VERIFIED: ContentView.swift:227]
sessionType: .callCapture,

// After (CORRECT) -- settings is available in ContentView via @Environment or stored reference
let recoveredType: SessionType
if checkpoint.transcriptPath.hasPrefix(settings.vaultVoicePath) {
    recoveredType = .voiceMemo
} else if checkpoint.transcriptPath.hasPrefix(settings.vaultMeetingsPath) {
    recoveredType = .callCapture
} else {
    recoveredType = .callCapture  // D-06: default
}
```

**Dependency:** ContentView already holds a reference to `settings: AppSettings` (confirmed by usage at line 53-54 `settings.notionDatabaseID`). No new dependency injection needed. [VERIFIED: ContentView.swift:53-55]

### Anti-Patterns to Avoid

- **String interpolation for URL query params:** `"obsidian://open?vault=\(name)&file=\(path)"` -- will break for vault names or paths with spaces or special chars. Use `URLComponents` + `URLQueryItem`.
- **Absolute file paths in Obsidian URL:** The `file=` parameter must be vault-relative, not an absolute filesystem path. Absolute paths cause Obsidian to silently fail to open.
- **Hiding the Obsidian menu item when unconfigured:** D-03 explicitly requires showing it disabled with tooltip. Don't gate it behind `isObsidianConfigured` the way Notion is gated behind `isNotionConfigured`.
- **Modifying `removeUtterance` beyond the speaker label fix:** D-04 says minimal change only. Don't refactor timestamp matching or add fallback logic.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Percent-encoding URL query params | String interpolation with manual `%20` substitution | URLComponents + URLQueryItem | Handles all RFC 3986 reserved chars, not just spaces |
| Detecting installed apps | Checking /Applications/ filesystem | NSWorkspace.shared.urlForApplication(withBundleIdentifier:) | Handles apps installed outside /Applications, sandboxed correctly |

---

## Common Pitfalls

### Pitfall 1: Obsidian URL path not vault-relative
**What goes wrong:** Passing the absolute filesystem path as the `file=` parameter. Obsidian receives `/Users/cary/Documents/MyVault/Meetings/recording.md` and cannot find the file because it expects `Meetings/recording.md`.
**Why it happens:** The `entry.filePath` stored in `LibraryEntry` is an absolute path.
**How to avoid:** Strip the vault root prefix before constructing the URL. Guard against the case where `filePath` doesn't start with `vaultRoot` (different vault, missing file).
**Warning signs:** Obsidian opens but shows "File not found" or opens to vault root.

### Pitfall 2: Vault name derivation returns wrong directory level
**What goes wrong:** Using `URL(fileURLWithPath: vaultMeetingsPath).lastPathComponent` instead of `.deletingLastPathComponent().lastPathComponent`. This gives `"Meetings"` instead of `"MyVault"`.
**Why it happens:** Off-by-one in path component stripping.
**How to avoid:** The vault sub-folder (Meetings, Voice) is one level *below* the vault root. Call `.deletingLastPathComponent()` once before `.lastPathComponent`.

### Pitfall 3: `.help()` tooltip not visible on disabled context menu item
**What goes wrong:** macOS context menus may not surface `.help()` tooltips on disabled items -- this is a known platform behavior.
**Why it happens:** NSMenu disabled items receive no hover event; tooltips require hover.
**How to avoid:** Accept this as best-effort per D-03. The requirement says show disabled with tooltip, not that the tooltip is guaranteed to appear. Manual test during verification.

### Pitfall 4: `Speaker.rawValue` capitalization mismatch
**What goes wrong:** Using `removed.speaker.rawValue` for the speaker label -- this returns `"you"` (lowercase) instead of `"You"` (as written in the transcript file).
**Why it happens:** `Speaker.rawValue` returns lowercase strings (`"you"`, `"them"`, label string). The markdown file uses title-case `"You"` and `"Them"`.
**How to avoid:** The fix in D-04 explicitly maps to `"You"` and `"Them"` (title case). Do not use `rawValue` as a shortcut.

### Pitfall 5: AppSettings not accessible in crash recovery `.task`
**What goes wrong:** The crash recovery `.task` in ContentView may reference `settings` as an `@Environment` or `@State` -- if captured by value in the task closure, the paths could be stale.
**Why it happens:** Swift 6 strict concurrency; `@Observable` AppSettings on `@MainActor`.
**How to avoid:** The crash recovery `.task` already runs on `@MainActor` (it calls `await libraryStore.addEntry`). `settings.vaultVoicePath` and `settings.vaultMeetingsPath` are safe to read on `@MainActor`. Capture the paths as local `let` bindings before the async boundary.

---

## Code Examples

### Constructing the Obsidian URL
```swift
// Source: D-01/D-02 decisions; URLComponents pattern [VERIFIED: Apple docs]
func makeObsidianURL(filePath: String, vaultRoot: String, vaultName: String) -> URL? {
    guard !filePath.isEmpty,
          !vaultRoot.isEmpty,
          !vaultName.isEmpty,
          filePath.hasPrefix(vaultRoot) else { return nil }

    // Relative path: strip vault root and leading separator
    var relative = String(filePath.dropFirst(vaultRoot.count))
    if relative.hasPrefix("/") { relative = String(relative.dropFirst()) }
    guard !relative.isEmpty else { return nil }

    var comps = URLComponents()
    comps.scheme = "obsidian"
    comps.host = "open"
    comps.queryItems = [
        URLQueryItem(name: "vault", value: vaultName),
        URLQueryItem(name: "file", value: relative)
    ]
    return comps.url
}
```

### LibraryEntryRow additions (D-01/D-03)
```swift
// Insert after "Show in Finder" Button, before Notion section
// [VERIFIED: LibraryEntryRow.swift:114-120 for Show in Finder anchor]

let obsidianAvailable = isObsidianConfigured && isObsidianInstalled

Divider()
Button("Open in Obsidian") {
    if let url = obsidianURLForEntry {
        NSWorkspace.shared.open(url)
    }
}
.disabled(!obsidianAvailable)
.help(obsidianAvailable ? "" : "Configure vault paths in Settings")
```

`LibraryEntryRow` needs two new inputs: `isObsidianConfigured: Bool` and `obsidianVaultInfo: (root: String, name: String)?` (or just pass the vault path strings and compute inline). The simplest approach matching the existing `isNotionConfigured: Bool` pattern is to add `isObsidianConfigured: Bool` and a computed `obsidianURL: URL?` computed at the call site in LibrarySidebar/ContentView, then passed in.

### Wiring through LibrarySidebar
```swift
// LibrarySidebar gains two new props (matching isNotionConfigured pattern):
// [VERIFIED: LibrarySidebar.swift:9-10 for existing Notion wiring]
var isObsidianConfigured: Bool = false
var obsidianURLForEntry: ((LibraryEntry) -> URL?)? = nil

// ContentView computes isObsidianConfigured:
private var isObsidianConfigured: Bool {
    !settings.vaultMeetingsPath.isEmpty &&
    NSWorkspace.shared.urlForApplication(withBundleIdentifier: "md.obsidian") != nil
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Obsidian required a separate "vault name" setting | Vault name derived from path structure | Phase 10 design (D-02) | No new UserDefaults key; vault name always consistent with path |
| `Speaker.you ? "You" : "Them"` ternary | Switch on all three Speaker cases | Phase 10 defect fix (D-04) | Named speakers can now be removed from transcripts |
| Crash-recovered entries hardcoded to `.callCapture` | Session type inferred from transcript path | Phase 10 defect fix (D-05/D-06) | Voice memos show correct mic icon after recovery |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `.help()` tooltip on a disabled `.contextMenu` Button is visible on macOS 13+ | Architecture Patterns #4, Pitfall 3 | Tooltip never shows; user has no feedback. Low risk -- disabled state alone communicates non-functionality |
| A2 | `URLComponents` + `URLQueryItem` percent-encodes path separators (`/`) within the `file=` value as `%2F` | Architecture Patterns #1 | Path with subdirectories breaks; Obsidian can't resolve file. Mitigation: test with a path like `Meetings/recording.md` |

**If A2 is a problem:** Obsidian's URI spec says `file=` accepts forward-slash path separators unencoded. If `URLComponents` over-encodes `/` in query items, use `addingPercentEncoding(withAllowedCharacters:)` with a custom set that includes `/`.

---

## Open Questions

1. **Does Obsidian `file=` accept forward-slash path separators unencoded, or must they be `%2F`?**
   - What we know: `URLQueryItem` will percent-encode `/` by default. Obsidian's docs show unencoded `/` in examples.
   - What's unclear: Whether Obsidian's URI handler decodes `%2F` to `/` correctly (most URL handlers do, but custom URI schemes vary).
   - Recommendation: Build with `URLComponents` + `URLQueryItem` as the base; add a manual test case with a transcript in a subdirectory (e.g., `Meetings/recording.md`). If Obsidian fails to open, replace path encoding with a custom allowed-character set that permits `/`.

2. **Should `obsidianURL` construction live in `LibraryEntryRow` (computed property) or in a helper on `AppSettings`/`TranscriptParser`?**
   - What we know: The removed implementation lived in `TranscriptParser` as a free function.
   - What's unclear: The new approach needs vault path access -- `AppSettings` is not passed to `TranscriptParser`.
   - Recommendation: Implement as a free function in `TranscriptParser.swift` (mirrors prior implementation), accept vault root + vault name as parameters. Call site in ContentView computes and passes the derived `URL?` per entry, matching how `notionPageURL` is stored on the entry.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Obsidian.app | Manual testing of deep-link | Yes | /Applications/Obsidian.app | N/A |
| Swift toolchain | `swift test` | Yes | (system SDK) | N/A |

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`import Testing`) |
| Config file | PSTranscribe/Package.swift |
| Quick run command | `cd PSTranscribe && swift test` |
| Full suite command | `cd PSTranscribe && swift test` |

**Baseline:** 31 tests in 6 suites, all passing. [VERIFIED: runtime]

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SESS-06 | `makeObsidianURL` returns correctly encoded URL for file in vault | unit | `cd PSTranscribe && swift test --filter ObsidianURLTests` | No -- Wave 0 |
| SESS-06 | `makeObsidianURL` returns nil when filePath not under vaultRoot | unit | `cd PSTranscribe && swift test --filter ObsidianURLTests` | No -- Wave 0 |
| SESS-06 | `makeObsidianURL` returns nil when vaultRoot is empty | unit | `cd PSTranscribe && swift test --filter ObsidianURLTests` | No -- Wave 0 |
| D-04 (utterance removal) | `removeUtterance` with `.named` speaker constructs correct header line | unit | `cd PSTranscribe && swift test --filter TranscriptParserTests` | Partial -- add case |
| D-05 (crash recovery) | Session type inferred as `.voiceMemo` when path contains vaultVoicePath | unit | `cd PSTranscribe && swift test` | No -- manual/logic only |

### Sampling Rate
- **Per task commit:** `cd PSTranscribe && swift test`
- **Per wave merge:** `cd PSTranscribe && swift test`
- **Phase gate:** Full suite green (31 + new tests) before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `PSTranscribe/Tests/PSTranscribeTests/ObsidianURLTests.swift` -- covers SESS-06 URL construction (3-5 test cases: normal path, subdirectory path, empty vault, file not under vault root, vault name extraction)

*(TranscriptParserTests.swift already exists -- add `.named` speaker case to existing suite, no new file needed)*

---

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | Validate `filePath` starts with vault root before constructing URL; empty/default path check per D-03 |
| V6 Cryptography | no | N/A |
| V4 Access Control | no | N/A |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal via `file=` param | Tampering | Guard `filePath.hasPrefix(vaultRoot)` before constructing URL -- already in proposed implementation |
| Open redirect via malformed vault name | Tampering | Vault name is derived programmatically from path structure, not user-typed input |

---

## Sources

### Primary (HIGH confidence)
- [VERIFIED: codebase] `LibraryEntryRow.swift:105-145` -- contextMenu structure, Notion pattern
- [VERIFIED: codebase] `ContentView.swift:449` -- speaker ternary bug location
- [VERIFIED: codebase] `ContentView.swift:224-236` -- crash recovery LibraryEntry construction
- [VERIFIED: codebase] `AppSettings.swift:18-24` -- vaultMeetingsPath/vaultVoicePath properties
- [VERIFIED: codebase] `Models.swift:3-53` -- Speaker enum with .you, .them, .named(String) cases
- [VERIFIED: codebase] `TranscriptParser.swift:60-64` -- speaker string to Speaker mapping (confirms label case)
- [VERIFIED: codebase] `LibrarySidebar.swift:9-10` -- existing Notion prop wiring pattern
- [VERIFIED: runtime] `swift test` baseline: 31/31 tests pass
- [VERIFIED: runtime] Obsidian bundle ID `md.obsidian` resolves to `/Applications/Obsidian.app/`

### Secondary (MEDIUM confidence)
- [CITED: help.obsidian.md/Extending+Obsidian/Obsidian+URI] Obsidian URI scheme: `obsidian://open?vault=NAME&file=PATH`, file path is vault-relative

### Tertiary (LOW confidence)
- [ASSUMED] `.help()` tooltip visible on disabled context menu Button -- needs manual verification

---

## Project Constraints (from CLAUDE.md)

No project-level `CLAUDE.md` found. Global `~/.claude/CLAUDE.md` constraints in effect:

- TypeScript/React/Next.js are the default stack -- not applicable here (this is a SwiftUI/macOS project; follow project conventions)
- Build only what's requested -- no extras, no unrequested abstractions (enforce: no `sessionType` field on `SessionCheckpoint` unless explicitly chosen per Claude's Discretion)
- Verify before completing -- run `swift test` after each change
- Never suppress errors -- all `try?` replacements must be deliberate
- Error handling: log with context, never expose internals

---

## Metadata

**Confidence breakdown:**
- Bug fixes (D-04, D-05): HIGH -- exact line numbers verified in codebase, fix is mechanical
- Obsidian URL construction: HIGH -- URL scheme documented, URLComponents behavior confirmed
- Vault name derivation: HIGH -- path structure confirmed from AppSettings
- Disabled tooltip behavior: LOW -- platform behavior unverified, marked ASSUMED
- Obsidian `file=` path separator encoding: MEDIUM -- common URI handler behavior, flagged as open question

**Research date:** 2026-04-07
**Valid until:** 2026-05-07 (stable platform APIs, 30-day window)
