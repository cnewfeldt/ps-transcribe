# Pitfalls Research

**Domain:** macOS native audio transcription app -- rebrand, Ollama LLM integration, security hardening
**Researched:** 2026-03-31
**Confidence:** HIGH (codebase-grounded) / MEDIUM (Ollama integration patterns)

---

## Critical Pitfalls

### Pitfall 1: UserDefaults Data Silently Lost on Bundle ID Change

**What goes wrong:**
UserDefaults are stored under the app's bundle ID as the domain key. When the bundle ID changes from `com.example.Tome` to something like `com.example.PSTranscribe`, every user's settings (vault paths, configured locales, session context, UI preferences) silently vanishes on first launch of the rebranded app. The app starts with factory defaults, which means vault paths point nowhere -- subsequent transcript writes silently fail because `SessionStore.swift:13` already suppresses directory-creation errors with `try?`.

**Why it happens:**
Developers focus on the code rename and miss that NSUserDefaults is a persistent store keyed by bundle ID. There is no automatic migration. The error is invisible because the old data is still on disk; it just lives under the old domain name.

**How to avoid:**
At first launch after the rebrand, check if the new domain is empty and the old domain (`group.Tome` or `io.github.gremble.Tome`) still exists. If so, copy all keys over programmatically using `UserDefaults(suiteName:)` before anything reads settings. Delete the old domain after migration. Ship this migration in the first rebrand release -- it cannot be retroactively added.

**Warning signs:**
- Settings screen shows blank vault paths after update
- First transcript write after update silently goes to the wrong location
- Crash logs show "no such file or directory" on vault path operations

**Phase to address:**
Rebrand phase -- must be implemented before any release that changes the bundle ID. A pre-migration test with two UserDefaults domains should be a release gate.

---

### Pitfall 2: Sparkle Appcast Break After Rebrand

**What goes wrong:**
Sparkle compares `sparkle:version` (build number) numerically to determine update direction. If the rebrand ships with a version number that appears "older" than existing installs (e.g., resetting build numbers, or mixing date-based vs. sequential schemes), existing users get offered a "downgrade" instead of an update -- or worse, receive no update prompt at all. The `SUFeedURL` in Info.plist also needs to stay consistent or existing installs stop receiving updates entirely.

**Why it happens:**
Rebrands often reset version numbering to "start fresh." Developers forget that Sparkle's update logic is purely numeric comparison against `sparkle:version`, not against display names or bundle IDs.

**How to avoid:**
- Keep `sparkle:version` (CFBundleVersion) strictly monotonically increasing across the rebrand. Never reset it.
- The `SUFeedURL` must either stay the same or old installs must receive one last update pointing to the new feed URL before the old feed is retired.
- Add a `codesign -v` verification step to CI post-build to catch signature issues before publishing.
- Test Sparkle update flow end-to-end with a staging appcast before cutting a real release.

**Warning signs:**
- Sparkle in sandbox logs shows version comparison going backwards
- GitHub Actions release step succeeds but users report "no updates available"
- DMG signature verification fails after bundle ID change but code-signing certificate is unchanged

**Phase to address:**
Rebrand phase -- the appcast migration strategy must be locked in before the first renamed release ships.

---

### Pitfall 3: Sequential try? Fixes Create New Data Loss Paths

**What goes wrong:**
The codebase has 29 `try?` instances. The instinct is to replace them all with `try` and add a `catch` that logs. But `TranscriptLogger.swift:163-165` has three sequential file ops (write temp, remove original, move temp). If you add a throwing `try` to the remove-then-move sequence without atomic rollback logic, a move failure now throws and unwinds -- but the remove already succeeded. The original file is gone, the temp file is stranded, and the data is lost with an error logged that nobody sees in production.

**Why it happens:**
Error suppression cleanup is treated as a mechanical find-replace. The atomicity contract of the three-op sequence is not obvious from reading any single line.

**How to avoid:**
Fix the file I/O operations in two passes:
1. First pass -- replace `try?` with `try` + logging only where there is no downstream dependency on success (directory creation, cleanup of temp files, audio buffer cleanup).
2. Second pass -- fix the truly dangerous sequences (write/remove/move) with proper rollback: if remove succeeds but move fails, restore from temp. Only after rollback logic is in place, replace `try?` with `try`.

Never do a bulk find-replace of `try?` -> `try` without auditing each call site for downstream dependencies.

**Warning signs:**
- `.tome_tmp` files appearing in vault after sessions
- Transcript files disappearing after a crash mid-save
- Error logs showing "move failed" with no corresponding "original restored"

