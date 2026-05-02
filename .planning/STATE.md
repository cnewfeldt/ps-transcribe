---
gsd_state_version: 1.0
milestone: v1.3
milestone_name: Polish & Validation
status: completed
stopped_at: Phase 23 context gathered
last_updated: "2026-05-02T23:06:22.829Z"
last_activity: 2026-05-02 -- Phase 22 complete (lint green across 39 SUMMARYs)
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 6
  completed_plans: 6
  percent: 17
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-01)

**Core value:** Users can record meetings and voice memos with accurate, private, on-device transcription. Plus standalone hotkey-triggered dictation as of v1.2. All processing stays on-device.
**Current focus:** v1.3 Polish & Validation — Phase 22 (SUMMARY frontmatter standard + CI lint) complete; Phase 23 (Visual Regression Infra) next.

**Shipped milestones:**

- v1.0 PS Transcribe (2026-04-14) — see `milestones/v1.0-ROADMAP.md`
- v1.1 Marketing Website (2026-04-25) — see `milestones/v1.1-ROADMAP.md`
- v1.2 Standalone Dictation + Model Auto-Update + Dark Mode Parity (2026-05-01; macOS app v2.2.0) — see `milestones/v1.2-ROADMAP.md`

**2026-04-04 scope reduction:** Phases 5 (Ollama Integration) and 6 (Live LLM Analysis) were abandoned in v1.0. PS Transcribe is scoped to transcription only; LLM analysis of transcripts is not part of the product. Implementation preserved at git tag `archive/llm-analysis-attempt`.

**2026-04-25 scope reduction:** Phase 15 (Changelog Page) was scoped, planned, built, and then reverted in v1.1. No public release-notes surface; `CHANGELOG.md` stays a developer-internal artifact.

## Current Position

Phase: Phase 23 next (Visual Regression Infra)
Plan: —
Status: Phase 22 complete; ready to discuss/plan Phase 23
Last activity: 2026-05-02 -- Phase 22 complete (lint green across 39 SUMMARYs)

Progress: 1/6 phases (17%)

## Performance Metrics

**Velocity (cumulative):**

- v1.0 plans completed: 28
- v1.1 plans completed: 16
- Total plans (v1.0 + v1.1): 44

**By Milestone:**

| Milestone | Phases | Plans | Shipped |
|-----------|--------|-------|---------|
| v1.0 — PS Transcribe | 8 active (5/6 abandoned) | 28 | 2026-04-14 |
| v1.1 — Marketing Website | 4 (15 reverted) | 16 | 2026-04-25 |
| v1.2 — Standalone Dictation + Model Auto-Update + Dark Mode Parity | 6 executed (19 removed from scope) | 32 | 2026-05-01 |
| Phase 18 P01 | 3min | 1 tasks | 16 files |
| Phase 18 P02 | 3min | 2 tasks | 4 files |
| Phase 18 P03 | 2min | 1 tasks | 2 files |
| Phase 18 P04 | 4min | 2 tasks | 4 files |
| Phase 18 P5 | 3min | 2 tasks | 3 files |
| Phase 18 P06 | 13min | 2 tasks | 12 files |
| Phase 18 P07 | 4min | 4 tasks | 5 files |
| Phase 18 P08 | 5min | 4 tasks | 5 files |
| Phase 20 P01 | 8min | 2 tasks | 2 files |
| Phase 20 P02 | 3min | 3 tasks | 7 files |
| Phase 21 P01 | ~5min | 1 tasks | 1 files |
| Phase 21 P02 | ~3min | 3 tasks | 3 files |
| Phase 21 P03 | ~10min | 3 tasks | 1 files |
| Phase 22 P01 | 2min | 1 tasks | 1 files |
| Phase 22 P02 | 3min | 2 tasks | 3 files (out-of-repo templates) |
| Phase 22 P03 | 4min | 2 tasks | 2 files (out-of-repo workflow + agent) |
| Phase 22 P04 | 12min | 1 tasks | 1 files (lint script) |
| Phase 22 P05 | 2min | 1 tasks | 1 files (CI workflow) |
| Phase 22 P06 | 25min | 2 tasks | 19 files (18 SUMMARYs + ephemeral script) |

## Accumulated Context

### Roadmap Evolution

- Phase 18.1 inserted after Phase 18: Shared save destinations + Local File (URGENT) — Phase 18 paused mid-UAT after architectural feedback that dictation-private folder picker duplicates what shared destinations should own; Phase 18.1 introduces top-level Local File destination parallel to Notion/Obsidian and refactors dictation off `DictationOutputMode`. (2026-04-29)
- Phase 20 added: Dark mode parity (2026-04-30)

### Decisions

