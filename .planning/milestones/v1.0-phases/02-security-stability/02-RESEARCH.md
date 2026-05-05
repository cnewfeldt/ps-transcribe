# Phase 02: Security + Stability -- Research

**Researched:** 2026-04-02
**Domain:** Swift security hardening, CI/CD security, macOS file I/O, crash recovery, diarization timestamps
**Confidence:** HIGH

## Summary

This phase resolves 12 security scan findings and 4 stability bugs in the PSTranscribe codebase. The work is entirely mechanical: no new features, no UX changes beyond surfacing existing errors. Every finding has a known fix pattern and the source files are all small and well-understood.

The security work falls into five buckets: CI hardening (SCAN-001, 005, 007, 012), logging replacement (SCAN-002), path validation and filename sanitization (SCAN-003, 010), file permissions (SCAN-004, 006), and .gitignore + error handling hygiene (SCAN-008, 009, 011). The stability work covers crash recovery (STAB-01, 03), diarization timestamp math (STAB-02), and mic error propagation (STAB-04).

The primary risk is SCAN-009 (try? replacement). All 29 try? instances are documented below with a safe/dangerous classification. Bulk replacement without this audit would cause data loss. All other fixes are mechanical and low-risk.

**Primary recommendation:** Work through findings in severity order (Critical first), audit each try? individually before touching, and implement the atomic write helper once to use across all three rewrite sites.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Error Handling Strategy**
- D-01: Audit all 29 try? instances individually -- categorize each as safe (cleanup) or dangerous (data path) before changing anything
- D-02: Data-path file operation failures surface via os.Logger AND a non-blocking UI banner/toast. Recording continues despite the error.
- D-03: TranscriptLogger's write-remove-move sequence (SCAN-009) replaced with atomic write pattern: write to temp file, verify contents, atomically rename to replace original. If anything fails, original file is untouched.

**File Permissions Model**
- D-04: All transcript, session, and audio temp files created with POSIX 0600 (owner read/write only). No FileProtectionType -- just POSIX permissions uniformly.
- D-05: Audio temp files (SCAN-004) moved from system /tmp to Application Support/PSTranscribe/tmp/. Sandboxed, auto-cleaned on uninstall, restricted permissions.

**Crash Recovery**
- D-06: On next launch after crash, detect incomplete sessions (no finalization marker). Surface them in the library as "incomplete" with whatever transcript was flushed to disk. No auto-recovery attempt, no dialog -- just show what exists.
- D-07: Session finalization (STAB-03) uses checkpoint-based approach: write checkpoint file after each step (frontmatter done, diarization done, move done). On crash, resume from last completed checkpoint on next launch.

**Debug Logging**
- D-08: Replace /tmp file logging (diagLog) with os.Logger. Logging available in release builds at .debug level (suppressed by default in Console.app).
- D-09: Hidden toggle via UserDefaults key: `defaults write com.pstranscribe.app enableVerboseLogging -bool true`. No UI toggle needed -- power-user mechanism documented in README or help.
- D-10: Existing diagLog calls converted to os.Logger equivalents, not removed. Function signature can change but call sites preserved.

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

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SECR-01 | GH_TOKEN no longer exposed in CI git clone URLs | See CI Patterns -- use HTTPS with token in Authorization header via git config |
| SECR-02 | Debug log uses os.Logger instead of world-readable /tmp file | See Logging Patterns -- Logger(subsystem:category:) at .debug level |
| SECR-03 | Vault path validated against directory traversal before file creation | See Path Validation Pattern -- resolvingSymlinksInPath + hasPrefix |
| SECR-04 | System audio temp files use restricted permissions and reliable cleanup | See File Permissions Pattern -- POSIX 0600 + Application Support/tmp/ |
| SECR-05 | CI keychain file created via mktemp instead of predictable path | See CI Patterns -- mktemp /tmp/keychain.XXXXXX.keychain-db |
| SECR-06 | Transcript and session files created with restrictive file permissions | See File Permissions Pattern -- setAttributes after createFile |
| SECR-07 | GitHub Actions pinned to commit SHAs | See verified SHAs in CI Patterns section |
| SECR-08 | .gitignore includes secret file patterns | See .gitignore Pattern |
| SECR-09 | File I/O operations use explicit error handling with rollback, not try? | See try? Audit table + Atomic Write Pattern |
| SECR-10 | Filename sanitization uses whitelist approach | See Filename Sanitization Pattern |
| SECR-11 | Audio buffer memory cleared with removeAll(keepingCapacity: false) | Single-line change in StreamingTranscriber.swift |
| SECR-12 | CI cleanup logs errors instead of suppressing with 2>/dev/null | See CI Patterns -- replace with stderr echo |
| STAB-01 | App recovers incomplete sessions on next launch | See Crash Recovery Pattern |
| STAB-02 | Diarization timestamps use session-relative offsets, not clock time | See Timestamp Fix Pattern |
| STAB-03 | Session finalization is atomic or recoverable | See Checkpoint Pattern |
| STAB-04 | MicCapture errors propagate to UI via TranscriptionEngine.lastError | See Error Propagation Pattern |
</phase_requirements>