**Phase to address:**
Security/error-handling hardening phase. Fix cleanup-type `try?` instances first (safe), then tackle the file I/O sequences with rollback logic.

---

### Pitfall 4: Ollama "Not Running" Causes App to Hang or Crash

**What goes wrong:**
Ollama runs as a local process on port 11434. When the user hasn't started Ollama, every API call from the app will fail with a connection refused error. The default HTTP timeout in URLSession is long (60-300 seconds depending on configuration). If LLM analysis is triggered during recording and the connection attempt blocks, the recording session's async task chain stalls. On Swift actors, a stalled task holds the actor -- the transcription pipeline may degrade or stop updating the UI.

**Why it happens:**
Developers test with Ollama already running. The "first launch" or "Ollama not started" path is never exercised during development. URLSession connection timeouts are also much longer than users will tolerate for a "local" service.

**How to avoid:**
- Add a health-check ping to `http://127.0.0.1:11434/` with a 2-second timeout before attempting any generation request. Surface the result as a distinct `OllamaState` enum: `.notInstalled`, `.notRunning`, `.modelNotLoaded`, `.ready`.
- Never initiate a streaming generation request unless health check passes.
- Display a non-blocking banner ("Ollama not running -- LLM analysis unavailable") rather than blocking recording.
- LLM analysis must be fully decoupled from the recording/transcription pipeline -- a failure in Ollama must not affect transcript capture.

**Warning signs:**
- Recording UI freezes for 60+ seconds when Ollama is not running
- Transcript stops updating during Ollama request timeout
- App crash on task cancellation when Ollama connection is mid-flight

**Phase to address:**
Ollama integration phase -- health check and decoupled architecture must be designed before any generation calls are wired up.

---

### Pitfall 5: Ollama Context Window Silently Truncates Live Transcripts

**What goes wrong:**
Ollama defaults to a 2048-4096 token context window regardless of the model's actual capability. A live transcript of a 30-minute meeting easily exceeds 4096 tokens. Ollama silently clips input beyond `num_ctx` -- no error is returned, the model just never sees the truncated tokens. The LLM analysis panel will produce summaries that are subtly wrong (based on the first ~15 minutes only) with no indication to the user. This is particularly bad for "action items" -- the most important ones near the end of the meeting are invisible to the model.

**Why it happens:**
The default context size is not surfaced in API responses. Developers see the summary "working" in testing with short transcripts and never discover the truncation.

**How to avoid:**
- Always explicitly set `num_ctx` in generation requests. For live transcription use cases, a minimum of 16384 tokens is reasonable; check available model context and cap appropriately.
- Track token count of the transcript being sent and display a warning if it approaches the configured limit.
- For very long sessions, use a sliding window strategy -- send the last N tokens plus the initial summary, not the full raw transcript.

**Warning signs:**
- LLM summaries consistently omit content from the second half of long sessions
- Action items list is shorter than expected for a long meeting
- No error in logs despite truncated output