Decisions are logged in PROJECT.md Key Decisions table. Recent milestone-level decisions:

- v1.1 phases continued v1.0's numbering (first v1.1 phase was 11)
- v1.2 phases continue from v1.1's last phase: Phases 16–19 (phase 15 was reverted, so 16 is the correct next number)
- Backlog phase 999.1 (keyboard-triggered clipboard dictation) promoted into v1.2 as DICT-01..11 + FOLDER-01..05; removed from backlog
- Marketing site lives in `/website` subdirectory of this repo (not a separate repo)
- Chronicle design system ported to web, light-only — no web-specific redesign
- Vercel subdomain fallback to `ps-transcribe-web.vercel.app` (canonical slug claimed); custom domain deferred post-v1.2
- No public changelog — decided after building and reverting a page in phase 15
- Build-time sidebar codegen from MDX `doc` exports (drift-by-construction in phase 14)
- Global hotkey mechanism: `sindresorhus/KeyboardShortcuts` via `RegisterEventHotKey` (no Accessibility or Input Monitoring permissions required; App Store compatible)
- Dictation uses a separate `TranscriptionEngine` instance owned by `DictationCoordinator` (Option B from architecture research), not a forked state machine
- **Manifest hosting strategy ADR is a research gate for Phase 17** — resolve before Phase 17 planning locks; SUMMARY.md recommends project-owned manifest on gh-pages for per-file SHA-256 + `min_app_version` support
- [Phase 18]: Wave 0 RED test scaffolding pattern: 16 @Suite files with .disabled('Pending Plan 18-XX') traits. Body is placeholder; un-disabling wave replaces both trait AND body with real assertions against actual production symbols (forces compile-time binding to ship-state code, not Wave-0 mocks).
- [Phase 18]: [Phase 18-02]: KeyboardShortcuts v2.4.0 Name initializer parameter label is default: (NOT initial: as RESEARCH.md anticipated). Verified directly in .build/checkouts/.../Name.swift:38.
- [Phase 18]: [Phase 18-02]: GlobalHotkeyService is the @MainActor @Observable wrapper for KeyboardShortcuts; mirrors ModelUpdateService shape. Default Cmd+Shift+D is registered via KeyboardShortcuts.Name.dictateGlobal extension; library handles UserDefaults persistence under prefix KeyboardShortcuts_dictateGlobal.
- [Phase 18]: [Phase 18-02]: Removed Thread.isMainThread runtime assertions from onKeyDown/onKeyUp closure tests -- invoking from an @MainActor test body is trivially main-thread; genuine cross-thread Carbon-callback dispatch is verified by manual UAT only.
- [Phase 18]: [Phase 18-03]: hasActiveSession is non-async computed property on DictationLogger actor (callers await); chose minimal-leak Bool over exposing currentFilePath: URL?. Resolves RESEARCH §3.
- [Phase 18]: [Phase 18-03]: discardSession() is companion to endSession(): same close-and-clear shape, but unlinks file instead of returning URL. Bounded try? for already-closed-handle (mirrors endSession line 94) and missing-file race (NSFileNoSuchFileError); documented inline as policy not suppression.
- [Phase 18]: [Phase 18-04]: DictationCoordinator skeleton lands as @Observable @MainActor final class with 6-state Equatable enum (idle, loadingModel, listening, cancellingPending(deadline:), copied, blockedSessionActive). isActive returns true for listening/cancellingPending/loadingModel; false for idle/copied/blockedSessionActive. Wave 2 ships TYPE only; Wave 4 (Plan 18-06) ships begin/end/cancel methods.
- [Phase 18]: [Phase 18-04]: Internal session-state vars (sessionStartTime, elapsedTimerTask, cancelRevertTask, copiedDismissTask, savedPasteboardItems, postWriteChangeCount, restoreTask) declared at class level (NOT private) so Plan 18-06 can attach begin/end/cancel methods in the SAME file without widening visibility. Plan 18-06 will mark them private once the methods land.
- [Phase 18]: [Phase 18-04]: SessionCoordinator.anySessionActive now ORs three branches: engine?.isRunning || modelUpdate?.isApplying || dictation?.isActive. DICT-11 mutual-exclusion gate is structurally complete; Plan 18-06's begin path will rely on the predicate for its early-return guard.
- [Phase 18]: [Phase 18-05]: DictationWindowController is @MainActor NSWindowController owning a borderless non-activating NSPanel with .hudWindow vibrancy + NSHostingView; sharingType = .none set INLINE in init (Pitfall #4: AppDelegate didBecomeKeyNotification observer never fires for .nonactivatingPanel)
- [Phase 18]: [Phase 18-05]: HUD width clamps to min(420, screen.visibleFrame.width - 40) with 280pt floor (Open Question §4); bottom-center positioning math: vertically centered within bottom-quarter band of NSScreen.main.visibleFrame
- [Phase 18]: [Phase 18-05]: DictationHUD is parameterized (state/elapsed/partialText/onStop), NOT @Observable-bound. Wave 4 supplies the binding closure to setContent() that reads coordinator state -- @Observable propagation handles re-renders. Keeps view side-effect-free and trivially previewable (5 #Preview blocks)
- [Phase 18]: [Phase 18-05]: Test fix -- NSWindow.SharingType.none must be fully qualified in #expect because bare .none resolves to Optional.none (nil) due to Swift type-inference preference. Documented inline.
- [Phase 18]: [Phase 18-06]: DictationCoordinator behavior complete -- begin/end/cancel/escape/hold-release/preWarm + helpers + DEBUG test surface. inlineTranscript: String? added to LibraryEntry (D-12, Codable backward-compat). LibraryEntryRow shows mic.fill for dictation entries (D-11).
- [Phase 18]: [Phase 18-06]: PasteboardTestLock actor mutex pattern -- Swift Testing's .serialized trait orders tests within a suite, but multiple suites still run in parallel and share NSPasteboard.general. Cross-suite mutex via shared actor lock with continuation queue. All clipboard-touching Phase 18 tests acquire/release before/after pasteboard touches.
- [Phase 18]: [Phase 18-06]: Output-mode branching as conditionals (if mode == .clipboard || mode == .both) rather than mode-specific subclasses. inlineTranscript = (finalFileURL == nil) ? assembled : nil -- single source of truth based on whether the on-disk file exists. D-15 silent fallback path lands in the inline branch.
- [Phase 18]: [Phase 18-07]: Settings > Dictation section uses Recorder(for:) initializer (no label arg) inside HStack with custom 12pt Text label, not the Recorder("Hotkey", name:) form. Both forms exist in v2.4.0; bare-init keeps typography consistent with adjacent rows.
- [Phase 18]: [Phase 18-07]: Folder picker row uses .disabled() AND .opacity(0.5) when output mode is .clipboard, not just .disabled. macOS 26 leaves disabled controls fully opaque otherwise -- the dim is necessary for legible no-op state.
- [Phase 18]: [Phase 18-07]: AppSettingsDictationPersistenceTests use per-test defer { UserDefaults.standard.removeObject(forKey:) } for cleanup rather than suite-level traits. Simplest correct mechanism; runs even on #expect failure inside @MainActor test bodies.
- [Phase 18]: [Phase 18-07]: ClipboardRestoreTests cross-suite pasteboard race documented as deferred item rather than fixed in this plan. Pre-existing Plan 18-06 carry-over; Plan 18-07 scope is Settings UI + persistence tests, not Plan 18-06 surface. Suggested fix (migrate to PasteboardTestLock) recorded in deferred-items.md.
- [Phase 18]: [Phase 18-08]: PSTranscribeApp.init wires GlobalHotkeyService + DictationCoordinator + DictationWindowController at app scope; hotkey callbacks routed by AppSettings.dictationHotkeyMode (toggle vs press-and-hold); Esc NSEvent global monitor installed; eager pre-warm via Task.detached(priority: .background) + 2s sleep + MainActor.run gated on hotkeyAssigned (WARNING #11 opt-out).
- [Phase 18]: [Phase 18-08]: MenuBarExtra label uses ternary 'mic.fill' / 'book.closed' bound to dictationCoordinator.isActive + .symbolEffect(.pulse, isActive:) for the recording animation (DICT-03). ContentView .task subscribes to .dictationSessionEnded and invokes refreshLibrary() so sidebar updates without app restart.
- [Phase 18]: [Phase 18-08]: Swift 6.2's region-based isolation checker rejected Task.detached { @MainActor in ... } for the eager pre-warm Task. Refactored to Task.detached(priority: .background) + MainActor.run for the hotkeyAssigned read followed by an inner Task { @MainActor in await preWarmModels() }. Equivalent semantics, compiles cleanly. Documented as Rule 3 deviation.
- [Phase 21]: [Phase 21-01]: AppearancePreference enum lands at file scope in AppSettings.swift (D-08 lock), not nested or extracted. Sendable conformance added beyond plan minimum -- free for String-backed enums under Swift 6.2 strict concurrency. Init read positioned between dictation block and model-update block so v1.2 init() body groups read top-to-bottom in the same order as the MARK sections.
- [Phase 21]: [Phase 21-01]: colorScheme: ColorScheme? returns nil for .system -- a SwiftUI no-op when fed to .preferredColorScheme(_:). This is the primitive Plan 21-02 will use to bypass overrides without a separate code branch for .system; satisfies Req 6 (invisible migration to system-following default).
- [Phase 21]: [Phase 21-02]: MenuBarExtra menu content wrapped in Group { ... } so .preferredColorScheme attaches to the multi-statement view builder body. Status-bar Image label intentionally NOT modified -- system-rendered NSStatusItem inherits NSApp.effectiveAppearance regardless of .preferredColorScheme; documented tolerated gap per CONTEXT.md.
- [Phase 21]: [Phase 21-02]: Recursive observeAppearance() continuation pattern (re-arming withObservationTracking) chosen over for-await/AsyncStream because @Observable doesn't expose AsyncSequence. Task { @MainActor in ... } continuation in onChange compiled cleanly under Swift 6.2 strict concurrency without capture-list adjustments or @MainActor.assumeIsolated workarounds.
- [Phase 21]: [Phase 21-02]: Relaxed D-06 grep gate satisfied -- all three runtime .preferredColorScheme call-sites in PSTranscribe/Sources (excluding #Preview blocks and /// doc comments) live in PSTranscribeApp.swift at lines 163, 185, 197 and read settings.appearancePreference.colorScheme.
- [Phase 21]: [Phase 21-03]: 8/8 UAT scenarios PASS without notes; user response "approved". KVO fallback for NSPanel `.system` resolution NOT needed -- `panel.appearance = nil` correctly inherits NSApp.effectiveAppearance on live macOS Light↔Dark toggle (Scenario G step 8).
- [Phase 21]: [Phase 21-03]: D-06 deviation documented inline in 21-VERIFICATION.md TWICE (audit gate intro paragraph + criteria-table row 3) so future verifiers reading SPEC #4's superseded "exactly ONE hit" wording are immediately redirected to the relaxed location+source check.
- [Phase 21]: [Phase 21-03]: MenuBarExtra status bar icon glyph remaining system-rendered (does not flip per app preference) confirmed as tolerated gap; not a Phase 22 candidate. Dropdown menu *content* flips correctly via Group { ... }.preferredColorScheme(...) wrapper from Plan 21-02.
- [v1.2 close-out]: D-01 milestone state flip executed -- STATE.md status: completed, ROADMAP.md Phase 21 ticked, Progress Table 3/3 Complete 2026-05-01. v1.2 git tag remains separate ship gate (NOT part of Plan 21-03 metadata commit).
- [Phase 22]: D-01 canonical key is `requirements-completed` (hyphen). All v1.3+ SUMMARY artifacts MUST use the hyphen form; underscore is forbidden and lint-flagged.
- [Phase 22]: [Phase 22-04]: lint-summaries.sh added grep-based fallback for legacy v1.2 SUMMARYs whose YAML yq cannot parse (unquoted colons in list values). Without the fallback, set -euo pipefail aborted the script on the first parse error and missed downstream files.
- [Phase 22]: [Phase 22-06]: Migration shipped as 2-commit pair (script-add → migration+script-rm) instead of single commit. Single-commit add+delete nets to zero in git, defeating D-13 reproducibility-via-history. Pattern documented for future ephemeral-script migrations.
- [Phase 22]: [Phase 22-06]: lint-summaries.sh exits 0 with `39 SUMMARY files checked, 0 failures, 0 warnings` (33 archived + 6 v1.3 plan-22 SUMMARYs). CI gate active for all future PRs touching SUMMARY/PLAN files.

### Pending Todos

v1.3 active scope (now in REQUIREMENTS.md):

- [ ] `QA-FUT-01` — Phase 19 "Looks Done But Isn't" QA checklist sweep + Phase 21 titlebar visual UAT (folded in)
- [ ] `DOMAIN-FUT-01` — Custom domain for marketing site
- [ ] `NYQUIST-FUT-01` — Full Nyquist validation sweep (v1.0 phases 1/2/3/8/10 + Phase 20 + Phase 21)
- [ ] `PROCESS-FUT-01` — `requirements_completed` frontmatter on SUMMARY.md template + tooling
- [ ] `VISREG-01` — Visual regression / snapshot testing infra for appearance override

Deferred beyond v1.3 (see PROJECT.md "Future Candidate Goals" + `.planning/seeds/`):

- Designer-tuned dark Chronicle pass — dropped from v1.3; revisit only if dark-mode issues surface
- SEED-001 Dictation extensions
- SEED-002 Library upgrade
- SEED-003 Transcript editing surface
- SEED-004 Format reach

### Blockers/Concerns

None — v1.2 shipped clean.

## Session Continuity

Last session: 2026-05-02T23:06:22.823Z
Stopped at: Phase 23 context gathered
Resume file: .planning/phases/23-visual-regression-infra/23-CONTEXT.md
