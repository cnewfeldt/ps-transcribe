# Phase 12 Research: Chronicle Design System Port

**Researched:** 2026-04-22
**Domain:** Next.js 16 App Router + Tailwind CSS v4 (CSS-first config) + React primitives + light-mode enforcement
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Token distribution**
- **D-01:** Hybrid token architecture. CSS custom properties in `:root` are source of truth; Tailwind v4 `@theme inline` re-exports them so both `className="bg-paper text-ink"` and `style={{ background: 'var(--color-paper)' }}` resolve to the same values.
- **D-02:** Full token set, not colors-only. Palette (16 colors) + radii (`--radius-input: 4px`, `--radius-btn: 6px`, `--radius-card: 10px`, `--radius-bubble: 12px`, `--radius-pill: 999px`) + named shadows (`--shadow-lift`, `--shadow-btn`, `--shadow-float`). Font-family vars from `layout.tsx` (`--font-inter`, `--font-spectral`, `--font-jetbrains-mono`) are re-exposed as `--font-sans`, `--font-serif`, `--font-mono` via `@theme inline` with SF Pro / New York / SF Mono fallbacks appended.
- **D-03:** Kebab-case token names with Tailwind-v4 prefixes (`--color-paper`, `--color-ink-muted`, `--color-spk2-bg`, `--radius-card`, `--shadow-btn`, etc.).

**Primitives**
- **D-04:** Tailwind utility class strings in React. No `@apply`. No semantic CSS classes. No CSS Modules. Variant logic is a conditional object in each component.
- **D-05:** Location: `src/components/ui/`. One file per primitive (`Button.tsx`, `Card.tsx`, `MetaLabel.tsx`, `SectionHeading.tsx`, `CodeBlock.tsx`). Named exports.
- **D-06:** Variant-union prop API. Discriminated string unions (`variant: 'primary' | 'secondary'`), not boolean flags. All primitives spread standard HTML attributes via `...rest`.
- **D-07:** Props stay minimal for Phase 12. No `asChild`, no Radix. `CodeBlock` supports an `inline` prop. No syntax highlighting.

**Showcase / dev page**
- **D-08:** New route at `/design-system` (`src/app/design-system/page.tsx`). Current `/` placeholder untouched.
- **D-09:** Noindex + excluded from sitemap. Page exports own `metadata` with `robots: { index: false, follow: false }`. `src/app/sitemap.ts` does NOT list it.
- **D-10:** Showcase content: (a) 16-swatch palette grid with name/hex/`var(--color-*)` reference; (b) primitive gallery showing every variant; (c) top Card with the brief's typography scale.

**Design handoff reuse**
- **D-11:** Port token values only; rebuild primitives fresh. Copy 16 colors + 5 radii + 3 shadows from `design/ps-transcribe-web-unzipped/assets/tokens.css` into `globals.css` (renamed per D-03). `chronicle-mock.css` reference-only, never imported.
- **D-12:** Do not import `chronicle-mock.css` or use its class names.

**Dark-mode enforcement**
- **D-13:** Strip the `@media (prefers-color-scheme: dark)` block currently in `globals.css`.
- **D-14:** Add `color-scheme: light` on `<html>` (via `globals.css` `html { color-scheme: light; }` or inline).

### Claude's Discretion

- Exact Tailwind v4 `@theme inline` property syntax
- Variant-object shape inside each primitive
- Whether `MetaLabel` exposes a `tone` prop (default-only acceptable)
- Whether `CodeBlock` uses `<code>` or `<pre><code>` (follow semantic HTML)
- Showcase page visual layout and section ordering
- Whether to use `forwardRef` on primitives (default: skip)
- Any `cn()` / `clsx` helper adoption (fine to add, not required)

### Deferred Ideas (OUT OF SCOPE)

- Layout-level components (Nav, Footer, Hero, FeatureBlock, Sidebar, ChangelogEntry) — Phases 13/14/15
- CodeBlock syntax highlighting — Phase 14
- `MetaLabel tone` prop — defer unless Phase 13 explicitly needs it
- `forwardRef` on primitives — add only when a concrete caller needs it
- Playwright / visual-regression tests for light-mode
- shadcn/ui adoption
- Removing `page.tsx` inline styles — Phase 13 rewrites it
- Updating `opengraph-image.tsx` to use tokens
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DESIGN-01 | Chronicle 16-color palette available as Tailwind tokens or CSS custom properties on every page | Tailwind v4 `@theme inline` section — exact syntax for 16 `--color-*` declarations that both expose utilities (`bg-paper`, `text-ink-muted`, etc.) and keep `:root` as the source of truth for raw `var(--color-*)` references. |
| DESIGN-02 | Inter + Spectral + JetBrains Mono loaded via `next/font` with system fallbacks (SF Pro / New York / SF Mono) | `next/font` variables already wired in `layout.tsx` (Phase 11). Phase 12 adds a second hop via `@theme inline` that appends SF Pro / New York / SF Mono fallbacks to `--font-sans` / `--font-serif` / `--font-mono`. Verified in Next.js 16 font docs at `node_modules/next/dist/docs/01-app/03-api-reference/02-components/font.md`. |
| DESIGN-03 | Reusable primitives available: Button (primary/secondary), Card, MetaLabel, SectionHeading, CodeBlock | Primitive Component Patterns section — minimal conditional-object variant pattern. Each primitive under ~30 lines, no external deps. |
| DESIGN-04 | Site renders in light mode only — no dark-mode CSS variants | Light-Mode Enforcement section — three-layer defense: (1) strip the `@media (prefers-color-scheme: dark)` block in `globals.css`, (2) `html { color-scheme: light; }` in CSS, (3) `export const viewport: Viewport = { colorScheme: 'light' }` in `layout.tsx` (Next 16 canonical API — emits `<meta name="color-scheme" content="light">`). |
</phase_requirements>

## Project Constraints (from CLAUDE.md / AGENTS.md)

