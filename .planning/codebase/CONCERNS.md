# Codebase Concerns

**Analysis Date:** 2026-03-30

## Security Issues

### CRITICAL: GH_TOKEN exposed in CI logs
- **Risk:** Token visible in GitHub Actions runner logs and process listings
- **Files:** `.github/workflows/release-dmg.yml:142`
- **Current state:** Token embedded in git clone URL: `https://x-access-token:${GH_TOKEN}@github.com/...`
- **Recommendations:** Use SSH keys with deploy keys or GitHub App tokens instead. Never pass tokens in URLs that get logged.

### CRITICAL: Debug log writes to world-readable /tmp
- **Risk:** Audio device details, sample counts, session metadata leaked to all local users
- **Files:** `Tome/Sources/Tome/Transcription/TranscriptionEngine.swift:7-20`
- **Current state:** `/tmp/tome.log` created with default permissions (644 on most systems). Guarded by `#if DEBUG` but debug builds expose transcription metadata.
- **Recommendations:** Use `os_log` framework instead of direct file writes. If file logging needed: create in app's restricted container with 0600 permissions, or use private temp directory with restricted permissions.

### HIGH: Unvalidated vault path allows directory traversal
- **Risk:** Modified UserDefaults could write transcript files anywhere on disk
- **Files:** `Tome/Sources/Tome/Storage/TranscriptLogger.swift:39-41`
- **Current state:** `vaultPath` from UserDefaults passed directly to `expandingTildeInPath` and `createDirectory`. No validation for `..`, symbolic links, or filesystem junctions.
- **Recommendations:** Validate that expanded path is within intended vault directory. Use `URL(fileURLWithPath:).resolvingSymlinksInPath` and compare against vault root.

### HIGH: Unencrypted audio buffer in system temp
- **Risk:** Raw PCM audio from system capture written unencrypted to shared `/tmp`. File cleanup uses `try?` so failures are silent.
- **Files:** `Tome/Sources/Tome/Audio/SystemAudioCapture.swift:46, 83-87`
- **Current state:** WAV file created with `UUID()` filename but no encryption. Cleanup (line 85) suppresses errors.
- **Recommendations:** Use FileProtectionType.complete when creating file. Encrypt before writing. Log cleanup failures instead of suppressing with `try?`.

### HIGH: Transcript files written unencrypted with default permissions
- **Risk:** Transcripts readable by any local user without FileVault enabled
- **Files:** `Tome/Sources/Tome/Storage/TranscriptLogger.swift:97-98`, `SessionStore.swift:32-35`
- **Current state:** Markdown and JSONL files created with `FileManager.default.createFile()` — no file protection attributes set.
- **Recommendations:** Set file protection immediately after creation using `try? FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath:)`.

### HIGH: Predictable keychain temp file in CI
- **Risk:** Co-tenant on CI runner could pre-create symlink at predictable path
- **Files:** `.github/workflows/release-dmg.yml:47`
- **Current state:** `KEYCHAIN_FILE="/tmp/build-$$-$(date +%s).keychain-db"` — PID and epoch seconds are guessable.
- **Recommendations:** Use `mktemp` for keychain file too (currently only cert file uses it). Verify symlink safety in CI scripts.

### MEDIUM: Incomplete .gitignore missing secret patterns
- **Risk:** Accidental commit of signing certificates, provisioning profiles, env files
- **Files:** `.gitignore`
- **Current state:** Missing patterns: `.env`, `*.p12`, `*.cer`, `*.pem`, `*.key`, `*.keychain*`, `*.mobileprovision`
- **Recommendations:** Add patterns for all secret file types. Add `*.xcconfig` with credentials.

### MEDIUM: Unpinned GitHub Actions versions
- **Risk:** Compromised action upstream could inject code into release pipeline
- **Files:** `.github/workflows/release-dmg.yml:15, 94` and others
- **Current state:** Using `actions/checkout@v4`, `actions/upload-artifact@v4` (mutable tags)
- **Recommendations:** Pin to commit SHAs: `actions/checkout@a5ac7e51b41094c153674e0871121552f463ba63` etc.

