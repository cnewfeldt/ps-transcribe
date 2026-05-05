# Phase 24: Nyquist Sweep -- v1.0 - Pattern Map

**Mapped:** 2026-05-05
**Files analyzed:** 7 new test files + 5 VALIDATION.md edits + 5 cross-referenced existing tests = 17 file-level decisions
**Analogs found:** 16 / 17 (1 partial: workflow YAML file IO has no in-house precedent)

This phase is mechanical audit. Every new test follows an established Swift Testing pattern that already lives in `PSTranscribe/Tests/PSTranscribeTests/`. Only the workflow-YAML file-IO pattern (`String(contentsOf:)` against repo root from a relative path) is new in-house -- flagged in §"No Analog Found".

---

## File Classification

### New Swift Testing Files (D-04: flat layout, behavior-named)

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `PSTranscribe/Tests/PSTranscribeTests/RebrandInfoPlistTests.swift` | test (unit, source assertion) | file-I/O (read Info.plist) | `LibraryStoreTests.swift` (file-IO via tempDir) + `ObsidianURLTests.swift` (`#require` + `URLComponents`) | role-match |
| `PSTranscribe/Tests/PSTranscribeTests/WorkflowSecretsTests.swift` | test (unit, static source assertion) | file-I/O (read `.github/workflows/*.yml`) | None in-house -- closest shape is `LibraryStoreTests.tempDir()` URL construction | partial |
| `PSTranscribe/Tests/PSTranscribeTests/TranscriptLoggerSecurityTests.swift` | test (unit, integration) | file-I/O (tempDir round-trip via actor) | `DictationLoggerTests.swift` | exact |
| `PSTranscribe/Tests/PSTranscribeTests/MidnightOffsetTests.swift` | test (unit, behavioral assertion) | request-response (actor in -> assertion out) | `DictationLoggerTests.swift::appendComputesSessionRelativeOffset` | exact |
| `PSTranscribe/Tests/PSTranscribeTests/CheckpointRoundTripTests.swift` | test (unit, persistence round-trip) | file-I/O (write -> reload) | `LibraryStoreTests.swift::entriesPersistToDiskAndReloadOnInit` | exact |
| `PSTranscribe/Tests/PSTranscribeTests/RecoveredSessionTypeTests.swift` | test (unit, pure function) | request-response (string in -> enum out) | `ObsidianURLTests.swift` | exact |
| `PSTranscribe/Tests/PSTranscribeTests/ErrorPathLoggingTests.swift` | test (unit, static source assertion) | file-I/O (read source files as strings) | None in-house -- closest is `WorkflowSecretsTests.swift` (peer pattern from this phase) | new in-house pattern |

### VALIDATION.md Edits (5 of them)

| File to Edit | Role | Data Flow | Closest Analog | Match Quality |
|--------------|------|-----------|----------------|---------------|
| `.planning/milestones/v1.0-phases/01-rebrand/01-VALIDATION.md` | doc (frontmatter + table flip) | transform (draft/approved -> approved with new audit block) | itself (already `status: approved` 2026-04-27) -- pattern is "add second `## Validation Audit` section dated 2026-05-05" | exact (self-analog) |
| `.planning/milestones/v1.0-phases/02-security-stability/02-VALIDATION.md` | doc | transform (draft -> approved) | `01-VALIDATION.md` post-2026-04-27 frontmatter shape | exact |
| `.planning/milestones/v1.0-phases/03-session-management-recording-naming/03-VALIDATION.md` | doc | transform | `01-VALIDATION.md` | exact |
| `.planning/milestones/v1.0-phases/08-code-defect-fixes/08-VALIDATION.md` | doc | transform | `01-VALIDATION.md` | exact |
| `.planning/milestones/v1.0-phases/10-final-defect-fixes-obsidian-deeplink/10-VALIDATION.md` | doc | transform | `01-VALIDATION.md` | exact |

### Cross-Referenced Existing Tests (no edits, just citations in VALIDATION.md rows)

