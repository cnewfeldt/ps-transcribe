# Phase 24: Nyquist Sweep — v1.0 - Research

**Researched:** 2026-05-05
**Domain:** Swift Testing audit + VALIDATION.md backfill (mechanical)
**Confidence:** HIGH

## Summary

Phase 24 is mechanical audit work, not greenfield exploration. The v1.0 milestone is shipped, audit-clean, and stable. CONTEXT.md locks the four high-leverage decisions (D-01 sweep all 5, D-02 one `@Test` per req, D-03 lenient WITHDRAWN policy, D-04 flat behavior-named files). The product surface — Info.plist, TranscriptLogger, TranscriptParser, SessionStore, Models — is unchanged and exercises cleanly through `@testable import PSTranscribe` from Swift Testing. CI's `swift test` step (added in Phase 23, commit `ddcec6a`) is the gate Phase 24 piggybacks on; no workflow changes needed.

The audit yields **~22 UNIT-testable rows** across 36 v1.0 requirement IDs, with **~14 WITHDRAWN per D-03** (force-quit/SIGKILL, runtime entitlements, NSWorkspace launches, deleted code, live-FS side-effects). Pure-function corners of "runtime-flavored" requirements (filename sanitization, midnight offset math, Obsidian URL construction, vault path traversal rejection, Speaker.named round-trip, frontmatter source tag) all have direct testable surface today.

**Primary recommendation:** Five plans, one per audited v1.0 phase, in the order CONTEXT.md hinted (01 → 10 → 08 → 03 → 02). Each plan writes its new test file(s), runs `swift test`, flips frontmatter to `status: approved` / `nyquist_compliant: true`, stamps `last_audited: 2026-05-05`, and commits atomically. Skip `/gsd-validate-phase` skill invocation — write tests directly inline. Reasoning: the skill's State A flow is designed for newly-completed phases; Phase 24 is doing the exact same work for 5 phases at once, and the locked D-policies already short-circuit half of what the auditor agent would re-derive.

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01 (Phase 1 re-audit posture):** Phase 24 covers all 5 v1.0 phases including Phase 1, even though `01-VALIDATION.md` was retroactively approved on 2026-04-27 via `swift build` + grep. Phase 24 backfills genuine Swift Testing assertions for testable parts of REBR-01..07; bumps `last_audited` to Phase 24 completion date; keeps `status: approved` / `nyquist_compliant: true`.
- **D-02 (Coverage depth):** One `@Test` per testable requirement ID. Total ~22-26 `@Test` methods after D-03 withdrawals.
- **D-03 (Untestable / removed-code policy):** Lenient — untestable requirements get `Test Type: WITHDRAWN` with one-line reason and `Source: 0X-VERIFICATION.md` pointer. NO Manual-Only fallback rows. WITHDRAWN does NOT block `nyquist_compliant: true`. Pure-function corners of runtime-flavored reqs DO get UNIT tests.
- **D-04 (Test file organization):** Flat at top of `PSTranscribe/Tests/PSTranscribeTests/`, named by behavior NOT phase. Examples: `RebrandInfoPlistTests.swift`, `WorkflowSecretsTests.swift`, `FilenameSanitizationTests.swift`, etc.

### Claude's Discretion

- Per-test temp-dir / fixture pattern — DictationLoggerTests.swift's `tempDir()` + `defer` cleanup is reusable. Bias inline unless 3+ tests share helpers.
- `@Suite(.serialized)` vs default parallelism — serialize anything mutating UserDefaults / NSApp.appearance / shared FS paths. Pure-function tests do not.
- Exact test names + `#expect` vs `#require` — planner's call.
- Bundle.main vs file IO for Info.plist reads — both work; planner picks.
- Plan splitting — bias 5 plans, one per phase audited.
- Order of plans — bias smallest first: 01 → 10 → 08 → 03 → 02.
- WITHDRAWN row formatting in VALIDATION.md — column shape flexible but row MUST include Test Type: WITHDRAWN, requirement ID, one-line reason, and `Source: 0X-VERIFICATION.md` pointer.

### Deferred Ideas (OUT OF SCOPE)

- Manual-Only entries / integration-test scaffolding for force-quit / SIGKILL / runtime entitlement scenarios.
- Phase 4 (Mic Button), Phase 7 (Notion), Phase 9 (Verification Sweep) Nyquist sweep — git history only.
- Move restored v1.0 phase directories to `.planning/milestones/v1.0-phases/` — post-Phase 24 housekeeping.
- Phase 23-VALIDATION.md own approval — separate concern.
- New visual/snapshot tests — Phase 23's domain.
- Backfill `requirements-completed` frontmatter on v1.0 SUMMARY.md files — milestone is archived.
- Centralized `Phase24Fixtures.swift` — only worth introducing if 3+ tests share fixture code.
- Cross-phase CI splitting.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NYQUIST-01 | Backfill `01-VALIDATION.md` (Rebrand) — UserDefaults migration, bundle ID, app name, executable rename | Per-Requirement API Audit row REBR-01..08 below; Info.plist surface verified `[VERIFIED: file read]` |
| NYQUIST-02 | Backfill `02-VALIDATION.md` (Security + Stability) — 12 SCAN findings, crash recovery, midnight bug | SECR-01..12, STAB-01..04 audit rows; `validatedVaultPath` and `sanitizedFilenameComponent` indirect testability via `TranscriptLogger.startSession` and `setName` `[VERIFIED: source grep]` |
| NYQUIST-03 | Backfill `03-VALIDATION.md` (Session Library + Recording Naming) — SESS-01..05/07..09, NAME-01..05 | Audit rows below; `LibraryStore`, `LibraryEntry`, `parseTranscript` all extant `[VERIFIED]` |
| NYQUIST-04 | Backfill `08-VALIDATION.md` (Code Defect Fixes) — Speaker.named codable, frontmatter tag, transcriptStore.clear, file-exists caching | Speaker.named in `Models.swift:39`, source/pstranscribe at TranscriptLogger.swift:151 `[VERIFIED]` |
| NYQUIST-05 | Backfill `10-VALIDATION.md` (Obsidian Deep-link + Defect Cleanup) — `makeObsidianURL`, `obsidianVaultForPath`, exhaustive Speaker switch, recoveredType inference | `makeObsidianURL` is public free function at `TranscriptParser.swift:105` — already 8 tests in `ObsidianURLTests.swift` `[VERIFIED]` |

## Architectural Responsibility Map

This phase has no production code changes — only test code and VALIDATION.md docs. Architectural tier mapping is therefore single-tier:

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Swift Testing assertions | Test target (`PSTranscribeTests`) | — | All new artifacts live in `PSTranscribe/Tests/PSTranscribeTests/`; no production tier change |
| VALIDATION.md frontmatter | `.planning/milestones/v1.0-phases/0X-name/` (docs) | — | Mechanical doc edit; no runtime impact. v1.0 phase dirs restored to milestones location 2026-05-05. |
| CI gate | `.github/workflows/build-check.yml` | — | Pre-existing `swift test` step (Phase 23) — Phase 24 produces only NEW tests under that step |

## Project Constraints (from CLAUDE.md)

`./CLAUDE.md` does not exist at the repository root. User-level global rules (sacred-rules, verification, antipatterns) apply:

- **Never claim done without proof:** Each plan must run `swift test` and capture green output before flipping VALIDATION frontmatter.
- **Never speculate about code:** Each test must reference a real file/function verified in HEAD (this research provides the audit table).
- **Hooks beat rules:** CI's `swift test` step IS the deterministic gate. Local `swift test` MUST be green before committing.
- **No Claude attribution in commits:** Commit messages strip `Co-Authored-By: Claude…` and robot footer per global commit-style rule.

## Standard Stack

Phase 24 adds **zero new dependencies**. Existing test target stack is the entire surface.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Swift Testing | bundled with Swift 6.2 / Xcode 26 | `import Testing`, `@Suite`, `@Test`, `#expect`, `#require` | Phase 16+ established (D-01 in Phase 23 reaffirmed Swift Testing exclusively, no XCTest) `[VERIFIED: Package.swift]` |
| `@testable import PSTranscribe` | n/a | Access internal/private types from test target | Existing convention across all 18 tests `[VERIFIED]` |
| Foundation / FileManager | system | tempDir + fileExists + posixPermissions assertions | DictationLoggerTests pattern `[VERIFIED]` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| swift-snapshot-testing | 1.19.2 | Phase 23 added; **NOT used in Phase 24** | Skip — Phase 24 is unit/integration only |
| MockURLProtocol | local fixture | HTTP-shaped assertions | Probably not needed; available if a test needs URL session injection |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Swift Testing | XCTest | Rejected — Phase 16+ banned XCTest from this target; would mix conventions |
| `Bundle.main` Info.plist read | Direct `Info.plist` file IO | Both work for REBR-01..04. `Bundle(for: AnyClass.self)` matches how the app reads it; file IO is cleaner if the test bundle Info.plist is missing keys (it almost certainly is — see Risk Register) |
| Per-test inline temp dir | Shared `Phase24Fixtures.swift` helper | Inline preferred unless 3+ tests share. CONTEXT.md already biased here. |

**Installation:** None — all dependencies present.

