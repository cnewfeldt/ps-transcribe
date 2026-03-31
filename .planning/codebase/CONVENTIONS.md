# Coding Conventions

**Analysis Date:** 2026-03-30

## Language & Version

**Swift 6.2** (macOS 26 deployment) with Swift 6 strict concurrency enabled.

## Naming Patterns

**Files:**
- PascalCase for types: `TranscriptionEngine.swift`, `MicCapture.swift`, `AppSettings.swift`
- Describe purpose clearly: `TranscriptLogger.swift`, `StreamingTranscriber.swift`
- Location groups functionality: `Sources/Tome/Transcription/`, `Sources/Tome/Audio/`, `Sources/Tome/Storage/`

**Types (Classes, Structs, Enums):**
- PascalCase: `TranscriptStore`, `SessionRecord`, `Speaker`, `SessionType`
- Enums use lowercase cases: `case you`, `case them` in `enum Speaker`
- Enums use lowercase cases: `case callCapture`, `case voiceMemo` in `enum SessionType`
- Final classes for observable state: `final class TranscriptionEngine`, `final class SessionStore`

**Functions & Methods:**
- camelCase: `startSession()`, `bufferStream()`, `normalizedRMS()`, `runPostSessionDiarization()`
- Action verbs for imperative: `start`, `stop`, `append`, `clear`, `extract`, `install`, `remove`
- Query methods use nouns: `audioLevel`, `audioLevel:`, `captureError`

**Variables:**
- camelCase for instance/local: `transcriptStore`, `assetStatus`, `isRunning`, `lastError`
- Computed properties use noun phrases: `audioLevel`, `isRunning`, `topBarStatus`
- Private state prefixed with underscore: `_audioLevel`, `_error` (used for thread-safe wrappers)
- Volatile/temporary state named explicitly: `volatileYouText`, `volatileThemText` (partial transcription buffers)

**Constants:**
- Screaming snake_case for constants inside functions/closures: `vadChunkSize = 4096`, `flushInterval = 480_000`
- When extracted to file level, PascalCase or screaming: `conferencingBundleIDs` (private file-level dict)

**Properties:**
- Use `didSet` observers for automatic UserDefaults sync: `transcriptionLocale { didSet { UserDefaults.standard.set(...) } }`
- Private stored properties: `private(set) var utterances: [Utterance]` for read-only outside module

## Code Style

**Formatting:**
- No enforced formatter (no .swiftformat or swiftlint config detected)
- Spacing: 4-space indentation observed
- Line breaks: Logical grouping with blank lines between logical sections
- MARK comments: Used to divide major sections: `// MARK: - Top Bar`, `// MARK: - Helpers`

**Comments:**
- Doc comments on public types and functions explain purpose
- Comments describe *why*, not what code does
- Inline comments for complex logic only
- Example from `TranscriptionEngine.swift`:
  ```swift
  /// Dual-stream mic + system audio transcription.
  @Observable
  @MainActor
  final class TranscriptionEngine { ... }
  ```
- Status/progress logging via `diagLog()` function for DEBUG builds only

**Error Handling:**

Three patterns used:

1. **Custom Error Types:** Defined as enums conforming to `LocalizedError`
   ```swift
   enum TranscriptLoggerError: LocalizedError {
       case cannotCreateFile(String)
       var errorDescription: String? { ... }
   }
   ```
   Example file: `Sources/Tome/Storage/TranscriptLogger.swift`

2. **Result Assignment via `try?`:** Silent failures acceptable for non-critical operations
   ```swift
   try? fileHandle?.close()
   try? FileManager.default.createDirectory(at: sessionsDirectory, withIntermediateDirectories: true)
   ```
   Used when: file cleanup, optional initialization, fallback to defaults
   
3. **Propagated Errors via `throws`:** Critical paths throw to caller
   ```swift
   func startSession(sourceApp: String, vaultPath: String, sessionType: SessionType = .callCapture) throws
   ```
   Caller handles with `do/catch` in async context:
   ```swift
   do {
       try await transcriptLogger.startSession(...)
   } catch {
       transcriptionEngine?.lastError = error.localizedDescription
   }
   ```

4. **State-Based Error Tracking:** UI-facing errors stored as optional strings
   ```swift
   var lastError: String? // In @Observable TranscriptionEngine
   // Set in error paths: lastError = "Failed to load models: \(error.localizedDescription)"
   // Display in UI via ControlBar(errorMessage: engine.lastError)
   ```

## Concurrency Patterns

**Swift 6 Strict Concurrency:**

