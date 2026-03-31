# External Integrations

**Analysis Date:** 2026-03-30

## APIs & External Services

**None detected.** Tome is designed as a completely offline application with zero external API dependencies.

The application explicitly states in `Sources/Tome/Views/OnboardingView.swift`:
> "A lightweight meeting transcription tool that captures your conversations — all running locally on your Mac. No API keys, no cloud services."

## Data Storage

**Local Filesystem Only:**
- Session transcripts: JSONL format stored in configurable `vaultMeetingsPath` (default: `~/Documents/Tome/Meetings`)
- Voice memo transcripts: JSONL format stored in configurable `vaultVoicePath` (default: `~/Documents/Tome/Voice`)
- Temporary audio buffers: WAV files in system temporary directory (`FileManager.default.temporaryDirectory`)
- Application support directory: `~/Library/Application Support/Tome/sessions/`

**File Formats:**
- `.jsonl` for transcripts - each line is a JSON-encoded `SessionRecord` with `speaker`, `text`, `timestamp` fields
- Session files named: `session_YYYY-MM-DD_HH-mm-ss.jsonl`
- Temporary WAV files for post-session diarization: `tome_sys_audio_[UUID].wav` (cleaned up after processing)

**No external database.** All data persists locally on the user's machine.

**Storage Locations in Code:**
- `Sources/Tome/Storage/SessionStore.swift` - manages JSONL session files
- `Sources/Tome/Settings/AppSettings.swift` - UserDefaults preferences (no external sync)

## Authentication & Identity

**Custom/Local:**
- App identification: Bundle ID `io.gremble.tome`
- Version: 1.2.1 (from `Info.plist`)
- No user accounts, login, or authentication required

**System Permissions:**
- Microphone access via `AVCaptureDevice.authorizationStatus(for: .audio)`
- Screen capture via `ScreenCaptureKit` (macOS native)
- File access via standard macOS file chooser dialogs

## Monitoring & Observability

**Error Tracking:** None

**Logs:**
- Debug logging to `/tmp/tome.log` (only in DEBUG builds)
- Uses `os.Logger` with subsystem `io.gremble.tome` for app lifecycle events
- No remote error reporting or telemetry

**Log Functions:**
- `diagLog()` in `Sources/Tome/Transcription/TranscriptionEngine.swift` - for diagnostic messages during transcription
- `Logger(subsystem: "io.gremble.tome", category: "...")` for structured logging

## CI/CD & Deployment

**Hosting:**
- GitHub repository: https://github.com/Gremble-io/Tome
- Updates distributed via GitHub Releases with Sparkle framework

**Update Mechanism:**
- Sparkle framework handles auto-update checks
- Feed URL: https://raw.githubusercontent.com/Gremble-io/Tome/gh-pages/appcast.xml
- EdDSA signature verification enabled (public key in `Info.plist`)
- Users can toggle automatic update checks in Settings

**CI Pipeline:** Not detected in codebase

**Release Process:**
- Manual builds and releases to GitHub
- Appcast XML file hosted on `gh-pages` branch
- App Management permissions required on macOS for update installation

## Environment Configuration

**No environment variables required.** The app is fully self-contained.

**Configuration via UI:**
- Transcription language/locale (Picker in Settings)
- Microphone device selection (Picker in Settings)
- Output folder paths (File chooser dialogs)
- Privacy toggle for screen share visibility (Toggle in Settings)

**Configuration Storage:**
- All saved to `UserDefaults` (macOS native preferences)
- Keys: `transcriptionLocale`, `inputDeviceID`, `vaultMeetingsPath`, `vaultVoicePath`, `hideFromScreenShare`

## Webhooks & Callbacks

**Incoming:** None

**Outgoing:** None

**Local Event Handlers:**
- System default audio device change listener (`installDefaultDeviceListener()` in `TranscriptionEngine.swift`)
- Window creation observer for screen share visibility in `AppDelegate.applicationDidFinishLaunching()`

## ML/AI Models

**FluidAudio Models (Local):**
- **Parakeet-TDT v3** - Speech-to-text model
  - Multilingual ASR (supports configurable locales)
  - Downloaded on first run: ~1-2GB
  - Cached locally for subsequent runs
  - Streaming mode: processes speech in ~30-second chunks (480,000 samples at 16kHz)

- **Silero VAD** - Voice Activity Detection
  - Detects speech/silence boundaries
  - Chunk-based processing: 4096 samples (256ms at 16kHz)
  - Open-source model bundled with FluidAudio

- **Speaker Diarization Model** - Post-session speaker identification
  - Runs offline on buffered system audio
  - Manages via `OfflineDiarizerManager` in `TranscriptionEngine.swift`
  - Identifies distinct speakers and timestamps

**Model Loading:**
- Location: `Sources/Tome/Transcription/TranscriptionEngine.swift` lines 71-92
- Loading sequence:
  1. `AsrModels.downloadAndLoad(version: .v3)` - downloads/caches models
  2. `AsrManager(config: .default)` - initializes ASR
  3. `VadManager()` - initializes VAD
  4. Error handling with user-visible status messages

## Privacy & Security Notes

**No External Data Transmission:**
- No API keys, tokens, or credentials needed
- No cloud sync, no telemetry, no analytics
- Updates checked only via Sparkle (GitHub-hosted appcast)

**Local Processing:**
- All audio processing: on-device only
- Transcription models run fully locally
- Speaker diarization: post-processing on buffered audio files
- Temporary files cleaned up after diarization

**Security Entitlements:**
- Microphone permission required and explicitly requested
- Screen capture permission for system audio capture
- File system access via standard macOS dialogs (no blanket file access)
- Window sharing visibility controls respect macOS native APIs

---

*Integration audit: 2026-03-30*