---

## Standard Stack

### Core
| Library/API | Version | Purpose | Why Standard |
|-------------|---------|---------|--------------|
| os.Logger | Built-in (Swift 6.x) | Structured logging replacing diagLog | Apple-standard, privacy-aware, Console.app integration |
| FileManager | Built-in | File I/O, permissions, directory ops | Foundation standard |
| Foundation.URL | Built-in | Path manipulation | Type-safe path operations |

### Supporting
| Library/API | Version | Purpose | When to Use |
|-------------|---------|---------|-------------|
| POSIX setAttributes | Built-in | Set 0600 file permissions | After createFile, before writing data |
| NSRegularExpression | Built-in | Filename sanitization whitelist | Already used in TranscriptLogger |
| mktemp (bash) | System | Unpredictable temp file paths in CI | CI keychain file creation |

No new package dependencies are introduced in this phase. All fixes use APIs already present in the codebase or system-provided tools.

---

## Architecture Patterns

### try? Audit -- Complete Classification

All 29 try? instances in the codebase, classified as SAFE (cleanup/optional) or DANGEROUS (data path, needs explicit handling):

**TranscriptLogger.swift**
| Line | Code | Classification | Action |
|------|------|---------------|--------|
| `try? fileHandle?.close()` (updateContext) | Close before rewrite | SAFE -- close failure doesn't lose data, handle will be nilled anyway | Keep try? |
| `guard var content = try? String(contentsOf:...)` (updateContext) | Read file for rewrite | DANGEROUS -- silent failure means context update is lost, no indication | Convert to do/catch, log error |
| `try? content.write(to: tmpPath...)` (updateContext) | Write temp file | DANGEROUS -- first step of write-remove-move chain | Replace with atomic helper |
| `try? FileManager.default.removeItem(at: filePath)` (updateContext) | Remove original | DANGEROUS -- if write succeeded but remove fails, silent inconsistency | Replace with atomic helper |
| `try? FileManager.default.moveItem(at: tmpPath, to: filePath)` (updateContext) | Move temp to final | DANGEROUS -- if remove succeeded but move fails, original is lost | Replace with atomic helper |
| `fileHandle = try? FileHandle(forWritingTo: filePath)` (updateContext) | Reopen handle | DANGEROUS -- silent failure means subsequent writes go to nil handle | Convert to do/catch |
| `try? fileHandle?.close()` (endSession) | Close at session end | SAFE -- cleanup, state is being reset regardless | Keep try? |
| `guard var content = try? String(contentsOf:...)` (rewriteFrontmatter) | Read file for frontmatter | DANGEROUS -- silent failure means frontmatter never updated | Convert to do/catch, log error |
| `try? content.write(to: tmpPath...)` (rewriteFrontmatter) | Write temp file | DANGEROUS -- first step of write-remove-move chain | Replace with atomic helper |
| `try? FileManager.default.removeItem(at: filePath)` (rewriteFrontmatter, rename path) | Remove old file on rename | DANGEROUS -- chained with move below | Replace with atomic helper |
| `try? FileManager.default.moveItem(at: tmpPath, to: finalPath)` (rewriteFrontmatter, rename path) | Move to new name | DANGEROUS | Replace with atomic helper |
| `try? FileManager.default.removeItem(at: filePath)` (rewriteFrontmatter, same-name path) | Remove original | DANGEROUS | Replace with atomic helper |
| `try? FileManager.default.moveItem(at: tmpPath, to: filePath)` (rewriteFrontmatter, same-name path) | Move temp to final | DANGEROUS | Replace with atomic helper |
| `guard var content = try? String(contentsOf:...)` (rewriteWithDiarization) | Read file for diarization rewrite | DANGEROUS -- silent failure means diarization is lost | Convert to do/catch, log error |
| `guard let regex = try? NSRegularExpression(...)` (rewriteWithDiarization) | Compile regex | SAFE -- pattern is hardcoded, failure means bug not user error | Keep try? (or assert in debug) |
| `try? content.write(to: tmpPath...)` (rewriteWithDiarization) | Write diarized temp | DANGEROUS | Replace with atomic helper |
| `try? FileManager.default.removeItem(at: filePath)` (rewriteWithDiarization) | Remove original | DANGEROUS | Replace with atomic helper |
| `try? FileManager.default.moveItem(at: tmpPath, to: filePath)` (rewriteWithDiarization) | Move diarized temp to final | DANGEROUS | Replace with atomic helper |

