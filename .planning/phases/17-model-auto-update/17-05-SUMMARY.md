---
phase: 17-model-auto-update
plan: 05
subsystem: model-auto-update
tags: [swift, testing, backfill, release-tooling, verification]

requires:
  - phase: 17-04
    provides: ModelUpdateService fully wired at app scope, Settings > Speech Model UI

provides:
  - D-14 first-run backfill (backfillInstalledVersionIfNeeded) in ModelUpdateService.checkForUpdate
  - Scripts/generate-model-manifest.swift for authoring and publishing the live manifest
  - 17-VERIFICATION.md with SC-1..5, MODEL-01..10, backfill smoke test, and manifest publication procedure

affects: [v1.2-launch, release-checklist]

tech-stack:
  added: []
  patterns:
    - "TDD RED-GREEN: failing tests committed before implementation, passing tests committed after"
    - "D-14 conjunctive backfill: empty installedModelVersion + all files exist + first file size matches"
    - "Size-only check for backfill (avoids 5-30s SHA scan on launch)"
    - "FileHandle chunked SHA-256 hashing for large model files in generate-model-manifest.swift"

key-files:
  created:
    - Scripts/generate-model-manifest.swift
    - .planning/phases/17-model-auto-update/17-05-SUMMARY.md
  modified:
    - PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift
    - PSTranscribe/Tests/PSTranscribeTests/ModelUpdateServiceTests.swift
    - .planning/phases/17-model-auto-update/17-VERIFICATION.md

key-decisions:
  - "D-14 backfill uses size-only check on first file (not SHA-256) to avoid 5-30s startup latency"
  - "Backfill is conjunctive: any failing condition (file missing, size mismatch, version already set) reverts to normal flow"
  - "generate-model-manifest.swift enumerates leaf files inside .mlmodelc dirs (Pitfall #1) not top-level .mlpackage names"
  - "Manifest publication to cnewfeldt/ps-transcribe-releases is a release-time step, not a plan-execution step"
  - "STATE.md release prerequisite update deferred to orchestrator (orchestrator owns STATE.md writes)"

metrics:
  duration: ~30min
  completed: "2026-04-27"
  tasks_completed: 3
  tasks_total: 4
  files_created: 2
  files_modified: 3
  tests_added: 5
  tests_total: 60
---

# Phase 17 Plan 05: D-14 Backfill + Manifest Publication Tooling Summary

**D-14 first-run backfill wired into checkForUpdate (5 tests pass); Scripts/generate-model-manifest.swift produces valid leaf-file manifest from live model directory; 17-VERIFICATION.md documents all SC-*, MODEL-* rows and manifest publication as v1.2 release prerequisite**

## Performance

- **Duration:** ~30 min
- **Completed:** 2026-04-27
- **Tasks:** 3 of 4 complete (Task 4 is human-verify checkpoint, paused)
- **Files modified:** 3 source/test files + 2 planning files

## Accomplishments

### Task 1: D-14 First-Run Backfill (TDD)

Added `backfillInstalledVersionIfNeeded(_:)` private method to `ModelUpdateService` and wired it into `checkForUpdate` after the manifest fetch, before the min_app_version gate.

**Backfill logic (D-14 conjunctive conditions):**
1. `settings.installedModelVersion.isEmpty == true` (only fires for v1.0 upgraders with empty version)
2. Every `manifest.files[*].name` exists on disk at `modelDirectory.appendingPathComponent(name)`
3. The first file's on-disk size (via `FileManager.attributesOfItem`) matches `manifest.files[0].size`

Any condition failing silently skips backfill and routes the user to normal update flow. No download, no SHA-256 scan, no UI.

**5 tests added (all pass):**
- `backfillFiresWhenAllConditionsMet` -- happy path: all conditions met, installedModelVersion set, state .upToDate
- `backfillDoesNotFireWhenInstalledIsSet` -- pre-set version not overwritten, state .updateAvailable
- `backfillDoesNotFireOnSizeMismatch` -- wrong first-file size, backfill skips
- `backfillDoesNotFireOnMissingFile` -- manifest declares file not on disk, backfill skips
- `backfillSurvivesAttributeReadFailure` -- non-existent modelsRoot, no crash, backfill skips silently

All 60 Phase 17 tests pass after implementation. No regressions.

### Task 2: Scripts/generate-model-manifest.swift