`website/AGENTS.md` (referenced by `website/CLAUDE.md`):
> This is NOT the Next.js you know. This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` before writing any code. Heed deprecation notices.

Actionable directives for this phase:
- All Tailwind v4 and Next.js 16 patterns MUST be verified against `node_modules/tailwindcss/` or `node_modules/next/dist/docs/` before planning. Training-data patterns for Tailwind v3 (`tailwind.config.ts` / `theme.extend.colors`) do NOT apply.
- Heed deprecation notices. Example found: `metadata.colorScheme` is deprecated since Next.js 14 — use `export const viewport: Viewport = { colorScheme: 'light' }` instead.
- Use pnpm only (Phase 11 decision). Never `npm install` or `yarn add`.

Global user rules from `~/.claude/CLAUDE.md` that affect this phase:
- **Build only what's requested.** No unrequested abstractions. Rule-of-three before extracting shared helpers.
- **No em dashes in source/content.** (Applies to any copy written into the showcase page and primitive demo text.)
- **No Claude attribution in commits.** No `Co-Authored-By`, no "Generated with", no robot emoji.
- **Never claim done without deterministic proof.** Verification commands must run green before phase is marked complete.

## Summary

- **Tailwind v4 `@theme inline` is the right directive for this phase.** `@theme inline` tells Tailwind to emit utilities that *reference* the CSS custom property via `var(--color-paper)` rather than inline its literal value. This preserves the D-01 hybrid architecture (utility + raw `var()` consumers resolve to the same live value). `[VERIFIED: tailwindcss.com/docs/theme via WebFetch 2026-04-22]`
- **Token name convention is a direct 1:1 mapping.** `--color-paper` → `bg-paper`, `text-paper`, `border-paper`, `ring-paper`, `fill-paper`, `stroke-paper`. `--color-spk2-bg` → `bg-spk2-bg` (hyphens preserved). `--radius-card` → `rounded-card`. `--shadow-btn` → `shadow-btn`. `--font-sans` → `font-sans` (overrides Tailwind default). `[VERIFIED: tailwindcss.com/docs/colors + local node_modules/tailwindcss/theme.css showing --color-red-500 produces bg-red-500]`
- **Next.js 16 has a canonical per-page noindex API.** Export `robots: { index: false, follow: false }` inside `metadata` on the page. For the showcase page at `/design-system`, this emits `<meta name="robots" content="noindex, nofollow" />` and overrides the `{ index: true, follow: true }` set in the root layout. `[VERIFIED: node_modules/next/dist/docs/01-app/03-api-reference/04-functions/generate-metadata.md line 551]`
- **Light-mode enforcement needs three layers, one of which is Next.js's new viewport API.** (a) Strip `@media (prefers-color-scheme: dark)` from globals.css, (b) `html { color-scheme: light; }` in globals.css, (c) `export const viewport: Viewport = { colorScheme: 'light' }` in `layout.tsx` — the Next 16 canonical API. **Note: `metadata.colorScheme` is deprecated since Next 14.** `[VERIFIED: node_modules/next/dist/docs/01-app/03-api-reference/04-functions/generate-viewport.md line 157]`
- **No `cn()` helper needed.** With 5 primitives and simple variant unions, template-literal concatenation of a static base string + a lookup-object variant string beats adding `clsx` / `tailwind-merge`. Saves ~8KB of dependencies and a build step. `[ASSUMED — based on Phase 12 scope; revisit if Phase 13+ primitives need composable variants.]`

**Primary recommendation:** Use `@theme inline` in `globals.css` with all tokens named `--color-*`, `--radius-*`, `--shadow-*`, `--font-*`. Rewrite globals.css in one pass: `@import "tailwindcss";` → `:root { ...raw values... }` → `@theme inline { ...var() re-exports... }` → `html { color-scheme: light; }` → minimal body reset. Build the 5 primitives with a conditional-object variant pattern, no helper libs. Add `colorScheme: 'light'` to `layout.tsx`'s viewport export (the only `layout.tsx` touch allowed — it's a separate export, not a font-loading modification).

## Tailwind v4 @theme inline

### Why `@theme inline` not `@theme`

`@theme` (default) resolves variable values at definition time. If you write:

```css
@theme {
  --color-paper: var(--paper-raw);
}
```

…Tailwind "bakes in" the `var(--paper-raw)` lookup into its utility — **at the scope where `@theme` itself lives** (the `:root` selector Tailwind generates). If the variable is later redefined deeper in the tree (or if the indirection chain has a fallback), you get the outer value, not the local one.

`@theme inline` tells Tailwind: "Emit this utility as `background-color: var(--color-paper)` and let the browser resolve it at paint time against the nearest definition in the cascade." This is exactly what D-01 requires — one live `--color-paper` value consumed equally by `bg-paper` and by inline `style={{ background: 'var(--color-paper)' }}`. `[VERIFIED: tailwindcss.com/docs/theme via WebFetch 2026-04-22]`

### Exact syntax for this phase

```css
/* website/src/app/globals.css */
@import "tailwindcss";

/* Source of truth — raw values */
:root {
  /* Paper */
  --color-paper:        #FAFAF7;
  --color-paper-warm:   #F4F1EA;
  --color-paper-soft:   #EEEAE0;

  /* Rules */
  --color-rule:         rgba(30, 30, 28, 0.08);
  --color-rule-strong:  rgba(30, 30, 28, 0.14);

  /* Ink */
  --color-ink:          #1A1A17;
  --color-ink-muted:    #595954;
  --color-ink-faint:    #8A8A82;
  --color-ink-ghost:    #B8B8AF;

  /* Accents */
  --color-accent-ink:   #2B4A7A;
  --color-accent-soft:  #DFE6F0;
  --color-accent-tint:  #F1F4F9;

  /* Sage (speaker 2) */
  --color-spk2-bg:      #E6ECEA;
  --color-spk2-fg:      #2D4A43;
  --color-spk2-rail:    #7FA093;

  /* Status */
  --color-rec-red:      #C24A3E;
  --color-live-green:   #4A8A5E;

  /* Radii */
  --radius-input:       4px;
  --radius-btn:         6px;
  --radius-card:        10px;
  --radius-bubble:      12px;
  --radius-pill:        999px;

  /* Shadows — named, two-layer primary button intentional */
  --shadow-lift:  0 1px 3px rgba(30, 30, 28, 0.08);
  --shadow-btn:   0 1px 2px rgba(30, 30, 28, 0.20), inset 0 1px 0 rgba(255, 255, 255, 0.08);
  --shadow-float: 0 8px 24px rgba(30, 30, 28, 0.12), 0 1px 3px rgba(30, 30, 28, 0.06);
}