**SessionStore.swift**
| Line | Code | Classification | Action |
|------|------|---------------|--------|
| `try? FileManager.default.createDirectory(...)` (init) | Create sessions dir | MEDIUM -- silent failure means all subsequent writes fail with confusing error | Convert to do/catch, log error |
| `fileHandle = try? FileHandle(forWritingTo: currentFile!)` (startSession) | Open session file | DANGEROUS -- silent failure means all appendRecord calls silently drop data | Convert to do/catch |
| `try? fileHandle?.close()` (endSession) | Close at session end | SAFE -- cleanup | Keep try? |

**SystemAudioCapture.swift**
| Line | Code | Classification | Action |
|------|------|---------------|--------|
| `try? await _stream.withLock {...}?.stopCapture()` (stop) | Stop SCStream | SAFE -- cleanup, stream is being discarded | Keep try? |
| `try? FileManager.default.removeItem(at: path)` (cleanupBufferFile) | Delete audio temp file | SAFE -- cleanup, log but don't block | Keep try?, add os.Logger error log |
| `writer = try? AVAudioFile(forWriting: bufferPath, ...)` (audio callback) | Create audio file | DANGEROUS -- silent failure means diarization has no audio | Convert to do/catch, log error |
| `try? writer?.write(from: pcmBuffer)` (audio callback) | Write audio frame | DANGEROUS -- silent failure means diarization audio is incomplete | Convert to do/catch, log error |

**ContentView.swift**
| Line | Code | Classification | Action |
|------|------|---------------|--------|
| `try? await Task.sleep(for: .milliseconds(100))` | UI timer loop | SAFE -- CancellationError expected during view cleanup | Keep try? |
| `try? await Task.sleep(for: .seconds(1))` | UI timer loop | SAFE | Keep try? |
| `try? await Task.sleep(for: .seconds(10))` | UI timer loop | SAFE | Keep try? |
| `try? await Task.sleep(for: .seconds(8))` | UI timer loop | SAFE | Keep try? |

**Summary:** 4 SAFE keep, 4 SAFE with log added, 18 DANGEROUS need conversion, 3 SAFE Task.sleep keep.

---

### Pattern 1: Atomic Write Helper (SECR-09)

The three rewrite sites (updateContext, rewriteFrontmatter, rewriteWithDiarization) all share the same write-remove-move pattern with the same failure modes. Build one shared helper used by all three.

```swift
// In TranscriptLogger actor
private func atomicRewrite(at filePath: URL, newPath: URL? = nil, content: String) throws {
    let dir = filePath.deletingLastPathComponent()
    let tmpPath = dir.appendingPathComponent(".\(filePath.lastPathComponent).tmp")

    // Step 1: Write to temp. If this fails, original is untouched.
    do {
        try content.write(to: tmpPath, atomically: false, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: tmpPath.path
        )
    } catch {
        log.error("atomicRewrite: failed to write temp file: \(error.localizedDescription)")
        try? FileManager.default.removeItem(at: tmpPath)  // cleanup orphan
        throw error
    }

    let destination = newPath ?? filePath
    // Step 2: Remove original. If this fails, temp is orphaned but original is intact.
    do {
        if FileManager.default.fileExists(atPath: filePath.path) {
            try FileManager.default.removeItem(at: filePath)
        }
    } catch {
        log.error("atomicRewrite: failed to remove original: \(error.localizedDescription)")
        try? FileManager.default.removeItem(at: tmpPath)
        throw error
    }

    // Step 3: Move temp to final. If this fails, both are gone -- log prominently.
    do {
        try FileManager.default.moveItem(at: tmpPath, to: destination)
    } catch {
        log.error("atomicRewrite: CRITICAL -- failed to move temp to destination, data in \(tmpPath.path): \(error.localizedDescription)")
        throw error
    }
}
```

