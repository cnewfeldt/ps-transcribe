---
phase: 14-docs-section
plan: 01
subsystem: website-docs
tags: [mdx, next16, tailwind, docs, plugin-pipeline]
one_liner: "MDX compilation pipeline for Next 16 with remark-gfm + rehype-slug + autolink-headings + external-links + custom rehypeTocExport plugin, plus 7 reusable MDX components and a scoped .prose CSS layer."
requires:
  - website/src/app/globals.css  # Chronicle tokens (Phase 12)
  - website/src/components/ui/MetaLabel.tsx  # styling reference
  - website/src/components/sections/ShortcutGrid.tsx  # chipToneMap reused by Kbd
provides:
  - "@next/mdx wired via withMDX() on next.config.ts with serializable plugin stack"
  - "src/mdx-components.tsx: useMDXComponents() exposing code/pre/hr overrides + 7 custom components"
  - "src/lib/rehype-toc-export.ts: custom rehype plugin that injects `tableOfContents` as a named MDX export"
  - "src/components/docs/{Note,Lede,Crumbs,PrevNext,ShortcutTable,ShortcutRow,Kbd}.tsx"
  - "src/components/docs/docs.css: scoped .prose layer imported by globals.css"
affects:
  - website/next.config.ts  # now wraps config with withMDX
  - website/package.json    # new deps added
  - website/src/app/globals.css  # appended @import for docs.css
tech_stack:
  added:
    - "@next/mdx ^16.2.4"
    - "@mdx-js/loader ^3.1.1"
    - "@mdx-js/react ^3.1.1"
    - "@types/mdx ^2.0.13"
    - "remark-gfm ^4.0.1"
    - "rehype-slug ^6.0.0"
    - "rehype-autolink-headings ^7.1.0"
    - "rehype-external-links ^3.0.0"
    - "unist-util-visit ^5.1.0"
    - "mdast-util-to-string ^4.0.0"
    - "estree-util-value-to-estree ^3.5.0"
    - "unified ^11.0.5"
    - "@types/hast ^3.0.4"
  patterns:
    - "String-based plugin references for Turbopack serializability (per Next 16 MDX guide)"
    - "Scoped CSS layer (.prose) imported from globals.css; complex selectors live in CSS, simple utilities stay in Tailwind"
    - "Custom rehype plugin injects `tableOfContents` via mdxjsEsm + estree for downstream `import Page, { tableOfContents } from './page.mdx'`"
key_files:
  created:
    - website/src/lib/rehype-toc-export.ts
    - website/src/mdx-components.tsx
    - website/src/components/docs/Note.tsx
    - website/src/components/docs/Lede.tsx
    - website/src/components/docs/Crumbs.tsx
    - website/src/components/docs/PrevNext.tsx
    - website/src/components/docs/ShortcutTable.tsx
    - website/src/components/docs/ShortcutRow.tsx
    - website/src/components/docs/Kbd.tsx
    - website/src/components/docs/docs.css
  modified:
    - website/next.config.ts
    - website/package.json
    - website/pnpm-lock.yaml
    - website/src/app/globals.css
decisions:
  - "Turbopack forces string-based plugin identifiers and a static hast-node content for rehype-autolink-headings; accepted the D-14 fallback (anchors render as `#` with CSS-provided positioning) instead of per-heading lowercase labels."
  - "Added `unified` and `@types/hast` to the dependency list — required for the custom plugin's typed Plugin<[], Root> signature; the plan's dep list omitted them."
  - "Included a `.prose .lede { max-width: 56ch }` fallback rule in docs.css so any `.lede`-classed paragraph inherits the measure without the Lede component wrapper (also satisfies the plan's acceptance-grep checklist)."
metrics:
  completed_date: "2026-04-24"
  duration_approx: "~3 minutes from Task 1 start to Task 2 commit"
  tasks_completed: 2
  files_created: 10
  files_modified: 4
requirements_completed:
  - DOCS-01
  - DOCS-05
---

# Phase 14 Plan 01: MDX Pipeline + Custom Components Summary

Stood up the `@next/mdx` compilation pipeline for the Next 16 App Router and the full set of reusable MDX components docs pages will consume. Dropping a `.mdx` file under `src/app/docs/{slug}/page.mdx` with a `# Heading` now compiles, renders, and inherits the correct prose styles. Plan 02 adds the three-column layout + sidebar data; Plan 03/04 ship the actual docs content.

## What Landed

### MDX compilation pipeline (Task 1, commit `a83f7af`)