| Existing File | Reqs Cited | Reason |
|---------------|-----------|--------|
| `ObsidianURLTests.swift` | SESS-06 (Phase 03), 10-SESS-06 | 8 tests already cover `makeObsidianURL` + `obsidianVaultForPath` |
| `LibraryStoreTests.swift` | SESS-09 | `entriesPersistToDiskAndReloadOnInit` test already passes |
| `SpeakerCodableTests.swift` | 08-D-01a | 6 tests cover Speaker.named codable round-trip |
| `TranscriptParserTests.swift` | 08-D-01b, SESS-03 | `otherSpeakerMapsToNamed` + `diarizedSpeakerMapsToNamed` already exist |
| `LibraryEntryTests.swift` | SESS-02, NAME-04 | displayName fallbacks already covered |

---

## Pattern Assignments

### `RebrandInfoPlistTests.swift` (unit, file-I/O)

**Reqs covered:** REBR-01, REBR-02, REBR-04, REBR-06, REBR-07
**Analog:** `LibraryStoreTests.swift` (file-IO + path-from-tempDir pattern) AND `ObsidianURLTests.swift` (`try #require(...)` + URL-shape assertions)

**Imports pattern** (from `LibraryStoreTests.swift:1-3`):
```swift
import Testing
import Foundation
@testable import PSTranscribe
```

**Suite shape -- pure file read, no `.serialized` needed** (from `ObsidianURLTests.swift:5-6`):
```swift
@Suite("RebrandInfoPlistTests")
struct RebrandInfoPlistTests {
```

**Core pattern -- read Info.plist via direct file IO** (Info.plist lives at `PSTranscribe/Sources/PSTranscribe/Info.plist`; `swift test` runs with cwd = `PSTranscribe/`, so relative path is `Sources/PSTranscribe/Info.plist`):
```swift
@Test func bundleNameIsPSTranscribe() throws {
    let url = URL(fileURLWithPath: "Sources/PSTranscribe/Info.plist")
    let data = try Data(contentsOf: url)
    let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
    let name = try #require(plist?["CFBundleName"] as? String)
    #expect(name == "PS Transcribe")
}
```

**`#require` for "must succeed before further assertion"** (from `ObsidianURLTests.swift:16`):
```swift
let result = try #require(url)
#expect(result.scheme == "obsidian")
```

**Notes for planner:**
- CONTEXT.md D-Discretion notes both `Bundle.main` and direct file IO are acceptable. Direct file IO is the safer route -- the test bundle's `Bundle.main` is the test runner, not the app, and `CFBundleName` may not be populated. See "No Analog Found" section.
- One `@Test` per req: 5 reqs => 5 `@Test` methods. REBR-02 also asserts Logger subsystem string at `StreamingTranscriber.swift:13` matches the bundle ID -- this is a static source grep, fold into ErrorPathLoggingTests OR into this file.
- REBR-08 = WITHDRAWN (no test file entry; row in `01-VALIDATION.md` only).

---

### `WorkflowSecretsTests.swift` (unit, static source assertion)

**Reqs covered:** REBR-05, SECR-01, SECR-05, SECR-07, SECR-08, SECR-12
**Analog:** None directly in-house. Closest shape: pure-function file-IO from a relative path. New in-house pattern (flagged below).

**Imports pattern** (lifted from any existing test):
```swift
import Testing
import Foundation
```

**Suite shape -- pure file reads, no `.serialized`:**
```swift
@Suite("WorkflowSecretsTests")
struct WorkflowSecretsTests {

    private func readWorkflow(_ name: String) throws -> String {
        // swift test cwd is PSTranscribe/; .github lives at repo root
        let url = URL(fileURLWithPath: "../.github/workflows/\(name)")
        return try String(contentsOf: url, encoding: .utf8)
    }
```

**Core pattern -- substring + regex assertions on workflow text** (no in-house analog; canonical Swift idiom):
```swift
@Test func noTomeReferencesInBuildCheck() throws {
    let yaml = try readWorkflow("build-check.yml")
    #expect(!yaml.contains("Tome"))
    #expect(!yaml.contains("Gremble"))
    #expect(yaml.contains("working-directory: PSTranscribe"))
}

@Test func noTokenInDownloadURLs() throws {
    let yaml = try readWorkflow("release-dmg.yml")
    #expect(!yaml.contains("x-access-token"))
    #expect(yaml.contains("gh repo clone"))
}
```

