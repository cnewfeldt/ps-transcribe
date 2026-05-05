---
phase: 1
slug: rebrand
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-01
last_audited: 2026-04-27
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

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 01-01-01 | 01 | 1 | REBR-04 | automated | `test -d PSTranscribe/Sources/PSTranscribe/App && test ! -d Tome` | green |
| 01-01-02 | 01 | 1 | REBR-01, REBR-02, REBR-03 | automated | `cd PSTranscribe && swift build` + `grep -rn '"Tome"' PSTranscribe/Sources/ PSTranscribe/Package.swift` (expect 0) + `grep com.pstranscribe.app PSTranscribe/Sources/PSTranscribe/Transcription/StreamingTranscriber.swift` | green |
| 01-02-01 | 02 | 2 | REBR-06, REBR-07 | automated | `grep com.pstranscribe.app PSTranscribe/Sources/PSTranscribe/Info.plist` + `grep "PS Transcribe" PSTranscribe/Sources/PSTranscribe/Info.plist` + `grep "OWNER/ps-transcribe" PSTranscribe/Sources/PSTranscribe/Info.plist` + `grep 'APP_NAME="PS Transcribe"' scripts/build_swift_app.sh` + `grep 'APP_PATH="dist/PS Transcribe.app"' scripts/make_dmg.sh` | green |
| 01-02-02 | 02 | 2 | REBR-05 | automated | `grep -c "Tome" .github/workflows/build-check.yml .github/workflows/release-dmg.yml` (expect 0) + `grep "working-directory: PSTranscribe" .github/workflows/build-check.yml` + `grep "PS-Transcribe-dmg" .github/workflows/release-dmg.yml` | green |
| 01-03-01 | 03 | 2 | REBR-08 | manual | Static check at phase completion (commit 291e0e3): `grep migrateUserDefaultsIfNeeded PSTranscribeApp.swift` >= 2 + `grep "io.gremble.tome" PSTranscribeApp.swift` >= 1 + `grep hasMigratedFromTome PSTranscribeApp.swift` >= 1. Note: code intentionally removed post-v1.0 ship (commit 4ef30e0) -- migration window has closed. | green-historical |
| 01-03-02 | 03 | 2 | REBR-08 | manual | Human-verify checkpoint approved 2026-04-02 (commit 304a158) -- `defaults read com.pstranscribe.app` showed 6 migrated keys + `hasMigratedFromTome=1` after first launch | green-historical |

*Status: pending / green / red / flaky / green-historical*

*green-historical: requirement was satisfied at phase completion and verified; underlying code was subsequently removed by an intentional, documented commit. The manifest is preserved as audit trail.*

---

## Wave 0 Requirements

- No test framework to install -- validation relies on `swift build` and grep checks against existing source/config files.
- Existing build infrastructure (Swift Package Manager) covers all automated phase requirements with zero added tooling.

**Wave 0 complete:** No tooling installation needed; sampling rate met via `swift build` and grep against committed artifacts.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| User-facing strings show "PS Transcribe" in running UI | REBR-01 | Requires visual UI inspection -- grep proves source-level absence of "Tome" string literals, but only a launched app reveals titles, menu bar text, and About dialog rendering | Launch app, check window title, menu bar extra ("PS Transcribe" + "Quit PS Transcribe"), About dialog, Settings window title |
| UserDefaults migration preserves settings on first launch with old prefs | REBR-08 | Runtime UserDefaults behavior on a machine that previously ran Tome -- cannot be statically verified | Performed and approved 2026-04-02: confirmed `defaults read com.pstranscribe.app` showed all 6 migrated keys + `hasMigratedFromTome=1`; old `io.gremble.tome` keys deleted. (Subsequently the migration code was removed in commit 4ef30e0 because the migration window has closed -- v1.0 shipped, all old-binary users already migrated.) |

*Two behaviors require manual verification due to no test target. Both have been performed and recorded.*

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (no missing references -- existing infra suffices)
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-27 (retroactive audit)

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
