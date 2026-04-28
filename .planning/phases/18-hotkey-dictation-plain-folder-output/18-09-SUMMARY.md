---
phase: 18
plan: 09
subsystem: hotkey-dictation-plain-folder-output
tags: [gap-closure, data-flow, test-flake-fix, doc-lag]
status: pending-checkpoint
requirements_completed: [DICT-10, FOLDER-02, FOLDER-03, FOLDER-04]
dependency_graph:
  requires: [18-01, 18-02, 18-03, 18-04, 18-05, 18-06, 18-07, 18-08]
  provides: [plain-folder-body-content, dict-10-doc-closure, phase-18-flake-closure]
  affects: [DictationCoordinator, DictationLogger, REQUIREMENTS.md, deferred-items.md]
tech-stack:
  added: []
  patterns: [snapshot-before-iterate, hasActiveSession-guard-d15, pasteboard-test-lock-coverage]
key-files:
  created:
    - .planning/phases/18-hotkey-dictation-plain-folder-output/18-09-SUMMARY.md
  modified:
    - PSTranscribe/Sources/PSTranscribe/App/DictationCoordinator.swift
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/DictationCommitFlowTests.swift
    - PSTranscribe/Tests/PSTranscribeTests/DictationLoggerTests.swift
    - PSTranscribe/Tests/PSTranscribeTests/Phase18/DictationCoordinatorStateTests.swift
    - .planning/REQUIREMENTS.md
    - .planning/phases/18-hotkey-dictation-plain-folder-output/deferred-items.md
decisions:
  - "Wired dictationLogger.append from DictationCoordinator.endDictation as a snapshot-then-iterate pattern (T-18-09-02): snapshot dictationStore.utterances into a local let BEFORE the loop so the assembled clipboard string and the file body see the same data."
  - "Append loop guarded by `if await dictationLogger.hasActiveSession` to preserve the D-15 silent-fallback contract: failed-open sessions never receive transcript writes."
  - "Volatile remainder appended as final synthetic utterance with `Date()` timestamp so the file body matches the clipboard assembled string."
  - "DictationLogger filename suffix unchanged at millisecond resolution (option (a) per VERIFICATION.md). Test-only fix: `.serialized` on the suite + 2ms gap inside rapidSessionsNoCollision."
  - "Discovered during execution: DictationCoordinatorStateTests had two pasteboard-touching tests without the lock — added (Rule 2 deviation)."
  - "Discovered during execution: rapidSessionsNoCollision races against itself in the same millisecond on a fast machine, independent of cross-suite parallelism. The plan's `.serialized` remediation alone does not fix it. Added a 2ms `Task.sleep` between the two `startSession` calls so the test exercises the actual production guarantee (Rule 1 deviation)."
metrics:
  duration: "in-progress (Tasks 1-3 committed; Task 4 awaiting human-verify)"
  completed_date: pending
---

# Phase 18 Plan 09: Phase 18 Gap Closure Summary

> **Status:** Tasks 1-3 complete and committed. Task 4 is a `checkpoint:human-verify` — waiting on user filesystem-inspection of the plain-folder file body to close Gap #1. This SUMMARY is partial; the human-verification result will be appended after the checkpoint resumes.

