# Phase 20 — Wave 3 UAT Worksheet

## Status

- **Code portion:** COMPLETE (commit `b20d4ba`)
- **UAT portion:** PENDING USER

The code change for Wave 3 is the deletion of two `.preferredColorScheme` modifiers:

- `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift` — `.preferredColorScheme(.light)` removed
- `PSTranscribe/Sources/PSTranscribe/Views/NotionTagSheet.swift` — `.preferredColorScheme(.dark)` removed

`grep -rn "preferredColorScheme" PSTranscribe/Sources` now returns only one match — a comment string in `DesignTokens.swift:173` (not a call-site). Build verified clean post-commit.

This document is the manual UAT worksheet. Fill in PASS/FAIL + timestamp + screenshot path for each row, then re-spawn an executor to write `20-03-SUMMARY.md` from a complete worksheet.

## Pre-flight

- [x] `swift build` clean — verified by executor (post-commit `b20d4ba`)
- [ ] App launches — user confirms (`cd PSTranscribe && swift run` or via Xcode)

## Manual UAT Checklist

For each row: fill in **Result** (PASS/FAIL), **Timestamp** (local time of observation), and **Screenshot path** (relative to `.planning/phases/20-dark-mode-parity/`).

Capture directories — create if missing:

```bash
mkdir -p .planning/phases/20-dark-mode-parity/screenshots/wave-3/{light,dark}
```

### Row group A — Light → Dark toggle (System Settings > Appearance)

Set macOS to **Light**. Launch the app. Open every surface. Then switch to **Dark** without quitting the app and verify each surface re-renders.

| # | Surface | Light render | Dark re-render (no restart) | Light screenshot | Dark screenshot |
|---|---------|--------------|------------------------------|------------------|------------------|
| 1 | ContentView (main window: sidebar + transcript + details) | ___ | ___ | screenshots/wave-3/light/main-window-idle.png | screenshots/wave-3/dark/main-window-idle.png |
| 2 | LibrarySidebar (visible inside main window) | ___ | ___ | (covered by main-window) | (covered by main-window) |
| 3 | LibraryEntryRow (selected + unselected states visible) | ___ | ___ | (covered by main-window) | (covered by main-window) |
| 4 | TranscriptView (with at least one entry open) | ___ | ___ | (covered by main-window) | (covered by main-window) |
| 5 | DetailsPane (right pane visible) | ___ | ___ | (covered by main-window) | (covered by main-window) |
| 6 | CaptureDock (idle) | ___ | ___ | screenshots/wave-3/light/capture-dock-idle.png | screenshots/wave-3/dark/capture-dock-idle.png |
| 6b | CaptureDock (recording) — start a test recording | ___ | ___ | screenshots/wave-3/light/capture-dock-recording.png | screenshots/wave-3/dark/capture-dock-recording.png |
| 7 | ControlBar | ___ | ___ | screenshots/wave-3/light/control-bar.png | screenshots/wave-3/dark/control-bar.png |
| 8 | SettingsView — every tab (capture each tab as separate PNG: general / notion / obsidian / local-file / advanced) | ___ | ___ | screenshots/wave-3/light/settings-{tab}.png | screenshots/wave-3/dark/settings-{tab}.png |
| 9 | NotionTagSheet (trigger via Notion send flow) | ___ | ___ | screenshots/wave-3/light/notion-tag-sheet.png | screenshots/wave-3/dark/notion-tag-sheet.png |
| 10 | OnboardingView (force first-run reset; check `OnboardingView.swift` for the UserDefaults key) | ___ | ___ | screenshots/wave-3/light/onboarding.png | screenshots/wave-3/dark/onboarding.png |

**Aggregate row group A:**

- All 10 surfaces re-render correctly without app restart on Light → Dark flip: ___ (PASS / FAIL)
- Observation timestamp (local): ___

**Reject if any surface shows:**

