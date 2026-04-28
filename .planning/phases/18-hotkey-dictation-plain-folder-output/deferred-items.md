# Phase 18 Deferred Items

All Phase 18 deferred items resolved. See `18-09-SUMMARY.md` for details.

## Resolved 2026-04-28 (Plan 18-09)

Three flaky tests were resolved by Plan 18-09:

1. `ClipboardRestoreTests.clipboardRestoresAfterDelay` — already migrated to `PasteboardTestLock` actor mutex by Plan 18-06; Plan 18-09 verified the lock is present in all 3 cases.
2. `PlainFolderFallbackTests.plainFolderWriteFailureSilentlyFallsBackToClipboard` — verified to use `PasteboardTestLock` (migrated by Plan 18-06; Plan 18-09 confirmed).
3. `DictationLoggerTests.rapidSessionsNoCollision` — Plan 18-09 added `.serialized` to the `@Suite("DictationLogger")` trait list, eliminating the parallel-clock millisecond-collision flake. Production filename-suffix resolution at `DictationLogger.swift:51` remains millisecond-precision (`yyyy-MM-dd HH-mm-ss-SSS`) — the fix was test-only.

No outstanding deferred items remain for Phase 18.
