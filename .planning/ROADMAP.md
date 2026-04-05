# Roadmap: PS Transcribe v1.0

## Overview

Four phases transform Tome (v1.2.1) into PS Transcribe: start with the rebrand and all UserDefaults migration to establish the new identity, harden security and stability before any feature work ships, build the session library and recording naming that anchors the app's UX, and polish the interaction model with a three-state mic button and model onboarding.

**2026-04-04 scope reduction:** Phases 5 (Ollama Integration) and 6 (Live LLM Analysis) were abandoned. PS Transcribe is scoped to transcription of meetings and voice memos only; LLM analysis of transcripts is not part of the product. See tag `archive/llm-analysis-attempt` for the preserved implementation.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Rebrand** - Rename Tome to PS Transcribe across all code, config, CI, and user settings
- [x] **Phase 2: Security + Stability** - Resolve all 12 SCAN findings and fix crash/data-loss bugs (completed 2026-04-03)
- [ ] **Phase 3: Session Management + Recording Naming** - Session library grid, lifecycle, and flexible recording naming
- [x] **Phase 4: Mic Button + Model Onboarding** - Three-state mic button and first-launch model download flow (completed 2026-04-03)
- [~] **Phase 5: Ollama Integration** - ABANDONED 2026-04-04 (scope reduction; see tag `archive/llm-analysis-attempt`)
- [~] **Phase 6: Live LLM Analysis** - ABANDONED 2026-04-04 (scope reduction; see tag `archive/llm-analysis-attempt`)

## Phase Details

### Phase 1: Rebrand
**Goal**: The app is fully renamed PS Transcribe -- every user-facing string, bundle identifier, package reference, CI workflow, Sparkle feed, and user setting reflects the new name without data loss for existing users
**Depends on**: Nothing (first phase)
**Requirements**: REBR-01, REBR-02, REBR-03, REBR-04, REBR-05, REBR-06, REBR-07, REBR-08
**Success Criteria** (what must be TRUE):
  1. App launches as "PS Transcribe" with the new bundle identifier and no references to "Tome" visible in the UI
  2. Existing user settings (vault paths, device ID, locale) are preserved after upgrading from Tome -- user does not need to re-configure anything
  3. Sparkle update check resolves against the new appcast URL without breaking the update chain
  4. CI builds and releases use PS Transcribe names throughout; no Tome artifact names appear in GitHub Releases
**Plans:** 1/3 plans executed

Plans:
- [x] 01-01-PLAN.md -- Rename directories and update all Swift source content
- [x] 01-02-PLAN.md -- Update Info.plist, build scripts, and CI workflows
- [x] 01-03-PLAN.md -- UserDefaults migration and manual verification

### Phase 2: Security + Stability
**Goal**: All 12 security findings are resolved and the app no longer silently loses transcripts, crashes unrecoverably, or produces wrong timestamps
**Depends on**: Phase 1
**Requirements**: SECR-01, SECR-02, SECR-03, SECR-04, SECR-05, SECR-06, SECR-07, SECR-08, SECR-09, SECR-10, SECR-11, SECR-12, STAB-01, STAB-02, STAB-03, STAB-04
**Success Criteria** (what must be TRUE):
  1. No GH_TOKEN, predictable temp paths, world-readable log files, or unpinned GitHub Actions SHA in CI
  2. All file I/O operations use explicit error handling with rollback -- no silent try? on write/move/delete sequences
  3. After a crash or force-quit mid-session, the next app launch surfaces the incomplete session in the library rather than losing it
  4. Diarization timestamps are correct for sessions that cross midnight -- no negative or wraparound offsets
  5. MicCapture errors appear visibly in the UI -- silent audio failures are not possible
**Plans:** 5/5 plans complete

Plans:
- [x] 02-01-PLAN.md -- CI hardening: token exposure, mktemp, SHA pinning, gitignore, cleanup logging
- [x] 02-02-PLAN.md -- Replace diagLog with os.Logger and fix audio buffer memory clearing
- [x] 02-03-PLAN.md -- TranscriptLogger overhaul: path validation, permissions, atomic writes, try? audit
- [x] 02-04-PLAN.md -- SessionStore and SystemAudioCapture: permissions, temp dir, try? conversions
- [x] 02-05-PLAN.md -- Stability: crash recovery checkpoints, timestamp fix, mic error propagation