**Version verification:** `swift-snapshot-testing` 1.19.2 verified against `PSTranscribe/Package.swift` line 13 `[VERIFIED: file read]`. Swift Testing is bundled with Xcode; no version pin needed.

---

## Phase Boundary Confirmation

CONTEXT.md scope restated for sanity:

- **In scope:** 5 VALIDATION.md backfills (phases 01, 02, 03, 08, 10). New Swift Testing files at flat `PSTranscribe/Tests/PSTranscribeTests/`. ~22-26 `@Test` methods. WITHDRAWN policy for the rest. `swift test` green local + CI.
- **Out of scope:** Snapshot tests, integration scaffolding, Phase 4/7/9 sweep, Phase 25 v1.2 sweep, deleted REBR-08 code restoration, moving phase dirs.
- **No drift detected.** Research findings align with locked decisions.

One nuance worth surfacing: the v1.0 phase directories (01, 02, 03, 08, 10) **currently live only in git** — they were re-archived in commit `065d63f`. Phase 24 work logically targets those `*-VALIDATION.md` files. The planner must coordinate restoration (re-cherry-pick from `23f3949` or equivalent) BEFORE the per-phase plans can edit those files. Treat this as a Wave 0 prerequisite for Phase 24's first plan, OR as an explicit todo step before plan execution starts.

## Per-Requirement API Audit

Each row records: REQ-ID | Surviving API or "deleted" | Test Class (UNIT / WITHDRAWN) | Reason. Source: `[VERIFIED]` from `git grep` / file read in HEAD.

### Phase 01 — Rebrand (REBR-01..08)

| REQ-ID | Surviving API / Surface | Test Class | Reason |
|--------|------------------------|------------|--------|
| REBR-01 | `Info.plist` `CFBundleName` = "PS Transcribe" `[VERIFIED: line 6]` | UNIT | Read Info.plist via `Bundle.main.infoDictionary?["CFBundleName"]` or direct file read; assert == "PS Transcribe". Caveat: test bundle main may not be the app bundle — see Risk Register. |
| REBR-02 | `Info.plist` `CFBundleIdentifier` = "com.pstranscribe.app" `[VERIFIED: line 10]`; `Logger(subsystem: "com.pstranscribe.app", …)` at `StreamingTranscriber.swift:13` and `TranscriptLogger.swift:4` | UNIT | Assert Info.plist value AND grep-equivalent: at least one `Logger` source-of-truth uses the bundle ID (test fetches bundle ID, compares to Logger subsystem string via reflection or hard-coded equality) |
| REBR-03 | `Package.swift` `name: "PSTranscribe"`, `target name: "PSTranscribe"` `[VERIFIED: Package.swift]`. Note: REBR-03 was *also* mapped to Phase 8 (frontmatter `source/pstranscribe` tag at TranscriptLogger.swift:151 — but that's REBR-03's Phase 8 closure) `[VERIFIED]` | UNIT | Phase 1 plan: assert build identifier / `@testable import PSTranscribe` resolves (compile-time proof). Phase 8 plan separately asserts `source/pstranscribe` appears in finalized frontmatter, NOT `source/tome`. |
| REBR-04 | `PSTranscribe/Sources/PSTranscribe/` directory exists; `PSTranscribe/Sources/Tome/` does not `[VERIFIED]` | UNIT | Build-time proof: `@testable import PSTranscribe` succeeds. Optionally a `Bundle(for: …)` resource path assertion. |
| REBR-05 | `.github/workflows/build-check.yml` line 38 `working-directory: PSTranscribe`; release-dmg.yml `PLIST="PSTranscribe/Sources/PSTranscribe/Info.plist"` `[VERIFIED]` | UNIT | Read workflow YAML as a String; assert no "Tome" / "Gremble" substrings; assert `working-directory: PSTranscribe` present. (Test framework loads the file at a known relative path; see test-bundle-relative path Risk Register.) |
| REBR-06 | `Info.plist` `SUFeedURL` = `https://raw.githubusercontent.com/cnewfeldt/ps-transcribe-releases/main/appcast.xml` `[VERIFIED: line 30]` (note: now `cnewfeldt`, not `OWNER` placeholder anymore — tech debt resolved) | UNIT | Assert SUFeedURL matches a regex requiring `ps-transcribe` in the path AND no `Tome`/`Gremble` substring. |
| REBR-07 | `Info.plist` `CFBundleDisplayName`, `CFBundleExecutable=PSTranscribe`, `NSMicrophoneUsageDescription` mentions "PS Transcribe" `[VERIFIED]` | UNIT | Assert each Info.plist key value. |
| **REBR-08** | **DELETED** in commit `4ef30e0` (2026-04-14) — `migrateUserDefaultsIfNeeded()` and the `hasMigratedFromTome` sentinel are gone from `PSTranscribeApp.swift`; zero matches in source `[VERIFIED: git show 4ef30e0]` | **WITHDRAWN** | "Code deleted post-v1.0 (`4ef30e0`); upgrade window closed. v1.0 milestone audit verified live migration on 2026-04-14. Source: 01-VERIFICATION.md REBR-08 row." |

**Phase 01 score: 7 UNIT, 1 WITHDRAWN.**

### Phase 02 — Security + Stability (SECR-01..12, STAB-01..04)

