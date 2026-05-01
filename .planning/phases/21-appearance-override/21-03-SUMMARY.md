---
phase: 21-appearance-override
plan: 03
subsystem: verification
tags: [verification, uat, manual-testing, sign-off, milestone, dark-mode, appearance, d-01, d-06, d-07]

# Dependency graph
requires:
  - phase: 21-appearance-override
    plan: 01
    provides: AppearancePreference enum + AppSettings.appearancePreference stored property + colorScheme: ColorScheme? bridge
  - phase: 21-appearance-override
    plan: 02
    provides: Three .preferredColorScheme call-sites + DictationWindowController.applyAppearance + Section("Appearance") Picker
provides:
  - "21-VERIFICATION.md fully populated: Automated Audit + Manual UAT (8 scenarios all PASS) + 11-row SPEC.md Acceptance Criteria Status table + Phase 21 Sign-Off + D-01 milestone state update follow-ups"
  - "End-to-end Phase 21 sign-off: ALL PASS, no scenarios failed, no KVO fallback needed"
  - "Inline D-06 deviation documentation so future verifiers reading SPEC.md #4's superseded 'exactly ONE hit' wording are immediately redirected to the relaxed location+source check"
affects: [STATE.md, ROADMAP.md, REQUIREMENTS.md, milestone v1.2]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Verification doc structure: Automated Audit (verbatim grep transcripts) + Manual UAT (per-scenario checklist) + SPEC.md Acceptance Criteria Status table (with Verified-by traceability column) + Sign-Off block + milestone state update follow-ups"
    - "D-06 deviation pattern: when SPEC.md acceptance gate is intentionally relaxed via CONTEXT.md decision, document the deviation INLINE in the verification doc (twice: once in the audit gate's intro paragraph, once in the criteria-table row that maps to the superseded SPEC item) so the relaxation is impossible to miss"

key-files:
  modified:
    - .planning/phases/21-appearance-override/21-VERIFICATION.md -- Manual UAT section (8 scenarios A-H all [x] PASS) appended at line 107; SPEC.md Acceptance Criteria Status table (11 rows) appended at line 119; Phase 21 Sign-Off block at line 133; D-01 milestone state update section at line 141; header status updated from "AUTOMATED AUDIT PASSED" to "ALL PASS"
  created:
    - .planning/phases/21-appearance-override/21-03-SUMMARY.md -- this file

key-decisions:
  - "All eight UAT scenarios PASS without notes — no PASS WITH NOTES, no FAIL, no scenarios required re-running. User response: 'approved'."
  - "KVO fallback for NSPanel `.system` resolution NOT needed (Scenario G step 8) — `panel.appearance = nil` correctly inherits `NSApp.effectiveAppearance` on live macOS Light↔Dark toggle. CONTEXT.md Claude's Discretion item resolved without additional plumbing."
  - "MenuBarExtra status bar icon glyph remaining system-rendered (does not flip per app preference) is the single tolerated gap, documented in CONTEXT.md Claude's Discretion and re-affirmed in 21-VERIFICATION.md Sign-Off. Not a regression; not a Phase 22 candidate."
  - "Phase 21 verification ships with manual UAT only — automated visual-regression / snapshot testing remains deferred (carried forward from Phase 20 CONTEXT.md `<deferred>`)."

requirements-completed: [SPEC.Req-2, SPEC.Req-3, SPEC.Req-4, SPEC.Req-5, SPEC.Req-6, D-01, D-05, D-06, D-07]

# Metrics
duration: ~10min (Task 1 audit + Task 2 manual UAT execution by user + Task 3 results recording)
completed: 2026-05-01
---

# Phase 21 Plan 03: Manual UAT and Phase Verification Summary

Phase 21 (User-Controlled Appearance Preference) verified end-to-end via the relaxed D-06 grep gate audit and an eight-scenario manual UAT covering live-toggle, persistence, fresh-install, default-state visual parity, DictationHUD live re-render, and MenuBarExtra menu content. Outcome: **ALL PASS**.

## What this plan did

1. **Task 1 (commit `f4b2faf`)** — Captured the automated audit transcript in `21-VERIFICATION.md`: nine verbatim grep + build commands proving zero runtime `.preferredColorScheme(` call-sites outside `PSTranscribeApp.swift`, three intentional call-sites at Scene roots (lines 163, 185, 197), HUD `panel.appearance` mapping at lines 114-116 of `DictationWindowController.swift`, `Section("Appearance")` at line 30 strictly above `Section("Audio Input")` at line 39, and `swift build` clean (`Build complete! (0.26s)`, exit 0, zero warnings).