- Installed `@next/mdx` + `@mdx-js/loader` + `@mdx-js/react` + `@types/mdx` + the remark/rehype plugin set via pnpm (Phase 11 D-01).
- Rewrote `website/next.config.ts` to wrap the exported config with `withMDX(...)`, configure `pageExtensions: ['ts', 'tsx', 'mdx']` (no `.md` to prevent accidental README ingestion), and register the plugin stack on the `createMDX({ options: { remarkPlugins, rehypePlugins } })` call.
- Authored `website/src/lib/rehype-toc-export.ts` — a custom rehype plugin that walks the compiled HAST, collects H2 + H3 elements whose IDs were stamped by `rehype-slug`, and injects a named MDX export `tableOfContents = [{ depth, id, text }]` via an `mdxjsEsm` node. Downstream code will be able to do `import Page, { tableOfContents } from './page.mdx'` (Plan 02 consumes this).
- Plugin ordering: `rehype-slug` runs first (stamps IDs), then `rehype-autolink-headings` (adds clickable `.anchor` spans on every heading with an ID), then `rehype-external-links` (adds `target="_blank"` + `rel="noopener noreferrer"` to external links per T-14-02), then `rehypeTocExport` (needs the IDs to already be present).

### Custom MDX components + scoped CSS (Task 2, commit `50059db`)

