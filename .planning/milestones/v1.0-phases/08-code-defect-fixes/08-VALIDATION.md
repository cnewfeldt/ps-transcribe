---
phase: 8
slug: code-defect-fixes
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-06
last_audited: 2026-05-05
---

# Phase 8 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (swift-testing package) |
| **Config file** | Package.swift -- test target defined |
| **Quick run command** | `swift test --filter TranscriptParserTests` |
| **Full suite command** | `swift test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `swift test --filter` on the relevant test file
- **After every plan wave:** Run `swift test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status | Notes |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|-------|
| 24-03-01 | 24-03 | 1 | D-01a (Speaker.named codable round-trip) | — | Speaker.named encodes/decodes via custom CodingKeys | unit | `cd PSTranscribe && swift test --filter SpeakerCodableTests` | ✅ existing | green | Cross-reference: 6 `@Test` methods in `SpeakerCodableTests.swift` cover round-trip + legacy raw-string decode |
| 24-03-02 | 24-03 | 1 | D-01b (TranscriptParser maps "Speaker N" to .named) | — | Parser produces `.named(label)` for diarized utterances | unit | `cd PSTranscribe && swift test --filter TranscriptParserTests` | ✅ existing | green | Cross-reference: `TranscriptParserTests.otherSpeakerMapsToNamed` + `diarizedSpeakerMapsToNamed` cover the `.named` branch |
| 24-03-03 | 24-03 | 1 | STAB-03 (transcriptStore.clear on stop) | — | stopSession clears accumulated transcript state | unit | `cd PSTranscribe && swift test --filter TranscriptStoreClearTests` | ✅ new | green | Plan 24-03 Task 1 added `TranscriptStoreClearTests.swift` |
| 24-03-04 | 24-03 | 1 | REBR-03 (frontmatter source/pstranscribe — phase 8 closure) | — | Finalized transcript frontmatter contains '- source/pstranscribe' and not 'source/tome' | unit | `cd PSTranscribe && swift test --filter FrontmatterSourceTagTests` | ✅ new | green | Plan 24-03 Task 2 added `FrontmatterSourceTagTests.swift`; cross-references the rebrand half asserted in `RebrandInfoPlistTests` (Plan 24-01) |
| 24-03-05 | 24-03 | 1 | LibraryEntryRow file-exists caching | — | n/a | WITHDRAWN | n/a — WITHDRAWN | n/a | withdrawn | `@State private var fileExists` + `.onAppear` is SwiftUI lifecycle, not unit-testable. Behavior verified at code level in `08-VERIFICATION.md` row 5; visual rendering covered by Phase 23 LibraryView snapshot tests. Source: 08-VERIFICATION.md row 5. |
| 24-03-06 | 24-03 | 1 | STAB-01 (crash recovery end-to-end) | — | After force-quit, next launch surfaces incomplete session via checkpoint scan | WITHDRAWN | n/a — WITHDRAWN | n/a | withdrawn | Force-quit / SIGKILL mid-session is out of scope per Phase 24 D-03 (no integration scaffolding). The `SessionStore.scanIncompleteCheckpoints` round-trip portion IS unit-tested by `CheckpointRoundTripTests.swift` (Plan 24-05); the end-to-end crash-recovery UX flow is the WITHDRAWN portion. Source: 08-VERIFICATION.md human-verification item. |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `PSTranscribe/Tests/PSTranscribeTests/SpeakerCodableTests.swift` — 6 `@Test` methods covering Speaker.named codable (already shipped; cross-reference)
- [x] `PSTranscribe/Tests/PSTranscribeTests/TranscriptParserTests.swift` — `.named` parser cases (already shipped; cross-reference)
- [x] `PSTranscribe/Tests/PSTranscribeTests/TranscriptStoreClearTests.swift` — STAB-03 (added in Plan 24-03 Task 1)
- [x] `PSTranscribe/Tests/PSTranscribeTests/FrontmatterSourceTagTests.swift` — REBR-03 phase-8 closure (added in Plan 24-03 Task 2)

**Wave 0 complete.**

---

## Validation Audit 2026-05-05 (Phase 24 — NYQUIST-04)

| Metric | Count |
|--------|-------|
| Gaps found | 1 (Phase 8 draft VALIDATION.md had 1 manual STAB-01 row + 1 missing test target for STAB-03/REBR-03) |
| Resolved | 4 (D-01a/b cross-referenced; STAB-03 unit-tested via TranscriptStoreClearTests; REBR-03 phase-8 closure unit-tested via FrontmatterSourceTagTests) |
| Withdrawn | 2 (LibraryEntryRow caching — SwiftUI lifecycle; STAB-01 e2e — force-quit out of scope per Phase 24 D-03) |
| Escalated | 0 |
| Document updates | Frontmatter flipped to approved/true/true; `last_audited: 2026-05-05` added; Per-Task Map rewritten with unit + WITHDRAWN rows; Manual-Only Verifications section removed (D-03 lenient policy). |

### Audit Method

- Cross-referenced existing `SpeakerCodableTests.swift` (6 `@Test` methods covering Speaker.named codable + legacy raw-string decode) for Phase 8 D-01a — no new test added.
- Cross-referenced existing `TranscriptParserTests.swift` (`.named` speaker mapping cases) for Phase 8 D-01b — no new test added.
- Created `PSTranscribe/Tests/PSTranscribeTests/TranscriptStoreClearTests.swift` (1 `@Test`: `clearEmptiesAccumulatedState`). Plan 24-03 Task 1.
- Created `PSTranscribe/Tests/PSTranscribeTests/FrontmatterSourceTagTests.swift` (1 `@Test`: `finalizedFrontmatterContainsSourcePstranscribe`). End-to-end round-trip via `TranscriptLogger.startSession` + `append` + `endSession` + `finalizeFrontmatter`; reads finalized file; asserts `"- source/pstranscribe"` present, `"source/tome"` absent. Plan 24-03 Task 2.
- Ran `cd PSTranscribe && swift test --filter TranscriptStoreClearTests` → 1 passing.
- Ran `cd PSTranscribe && swift test --filter FrontmatterSourceTagTests` → 1 passing.
- Ran full `cd PSTranscribe && swift test` → exits 0.

### Notes

- LibraryEntryRow `@State private var fileExists` + `.onAppear` is SwiftUI lifecycle, not unit-testable from this target. Phase 23 snapshot tests for LibraryView cover visual rendering of the missing-file badge across Light/Dark/System appearances.
- Speaker colored-badges (Phase 8 internal D-02) is also a Phase 23 visual-regression concern — covered by LibraryView/TranscriptView snapshot baselines.
- STAB-01 end-to-end crash recovery is WITHDRAWN per Phase 24 D-03 lenient policy. The pure round-trip portion (`SessionStore.writeCheckpoint` → fresh instance → `scanIncompleteCheckpoints`) IS unit-tested by `CheckpointRoundTripTests.swift` in Plan 24-05; that test closes the data-layer half of STAB-01. The WITHDRAWN portion is the force-quit + relaunch + UI-surfaces-it user flow.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-05 (Phase 24 NYQUIST-04)