/* Re-export to Tailwind — utilities reference var() (not value) */
@theme inline {
  /* Colors — produces bg-paper, text-paper, border-paper, ring-paper, etc. */
  --color-paper:        var(--color-paper);
  --color-paper-warm:   var(--color-paper-warm);
  --color-paper-soft:   var(--color-paper-soft);
  --color-rule:         var(--color-rule);
  --color-rule-strong:  var(--color-rule-strong);
  --color-ink:          var(--color-ink);
  --color-ink-muted:    var(--color-ink-muted);
  --color-ink-faint:    var(--color-ink-faint);
  --color-ink-ghost:    var(--color-ink-ghost);
  --color-accent-ink:   var(--color-accent-ink);
  --color-accent-soft:  var(--color-accent-soft);
  --color-accent-tint:  var(--color-accent-tint);
  --color-spk2-bg:      var(--color-spk2-bg);
  --color-spk2-fg:      var(--color-spk2-fg);
  --color-spk2-rail:    var(--color-spk2-rail);
  --color-rec-red:      var(--color-rec-red);
  --color-live-green:   var(--color-live-green);

  /* Radii — produces rounded-input, rounded-btn, rounded-card, rounded-bubble, rounded-pill */
  --radius-input:       var(--radius-input);
  --radius-btn:         var(--radius-btn);
  --radius-card:        var(--radius-card);
  --radius-bubble:      var(--radius-bubble);
  --radius-pill:        var(--radius-pill);

  /* Shadows — produces shadow-lift, shadow-btn, shadow-float */
  --shadow-lift:        var(--shadow-lift);
  --shadow-btn:         var(--shadow-btn);
  --shadow-float:       var(--shadow-float);

  /* Fonts — appends system fallbacks to next/font variables from layout.tsx */
  --font-sans:  var(--font-inter),          "SF Pro Text", -apple-system, system-ui, sans-serif;
  --font-serif: var(--font-spectral),       "New York",    Georgia,       serif;
  --font-mono:  var(--font-jetbrains-mono), "SF Mono",     Menlo,         monospace;
}
```

**Why `:root` and `@theme inline` both declare the same names:** `:root` is the normal CSS cascade; `@theme inline` is Tailwind's token registry. `@theme inline` with `var(--color-paper)` on the right says "when you see `bg-paper`, emit `background-color: var(--color-paper)`" — it does NOT redefine `--color-paper` in `:root`. The two declarations work together: `:root` provides the value, `@theme inline` provides the utility mapping. `[CITED: tailwindcss.com/docs/theme]`

### Namespaces and utility generation

| Token prefix | Utilities produced |
|---|---|
| `--color-*` | `bg-*`, `text-*`, `border-*`, `ring-*`, `fill-*`, `stroke-*`, `divide-*`, `outline-*`, `accent-*`, `caret-*`, `placeholder-*` |
| `--radius-*` | `rounded-*` (and directional: `rounded-t-*`, `rounded-tl-*`, etc.) |
| `--shadow-*` | `shadow-*` |
| `--font-*` | `font-*` (font-family only; NOT font-size) |

Hyphens in token names are preserved: `--color-spk2-bg` → `bg-spk2-bg`, `--color-ink-muted` → `text-ink-muted`, `--color-rule-strong` → `border-rule-strong`. `[VERIFIED: tailwindcss.com/docs/colors via WebFetch 2026-04-22]`

**Tokens NOT renamed (intentional divergence from `tokens.css`):**

| `tokens.css` original | `globals.css` (Phase 12) | Reason |
|---|---|---|
| `--paper`, `--paper-warm`, `--paper-soft` | `--color-paper`, etc. | Tailwind v4 namespace prefix |
| `--rule`, `--rule-strong` | `--color-rule`, `--color-rule-strong` | Tailwind v4 namespace prefix |
| `--ink`, `--ink-muted`, `--ink-faint`, `--ink-ghost` | `--color-ink`, etc. | Tailwind v4 namespace prefix |
| `--accent-ink`, `--accent-soft`, `--accent-tint` | `--color-accent-ink`, etc. | Tailwind v4 namespace prefix |
| `--spk2-bg`, `--spk2-fg`, `--spk2-rail` | `--color-spk2-bg`, etc. | Tailwind v4 namespace prefix |
| `--rec-red`, `--live-green` | `--color-rec-red`, `--color-live-green` | Tailwind v4 namespace prefix |
| `--r-input`, `--r-btn`, `--r-card`, `--r-bubble`, `--r-pill` | `--radius-input`, `--radius-btn`, `--radius-card`, `--radius-bubble`, `--radius-pill` | Tailwind v4 namespace prefix (`r-` not recognized) |
| `--shadow-lift`, `--shadow-btn`, `--shadow-float` | unchanged | Already correct namespace |
| `--font-sans`, `--font-serif`, `--font-mono` | unchanged | Already correct namespace, value changes (see fallback section) |

## next/font Fallback Chain

### Current state (Phase 11, locked)

`layout.tsx` imports Inter / Spectral / JetBrains Mono via `next/font/google`, wiring them to `--font-inter`, `--font-spectral`, `--font-jetbrains-mono` on `<html>`. Phase 12 does NOT modify font loading.

```tsx
// website/src/app/layout.tsx — DO NOT MODIFY (font loading locked by D-11/Phase 11)
const inter = Inter({ subsets: ['latin'], display: 'swap', variable: '--font-inter' })
const spectral = Spectral({ subsets: ['latin'], display: 'swap', weight: ['400', '600'], variable: '--font-spectral' })
const jetbrainsMono = JetBrains_Mono({ subsets: ['latin'], display: 'swap', variable: '--font-jetbrains-mono' })