### Phase 3: Session Management + Recording Naming
**Goal**: Users have a persistent, browsable library of past recordings with reliable session lifecycle, flexible naming, and direct Obsidian access
**Depends on**: Phase 2
**Requirements**: SESS-01, SESS-02, SESS-03, SESS-04, SESS-05, SESS-06, SESS-07, SESS-08, SESS-09, NAME-01, NAME-02, NAME-03, NAME-04, NAME-05
**Success Criteria** (what must be TRUE):
  1. User sees a grid of all past recordings showing name, date, duration, and file status -- including a "missing" indicator if the file has been moved or deleted
  2. Clicking a library entry loads the transcript; clicking the file path opens it in Finder; clicking the Obsidian link opens it in Obsidian
  3. Stopping a recording saves it to the library and clears the transcript view -- the next recording start creates a fresh session with no risk of overwriting the previous one
  4. Session library persists across app restarts -- no recordings disappear after quitting and relaunching
  5. User can name a recording before starting, rename it mid-session, or rename it later from the library -- unnamed recordings get a date-based filename automatically, and renaming updates the file on disk
**Plans:** 3/4 plans executed

Plans:
- [x] 03-01-PLAN.md -- Data models, LibraryStore actor, TranscriptParser, test infrastructure
- [x] 03-02-PLAN.md -- UI components (LibrarySidebar, LibraryEntryRow, RecordingNameField) and ContentView NavigationSplitView restructure
- [x] 03-03-PLAN.md -- Session lifecycle wiring, name flow, inline rename, Obsidian settings
- [ ] 03-04-PLAN.md -- End-to-end manual verification of all session library features
**UI hint**: yes

### Phase 4: Mic Button + Model Onboarding
**Goal**: The recording interaction is a clear three-state mic button and new users are never stuck with a broken app due to a missing transcription model
**Depends on**: Phase 3
**Requirements**: MICB-01, MICB-02, MICB-03, MICB-04, MICB-05, MICB-06, ONBR-01, ONBR-02, ONBR-03, ONBR-04, ONBR-05
**Success Criteria** (what must be TRUE):
  1. The waveform visualizer is gone -- a mic icon button is the sole recording control, with a pulsing green ring during recording and a red error state when something is wrong
  2. Error state is never silent -- hovering shows a tooltip with the error message, clicking opens settings with the error displayed
  3. On first launch without a transcription model, the app shows a download prompt with a progress indicator -- recording is disabled until the download succeeds or fails with a clear message
**Plans:** 3/3 plans complete

Plans:
- [x] 04-01-PLAN.md -- Engine error aggregation, retry-safe model download, OnboardingView failure/retry, AppSettings lastUsedSessionType
- [x] 04-02-PLAN.md -- MicButton component, ControlBar layout restructure, WaveformView deletion, ContentView wiring
- [x] 04-03-PLAN.md -- Visual verification + ControlBar redesign (session buttons embed mic indicator, expand to full width when recording)
**UI hint**: yes

### Phase 5: Ollama Integration (ABANDONED 2026-04-04)
**Status**: Abandoned during scope reduction. PS Transcribe is scoped to transcription only; LLM integration is out of scope.
**Preserved at**: git tag `archive/llm-analysis-attempt` (full implementation including OllamaService, OllamaState, Settings section, model browse sheet).
**Original goal**: The app detects and connects to a local Ollama instance, exposes its models, and provides a stable decoupled LLM service.

### Phase 6: Live LLM Analysis (ABANDONED 2026-04-04)
**Status**: Abandoned during scope reduction alongside Phase 5. Live analysis during recording conflicts with the product's focus on distraction-free transcription.
**Preserved at**: git tag `archive/llm-analysis-attempt` (AnalysisCoordinator, AnalysisPanel, persistence, full wiring).
**Original goal**: Live side panel surfacing summary / action items / key topics during recording.

## Progress

**Execution Order:**
Phases 1 -> 2 -> 3 -> 4. Phases 5 and 6 abandoned.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Rebrand | 1/3 | In Progress|  |
| 2. Security + Stability | 5/5 | Complete   | 2026-04-03 |
| 3. Session Management + Recording Naming | 3/4 | In Progress|  |
| 4. Mic Button + Model Onboarding | 3/3 | Complete   | 2026-04-03 |
| 5. Ollama Integration | -- | Abandoned  | 2026-04-04 |
| 6. Live LLM Analysis | -- | Abandoned  | 2026-04-04 |