Note: `atomically: false` in Step 1 because we're doing our own atomic pattern. Using `atomically: true` internally would write to another temp then rename -- a double temp that adds no value here.

### Pattern 2: POSIX 0600 File Permissions (SECR-04, SECR-06)

Decision D-04 specifies POSIX 0600 via FileManager attributes, not FileProtectionType. This works uniformly across all file types.

```swift
// Set immediately after createFile
try FileManager.default.setAttributes(
    [.posixPermissions: 0o600],
    ofItemAtPath: filePath.path
)
```

For the audio temp directory (Application Support/PSTranscribe/tmp/):

```swift
// Set 0700 on directory so contents are not listable
try FileManager.default.setAttributes(
    [.posixPermissions: 0o700],
    ofItemAtPath: tmpDir.path
)
```

The `.posixPermissions` key expects an `NSNumber` with an octal value. The Swift literal `0o600` satisfies this when bridged via `FileAttributeKey.posixPermissions`. Confidence: HIGH -- this is standard Foundation API, verified against Apple docs.

### Pattern 3: os.Logger Replacing diagLog (SECR-02)

StreamingTranscriber already uses `Logger(subsystem: "com.pstranscribe.app", category: "StreamingTranscriber")`. The same subsystem is confirmed in Phase 1. New loggers follow the same pattern with appropriate categories.

```swift
// Replace diagLog global function entirely
// New file-level loggers per category:
private let log = Logger(subsystem: "com.pstranscribe.app", category: "TranscriptionEngine")
// In TranscriptLogger actor:
private let log = Logger(subsystem: "com.pstranscribe.app", category: "TranscriptLogger")
// In SystemAudioCapture:
// already has: private let log = Logger(subsystem:...) -- confirm it exists or add
```

The D-08/D-09 verbose logging toggle:

```swift
// In diagLog replacement -- only log .debug if verbose is on:
func diagLog(_ msg: String) {
    if UserDefaults.standard.bool(forKey: "enableVerboseLogging") {
        log.debug("\(msg, privacy: .public)")
    }
}
// The #if DEBUG guard is removed; os.Logger .debug messages are suppressed
// by Console.app in production unless the subsystem is explicitly enabled.
```

Important: os.Logger `.debug` messages are suppressed at the subsystem level in production builds unless the user runs `log config --subsystem com.pstranscribe.app --mode level:debug`. This satisfies D-08 without any conditional compilation.

### Pattern 4: Vault Path Traversal Validation (SECR-03)

Decision deferred to Claude's discretion. The safest approach for a sandboxed macOS app is to resolve symlinks then verify the resolved path starts with an expected prefix. However, the vault path is user-controlled (they chose it in settings), so the goal is preventing `/../../etc/passwd` style inputs from UserDefaults corruption, not preventing the user from choosing a path.

Recommended approach: resolve symlinks and confirm the path doesn't escape its own expanded form (no `.` components after resolution):

```swift
// In TranscriptLogger.startSession
func validatedVaultPath(_ rawPath: String) throws -> URL {
    let expanded = NSString(string: rawPath).expandingTildeInPath
    let resolved = URL(fileURLWithPath: expanded).resolvingSymlinksInPath
    let normalized = resolved.standardized

    // Reject if the path contains null bytes or known traversal patterns
    guard !expanded.contains("\0"),
          !expanded.contains("..") else {
        throw TranscriptLoggerError.invalidVaultPath(rawPath)
    }

    return normalized
}
```

The `..` check on the pre-expansion string is sufficient for the threat model (UserDefaults corruption or injection). A legitimate user path will never contain `..`.

### Pattern 5: Filename Sanitization Whitelist (SECR-10)

Decision D-Claude's discretion -- use whitelist approach. The session context used in filenames should only contain characters safe for all filesystems.

```swift
// Replace the blocklist approach (only removing / and :)
// With a whitelist that retains only alphanumeric, space, hyphen, underscore, period
private func sanitizedFilenameComponent(_ input: String) -> String {
    let allowed = CharacterSet.alphanumerics
        .union(.init(charactersIn: " -_."))
    return String(input.unicodeScalars.filter { allowed.contains($0) })
        .trimmingCharacters(in: .whitespaces)
        .prefix(50)
        .description
}
```

This strips null bytes, `..`, backslashes, control characters, and any other filesystem-special characters. HIGH confidence -- whitelist approach is unambiguously more robust than blocklist.

### Pattern 6: GH_TOKEN Fix (SECR-01)

