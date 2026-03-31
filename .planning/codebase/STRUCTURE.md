# Codebase Structure

**Analysis Date:** 2026-03-30

## Directory Layout

```
Tome/
├── Package.swift                    # SwiftPM manifest (Swift 6.2, macOS 15+)
├── Sources/
│   └── Tome/
│       ├── Info.plist              # App metadata (CFBundleVersion, etc.)
│       ├── Tome.entitlements       # Sandbox entitlements (audio, screen capture)
│       ├── App/
│       │   ├── TomeApp.swift       # @main entry point, window/menu setup
│       │   └── AppDelegate.swift   # (nested in TomeApp) window lifecycle
│       ├── Audio/
│       │   ├── MicCapture.swift    # AVAudioEngine microphone capture
│       │   └── SystemAudioCapture.swift  # ScreenCaptureKit system audio
│       ├── Models/
│       │   ├── Models.swift        # Speaker enum, Utterance, SessionRecord types
│       │   └── TranscriptStore.swift   # @Observable transcript state
│       ├── Settings/
│       │   └── AppSettings.swift   # @Observable user preferences, locale, device
│       ├── Storage/
│       │   ├── TranscriptLogger.swift  # Markdown transcript writing (actor)
│       │   └── SessionStore.swift      # JSONL session logging (actor)
│       ├── Transcription/
│       │   ├── TranscriptionEngine.swift   # Dual-stream orchestrator (Observable, MainActor)
│       │   └── StreamingTranscriber.swift  # VAD+ASR pipeline for one stream
│       ├── Views/
│       │   ├── ContentView.swift        # Main UI, session control, state binding
│       │   ├── ControlBar.swift         # Record button, status bar, error display
│       │   ├── TranscriptView.swift     # Scrollable utterance list
│       │   ├── WaveformView.swift       # Real-time audio level visualizer
│       │   ├── SettingsView.swift       # Device, path, and locale preferences
│       │   ├── OnboardingView.swift     # First-run permissions & intro
│       │   └── CheckForUpdatesView.swift # Sparkle update menu item
│       └── Assets/
│           └── Colors.swift         # (if present) SwiftUI color definitions
```

## Directory Purposes

**App:**
- Purpose: Application entry point and lifecycle
- Contains: Main SwiftUI app declaration, AppDelegate, app-level state setup
- Key files: `TomeApp.swift`

**Audio:**
- Purpose: Capture audio from input devices at OS level
- Contains: AVAudioEngine tap-based mic capture, ScreenCaptureKit system audio
- Key files: `MicCapture.swift` (RMS level calculation, device enumeration), `SystemAudioCapture.swift` (SCStream callbacks, WAV buffer)

**Models:**
- Purpose: Core data types and their observable counterparts
- Contains: Value types (Speaker enum, Utterance struct), MainActor-isolated observable stores
- Key files: `Models.swift` (immutable), `TranscriptStore.swift` (mutable state)

**Settings:**
- Purpose: User preferences, persisted and observable
- Contains: @Observable app configuration, UserDefaults binding, locale/device management
- Key files: `AppSettings.swift` (single source of truth for prefs)

**Storage:**
- Purpose: Persist transcripts and session data to disk
- Contains: Actor-based file writers for atomic operations
- Key files: `TranscriptLogger.swift` (markdown + frontmatter), `SessionStore.swift` (JSONL backup)

**Transcription:**
- Purpose: Real-time speech-to-text processing
- Contains: FluidAudio integration, streaming pipeline orchestration, model lifecycle
- Key files: `TranscriptionEngine.swift` (conductor), `StreamingTranscriber.swift` (worker)

**Views:**
- Purpose: SwiftUI UI components
- Contains: Observable view bindings, interactive controls, display logic
- Key files: `ContentView.swift` (parent coordinator), `ControlBar.swift` (record/stop), `TranscriptView.swift` (scrollable list)

**Assets:**
- Purpose: Static resources (colors, strings, images)
- Key files: Color definitions if extracted, or inline in views

## Key File Locations

**Entry Points:**
- `Sources/Tome/App/TomeApp.swift`: SwiftUI @main app definition with WindowGroup, Settings, MenuBarExtra
- `Sources/Tome/Views/ContentView.swift`: Main window body, session orchestration
- `Sources/Tome/App/AppDelegate.swift`: Window lifecycle (screen-share visibility)

**Configuration:**
- `Sources/Tome/Settings/AppSettings.swift`: Persisted user preferences (device ID, vault paths, locale)
- `Package.swift`: Dependency declarations (FluidAudio, Sparkle)
- `Sources/Tome/Info.plist`: App bundle metadata
- `Sources/Tome/Tome.entitlements`: Sandbox permissions (audio input, screen recording)

**Core Logic:**
- `Sources/Tome/Transcription/TranscriptionEngine.swift`: Dual-stream orchestration, model lifecycle
- `Sources/Tome/Transcription/StreamingTranscriber.swift`: VAD + ASR chunk processing
- `Sources/Tome/Audio/MicCapture.swift`: Microphone capture via AVAudioEngine
- `Sources/Tome/Audio/SystemAudioCapture.swift`: System audio via ScreenCaptureKit