<html className={`${inter.variable} ${spectral.variable} ${jetbrainsMono.variable}`}>
```

### Phase 12's job: fallback chain

The `next/font` variables expand to something like `__inter_abc123, __inter_Fallback_abc123` — a two-entry list produced by Next.js. We need the Tailwind `font-sans` / `font-serif` / `font-mono` utilities (and any consumer of `var(--font-sans)`) to resolve to:

```
var(--font-inter), "SF Pro Text", -apple-system, system-ui, sans-serif
```

This is done in the `@theme inline` block (see Tailwind v4 section above). Because `@theme inline` emits `font-family: var(--font-sans)` into `.font-sans`, and `--font-sans` is declared in the theme as the full chain, the fallback kicks in exactly when the Inter webfont hasn't loaded yet (or fails to load). The chain is:

| Slot | Primary (from `next/font`) | Fallback 1 | Fallback 2 | Fallback 3 |
|---|---|---|---|---|
| Sans | `var(--font-inter)` | `"SF Pro Text"` | `-apple-system, system-ui` | `sans-serif` |
| Serif | `var(--font-spectral)` | `"New York"` | `Georgia` | `serif` |
| Mono | `var(--font-jetbrains-mono)` | `"SF Mono"` | `Menlo` | `monospace` |

**Why SF Pro Text instead of SF Pro:** "SF Pro" is an installed-family hint; "SF Pro Text" is the specific variant macOS uses at body sizes (Display for >20px is a separate face). "SF Pro Text" is what the app's `tokens.css` already uses (line 33: `"SF Pro Text"`) — matching that for consistency. `[VERIFIED: design/ps-transcribe-web-unzipped/assets/tokens.css line 33]`

**Why `-apple-system` after "SF Pro Text":** `-apple-system` is the canonical way to request the platform UI font on Apple devices and is more robust than a literal `"SF Pro Text"` string (which can miss on some versions). Order matters: the literal name is tried first, falling through to `-apple-system` if the user has a differently-versioned SF, then to cross-platform `system-ui`, then to the generic `sans-serif`. `[CITED: tokens.css pattern + webkit docs convention]`

### Anti-pattern to avoid

Do NOT do this in `layout.tsx`:

```tsx
// WRONG — modifies font loading, violates D-11/Phase 11 lock
const inter = Inter({ subsets: ['latin'], fallback: ['SF Pro Text', ...] })
```

`next/font`'s `fallback` option injects fallbacks *into the `next/font` loader itself*, which only affects the layout-shift adjustment font computation. It does NOT produce the cross-platform chain we want in `--font-sans`. The right place is `@theme inline`, where we compose the chain *around* the `next/font` variable. `[CITED: node_modules/next/dist/docs/01-app/03-api-reference/02-components/font.md `fallback` section]`

### Body font-family override — also needs attention

`layout.tsx` currently hard-codes `<body style={{ fontFamily: 'var(--font-inter), system-ui, sans-serif' }}>`. This is a Phase-11 placeholder and BYPASSES the `--font-sans` chain. Phase 12 should either:

- **Option A (recommended):** Remove the inline `style`; let the body inherit from Tailwind base (or add a single `className="font-sans text-ink bg-paper"` to body). Keeps the full fallback chain intact.
- **Option B:** Change the inline `style` to `fontFamily: 'var(--font-sans)'`. Also works; relies on `@theme inline` to expand `--font-sans` to the full chain.

Both options technically modify `layout.tsx`, but only the `<body>` element and only the non-font-loading part. D-11 says "do NOT modify font loading" — it doesn't say "never touch `layout.tsx`". The three font imports and the `<html className>` stay untouched. **Plans should pick Option A** for cleanliness; the current inline style is a Phase-11 placeholder and removing it is the natural cleanup.

## Light-Mode Enforcement

### Current globals.css dark block (to be removed)

```css
@media (prefers-color-scheme: dark) {
  :root {
    --background: #0a0a0a;
    --foreground: #ededed;
  }
}
```

This is the placeholder from `create-next-app`'s Geist-based starter. Per D-13, delete the entire block. `[VERIFIED: website/src/app/globals.css lines 15–20]`

### Three-layer enforcement strategy

| Layer | Purpose | Where | What it does |
|---|---|---|---|
| 1. Remove dark block | No way for CSS to flip on `prefers-color-scheme: dark` | `globals.css` | Deletes the 5-line `@media` block. Per D-13. |
| 2. `color-scheme: light` on `<html>` | Pin OS-rendered UI (scrollbars, form controls) to light | `globals.css` `html { color-scheme: light; }` | Tells the browser "render all UA default controls as if light mode." Affects scrollbars, date pickers, `<select>` dropdowns, spellcheck underlines. Per D-14. `[CITED: developer.mozilla.org/en-US/docs/Web/CSS/color-scheme via WebFetch]` |
| 3. `<meta name="color-scheme" content="light">` | Prevents dark-mode flash before CSS loads | `layout.tsx` via `export const viewport: Viewport = { colorScheme: 'light' }` | Sets UA chrome color scheme during initial page render, before any CSS paints. `[VERIFIED: node_modules/next/dist/docs/01-app/03-api-reference/04-functions/generate-viewport.md line 157]` |

### Exact code for each layer

**Layer 1 (globals.css):** just delete the `@media (prefers-color-scheme: dark)` block.

**Layer 2 (globals.css):**

```css
html {
  color-scheme: light;
}
```

Place after `@theme inline`, before the body reset. Standalone rule, single line.

**Layer 3 (layout.tsx):** add a new viewport export alongside the existing metadata export.

```tsx
import type { Metadata, Viewport } from 'next'
// ... existing font imports ...

export const metadata: Metadata = { /* unchanged */ }

// NEW — emits <meta name="color-scheme" content="light">
export const viewport: Viewport = {
  colorScheme: 'light',
}
```

**Do not use `metadata.colorScheme`.** That API is deprecated since Next 14 (the `website/AGENTS.md` "heed deprecation notices" rule applies). The canonical location is `viewport`. `[VERIFIED: node_modules/next/dist/docs/01-app/03-api-reference/04-functions/generate-metadata.md line 658]`

### Why all three, not just one

- **Layer 1 alone** would still leave scrollbars, form controls, and OS-native UI flipping dark on a dark-OS user.
- **Layer 2 alone** works after CSS loads but can FOUC for a frame on slow connections.
- **Layer 3 alone** handles the pre-CSS-paint case but is ignored if Layer 1 isn't done (the media query would still match at runtime).

All three give belt-and-suspenders coverage at near-zero cost. `[CITED: MDN color-scheme best-practice pattern]`

## Primitive Component Patterns

### Recommended pattern: conditional object + template-literal concat

No `cn()` helper. No `clsx`. No `tailwind-merge`. No CVA. For 5 primitives with 1–2 variants each and no need for mid-use class overrides, plain string concatenation is shorter, faster, and removes ~8KB of deps. Revisit if Phase 13+ adds primitives that need composable variants.

**Example — Button.tsx:**

```tsx
// website/src/components/ui/Button.tsx
import type { ButtonHTMLAttributes } from 'react'

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: 'primary' | 'secondary'
}

const base =
  'inline-flex items-center gap-2 px-4 py-[10px] rounded-btn font-sans text-[14px] font-medium leading-none transition-colors duration-[120ms] focus-visible:outline focus-visible:outline-2 focus-visible:outline-accent-ink focus-visible:outline-offset-2'

const variants: Record<NonNullable<ButtonProps['variant']>, string> = {
  primary:   'bg-ink text-paper shadow-btn hover:bg-[#2a2a25]',
  secondary: 'bg-paper text-ink border-[0.5px] border-rule-strong hover:bg-paper-soft',
}

export function Button({ variant = 'primary', className = '', ...rest }: ButtonProps) {
  return (
    <button
      {...rest}
      className={`${base} ${variants[variant]} ${className}`.trim()}
    />
  )
}
```

**Line count:** 17. Under the ~30-line target. No runtime deps beyond React.

### Per-primitive notes

| Primitive | Variants | Element | Notes |
|---|---|---|---|
| `Button` | `primary \| secondary` | `<button>` | Include `focus-visible` ring. `className` prop spread for caller overrides. |
| `Card` | none (Phase 12) | `<div>` | `bg-paper border-[0.5px] border-rule rounded-card p-[22px]`. Accepts `children` and `className`. |
| `MetaLabel` | none for Phase 12 per deferred list | `<span>` | `font-mono text-[10px] uppercase tracking-[0.08em] leading-none text-ink-faint`. |
| `SectionHeading` | optional `as` prop (`'h2' \| 'h3' \| 'h4'`), default `'h2'` | dynamic | `font-serif font-normal text-[clamp(26px,3vw,32px)] leading-[1.15] tracking-[-0.01em]`. |
| `CodeBlock` | `inline?: boolean` | `<code>` (inline) or `<pre><code>` (block) | Inline: `font-mono text-[14px] bg-paper-soft px-[6px] py-[2px] rounded-[4px]`. Block: `<pre className="font-mono text-[14px] bg-paper-soft border-[0.5px] border-rule rounded-card p-4 overflow-x-auto"><code>...</code></pre>`. |

### File layout

```
website/src/
├── app/
│   ├── design-system/
│   │   └── page.tsx          # NEW — showcase route
│   ├── globals.css            # REWRITTEN
│   ├── layout.tsx             # MINOR EDIT (add viewport export, adjust body style)
│   └── page.tsx               # UNTOUCHED (Phase 13 rewrites)
└── components/
    └── ui/                    # NEW DIRECTORY
        ├── Button.tsx
        ├── Card.tsx
        ├── MetaLabel.tsx
        ├── SectionHeading.tsx
        └── CodeBlock.tsx
