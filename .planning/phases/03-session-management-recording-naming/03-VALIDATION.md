---
phase: 3
slug: session-management-recording-naming
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-02
---

# Phase 3 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing / XCTest (built into Swift 6.2) |
| **Config file** | None -- no test target exists yet (Wave 0 installs) |
| **Quick run command** | `swift test --package-path PSTranscribe` |
| **Full suite command** | `swift test --package-path PSTranscribe` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `swift test --package-path PSTranscribe`
- **After every plan wave:** Run `swift test --package-path PSTranscribe`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 0 | SESS-09 | unit | `swift test --filter LibraryStoreTests` | Wave 0 | pending |
| 03-01-02 | 01 | 0 | SESS-05, NAME-04 | unit | `swift test --filter LibraryEntryTests` | Wave 0 | pending |
| 03-01-03 | 01 | 0 | SESS-03 | unit | `swift test --filter TranscriptParserTests` | Wave 0 | pending |
| 03-01-04 | 01 | 0 | SESS-06 | unit | `swift test --filter ObsidianURLTests` | Wave 0 | pending |
| 03-01-05 | 01 | 0 | NAME-05 | unit | `swift test --filter TranscriptLoggerTests` | Wave 0 | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] Add `.testTarget(name: "PSTranscribeTests", ...)` to `PSTranscribe/Package.swift`
- [ ] `PSTranscribe/Tests/PSTranscribeTests/LibraryStoreTests.swift` -- covers SESS-09
- [ ] `PSTranscribe/Tests/PSTranscribeTests/LibraryEntryTests.swift` -- covers SESS-05, NAME-04
- [ ] `PSTranscribe/Tests/PSTranscribeTests/TranscriptParserTests.swift` -- covers SESS-03
- [ ] `PSTranscribe/Tests/PSTranscribeTests/ObsidianURLTests.swift` -- covers SESS-06

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Sidebar grid layout renders correctly | SESS-01 | SwiftUI visual layout | Build and inspect in preview/simulator |
| Clicking library entry loads transcript | SESS-02, SESS-03 | UI interaction flow | Click entry, verify transcript appears |
| Clicking file path opens Finder | SESS-07 | AppKit integration | Click path, verify Finder opens |
| Clicking Obsidian link opens Obsidian | SESS-08 | External app launch | Click link, verify Obsidian opens |
| NavigationSplitView layout at 640px+ | SESS-01 | Window size behavior | Resize window, verify split view |
| Top bar name field editing | NAME-01, NAME-02, NAME-03 | UI interaction | Type name, verify field updates |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