**Data Persistence:**
- `Sources/Tome/Storage/TranscriptLogger.swift`: Markdown file writing with YAML frontmatter
- `Sources/Tome/Storage/SessionStore.swift`: JSONL session backup to app support directory
- `Sources/Tome/Models/TranscriptStore.swift`: In-memory transcript state (Observable)

**UI Components:**
- `Sources/Tome/Views/ControlBar.swift`: Record/stop button and status messages
- `Sources/Tome/Views/TranscriptView.swift`: Scrollable transcript display
- `Sources/Tome/Views/WaveformView.swift`: Real-time audio level meter
- `Sources/Tome/Views/SettingsView.swift`: Preferences UI
- `Sources/Tome/Views/OnboardingView.swift`: First-run wizard

## Naming Conventions

**Files:**
- PascalCase for view and model files: `ContentView.swift`, `TranscriptStore.swift`
- PascalCase for domain-specific utilities: `TranscriptionEngine.swift`, `MicCapture.swift`
- `App` dir contains entry points, delegates
- `Views` dir contains SwiftUI struct definitions only
- `Models` dir contains value types and observable stores
- `Audio` dir contains capture implementations
- `Transcription` dir contains streaming pipeline code
- `Storage` dir contains persistence actors

**Directories:**
- Feature/layer grouping with clear separation: `Views/`, `Models/`, `Audio/`, etc.
- Each layer is independent (Audio doesn't import Views, etc.)
- Direction of dependencies flows: Views → State → Engine → Audio/Storage

**Swift Naming:**
- @Observable classes use `TranscriptStore`, not `TranscriptStoreViewModel`
- Actors end in `Manager` if they manage state (`TranscriptLogger` is exception, named for purpose)
- Callbacks as function properties: `onFinal: @Sendable (String) -> Void`
- Private properties prefixed with `_` when wrapped: `_audioLevel`, `_error`
- Thread-safe wrapper classes end in name: `AudioLevel`, `SyncString`

## Where to Add New Code

**New Feature (e.g., real-time translation):**
- Primary code: `Sources/Tome/Transcription/` (new `TranslationEngine.swift`)
- Integration: Pass output through `StreamingTranscriber` callbacks
- Storage: Update `TranscriptLogger` to include translated text field
- Tests: Create alongside implementation if test infrastructure exists

**New Component/Module (e.g., speaker diarization during recording):**
- Implementation: Create in most specific layer
  - If audio-related: `Sources/Tome/Audio/`
  - If transcription-related: `Sources/Tome/Transcription/`
  - If UI-related: `Sources/Tome/Views/`
  - If storage-related: `Sources/Tome/Storage/`
- Example: Streaming diarization would go in `Transcription/`, parallel to `StreamingTranscriber.swift`

**Utilities & Helpers:**
- Shared helpers with no external dependencies: Add to `Models/` as extensions or new file
- Audio utilities (RMS, resampling): Keep in `Audio/` module or `StreamingTranscriber.swift`
- Formatting helpers (time display, speaker labels): Can be inline in view or extract to `Models/`
- Example: `formatTime()` in `ContentView.swift` could be extracted to `Models/Formatting.swift` if reused

**Observable State:**
- New @Observable class: `Sources/Tome/Models/` with MainActor isolation
- Persistence: Add to `AppSettings.swift` if user pref, or create new actor in `Storage/`
- Binding in views: Use `@Bindable` in struct init, or `@State` for local state

**New Audio Device Types:**
- Extend `MicCapture.swift` if another AVAudioEngine source
- Extend `SystemAudioCapture.swift` if another ScreenCaptureKit filter
- Keep device enumeration static methods together

## Special Directories

**`.build/`:**
- Purpose: SwiftPM build artifacts (generated, not committed)
- Generated: Yes
- Committed: No
- Contains: Compiled binaries, intermediate files, dependencies checkouts

**`dist/`:**
- Purpose: Built app bundle for distribution
- Generated: Yes (via `swift build -c release`)
- Committed: No
- Contains: Tome.app with code signature and frameworks

**`~/Documents/Tome/Meetings/` and `~/Documents/Tome/Voice/`:**
- Purpose: User vault directories for storing transcripts
- Generated: Yes (created by app on first save)
- Committed: No
- User-configurable via Settings

**`~/Library/Application Support/Tome/sessions/`:**
- Purpose: JSONL crash recovery logs
- Generated: Yes (during sessions)
- Committed: No
- Contains: `session_YYYY-MM-DD_HH-mm-ss.jsonl` files

**`/tmp/tome_sys_audio_*.wav`:**
- Purpose: Temporary system audio buffer for diarization
- Generated: Yes (during call capture)
- Committed: No
- Cleaned up after diarization or on app exit

**`/tmp/tome.log`:**
- Purpose: Diagnostic logging (DEBUG builds only)
- Generated: Yes
- Committed: No
- Used for troubleshooting audio/transcription issues
