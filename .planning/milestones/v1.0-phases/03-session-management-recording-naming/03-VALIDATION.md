---
phase: 3
slug: session-management-recording-naming
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-02
last_audited: 2026-05-05
---

# Phase 3 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing / XCTest (built into Swift 6.2) |
| **Config file** | None -- no test target exists yet (Wave 0 installs) |
| **Quick run command** | `swift test --package-path PSTranscribe` |
| **Full suite command** | `swift test --package-path PSTranscribe` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `swift test --package-path PSTranscribe`
- **After every plan wave:** Run `swift test --package-path PSTranscribe`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status | Notes |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|-------|
| 24-04-01 | 24-04 | 1 | SESS-01 (sidebar grid layout renders) | WITHDRAWN | n/a -- WITHDRAWN | n/a | withdrawn | SwiftUI rendering. Phase 23 snapshot tests cover `LibraryView` Light/Dark/System rendering. Source: 03-VERIFICATION.md SESS-01 row. |
| 24-04-02 | 24-04 | 1 | SESS-02 (clicking entry loads transcript) | unit | `cd PSTranscribe && swift test --filter LibraryEntryTests` | ✅ existing | green | Cross-reference: existing `LibraryEntryTests.swift` covers `displayName` + `metadataLine` data shape. Click→load is a SwiftUI binding (out of unit-test scope; covered by Phase 23 snapshot tests). |
| 24-04-03 | 24-04 | 1 | SESS-03 (parseTranscript) | unit | `cd PSTranscribe && swift test --filter TranscriptParserTests` | ✅ existing | green | Cross-reference: existing `TranscriptParserTests.swift` (7 tests) covers `parseTranscript(at:)` |
| 24-04-04 | 24-04 | 1 | SESS-04 (right-click "Show in Finder") | WITHDRAWN | n/a -- WITHDRAWN | n/a | withdrawn | NSWorkspace + right-click context menu interaction not testable from Swift Testing without UI automation. Source: 03-VERIFICATION.md SESS-04 row + 10-VERIFICATION.md cross-ref. |
| 24-04-05 | 24-04 | 1 | SESS-05 (missing-file detection badge) | WITHDRAWN | n/a -- WITHDRAWN | n/a | withdrawn | `@State` + `.onAppear` SwiftUI lifecycle for `LibraryEntryRow.fileExists`. Pure-function corner is `FileManager.fileExists()` (Foundation); no production code to assert. Phase 23 snapshot tests cover the rendering. Source: 03-VERIFICATION.md SESS-05 row. |
| 24-04-06 | 24-04 | 1 | SESS-06 (Obsidian deep-link) | unit | `cd PSTranscribe && swift test --filter ObsidianURLTests` | ✅ existing | green | Cross-reference: existing `ObsidianURLTests.swift` (8 tests) covers `makeObsidianURL` + `obsidianVaultForPath` (also cited in Plan 24-02 / 10-VALIDATION.md). |
| 24-04-07 | 24-04 | 1 | SESS-07 (transcriptStore.clear on stop) | unit | `cd PSTranscribe && swift test --filter TranscriptStoreClearTests` | ✅ existing (Plan 24-03) | green | Cross-reference: `TranscriptStoreClearTests.swift` added in Plan 24-03; covers the data-layer half of SESS-07. View-branch transition is SwiftUI (WITHDRAWN per D-03; folded into this row). |
| 24-04-08 | 24-04 | 1 | SESS-08 (new session has fresh UUID) | unit | `cd PSTranscribe && swift test --filter TranscriptStoreClearTests` | ✅ existing (Plan 24-03) | green | Cross-reference: same TranscriptStoreClearTests; `clear()` is the precondition for SESS-08's "fresh UUID" -- the LibraryEntry UUID generation itself is covered by `LibraryEntryTests.swift`. |
| 24-04-09 | 24-04 | 1 | SESS-09 (LibraryStore persistence) | unit | `cd PSTranscribe && swift test --filter LibraryStoreTests/entriesPersistToDiskAndReloadOnInit` | ✅ existing | green | Cross-reference: existing `LibraryStoreTests.swift::entriesPersistToDiskAndReloadOnInit` already passing |
| 24-04-10 | 24-04 | 1 | NAME-01 (RecordingNameField text field UI) | WITHDRAWN | n/a -- WITHDRAWN | n/a | withdrawn | SwiftUI text-field interaction, not unit-testable. Pure-function corner is `LibraryEntry.displayName` fallback for unnamed sessions = NAME-04 (covered). Source: 03-VERIFICATION.md NAME-01 row. |
| 24-04-11 | 24-04 | 1 | NAME-02 (setName during session) | unit | `cd PSTranscribe && swift test --filter TranscriptRenameTests/setNameDuringSessionUpdatesOnDiskFilename` | ✅ new | green | Plan 24-04 Task 1 added `TranscriptRenameTests.swift` |
| 24-04-12 | 24-04 | 1 | NAME-03 (renameFinalized after session) | unit | `cd PSTranscribe && swift test --filter TranscriptRenameTests/renameFinalizedAfterSessionMovesFileAndPreservesContent` | ✅ new | green | Plan 24-04 Task 1 |
| 24-04-13 | 24-04 | 1 | NAME-04 (LibraryEntry.displayName fallback for unnamed) | unit | `cd PSTranscribe && swift test --filter LibraryEntryTests` | ✅ existing | green | Cross-reference: `LibraryEntryTests.swift::displayNameCallCaptureFallback` + `displayNameVoiceMemoFallback` |
| 24-04-14 | 24-04 | 1 | NAME-05 (file path renames preserved) | unit | `cd PSTranscribe && swift test --filter TranscriptRenameTests` | ✅ new | green | Same surface as NAME-02 + NAME-03; covered by both `TranscriptRenameTests` methods (file-on-disk before/after assert) |

