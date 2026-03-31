# Testing Patterns

**Analysis Date:** 2026-03-30

## Test Framework

**Current Status:**
- **No test targets detected** in `Package.swift` (executable target only)
- **No test files** in `Sources/Tome/`
- **No test configuration** (no XCTest, pytest, or test runner)

**macOS Build Verification:**
The repository uses CI/CD verification only:
```yaml
# .github/workflows/build-check.yml
- name: Build
  working-directory: Tome
  run: swift build
```

Build succeeds on `macos-26` with Swift 6.2 but no automated tests are run.

## Testing Approach

### Current Strategy: Manual Testing + Diagnostics

**Diagnostic Logging for Validation:**

Rather than unit tests, the codebase uses structured diagnostic logging to validate behavior during development and troubleshooting.

In `Sources/Tome/Transcription/TranscriptionEngine.swift`:
```swift
func diagLog(_ msg: String) {
    #if DEBUG
    let line = "\(Date()): \(msg)\n"
    let path = "/tmp/tome.log"
    // ... write to /tmp/tome.log
    #endif
}
```

Usage pattern — logging state transitions with prefixed context tags:
```swift
diagLog("[ENGINE-0] start() called, isRunning=\(isRunning)")
diagLog("[ENGINE-1] loading FluidAudio ASR models...")
diagLog("[ENGINE-2] FluidAudio models loaded")
diagLog("[ENGINE-MIC-SWAP] switching mic from \(currentMicDeviceID) to \(targetMicID)")
```

These logs are written to `/tmp/tome.log` in DEBUG builds and can be inspected for validation:
```bash
tail -f /tmp/tome.log
```

### OS Log Framework (Production)

In `Sources/Tome/Transcription/StreamingTranscriber.swift`:
```swift
private let log = Logger(subsystem: "io.gremble.tome", category: "StreamingTranscriber")

// Info logging for successful operations
log.info("[\(self.speaker.rawValue)] transcribed: \(text.prefix(80))")

// Error logging for failures
log.error("VAD error: \(error.localizedDescription)")
log.error("ASR error: \(error.localizedDescription)")
log.error("Resample error: \(error.localizedDescription)")
```

Accessible via Console.app or command-line:
```bash
log stream --level debug --predicate 'subsystem == "io.gremble.tome"'
```

## Testable Code Patterns

### Dependency Injection

Critical services accept dependencies in initializers, enabling test scenarios:

**TranscriptionEngine:**
```swift
init(transcriptStore: TranscriptStore) {
    self.transcriptStore = transcriptStore
}
```
Consumers can inject a mock `TranscriptStore` in tests (if tests were written).

**StreamingTranscriber:**
```swift
init(
    asrManager: AsrManager,
    vadManager: VadManager,
    speaker: Speaker,
    audioSource: AudioSource = .microphone,
    onPartial: @escaping @Sendable (String) -> Void,
    onFinal: @escaping @Sendable (String) -> Void
)
```
All dependencies passed explicitly; callbacks allow test assertion.

**ContentView:**
```swift
@Bindable var settings: AppSettings
@State private var transcriptStore = TranscriptStore()
@State private var transcriptionEngine: TranscriptionEngine?
```
State initialized in view; in a test scenario, could be injected.

### Error Handling via CustomError Enums

Errors are typed and testable:
```swift
enum TranscriptLoggerError: LocalizedError {
    case cannotCreateFile(String)
    var errorDescription: String? {
        switch self { case .cannotCreateFile(let p): return "Cannot create transcript at \(p)" }
    }
}
```

Example test scenario (not implemented):
```swift
// Hypothetical test
do {
    try await logger.startSession(sourceApp: "Test", vaultPath: "/nonexistent/path", sessionType: .callCapture)
    XCTFail("Should throw cannotCreateFile")
} catch TranscriptLoggerError.cannotCreateFile(let path) {
    XCTAssert(path.contains("nonexistent"))
}
```

### Actor Isolation Makes Concurrency Explicit

Actor boundaries and async/await make concurrency testable:

```swift
actor SessionStore {
    func startSession() { ... }
    func appendRecord(_ record: SessionRecord) { ... }
    func endSession() { ... }
}

// Test code would use:
let store = SessionStore()
await store.startSession()
await store.appendRecord(record)
await store.endSession()
```