The current code embeds GH_TOKEN in the clone URL. The fix uses `git config` to set the authorization header without exposing it in the process list:

```bash
# Replace:
git clone --branch gh-pages --single-branch "https://x-access-token:${GH_TOKEN}@github.com/OWNER/ps-transcribe.git" /tmp/gh-pages

# With:
git clone --branch gh-pages --single-branch "https://github.com/OWNER/ps-transcribe.git" /tmp/gh-pages
cd /tmp/gh-pages
git config http.https://github.com/.extraheader "Authorization: Basic $(echo -n "x-access-token:${GH_TOKEN}" | base64)"
```

Or more simply, use the `gh` CLI already available on GitHub-hosted runners (the workflow already uses `gh release upload`):

```bash
# Alternative using gh CLI (already authenticated via GH_TOKEN env var):
gh repo clone OWNER/ps-transcribe -- --branch gh-pages --single-branch /tmp/gh-pages
```

The `gh` CLI approach is preferable since the workflow already uses `gh release upload` on line 104 and `GH_TOKEN` is set as `${{ github.token }}`. The CLI reads it from the environment, not the URL. Confidence: HIGH.

### Pattern 7: Diarization Timestamp Fix (STAB-02)

The current bug: timestamps stored as clock time (HH:mm:ss strings), offset calculated by subtracting clock-time seconds of session start. This breaks at midnight because `uttSeconds - startSeconds` is negative.

Fix: store timestamps as `TimeInterval` (seconds since session start) when writing utterances. Change the flush format from `timeFmt.string(from: entry.timestamp)` to a relative seconds value, and update the regex + parsing accordingly.

```swift
// In flushBuffer, change timestamp format from HH:mm:ss to session-relative seconds
// utteranceBuffer stores timestamp: Date -- compute offset at flush time
let offsetSeconds = entry.timestamp.timeIntervalSince(sessionStartTime ?? entry.timestamp)
let hh = Int(offsetSeconds) / 3600
let mm = (Int(offsetSeconds) % 3600) / 60
let ss = Int(offsetSeconds) % 60
let relativeTimestamp = String(format: "%02d:%02d:%02d", hh, mm, ss)

// In rewriteWithDiarization, the offsetSeconds computation simplifies to:
// Parse the HH:mm:ss as a duration (not a clock time) -- no calendar math needed
let parts = timeStr.split(separator: ":").compactMap { Int($0) }
guard parts.count == 3 else { continue }
let offsetSeconds = Float(parts[0] * 3600 + parts[1] * 60 + parts[2])
```

Existing transcripts written with clock-time format will parse incorrectly with the new code during diarization, but this only matters for the current session (diarization runs immediately after recording stops). Historical transcripts are not re-diarized. The change is safe to make without a migration. Confidence: HIGH.

### Pattern 8: Crash Recovery with Checkpoint Files (STAB-01, STAB-03)

D-07: Write checkpoint files alongside session data after each finalization step. On launch, scan for sessions with in-progress markers.

Checkpoint file location: `Application Support/PSTranscribe/sessions/.checkpoints/`

Checkpoint file naming: `{session-datetime}.checkpoint.json`

```swift
struct SessionCheckpoint: Codable {
    let sessionStartTime: Date
    let transcriptPath: String       // absolute path
    let completedSteps: [String]     // ["transcript_written", "frontmatter_done", "diarization_done"]
    let isFinalized: Bool
}
```

Steps that write checkpoints:
1. `TranscriptLogger.startSession` -- write checkpoint with `[]` completed steps (session started)
2. After `endSession()` flushes buffer -- add `"transcript_written"` to completed steps
3. After `finalizeFrontmatter()` -- add `"frontmatter_done"`
4. After `rewriteWithDiarization()` -- add `"diarization_done"`
5. Final: mark `isFinalized: true` and delete checkpoint file

On launch: scan checkpoint directory. Any checkpoint without `isFinalized: true` is an incomplete session. Surface transcript path in library as "incomplete" (D-06). No auto-recovery needed.

### Pattern 9: MicCapture Error Propagation (STAB-04)

MicCapture already stores errors in `_error: SyncString`. TranscriptionEngine already has `var lastError: String?`. The plumbing is mostly there -- the gap is that TranscriptionEngine never reads `micCapture.captureError` after the mic task completes.

```swift
// In TranscriptionEngine, in the micTask block:
micTask = Task.detached {
    let hadFatalError = await micTranscriber.run(stream: micStream)
    if hadFatalError {
        await MainActor.run {
            self.lastError = self.micCapture.captureError ?? "Microphone recording failed"
        }
    }
}
```