Created `Scripts/generate-model-manifest.swift` (executable, `#!/usr/bin/env swift` shebang) that:
- Walks the on-disk `parakeet-tdt-0.6b-v3` model directory
- Enumerates **leaf files** inside `.mlmodelc` directories (not top-level `.mlpackage` names -- RESEARCH Pitfall #1)
- Computes SHA-256 per leaf file using CryptoKit chunked hashing (256KB chunks via FileHandle)
- Emits JSON conforming to `ModelManifest.Codable` with `model_id`, `version`, `min_app_version`, `total_size_bytes`, `released_at`, and `files[]`
- HuggingFace URL pattern: `https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v3-coreml/resolve/main/{name}`

CLI arguments: `--version=`, `--min-app=`, `--models-dir=` (defaults: today yyyyMMdd UTC, "1.2.0", live ~/Library path).

**Verified against live model directory:** 23 leaf files, 483 MB total, valid JSON parseable by Python `json.load`.

### Task 3: 17-VERIFICATION.md + Release Prerequisite

Replaced the Plan 17-04 smoke-test stub with the full Phase 17 verification record:
- SC-1 through SC-5 success criteria checkboxes
- MODEL-01 through MODEL-10 requirement traceability table (covered-by, test name, status)
- Plan 17-04 smoke-test deferral notes preserved verbatim (A through I, user-approved 2026-04-27)
- Plan 17-05 backfill smoke test checklist
- RELEASE PREREQUISITE section: step-by-step manifest publication procedure for v1.2 launch

**Task 4 (checkpoint:human-verify):** Paused. The full A-through-E smoke test requires the live manifest to be published (release-time step). Unit test substitute for backfill verification: `swift test --filter "ModelUpdateServiceTests/backfillFiresWhenAllConditionsMet"` passes and covers the core D-14 scenario.

## Task Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 RED | `16551bc` | 5 failing D-14 backfill tests |
| 1 GREEN | `82490a7` | backfillInstalledVersionIfNeeded implementation |
| 2 | `04e0ed3` | Scripts/generate-model-manifest.swift |
| 3 | `b2f38fe` | 17-VERIFICATION.md full record + release prerequisite |

## Deviations from Plan

### Auto-fixed Issues

None -- plan executed exactly as written. The TDD cycle matched the spec precisely. The `backfillSurvivesAttributeReadFailure` test exercises the "non-existent path" scenario rather than an actual permissions failure (which cannot be reliably simulated in a sandboxed test), but the behavior is identical: `fileExists` returns false, backfill returns early, no crash.

## Known Stubs

None in this plan. The only intentional deferral is the live manifest publication to `cnewfeldt/ps-transcribe-releases:main`, which is a release-time step documented as a release prerequisite rather than a code stub.

## Threat Surface Scan

No new network endpoints, auth paths, or file access patterns introduced beyond what the plan's threat model covers:
- T-17-05-01 (backfill misfires on partial install): mitigated by conjunctive conditions
- T-17-05-06 (malicious manifest draining disk): existing Plan 17-02 disk preflight + SHA-256 verify still applies; backfill specifically does NOT download anything

`Scripts/generate-model-manifest.swift` reads only the public model directory (no PII, no secrets, no env vars). Output is written to stdout for the developer to pipe to their destination.

## Release Handoff

Phase 17 is code-complete. The only step outside this worktree is publishing the initial manifest:

```bash
swift Scripts/generate-model-manifest.swift --version=20260427 --min-app=1.2.0 > model-manifest.json
# then push to cnewfeldt/ps-transcribe-releases:main
```

Full procedure: `.planning/phases/17-model-auto-update/17-VERIFICATION.md` -- RELEASE PREREQUISITE section.

## Self-Check: PASSED

| Item | Result |
|------|--------|
| `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift` contains `backfillInstalledVersionIfNeeded` | FOUND |
| `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift` contains `D-14` | FOUND |
| `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift` contains `attributesOfItem` | FOUND |
| `Scripts/generate-model-manifest.swift` exists and is executable | FOUND |
| `.planning/phases/17-model-auto-update/17-VERIFICATION.md` contains SC-1..5 and MODEL-01..10 | FOUND |
| Commit `16551bc` (RED tests) | FOUND |
| Commit `82490a7` (GREEN implementation) | FOUND |
| Commit `04e0ed3` (script) | FOUND |
| Commit `b2f38fe` (VERIFICATION.md) | FOUND |
| `swift build` exits 0 | VERIFIED |
| All 5 backfill tests pass | VERIFIED |
| 60/60 Phase 17 suite tests pass | VERIFIED |
| Package.swift / Package.resolved unchanged (Pitfall #15) | VERIFIED |
