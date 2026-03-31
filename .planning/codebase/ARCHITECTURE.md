# Architecture

**Analysis Date:** 2026-03-30

## Pattern Overview

**Overall:** Concurrent streaming pipeline with Observable state management

**Key Characteristics:**
- Real-time dual-stream audio processing (microphone + system audio via ScreenCaptureKit)
- Actor-based concurrency for thread-safe file I/O and session management
- @Observable pattern for reactive UI state binding
- Streaming VAD (Voice Activity Detection) + ASR (Automatic Speech Recognition) pipeline
- Post-session offline diarization for speaker attribution
- SwiftUI-based macOS app with menu bar and floating window UI

## Layers

**Presentation Layer:**
- Purpose: Render UI state and handle user interactions
- Location: `Sources/Tome/Views/`
- Contains: SwiftUI views for main window, controls, settings, onboarding
- Depends on: `TranscriptStore`, `AppSettings`, `TranscriptionEngine`
- Used by: SwiftUI app lifecycle and event handlers

**Application Coordination:**
- Purpose: Manage app lifecycle, session state, and cross-layer coordination
- Location: `Sources/Tome/App/TomeApp.swift`, `Sources/Tome/App/AppDelegate.swift`
- Contains: Main app entry point, window management, update checks
- Depends on: `TranscriptionEngine`, `AppSettings`, `SessionStore`
- Used by: System (SwiftUI @main app protocol)

**State Management Layer:**
- Purpose: Hold observable state and provide thread-safe access
- Location: `Sources/Tome/Models/TranscriptStore.swift`, `Sources/Tome/Settings/AppSettings.swift`
- Contains: @Observable view models for transcript data and user preferences
- Depends on: Foundation (Observation framework)
- Used by: Views for UI binding, Transcription layer for updates

**Transcription Engine:**
- Purpose: Orchestrate dual-stream audio capture and streaming transcription
- Location: `Sources/Tome/Transcription/TranscriptionEngine.swift`
- Contains: Model loading, stream startup/shutdown, device management, error handling
- Depends on: FluidAudio (ASR/VAD), audio capture modules, transcript store
- Used by: ContentView as the central transcription coordinator

**Audio Capture Layer:**
- Purpose: Capture audio from microphone and system using OS-level APIs
- Location: `Sources/Tome/Audio/MicCapture.swift`, `Sources/Tome/Audio/SystemAudioCapture.swift`
- Contains: AVAudioEngine mic capture, ScreenCaptureKit system audio, audio level calculation
- Depends on: AVFoundation, CoreAudio, ScreenCaptureKit
- Used by: TranscriptionEngine to obtain audio streams

**Streaming Processing Layer:**
- Purpose: Process audio frames through VAD then ASR pipeline
- Location: `Sources/Tome/Transcription/StreamingTranscriber.swift`
- Contains: Chunk-based VAD processing, speech segmentation, ASR inference, resampling
- Depends on: FluidAudio (VAD/ASR managers), AVFoundation for audio conversion
- Used by: TranscriptionEngine spawns two instances (mic and system)

**Storage & Persistence Layer:**
- Purpose: Write transcript data to files and maintain session records
- Location: `Sources/Tome/Storage/TranscriptLogger.swift`, `Sources/Tome/Storage/SessionStore.swift`
- Contains: Markdown transcript writing with frontmatter, JSONL session logging, diarization rewriting
- Depends on: Foundation (file I/O), actor-based concurrency
- Used by: ContentView for session lifecycle

## Data Flow

**Real-Time Transcription (During Session):**

1. User clicks "Start Call Capture" or "Voice Memo" in ControlBar
2. `ContentView.startSession()` initializes `TranscriptionEngine`, `TranscriptLogger`, `SessionStore`
3. `TranscriptionEngine.start()` loads FluidAudio models (ASR + VAD) from disk/download
4. Two parallel streams launch:
   - `MicCapture.bufferStream()` yields audio from input device via AVAudioEngine tap
   - `SystemAudioCapture.bufferStream()` yields audio from ScreenCaptureKit
5. Two `StreamingTranscriber` instances process streams concurrently:
   - Extract float samples from buffers, resample to 16kHz mono if needed
   - Feed 4096-sample (256ms) chunks to VAD state machine
   - Accumulate samples during speech, flush every ~30s for transcription
   - Call `asrManager.transcribe()` on speech segments
6. `onFinal` callback updates `TranscriptStore.utterances` on MainActor
7. `TranscriptLogger` appends utterance to buffer, flushes periodically to markdown file
8. `SessionStore` writes JSONL record for crash recovery
9. UI updates automatically via @Observable binding, waveform animates from audio levels

