# Milestones

Historical record of shipped versions. Newest first.

---

## v1.3 — Polish & Validation

**Shipped:** 2026-05-12
**Tag:** `v1.3`
**Phases:** 22 / 23 / 24 / 25 / 26 / 26.1 (6 executed; 26.1 inserted post-Phase 26 to close PROCESS-03 lint-gate regression)
**Plans:** 21 across 6 phases (22 → 6 plans, 23 → 5, 24 → 5, 25 → 2, 26 → 2, 26.1 → 1)
**Timeline:** 11 days (2026-05-01 → 2026-05-11)
**Git range:** `b9753bf` → `75a5856` (125 commits)
**Files changed:** 212 · **LOC delta:** +34,590 / −277 (Swift sources 10,097 · Tests 6,166 · website 2,629)

### Delivered

Close deferred v1.0–v1.2 backlog: complete the Phase 19 "Looks Done But Isn't" QA checklist + Phase 21 titlebar visual UAT, backfill Nyquist `*-VALIDATION.md` across v1.0 phases 1/2/3/8/10 and v1.2 phases 20/21, standardize SUMMARY.md `requirements-completed:` frontmatter with a CI lint gate, and stand up swift-snapshot-testing visual-regression infra for the appearance bridge.

### Key Accomplishments

1. **SUMMARY frontmatter standard + CI lint gate (Phase 22)** — Canonical `requirements-completed:` (hyphen, D-01) key added to all three SUMMARY templates (`summary.md`, `summary-standard.md`, `summary-minimal.md`) plus a 4-rule contract paragraph in `execute-plan.md`. `scripts/lint-summaries.sh` (Bash + yq) enforces presence/subset; `.github/workflows/lint-summaries.yml` wires it as a path-filtered macos-26 PR-merge gate. 18 archived SUMMARYs canonicalised via ephemeral migration script (committed and git-rm'd in the same migration commit per D-13). Phase 22 closed `38 files checked, 0 failures, 0 warnings`.
2. **Visual regression infra (Phase 23)** — swift-snapshot-testing 1.19.2 wired into the test target, 15 baselines locked across 5 surfaces (ContentView, LibraryView, SettingsView, RecordingView, DictationHUD) × 3 appearances (Light/Dark/System), `SnapshotFixtures` helper, Nygard-style ADR rejecting custom XCTest+CGImage, snapshotpreviews, and XCUITest. `build-check.yml` extended with `swift test` step + record-mode env-var guard + failure-only diff-PNG artifact upload. `TESTING.md` refreshed, `CONTRIBUTING.md` created at repo root with the regen workflow and an AI-attribution-forbidden Commit Hygiene rule.
3. **Nyquist sweep — v1.0 (Phase 24)** — 5 green `*-VALIDATION.md` files for v1.0 phases 1 (Rebrand), 2 (Security+Stability), 3 (Library+Naming), 8 (Defects), 10 (Obsidian+Cleanup). 10 new test files / 26 new @Test methods cover REBR-01/02/04/06/07, SECR-01..12 + STAB-01..04 + REBR-05, NAME-02/03 + SESS-06, STAB-03 + REBR-03, and the D-05 `recoveredSessionType()` helper lift. `build-check.yml:56` SHA-pin regression (Phase 23 ddcec6a) fixed inline — sole Phase 24 production-source change. Test suite grew 236 → 262 / 42 → 51 suites.
4. **Nyquist sweep — v1.2 (Phase 25)** — 2 green `*-VALIDATION.md` files for v1.2 phases 20 (dark-mode parity) and 21 (AppearancePreference). `PreferredColorSchemeGrepGateTests` (shared, 7 @Test methods), `DesignTokensAdaptivePaletteTests` (NSColor-bridged variance test for 17 Chronicle tokens), `AppSettingsTests` extension for AppearancePreference UD round-trip. 8 verification rows per VALIDATION file, both at `nyquist_compliant: true`. Suite grew 262 → 274 / 51 → 53 suites.
5. **QA sweep + visual UAT (Phase 26)** — Full 9-scenario QA sweep authored in `26-UAT.md`, terminal status `approved-with-debt`. QA-03 PASS for full multi-monitor matrix (primary + secondary-left + secondary-right + vertical + mid-recording-disconnect attested by user). QA-06..09 pass-citation from `21-HUMAN-UAT.md` (2026-05-01 user attestation). QA-01/02/04 WITHDRAWN with codebase-verified reasoning (Maccy/Alfred positioning retired; non-sandboxed app has no security-scoped bookmark code path). QA-05 UNTESTABLE-this-cycle, routed to `model-manifest-url-404.md` deferred-todo. Phase 26-02 retired DICT-06 (post-dictation clipboard restore) after smoke-test showed the 3s restore broke the dictation→paste UX; 268/268 tests pass post-retirement.
6. **PROCESS-03 lint-gate closure (Phase 26.1)** — Inserted `requirements-completed: []` (empty list, valid per D-04) into 8 v1.0-archive SUMMARY frontmatters, flipping `bash scripts/lint-summaries.sh` from exit 1 (8 failures) to exit 0 (55 files, 0 failures, 0 warnings). `Lint Summaries` CI gate restored to green on `main`. Frontmatter-only migration — zero code/test/schema surface touched.

### Known Gaps / Deferred

- **`ci-build-check-failing-on-main.md`** (high) — Swift 6 strict-concurrency errors at `TranscriptionEngine.swift:238,342` (pre-existing from 2026-04-02 commit `2a2e7af`) fail `build-check.yml` `swift build` on the macos-26 runner. Blocks Phase 24 CI green attestation (NYQUIST-01..05 marked `satisfied (CI attest pending)` in the milestone audit).
- **`model-manifest-url-404.md`** (high) — `raw.githubusercontent.com/cnewfeldt/ps-transcribe-releases/main/model-manifest.json` returns HTTP 404. `ModelUpdateService.checkForUpdate()` always fails, making QA-05's disk-space preflight unreachable end-to-end. Release/deployment-process gap (manifest needs republishing), not a v1.3 milestone-deliverable failure.
- **Phase 24 + Phase 26 verifications** at `human_needed` — CI green attestation (Phase 24) and REQUIREMENTS.md traceability + QA-03b sub-scenario absorption decisions (Phase 26) carried forward to v1.4 as accepted tech debt. UAT artifacts ship at `approved-with-debt` with 0 pending scenarios.
- **Phase 23 SettingsView snapshot Dictation crop** — 520×400 frame crops out the Dictation section; coverage gap, not a failure.
- **Phase 25 WR-02 advisory** — Wave-2 adaptive tokens (warningTint et al.) not in REQ-20.2 roster; advisory hardening, not a current break.
- **Phase 22 lint scope** — `lint-summaries.sh DEFAULT_ROOT=".planning/milestones"` does not cover `.planning/phases/`; active-phase SUMMARYs are an unscanned blind spot. Architectural debt, no current violation.

### Decisions

- v1.3 phases continue v1.2's numbering (first v1.3 phase = 22).
- Canonical SUMMARY frontmatter key is `requirements-completed` (hyphen, D-01). Underscore is forbidden and lint-flagged.
- Lint script tolerates legacy v1.2 YAML quirks via a grep-based fallback (yq parse failures don't abort `set -euo pipefail`).
- Ephemeral migration scripts ship as a 2-commit pair (script-add → migration+script-rm) to preserve D-13 reproducibility-via-history.
- D-03 lenient Nyquist policy: WITHDRAWN-with-cited-source rows are valid VALIDATION.md outcomes when codebase reality has moved past the original requirement.
- D-04 `requirements-completed: []` (empty list) is valid frontmatter — used for closure phases that touch zero requirement surface.
- QA-03 multi-monitor matrix collapses sub-scenarios into a single PASS row when primary attestation covers the architectural concern (Phase 26 human-decision #2).
- DICT-06 (post-dictation clipboard restore) retired mid-Phase-26 after smoke-test surfaced UX regression; backward removal preferred over forward toggle.
- `gogglebox.com` custom domain (`DOMAIN-FUT-01` / proposed Phase 27) removed from scope 2026-05-05; marketing site stays on `ps-transcribe-web.vercel.app`.

### Archives

- Roadmap: [`milestones/v1.3-ROADMAP.md`](milestones/v1.3-ROADMAP.md)
- Requirements: [`milestones/v1.3-REQUIREMENTS.md`](milestones/v1.3-REQUIREMENTS.md)
- Audit: [`milestones/v1.3-MILESTONE-AUDIT.md`](milestones/v1.3-MILESTONE-AUDIT.md)
- Phases: `milestones/v1.3-phases/` (Phase 22 archived inline; 23/24/25/26/26.1 moved at milestone close)

Known deferred items at close: 6 (2 high-priority todos + 4 tech-debt items; see STATE.md Deferred Items section).

---

## v1.2 — Standalone Dictation + Model Auto-Update + Dark Mode Parity

**Shipped:** 2026-05-01 (macOS app released as v2.2.0)
**Tag:** `v1.2`
**Phases:** 16 / 17 / 18 / 18.1 / 20 / 21 (6 executed; Phase 19 removed from scope)
**Plans:** 32 across 6 phases
**Timeline:** 5 days (2026-04-27 → 2026-05-01)
**Git range:** `33d6baa` → `cb7a35e` (191 commits, 52 feat/fix)
**Files changed:** 293 · **LOC:** 10,165 Swift + 2,687 website TS/MDX

### Delivered

Make PS Transcribe useful as a standalone dictation tool, let the ASR model update without an app rebuild, and bring the macOS app to full dark-mode parity with a user-controlled appearance preference.

### Key Accomplishments

1. **Hotkey dictation with floating HUD** — `RegisterEventHotKey`-based global hotkey (default `Cmd+Shift+D`), borderless non-activating NSPanel HUD with native vibrancy, live partial transcription, clipboard write with `org.nspasteboard.TransientType` + `AutoGeneratedType` privacy markers, configurable toggle vs. press-and-hold modes.
2. **Shared save-destinations architecture (Phase 18.1 pivot)** — Top-level `SaveDestinations` fan-out (Local File / Obsidian / Notion). All content producers (meeting recording, voice memo, dictation) emit `(content, sessionType)` to one writer set with per-destination non-fatal failure. Replaced dictation-private folder picker; FOLDER-04 contract retired in favor of always-on clipboard.
3. **FluidAudio model auto-update** — `ModelUpdateService` with manifest fetch, 24h throttle, `min_app_version` gate, staging download, SHA-256 verify, atomic `moveItem` swap, `TranscriptionEngine.reloadModels()` hot-swap, deferred-while-session-active, disk-space preflight, rollback on reload failure. Manifest hosted at `cnewfeldt/ps-transcribe-releases`.
4. **Chronicle adaptive light/dark token palette** — `Color(light:dark:)` helper, 17 Chronicle tokens converted, 11 legacy tokens promoted, 10 surface call-sites audited and adapted. Removed all forced `.preferredColorScheme(.light)` overrides.
5. **User-controlled appearance preference** — Three-way `AppearancePreference` (System / Light / Dark) with `colorScheme: ColorScheme?` SwiftUI bridge, `AppSettings` UserDefaults persistence, three Scene-root `.preferredColorScheme(...)` call-sites, `DictationWindowController.NSAppearance(named:)` mirror for the AppKit-owned HUD, `Section("Appearance")` Picker at top of `SettingsView`. Default `.system` preserves Phase 20 byte-for-byte.
6. **Chronicle titlebar bridge (post-fix)** — Code review caught the AppKit-owned main-window titlebar painting cream `#FAFAF7` unconditionally, fighting the Dark override. Fixed via `window.appearance` follows preference + cream paint gated on resolved `.aqua` effective appearance + dynamic `NSColor.labelColor` on toolbar title + `observeChronicleTitlebar` re-applies on every preference change.

### Known Gaps / Deferred

- **`QA-FUT-01`:** Phase 19 "Looks Done But Isn't" QA checklist (clipboard history vs. Maccy/Alfred live test, multi-monitor HUD positioning, security-scoped bookmark survival across relaunch, disk-space preflight UAT) — deferred to a later milestone.
- **`NYQUIST-FUT-01` (extended):** Nyquist `*-VALIDATION.md` missing for Phase 20 + Phase 21 (Wave 0 RED scaffolding pattern was retired post-18.1).
- **Phase 21 titlebar bridge visual UAT:** 4 visual UAT items (titlebar strip flip under runtime preference toggles) deferred to backlog. Code-verified at `ce79965`.
- **Phase 18.1 tech debt (4 warnings + 4 info):** transient `settings.localFileEnabled` toggle pattern observable to UI, path validation `..` substring check over-restrictive, `isAnyDestinationEnabled` asymmetric check, etc. — see `.planning/milestones/v1.2-MILESTONE-AUDIT.md`.

### Decisions

- v1.2 phases continue v1.1's numbering (first v1.2 phase = 16; phase 15 was reverted in v1.1).
- KeyboardShortcuts via `RegisterEventHotKey` (no Accessibility / Input Monitoring permission required; App Store compatible).
- Dictation uses a separate `TranscriptionEngine` instance owned by `DictationCoordinator` (Option B from architecture research).
- Manifest hosting: project-owned JSON at `cnewfeldt/ps-transcribe-releases` (per-file SHA-256 + `min_app_version` support; HuggingFace refs API rejected for lacking compatibility gating).
- Model swap: `FileManager.moveItem` (not `replaceItem`) for atomicity with APFS rollback safety. Documented in 17-03-SUMMARY.md.
- Save destinations are top-level shared layer; features fan out, never own a folder picker (Phase 18.1 architectural pivot).
- Default `AppearancePreference` is `.system`; `colorScheme: nil` is a SwiftUI no-op preserving Phase 20 baseline.

### Archives

- Roadmap: [`milestones/v1.2-ROADMAP.md`](milestones/v1.2-ROADMAP.md)
- Requirements: [`milestones/v1.2-REQUIREMENTS.md`](milestones/v1.2-REQUIREMENTS.md)
- Audit: [`milestones/v1.2-MILESTONE-AUDIT.md`](milestones/v1.2-MILESTONE-AUDIT.md)
- Phases: `milestones/v1.2-phases/` (after archive)

---

## v1.1 — Marketing Website

**Shipped:** 2026-04-25
**Tag:** `v1.1`
**Phases:** 11 / 12 / 13 / 14 (4 executed; Phase 15 reverted)
**Plans:** 16
**Production:** `ps-transcribe-web.vercel.app` (slug fallback)

### Delivered

Marketing website at `ps-transcribe-web.vercel.app`: Next.js + Vercel scaffold, Chronicle design system port (light-only), landing page, MDX docs section (6 pages). Phase 15 (Changelog) was scoped, planned, built, and reverted on 2026-04-25 — public release notes are out of scope.

### Archives

- Roadmap: [`milestones/v1.1-ROADMAP.md`](milestones/v1.1-ROADMAP.md)
- Requirements: [`milestones/v1.1-REQUIREMENTS.md`](milestones/v1.1-REQUIREMENTS.md)

---

## v1.0 — PS Transcribe

**Shipped:** 2026-04-14
**Tag:** `v1.0`
**Phases:** 8 active (Phases 5 + 6 abandoned in 2026-04-04 scope reduction)
**Plans:** 28
**Requirements:** 45

### Delivered

Full rebrand from "Tome" to "PS Transcribe", security fixes for all 12 SCAN findings, crash recovery and diarization fixes, session library with grid view + missing-file detection + Obsidian deep-link, recording naming + lifecycle, three-state mic button, model onboarding, Notion integration. LLM analysis of transcripts removed in scope reduction; preserved at git tag `archive/llm-analysis-attempt`.

### Archives

- Roadmap: [`milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md)
- Requirements: [`milestones/v1.0-REQUIREMENTS.md`](milestones/v1.0-REQUIREMENTS.md)
- Audit: [`milestones/v1.0-MILESTONE-AUDIT.md`](milestones/v1.0-MILESTONE-AUDIT.md)