```

### Anti-patterns (called out explicitly)

- No `@apply` inside primitives (D-04 forbids).
- No `forwardRef` (deferred; add when Phase 13+ needs refs).
- No default-export mixed with named (D-05 says named exports).
- No `"use client"` directive — all 5 primitives are pure presentational and should render on the server. Adding `"use client"` would opt them out of RSC and bloat the client bundle.

## Showcase Route Setup

### File structure

```
website/src/app/design-system/
└── page.tsx
```

App Router conventions: a folder under `app/` with a `page.tsx` becomes a route at `/design-system`. No `layout.tsx` needed — the root layout at `app/layout.tsx` wraps it.

### Per-page noindex (D-09)

```tsx
// website/src/app/design-system/page.tsx
import type { Metadata } from 'next'
import { Button, Card, MetaLabel, SectionHeading, CodeBlock } from '@/components/ui'

export const metadata: Metadata = {
  title: 'Design System',
  robots: {
    index: false,
    follow: false,
  },
}

export default function DesignSystemPage() {
  return (
    <main className="bg-paper text-ink min-h-dvh">
      {/* swatch grid + primitive gallery */}
    </main>
  )
}
```

**What the HTML output looks like:**
```html
<meta name="robots" content="noindex, nofollow" />
```

This overrides the root layout's `robots: { index: true, follow: true }` because page-level metadata is merged last. `[VERIFIED: node_modules/next/dist/docs/01-app/03-api-reference/04-functions/generate-metadata.md line 574 + line 1328 "nested fields ... are overwritten by the last segment"]`

### Sitemap exclusion (D-09)

No opt-out mechanism needed — `sitemap.ts` is an allow-list, not a deny-list. The current file lists only the root URL:

```tsx
// website/src/app/sitemap.ts — ALREADY CORRECT, no change needed
export default function sitemap(): MetadataRoute.Sitemap {
  return [{ url: 'https://ps-transcribe-web.vercel.app', lastModified: new Date(), changeFrequency: 'monthly', priority: 1 }]
}
```

**DESIGN-04 verification:** `sitemap.ts` must NOT be modified in Phase 12. If a planner accidentally adds `/design-system` to it, that's a DESIGN-04 violation. The verification command (see Validation Architecture) greps for the string. `[VERIFIED: node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/01-metadata/sitemap.md — sitemap.ts is an exhaustive list; routes not returned are not listed]`

### Path alias note

`@/components/ui` — verify the `@/` alias works. Looking at `tsconfig.json`:

```tsx
// Import pattern: verify against tsconfig baseUrl/paths before using
import { Button } from '@/components/ui/Button'
// or (if no path alias):
import { Button } from '../../components/ui/Button'
```

Planner should check `tsconfig.json` for `compilerOptions.paths` during Wave 0. If `@/*` isn't configured, either add it (one-line change) or use relative imports. `[ASSUMED — default create-next-app 16 sets up `@/*` alias, but planner should verify.]`

## Tricky Visual Details

### 0.5px hairlines

Per D-11 "Port token values only; rebuild primitives fresh" and Specifics bullet "Hairlines must be 0.5px, not 1px. This is an intentional editorial detail... Use `border: 0.5px solid var(--color-rule)` literally."

**Current state of browser support (2026):**

| Browser | `border: 0.5px` at DPR 2+ | `border: 0.5px` at DPR 1 |
|---|---|---|
| Safari (macOS/iOS) | Renders true 1 device-pixel hairline | Rounds up to 1px |
| Chrome (Blink) | Renders fractional (anti-aliased half-pixel) at DPR 2; truer at DPR 3 | Anti-aliases, often visible but lighter |
| Firefox (Gecko) | Historically rounded up to 1px; modern Firefox (2024+) renders fractional | Rounds up to 1px |

`[VERIFIED: chenhuijing.com/blog/about-subpixel-rendering-in-browsers + dieulot.net/css-retina-hairline + WebSearch cross-checked 2026-04-22; confidence MEDIUM — browsers evolve, and the 2016-era "Chrome doesn't support it" claim is no longer accurate as of recent Chromium versions]`

**Practical verdict:** On the primary Mac/iPhone/iPad audience (DPR 2 or 3), `border: 0.5px solid var(--color-rule)` renders a true crisp hairline in Safari, an anti-aliased half-pixel in Chrome (imperceptibly softer — fine for the quiet Chronicle aesthetic), and a hairline in modern Firefox. On DPR-1 monitors (older external displays), it rounds up to 1px in Safari/Firefox and stays fractional in Chrome. **The design intent survives** — this is exactly the tradeoff the Specifics bullet accepts ("we accept that fidelity tradeoff").

**Tailwind syntax for arbitrary 0.5px border width:**

```tsx
<div className="border-[0.5px] border-rule rounded-card">
```

Tailwind v4 supports arbitrary values in `[…]` notation out of the box. No config needed. `[CITED: tailwindcss.com/docs/border-width — arbitrary values]`

**Alternative approaches (NOT recommended for this phase):**
- `box-shadow: 0 0 0 0.5px var(--color-rule)` — Safari doesn't support fractional box-shadow spread well.
- `transform: scaleY(0.5)` with pseudo-element — works but complicates the primitive API.
- Stick with `border: 0.5px solid`.

### Two-layer primary button shadow

```css
--shadow-btn: 0 1px 2px rgba(30, 30, 28, 0.20), inset 0 1px 0 rgba(255, 255, 255, 0.08);
```

Two comma-separated layers:
1. `0 1px 2px rgba(30,30,28,0.20)` — outer soft drop shadow (below-surface depth)
2. `inset 0 1px 0 rgba(255,255,255,0.08)` — 1px top-inset highlight (simulates the bevel at top of a button against dark ink)

**Tailwind v4 behavior:** `@theme inline { --shadow-btn: var(--shadow-btn); }` causes `shadow-btn` utility to emit `box-shadow: var(--shadow-btn)`. CSS natively supports comma-separated `box-shadow` values (multi-layer), so this just works. `[VERIFIED: CSS spec — box-shadow accepts comma-separated list; tested pattern in `chronicle-mock.css` `.btn--primary` line 101]`

No need to special-case the inset layer. The `--shadow-btn` custom property holds the whole comma-separated string.

### CodeBlock inline pill padding

From the Specifics bullet: "Keep padding tight (e.g., 2px 6px); the pill should sit on a line of body text without disrupting the line-height."

**Recommended values:**

```tsx
// Inline
<code className="font-mono text-[14px] bg-paper-soft text-ink px-[6px] py-[2px] rounded-[4px]">
```

- `py-[2px]` keeps the pill vertically small so it doesn't push the line apart
- `px-[6px]` matches the brief
- `rounded-[4px]` is `--radius-input` (smaller than `--radius-btn`'s 6px for a tighter look)
- `text-[14px]` matches body copy but leaves mono slightly smaller-feeling due to glyph density

For block code, use `<pre><code>`:
```tsx
<pre className="font-mono text-[14px] bg-paper-soft text-ink border-[0.5px] border-rule rounded-card p-4 overflow-x-auto">
  <code>{children}</code>
</pre>
```

Semantic HTML: `<code>` alone for inline, `<pre><code>` for block. `<pre>` preserves whitespace; `<code>` carries the semantic "this is code" signal for screen readers and copy-paste. `[CITED: MDN Web Docs — <pre> and <code> elements]`

## Current State Audit

### `website/src/app/globals.css` (27 lines — entire file)

```css
@import "tailwindcss";

:root {
  --background: #ffffff;
  --foreground: #171717;
}

@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --font-sans: var(--font-geist-sans);
  --font-mono: var(--font-geist-mono);
}

@media (prefers-color-scheme: dark) {
  :root {
    --background: #0a0a0a;
    --foreground: #ededed;
  }
}

body {
  background: var(--background);
  color: var(--foreground);
  font-family: Arial, Helvetica, sans-serif;
}
```

### Audit: what to preserve vs rewrite

| Keep | Rewrite | Delete |
|---|---|---|
| `@import "tailwindcss";` (line 1) | `:root` block (lines 3–6) → full Chronicle palette per D-02 | `@media (prefers-color-scheme: dark)` block (lines 15–20) per D-13 |
| | `@theme inline` block (lines 8–13) → Chronicle tokens per D-03 | `body { ... font-family: Arial, Helvetica, sans-serif }` — Geist placeholder |
| | | `--font-geist-sans`, `--font-geist-mono` references — not used by `layout.tsx` (which wires Inter/Spectral/JetBrains Mono) |

**Notable current bugs:**
- The `@theme inline` block references `--font-geist-sans` and `--font-geist-mono`, but `layout.tsx` wires `--font-inter`, `--font-spectral`, `--font-jetbrains-mono`. So the current `font-sans` / `font-mono` utilities resolve to undefined vars → UA default. This is a pre-existing Phase-11 bug we'll fix by rewriting `@theme inline` per D-02.
- `body { font-family: Arial, Helvetica, sans-serif }` is also stale. Phase 12 can either drop the body selector entirely (letting `layout.tsx`'s inline style govern, or preferably let `font-sans` utility govern after Option A cleanup) or replace with minimal body reset matching `tokens.css` lines 52–60.

### Final globals.css shape (post-Phase 12)

```css
@import "tailwindcss";

/* Source of truth — raw Chronicle token values */
:root { /* 16 colors + 5 radii + 3 shadows — see Tailwind v4 section above */ }