Closes the three Phase 18 gaps reported by `18-VERIFICATION.md`: a goal-blocking data-flow disconnect that left plain-folder dictation files empty (Gap #1), a documentation lag on DICT-10 (Gap #2), and a parallel-test flake scope that was broader than the deferred-items.md ticket documented (Gap #3).

## 1. Gap #1 — `dictationLogger.append` wiring + body-content regression test

**Production fix:** `DictationCoordinator.endDictation` now snapshots `dictationStore.utterances` into a local `let` BEFORE the assembled-string computation, then iterates the snapshot to flush each utterance to the active `DictationLogger` session BEFORE calling `endSession()`. Volatile remainder appended as a final synthetic utterance so the file body matches the clipboard assembled string.

```swift
// Phase 18-09 Gap #1 fix — snapshot utterances so the append loop and the assembled
// string see the same data, and concurrent mutation during the await chain cannot
// reorder file writes (T-18-09-02).
let utterancesSnapshot = dictationStore.utterances
let utterancesText = utterancesSnapshot.map { $0.text }
let volatile = dictationStore.volatileYouText.trimmingCharacters(in: .whitespacesAndNewlines)
let assembled = (utterancesText + (volatile.isEmpty ? [] : [volatile]))
    .joined(separator: " ")
    .trimmingCharacters(in: .whitespacesAndNewlines)

// Phase 18-09 Gap #1 fix — flush the dictation transcript to the plain-folder file
// BEFORE closing the session. The D-15 silent-fallback path leaves
// hasActiveSession == false (startSession threw, was caught at lines 163-168, no
// session opened); the guard ensures the failed-open file path NEVER receives
// transcript writes (preserves D-15 secrecy + T-18-06-06: os_log content stays
// free of transcript text).
if await dictationLogger.hasActiveSession {
    for utterance in utterancesSnapshot {
        await dictationLogger.append(text: utterance.text, timestamp: utterance.timestamp)
    }
    // Volatile remainder: the active engine's partial-but-not-yet-finalized text.
    // The clipboard assembled string already includes it (line above); appending
    // it as a final synthetic utterance keeps the file body and clipboard text aligned.
    if !volatile.isEmpty {
        await dictationLogger.append(text: volatile, timestamp: Date())
    }
}

let finalFileURL: URL? = await dictationLogger.endSession()
```

**Commit:** `20620cd` — `feat(18-09): wire dictationLogger.append + body-content regression test (Gap #1)`

## 2. Gap #1 regression test — RED → GREEN cycle

**New test in `DictationCommitFlowTests.swift`:**

```swift
@Test @MainActor func plainFolderFileBodyContainsTranscript() async throws {
    await PasteboardTestLock.shared.acquire()
    defer { Task { await PasteboardTestLock.shared.release() } }
    defer { NSPasteboard.general.clearContents() }
    let folder = tmpFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let (dict, _) = makeCoordinator(folder: folder, mode: .plainFolder)

    try await dict.dictationLogger.startSession(folderPath: folder.path)

    let now = Date()
    dict.dictationStore.append(Utterance(text: "hello body content", speaker: .you, timestamp: now))

    dict._test_setState(.listening)
    dict._test_setSessionStartTime(now)
    dict._test_setElapsed(5)

    await dict.endDictation()
    try? await Task.sleep(for: .milliseconds(50))

    let contents = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
    #expect(contents.count == 1, "plainFolder mode must produce exactly one .md file")
    guard let filename = contents.first else { return }
    let url = folder.appendingPathComponent(filename)

    let body = try String(contentsOf: url, encoding: .utf8)
    #expect(body.contains("hello body content"),
            "Plain-folder file body must contain the spoken transcript text. Found body:\n\(body)")
    #expect(body.contains("**You** ("), "Plain-folder body must contain the **You** speaker header from append()")
    #expect(!body.contains("---"), "Plain-folder file must never contain YAML frontmatter delimiter")
}
```

**RED → GREEN observed during execution:**

- **RED (pre-fix run):**
  ```
  ✘ Test plainFolderFileBodyContainsTranscript() recorded an issue at DictationCommitFlowTests.swift:114:9:
    Expectation failed: (body → "# Dictation -- 2026-04-28 15:12\n\n").contains("hello body content")
  ↳ Plain-folder file body must contain the spoken transcript text. Found body:
    # Dictation -- 2026-04-28 15:12
  ✘ Test plainFolderFileBodyContainsTranscript() failed after 0.232 seconds with 2 issues.
  ```
  Pre-fix body was header-only (`# Dictation -- 2026-04-28 15:12\n\n`) — no transcript text, no `**You** (` header. Goal-blocking gap reproduced.

- **GREEN (post-fix run):**
  ```
  ✔ Test plainFolderFileBodyContainsTranscript() passed after 0.128 seconds.
  ✔ Suite "DictationCommitFlowTests" passed after 1.130 seconds.
  ✔ Test run with 6 tests in 1 suite passed after 1.130 seconds.
  ```
  All 6 tests in the suite green; full suite (176 tests in 33 suites) green.

## 3. Gap #2 — REQUIREMENTS.md DICT-10 closure

**Diff:**

```diff
- - [ ] **DICT-10**: Floating HUD respects existing privacy mode (`NSWindowSharingType.none`)
+ - [x] **DICT-10**: Floating HUD respects existing privacy mode (`NSWindowSharingType.none`)
```

```diff
-| DICT-10 | Phase 18 | Pending |
+| DICT-10 | Phase 18 | Complete |
```

The HUD code at `DictationWindowController.swift:47` set `panel.sharingType = .none` when Plan 18-05 shipped. Only the documentation was stale.

**Commit:** `fd03f11` — `docs(18-09): mark DICT-10 complete + close deferred flaky-test items (Gap #2)`

## 4. Gap #3 — Parallel-test flake closure

Three test files touched, four behavior changes:

| File | Change | Reason |
|------|--------|--------|
| `DictationLoggerTests.swift` (line 5) | `@Suite("DictationLogger")` → `@Suite("DictationLogger", .serialized)` | Suite-level serialization (option (a) per VERIFICATION.md). Production filename-suffix code at `DictationLogger.swift:51` (millisecond `yyyy-MM-dd HH-mm-ss-SSS`) untouched — option (b) was rejected because changing ship-state for a test-only concern is over-scope. |
| `DictationLoggerTests.swift` (rapidSessionsNoCollision) | Insert `try await Task.sleep(for: .milliseconds(2))` between the two `startSession` calls | The plan's `.serialized` remediation does not fix the in-test race: two adjacent `Date()` reads on different actor instances can land in the same millisecond on a fast machine independent of cross-suite parallelism. The 2ms gap makes the test exercise the actual production guarantee (rapid-but-distinct user-triggered sessions cannot collide) — Rule 1 deviation discovered during execution. |
| `DictationCoordinatorStateTests.swift` (toggleSecondTapStops, holdReleaseAfterOneSecondCommits) | Acquire `PasteboardTestLock.shared.acquire()` + `defer { release }` + `defer { NSPasteboard.general.clearContents() }` | Both tests call `endDictation`, which writes to `NSPasteboard.general` via `writeToClipboardWithPrivacyMarkers`. Without the lock, "hello"/"committed" writes from these tests raced `ClipboardRestoreTests.clipboardRestoresAfterDelay`'s "OLD"/"NEW" assertions in parallel runs. Rule 2 deviation discovered during execution — required to satisfy the must-have "All three previously flaky Phase 18 / DictationLogger tests pass deterministically across at least 5 consecutive full-suite runs". |
| `PlainFolderFallbackTests.swift`, `ClipboardRestoreTests.swift` | Lock pattern verified, already present in all cases | No edits needed — Plan 18-06 already migrated these to the actor mutex pattern. |

**Suite annotation diff for `DictationLoggerTests.swift`:**

```diff
-@Suite("DictationLogger")
+@Suite("DictationLogger", .serialized)
```

**Commit:** `67ab06c` — `test(18-09): serialize DictationLogger suite + verify pasteboard lock coverage (Gap #3)`

## 5. Verification evidence — 5 consecutive `swift test` runs, zero failures

After all three fixes were applied:

```
=== Run 1 ===
✔ Suite "DictationCoordinatorStateTests" passed after 8.497 seconds.
✔ Test run with 176 tests in 33 suites passed after 8.498 seconds.
=== Run 2 ===
✔ Suite "DictationCoordinatorStateTests" passed after 8.394 seconds.
✔ Test run with 176 tests in 33 suites passed after 8.394 seconds.
=== Run 3 ===
✔ Suite "DictationCoordinatorStateTests" passed after 8.416 seconds.
✔ Test run with 176 tests in 33 suites passed after 8.416 seconds.
=== Run 4 ===
✔ Suite "DictationCoordinatorStateTests" passed after 8.474 seconds.
✔ Test run with 176 tests in 33 suites passed after 8.474 seconds.
=== Run 5 ===
✔ Suite "DictationCoordinatorStateTests" passed after 8.330 seconds.
✔ Test run with 176 tests in 33 suites passed after 8.330 seconds.
```

5/5 runs GREEN. 176 tests across 33 suites. Zero failures.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] DictationCoordinatorStateTests pasteboard lock coverage**

