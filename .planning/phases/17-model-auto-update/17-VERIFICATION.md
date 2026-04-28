# Phase 17 Verification Log

## Plan 17-04 Manual Smoke Test — 2026-04-27

**Status:** Partially verified. Full end-to-end verification deferred to post-Plan-17-05 (manifest must be live).

**User response:** `approved` — 404 on manifest fetch acknowledged as expected pre-17-05 state.

---

### Checklist Results

**A. Section ordering (D-06)**
- Deferred to post-17-05 manual run. Requires running the app with the live manifest published so the full "Updates → Speech Model" sequence can be visually confirmed.

**B. Idle / up-to-date state**
- Deferred to post-17-05 manual run. The `installedModelVersion` empty path renders `Speech Model: v—` as expected when no manifest has been fetched. The `v{version} · {readableDate}` path cannot be confirmed until Plan 17-05 publishes the manifest.

**C. Manual "Check for Updates" button**
- Deferred to post-17-05 manual run. Pre-17-05, the manifest URL returns 404. The 404 is the documented expected state and transitions the UI to `.failed` (shows `⚠️ Update failed: <reason>`). This is correct behavior -- no bug.
- 404 acknowledged by user as expected pre-17-05 publish state.

**D. Auto-update toggle**
- Deferred to post-17-05 manual run.

**E. Failed state (404 path)**
- Partially observable pre-17-05: clicking "Check for Updates" with the manifest unpublished should produce `⚠️ Update failed: <reason>` with a "Retry" button. This is correct behavior for the pre-publish state.
- Deferred to post-17-05 for full confirmation of the "Retry" re-fires path.

**F. Auto-check trigger at launch (D-10)**
- Deferred to post-17-05 manual run. Throttle and toggle gate behavior requires a live manifest to distinguish "fetched and up-to-date" from "fetched and 404'd".

**G. AppSettings.modelAutoUpdateEnabled gate (D-13)**
- Deferred to post-17-05 manual run.

**H. SessionCoordinator integration (read-only check)**
- Deferred to post-17-05. Swap-deferral end-to-end cannot be verified without a live manifest delivering an actual downloadable update.
- Covered by Plan 17-03 unit tests (SessionCoordinatorTests + ModelUpdateServiceTests confirm the deferral logic).

**I. No regressions (P0)**
- User has not reported any regressions.
- Existing Settings flows (Audio, Obsidian, Notion, Privacy, Updates) are unmodified by Plans 17-01 through 17-04.
- Full test suite passes: `swift test` exits 0 with all ModelUpdateServiceTests, ModelManifestTests, SessionCoordinatorTests, AppSettingsTests passing.

---

### Notes

- The 404 on manifest fetch is the documented expected state pre-Plan-17-05. It is not a bug.
- Full A-through-G verification is gated on Plan 17-05 publishing the live manifest to the gh-pages URL.
- This verification file will be updated after Plan 17-05 completes and a follow-up smoke test is run.