### LOW: Audio buffer memory not securely cleared
- **Risk:** Previous audio data remains in deallocated-but-retained memory
- **Files:** `Tome/Sources/Tome/Transcription/StreamingTranscriber.swift:100, 108`
- **Current state:** `speechSamples.removeAll(keepingCapacity: true)` retains allocation. Low risk on macOS with ASLR but relevant for privacy-sensitive data.
- **Recommendations:** Use `removeAll(keepingCapacity: false)` or implement secure buffer clearing with memset equivalent.

---

## Fragile Areas & Race Conditions

### Audio Pipeline Synchronization
- **Problem:** Mic and system audio are captured and transcribed on separate concurrent tasks with no explicit synchronization between them.
- **Files:** `Tome/Sources/Tome/Transcription/TranscriptionEngine.swift:136-141, 163-168`
- **Risk:** Timestamp misalignment during diarization. If one stream stalls, utterances get attributed to wrong speaker.
- **Safe modification:** Add synchronized clock source or explicit coordination mechanism between the two transcription streams.

### Diarization Timestamp Calculation Bug
- **Problem:** Session start time is stored as full `Date` but transcript timestamps are stored as clock time (HH:mm:ss). The offset calculation assumes same-day transcription.
- **Files:** `Tome/Sources/Tome/Storage/TranscriptLogger.swift:336-343`
- **Risk:** Transcriptions spanning midnight will have incorrect speaker attribution. Offset calculation will be negative or wildly wrong.
- **Safe modification:** Store all timestamps relative to session start, not clock time. Use `Date().timeIntervalSince(sessionStart)` everywhere.

### File Operations Race in TranscriptLogger
- **Problem:** Three sequential unguarded `try?` operations (write, remove, move) in atomic write operations
- **Files:** `Tome/Sources/Tome/Storage/TranscriptLogger.swift:163-165, 288-296, 382-384`
- **Risk:** 
  - If `removeItem` fails but `moveItem` succeeds, old file gets overwritten with temp file
  - If `moveItem` fails after `removeItem`, original file is deleted and data is lost
  - Failures are silently swallowed, leaving .tome_tmp files on disk
- **Safe modification:** 
  1. Check each operation's result explicitly
  2. Log errors instead of suppressing
  3. On failure, restore from backup or clear error state before continuing

