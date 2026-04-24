# Phase 14: Docs Section - Context

**Gathered:** 2026-04-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship `ps-transcribe-web.vercel.app/docs/*` as MDX-rendered help pages inside the existing `/website` Next.js app. Six initial pages land in this phase, organized in three sidebar groups matching the mock, with a right-hand "On this page" TOC that collapses below 1200px. Every page inherits the Chronicle-styled `<Nav>` and `<Footer>` that Phase 13 already mounted in `layout.tsx`.

In scope:
- `@next/mdx` install + configuration (next.config.ts + `pageExtensions` + `withMDX`)
- Required `mdx-components.tsx` at `src/` root (App Router convention) with element overrides for `h1..h3`, `p`, `ul`/`ol`, `strong`, `em`, `a`, `pre`, `code`, `hr`, plus custom docs components (`<Note>`, `<Lede>`, `<Crumbs>`, `<PrevNext>`, `<ShortcutTable>`)
- Six `page.mdx` files at `src/app/docs/{slug}/page.mdx`, each exporting `metadata` (Next Metadata API) and `doc` (sidebar descriptor: `{ group, order, navTitle }`) as ES-module constants
- Six pages: Getting started, Configuring your vault (Obsidian), Keyboard shortcuts, Notion property mapping, FAQ, Troubleshooting
- `src/app/docs/layout.tsx` — the three-column grid wrapper (`240px 1fr 200px`, sticky sidebar + sticky TOC, responsive collapse at 1200px then 820px)
- `src/components/docs/Sidebar.tsx` — left sidebar, reads a build-time-assembled sidebar descriptor, renders the three groups (`Start here` / `Reference` / `Help`) with mono uppercase group labels and active-page card treatment
- `src/components/docs/TableOfContents.tsx` — right column, renders the heading list exported by the current MDX page as `tableOfContents`, client component for scroll-spy active state
- Build-time heading/TOC extraction via `rehype-slug` + a small custom rehype plugin that exposes `tableOfContents` as a named MDX export
- `rehype-autolink-headings` wiring so each H2 gets a clickable `<a class="anchor">` that CSS positions absolutely to the left (`# section-name` in ink-ghost mono, hidden below 1100px — matches mock)
- `remark-gfm` for GFM features (tables, task lists, strikethrough) that editorial copy may use
- Prose body styling matching the mock's `.prose` rules (Spectral H1/H2, Inter H3/body, 16px/1.65 body, 56ch lede, 28px rhythm, etc.) — ported into Tailwind utility strings or a small `docs.css` layer, never by importing `chronicle-mock.css`
- Inline `code` renders on a `paperSoft` pill (DOCS-05); fenced `<pre>` renders on `paper-warm` with 0.5px rule, 8px radius, and a top-right lang label derived from the fence's `language-*` class
- Writing fresh editorial copy for FAQ, Troubleshooting, Configuring your vault, and Notion property mapping from PROJECT.md + README + observed app behavior; porting mock copy verbatim for Getting Started and Keyboard Shortcuts with two mechanical fixes (macOS version + dead internal links)
- Sidebar links pointing at `/docs/*` paths for the six pages only; the other five mock sidebar slots (Recording your first meeting, Frontmatter schema, Privacy & data, Build from source, Sparkle appcast) are deferred — the "Developer" group is dropped entirely, no placeholders
- Per-page metadata (`title` + `description` + OG tuned per doc) via the `metadata` export in each `page.mdx`

Out of scope (deferred to later phases or post-v1.1):
- Syntax highlighting on fenced code blocks (ship plain; revisit if docs add more code)
- Docs search / Cmd+K modal — explicit milestone Out of Scope (REQUIREMENTS.md)
- Mobile drawer/hamburger for the sidebar — mock just hides the sidebar below 820px; match that (content-only on mobile)
- The five non-shipping mock sidebar pages — candidate for v1.2+ docs expansion
- Dark-mode variants — blocked by DESIGN-04
- Analytics — milestone Out of Scope
- `/changelog` page — Phase 15
- Revisiting or extending the Phase 12 `CodeBlock` primitive — MDX uses element overrides instead; primitive stays for JSX callers (landing page)
- Custom domain — post-v1.1
- Localization — out of milestone

</domain>

<decisions>
## Implementation Decisions

