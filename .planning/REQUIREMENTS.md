# Requirements: PS Transcribe

**Defined:** 2026-03-31
**Core Value:** Users can record conversations and voice memos with accurate, private, on-device transcription and get live AI-powered insights without anything leaving their machine.

## v1 Requirements

Requirements for this milestone. Each maps to roadmap phases.

### Rebrand

- [ ] **REBR-01**: App name changed from "Tome" to "PS Transcribe" in all user-facing strings
- [ ] **REBR-02**: Bundle identifier updated across project configuration
- [ ] **REBR-03**: Package.swift target names and module references updated
- [ ] **REBR-04**: Source directory structure renamed (Tome/ to PSTranscribe/)
- [x] **REBR-05**: CI/CD workflows (release-dmg.yml, build-check.yml) reference new names
- [x] **REBR-06**: Sparkle update feed URL and appcast references updated
- [x] **REBR-07**: Info.plist and entitlements updated with new app identity
- [ ] **REBR-08**: UserDefaults migration preserves existing user settings (vault paths, device ID, locale) on first launch after rebrand

### Security

- [ ] **SECR-01**: GH_TOKEN no longer exposed in CI git clone URLs (SCAN-001)
- [x] **SECR-02**: Debug log uses os.Logger instead of world-readable /tmp file (SCAN-002)
- [ ] **SECR-03**: Vault path validated against directory traversal before file creation (SCAN-003)
- [x] **SECR-04**: System audio temp files use restricted permissions and reliable cleanup (SCAN-004)
- [ ] **SECR-05**: CI keychain file created via mktemp instead of predictable path (SCAN-005)
- [x] **SECR-06**: Transcript and session files created with restrictive file permissions (SCAN-006)
- [ ] **SECR-07**: GitHub Actions pinned to commit SHAs (SCAN-007)
- [ ] **SECR-08**: .gitignore includes secret file patterns (.env, *.p12, *.cer, *.pem, *.key) (SCAN-008)
- [ ] **SECR-09**: File I/O operations use explicit error handling with rollback, not try? (SCAN-009)
- [ ] **SECR-10**: Filename sanitization uses whitelist approach for all filesystem-special characters (SCAN-010)
- [x] **SECR-11**: Audio buffer memory cleared with removeAll(keepingCapacity: false) (SCAN-011)
- [ ] **SECR-12**: CI cleanup logs errors instead of suppressing with 2>/dev/null (SCAN-012)

### Stability

- [x] **STAB-01**: App recovers incomplete sessions on next launch (marks as incomplete, surfaces in library)
- [x] **STAB-02**: Diarization timestamps use session-relative offsets, not clock time (fixes midnight crossing bug)
- [x] **STAB-03**: Session finalization (endSession + frontmatter + diarization) is atomic or recoverable
- [x] **STAB-04**: MicCapture errors propagate to UI via TranscriptionEngine.lastError

### Session Management

- [x] **SESS-01**: User sees a library/grid view of all past recordings
- [x] **SESS-02**: Each library entry shows recording name, date, duration, and file status
- [x] **SESS-03**: Clicking a library entry loads the transcript content in the app
- [x] **SESS-04**: Each library entry has a clickable file path to the transcript on disk
- [x] **SESS-05**: Library entries show "missing" indicator if transcript file has been moved or deleted
- [x] **SESS-06**: Each library entry has an Obsidian deep link that opens the transcript in Obsidian
- [ ] **SESS-07**: Stopping a recording clears the transcript view and saves the session to the library
- [ ] **SESS-08**: Starting a new recording creates a fresh session (no overwriting previous content)
- [x] **SESS-09**: Session index persists across app restarts

### Recording Naming

- [x] **NAME-01**: User can set a recording name before starting a recording
- [x] **NAME-02**: User can rename a recording during an active session
- [ ] **NAME-03**: User can rename a recording after it has been saved (from library)
- [x] **NAME-04**: Unnamed recordings fall back to date-based filename
- [ ] **NAME-05**: File on disk renames to match when user changes the recording name

### Mic Button

- [ ] **MICB-01**: Waveform visualizer replaced with a mic icon button
- [ ] **MICB-02**: Idle state shows static mic icon; clicking starts recording
- [ ] **MICB-03**: Recording state shows green pulsing ring animation; clicking stops recording
- [ ] **MICB-04**: Error state shows red mic icon with circle/slash overlay
- [ ] **MICB-05**: Clicking error state opens settings pane with error message displayed
- [ ] **MICB-06**: Hovering error state shows error message as tooltip

### Model Onboarding

- [ ] **ONBR-01**: First launch shows message to download transcription model before recording
- [ ] **ONBR-02**: Download shows a loading/progress indicator
- [ ] **ONBR-03**: Successful download shows success message with close button
- [ ] **ONBR-04**: Failed download shows error message with close button
- [ ] **ONBR-05**: Recording is disabled until model is successfully downloaded

### Ollama Integration

- [ ] **OLMA-01**: App detects whether Ollama is installed and running on the local machine
- [ ] **OLMA-02**: Settings pane shows Ollama connection status (connected/not found/not running)
- [ ] **OLMA-03**: User can browse available Ollama models from within the app
- [ ] **OLMA-04**: User can download/pull Ollama models from within the app with progress indication
- [ ] **OLMA-05**: Ollama operations use 2-second timeout and never block the recording pipeline
- [ ] **OLMA-06**: Ollama requests explicitly set num_ctx to handle long transcripts (not default 4096)