2. **Task 2 (user-driven manual UAT)** — User ran 8 scenarios on build `f4b2faf` and reported "approved" — every scenario PASS:
   - **A**: Live toggle to Light while macOS Dark — main window, Settings, DictationHUD vibrancy, MenuBarExtra menu content all flipped within ~1s
   - **B**: Live toggle to Dark while macOS Light — symmetric pass
   - **C**: Revert to System — immediate revert; macOS toggles propagate live
   - **D**: Persistence across relaunch — preference survives quit/relaunch; Picker reflects stored value
   - **E**: Fresh-install / wiped UserDefaults (`defaults delete com.newfeldt.PSTranscribe appearancePreference`) — System mode + "System" Picker default; no crash (Req 6 invisible migration confirmed)
   - **F**: Default-state pixel parity with post-Phase-20 baseline (`f9f2139`) — visually indistinguishable across light/dark macOS settings
   - **G**: DictationHUD live re-render — `.system` → `.light` → `.dark` → `.system` flips without dismiss/re-show; `.system` correctly inherits `NSApp.effectiveAppearance` on live macOS toggle (D-07 confirmed)
   - **H**: MenuBarExtra menu content flips per preference; status bar icon glyph (system-rendered) acknowledged as tolerated gap

3. **Task 3 (commit `828b4eb`)** — Appended SPEC.md Acceptance Criteria Status table (11 rows, all PASS), Phase 21 Sign-Off block, and D-01 milestone state update follow-ups to `21-VERIFICATION.md`. Row 3 of the table explicitly cites "SUPERSEDED by D-06" so future verifiers reading SPEC #4's "exactly ONE hit" wording are immediately redirected to the relaxed location+source check.

## Final UAT outcome

**ALL PASS.** Eight of eight scenarios pass without notes. The verification document is committed to git and provides traceable evidence for every one of SPEC.md's 11 acceptance criteria.

## Tolerated gaps surfaced during UAT

- **MenuBarExtra status bar icon glyph (`mic.fill` / `book.closed`) does not flip per app preference.** The `NSStatusItem` machinery is system-rendered and inherits `NSApp.effectiveAppearance`. The dropdown menu *content* (Text "PS Transcribe", Divider, Quit button) does flip correctly via the `Group { ... }.preferredColorScheme(...)` wrapper from Plan 21-02. This was an acknowledged gap in CONTEXT.md Claude's Discretion and is not a regression. Not a Phase 22 candidate.

## NSPanel `.system` resolution — KVO fallback NOT needed

CONTEXT.md Claude's Discretion flagged a possible KVO fallback for the DictationHUD's `.system` case if `panel.appearance = nil` failed to inherit live macOS appearance changes without restart. **Scenario G step 8 confirmed the inheritance works correctly** — toggling System Settings → Appearance Light ↔ Dark with the app's preference set to System propagates live to the HUD without app restart and without any explicit observation of `NSApp.effectiveAppearance`. The fallback was not implemented, and the simpler one-line `panel.appearance = nil` path ships unchanged.

## Deferred to backlog (carried forward)

These were already in CONTEXT.md `<deferred>` for Phase 21; they remain deferred:

- **Automated visual-regression / snapshot testing** for the override path. Phase 20 deferred snapshot testing; Phase 21 inherits that deferral. Manual UAT remains the verification mechanism for any future appearance-related work.
- **Designer-tuned dark Chronicle pass.** Phase 20 shipped functional dark-mode parity using algorithmic `Color(light:dark:)` token inversions; a designer pass to hand-tune the dark palette for visual polish remains backlog. Phase 21 reused Phase 20's tokens unchanged.

## Orchestrator follow-ups (D-01 milestone state update)

Per CONTEXT.md **D-01**, with Phase 21 complete the v1.2 milestone state needs to flip back from `in_progress` to `completed`. The orchestrator owns these writes (this plan's metadata commit handles STATE.md and ROADMAP.md per the standard sequential plan completion flow; the v1.2 git tag remains a separate ship gate):

- **STATE.md:** flip `status: completed`, increment plan counters to 33/33 = 100%, update `last_activity` to mark Plan 21-03 complete and Phase 21 closed
- **ROADMAP.md:** tick the Phase 21 plan checkbox for `21-03-PLAN.md`, mark Phase 21 row as `[x] Complete` with completion date `2026-05-01`, update Progress Table row to `3/3 Complete 2026-05-01`
- **`v1.2` git tag:** capture for separate release/ship gate when ready — NOT part of Plan 21-03 metadata commit

## Deviations from Plan

None — plan executed exactly as written. The Task 1 audit transcript surfaced one expected non-runtime hit (a `///` doc comment in `AppSettings.swift:9`) that was documented inline in the verification doc with both forms of the grep gate (with and without `///` exclusion) for transparency. This is an intentional documentation artifact, not a deviation from the relaxed D-06 gate which targets *runtime* call-sites.

## Self-Check: PASSED

- File created: `.planning/phases/21-appearance-override/21-03-SUMMARY.md` ✓
- Verification doc committed at `828b4eb` ✓
- Audit doc committed at `f4b2faf` ✓
- All 5 required sections present in 21-VERIFICATION.md (Automated Audit, Manual UAT, SPEC.md Acceptance Criteria Status, Phase 21 Sign-Off, D-01 milestone state update) ✓
- All 8 UAT scenarios marked `[x]` PASS ✓
- All 11 SPEC criteria rows have non-placeholder status cells ✓
- Row 3 cites "SUPERSEDED by D-06" ✓
