---
phase: 20-dark-mode-parity
plan: 03
subsystem: ui
tags: [swiftui, dark-mode, preferredcolorscheme, uat, macos26]

requires:
  - phase: 20-dark-mode-parity
    provides: Adaptive Color(light:dark:) helper + 28 Chronicle/legacy tokens (Wave 1) and 5 audit tokens (Wave 2)
  - phase: 12-chronicle-design-system-port
    provides: Chronicle palette identity (paper / ink / accent / spk / status)
  - phase: 18-hotkey-dictation-plain-folder-output
    provides: DictationHUD vibrancy as out-of-scope token consumer

provides:
  - System-following dark-mode parity (app respects macOS appearance for the first time)
  - .preferredColorScheme(.light) override deleted from ContentView.swift
  - .preferredColorScheme(.dark) override deleted from NotionTagSheet.swift
  - UAT-attested adaptive rendering across all 10 surfaces in Light, Dark, and Auto-transition states
  - DictationHUD partial-text legibility confirmed against .hudWindow vibrancy in both modes

affects: [future-ui-work, design-system-iterations]

tech-stack:
  added: []
  patterns:
    - "System-appearance-following: no .preferredColorScheme overrides on non-Preview views; SwiftUI auto-observes @Environment(\\.colorScheme)"
    - "Source-level byte-equality as visual-stability proof: when light-side hexes equal pre-change literals byte-for-byte, screenshot capture is mathematically redundant for light-mode pixel stability"

key-files:
  created: []
  modified:
    - "PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift (deleted .preferredColorScheme(.light) at line 251)"
    - "PSTranscribe/Sources/PSTranscribe/Views/NotionTagSheet.swift (deleted .preferredColorScheme(.dark) at line 130)"
    - ".planning/phases/20-dark-mode-parity/20-VERIFICATION.md (UAT worksheet — sign-off PASS)"

key-decisions:
  - "User waived screenshot capture for Wave 3: light-side hex byte-equality across Waves 1-2 mathematically guarantees zero light-mode pixel drift; dark-mode visual attestation accepted in lieu of capture"
  - "Auto-transition evidence recorded via Path A (observed during user UAT) — system appearance flip propagated to running app without restart"
  - "Override removal confirmed clean: only remaining preferredColorScheme reference in PSTranscribe/Sources is a comment string in DesignTokens.swift:173 (not a call-site)"

patterns-established:
  - "Wave-3 override-removal pattern: after a token-foundation wave (Wave 1) and a call-site-audit wave (Wave 2) both preserve light-side byte-equality, the final override-removal wave is two grep-targeted line deletions plus UAT — no further code work needed for system-following adaptation"
  - "User-attestation-in-lieu-of-screenshots: when source-level byte-equality is mathematically established, visual sign-off can substitute for PNG capture — reserved for situations where the mathematical proof is airtight"

requirements-completed: [REQ-20.1, REQ-20.4, REQ-20.5, REQ-20.6]

duration: ~5min code + UAT session
completed: 2026-05-01
---

# Phase 20 Plan 03: Override removal + UAT Summary

**Two `.preferredColorScheme` overrides deleted, app now follows system appearance for the first time; UAT confirms all 10 surfaces re-render correctly across Light, Dark, and Auto-transition without app restart; DictationHUD partial-text legibility attested in both modes; user waived screenshot capture in favor of source-level byte-equality proof for light mode and visual attestation for dark mode.**

## Performance

- **Duration:** ~5 min code work (commit `b20d4ba`) + user UAT session on 2026-05-01
- **Completed:** 2026-05-01
- **Tasks:** 2 of 2 executed (Task 1 code change; Task 2 UAT signed off)
- **Files modified:** 2 source files + 1 verification worksheet

## Accomplishments

- **`.preferredColorScheme(.light)` deleted** from `ContentView.swift:251`. The pin that forced the entire app to light mode is gone. ContentView's root view now adapts to `@Environment(\.colorScheme)` automatically.
- **`.preferredColorScheme(.dark)` deleted** from `NotionTagSheet.swift:130`. The pin that forced the Notion tag sheet to dark mode is gone. NotionTagSheet now renders with the system-appropriate Chronicle palette (warm paper in light, warm-dark in dark).
- **Grep gate passes:** `grep -rn "preferredColorScheme" PSTranscribe/Sources` returns only one match — a comment string in `DesignTokens.swift:173`. Zero call-site hits outside `#Preview` blocks.
- **`swift build` clean** post-commit `b20d4ba`. Zero compile errors, zero new warnings.
- **D-10 UAT script executed by user** on 2026-05-01. All 10 surfaces (ContentView, LibrarySidebar, LibraryEntryRow, TranscriptView, DetailsPane, CaptureDock idle + recording, ControlBar, SettingsView, NotionTagSheet, OnboardingView) re-rendered correctly without app restart on Light → Dark → Light flips.
- **Auto-transition observed (Path A)** during the UAT session: system appearance flip propagated to the running app; all 10 surfaces re-rendered without restart. Recorded in `20-VERIFICATION.md` as `Auto-transition observed at 2026-05-01 during user UAT`.
- **DictationHUD partial-text legibility PASS in both modes** (REQ-20.6). `.primary` / `.secondary` SwiftUI semantics auto-adapt against `.hudWindow` vibrancy in both system appearances.
- **Light-mode pixel stability vs Wave-2 baseline PASS** via mathematical equivalence (light-side hex byte-equality across Waves 1-2 + Wave 3 deletes only the `.preferredColorScheme` overrides, which are no-ops in light mode).

## Task Commits

1. **Task 1: Delete the two `.preferredColorScheme` overrides** — `b20d4ba` (refactor)
2. **Task 2: D-10 UAT script + sign-off** — UAT attestation in `20-VERIFICATION.md` (no code commit; UAT-only task)

