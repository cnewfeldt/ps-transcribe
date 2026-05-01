---
status: partial
phase: 21-appearance-override
source: [21-VERIFICATION.md]
started: 2026-05-01T20:20:33Z
updated: 2026-05-01T20:20:33Z
---

## Current Test

[awaiting human testing — post-fix titlebar visual UAT]

## Tests

### 1. Scenario A revisited — titlebar strip flips to Dark when picker = Dark while macOS = Light
expected: Main window titlebar strip flips dark (no cream paper background, dynamic system label color on toolbar title), and re-flips to cream when picker is set back to Light or System (with macOS in Light). The cream Chronicle paper background must NOT persist over a dark-rendered SwiftUI content area.
result: [pending]

### 2. Scenario B revisited — titlebar strip flips to Light when picker = Light while macOS = Dark
expected: Main window titlebar strip flips light (cream Chronicle paper background returns) when picker = Light and the resolved effectiveAppearance is Aqua. Toolbar centered title text remains legible (uses NSColor.labelColor).
result: [pending]

### 3. Scenario C revisited — System mode follows live macOS Light↔Dark toggle on the titlebar
expected: With picker = System, toggling System Settings → Appearance from Light → Dark → Light propagates to the titlebar strip without app restart. Cream paint shows under Aqua effective appearance and clears under Dark Aqua effective appearance.
result: [pending]

### 4. Settings window titlebar early-return behavior under preference change
expected: The Settings window keeps its native AppKit titlebar (no Chronicle paper paint) and continues to render correctly across all three picker values. Only the main window receives Chronicle styling; Settings keeps the system titlebar appearance per the early-return at applyChronicleTitlebar (lines 342–348).
result: [pending]

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps
