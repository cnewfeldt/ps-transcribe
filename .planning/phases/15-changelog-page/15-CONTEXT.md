# Phase 15: Changelog Page - Context

**Gathered:** 2026-04-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship `ps-transcribe-web.vercel.app/changelog` as a styled, build-time-rendered page that consumes the existing `CHANGELOG.md` at the repo root via the parser already shipped in Phase 13-01 (`website/src/lib/changelog.ts`). Renders 10 release cards (today: v1.0.0 → v2.1.1) sorted newest-first, preserving every subsection grouping verbatim from the markdown source. Inherits the root `<Nav>` + `<Footer>` mounted in `layout.tsx`.

In scope:
- `website/src/app/changelog/page.tsx` — server-component page that calls `getAllReleases()` and renders the hero + two-column layout
- Two-column layout: 180px sticky left aside (Versions list + Subscribe block) + 1fr release stream, 48px gap, collapses to single column below 820px
- `<ReleaseCard>` component — date + version header, Current/Breaking pill row (top-right), section grid (heading + colored bullet list), `release--current` / `release--older` visual variants
- `<VersionsAside>` component — sticky scroll-spy via IntersectionObserver matching Phase 14 D-15 pattern (`rootMargin: '-20% 0px -70% 0px'`); active-state styling on the link matching the version currently in view
- `<SubscribeBlock>` — three external-link rows: Sparkle appcast URL, GitHub releases page, RSS feed (the new route below)
- New build-time RSS Route Handler at `website/src/app/changelog/rss.xml/route.ts` — emits RSS 2.0 derived from `getAllReleases()`, item per release, item description = HTML-rendered sections, item link = `https://ps-transcribe-web.vercel.app/changelog#vX-Y-Z`
- `website/src/lib/section-color.ts` — heuristic keyword classifier mapping freeform CHANGELOG headings to one of 5 buckets (features=accent-ink, ux=spk2-rail, fixes=ink-muted, breaking=rec-red, default=ink-faint)
- `website/src/lib/inline-markdown.tsx` — small renderer for inline backticks (`code`), bold (`**text**`), and Markdown links (`[text](url)`); no block-level support
- `<Pill>` primitive (small new addition under `website/src/components/ui/`) — variants `live` (Current, navy LED dot) and `breaking` (red tint border/bg). Two variants only; not over-engineered.
- `Nav.tsx` modification — extend the existing `usePathname()` active-state pattern (Phase 14 D-11) to highlight the "Changelog" link on `/changelog/*`
- `sitemap.ts` modification — add `/changelog` to the static URL list
- Anchor IDs per release in slug form `vX-Y-Z` (mock convention: `v2-1-0`, `v2-0-0`, `v1-4-2`)
- Hero ported verbatim from mock: "Every release." H1 + "Notes from each version of PS Transcribe, newest first. Auto-update through Sparkle will always bring you here if you want the full picture."

Out of scope (deferred or excluded):
- Per-release Download or "Diff from previous" action links (only 2 of 10 versions have matching git tags — deferred until tags backfill or new release convention established)
- Codename slot per release (not in source)
- Per-release summary line (not in source)
- DMG byte size + minOS in card foot (would require GitHub Releases API at build time)
- Recommended / Patch / Minor pills (subjective or noisy when computed from semver across 10 entries)
- Card foot row entirely (no hairline, no meta line, no actions — card ends after the sections grid)
- Timeline-dot visual element (mock had it; we drop it since we dropped the foot entirely)
- Search / filter / category-based filtering (10 entries is navigable without)
- Pagination (would only matter past ~30 entries)
- Atom feed alongside RSS (RSS 2.0 covers the use case; Atom can be added later)
- Custom domain — post-v1.1
- Dark mode — blocked by DESIGN-04
- Localization — out of milestone
- Reading the public `release-notes/v<version>.md` files (per CHANGELOG v2.1.1 convention) — LOG-01 says CHANGELOG.md is the source; release-notes/ is a separate user-facing concern outside this phase

</domain>

<decisions>
## Implementation Decisions

### Section labels & color taxonomy

