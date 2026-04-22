---
phase: 12
plan: 02
subsystem: website/layout
tags: [next.js, viewport, light-mode, typography, layout]
dependency_graph:
  requires: []
  provides: [viewport-color-scheme-meta, body-font-resolution]
  affects: [website/src/app/layout.tsx]
tech_stack:
  added: []
  patterns: [Next.js Viewport export API, Tailwind built-in utilities on body]
key_files:
  created: []
  modified:
    - website/src/app/layout.tsx
decisions:
  - Option A body cleanup: dropped inline fontFamily style, used only Tailwind built-in utilities (font-sans antialiased) so Plan 02 stays at wave 1 with no depends_on; bg/color resolved by Plan 01 body reset via CSS custom properties
metrics:
  duration: "~5 minutes"
  completed: "2026-04-22T23:12:29Z"
  tasks_completed: 1
  tasks_total: 1
  files_modified: 1
requirements_completed: [DESIGN-02, DESIGN-04]
---

# Phase 12 Plan 02: Layout Viewport Summary

Viewport export with `colorScheme: 'light'` added to `website/src/app/layout.tsx`, completing DESIGN-04 layer 3 (the `<meta name="color-scheme" content="light">` HTML signal emitted before CSS paints).

## What Was Built

Four surgical changes to `website/src/app/layout.tsx`:

1. **Viewport type import** -- Added `Viewport` to the `import type { Metadata, Viewport } from 'next'` line.

2. **Viewport export** -- Added `export const viewport: Viewport = { colorScheme: 'light' }` after the metadata block. Next.js 16 emits this as `<meta name="color-scheme" content="light">` in every page `<head>` at build time, before CSS loads -- the final layer of the three-layer light-mode defense.

3. **Body cleanup** -- Replaced `style={{ fontFamily: 'var(--font-inter), system-ui, sans-serif' }}` with `className="font-sans antialiased"`. Uses only Tailwind built-in utilities; no Plan-01-dependent tokens (`bg-paper`, `text-ink`) on the body element. Font resolution still flows through `--font-inter` via Plan 01's `@theme inline` composition. Plan 02 stays at `wave: 1` / `depends_on: []`.

4. **Em-dash fix** -- Replaced `—` (U+2014) with `--` in `metadata.title.default` per global style guide.

## Font Loading Confirmation

The following lines were NOT modified (Phase 11 lock per D-11):

```tsx
import { Inter, Spectral, JetBrains_Mono } from 'next/font/google'

const inter = Inter({ subsets: ['latin'], display: 'swap', variable: '--font-inter' })
const spectral = Spectral({ subsets: ['latin'], display: 'swap', weight: ['400', '600'], variable: '--font-spectral' })
const jetbrainsMono = JetBrains_Mono({ subsets: ['latin'], display: 'swap', variable: '--font-jetbrains-mono' })

<html className={`${inter.variable} ${spectral.variable} ${jetbrainsMono.variable}`}>
```

`next/font/google` self-hosts webfonts during build; no runtime Google Fonts fetch.

## Body className Confirmation

Body uses ONLY Tailwind built-in utilities:

```tsx
<body className="font-sans antialiased">
```

No `bg-paper`, no `text-ink`, no Plan-01-dependent utilities. Plan 02 remains at `wave: 1` with `depends_on: []`.

## Commits

| Task | Commit | Files |
|------|--------|-------|
| 1: Add Viewport export, body cleanup, em-dash fix | aca9504 | website/src/app/layout.tsx |

## Verification

All acceptance criteria passed:

- `import type { Metadata, Viewport } from 'next'` -- PASS
- `export const viewport: Viewport` -- PASS
- `colorScheme: 'light'` -- PASS
- `next/font/google` import preserved -- PASS
- `Inter|Spectral|JetBrains_Mono` preserved -- PASS
- No `metadata.colorScheme` -- PASS
- No em-dashes (U+2014) -- PASS
- No `style={{ fontFamily:` -- PASS
- `className="font-sans antialiased"` -- PASS
- No `bg-paper` or `text-ink` on body -- PASS
- `pnpm run build` -- exit 0, 9 static pages generated

## Deviations from Plan

None -- plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None. This plan only modifies server-rendered layout metadata. No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries.

## Next Steps

- Plan 03: Build Chronicle design-system primitives (colors, typography tokens)
- Plan 04: Verify `<meta name="color-scheme" content="light">` via `curl` probe after `pnpm run build && pnpm run start`

## Self-Check: PASSED

- `website/src/app/layout.tsx` -- confirmed modified
- Commit `aca9504` -- confirmed in git log