*Status: pending / green / red / flaky / withdrawn*

---

## Wave 0 Requirements

- [x] `PSTranscribe/Tests/PSTranscribeTests/LibraryStoreTests.swift` -- SESS-09 (already shipped)
- [x] `PSTranscribe/Tests/PSTranscribeTests/LibraryEntryTests.swift` -- SESS-02, NAME-04 (already shipped)
- [x] `PSTranscribe/Tests/PSTranscribeTests/TranscriptParserTests.swift` -- SESS-03 (already shipped)
- [x] `PSTranscribe/Tests/PSTranscribeTests/ObsidianURLTests.swift` -- SESS-06 (already shipped)
- [x] `PSTranscribe/Tests/PSTranscribeTests/TranscriptStoreClearTests.swift` -- SESS-07/08 (added in Plan 24-03)
- [x] `PSTranscribe/Tests/PSTranscribeTests/TranscriptRenameTests.swift` -- NAME-02/03/05 (added in Plan 24-04)

**Wave 0 complete.**

---

## Validation Audit 2026-05-05 (Phase 24 -- NYQUIST-03)

| Metric | Count |
|--------|-------|
| Gaps found | 1 (Phase 3 draft VALIDATION.md had 5 pending unit rows + 6 manual rows; the unit rows pointed at test files that were Wave-0 placeholders at the time the draft was written) |
| Resolved | 9 (4 cross-referenced existing test files: LibraryStoreTests, LibraryEntryTests, TranscriptParserTests, ObsidianURLTests; 2 cross-referenced from Plan 24-03: TranscriptStoreClearTests for SESS-07/08; 2 new tests in TranscriptRenameTests for NAME-02/03; NAME-05 covered by NAME-02/03 as same surface) |
| Withdrawn | 4 (SESS-01 sidebar grid; SESS-04 right-click Show in Finder; SESS-05 missing-file badge SwiftUI lifecycle; NAME-01 text-field UI) |
| Escalated | 0 |
| Document updates | Frontmatter flipped to approved/true/true; `last_audited: 2026-05-05` added; Per-Task Map rewritten with unit + cross-reference + WITHDRAWN rows; Manual-Only Verifications section removed (D-03 lenient policy). |

### Audit Method

- Cross-referenced existing tests for SESS-02 (LibraryEntryTests), SESS-03 (TranscriptParserTests), SESS-06 (ObsidianURLTests), SESS-09 (LibraryStoreTests), NAME-04 (LibraryEntryTests) -- no new tests added; these suites have shipped pre-Phase-24 and are green.
- Cross-referenced Plan 24-03's `TranscriptStoreClearTests.swift` for SESS-07 (data-layer half of stop→clear) and SESS-08 (new-session UUID precondition).
- Created `PSTranscribe/Tests/PSTranscribeTests/TranscriptRenameTests.swift` with 2 `@Test` methods covering NAME-02 (setName during session changes on-disk filename) and NAME-03 (renameFinalized after session moves file + preserves content). NAME-05 (file path renames preserved) shares the same surface -- folded into the NAME-02/03 tests.
- Ran `cd PSTranscribe && swift test --filter TranscriptRenameTests` → 2 passing.
- Ran each cross-referenced suite (`LibraryStoreTests`, `LibraryEntryTests`, `TranscriptParserTests`, `ObsidianURLTests`, `TranscriptStoreClearTests`) → all green.
- Ran full `cd PSTranscribe && swift test` → exits 0.

### Notes

- Phase 3 draft VALIDATION.md was authored before any test target existed. The 5 "pending Wave 0" unit rows have shipped over Phases 16+; the cross-references close those rows now.
- SESS-04 ("right-click Show in Finder") was reframed in v1.0 audit (REQUIREMENTS.md SESS-04 line 48 changed from "click file path opens Finder" to "right-click 'Show in Finder' action"). Either form is NSWorkspace-mediated and out of Swift Testing's reach.
- SESS-05 (missing-file detection badge) is split: the `FileManager.fileExists` call is Foundation (no production code to assert); the badge rendering is SwiftUI (Phase 23 snapshot domain). Both halves are not directly unit-testable here.
- NAME-05 ("file path renames preserved") is the file-on-disk invariant of NAME-02 + NAME-03; same surface, folded into the same two tests.
- `TranscriptRenameTests.swift` is intentionally separate from a hypothetical `TranscriptLoggerSecurityTests.swift` (which Plan 24-05 introduces) per RESEARCH.md Open Question #4 -- separating files avoids cross-plan file-growth coordination.

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-05 (Phase 24 NYQUIST-03)
