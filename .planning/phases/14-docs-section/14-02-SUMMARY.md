---
phase: 14-docs-section
plan: 02
subsystem: website-docs
tags: [next16, docs, sidebar, codegen, toc, layout]
one_liner: "Docs chrome: build-time sidebar codegen (predev/prebuild) + three-column grid layout + TOC client component with IntersectionObserver scroll-spy + /docs redirect. Plan 03/04 only drop page.mdx files now."
requires:
  - website/src/components/docs/Kbd.tsx                # Plan 01 — exposed via MDX namespace
  - website/src/components/docs/Note.tsx               # Plan 01
  - website/src/components/docs/Lede.tsx               # Plan 01
  - website/src/components/docs/Crumbs.tsx             # Plan 01
  - website/src/components/docs/ShortcutTable.tsx      # Plan 01
  - website/src/components/docs/ShortcutRow.tsx        # Plan 01
  - website/src/components/docs/docs.css               # Plan 01 — .prose layer
  - website/src/mdx-components.tsx                     # Plan 01 — extended, not replaced
  - website/src/lib/rehype-toc-export.ts               # Plan 01 — injects `tableOfContents`
  - website/src/components/layout/Nav.tsx              # existing — extended with /docs active-state
provides:
  - "scripts/build-sidebar-data.mjs: prebuild codegen scanning src/app/docs/*/page.mdx for `export const doc`, writing sidebar-data.generated.ts"
  - "predev + prebuild npm lifecycle hooks (package.json) that run the codegen automatically"
  - "src/components/docs/sidebar-data.generated.ts: AUTO-GENERATED discovered-docs array (empty until Plan 03/04 ships pages)"
  - "src/components/docs/sidebar-data.ts: consumer module grouping DISCOVERED_DOCS per D-07 (Start here / Reference / Help) and exposing `sidebar` + `DOC_ORDER`"
  - "src/components/docs/Sidebar.tsx: client component reading usePathname() for active-state"
  - "src/components/docs/PrevNext.tsx: overwritten — now supports both manual prev/next props AND currentSlug auto-derivation from DOC_ORDER"
  - "src/components/docs/TableOfContents.tsx: client component with IntersectionObserver scroll-spy; pins itself to grid column 3 on lg via its own className"
  - "src/app/docs/layout.tsx: three-column CSS grid wrapper (grid-cols-1 / md:[240px_1fr] / lg:[240px_1fr_200px]) with `display: contents` children container"
  - "src/app/docs/page.tsx: redirect to /docs/getting-started"
  - "src/app/sitemap.ts: rewritten — derives /docs/* entries from DOC_ORDER"
  - "src/mdx-components.tsx: surgical two-line edit to expose <TableOfContents> to MDX"
affects:
  - website/package.json                               # two new lifecycle hooks added
  - website/src/components/layout/Nav.tsx              # usePathname() + Docs active-state
  - website/src/app/sitemap.ts                         # now spreads DOC_ORDER
  - website/src/mdx-components.tsx                     # TableOfContents added to components map
tech_stack:
  added:
    - "(none — uses only Node built-ins + existing next/react deps)"
  patterns:
    - "Build-time codegen via npm lifecycle hooks (predev/prebuild) — satisfies ROADMAP SC-1 without touching Next config or introducing a plugin"
    - "`display: contents` children wrapper — lets page.mdx render its `<article>` and `<TableOfContents>` directly into the parent CSS grid at the right columns without a stacked wrapper"
    - "Narrow regex extraction over MDX `export const doc = { ... }` literal — the codegen never evaluates MDX, so malicious MDX can at worst cause the script to skip a page (fail-open)"
    - "IntersectionObserver scroll-spy with rootMargin '-20% 0px -70% 0px' (matches the mock's JS)"
key_files:
  created:
    - website/scripts/build-sidebar-data.mjs
    - website/src/components/docs/sidebar-data.generated.ts
    - website/src/components/docs/sidebar-data.ts
    - website/src/components/docs/Sidebar.tsx
    - website/src/components/docs/TableOfContents.tsx
    - website/src/app/docs/layout.tsx
    - website/src/app/docs/page.tsx
  modified:
    - website/package.json
    - website/src/components/docs/PrevNext.tsx
    - website/src/components/layout/Nav.tsx
    - website/src/app/sitemap.ts
    - website/src/mdx-components.tsx