Sequential execution is guaranteed; no race conditions without explicit Task spawning.

## Known Testing Gaps

**Unit Testing:**
- No unit tests for business logic (transcription, recording, storage)
- No tests for error handling paths
- No tests for actor isolation or concurrency correctness

**Integration Testing:**
- No end-to-end tests for complete recording flow
- No tests for mic/system audio capture integration
- No tests for FluidAudio ASR/VAD integration

**Visual Testing:**
- SwiftUI views not tested
- No snapshot tests for UI layout or state transitions

## Recommended Testing Structure (If Tests Were Added)

### File Organization

```
Tome/
├── Sources/Tome/
│   ├── App/
│   ├── Audio/
│   ├── Models/
│   ├── Storage/
│   ├── Transcription/
│   └── Views/
└── Tests/
    ├── TranscriptStoreTests.swift
    ├── SessionStoreTests.swift
    ├── TranscriptLoggerTests.swift
    ├── TranscriptionEngineTests.swift
    ├── StreamingTranscriberTests.swift
    └── Fixtures/
        └── TestData.swift
```

### Test Patterns (Hypothetical)

**XCTest with @MainActor:**
```swift
@MainActor
final class TranscriptStoreTests: XCTestCase {
    var sut: TranscriptStore!
    
    override func setUp() {
        super.setUp()
        sut = TranscriptStore()
    }
    
    func testAppendUtterance() {
        let utterance = Utterance(text: "Hello", speaker: .you)
        sut.append(utterance)
        XCTAssertEqual(sut.utterances.count, 1)
        XCTAssertEqual(sut.utterances[0].text, "Hello")
    }
    
    func testClearRemovesAll() {
        sut.append(Utterance(text: "One", speaker: .you))
        sut.append(Utterance(text: "Two", speaker: .them))
        sut.clear()
        XCTAssertTrue(sut.utterances.isEmpty)
    }
}
```

**Actor-based Async Tests:**
```swift
final class SessionStoreTests: XCTestCase {
    var sut: SessionStore!
    
    override func setUp() {
        super.setUp()
        sut = SessionStore()
    }
    
    func testSessionLifecycle() async {
        await sut.startSession()
        let record = SessionRecord(speaker: .you, text: "Test", timestamp: .now)
        await sut.appendRecord(record)
        await sut.endSession()
        // Verify file exists and contains record
    }
}
```

**Error Handling Tests:**
```swift
final class TranscriptLoggerTests: XCTestCase {
    func testStartSessionThrowsOnInvalidPath() async {
        let logger = TranscriptLogger()
        do {
            try await logger.startSession(
                sourceApp: "Test",
                vaultPath: "/invalid/path/that/does/not/exist",
                sessionType: .callCapture
            )
            XCTFail("Should throw")
        } catch TranscriptLoggerError.cannotCreateFile {
            // Expected
        }
    }
}
```

## CI/CD Build Verification

Current workflow in `.github/workflows/build-check.yml`:
```yaml
name: Build Check
on:
  pull_request:
    branches: [main]
jobs:
  build:
    runs-on: macos-26
    steps:
      - uses: actions/checkout@v4
      - name: Select Xcode 26
        run: |
          sudo xcode-select -s /Applications/Xcode_26.app || sudo xcode-select -s /Applications/Xcode.app
          swift --version
      - name: Build
        working-directory: Tome
        run: swift build
```

**Could be extended to:**
```yaml
- name: Build
  working-directory: Tome
  run: swift build

- name: Run Tests
  working-directory: Tome
  run: swift test

- name: Check Logging
  working-directory: Tome
  run: swift build -c debug && grep -r "TODO\|FIXME" Sources/
```

## Validation Approach

Without automated tests, validation occurs through:

1. **Manual Build Verification:** `swift build` succeeds
2. **Diagnostic Logs:** Review `/tmp/tome.log` during development
3. **Runtime Observation:** Use Console.app to observe `os.Logger` output
4. **End-to-End Testing:** Run the app and test recording flows manually
5. **Code Review:** Inspect changes for correctness patterns before merge

---

*Testing analysis: 2026-03-30*
