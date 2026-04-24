# Phase 14: Docs Section - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-23
**Phase:** 14-docs-section
**Areas discussed:** MDX pipeline, Sidebar + content scope, TOC generation, Code block treatment

---

## Gray area selection

| Option | Description | Selected |
|--------|-------------|----------|
| MDX pipeline | How MDX compiles and renders | ✓ |
| Sidebar + content scope | 11 mock links vs 4 required pages + FAQ/Troubleshooting content | ✓ |
| TOC generation | Build-time vs runtime vs hybrid | ✓ |
| Code block treatment | Plain vs Shiki vs Prism; reuse primitive vs MDX overrides | ✓ |

**User's additional input:** "configuring notion and obsidian" (free-text add) — folded into sidebar + content scope.

**Deferred to Claude's Discretion (not discussed):** URL routing, mobile sidebar nav, MDX custom-component inventory.

---

## MDX pipeline

### Q1: Which MDX pipeline for Phase 14?

| Option | Description | Selected |
|--------|-------------|----------|
| @next/mdx (Recommended) | Official Vercel plugin, file-based MDX pages, smallest dep footprint | ✓ |
| next-mdx-remote | Runtime compilation; overkill for filesystem-authored content | |
| fumadocs / content-collections | Full docs frameworks; would fight Chronicle design system | |
| Hand-rolled (gray-matter + bundler) | Reinvents @next/mdx's wheels | |

**User's choice:** @next/mdx.

### Q2: Where should MDX source files live?

| Option | Description | Selected |
|--------|-------------|----------|
| Page-file routing: src/app/docs/{slug}/page.mdx (Recommended) | Most Next-native; zero glue code | ✓ |
| Content folder + catch-all /docs/[slug]/page.tsx | More moving parts | |
| Hybrid generated pages at build time | Overkill for 4-8 pages | |

**User's choice:** Page-file routing.

### Q3: Frontmatter and per-page metadata

| Option | Description | Selected |
|--------|-------------|----------|
| Export metadata + doc constant from page.mdx (Recommended) | Native ESM exports, no YAML, no gray-matter | ✓ |
| YAML frontmatter (---) + remark-frontmatter | Traditional MDX pattern; duplicates metadata | |
| Central config file: src/app/docs/nav.ts | Title lives away from content | |

**User's choice:** ESM exports (`metadata` + `doc`).

---

## Sidebar + content scope

### Q1: How many doc pages ship in Phase 14?

| Option | Description | Selected |
|--------|-------------|----------|
| Required 4 only | Tight to ROADMAP; sparse sidebar | |
| Required 4 + Configuring Obsidian + Notion (6 total) (Recommended) | Honors user's "configuring Notion + Obsidian" add | ✓ |
| Full 11 from mock, 5 as "Coming soon" stubs | Half-built feel | |
| Full 11 with real content | Significant scope expansion | |

**User's choice:** 6 pages.
**Notes:** User's earlier free-text add "configuring notion and obsidian" mapped directly onto mock sidebar slots "Configuring your vault" + "Notion property mapping".

### Q2: How should the sidebar be organized for 6 pages?

| Option | Description | Selected |
|--------|-------------|----------|
| 3 groups matching mock structure (Recommended) | Start here / Reference / Help, Developer dropped | ✓ |
| 2 groups: Getting started / Reference | Simpler, further from mock | |
| Flat, no groups | Loses editorial structure | |

**User's choice:** 3 groups.

### Q3: Who writes FAQ, Troubleshooting, Obsidian, Notion copy?

| Option | Description | Selected |
|--------|-------------|----------|
| Claude drafts from PROJECT.md + README + app behavior (Recommended) | Ships in one pass; user reviews at UAT | ✓ |
| User writes, Claude scaffolds | Blocks phase on user writing 1500-2500 words | |
| Stubs for Obsidian/Notion + full FAQ/Troubleshooting | Compromise | |
| User outlines, Claude expands | Still blocks on user outlining | |

**User's choice:** Claude drafts all four.

### Q4: Mock's "macOS 14" and inline dead links

| Option | Description | Selected |
|--------|-------------|----------|
| Port verbatim, fix factual errors + strip dead links (Recommended) | Matches Phase 13's policy | ✓ |
| Port verbatim, leave dead links at # | Broken links in docs | |
| Write fresh, ignore mock copy | Discards strong editorial voice | |