### Concurrent File Handle Access
- **Problem:** `TranscriptLogger` and `SessionStore` both hold file handles that can be closed or replaced while data is being written.
- **Files:** `Tome/Sources/Tome/Storage/TranscriptLogger.swift:99-100, 130-131`, `SessionStore.swift:29-35`
- **Risk:** Write during close (line 143-144) could cause data loss or corruption if flushBuffer() is called concurrently.
- **Safe modification:** Ensure file handle is checked and acquired atomically before each write. Use `actor` isolation (TranscriptLogger already is, but endSession doesn't flush then close atomically).

### Audio Level State Race
- **Problem:** `audioLevel` in `AudioLevel` and `_audioLevel` in UI updated from multiple callback threads without synchronization
- **Files:** `Tome/Sources/Tome/Audio/SystemAudioCapture.swift:117`, `MicCapture.swift:77`
- **Risk:** Torn reads on 32-bit systems (unlikely on modern macOS but possible in theory). More practically: waveform visualizer jitters from unsynchronized samples.
- **Safe modification:** Already using `OSAllocatedUnfairLock` in SystemAudioCapture — verify MicCapture's AudioLevel wrapper does the same.

---

## Error Handling & Silent Failures

### Silent Error Suppression Throughout File I/O
- **Count:** 29 instances of `try?` across codebase
- **Problem:** Critical failures become invisible. Transcript loss, audio loss, or corrupted state not reported.
- **High-risk instances:**
  - `TranscriptLogger.swift:163-165` — three sequential file ops, all suppressed
  - `TranscriptLogger.swift:382-384` — diarization rewrite, silent failure loses speaker attribution
  - `SystemAudioCapture.swift:85` — audio buffer cleanup fails silently, temp files accumulate
  - `SessionStore.swift:13` — directory creation failure ignored, subsequent writes will fail
- **Recommendations:** Replace `try?` with explicit error logging at least in: file operations (TranscriptLogger), audio buffer cleanup, directory creation.

### Incomplete Error Recovery in Audio Capture
- **Problem:** MicCapture errors cause stream to finish but engine doesn't visibly report them
- **Files:** `Tome/Sources/Tome/Audio/MicCapture.swift:40-41, 56, 65`
- **Risk:** User gets silent audio dropout with no indication something failed.
- **Current state:** Errors stored in `_error` but never surfaced to UI unless explicitly checked.
- **Recommendations:** Ensure MicCapture errors propagate to ContentView's `transcriptionEngine?.lastError`.

### Task Cancellation Not Handled
- **Problem:** Many async tasks use `try? await Task.sleep()` suppressing CancellationError
- **Files:** `Tome/Sources/Tome/Views/ContentView.swift:100, 119, 136, 343`
- **Risk:** CancellationErrors hidden; unclear when tasks actually stop
- **Recommendations:** Use `try await Task.sleep()` (without try?) since CancellationError is expected and should propagate. Check `Task.isCancelled` explicitly instead.

---

## Tech Debt & Performance Issues

### Large File (TranscriptLogger)
- **Size:** 402 lines
- **Issue:** Handles session lifecycle, file I/O, markdown generation, regex substitution, AND diarization rewriting all in one actor
- **Improvement path:** Split into: SessionFile (file handle lifecycle), TranscriptMarkdown (formatting), TranscriptDiarizer (post-processing). Makes error handling and testing easier.

### Complex Timestamp/Filename Sanitization Logic Duplicated
- **Problem:** Session context prefix+sanitization appears in multiple places (lines 214-217, 267-270)
- **Files:** `Tome/Sources/Tome/Storage/TranscriptLogger.swift`
- **Issue:** Incomplete sanitization (only removes `/` and `:`, not `..`, null bytes, backslashes)
- **Improvement path:** Extract to shared function, add comprehensive sanitization (null bytes, path traversal, filesystem special chars).

### Audio Resampling on Every Buffer
- **Problem:** `AVAudioConverter` recreated if source format changes (StreamingTranscriber:177-178)
- **Files:** `Tome/Sources/Tome/Transcription/StreamingTranscriber.swift:177-178`
- **Risk:** Inefficient if format changes frequently; converter initialization isn't cheap
- **Improvement path:** Cache converter per-format or validate format won't change at stream start.

### Missing Input Validation
- **Problem:** Vault paths, session context, locale strings accepted without validation
- **Files:** `Tome/Sources/Tome/Settings/AppSettings.swift` (initialization), `TranscriptionEngine.swift:59`
- **Risk:** Invalid paths, invalid locales, empty strings cause cryptic failures downstream
- **Improvement path:** Add validators. Enforce non-empty vaultPaths, valid locales, reasonable session context length.

### Audio Buffer File Not Cleaned Up on Crashes
- **Problem:** SystemAudioCapture creates WAV files in `/tmp` but cleanup only called explicitly
- **Files:** `Tome/Sources/Tome/Audio/SystemAudioCapture.swift:83-87, 350`
- **Risk:** Temp audio files accumulate across crashes/force-quits. User's `/tmp` fills with old audio data.
- **Improvement path:** Implement cleanup in deinit or add timer-based cleanup at app start.

### Session Finalization Not Atomic
- **Problem:** endSession() -> finalizeFrontmatter() -> rewriteWithDiarization() happens in three separate steps. If crash between endSession and finalizeFrontmatter, file is left with incomplete metadata.
- **Files:** `Tome/Sources/Tome/Views/ContentView.swift:315-350` (stopSession logic)
- **Risk:** Incomplete transcript files with wrong duration/speaker count
- **Improvement path:** Atomic multi-step transaction or delayed write until all steps complete.

---

## Known Bugs & Incomplete Features

### Diarization Speaker ID Mapping Fragile
- **Problem:** Speaker ID to label mapping (Speaker 2, Speaker 3, etc.) based on order of appearance in diarization segments, not consistent across reruns
- **Files:** `Tome/Sources/Tome/Storage/TranscriptLogger.swift:306-313`
- **Risk:** If diarization is re-run, speaker IDs might change (Speaker 2 becomes Speaker 3)
- **Workaround:** Don't re-run diarization; if you do, speaker labels may shift
- **Fix approach:** Use stable hashing of diarization segment IDs, not iteration order.

### Incomplete Filename Sanitization Allows Path Traversal
- **Problem:** Session context used in filename after only removing `/` and `:`. Null bytes, `..`, backslashes not stripped.
- **Files:** `Tome/Sources/Tome/Storage/TranscriptLogger.swift:214-217, 267-270`
- **Risk:** Context like `../../etc/passwd` would create file in unexpected location (though mitigated by vault path). Null bytes could cause truncation.
- **Workaround:** Keep session context simple, no special characters
- **Fix approach:** Use comprehensive whitelist (alphanumeric, hyphen, underscore, space) or reject any string with path-special characters.

### Silence Auto-Stop at 120 Seconds May Be Too Aggressive
- **Problem:** If audio drops for >2 minutes (network hiccup, speaker muted), session auto-stops
- **Files:** `Tome/Sources/Tome/Views/ContentView.swift:125-129`
- **Risk:** Long pauses in conversation cause unwanted session end
- **Current behavior:** Configurable timer commented out; hardcoded to 120s
- **Improvement path:** Make configurable in settings. Consider disabling for some session types.

---

## Test Coverage Gaps

### No Tests for File I/O Error Cases
- **What's not tested:** 
  - Disk full during transcript write
  - Permission denied on vault directory
  - File already exists with same name
  - Temp file cleanup when move fails
- **Files:** `TranscriptLogger.swift`, `SessionStore.swift`
- **Risk:** Silent data loss in production
- **Priority:** High

### No Tests for Audio Stream Drops
- **What's not tested:**
  - MicCapture failing after successful start
  - SystemAudioCapture stopping mid-session
  - One stream finishing while other is still running
- **Files:** `TranscriptionEngine.swift`
- **Risk:** Concurrent task state leaks or crashes
- **Priority:** High

### No Tests for Timestamp Edge Cases
- **What's not tested:**
  - Transcriptions spanning midnight
  - Sessions longer than 12 hours (timestamp wraps)
  - Diarization segment overlap with utterance timestamps
- **Files:** `TranscriptLogger.swift:336-343`
- **Risk:** Incorrect speaker attribution after midnight
- **Priority:** Medium

### No Tests for Race Conditions in File Operations
- **What's not tested:**
  - Concurrent writes to same transcript file
  - finalizeFrontmatter() called while endSession() is in progress
  - Cleanup races between two sessions
- **Files:** `TranscriptLogger.swift`, `SessionStore.swift`
- **Risk:** Data corruption, orphaned temp files
- **Priority:** Medium

---

## Scaling Limits

### Audio Buffer Memory Unbounded During Long Sessions
- **Problem:** `speechSamples` array grows to `flushInterval` (480k samples = ~30 seconds of audio per flush)
- **Files:** `Tome/Sources/Tome/Transcription/StreamingTranscriber.swift:51, 117-120`
- **Current behavior:** Works fine for typical meetings. For very long sessions (8+ hours), transcriber may accumulate significant memory.
- **Capacity:** System audio capture also buffers to WAV file on disk (unbounded)
- **Improvement path:** Add memory pressure monitoring or flush more frequently on high memory.

### Temp Audio File Grows Unbounded
- **Problem:** SystemAudioCapture writes all captured audio to `/tmp/tome_sys_audio_*.wav` until session ends
- **Files:** `Tome/Sources/Tome/Audio/SystemAudioCapture.swift:46, 125-133`
- **Risk:** Hour-long session = ~600MB WAV file. `/tmp` may not have that much space.
- **Improvement path:** Implement ring buffer or streaming diarization instead of post-session processing.

### Transcript File Regex Operations Scale Poorly
- **Problem:** Entire transcript file read into memory, then processed with regex replacements
- **Files:** `Tome/Sources/Tome/Storage/TranscriptLogger.swift:239, 322-372`
- **Risk:** Multi-hour transcript files (100K+ lines) cause memory spike and regex stalls
- **Improvement path:** Stream-based transcript processing, incremental regex updates instead of full rewrites.

---

## Dependencies at Risk

### FluidAudio Models Download & Caching
- **Risk:** Large ML model download on first run; no resume/retry logic
- **Files:** `Tome/Sources/Tome/Transcription/TranscriptionEngine.swift:72`
- **Current state:** Download happens in UI blocking task. No visible progress during download beyond "Downloading multilingual model (first run)...".
- **Improvement path:** Add progress reporting. Implement download resume. Cache validation.

### ScreenCaptureKit (macOS 15+ dependency)
- **Risk:** SCStream is macOS 13+ API but may have subtle bugs in certain configurations
- **Files:** `Tome/Sources/Tome/Audio/SystemAudioCapture.swift:61-70`
- **Current state:** No fallback if ScreenCaptureKit fails. Per-app filtering falls back to all-audio, but no lower-level fallback.
- **Improvement path:** Document macOS version requirements. Test on older macOS versions.

---

## Missing Critical Features

### No Session Recovery After Crash
- **Problem:** If app crashes mid-transcript, last session file is left incomplete
- **Files:** `Tome/Sources/Tome/Storage/TranscriptLogger.swift` (no crash recovery)
- **Blocks:** Reliable session history; incomplete transcripts appear in vault
- **Improvement path:** Implement session recovery: mark sessions as "in-progress", recover/clean on next launch

### No Diarization Quality Metrics
- **Problem:** No indication whether diarization succeeded or how confident it was
- **Files:** `Tome/Sources/Tome/Transcription/TranscriptionEngine.swift:327-357`
- **Blocks:** User can't validate whether speaker attribution is reliable
- **Improvement path:** Return confidence scores from diarizer, display to user

### No Partial Transcript Export During Session
- **Problem:** Transcript only saved/exported after session ends
- **Files:** `Tome/Sources/Tome/Views/ContentView.swift:312-350`
- **Blocks:** Long sessions risk data loss if app crashes
- **Improvement path:** Implement auto-save or periodic export

---

## Deployment & CI/CD Concerns

### CI Workflow Secret Exposure Risk
- **Problem:** GH_TOKEN logged in runner process list; APPLE_ID/APPLE_APP_PASSWORD in environment
- **Files:** `.github/workflows/release-dmg.yml:142, 79-81`
- **Risk:** CI logs captured by third-party services or retained in GitHub artifacts
- **Recommendations:** Use secrets context mask. Consider GitHub-hosted instead of custom runners.

### No Signed Build Verification
- **Problem:** DMG is signed but no verification step in workflow
- **Files:** `.github/workflows/release-dmg.yml:69-84` (build step has no signature check)
- **Risk:** Build artifact corruption not detected
- **Improvement path:** Add post-build `codesign -v` verification

### No Rollback Strategy for Failed Releases
- **Problem:** If release fails mid-way, no mechanism to clean up partial release or publish
- **Files:** `.github/workflows/release-dmg.yml`
- **Risk:** Failed release leaves artifact in bad state
- **Improvement path:** Implement release cleanup on failure, transactional release steps

---

## Summary by Priority

| Severity | Count | Examples |
|----------|-------|----------|
| CRITICAL | 2 | GH_TOKEN logs, /tmp debug log exposure |
| HIGH | 4 | Unvalidated vault path, unencrypted audio, unencrypted transcripts, predictable keychain |
| MEDIUM | 4 | Incomplete gitignore, unpinned actions, silent error suppression, incomplete sanitization |
| LOW | 2 | Memory clearing, CI error suppression |
| **Architectural** | 5 | Audio sync, diarization timestamp bugs, file operation races, finalization atomicity, session recovery |

---

*Concerns audit: 2026-03-30*