- Frozen light backgrounds while system is dark (would indicate a missed hex literal)
- Clashing dark sheets floating over a still-light parent (override removal didn't propagate)
- Missing tokens (text invisible because foreground hex didn't flip)
- Slate-blue or pure-black backgrounds (D-04 mandates the warm `#1A1818` family)

### Row group B — Dark → Light toggle (revert)

Switch System Settings > Appearance back to **Light**. Walk through all surfaces again.

| Check | Result | Timestamp |
|-------|--------|-----------|
| All 10 surfaces revert to light render correctly | ___ | ___ |
| Light render is pixel-stable vs. Wave-2 baseline (see Row group D) | ___ | ___ |

### Row group C — Auto / sunset transition (D-10 step 5)

Switch System Settings > Appearance to **Auto**. Choose Path A (observed) OR Path B (scripted). The gate fails if neither is performed.

**Path A — Observe a real sunrise/sunset transition:**

- [ ] Leave the app running through a natural sunrise or sunset on macOS Auto.
- [ ] System flips, app re-renders all 10 surfaces without restart.
- [ ] Result: ___ (PASS / FAIL)
- [ ] Required line (fill in if Path A used):

  > `Auto-transition observed at YYYY-MM-DD HH:MM:SS local — sunset triggered system flip; app re-rendered all 10 surfaces without restart.`

**Path B — Script the macOS appearance flip:**

- [ ] With app running and System Settings > Appearance set to Auto, run from terminal:

  ```bash
  osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to not dark mode'
  # Wait 2 seconds, observe app re-render
  sleep 2
  osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to not dark mode'
  ```

  (If the `osascript` command above does not flip the visible appearance on macOS 26, try the `defaults` fallback or research the macOS-26-compatible incantation; document the actual command used.)

- [ ] App re-renders on each flip (two-flip cycle is the test).
- [ ] Result: ___ (PASS / FAIL)
- [ ] Required line (fill in if Path B used, with the EXACT command actually run):

  > `Auto-transition scripted via osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to not dark mode' — confirmed working on macOS 26; app re-rendered all 10 surfaces on each flip without restart.`

### Row group D — Light-mode pixel stability vs. Wave-2 baseline

- [ ] Capture light-mode screenshots into `screenshots/wave-3/light/` (already done in Row group A; one set serves both).
- [ ] Diff vs. `screenshots/wave-2/` side-by-side. Expected: **zero perceptible drift** in light mode (Waves 1–2 mathematically guaranteed light-side byte-equivalence; Wave 3 only removes overrides, which is a no-op in light mode because the override was forcing light).
- [ ] **Special case:** NotionTagSheet light-mode appearance now DIFFERS from baseline because pre-Wave-3 it was forced `.dark`. Post-Wave-3 it adapts to system Light, which is intentional. Acceptance for the NotionTagSheet light render: warm paper background, ink text, accent for buttons, legible contrast. Reject if it renders broken (frozen hexes, illegible).
- [ ] Result: ___ (PASS / FAIL)
- [ ] Notes / discrepancies: ___

### Row group E — Dark-mode capture (final reference set)

- [ ] All dark-mode screenshots captured into `screenshots/wave-3/dark/` (done in Row group A).
- [ ] Visual sanity check: every dark surface uses warm-dark backgrounds (`#1A1818` family), cream foreground (`#F0EDE8` family), lavender accent (`#C4A0FF`), NOT slate, NOT pure black, NOT material-design-grey.
- [ ] Result: ___ (PASS / FAIL)

### Row group F — DictationHUD vibrancy (REQ-20.6)

Trigger the dictation hotkey in each mode. The HUD background is system `.hudWindow` vibrancy material; partial-text foreground uses `.primary`/`.secondary` SwiftUI semantic colors.

| Mode | Partial-text legibility against vibrancy | Screenshot |
|------|-----------------------------------------|------------|
| Light | ___ (PASS / FAIL) | screenshots/wave-3/light/dictation-hud.png |
| Dark | ___ (PASS / FAIL) | screenshots/wave-3/dark/dictation-hud.png |

## Deviations Found

(Fill in any visual issues discovered during UAT. For each: surface, transition Light→Dark / Dark→Light / Auto, expected vs actual, proposed fix.)

| # | Surface | Transition | Expected | Actual | Proposed fix |
|---|---------|------------|----------|--------|--------------|

(Add rows as needed. If empty: "No deviations — Phase 20 complete.")

## Resolution

(If deviations: describe fix applied, link to follow-up commit. If none: "No deviations, phase 20 complete.")

___

## Auto-Transition Evidence (REQUIRED)

This section MUST contain exactly one of these strings, with real values filled in, before the phase can close:

- `Auto-transition observed at [YYYY-MM-DD HH:MM:SS local]` — Path A
- `Auto-transition scripted via [exact command]` — Path B

Filled-in line: ___

## Sign-off

- **User:** ___
- **Date:** ___
- **Phase 20 final gate:** ___ (PASS / FAIL)

---

*Phase: 20-dark-mode-parity*
*Wave: 3 of 3*
*Code commit: `b20d4ba`*
*UAT worksheet generated: 2026-04-30*
