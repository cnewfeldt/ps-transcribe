---
status: partial
phase: 11-website-scaffolding-vercel-deployment
source: [11-VERIFICATION.md]
started: 2026-04-22T00:00:00Z
updated: 2026-04-22T00:00:00Z
---

## Current Test

[awaiting natural trigger — first PR touching /website, first Swift-only commit on main]

## Tests

### 1. PR preview URL with Vercel bot comment (SITE-03)
expected: PR page shows a comment from the Vercel GitHub App with a URL of the form `https://ps-transcribe-web-git-<branch>-<user>.vercel.app` that returns 200 and serves the branch build
result: [pending]
deferred_trigger: first PR touching /website (expected from phase 12 onward)

### 2. Ignored Build Step skips Swift-only commits (D-09)
expected: After a Swift-only commit lands on main, Vercel deployments list shows a Canceled deploy with status "Ignored Build Step"; no new production build produced
result: [pending]
deferred_trigger: first Swift-only commit on main post phase 11

## Summary

total: 2
passed: 0
issues: 0
pending: 2
skipped: 0
blocked: 0

## Gaps
