# Changelog

## [2.1.0] — 2026-04-20

### UX / Redesign — "Quiet Chronicle"
- Three-column shell with Library (270), flex Transcript, and Details (240) columns separated by 0.5pt rule hairlines. Window minimums bumped to 960×640; default 1280×820.
- Native macOS titlebar with centered "PS Transcribe" title via `NSToolbar.centeredItemIdentifier`. Grey RecordingNameField top strip removed; `⌘⇧S` keeps sidebar-toggle accessible.
- Settings window retitled `PS Transcribe - Settings`; Audio Input moved to top of Settings.
- New `DesignTokens.swift` with paper palette, Spacing/Radius/Shadow tokens, Chronicle sans/serif/mono font helpers + reusable text-style modifiers.
- Library sidebar rewritten: bold "Library" header with count, search field, date-grouped (`APR 20`) entries with 22pt icon chips, card-style white selected row with hairline + soft shadow, 10pt inter-item spacing.
- Capture Dock moved into the sidebar footer: status dot (green→red pulsing), `READY` / `RECORDING · MM:SS`, input device label, rolling 16-bar waveform strip while recording. Primary button = video-icon Meeting (dark bg, red stop-circle when recording), secondary = mic-icon Memo (white, 50/50 split).
- Transcript column: new `Transcript` meta label + name header with live meta (`In progress · 12s · 1 speaker`) or archived meta (`Apr 17, 2026 · 1h 12m · 2 speakers`). Inline rename — double-click or right-click → text field auto-selects, commits on Return or focus-loss, Escape cancels.
- Transcript content rewritten as chat bubbles: max 50% column width; "You" right-aligned dark on paper, others left-aligned soft sage. Joining corners flatten when same speaker continues. Timestamps inline, 0.5 opacity.
- Details pane: `DETAILS` label pinned; when entry selected, shows `Saved to` (Folder/File/Duration), `Sent to` (Notion/Obsidian sync status in liveGreen or faint), `Speakers` (word-count percentages parsed off-main).

### Features
- VAD-based auto-stop endpointer replaces the 120s RMS threshold. Uses FluidAudio Silero VAD `speechStart`/`speechEnd` events. Mode-keyed thresholds: voice memo = 6s trailing silence, call capture = 120s. Won't arm until VAD has confirmed at least one speech segment.
- Notion auto-send on recording end, opt-in via new `notionAutoSendEnabled` setting. Posts with empty tags after finalization; users can add tags later via the existing "Resend to Notion" flow (which updates the same page).
- New Obsidian settings section: status dot + vault detection via `obsidianVaultForPath`, Meetings/Voice folder rows with Choose/Remove, guard at session start that aborts with a surfaced error if no Obsidian folder is configured for that session type.

### Fixes / Internals
- Build cache regenerated after repo rename (Tome/PSTranscribe → ps-transcribe/PSTranscribe).
- `TranscriptionEngine` now surfaces `isSpeaking` (mic OR system) and `hasDetectedSpeech` (armed flag) by wiring new `onSpeechActivity` callbacks from both `StreamingTranscriber` instances and the `restartMic` path.

## [2.0.0] — 2026-04-14

### Breaking
- **Tome → PS Transcribe migration removed.** `migrateUserDefaultsIfNeeded()`, its `init()` call site, and the `hasMigratedFromTome` sentinel deleted. Users upgrading from the original Tome binary after this release will no longer have their settings carried over — they must have already upgraded through a v1.x build for their preferences to persist.

### Repo / Distribution
- Renamed GitHub repo `cnewfeldt/Tome` → `cnewfeldt/ps-transcribe`. GitHub redirect covers inbound links.
- `Info.plist` `SUFeedURL` now points at `https://raw.githubusercontent.com/cnewfeldt/ps-transcribe/gh-pages/appcast.xml` (OWNER placeholder removed).
- `release-dmg.yml` OWNER placeholders replaced; stale TODO comments removed.