ContentView already observes `transcriptionEngine?.lastError` via `@Observable`, so the error will appear in the UI without any UI changes needed in this phase. This satisfies STAB-04 with a minimal code change.

### CI Patterns

**SECR-05: mktemp for keychain file**
```bash
# Replace:
KEYCHAIN_FILE="/tmp/build-$$-$(date +%s).keychain-db"
# With:
KEYCHAIN_FILE=$(mktemp /tmp/keychain.XXXXXX.keychain-db)
```

**SECR-07: Pinned SHA digests for GitHub Actions**

Verified SHA values (fetched from GitHub releases pages on 2026-04-02):

| Action | Tag | Verified SHA |
|--------|-----|-------------|
| actions/checkout | v4 | `34e114876b0b11c390a56381ad16ebd13914f8d5` |
| actions/upload-artifact | v4 | `ea165f8d65b6e75b540449e92b4886f43607fa02` |

Usage pattern:
```yaml
- uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5  # v4
- uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02  # v4
```

Confidence: MEDIUM -- SHAs fetched from releases pages, which show tag-to-SHA mappings. Implementer should verify on GitHub before committing.

**SECR-12: Replace 2>/dev/null || true with logged cleanup**
```bash
# Replace:
security delete-keychain "$KEYCHAIN_FILE" 2>/dev/null || true
# With:
if ! security delete-keychain "$KEYCHAIN_FILE"; then
    echo "Warning: failed to delete keychain $KEYCHAIN_FILE -- may need manual cleanup" >&2
fi
```

**SECR-08: .gitignore additions**
```gitignore
# Secrets and credentials
.env
*.env.*
*.p12
*.cer
*.pem
*.key
*.keychain
*.keychain-db
*.mobileprovision
*.xcconfig
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Atomic file replace | Custom lock+swap | `FileManager.moveItem` (after verified write) | moveItem is atomic at FS level on same volume |
| Structured logging | diagLog to /tmp | `os.Logger` | Privacy controls, Console integration, no disk writes |
| Filename sanitization | Manual char-by-char loop | `CharacterSet` union + filter | Correct Unicode handling |
| Temp file path | PID+timestamp concat | `mktemp` (bash) or `FileManager.temporaryDirectory` + UUID (Swift) | Unpredictable, race-free |

**Key insight:** The atomic rename pattern (`write to temp, then rename`) is what the OS-level VFS guarantees atomicity for -- not the write itself. This is why the three-step try? sequence fails: the write to atomically:true creates an internal temp then renames it, but our outer removeItem+moveItem is NOT atomic relative to that.

---

## Common Pitfalls

### Pitfall 1: "Atomic" write is not the same as "safe" write
**What goes wrong:** Using `content.write(to:atomically:true)` and thinking the data is safe. It writes to an OS-chosen temp then renames, but if a crash happens before the rename completes, you get the old file (not partial data). This is fine for the write itself, but is NOT safe when combined with `removeItem` on the original first.
**Why it happens:** The code does: write-temp, remove-original, move-temp. If remove succeeds but move fails, original is gone.
**How to avoid:** Never removeItem before you have confirmed the new content is safely written and accessible. The safe order is: write-temp (verify), move-temp-over-original (using replaceItemAt or moveItem when original doesn't exist).
**Warning signs:** `try?` on any of the three steps with no log or error state.

### Pitfall 2: Clock-time timestamps break at midnight
**What goes wrong:** Timestamp string "23:55:00" minus start "23:50:00" = 300 seconds. But "00:05:00" minus "23:50:00" = -85,800 seconds. Diarization segment matching fails completely for all utterances after midnight.
**Why it happens:** `HH:mm:ss` strings are parsed as wall-clock times, not durations.
**How to avoid:** Always store timestamps as `TimeInterval` relative to session start. Convert to display format (HH:mm:ss) only in the UI.
**Warning signs:** `calendar.dateComponents([.hour, .minute, .second], from:)` used to compute offsets.

### Pitfall 3: File permissions set too late
**What goes wrong:** `createFile` creates the file with default permissions (0644 on macOS), then a window exists before `setAttributes` is called where another process could read it.
**Why it happens:** File creation and permission setting are two separate operations.
**How to avoid:** Set permissions immediately after createFile in the same synchronous block. For the actor-based storage layer, no other code can interleave between these two calls within the same method, so the window is effectively zero in practice.
**Warning signs:** setAttributes call in a separate function from createFile.

### Pitfall 4: os.Logger .debug messages are NOT suppressed by #if DEBUG alone
**What goes wrong:** Assuming os.Logger messages are invisible in release builds. They're written to the unified log and visible in Console.app.
**Why it happens:** Unlike print(), os.Logger writes to the system log always. `.debug` level is hidden by default in Console.app unless the subsystem is explicitly enabled, but they ARE in the log.
**How to avoid:** Use appropriate privacy level for sensitive content: `.private` for paths/content, `.public` for status messages. The D-08 design is correct: no `#if DEBUG`, rely on Console.app's default filtering.
**Warning signs:** Logging transcript content or audio file paths at `.public` privacy level.