### Live LLM Analysis

- [ ] **LLMA-01**: During recording, a side panel displays alongside the transcript
- [ ] **LLMA-02**: Side panel shows live-updating summary of the conversation so far
- [ ] **LLMA-03**: Side panel shows accumulating action items extracted from the conversation
- [ ] **LLMA-04**: Side panel shows key topics discussed
- [ ] **LLMA-05**: LLM analysis updates periodically as new transcript chunks arrive
- [ ] **LLMA-06**: If Ollama is not available, recording proceeds normally without the analysis panel
- [ ] **LLMA-07**: Analysis results are saved alongside the transcript when the session ends

## v2 Requirements

Deferred to future milestone. Tracked but not in current roadmap.

### Enhanced LLM Features

- **LLMV2-01**: User can ask questions about the transcript via a chat interface
- **LLMV2-02**: User can select different analysis prompts/templates for different meeting types
- **LLMV2-03**: Post-session re-analysis with different or larger models

### Library Enhancements

- **LIBV2-01**: Search across all past transcripts by content
- **LIBV2-02**: Tags/categories for organizing recordings
- **LIBV2-03**: Bulk export of transcripts

## Out of Scope

| Feature | Reason |
|---------|--------|
| Cloud LLM APIs (OpenAI, Anthropic, etc.) | Violates offline-first philosophy; Ollama only |
| Calendar integration / auto-start | Adds complexity and permissions; users start recordings intentionally |
| Mobile/iOS version | macOS-only native app |
| Video recording | Audio transcription is the product |
| Multi-language simultaneous transcription | Single locale per session; ASR model constraint |
| Real-time collaboration / sharing | Single-user app; users share via markdown export |
| Cloud backup / sync | User controls backup via vault path (iCloud, Dropbox) |
| Complex onboarding wizard | Minimal setup; user owns troubleshooting |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| REBR-01 | Phase 1 | Pending |
| REBR-02 | Phase 1 | Pending |
| REBR-03 | Phase 1 | Pending |
| REBR-04 | Phase 1 | Pending |
| REBR-05 | Phase 1 | Complete |
| REBR-06 | Phase 1 | Complete |
| REBR-07 | Phase 1 | Complete |
| REBR-08 | Phase 1 | Pending |
| SECR-01 | Phase 2 | Pending |
| SECR-02 | Phase 2 | Complete |
| SECR-03 | Phase 2 | Pending |
| SECR-04 | Phase 2 | Complete |
| SECR-05 | Phase 2 | Pending |
| SECR-06 | Phase 2 | Complete |
| SECR-07 | Phase 2 | Pending |
| SECR-08 | Phase 2 | Pending |
| SECR-09 | Phase 2 | Pending |
| SECR-10 | Phase 2 | Pending |
| SECR-11 | Phase 2 | Complete |
| SECR-12 | Phase 2 | Pending |
| STAB-01 | Phase 2 | Complete |
| STAB-02 | Phase 2 | Complete |
| STAB-03 | Phase 2 | Complete |
| STAB-04 | Phase 2 | Complete |
| SESS-01 | Phase 3 | Complete |
| SESS-02 | Phase 3 | Complete |
| SESS-03 | Phase 3 | Complete |
| SESS-04 | Phase 3 | Complete |
| SESS-05 | Phase 3 | Complete |
| SESS-06 | Phase 3 | Complete |
| SESS-07 | Phase 3 | Pending |
| SESS-08 | Phase 3 | Pending |
| SESS-09 | Phase 3 | Complete |
| NAME-01 | Phase 3 | Complete |
| NAME-02 | Phase 3 | Complete |
| NAME-03 | Phase 3 | Pending |
| NAME-04 | Phase 3 | Complete |
| NAME-05 | Phase 3 | Pending |
| MICB-01 | Phase 4 | Pending |
| MICB-02 | Phase 4 | Pending |
| MICB-03 | Phase 4 | Pending |
| MICB-04 | Phase 4 | Pending |
| MICB-05 | Phase 4 | Pending |
| MICB-06 | Phase 4 | Pending |
| ONBR-01 | Phase 4 | Pending |
| ONBR-02 | Phase 4 | Pending |
| ONBR-03 | Phase 4 | Pending |
| ONBR-04 | Phase 4 | Pending |
| ONBR-05 | Phase 4 | Pending |
| OLMA-01 | Phase 5 | Pending |
| OLMA-02 | Phase 5 | Pending |
| OLMA-03 | Phase 5 | Pending |
| OLMA-04 | Phase 5 | Pending |
| OLMA-05 | Phase 5 | Pending |
| OLMA-06 | Phase 5 | Pending |
| LLMA-01 | Phase 6 | Pending |
| LLMA-02 | Phase 6 | Pending |
| LLMA-03 | Phase 6 | Pending |
| LLMA-04 | Phase 6 | Pending |
| LLMA-05 | Phase 6 | Pending |
| LLMA-06 | Phase 6 | Pending |
| LLMA-07 | Phase 6 | Pending |

**Coverage:**
- v1 requirements: 53 total
- Mapped to phases: 53
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-31*
*Last updated: 2026-03-31 after initial definition*
