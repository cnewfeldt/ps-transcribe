---
phase: 2
slug: security-stability
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-02
last_audited: 2026-05-05
---

# Phase 02 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`import Testing`) -- enabled by Phase 18+ test target |
| **Config file** | `PSTranscribe/Package.swift` (`PSTranscribeTests` target) |
| **Quick run command** | `cd PSTranscribe && swift test --filter <SuiteName>` |
| **Full suite command** | `cd PSTranscribe && swift test` |
| **Estimated runtime** | ~60-90 seconds (full suite) / <1 second (focused suites) |

---

## Sampling Rate

- **After every task commit:** Run `cd PSTranscribe && swift test --filter <SuiteName>`
- **After every plan wave:** Run `cd PSTranscribe && swift test`
- **Before `/gsd:verify-work`:** Full suite must be green locally AND CI green on the PR
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status | Notes |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|-------|
| 24-05-01 | 24-05 | 1 | SECR-01 | T-24-05-secret | GH_TOKEN never embedded in URLs | unit | `cd PSTranscribe && swift test --filter WorkflowSecretsTests/noTokenInReleaseDmgAndGhCloneUsed` | ✅ new | green | Static workflow YAML assertion |
| 24-05-02 | 24-05 | 1 | SECR-02 | T-24-05-tmplog | No /tmp log file at runtime | unit | `cd PSTranscribe && swift test --filter ErrorPathLoggingTests/noTmpLogWritesInTranscriptionEngine` | ✅ new | green | Static-source absence assertion (no `/tmp/tome.log` write path can run if the string isn't in source) |
| 24-05-03 | 24-05 | 1 | SECR-03 | T-24-05-traversal | Vault path with `..` or `\0` rejected | unit | `cd PSTranscribe && swift test --filter TranscriptLoggerSecurityTests/rejectsPathTraversal` | ✅ new | green | Behavioral via TranscriptLogger.startSession (file-private validatedVaultPath reached through public surface -- Risk #4) |
| 24-05-04 | 24-05 | 1 | SECR-04 | T-24-05-tempfs | Audio temp in App Support/PSTranscribe/tmp | WITHDRAWN | n/a -- WITHDRAWN | n/a | withdrawn | Live audio capture session required; pure-source check would be a refactor-detector, not a security assertion. Behavior verified at v1.0 ship in 02-VERIFICATION.md row 4. Source: 02-VERIFICATION.md row 4. |
| 24-05-05 | 24-05 | 1 | SECR-05 | T-24-05-keychain | CI keychain via mktemp | unit | `cd PSTranscribe && swift test --filter WorkflowSecretsTests/keychainUsesMktemp` | ✅ new | green | Static workflow YAML assertion |
| 24-05-06 | 24-05 | 1 | SECR-06 | T-24-05-perms | Files created with POSIX 0600 | unit | `cd PSTranscribe && swift test --filter TranscriptLoggerSecurityTests/finalizedTranscriptHas0o600Permissions` | ✅ new | green | TranscriptLogger half asserted; SystemAudioCapture sub-path WITHDRAWN (live FS) -- folded into this row's note |
| 24-05-07 | 24-05 | 1 | SECR-07 | T-24-05-shapin | All GitHub Actions SHA-pinned | unit | `cd PSTranscribe && swift test --filter WorkflowSecretsTests/actionsAreSHAPinned` | ✅ new | green | Plan 24-05 Task 1 fixed the `actions/upload-artifact@v4` regression (Phase 23 ddcec6a); test passes cleanly without carve-outs |
| 24-05-08 | 24-05 | 1 | SECR-08 | T-24-05-secrets | .gitignore blocks secret patterns | unit | `cd PSTranscribe && swift test --filter WorkflowSecretsTests/gitignoreBlocksSecretFilePatterns` | ✅ new | green | All 7 patterns asserted: .env, *.p12, *.cer, *.pem, *.key, *.keychain, *.keychain-db |
| 24-05-09 | 24-05 | 1 | SECR-09 | T-24-05-atomic | Atomic write integrity (normal path) | unit | `cd PSTranscribe && swift test --filter TranscriptLoggerSecurityTests/setNameAtomicRewriteProducesValidFile` | ✅ new | green | Normal-path atomic-write integrity. Force-quit/SIGKILL variant WITHDRAWN per D-03 -- folded into this row's note. |
| 24-05-10 | 24-05 | 1 | SECR-10 | T-24-05-sanitize | Filename sanitization whitelist | unit | `cd PSTranscribe && swift test --filter TranscriptLoggerSecurityTests/sanitizesAdversarialFilenameComponents` | ✅ new | green | Adversarial input through public setName surface; whitelist regex `^[A-Za-z0-9 ._-]+$` enforced |
| 24-05-11 | 24-05 | 1 | SECR-11 | T-24-05-memory | Audio buffer released without retaining capacity | unit | `cd PSTranscribe && swift test --filter ErrorPathLoggingTests/speechSamplesUsesNoCapacityRetention` | ✅ new | green | Static-source assertion on StreamingTranscriber.swift |
| 24-05-12 | 24-05 | 1 | SECR-12 | T-24-05-suppress | No 2>/dev/null error suppression | unit | `cd PSTranscribe && swift test --filter WorkflowSecretsTests/noTomeOrTokenOrSuppressionInBuildCheck` | ✅ new | green | Folded into Test 1's `2>/dev/null` absence assertion; release-dmg.yml also asserted via `noTokenInReleaseDmgAndGhCloneUsed` |
| 24-05-13 | 24-05 | 1 | STAB-01 | T-24-05-recover | Crash recovery surfaces incomplete session | unit (round-trip) + WITHDRAWN (e2e) | `cd PSTranscribe && swift test --filter CheckpointRoundTripTests/writeCheckpointAndReloadFromFreshInstance` | ✅ new | green | Data-layer round-trip portion: writeCheckpoint + fresh-instance scanIncompleteCheckpoints. Force-quit + UI-surfaces-it user flow is WITHDRAWN per Phase 24 D-03. Source: 02-VERIFICATION.md row 13 (note: row 13 was scored ✗ FAILED; resolution wired at Phase 8 -- see 08-VERIFICATION.md). |
| 24-05-14 | 24-05 | 1 | STAB-02 | T-24-05-midnight | Diarization timestamps midnight-safe | unit | `cd PSTranscribe && swift test --filter MidnightOffsetTests/midnightBoundaryProducesNonNegativeOrderedOffsets` | ✅ new | green | Spans 60-second gap mimicking midnight cross; asserts non-negative + ordered |
| 24-05-15 | 24-05 | 1 | STAB-03 | T-24-05-checkpoint | Checkpoint write+finalize round-trip | unit | `cd PSTranscribe && swift test --filter CheckpointRoundTripTests` | ✅ new | green | Same suite as STAB-01 round-trip portion; the data-layer atomicity test |
| 24-05-16 | 24-05 | 1 | STAB-04 | T-24-05-mic | Mic permission denial visible in UI | WITHDRAWN | n/a -- WITHDRAWN | n/a | withdrawn | Mic permission denial requires runtime entitlement state the test target can't simulate; error propagation chain is multi-actor + MainActor-isolated, not cleanly UNIT-testable without mocking AVAudioEngine. Source: 02-VERIFICATION.md row 16. |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `PSTranscribe/Tests/PSTranscribeTests/WorkflowSecretsTests.swift` -- REBR-05/SECR-01/05/07/08/12 (added in Plan 24-05 Task 2)
- [x] `PSTranscribe/Tests/PSTranscribeTests/TranscriptLoggerSecurityTests.swift` -- SECR-03/06/09/10 (added in Plan 24-05 Task 3)
- [x] `PSTranscribe/Tests/PSTranscribeTests/MidnightOffsetTests.swift` -- STAB-02 (added in Plan 24-05 Task 4)
- [x] `PSTranscribe/Tests/PSTranscribeTests/CheckpointRoundTripTests.swift` -- STAB-01/03 round-trip (added in Plan 24-05 Task 4)
- [x] `PSTranscribe/Tests/PSTranscribeTests/ErrorPathLoggingTests.swift` -- SECR-02/11 + 08-print-removal (added in Plan 24-05 Task 5)
- [x] `.github/workflows/build-check.yml` SHA-pin regression fixed (line 56; Plan 24-05 Task 1)

**Wave 0 complete.**

---

## Validation Sign-Off

- [x] All tasks have automated verify (swift test) or WITHDRAWN with cited source
- [x] Sampling continuity: focused `swift test --filter` after every commit; full suite per wave
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-05 (Phase 24 NYQUIST-02)

---

## Validation Audit 2026-05-05 (Phase 24 -- NYQUIST-02)

| Metric | Count |
|--------|-------|
| Gaps found | 1 (Phase 02 draft VALIDATION.md had 16 pending rows, 11 manual; D-03 lenient policy converts 13 to automated unit, 3 to WITHDRAWN) |
| Resolved | 13 (SECR-01/02/03/05/06/07/08/09/10/11/12 + STAB-01-roundtrip + STAB-02 + STAB-03-roundtrip -- all unit-tested) |
| Withdrawn | 3 (SECR-04 live FS audio temp; STAB-01 e2e force-quit; STAB-04 runtime mic entitlement) |
| Escalated | 0 |
| Document updates | Frontmatter flipped to approved/true/true; `last_audited: 2026-05-05` added; Per-Task Map rewritten with unit + WITHDRAWN rows; Manual-Only Verifications section removed (D-03 lenient policy); SHA-pin regression on `build-check.yml:56` FIXED inline. |

### Audit Method

- Fixed Phase 23 SHA-pin regression on `build-check.yml:56` -- `actions/upload-artifact@v4` -> `actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02 # v4` (SHA from `release-dmg.yml:96`). Plan 24-05 Task 1.
- Created 5 new Swift Testing files covering 13 unit-testable reqs:
  - `WorkflowSecretsTests.swift` (5 `@Test` methods) -- REBR-05, SECR-01/05/07/08/12 (Task 2)
  - `TranscriptLoggerSecurityTests.swift` (5 `@Test` methods) -- SECR-03/06/09/10 (Task 3)
  - `MidnightOffsetTests.swift` (1 `@Test`) -- STAB-02 (Task 4)
  - `CheckpointRoundTripTests.swift` (1 `@Test`) -- STAB-01/03 round-trip (Task 4)
  - `ErrorPathLoggingTests.swift` (3 `@Test` methods) -- SECR-02/11 + 08-print-removal (Task 5)
- Ran each focused suite -- all green.
- Ran full `cd PSTranscribe && swift test` -- exits 0.

### Notes

- SECR-04 (audio temp in App Support) WITHDRAWN: live capture session required; static-source check would be a refactor-detector, not a security assertion. Behavior verified at v1.0 ship in 02-VERIFICATION.md row 4.
- STAB-01 split: round-trip data-layer portion is unit-tested by `CheckpointRoundTripTests`; the end-to-end crash-recovery user flow (force-quit, relaunch, UI surfaces it) is WITHDRAWN per Phase 24 D-03 (force-quit out of scope). The wiring of `scanIncompleteCheckpoints` at app launch was Phase 8's resolution to the 02-VERIFICATION.md row 13 "FAILED" finding -- see 08-VERIFICATION.md.
- STAB-04 (mic permission denial) WITHDRAWN: requires runtime entitlement state the test target can't simulate; multi-actor MainActor-isolated error chain not cleanly unit-testable without AVAudioEngine mocking.
- SECR-09 (atomic-rewrite under SIGKILL) split: normal-path integrity is unit-tested by `setNameAtomicRewriteProducesValidFile`; force-kill simulation is WITHDRAWN per D-03 (folded into the SECR-09 unit row's note rather than as a separate row).
- The SHA-pin fix on `build-check.yml:56` is the only production-side change in all of Phase 24 -- surgical, restoring the Phase 02 SECR-07 invariant that Phase 23 incidentally regressed.