**Plan metadata:** (this commit) `docs(20-03): complete UAT and close override-removal plan`

## Files Created/Modified

- `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift` — Deleted `.preferredColorScheme(.light)` modifier at line 251. Surrounding modifier chain stayed syntactically valid; build clean.
- `PSTranscribe/Sources/PSTranscribe/Views/NotionTagSheet.swift` — Deleted `.preferredColorScheme(.dark)` modifier at line 130. Surrounding modifier chain stayed syntactically valid; build clean.
- `.planning/phases/20-dark-mode-parity/20-VERIFICATION.md` — UAT worksheet completed; all surfaces marked PASS; sign-off recorded; user-waiver of screenshot capture documented.

## Decisions Made

- **User waived screenshot capture.** Light-side hex byte-equality was established at the source level across Waves 1-2 (every replacement preserved the original literal byte-for-byte). Wave 3 deletes only the two `.preferredColorScheme` overrides, which are no-ops in light mode. Therefore, light-mode pixel drift is mathematically zero — screenshot capture would only confirm the math. For dark mode, the user accepted visual attestation (warm-dark backgrounds in the `#1A1818` family, cream foreground in `#F0EDE8` family, lavender accent `#C4A0FF`) as sufficient evidence in lieu of a PNG reference set.
- **Auto-transition path: Path A (observed).** Path B's scripted-flip incantation was not needed — the user's UAT session captured a real system flip on Auto and confirmed all 10 surfaces re-rendered without restart.

## Acceptance Criteria (from plan `<truths>`)

| Criterion | Result |
|-----------|--------|
| `.preferredColorScheme(.light)` at ContentView.swift:251 deleted | PASS |
| `.preferredColorScheme(.dark)` at NotionTagSheet.swift:130 deleted | PASS |
| `grep -rn preferredColorScheme PSTranscribe/Sources` returns zero hits outside `#Preview` blocks | PASS (only match is a comment in DesignTokens.swift:173) |
| `swift build` clean, zero new warnings | PASS |
| Manual UAT confirms System Settings > Appearance Light→Dark→Light toggle re-renders all 10 surfaces without app restart | PASS |
| Manual UAT confirms Auto / sunset transition propagates appearance correctly; VERIFICATION.md contains the required Auto-transition string | PASS (`Auto-transition observed at 2026-05-01 during user UAT`) |
| DictationHUD partial-text legible against `.hudWindow` vibrancy in both modes | PASS |
| Light-mode pixel-stable vs Wave-2 (= baseline) post-override-removal | PASS (mathematical equivalence; user-waived screenshot capture) |
| Any discovered deviations documented in 20-VERIFICATION.md and resolved | PASS (no deviations found) |

## Deviations from Plan

None — plan executed exactly as written.

The only divergence from the plan's literal output spec is the user's choice to waive PNG screenshot capture in favor of source-level byte-equality proof + visual attestation. The plan permits this trade-off implicitly through its `<truths>` block (light-side byte-equality is itself listed as an acceptance criterion); the user made an explicit informed decision rather than following the screenshot-capture sub-step. This is documented in `20-VERIFICATION.md` and is not a deviation in the auto-fix sense — it is a sign-off-time decision recorded in the UAT log.

**Total deviations:** 0.
**Impact on plan:** None. All 9 acceptance criteria from `<truths>` met. All UAT script steps executed. Phase 20 final gate: PASS.

## Issues Encountered

None.

## Requirements Addressed

- **REQ-20.1** — Override removal: `.preferredColorScheme(.light)` and `.preferredColorScheme(.dark)` both deleted from non-Preview views. Grep gate passes.
- **REQ-20.4** — Call-site adaptation final: with overrides removed, every adaptive token added in Waves 1-2 now drives a real visible adaptation when the system appearance flips. UAT confirmed all 10 surfaces re-render correctly.
- **REQ-20.5** — Light-mode pixel stability: mathematically guaranteed via source-level byte-equality across Waves 1-2-3; user-attested.
- **REQ-20.6** — DictationHUD vibrancy: partial-text foreground legible against `.hudWindow` vibrancy in both light and dark system appearances; UAT confirmed PASS in both modes.

## User Setup Required

None — no external service configuration required. Phase 20 is now closed.

## Self-Check

- [x] `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift` no longer contains `.preferredColorScheme(.light)` outside `#Preview` blocks.
- [x] `PSTranscribe/Sources/PSTranscribe/Views/NotionTagSheet.swift` no longer contains `.preferredColorScheme(.dark)` outside `#Preview` blocks.
- [x] Commit `b20d4ba` exists in `git log` (Task 1 — override removal).
- [x] `20-VERIFICATION.md` contains UAT log with all 10 surfaces marked PASS.
- [x] `20-VERIFICATION.md` contains the required `Auto-transition observed at` string.
- [x] User sign-off recorded in `20-VERIFICATION.md` (Cary Newfeldt, 2026-05-01, PASS).
- [x] `swift build` clean post-commit `b20d4ba` (verified during Wave 3 code task).

## Self-Check: PASSED

## Next Phase Readiness

**Phase 20 is closed.** System-following dark-mode parity achieved. The app respects macOS Appearance for the first time. All token work (Wave 1 foundation + Wave 2 call-site audit) and override-removal (Wave 3) are complete and UAT-attested.

Recommendation: close Phase 20 and proceed to the next phase per the roadmap. No follow-up tickets, no deferred work, no open issues.

---
*Phase: 20-dark-mode-parity*
*Wave: 3 of 3*
*Code commit: `b20d4ba`*
*UAT signed off: 2026-05-01*
*Completed: 2026-05-01*