/* Tailwind v4 theme re-export — utilities reference var() not value */
@theme inline { /* --color-*, --radius-*, --shadow-*, --font-* — see above */ }

/* Light-mode lock (DESIGN-04 layer 2) */
html {
  color-scheme: light;
}

/* Minimal body reset — Tailwind's preflight handles most resets already */
body {
  font-family: var(--font-sans);
  color: var(--color-ink);
  background: var(--color-paper);
  font-feature-settings: "ss01", "cv11";
  -webkit-font-smoothing: antialiased;
}
```

No `@media (prefers-color-scheme: dark)` block anywhere.

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | **None installed.** Plain command-line verification commands only. No Jest / Vitest / Playwright in `package.json`. |
| Config file | — |
| Quick run command | `cd website && pnpm run build 2>&1 \| head -60` — verifies TS+PostCSS+Tailwind compile cleanly |
| Full suite command | `cd website && pnpm run build && pnpm run lint` |
| Phase gate | Build green + all grep/curl probes below pass |

**Rationale for no test framework:** Phase 12 is declarative CSS + trivial presentational React components. Behavior (state, interactivity) is minimal. Adding Jest/Vitest for this phase is premature and violates YAGNI — defer until Phase 14 MDX or Phase 15 CHANGELOG parser introduce real logic worth unit-testing. Validation for Phase 12 is grep + curl + browser-eye against Vercel preview.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| DESIGN-01 | All 16 Chronicle color tokens declared in `globals.css` | grep | `for c in paper paper-warm paper-soft rule rule-strong ink ink-muted ink-faint ink-ghost accent-ink accent-soft accent-tint spk2-bg spk2-fg spk2-rail rec-red live-green; do grep -q "^  --color-$c:" website/src/app/globals.css \|\| echo "MISSING: --color-$c"; done` (expect no output) | globals.css exists post-rewrite |
| DESIGN-01 | `@theme inline` block present with all color re-exports | grep | `grep -c "^@theme inline" website/src/app/globals.css` (expect 1) | globals.css |
| DESIGN-01 | At least one `bg-*` utility used in `/design-system` page proves the generator is wired | grep | `grep -Eq "bg-(paper\|ink\|accent-ink\|spk2-bg)" website/src/app/design-system/page.tsx` | design-system/page.tsx (Wave 0) |
| DESIGN-01 | Accessibility check: `/design-system` renders without runtime errors | curl | `curl -fsSI http://localhost:3000/design-system \| head -1` (expect HTTP/2 200 after `pnpm run dev`) OR `pnpm run build` exits 0 | — |
| DESIGN-02 | `next/font` imports preserved in `layout.tsx` | grep | `grep -q "next/font/google" website/src/app/layout.tsx && grep -q "Inter\|Spectral\|JetBrains_Mono" website/src/app/layout.tsx` | layout.tsx (preserved from Phase 11) |
| DESIGN-02 | `--font-sans` chain contains "SF Pro Text" | grep | `grep -q '"SF Pro Text"' website/src/app/globals.css` | globals.css |
| DESIGN-02 | `--font-serif` chain contains "New York" | grep | `grep -q '"New York"' website/src/app/globals.css` | globals.css |
| DESIGN-02 | `--font-mono` chain contains "SF Mono" | grep | `grep -q '"SF Mono"' website/src/app/globals.css` | globals.css |
| DESIGN-03 | All 5 primitive files exist | fs | `for f in Button Card MetaLabel SectionHeading CodeBlock; do test -f website/src/components/ui/$f.tsx \|\| echo "MISSING: $f.tsx"; done` (expect no output) | 5 files (Wave 0) |
| DESIGN-03 | Each primitive is imported and rendered on `/design-system` | grep | `grep -q "import.*Button.*Card.*MetaLabel.*SectionHeading.*CodeBlock\|import.*from.*'@/components/ui'" website/src/app/design-system/page.tsx` | design-system/page.tsx |
| DESIGN-03 | `/design-system` renders all primitive DOM signatures in production build | curl+grep | After `pnpm run build && pnpm run start`: `curl -s http://localhost:3000/design-system \| grep -Ec 'class="[^"]*(bg-ink\|text-ink-faint\|border-rule\|rounded-card)[^"]*"'` (expect ≥ 5, one per primitive) | — |
| DESIGN-04 | No `prefers-color-scheme: dark` block in `globals.css` | grep | `! grep -q "prefers-color-scheme" website/src/app/globals.css` (exit 0 means absent) | globals.css |
| DESIGN-04 | No `dark:` Tailwind variant anywhere under `src/` | grep | `! grep -rE "[\"'\\s]dark:" website/src/` (exit 0 means no `dark:bg-*`, `dark:text-*`, etc.) | all source |
| DESIGN-04 | `color-scheme: light` declared in CSS | grep | `grep -q "color-scheme: *light" website/src/app/globals.css` | globals.css |
| DESIGN-04 | `colorScheme: 'light'` in layout viewport export | grep | `grep -q "colorScheme: *'light'" website/src/app/layout.tsx` | layout.tsx |
| DESIGN-04 | `<meta name="color-scheme" content="light">` emitted in production HTML | curl+grep | `curl -s http://localhost:3000/ \| grep -q '<meta name="color-scheme" content="light"'` | — |
| DESIGN-04 | `/design-system` NOT listed in sitemap | grep | `! grep -q "design-system" website/src/app/sitemap.ts` (exit 0 means absent) | sitemap.ts (unchanged) |
| DESIGN-04 | `/design-system` page emits `noindex, nofollow` | curl+grep | `curl -s http://localhost:3000/design-system \| grep -q '<meta name="robots" content="noindex,nofollow"'` | — |

