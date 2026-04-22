# Phase 12: Chronicle Design System Port - Context

**Gathered:** 2026-04-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Port the Chronicle visual language into the Next.js site at `/website` so Phases 13–15 inherit a consistent visual base: the full 16-token paper palette, non-color tokens (radii + shadows + fonts), and five reusable primitives — `Button` (primary + secondary), `Card`, `MetaLabel`, `SectionHeading`, `CodeBlock`. Light mode only. A `/design-system` route proves the system renders correctly.

In scope:
- CSS custom properties for the 16 palette colors + 5 radii + 3 named shadows in `src/app/globals.css`
- Tailwind v4 `@theme inline` re-export so `bg-paper`, `text-ink-muted`, `rounded-card`, `shadow-btn` etc. work as utilities
- `src/components/ui/` directory with the 5 primitives as React components using Tailwind class strings + variant-union props
- `src/app/design-system/page.tsx` showcase rendering every palette color and every primitive
- Removal of the existing `@media (prefers-color-scheme: dark)` block in `globals.css` + `color-scheme: light` on `<html>` (enforces DESIGN-04)
- System-font fallback declarations asserting `SF Pro` / `New York` / `SF Mono` fall back from the `next/font` variables (DESIGN-02)

Out of scope (deferred to later phases):
- Real landing page content → Phase 13 (will replace the existing `/` placeholder)
- MDX pipeline, docs sidebar, right-hand TOC → Phase 14
- Changelog parser → Phase 15
- Layout / page-level components (Nav, Footer, Hero, FeatureBlock) → Phase 13
- Any copy from `chronicle-mock.css` semantic classes (`.btn`, `.card`, `.nav`, `.footer`) — mock CSS stays reference-only
- Custom domain, analytics, dark-mode variants — out of milestone

</domain>

<decisions>
## Implementation Decisions

### Token distribution
- **D-01:** **Hybrid token architecture.** CSS custom properties in `:root` are the source of truth; Tailwind v4 `@theme inline` re-exports them so both `className="bg-paper text-ink"` and `style={{ background: 'var(--color-paper)' }}` resolve to the same values. Strict superset of either approach alone.
- **D-02:** **Full token set, not colors-only.** Palette (16 colors) + radii (`--radius-input: 4px`, `--radius-btn: 6px`, `--radius-card: 10px`, `--radius-bubble: 12px`, `--radius-pill: 999px`) + named shadows (`--shadow-lift`, `--shadow-btn`, `--shadow-float`) all ship as tokens. Typography font-family vars already live in `layout.tsx` (`--font-inter`, `--font-spectral`, `--font-jetbrains-mono` from Phase 11) — those are re-exposed as `--font-sans`, `--font-serif`, `--font-mono` via `@theme inline` with SF Pro / New York / SF Mono fallbacks appended.
- **D-03:** **Kebab-case token names with Tailwind-v4 prefixes.** `--color-paper`, `--color-paper-warm`, `--color-ink-muted`, `--color-spk2-bg`, `--color-rec-red`, `--radius-card`, `--shadow-btn`, etc. Natural for CSS, and Tailwind v4 auto-generates the matching utility names (`bg-paper`, `text-ink-muted`, `rounded-card`, `shadow-btn`).

### Primitives
- **D-04:** **Tailwind utility class strings in React** — no `@apply`, no semantic CSS classes, no CSS Modules. Variant logic is a conditional object in each component. Matches Next.js App Router idioms.
- **D-05:** **Location: `src/components/ui/`.** One file per primitive (`Button.tsx`, `Card.tsx`, `MetaLabel.tsx`, `SectionHeading.tsx`, `CodeBlock.tsx`). Named exports. Mirrors shadcn/ui conventions and leaves room for `src/components/` to hold feature components in Phases 13–15.
- **D-06:** **Variant-union prop API.** Discriminated string unions, not boolean flags: `variant: 'primary' | 'secondary'` on `Button`, `tone?: 'default' | 'sage' | 'navy'` on `MetaLabel` if more than the default is needed. All primitives spread standard HTML attributes (`...rest` onto the underlying element).
- **D-07:** **Props stay minimal for Phase 12.** Only what's needed to render the showcase. `Button` must support `variant`, `children`, and standard button attributes (incl. `asChild` is NOT in scope — no Radix). `Card` is a paper background + `0.5px var(--color-rule)` hairline + `10px` radius container with default padding. `MetaLabel` renders uppercase `10px` JetBrains Mono with `0.08em` letter-spacing. `SectionHeading` renders Spectral serif at the brief's section scale (28–32px fluid). `CodeBlock` supports an `inline` prop — inline renders JetBrains Mono on a `paperSoft` pill background, block renders a `<pre>` with the same font and rule border. Syntax highlighting is NOT in scope (deferred to Phase 14 when MDX lands if needed).