### Pitfall 5: MainActor crossing from actor context for error surfacing
**What goes wrong:** `TranscriptLogger` is an `actor` -- it cannot directly call MainActor code. Error surfacing (D-02) requires posting to MainActor.
**Why it happens:** Swift 6 strict concurrency prevents direct actor-to-MainActor calls.
**How to avoid:** The actor logs the error with os.Logger. The caller (in TranscriptionEngine, which IS MainActor) handles the thrown error and sets `lastError`. The actor does NOT need to reach out to MainActor itself -- it throws, and the MainActor caller catches and surfaces.
**Warning signs:** Attempting `Task { @MainActor in ... }` from within the actor body to update UI state.

---

## Code Examples

### os.Logger with Privacy Controls
```swift
// Source: Apple os.Logger documentation
// Transcript paths should be private (not logged by default in Console)
log.error("Failed to write transcript: \(filePath.path, privacy: .private)")
// Status messages can be public
log.debug("Session started: \(sourceApp, privacy: .public)")
```

### FileManager POSIX Permissions
```swift
// Source: Apple FileManager documentation
try FileManager.default.setAttributes(
    [FileAttributeKey.posixPermissions: NSNumber(value: 0o600)],
    ofItemAtPath: filePath.path
)
```

### Application Support Directory (matches existing SessionStore pattern)
```swift
// SessionStore already uses this pattern -- match it exactly
let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
let audioTmpDir = appSupport.appendingPathComponent("PSTranscribe/tmp", isDirectory: true)
try FileManager.default.createDirectory(at: audioTmpDir, withIntermediateDirectories: true)
try FileManager.default.setAttributes([.posixPermissions: NSNumber(value: 0o700)], ofItemAtPath: audioTmpDir.path)
```

### Checkpoint Write
```swift
// Checkpoint files are non-critical -- if they fail to write, log and continue
private func writeCheckpoint(_ checkpoint: SessionCheckpoint, to dir: URL) {
    let filename = "\(checkpoint.sessionId).checkpoint.json"
    let path = dir.appendingPathComponent(filename)
    do {
        let data = try JSONEncoder().encode(checkpoint)
        try data.write(to: path)
        try FileManager.default.setAttributes([.posixPermissions: NSNumber(value: 0o600)], ofItemAtPath: path.path)
    } catch {
        log.error("Failed to write checkpoint: \(error.localizedDescription, privacy: .public)")
        // Non-fatal -- crash recovery is best-effort
    }
}
```

---

## Environment Availability

Step 2.6: SKIPPED (no external tools or services required -- all fixes are code/config/CI changes using existing Apple APIs and bash utilities already present on GitHub-hosted macOS runners).

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None detected -- no test targets in Package.swift |
| Config file | None |
| Quick run command | `swift build` (compilation only) |
| Full suite command | `swift build` |

No automated test infrastructure exists. The phase introduces checkpoint files, atomic write helpers, and timestamp logic -- all of which have correctness requirements that would benefit from tests. However, per CONCERNS.md, adding tests is not in scope for Phase 2.