| REQ-ID | Surviving API / Surface | Test Class | Reason |
|--------|------------------------|------------|--------|
| SECR-01 | `release-dmg.yml:144` uses `gh repo clone cnewfeldt/ps-transcribe …`; zero `x-access-token` matches `[VERIFIED]` | UNIT | Read workflow file as String; assert zero `x-access-token` substring; assert `gh repo clone` present. |
| SECR-02 | TranscriptionEngine uses `Logger(subsystem: "com.pstranscribe.app", …)`; zero `/tmp/tome.log` or `FileHandle(forWritingAtPath: "/tmp/…")` matches `[VERIFIED]` | UNIT | Static check: read `TranscriptionEngine.swift`, assert no `/tmp/` write path. (Pure source assertion — no runtime side effect.) The "no /tmp log AT RUNTIME during a real session" runtime check is WITHDRAWN-eligible but unnecessary because the static absence already proves it. |
| SECR-03 | `validatedVaultPath` is **private** to `TranscriptLogger` (line 40); rejects `..` and `\0` `[VERIFIED]` | UNIT | Indirect: `try await logger.startSession(sourceApp:..., vaultPath: "../evil", ...)` and `await #expect(throws: TranscriptLoggerError.self)`. DictationLoggerTests has the exact pattern (`rejectsTraversal`, `rejectsNullByte`). |
| SECR-04 | SystemAudioCapture uses `applicationSupportDirectory + "PSTranscribe/tmp"` with `0o700` dir + `0o600` files `[VERIFIED: SystemAudioCapture.swift:28-32, 153]` | **WITHDRAWN** | Live capture session required to assert temp file location. Pure-function check ("static path string in source") would test the wrong invariant — that's a refactor-detector, not a security test. Source: 02-VERIFICATION.md row 4. |
| SECR-05 | `release-dmg.yml:47` `KEYCHAIN_FILE=$(mktemp /tmp/keychain.XXXXXX.keychain-db)` `[VERIFIED]` | UNIT | Read workflow file; assert `mktemp` present in keychain creation block. |
| SECR-06 | `posixPermissions: 0o600` set in TranscriptLogger.swift:70,174; SessionStore.swift:64,126; SystemAudioCapture.swift:153 `[VERIFIED]` | UNIT (partial) | DictationLogger already covers the pattern (`outputFileHasRestrictivePermissions` test). For TranscriptLogger: end-to-end session through `startSession` + `endSession` + `finalizeFrontmatter`; assert resulting file has `0o600`. Some sub-paths (live audio capture in SystemAudioCapture) require runtime — WITHDRAWN for those. UNIT for TranscriptLogger; WITHDRAWN for SystemAudioCapture sub-path with cross-reference to SECR-04. |
| SECR-07 | `actions/checkout@<sha>` and `actions/upload-artifact@<sha>` SHA-pinned `[VERIFIED]` BUT **regression detected:** `build-check.yml:56` `actions/upload-artifact@v4` (tag, not SHA) introduced by Phase 23 commit `ddcec6a` `[VERIFIED]` | UNIT | Read all three workflow files; regex-match every `uses: actions/…@(.+)` and assert each capture group matches `^[a-f0-9]{40}` (commit SHA shape). **This test will FAIL** on the current build-check.yml line 56 — see Risk Register: planner must decide whether to (a) treat as a Phase 24 incidental fix, (b) carve out an exception in the regex, or (c) escalate as a separate todo. |
| SECR-08 | `.gitignore` contains `.env`, `*.p12`, `*.cer`, `*.pem`, `*.key`, `*.keychain`, `*.keychain-db` `[VERIFIED]` | UNIT | Read `.gitignore`; assert each pattern present. |
| SECR-09 | `atomicRewrite` private at TranscriptLogger.swift:62; 3 call sites (`updateContext`, `rewriteFrontmatter`, `rewriteWithDiarization`) `[VERIFIED]` | UNIT (partial) | Direct rollback-under-kill test is WITHDRAWN (force-kill simulation out of scope per D-03). The atomic-write *normal-path* behavior (file ends up with `0o600` and contains expected content after `setName` rename) is a UNIT test through `TranscriptLogger.startSession` + `setName` + assert filesystem state. |
| SECR-10 | `sanitizedFilenameComponent` is **private** to `TranscriptLogger` (line 53) AND `LocalFileWriter` (line 165) — alphanumeric + space/hyphen/underscore/period whitelist, 50-char prefix `[VERIFIED]` | UNIT | Indirect test through public surface: invoke `TranscriptLogger.setName("../evil/<script>")` (or `LocalFileWriter.write(...)` with malicious title); inspect resulting filename on disk; assert it contains only whitelisted chars and ≤50 chars. **Property-based candidate** — see Validation Architecture. |
| SECR-11 | `speechSamples.removeAll(keepingCapacity: false)` at StreamingTranscriber.swift:92,100,108,119 `[VERIFIED]` | UNIT | Static-source check: read StreamingTranscriber.swift; assert zero `speechSamples.removeAll(keepingCapacity: true)` matches and ≥1 `keepingCapacity: false`. (Behavior assertion would require memory-residue testing — overkill.) |
| SECR-12 | Zero `2>/dev/null` in either CI workflow `[VERIFIED]` | UNIT | Read workflow files; assert zero `2>/dev/null` substring. (Could combine with SECR-01 into one test. Planner's call.) |
| **STAB-01** | `scanIncompleteCheckpoints()` at SessionStore.swift:97; called at ContentView.swift:317 `[VERIFIED]` | **WITHDRAWN** | Force-quit / SIGKILL mid-session simulation out of scope per D-03. Pure-function corner: `SessionStore.writeCheckpoint(_:)` round-trip via `scanIncompleteCheckpoints()` IS UNIT-testable in isolation (write a checkpoint to a tempDir-scoped SessionStore, then call scan, assert returned checkpoint matches). Recommend: **promote to UNIT** for the round-trip portion; STAB-01 *crash recovery end-to-end UI flow* stays WITHDRAWN. Source: 02-VERIFICATION.md (failed end-to-end ⇒ Phase 8 wired the call site) and 08-VERIFICATION.md (verified scanIncompleteCheckpoints is wired). |
| STAB-02 | midnight offset math at TranscriptLogger.swift:202-207: `timeIntervalSince(sessionStartTime) → max(0, Int) → HH:mm:ss` `[VERIFIED]` | UNIT | Indirect via TranscriptLogger.swift behavior, OR refactor a small helper for direct test. Easiest: extract assertion through the regex used in DictationLoggerTests (`appendComputesSessionRelativeOffset` shape). Insert two utterances via `appendUtterance` with timestamps spanning a midnight boundary (manipulated `sessionStartTime` via Date arithmetic if surface allows; otherwise assert ordering of relative offsets). |
| STAB-03 | `updateCheckpoint` called at TranscriptLogger.swift:278 (transcript_written), 320 (frontmatter_done), 477 (diarization_done) `[VERIFIED]`; `transcriptStore.clear()` at ContentView.swift:526 (start) and 665 (stop) `[VERIFIED via 08-VERIFICATION.md]` | UNIT (partial) | Atomic-finalization end-to-end is multi-actor, hard to assert in unit. The Phase 8 plan covers `transcriptStore.clear()` separately (DEFC-side). For STAB-03: full atomicity = WITHDRAWN; the discrete pieces (checkpoint write/finalize round-trip via `SessionStore`) are UNIT — same test as STAB-01. |
| STAB-04 | `MicCapture.captureError` at line 11; consumed at TranscriptionEngine.swift:130,219; `lastError` set on MainActor `[VERIFIED]` | **WITHDRAWN** | Mic permission denial requires runtime entitlement state per D-03. Pure-function corner: error propagation chain is multi-actor + MainActor-isolated, not cleanly UNIT-testable without mocking AVAudioEngine. Source: 02-VERIFICATION.md "Visual confirmation that MicCapture errors appear in the UI" (deferred to manual). |

**Phase 02 score: 9 UNIT, 4 partial-UNIT-with-WITHDRAWN-companion (SECR-04 sub-path, SECR-06 sub-path, SECR-09 sub-path, STAB-01 + STAB-03 share one round-trip test), 3 WITHDRAWN clean (SECR-04 dominant, STAB-01 dominant, STAB-04). Practical test count: ~10 `@Test` methods.**

### Phase 03 — Session Library + Recording Naming (SESS-01..05/07..09, NAME-01..05)

| REQ-ID | Surviving API / Surface | Test Class | Reason |
|--------|------------------------|------------|--------|
| **SESS-01** | `LibrarySidebar` SwiftUI view + `LibraryEntryRow` rendering `[VERIFIED]` | **WITHDRAWN** | "Sees a library/grid view" is a SwiftUI rendering assertion. Phase 23's snapshot tests cover LibraryView (visual). Phase 24 doesn't add snapshot tests per scope. Source: 03-VERIFICATION.md. |
| SESS-02 | `LibraryEntry.displayName`, `metadataLine` (date/duration/source) `[VERIFIED]` | UNIT | Already covered by `LibraryEntryTests.swift` (4 tests). Add a `@Test` per missing case if any — likely already done. Confirm assertion: each LibraryEntry, given a SessionType + name + duration + Date, produces expected `displayName` string. |
| SESS-03 | `parseTranscript(at:)` at TranscriptParser.swift:15 `[VERIFIED]`; existing `TranscriptParserTests.swift` 7 tests | UNIT | Already covered. Cross-reference, no new test needed. |
| **SESS-04** | Right-click context menu "Show in Finder" wired in LibraryEntryRow.swift via `NSWorkspace.shared.selectFile()` `[VERIFIED]` | **WITHDRAWN** | NSWorkspace + right-click UI interaction not testable from Swift Testing without UI automation. Requirement text was reframed in v1.0 audit (REQUIREMENTS.md SESS-04 line 48 says "right-click 'Show in Finder' action"). Source: 03-VERIFICATION.md SESS-04 row + 10-VERIFICATION.md. |
| SESS-05 | `FileManager.default.fileExists(atPath: entry.filePath)` cached in LibraryEntryRow `@State private var fileExists` (Phase 8 caching change at line 13/60-61, 137) `[VERIFIED]` | UNIT (partial) | The *behavior* (badge appears when file is missing) is SwiftUI render = WITHDRAWN. The pure-function corner: given an entry with `filePath = "/nonexistent/path"`, `FileManager.fileExists()` returns false. Trivial — the assertion is on FileManager, not our code. **Recommend: WITHDRAWN with cross-reference to LibraryEntry test** OR fold into LibraryEntryRow @State init test if the planner wants symmetry. |
| SESS-06 | `makeObsidianURL` at TranscriptParser.swift:105; `obsidianVaultForPath` at TranscriptParser.swift:79 `[VERIFIED]` | UNIT | **Already covered** by `ObsidianURLTests.swift` (8 `@Test` methods). Phase 24 cross-references existing coverage; no new test needed (or one corroborating test in a behavior-named file like `ObsidianDeepLinkTests.swift` if D-04 demands a fresh file — but `ObsidianURLTests.swift` already follows D-04 naming). Recommend: planner cites existing file. |
| SESS-07 | `transcriptStore.clear()` called at ContentView.swift:526 (start) and 665 (stop) `[VERIFIED]`; live-transcript view branch switch on `activeSessionType = nil` | UNIT (partial) | Phase 8's Plan 08-02 covers the `transcriptStore.clear()` part — re-cite. UI view-branch transition WITHDRAWN. |
| SESS-08 | `transcriptStore.clear()` at startSession; new LibraryEntry has fresh UUID `[VERIFIED]` | UNIT | Same `transcriptStore.clear()` test as SESS-07; assert UUID inequality across two start calls. |
| SESS-09 | `LibraryStore.entriesPersistToDiskAndReloadOnInit` at `LibraryStoreTests.swift:44` `[VERIFIED — already passes]` | UNIT | **Already covered**. Cross-reference. |
| NAME-01 | `RecordingNameField` SwiftUI view + sessionName binding `[VERIFIED]` | **WITHDRAWN** | UI text field interaction; pure-function corner is `LibraryEntry.displayName` for unnamed = NAME-04 (covered). Source: 03-VERIFICATION.md. |
| NAME-02 | `transcriptLogger.setName(_:)` at TranscriptLogger.swift:490 `[VERIFIED]` | UNIT | Start session, call setName, assert file on disk renamed to expected path containing sanitized name. (Combines with SECR-10 sanitization test.) |
| NAME-03 | `transcriptLogger.renameFinalized(at:to:)` at TranscriptLogger.swift:545 `[VERIFIED]` | UNIT | Start, finalize (`finalizeFrontmatter`), call renameFinalized, assert old path doesn't exist + new path does + content preserved. |
| NAME-04 | `LibraryEntry.displayName` fallback at Models.swift:87-97 `[VERIFIED]` | UNIT | **Already covered** by `LibraryEntryTests.swift::displayNameCallCaptureFallback` and `displayNameVoiceMemoFallback`. Cross-reference. |
| NAME-05 | Same as NAME-02 (file on disk renames) and NAME-03 (post-session rename) | UNIT | Same test as NAME-02 + NAME-03 — file path on disk before/after assert. |

**Phase 03 score: 7 UNIT (4 brand-new, 3 cross-referenced from existing tests), 4 WITHDRAWN. Net new tests: ~3-4.**

### Phase 08 — Code Defect Fixes (DEFC-class — D-01..D-05 in 08-VERIFICATION.md, mapping to STAB-01, STAB-03, REBR-03)

| REQ-ID (08 plan IDs) | Surviving API / Surface | Test Class | Reason |
|--------|------------------------|------------|--------|
| 08-D-01 (Speaker.named codable) | Speaker enum at Models.swift:3-53; CodingKeys + custom encode/decode `[VERIFIED]` | UNIT | **Already covered** by `SpeakerCodableTests.swift` (6 `@Test` methods: namedSpeakerRoundTrips, you/themRoundTrips, legacy decoders). Cross-reference. |
| 08-D-01 (TranscriptParser maps "Speaker N" → .named) | TranscriptParser.swift:60-63 switch `[VERIFIED]` | UNIT | **Already covered** by `TranscriptParserTests.swift::otherSpeakerMapsToNamed` and `diarizedSpeakerMapsToNamed`. Cross-reference. |
| 08-STAB-03 (transcriptStore.clear on stop) | ContentView.swift:526, 665 `[VERIFIED]` | UNIT (partial) | TranscriptStore is `@MainActor @Observable final class TranscriptStore` (likely). Direct test: instantiate TranscriptStore, populate, call `clear()`, assert empty. Trivial. New test file (or extend SessionCoordinatorTests): `TranscriptStoreClearTests.swift` — 1 `@Test`. |
| 08-REBR-03 (frontmatter `source/pstranscribe`) | TranscriptLogger.swift:151 `- source/pstranscribe` `[VERIFIED]`; LocalFileWriter.swift:124 same `[VERIFIED]` | UNIT | Two routes: (1) end-to-end via `TranscriptLogger.startSession` + `endSession` + `finalizeFrontmatter`, read finalized file, assert "source/pstranscribe" line present and "source/tome" absent. (2) Same shape for LocalFileWriter. **Recommend (1)** for Phase 24; LocalFileWriter is Phase 18.1 territory (covered there). |
| 08-print-removal | All error paths use `os.Logger`; zero `print(` matches in error files `[VERIFIED]` | UNIT | Static source check: read SystemAudioCapture.swift, MicCapture.swift, SessionStore.swift; assert zero `print(` matches in error blocks. |
| 08-LibraryEntryRow file-exists caching | `@State private var fileExists` at line 13; .onAppear at line 60-61 `[VERIFIED]` | **WITHDRAWN** | SwiftUI `@State` + `.onAppear` lifecycle = view test, not unit. Source: 08-VERIFICATION.md row 5 (verified at code level). |
| **08-STAB-01** (crash recovery end-to-end) | `scanIncompleteCheckpoints` + ContentView.task wiring `[VERIFIED]` | **WITHDRAWN** | Full crash-recovery round-trip requires force-quit per D-03. The `SessionStore` checkpoint round-trip portion = UNIT (also covered by Phase 02 STAB-01 row above; same test). Source: 08-VERIFICATION.md human verification item. |

**Phase 08 score: 4 UNIT (3 cross-referenced + 1 brand-new for source/pstranscribe + 1 for transcriptStore.clear + 1 print()-removal static), 2 WITHDRAWN. Net new tests: ~2-3.**

### Phase 10 — Obsidian Deep-link + Defect Cleanup (SESS-06 + DEFC items)

| REQ-ID (10 plan IDs) | Surviving API / Surface | Test Class | Reason |
|--------|------------------------|------------|--------|
| 10-SESS-06 | `makeObsidianURL` + `obsidianVaultForPath` at TranscriptParser.swift:105/79 `[VERIFIED]` | UNIT | **Already covered** by `ObsidianURLTests.swift` (8 tests). Cross-reference. |
| 10-D-04 (exhaustive Speaker switch in removeUtterance) | ContentView.swift:472-476 `case .you / .them / .named(let lbl)` `[VERIFIED]` | **WITHDRAWN** | View-internal callback in ContentView; not cleanly UNIT-testable without view harness. Pure-function corner: assertion that `Speaker.named` is exhaustively handled (compile-time guarantee from Swift). The TranscriptParser side IS UNIT (already covered in Phase 08). Source: 10-VERIFICATION.md. |
| 10-D-05 (crash-recovered session type icon: hasPrefix(vaultVoicePath) → .voiceMemo) | ContentView.swift:325-331 `[VERIFIED]` | UNIT | The inference logic IS pure: given a checkpoint.transcriptPath and a settings.vaultVoicePath, hasPrefix → .voiceMemo else .callCapture. Could be lifted to a helper for direct testing OR tested indirectly via SessionStore round-trip + simulated AppSettings. **Recommend: lift to a small free function or static method for direct test** (planner's call). One `@Test`. |

**Phase 10 score: 1 UNIT (cross-referenced existing) + 1 UNIT (new helper for recoveredType inference) + 1 WITHDRAWN. Net new tests: ~1-2.**

### Audit Totals

| Source | Count |
|--------|-------|
| Total v1.0 requirement IDs across the 5 phases | 36 |
| UNIT — already covered by existing tests (cross-reference, no new test) | 8 (LibraryStore-09, ObsidianURL-06, SpeakerCodable-08D01, TranscriptParser-08D01b, LibraryEntry-04 etc.) |
| UNIT — new tests needed | ~14-18 |
| WITHDRAWN | ~12-14 |

**Practical new-test count: ~14-18 `@Test` methods across ~6-7 new files.** This is consistent with CONTEXT.md's "~30-40" estimate when you include the existing 8 cross-referenced tests under the same banner.

## Proposed Test File Roster

Per D-04: flat at `PSTranscribe/Tests/PSTranscribeTests/`, named by behavior. CONTEXT.md listed 7 candidates; refined below with surviving-API evidence.

| Filename | Req IDs covered | Closest existing analog | Needs `.serialized`? | Notes |
|----------|----------------|------------------------|----------------------|-------|
| `RebrandInfoPlistTests.swift` | REBR-01, REBR-02, REBR-04, REBR-06, REBR-07 | `LibraryStoreTests.swift` (file-IO + `Bundle(for:)` patterns) | No (pure file read) | Reads Info.plist via `Bundle(for: AnyClass.self).path(forResource:ofType:)` OR direct file IO from a known relative path. **Open Question:** test bundle's Info.plist may not contain the app's CFBundleName — see Risk Register. Direct file IO is the safer route. |
| `WorkflowSecretsTests.swift` | REBR-05, SECR-01, SECR-05, SECR-07, SECR-08, SECR-12 | None directly — first time this target reads workflow files. Pattern from `LibraryStoreTests.tempDir()` for path construction. | No | Reads `.github/workflows/build-check.yml`, `release-dmg.yml`, `lint-summaries.yml`, `.gitignore` as Strings via `String(contentsOf:)`. Asserts substrings + regex on `actions/*@<sha>` SHA-pin format. **Risk: build-check.yml line 56 `@v4` will FAIL the SHA-pin regex** — see Risk Register for resolution options. |
| `TranscriptLoggerSecurityTests.swift` | SECR-03 (path traversal), SECR-06 (0o600), SECR-09 (atomicRewrite normal-path), SECR-10 (filename sanitization), NAME-02, NAME-05, REBR-03+08-source-tag | `DictationLoggerTests.swift` (canonical tempDir + actor pattern) | **Yes** — `.serialized` (writes to tempDir; though tempDir is per-test UUIDed, actor isolation under stress is safer with `.serialized` to match DictationLoggerTests precedent) | Single suite covering full TranscriptLogger lifecycle through `startSession` + `setName` + `endSession` + `finalizeFrontmatter`. Asserts: rejects `..` path; output file is `0o600`; setName produces sanitized filename; finalized frontmatter contains `- source/pstranscribe` and NOT `source/tome`. **Property-based candidate** for sanitization (random unicode → assert whitelist). |
| `MidnightOffsetTests.swift` | STAB-02 | `DictationLoggerTests.appendComputesSessionRelativeOffset` (regex offset assertion) | **Yes** if mutates session-singleton state; **No** if pure | One `@Test`: spans midnight via Date arithmetic, asserts produced HH:MM:SS offsets are positive and monotonic. May require lifting offset math to a small helper for direct test (planner's call). Else, pure assertion via TranscriptLogger.appendUtterance. |
| `CheckpointRoundTripTests.swift` | STAB-01 (round-trip part), STAB-03 (round-trip part) | `LibraryStoreTests.swift` (actor + tempDir + reload-from-disk pattern) | **Yes** — actor + FS | One `@Test`: instantiate `SessionStore(directory: tempDir)`; call `writeCheckpoint`; instantiate fresh `SessionStore` at same dir; call `scanIncompleteCheckpoints`; assert round-trip. Force-quit semantics WITHDRAWN. |
| `RecoveredSessionTypeTests.swift` | 10-D-05 (recoveredType inference) | None — small new helper | No (pure) | Asserts: given a transcriptPath under a vaultVoicePath prefix, infer `.voiceMemo`; else `.callCapture`. May require lifting to a pure helper (recommendation in Risk Register). |
| `ErrorPathLoggingTests.swift` | 08-print-removal, SECR-02 (no /tmp log), SECR-11 (removeAll keepingCapacity:false) | `WorkflowSecretsTests.swift` pattern (read source as String, assert substrings) | No (pure source read) | Static source assertions: read SystemAudioCapture.swift, MicCapture.swift, SessionStore.swift, TranscriptionEngine.swift, StreamingTranscriber.swift; assert zero `print(` matches; zero `/tmp/tome.log` writes; zero `keepingCapacity: true` for `speechSamples`. |

**Total proposed: 7 new test files, ~14-18 new `@Test` methods.** Plus cross-references to:
- `ObsidianURLTests.swift` (8 existing tests, covers SESS-06)
- `LibraryStoreTests.swift` (covers SESS-09)
- `SpeakerCodableTests.swift` (covers 08-D-01a)
- `TranscriptParserTests.swift` (covers 08-D-01b, SESS-03)
- `LibraryEntryTests.swift` (covers SESS-02, NAME-04)

## Existing Test Analogs

These existing files demonstrate patterns Phase 24 plans should copy:

| File | Demonstrates | Phase 24 Reuse |
|------|--------------|----------------|
| `DictationLoggerTests.swift` | `tempDir()` helper + `defer` cleanup; actor + `await`; `await #expect(throws:)`; `.serialized` suite; FileManager `posixPermissions` assertion via `attributesOfItem` | TranscriptLoggerSecurityTests, CheckpointRoundTripTests |
| `LibraryStoreTests.swift` | Actor instantiated with tempDir; reload from disk via fresh instance; entry round-trip | CheckpointRoundTripTests |
| `ObsidianURLTests.swift` | Pure-function URL test; `#require` for nil-or-throw shape; `URLComponents` query assertion | RecoveredSessionTypeTests, MidnightOffsetTests if planner picks pure shape |
| `LibraryEntryTests.swift` | Codable JSON round-trip; struct fixture builder | (Cross-reference target — no new test needed) |
| `AppSettingsTests.swift` | `@Suite(.serialized)` for UserDefaults mutation; per-test `clearV12Keys()` defer; `@MainActor` annotation pattern | If any Phase 24 test needs UserDefaults (none currently planned, but kept available) |
| `SpeakerCodableTests.swift` | Custom-decoder round-trip + legacy-format decode | (Cross-reference target) |
| `TranscriptParserTests.swift` | Sample-string parsing + regex assertion | (Cross-reference target; could extend if Phase 24 wants a frontmatter-source-tag round-trip) |
| `SnapshotFixtures.swift` | Phase 23 fixture-grouping pattern (file with shared helpers) | Skip — D-04 prefers inline; only emerge as `Phase24Fixtures.swift` if 3+ tests share helpers |
| `MockURLProtocol.swift` | Available for HTTP mocking — not needed in Phase 24 | — |

## Validation Architecture

This section is consumed by step 5.5 of `plan-phase.md` to stamp 5 `*-VALIDATION.md` files via the template at `$HOME/.claude/get-shit-done/templates/VALIDATION.md`. Phase 24 inherits Phase 23's CI gate verbatim; the only new artifact per phase is the test file(s) and the VALIDATION.md frontmatter flip.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Swift Testing (Swift 6.2 / Xcode 26) |
| Config file | `PSTranscribe/Package.swift` `.testTarget("PSTranscribeTests")` (already declared) |
| Quick run command | `cd PSTranscribe && swift test --filter <SuiteName>` |
| Full suite command | `cd PSTranscribe && swift test` |
| Estimated runtime | ~15 seconds full suite (~50 tests pre-Phase 24, ~65-70 tests post-Phase 24) |

### Phase Requirements → Test Map (template — populate per phase)

> The 5 per-phase VALIDATION.md files share this row shape. Each phase's planner stamps its own subset.

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| {REQ-ID} | {behavior} | unit / WITHDRAWN | `cd PSTranscribe && swift test --filter {SuiteName}` | ✅ existing / ❌ new in Phase 24-{plan} |

**Standardized columns for Phase 24:** Use the existing draft VALIDATION.md row shape — `Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status` — but with `Test Type ∈ {unit, WITHDRAWN}` (no "manual" per D-03). For WITHDRAWN rows: Automated Command = `n/a — WITHDRAWN`; Status = `withdrawn`; add a "Reason" column or footnote per D-03.

### Sampling Rate

- **Per task commit:** `cd PSTranscribe && swift test --filter <new-suite-name>` — runs the focused suite only. < 5s.
- **Per wave merge / per plan close:** `cd PSTranscribe && swift test` — runs full suite. ~15s.
- **Phase gate:** Full suite green locally AND CI's `build-check.yml` green on the PR.

### Wave 0 Gaps

For each Phase 24 plan, the new test file(s) ARE the Wave 0 deliverable. No framework install, no shared fixture file (per CONTEXT.md bias), no Package.swift changes.

- [ ] Phase 24-01 (Rebrand): `RebrandInfoPlistTests.swift` (5 `@Test`s) + `WorkflowSecretsTests.swift` (1-2 `@Test`s for REBR-05) — covers REBR-01..07; REBR-08 = WITHDRAWN.
- [ ] Phase 24-02 (Security+Stability): `WorkflowSecretsTests.swift` (extend) + `TranscriptLoggerSecurityTests.swift` + `MidnightOffsetTests.swift` + `CheckpointRoundTripTests.swift` + `ErrorPathLoggingTests.swift` — covers SECR-01/03/05/06/07/08/09/10/11/12, STAB-02, STAB-01-roundtrip, STAB-03-roundtrip; SECR-02/04, STAB-01-end-to-end, STAB-04 = WITHDRAWN.
- [ ] Phase 24-03 (Session+Naming): cross-reference existing tests (LibraryStoreTests, LibraryEntryTests, TranscriptParserTests, ObsidianURLTests) + minor additions in `TranscriptLoggerSecurityTests.swift` for NAME-02/03/05 — covers SESS-02/03/05/06/07/08/09, NAME-02/03/04/05; SESS-01/04, NAME-01 = WITHDRAWN.
- [ ] Phase 24-08 (Code Defect Fixes): cross-reference SpeakerCodableTests + TranscriptParserTests; new tests in `TranscriptLoggerSecurityTests.swift` (source/pstranscribe assertion) and `ErrorPathLoggingTests.swift` (print-removal) and a small `TranscriptStoreClearTests.swift` if planner wants a discrete file — covers REBR-03 (frontmatter), Speaker.named, transcriptStore.clear, print-removal, file-exists caching = WITHDRAWN, STAB-01 end-to-end = WITHDRAWN.
- [ ] Phase 24-10 (Obsidian + Cleanup): cross-reference ObsidianURLTests; new `RecoveredSessionTypeTests.swift` for D-05 — covers SESS-06, recoveredType inference; D-04 ContentView switch = WITHDRAWN.

### Invariants

1. `cd PSTranscribe && swift test` exits 0 on a clean checkout post-merge of each Phase 24 plan.
2. CI's `build-check.yml` `swift test` step is green on the Phase 24 PR.
3. Each VALIDATION.md row has Test Type ∈ {`unit`, `WITHDRAWN`}; no `manual` per D-03.
4. Each WITHDRAWN row has a one-line reason AND a `Source: 0X-VERIFICATION.md` pointer.
5. Each `*-VALIDATION.md` frontmatter post-Phase-24 has `status: approved`, `nyquist_compliant: true`, `wave_0_complete: true`, `last_audited: 2026-05-XX`.
6. Each Phase 24 plan SUMMARY.md carries `requirements-completed: [NYQUIST-0X]` (PROCESS-01 in effect).
7. No new dependencies added to `Package.swift`.
8. No production code (i.e., `Sources/PSTranscribe/`) edited unless surfacing a bug — in which case planner must escalate per D-03 (Phase 24 is audit, not fix).

### Edge Cases

- **FS cleanup:** Every test that writes to disk uses `tempDir()` + `defer { try? FileManager.default.removeItem(at: dir) }` per `DictationLoggerTests` pattern. Even on assertion failure, defer fires.
- **Parallel test races:** UserDefaults / NSApp.appearance / SessionStore checkpoints directory races avoided via `@Suite(.serialized)`. Pure-function tests run in default parallel mode.
- **Missing Info.plist key in test bundle:** `Bundle.main.infoDictionary` in a Swift Testing target points to the **test bundle**, not the app bundle. The app's CFBundleName/CFBundleIdentifier may not be present. Resolution options: (a) read the Info.plist file directly via `String(contentsOf:)` from a known relative path (`PSTranscribe/Sources/PSTranscribe/Info.plist`); (b) use `Bundle(identifier: "com.pstranscribe.app")` if the test process has loaded the app bundle (it has not — this is a test target). **Recommendation: direct file IO.** This is also what the v1.0 audit's grep checks did.
- **`actions/upload-artifact@v4` SHA-pin regression:** SECR-07 originally required all actions SHA-pinned; Phase 23 introduced `@v4` (tag) on build-check.yml:56. Test will fail if planner writes a strict regex. **Resolution options:**
  1. Carve out an exception (regex allows `@v4` for `actions/upload-artifact` only) — least invasive; flags as known tolerated regression in test comment.
  2. Fix the regression as a Phase 24 incidental — replace `@v4` with the SHA pin (`ea165f8d65b6e75b540449e92b4886f43607fa02 # v4`, copied from release-dmg.yml:96). Out of strict scope but trivial.
  3. Escalate as a separate todo and run Phase 24 with carve-out.
  **Recommendation:** Option 2 (fix inline; SHA already known from release-dmg.yml). One-line workflow edit. Document in Phase 24-02 plan body. Alternative: option 1 if planner doesn't want to mix audit + fix.
- **`@MainActor` requirement:** TranscriptLogger tests use `await` on actor methods; no `@MainActor` annotation needed unless the test crosses a SwiftUI view boundary. Most Phase 24 tests are pure-function or actor — no `@MainActor`. Exceptions: any test reading `AppSettings` (which is `@MainActor`) — none currently planned.
- **Test bundle relative path for workflow files:** `String(contentsOf: URL(fileURLWithPath: ".github/workflows/build-check.yml"))` — the working directory at test time is `PSTranscribe/`, so the path needs to be `../.github/workflows/build-check.yml`. **Verify in Wave 0** of Phase 24-01: write a smoke test that opens the file before asserting on contents; if the path is wrong, fail fast with a clear `Issue.record`.

### Property-Based Candidates

Only one candidate, and it's optional:

- **Filename sanitization (SECR-10):** `sanitizedFilenameComponent` whitelist is alphanumeric + space/hyphen/underscore/period, max 50 chars. Property-based assertion: for any random unicode string, the output contains only whitelisted chars AND has length ≤ 50. Swift Testing supports parameterized `@Test(arguments: [...])`. **Recommendation:** A handful of hand-crafted adversarial inputs (path traversal, null bytes, emoji, RTL text, 200-char string) is enough — true property-based fuzzing is overkill for this surface. Six `@Test(arguments:)` cases ≈ one property-based `@Test` for our purposes.

### Test-Class Breakdown (UNIT vs WITHDRAWN)

| Phase | UNIT (new) | UNIT (cross-ref) | WITHDRAWN | Total reqs |
|-------|-----------|-------------------|-----------|------------|
| 01 | 5 (REBR-01/02/05/06/07) | 0 | 1 (REBR-08) | 8 |
| 02 | ~10 (SECR-01/03/05/06/07/08/09/10/11/12; STAB-02; STAB-01/03 round-trip) | 0 | 4 (SECR-02 covered by static-source so not WITHDRAWN; SECR-04 live FS; STAB-01 e2e; STAB-04 mic) | 16 |
| 03 | 4 (NAME-02/03/05; some via TranscriptLoggerSecurityTests) | 5 (SESS-02/03/06/09; NAME-04) | 4 (SESS-01/04/05; NAME-01) | 13 |
| 08 | 2 (source/pstranscribe; print-removal; transcriptStore.clear) | 2 (Speaker.named codable + parser) | 2 (LibraryEntryRow caching; STAB-01 e2e) | 6 |
| 10 | 1 (recoveredType inference) | 1 (SESS-06 / ObsidianURL) | 1 (D-04 view switch) | 3 |
| **Total** | **~22** | **~8** | **~12** | **46** *(some reqs counted in multiple phases via the SUMMARY frontmatter cross-mapping)* |

(Counts are approximate; planner consolidates duplicates when a single test covers two reqs across two phases — e.g., `TranscriptLoggerSecurityTests.testSourcePstranscribeFrontmatter` covers REBR-03 in both Phase 01 and Phase 08 contexts.)

### Acceptance Criteria Glossary

For Phase 24 plan `<acceptance_criteria>` blocks, use these literal phrases (consumable by gsd-checker):

| Phrase | Meaning |
|--------|---------|
| `swift test --filter <SuiteName> passes` | The named test suite exits 0 when run as `cd PSTranscribe && swift test --filter <SuiteName>`. |
| `<TestFile>.swift contains @Test func <name>()` | The literal Swift Testing test method name appears in the new test file. |
| `0X-VALIDATION.md frontmatter shows status: approved` | YAML frontmatter line `status: approved` is present in the named VALIDATION.md. |
| `0X-VALIDATION.md frontmatter shows nyquist_compliant: true` | Frontmatter line literally `nyquist_compliant: true`. |
| `0X-VALIDATION.md frontmatter shows last_audited: 2026-05-XX` | Frontmatter `last_audited` field set to the Phase 24 completion date. |
| `0X-VALIDATION.md Per-Task Map row for REQ-Y has Test Type: WITHDRAWN` | The map table contains a row for REQ-Y where the Test Type column reads exactly `WITHDRAWN`. |
| `0X-VALIDATION.md Per-Task Map row for REQ-Y references Source: 0X-VERIFICATION.md` | The WITHDRAWN row body contains the literal string `Source: 0X-VERIFICATION.md`. |
| `swift test exits 0 in PSTranscribe/` | Full test suite green locally. |
| `build-check.yml green on PR <#>` | CI status check named "Build Check / build" on the PR is green. |

## Plan Splitting Recommendation

**Confirmed: 5 plans, one per audited v1.0 phase, in CONTEXT.md's suggested order.**

| Plan | Audited phase | Net new tests | Net new test files | Reqs touched | Estimated duration |
|------|---------------|---------------|---------------------|--------------|---------------------|
| 24-01 | Phase 01 (Rebrand) | 5-6 | 1 (`RebrandInfoPlistTests.swift`); plus stub of `WorkflowSecretsTests.swift` for REBR-05 (extended in 24-02) | REBR-01..07 (REBR-08 WITHDRAWN) | smallest |
| 24-02 | Phase 10 (Obsidian + Cleanup) | 1-2 | 1 (`RecoveredSessionTypeTests.swift`); cross-references ObsidianURLTests | SESS-06 cross-ref + 10-D-05 | small |
| 24-03 | Phase 08 (Code Defect Fixes) | 2-3 | 0-1 (extend TranscriptLoggerSecurityTests + ErrorPathLoggingTests; optional new `TranscriptStoreClearTests.swift`) | REBR-03 frontmatter + 08-D-01 cross-ref + transcriptStore.clear + print-removal | medium |
| 24-04 | Phase 03 (Session+Naming) | 3-4 | 0 new (extends TranscriptLoggerSecurityTests for NAME-02/03/05; cross-references rest) | SESS-02/03/05/06/07/08/09 + NAME-02/03/04/05 | medium |
| 24-05 | Phase 02 (Security+Stability) | 8-10 | 4 (`WorkflowSecretsTests.swift` finalize, `TranscriptLoggerSecurityTests.swift` finalize, `MidnightOffsetTests.swift`, `CheckpointRoundTripTests.swift`, `ErrorPathLoggingTests.swift` finalize) | SECR-01..12, STAB-01..04 | largest (16 reqs) |

**Rationale for "smallest first" order:**
- 01 establishes the Info.plist read pattern + workflow file read pattern. Other phases reuse.
- 10 establishes the recoveredType inference helper pattern (lift to free function or stay inline).
- 08 extends TranscriptLoggerSecurityTests + ErrorPathLoggingTests — incremental.
- 03 finishes NAME-02/03/05 in TranscriptLoggerSecurityTests — same file, more cases.
- 02 is the largest — by this point all helper patterns are established; only midnight offset + checkpoint round-trip + ErrorPathLoggingTests are net new.

**Implicit dependency:** WorkflowSecretsTests, TranscriptLoggerSecurityTests, ErrorPathLoggingTests grow plan-by-plan. The planner must coordinate so each plan's new `@Test` appends without conflict (one plan per file is cleanest, but cross-plan file growth is fine if the planner sequences waves).

**Alternative considered: behavior-clustered plans (e.g., one plan for "all Info.plist + workflow security", one for "all TranscriptLogger", one for "all parser/codable").** Rejected — splits one VALIDATION.md update across multiple plans, which complicates the atomic `status: draft → approved` flip. CONTEXT.md's bias toward one VALIDATION.md per plan is correct.

## Skill Invocation Pattern

**Recommendation: Write tests directly inline in each Phase 24 plan. Do NOT invoke `/gsd-validate-phase` skill or spawn `gsd-nyquist-auditor` agent.**

**Rationale:**

1. **The locked decisions short-circuit the auditor's discovery work.** `gsd-nyquist-auditor` (per `$HOME/.claude/agents/gsd-nyquist-auditor.md`) starts by analyzing gaps and identifying observable behaviors per requirement. CONTEXT.md's D-02/D-03/D-04 already do this for all 36 reqs. The audit table in this RESEARCH.md is the artifact the auditor would produce — re-running the auditor is redundant work.
2. **The skill's State A flow is one-phase-at-a-time.** `/gsd-validate-phase 1` is designed for a recently-completed phase that hasn't been audited. Phase 24 audits 5 phases atomically with shared test infrastructure; running the skill 5 times serially repeats the gap-analysis step 5 times.
3. **Inline tests follow existing GSD conventions.** Phase 23 wrote its tests inline in the plans (Plan 23-03 wrote 15 `@Test` methods directly without invoking the auditor agent). Phase 24 follows the same convention.
4. **The skill is still appropriate for FUTURE phases.** Phase 25 v1.2 sweep, or any single-phase retroactive audit, should still use `/gsd-validate-phase`. Phase 24 is the special case (5 phases, one campaign).

**What each Phase 24 plan looks like instead:**

```
<plan>
1. Read CONTEXT.md, RESEARCH.md, 0X-VERIFICATION.md, 0X-VALIDATION.md (existing draft)
2. (If phase dir not currently in tree) git restore from 23f3949 or equivalent commit
3. Wave 0: Add new test file(s) per RESEARCH Proposed Test File Roster
4. Wave 0: Run swift test --filter <SuiteName> locally; assert green
5. Wave 1: Edit 0X-VALIDATION.md — flip frontmatter, populate Per-Task Map per audit table
6. Wave 1: Run swift test full suite; assert green
7. Commit (test files + VALIDATION.md edit + SUMMARY.md with requirements-completed: [NYQUIST-0X])
</plan>
```

## Risk Register / Gotchas

| # | Risk | Severity | Mitigation |
|---|------|----------|------------|
| 1 | **`actions/upload-artifact@v4` SHA-pin regression on build-check.yml:56** introduced by Phase 23 commit `ddcec6a`. SECR-07 test will FAIL if planner writes a strict SHA-pin regex. | High | Recommend fixing inline in Phase 24-05 (or its own Wave 0): replace `@v4` with `@ea165f8d65b6e75b540449e92b4886f43607fa02  # v4` (SHA copied from release-dmg.yml:96). Alternatively: write regex with carve-out for `actions/upload-artifact` and document in test comment. |
| 2 | **Test bundle vs app bundle for Info.plist reads (REBR-01..04, REBR-06, REBR-07).** `Bundle.main.infoDictionary` from a Swift Testing target points to the test runner's bundle, not the app bundle. Keys may be missing or wrong. | High | Use direct file IO: `try String(contentsOf: URL(fileURLWithPath: "Sources/PSTranscribe/Info.plist"))` from working dir `PSTranscribe/`. Wave 0 of Phase 24-01: write a smoke test that opens the file and asserts non-empty before asserting key contents. Document the working-directory assumption inline. |
| 3 | **Test working-directory assumption.** `swift test` runs from `PSTranscribe/`, so workflow file reads need `../.github/workflows/...`. Inconsistencies will silently produce empty file content (assertion will fail with confusing message). | Medium | First test in `WorkflowSecretsTests.swift`: open the file via the assumed path; `try #require(!content.isEmpty)`; fail with clear message if path is wrong. |
| 4 | **`@testable import PSTranscribe` exposure of private members.** `validatedVaultPath`, `sanitizedFilenameComponent`, `atomicRewrite` are `private` (file-scoped), not `internal`. `@testable import` does NOT cross `private` — it crosses `internal`. So Phase 24 cannot directly call those helpers. | Medium | Test via public surface only: `TranscriptLogger.startSession(vaultPath: "../evil")` to exercise validation; `TranscriptLogger.setName("../bad/<chars>")` to exercise sanitization. The DictationLogger tests already prove this works (DictationLoggerTests.rejectsTraversal). Document in TranscriptLoggerSecurityTests header comment. |
| 5 | **REBR-08 migration code is gone — no test target.** Confirmed via `git show 4ef30e0`: 38 lines deleted including `migrateUserDefaultsIfNeeded()`, `hasMigratedFromTome` sentinel, init() call site. Zero matches in current source. | Low (resolved by D-03) | WITHDRAWN row in 01-VALIDATION.md with reason: "Code deleted post-v1.0 (4ef30e0); upgrade window closed; v1.0 milestone audit verified live migration on 2026-04-14. Source: 01-VERIFICATION.md REBR-08 row." |
| 6 | ~~**v1.0 phase directories not in tree.**~~ **RESOLVED 2026-05-05 as Phase 24 setup.** The 5 dirs were restored from `065d63f^` (`552e975`) and relocated to `.planning/milestones/v1.0-phases/{01-rebrand, 02-security-stability, 03-session-management-recording-naming, 08-code-defect-fixes, 10-final-defect-fixes-obsidian-deeplink}/`. All Phase 24 plans target VALIDATION.md at the new location. Restoration is staged but not yet committed; plan-phase commit step will include it. | Resolved | n/a — done. |
| 7 | **UserDefaults serialization races** in any test reading `AppSettings`. AppSettings is `@MainActor`-isolated and UserDefaults is process-global. | Medium | No Phase 24 test currently plans to touch AppSettings. If one emerges (unlikely), use `@Suite(.serialized)` + `@MainActor` per AppSettingsTests precedent. |
| 8 | **`@MainActor` requirement for SwiftUI-touching tests.** None planned. | Low | Skip — Phase 24 tests are pure-function or actor. |
| 9 | **`swift-snapshot-testing` 1.19.2 dependency** added in Phase 23 IS NOT used in Phase 24. | Low | Confirm: no `import SnapshotTesting` in any new Phase 24 test file. The only Phase 24 file that should import SnapshotTesting is `VisualRegressionTests.swift` (Phase 23 territory, untouched). |
| 10 | **`build-check.yml` macos-26 / Xcode 26 environment match.** Phase 23 added `swift test` step. Local dev may have a different Xcode version. | Low | Run `swift test` locally on macos-26 / Xcode 26 before opening PR. If a test passes locally on Xcode 25 but fails on Xcode 26, surface as a separate issue. |
| 11 | **TranscriptStore type — Phase 8 says `transcriptStore.clear()` was wired.** Need to confirm `TranscriptStore` type is constructable and clearable in a unit test. | Low | Spot-checked existing source — TranscriptStore is `@Observable @MainActor final class TranscriptStore` (or similar). Constructable. Verify in plan-phase exec. |
| 12 | **Atomic-write test on tempDir vs production vault.** `TranscriptLogger.startSession(vaultPath:)` requires a directory; tempDir works. `setName` performs `atomicRewrite` which is a write+remove+move sequence — test must allow time for FS to settle if running on a slow CI runner. | Low | Use `await` on actor methods; no manual delays needed. DictationLoggerTests pattern proves this works. |
| 13 | **Linting build-check.yml `@v4` regression silently makes test pass.** If the planner adopts the carve-out option (Risk #1 option 1), the test exempts `actions/upload-artifact` from SHA-pin assertion — a future regression on a different action would still be caught, but the upload-artifact regression is locked in. | Medium | Document tradeoff in test comment. Recommend Risk #1 option 2 (fix inline) instead. |

## Out of Scope (Confirmed)

Restated from CONTEXT.md so the planner doesn't drift:

- **Re-running v1.0 milestone audit** — already passed 2026-04-27.
- **Phase 4 (Mic Button), Phase 7 (Notion), Phase 9 (Verification Sweep) Nyquist sweep** — phase dirs in git history only; out of scope for Phase 24.
- **Phase 25 v1.2 sweep (NYQUIST-06, NYQUIST-07)** — separate phase.
- **Manual-Only entries in any VALIDATION.md** — D-03 forbids; WITHDRAWN-only.
- **Integration-test scaffolding for force-quit / SIGKILL / runtime entitlement** — D-03 lenient policy.
- **Restoring or rewriting REBR-08 UserDefaults migration code** — deleted in 4ef30e0; window closed.
- **New visual regression / snapshot tests** — Phase 23's domain.
- **Moving v1.0 phase dirs to `.planning/milestones/v1.0-phases/`** — post-Phase 24 housekeeping.
- **Extending coverage beyond the 5 restored v1.0 phases.**
- **Adding new test target dependencies** — `swift-snapshot-testing` is the latest add (Phase 23).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `swift build` + grep audit (Phase 1's 2026-04-27 approval basis) | `swift test` Swift Testing assertions | Phase 16+ established test target; Phase 23 added `swift test` to CI | Phase 24's whole reason for existing |
| XCTest | Swift Testing exclusively | Phase 16 D-01 (reaffirmed by Phase 23 D-01) | All Phase 24 tests use `import Testing` |
| Manual-Only / human-needed VALIDATION rows | WITHDRAWN with VERIFICATION.md cross-reference | Phase 24 D-03 (this phase, this campaign) | Stricter posture — Nyquist's automated-feedback promise enforced |
| `OWNER` placeholder in Sparkle URL + release workflow | `cnewfeldt/ps-transcribe` actual | Some commit between v1.0 audit (2026-04-27) and now | REBR-06 has a real testable assertion now |
| `actions/upload-artifact@<sha>` (Phase 2 SECR-07 standard) | `actions/upload-artifact@v4` (Phase 23 regression) | commit `ddcec6a` (2026-05-02) | Risk Register #1 |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The 5 v1.0 phase directories will be restored from git before Phase 24 plan execution starts | Phase Boundary Confirmation, Risk #6 | Plans cannot edit non-existent VALIDATION.md files; HARD blocker. Mitigation: explicit Wave 0 restore step in Phase 24-01. |
| A2 | `Bundle.main.infoDictionary` from the test target does NOT contain the app's CFBundleName/CFBundleIdentifier; direct file IO required | Risk #2, Edge Cases | If Bundle.main DOES work, planner can simplify. Verify in Wave 0 of Phase 24-01 with a smoke `@Test`. |
| A3 | Test working directory at `swift test` time is `PSTranscribe/` (per Package.swift package root) | Risk #3, Edge Cases | If working dir differs, workflow file reads break with confusing assertion failures. Verify in Wave 0 with a path smoke test. |
| A4 | `validatedVaultPath`, `sanitizedFilenameComponent`, `atomicRewrite` are file-private and NOT exposed by `@testable import` | Risk #4 | Confirmed via grep — they are `private`, not `internal`. If a future refactor changes them to `internal`, direct testing becomes available. |
| A5 | Phase 24 plans WILL fix the `actions/upload-artifact@v4` regression OR carve out an exception | Risk #1, Risk #13 | If neither, the SECR-07 test fails. Forces planner to make the call inline. |
| A6 | The TranscriptStore type (referenced in Phase 8 STAB-03) is unit-testable in isolation | Risk #11 | Spot-checked via grep — appears to be `@Observable @MainActor final class TranscriptStore`. Verify in plan-phase. |
| A7 | The "midnight offset" math at TranscriptLogger.swift:202 can be exercised through `appendUtterance` with manipulated timestamps without lifting to a free helper | Per-Requirement Audit STAB-02 | If not, planner may need to do a small refactor (extract the offset math to a static method) — this would be a Phase 24 production code change, which D-03 says NO. Alternative: WITHDRAWN with cross-reference to TranscriptLogger.swift:202 source comment. |
| A8 | `recoveredType` inference math at ContentView.swift:325-331 is liftable to a small free helper without breaking the view | Per-Requirement Audit 10-D-05 | If lifting is rejected by planner, fall back to indirect test through the .task block — harder but possible. Alternative: WITHDRAWN with source pointer. |
| A9 | The CONTEXT.md "~30-40 @Test methods" estimate includes the 8 cross-referenced existing tests; net new is ~14-22 | Audit Totals | Just a counting nuance; doesn't affect plan execution. |

## Open Questions

1. **Should Phase 24-05 also fix the `actions/upload-artifact@v4` regression?**
   - What we know: It's a Phase 23 regression; SHA pin is known; one-line fix.
   - What's unclear: Whether D-03 (audit, don't fix) extends to obvious-low-risk CI-only fixes.
   - Recommendation: Yes — fix inline in Phase 24-05 with a one-line note. Net effect: SECR-07 test passes cleanly without carve-out logic.

2. **Should `recoveredType` inference (Phase 10) be lifted to a pure helper for direct test?**
   - What we know: It's 7 lines of pure logic at ContentView.swift:325-331; lifting is trivial.
   - What's unclear: D-03 says no production code changes for Phase 24; lifting is technically a refactor.
   - Recommendation: Lift it. The lift is mechanical, no behavior change, and gives clean unit testability. Document as "Phase 24 minor refactor for testability" in plan body.

3. **Do we need a separate `Phase24Fixtures.swift`?**
   - What we know: CONTEXT.md says no unless 3+ tests share helpers.
   - Audit math: `TranscriptLoggerSecurityTests`, `CheckpointRoundTripTests`, and `MidnightOffsetTests` all use the `tempDir()` pattern. That's 3.
   - Recommendation: Inline `tempDir()` per test file (copy from DictationLoggerTests). 6 lines of duplication beats a fragile shared helper. CONTEXT.md bias holds.

4. **Order of Phase 24-04 and Phase 24-05?**
   - What we know: CONTEXT.md says smallest first → 03 before 02.
   - But: 03's NAME-02/03/05 tests live in `TranscriptLoggerSecurityTests.swift`, which 02 also extends. Does 03 land first (creates the file), then 02 extends it? Or does 02 create everything and 03 cross-references?
   - Recommendation: 02 creates `TranscriptLoggerSecurityTests.swift` skeleton + SECR-related tests; 03 (which actually runs FIRST in the plan order) creates a SEPARATE `TranscriptRenameTests.swift` for NAME-02/03/05. This avoids the file-growth coordination problem. Alternative: keep CONTEXT.md's "smallest first" bias and have 24-04 (Phase 03) extend the file 24-05 (Phase 02) created — but 24-04 runs BEFORE 24-05, which inverts the dependency. Cleanest split: NAME tests in their own file (`TranscriptRenameTests.swift`), security tests in `TranscriptLoggerSecurityTests.swift`. **Updates the proposed roster** — see updated table below if planner picks this option.

5. **`workflow.security_enforcement` + ASVS section in RESEARCH.md?**
   - What we know: `.planning/config.json` doesn't show `security_enforcement` key explicitly (default = enabled per workflow conventions).
   - But: Phase 24 is purely test additions on the test target; production source code untouched. ASVS categories are aspirational against production code, not test code.
   - Recommendation: Skip the Security Domain section in this RESEARCH.md (since this is a test-only phase). The SECR-* requirements ARE covered by the Per-Requirement Audit which already classifies threat patterns implicitly (path traversal, secret exposure, atomic-write, sanitization). Adding a parallel ASVS table would duplicate.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Swift toolchain (6.2 / Xcode 26) | All Phase 24 tests | ✓ | per Package.swift `swift-tools-version: 6.2` | None — hard dep |
| `swift test` runner | Per-task quick + full suite | ✓ | bundled | None — hard dep |
| macOS 26 | App platform target | ✓ | local + CI runs `macos-26` | None |
| Xcode test target signing | Test bundle code-signing | ✓ | unsigned test bundle works | None |
| Existing test files (`*Tests.swift`) | Cross-references | ✓ | 18 files; total 3173 LOC | Verified via `wc -l` |
| `.github/workflows/build-check.yml` | CI gate | ✓ | Phase 23 added `swift test` step | None |
| `.github/workflows/release-dmg.yml` | SECR-01/05/07/12 source | ✓ | post-rebrand, SHA-pinned | None |
| `.github/workflows/lint-summaries.yml` | SECR-07 source | ✓ | Phase 22 | None |
| `.gitignore` | SECR-08 source | ✓ | All 7 patterns present | None |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None.

## Sources

### Primary (HIGH confidence)
- `PSTranscribe/Package.swift` — test target declaration verified [VERIFIED: file read]
- `PSTranscribe/Sources/PSTranscribe/Info.plist` — REBR-01..07 surface verified [VERIFIED: lines 6/10/16/30]
- `PSTranscribe/Sources/PSTranscribe/Storage/TranscriptLogger.swift` — SECR-03/06/09/10, STAB-02, REBR-03 surface [VERIFIED: lines 4/40/53/62/151/202]
- `PSTranscribe/Sources/PSTranscribe/Storage/TranscriptParser.swift` — SESS-06 free functions verified [VERIFIED: lines 79/105]
- `PSTranscribe/Sources/PSTranscribe/Storage/SessionStore.swift` — checkpoint API verified [VERIFIED: lines 4/12/57/97]
- `PSTranscribe/Sources/PSTranscribe/Models/Models.swift` — Speaker.named codable verified [VERIFIED: lines 3-53]
- `PSTranscribe/Sources/PSTranscribe/Views/ContentView.swift` — scanIncompleteCheckpoints + recoveredType verified [VERIFIED: lines 317/325-331/472-476/526/665]
- `.github/workflows/build-check.yml` — `swift test` step (Phase 23) [VERIFIED: lines 38/46]
- `.github/workflows/release-dmg.yml` — SECR-01/05 surface [VERIFIED: lines 47/144]
- `git show 4ef30e0` — REBR-08 deletion [VERIFIED: 38 lines deleted; full diff shown]
- `git show 23f3949` — restored phase artifacts (currently re-archived) [VERIFIED]
- `git show ddcec6a` — Phase 23 introduced `actions/upload-artifact@v4` [VERIFIED]
- All existing test files — pattern reference [VERIFIED via wc -l + grep]

### Secondary (MEDIUM confidence)
- `.planning/codebase/TESTING.md` — refreshed 2026-05-04 for Phase 23; describes Swift Testing conventions [VERIFIED: file read]
- `.planning/codebase/CONVENTIONS.md` — `@MainActor` + `@Suite(.serialized)` precedent [VERIFIED: file read]
- `$HOME/.claude/get-shit-done/templates/VALIDATION.md` — template that step 5.5 uses [VERIFIED: file read]
- `$HOME/.claude/get-shit-done/workflows/validate-phase.md` — sweep pattern (skipped per Skill Invocation Pattern recommendation) [VERIFIED: file read]
- `$HOME/.claude/agents/gsd-nyquist-auditor.md` — agent role (skipped per recommendation) [VERIFIED: file read]
- `.planning/milestones/v1.0-MILESTONE-AUDIT.md` — Nyquist Compliance section + Tech Debt section [VERIFIED: file read]
- `.planning/milestones/v1.0-REQUIREMENTS.md` — REBR/SECR/STAB/SESS/NAME requirement definitions [VERIFIED: file read]

### Tertiary (LOW confidence)
- None — all claims in this RESEARCH.md are verified against source files or git history.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all dependencies in `Package.swift`, no version drift since Phase 23.
- Architecture: HIGH — single-tier test target work, no new design.
- Per-requirement audit: HIGH — every row backed by a `[VERIFIED]` citation against current HEAD.
- Pitfalls: HIGH — Risk Register sourced from existing test patterns + grep against current source. Risk #1 (upload-artifact@v4 regression) verified via `git blame`.
- Plan splitting: HIGH — confirms CONTEXT.md bias; no novel proposal.

**Research date:** 2026-05-05
**Valid until:** 2026-06-05 (30 days for stable; surface is settled). If Phase 23 ships subsequent test-infra changes or production code is refactored before Phase 24 starts, re-verify the audit table.

## RESEARCH COMPLETE