**SHA-pin regex pattern (SECR-07)** -- the regression detected in RESEARCH.md:
```swift
@Test func actionsAreSHAPinned() throws {
    let workflows = ["build-check.yml", "release-dmg.yml", "lint-summaries.yml"]
    let pattern = #/uses:\s+actions/[^@]+@([^\s]+)/#
    for name in workflows {
        let yaml = try readWorkflow(name)
        for match in yaml.matches(of: pattern) {
            let ref = String(match.output.1)
            #expect(ref.range(of: #"^[a-f0-9]{40}$"#, options: .regularExpression) != nil,
                    "\(name): action ref '\(ref)' is not a 40-char SHA")
        }
    }
}
```

**Notes for planner:**
- This test is expected to FAIL on `build-check.yml` line 56 (`actions/upload-artifact@v4` -- tag, not SHA) per RESEARCH.md Risk Register. Planner picks: (a) treat as a Phase 24 incidental fix and pin to SHA in same PR, (b) carve out a regex exception, or (c) escalate to a follow-up plan. Recommended: (a), since the fix is one-line and matches Phase 24's audit-truth posture.
- Plan splitting: REBR-05 lives in Phase 24-01's VALIDATION.md; SECR-01/05/07/08/12 live in Phase 24-02's VALIDATION.md. Same file covers both -- the file's `@Test` methods are sliced across plan rows by req-ID, not file boundary.

---

### `TranscriptLoggerSecurityTests.swift` (unit, integration)

**Reqs covered:** SECR-03 (path traversal), SECR-06 (0o600), SECR-09 (atomicRewrite normal-path), SECR-10 (filename sanitization), NAME-02 (setName), NAME-03 (renameFinalized), NAME-05 (file path renames), 08-REBR-03 (frontmatter `source/pstranscribe`)
**Analog:** `DictationLoggerTests.swift` -- canonical match (same target shape, same actor)

**Imports + Suite header** (from `DictationLoggerTests.swift:1-6`):
```swift
import Testing
import Foundation
@testable import PSTranscribe

@Suite("TranscriptLoggerSecurityTests", .serialized)
struct TranscriptLoggerSecurityTests {
```

**`tempDir()` helper** (lift from `DictationLoggerTests.swift:8-13`, rename prefix):
```swift
private func tempDir() throws -> URL {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("TranscriptLoggerSecurityTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}
```

**Path-traversal pattern (SECR-03)** (from `DictationLoggerTests.swift:121-126`):
```swift
@Test func rejectsTraversal() async throws {
    let logger = TranscriptLogger()
    await #expect(throws: TranscriptLoggerError.self) {
        try await logger.startSession(sourceApp: "Teams", vaultPath: "../../../etc", ...)
    }
}
```

**File permissions pattern (SECR-06)** (from `DictationLoggerTests.swift:135-147`):
```swift
@Test func outputFileHasRestrictivePermissions() async throws {
    let dir = try tempDir()
    defer { try? FileManager.default.removeItem(at: dir) }

    let logger = TranscriptLogger()
    try await logger.startSession(...)
    // ... endSession + finalizeFrontmatter
    let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
    let perms = (attrs[.posixPermissions] as? NSNumber)?.intValue ?? 0
    #expect(perms == 0o600)
}
```

**Frontmatter-source assertion (08-REBR-03)** (from `DictationLoggerTests.swift:25-32` -- file-content substring assertion):
```swift
let contents = try String(contentsOf: url, encoding: .utf8)
#expect(contents.contains("- source/pstranscribe"))
#expect(!contents.contains("source/tome"))
```

**Filename sanitization pattern (SECR-10)** (regex assertion shape from `DictationLoggerTests.swift:50`):
```swift
@Test func sanitizesFilenameComponents() async throws {
    let dir = try tempDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    let logger = TranscriptLogger()
    try await logger.startSession(...)
    try await logger.setName("../evil/<script>")
    // Inspect tempDir contents; assert resulting filename is whitelist-conformant.
    let files = try FileManager.default.contentsOfDirectory(atPath: dir.path)
    let candidate = try #require(files.first { $0.contains("evil") || $0.contains("script") })
    #expect(candidate.range(of: #"^[A-Za-z0-9 ._-]+$"#, options: .regularExpression) != nil)
}
```