**Phase to address:**
Ollama integration phase -- token management must be part of the initial API wrapper design, not a retrofit.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| `try?` on file cleanup ops | Shorter code, no crash on cleanup failure | Temp files accumulate, disk fills, no signal for debugging | Never for critical data paths; acceptable only for best-effort cleanup if failure is already logged |
| Hardcode `num_ctx` to 4096 | Works for short demos | Silently wrong summaries for real meetings | Never in production |
| Reuse existing `SUFeedURL` without migration plan | Less work upfront | Broken update path for current users | Never when bundle ID changes |
| Reset CFBundleVersion to 1 on rebrand | Clean versioning optics | Sparkle offers downgrade or skips update | Never |
| Skip UserDefaults migration | Faster rebrand ship | All existing users lose their vault configuration | Never |
| Run Ollama calls on same actor as transcription | Simpler plumbing | Audio dropout on Ollama timeout | Never |
| Replace all `try?` with bare `try` + catch-and-log | Looks correct | Data loss when sequential ops have no rollback | Never without auditing each call site |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Ollama streaming API | Using `URLSession.data(for:)` (single response) instead of `URLSession.bytes(for:)` (stream) | Use `AsyncBytes` / server-sent events to consume token stream incrementally as Ollama produces it |
| Ollama health check | Checking `/api/tags` (model list) to detect availability | Hit `GET /` (root); `/api/tags` can succeed while a model is still loading |
| Ollama model loading | Assuming model is loaded immediately after `ollama pull` | First generation request after a pull triggers model loading which can take 5-30 seconds; show a "loading model" state |
| Sparkle + notarization | Signing the DMG but not verifying entitlements after bundle ID change | Run `codesign -dv --entitlements - YourApp.app` post-build; entitlements reference the old bundle ID if not updated |
| FluidAudio + rebrand | Assuming FluidAudio model cache is bundle-ID-agnostic | Verify FluidAudio's cache path (likely in `~/Library/Caches/<bundle-id>/`) -- a bundle ID change may invalidate cached models and force a re-download on first launch |
| CI keychain + rebrand | Using the same KEYCHAIN_FILE path pattern with new bundle ID | The CI keychain is ephemeral; bundle ID change has no keychain impact on CI -- but the predictable path (PID + epoch) must be fixed to `mktemp` regardless |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Full transcript regex rewrite on every diarization update | UI jank after sessions > 30 min; file I/O spike | Stream-based or incremental transcript patching; only rewrite diarized segments | ~50K lines / 30 min+ sessions |
| Unbounded WAV temp file for system audio | `/tmp` fills during long meetings; OS terminates app | Ring buffer or streaming diarization instead of accumulate-then-process | ~1 hour session = 600 MB |
| `speechSamples` array growing to 480K entries | Memory pressure at 8+ hours | Already flushes at 480K -- acceptable for typical use; add `os_log` for memory pressure events | 8+ hour sessions |
| Ollama streaming on main actor | UI freeze during token generation | Explicitly `nonisolated` or `Task.detached` for generation; only `@MainActor` for appending tokens to `@Observable` state | Every Ollama call |
| Session library full-scan on every launch | Slow startup with large vault | Load library lazily; scan on demand or use file metadata cache | >100 sessions in vault |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Keeping `#if DEBUG` as the only guard on `/tmp/tome.log` | Debug builds (including TestFlight-equivalent ad-hoc) expose audio metadata to all local users | Replace with `os_log`; if file logging is ever needed, use the app's sandboxed container with 0600 permissions |
| Setting `FileProtectionType` after file creation instead of at creation | Race window between file creation and protection application | Pass file attributes dict with `.protectionKey: .complete` to `FileManager.createFile(_:contents:attributes:)` at creation time |
| Unvalidated vault path from UserDefaults | Path traversal to write transcripts outside intended vault | `URL(fileURLWithPath: expanded).resolvingSymlinksInPath()` then assert prefix matches validated vault root before any write |
| Predictable CI keychain path | Symlink attack by co-tenant on shared runner | Replace `"/tmp/build-$$-$(date +%s).keychain-db"` with `$(mktemp -u /tmp/keychain-XXXXXX.keychain-db)` |
| Unpinned GitHub Actions (`@v4` tags) | Compromised action injects code into release pipeline | Pin every action to a commit SHA; add a comment with the human-readable tag/version next to the SHA |
| Ollama running over HTTP on localhost | Low risk for a single-user local app, but worth noting: no TLS means any local process can MITM | Acceptable for local-only Ollama at 127.0.0.1; document the assumption; do not allow configuring arbitrary remote Ollama endpoints without TLS |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| LLM panel appears but shows nothing when Ollama not running | User confused whether analysis is broken or just slow | Show explicit `OllamaState` -- "Not running: start Ollama to enable analysis" -- in the panel itself |
| Session library shows old sessions from pre-rebrand vault | Confusion about missing files (vault path changed due to lost UserDefaults) | UserDefaults migration (see Critical Pitfall 1) prevents this; add missing-file detection with clear "file not found" state in grid |
| Rebrand update removes waveform, no explanation | Users think recording is broken (waveform was their confidence indicator) | Three-state button must have unambiguous recording state (color, label, animation) that cannot be confused with idle |
| Crash recovery prompt on launch is too aggressive | Users who intentionally force-quit get spurious recovery offer | Only offer recovery if the incomplete session file has substantive content (> N lines) and is recent (< 24 hours old) |
| Ollama model download progress not surfaced | User thinks app is frozen during first model pull | Show download progress bar with estimated size; allow cancellation; show clear success/failure state |

---

## "Looks Done But Isn't" Checklist

