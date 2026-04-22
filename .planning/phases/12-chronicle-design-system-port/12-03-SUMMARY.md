---
phase: 12
plan: 03
subsystem: website/ui
tags: [react, tailwind, design-tokens, chronicle, primitives, server-components]

dependency_graph:
  requires:
    - phase: 12
      plan: 01
      provides: Chronicle @theme inline tokens (bg-paper, text-ink, rounded-card, shadow-btn, font-*)
  provides:
    - Five named-export server components in website/src/components/ui/
    - Barrel export at @/components/ui for clean single-line imports
  affects:
    - 12-04-showcase (Plan 04 -- showcase page imports all five primitives)
    - 13-15 (landing, docs, changelog pages compose against this primitive surface)

tech-stack:
  added: []
  patterns:
    - "Server component primitive pattern: named export, spreads ...rest, no use client, no forwardRef, no cn() helper"
    - "Discriminated string union for variants: Record<NonNullable<ButtonProps['variant']>, string> keyed variant map"
    - "Polymorphic element via createElement: SectionHeading accepts as prop without JSX conditional chain"
    - "Tailwind arbitrary values for sub-pixel borders: border-[0.5px] for 0.5px hairlines per D-11"

key-files:
  created:
    - website/src/components/ui/Button.tsx
    - website/src/components/ui/Card.tsx
    - website/src/components/ui/MetaLabel.tsx
    - website/src/components/ui/SectionHeading.tsx
    - website/src/components/ui/CodeBlock.tsx
    - website/src/components/ui/index.ts
  modified: []

decisions:
  - "No cn() helper or tailwind-merge: className composition done via template literal with .trim(), consistent with D-07 minimal deps constraint"
  - "MetaLabel ships without tone prop: deferred to Phase 13 per D-07 minimal props surface rule"
  - "CodeBlock renders children via React text interpolation only, no dangerouslySetInnerHTML -- T-12-01 mitigation verified by grep probe"
  - "pnpm install required before build (node_modules absent in worktree) -- pre-existing worktree environment gap, not a code deviation"

metrics:
  duration: ~8 minutes
  completed: 2026-04-22
  tasks_completed: 1
  tasks_total: 1
  files_modified: 6

requirements_completed: [DESIGN-03]
---

# Phase 12 Plan 03: UI Primitives Summary

Five presentational React server-component primitives (Button, Card, MetaLabel, SectionHeading, CodeBlock) plus barrel export, composing Chronicle tokens from Plan 01 via Tailwind v4 utility strings -- no external deps, no dark-mode variants, no forwardRef.

## Performance

- **Duration:** ~8 min
- **Completed:** 2026-04-22
- **Tasks:** 1
- **Files created:** 6

## Line Counts

| File | Lines | Target |
|------|-------|--------|
| Button.tsx | 20 | 30 or fewer |
| Card.tsx | 13 | 30 or fewer |
| MetaLabel.tsx | 14 | 30 or fewer |
| SectionHeading.tsx | 21 | 30 or fewer |
| CodeBlock.tsx | 30 | 30 or fewer |
| index.ts | 5 | -- |

All primitives meet the 30-line target.

## Conformance Verification

| Check | Result |
|-------|--------|
| No `"use client"` in any file | PASS |
| No `@apply` in any file | PASS |
| No `forwardRef` in any file | PASS |
| No `dark:` variants (strict: bg/text/border/ring) | PASS |
| No `dark:` variants (loose belt-and-suspenders) | PASS |
| No `dangerouslySetInnerHTML` (T-12-01) | PASS |
| `pnpm run build` exits 0 | PASS |

## Primitive className Signatures

These are the exact class strings each primitive emits (for Plan 04 DOM matching):

### Button (primary)

```
inline-flex items-center gap-2 px-4 py-[10px] rounded-btn font-sans text-[14px] font-medium leading-none transition-colors duration-[120ms] focus-visible:outline focus-visible:outline-2 focus-visible:outline-accent-ink focus-visible:outline-offset-2 bg-ink text-paper shadow-btn hover:bg-[#2a2a25]
```

### Button (secondary)

```
inline-flex items-center gap-2 px-4 py-[10px] rounded-btn font-sans text-[14px] font-medium leading-none transition-colors duration-[120ms] focus-visible:outline focus-visible:outline-2 focus-visible:outline-accent-ink focus-visible:outline-offset-2 bg-paper text-ink border-[0.5px] border-rule-strong hover:bg-paper-soft
```

### Card

```
bg-paper border-[0.5px] border-rule rounded-card p-[22px]
```

### MetaLabel

```
font-mono text-[10px] uppercase tracking-[0.08em] leading-none text-ink-faint
```

### SectionHeading (h2 default)

```
font-serif font-normal text-[clamp(26px,3vw,32px)] leading-[1.15] tracking-[-0.01em] text-ink
```

### CodeBlock (inline)

```
font-mono text-[14px] bg-paper-soft text-ink px-[6px] py-[2px] rounded-[4px]
```

### CodeBlock (block)

```
font-mono text-[14px] bg-paper-soft text-ink border-[0.5px] border-rule rounded-card p-4 overflow-x-auto
```
(wraps `<pre>` around inner `<code>`)

## Commits

| Task | Commit | Files |
|------|--------|-------|
| 1: Create all five primitives + barrel export | b159337 | 6 files created |

## Deviations from Plan

None -- plan executed exactly as written. `pnpm install` required before build (node_modules absent in worktree) -- pre-existing worktree environment setup gap identical to Plan 01, not a code deviation.

## Known Stubs

None. All primitives accept caller-provided children with no hardcoded placeholder text or empty data flowing to UI rendering.

## Threat Flags

None. These primitives are purely presentational server components. No new network endpoints, auth paths, file access patterns, or schema changes introduced. T-12-01 (CodeBlock XSS) is actively mitigated: children render via React text interpolation, `dangerouslySetInnerHTML` absent (verified by grep probe).

## Next Step

Plan 04 renders the `/design-system` showcase gallery by importing from `@/components/ui` and composing all five primitives with Chronicle token values as props and content.

## Self-Check: PASSED

- `website/src/components/ui/Button.tsx` -- confirmed exists
- `website/src/components/ui/Card.tsx` -- confirmed exists
- `website/src/components/ui/MetaLabel.tsx` -- confirmed exists
- `website/src/components/ui/SectionHeading.tsx` -- confirmed exists
- `website/src/components/ui/CodeBlock.tsx` -- confirmed exists
- `website/src/components/ui/index.ts` -- confirmed exists
- Commit `b159337` -- confirmed in git log