**Notes for planner:**
- `DictationLogger` and `TranscriptLogger` are sibling actors -- the analog is exact in shape.
- `.serialized` suite per `DictationLoggerTests.swift:5` precedent (FS mutation under tempDir).
- `await #expect(throws:)` is the established async-throwing assertion shape.
- Reqs spread across multiple plans (SECR -> Phase 24-02, NAME -> Phase 24-03, source/pstranscribe -> Phase 24-08). Same file, sliced by row.

---

### `MidnightOffsetTests.swift` (unit, behavioral)

**Reqs covered:** STAB-02
**Analog:** `DictationLoggerTests.swift::appendComputesSessionRelativeOffset` (lines 53-78) -- exact pattern for offset assertion.

**Pattern -- relative-offset assertion via two appends + `Date` arithmetic** (from `DictationLoggerTests.swift:53-78`):
```swift
@Test func midnightBoundaryProducesPositiveOffsets() async throws {
    let dir = try tempDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    let logger = TranscriptLogger()
    try await logger.startSession(...)
    try await Task.sleep(for: .milliseconds(50))
    let sessionT0 = Date().addingTimeInterval(-0.05)
    // Synthesize two timestamps spanning midnight via Date arithmetic
    await logger.appendUtterance(text: "before-midnight", timestamp: sessionT0.addingTimeInterval(5))
    await logger.appendUtterance(text: "after-midnight",  timestamp: sessionT0.addingTimeInterval(65))
    // ... endSession + read file + assert HH:MM:SS regex matches AND offsets are non-negative
    #expect(contents.range(of: #"\(\d{2}:\d{2}:\d{2}\)"#, options: .regularExpression) != nil)
}
```

**Notes for planner:**
- The DictationLogger analog asserts ordering rather than exact offsets due to actor-internal `startTime` capture timing -- same pattern applies here.
- One `@Test`. Pure assertion via TranscriptLogger.appendUtterance round-trip.
- May lift offset math to a small free-function helper at `TranscriptLogger.swift:202-207` if planner wants direct testing -- CONTEXT.md leaves this to discretion. Bias: do NOT lift; use the existing public API (matches D-Discretion "no production code edits unless surfacing a bug").

---

### `CheckpointRoundTripTests.swift` (unit, persistence)

**Reqs covered:** STAB-01 (round-trip part; end-to-end crash recovery WITHDRAWN), STAB-03 (round-trip part)
**Analog:** `LibraryStoreTests.swift::entriesPersistToDiskAndReloadOnInit` (lines 44-59) -- exact pattern.

**Imports + Suite + tempDir** (from `LibraryStoreTests.swift:1-26`):
```swift
import Testing
import Foundation
@testable import PSTranscribe

@Suite("CheckpointRoundTripTests", .serialized)
struct CheckpointRoundTripTests {

    func tempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("CheckpointRoundTripTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
```

**Core round-trip pattern -- write via instance A, reload via instance B** (from `LibraryStoreTests.swift:44-59`):
```swift
@Test func checkpointRoundTrips() async throws {
    let dir = try tempDir()
    defer { try? FileManager.default.removeItem(at: dir) }

    let store1 = SessionStore(directory: dir)
    await store1.writeCheckpoint(...)

    // Fresh instance at same dir -- should load checkpoint from disk
    let store2 = SessionStore(directory: dir)
    let recovered = await store2.scanIncompleteCheckpoints()
    #expect(recovered.count == 1)
    #expect(recovered[0].transcriptPath == ...)
}
```

**Notes for planner:**
- STAB-01 end-to-end (force-quit) = WITHDRAWN. Round-trip portion = UNIT here.
- STAB-03 atomic-finalization end-to-end = WITHDRAWN; checkpoint write+finalize round-trip = UNIT, can fold into same `@Test` or separate.
- Suite is `.serialized` per `LibraryStoreTests.swift` precedent (FS).

---

### `RecoveredSessionTypeTests.swift` (unit, pure function)

**Reqs covered:** 10-D-05 (recoveredType inference)
**Analog:** `ObsidianURLTests.swift` -- pure-function URL test pattern.