- [ ] **UserDefaults migration:** Verify settings are present after simulating an update from a Tome-bundle-ID build to the PSTranscribe-bundle-ID build on the same machine
- [ ] **Sparkle update path:** Test update flow end-to-end with a staging appcast that has the new bundle ID before cutting a real release
- [ ] **try? replacement:** For every fixed `try?`, verify the enclosing function has a rollback path if a later step in the same sequence fails
- [ ] **Ollama decoupling:** Verify that disabling network (or not running Ollama) does not affect transcript capture -- run a full recording session with Ollama absent
- [ ] **File protection attributes:** Verify new transcript files have `FileProtectionType.complete` set -- use `ls -lO` or `xattr -l` to inspect protection class on a test file
- [ ] **Session finalization atomicity:** Verify that force-quitting mid-session leaves a file that crash recovery can detect and offer to the user (not a zero-byte or malformed file)
- [ ] **Diarization timestamp fix:** Test a session that starts at 23:45 and ends at 00:15 -- verify speaker attribution is correct across the midnight boundary
- [ ] **Temp file cleanup:** After 5 recorded sessions, verify no `.tome_tmp` or `tome_sys_audio_*.wav` files remain in `/tmp`
- [ ] **Bundle ID change in all targets:** Check entitlements files, Info.plist, and any hardcoded strings referencing "Tome" in bundle IDs -- not just the main target's project settings
- [ ] **FluidAudio model cache:** After bundle ID change, verify Parakeet model is not re-downloaded on first launch (or if it is, that this is intentional and surfaced to the user)

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| UserDefaults lost after rebrand ships | HIGH | Ship a follow-up release that reads old domain and re-populates new domain; requires users to manually re-enter vault paths if they already dismissed the defaults |
| Sparkle update broken after rebrand | HIGH | Publish a patch to the old appcast pointing at new feed URL; users on old bundle ID must get this transitional update or they will never auto-update again |
| Sequential try? fix causes data loss | HIGH | Restore from git; no user-facing recovery -- data is gone. Prevention is the only option. |
| Ollama hangs recording session | MEDIUM | Task cancellation on session stop should work if tasks are properly structured; if not, force-quit + crash recovery path handles it |
| Context truncation gives wrong summaries | LOW | Increase `num_ctx`, re-run analysis against saved transcript; summaries are non-destructive |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| UserDefaults lost on bundle ID change | Rebrand phase | Simulate update from old bundle ID build; verify vault path persists |
| Sparkle appcast break | Rebrand phase | End-to-end staging appcast test before release |
| Sequential try? fix causes data loss | Security/error-handling phase | Code review every `try?` replacement; test write-failure scenarios |
| Ollama hangs recording pipeline | Ollama integration phase | Integration test with Ollama absent; verify transcript capture unaffected |
| Ollama context truncation | Ollama integration phase | Send 10K+ token transcript; verify summary covers full content |
| File protection applied after creation | Security phase | Inspect created files' protection class with `ls -lO` in test |
| Predictable CI keychain path | Security phase | Diff the workflow file, confirm `mktemp` usage |
| Diarization timestamp midnight bug | Bug-fix phase | Unit test with timestamps spanning 23:59 -> 00:01 |
| Session finalization not atomic | Session lifecycle phase | Simulate crash at each step of endSession -> finalizeFrontmatter -> rewriteWithDiarization |
| Temp audio files accumulate on crash | Session lifecycle / cleanup phase | Kill app mid-session 5 times; count surviving `/tmp` files |

---

## Sources

- Codebase audit: `/Users/cary/Development/ai-development/Tome/.planning/codebase/CONCERNS.md` (2026-03-30) -- HIGH confidence
- Apple Developer Forums: UserDefaults and bundle ID behavior -- MEDIUM confidence
- Sparkle documentation: https://sparkle-project.org/documentation/publishing/ -- HIGH confidence
- Sparkle version numbering issue: https://github.com/openclaw/openclaw/issues/26965 -- MEDIUM confidence
- Ollama FAQ (context window defaults): https://docs.ollama.com/faq -- HIGH confidence
- Ollama context truncation behavior: https://www.arsturn.com/blog/what-happens-when-you-exceed-the-token-context-limit-in-ollama -- MEDIUM confidence
- Ollama connection timeout issues: https://github.com/ollama/ollama/issues/7070 -- MEDIUM confidence
- SwiftUI main actor / task blocking: https://useyourloaf.com/blog/swiftui-tasks-blocking-the-mainactor/ -- HIGH confidence
- Apple Keychain access groups on bundle ID change: https://developer.apple.com/forums/thread/706128 -- HIGH confidence
- Swift 6 migration guide: https://github.com/swiftlang/swift-migration-guide/blob/main/Guide.docc/CommonProblems.md -- HIGH confidence

---
*Pitfalls research for: macOS transcription app rebrand, Ollama integration, security hardening*
*Researched: 2026-03-31*