decisions:
  - "Codegen runs via predev + prebuild npm lifecycle hooks (not a Next config plugin). Keeps the script independent of Next/Turbopack's plugin serializability rules, and makes `pnpm dev` pick up new pages on the next dev-server start."
  - "Generated file (sidebar-data.generated.ts) is committed despite being auto-output. Reason: TypeScript + the sidebar consumer import it, so CI must have the file before `pnpm install && pnpm build` runs its TS check in a cold environment."
  - "PrevNext.tsx's manual-override branch (prev/next props) wins over auto-derivation. Plan 01 shipped the manual-only signature; keeping it as an escape hatch means future pages with custom pair-ups (e.g., cross-section jumps) don't need separate plumbing."
  - "TableOfContents pins itself to column 3 (lg:col-start-3 lg:col-end-4 lg:row-start-1) — the layout file does NOT reserve the TOC column. This means page.mdx files that omit <TableOfContents> simply leave the third column empty; no layout-level guardrail needed."
metrics:
  completed_date: "2026-04-24"
  duration_approx: "~4 minutes from Task 1 start to Task 2 commit"
  tasks_completed: 2
  files_created: 7
  files_modified: 5
requirements_completed:
  - DOCS-02
  - DOCS-04
---

# Phase 14 Plan 02: Docs Chrome (Layout + Sidebar + TOC) Summary

Built the docs section chrome so Plan 03/04 only have to write MDX content. A prebuild codegen script now scans `src/app/docs/*/page.mdx`, extracts each file's `export const doc` via narrow regex, and writes `sidebar-data.generated.ts`. The sidebar descriptor, `DOC_ORDER`, `PrevNext` auto-derivation, and sitemap all read from that generated file, which satisfies ROADMAP SC-1 structurally: dropping a new `page.mdx` with a valid `doc` export produces a live doc page, sidebar entry, PrevNext wiring, and sitemap URL on the next `pnpm dev` / `pnpm build` — zero other code changes.

## What Landed

### Task 1 — Build-time sidebar assembly + Sidebar + PrevNext + Nav + sitemap (commit `7233571`)

- `website/scripts/build-sidebar-data.mjs` — Node ESM codegen. Uses `fs.readdir` to iterate `src/app/docs/*` directories, `fs.readFile` to grab each `page.mdx`, a narrow `/export\s+const\s+doc\s*=\s*\{([\s\S]*?)\}/` regex to snip the object literal body, and per-key regexes to pull `group`/`order`/`navTitle`. Fail-open on malformed MDX: logs a warning and skips the page. Handles `ENOENT` on the docs dir (writes `DISCOVERED_DOCS: []`, which is exactly what happens at Plan 02 time — no pages exist yet).
- `website/package.json` gained two lifecycle hooks: `"predev": "node scripts/build-sidebar-data.mjs"` and `"prebuild": "node scripts/build-sidebar-data.mjs"`. pnpm runs them automatically before `dev` and `build`. Observed in `pnpm build` output: `> website@0.1.0 prebuild / > node scripts/build-sidebar-data.mjs / [build-sidebar-data] wrote 0 entries`.
- `website/src/components/docs/sidebar-data.generated.ts` — AUTO-GENERATED placeholder. Banner comment at the top tells humans not to edit. Current contents: `export const DISCOVERED_DOCS: DiscoveredDoc[] = []`. Committed so TS and the sidebar consumer compile in cold CI.
- `website/src/components/docs/sidebar-data.ts` — consumer module. Imports `DISCOVERED_DOCS`, groups into `Start here` / `Reference` / `Help` per D-07, sorts each group by `doc.order`, and appends any ad-hoc groups alphabetically at the end (SC-1 honesty: a new page with a new group name still ships). Exports `sidebar`, `DOC_ORDER`, `SidebarGroup`, `SidebarItem`.
- `website/src/components/docs/Sidebar.tsx` — client component. `usePathname()` drives `isActive` via `===` equality with `item.href`. Active classes: `bg-paper text-ink border-rule shadow-lift font-medium`. Outer `<aside>` is sticky at `top-16`, `bg-paper-warm`, `border-r-[0.5px] border-rule`, `hidden md:block` (collapses below 820px).
- `website/src/components/docs/PrevNext.tsx` — overwrote the Plan 01 placeholder. New signature accepts optional `currentSlug` plus optional manual `prev`/`next`. Manual overrides win; otherwise `deriveFromSidebar(slug)` looks up the index in `DOC_ORDER` and returns neighbors. Returns `null` if both are missing (end-of-list case — renders nothing instead of empty cards).
- `website/src/components/layout/Nav.tsx` — added `usePathname()` + `docsActive = pathname?.startsWith('/docs') ?? false`. Docs `<Link>` gets `${linkBase} ${docsActive ? linkActive : linkIdle}` and `aria-current="page"` when active. Preserved the existing `useScrolled` sticky-scroll behavior untouched.
- `website/src/app/sitemap.ts` — rewrote. Imports `DOC_ORDER` from `@/components/docs/sidebar-data` and spreads it into the returned array. New pages land in the sitemap automatically.