**Pattern -- pure-function input/output assertion** (from `ObsidianURLTests.swift:10-22`):
```swift
@Test func voiceMemoPathInferredFromVaultPrefix() {
    let result = recoveredSessionType(
        transcriptPath: "/Users/cary/Vault/VoiceMemos/2026-04-07-foo.md",
        vaultVoicePath: "/Users/cary/Vault/VoiceMemos"
    )
    #expect(result == .voiceMemo)
}

@Test func callCaptureFallback() {
    let result = recoveredSessionType(
        transcriptPath: "/Users/cary/Vault/Calls/2026-04-07-bar.md",
        vaultVoicePath: "/Users/cary/Vault/VoiceMemos"
    )
    #expect(result == .callCapture)
}
```

**Notes for planner:**
- Logic currently inline at `ContentView.swift:325-331`. Planner's call: lift to a small free function (`recoveredSessionType(transcriptPath:vaultVoicePath:) -> SessionType`) for direct test, OR test indirectly via SessionStore round-trip.
- Bias per RESEARCH.md: lift to free function -- the inference is pure and view-independent. Production-code edit is surgical (extract method) and falls within "no behavior change" so does NOT trigger the D-03 escalation rule.
- One `@Test` minimum (or two -- happy + fallback).

---

### `ErrorPathLoggingTests.swift` (unit, static source assertion)

**Reqs covered:** 08-print-removal, SECR-02 (no `/tmp` log), SECR-11 (`removeAll(keepingCapacity: false)`)
**Analog:** `WorkflowSecretsTests.swift` (peer pattern from this phase) -- read source as String, assert substrings. New in-house pattern; flagged.

