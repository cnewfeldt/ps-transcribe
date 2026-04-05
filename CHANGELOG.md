# Changelog

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
