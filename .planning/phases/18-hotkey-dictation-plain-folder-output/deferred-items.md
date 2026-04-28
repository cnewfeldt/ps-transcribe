# Phase 18 Deferred Items

Items discovered during execution that are out of scope for the current task.

## Pre-existing flaky test: `ClipboardRestoreTests.clipboardRestoresAfterDelay`

- **Discovered during:** Plan 18-07 Task 1 verification (full `swift test` run after adding the Settings Dictation section).
- **Symptom:** When the full test suite runs, `clipboardRestoresAfterDelay` intermittently fails with `(pb.string(forType: .string) → "hello") == "OLD"`. The suite passes in isolation (`swift test --filter ClipboardRestoreTests`).
- **Cause:** Cross-suite pasteboard race. The test file's own comment acknowledges it: *".serialized is required because all 3 tests share NSPasteboard.general (system-global state). Without serialization the tests race: one test's `setString("USER_COPY")` lands while another is asleep waiting for its restore, and changeCount/string assertions fail unpredictably."* The `.serialized` trait orders tests **within** a suite, but `ClipboardRestoreTests`, `ClipboardPrivacyMarkersTests`, and `DictationCommitFlowTests` all touch `NSPasteboard.general` and run in parallel across suites.
- **Why deferred:** Pre-existing. Plan 18-06 introduced the `PasteboardTestLock` actor mutex pattern; this suite was not yet migrated to use it. Migration is its own work item, unrelated to Plan 18-07's Settings UI scope.
- **Suggested fix (future plan):** Wrap the three remaining `ClipboardRestoreTests` cases with `await PasteboardTestLock.shared.acquire { ... defer { release } }` per the Plan 18-06 SUMMARY pattern.