### Sampling Rate

- **Per task commit:** `cd website && pnpm run build` (≈ 15–30s) + targeted grep commands for the files just changed.
- **Per wave merge:** All grep commands in the table + `pnpm run lint` + `pnpm run build`.
- **Phase gate:** All grep commands green + `pnpm run build` green + manual browser verification on Vercel preview URL (visual fidelity check against `chronicle-mock.css` reference).

### Wave 0 Gaps

Files that DO NOT exist yet and must be created before primitive/showcase verification can pass:

- [ ] `website/src/app/design-system/page.tsx` — covers DESIGN-03 rendering check
- [ ] `website/src/components/ui/Button.tsx` — covers DESIGN-03
- [ ] `website/src/components/ui/Card.tsx` — covers DESIGN-03
- [ ] `website/src/components/ui/MetaLabel.tsx` — covers DESIGN-03
- [ ] `website/src/components/ui/SectionHeading.tsx` — covers DESIGN-03
- [ ] `website/src/components/ui/CodeBlock.tsx` — covers DESIGN-03
- [ ] `website/src/components/ui/index.ts` (optional barrel export) — simplifies `/design-system` imports

No test framework install needed. No fixtures directory. No `conftest.py`. Plain grep + curl suffices for this declarative/presentational phase.

### Verification commands the planner should encode into each task's `verification_criteria`

Pattern: each task that touches globals.css / layout.tsx / a primitive file / the showcase page should include at least 2 grep probes from the table above that correspond to its scope. Example for a "write globals.css" task:

```yaml
verification_criteria:
  - "grep -c '^@theme inline' website/src/app/globals.css outputs 1"
  - "all 16 --color-* tokens declared: for c in paper paper-warm ... done outputs nothing"
  - "! grep -q 'prefers-color-scheme' website/src/app/globals.css (DESIGN-04 guard)"
  - "grep -q 'color-scheme: light' website/src/app/globals.css"
  - "cd website && pnpm run build exits 0"
```

## Anti-patterns

Training-data traps to explicitly avoid. The planner should add each of these to the "Forbidden" section of plans that touch the relevant files.

