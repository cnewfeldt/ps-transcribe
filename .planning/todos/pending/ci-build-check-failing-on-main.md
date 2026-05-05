---
title: Build Check workflow fails on macos-26 runner
status: pending
created: 2026-05-05
priority: high
blocking: false
source: phase-24
---

## Context

Phase 24 added a `push: branches: [main]` trigger to `.github/workflows/build-check.yml` so the Build Check job runs on direct pushes to main (not just PRs). This surfaced two pre-existing CI failures that were latent because Phase 23's CI never actually fired on main pushes.

## Issue 1: Swift 6 strict-concurrency errors (blocking the build step)

`PSTranscribe/Sources/PSTranscribe/Transcription/TranscriptionEngine.swift` fails to compile on the runner with:

```
error: sending 'self' risks causing data races [#SendingRisksDataRace]
  at line 238: guard let self else { return }
  at line 342: guard let self else { return }
```

Both sites are inside `Task.detached { [weak self] in ... await MainActor.run { guard let self } }` patterns. Code is from commit `2a2e7af6` (2026-04-02), well before Phase 24.

**Why local passes:** Same toolchain (Swift 6.3.1, arm64-apple-macosx26.0), but the user's local Xcode resolves the `await MainActor.run { guard let self }` differently than the runner's fallback Xcode (see Issue 2).

**Suggested fixes:**
- Capture `self` (or `lastError` setter) before the `Task.detached` and pass it in explicitly, or
- Use `[weak self]` capture in the inner `MainActor.run` closure too instead of relying on the outer one's `self`, or
- Restructure to avoid the cross-actor send

## Issue 2: Xcode 26 not present on runner; falls back silently

`build-check.yml` step `Select Xcode 26` runs:

```yaml
sudo xcode-select -s /Applications/Xcode_26.app || sudo xcode-select -s /Applications/Xcode.app
```

The runner reports `xcode-select: error: invalid developer directory '/Applications/Xcode_26.app'` and silently falls back to default `Xcode.app`. This means the Build Check is no longer pinned to Xcode 26 — it's running on whatever the runner image's default is.

**Suggested fixes:**
- Use `xcodes select 26.x` via the maxim-lobanov/setup-xcode action, or
- Detect the actual Xcode 26 path on macos-26 (may be `/Applications/Xcode_26.0.0.app` or similar), or
- Pin to a specific Xcode version that matches the local toolchain

## Why deferred from Phase 24

Phase 24 was a Nyquist sweep — backfill VALIDATION contracts for v1.0 phases that shipped without test coverage. All 5 plans completed, all 5 contracts approved, 10 new test files added (262 tests / 51 suites passing locally, +26 / +9 from Phase 23 baseline), SHA-pin regression on `build-check.yml:56` fixed.

These CI issues are pre-existing infrastructure debt that surfaced when Phase 24 added the `push:` trigger. Fixing them is non-trivial (real production code changes for the data race + runner image investigation for Xcode 26) and orthogonal to the Nyquist sweep's scope.

## Acceptance criteria for closing this todo

- [ ] `gh run view` for a push to main shows the `Build Check` workflow completing successfully
- [ ] Build step compiles `TranscriptionEngine.swift` with no errors
- [ ] `Select Xcode 26` step uses Xcode 26 (not the silent fallback)
- [ ] Local `swift test` parity confirmed (262+ tests / 51+ suites passing)