**User's choice:** Port verbatim with mechanical fixes.

---

## TOC generation

### Q1: How should we extract headings for the TOC?

| Option | Description | Selected |
|--------|-------------|----------|
| Build-time via rehype plugin (Recommended) | SSR clean, mobile-safe, no client-JS structure | ✓ |
| Runtime client component (matches mock) | Matches mock inline JS; first-paint flash | |
| Hybrid: build-time list + runtime active-state IO | Best of both, slightly more code | |

**User's choice:** Build-time.
**Notes:** Even with build-time TOC, scroll-spy active-state still needs a small `'use client'` component with IntersectionObserver.

### Q2: H2-only vs H2+H3 TOC depth

| Option | Description | Selected |
|--------|-------------|----------|
| H2 + H3, H3 visually nested (Recommended) | Matches DOCS-04 verbatim | ✓ |
| H2 only (match mock) | Under-delivers DOCS-04 | |
| H2 + H3 flat | Less visual structure | |

**User's choice:** H2 + H3 nested.

### Q3: Ship the mock's `# anchor` label treatment?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, via rehype-autolink-headings with absolute-positioned anchor (Recommended) | Editorial texture, deep-link affordance | ✓ |
| No anchor labels — headings just have IDs | Loses editorial detail | |
| Anchors on hover only | Less cluttered but loses mock's always-on signal | |

**User's choice:** Yes, always-on anchor labels.

---

## Code block treatment

### Q1: Syntax highlighting for fenced blocks?

| Option | Description | Selected |
|--------|-------------|----------|
| No highlighting, match mock (Recommended) | Smallest footprint, matches mock exactly | ✓ |
| Shiki via rehype-pretty-code (build-time) | Beautiful, zero client JS, adds build deps | |
| Shiki direct | Same as above, lighter wrapper | |
| Prism client-side | Ships ~20KB JS | |

**User's choice:** No highlighting.

### Q2: Reuse Phase 12 CodeBlock primitive vs MDX element overrides?

| Option | Description | Selected |
|--------|-------------|----------|
| mdx-components.tsx overrides, no primitive reuse (Recommended) | Keeps primitive focused on JSX; MDX has different contract | ✓ |
| Extend CodeBlock primitive for both | Churn on Phase 12 artifact | |
| New MDX-specific CodeBlock in src/components/docs/ | Slight duplication | |

**User's choice:** mdx-components.tsx overrides.

### Q3: How to render the lang label?

| Option | Description | Selected |
|--------|-------------|----------|
| Derive from code className in pre override (Recommended) | Matches mock visually, zero extra config | ✓ |
| Drop lang label entirely | Loses editorial detail | |
| rehype-pretty-code meta support | Overkill for a label | |

**User's choice:** Derive from className.

---

## Claude's Discretion

Areas where the user deferred to Claude's judgment:

- URL routing (`/docs` landing vs redirect to `/docs/getting-started`) — defaulting to redirect.
- Mobile sidebar behavior — match mock (hide below 820px).
- MDX custom-component inventory — ship `<Note>` (both variants), `<Lede>`, `<Crumbs>`, `<PrevNext>`, `<ShortcutTable>`.
- Remark/rehype plugin stack beyond the minimum — add `rehype-external-links` for `target="_blank"` on external links.
- Slug generation for URL paths (lowercase hyphenated from mock link texts).
- Whether the sidebar is a server or client component — client (for `usePathname`).
- Exact Tailwind vs scoped CSS boundary for prose styling (planner picks).
- Anchor-label content format (mock uses one-word lowercase `# install`; rehype-slug default is longer `# install-something`) — custom `content` function to approximate mock; longer slug as acceptable fallback.

## Deferred Ideas

- Full 11-page mock sidebar — 5 remaining pages are v1.2+ candidates.
- Syntax highlighting — revisit when code-heavy content grows.
- Docs search (Cmd+K) — milestone Out of Scope.
- Mobile drawer / hamburger — revisit post-ship if user testing flags friction.
- Per-page OG images — deferred polish.
- Versioned docs — not needed until v2.x breaks behavior.
- Anchor-label hover-reveal variant — mock always-on; revisit if noisy.
- Playwright visual regression — post-v1.1 hardening pass.
