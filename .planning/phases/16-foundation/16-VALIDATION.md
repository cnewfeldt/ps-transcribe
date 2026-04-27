---
phase: 16
slug: foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-27
---

# Phase 16 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Sourced from `16-RESEARCH.md` §"Validation Architecture".

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (bundled with Swift 6.0+; in use across `Tests/PSTranscribeTests/`) |
| **Config file** | `PSTranscribe/Package.swift` (test target lines 22-26) |
| **Quick run command** | `cd PSTranscribe && swift test --filter <SuiteName>` |
| **Full suite command** | `cd PSTranscribe && swift test` |
| **Build-only gate** | `cd PSTranscribe && swift build` |
| **Estimated runtime** | ~30s per filtered suite, ~3-5 min for full suite |

---

## Sampling Rate

- **After every task commit:** Run the relevant filtered suite + `swift build` (e.g. `cd PSTranscribe && swift test --filter DictationLoggerTests && swift build`)
- **After every plan wave:** Run `cd PSTranscribe && swift test` (full suite)
- **Before `/gsd-verify-work`:** Full suite must be green AND manual smoke test of existing meeting flow (SC-4 regression check)
- **Max feedback latency:** ~30s per task (filtered suite), ~5 min per wave (full suite)

---

## Per-Task Verification Map

> Task IDs filled in by `/gsd-plan-phase` once PLAN.md files exist. Mapping is from Phase 16 Success Criteria (SC-1..SC-5) to test commands.

| SC | Behavior | Test Type | Automated Command | File Exists | Status |
|----|----------|-----------|-------------------|-------------|--------|
| SC-1 | App builds with new `SessionType.dictation` + `DictationOutputMode` | build | `cd PSTranscribe && swift build` | ✅ | ⬜ pending |
| SC-1 | `SessionType.dictation` Codable round-trip | unit | `cd PSTranscribe && swift test --filter SessionTypeCodableTests` | ❌ W0 | ⬜ pending |
| SC-1 | `DictationOutputMode` Codable round-trip | unit | `cd PSTranscribe && swift test --filter SessionTypeCodableTests/dictationOutputMode` | ❌ W0 | ⬜ pending |
| SC-1 | `DictationHotkeyMode` Codable round-trip | unit | `cd PSTranscribe && swift test --filter SessionTypeCodableTests/dictationHotkeyMode` | ❌ W0 | ⬜ pending |
| SC-2 | All six new AppSettings keys persist + reload | unit | `cd PSTranscribe && swift test --filter AppSettingsTests` | ❌ W0 | ⬜ pending |
| SC-2 | Default values match D-04 (clipboard / ~/Documents/PS Transcribe Dictations / toggle / 3.0 / "" / nil) | unit | `cd PSTranscribe && swift test --filter AppSettingsTests/defaults` | ❌ W0 | ⬜ pending |
| SC-2 | Build emits zero warnings on the six new properties | build | `cd PSTranscribe && swift build 2>&1 \| grep -E 'warning:.*AppSettings'` (must be empty) | ✅ | ⬜ pending |
| SC-3 | `DictationLogger.startSession` writes header without YAML frontmatter | unit | `cd PSTranscribe && swift test --filter DictationLoggerTests/startSessionWritesHeader` | ❌ W0 | ⬜ pending |
| SC-3 | `DictationLogger.append` writes utterance with session-relative timestamp | unit | `cd PSTranscribe && swift test --filter DictationLoggerTests/appendWritesUtterance` | ❌ W0 | ⬜ pending |
| SC-3 | `DictationLogger.endSession` returns URL and closes handle | unit | `cd PSTranscribe && swift test --filter DictationLoggerTests/endSessionClosesHandle` | ❌ W0 | ⬜ pending |
| SC-3 | Two `startSession` calls within 100ms produce distinct files (Pitfall #9) | unit | `cd PSTranscribe && swift test --filter DictationLoggerTests/rapidSessionsNoCollision` | ❌ W0 | ⬜ pending |
| SC-3 | `DictationLogger` rejects path traversal (`..`) | unit | `cd PSTranscribe && swift test --filter DictationLoggerTests/rejectsTraversal` | ❌ W0 | ⬜ pending |
| SC-4 | `LibraryStore` lifts cleanly: `PSTranscribeApp` constructs, `ContentView` accepts via init | build | `cd PSTranscribe && swift build` | ✅ | ⬜ pending |
| SC-4 | Existing `LibraryStoreTests` continues green (regression) | unit | `cd PSTranscribe && swift test --filter LibraryStoreTests` | ✅ | ⬜ pending |
| SC-5 | `SessionCoordinator.anySessionActive` is `false` when no engine attached | unit | `cd PSTranscribe && swift test --filter SessionCoordinatorTests/falseWhenNoEngine` | ❌ W0 | ⬜ pending |
| SC-5 | `SessionCoordinator.anySessionActive` is `false` when engine attached but `isRunning == false` | unit | `cd PSTranscribe && swift test --filter SessionCoordinatorTests/falseWhenEngineIdle` | ❌ W0 | ⬜ pending |
| SC-5 | `SessionCoordinator.anySessionActive` is `true` when engine attached and `isRunning == true` | unit | `cd PSTranscribe && swift test --filter SessionCoordinatorTests/trueWhenEngineRunning` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
*File Exists: ✅ exists · ❌ W0 = Wave 0 must create*

---

## Wave 0 Requirements

- [ ] `Tests/PSTranscribeTests/SessionTypeCodableTests.swift` — covers SC-1 (three new enums, codability)
- [ ] `Tests/PSTranscribeTests/AppSettingsTests.swift` — covers SC-2 (six new keys, defaults + UserDefaults round-trip)
- [ ] `Tests/PSTranscribeTests/DictationLoggerTests.swift` — covers SC-3 (start/append/end + collision + path traversal)
- [ ] `Tests/PSTranscribeTests/SessionCoordinatorTests.swift` — covers SC-5 (anySessionActive computed property under three engine states)

*No framework install needed — Swift Testing is bundled with the toolchain.*

---

## Manual-Only Verifications

| Behavior | Success Criterion | Why Manual | Test Instructions |
|----------|-------------------|------------|-------------------|
| Existing meeting recording flow has no behavioral regression after `LibraryStore` lift | SC-4 | UI smoke test — automated tests cover component-level regressions only, not full app launch + recording UX | 1. `cd PSTranscribe && swift run` 2. Click record on a meeting capture 3. Speak for 30 seconds 4. Stop recording 5. Verify entry appears in sidebar identically to pre-Phase-16 baseline. Capture observation in `16-VERIFICATION.md`. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all ❌ MISSING references (4 new test files)
- [ ] No watch-mode flags in commands
- [ ] Feedback latency < 30s for filtered suites
- [ ] `nyquist_compliant: true` set in frontmatter
- [ ] SC-4 manual smoke test recorded in `16-VERIFICATION.md`

**Approval:** pending