- **Actors for Isolation:** Mutable state protected by actor boundaries
  ```swift
  actor SessionStore { ... }  // in Sources/Tome/Storage/SessionStore.swift
  actor TranscriptLogger { ... }  // in Sources/Tome/Storage/TranscriptLogger.swift
  ```
  All public methods are `async`, callers must `await`.

- **MainActor for UI State:**
  ```swift
  @MainActor
  @Observable
  final class TranscriptionEngine { ... }
  
  @Observable
  @MainActor
  final class TranscriptStore { ... }
  
  @Observable
  @MainActor
  final class AppSettings { ... }
  ```
  Properties auto-sync to MainThread via Observation framework.

- **Sendable Constraints:** Callbacks and closures marked `@Sendable` for Thread Safety
  ```swift
  private let onPartial: @Sendable (String) -> Void
  private let onFinal: @Sendable (String) -> Void
  ```
  Example: `Sources/Tome/Transcription/StreamingTranscriber.swift`

- **@unchecked Sendable:** Used for types wrapping non-Sendable OS APIs
  ```swift
  final class MicCapture: @unchecked Sendable {
      private let engine = AVAudioEngine()  // non-Sendable
      private let _audioLevel = AudioLevel()  // custom Sendable wrapper
  }
  ```
  Manual synchronization via NSLock:
  ```swift
  final class AudioLevel: @unchecked Sendable {
      private var _value: Float = 0
      private let lock = NSLock()
      var value: Float {
          get { lock.withLock { _value } }
          set { lock.withLock { _value = newValue } }
      }
  }
  ```

- **Task.detached for Background Work:**
  ```swift
  micTask = Task.detached {
      let hadFatalError = await micTranscriber.run(stream: micStream)
      if hadFatalError { reportMicError(...) }
  }
  ```
  Tasks cancelled and awaited on cleanup:
  ```swift
  let mic = micTask
  micTask = nil
  _ = await mic?.value
  ```

- **Task { @MainActor in } for MainThread Updates from Background:**
  ```swift
  Task { @MainActor in
      store.volatileYouText = text  // Update observable from background task
  }
  ```

## Import Organization

**Order:**
1. Framework imports (SwiftUI, AppKit, Foundation, etc.)
2. Third-party packages (FluidAudio, Sparkle)
3. Observation/concurrency frameworks (Observation, os)

**Example from TranscriptionEngine.swift:**
```swift
import AVFoundation
import CoreAudio
import FluidAudio
import Observation
import os
```

**Example from StreamingTranscriber.swift:**
```swift
@preconcurrency import AVFoundation
import FluidAudio
import os
```

The `@preconcurrency` modifier suppresses warnings from non-Sendable APIs; used when wrapping OS frameworks.

## Access Control

**Module-level defaults:**
- Private properties by default: `private let engine = AVAudioEngine()`
- Private methods: `private func ensureMicrophonePermission() async -> Bool`
- Public only what's needed for consumers
- `private(set)` for properties that should be read-only outside: `private(set) var utterances: [Utterance]`

**File-level constants:**
- `private let conferencingBundleIDs: [String: String] = [...]` for view-local data

## Debugging & Logging

**Diagnostic Logging (DEBUG only):**
```swift
func diagLog(_ msg: String) {  // in TranscriptionEngine.swift
    #if DEBUG
    let line = "\(Date()): \(msg)\n"
    let path = "/tmp/tome.log"
    if let fh = FileHandle(forWritingAtPath: path) {
        fh.seekToEndOfFile()
        fh.write(line.data(using: .utf8)!)
        fh.closeFile()
    } else {
        FileManager.default.createFile(atPath: path, contents: line.data(using: .utf8))
    }
    #endif
}
```
Called as `diagLog("[ENGINE-1] loading FluidAudio ASR models...")` — prefixed with context tags.

**OS Log Framework:**
```swift
private let log = Logger(subsystem: "io.gremble.tome", category: "StreamingTranscriber")
// ...
log.info("[\(self.speaker.rawValue)] transcribed: \(text.prefix(80))")
log.error("ASR error: \(error.localizedDescription)")
```
Used in `StreamingTranscriber.swift` for permanent error/info logging.

## SwiftUI Patterns

**Observable Macro for State:**
```swift
@Observable
@MainActor
final class TranscriptStore { ... }
```
Consumed via `@Bindable` in views:
```swift
@Bindable var settings: AppSettings
```

**State Mutations in Tasks:**
```swift
.task {
    while !Task.isCancelled {
        try? await Task.sleep(for: .milliseconds(100))
        // Update state
        audioLevel = engine.audioLevel
    }
}
```

**Computed Properties for Derived State:**
```swift
private var isRunning: Bool {
    transcriptionEngine?.isRunning ?? false
}
```

---

*Convention analysis: 2026-03-30*