### Task 2 — Layout + TOC + redirect + MDX wire-up (commit `4cafd46`)

- `website/src/app/docs/layout.tsx` — three-column CSS grid. Uses `grid-cols-1 md:grid-cols-[240px_1fr] lg:grid-cols-[240px_1fr_200px]` on the outer wrapper. Renders `<Sidebar />` as the first grid child, then wraps `{children}` in a `<div className="contents">` so the page-level `<article>` and `<TableOfContents>` render as direct grid children (landing at columns 2 and 3 via their own `col-start-*` classes).
- `website/src/app/docs/page.tsx` — three-line server component that `redirect('/docs/getting-started')`. Verified in `pnpm build` output: the `/docs` route compiles as a static page (Next's redirect at render time).
- `website/src/components/docs/TableOfContents.tsx` — client component. Props: `items: TocItem[]` where `TocItem = { depth: 2|3; id: string; text: string }`. Uses an `IntersectionObserver` with the exact `rootMargin: '-20% 0px -70% 0px'` from the mock; updates `activeId` when any observed heading intersects. Returns `null` when `items.length === 0` (defensive: pages with zero H2s render no TOC). Outer `<nav>` has `hidden lg:block lg:col-start-3 lg:col-end-4 lg:row-start-1 sticky top-16`. Active-state: `text-ink border-l-accent-ink`. H3 items get `pl-6` indentation.
- `website/src/mdx-components.tsx` — surgical two-line edit. Added `import { TableOfContents } from '@/components/docs/TableOfContents'` at the top alongside the other docs-component imports, and added `TableOfContents,` to the `components` object next to `Kbd,`. Zero other lines touched — the Plan 01 `code` / `pre` / `hr` overrides are byte-identical.

## Verification

- `cd website && pnpm build` exits 0 after both tasks.
- `node scripts/build-sidebar-data.mjs` produces `sidebar-data.generated.ts` with `DISCOVERED_DOCS: []` (zero entries, as expected before Plan 03/04).
- All acceptance-criteria greps from the plan pass (documented in the Self-Check section below).
- Sitemap runtime smoke-check via `pnpm dlx tsx`: `sitemap entries: 1` (landing only, which is the expected Plan 02 baseline; jumps to 7 once Plan 03/04 ships 6 pages).
- The `predev` / `prebuild` hooks fire automatically on every build, observed in the build output.
- The `/docs` route is compiled into the build manifest.
- Runtime behavior (three-column layout, active-state, TOC scroll-spy) cannot be tested until at least one page.mdx exists — that happens in Plan 03 Task 1 (getting-started).

## Deviations from Plan

None. Plan executed exactly as written. All string anchors, behaviors, and file paths match the plan's `<action>` blocks byte-for-byte.

One environment note: the worktree started without `node_modules/` (fresh checkout), so `pnpm install` was run once before `pnpm build` could execute. This is not a deviation — it's standard workflow for a cold worktree — and the installed versions match the Plan 01 lockfile exactly.

## Authentication Gates

None. Pure build-chrome work; no credentials or external services.

## Known Stubs

- `DISCOVERED_DOCS` is an empty array until Plan 03/04 ship page.mdx files. This is by design, not a stub: the generator writes whatever the filesystem says. The sidebar and TOC components handle the empty case (sidebar renders no groups; DOC_ORDER is empty; PrevNext returns `null`; sitemap returns only the landing page). Once Plan 03 ships `getting-started/page.mdx`, the next `pnpm dev` / `pnpm build` regenerates the file with 1+ entry.

## Threat Flags

None introduced beyond what the plan's `<threat_model>` already documented (T-14-07, T-14-08, T-14-09, T-14-10, T-14-11, T-14-23). The codegen script reads only files under `src/app/docs/`, never executes MDX code, and fails open on malformed input. `usePathname()`/`IntersectionObserver` usage is contained to client components and bounded by DOM node count.

## Output Notes (per plan's `<output>` section)

- **Did `scripts/build-sidebar-data.mjs` need regex adjustments?** No. The plan's narrow regex works for the empty-input case at Plan 02; Plan 03/04 will exercise the regex against real `doc` exports and may surface the need for trailing-comma tolerance or nested-object handling. If that happens, the fix is scoped to `extractDocLiteral` / `pullValue` and does not affect the consumer modules.
- **Did `predev` / `prebuild` fire automatically?** Yes, confirmed in the `pnpm build` output — the lifecycle hook ran before `next build` on both Task 1 and Task 2 verifications.
- **Did `display: contents` + `lg:col-start-3` hold up?** Cannot be runtime-verified yet (no page.mdx exists). Static verification passes: layout.tsx has `contents` wrapper; TableOfContents.tsx has `lg:col-start-3 lg:col-end-4 lg:row-start-1`; layout does not reserve the third column. Plan 03 Task 1 will UAT-verify this with the first real page.
- **Initial contents of `sidebar-data.generated.ts`:** 0 entries (empty array); expected to jump to 6 after Wave 3 completes.

## Self-Check: PASSED

**Created files exist:**
- FOUND: website/scripts/build-sidebar-data.mjs
- FOUND: website/src/components/docs/sidebar-data.generated.ts
- FOUND: website/src/components/docs/sidebar-data.ts
- FOUND: website/src/components/docs/Sidebar.tsx
- FOUND: website/src/components/docs/TableOfContents.tsx
- FOUND: website/src/app/docs/layout.tsx
- FOUND: website/src/app/docs/page.tsx

**Acceptance-criteria greps (all matched):**
- `grep "readdir" scripts/build-sidebar-data.mjs` → line 14, 50
- `grep "sidebar-data.generated.ts" scripts/build-sidebar-data.mjs` → line 5, 22
- `grep "AUTO-GENERATED" src/components/docs/sidebar-data.generated.ts` → line 1
- `grep "DISCOVERED_DOCS" src/components/docs/sidebar-data.generated.ts` → line 6
- `grep '"predev":' package.json` → line 9
- `grep '"prebuild":' package.json` → line 11
- `grep "import { DISCOVERED_DOCS }" src/components/docs/sidebar-data.ts` → line 20
- `grep "export const sidebar" src/components/docs/sidebar-data.ts` → line 69
- `grep "export const DOC_ORDER" src/components/docs/sidebar-data.ts` → line 72
- `grep "'use client'" src/components/docs/Sidebar.tsx` → line 1
- `grep "usePathname" src/components/docs/Sidebar.tsx` → line 4, 8
- `grep "shadow-lift" src/components/docs/Sidebar.tsx` → line 22
- `grep "bg-paper-warm" src/components/docs/Sidebar.tsx` → line 10
- `grep "currentSlug" src/components/docs/PrevNext.tsx` → lines 7, 10, 25, 26
- `grep "DOC_ORDER" src/components/docs/PrevNext.tsx` → lines 2, 6, 15, 17, 18
- `grep "usePathname" src/components/layout/Nav.tsx` → lines 4, 15
- `grep "startsWith('/docs')" src/components/layout/Nav.tsx` → line 16
- `grep "DOC_ORDER" src/app/sitemap.ts` → lines 2, 15
- `grep "'use client'" src/components/docs/TableOfContents.tsx` → line 1
- `grep "IntersectionObserver" src/components/docs/TableOfContents.tsx` → lines 22, 26
- `grep "rootMargin: '-20% 0px -70% 0px'" src/components/docs/TableOfContents.tsx` → line 34
- `grep "lg:col-start-3" src/components/docs/TableOfContents.tsx` → line 52
- `grep "hidden lg:block" src/components/docs/TableOfContents.tsx` → line 52
- `grep "grid-cols-\[240px_1fr_200px\]" src/app/docs/layout.tsx` → line 29 (plus doc comment)
- `grep "md:grid-cols-\[240px_1fr\]" src/app/docs/layout.tsx` → line 29 (plus doc comment)
- `grep "Sidebar" src/app/docs/layout.tsx` → lines 2, 8, 18, 30
- `grep 'className="contents"' src/app/docs/layout.tsx` → line 31
- `grep "redirect" src/app/docs/page.tsx` → lines 1, 4
- `grep "/docs/getting-started" src/app/docs/page.tsx` → line 4
- `grep "TableOfContents" src/mdx-components.tsx` → lines 10, 31
- `grep "from '@/components/docs/TableOfContents'" src/mdx-components.tsx` → line 10

**Commits exist:**
- FOUND: 7233571 — feat(14-02): build-time sidebar assembly + Sidebar + PrevNext + Nav active-state + sitemap
- FOUND: 4cafd46 — feat(14-02): docs three-column layout + TableOfContents + /docs redirect + TOC wired to MDX

**Build status:**
- `cd website && pnpm build` → exits 0 on both Task 1 and Task 2 runs.
- `pnpm dlx tsx -e "…sitemap.default()"` → prints `sitemap entries: 1` (landing only; jumps to 7 after Wave 3).
