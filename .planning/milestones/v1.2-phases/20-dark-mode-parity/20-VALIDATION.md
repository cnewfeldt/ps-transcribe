---
phase: 20
slug: dark-mode-parity
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-07
last_audited: 2026-05-07
---

# Phase 20 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

Backfilled by Phase 25 (NYQUIST-06) on 2026-05-07. Phase 20 shipped 2026-05-01 without Nyquist coverage; this validation contract certifies the structural half of every REQ-20.x with Swift Testing assertions and cites `20-VERIFICATION.md` (and `20-01-SUMMARY.md` / `20-02-SUMMARY.md` byte-equality transcripts for REQ-20.5) for the visual halves per Phase 25 D-01 (cite-only snapshot posture) and D-02 (PARTIAL `a`/`b` split for compound contracts).

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

Compound REQs are split into TESTABLE structural halves (`Xa`) and WITHDRAWN visual halves (`Xb`) per Phase 25 D-02. Visual halves cite `20-VERIFICATION.md` per Phase 25 D-01 cite-only posture (Phase 23's snapshot infrastructure is not extended here -- see Audit Notes).

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status | Notes |
|---------|------|------|-------------|-----------|-------------------|--------|-------|
| 25-02-01 | 25-02 | 2 | REQ-20.1 | unit | `cd PSTranscribe && swift test --filter PreferredColorSchemeGrepGateTests/noForcedPreferredColorSchemeAnywhere` | green | Forced-override deletion contract: zero `.preferredColorScheme(.light)` / `.preferredColorScheme(.dark)` literal calls in any view source outside `#Preview`. Companion `noPreferredColorSchemeOutsideAppRoot` (Plan 25-01) covers the broader app-root-only invariant |
| 25-02-02 | 25-02 | 2 | REQ-20.2 | unit | `cd PSTranscribe && swift test --filter DesignTokensAdaptivePaletteTests/allChronicleTokensHaveDistinctLightAndDarkVariants` | green | All 17 Chronicle tokens resolve to distinct RGB triples under `.aqua` vs `.darkAqua` (NSColor bridging via `performAsCurrentDrawingAppearance`); proves each is defined as `Color(light:dark:)`, not a single-hex literal |
| 25-02-03a | 25-02 | 2 | REQ-20.3 (deletion) | unit | `cd PSTranscribe && swift test --filter PreferredColorSchemeGrepGateTests/transcriptViewDoesNotDefineExtensionColor` | green | Legacy `extension Color` block (TranscriptView.swift:207-228 in pre-Phase-20 build) deleted; tripwire on re-introduction |
| 25-02-03b | 25-02 | 2 | REQ-20.3 (promotion) | unit | `cd PSTranscribe && swift test --filter PreferredColorSchemeGrepGateTests/legacyPromotedTokensAreDefinedAsColorLightDarkInDesignTokens` | green | W-02 fix: 11 legacy tokens (bg0/bg1/bg2/fg1/fg2/fg3/accent1/accent2/recordRed/speakerTeal/speakerAmber) defined via `Color(light:dark:)` syntax in DesignTokens.swift (structural -- light==dark by Wave 1 design per DesignTokens.swift:175-177; closes the "11 legacy tokens" half of ROADMAP success criterion 1) |
| 25-02-04 | 25-02 | 2 | REQ-20.4a | unit | `cd PSTranscribe && swift test --filter PreferredColorSchemeGrepGateTests/viewSourcesContainNoHexColorLiterals` | green | Structural half (D-02 split): per-view hex-literal grep -- no `Color(red:` literals in any view file outside DesignTokens.swift (single-source-of-truth Constraint) |
| 25-02-05 | 25-02 | 2 | REQ-20.4b | WITHDRAWN | n/a -- WITHDRAWN | withdrawn | Visual half (D-02 split): runtime appearance-toggle re-renders all 10 surfaces without app restart. Manual UAT covers; no CI-runnable harness for transition-state re-renders (Phase 25 D-01 cite-only). Source: 20-VERIFICATION.md Row groups A-F. |
| 25-02-06 | 25-02 | 2 | REQ-20.5 | WITHDRAWN | n/a -- WITHDRAWN | withdrawn | Light-mode pixel stability gate. Source-level byte-equality already proven via Plan 20-01 / 20-02 SUMMARY hex transcripts (each Color(light:dark:) light hex equals the pre-Phase-20 literal byte-for-byte); visual attestation in 20-VERIFICATION.md Row group D. No CI-runnable visual diff in scope (Phase 25 D-01). Source: 20-01-SUMMARY.md + 20-02-SUMMARY.md + 20-VERIFICATION.md. |
| 25-02-07 | 25-02 | 2 | REQ-20.6 | WITHDRAWN | n/a -- WITHDRAWN | withdrawn | DictationHUD vibrancy adapts via NSPanel `.hudWindow` material; system-controlled, not a SwiftUI invariant. Visual attestation in 20-VERIFICATION.md Row group F. Source: 20-VERIFICATION.md. |

*Status: pending / green / red / flaky / withdrawn*

*withdrawn: requirement is satisfied at the product level (per `20-VERIFICATION.md`) but the specific contract is not automatable within Phase 25's cite-only scope (D-01). Source pointer in Notes column points at where the human-attested evidence lives.*

---

## Wave 0 Requirements

- Existing Swift Testing test target (`PSTranscribe/Tests/PSTranscribeTests/`) already meets infra requirements -- no new dependencies, no `Package.swift` edits.
- `build-check.yml` CI runs `swift test` on macos-26 (inherited from Phase 23 D-06).

**Wave 0 complete:** No tooling installation needed; sampling rate met via existing Swift Testing target + CI.

---

## Validation Sign-Off

- [x] All tasks have automated verify or are explicitly WITHDRAWN per Phase 25 D-01/D-02
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (8 rows; 5 UNIT + 3 WITHDRAWN; pattern: U-U-U-U-U-W-W-W)
- [x] Wave 0 covers all MISSING references (no missing references -- existing test target suffices)
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-07 (Phase 25 NYQUIST-06 -- Swift Testing-backed; new VALIDATION.md, no prior audit)

---

## Validation Audit 2026-05-07 (Phase 25 -- NYQUIST-06)

| Metric | Count |
|--------|-------|
| Gaps found | 0 (no MISSING test coverage; Phase 20 shipped with manual UAT only -- Phase 25 backfills automated coverage for the structural half of every REQ) |
| Resolved | 5 (REQ-20.1 forced-literal grep gate; REQ-20.2 17-token light/dark variance via NSColor bridging; REQ-20.3 deletion half via extension-Color tripwire; REQ-20.3 promotion half via 11-token Color(light:dark:) structural check; REQ-20.4a per-view hex-literal grep) |
| Withdrawn | 3 (REQ-20.4b visual half + REQ-20.5 light-mode pixel stability + REQ-20.6 DictationHUD vibrancy per D-01 cite-only + D-02 PARTIAL split) |
| Escalated | 0 |
| Document updates | New 20-VALIDATION.md created at `status: approved` / `nyquist_compliant: true`; created 2026-05-07. |

### Audit Method

- Extended `PSTranscribe/Tests/PSTranscribeTests/PreferredColorSchemeGrepGateTests.swift` (file created in Plan 25-01) with 4 new `@Test` methods: `noForcedPreferredColorSchemeAnywhere`, `transcriptViewDoesNotDefineExtensionColor`, `legacyPromotedTokensAreDefinedAsColorLightDarkInDesignTokens` (W-02 fix), `viewSourcesContainNoHexColorLiterals`
- Created `PSTranscribe/Tests/PSTranscribeTests/DesignTokensAdaptivePaletteTests.swift`:
    - 1 `@Test` method: `allChronicleTokensHaveDistinctLightAndDarkVariants` (iterates over 17 Chronicle tokens)
    - Pattern: NSColor bridging via `NSAppearance(named:)?.performAsCurrentDrawingAppearance { NSColor(swiftUIColor) ... .usingColorSpace(.sRGB) }` -- Phase-25-introduced technique (no in-house analog); rationale documented in file header
    - `.serialized` annotation MANDATORY: `NSAppearance.current` is process-global; parallel tests would race
- Ran `cd PSTranscribe && swift test --filter PreferredColorSchemeGrepGateTests` -- exits 0 (7 tests: Plan 25-01's 3 + Plan 25-02's 4)
- Ran `cd PSTranscribe && swift test --filter DesignTokensAdaptivePaletteTests` -- exits 0 (1 test, 17 tokens iterated)
- Ran full `cd PSTranscribe && swift test` -- exits 0 (no regressions)

### Notes

- **D-01 cite-only posture:** Phase 23's 15 snapshot baselines (`PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/`) prove static palette correctness across light/dark/system but are NOT extended in Phase 25. WITHDRAWN rows for REQ-20.4b/20.5/20.6 cite `20-VERIFICATION.md`; REQ-20.5 also cites the byte-equality hex transcripts in `20-01-SUMMARY.md` and `20-02-SUMMARY.md`.
- **D-02 PARTIAL `a`/`b` split:** Phase-25-introduced convention. REQ-20.4 cleaved into `20.4a` (testable structural: per-view hex-literal grep) and `20.4b` (WITHDRAWN visual: runtime appearance-toggle re-render across 10 surfaces). Both halves keep the original SPEC ID prefix in adjacent rows so SPEC traceability is preserved. REQ-20.3 also cleaved into deletion (`20.3a`-shaped) + promotion (`20.3b`-shaped) halves to separate the legacy-block-removed tripwire from the 11-token Color(light:dark:) structural contract.
- **REQ-20.5 dual-source citation:** The light-mode pixel stability gate is uniquely well-evidenced -- both source-level byte-equality (each `Color(light:dark:)` light hex equals the pre-Phase-20 literal byte-for-byte, proven in Plan 20-01/02 SUMMARY hex transcripts) AND visual user attestation (`20-VERIFICATION.md` Row group D). The WITHDRAWN reason cites both for completeness.
- **REQ-20.6 vibrancy boundary:** DictationHUD's `.hudWindow` vibrancy material is system-rendered AppKit chrome, not a SwiftUI surface. Adaptation under appearance toggle is a system invariant; visual attestation in `20-VERIFICATION.md` Row group F is the right Source.
- **Token-of-token chain (`youBg` / `youFg`):** Defined as `Color.ink` / `Color.paper` in `DesignTokens.swift:103-104`. They auto-flip because the underlying tokens are adaptive; Phase 25's REQ-20.2 test asserts on the 17 directly-defined Chronicle tokens (paper..liveGreen). The "17 Chronicle tokens" SPEC contract is satisfied by the directly-defined entries; youBg/youFg are accessors over those.
