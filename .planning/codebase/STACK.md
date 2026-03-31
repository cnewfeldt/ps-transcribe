# Technology Stack

**Analysis Date:** 2026-03-30

## Languages

**Primary:**
- Swift 6.2 - Main language for native macOS application

## Runtime

**Environment:**
- macOS 26.0 (macOS Sequoia) minimum
- Native app deployment

**Build System:**
- Swift Package Manager (SwiftPM) - Specified in `Package.swift` as `swift-tools-version: 6.2`

## Frameworks

**Core:**
- SwiftUI - UI framework for views and interface
- AppKit - macOS native integration (windows, menus, file dialogs)
- Observation - Observable pattern for reactive state management
- Combine - Reactive framework

**Audio & Media:**
- AVFoundation - Audio capture, format conversion, device management
- ScreenCaptureKit - System audio capture from applications
- CoreAudio - Low-level audio device enumeration and listeners
- CoreMedia - Audio sample buffer handling

**System:**
- Foundation - Core utilities, file management, date formatting
- os - Logging framework via `Logger`

## Key Dependencies

**Critical:**
- FluidAudio (commit `ea50062`) - Multilingual speech recognition (Parakeet-TDT v3 ASR) and Voice Activity Detection (Silero VAD) models
  - Provides: `AsrManager`, `VadManager`, `AsrModels`, `OfflineDiarizerManager`
  - Models: Parakeet-TDT v3 for streaming transcription, Silero VAD for speech detection, speaker diarization
  - Custom package: https://github.com/FluidInference/FluidAudio.git
  - Location: `Sources/Tome/Transcription/TranscriptionEngine.swift` and `StreamingTranscriber.swift`

- Sparkle (2.7.0+, resolved to 2.9.0) - macOS app update framework
  - Provides: `SPUUpdater`, `SPUStandardUserDriver`
  - Auto-update mechanism with EdDSA signing verification
  - Location: `Sources/Tome/App/AppUpdaterController.swift`

## Configuration

**Environment:**
- macOS System Settings for microphone and screen capture permissions required
- `UserDefaults` for app preferences:
  - `transcriptionLocale` - Language for transcription (default: "en-US")
  - `inputDeviceID` - Selected microphone device (default: system default)
  - `vaultMeetingsPath` - Folder for meeting transcripts
  - `vaultVoicePath` - Folder for voice memo transcripts
  - `hideFromScreenShare` - Privacy toggle for screen sharing visibility

**Build:**
- No external build configuration files detected
- App metadata in `Info.plist` at `Sources/Tome/Info.plist`
- Security entitlements in `Tome.entitlements` enabling:
  - Microphone access (`com.apple.security.device.audio-input`)
  - Screen capture access (`com.apple.security.device.screen-capture`)

## Platform Requirements

**Development:**
- macOS 26.0 or later for building and running
- Swift 6.2 compiler

**Production:**
- macOS 26.0 (Sequoia) or later
- Minimum 48kHz audio sampling for system audio capture
- Local storage for transcripts (configurable paths)

**Deployment:**
- Distributed via GitHub Releases with Sparkle updates
- Update feed: https://raw.githubusercontent.com/Gremble-io/Tome/gh-pages/appcast.xml
- EdDSA public key: `LT2/oCSuJPmnri+6b62DV1WhHxSmWrJ1nZzbAK2ipV4=`

## Architecture Notes

**Offline-First Design:**
- All transcription and diarization runs locally on device
- No API calls, no cloud services, no internet requirement
- Models downloaded and cached on first run

**Audio Processing Pipeline:**
- Dual-stream capture: microphone + system audio
- 16kHz mono Float32 resampling for ASR model compatibility
- VAD chunking: 4096 samples (256ms at 16kHz)
- ASR flush interval: 480,000 samples (~30 seconds) for context

**Data Storage:**
- JSONL format for session logs (ISO8601 timestamps)
- Temporary WAV files for post-session diarization processing
- Configurable vault directories for meeting and voice memo transcripts

---

*Stack analysis: 2026-03-30*
