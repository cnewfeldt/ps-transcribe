---
phase: 1
slug: rebrand
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-01
last_audited: 2026-05-05
---

# Phase 1 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None -- no project-level XCTest target exists in Package.swift |
| **Config file** | None |
| **Quick run command** | `cd PSTranscribe && swift build` |
| **Full suite command** | `cd PSTranscribe && swift build` + grep audit |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd PSTranscribe && swift build`
- **After every plan wave:** Run `swift build` + grep audit for residual "Tome" strings
- **Before `/gsd:verify-work`:** Full build green + manual launch verification
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status | Notes |
|---------|------|------|-------------|-----------|-------------------|--------|-------|
| 24-01-01 | 24-01 | 1 | REBR-01 | unit | `cd PSTranscribe && swift test --filter RebrandInfoPlistTests/bundleNameIsPSTranscribe` | green | Re-audit 2026-05-05 (D-01) |
| 24-01-02 | 24-01 | 1 | REBR-02 | unit | `cd PSTranscribe && swift test --filter RebrandInfoPlistTests/bundleIdentifierIsPSTranscribe` | green | Re-audit 2026-05-05 (D-01) |
| 24-01-03 | 24-01 | 1 | REBR-03 | unit | `cd PSTranscribe && swift test` (compile-time proof; `@testable import PSTranscribe` resolves) | green | Re-audit 2026-05-05 (D-01); frontmatter `source/pstranscribe` covered separately by Plan 24-03 |
| 24-01-04 | 24-01 | 1 | REBR-04 | unit | `cd PSTranscribe && swift test --filter RebrandInfoPlistTests/executableNameIsPSTranscribe` | green | Re-audit 2026-05-05 (D-01) |
| 24-05-XX | 24-05 | 1 | REBR-05 | unit | `cd PSTranscribe && swift test --filter WorkflowSecretsTests` | pending | Workflow secrets test created in Plan 24-05; cross-reference here |
| 24-01-05 | 24-01 | 1 | REBR-06 | unit | `cd PSTranscribe && swift test --filter RebrandInfoPlistTests/sparkleFeedURLPointsAtPSTranscribe` | green | Re-audit 2026-05-05 (D-01) |
| 24-01-06 | 24-01 | 1 | REBR-07 | unit | `cd PSTranscribe && swift test --filter RebrandInfoPlistTests/displayNameAndMicUsageMentionPSTranscribe` | green | Re-audit 2026-05-05 (D-01) |
| 24-01-07 | 24-01 | 1 | REBR-08 | WITHDRAWN | n/a -- WITHDRAWN | withdrawn | Code deleted post-v1.0 in commit `4ef30e0` (`migrateUserDefaultsIfNeeded()` and `hasMigratedFromTome` sentinel removed; upgrade window closed). v1.0 milestone audit verified live migration on 2026-04-14. Source: 01-VERIFICATION.md REBR-08 row. |

*Status: pending / green / red / flaky / green-historical*

*green-historical: requirement was satisfied at phase completion and verified; underlying code was subsequently removed by an intentional, documented commit. The manifest is preserved as audit trail.*

---

## Wave 0 Requirements

- No test framework to install -- validation relies on `swift build` and grep checks against existing source/config files.
- Existing build infrastructure (Swift Package Manager) covers all automated phase requirements with zero added tooling.

**Wave 0 complete:** No tooling installation needed; sampling rate met via `swift build` and grep against committed artifacts.

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (no missing references -- existing infra suffices)
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** re-approved 2026-05-05 (Phase 24 NYQUIST-01 -- Swift Testing-backed; supersedes 2026-04-27 build+grep audit per D-01)

---

## Validation Audit 2026-04-27

| Metric | Count |
|--------|-------|
| Gaps found | 0 (no MISSING test coverage) |
| Resolved | 0 |
| Escalated | 0 |
| Document updates | 6 stale "pending" statuses set to green; task IDs corrected to match actual plan/wave assignments (Plan 02 covers REBR-05/06/07, Plan 03 covers REBR-08); REBR-08 manual-only entry annotated with post-v1.0 removal context |

### Audit Method

Re-ran every automated command in the per-task map against current HEAD:

- `cd PSTranscribe && swift build` -- Build complete! (1.02s)
- `grep -c "Tome" PSTranscribe/Sources/PSTranscribe/Info.plist` -- 0
- `grep -c "Tome" .github/workflows/build-check.yml .github/workflows/release-dmg.yml` -- 0, 0
- `grep -c "Tome" scripts/make_dmg.sh` -- 0
- `grep -c "Tome" scripts/build_swift_app.sh` -- 1 (LICENSE attribution comment, intentional)
- `grep com.pstranscribe.app PSTranscribe/Sources/PSTranscribe/Info.plist` -- match
- `grep com.pstranscribe.app PSTranscribe/Sources/PSTranscribe/Transcription/StreamingTranscriber.swift` -- match (line 15)
- `grep 'name: "PSTranscribe"' PSTranscribe/Package.swift` -- match
- `test ! -d Tome` -- pass

### Notes

- The original VALIDATION.md (created 2026-04-01) misassigned all 8 task entries to Plan 01 Wave 1. Actual plan structure is Plan 01 (REBR-01 to 04, Wave 1) + Plan 02 (REBR-05 to 07, Wave 2) + Plan 03 (REBR-08, Wave 2). Map corrected to reflect 6 actual task slots across 3 plans.
- REBR-08 migration code (commits 291e0e3 and 304a158 approval) was deliberately removed post-v1.0 ship in commit 4ef30e0. This is not a regression -- the requirement was satisfied during the relevant migration window and the human-verify checkpoint was passed before removal.
- The lone "Tome" residue in `scripts/build_swift_app.sh:71` is a LICENSE comment ("covers PS Transcribe, Tome, OpenGranola per MIT") preserving copyright attribution; intentional and correct.

---

## Validation Audit 2026-05-05 (Phase 24 -- NYQUIST-01)

| Metric | Count |
|--------|-------|
| Gaps found | 1 (Phase 1 originally approved on `swift build` + grep alone -- D-01 brings Phase 1 into Phase 24's uniform test-target sweep) |
| Resolved | 1 (RebrandInfoPlistTests.swift adds 5 `@Test` methods backing REBR-01/02/04/06/07) |
| Withdrawn | 1 (REBR-08; code deleted post-v1.0 in `4ef30e0`) |
| Escalated | 0 |
| Document updates | Frontmatter `last_audited` bumped to 2026-05-05; Per-Task Map rewritten with unit rows and one WITHDRAWN row per D-03; Manual-Only Verifications section removed (D-03 lenient policy supersedes prior 2026-04-27 manual rows). |

### Audit Method

- Created `PSTranscribe/Tests/PSTranscribeTests/RebrandInfoPlistTests.swift` (5 `@Test` methods: `bundleNameIsPSTranscribe`, `bundleIdentifierIsPSTranscribe`, `executableNameIsPSTranscribe`, `sparkleFeedURLPointsAtPSTranscribe`, `displayNameAndMicUsageMentionPSTranscribe`).
- Pattern: direct file IO `URL(fileURLWithPath: "Sources/PSTranscribe/Info.plist")` + `PropertyListSerialization` (NOT `Bundle.main` -- test bundle is the runner, not the app; per Phase 24 RESEARCH.md Risk #2).
- Ran `cd PSTranscribe && swift test --filter RebrandInfoPlistTests` -- exits 0, 5 passing tests.
- Ran full `cd PSTranscribe && swift test` -- exits 0.

### Notes

- REBR-03 (Package.swift `name: "PSTranscribe"`) is verified at compile-time by `@testable import PSTranscribe` resolving in every test file in the target. The frontmatter `source/pstranscribe` half of REBR-03 (TranscriptLogger.swift:151) is asserted separately by Plan 24-03 (Phase 8 audit) in `FrontmatterSourceTagTests.swift` -- see 08-VALIDATION.md.
- REBR-05 (workflow file rebrand) is asserted by `WorkflowSecretsTests.swift` created in Plan 24-05 (Phase 02 audit) -- cross-referenced here so Plan 24-01's audit closes atomically without waiting on 24-05's wave. The cross-reference row's status reads `pending` until 24-05 ships and is flipped at that time by the Plan 24-05 close step.
- The 2026-04-27 audit block is preserved above for audit-trail continuity. This 2026-05-05 block supersedes the manual-only entries (REBR-01 visual UI, REBR-08 runtime migration) under D-03.
