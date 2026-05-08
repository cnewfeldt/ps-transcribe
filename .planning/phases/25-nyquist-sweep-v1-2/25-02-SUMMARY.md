---
phase: 25-nyquist-sweep-v1-2
plan: 02
subsystem: testing
tags: [swift-testing, nyquist, dark-mode, design-tokens, source-grep, nscolor-bridging, phase-20, v1.2]

requires:
  - phase: 20-dark-mode-parity
    provides: 17 Chronicle Color(light:dark:) tokens + 11 promoted legacy tokens + extension-Color removed from TranscriptView + zero hex-literal Color(red:) in views
  - plan: 25-01
    provides: PreferredColorSchemeGrepGateTests.swift (shared file with readSource / swiftFilesUnder / stripPreviewBlocks helpers + 3 REQ-21 @Test methods)

provides:
  - 4 new @Test methods appended to PreferredColorSchemeGrepGateTests.swift covering REQ-20.1 forced-literal grep, REQ-20.3 deletion-half tripwire, REQ-20.3 promotion-half (11 legacy tokens) structural check, and REQ-20.4a per-view hex-literal grep
  - 1 new test file DesignTokensAdaptivePaletteTests.swift with @Suite(.serialized) and 1 @Test iterating 17 Chronicle tokens under .aqua / .darkAqua via NSColor bridging through performAsCurrentDrawingAppearance, asserting distinct light/dark RGB triples (REQ-20.2)
  - 20-VALIDATION.md created from scratch with 8 verification rows (5 UNIT + 3 WITHDRAWN), D-02 PARTIAL splits for REQ-20.3 and REQ-20.4, dual-source citation for REQ-20.5

affects: [requirements-nyquist-06, milestone-v1.3-polish-validation]

tech-stack:
  added: []
  patterns:
    - "NSColor bridging via NSAppearance(named:)?.performAsCurrentDrawingAppearance { NSColor(swiftUIColor).usingColorSpace(.sRGB) } for runtime palette resolution under explicit appearance (Phase-25-introduced; mirrors DesignTokens.swift:11-21 closure-based dynamic resolution)"
    - "@Suite(.serialized) annotation mandatory when mutating NSAppearance.current (process-global) -- parallel tests would race"
    - "Token roster in test file matches DesignTokens.swift directly-defined entries; token-of-token aliases (youBg/youFg) excluded from variance test since they derive adaptiveness from underlying tokens"

key-files:
  created:
    - PSTranscribe/Tests/PSTranscribeTests/DesignTokensAdaptivePaletteTests.swift
    - .planning/milestones/v1.2-phases/20-dark-mode-parity/20-VALIDATION.md
  modified:
    - PSTranscribe/Tests/PSTranscribeTests/PreferredColorSchemeGrepGateTests.swift

key-decisions:
  - "PreferredColorSchemeGrepGateTests.swift extended in-place (not split) per D-04 -- shared file with Plan 25-01; total now 7 @Test methods (3 REQ-21 + 4 REQ-20)"
  - "REQ-20.3 split into deletion (extension-Color removed from TranscriptView) + promotion (11 legacy tokens defined via Color(light:dark:)) halves per W-02 -- both halves needed structural coverage to fully back the Phase 20 deletion+promotion contract"
  - "DesignTokensAdaptivePaletteTests asserts only `light != dark` per token (variance contract); byte-equality of light variants is independently certified by 20-01-SUMMARY.md / 20-02-SUMMARY.md hex transcripts which the REQ-20.5 WITHDRAWN row cites -- no duplication"
  - "youBg / youFg tokens excluded from REQ-20.2 test roster -- they are token-of-token aliases (Color.ink / Color.paper); their adaptiveness derives from the underlying tokens which ARE tested"
  - "D-01 cite-only posture: no new snapshot tests; WITHDRAWN rows cite 20-VERIFICATION.md, with REQ-20.5 also citing 20-01-SUMMARY.md + 20-02-SUMMARY.md byte-equality proof"
  - "D-02 PARTIAL split applied to REQ-20.4 (4a UNIT + 4b WITHDRAWN) and REQ-20.3 (deletion + promotion adjacent rows preserve SPEC traceability)"

requirements-completed: [NYQUIST-06]

duration: 20min
completed: 2026-05-07
---

# Phase 25 Plan 02: Nyquist Backfill for Phase 20 Dark Mode Parity Summary

**Swift Testing coverage for the 17 Chronicle adaptive palette tokens (1 NSColor-bridged @Test) + 4 source-grep @Test methods covering REQ-20.1/20.3/20.4a + 20-VALIDATION.md with 8 verification rows, closing NYQUIST-06**

## Performance

- **Duration:** ~20 min (executed inline in orchestrator after subagent Bash permission was repeatedly denied)
- **Started:** 2026-05-07T23:30:00Z
- **Completed:** 2026-05-07T23:50:00Z
- **Tasks:** 3
- **Files modified:** 3 (2 created, 1 extended)

## Accomplishments

