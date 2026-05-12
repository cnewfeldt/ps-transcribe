---
title: Model manifest URL returns HTTP 404 — no model updates can ship
status: pending
created: 2026-05-11
priority: high
blocking: false
source: phase-26
---

## Context

Surfaced incidentally during Phase 26 QA sweep while attempting to test QA-05 (disk-space preflight warning). The model manifest URL `https://raw.githubusercontent.com/cnewfeldt/ps-transcribe-releases/main/model-manifest.json` returns HTTP 404 in production. Verified 2026-05-11 via `curl -sI`. This means `ModelUpdateService.checkForUpdate()` always fails with `manifestFetchFailed(statusCode: 404)`, and `ModelUpdateService.downloadAndApply()` is unreachable. No model updates can ever ship to users in the current released app, and the QA-05 disk-space preflight test cannot be exercised end-to-end until this is resolved.

## Issue

**Reproduction:** Open PS Transcribe Settings -> Speech Models section -> click "Check for Updates". Status flips to "Update failed: failed to fetch model manifest (HTTP 404)".

**Code paths involved:**
- `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift:21` -- `private let modelManifestURL = URL(string: "https://raw.githubusercontent.com/cnewfeldt/ps-transcribe-releases/main/model-manifest.json")!`
- `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift:175-189` -- `fetchManifest()` raises `ModelUpdateError.manifestFetchFailed(statusCode: 404)`

**Suggested fixes (one of):**
- Publish a real `model-manifest.json` to the `cnewfeldt/ps-transcribe-releases` repo on the `main` branch (deployment / release-process work -- outside this codebase's source tree).
- Update the `modelManifestURL` constant to a known-good live endpoint (1-line code change in this repo, but only valid if a working endpoint already exists somewhere).
- Both -- publish AND update if the canonical URL has moved.

## Why deferred from Phase 26

Phase 26 is a manual QA sweep producing `26-UAT.md`. The 404 is a release/deployment-process gap, not a QA scenario per se. It surfaced as the blocker for QA-05 (which is consequently UNTESTABLE-this-cycle). The fix needs product/release-process context that is beyond Phase 26's scope.

## Acceptance criteria for closing this todo

- [ ] `curl -sI "<resolved manifest URL>"` returns HTTP 200
- [ ] In a debug build of PS Transcribe, Settings -> Speech Models -> Check for Updates returns either "Update available" or "Up to date" (NOT a manifest-fetch failure)
- [ ] QA-05 (disk-space preflight warning) becomes testable end-to-end via the debug-only `diskSpaceProvider` override mechanism documented in `.planning/phases/26-qa-sweep-visual-uat/26-01-PLAN.md` Task 8

## Cross-references

- `.planning/phases/26-qa-sweep-visual-uat/26-UAT.md` -- QA-05 row (UNTESTABLE-this-cycle, this todo cited as the blocker)
- `PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift:21` -- manifest URL constant