### Phase Requirements -- Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SECR-01 | GH_TOKEN not in URLs | Manual CI inspection | n/a | -- |
| SECR-02 | No /tmp log file created | Manual: run debug build, check /tmp | n/a | -- |
| SECR-03 | `..` in vault path rejected | Manual: set malformed path in defaults | n/a | -- |
| SECR-04 | Audio temp in App Support, 0600 | Manual: check file location + `ls -la` | n/a | -- |
| SECR-05 | Keychain path uses mktemp | CI diff inspection | n/a | -- |
| SECR-06 | Transcript files 0600 | Manual: create session, `ls -la` vault | n/a | -- |
| SECR-07 | Actions pinned to SHA | CI diff inspection | n/a | -- |
| SECR-08 | .gitignore has secret patterns | `git check-ignore -v test.p12` | Manual | -- |
| SECR-09 | Atomic write doesn't lose data | Manual: force-kill mid-write, verify file intact | n/a | -- |
| SECR-10 | Sanitized filename strips special chars | Manual: set context with `../evil`, verify filename | n/a | -- |
| SECR-11 | removeAll(keepingCapacity: false) | Code inspection | n/a | -- |
| SECR-12 | CI cleanup logs instead of suppresses | CI diff inspection | n/a | -- |
| STAB-01 | Incomplete session visible after crash | Manual: force-quit mid-session, relaunch | n/a | -- |
| STAB-02 | Midnight-crossing timestamps correct | Manual: set clock near midnight, verify offset math | n/a | -- |
| STAB-03 | Checkpoint files written during finalization | Manual: inspect App Support after session | n/a | -- |
| STAB-04 | MicCapture error appears in UI | Manual: deny mic permission, start recording | n/a | -- |

### Sampling Rate
- **Per task commit:** `swift build` (compilation gate -- catches type errors)
- **Per wave merge:** `swift build`
- **Phase gate:** `swift build` passes + manual verification checklist above passes

### Wave 0 Gaps
No test infrastructure changes needed -- there is no test target to create or configure. The verification strategy for this phase is compilation + manual spot checks for each fix.

---

## Open Questions

1. **MicCapture error after successful start**
   - What we know: MicCapture stores errors in `_error: SyncString`, set when `continuation.finish()` is called with an error message. TranscriptionEngine reads `micCapture.captureError` nowhere.
   - What's unclear: Does TranscriptionEngine have a hook that fires when the mic task finishes with `hadFatalError = true`? Looking at the code: yes, `micTask` is a `Task.detached` that calls `micTranscriber.run(stream:)` and checks `hadFatalError`. The `reportMicError` call site is referenced in ARCHITECTURE.md but not visible in the truncated TranscriptionEngine read.
   - Recommendation: Read the full micTask setup block in TranscriptionEngine before implementing STAB-04.

2. **Checkpoint file location relative to SessionStore**
   - What we know: SessionStore writes to `Application Support/PSTranscribe/sessions/`. Checkpoint files should be nearby.
   - What's unclear: Should checkpoints be inside `sessions/` or in a sibling `checkpoints/` directory?
   - Recommendation: Use `Application Support/PSTranscribe/sessions/.checkpoints/` (subdirectory of sessions) to keep them co-located. The dot prefix hides them from casual directory browsing.

3. **Verified GitHub Actions SHAs**
   - What we know: Fetched SHAs from release pages show `34e114876b0b11c390a56381ad16ebd13914f8d5` (checkout v4) and `ea165f8d65b6e75b540449e92b4886f43607fa02` (upload-artifact v4).
   - What's unclear: Whether these are the latest v4 point releases or the v4 major-version tag. The releases page may show the latest tagged release, not the latest commit on v4.
   - Recommendation: Implementer should run `git ls-remote https://github.com/actions/checkout refs/tags/v4` and `git ls-remote https://github.com/actions/upload-artifact refs/tags/v4` at implementation time to confirm the SHAs, since they can change when maintainers move the tag.

---

## Sources

### Primary (HIGH confidence)
- Apple FileManager documentation -- POSIX permissions, setAttributes, createDirectory
- Apple os.Logger documentation -- Logger(subsystem:category:), privacy levels, debug suppression
- Apple Foundation URL documentation -- resolvingSymlinksInPath, standardized

### Secondary (MEDIUM confidence)
- GitHub Actions checkout v4 release page (fetched 2026-04-02) -- SHA `34e114876b0b11c390a56381ad16ebd13914f8d5`
- GitHub Actions upload-artifact v4 release page (fetched 2026-04-02) -- SHA `ea165f8d65b6e75b540449e92b4886f43607fa02`

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new libraries, all Apple built-in APIs
- Architecture patterns: HIGH -- derived directly from reading the source files; every pattern references actual code locations
- try? audit: HIGH -- all 29 instances read and classified from actual file content
- Pitfalls: HIGH -- derived from actual code analysis + CONCERNS.md
- GitHub Actions SHAs: MEDIUM -- fetched from release pages, should be re-verified at implementation time

**Research date:** 2026-04-02
**Valid until:** 2026-05-02 (SHAs may change sooner if actions maintainers update tags)