- Extended `PreferredColorSchemeGrepGateTests.swift` (Plan 25-01's shared file) with 4 new `@Test` methods: `noForcedPreferredColorSchemeAnywhere` (REQ-20.1), `transcriptViewDoesNotDefineExtensionColor` (REQ-20.3 deletion), `legacyPromotedTokensAreDefinedAsColorLightDarkInDesignTokens` (REQ-20.3 promotion -- W-02 fix), `viewSourcesContainNoHexColorLiterals` (REQ-20.4a). Updated header doc-comment to enumerate all four new invariants. File total: 7 @Test methods.
- Created `DesignTokensAdaptivePaletteTests.swift` with `@Suite("DesignTokensAdaptivePaletteTests", .serialized)` and 1 @Test (`allChronicleTokensHaveDistinctLightAndDarkVariants`) that iterates over 17 Chronicle tokens, resolves each under `.aqua` and `.darkAqua` via `NSAppearance.performAsCurrentDrawingAppearance`, bridges SwiftUI Color -> NSColor -> sRGB, and asserts at-least-one-component differs between light and dark.
- Created `20-VALIDATION.md` at `status: approved` / `nyquist_compliant: true` with 8 verification rows (5 UNIT + 3 WITHDRAWN), D-02 PARTIAL splits for REQ-20.3 (deletion + promotion) and REQ-20.4 (4a + 4b), and dual-source citation for REQ-20.5 (cites both 20-VERIFICATION.md AND 20-01-SUMMARY.md / 20-02-SUMMARY.md byte-equality transcripts).
- Full swift test suite green: 274 tests in 53 suites (grew by 5 tests + 1 suite from Wave 1 baseline of 269/52; Phase-25 cumulative: +12 tests +2 suites from pre-Phase-25 baseline of 262/51).

## Task Commits

1. **Task 1: Extend PreferredColorSchemeGrepGateTests with REQ-20.1/20.3/20.4a (4 tests)** -- `8474c7d` (feat)
2. **Task 2: Create DesignTokensAdaptivePaletteTests covering REQ-20.2** -- `ddf24b8` (feat)
3. **Task 3: Create 20-VALIDATION.md with 8 verification rows** -- `a40bde5` (feat)

## Files Created/Modified

- `PSTranscribe/Tests/PSTranscribeTests/PreferredColorSchemeGrepGateTests.swift` -- Extended: header doc-comment updated for both NYQUIST IDs; 4 @Test methods appended in `// MARK: - Phase 20 NYQUIST-06 (Plan 25-02)` section
- `PSTranscribe/Tests/PSTranscribeTests/DesignTokensAdaptivePaletteTests.swift` -- Created: NSColor-bridging adaptive palette runtime resolution test with .serialized suite annotation
- `.planning/milestones/v1.2-phases/20-dark-mode-parity/20-VALIDATION.md` -- Created: 8 verification rows (REQ-20.1 / REQ-20.2 / REQ-20.3a / REQ-20.3b / REQ-20.4a / REQ-20.4b WITHDRAWN / REQ-20.5 WITHDRAWN / REQ-20.6 WITHDRAWN)

## Decisions Made

- The acceptance criterion in 25-02-PLAN.md text says "7 verification map rows" in some places and "8 rows" in others (verification block line 646 says 8). The 20-VALIDATION.md as written has 8 rows (REQ-20.3 split into deletion + promotion as adjacent rows). This matches the deeper W-02 contract that requires both halves to be testable, and matches the verification block's authoritative count.
- REQ-20.5 WITHDRAWN row uses `n/a -- WITHDRAWN` as the Automated Command (matching the Plan 25-01 21-VALIDATION.md sibling shape) but the Notes field carries the full dual-source citation (20-01-SUMMARY.md + 20-02-SUMMARY.md + 20-VERIFICATION.md).
- All 4 new tests reuse the `readSource(_:)`, `stripPreviewBlocks(_:)`, and `swiftFilesUnder(_:)` helpers from Plan 25-01. No new helpers introduced.

## Deviations from Plan

- **Execution mode:** This plan was originally spawned as a parallel worktree subagent (gsd-executor). Two consecutive subagent spawns failed because the runtime denied Bash permission to the subagent before it could run `git merge-base` for the worktree-base verification step. After cleaning up both dangling worktrees, the orchestrator executed all 3 tasks inline using its own Bash + Edit + Write tools (effectively `--interactive` mode without the wave-level subagent indirection). All commits were made directly on `main` (not on a worktree branch); no `--no-verify` flag was needed since the orchestrator runs hooks normally.
- **Pre-commit hooks status:** Wave 2 commits used standard `git commit` (not `--no-verify`), so any pre-commit hooks ran. No hook failures occurred.

## Issues Encountered

- **Subagent Bash permission denial (×2):** The first wave-2 spawn returned with a permission-grant request after attempting only `git merge-base`; the second retry hit the identical denial despite an explicit retry context block telling the agent permission had been granted. Wave 1's executor (same agent type, same isolation mode, same prompt structure) ran without issue earlier in the same session, so the cause is unclear -- possibly a session-level permission scope change, or a difference in how the runtime tokenizes wave-2 spawns. Workaround: orchestrator inline execution. No code-level impact -- Plan 25-02 is shipped identically to what the subagent would have produced.

## User Setup Required

None -- no external service configuration required.

## Next Phase Readiness

- NYQUIST-06 closed: `20-VALIDATION.md` approved with full 8-row verification map covering all of REQ-20.1..20.6 (5 UNIT + 3 WITHDRAWN per D-01 + D-02 PARTIAL split).
- Phase 25 cumulative coverage: NYQUIST-06 + NYQUIST-07 both closed; both phases of v1.2 (Phase 20 dark-mode-parity + Phase 21 appearance-override) now have approved VALIDATION.md files with `nyquist_compliant: true`.
- Full test suite green at 274/53 -- no regressions introduced; ready for orchestrator post-merge gate + verifier.
- The shared `PreferredColorSchemeGrepGateTests.swift` (now 7 @Test methods) is the durable artifact protecting the v1.2 dark-mode + appearance-override contracts against regression in any future PR.

---
*Phase: 25-nyquist-sweep-v1-2*
*Completed: 2026-05-07*
