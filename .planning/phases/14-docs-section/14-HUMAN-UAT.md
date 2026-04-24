---
status: partial
phase: 14-docs-section
source: [14-VERIFICATION.md]
started: 2026-04-24T17:00:00Z
updated: 2026-04-24T17:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Three-column layout at >= 1200px viewport
expected: Sidebar visible on left (240px), article in middle (720px max), 'On this page' TOC on right (200px)
result: [pending]

### 2. Responsive collapse across viewport widths (1400px → 400px)
expected: TOC disappears below 1200px; sidebar disappears below 820px (md breakpoint); article remains readable at all widths
result: [pending]

### 3. TOC scroll-spy active-state tracking
expected: On /docs/getting-started, scrolling highlights the active H2/H3 heading in the right-hand TOC (border-l-accent-ink + text-ink) as it enters view
result: [pending]

### 4. Sidebar active-state visual styling
expected: Visiting /docs/getting-started then /docs/faq, the current page's sidebar link renders with bg-paper + border-rule + shadow-lift + font-medium (visibly different from idle links)
result: [pending]

### 5. /docs redirect behavior
expected: Visiting /docs updates browser URL to /docs/getting-started and renders the Getting Started page
result: [pending]

### 6. Inline code pill styling
expected: Inline code spans (e.g. `~/Applications` in getting-started) render in JetBrains Mono on a paperSoft (#EEEAE0) pill background with 4px radius
result: [pending]

### 7. Fenced code block styling
expected: Fenced blocks (e.g. the YAML block on getting-started) render on paper-warm background, 0.5px rule border, 8px radius, uppercase lang label (YAML) in top-right
result: [pending]

## Summary

total: 7
passed: 0
issues: 0
pending: 7
skipped: 0
blocked: 0

## Gaps