- **D-01:** **Verbatim labels.** Render the real CHANGELOG heading text exactly as it appears (e.g., "Distribution / Tooling", "Auto-updates (Sparkle)", "UX / Redesign — Quiet Chronicle", "Notion Integration", "Scope reduction"). Do NOT normalize, abbreviate, or rewrite. Source fidelity beats taxonomy uniformity.
- **D-02:** **Source order within a card.** Sections render in the same order they appear under the version heading in CHANGELOG.md. No canonical reorder. Preserves author intent (e.g., v2.0.0's "Breaking" section appears wherever the author placed it; v2.1.0's "UX / Redesign" leads because that's the headline).
- **D-03:** **Heuristic 4-color mapping** applied to both the section H4 label color and the bullet `::before` dot color. Keyword rules (case-insensitive, applied in order):
  - **breaking** (`var(--color-rec-red)`): `/\b(breaking|migration|scope\s+reduction)\b/i`
  - **features** (`var(--color-accent-ink)`): `/\b(features?|integration|notion|sparkle|auto[-\s]?update|distribution)\b/i`
  - **ux** (`var(--color-spk2-rail)`): `/\b(ux|interface|layout|library|recording|onboarding|redesign|transcript)\b/i`
  - **fixes** (`var(--color-ink-muted)` label, `var(--color-ink-ghost)` dot): `/\b(fix|fixes|bug|internals)\b/i`
  - **default** (`var(--color-ink-faint)` label, `var(--color-ink-ghost)` dot): everything else (Docs, Milestone, Housekeeping, Testing, Developer tooling, Repo / Distribution)
- **D-04:** **Color logic lives in `website/src/lib/section-color.ts`,** not in the parser. The parser (`lib/changelog.ts`) stays a pure data layer. The classifier exports a single `classifySection(title: string): 'features' | 'ux' | 'fixes' | 'breaking' | 'default'` function consumed by `<ReleaseCard>` at render time.
- **D-05:** **Bullet dots inherit the section color** (mock-faithful). 4px circular dot, color = the section's classified bucket color. Default bucket dots use `ink-ghost`. Matches the mock's `.sec--features li::before { background: var(--accent-ink) }` pattern.

### Mock-only metadata (codename / summary / pills / DMG meta)

- **D-06:** **No codename slot.** The mock's italic Spectral codename next to the version ("Quiet Chronicle", "Silent Quarter") is dropped. Real CHANGELOG.md doesn't have codenames; v2.1.0's "Quiet Chronicle" is conveyed by its section heading "UX / Redesign — Quiet Chronicle" anyway.
- **D-07:** **No summary line.** The mock's italic-Spectral 18px per-release summary is dropped. Cards jump from header → pills → sections grid with no synthesized prose in between. Single source = CHANGELOG.md; no first-bullet promotion, no manual annotation convention.
- **D-08:** **Pills: only Current + Breaking, both auto-derived.**
  - **Current pill** renders on `entries[0]` (newest release): navy "live" style with a small LED dot, mono uppercase "Current" label.
  - **Breaking pill** renders on any release whose `sections[]` includes a section whose title (lowercased) matches `/\bbreaking\b/`. Today: v2.0.0 only (it has a `### Breaking` section). Red-tinted background + red border + red text.
  - **Drop** Recommended (subjective), Patch / Minor (semver-derived would yield 5/10 "Patch" pills — visual noise).
- **D-09:** **No DMG meta line.** "Signed DMG · 34.2 MB · macOS 14+" is dropped. No GitHub Releases API call at build, no hardcoded version drift.
- **D-10:** **`release--current` visual treatment** (navy-tinted border `rgba(43, 74, 122, 0.2)` + `shadow-lift`) is applied to `entries[0]` only.
- **D-11:** **`release--older` opacity treatment** (`opacity: 0.92`) is applied to `entries[2..]`. Pattern: index 0 = current, index 1 = neutral, indices 2+ = older. Matches the mock's three-tier visual rhythm (newest stands out, recent stays normal, older recedes slightly).

### Filter aside (Versions list + Subscribe)

- **D-12:** **All 10 versions** in the left aside, no cap. With 10 entries the aside stack is ~280px tall — fits comfortably under the 64px sticky offset, no internal scroll needed today.
- **D-13:** **Scroll-spy active state** via IntersectionObserver in a `'use client'` component. Same pattern Phase 14 established for the docs TOC (D-15): `rootMargin: '-20% 0px -70% 0px'`, toggles `data-active` on the matching aside link. Each release `<article>` gets `id="vX-Y-Z"` so the observer can map them.
- **D-14:** **Aside link format:** `vX.Y.Z` left-aligned + small date right-aligned (e.g., `v2.1.1` ··· `Apr 23`). Mono 11px, letter-spacing 0.04em, padding 5px 10px, border-radius 6px. Hover and active state both use `bg-paper-warm` + `text-ink`.
- **D-15:** **Aside heading:** "Versions" — mono 10px uppercase via `<MetaLabel>` primitive (Phase 12). Matches the mock's `.cl-filters h5` exactly.
- **D-16:** **Subscribe block ships all three links:**
  - **Sparkle appcast** → `https://raw.githubusercontent.com/cnewfeldt/ps-transcribe-releases/main/appcast.xml` (per CHANGELOG v2.1.1 — the actual update mechanism)
  - **GitHub releases** → `https://github.com/cnewfeldt/ps-transcribe-releases/releases` (the public releases repo)
  - **RSS feed** → `/changelog/rss.xml` (the new Route Handler this phase introduces)
  - All three open in a new tab (`target="_blank" rel="noopener"`).
  - Subscribe heading: "Subscribe", same `<MetaLabel>` treatment as "Versions".
- **D-17:** **`/changelog/rss.xml` is a Next 16 Route Handler** at `website/src/app/changelog/rss.xml/route.ts` (the literal `.xml` in the path is a routing convention; Next allows arbitrary file names in route segments). Returns `Content-Type: application/rss+xml`. Body = RSS 2.0 channel with one `<item>` per release: `<title>vX.Y.Z</title>`, `<pubDate>` from the release date, `<link>https://ps-transcribe-web.vercel.app/changelog#vX-Y-Z</link>`, `<guid isPermaLink="true">` same URL, `<description><![CDATA[ ...HTML-rendered sections... ]]></description>`. Channel-level: `<title>PS Transcribe — Changelog</title>`, `<link>https://ps-transcribe-web.vercel.app/changelog</link>`, `<description>Release notes for PS Transcribe.</description>`, `<atom:link rel="self" href="https://ps-transcribe-web.vercel.app/changelog/rss.xml"/>`.

### Per-release actions, bullet rendering, card foot

- **D-18:** **No per-release Download or Diff actions.** Only 2 of 10 versions currently have git tags (`v1.0`, `v2.0.0`); shipping the actions would mean 8/10 broken links or conditional rendering complexity. The `<SubscribeBlock>` "GitHub releases" link covers download discoverability site-wide; users land on the public releases repo and grab whatever they need. Tag backfill is captured under Deferred Ideas — if/when tags exist for every version, the actions can be added in a follow-up phase.
- **D-19:** **Inline bullet rendering supports backticks + bold + Markdown links** via a small custom renderer at `website/src/lib/inline-markdown.tsx`. Approach:
  - Tokenize the bullet string by walking the regex pattern in priority order: code (`` `...` ``) → bold (`**...**`) → link (`[text](url)`) → plain text. No nested handling beyond depth 1 (CHANGELOG bullets don't nest these constructs).
  - Returns `React.ReactNode[]` (array of strings + `<code>` / `<strong>` / `<a>` elements). The component renders them directly inside `<li>`.
  - Inline `<code>` styling matches Phase 14 D-18 for inline code: JetBrains Mono 12.5px (per mock's `.sec li code { font-size: 12.5px }`), `paperSoft` background, 2px/6px padding, 4px radius, ink color.
  - `<a>` elements get `target="_blank" rel="noopener"` if the URL is external (starts with `http`).
  - **Library choice:** roll the small custom renderer (~30 lines). Skip pulling in `react-markdown` — it's overkill for inline-only handling and adds a dep + bundle weight for one feature. Planner may revisit if real CHANGELOG starts using more inline constructs.
- **D-20:** **Drop the card foot row entirely.** No 0.5px hairline below the sections grid, no meta line, no action links. Card ends after the section grid. Combined with D-09 (no DMG meta) and D-18 (no actions), the foot would be empty anyway.
- **D-21:** **No `.timeline-dot`.** The mock's 10px circle absolutely positioned at `left: -24px` on every card is dropped. We're not shipping the timeline visual cue (it implied a vertical thread of dots which adds visual weight without functional value once the foot is dropped).

### Navigation & wiring

- **D-22:** **Nav Changelog link gets `usePathname()` active-state.** Mirror Phase 14 D-11's exact pattern: existing `linkActive` style applied when `usePathname()` starts with `/changelog`. Existing `Nav.tsx` already has a `docsActive` derivation; add a parallel `changelogActive` derivation and use it on the existing `<Link href="/changelog">`. Single-line change.
- **D-23:** **`sitemap.ts` adds `/changelog` and `/changelog/rss.xml`** as static routes. The RSS endpoint isn't a page but its inclusion in the sitemap is fine and aids discoverability.

### Claude's Discretion

- **Hero copy** — Port verbatim from the mock: H1 "Every release." + sub "Notes from each version of PS Transcribe, newest first. Auto-update through Sparkle will always bring you here if you want the full picture." Hero meta label: "Changelog" via `<MetaLabel>`. No factual fixes needed (Sparkle reference is accurate per CHANGELOG v2.1.1).
- **Mobile breakpoints** — Match the mock literally. `≤820px`: aside collapses, single-column release stream. `≤680px`: section grid (label / list two-column) collapses to stacked single column. Anything narrower keeps stacking gracefully.
- **Container max-width** — Confirm against the existing site's `.container` equivalent. Phase 13 likely settled on a max-width; reuse it. Mock uses 1280px.
- **Pill primitive shape** — Two variants only (`'live'` for Current, `'breaking'` for Breaking). Variant-union props per Phase 12 D-06 convention. The Pill primitive lives in `website/src/components/ui/Pill.tsx` and is exported from the `ui/index.ts` barrel.
- **Where the heuristic keyword table lives** — `website/src/lib/section-color.ts`, exported as a single `classifySection()` function. Keywords as a flat object the file owns; not surfaced through the parser API.
- **Inline `<code>` styling source of truth** — Reuse the same Tailwind class string Phase 14's MDX `code` override uses (D-18). If that's encoded as a class in `mdx-components.tsx`, hoist the class string to a shared constant or just port the values verbatim. Acceptable if the planner picks "duplicate the values, don't share" — same end result.
- **Anchor copy-link affordance** — Out of scope. Anchor IDs exist (`#v2-1-1`) so the URL bar contains the anchor when scrolled, but no per-release "copy link" button. If users want the link they can right-click the version in the aside.
- **`<MetaLabel>` arrangement in the hero** — Spectral "Every release." + Inter sub. Wrap in the same hero container Phase 13 used for the landing hero, scaled down (the changelog hero is `padding: 64px 0 40px` with a bottom border, not the full-bleed landing hero).
- **Filter aside vertical spacing** — Match the mock: 22px between "Versions" label and the list, 28px after the last version link before "Subscribe", 12px between "Subscribe" label and its list.
- **Loading and revalidation behavior** — Pure static page; no `revalidate`, no loading state. Build-time only. Adding a new entry to CHANGELOG.md at the repo root requires a redeploy (Vercel auto-builds on push).

### Folded Todos

None — no pending todos matched this phase.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements

- `.planning/REQUIREMENTS.md` §LOG — Requirements LOG-01 through LOG-04 (this phase's exact scope).
- `.planning/ROADMAP.md` §"Phase 15: Changelog Page" — Phase goal, four success criteria, dependency on Phase 12.
- `.planning/PROJECT.md` §"Current Milestone: v1.1 Marketing Website" — Milestone framing and scope boundaries (no analytics, no custom domain, no commerce, light-mode only).

### Design source of truth

- `design/ps-transcribe-web-unzipped/changelog.html` — **PRIMARY MOCK.** 370 lines. Hero + 180px filter aside (Versions + Subscribe) + release stream with 4 sample release cards exhibiting all visual variants (`release--current`, `release`, `release--older`). Every visual decision in this phase traces back to this file. Read top-to-bottom before writing any component.
- `design/ps-transcribe-web-unzipped/assets/chronicle-mock.css` — **Reference-only** for `.cl-hero`, `.cl-stream`, `.cl-filters`, `.releases`, `.release`, `.release--current`, `.release--older`, `.release__head`, `.release__date`, `.release__ver`, `.release__codename`, `.release__meta`, `.release__summary`, `.release__sections`, `.sec`, `.sec h4` + variants (`sec--features`, `sec--ux`, `sec--fixes`, `sec--breaking`), `.sec ul`, `.sec li`, `.sec li::before` + color variants, `.release__foot`, `.timeline-dot`, `.pill`, `.pill--live`, `.pill--sage`, `.kbd`. **Never imported. Never referenced by class name in React.** Values are ported into Tailwind utility classes.
- `design/ps-transcribe-web-unzipped/assets/tokens.css` — Source tokens (already ported to `website/src/app/globals.css` by Phase 12; listed for cross-reference).
- `.planning/research/CLAUDE-DESIGN-BRIEF.md` §Palette, §Typography, §"Spacing, radii, shadows" — Calibration reference for any new values not in the mock.

### Source data

- `CHANGELOG.md` (repo root) — The single source of truth for release history. 10 releases as of 2026-04-24. Subsection vocabulary is freeform (~19 unique heading strings across all releases) — D-03's heuristic classifier handles this. Inline markdown usage: ~31 backtick code occurrences, 2 bold lines, 1 Markdown link.
- `website/src/lib/changelog.ts` — **Existing parser, shipped Phase 13-01.** Exports `getAllReleases()` returning `ChangelogEntry[]` and `getLatestRelease()`. Type: `{ version, versionShort, date, dateHuman, sections: [{ title, items: string[] }] }`. Reads `process.cwd() + '../CHANGELOG.md'` (Next.js cwd is `/website`, so this resolves to repo-root). Already module-cached. **Reuse without modification.** Parser regex handles em-dash AND hyphen separators in `## [version] — date` lines.

### Framework & tooling docs

- `website/node_modules/next/dist/docs/01-app/02-guides/route-handlers.md` — **Authoritative Next 16 App Router Route Handler guide.** Required reading before writing the RSS Route Handler. Covers `route.ts` file convention, `Response` constructor with custom `Content-Type`, GET handler signature, static vs dynamic resolution.
- `website/node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/route.md` — Reference for the Route Handler file convention (`route.ts` exports named HTTP method handlers).
- `website/node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/sitemap.md` — Reference for the existing `sitemap.ts` we extend.
- `node_modules/next/dist/docs/` (general) — Next.js 16 metadata API, App Router patterns, `<Link>` semantics.
- `node_modules/tailwindcss/` docs — Tailwind v4 `@theme inline` + arbitrary values.
- Agents may use `mcp__plugin_context7_context7__*` to fetch additional Next.js, RSS spec, or React docs if local copies are insufficient.

### Existing code to reuse / respect / not touch

- `website/src/app/layout.tsx` — Root layout already renders `<Nav />` and `<Footer />` (Phase 13 D-17/18). Changelog page inherits both for free. Do NOT duplicate them inside `src/app/changelog/layout.tsx` (and don't introduce that layout file unless the planner finds a real reason).
- `website/src/components/layout/Nav.tsx` — Existing nav. **Modify** to add a `usePathname()`-driven active-state for the existing `<Link href="/changelog">`. Mirror the existing `docsActive` pattern exactly. Single-line addition.
- `website/src/components/layout/Footer.tsx` — Footer already links to `/changelog` as "Changelog". No change required for this phase.
- `website/src/components/ui/` — Phase 12 primitives (`Button`, `Card`, `MetaLabel`, `SectionHeading`, `CodeBlock`, `LinkButton`). **Reuse `MetaLabel` for both aside headings ("Versions", "Subscribe") and the hero meta label ("Changelog").** **Reuse `Card` if the planner judges it a good fit for the release card** (it provides paper bg + 0.5px rule + rounded-card + 22px padding — close to but not exactly the mock's 32px/36px padding; the planner may decide to roll a bespoke `<ReleaseCard>` rather than wrap `Card`). **Add `Pill.tsx`** as a new primitive in `ui/` with two variants (`live` / `breaking`); export from the `ui/index.ts` barrel.
- `website/src/lib/site.ts` — `SITE.OWNER`, `SITE.REPO`, `SITE.REPO_URL`, `SITE.APPCAST_URL`. The Subscribe block's GitHub releases link should use `SITE.REPO_URL + '/releases'` or — more accurately per CHANGELOG v2.1.1 — point at `https://github.com/cnewfeldt/ps-transcribe-releases/releases`. Planner: **add a new constant `SITE.RELEASES_URL`** to `site.ts` for the public releases repo URL, then reference it from both the Subscribe block and (eventually) the landing-page Download CTA if it doesn't already.
- `website/src/app/globals.css` — Chronicle token source of truth (16 colors + 5 radii + 3 shadows + font vars). Consume tokens via Tailwind utilities (`bg-paper-warm`, `text-ink-muted`, `border-rule`) or `var(--color-*)` references. Do NOT redefine tokens.
- `website/src/app/sitemap.ts` — **Modify** to add `/changelog` (and optionally `/changelog/rss.xml`).
- `website/src/hooks/useScrolled.ts` — Existing hook from Phase 13. May or may not be useful; the aside scroll-spy uses its own IntersectionObserver, not `useScrolled`. Available if a header treatment wants to react to page scroll.
- `website/CLAUDE.md` / `website/AGENTS.md` — **"This is NOT the Next.js you know."** Downstream agents MUST read `node_modules/next/dist/docs/` (especially the Route Handlers guide above) before writing the RSS endpoint. Training-data Next.js patterns may be outdated.

### Prior phase context

- `.planning/phases/11-website-scaffolding-vercel-deployment/11-CONTEXT.md` — Stack (pnpm, Next 16, strict TS, `src/app` layout, `@/*` alias), production deploy URL `ps-transcribe-web.vercel.app` (NOT `ps-transcribe.vercel.app` — that slug was claimed by another account; v1.1 ships under the `-web` suffix).
- `.planning/phases/12-chronicle-design-system-port/12-CONTEXT.md` — Token architecture (hybrid CSS vars + `@theme inline`), primitive API (variant unions, Tailwind class strings, minimal surface), `chronicle-mock.css` usage policy (reference-only, never imported).
- `.planning/phases/13-landing-page/13-CONTEXT.md` — Shared `<Nav>` and `<Footer>` shipped (D-17/18); Phase 13-01 introduced `lib/changelog.ts`, `lib/site.ts`, and `useScrolled` / `useReveal` hooks; mock-copy-verbatim policy with mechanical fixes.
- `.planning/phases/14-docs-section/14-CONTEXT.md` — D-11 active-state pattern via `usePathname()` (we mirror for Changelog link); D-15 IntersectionObserver scroll-spy with `rootMargin: '-20% 0px -70% 0px'` (we reuse the same pattern for the versions aside); D-18 inline `<code>` styling values (paperSoft pill, JetBrains Mono).

### Repository facts (factual correctness)

- `PROJECT.md` §Constraints — Platform / architecture / distribution facts. Production URL is `ps-transcribe-web.vercel.app`.
- `CHANGELOG.md` v2.1.1 entry — Documents the public releases repo (`cnewfeldt/ps-transcribe-releases`) and the Sparkle appcast URL pattern. Source of truth for the Subscribe block links.
- Git tags inventory: `v2.0.0`, `v1.0`, `archive/llm-analysis-attempt`. Most CHANGELOG versions do not have matching tags — this is the constraint that drove D-18 (no per-release Download/Diff actions).

### Paths introduced by this phase (for reference)

- `website/src/app/changelog/page.tsx` — The page.
- `website/src/app/changelog/rss.xml/route.ts` — RSS Route Handler (path includes literal `.xml`).
- `website/src/components/changelog/ReleaseCard.tsx` — Release card (header + pills + sections grid).
- `website/src/components/changelog/VersionsAside.tsx` — Sticky left aside with versions list + Subscribe block; client component for the IntersectionObserver scroll-spy.
- `website/src/components/changelog/SubscribeBlock.tsx` — May be inlined into `VersionsAside` if planner judges separate component over-engineered.
- `website/src/components/ui/Pill.tsx` — New primitive, two variants.
- `website/src/lib/section-color.ts` — Heuristic classifier for section title → bucket.
- `website/src/lib/inline-markdown.tsx` — Inline-only Markdown renderer (backticks, bold, links).
- `website/src/lib/site.ts` — **Modified:** add `SITE.RELEASES_URL` and `SITE.SPARKLE_APPCAST_URL` constants.
- `website/src/components/layout/Nav.tsx` — **Modified:** add `changelogActive` derivation mirroring `docsActive`.
- `website/src/app/sitemap.ts` — **Modified:** add `/changelog`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`website/src/lib/changelog.ts`** — Parser shipped in Phase 13-01. `getAllReleases()` returns the typed dataset this phase consumes verbatim. No parser changes needed for any decision in this CONTEXT.
- **`<Nav>` + `<Footer>` already mounted in `layout.tsx`** (Phase 13). Changelog page inherits both for free. Nav already has the `<Link href="/changelog">` — only modification is the `usePathname()` active-state extension (D-22).
- **Phase 12 primitives** in `src/components/ui/` — `MetaLabel` is the natural fit for the hero "Changelog" eyebrow + the aside "Versions" / "Subscribe" headings + the section H4 labels (mono 10px uppercase, 0.1em letter-spacing). `Card` may or may not be used for the release card body (planner judgment — mock padding is 32px/36px vs Card's 22px).
- **Chronicle tokens** — All colors resolve to existing tokens: `bg-paper` (release card bg), `bg-paper-warm` (aside hover/active state), `bg-paper-soft` (inline code pill background), `text-ink` / `text-ink-muted` / `text-ink-faint` / `text-ink-ghost`, `border-rule` / `border-rule-strong` (hairlines), `text-accent-ink` + arbitrary `rgba(43,74,122,0.2)` border for `release--current`, `text-rec-red` + arbitrary `rgba(194,74,62,0.08)` bg for breaking pill, `text-spk2-rail` for ux section dots/labels, `shadow-lift` for the current release card.
- **Font variables** — `--font-inter` / `--font-spectral` / `--font-jetbrains-mono` already loaded by Phase 11 via `next/font`, re-exported via `@theme inline` as `--font-sans` / `--font-serif` / `--font-mono` (Phase 12). Tailwind `font-sans` / `font-serif` / `font-mono` utilities work directly.
- **`useScrolled` hook** from Phase 13. Probably not needed for changelog (aside is sticky via CSS, scroll-spy is its own IntersectionObserver). Available if any sub-component wants page-scroll awareness.

### Established Patterns

- **Tailwind v4 CSS-first config.** No `tailwind.config.ts`. All theme in `globals.css` via `@theme inline`. Phase 15 adds no new tokens; it consumes existing ones.
- **Variant-union props on primitives** (Phase 12 D-06). The new `<Pill>` component follows: `variant: 'live' | 'breaking'`, no boolean flags.
- **`src/components/{layout,sections,mocks,docs}/` directory pattern** (Phases 13/14). Adding `src/components/changelog/` for changelog-specific components follows the same top-level-folder convention.
- **App Router file conventions** — `metadata.ts`, `sitemap.ts`, `robots.ts`, route folders with `page.tsx`, `route.ts` for Route Handlers. The RSS endpoint at `app/changelog/rss.xml/route.ts` follows the standard Route Handler convention; the literal `.xml` in the segment name is allowed.
- **pnpm-only** (Phase 11 D-01). No new runtime deps required for Phase 15 (custom inline-markdown renderer per D-19; Route Handler is built-in to Next).
- **Mock-copy-verbatim + factual correction** (Phase 13 specifics). Hero copy ports verbatim; no factual fixes needed for this phase's hero text.
- **0.5px hairlines** (Phase 12 specifics). `border-[0.5px]` arbitrary-value utilities for all rules in the card border, head divider, and aside.
- **Active-state via `usePathname()`** (Phase 14 D-11). Reuse identically for the Nav Changelog link (D-22).
- **IntersectionObserver scroll-spy** (Phase 14 D-15). `rootMargin: '-20% 0px -70% 0px'`. Reuse identically for the versions aside (D-13).

### Integration Points

- **`website/src/app/layout.tsx`** — Unchanged in this phase. Nav + Footer already mount here; they inherit onto `/changelog`.
- **`website/src/components/layout/Nav.tsx`** — One-line addition: `const changelogActive = pathname?.startsWith('/changelog')` and apply `linkActive` class to the Changelog `<Link>` when true.
- **`website/src/app/sitemap.ts`** — Add `/changelog` entry (and optionally `/changelog/rss.xml`).
- **`website/src/lib/site.ts`** — Add two new constants: `SITE.RELEASES_URL` (public releases repo) and `SITE.SPARKLE_APPCAST_URL` (raw appcast XML URL).
- **`website/src/lib/changelog.ts`** — Consumed read-only. No mutations.
- **Vercel preview deploys** (Phase 11) — Each PR touching `/website/**` gets a preview URL. Hero + aside + cards iterate visually on a shareable URL.

</code_context>

<specifics>
## Specific Ideas

- **Mock CSS values to port literally** (consume tokens, never `chronicle-mock.css`):
  - `.cl-hero` — `padding: 64px 0 40px`, `border-bottom: 0.5px solid var(--color-rule)`, container `max-w-[1280px]` with site-wide horizontal padding.
  - `.cl-hero h1` — Spectral, weight 400, `font-size: clamp(40px, 5vw, 56px)`, `letter-spacing: -0.015em`, `line-height: 1.08`, `margin: 0`.
  - `.cl-hero p` — Inter, `var(--color-ink-muted)`, `max-w-[52ch]`, `margin-top: 18px`, `font-size: 17px`, `line-height: 1.55`.
  - `.cl-stream` — `padding: 48px 0 96px`, `display: grid`, `grid-template-columns: 180px 1fr`, `gap: 48px`. Below 820px: single column, gap 22px.
  - `.cl-filters` — `position: sticky; top: 64px; align-self: start` (NOT mock's 84px — our nav is 64px).
  - `.cl-filters` heading — mono 10px / 0.1em / uppercase / weight 500 / `var(--color-ink-faint)` / `margin: 0 0 12px`. Use `<MetaLabel>`.
  - `.cl-filters ul` — list-none, `margin: 0 0 28px`, `padding: 0`, `display: grid`, `gap: 4px`.
  - `.cl-filters a` — `display: flex`, `justify-content: space-between`, `padding: 5px 10px`, `border-radius: 6px`, mono 11px / 0.04em, `var(--color-ink-muted)`, no underline. Hover and `[data-active]` (or `is-active`): `bg-paper-warm` + `text-ink`.
  - `.cl-filters a small` — `var(--color-ink-ghost)` for the date.
  - `.releases` — flex column, `gap: 28px`.
  - `.release` — `border: 0.5px solid var(--color-rule)`, `border-radius: 10px`, `padding: 32px 36px`, `bg-paper`, `position: relative`.
  - `.release--current` — `border-color: rgba(43, 74, 122, 0.2)`, `box-shadow: var(--shadow-lift)`. Apply only to `entries[0]`.
  - `.release--older` — `opacity: 0.92`. Apply to `entries[2..]`.
  - `.release__head` — `display: flex`, `align-items: baseline`, `justify-content: space-between`, `gap: 18px`, `padding-bottom: 18px`, `margin-bottom: 20px`, `border-bottom: 0.5px solid var(--color-rule)`, `flex-wrap: wrap`.
  - `.release__head .left` — `display: flex`, `align-items: baseline`, `gap: 20px`, `flex-wrap: wrap`.
  - `.release__date` — mono 11px / 0.08em / uppercase / `var(--color-ink-faint)`.
  - `.release__ver` — Spectral 32px / weight 400 / -0.01em / `var(--color-ink)` / `line-height: 1`.
  - `.release__meta` — `display: flex`, `gap: 8px`, `align-items: center`, `flex-wrap: wrap`. Holds the auto-derived pills.
  - `.release__sections` — `display: grid`, `gap: 20px`.
  - `.sec` — `display: grid`, `grid-template-columns: 110px 1fr`, `gap: 20px`, `align-items: start`. Below 680px: single column, gap 4px.
  - `.sec h4` — mono 10px / 0.1em / uppercase / weight 500, `margin: 6px 0 0`. Color from `classifySection()`.
  - `.sec ul` — list-none, `margin: 0`, `padding: 0`, `display: grid`, `gap: 8px`.
  - `.sec li` — `display: flex`, `gap: 10px`, `font-size: 14.5px`, `var(--color-ink)`, `line-height: 1.55`.
  - `.sec li::before` — empty content, `flex: 0 0 auto`, `width: 4px`, `height: 4px`, `border-radius: 999px`, `margin-top: 10px`. Color from `classifySection()`.
  - `.sec li code` — `font-size: 12.5px` (overrides the `<code>` element's default 13.5px from mock; we follow).
- **Pill primitive** (`Pill.tsx`):
  - **`variant="live"`** (Current): bg `var(--color-accent-soft)`, border `0.5px solid var(--color-accent-ink)`, color `var(--color-accent-ink)`, mono 10px uppercase 0.08em, padding `2px 8px`, border-radius `999px`. Includes a 6px navy LED dot before the label (small `<span>` with `bg-accent-ink rounded-full w-1.5 h-1.5`).
  - **`variant="breaking"`** (Breaking): bg `rgba(194, 74, 62, 0.08)`, border `0.5px solid rgba(194, 74, 62, 0.2)`, color `var(--color-rec-red)`, mono 10px uppercase 0.08em, padding `2px 8px`, border-radius `999px`. No dot.
- **Hero copy** (verbatim from mock):
  - Eyebrow `<MetaLabel>`: "Changelog"
  - H1: "Every release."
  - Sub: "Notes from each version of PS Transcribe, newest first. Auto-update through Sparkle will always bring you here if you want the full picture."
- **Anchor IDs:** Each `<article id="vX-Y-Z">` where the slug replaces `.` with `-` (e.g., `v2.1.1` → `v2-1-1`). Mock pattern matches this.
- **Aside link href:** `#vX-Y-Z` (anchor only, same page).
- **Section keyword classifier rules** (D-03), implemented as a single ordered scan in `lib/section-color.ts`:
  ```
  1. /\b(breaking|migration|scope\s+reduction)\b/i           → 'breaking'
  2. /\b(features?|integration|notion|sparkle|auto[-\s]?update|distribution)\b/i → 'features'
  3. /\b(ux|interface|layout|library|recording|onboarding|redesign|transcript)\b/i → 'ux'
  4. /\b(fix|fixes|bug|internals)\b/i                        → 'fixes'
  5. otherwise                                               → 'default'
  ```
  Applied verbatim against the section title text. Order matters (e.g., "Scope reduction" must classify as breaking before any other rule could match). Returns one of `'features' | 'ux' | 'fixes' | 'breaking' | 'default'`. Each bucket maps to a label color and a dot color.
- **Inline-markdown renderer** (`lib/inline-markdown.tsx`):
  - Single export: `renderInlineMarkdown(text: string): React.ReactNode`.
  - Tokenization: scan for the next match of any of three patterns, in priority order: `` `([^`]+)` `` (code), `\*\*([^*]+)\*\*` (bold), `\[([^\]]+)\]\(([^)]+)\)` (link). Emit the preceding plain text as a string, then the matched element, then continue from after the match. Repeat until end of string.
  - Output: `React.ReactNode[]`. The component renders directly inside `<li>` via `{...}`.
  - Code element: JetBrains Mono 12.5px, `bg-paper-soft`, `px-1.5 py-0.5`, `rounded`, `text-ink`. (Same values Phase 14 D-18 picks for inline `<code>`.)
  - Bold element: `<strong className="font-semibold text-ink">`.
  - Link element: `<a href={url} className="text-accent-ink underline decoration-rule underline-offset-2 hover:decoration-accent-ink">`. External (starts with `http`): add `target="_blank" rel="noopener"`.
- **`SITE` additions** to `lib/site.ts`:
  - `RELEASES_URL: 'https://github.com/cnewfeldt/ps-transcribe-releases/releases'` — public releases repo (per CHANGELOG v2.1.1).
  - `SPARKLE_APPCAST_URL: 'https://raw.githubusercontent.com/cnewfeldt/ps-transcribe-releases/main/appcast.xml'` — actual update mechanism (per CHANGELOG v2.1.1).
  - Existing `SITE.APPCAST_URL` (`https://github.com/cnewfeldt/ps-transcribe/releases.atom`) is technically the source-repo Atom feed; the planner should decide whether to deprecate it or keep both. Recommendation: the new constant `SPARKLE_APPCAST_URL` is the authoritative one for the Subscribe block.
- **RSS 2.0 channel** structure for `/changelog/rss.xml`:
  ```
  <?xml version="1.0" encoding="UTF-8"?>
  <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
    <channel>
      <title>PS Transcribe — Changelog</title>
      <link>https://ps-transcribe-web.vercel.app/changelog</link>
      <description>Release notes for PS Transcribe.</description>
      <language>en-us</language>
      <atom:link rel="self" href="https://ps-transcribe-web.vercel.app/changelog/rss.xml" />
      <lastBuildDate>{newest release pubDate, RFC 822}</lastBuildDate>
      {for each release in entries:}
      <item>
        <title>v{version}</title>
        <link>https://ps-transcribe-web.vercel.app/changelog#v{slug}</link>
        <guid isPermaLink="true">https://ps-transcribe-web.vercel.app/changelog#v{slug}</guid>
        <pubDate>{date in RFC 822, e.g., "Wed, 23 Apr 2026 00:00:00 GMT"}</pubDate>
        <description><![CDATA[
          {sections rendered as <h4> + <ul><li> HTML; inline backticks/bold/links rendered server-side using the same inline renderer}
        ]]></description>
      </item>
    </channel>
  </rss>
  ```
- **Production deploy URL** (per Phase 11 note): `ps-transcribe-web.vercel.app`. Use this exact host for all RSS `<link>` and `<guid>` URLs. Do NOT use `ps-transcribe.vercel.app` (claimed by another account).
- **Sticky offset:** `top: 64px` for the aside (Phase 13 nav height). Mock uses `top: 84px` — that's the mock's nav height, not ours. Adjust.
- **`max-width` for the changelog container:** Match whatever Phase 13's landing `.container` uses (likely 1280px). If Phase 13 standardized on `max-w-screen-2xl` or a custom value, use the same.
- **Editorial voice for any new prose** (only the hero copy in this phase; bullets are sourced from CHANGELOG.md): match Chronicle voice — calm, precise, editorial. The hero text from the mock already nails this.
- **Minimum-OS reference:** If anywhere in the changelog page wants to reference the OS minimum (e.g., a small footer line), use `SITE.OS_REQUIREMENTS` from `lib/site.ts` ("macOS 26+ · Apple Silicon · Free & open source"). Per D-09 we're not shipping the DMG meta line, so this is informational only.

</specifics>

<deferred>
## Deferred Ideas

- **Backfill missing git tags** (`v1.0.0`, `v1.0.1`, `v1.1.0`, `v1.2.0`, `v1.3.0`, `v1.4.0`, `v1.4.1`, `v2.1.0`, `v2.1.1`) — Today only `v1.0` and `v2.0.0` exist. Backfilling would unlock per-release Download/Diff actions. Either a one-time housekeeping pass or a process change to tag every future release. Out of scope for Phase 15 but useful future work.
- **Per-release Download / Diff action links** — Conditional on tag backfill above. Not in this phase; can be added in a follow-up phase that also backfills tags.
- **Codenames for releases** — Would require either a new convention in CHANGELOG.md (e.g., `> codename: "Quiet Chronicle"` after the version heading) or auto-extraction from quoted subsection titles. Not worth the complexity until/unless the CHANGELOG starts getting codenames as a habit.
- **Per-release summary line** — Would require a CHANGELOG.md authoring convention (a paragraph between version heading and first section). Not currently followed; adding it now would require backfilling 10 entries with synthetic prose. Defer.
- **DMG byte size + minOS in card foot** — Would require a build-time GitHub Releases API call (with graceful fallback for CI without `GH_TOKEN`). Modest visual gain for non-trivial new infrastructure. Defer.
- **Recommended / Patch / Minor pills** — Recommended is editorial (subjective); Patch/Minor computed from semver would add 5+ "Patch" pills across the 10 entries (visual clutter). Defer indefinitely.
- **Atom feed alongside RSS 2.0** — RSS 2.0 covers the use case for now. Add Atom only if a real consumer asks for it.
- **Search / tag-based filtering** — 10 entries is fully navigable via the aside scroll-spy. Revisit if the CHANGELOG grows past ~30 entries.
- **Pagination** — Same: 10 entries is fine on one page. Revisit at ~30+.
- **Per-release "copy link" button** — Anchor IDs work for permalinking via right-click; explicit copy buttons can be added later if users miss the affordance.
- **Reading the public `release-notes/v<version>.md`** files (per CHANGELOG v2.1.1 convention) — LOG-01 specifies `CHANGELOG.md` as the source. The user-facing release-notes files are a separate distribution concern; potentially a v1.2 candidate to surface them on the page (e.g., as the per-release summary).
- **Custom domain** — Post-v1.1.
- **Dark mode** — Blocked by DESIGN-04.
- **Localization** — Out of milestone.
- **Versioned docs / archived changelog snapshots** — If a future v3.0 makes substantive deprecations, would want to preserve historical per-version docs alongside the changelog. Out of scope today.
- **Visual-regression testing** — Not required for this phase. Revisit in a post-v1.1 hardening pass.
- **Timeline-dot visual element** — Mock had it; we dropped it (D-21) since the foot row is gone. If editorial future adds a foot row back, the timeline-dot can be revisited.

### Reviewed Todos (not folded)

None — no pending todos matched this phase (todo `match-phase 15` returned 0 results).

</deferred>

---

*Phase: 15-changelog-page*
*Context gathered: 2026-04-24*
