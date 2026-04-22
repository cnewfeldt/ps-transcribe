---
phase: 12-chronicle-design-system-port
plan: 01
subsystem: ui
tags: [tailwind, css, design-tokens, chronicle, tailwind-v4, next-js]

# Dependency graph
requires:
  - phase: 11-website-scaffolding-vercel-deployment
    provides: Next.js 15/16 scaffold at /website, next/font variables --font-inter, --font-spectral, --font-jetbrains-mono wired in layout.tsx

provides:
  - Chronicle design token source of truth in website/src/app/globals.css
  - 16 color tokens under --color-* Tailwind v4 namespace (bg-paper, text-ink, etc.)
  - 5 radius tokens under --radius-* namespace (rounded-card, rounded-pill, etc.)
  - 3 shadow tokens under --shadow-* namespace (shadow-lift, shadow-btn, shadow-float)
  - 3 font-family chains composing next/font variables with cross-platform fallbacks
  - Light-mode lock via html { color-scheme: light }
  - @theme inline re-export enabling all Chronicle tokens as Tailwind utilities

affects:
  - 12-02-layout-viewport (next plan -- viewport export, font metadata)
  - 12-03-primitives (Plan 03 -- all primitives consume bg-paper, rounded-card, shadow-btn)
  - 12-04-showcase (Plan 04 -- showcase pages built on primitives)
  - all subsequent plans in phase 12 and 13-15 that reference Chronicle utilities

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Tailwind v4 @theme inline pattern: declare raw values in :root, re-export as var() references in @theme inline so utilities resolve through CSS custom properties at runtime (not baked-in hex values)"
    - "Hybrid token approach (D-01): tokens declared once in :root, consumed by both Tailwind utilities (via @theme inline) and inline styles (via var(--color-*))"
    - "Light-mode lock pattern: html { color-scheme: light } prevents OS dark-mode from flipping native UA controls"

key-files:
  created: []
  modified:
    - website/src/app/globals.css

key-decisions:
  - "Tailwind v4 @theme inline re-exports use var() references (not raw hex values) so that :root remains the single source of truth -- changing a token value in :root propagates to all utilities automatically"
  - "Font fallback chains compose next/font CSS variables as primary with cross-platform fallbacks (SF Pro Text, New York, SF Mono) -- webfont failure degrades gracefully to system fonts"
  - "Dark-mode media query stripped entirely per D-13; color-scheme: light on html per D-14"

patterns-established:
  - "Token prefix convention: bare tokens.css names (--paper, --r-card) map to Tailwind-v4-prefixed names (--color-paper, --radius-card) in globals.css"
  - "All Chronicle CSS tokens declared in :root, re-exported in @theme inline -- no token duplication across files"

requirements-completed: [DESIGN-01, DESIGN-02, DESIGN-04]

# Metrics
duration: ~10min
completed: 2026-04-22
---

# Phase 12 Plan 01: Chronicle Design Token Source of Truth

**16-color Chronicle palette + 5 radii + 3 shadows + 3 font chains exported as Tailwind v4 utilities via @theme inline, with dark-mode permanently locked to light**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-04-22T00:00:00Z
- **Completed:** 2026-04-22
- **Tasks:** 2 (1 file rewrite, 1 build verification)
- **Files modified:** 1

## Accomplishments

- Replaced 27-line create-next-app placeholder with 86-line Chronicle token source of truth
- All 16 color tokens (`--color-paper` through `--color-live-green`), 5 radius tokens, and 3 shadow tokens declared in `:root` and re-exported via `@theme inline`
- Font-family chains compose `--font-inter`, `--font-spectral`, `--font-jetbrains-mono` (from Phase 11 layout.tsx) with cross-platform fallbacks
- `pnpm run build` exits 0 -- Tailwind v4 ingested `@theme inline` cleanly, no TypeScript errors
- Dark-mode media query removed; `html { color-scheme: light }` locks native UA controls

## Before / After

| Metric | Before | After |
|--------|--------|-------|
| Line count | 27 | 86 |
| Color tokens | 2 (`--background`, `--foreground`) | 16 Chronicle colors |
| Radius tokens | 0 | 5 |
| Shadow tokens | 0 | 3 |
| Font chains | 2 (Geist) | 3 (Inter/Spectral/JetBrains with fallbacks) |
| Dark-mode block | Yes (`@media prefers-color-scheme: dark`) | Removed |
| Light-mode lock | No | Yes (`color-scheme: light`) |
| Geist references | Yes (`--font-geist-sans`, `--font-geist-mono`) | None |