### MDX pipeline
- **D-01:** Use **`@next/mdx`** — Vercel's official plugin for Next 16 App Router. Install `@next/mdx` + `@mdx-js/loader` + `@mdx-js/react` + `@types/mdx`.
- **D-02:** Configure `next.config.ts` with `pageExtensions: ['ts', 'tsx', 'mdx']` and wrap the config in `withMDX(...)`. Remark/rehype plugins configured on the `createMDX({ options: { remarkPlugins, rehypePlugins } })` call.
- **D-03:** **File-based MDX routing.** Each doc is a folder: `src/app/docs/{slug}/page.mdx`. Zero glue code — Next turns each into a route automatically. URLs are `/docs/getting-started`, `/docs/configuring-your-vault`, `/docs/keyboard-shortcuts`, `/docs/notion-property-mapping`, `/docs/faq`, `/docs/troubleshooting`.
- **D-04:** **Metadata and sidebar info via ES-module exports, not YAML frontmatter.** Each `page.mdx` does `export const metadata = { title, description }` for the Metadata API AND `export const doc = { group, order, navTitle }` for the sidebar descriptor. No `gray-matter`, no `remark-frontmatter`, no runtime parsing — the sidebar builder reads these exports at build time via a small `import()` loop. Idiomatic Next 16.
- **D-05:** Create **`src/mdx-components.tsx`** — required file for `@next/mdx` with App Router (build fails without it). Exports `useMDXComponents()` returning element overrides (`h1..h3`, `p`, `ul`, `ol`, `a`, `strong`, `em`, `code`, `pre`, `hr`) and the custom docs components that MDX authors can use directly (`Note`, `Lede`, `Crumbs`, `PrevNext`, `ShortcutTable`).

### Sidebar + content scope
- **D-06:** Ship **6 pages** in Phase 14 — Getting started, Configuring your vault, Keyboard shortcuts, Notion property mapping, FAQ, Troubleshooting. Exceeds the ROADMAP's explicit 4 pages by adding Obsidian + Notion config, per user request in discussion. Does not ship the other 5 mock slots (those are v1.2 candidates).
- **D-07:** **Three sidebar groups matching the mock** — `Start here` (Getting started, Configuring your vault), `Reference` (Keyboard shortcuts, Notion property mapping), `Help` (FAQ, Troubleshooting). The mock's fourth group `Developer` is dropped: no placeholder, no "coming soon" stubs, group label does not render.
- **D-08:** **Sidebar structure is build-time assembled from the `doc` exports of each `page.mdx`.** A single module at `src/components/docs/sidebar-data.ts` imports every `page.mdx` in the docs tree, reads its `doc` export, and produces a typed `sidebar: SidebarGroup[]` constant grouped and sorted. The `Sidebar` component consumes this constant. Authors add a new page by creating `src/app/docs/{slug}/page.mdx` with a `doc` export — no config file edits.
- **D-09:** **Claude drafts fresh editorial copy** for FAQ, Troubleshooting, Configuring your vault, and Notion property mapping. Source material: PROJECT.md, README.md, the existing app's observed behavior (especially around vault paths, frontmatter, and the Notion integration shipped in v1.0). Target length per page: 300–600 words in the Chronicle voice (concrete, calm, anti-"seamless"). User reviews during UAT and edits in place.
- **D-10:** **Mock copy for Getting Started and Keyboard Shortcuts ports verbatim** (same discipline Phase 13 applied), with two mechanical fixes:
  - "macOS 14 (Sonoma) or later" → the real minimum. Planner MUST grep `Package.swift` to confirm the platform constraint; copy phrasing follows `PROJECT.md` ("macOS 26.0+"). Do NOT ship the mock's macOS 14 string.
  - Inline links pointing at docs we don't ship (e.g., `<a href="#">Frontmatter schema</a>`) — remove the link and inline the relevant information into surrounding prose, or drop the reference if it's not load-bearing. Dead `#` anchors ship nothing.
- **D-11:** **Active-page styling matches the mock's treatment** — active link gets `bg-paper` + ink color + 0.5px rule border + `shadow-lift`, font-weight 500. Inactive links: `text-ink-muted`, no border, hover gets `text-ink` + a faint `rgba(255,255,255,0.5)` wash. Implement via Next's `usePathname()` in the `Sidebar` client component.

