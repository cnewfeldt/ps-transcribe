# Testing Patterns

**Analysis Date:** 2026-03-30 (refreshed 2026-05-04 for Phase 23)

## Test Framework

**Current Status:**
- **Swift Testing test target** declared in `PSTranscribe/Package.swift` (`.testTarget("PSTranscribeTests")`)
- **18+ test files** in `PSTranscribe/Tests/PSTranscribeTests/` covering AppSettings, DictationLogger, Keychain, LibraryStore, ModelManifest, ModelUpdateService, NotionService, ObsidianURL, SessionCoordinator, transcript parsing, and (Phase 23) visual regression
- **Framework:** Swift Testing (`import Testing` + `@Suite` + `@Test`); some suites use `.serialized` for shared-state mutation
- **Convention:** `@testable import PSTranscribe`, per-test `defer` for cleanup, `Issue.record` for soft-fail messaging

**macOS Build + Test Verification:**
```yaml
# .github/workflows/build-check.yml
- name: Build
  working-directory: PSTranscribe
  run: swift build
- name: Test
  working-directory: PSTranscribe
  run: swift test
```

Build + test run on `macos-26` with Swift 6.2 + Xcode 26.

## Testing Approach

### Current Strategy: Manual Testing + Diagnostics

**Diagnostic Logging for Validation:**

Rather than unit tests, the codebase uses structured diagnostic logging to validate behavior during development and troubleshooting.

In `Sources/PSTranscribe/Transcription/TranscriptionEngine.swift`:
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

In `Sources/PSTranscribe/Transcription/StreamingTranscriber.swift`:
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
PSTranscribe/
├── Sources/PSTranscribe/
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
        working-directory: PSTranscribe
        run: swift build
      - name: Test
        working-directory: PSTranscribe
        run: swift test
```

Phase 23 extended this with a record-mode guard step (fail-fast if `SNAPSHOT_TESTING_RECORD` is set in the runner env), `SNAPSHOT_ARTIFACTS=$RUNNER_TEMP/snapshot-failures` env on the build job, and an `if: failure()` step that uploads `snapshot-failures/` via `actions/upload-artifact@v4` (7-day retention).

## Validation Approach

Without automated tests, validation occurs through:

1. **Manual Build Verification:** `swift build` succeeds
2. **Diagnostic Logs:** Review `/tmp/tome.log` during development
3. **Runtime Observation:** Use Console.app to observe `os.Logger` output
4. **End-to-End Testing:** Run the app and test recording flows manually
5. **Code Review:** Inspect changes for correctness patterns before merge

## Visual Regression

Phase 23 (v1.3) added a snapshot test suite at `PSTranscribe/Tests/PSTranscribeTests/VisualRegressionTests.swift` covering 5 macOS surfaces across 3 appearance variants (15 baselines total).

### Surfaces

| Surface | Source | Canonical frame |
|---------|--------|-----------------|
| ContentView | `Sources/PSTranscribe/Views/ContentView.swift` | 1280 x 820 |
| LibrarySidebar | `Sources/PSTranscribe/Views/LibrarySidebar.swift` | 280 x 600 |
| SettingsView | `Sources/PSTranscribe/Views/SettingsView.swift` | 520 x 400 |
| ControlBar | `Sources/PSTranscribe/Views/ControlBar.swift` | 800 x 56 |
| DictationHUD | `Sources/PSTranscribe/Views/DictationHUD.swift` | 560 x 120 |

### Appearance variants

- **Light:** `.preferredColorScheme(.light)` on the test wrapper
- **Dark:** `.preferredColorScheme(.dark)` on the test wrapper
- **System:** `NSApp.appearance = NSAppearance(named: .aqua)` for the test duration (no `.preferredColorScheme`); validates that views resolve color scheme from `NSApp.effectiveAppearance` when no explicit override is set

### Strict precision

Baselines are compared at `precision: 1.0`, `perceptualPrecision: 0.99` (Phase 23 D-02). The product invariant: a real visual change must cause a baseline regen, not silently pass. Per-test loosening is allowed only with documented justification in the test body comment. See `.planning/phases/23-visual-regression-infra/23-ADR-snapshot-framework.md` for rationale.

### Baseline storage

Baseline PNGs live at `PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/` and are committed to `main`. No git LFS (~750 KB total expected for 15 PNGs).

### Regenerate baselines locally

After a legitimate UI change:

```bash
cd PSTranscribe
SNAPSHOT_TESTING_RECORD=all swift test --filter VisualRegression
```

Then `git add` the changed PNGs and include them in the same PR as the source change. The reviewer eyeballs the diff in the PR.

The env var accepts `all | failed | missing | never` -- NOT `true`. Common modes:

| Value | Behavior |
|-------|----------|
| `all` | Always overwrite baselines on every test run |
| `failed` | Overwrite a baseline only when the test fails the diff |
| `missing` | Write a baseline only when none exists on disk (suite default) |
| `never` | Never write; fail the test if a baseline is missing or differs |

### CI behavior

`.github/workflows/build-check.yml` runs `swift test` on every PR against `main`. The `VisualRegression` suite is part of the run. CI fails fast if `SNAPSHOT_TESTING_RECORD` is set in the runner env (prevents silent baseline overwrite). On test failure, snapshot diff PNGs are uploaded as a `snapshot-failures` artifact (7-day retention).

`release-dmg.yml` does NOT run tests -- the test gate is the PR-merge surface only.

### See also

- `CONTRIBUTING.md` -- developer-facing summary of the regen workflow
- `.planning/phases/23-visual-regression-infra/23-ADR-snapshot-framework.md` -- framework choice rationale

---

*Testing analysis: 2026-03-30*
*Visual Regression section added: 2026-05-04 (Phase 23)*