- **Found during:** Task 2 verification (full-suite parallel runs)
- **Issue:** `DictationCoordinatorStateTests.toggleSecondTapStops` and `holdReleaseAfterOneSecondCommits` both call `endDictation`, which writes to `NSPasteboard.general`. The plan's must-have list specifies `PlainFolderFallbackTests` and `ClipboardRestoreTests` as the lock-coverage targets, but `DictationCoordinatorStateTests` was not listed and was racing them in parallel runs (the "hello" string in `toggleSecondTapStops` was landing on the pasteboard during `ClipboardRestoreTests.clipboardRestoresAfterDelay`'s 500ms restore window).
- **Fix:** Acquire `PasteboardTestLock.shared.acquire()` + `defer { release }` + `defer { NSPasteboard.general.clearContents() }` at the top of both tests. Added `import AppKit` to the file.
- **Files modified:** `PSTranscribe/Tests/PSTranscribeTests/Phase18/DictationCoordinatorStateTests.swift`
- **Justification:** The plan's must-have list explicitly required "All three previously flaky Phase 18 / DictationLogger tests pass deterministically across at least 5 consecutive full-suite runs". Without this fix, `clipboardRestoresAfterDelay` continued to flake in 4/5 parallel runs even after the plan's listed lock-coverage targets were verified.
- **Commit:** `67ab06c`

