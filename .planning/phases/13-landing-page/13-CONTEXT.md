# Phase 13: Landing Page - Context

**Gathered:** 2026-04-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Rewrite `website/src/app/page.tsx` from the Phase-11 placeholder into a complete Chronicle-flavored marketing landing page at `/`. Seven sections — Nav + Hero + "Three things" intro strip + four Feature blocks + Shortcuts + Final CTA + Footer — ported as faithfully as practical from the existing design handoff at `design/ps-transcribe-web-unzipped/index.html` (hero variant C). The primary CTA resolves to the latest GitHub Release DMG. Every shared layout component (`Nav`, `Footer`) that phases 14 and 15 will also consume lands here. Reuses the five Phase-12 primitives and Chronicle tokens; does not import `chronicle-mock.css` or its semantic class names.

In scope:
- Complete rewrite of `src/app/page.tsx` (the current inline-styled placeholder is replaced wholesale)
- Two shared layout components in `src/components/layout/`: `Nav.tsx` (wordmark + Docs / Changelog / GitHub links + scrolled-state background) and `Footer.tsx` (three-column grid: brand blurb + Product + Source)
- Five landing-specific section components in `src/components/sections/`: `Hero.tsx` (variant C), `ThreeThingsStrip.tsx`, `FeatureBlock.tsx` (reusable with `tint` prop), `ShortcutGrid.tsx`, `FinalCTA.tsx`
- Four React mini-mockup components in `src/components/mocks/`: `DualStreamMock.tsx` (two-column bar meters), `ChatBubbleMock.tsx` (speaker-2 + you bubbles), `ObsidianVaultMock.tsx` (2-col tree + file pane with YAML frontmatter), `NotionTableMock.tsx` (mini database table)
- Hero `<figure>` embedding `design/.../assets/app-screenshot.png` (copied into `website/public/`) via `next/image` with `priority`, mock's `.app-shot` frame (0.5px `rule-strong` + 12px radius + `shadow-float`)
- Four `kbd` key chips in `ShortcutGrid` — `⌘R`, `⌘⇧R`, `⌘.`, `⌘⇧S` — with mock's color-tag treatment (navy / sage / default)
- Download CTA: `https://github.com/cnewfeldt/ps-transcribe/releases/latest/download/PS-Transcribe.dmg` (GitHub's auto-redirect to latest release asset)
- Secondary hero CTA: "View on GitHub →" linking to `https://github.com/cnewfeldt/ps-transcribe`
- Build-time CHANGELOG.md parse for the hero eyebrow (`Ver X.Y · Released <date>`) and final CTA stamp (`vX.Y.Z · <date>`) — shared helper that Phase 15's changelog page will also consume
- Mock's reveal-on-scroll behavior reimplemented in React (IntersectionObserver in a single `useReveal` hook with `prefers-reduced-motion` fallback to immediately-visible)
- Updated page-level `metadata` export (title + description + OG tags) tuned for the landing page specifically
- Responsive breakpoints from the mock (`≤980px` hero collapse, `≤900px` feature collapse, `≤820px` strip collapse)

Out of scope (deferred to later phases or post-v1.1):
- Docs routing, MDX pipeline, sidebar, right-hand TOC → Phase 14
- Changelog parsing for release cards (the version-stamp helper is reused, but the `/changelog` page itself is Phase 15)
- Mobile hamburger nav / drawer — mock does not ship one; if landing feels cramped on <480px, add in a follow-up
- Dark-mode variants — blocked by DESIGN-04 (Phase 12 D-13/14)
- Analytics / tracking pixels — explicit milestone Out of Scope
- Custom domain — post-v1.1
- Any copy from `chronicle-mock.css` semantic classes (`.btn`, `.card`, `.nav`, `.footer`, `.hero`) — mock CSS is reference-only
- The mock's `#tweaks` dev overlay (accent-swatch + hero-variant switcher) — internal design tool, not a production feature
- OWNER placeholder replacement in `SUFeedURL` and `release-dmg.yml` (tracked separately; unrelated to web)
- Fresh app screenshot capture (we ship the existing PNG; recapture is a future polish pass)

</domain>

<decisions>
## Implementation Decisions

### Fidelity & scope
- **D-01:** Ship **all seven mock sections** — Nav, Hero, "Three things" strip, four Feature blocks, Shortcuts, Final CTA, Footer. The strip + final CTA are not required by LAND-01–07 but complete the mock's narrative arc and carry strong conversion-UX weight.
- **D-02:** Hero layout is **variant C** — centered editorial (`<h1>Your meeting audio<br><em>never leaves your Mac.</em></h1>`, wide deck below). Not variant A (asymmetric tilted deck) or B (capability-first wide).
- **D-03:** Use the mock's copy **verbatim**. Mock headline, lede, feature paragraphs, bullet lists, shortcut labels, final-CTA copy, footer blurb — all port as-written. Only mechanical substitutions: the version string (build-time fetched) and the GitHub owner slug (`cnewfeldt/ps-transcribe`).
- **D-04:** **Extract all layout + section components.** `src/components/layout/{Nav,Footer}.tsx` are shared and consumed by phases 14 and 15 too. `src/components/sections/{Hero,ThreeThingsStrip,FeatureBlock,ShortcutGrid,FinalCTA}.tsx` are landing-only. Mini-mockups live in `src/components/mocks/`.

### Hero app imagery
- **D-05:** Use the **existing PNG** at `design/ps-transcribe-web-unzipped/assets/app-screenshot.png`. Copy to `website/public/app-screenshot.png` (don't import from `design/`; it's not part of the `/website` build). Current Chronicle UI is close enough; recapture is a deferred polish pass, not a phase-blocker.
- **D-06:** Wrap the screenshot in the mock's **`.app-shot` frame** — `0.5px solid var(--color-rule-strong)`, `12px` radius, `shadow-float`, paper background, max-width `1080px` centered, `margin-inline: auto`. Port the values into Tailwind utility classes or a scoped CSS snippet inside `Hero.tsx`.
- **D-07:** Hero image loads via **`next/image` with `priority`**. It's the LCP image; Next 16 will auto-optimize to WebP/AVIF, generate a responsive `srcset`, and flag it for eager preload. Use an explicit `width={2260}` and `height={1408}` so layout is stable before the image resolves.
- **D-08:** Alt text = `"PS Transcribe — meeting transcript with Library, Transcript, and Details columns"` (the mock's exact alt). Describes the UI layout for screen readers.

### Feature block visuals
- **D-09:** **Port the four mini-mockups as React components** in `src/components/mocks/`. Each owns its layout in JSX + Tailwind classes, reads real Chronicle fonts via the already-loaded `next/font` variables, renders sharp at every DPI, stays editable without re-capturing. Expected sizes: `DualStreamMock` ~60 lines, `ChatBubbleMock` ~40 lines, `ObsidianVaultMock` ~70 lines (tree + file pane + YAML frontmatter), `NotionTableMock` ~45 lines. No library needed beyond what's already in `/website`.
- **D-10:** Port the **tint wrapper variants**. `<FeatureBlock tint="default" | "tint" | "sage">` renders the padded panel around each mini-mockup: `default` = `bg-paper-warm` + `border-rule`, `tint` = `bg-accent-soft` (navy-tinted), `sage` = `bg-spk2-bg`. Preserves the mock's color rhythm: Feature 1 = `tint`, Feature 2 = `sage`, Feature 3 = `default`, Feature 4 = `tint`.
- **D-11:** **No animation** on any mini-mockup. Static bar heights, static bubble content, static table rows. Matches the "designed to disappear" voice; an audio meter that loops on every scroll-past undermines the product's calm-editorial positioning. Continuous ambient motion explicitly rejected.
- **D-12:** **Alternate layout** every other feature block. Feature 1: copy-left / mock-right. Feature 2: mock-left / copy-right. Feature 3: copy-left / mock-right. Feature 4: mock-left / copy-right. Implement via Tailwind `order-*` utilities on the grid children (not `direction: rtl` — rtl leaks into nested text content).

### Download CTA + version
- **D-13:** Primary CTA href = **`https://github.com/cnewfeldt/ps-transcribe/releases/latest/download/PS-Transcribe.dmg`**. GitHub auto-redirects to the most recent release asset. Zero build-time fetch, survives every future release without a site rebuild, no stale-release risk. The DMG filename `PS-Transcribe.dmg` must match whatever `release-dmg.yml` actually produces — downstream planner verifies against the workflow.
- **D-14:** Secondary hero CTA = **"View on GitHub →"**, `Button variant="secondary"` linking to `https://github.com/cnewfeldt/ps-transcribe`. Reinforces the "free + open source" positioning and gives users a non-download path into the project.
- **D-15:** **Build-time version fetch from `CHANGELOG.md`** (not the GitHub API). Parse the top `## [X.Y.Z] — YYYY-MM-DD` entry at `next build` time. Inject the version + date into the hero eyebrow (`Ver 1.0 · Released Apr 14, 2026`) and the final CTA stamp (`v1.0.0 · Apr 14, 2026`). A shared helper at `src/lib/changelog.ts` — Phase 15 will reuse it for the full changelog page.
- **D-16:** GitHub owner/repo slug = **`cnewfeldt/ps-transcribe`**. Resolves the DMG URL, the GitHub nav link, the secondary hero CTA, the footer "Source" column, and Phase 15's changelog entries. Stored as a single constant in `src/lib/site.ts` (or equivalent) so future forks/renames are a one-line change.

### Shared layout
- **D-17:** `Nav` ships with the mock's **scrolled-state behavior** — transparent/paper bg at `scrollY <= 6`, slight shadow + `paper-warm` bg once scrolled. Implement via a tiny `useScrolled()` hook (IntersectionObserver on a sentinel `<div>` at the top, or a passive scroll listener — planner picks). Wordmark on the left (Spectral word + dot-mark), three links on the right (Docs → `/docs`, Changelog → `/changelog`, GitHub → repo URL). Docs and changelog routes won't exist until phases 14/15; that's fine — the links 404 locally but deploy safely on Vercel since the build doesn't check internal-link validity.
- **D-18:** `Footer` matches the mock's **three-column grid**: (col 1) brand blurb + `© 2026` + MIT line, (col 2) Product links (Documentation, Changelog, Download DMG, Sparkle appcast), (col 3) Source links (GitHub repository, Report an issue, Acknowledgements, License · MIT). Collapses to single column on mobile. The "Sparkle appcast" link target is `https://github.com/cnewfeldt/ps-transcribe/releases.atom` (GitHub's release feed).

### Motion
- **D-19:** **Reveal-on-scroll** ported from the mock as a single `useReveal()` hook in `src/hooks/` — IntersectionObserver with `threshold: 0.12`, adds an `is-in` class on first intersection, unobserves after. Apply via a `<Reveal>` wrapper component or a `data-reveal` attribute pattern. MUST honor `prefers-reduced-motion: reduce` — in that case, elements are visible immediately with no transition.
- **D-20:** No other motion. No hover-scale, no parallax, no float, no continuous animation. The site is calm by design.

### Claude's Discretion
- Exact CSS for the `.app-shot` frame — Tailwind utility string vs scoped CSS snippet vs inline `style` vs `@layer components` rule. Pick whichever keeps `Hero.tsx` cleanest (arbitrary-value utilities like `border-[0.5px]` are fine).
- Whether `useReveal` is a hook consumed by a wrapper `<Reveal>` component or a primitive that attaches directly to a `ref` — either is fine.
- Whether `useScrolled` watches `window.scrollY` or an IntersectionObserver sentinel — both work; planner picks based on React 19 / Next 16 patterns.
- Exact file boundaries for mock components — single file per mock is fine; extracting shared mock chrome (titlebar with traffic lights + centered title) into a `MockWindow.tsx` helper is permitted if it simplifies three or more mocks.
- Whether `Nav` uses a `<nav>` or `<header>` as its outer element — the mock uses `<header class="nav">`; planner picks based on semantic-HTML preference.
- Shortcut chip color assignments (which shortcuts get `navy` / `sage` / `default`) — match the mock's assignments: ⌘R = navy, ⌘⇧R = sage, ⌘. = default, ⌘⇧S = default.
- How `CHANGELOG.md` is parsed — regex, remark, unified, or a hand-rolled line splitter. The data shape exposed to components should be `{ version: string, date: string, sections: { title: string, items: string[] }[] }` so Phase 15 can consume the same helper unchanged.
- Whether the page-level `metadata` export for `/` moves into `src/app/metadata.ts` (existing file) or stays inline in `page.tsx`. Existing file is fine; whatever matches repo conventions.
- Exact Tailwind arbitrary values for sizes the tokens don't cover (e.g., the `0.5px` hairline, `clamp(32px, 4vw, 44px)` for the final CTA headline) — use `[...]` arbitrary-value syntax, not new tokens.
- Whether `<Reveal>` or the hook is opt-in per element (preferred: opt-in; don't blanket-wrap the page).
- Image priority tuning — only the hero screenshot gets `priority`. All four feature mini-mockups are plain DOM, no images; the final CTA has no image either.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & scope
- `.planning/REQUIREMENTS.md` §LAND — Requirements LAND-01 through LAND-07 (this phase's scope).
- `.planning/ROADMAP.md` §"Phase 13: Landing Page" — Phase goal, five success criteria, dependency on Phase 12.
- `.planning/PROJECT.md` §"Current Milestone: v1.1 Marketing Website" — Milestone context, scope boundaries, macOS app identity.

### Design source of truth
- `.planning/research/CLAUDE-DESIGN-BRIEF.md` — Full Chronicle design brief. Use §Palette, §Typography, §Buttons, §"Spacing, radii, shadows" as the calibration reference.
- `design/ps-transcribe-web-unzipped/index.html` — **PRIMARY MOCK.** 665-line landing page with hero variant C selected via `<body data-hero="C">`. Every section, copy string, and layout pattern this phase ships comes from this file. Read it top-to-bottom before writing any component.
- `design/ps-transcribe-web-unzipped/assets/chronicle-mock.css` — **Reference-only** for `.app-shot`, `.feature`, `.feature--alt`, `.shot`, `.shot--tint`, `.shot--sage`, `.strip`, `.shortcuts`, `.cta`, `.footer`, `.nav`, `.bubble`, `.kbd`, `.meta`, `.btn` sizing / spacing / border / radius / shadow values. **Never imported** into `/website`. **Never referenced by class name** in React components. Values are ported into Tailwind utility classes or scoped CSS inside the component that needs them.
- `design/ps-transcribe-web-unzipped/assets/tokens.css` — Source tokens. Already ported into `website/src/app/globals.css` by Phase 12; listed here for cross-reference.
- `design/ps-transcribe-web-unzipped/assets/app-screenshot.png` — Hero image asset. Copy to `website/public/app-screenshot.png` at the start of this phase; do not keep a `design/` import path in the final bundle.

### Existing code to reuse / modify / respect
- `website/src/components/ui/` (Button, Card, MetaLabel, SectionHeading, CodeBlock) — **Reuse these five primitives.** Phase 13 is forbidden from rebuilding them (Phase 12 D-05/07). If a new landing-specific primitive is genuinely needed, add it as a separate component, don't modify the existing five.
- `website/src/components/ui/index.ts` — Barrel export. Add new component exports here if any land in `ui/`.
- `website/src/app/globals.css` — Chronicle token source of truth (16 colors + 5 radii + 3 shadows + font vars). Do NOT redefine tokens in Phase 13; consume them via Tailwind utilities (`bg-paper`, `text-ink-muted`, `rounded-card`, `shadow-btn`) or `var(--color-*)` references.
- `website/src/app/page.tsx` — Current inline-styled placeholder from Phase 11. **Rewrite wholesale** in this phase.
- `website/src/app/layout.tsx` — Font loading + root viewport. **Do NOT modify font loading** (Phase 12 D-02). May add `<Nav>` / `<Footer>` here if the planner decides every page gets them, OR they live in `page.tsx` per-route — planner's call; prefer layout.tsx so phases 14/15 inherit automatically.
- `website/src/app/metadata.ts` — Existing metadata file. Update `/` metadata in this phase (title, description, OG tags tuned for the landing page). Do not add `/docs` or `/changelog` metadata here — those land in phases 14/15.
- `website/src/app/sitemap.ts` — Already lists `/`. No change required for this phase.
- `website/src/app/opengraph-image.tsx` — Existing OG image (Chronicle paper palette, Spectral wordmark). No change required; it's the right OG asset for `/`.
- `website/CLAUDE.md` / `website/AGENTS.md` — **"This is NOT the Next.js you know."** Downstream agents must read `node_modules/next/dist/docs/` for Next.js 16 App Router patterns rather than relying on training data.

### Framework & tooling docs
- `node_modules/next/dist/docs/` — Authoritative reference for Next.js 16 App Router patterns, `next/image` (priority, fill, sizes, responsive srcset), `Metadata` API, static asset handling from `/public`.
- `node_modules/tailwindcss/` — Tailwind v4 reference for arbitrary values (`border-[0.5px]`, `text-[clamp(...)]`), `@theme inline`, and the v4 utility generation rules.
- Agents may use `mcp__plugin_context7_context7__*` to fetch current Next.js 16 / Tailwind v4 / React 19 docs if local node_modules docs are insufficient.

### Prior phase context
- `.planning/phases/11-website-scaffolding-vercel-deployment/11-CONTEXT.md` — Stack decisions (pnpm, Next 16, strict TS, src/app layout, `@/*` alias).
- `.planning/phases/12-chronicle-design-system-port/12-CONTEXT.md` — Token architecture (hybrid: CSS vars in `:root` + Tailwind v4 `@theme inline`), primitive API patterns (variant-union props, Tailwind class strings in React, minimal surface), `chronicle-mock.css` usage policy (reference-only, never imported).

### Repository assets
- `CHANGELOG.md` (repo root) — **Build-time input** for D-15's version helper. The top entry provides the hero eyebrow and final CTA stamp strings. Phase 15 will re-consume the same helper for full rendering.
- `LICENSE` (repo root) — MIT. Footer "License · MIT" line acknowledges it; no direct link required beyond the GitHub repo URL.
- `README.md` (repo root) — Contains the canonical one-line project description; sanity-check the hero lede against it.
- `assets/` (repo root) — "Bot on Laptop" app icon (already the site favicon from Phase 11). Not consumed by Phase 13 directly, but the identity parity between app and site is load-bearing.
- `.github/workflows/release-dmg.yml` — Determines the real DMG asset filename that `releases/latest/download/<filename>` must match. Downstream planner MUST grep the workflow to confirm `PS-Transcribe.dmg` is the produced filename (and adjust D-13's URL if it's different).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Phase-12 primitives** in `src/components/ui/` — `Button` supports `variant="primary" | "secondary"` and spreads standard button attrs; both hero CTAs use it directly. `Card` (paper + hairline + 10px radius) is the base for every mini-mockup wrapper and every "Three things" card. `MetaLabel` (10px JetBrains Mono uppercase) is every eyebrow in the mock (feature labels, "Ver 2.1 · Released", shortcut `.lbl`, footer column heads, section eyebrows). `SectionHeading` is every Spectral section title. `CodeBlock` is consumed in the hero's `.hero__note` and the ShortcutGrid's descriptions — inline variant with mono pill.
- **Font variables** on `<html>` — `--font-inter`, `--font-spectral`, `--font-jetbrains-mono` set by Phase 11; re-exported as `--font-sans`, `--font-serif`, `--font-mono` by Phase 12. Consume as Tailwind `font-sans` / `font-serif` / `font-mono` utilities. Never re-register fonts.
- **Chronicle color tokens** — `bg-paper`, `bg-paper-warm`, `bg-paper-soft`, `text-ink`, `text-ink-muted`, `text-ink-faint`, `text-ink-ghost`, `bg-accent-ink`, `text-accent-ink`, `bg-accent-soft`, `bg-spk2-bg`, `text-spk2-fg`, `bg-spk2-rail`, `bg-rec-red`, `bg-live-green`, `border-rule`, `border-rule-strong`. Use the Tailwind utilities; don't hardcode hex.
- **Shadow + radius tokens** — `shadow-btn`, `shadow-lift`, `shadow-float`; `rounded-input`, `rounded-btn`, `rounded-card`, `rounded-bubble`, `rounded-pill`. The `.app-shot` frame uses `shadow-float` + `rounded-[12px]` (tokens don't have a 12px radius named; use arbitrary value, or reuse `rounded-bubble` which is also 12px — planner picks).

### Established Patterns
- **Tailwind v4 CSS-first config** — All theme in `globals.css` via `@theme` / `@theme inline`. No `tailwind.config.ts` exists. v3 `theme.extend.colors` patterns don't apply.
- **Variant-union props on primitives** — `Button variant="primary" | "secondary"`, discriminated string unions not boolean flags. New sections / mock components should follow the same convention (e.g., `FeatureBlock tint="default" | "tint" | "sage"`).
- **App Router file conventions** — Metadata routes like `metadata.ts`, `sitemap.ts`, `robots.ts`, `opengraph-image.tsx` already live under `src/app/`. Adding `src/hooks/`, `src/lib/`, `src/components/layout/`, `src/components/sections/`, `src/components/mocks/` follows the same top-level-folder pattern.
- **pnpm-only** — `pnpm install` / `pnpm run dev` / `pnpm run build` are the only blessed package manager invocations (Phase 11 D-01).
- **Hairlines are 0.5px, not 1px** — intentional Chronicle detail (Phase 12 specifics). Use `border-[0.5px]` arbitrary-value utilities; accept browsers that render sub-pixel.

### Integration Points
- **`src/app/page.tsx`** — Single file that gets rewritten. After this phase, it imports from `layout/Nav`, `sections/*`, and indirectly from `ui/*`.
- **`src/app/layout.tsx`** — Planner decides whether `<Nav />` and `<Footer />` mount here (inherited by docs + changelog) or in each `page.tsx`. Strongly prefer `layout.tsx` so phases 14/15 get them for free.
- **`src/app/metadata.ts`** — Landing-page metadata export updated in this phase. Docs / changelog metadata land in their respective phases.
- **`website/public/`** — New asset: `app-screenshot.png` copied from `design/.../assets/`.
- **`CHANGELOG.md` at repo root** — Consumed at build time via `fs.readFileSync` (or equivalent) from a helper in `src/lib/`. The helper is colocated with the site; it does NOT live in the repo-root project.
- **Vercel preview deploys** (Phase 11 Ignored Build Step) rebuild automatically on any PR touching `/website/**`. Every section iteration ships a shareable URL with no extra config.

</code_context>

<specifics>
## Specific Ideas

- **Hero narrative** — mock's hero is the best-calibrated part of the site. Headline `Your meeting audio<br><em>never leaves your Mac.</em>` uses a Spectral italic on the second line; render as `<em>` with `font-style: italic` (Spectral has a 400 italic cut loaded via `next/font`). Don't approximate with CSS slant.
- **Eyebrow dot pattern** — the version stamp in the hero eyebrow has a `.led` green indicator (`bg-live-green`, `6×6`, `rounded-full`, `box-shadow: 0 0 0 2px rgba(74,138,94,0.15)`). Port the exact shadow — the halo is what makes the dot feel alive without motion.
- **Three-things card `meta` coloring** — `.meta` default (ink-faint), `.meta--sage` (spk2-fg), `.meta--navy` (accent-ink). Rotate across the three cards for the same color rhythm as the feature blocks.
- **Shortcut chips** — `.kbd` with variants `.kbd--navy` (accent-soft bg + accent-ink fg) and `.kbd--sage` (spk2-bg + spk2-fg bg). ⌘R uses navy, ⌘⇧R uses sage, ⌘. and ⌘⇧S use default (paper bg + 0.5px ruleStrong + ink fg). Keys are `24×24` minimum, JetBrains Mono 12px, pill-rounded.
- **Final CTA stamp** — top-right of the CTA card, `position: absolute; right: 28px; top: 28px;` with the led dot + `v1.0.0 · Apr 14, 2026` in MetaLabel styling. The live-green led mirrors the hero eyebrow; reinforces "this is the real, shipping version."
- **Editorial voice** — match existing copy exactly. Don't substitute "Your Mac" for "your Mac" anywhere; don't Title-Case the subheads; keep the em-dashes as-written in the mock (they're used sparingly and deliberately). Global CLAUDE.md prefers double-hyphens outside code, but this is *copy inside a production asset* where the editorial voice and mock verbatim requirement take precedence.
- **Feature-block body copy** — all four feature `<p class="body">` + `<ul>` blocks port exactly. Do not pluralize differently, do not "AI-smooth" the wording.
- **Mini-mockup chrome** — each mock has a titlebar with three traffic-light dots and a centered `<b>` label in `.meta` style (e.g., "Session · 00:14:32", "Chronicle · Transcript", "Notion · Meetings DB"). Consistent across mocks; fair candidate for extraction into a `<MockWindow title="...">` helper.
- **Obsidian vault YAML frontmatter** — the `.k` class spans (`date`, `duration`, `participants`, `tags`) render in `accent-ink`. JetBrains Mono throughout, `font-size: 11px`, `line-height: 1.6`. Preserve the mock's exact frontmatter keys in the demo content.
- **Notion `.new` row** — the latest row highlights in `bg-accent-soft` with `text-accent-ink`. Small but load-bearing detail; communicates "just added" without copy.
- **`<em>` usage** — the hero headline uses `<em>` for the italic clause. The first feature block uses `<em>` in "the transcript _is_ a note in your vault." Preserve both. Spectral handles italic beautifully — the site loses character without them.
- **macOS version string** — the mock says `macOS 14+ · Apple Silicon & Intel · Free & open source` in the hero note AND `macOS 14+ (Sonoma & later)` in the final CTA note. PROJECT.md says the real minimum is macOS 26.0+. **Resolve:** use the real minimum (`macOS 26+` or actual product-documented version). This is the one place "copy verbatim" gets overridden by factual correctness. Planner should grep `Package.swift` or similar to confirm the exact platform constraint.
- **Version info flows** — the macOS app's latest version (from CHANGELOG.md) shows in three places: hero eyebrow, final CTA stamp, footer "Sparkle appcast" link. They all read from the same `getLatestRelease()` helper so they never drift.

</specifics>

<deferred>
## Deferred Ideas

- **Mobile hamburger / drawer navigation** — mock has none; landing reads fine stacked on ≤480px. Revisit if user testing flags nav friction post-ship.
- **Fresh app screenshot capture** — existing PNG is acceptable; recapture is a polish pass after the macOS app UI shifts meaningfully.
- **Dark-mode variants** — blocked by DESIGN-04 (Phase 12). Out of milestone.
- **Analytics / tracking pixels** — milestone Out of Scope (REQUIREMENTS.md).
- **Testimonials / social proof** — milestone Out of Scope.
- **Pricing / commerce / email capture** — milestone Out of Scope.
- **Multi-language or translation** — raised 2026-04-22 as "could we translate English → Korean via Parakeet-TDT v3?" Parakeet is an ASR model, not a translation model; Korean is not in the v3 language set. Would require a separate MT pipeline and reopens the "transcripts as model input" scope that was cut 2026-04-04. Not in v1.1; reconsider as a future exploratory project if demand emerges.
- **The mock's `#tweaks` dev overlay** — accent-swatch and hero-variant switcher are design-tooling, not product. Drop for production. If internal design iteration wants it back, it ships as a `/__tweaks` route behind `process.env.NODE_ENV === "development"`.
- **Extracted `MockWindow` wrapper** — fine to add during implementation if three+ mocks share the titlebar chrome, but not required. Planner's call.
- **Playwright / visual-regression tests** — not required by LAND-01–07. Worth revisiting in a post-v1.1 hardening pass, especially before a custom domain brings more traffic.
- **OG image refresh** — the Phase-11 Chronicle paper wordmark OG is adequate for launch; a per-page custom OG (e.g., feature-specific) is a post-ship polish.

</deferred>

---

*Phase: 13-landing-page*
*Context gathered: 2026-04-22*
