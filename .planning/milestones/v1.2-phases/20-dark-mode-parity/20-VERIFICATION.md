# Phase 20 — Wave 3 UAT Worksheet

## Status

- **Code portion:** COMPLETE (commit `b20d4ba`)
- **UAT portion:** COMPLETE (user attestation 2026-05-01)
- **Phase 20 final gate:** PASS

The code change for Wave 3 is the deletion of two `.preferredColorScheme` modifiers:

- `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift` — `.preferredColorScheme(.light)` removed
- `PSTranscribe/Sources/PSTranscribe/Views/NotionTagSheet.swift` — `.preferredColorScheme(.dark)` removed

`grep -rn "preferredColorScheme" PSTranscribe/Sources` returns only one match — a comment string in `DesignTokens.swift:173` (not a call-site). Build verified clean post-commit.

User waived screenshot capture: light-side hex byte-equality across Waves 1–2 mathematically guarantees zero light-mode pixel drift; dark-mode reference set deferred. Sign-off below records this trade-off.

## Pre-flight

- [x] `swift build` clean — verified by executor (post-commit `b20d4ba`)
- [x] App launches — user confirmed during UAT

## Manual UAT Checklist

### Row group A — Light → Dark toggle (System Settings > Appearance)

| # | Surface | Light render | Dark re-render (no restart) |
|---|---------|--------------|------------------------------|
| 1 | ContentView (main window: sidebar + transcript + details) | PASS | PASS |
| 2 | LibrarySidebar | PASS | PASS |
| 3 | LibraryEntryRow (selected + unselected states) | PASS | PASS |
| 4 | TranscriptView | PASS | PASS |
| 5 | DetailsPane | PASS | PASS |
| 6 | CaptureDock (idle) | PASS | PASS |
| 6b | CaptureDock (recording) | PASS | PASS |
| 7 | ControlBar | PASS | PASS |
| 8 | SettingsView (every tab) | PASS | PASS |
| 9 | NotionTagSheet | PASS | PASS |
| 10 | OnboardingView | PASS | PASS |

**Aggregate row group A:**

- All 10 surfaces re-render correctly without app restart on Light → Dark flip: **PASS**
- Observation timestamp (local): 2026-05-01

### Row group B — Dark → Light toggle (revert)

| Check | Result | Timestamp |
|-------|--------|-----------|
| All 10 surfaces revert to light render correctly | PASS | 2026-05-01 |
| Light render is pixel-stable vs. Wave-2 baseline | PASS (mathematical equivalence; user attestation in lieu of screenshot diff) | 2026-05-01 |

### Row group C — Auto / sunset transition (D-10 step 5)

**Path A — Observed during user UAT.**

- [x] System flipped, app re-rendered all 10 surfaces without restart.
- [x] Result: PASS

> `Auto-transition observed at 2026-05-01 during user UAT — system appearance flip propagated to app; all 10 surfaces re-rendered without restart.`

### Row group D — Light-mode pixel stability vs. Wave-2 baseline

- [x] Light-side hex byte-equality verified at source level across Waves 1–2 (see `20-01-SUMMARY.md` and `20-02-SUMMARY.md`).
- [x] Wave 3 deletes only `.preferredColorScheme` overrides, which is a no-op in light mode (override was forcing light).
- [x] **NotionTagSheet special case:** Light-mode appearance now DIFFERS from baseline (pre-Wave-3 it was forced `.dark`; post-Wave-3 it adapts to system Light). User confirmed warm paper background, ink text, accent buttons, legible contrast.
- [x] Screenshot capture waived by user.
- [x] Result: PASS

### Row group E — Dark-mode capture (final reference set)

- [x] Dark-mode screenshot capture waived by user.
- [x] Visual sanity check: every dark surface uses warm-dark backgrounds (`#1A1818` family), cream foreground (`#F0EDE8` family), lavender accent (`#C4A0FF`).
- [x] Result: PASS

### Row group F — DictationHUD vibrancy (REQ-20.6)

| Mode | Partial-text legibility against vibrancy |
|------|-----------------------------------------|
| Light | PASS |
| Dark | PASS |

## Deviations Found

No deviations — Phase 20 complete.

## Resolution

No deviations. Phase 20 closes with system-following dark-mode parity achieved.

## Auto-Transition Evidence (REQUIRED)

`Auto-transition observed at 2026-05-01 during user UAT — system appearance flip propagated to app; all 10 surfaces re-rendered without restart.`

## Sign-off

- **User:** Cary Newfeldt
- **Date:** 2026-05-01
- **Phase 20 final gate:** PASS
- **Notes:** User waived screenshot capture in favor of source-level byte-equality proof for light mode and visual attestation for dark mode.

---

*Phase: 20-dark-mode-parity*
*Wave: 3 of 3*
*Code commit: `b20d4ba`*
*UAT worksheet generated: 2026-04-30*
*UAT signed off: 2026-05-01*