### Docs
- `README.md` rewritten: title, body, architecture tree, troubleshooting, and clone URL all reference PS Transcribe. Screenshot blocks removed. New **Acknowledgments** section credits the original [Tome](https://github.com/Gremble-io/Tome) repo as the foundation app and OpenGranola as its upstream.

### Milestone
- v1.0 milestone archived. ROADMAP.md and REQUIREMENTS.md moved under `.planning/milestones/v1.0-*.md`; active ROADMAP collapsed to a one-line summary. PROJECT.md updated with Current State / Next Milestone sections. Git tag `v1.0` created and pushed.
- All 45 active v1 requirements satisfied, including REBR-08 verified via live Tome → PS Transcribe upgrade on a test machine.

## [1.4.1] — 2026-04-14

### Housekeeping
- Save-point release. No functional changes.
- Phase 6 (Live LLM Analysis) remains descoped per the 2026-04-04 scope reduction. An execution attempt landed LLM/Ollama code and was fully reverted in the same session once the prior abandonment was reconfirmed.
- Worktree cleanup: pruned stale GSD agent worktrees.

## [1.4.0] — 2026-04-06

### Notion Integration
- KeychainHelper for secure API key storage (save/read/delete via Security framework)
- NotionService actor: connection validation, database validation, transcript-to-blocks conversion, page creation
- Settings UI: 4-state Notion section (not configured, validating, connected, fully configured) with database URL parsing
- NotionTagSheet: tag input with persistence across sends, previously-used tag suggestions
- Context menu: "Send to Notion...", "Open in Notion", "Resend to Notion..." on library entries
- Markdown-to-Notion-blocks converter with heading support (H1/H2/H3) and inline bold parsing
- Adaptive property filtering: skips properties the database doesn't have instead of failing
- Resend updates existing page in-place (properties + content blocks replaced, no duplicates)

### Transcript Management
- Right-click individual transcript utterances to remove them (updates file on disk + Notion page)
- Enhanced delete: removing a library entry also deletes the .md file from disk and archives the Notion page

### Testing
- 10 new tests: 3 KeychainHelper + 7 NotionService (block conversion, speaker extraction, properties)

## [1.3.0] — 2026-04-04

### Scope reduction
- Removed Phase 5 (Ollama integration) and Phase 6 (Live LLM analysis) entirely. PS Transcribe is now scoped to transcription of meetings and voice memos only; LLM analysis of transcripts is out of scope. Full implementation preserved at git tag `archive/llm-analysis-attempt` for future reference.
- Removed Obsidian vault name setting and deep-link buttons from library rows. Recordings are still saved as markdown in the configured vault folders — they just appear as regular files rather than via the `obsidian://` URL scheme.

### Layout
- Replaced `NavigationSplitView` with a hand-rolled `HStack` drawer layout. Eliminates the persistent gap under the custom title bar that `NavigationSplitView`'s internal NSSplitViewController chrome was creating. Animated sidebar toggle with spring transition; divider now lives inside the sidebar so it transitions as one unit.

### Recording indicator
- During active Call Capture, the pulsing green ring now wraps the captured app's actual icon (Zoom, Teams, Chrome, etc.) instead of a generic microphone glyph. Falls back to `mic.fill` for Voice Memo and unknown apps.

### Library management
- Removed inline pencil edit button from library rows — the name area was too cramped to edit comfortably.
- Right-click context menu now provides Rename (native `NSAlert` dialog with a properly-sized text field), Show in Finder, and Delete (removes library entry, leaves the transcript file on disk).

### Onboarding
- Replaced the fake stage-based progress bar (which hardcoded 0.2 / 0.6 / 0.8 values mapped to status strings) with an indeterminate circular spinner. Status text underneath still reports the current stage. More honest representation of what's actually happening during model download.

### Developer tooling
- `scripts/refresh.sh --reset` now wipes the correct paths. Previously it targeted `~/Library/Application Support/PSTranscribe/.checkpoints` (wrong — never existed). Now correctly wipes `PSTranscribe/sessions/` (the real checkpoint location) plus the default vault folders under `~/Documents/PSTranscribe/`.

## [1.2.0] — 2026-03-30
- Upgraded FluidAudio to latest (actor-based AsrManager) — fixes Swift 6 build failures on Xcode 26.4+
- Build script now fails on missing code signing identity instead of silently shipping unsigned
- Added Gatekeeper troubleshooting to README

## [1.1.0] — 2026-03-29
- Multilingual transcription: Parakeet-TDT v3, 25 European languages with auto-detection
- Pinned FluidAudio to 0.12.1

## [1.0.1] — 2026-03-28
- Spectrum visualizer replaces static waveform (reactive bars, peak hold, dynamic glow)
- Visual redesign: warm glass UI, chat-style transcript bubbles
- Pulsing recording indicator, silence countdown, keyboard shortcuts (⌘R, ⌘⇧R, ⌘.)
- Diarization progress messages during post-session processing
- Error visibility and save confirmation banner
- Session cleanup and async handling fixes

## [1.0.0] — 2026-03-24
- Initial release
- Local transcription via Parakeet-TDT v2 on Apple Silicon
- Call capture (mic + system audio) with per-app filtering
- Voice memo mode
- Speaker diarization
- Vault-native .md output with YAML frontmatter
- Sparkle auto-updates
