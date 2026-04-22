# Phase 12: Chronicle Design System Port - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-22
**Phase:** 12-chronicle-design-system-port
**Areas discussed:** Token distribution, Primitive authoring style, Showcase/dev page, Design handoff reuse, Dark-mode enforcement

---

## Gray Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| Token distribution | How Chronicle colors reach components: Tailwind v4 @theme, CSS variables only, or hybrid. | ✓ |
| Primitive authoring style | How the 5 primitives are coded: Tailwind class strings, mirror handoff CSS, or hybrid @layer. | ✓ |
| Showcase/dev page | Where primitives get proven: replace `/`, new `/design-system` route, or both. | ✓ |
| Design handoff reuse | How much of `tokens.css` / `chronicle-mock.css` to port. | ✓ |

**User's choice:** All four areas selected.

---

## Token distribution

### Q1: How should the 16 Chronicle palette tokens reach components?

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid: CSS vars + @theme (Recommended) | CSS custom properties in :root as source of truth; re-exposed via Tailwind v4 @theme inline. Both `bg-paper` utilities AND `var(--color-paper)` work. | ✓ |
| Tailwind @theme only | Tokens defined directly in @theme block. `bg-paper`, `text-ink-muted` utilities; no bare CSS var escape hatch. | |
| CSS vars only | Pure CSS custom properties in :root. Consumers use inline styles or arbitrary Tailwind values. | |

**User's choice:** Hybrid: CSS vars + @theme (Recommended)
**Notes:** Strict superset — components can use Tailwind utilities for DX and CSS vars for edge cases (OG image, inline styles, third-party surfaces).

### Q2: Should non-color tokens (radii, shadows, spacing, font families) also be centralized?

| Option | Description | Selected |
|--------|-------------|----------|
| Full token set (Recommended) | Radii (4/6/10/12/999), shadows (lift/btn/float), font families, and colors all live in :root + @theme. | ✓ |
| Colors only | Only 16 palette colors are tokens. Radii/shadows/fonts live inline per-primitive. | |
| Colors + shadows + radii, skip spacing | Skip custom font tokens since next/font already exposes them; keep Tailwind default spacing. | |

**User's choice:** Full token set (Recommended)
**Notes:** Phase 13-15 inherit a complete system without having to re-tokenize later.

---

## Primitive authoring style

### Q1: How should the 5 primitives be authored?

| Option | Description | Selected |
|--------|-------------|----------|
| Tailwind classes in React (Recommended) | React components with Tailwind utility class strings. Variant logic as conditional object per component. | ✓ |
| Mirror handoff CSS classes | Port `chronicle-mock.css` semantic classes (.btn, .card, .meta) into globals.css wholesale. React wraps className. | |
| Hybrid: Tailwind + small @layer components | Tailwind utilities + complex repeated patterns defined once as @layer components. | |

**User's choice:** Tailwind classes in React (Recommended)

### Q2: Where should primitives live and how should variants be expressed?

| Option | Description | Selected |
|--------|-------------|----------|
| src/components/ui/* with variant unions (Recommended) | One file per primitive in src/components/ui/. Discriminated variant props (`variant: 'primary' \| 'secondary'`). Named exports. | ✓ |
| src/components/* (flat, no ui subdir) | Same variant-union prop shape, flat directory structure. | |
| Let Claude decide | Defer location/API shape to planning. | |

**User's choice:** src/components/ui/* with variant unions (Recommended)
**Notes:** Matches shadcn/ui conventions and leaves src/components/ open for feature components in Phases 13-15.

---

## Showcase/dev page

### Q1: Where should primitives be proven to render (Success Criterion 3)?

| Option | Description | Selected |
|--------|-------------|----------|
| /design-system route, keep / placeholder (Recommended) | New `/design-system` page with all palette + primitives. `/` placeholder stays untouched for Phase 13. | ✓ |
| Replace / with showcase | Rewrite `page.tsx` as the showcase. Phase 13 overwrites it when building real landing. | |
| Both: /design-system AND refactor / | Showcase route + refactor placeholder to use primitives (prove real usage). | |

**User's choice:** /design-system route, keep / placeholder (Recommended)
**Notes:** Persistent reference page survives Phase 13+; Phase 13 gets a clean `/` canvas.

### Q2: Should `/design-system` be crawlable/public or hidden from search engines?

| Option | Description | Selected |
|--------|-------------|----------|
| Noindex + exclude from sitemap (Recommended) | Page exports `robots: { index: false, follow: false }`; sitemap.ts does not list it. Reachable by URL only. | ✓ |
| Public, no special treatment | Add to sitemap, no noindex. | |
| Only render in dev mode | 404 in production via NODE_ENV guard. | |

**User's choice:** Noindex + exclude from sitemap (Recommended)

---

## Design handoff reuse

### Q1: How much of `design/ps-transcribe-web-unzipped/assets/{tokens.css, chronicle-mock.css}` should be ported into /website?

| Option | Description | Selected |
|--------|-------------|----------|
| Port token values only, rebuild primitives (Recommended) | Copy 16 colors + 5 radii + 3 shadow VALUES into globals.css (renamed to Tailwind v4 conventions). Rebuild primitives fresh in React. chronicle-mock.css reference-only. | ✓ |
| Copy both files as-is + thin React wrappers | Drop both CSS files into /website/src/styles/, import from globals.css. React primitives pass `className="btn btn--primary"`. | |
| Brief-only, ignore handoff CSS | Pull values from CLAUDE-DESIGN-BRIEF.md only. Zero coupling to mock CSS. | |

**User's choice:** Port token values only, rebuild primitives (Recommended)
**Notes:** mock CSS is tuned to the handoff's HTML structure; would fight our React primitive boundaries. Values only, not rules.

---

## Dark-mode enforcement (DESIGN-04)

### Q1: How strict should no-dark-mode enforcement be?

| Option | Description | Selected |
|--------|-------------|----------|
| Strip + set color-scheme: light (Recommended) | Remove `@media (prefers-color-scheme: dark)` block AND add `color-scheme: light` on `<html>`. Native form controls locked to light theme. | ✓ |
| Just strip the prefers-color-scheme block | Minimum required by DESIGN-04. Native controls may still recolor on dark OS. | |
| Add Playwright/E2E check for light palette | Strip + color-scheme + a test that asserts tokens compute correctly under prefers-color-scheme: dark. | |

**User's choice:** Strip + set color-scheme: light (Recommended)
**Notes:** Two-line change; guarantees native form controls stay in light theme regardless of OS setting.

---

## Close-out

### Q: Ready to create CONTEXT.md, or are there other gray areas we should cover?

**User's choice:** Create context

---

## Claude's Discretion

- Exact Tailwind v4 `@theme inline` syntax per current installed docs
- Internal shape of each primitive's variant-logic object (map vs early-return vs function)
- Whether `MetaLabel` ships with a `tone` prop or default-only (prefer default-only; add tones when Phase 13 needs them)
- `<code>` vs `<pre><code>` semantic HTML choice inside `CodeBlock`
- Showcase page visual layout and section ordering
- `forwardRef` / `cn()` adoption — defer until a concrete caller needs them

## Deferred Ideas

- Layout-level components (Nav, Footer, Hero, FeatureBlock) → Phase 13+
- CodeBlock syntax highlighting → Phase 14 (if MDX needs it)
- MetaLabel tonal variants → Phase 13 (if pages need them)
- shadcn/ui library adoption → reconsider if Phase 14 needs complex primitives
- Playwright visual-regression for light-mode enforcement → post-v1.1 if regressions appear
- Updating `opengraph-image.tsx` to consume tokens → runtime can't read globals.css; leave hex values
