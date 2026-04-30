# Roadmap

## Shipped Milestones

- **v1.0 — PS Transcribe** (2026-04-02 → 2026-04-14): Full rebrand from Tome, security/stability hardening, session library + recording naming, three-state mic button + model onboarding, Notion integration, Obsidian deep-link, defect cleanup. 8 active phases, 45 requirements, 28 plans. Archived: [`milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md) · Requirements: [`milestones/v1.0-REQUIREMENTS.md`](milestones/v1.0-REQUIREMENTS.md) · Tag: `v1.0`.
- **v1.1 — Marketing Website** (2026-04-21 → 2026-04-25): Next.js + Vercel scaffold, Chronicle design system port, landing page, MDX docs section (6 pages). Phase 15 (Changelog) reverted — public release notes out of scope. 4 phases, 22 requirements, 16 plans. Production: `ps-transcribe-web.vercel.app`. Archived: [`milestones/v1.1-ROADMAP.md`](milestones/v1.1-ROADMAP.md) · Requirements: [`milestones/v1.1-REQUIREMENTS.md`](milestones/v1.1-REQUIREMENTS.md) · Tag: `v1.1`.

## Current Milestone: v1.2 — Standalone Dictation + Model Auto-Update

**Goal:** Make PS Transcribe useful as a standalone dictation tool -- hotkey-triggered capture that writes to clipboard and/or a plain OS folder with no Obsidian/Notion required -- and let the ASR model update without shipping a new app build.

**Dates:** 2026-04-27 → TBD  
**Requirements:** 26 (11 dictation hotkey/clipboard + 5 plain-folder + 10 model auto-update)  
**Phases:** 4 (Phases 16–19)

### Phases

- [x] **Phase 16: Foundation** — Internal scaffolding: lift `LibraryStore`, add `SessionCoordinator` with computed `anySessionActive`, add `SessionType.dictation` + `DictationOutputMode` + `DictationHotkeyMode` enums, add v1.2 `AppSettings` keys, add new `DictationLogger` actor (plain markdown writer, no YAML frontmatter). No user-visible change. (completed 2026-04-27)
- [x] **Phase 17: Model Auto-Update** — `ModelUpdateService` (manifest fetch, version compare, staging download, SHA-256 verify, atomic rename, rollback), `TranscriptionEngine.reloadModels()` hot-swap, Settings > Model section with version display + update badge + "Check for Updates" button + cancellable progress. (completed 2026-04-28)
- [x] **Phase 18: Hotkey Dictation + Plain-Folder Output** — `DictationHotkeyController` (KeyboardShortcuts/`RegisterEventHotKey`, no permissions needed), `DictationCoordinator`, `DictationWindowController` + `DictationHUD` NSPanel, clipboard write with privacy markers, NSOpenPanel folder picker, `DictationLogger` plain-markdown writer, hotkey recorder UI, dictation settings section. (completed 2026-04-28)
- [ ] **Phase 19: Integration & Hardening** — End-to-end validation: mutual exclusion between meeting recording / dictation / model-update apply, model rollback path simulation, privacy-mode HUD verification, SettingsView UX audit (three-folder-picker coherence), full QA checklist.

### Phase Details

#### Phase 16: Foundation

**Goal**: Internal scaffolding is in place so Phases 17 and 18 can compile and build without conflicts
**Depends on**: Nothing (first phase of v1.2)
**Requirements**: None directly — compiler-level prerequisite for all v1.2 phases
**Success Criteria** (what must be TRUE):
  1. App builds cleanly with `SessionType.dictation` and `DictationOutputMode` added to `Models.swift`
  2. All v1.2 `AppSettings` keys are present and compile without warnings
  3. `TranscriptLogger` exposes `startPlainSession` and `finalizePlain` methods with correct actor isolation
  4. `LibraryStore` is initialized at `PSTranscribeApp` scope and injected into `ContentView` with no behavioral regression in the existing session library
  5. `anySessionActive: Bool` flag exists at app scope and is set/cleared correctly by the existing meeting session flow
**Plans:** 4/4 plans complete

- [x] 16-01-PLAN.md — Models.swift enums (SessionType.dictation, DictationOutputMode, DictationHotkeyMode), six switch-site updates, ROADMAP correction, Codable tests (Wave 1)
- [x] 16-02-PLAN.md — Six v1.2 AppSettings keys with didSet UserDefaults mirroring + persistence tests (Wave 2)
- [x] 16-03-PLAN.md — New DictationLogger actor (plain markdown, no YAML frontmatter, millisecond-suffix filenames) + behavior tests (Wave 2)
- [x] 16-04-PLAN.md — LibraryStore lift to PSTranscribeApp + new SessionCoordinator with computed anySessionActive + ContentView injection + manual smoke test (Wave 2; autonomous: false)

#### Phase 17: Model Auto-Update

**Goal**: Users can check for and install FluidAudio model updates from Settings without waiting for a Sparkle app release
**Depends on**: Phase 16
**Requirements**: MODEL-01, MODEL-02, MODEL-03, MODEL-04, MODEL-05, MODEL-06, MODEL-07, MODEL-08, MODEL-09, MODEL-10
**Success Criteria** (what must be TRUE):
  1. User opens Settings > Model and sees the currently installed model version string alongside the latest available version
  2. When a newer model is available, a non-intrusive badge appears in Settings > Model with no modal alerts or push notifications
  3. User taps "Install Update," sees a progress bar, and can cancel mid-download; the active model is unaffected by a cancelled download
  4. After a completed update, the app hot-swaps the model without restarting; the next transcription session uses the new model
  5. A partial or checksum-failing download is rejected; the prior model remains active and the UI surfaces a clear failure reason
**Plans**: TBD
**Research gate**: Resolve "manifest hosting strategy" ADR (project-owned gh-pages manifest vs. HuggingFace refs API) before planning locks. SUMMARY.md recommends project-owned manifest for per-file SHA-256 + `min_app_version` support.

#### Phase 18: Hotkey Dictation + Plain-Folder Output

**Goal**: Users can trigger dictation from any app with a global hotkey, see a live floating HUD, and have the transcript written to clipboard and/or a plain OS folder
**Depends on**: Phase 16
**Requirements**: DICT-01, DICT-02, DICT-03, DICT-04, DICT-05, DICT-06, DICT-07, DICT-08, DICT-09, DICT-10, DICT-11, FOLDER-01, FOLDER-02, FOLDER-03, FOLDER-04, FOLDER-05
**Success Criteria** (what must be TRUE):
  1. User presses `Cmd+Shift+D` in any app (including while PS Transcribe is in the background) and a floating HUD appears within 200ms showing live partial transcription; the menu bar icon pulses to indicate active recording
  2. User stops dictation (second hotkey tap or Escape), the HUD briefly shows "Copied to clipboard," dismisses, and the transcript text is immediately pasteable in the target app; the text does not appear in Alfred, Maccy, or Pasta clipboard history
  3. User configures a plain OS folder in Settings > Dictation; after a dictation session, a clean markdown file (no YAML frontmatter) appears in that folder with a human-readable date-based filename; 10 rapid sessions produce 10 distinct files
  4. User presses Escape or a second hotkey tap during dictation to cancel; no text is written to clipboard and no file is written to the plain folder; sessions longer than 30 seconds prompt for confirmation before cancelling
  5. Attempting to start dictation while a meeting recording is active is a no-op (or shows a brief dismissible notice); there is never more than one active recording session at a time
**Plans:** 8/8 plans complete
- [x] 18-01-PLAN.md — Wave 0 RED test scaffolding (16 test files, Nyquist gate) (Wave 0)
- [x] 18-02-PLAN.md — KeyboardShortcuts dependency + GlobalHotkeyService (Cmd+Shift+D registration) (Wave 1)
- [x] 18-03-PLAN.md — DictationLogger.discardSession() + hasActiveSession (D-08 atomic cancel support) (Wave 1)
- [x] 18-04-PLAN.md — DictationCoordinator skeleton + SessionCoordinator.dictation slot (DICT-11 mutual exclusion) (Wave 2)
- [x] 18-05-PLAN.md — DictationWindowController + DictationHUD (NSPanel + SwiftUI body, sharingType=.none) (Wave 3)
- [x] 18-06-PLAN.md — Full begin/end/cancel flow (clipboard, library, auto-name, fallback) (Wave 4)
- [x] 18-07-PLAN.md — Settings > Dictation section (hotkey recorder, mode picker, folder picker) (Wave 5)
- [x] 18-08-PLAN.md — App-scope wiring (MenuBarExtra pulse, Esc-key monitor, eager pre-warm) (Wave 6)
**UI hint**: yes
### Phase 18.1: Shared save destinations + Local File (INSERTED)

**Goal**: Refactor save destinations into a top-level shared layer (Notion / Obsidian / Local File) so all content producers (meeting recording, voice memo, dictation) emit `(content, sessionType)` to a single `SaveDestinations` fan-out; retire `DictationOutputMode` and the dictation-private folder picker; add Local File destination peer to Notion / Obsidian; collapse Obsidian to a single folder + frontmatter tagging.
**Requirements**: FOLDER-01 (reframed via Local File), FOLDER-02 (Local File `Dictation/` subfolder), FOLDER-03, FOLDER-05, DICT-05 (always-on clipboard), DICT-09 (privacy markers); FOLDER-04 REMOVED (replaced by always-on clipboard + destination fan-out)
**Depends on:** Phase 18
**Plans:** 6/6 plans complete

Plans:
- [x] 18.1-01-PLAN.md — AppSettings rip-and-replace (delete dictationOutputMode/dictationFolderPath/vaultMeetingsPath/vaultVoicePath; add localFileEnabled/localFileRoot/obsidianEnabled/obsidianFolderPath) + delete DictationOutputMode enum + persistence tests (Wave 1)
- [x] 18.1-02-PLAN.md — SaveDestinations + LocalFileWriter + ObsidianWriter + SessionType destination-mapping extension + writer/fan-out tests (Wave 1)
- [x] 18.1-03-PLAN.md — SettingsView restructure (Local File section, single-folder Obsidian, behavior-only Dictation) + SettingsView source-grep tests (Wave 2)
- [x] 18.1-04-PLAN.md — DictationCoordinator refactor (always-on clipboard, SaveDestinations fan-out) + app-scope wiring + zero-destinations dictation test (Wave 2)
- [x] 18.1-05-PLAN.md — ContentView meeting/memo refactor (Local File subfolder routing, D-20 zero-destinations guard, post-session SaveDestinations fan-out) + Notion session-type tests (Wave 2)
- [x] 18.1-06-PLAN.md — Phase 18 sibling test migration sweep + full `swift test` green gate (Wave 3)

#### Phase 19: Integration & Hardening

**Goal**: All v1.2 features interact correctly under realistic edge cases and the app is ready to ship
**Depends on**: Phase 17, Phase 18
**Requirements**: Validates delivery of all 26 v1.2 requirements end-to-end
**Success Criteria** (what must be TRUE):
  1. Starting a meeting recording while a model update download is in-flight does not crash, and the model swap is deferred until the session ends
  2. A simulated bad-checksum model download is rejected with a clear error; the prior model reloads cleanly and transcription continues without restart
  3. The dictation HUD is not captured by legacy `CGWindowListCreateImage` screen capture (the ScreenCaptureKit limitation is documented in test notes, not treated as a bug)
  4. The Settings screen with all three folder pickers (meetings vault, voice memo vault, plain-folder dictation) passes a UX coherence audit: sections are clearly separated, the plain-folder output defaults to `~/Documents/PS Transcribe Dictations/` without requiring user action
  5. The full "Looks Done But Isn't" checklist from PITFALLS.md passes: clipboard history exclusion, file naming collision test (10 rapid dictations), security-scoped bookmark surviving relaunch, mutual exclusion (meeting + dictation), disk-space preflight warning
**Plans**: TBD

### Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 16. Foundation | 4/4 | Complete    | 2026-04-27 |
| 17. Model Auto-Update | 5/5 | Complete    | 2026-04-28 |
| 18. Hotkey Dictation + Plain-Folder Output | 8/8 | Complete   | 2026-04-28 |
| 18.1 Shared save destinations + Local File | 6/6 | Complete    | 2026-04-30 |
| 19. Integration & Hardening | 0/0 | Not started | - |

## Backlog

_Empty — all captured ideas have been promoted into active milestones._