### TOC generation
- **D-12:** **Build-time TOC extraction** via `rehype-slug` (stamps IDs on every heading) + a small custom rehype plugin that walks the MDX AST, collects H2 + H3 headings with their generated IDs and text, and exposes them as a named MDX export `tableOfContents` from each compiled page. The page layout reads the current page's `tableOfContents` export and passes it as a prop to `<TableOfContents>`.
- **D-13:** **H2 + H3 depth, H3 visually nested under its parent H2.** Matches DOCS-04's "H2/H3" wording. H3 entries render indented (12px left padding) under their parent H2 in the TOC. Pages with no H3s just show a flat H2 list.
- **D-14:** **Ship the mock's anchor label treatment.** `rehype-autolink-headings` wires a clickable `<a class="anchor" href="#slug">` inside every H2 (and H3). CSS positions the anchor absolutely at `left: -84px` on H2s in `ink-ghost` mono 10px uppercase with a `# ` prefix. Hidden below 1100px viewport (matches mock). Provides deep-link affordance and editorial texture without noisy hover states.
- **D-15:** **Scroll-spy active state via a small client component.** `<TableOfContents>` is `'use client'`, takes the heading list as a prop, and uses `IntersectionObserver` with `rootMargin: '-20% 0px -70% 0px'` (matches mock's JS) to toggle `data-active` on the matching link. No scroll-linked CSS animation; `prefers-reduced-motion` is moot for the active-state toggle.
- **D-16:** **TOC column hides below 1200px viewport** — DOCS-04 requirement. Implement via Tailwind `lg:grid-cols-[240px_1fr_200px]` + `grid-cols-[240px_1fr]` with the TOC itself under a `hidden lg:block`.

### Code block treatment
- **D-17:** **No syntax highlighting ships in Phase 14.** Fenced blocks render as plain monospace on paper-warm background — matches the mock exactly. The three fenced blocks in Getting Started + Shortcuts read fine without highlighting; adding Shiki now would be scope creep. Revisit if future docs add code-heavy content.
- **D-18:** **MDX-specific `pre` and `code` overrides in `mdx-components.tsx`** — do NOT extend or reuse the Phase 12 `CodeBlock` primitive. That primitive was designed for JSX callers (e.g., inline code in the hero/shortcut grid), with variant-union props. The MDX `code`/`pre` element contract is different (children pass through AST-transformed). Mixing the two shapes adds churn. The Phase 12 primitive stays untouched; the MDX overrides are parallel.
  - Inline `<code>` (no parent `<pre>`): render with JetBrains Mono 13.5px, `paperSoft` background, 2/6 padding, 4px radius, ink color (matches DOCS-05 + mock).
  - Fenced `<pre><code class="language-*">`: render the `<pre>` with `paper-warm` bg, 0.5px `rule` border, 8px radius, 16/18 padding, 13px mono, overflow-x auto, relative positioning so the lang label can anchor to `top-right`.
- **D-19:** **Lang label derived from the code element's `className`** in the `pre` override. Extract `language-yaml` → `yaml`, render a `<span>` at `top: 8px; right: 14px` with `font-size: 9px; letter-spacing: 0.1em; text-transform: uppercase; color: var(--color-ink-faint)`. Matches mock's `pre::before` treatment. No highlighting, just the label — so writers get "YAML" / "JSON" / "SWIFT" etc. without any runtime tokenizer.

### Claude's Discretion
- Which specific remark/rehype plugins beyond `remark-gfm`, `rehype-slug`, `rehype-autolink-headings`, and the custom TOC extractor — e.g., whether to add `rehype-external-links` for external-link `target="_blank"`. Default: add it; external links in docs should open in a new tab.
- Exact slug-generation algorithm for headings (github-style vs simpler lowercase+hyphens). Default to `rehype-slug`'s github-style; it handles unicode and duplicate-heading disambiguation.
- Whether the `Sidebar` component is a server component (reads the static sidebar descriptor) or a client component (needs `usePathname()`). Default: client (for `usePathname`), with the descriptor imported statically so it's still bundled-once. The performance hit is negligible at ~6 pages.
- The mock's `.crumbs` element (breadcrumbs above H1) — ship as a custom MDX component `<Crumbs>` that authors invoke manually, OR derive breadcrumbs automatically from the `doc` group + slug. Default: manual `<Crumbs>` — gives authors editorial control over what the trail says.
- The mock's `.prev-next` pagination block at the bottom of each page — ship as a custom `<PrevNext>` component. Derive prev/next automatically from the sidebar order, OR require authors to supply them. Default: automatic from sidebar order, with an optional `<PrevNext prev={...} next={...}>` override for edge cases.
- The mock's `.lede` class (large subhead paragraph after H1) — ship as `<Lede>` component that wraps a `<p>` in the appropriate class. Only Getting Started and Shortcuts need it currently.
- The `<Note>` and `<Note sage>` callouts — ship both variants. Getting Started uses both; Troubleshooting and FAQ will likely use them heavily.
- The `.sc-table` shortcut table from the mock — ship as `<ShortcutTable>` + `<ShortcutRow>` custom MDX components or inline HTML in the MDX. Default: custom components for editorial ergonomics.
- Whether to add a docs-specific `layout.tsx` that injects a distinct page-wide metadata default (e.g., `openGraph.type: 'article'`). Default: yes, it's a free win.
- Exact Tailwind class strings for the prose styles vs. a scoped `docs.css` layer for complex selectors (`.prose h2 .anchor`, `.prev-next`). Planner picks; pure Tailwind is fine but some of the mock's pseudo-element tricks are cleaner in a scoped CSS file.
- Whether the right TOC column is also sticky (mock sets `position: sticky; top: 64px`). Default: yes — matches mock, keeps TOC in view during scroll.
- Whether the whole docs tree has a shared `Breadcrumbs` / `docs/layout.tsx` component that consumes the shared `<Nav>` + `<Footer>` from the root layout, or re-declares them. Default: re-use the root layout — root layout already has `<Nav>` and `<Footer>` from Phase 13, so `src/app/docs/layout.tsx` just adds the grid wrapper around `{children}`.
- The exact slugs for the 6 pages (URL structure). Recommendation: `/docs/getting-started`, `/docs/configuring-your-vault`, `/docs/keyboard-shortcuts`, `/docs/notion-property-mapping`, `/docs/faq`, `/docs/troubleshooting`. All lowercase, hyphenated, matches mock's link texts turned into slugs.
- Whether `src/app/docs/page.tsx` (no slug — visiting `/docs`) renders a docs landing page or redirects to `/docs/getting-started`. Default: Next 16 `redirect()` from a tiny server component. Cleaner than maintaining an index page at this scope.
- Whether to include the mock's `data-doc` JS tab-switching pattern — no. That was a static-HTML-only trick for the mock; with Next routing each doc is a real route.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & scope
- `.planning/REQUIREMENTS.md` §DOCS — Requirements DOCS-01 through DOCS-05 (this phase's scope).
- `.planning/ROADMAP.md` §"Phase 14: Docs Section" — Phase goal, five success criteria, dependency on Phase 12.
- `.planning/PROJECT.md` §"Current Milestone: v1.1 Marketing Website" — Milestone context, scope boundaries.

### Design source of truth
- `design/ps-transcribe-web-unzipped/docs.html` — **PRIMARY MOCK.** 493 lines. Full Chronicle-styled docs layout with working sidebar, main column, right-hand TOC, plus full Getting Started + Keyboard Shortcuts page content. Every visual decision in this phase traces back to this file. Read it top-to-bottom before writing any component.
- `design/ps-transcribe-web-unzipped/assets/chronicle-mock.css` — **Reference-only** for `.docs`, `.docs__side`, `.docs__main`, `.docs__toc`, `.prose` (and all its descendants), `.note`, `.note.sage`, `.prev-next`, `.sc-table`, `.sc-row`, `.sc-group`, `.crumbs`, `.kbd` sizing / spacing / color / radius / border / shadow values. **Never imported.** **Never referenced by class name** in React components. Values are ported into Tailwind utility classes or a scoped CSS layer.
- `design/ps-transcribe-web-unzipped/assets/tokens.css` — Source tokens (already ported to `website/src/app/globals.css` by Phase 12; listed here for cross-reference).
- `.planning/research/CLAUDE-DESIGN-BRIEF.md` §"Docs page" (lines 112–122) — Sidebar specs (220–260px `paperWarm` bg, mono section labels, paper-bg active card), main column (`paper` bg, MDX body, Spectral H1 36px + H2 24px with `# ANCHOR` mono label, Inter 16/1.6, inline code 14px mono on `paperSoft` pill), right TOC (180px column, JetBrains Mono 11px uppercase, collapses below 1200px).
- `.planning/research/CLAUDE-DESIGN-BRIEF.md` §Palette, §Typography, §"Spacing, radii, shadows" — Calibration reference for any new values not in the mock.

### Framework & tooling docs
- `website/node_modules/next/dist/docs/01-app/02-guides/mdx.md` — **Authoritative Next 16 App Router MDX guide.** 825 lines. Covers `@next/mdx` install, `next.config.mjs` wiring, `mdx-components.tsx` (required file), file-based routing for `.mdx` pages, metadata export from MDX, remote MDX, remark/rehype plugin config, `mdxRs` option.
- `website/node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/mdx-components.md` — Reference for the `useMDXComponents()` export and the `MDXComponents` type from `mdx/types`.
- `website/node_modules/next/dist/docs/01-app/03-api-reference/05-config/01-next-config-js/mdxRs.md` — MDX Rust compiler config (opt-in, faster; default is fine for Phase 14).
- `node_modules/next/dist/docs/` (general) — Next.js 16 metadata API, `next/image`, App Router patterns.
- `node_modules/tailwindcss/` docs — Tailwind v4 `@theme inline` + arbitrary values.
- Agents may use `mcp__plugin_context7_context7__*` to fetch `@next/mdx`, `@mdx-js/react`, `rehype-slug`, `rehype-autolink-headings`, `remark-gfm` docs if local copies are insufficient.

### Existing code to reuse / respect / not touch
- `website/src/app/layout.tsx` — Root layout already renders `<Nav />` and `<Footer />` (Phase 13 D-17/18). Docs pages inherit both for free. Do NOT duplicate them inside `src/app/docs/layout.tsx`.
- `website/src/components/layout/Nav.tsx` — Existing nav already includes a `Docs` link (Phase 13 D-17). Will need to highlight the "Docs" link when on a `/docs/*` route — a small `usePathname()` tweak to the existing `<Nav>` may be necessary; confirm during planning and scope into an appropriate plan.
- `website/src/components/layout/Footer.tsx` — Footer already links to `/docs` as "Documentation". No change required for this phase.
- `website/src/components/ui/` — Phase 12 primitives (`Button`, `Card`, `MetaLabel`, `SectionHeading`, `CodeBlock`, `LinkButton`). **Reuse `MetaLabel` for sidebar group labels.** **Do NOT extend or modify `CodeBlock`** — MDX uses element overrides in `mdx-components.tsx` instead (D-18).
- `website/src/app/globals.css` — Chronicle token source of truth (16 colors + 5 radii + 3 shadows + font vars). Consume tokens via Tailwind utilities (`bg-paper-warm`, `text-ink-muted`, `rounded-card`, `shadow-lift`) or `var(--color-*)` references. Do NOT redefine tokens.
- `website/src/hooks/useReveal.ts` + `useScrolled.ts` — Existing hooks from Phase 13. Not strictly required for docs; `useReveal` may be useful if a page wants intro-reveal on first scroll (Claude's discretion).
- `website/next.config.ts` — Modified in this phase to wrap with `withMDX(...)` and add `pageExtensions`. Currently trivial; confirm current contents during planning.
- `website/src/app/sitemap.ts` — Add the six `/docs/*` routes to the sitemap. Currently only lists `/`.
- `website/package.json` — Add deps: `@next/mdx`, `@mdx-js/loader`, `@mdx-js/react`, `@types/mdx`, `remark-gfm`, `rehype-slug`, `rehype-autolink-headings`. All via pnpm per Phase 11 D-01.
- `website/CLAUDE.md` / `website/AGENTS.md` — **"This is NOT the Next.js you know."** Downstream agents MUST read `node_modules/next/dist/docs/` (especially the MDX guide above) before writing code. Training-data MDX patterns may be outdated.

### Prior phase context
- `.planning/phases/11-website-scaffolding-vercel-deployment/11-CONTEXT.md` — Stack (pnpm, Next 16, strict TS, `src/app` layout, `@/*` alias).
- `.planning/phases/12-chronicle-design-system-port/12-CONTEXT.md` — Token architecture (hybrid CSS vars + `@theme inline`), primitive API (variant unions, Tailwind class strings, minimal surface), `chronicle-mock.css` usage policy (reference-only, never imported).
- `.planning/phases/13-landing-page/13-CONTEXT.md` — Shared `<Nav>` and `<Footer>` shipped; mock-copy-verbatim policy with factual corrections (macOS version); reveal hooks patterns.

### Repository context (factual correctness)
- `Package.swift` (repo root) — Planner MUST grep to confirm the real macOS minimum (`.macOS(.vNN)` or equivalent) and sanity-check `PROJECT.md`'s "macOS 26.0+" claim. This value replaces "macOS 14 (Sonoma) or later" in the mock copy — both in Getting Started prose and any `<Note>` callouts.
- `PROJECT.md` §Constraints — Platform / architecture / distribution facts that Claude-drafted copy for FAQ + Troubleshooting + Configuring Obsidian + Notion must match.
- `README.md` — Canonical project description, acknowledgments, open-source positioning. Use phrasing from here to anchor the Chronicle voice in fresh copy.
- `CHANGELOG.md` — Not consumed in this phase (Phase 15 territory), but FAQ may want to reference "how do I see what's new" → link to `/changelog`.

### Paths introduced by this phase (for reference)
- `website/src/mdx-components.tsx` — MDX global components + element overrides.
- `website/src/app/docs/layout.tsx` — Three-column grid wrapper.
- `website/src/app/docs/page.tsx` — Root `/docs` redirects to `/docs/getting-started` (Claude's Discretion).
- `website/src/app/docs/{6 slugs}/page.mdx` — Content files.
- `website/src/components/docs/Sidebar.tsx` — Left sidebar.
- `website/src/components/docs/TableOfContents.tsx` — Right TOC, client component.
- `website/src/components/docs/sidebar-data.ts` — Build-time-assembled sidebar descriptor.
- `website/src/components/docs/Note.tsx`, `Lede.tsx`, `Crumbs.tsx`, `PrevNext.tsx`, `ShortcutTable.tsx` — Custom MDX components.
- `website/next.config.ts` — Updated with `withMDX` + `pageExtensions`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`<Nav>` + `<Footer>` already mounted in `layout.tsx`** (Phase 13 D-17/18). Docs pages get both for free. The `<Nav>` scroll behavior and brand treatment applies identically on `/docs/*`.
- **Phase 12 primitives** in `src/components/ui/` — `MetaLabel` is the natural fit for sidebar group labels (mono 10px uppercase, 0.08em letter-spacing). `Button` + `LinkButton` available for any CTA inside docs (unlikely at this phase, but available). `Card` available but probably not needed; the main column doesn't use card wrappers.
- **Chronicle tokens** — All sidebar/TOC/prose colors resolve to existing tokens: `bg-paper-warm` (sidebar bg), `bg-paper-soft` (inline code pill), `bg-paper` (active sidebar item), `text-ink` / `text-ink-muted` / `text-ink-faint` / `text-ink-ghost` (heading/body/meta/anchor colors), `border-rule` / `border-rule-strong` (hairlines), `bg-accent-soft` + `text-accent-ink` (note callout + default anchor hover), `bg-spk2-bg` + `text-spk2-fg` + `border-spk2-rail` (note.sage variant), `shadow-lift` (active sidebar card).
- **Font variables** — `--font-inter` (sans body), `--font-spectral` (serif H1/H2), `--font-jetbrains-mono` (mono TOC, labels, code) already loaded by Phase 11 via `next/font`. Re-exported via `@theme inline` as `--font-sans`/`--font-serif`/`--font-mono` (Phase 12). Tailwind utilities `font-sans`/`font-serif`/`font-mono` just work.
- **`useReveal` + `useScrolled` hooks** from Phase 13. Probably not needed for docs; sidebar + TOC are sticky by CSS, and the TOC's scroll-spy is its own IntersectionObserver. Available if a page wants intro-reveal.

### Established Patterns
- **Tailwind v4 CSS-first config.** No `tailwind.config.ts`. All theme in `globals.css` via `@theme inline`. Phase 14 adds no tokens; it consumes existing ones.
- **Variant-union props on primitives** (Phase 12 D-06). If any new doc-specific components expose variants (e.g., `<Note variant="default" | "sage">`), follow this convention — string unions, not boolean flags.
- **`src/components/{layout,sections,mocks}/` directory pattern** (Phase 13). Adding `src/components/docs/` for docs-specific components follows the same top-level-folder convention.
- **App Router file conventions** — `metadata.ts`, `sitemap.ts`, `robots.ts`, `opengraph-image.tsx`, route folders with `page.tsx`. Adding `src/app/docs/**/page.mdx` files follows the same pattern (just with a new extension enabled by `pageExtensions`).
- **pnpm-only** (Phase 11 D-01). All new deps installed via `pnpm add`.
- **Mock-copy-verbatim + factual correction** (Phase 13 specifics). Same policy applies to Getting Started + Shortcuts content in Phase 14.
- **0.5px hairlines** (Phase 12 specifics). `border-[0.5px]` arbitrary-value utilities for all rules in the sidebar, TOC, and prose.

### Integration Points
- **`website/next.config.ts`** — Wrapped with `withMDX(...)`. `pageExtensions` adds `'mdx'`.
- **`website/src/app/layout.tsx`** — Unchanged in this phase. Nav + Footer already mount here; they inherit onto `/docs/*`.
- **`website/src/mdx-components.tsx`** — New file at `src/` root. Required by `@next/mdx` with App Router.
- **`website/src/app/docs/layout.tsx`** — New. The three-column grid wrapper. Renders `<Sidebar>` + `{children}` + `<TableOfContents>` inside a grid container; `{children}` is the page.mdx content.
- **`website/src/app/sitemap.ts`** — Add the six `/docs/*` routes.
- **Nav's "Docs" link** — Currently in `src/components/layout/Nav.tsx` (Phase 13). May need an `aria-current="page"` / active-state highlight when the current pathname starts with `/docs` — planner checks existing `<Nav>` shape and adds minimally.
- **Vercel preview deploys** (Phase 11) — Each PR touching `/website/**` gets a preview URL. Every MDX/page iteration gets a shareable URL.

</code_context>

<specifics>
## Specific Ideas

- **Three-column grid values from mock** — `grid-template-columns: 240px 1fr 200px`, `max-width: 1280px`, `margin: 0 auto`, `min-height: calc(100vh - 64px)`. Breakpoints: `≤1200px` collapses to `240px 1fr` and hides TOC; `≤820px` collapses to `1fr` and hides sidebar. Port these literally into Tailwind utility strings.
- **Sidebar sticky** — `position: sticky; top: 64px` (below nav), `height: calc(100vh - 64px)`, `overflow-y: auto`, `padding: 40px 22px 64px`, `background: var(--color-paper-warm)`, `border-right: 0.5px solid var(--color-rule)`.
- **Group label** — mono 10px weight 500, letter-spacing 0.1em, uppercase, `var(--color-ink-faint)`, margin `22px 8px 10px`. Use `<MetaLabel>` primitive (which already codifies these values).
- **Sidebar link** — `padding: 7px 10px`, 13.5px, `var(--color-ink-muted)`, `border-radius: 6px`, `line-height: 1.35`, `border: 0.5px solid transparent` (so the border doesn't shift on active state). Hover: `var(--color-ink)` + `rgba(255,255,255,0.5)` bg. Active: `var(--color-paper)` bg, `var(--color-ink)` color, `0.5px var(--color-rule)` border, `shadow-lift`, weight 500.
- **Main column** — `padding: 56px 56px 96px`, `max-width: 720px`. Shrinks to `40px 28px 64px` below 900px.
- **Prose H1** — Spectral 40px weight 400, line-height 1.1, letter-spacing `-0.015em`, margin `0 0 14px`.
- **Prose H2** — Spectral 26px weight 400, line-height 1.2, letter-spacing `-0.01em`, margin `56px 0 14px`, position relative (for the anchor).
- **H2 anchor** — `position: absolute; left: -84px; top: 10px`, mono 10px uppercase, letter-spacing 0.08em, `var(--color-ink-ghost)`, `::before` content `"# "`. Hidden below 1100px. `rehype-autolink-headings` with a custom `behavior: 'prepend'` and `content: ...` config gets close; the absolute positioning is in our CSS.
- **Prose H3** — Inter 17px weight 600, letter-spacing `-0.005em`, margin `32px 0 8px`.
- **Prose body** — Inter 16px line-height 1.65, `var(--color-ink)`, `margin: 0 0 16px`. Consecutive `p+p` tightens to `margin-top: -4px` (preserves the mock's prose rhythm).
- **Lede** — Inter 18px, `var(--color-ink-muted)`, line-height 1.5, margin `0 0 28px`, `max-width: 56ch`. `<Lede>` component wraps a `<p>` with these styles.
- **Prose em** — italic, `var(--color-accent-ink)` color (not just italic). Spectral's italic cut (400) is already loaded.
- **Prose strong** — weight 600.
- **Prose list padding** — `padding-left: 20px`, `margin: 0 0 18px`, items spaced `4px`.
- **Inline code** — JetBrains Mono 13.5px, `var(--color-paper-soft)` bg, `padding: 2px 6px`, `border-radius: 4px`, `var(--color-ink)`. Inside a `<pre>`, strip the background and padding (so fenced blocks don't double-wrap).
- **Fenced code** — `var(--color-paper-warm)` bg, `0.5px solid var(--color-rule)` border, `8px` radius, `padding: 16px 18px`, JetBrains Mono 13px, line-height 1.6, `overflow-x: auto`, `margin: 0 0 22px`, `position: relative` (for the lang label).
- **Lang label** — `position: absolute; top: 8px; right: 14px`, font-size 9px, letter-spacing 0.1em, uppercase, `var(--color-ink-faint)`. Content derived from `className` match on `language-*`.
- **Note callout** — `0.5px solid var(--color-rule)` all around, `2px solid var(--color-accent-ink)` left border, `var(--color-accent-tint)` bg (or `var(--color-accent-soft)` if `accent-tint` isn't a token — planner checks), 8px radius, `padding: 14px 18px`, `margin: 0 0 22px`, font-size 14.5px. `<strong>` inside renders as a mono 10px uppercase label with `0.1em` letter-spacing, `var(--color-ink-faint)`, block-level, 4px bottom margin.
- **Note.sage** — same structure, but left-border becomes `var(--color-spk2-rail)`, bg becomes `var(--color-spk2-bg)`, `<strong>` color becomes `var(--color-spk2-fg)`.
- **Hr.soft** — `border: 0; border-top: 0.5px solid var(--color-rule); margin: 48px 0`.
- **Prev/Next** — 2-column grid, 12px gap, margin-top 56px. Each card: `padding: 16px 18px`, `0.5px solid var(--color-rule)`, `10px` radius, `var(--color-paper)` bg, hover `var(--color-paper-warm)`. Label: mono 10px uppercase letter-spacing 0.08em `var(--color-ink-faint)`. Title: Spectral 16px weight 500 `var(--color-ink)`. `.next` aligns text right. Collapses to single column below 600px.
- **Right TOC** — `padding: 56px 22px`, sticky `top: 64px`. Mono 10px uppercase label ("ON THIS PAGE"). List: `border-left: 0.5px solid var(--color-rule)`. Each link: `padding: 4px 12px`, mono 10.5px letter-spacing 0.04em uppercase, `var(--color-ink-faint)`, `margin-left: -0.5px`, `border-left: 1px solid transparent`. Hover: `var(--color-ink)`. Active: `var(--color-ink)` + `border-left-color: var(--color-accent-ink)`.
- **Shortcut table (`.sc-table`)** — `0.5px solid var(--color-rule)` border, 10px radius, `overflow: hidden`. Rows: grid `170px 1fr`, 14px gap, `12px 18px` padding, bottom 0.5px rule (last row no bottom). Key group: `.keys` flex 4px gap of kbd chips. Label: `var(--color-ink)` 14.5px. Sub-label: `var(--color-ink-muted)` 13px `margin-top: 2px`.
- **Keyboard chip `.kbd`** — Reuse the kbd styling Phase 13 shipped for landing. `⌘R` variant = navy (`bg-accent-soft` + `text-accent-ink`), `⌘⇧R` = sage, default = paper + 0.5px rule-strong + ink. Shortcuts page uses these heavily; Getting Started uses them once or twice inline.
- **Editorial voice for fresh copy (FAQ / Troubleshooting / Configuring Obsidian / Notion property mapping)** — Match the mock's existing Getting Started + Shortcuts voice. Calm, precise, editorial. Concrete capability statements ("Records both sides of your Zoom call, locally") beat abstractions. No "seamless", "empower", "revolutionize". The app is quiet; the docs are quiet. The mock's `.note.sage` "What 'on-device' actually means" block is the tone benchmark — factual, specific, verifiable.
- **FAQ candidate questions** (draft pool for Claude to narrow down): "Does PS Transcribe send audio to any cloud service?" "Which macOS versions are supported?" "What languages does transcription support?" "Can I use it without an Obsidian vault?" "How accurate is speaker diarization?" "Is there a mobile version?" "What's the file format for saved transcripts?" "Can I edit transcripts after recording?" "Does it work on Intel Macs?" "How do updates work?" "Does the app auto-update?" "Can I export to Notion without frontmatter?"
- **Troubleshooting candidate topics** (draft pool): "The app can't hear system audio" → ScreenCaptureKit permission. "Speaker names are wrong" → rename via ⌘E. "Transcript is slow to appear" → expected during VAD/diarization pass. "Notion sync failed" → check integration token in Preferences. "Models didn't download" → manual download link / disk space. "Privacy mode hid my transcript from someone I wanted to share with" → toggle off. "Sparkle update didn't appear" → appcast URL / manual check.
- **Configuring your vault candidate structure**: set vault path, understand template tokens (`{{year}}`, `{{month}}`, `{{date}}`, `{{title}}`), frontmatter schema (date, duration, participants, tags), how meetings vs memos split (separate paths). Could reference the `.planning/` materials and/or the actual app's Preferences UI.
- **Notion property mapping candidate structure**: connect integration via token, pick a database, map frontmatter → Notion properties (date → date prop, duration → number, participants → multi-select, tags → multi-select, transcript → body). Note that frontmatter fields without a matching property are ignored silently.
- **Anchor label text** — extract the last word or a shortened version of the heading (mock uses e.g. `# install`, `# permissions`, `# vault`, `# record`, `# notion` — all lowercase single words, not full heading slugs). Implementation note: `rehype-autolink-headings` by default inserts `#` as link content. To match mock's "one-word lowercase label" we'll need a custom `content` function that derives the label from the heading text. Acceptable fallback: just use `#` + the rehype-slug slug (longer but semantically correct).
- **Sticky nav offset** — Nav is 64px tall. `top: 64px` on sidebar and TOC and `min-height: calc(100vh - 64px)` on the grid. Confirm Phase 13's nav actually renders at 64px; if different, adjust.
- **FAQ/Troubleshooting page H2 structure** — Each FAQ question is an H2 so the TOC functions as a question index. Troubleshooting's common issues are H2 headings with the fix as prose below. This gives both pages a useful right-hand nav automatically.

</specifics>

<deferred>
## Deferred Ideas

- **The five non-shipping mock sidebar pages** — Recording your first meeting (subtree of Getting Started), Frontmatter schema (subtree of Configuring your vault / Notion mapping), Privacy & data (subtree of Getting Started `.note.sage`), Build from source (Developer group), Sparkle appcast (Developer group). Each becomes its own MDX page when the docs need expansion; the sidebar builder auto-picks them up on creation. v1.2+ candidate.
- **Syntax highlighting** — Shiki + `rehype-pretty-code` would give beautiful tokenization if docs add more code-heavy content (e.g., Configuring your vault's YAML block gets more examples). Revisit when the fenced-block count doubles.
- **Docs search (Cmd+K)** — Explicit milestone Out of Scope (REQUIREMENTS.md). Worth revisiting when doc count passes ~15 pages; 6 pages is navigable via sidebar.
- **Mobile drawer/hamburger for sidebar** — Mock just hides the sidebar below 820px. Matching that. If post-ship user testing flags "I can't find docs on mobile", revisit with a collapsible top drawer or a `<select>` page-picker.
- **Dark mode** — Blocked by DESIGN-04 (Phase 12). Out of milestone.
- **Analytics / tracking** — Milestone Out of Scope.
- **Versioned docs** — If v2.0 breaks app behavior, we'd want to preserve v1.x docs. Today the CHANGELOG page covers the delta. Post-v1.x if needed.
- **Localization / i18n** — Milestone Out of Scope. Docs are English-only.
- **MDX RSS feed or newsletter** — Out of scope. No newsletter.
- **Playwright / visual-regression testing on docs** — Not required. Revisit in a post-v1.1 hardening pass alongside landing-page regression tests.
- **Anchor-label hover affordance or custom hover state on TOC links** — Mock doesn't do hover-reveal; we match. If users miss the affordance, add later.
- **`<Crumbs>` auto-derivation from sidebar** — Mock treats crumbs as authored ("Docs / Start here / Getting started"). We keep them authored for now via a manual `<Crumbs>` component. Auto-derivation from the `doc` export + slug is possible later.
- **Prev/Next auto-wiring from sidebar** — Shipped as Claude's Discretion auto-from-sidebar; optional per-page override supported. If edge cases arise (e.g., a page that shouldn't have prev/next), authors pass `<PrevNext show={false} />` or similar.
- **Per-page OG images** — Global OG from Phase 11 covers all routes. Per-doc OG images would use `opengraph-image.tsx` co-located with each page.mdx — deferred polish.
- **Full 11-page sidebar** — The remaining 5 mock slots can land as real pages later. This phase holds the line at 6 to keep the scope honest.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.

</deferred>

---

*Phase: 14-docs-section*
*Context gathered: 2026-04-23*