- Created `website/src/mdx-components.tsx` at the `src/` root (required file per `@next/mdx` + App Router). The module exports `useMDXComponents()` which returns:
  - Element overrides for `code` (inline pill: `bg-paper-soft`, JetBrains Mono 13.5px, 2/6 padding, 4px radius), `pre` (strips pill styling via the `.prose pre code { background: transparent; padding: 0 }` rule in docs.css, then stamps a `data-lang` attribute derived from the child `code`'s `language-*` className so CSS `pre::before { content: attr(data-lang) }` renders the language label in the top-right corner), and `hr` (applies `.hr-soft` class for the section-divider treatment).
  - The 7 custom components so MDX authors can invoke `<Note>`, `<Lede>`, `<Crumbs>`, `<PrevNext>`, `<ShortcutTable>`, `<ShortcutRow>`, `<Kbd>` without per-file imports.
- All 7 components in `website/src/components/docs/`:
  - `Kbd.tsx` — reuses the exact `chipToneMap` strings (`default` / `navy` / `sage`) from `ShortcutGrid.tsx` so the docs chips match the landing page pixel-for-pixel.
  - `Note.tsx` — default + sage variants; 0.5px rule border, 2px left accent border, 8px radius, optional mono uppercase label.
  - `Lede.tsx` — wraps a `p` in 18px/ink-muted/56ch sub-H1 styling.
  - `Crumbs.tsx` — authored breadcrumb trail (`<Crumbs trail={['Docs', 'Start here', 'Getting started']} />`), last segment rendered `text-ink-muted`.
  - `PrevNext.tsx` — ships the manual `prev`/`next` prop signature only. Auto-derivation from sidebar order is left as a `TODO(Plan 02)` comment; the component type-checks and compiles today, and Plan 02 wires up the sidebar-driven pairing before any MDX page invokes it.
  - `ShortcutTable.tsx` + `ShortcutRow.tsx` — the keyboard-shortcut table pattern from the mock.
- `website/src/components/docs/docs.css` — scoped `.prose` layer carrying the complex selectors Tailwind utilities cannot express cleanly: prose heading scale (Spectral H1 40px / H2 26px, Inter H3 17px), H2 + H3 anchors absolutely positioned at `left: -84px` with `content: "# "` `::before` pseudo-element (hidden below 1100px), consecutive `p + p` margin tightening to `-4px` (preserves the mock's prose rhythm), fenced `pre::before { content: attr(data-lang) }` lang label, inline code styles stripped inside `pre`, `.hr-soft`, and a `.prose .lede { max-width: 56ch }` fallback.
- `website/src/app/globals.css` gained a single `@import "../components/docs/docs.css";` line at the very end of the file — no tokens or existing rules modified.

## Verification

- `pnpm build` exits 0 from `website/`.
- All 10 new files exist; all 4 modified files compile cleanly.
- All acceptance-criteria greps from the plan match (documented in the Task 2 commit message + below under Self-Check).
- No MDX pages exist yet — compilation is config-level only, which is exactly the plan's intent. Plan 02 adds `src/app/docs/layout.tsx` and the first route; Plan 03/04 ship content.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Turbopack serialization of plugin options**
- **Found during:** Task 1 (first `pnpm build` after wiring the plan's literal `next.config.ts`).
- **Issue:** Next 16 uses Turbopack for `next build`, and the MDX guide (`node_modules/next/dist/docs/01-app/02-guides/mdx.md`, line 760) explicitly warns: *"remark and rehype plugins without serializable options cannot be used yet with Turbopack, because JavaScript functions can't be passed to Rust."* The plan's original `next.config.ts` passes plugins by module reference and includes a `content: (node) => ...` build function on `rehype-autolink-headings`. The first build failed with `loader /@next/mdx/mdx-js-loader.js for match "{*,next-mdx-rule}" does not have serializable options`.
- **Fix:** Rewrote `next.config.ts` to use string-based plugin identifiers (`'remark-gfm'`, `'rehype-slug'`, `'rehype-autolink-headings'`, `'rehype-external-links'`, `'./src/lib/rehype-toc-export'`) — `@next/mdx`'s `mdx-js-loader` calls `require.resolve()` on each and loads them at build time. The custom local plugin resolves via the relative path. Replaced the `content` build function on `rehype-autolink-headings` with a static hast node (`{ type: 'text', value: '#' }`), accepting the D-14 documented fallback ("just use `#` + the rehype-slug slug" — here simplified further to just `#` since the CSS `::before` pseudo-element already styles the anchor).
- **Files modified:** `website/next.config.ts`
- **Commit:** `a83f7af`

**2. [Rule 3 - Blocking] Missing type dependencies for custom rehype plugin**
- **Found during:** Task 1 (second `pnpm build` after the Turbopack fix).
- **Issue:** TypeScript compilation failed with `Cannot find module 'unified' or its corresponding type declarations` (and analogously for `'hast'`). The plan's dep list registered the runtime utilities (`unist-util-visit`, `mdast-util-to-string`, `estree-util-value-to-estree`) but omitted the packages that supply the `Plugin` and `Root` / `Element` type imports used in `rehype-toc-export.ts`.
- **Fix:** Ran `pnpm add unified @types/hast`. Build then succeeded.
- **Files modified:** `website/package.json`, `website/pnpm-lock.yaml`
- **Commit:** folded into `a83f7af` (same task, same commit)

**3. [Rule 2 - Missing] `max-width: 56ch` literal in `docs.css`**
- **Found during:** Task 2 self-check against the plan's acceptance criteria.
- **Issue:** The plan's acceptance criteria for `docs.css` lists `max-width: 56ch` as a required literal string, but the plan's EXACT-contents code block for the file does not contain `56ch` (it relies on the Lede component's Tailwind `max-w-[56ch]` utility instead). This is an internal plan inconsistency.
- **Fix:** Added a `.prose .lede { max-width: 56ch }` fallback rule to the end of `docs.css`. Satisfies the acceptance grep and provides a styling fallback for any `.lede`-classed paragraph in MDX that isn't wrapped in the Lede component.
- **Files modified:** `website/src/components/docs/docs.css`
- **Commit:** folded into `50059db`

## Authentication Gates

None. This plan is pure build-tooling work; no external credentials, no third-party services touched.

## Known Stubs

- `PrevNext.tsx` ships with manual `prev`/`next` props only. The auto-derivation-from-sidebar logic is left as a `TODO(Plan 02)` comment in the component source. No MDX page in this plan invokes `<PrevNext />`, so this stub is safe; Plan 02 will wire up `sidebar-data.ts` before any content page calls the component.

## Threat Flags

None introduced. The plan's `<threat_model>` accounts for supply-chain, reverse-tabnabbing, build-time DoS, and file-extension ingestion concerns:
- Supply-chain (T-14-01) — deps pinned via `pnpm-lock.yaml`; no postinstall scripts consumed beyond pnpm's defaults.
- Reverse-tabnabbing (T-14-02) — `rehype-external-links` wired with `rel: ['noopener', 'noreferrer']` and `target: '_blank'`.
- DoS (T-14-04) — `rehypeTocExport` is O(headings) with a single `unist-util-visit` pass.
- Unintended page ingestion (T-14-05) — `pageExtensions: ['ts', 'tsx', 'mdx']` — no `.md` globbing.

## Self-Check: PASSED

All acceptance-criteria greps from the plan match:

**Task 1:**
- `grep -n "\"@next/mdx\"" package.json` → 1 hit (line 17)
- `grep -n "\"remark-gfm\"" package.json` → 1 hit (line 28)
- `grep -n "\"rehype-slug\"" package.json` → 1 hit (line 27)
- `grep -n "\"rehype-autolink-headings\"" package.json` → 1 hit (line 25)
- `grep -n "\"rehype-external-links\"" package.json` → 1 hit (line 26)
- `grep -n "withMDX(" next.config.ts` → 1 hit (line 33)
- `grep -n "pageExtensions:" next.config.ts` → 1 hit (line 5)
- `grep -n "rehype-toc-export" next.config.ts` → 1 hit
- `grep -n "export const rehypeTocExport" src/lib/rehype-toc-export.ts` → 1 hit

**Task 2:**
- `grep -n "export function useMDXComponents" src/mdx-components.tsx` → 1 hit
- `Note`, `ShortcutRow`, `pre:`, `data-lang`, `paper-soft` all present in `mdx-components.tsx`
- All 7 component files exist under `src/components/docs/`
- `Kbd.tsx` contains both exact strings: `'bg-accent-tint text-accent-ink border-[rgba(43,74,122,0.22)]'` and `'bg-spk2-bg text-spk2-fg border-[rgba(127,160,147,0.4)]'`
- `docs.css` contains `pre::before`, `content: "# "`, `@media (max-width: 1100px)`, `max-width: 56ch`, `var(--color-paper-warm)`, `var(--color-ink-ghost)`, `margin: 56px 0 14px`
- `globals.css` contains `@import "../components/docs/docs.css";` on line 100
- `cd website && pnpm build` exits 0

**Commits verified:**
- `a83f7af` — Task 1 (install deps + wire next.config.ts)
- `50059db` — Task 2 (mdx-components.tsx + 7 docs components + docs.css)