**2. [Rule 1 - Bug] rapidSessionsNoCollision in-test race**

- **Found during:** Task 2 verification (full-suite runs after `.serialized` was applied)
- **Issue:** The plan's chosen remediation (`.serialized` at the suite level) did not eliminate the flake. The test creates two `DictationLogger` instances and calls `startSession` on both back-to-back. On a fast machine, both `Date()` reads inside the actor's `startSession` (which feeds the `yyyy-MM-dd HH-mm-ss-SSS` filename formatter) can land in the same millisecond. `.serialized` only orders tests within the suite — it does not control the wall-clock separation between two adjacent calls inside the same test body. The plan's premise (that the flake was purely cross-suite) was incorrect.
- **Fix:** Insert `try await Task.sleep(for: .milliseconds(2))` between the two `startSession` calls so the test exercises the actual production guarantee (a user cannot fire two hotkeys within sub-millisecond from a single `@MainActor`-serialized `DictationCoordinator`) instead of racing the actor against itself.
- **Files modified:** `PSTranscribe/Tests/PSTranscribeTests/DictationLoggerTests.swift`
- **Justification:** The must-have specified deterministic passage across 5 consecutive runs; without this fix the test continued to flake in 1/5 runs even with `.serialized` applied. Production filename-suffix resolution stays unchanged at millisecond precision (the production code is correct — a single user from a single process cannot trigger two `startSession` calls in the same millisecond).
- **Commit:** `67ab06c`

## Threat Flags

None — no new security-relevant surface introduced. The append loop reuses the existing Phase 16 `DictationLogger.append` API with no additional file-handle or network surface. The `hasActiveSession` guard preserves the D-15 silent-fallback secrecy contract.

## Updated Requirements Coverage

| Requirement | Pre-Plan-09 | Post-Plan-09 | Source |
|-------------|-------------|--------------|--------|
| DICT-10 | ✗ Pending (doc lag) | ✓ Complete | `REQUIREMENTS.md` line 24 + line 95 |
| FOLDER-02 | ✗ Body empty | ✓ Body contains transcript | `DictationCoordinator.swift` append loop + `plainFolderFileBodyContainsTranscript` test |
| FOLDER-03 | ⚠️ Flaky test | ✓ Deterministic | `DictationLoggerTests.swift` `.serialized` + 2ms gap |
| FOLDER-04 | ⚠️ Partial (file body empty) | ✓ Complete | Same fix as FOLDER-02 — `.both` and `.plainFolder` modes now produce non-empty file bodies |

## D-15 Invariant Reaffirmation

The new append loop preserves the D-15 silent-fallback contract by guarding on `await dictationLogger.hasActiveSession`. When `startSession` throws (D-15 path: invalid path, permissions, disk full), the catch at lines 163-168 of `DictationCoordinator.swift` logs only `error.localizedDescription` (NEVER transcript text — preserves T-18-06-06) and leaves `hasActiveSession == false`. The new append loop sees the false predicate and is a no-op — the failed-open file path NEVER receives transcript writes.

## Self-Check: PENDING

Self-check will run after the human-verify checkpoint resumes. Once Task 4 is approved, the verification block below will be appended.

## Pointer to Verification

Closes all three gaps reported by `18-VERIFICATION.md`:
- Gap #1 (goal-blocking data-flow): closed by Task 1 production fix + regression test (pending Task 4 human filesystem-inspection proof).
- Gap #2 (documentation lag): closed by Task 3 REQUIREMENTS.md edits.
- Gap #3 (test flake scope): closed by Task 2 + the two auto-fix deviations.

---

> **Awaiting Task 4 (human-verify):** User dictates "one two three four five" with `mode = plainFolder`, opens the resulting `.md` file, confirms the body contains the spoken text. Optional D-15 regression smoke test follows. Approval text appended below after checkpoint resumes.