### Showcase / dev page
- **D-08:** **New route at `/design-system`.** `src/app/design-system/page.tsx`. Keeps the current `/` placeholder untouched so Phase 13 gets a clean canvas.
- **D-09:** **Noindex + excluded from sitemap.** Page exports its own `metadata` with `robots: { index: false, follow: false }`. `src/app/sitemap.ts` does NOT list it. Reachable if you know the URL; invisible to search.
- **D-10:** **Showcase content.** Two sections: (a) a color-swatch grid showing all 16 palette tokens with their name, hex value, and `var(--color-*)` reference; (b) a primitive gallery showing every variant of each primitive (Button primary + secondary, Card with sample content, MetaLabel in default/sage/navy tones if shipped, SectionHeading example, CodeBlock inline + fenced). Include one short `<Card>` at the top containing the brief's typography scale (hero / section / feature / body) rendered with actual copy so fidelity is verifiable at a glance.

### Design handoff reuse
- **D-11:** **Port token values only; rebuild primitives fresh.** Copy the 16 colors + 5 radii + 3 shadows from `design/ps-transcribe-web-unzipped/assets/tokens.css` into `globals.css` (renamed to Tailwind-v4 conventions per D-03). The primitive React components get built from scratch using those tokens + the brief's sizing/spacing hints. `chronicle-mock.css` stays reference-only for sizing and spacing verification — it is never imported.
- **D-12:** **Do not import `chronicle-mock.css` or use its class names.** Its rules are tuned to the handoff's HTML structure (`<nav class="nav">`, `<section class="hero">`) and would fight our React primitive boundaries. `tokens.css` values only.

### Dark-mode enforcement (DESIGN-04)
- **D-13:** **Strip the `@media (prefers-color-scheme: dark)` block** currently in `globals.css`. This is the minimum required by DESIGN-04.
- **D-14:** **Add `color-scheme: light` on `<html>`** (either via `globals.css` `html { color-scheme: light; }` or inline). Locks native form controls (scrollbars, inputs, date pickers) to the light theme regardless of OS preference.

