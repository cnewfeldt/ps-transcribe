---
gsd_state_version: 1.0
milestone: v1.2
milestone_name: — Standalone Dictation + Model Auto-Update
status: executing
stopped_at: Completed 18-07-PLAN.md
last_updated: "2026-04-28T19:00:16.636Z"
last_activity: 2026-04-28
progress:
  total_phases: 4
  completed_phases: 2
  total_plans: 17
  completed_plans: 16
  percent: 94
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-27)

**Core value:** Users can record meetings and voice memos with accurate, private, on-device transcription. All processing stays on-device.
**Current focus:** Phase 18 — hotkey-dictation-plain-folder-output

**Shipped milestones:**

- v1.0 PS Transcribe (2026-04-14) — see `milestones/v1.0-ROADMAP.md`
- v1.1 Marketing Website (2026-04-25) — see `milestones/v1.1-ROADMAP.md`

**2026-04-04 scope reduction:** Phases 5 (Ollama Integration) and 6 (Live LLM Analysis) were abandoned in v1.0. PS Transcribe is scoped to transcription only; LLM analysis of transcripts is not part of the product. Implementation preserved at git tag `archive/llm-analysis-attempt`.

**2026-04-25 scope reduction:** Phase 15 (Changelog Page) was scoped, planned, built, and then reverted in v1.1. No public release-notes surface; `CHANGELOG.md` stays a developer-internal artifact.

## Current Position

Phase: 18 (hotkey-dictation-plain-folder-output) — EXECUTING
Plan: 8 of 8
Status: Ready to execute
Last activity: 2026-04-28

Progress: [████████░░] 76%

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
| v1.2 — Standalone Dictation + Model Auto-Update | 4 (in progress) | TBD | TBD |
| Phase 18 P01 | 3min | 1 tasks | 16 files |
| Phase 18 P02 | 3min | 2 tasks | 4 files |
| Phase 18 P03 | 2min | 1 tasks | 2 files |
| Phase 18 P04 | 4min | 2 tasks | 4 files |
| Phase 18 P5 | 3min | 2 tasks | 3 files |
| Phase 18 P06 | 13min | 2 tasks | 12 files |
| Phase 18 P07 | 4min | 4 tasks | 5 files |

## Accumulated Context

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

### Pending Todos

v1.2 phases ready to plan:

- [ ] Phase 16: Foundation — lift LibraryStore, anySessionActive flag, Models.swift enums, AppSettings keys, TranscriptLogger plain methods
- [ ] Phase 17: Model Auto-Update — ModelUpdateService, reloadModels(), Settings > Model section
- [ ] Phase 18: Hotkey Dictation + Plain-Folder Output — DictationHotkeyController, DictationCoordinator, DictationHUD, clipboard write, folder picker, DictationLogger
- [ ] Phase 19: Integration & Hardening — mutual exclusion, rollback simulation, QA checklist

Deferred to a later milestone (see PROJECT.md "Future Candidate Goals"):

- [ ] Custom domain for marketing site
- [ ] Nyquist validation sweep across v1.0 phases 1, 2, 3, 8, 10
- [ ] `requirements_completed` frontmatter on future SUMMARY.md files (process improvement)

### Blockers/Concerns

**Research gate (Phase 17):** Manifest hosting strategy ADR must be resolved before Phase 17 planning locks. Options: HuggingFace refs API (lightweight, no infrastructure) vs. project-owned JSON manifest on gh-pages (enables per-file SHA-256 checksums and `min_app_version` compatibility gating). Recommendation in SUMMARY.md: project-owned manifest.

## Session Continuity

Last session: 2026-04-28T19:00:00.802Z
Stopped at: Completed 18-07-PLAN.md
Resume file: None
