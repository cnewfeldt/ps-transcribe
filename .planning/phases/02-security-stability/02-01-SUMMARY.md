---
phase: 02-security-stability
plan: "01"
subsystem: ci-cd
tags: [security, ci, github-actions, gitignore, hardening]
dependency_graph:
  requires: []
  provides: [hardened-ci-workflows, secret-file-gitignore]
  affects: [.github/workflows/release-dmg.yml, .github/workflows/build-check.yml, .gitignore]
tech_stack:
  added: []
  patterns: [sha-pinned-actions, mktemp-temp-files, gh-cli-auth, explicit-error-logging]
key_files:
  created: []
  modified:
    - .github/workflows/release-dmg.yml
    - .github/workflows/build-check.yml
    - .gitignore
decisions:
  - "find 2>/dev/null removed in addition to security delete-keychain suppression -- plan said ALL instances, consistent with zero-suppression goal"
  - "actions/checkout SHA 34e114876b0b11c390a56381ad16ebd13914f8d5 verified via git ls-remote at execution time"
  - "actions/upload-artifact SHA ea165f8d65b6e75b540449e92b4886f43607fa02 verified via git ls-remote at execution time"
metrics:
  duration_minutes: 8
  completed_date: "2026-04-03"
  tasks_completed: 2
  files_modified: 3
---

# Phase 02 Plan 01: CI/CD Security Hardening Summary

**One-liner:** Eliminated GH_TOKEN URL exposure, predictable keychain paths, unpinned action SHAs, missing .gitignore secret patterns, and error suppression from CI workflows.

## What Was Done

Applied all five CI security findings (SCAN-001, SCAN-005, SCAN-007, SCAN-008, SCAN-012) from the security scan.

### Task 1: release-dmg.yml (SECR-01, SECR-05, SECR-07, SECR-12)

**Commit:** 219436b

- **SECR-01**: Replaced `git clone "https://x-access-token:${GH_TOKEN}@github.com/..."` with `gh repo clone OWNER/ps-transcribe /tmp/gh-pages -- --branch gh-pages --single-branch`. The gh CLI reads `GH_TOKEN` from env automatically -- no token in URLs or logs.
- **SECR-05**: Replaced predictable `/tmp/build-$$-$(date +%s).keychain-db` with `mktemp /tmp/keychain.XXXXXX.keychain-db`. PID + epoch timestamp was guessable; mktemp uses OS-level randomness.
- **SECR-07**: Pinned `actions/checkout@v4` to `actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5 # v4` and `actions/upload-artifact@v4` to `actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02 # v4`. SHAs verified via `git ls-remote` at execution time.
- **SECR-12**: Replaced `security delete-keychain "$KEYCHAIN_FILE" 2>/dev/null || true` with explicit `if !` guard that echoes warning to stderr on failure.

### Task 2: build-check.yml + .gitignore (SECR-07, SECR-08)

**Commit:** ada5f4b

- **SECR-07**: Pinned `actions/checkout@v4` to the same verified SHA in build-check.yml.
- **SECR-08**: Added secret file pattern block to .gitignore: `.env`, `*.env.*`, `*.p12`, `*.cer`, `*.pem`, `*.key`, `*.keychain`, `*.keychain-db`, `*.mobileprovision`, `*.xcconfig`. Verified with `git check-ignore test.p12`.

## Verification Results

All plan-level verification checks passed:

```
grep -rn 'x-access-token' .github/workflows/  -> PASS (0 results)
grep -rn '@v4' .github/workflows/             -> PASS (0 results)
grep -rn '2>/dev/null' .github/workflows/     -> PASS (0 results)
grep -c 'mktemp' .github/workflows/release-dmg.yml -> PASS (2 occurrences)
git check-ignore test.p12                     -> PASS (test.p12 ignored)
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Completeness] Removed find 2>/dev/null in addition to security delete-keychain suppression**
- **Found during:** Task 1
- **Issue:** Plan specified SECR-12 fix for the `security delete-keychain` cleanup line, but also stated "Apply this pattern to ALL instances of `2>/dev/null` in the file." A `find ... 2>/dev/null` on the sign_update discovery line was also present.
- **Fix:** Removed `2>/dev/null` from the `find` command. The directory always exists post-build so suppression was masking potential path issues. This also satisfies the zero-suppression goal and the plan's ALL-instances directive.
- **Files modified:** .github/workflows/release-dmg.yml
- **Commit:** 219436b

## Known Stubs

None -- no placeholder values or wired-but-empty data in these files. The `OWNER/ps-transcribe` placeholder is a pre-existing intentional stub from Phase 1 (pending GitHub repo creation) and is explicitly preserved per Phase 1 decision.

## Self-Check: PASSED