**Pattern -- read source file as String + substring assertion:**
```swift
@Suite("ErrorPathLoggingTests")
struct ErrorPathLoggingTests {

    private func readSource(_ relativePath: String) throws -> String {
        // swift test cwd is PSTranscribe/
        let url = URL(fileURLWithPath: "Sources/PSTranscribe/\(relativePath)")
        return try String(contentsOf: url, encoding: .utf8)
    }

    @Test func noPrintInErrorPaths() throws {
        let files = [
            "Audio/SystemAudioCapture.swift",
            "Audio/MicCapture.swift",
            "Persistence/SessionStore.swift",
            "Transcription/TranscriptionEngine.swift",
        ]
        for path in files {
            let src = try readSource(path)
            // Coarse assertion: zero unqualified `print(` matches.
            #expect(!src.contains("print("), "\(path) contains a print() call")
        }
    }

    @Test func noTmpLogWrites() throws {
        let src = try readSource("Transcription/TranscriptionEngine.swift")
        #expect(!src.contains("/tmp/tome.log"))
        #expect(!src.contains("/tmp/PSTranscribe"))
    }

    @Test func speechSamplesUsesNoCapacityRetention() throws {
        let src = try readSource("Transcription/StreamingTranscriber.swift")
        #expect(!src.contains("speechSamples.removeAll(keepingCapacity: true)"))
        #expect(src.contains("speechSamples.removeAll(keepingCapacity: false)"))
    }
}
```

**Notes for planner:**
- This is a static-source-grep test class. It's a refactor-tripwire, not a behavioral test -- planner should briefly justify in the test doc-comment why source assertion is the right shape (per RESEARCH.md SECR-02 row: "static absence already proves it").
- Reqs span Phase 24-02 (SECR) and Phase 24-08 (print-removal). Same file, sliced by row.

---

## VALIDATION.md Edit Pattern Assignments

### Frontmatter Pattern

**Analog:** `01-VALIDATION.md` lines 1-9 (post-2026-04-27 audit -- the canonical "approved" shape):
```yaml
---
phase: 1
slug: rebrand
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-01
last_audited: 2026-04-27
---
```

**Apply to:** All 5 VALIDATION.md files. For Phase 24-01 (re-audit), update `last_audited` to 2026-05-XX (Phase 24 completion date) and keep `status: approved` per D-01. For Phases 02/03/08/10, flip:
- `status: draft` -> `status: approved`
- `nyquist_compliant: false` -> `nyquist_compliant: true`
- `wave_0_complete: false` -> `wave_0_complete: true`
- Add `last_audited: 2026-05-XX`

### Per-Task Verification Map Pattern

**Analog:** `01-VALIDATION.md` lines 40-48. Phase 24's draft VALIDATION.md files (`02`, `03`, `08`, `10`) currently have a similar table but with `Test Type: Manual` / `automated` / `CI diff inspection` -- per D-03 those become `unit` or `WITHDRAWN`.

**UNIT row pattern** (modeled on `01-VALIDATION.md:42`):
```markdown
| 24-02-01 | 02 | 1 | SECR-03 | unit | `cd PSTranscribe && swift test --filter TranscriptLoggerSecurityTests/rejectsTraversal` | green |
```

**WITHDRAWN row pattern** (per D-03 -- new shape, no in-house analog yet; this phase establishes it):
```markdown
| 24-02-04 | 02 | 1 | SECR-04 | WITHDRAWN | n/a -- WITHDRAWN | withdrawn | Live capture session required for runtime temp-file location assertion. Source: `02-VERIFICATION.md` SECR-04 row. |
```

Add a "Reason / Source" column or footnote per CONTEXT D-Discretion. Bias: extra column, since each WITHDRAWN row needs its own one-liner.

### Validation Audit Section Pattern

**Analog:** `01-VALIDATION.md` lines 88-115 -- the entire `## Validation Audit 2026-04-27` section, including:
- `| Metric | Count |` summary table (Gaps found / Resolved / Escalated / Document updates)
- `### Audit Method` -- bulleted list of every command re-run with output snippet
- `### Notes` -- prose explaining any anomalies

**Apply to:** All 5 VALIDATION.md files. For Phase 24-01, append a SECOND audit block dated 2026-05-XX below the existing 2026-04-27 block (preserve audit trail). For Phases 02/03/08/10, this is the FIRST audit block.

### Manual-Only Verifications Section -- DELETE per D-03

`01-VALIDATION.md` lines 64-71 carry a `## Manual-Only Verifications` table. Phases 02/03/08/10 drafts also carry one (with ~16 manual rows). Per D-03 (lenient WITHDRAWN, no Manual-Only fallback), this section is **removed entirely** in the Phase 24 edits, and rows that previously lived there migrate to:
- WITHDRAWN row in Per-Task Verification Map (with `Source: 0X-VERIFICATION.md` pointer), OR
- Cross-reference note in Validation Audit `### Notes` subsection.

For Phase 24-01 specifically: the existing Manual-Only block (REBR-01 visual UI inspection, REBR-08 migration runtime) gets removed; REBR-08 row becomes WITHDRAWN; REBR-01 visual inspection cross-references Phase 23 snapshot tests if applicable, else WITHDRAWN.

### Validation Sign-Off Pattern

**Analog:** `01-VALIDATION.md` lines 76-84:
```markdown
- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (no missing references -- existing infra suffices)
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-27 (retroactive audit)
```

**Apply to:** All 5 VALIDATION.md files. Update feedback latency line to "< 90s" (per Phase 23 D-06 / current `swift test` runtime) and approval date to 2026-05-XX.

---

## Shared Patterns

### `tempDir()` helper

**Source:** `DictationLoggerTests.swift:8-13` (canonical) and `LibraryStoreTests.swift:21-26` (variant)
**Apply to:** `TranscriptLoggerSecurityTests.swift`, `CheckpointRoundTripTests.swift`
**Bias per CONTEXT D-Discretion:** inline per-file. Only extract to `Phase24Fixtures.swift` if 3+ tests share helpers AND the helpers go beyond `tempDir()` (e.g., shared session-bootstrap).

```swift
private func tempDir() throws -> URL {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("<SuiteName>-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}
```

### `defer { try? FileManager.default.removeItem(at: dir) }`

**Source:** Every FS-touching test in `DictationLoggerTests.swift` and `LibraryStoreTests.swift`
**Apply to:** Every `@Test` that calls `tempDir()` -- one-liner immediately after the `tempDir()` call:
```swift
let dir = try tempDir()
defer { try? FileManager.default.removeItem(at: dir) }
```

### `@Suite(.serialized)` for FS / actor / shared-state mutation

**Source:** `DictationLoggerTests.swift:5`, `AppSettingsTests.swift:5`
**Apply to:**
- `TranscriptLoggerSecurityTests.swift` -- yes (FS via tempDir, actor)
- `CheckpointRoundTripTests.swift` -- yes (FS via tempDir, actor)
- `MidnightOffsetTests.swift` -- yes (FS via tempDir)
- `RebrandInfoPlistTests.swift` -- no (pure file read of versioned Info.plist)
- `WorkflowSecretsTests.swift` -- no (pure file read)
- `RecoveredSessionTypeTests.swift` -- no (pure function)
- `ErrorPathLoggingTests.swift` -- no (pure file read)

### `await #expect(throws: TranscriptLoggerError.self)` shape

**Source:** `DictationLoggerTests.swift:121-126`
**Apply to:** `TranscriptLoggerSecurityTests.swift` rejection-path tests (SECR-03 traversal, null byte if applicable):
```swift
await #expect(throws: TranscriptLoggerError.self) {
    try await logger.startSession(vaultPath: "../../../etc", ...)
}
```

### `try #require(...)` for "must succeed before further assertion"

**Source:** `ObsidianURLTests.swift:16`
**Apply to:** Any test that extracts a value before further `#expect`:
```swift
let result = try #require(plist?["CFBundleName"] as? String)
#expect(result == "PS Transcribe")
```

### `@MainActor` annotation

**Source:** `AppSettingsTests.swift` -- every UserDefaults-mutating `@Test` carries `@Test @MainActor` (line 28, 35, 42, etc.)
**Apply to:** None of the proposed Phase 24 tests need `@MainActor` (all are actor-isolated background work or pure functions). If a planner ends up touching `AppSettings`, follow this precedent.

### Static-source-grep test pattern (NEW in-house pattern)

**Source:** Establishes itself with `WorkflowSecretsTests.swift` and `ErrorPathLoggingTests.swift` (peer pattern within Phase 24)
**Apply to:** Both files. The pattern:
```swift
private func readSource(_ relativePath: String) throws -> String {
    let url = URL(fileURLWithPath: "<relative-from-PSTranscribe-cwd>/\(relativePath)")
    return try String(contentsOf: url, encoding: .utf8)
}
```
Document the cwd assumption in a header comment in each file -- Swift Testing executes from the package root (`PSTranscribe/`), so `.github/` is at `../`, and `Sources/PSTranscribe/` is at `Sources/PSTranscribe/`.

---

## No Analog Found

These tests establish in-house patterns where no prior analog exists. Planner should add a short doc-comment in each test file explaining the rationale (per CONTEXT D-04's "tests should read as tests of how X works today, not audit-era backfills").

| File / Pattern | Why No Analog | Recommendation |
|----------------|---------------|----------------|
| `WorkflowSecretsTests.swift` -- reading `.github/workflows/*.yml` as `String` from test cwd | Test target has never read repo-root files outside `PSTranscribe/`. Path-from-cwd assumption is brittle. | Header comment documenting `swift test` cwd = `PSTranscribe/`, so `../` reaches repo root. Add explicit `#expect` that the workflow file exists before substring assertions, with a clear failure message. |
| `ErrorPathLoggingTests.swift` -- static source assertion via `String(contentsOf:)` on `Sources/PSTranscribe/*.swift` | First "tripwire" test pattern in this target -- existing tests assert behavior, not source-string contents. | Header comment explaining intent (refactor tripwire for SECR-02/SECR-11/print-removal). |
| `RebrandInfoPlistTests.swift` -- direct `Info.plist` file IO (vs. `Bundle.main`) | The test bundle's `Bundle.main` is the test runner, not the app -- `CFBundleName` may not be populated. CONTEXT D-Discretion left this open; recommendation is now concrete. | Use direct `URL(fileURLWithPath: "Sources/PSTranscribe/Info.plist")` + `PropertyListSerialization`. Document the choice in a header comment ("Bundle.main is the test runner, not the app; read the source-of-truth Info.plist directly"). |
| WITHDRAWN row format in VALIDATION.md | D-03 lenient policy is new -- no prior VALIDATION.md uses `Test Type: WITHDRAWN`. | Phase 24-01 plan (smallest, first per RESEARCH.md ordering) establishes the row shape; subsequent plans copy it. CONTEXT D-Discretion specifies columns: Test Type=WITHDRAWN, req-ID, one-line reason, `Source: 0X-VERIFICATION.md`. |

---

## Cross-Reference Citations (existing tests, no new code)

For VALIDATION.md rows that map to ALREADY-EXISTING test coverage, use this row shape (no new test file written):

```markdown
| 24-03-04 | 03 | 1 | SESS-06 | unit | `cd PSTranscribe && swift test --filter ObsidianURLTests` | green |
```

The `Automated Command` cell points at the existing suite. Validation Audit `### Notes` subsection should call out the cross-reference explicitly: "SESS-06 covered by pre-existing `ObsidianURLTests.swift` (8 tests, no Phase 24 changes); cross-referenced rather than duplicated."

| Existing Test File | Reqs It Closes | Phase 24 Plan(s) That Cite It |
|--------------------|----------------|--------------------------------|
| `ObsidianURLTests.swift` | SESS-06 | 24-03 (SESS-06), 24-10 (10-SESS-06) |
| `LibraryStoreTests.swift` | SESS-09 | 24-03 |
| `SpeakerCodableTests.swift` | 08-D-01a | 24-08 |
| `TranscriptParserTests.swift` | 08-D-01b, SESS-03 | 24-03, 24-08 |
| `LibraryEntryTests.swift` | SESS-02, NAME-04 | 24-03 |

---

## Plan-Level Pattern Summary

For convenience, here is the recommended plan-by-plan file inventory (per RESEARCH.md "smallest first" ordering, CONTEXT D-Discretion bias):

| Plan | Phase Audited | New Test Files | VALIDATION.md Edited |
|------|---------------|----------------|----------------------|
| 24-01 | Phase 01 (Rebrand) | `RebrandInfoPlistTests.swift` (5 `@Test`) | `01-VALIDATION.md` (re-audit per D-01: bump `last_audited`, append second audit block) |
| 24-02 | Phase 10 (Obsidian) | `RecoveredSessionTypeTests.swift` (1-2 `@Test`); cross-ref `ObsidianURLTests.swift` | `10-VALIDATION.md` (draft -> approved) |
| 24-03 | Phase 08 (Defects) | Extends `TranscriptLoggerSecurityTests.swift` (source/pstranscribe `@Test`) + extends `ErrorPathLoggingTests.swift` (print-removal); cross-ref `SpeakerCodableTests.swift` + `TranscriptParserTests.swift` | `08-VALIDATION.md` (draft -> approved) |
| 24-04 | Phase 03 (Session+Naming) | Extends `TranscriptLoggerSecurityTests.swift` (NAME-02/03/05 `@Test`s); cross-ref `LibraryStoreTests.swift` + `LibraryEntryTests.swift` + `TranscriptParserTests.swift` + `ObsidianURLTests.swift` | `03-VALIDATION.md` (draft -> approved) |
| 24-05 | Phase 02 (Security+Stability) | `WorkflowSecretsTests.swift`, `TranscriptLoggerSecurityTests.swift` (file creation point), `MidnightOffsetTests.swift`, `CheckpointRoundTripTests.swift`, `ErrorPathLoggingTests.swift` (file creation point) | `02-VALIDATION.md` (draft -> approved) |

**Note on file creation order:** `TranscriptLoggerSecurityTests.swift` and `ErrorPathLoggingTests.swift` are created in Plan 24-05 (Phase 02 audit, the largest plan), but Plans 24-03 and 24-04 EXTEND these files with additional `@Test` methods. Planner picks: (a) create skeletons in Plan 24-01 / 24-02 even if their reqs land in later plans, OR (b) reorder to put 24-05 first. Bias: (a) -- preserves "smallest first" execution order; skeleton-then-extend is a clean Git history.

---

## Metadata

**Analog search scope:**
- `PSTranscribe/Tests/PSTranscribeTests/` (flat layout — 18 files)
- `.planning/milestones/v1.0-phases/01-rebrand/01-VALIDATION.md` (canonical approved shape)
- `.planning/phases/23-visual-regression-infra/23-VALIDATION.md` (recent draft shape)

**Files scanned:** 9 (`DictationLoggerTests.swift`, `LibraryStoreTests.swift`, `AppSettingsTests.swift`, `ObsidianURLTests.swift`, `SpeakerCodableTests.swift`, `SnapshotFixtures.swift`, `01-VALIDATION.md`, `02-VALIDATION.md`, `23-VALIDATION.md`)

**Pattern extraction date:** 2026-05-05