| Trap | Why it's wrong | What to do instead |
|---|---|---|
| Creating `tailwind.config.ts` with `theme.extend.colors` | Tailwind v4 is CSS-first; JS config is v3 pattern. Tailwind v4 even warns about it during build. | Put tokens in `globals.css` inside `@theme inline`. |
| Using `@apply` inside `Button.tsx` / primitives | D-04 explicitly forbids; `@apply` creates CSS/React impedance mismatch and defeats the purpose of utility classes in JSX | Inline Tailwind class strings directly in the JSX `className`. |
| Importing `chronicle-mock.css` into `globals.css` or any component | D-12 forbids. `chronicle-mock.css` is tuned to the handoff's HTML structure and would collide with React primitive class names. | Read `chronicle-mock.css` as a reference document; port values only. |
| Modifying the font loading in `layout.tsx` | D-11 + Phase 11 lock. The `Inter(...)`, `Spectral(...)`, `JetBrains_Mono(...)` calls and `className={...}` on `<html>` are untouchable. | Append fallbacks in `@theme inline` (see fallback-chain section). The only `layout.tsx` edits allowed are: (a) add `viewport` export for `colorScheme: 'light'`, (b) optionally clean up the body `style` to use `className="font-sans text-ink bg-paper"` or to reference `var(--font-sans)`. |
| Modifying `page.tsx` to use new tokens | Specifics / D-08 — Phase 13 rewrites it. Touching it in Phase 12 is churn. | Leave `page.tsx` as-is. Build the showcase at `/design-system` instead. |
| Adding `/design-system` to `sitemap.ts` | D-09 explicitly excludes it. Search engines should not index the dev page. | Leave `sitemap.ts` unchanged. |
| Using `metadata.colorScheme` in `layout.tsx` | Deprecated since Next 14. AGENTS.md explicitly says "heed deprecation notices." | Use `export const viewport: Viewport = { colorScheme: 'light' }`. |
| Using `robots.ts` to block `/design-system` | Overkill for a single page. `robots.txt` uses user-agent rules, not per-page noindex. The per-page `metadata.robots` approach is tighter and doesn't expose the URL pattern in `/robots.txt`. | Export `metadata.robots = { index: false, follow: false }` from `design-system/page.tsx`. Leave `robots.ts` alone. |
| Adding `dark:bg-*` / `dark:text-*` / any `dark:` variant | DESIGN-04 violation. Tailwind generates the `dark:` variant automatically but activating it on an element that inherits `color-scheme: light` still sends a dark-mode signal in authoring intent. | Never type `dark:`. Rely on a single palette. |
| Installing Radix / shadcn-ui / HeadlessUI | D-07 says "`asChild` is NOT in scope — no Radix." Phase 12 primitives don't need compound components. Adds ~40KB and a new mental model. | Native semantic HTML elements with `...rest` prop spreading. Revisit in Phase 14 if MDX needs Tabs/Accordion/Dialog. |
| Installing `clsx` / `tailwind-merge` / `class-variance-authority` for 5 primitives | Premature. Template-literal concat + a lookup object is 3 fewer deps and one fewer abstraction layer. | Template literal: `` `${base} ${variants[variant]} ${className}`.trim() ``. Adopt `clsx` when a primitive needs 3+ composable variant axes. |
| Adding `"use client"` to primitives | Forces client bundle and loses RSC benefits. Primitives are pure presentational — they don't use hooks, state, or event handlers beyond what `...rest` passes through. | Omit the directive. Server components by default. |
| Writing `border-[0.5px]` as `border-px` or `border` (1px default) | Tailwind's `border` utility is 1px. `border-px` is 1px. 0.5px is an intentional Chronicle editorial detail (Specifics bullet). Dropping it silently changes the visual. | Use `border-[0.5px]` Tailwind arbitrary-value syntax (supported out of the box in v4). |
| Using em dashes in showcase copy | User global rule: "Never use em dashes". | Use double hyphens `--` or rephrase. |
| Including `Co-Authored-By: Claude ...` in Phase 12 commits | User global rule: strip all Claude attribution. | Standard commit messages only. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Adopt no `cn()` / `clsx` helper for 5 primitives; template-literal concat suffices | Primitive Component Patterns | LOW — if Phase 13 adds primitives with composable variants, adopting `clsx` then is a 2-line change per file. No lock-in. |
| A2 | `@/components/ui` path alias is configured in `tsconfig.json` | Showcase Route Setup | LOW — planner verifies in Wave 0; fallback is relative imports (`../../components/ui/Button`). |
| A3 | create-next-app 16's tsconfig ships with `@/*` alias by default | Showcase Route Setup | LOW — same mitigation as A2. |
| A4 | Body font-family cleanup (removing `layout.tsx`'s `style={{ fontFamily: ... }}`) is allowed under D-11's "do NOT modify font loading" constraint | next/font Fallback Chain (Option A) | MEDIUM — if the user interprets D-11 strictly as "no changes to layout.tsx at all," plans should pick Option B (change style to `var(--font-sans)`) instead. Both yield correct runtime behavior. Planner should surface this in discuss-phase if unsure. |
| A5 | Chrome/Safari/Firefox in 2026 all render `border: 0.5px` at DPR 2+ to the designer's intended fidelity; the "fidelity tradeoff" bullet is accurate | Tricky Visual Details | LOW — it's an explicit Specifics bullet that accepts the tradeoff. Worst case: Chrome at DPR 1 renders slightly soft; matches Chronicle app's aesthetic regardless. |
| A6 | Phase 12 needs no test framework (no Jest/Vitest/Playwright install) | Validation Architecture | LOW — adding a test framework mid-milestone is a deliberate planner decision. Phase 12's declarative nature doesn't justify one. If Phase 14 MDX or Phase 15 parser needs one, install then. |
| A7 | The `chronicle-mock.css` `.meta` letter-spacing of `0.08em` is the intended value (not the brief's "0.5–0.8px") | Primitive Component Patterns (MetaLabel) | LOW — the Specifics bullet explicitly calibrates this: "Follow the brief's `.meta` rule in chronicle-mock.css as the sizing reference: `letter-spacing: 0.08em`". |
| A8 | Using `-apple-system` in the sans fallback chain as the 2nd hop (after `"SF Pro Text"`) matches Chronicle app convention | next/font Fallback Chain | LOW — `tokens.css` line 33 literally has `"Inter", -apple-system, "SF Pro Text", system-ui, sans-serif`. Our chain preserves this intent (swapping order slightly: `"SF Pro Text"` before `-apple-system` for cross-platform macOS-hint preference). Either order renders identically on macOS. |

## Open Questions

None — all decisions are resolvable by the planner using the locked CONTEXT.md decisions, the references above, and the Assumptions Log.

## Sources

### Primary (HIGH confidence)
- `website/node_modules/tailwindcss/theme.css` — Tailwind v4 default theme showing `--color-*` / `--font-*` / `--radius-*` / `--shadow-*` namespaces and their value format.
- `website/node_modules/next/dist/docs/01-app/03-api-reference/04-functions/generate-metadata.md` — `robots` field syntax (line 551); `colorScheme` deprecation notice (line 658 + line 1423 version history).
- `website/node_modules/next/dist/docs/01-app/03-api-reference/04-functions/generate-viewport.md` — `viewport.colorScheme` canonical API (line 157); replaces deprecated `metadata.colorScheme`.
- `website/node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/01-metadata/robots.md` — confirms per-page override pattern.
- `website/node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/01-metadata/sitemap.md` — sitemap is an allow-list.
- `website/node_modules/next/dist/docs/01-app/03-api-reference/02-components/font.md` — `next/font` variable + fallback option.
- `design/ps-transcribe-web-unzipped/assets/tokens.css` — source of truth for the 16 colors + 5 radii + 3 shadows + font-family reference chain.

### Secondary (MEDIUM confidence)
- `tailwindcss.com/docs/theme` via WebFetch 2026-04-22 — `@theme` vs `@theme inline` behavior and use cases.
- `tailwindcss.com/docs/colors` via WebFetch 2026-04-22 — hyphenated token name → utility name mapping.
- `developer.mozilla.org/en-US/docs/Web/CSS/color-scheme` via WebFetch 2026-04-22 — `color-scheme` CSS property behavior, relationship with `<meta>` tag.

### Tertiary (LOW confidence — verified by cross-reference)
- `chenhuijing.com/blog/about-subpixel-rendering-in-browsers`, `dieulot.net/css-retina-hairline`, `bigfrontend.dev/css/hairline` — 0.5px border behavior across browsers; 2016-era claims that Chrome doesn't support it are outdated. Modern Chromium renders fractional borders on retina displays. Confidence MEDIUM on the final verdict because the design intent explicitly accepts fidelity tradeoff.

## Metadata

**Confidence breakdown:**
- Tailwind v4 `@theme inline`: HIGH — verified via WebFetch + installed theme.css.
- Next.js 16 metadata + viewport API: HIGH — read directly from installed docs.
- next/font fallback chain: HIGH — pattern matches `tokens.css` + Next.js docs.
- Primitive component patterns: HIGH — straight React + Tailwind, no exotic APIs.
- 0.5px hairline browser behavior: MEDIUM — Specifics bullet accepts tradeoff; modern Chromium/Safari/Firefox all render something visible, with platform-specific fidelity differences.
- Light-mode enforcement three-layer strategy: HIGH — all three layers verified by MDN + Next.js 16 docs.
- No-test-framework recommendation: MEDIUM — judgment call; justified by declarative nature of Phase 12 scope.

**Research date:** 2026-04-22
**Valid until:** 2026-05-22 (30 days — Next.js 16 and Tailwind CSS v4 are both stable, but minor versions could ship new APIs)

## RESEARCH COMPLETE
