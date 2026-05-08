---
phase: 21
slug: appearance-override
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-07
last_audited: 2026-05-07
---

# Phase 21 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

Backfilled by Phase 25 (NYQUIST-07) on 2026-05-07. Phase 21 shipped 2026-05-01 without Nyquist coverage; this validation contract certifies the structural half of every REQ-21.x with Swift Testing assertions and cites `21-VERIFICATION.md` for the visual halves per Phase 25 D-01 (cite-only snapshot posture) and D-02 (PARTIAL `a`/`b` split for compound contracts).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`import Testing`) -- `PSTranscribeTests` target in `PSTranscribe/Package.swift` |
| **Config file** | `PSTranscribe/Package.swift` -- `.testTarget(name: "PSTranscribeTests", ...)` |
| **Quick run command** | `cd PSTranscribe && swift test --filter <suite>` |
| **Full suite command** | `cd PSTranscribe && swift test` |
| **Estimated runtime** | ~15-90 seconds (full suite, macos-26) |

---

## Sampling Rate

- **After every task commit:** Run focused `swift test --filter <suite>`
- **After every plan wave:** Run full `swift test` locally
- **Before merge:** `build-check.yml` CI green on PR (macos-26, Xcode 26)
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

Compound REQs are split into TESTABLE structural halves (`Xa`) and WITHDRAWN visual halves (`Xb`) per Phase 25 D-02. Visual halves cite `21-VERIFICATION.md` and `21-HUMAN-UAT.md` per Phase 25 D-01 cite-only posture (Phase 23's snapshot infrastructure is not extended here -- see Audit Notes).

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status | Notes |
|---------|------|------|-------------|-----------|-------------------|--------|-------|
| 25-01-01 | 25-01 | 1 | REQ-21.1 | unit | `cd PSTranscribe && swift test --filter AppSettingsTests/roundTrip_appearancePreferenceLight` | green | AppearancePreference enum + UD round-trip; companion tests cover `.dark` and `.system` default |
| 25-01-02 | 25-01 | 1 | REQ-21.2a | unit | `cd PSTranscribe && swift test --filter PreferredColorSchemeGrepGateTests/preferredColorSchemeOnlyAtAppRootReadingFromSettings` | green | Structural half (D-02 split): app-root call-sites read from `settings.appearancePreference.colorScheme` (relaxed grep per Phase 21 D-06 -- location + source contract, not exact count) |
| 25-01-03 | 25-01 | 1 | REQ-21.2b | WITHDRAWN | n/a -- WITHDRAWN | withdrawn | Visual half (D-02 split): runtime override re-renders all 10 surfaces without app restart. Manual UAT covers; no CI-runnable harness for runtime preference-toggle re-renders (Phase 25 D-01 cite-only). Source: 21-VERIFICATION.md Manual UAT Scenarios A-H + 21-HUMAN-UAT.md. |
| 25-01-04 | 25-01 | 1 | REQ-21.3a | unit | `cd PSTranscribe && swift test --filter PreferredColorSchemeGrepGateTests/settingsViewContainsAppearancePicker` | green | Structural half (D-02 split): SettingsView Picker existence + binding source (`Section("Appearance")` + `Picker` + `selection: $settings.appearancePreference`) |
| 25-01-05 | 25-01 | 1 | REQ-21.3b | WITHDRAWN | n/a -- WITHDRAWN | withdrawn | Visual half (D-02 split): user changes selection in Settings, every visible window re-renders immediately. Manual UAT covers. Source: 21-VERIFICATION.md Manual UAT Scenarios A-H. |
| 25-01-06 | 25-01 | 1 | REQ-21.4 | unit | `cd PSTranscribe && swift test --filter PreferredColorSchemeGrepGateTests/preferredColorSchemeOnlyAtAppRootReadingFromSettings` | green | Same `@Test` as REQ-21.2a -- one assertion satisfies both reqs (location AND source contract per Phase 21 D-06 relaxed grep). Companion `noPreferredColorSchemeOutsideAppRoot` test covers the forbidden-elsewhere refactor tripwire. |
| 25-01-07 | 25-01 | 1 | REQ-21.5 | WITHDRAWN | n/a -- WITHDRAWN | withdrawn | Default-state pixel stability with preference = `.system`. Pure visual UAT against post-Phase-20 baseline; no CI-runnable visual diff in scope (Phase 25 D-01). Source: 21-VERIFICATION.md + 21-HUMAN-UAT.md. |
| 25-01-08 | 25-01 | 1 | REQ-21.6 | unit | `cd PSTranscribe && swift test --filter AppSettingsTests/appearancePreferenceMissingKeyFallsBackToSystem` | green | Migration: missing UserDefaults key falls back to `.system` (invisible upgrade for post-Phase-20 installs) |

*Status: pending / green / red / flaky / withdrawn*

*withdrawn: requirement is satisfied at the product level (per `21-VERIFICATION.md`) but the specific contract is not automatable within Phase 25's cite-only scope (D-01). Source pointer in Notes column points at where the human-attested evidence lives.*

---

## Out of scope: Post-fix titlebar bridge (CR-01)

The `applyChronicleTitlebar(_:)` and `observeChronicleTitlebar(controller:settings:)` helpers in `PSTranscribeApp.swift` (introduced in commits `197043b..ce79965` after `21-SPEC.md` was locked) are scope extensions outside the original Phase 21 SPEC. The bridge is verified at the code level by `21-VERIFICATION.md`'s post-fix re-verification block (NSColor.labelColor dynamic, `window.appearance` set, `bestMatch(from:)` gate). Visual UAT for the titlebar Light / Dark / System / unfocused-window scenarios lives in **Phase 26's `26-UAT.md` (QA-06, QA-07, QA-08, QA-09)** -- produced when Phase 26 ships.

Phase 25 deliberately does not encode the bridge audit as `@Test` methods (per Phase 25 D-03): the bridge code is tightly tied to AppKit invariants that don't regress silently, and the re-verification grep audit in `21-VERIFICATION.md` already certifies the code-level invariants. Encoding it as CI tests would duplicate work without buying coverage; deferring entirely would leave a hole in this VALIDATION.md's narrative -- the cross-ref split is the cleanest fit.

---

## Wave 0 Requirements

- Existing Swift Testing test target (`PSTranscribe/Tests/PSTranscribeTests/`) already meets infra requirements -- no new dependencies, no `Package.swift` edits.
- `build-check.yml` CI runs `swift test` on macos-26 (inherited from Phase 23 D-06).

**Wave 0 complete:** No tooling installation needed; sampling rate met via existing Swift Testing target + CI.

---

## Validation Sign-Off

- [x] All tasks have automated verify or are explicitly WITHDRAWN per Phase 25 D-01/D-02
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (8 rows; 5 UNIT + 3 WITHDRAWN; pattern: U-U-W-U-W-U-W-U)
- [x] Wave 0 covers all MISSING references (no missing references -- existing test target suffices)
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-07 (Phase 25 NYQUIST-07 -- Swift Testing-backed; new VALIDATION.md, no prior audit)

---

## Validation Audit 2026-05-07 (Phase 25 -- NYQUIST-07)

| Metric | Count |
|--------|-------|
| Gaps found | 0 (no MISSING test coverage; Phase 21 shipped with manual UAT only -- Phase 25 backfills automated coverage for the structural half of every REQ) |
| Resolved | 5 (REQ-21.1 UD round-trip + missing-key fallback; REQ-21.2a Scene-root grep + source contract; REQ-21.3a SettingsView Picker grep; REQ-21.4 -- same `@Test` as REQ-21.2a per D-06; REQ-21.6 missing-key fallback) |
| Withdrawn | 3 (REQ-21.2b visual half + REQ-21.3b visual half + REQ-21.5 default-state pixel stability per D-01 cite-only + D-02 PARTIAL split) |
| Escalated | 0 |
| Document updates | New 21-VALIDATION.md created at `status: approved` / `nyquist_compliant: true`; created 2026-05-07. Out-of-scope section added per D-03 cross-referencing Phase 26's 26-UAT.md (QA-06..09). |

### Audit Method

- Extended `PSTranscribe/Tests/PSTranscribeTests/AppSettingsTests.swift`:
    - Added `"appearancePreference"` to `v12Keys` array (cleanup coverage)
    - 4 new `@Test` methods: `appearancePreferenceDefaultsToSystem`, `roundTrip_appearancePreferenceLight`, `roundTrip_appearancePreferenceDark`, `appearancePreferenceMissingKeyFallsBackToSystem`
- Created `PSTranscribe/Tests/PSTranscribeTests/PreferredColorSchemeGrepGateTests.swift`:
    - 3 new `@Test` methods: `preferredColorSchemeOnlyAtAppRootReadingFromSettings`, `noPreferredColorSchemeOutsideAppRoot`, `settingsViewContainsAppearancePicker`
    - Pattern: cwd-relative file IO via `URL(fileURLWithPath: "Sources/PSTranscribe/...")` + `String(contentsOf:)` (mirrors `WorkflowSecretsTests.swift` Phase 24 precedent)
    - Phase-25-introduced `stripPreviewBlocks(_:)` helper (linear scan + brace counting) so dev-tool `#Preview` blocks don't pollute production-code grep gates
- Ran `cd PSTranscribe && swift test --filter AppSettingsTests` -- exits 0
- Ran `cd PSTranscribe && swift test --filter PreferredColorSchemeGrepGateTests` -- exits 0
- Ran full `cd PSTranscribe && swift test` -- exits 0 (no regressions)

### Notes

- **D-01 cite-only posture:** Phase 23's 15 snapshot baselines (`PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/`) prove static palette correctness across light/dark/system but are NOT extended in Phase 25. WITHDRAWN rows for REQ-21.2b/21.3b/21.5 cite `21-VERIFICATION.md` (and `21-HUMAN-UAT.md` for REQ-21.5).
- **D-02 PARTIAL `a`/`b` split:** Phase-25-introduced convention. REQ-21.2 cleaved into `21.2a` (testable structural: app-root grep + source contract) and `21.2b` (WITHDRAWN visual: runtime override re-renders surfaces). REQ-21.3 cleaved into `21.3a` (testable structural: SettingsView Picker existence) and `21.3b` (WITHDRAWN visual: live re-render on selection change). Both halves keep the original SPEC ID prefix in adjacent rows so SPEC traceability is preserved.
- **D-03 cross-ref to Phase 26:** Out-of-scope section above names QA-06/07/08/09 explicitly and links to `26-UAT.md` (file does not yet exist; Phase 26 produces it). The cross-ref is forward -- readers landing on `21-VALIDATION.md` before Phase 26 ships see "produced when Phase 26 ships" disambiguator.
- **REQ-21.4 single-`@Test` policy:** Same `@Test` (`preferredColorSchemeOnlyAtAppRootReadingFromSettings`) satisfies both REQ-21.2a (location) and REQ-21.4 (source contract reads from AppSettings) per Phase 21 D-06 relaxed grep gate. The companion `noPreferredColorSchemeOutsideAppRoot` test enforces the forbidden-elsewhere half -- refactor tripwire.