## Token Inventory

### Colors (16)
| Token | Raw Value |
|-------|-----------|
| `--color-paper` | `#FAFAF7` |
| `--color-paper-warm` | `#F4F1EA` |
| `--color-paper-soft` | `#EEEAE0` |
| `--color-rule` | `rgba(30, 30, 28, 0.08)` |
| `--color-rule-strong` | `rgba(30, 30, 28, 0.14)` |
| `--color-ink` | `#1A1A17` |
| `--color-ink-muted` | `#595954` |
| `--color-ink-faint` | `#8A8A82` |
| `--color-ink-ghost` | `#B8B8AF` |
| `--color-accent-ink` | `#2B4A7A` |
| `--color-accent-soft` | `#DFE6F0` |
| `--color-accent-tint` | `#F1F4F9` |
| `--color-spk2-bg` | `#E6ECEA` |
| `--color-spk2-fg` | `#2D4A43` |
| `--color-spk2-rail` | `#7FA093` |
| `--color-rec-red` | `#C24A3E` |
| `--color-live-green` | `#4A8A5E` |

### Radii (5)
| Token | Value |
|-------|-------|
| `--radius-input` | `4px` |
| `--radius-btn` | `6px` |
| `--radius-card` | `10px` |
| `--radius-bubble` | `12px` |
| `--radius-pill` | `999px` |

### Shadows (3)
| Token | Value |
|-------|-------|
| `--shadow-lift` | `0 1px 3px rgba(30, 30, 28, 0.08)` |
| `--shadow-btn` | `0 1px 2px rgba(30, 30, 28, 0.20), inset 0 1px 0 rgba(255, 255, 255, 0.08)` |
| `--shadow-float` | `0 8px 24px rgba(30, 30, 28, 0.12), 0 1px 3px rgba(30, 30, 28, 0.06)` |

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite globals.css with full Chronicle token set** - `600f9da` (feat)
2. **Task 2: Build verification** - no commit (build-only check, no files modified)

## Files Created/Modified

- `website/src/app/globals.css` -- Rewritten from 27-line placeholder to 86-line Chronicle token source: :root raw values, @theme inline re-exports, html light-mode lock, body reset

## Decisions Made

- Tailwind v4 `@theme inline` re-exports use `var()` references rather than raw hex values so `:root` stays the single source of truth (consistent with plan D-01)
- Font chains composed around `--font-inter` / `--font-spectral` / `--font-jetbrains-mono` (Phase 11 variables) -- not redeclared here
- `node_modules` were missing in the worktree; ran `pnpm install` before build check (pre-existing gap, not a plan deviation)

## Deviations from Plan

None -- plan executed exactly as written. `pnpm install` was needed before the build check but this is a worktree environment setup issue, not a code deviation.

## Issues Encountered

- `node_modules` absent in worktree at build time -- ran `pnpm install` (2s, packages reused from cache). Build succeeded immediately after.
- Workspace root warning from Next.js about multiple lockfiles is pre-existing (detected `/Users/cary/bun.lockb`) and unrelated to this plan. Not a build failure.

## Known Stubs

None -- globals.css emits only CSS tokens and standard Tailwind utilities. No placeholder text, no hardcoded empty values flowing to UI rendering.

## Threat Flags

None -- this plan rewrites static CSS tokens only. No new network endpoints, auth paths, file access patterns, or schema changes introduced. Trust surface unchanged from Phase 11 (T-12-03 accepted: next/font self-hosts fonts during build, no new supply-chain surface).

## Next Phase Readiness

- Plan 02 (layout viewport) can proceed immediately -- `globals.css` establishes the token foundation; `layout.tsx` is untouched and ready for viewport metadata additions
- Plan 03 (primitives) can consume `bg-paper`, `text-ink`, `text-ink-muted`, `rounded-card`, `rounded-bubble`, `shadow-btn`, `shadow-lift`, `font-sans`, `font-serif`, `font-mono` as Tailwind utilities
- All 16 `--color-*`, 5 `--radius-*`, and 3 `--shadow-*` tokens also available as `var(--color-*)` in inline styles and custom CSS

---
*Phase: 12-chronicle-design-system-port*
*Completed: 2026-04-22*