**Post-Session Diarization (Call Capture only):**

1. User stops recording, `TranscriptionEngine.stop()` waits for transcriber tasks
2. If call capture, `TranscriptionEngine.runPostSessionDiarization()` called
3. Loads buffered system audio WAV from temp directory
4. `OfflineDiarizerManager` processes full audio with speaker clustering
5. Returns segments with (speakerId, startTime, endTime)
6. `TranscriptLogger.rewriteWithDiarization()` parses transcript timestamps, matches to segments
7. Rewrites "Them" labels to specific speaker IDs (Speaker 2, 3, etc.)
8. Updates speaker count in frontmatter

**Frontmatter Finalization:**

1. `TranscriptLogger.finalizeFrontmatter()` called after diarization
2. Calculates total session duration
3. Rewrites YAML frontmatter with duration, speaker list, and context
4. Optionally renames file to include context snippet
5. Returns final file path, displayed in save banner

**State Management:**

- `TranscriptStore`: MainActor-isolated, holds utterances + volatile partial text
- `AppSettings`: MainActor-isolated, persisted to UserDefaults (device ID, paths, locale)
- `TranscriptionEngine`: MainActor-isolated, owns all concurrent tasks and shared models
- `TranscriptLogger`: Actor-based, serializes file writes to prevent races
- `SessionStore`: Actor-based, appends to JSONL atomically

## Key Abstractions

**AudioLevel (Thread-Safe Float):**
- Purpose: Safely share audio RMS level across threads without MainActor overhead
- Examples: `MicCapture._audioLevel`, `SystemAudioCapture._audioLevel`
- Pattern: NSLock-wrapped property for lock-protected read/write

**SyncString (Thread-Safe Optional String):**
- Purpose: Hold async error messages across capture layers
- Examples: `MicCapture._error`
- Pattern: NSLock-wrapped property, used instead of Task { @MainActor } for lightweight errors

**StreamingTranscriber:**
- Purpose: Reusable VAD + ASR pipeline for one stream
- Abstracts away chunking logic, state management, sample format conversion
- Created fresh for each stream, keeps buffer resamplers for efficiency
- Handles fatal error detection and task cancellation

**AsyncStream Continuations:**
- Purpose: Bridge async callbacks from audio engines to async/await pipeline
- Used in `MicCapture.bufferStream()` and `SystemAudioCapture.bufferStream()`
- Allows pull-based consumption of audio frames as they arrive

## Entry Points

**TomeApp:**
- Location: `Sources/Tome/App/TomeApp.swift`
- Triggers: System launch (SwiftUI @main)
- Responsibilities: Define main window, settings window, menu bar, app updater integration

**AppDelegate:**
- Location: `Sources/Tome/App/TomeApp.swift` (nested class)
- Triggers: applicationDidFinishLaunching, NSWindow.didBecomeKeyNotification
- Responsibilities: Apply screen-share visibility settings to all windows

**ContentView:**
- Location: `Sources/Tome/Views/ContentView.swift`
- Triggers: Window appears, view state changes, timer tasks
- Responsibilities: Orchestrate session start/stop, manage concurrent tasks, bind to engine state

## Error Handling

**Strategy:** Immediate MainActor reporting with user-facing messages

**Patterns:**
- Microphone permission check in `TranscriptionEngine.start()` — shows action-required error if denied
- Audio format validation in `MicCapture.bufferStream()` — returns error through continuation.finish()
- FluidAudio model loading failures caught, displayed in `assetStatus` banner
- Streaming transcription errors accumulated (>10 consecutive failures = fatal)
- File write errors in `TranscriptLogger` caught silently (continues to next utterance)
- System audio capture failures don't halt session — only mic transcription proceeds

## Cross-Cutting Concerns

**Logging:** 
- Development: `diagLog()` function writes to `/tmp/tome.log` in DEBUG builds
- Production: os.Logger used in `StreamingTranscriber` and `SystemAudioCapture`
- UI feedback: `TranscriptionEngine.assetStatus` and `lastError` shown in control bar

**Validation:**
- Microphone permissions checked before starting engine
- Audio device ID validated against OS-reported devices
- Audio format sanity checks (sample rate > 0, channels > 0)
- Buffer size sanity before resampling (outputFrames > 0)

**Audio Device Management:**
- `MicCapture.defaultInputDeviceID()` queries OS default
- `CoreAudio` listener installed for default device changes
- User selection (0 = system default, or specific device ID) tracked separately
- Device switch at runtime restarts only mic stream, keeps system audio + models running