### Claude's Discretion
- Exact Tailwind v4 `@theme inline` property syntax — use whichever form the installed Tailwind CSS v4 docs currently prescribe (see canonical_refs: agents must read `node_modules/tailwindcss/` docs before writing).
- Variant-object shape inside each primitive (`const variants = { primary: '...', secondary: '...' }` vs class-map function vs early-return) — pick whatever keeps each primitive under ~30 lines.
- Whether `MetaLabel` exposes a `tone` prop or ships as default-only and lets consumers override color via `className`. Default-only is acceptable for Phase 12; the brief uses tones but our 5 primitives are a minimum surface.
- Whether `CodeBlock` uses `<code>` or `<pre><code>` internally for the `inline` vs block distinction — follow semantic HTML.
- Showcase page visual layout and section ordering — aim for the same calm, editorial density as the brief.
- Whether to use `forwardRef` on primitives. Default: skip it unless a concrete Phase 13-15 need appears. Adding it later is mechanical.
- Any `cn()` / `clsx` helper adoption — fine to add if useful, not required.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & scope
- `.planning/REQUIREMENTS.md` §DESIGN — Requirements DESIGN-01 through DESIGN-04 (this phase's scope).
- `.planning/ROADMAP.md` §"Phase 12: Chronicle Design System Port" — Phase goal, four success criteria, dependency on Phase 11.
- `.planning/PROJECT.md` §"Current Milestone: v1.1 Marketing Website" — Milestone context, scope boundaries.

### Design source of truth
- `.planning/research/CLAUDE-DESIGN-BRIEF.md` §Palette — 16 Chronicle tokens with hex values and usage.
- `.planning/research/CLAUDE-DESIGN-BRIEF.md` §Typography — Three-font stack, weight/size guidance, meta-label conventions.
- `.planning/research/CLAUDE-DESIGN-BRIEF.md` §"Spacing, radii, shadows" — Scale (4/6/8/10/14/18/22/28/40/64/96), radii (4/6/10/12/999), and three named shadows.
- `.planning/research/CLAUDE-DESIGN-BRIEF.md` §Buttons — Primary (dark ink bg, paper text, 6px radius, 8/12 padding) and secondary (paper bg, 0.5px ruleStrong border) specs.
- `.planning/research/CLAUDE-DESIGN-BRIEF.md` §"Component idioms from the app to borrow" — MetaLabel (10px JetBrains Mono, uppercase, 0.5 letter-spacing), Card (paper bg, 0.5px rule, 10px radius).

### Design handoff (port values, do NOT import)
- `design/ps-transcribe-web-unzipped/assets/tokens.css` — Source for porting the 16 palette hex values + 5 radii + 3 shadow strings into `globals.css`. Read the CSS variable definitions only; do not copy the file.
- `design/ps-transcribe-web-unzipped/assets/chronicle-mock.css` — Reference-only for sizing/spacing verification of the 5 primitives. Never imported. Never linked from `globals.css`. Its class names (`.btn`, `.card`, `.meta`, etc.) are not used in this phase.

### Existing code to modify / respect
- `website/src/app/globals.css` — Current file has a placeholder `@theme inline` block and a `@media (prefers-color-scheme: dark)` block. This phase replaces the theme contents and removes the dark-mode block.
- `website/src/app/layout.tsx` — Already wires Inter / Spectral / JetBrains Mono via `next/font/google`. Do NOT modify font loading. Phase 12 just asserts the SF Pro / New York / SF Mono fallbacks in the resolved `--font-sans` / `--font-serif` / `--font-mono` declarations.
- `website/src/app/page.tsx` — Current inline-styled placeholder. Do NOT modify in this phase. Phase 13 will rewrite it.
- `website/src/app/sitemap.ts` — Must NOT list `/design-system` (keep showcase out of search indexes).
- `website/CLAUDE.md` / `website/AGENTS.md` — Explicit note: "This is NOT the Next.js you know… Read the relevant guide in `node_modules/next/dist/docs/` before writing any code." Downstream agents must consult local Next.js 16 + Tailwind CSS v4 docs rather than relying on training data.

### Framework & tooling docs
- `node_modules/tailwindcss/` docs — Authoritative reference for Tailwind v4's `@theme` and `@theme inline` directives. The `tailwind.config.ts` approach from v3 does NOT apply.
- `node_modules/next/dist/docs/` — Authoritative reference for Next.js 16 App Router patterns (metadata API for `robots` field, `next/font` variable usage).
- Agents may use `mcp__plugin_context7_context7__*` tools to fetch current Tailwind v4 and Next.js 16 docs if local node_modules docs are insufficient.

### Repository context
- `website/package.json` — Confirms Tailwind v4 (`tailwindcss: ^4`, `@tailwindcss/postcss: ^4`), Next.js 16.2.4, React 19.2.4. Tailwind v4 requires the `@tailwindcss/postcss` plugin, already wired in `postcss.config.mjs`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Font variables on `<html>`**: `layout.tsx` sets `--font-inter`, `--font-spectral`, `--font-jetbrains-mono` via `next/font/google`. Phase 12 re-exposes these through Tailwind `@theme inline` as `--font-sans`, `--font-serif`, `--font-mono` with appended system fallbacks. No font loading work to redo.
- **Paper color `#FAFAF7`**: Already in use by `page.tsx` as the placeholder background. Post–Phase 12, new pages should use `bg-paper` utility instead of inline hex.
- **`ImageResponse`-generated OG image** (`opengraph-image.tsx`): Hardcodes the same Chronicle paper palette. Reference for post-Phase-12 consistency (not modified in this phase).

### Established Patterns
- **Tailwind v4 CSS-first config.** No `tailwind.config.ts` exists. All theme configuration lives in `globals.css` via `@theme` / `@theme inline` directives. Training-data patterns from v3 (`theme.extend.colors` in a JS config) do NOT apply.
- **App Router file conventions.** `src/app/metadata.ts`, `src/app/sitemap.ts`, `src/app/robots.ts`, `src/app/opengraph-image.tsx` already live as metadata-file-based routes. Adding `src/app/design-system/page.tsx` follows the same pattern.
- **pnpm as the package manager** (Phase 11 decision). `pnpm install` / `pnpm run dev` / `pnpm run build` are the only blessed invocations.

### Integration Points
- **`globals.css`** is the single shared CSS file. Phase 12 rewrites its `:root` and `@theme inline` blocks and removes its dark-mode block — no other CSS file is created.
- **`src/components/ui/`** is a new directory created by this phase. No existing code lives there.
- **`src/app/design-system/`** is a new route segment created by this phase. No route collision.
- **Vercel preview deploys** (Phase 11) automatically pick up any PR that touches `/website/**`. Every primitive iteration gets a shareable URL without extra work.

</code_context>

<specifics>
## Specific Ideas

- **MetaLabel calibration**: the brief calls for 10px JetBrains Mono with uppercase + 0.08em letter-spacing (not 0.5–0.8px as early copy suggested). Follow the brief's `.meta` rule in `chronicle-mock.css` as the sizing reference: `font-size: 10px; letter-spacing: 0.08em; text-transform: uppercase; color: var(--color-ink-faint);`.
- **Button primary shadow**: the two-layer shadow (`0 1px 2px rgba(30,30,28,0.20), inset 0 1px 0 rgba(255,255,255,0.08)`) is intentional and part of the Chronicle identity. Reproduce it in `--shadow-btn`, not just a single outer shadow.
- **Card is defensive by default**: `paper` bg (NOT `paperWarm`) with `0.5px var(--color-rule)` hairline and 10px radius. The `paperWarm`-background card variant in the brief's `.strip` grid is a Phase 13 concern, not a primitive-level variant.
- **Hairlines must be 0.5px, not 1px.** This is an intentional editorial detail from the Chronicle app. Use `border: 0.5px solid var(--color-rule)` literally — most browsers render it as a sub-pixel; we accept that fidelity tradeoff.
- **CodeBlock inline background**: the brief calls for `paperSoft` pill behind inline `<code>`. Keep padding tight (e.g., 2px 6px); the pill should sit on a line of body text without disrupting the line-height.
- **Showcase demo content** should quote the brief's own voice — e.g., "Records both sides of your Zoom call, locally." — rather than "Lorem ipsum." Reinforces the editorial tone and doubles as a voice-calibration check.

</specifics>

<deferred>
## Deferred Ideas

- **Layout-level components** (Nav, Footer, Hero, FeatureBlock, Sidebar, ChangelogEntry) — Phase 13/14/15 own these. Don't preemptively extract during Phase 12.
- **CodeBlock syntax highlighting** — Not needed for Phase 12 showcase. Phase 14 will decide (likely via Shiki or rehype-highlight during MDX processing).
- **`MetaLabel tone` prop** — Ship default-only if possible; add the `navy` / `sage` tones when Phase 13 needs them (avoid speculative API).
- **`cn()` / `clsx` helper** — Evaluate during planning; adopt only if variant strings exceed trivial conditional concatenation.
- **`forwardRef` on primitives** — Add only when a concrete caller needs a ref (none known in Phase 12).
- **Playwright or visual-regression test for light-mode enforcement** — Not required by DESIGN-04. Revisit post-v1.1 if dark-mode regressions appear.
- **shadcn/ui adoption** — Conventions borrowed (ui/ subdir, variant unions) but we're not installing the library. Reconsider if Phase 14 MDX rendering needs a complex Tabs/Accordion/Dialog component.
- **Removing the current `page.tsx` inline styles** — Phase 13 rewrites this file entirely; touching it in Phase 12 is churn.
- **Updating `opengraph-image.tsx` to use tokens** — Vercel OG image runs in an isolated edge runtime and can't read `globals.css` anyway. Leave the hardcoded hex values; they match the tokens by construction.

</deferred>

---

*Phase: 12-chronicle-design-system-port*
*Context gathered: 2026-04-22*
