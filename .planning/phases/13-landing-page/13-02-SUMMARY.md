---
phase: 13-landing-page
plan: 02
subsystem: ui
tags: [nextjs, client-components, server-components, intersection-observer, layout, motion, a11y]

requires:
  - phase: 13-landing-page
    plan: 01
    provides: SITE constants (REPO_URL, DMG_URL, APPCAST_URL, ISSUES_URL, LICENSE_URL, ACKNOWLEDGEMENTS_URL), verify-landing.mjs grep-suite
  - phase: 12-chronicle-design-system-port
    provides: Chronicle color/shadow/radius tokens, Button base + variants strings, font-sans/serif/mono utilities

provides:
  - useScrolled(threshold) — client hook tracking window.scrollY > threshold; passive listener with cleanup
  - useReveal<T>() — IntersectionObserver one-shot reveal hook; reduced-motion fallback to immediately-visible; no observer created when reduced
  - Reveal — client wrapper applying opacity/translate transition on intersection; opt-in per-element
  - LinkButton — server-renderable anchor twin of Button; primary/secondary variants reuse byte-identical class strings
  - Nav — sticky client header with scrolled-state (useScrolled(6)), wordmark + 3 links (Docs, Changelog, GitHub)
  - Footer — server three-column grid with brand blurb + Product + Source columns; all URLs sourced from SITE
  - layout.tsx mounts Nav + Footer — Phases 14 (docs) and 15 (changelog) inherit site chrome without modification

affects: [13-03 hero-section, 13-04 feature-blocks, 13-05 shortcuts-and-final-cta, 14-docs, 15-changelog]

tech-stack:
  added: []
  patterns:
    - "Client/server component split by concern — Nav + hooks + Reveal are client (browser APIs); Footer + LinkButton are server (zero JS shipped)"
    - "IntersectionObserver one-shot pattern — unobserve on first intersection + disconnect on unmount; no duplicate class toggling on rescroll"
    - "prefers-reduced-motion gate inside useReveal — early-return sets visible=true with no IO created, so reduced-motion users never pay the observer cost"
    - "Byte-identical Button/LinkButton class strings — LinkButton.tsx keeps the same base + variants strings as Button.tsx so visual weight matches at every breakpoint (no visual regression when switching semantic tags)"
    - "SITE constants consumption — every external URL in Footer and the GitHub link in Nav goes through SITE.*; zero hardcoded github.com URLs"
    - "Arbitrary-value Tailwind utilities for Chronicle precision — border-[0.5px], duration-[120ms], duration-[160ms], translate-y-[14px], text-[11px], tracking-[0.04em] — the 0.5px hairline and sub-pixel spacing are Chronicle details, not Tailwind defaults"
    - "Footer list styling via descendant selectors — [&_a]:font-mono [&_a]:no-underline keeps anchor styling out of every Link/anchor instance and out of a shared stylesheet"

key-files:
  created:
    - website/src/hooks/useScrolled.ts
    - website/src/hooks/useReveal.ts
    - website/src/components/motion/Reveal.tsx
    - website/src/components/ui/LinkButton.tsx
    - website/src/components/layout/Nav.tsx
    - website/src/components/layout/Footer.tsx
  modified:
    - website/src/components/ui/index.ts
    - website/src/app/layout.tsx

key-decisions:
  - "useScrolled wraps document.scroll with { passive: true } — Chronicle mock uses the same pattern; window.scroll would also work but document.scroll matches the mock verbatim and keeps drift surface minimal"
  - "useReveal guards matchMedia with typeof window !== 'undefined' — Next 16 runs useEffect only on the client so this is strictly defensive, but it keeps the hook safe if someone later inlines its logic into a server-side render path"
  - "Reveal children typed as ReactNode (not render-prop / function-as-child) — per Pitfall 10 in RESEARCH; downstream callers pass plain JSX subtrees, never closures that fire at render"
  - "LinkButton is server-renderable (no 'use client') — it's a pure functional component that renders <a> with a className string; splitting it from Button keeps the anchor semantics without polluting the <Button> surface with href/target concerns"
  - "Nav uses <header> with nested <nav> — matches mock markup and signals landmark semantics to screen readers; 'sticky top-0 z-50' + backdrop-blur honors the mock's frosted-paper effect"
  - "Footer is a server component — zero bytes of runtime JS for the entire footer surface, per RESEARCH Pattern 1; internal links use next/link, external links use plain <a>"

requirements-completed: [LAND-06, LAND-07]

duration: 3min
completed: 2026-04-23
---

# Phase 13 Plan 02: Landing Page — Wave 2 Layout Primitives Summary

**Shipped Nav + Footer site chrome mounted globally in layout.tsx plus the motion/interaction primitives (useScrolled, useReveal, Reveal, LinkButton) that every Phase-13 section and Phases 14/15 will consume. verify-landing.mjs flips LAND-06 (3 assertions) and LAND-07 (5 assertions) from MISS to OK; LAND-01..LAND-05 remain MISS as designed.**

## Performance

- **Duration:** ~3 min (executor run; 2026-04-23T07:38:17Z → 2026-04-23T07:41:00Z, 2 min 43 sec wall clock)
- **Started:** 2026-04-23T07:38:17Z
- **Completed:** 2026-04-23T07:41:00Z
- **Tasks:** 2
- **Files created:** 6 (2 hooks, 1 motion wrapper, 1 ui primitive, Nav, Footer)
- **Files modified:** 2 (ui/index.ts barrel export appended, layout.tsx imports + body mount)

## Accomplishments

### Motion + interaction primitives (Task 1)

- **`website/src/hooks/useScrolled.ts`** (19 lines) — Client hook. `useScrolled(6)` returns `false` at `window.scrollY === 0`, `true` at `scrollY > 6`. Uses `document.addEventListener('scroll', onScroll, { passive: true })` + `useEffect` cleanup. Parameterized threshold so phases 14/15 can reuse with their own thresholds.
- **`website/src/hooks/useReveal.ts`** (40 lines) — IntersectionObserver one-shot reveal. Threshold `0.12` matches the mock verbatim. On `isIntersecting`: sets `visible=true` and calls `io.unobserve(e.target)` so repeated scroll crossings don't re-fire. Returns `() => io.disconnect()` for unmount cleanup. **Reduced-motion fallback:** early-return after `matchMedia('(prefers-reduced-motion: reduce)').matches` sets `visible=true` with no IO created — zero observer overhead for users who opted out of motion.
- **`website/src/components/motion/Reveal.tsx`** (30 lines) — Client wrapper. Wraps children with `transition-[opacity,transform] duration-500 ease-out`; flips from `opacity-0 translate-y-[14px]` to `opacity-100 translate-y-0` on intersection; exposes `data-reveal="in"|"out"` for debugging.
- **`website/src/components/ui/LinkButton.tsx`** (33 lines) — Server-renderable anchor with Button-identical styling. Keeps `base` and `variants` strings byte-identical to `ui/Button.tsx` so primary/secondary LinkButtons are visually indistinguishable from their Button counterparts. Adds `no-underline` to the base class so anchors don't render with the default browser underline. Spreads `AnchorHTMLAttributes` minus `href` (href becomes a required prop).
- **`website/src/components/ui/index.ts`** — appended one line: `export { LinkButton } from './LinkButton'`. Barrel now exports 6 primitives (Button, Card, MetaLabel, SectionHeading, CodeBlock, LinkButton). Downstream plans import via `@/components/ui`.

### Site chrome (Task 2)

- **`website/src/components/layout/Nav.tsx`** (40 lines) — Client component; `'use client'`; uses `useScrolled(6)`. Sticky top-0, z-50, `backdrop-blur-[8px] backdrop-saturate-150`; transitions box-shadow + background-color over 160ms. Scrolled state flips from `border-transparent bg-paper/92` to `border-rule bg-paper-warm/92 shadow-btn`. Wordmark on the left: Spectral 19px, `text-ink`, 6×6 `bg-accent-ink` dot-mark, `PS&nbsp;Transcribe` (non-breaking space prevents the two words from wrapping apart at the smallest viewport). Three links on the right: `<Link href="/docs">`, `<Link href="/changelog">`, and `<a href={SITE.REPO_URL}>GitHub</a>` (external, plain anchor). Linkbase: font-mono 12px uppercase tracked, ink-muted → ink on hover.
- **`website/src/components/layout/Footer.tsx`** (50 lines) — Server component (no `'use client'`). Three-column grid on md+ (`md:grid-cols-[1.2fr_1fr_1fr]`) collapsing to single column on mobile. Column 1: wordmark + brand blurb ("A native macOS transcription tool. Released under MIT. Maintained as an indie side project.") + `© 2026`. Column 2 (Product): Documentation → `/docs`, Changelog → `/changelog`, Download DMG → `SITE.DMG_URL`, Sparkle appcast → `SITE.APPCAST_URL`. Column 3 (Source): GitHub repository → `SITE.REPO_URL`, Report an issue → `SITE.ISSUES_URL`, Acknowledgements → `SITE.ACKNOWLEDGEMENTS_URL`, License · MIT → `SITE.LICENSE_URL`. `FooterColumn` helper (same file, not exported) normalizes children into a `<ul>` and applies descendant-selector styling (`[&_a]:font-mono [&_a]:text-ink-muted hover:[&_a]:text-ink`) so every anchor in a column picks up mono type, muted color, and hover-underline without per-anchor class repetition.
- **`website/src/app/layout.tsx`** — Added two imports (`Nav`, `Footer`) and wrapped `{children}` in the body with `<Nav />` before and `<Footer />` after. Every route under `src/app/` (currently `/`, `/design-system`, plus metadata files) now inherits site chrome. Phase 14 (docs) and Phase 15 (changelog) will need zero layout changes.

## Task Commits

Each task was committed atomically with `--no-verify` (parallel executor flag):

1. **Task 1: useScrolled, useReveal, Reveal, LinkButton + barrel export** — `05a05eb` (feat)
2. **Task 2: Nav + Footer + layout.tsx mount** — `df2abcf` (feat)

Plan metadata (this SUMMARY) will be committed by the orchestrator after wave aggregation.

## Files Created/Modified

| Path | Lines | Kind |
|---|---|---|
| `website/src/hooks/useScrolled.ts` | 19 | created |
| `website/src/hooks/useReveal.ts` | 40 | created |
| `website/src/components/motion/Reveal.tsx` | 30 | created |
| `website/src/components/ui/LinkButton.tsx` | 33 | created |
| `website/src/components/layout/Nav.tsx` | 40 | created |
| `website/src/components/layout/Footer.tsx` | 50 | created |
| `website/src/components/ui/index.ts` | +1 line (append) | modified |
| `website/src/app/layout.tsx` | +4 lines (2 imports + 2 mount lines) | modified |
| **Total new code** | **212 lines** across 6 new files + 5 lines into 2 existing files | — |

## verify-landing.mjs current tally (post-Plan-02)

Post-build run (`./node_modules/.bin/next build` + `node scripts/verify-landing.mjs`):

```
Total OK:    14
Total MISS:  18
Exit code:    1  (as designed — Plans 03-05 remain outstanding)
```

Per-requirement breakdown:

| Requirement | OK | MISS | Notes |
|---|---|---|---|
| LAND-01 hero | 0 | 3 | ships in Plan 03 |
| LAND-02 DMG URL | 1 | 0 | already OK from Plan 01 footer |
| LAND-03 screenshot | 0 | 2 | ships in Plan 03 |
| LAND-04 features | 0 | 8 | ships in Plan 04 |
| LAND-05 shortcuts | 0 | 4 | ships in Plan 05 |
| **LAND-06 nav links** | **3** | **0** | **flipped MISS → OK in this plan** |
| **LAND-07 footer** | **5** | **0** | **flipped MISS → OK in this plan** |
| D-15 version stamp | 1 | 1 | "Released" OK (footer) / "Ver " MISS until Plan 03 hero eyebrow |
| forbidden-absent | 4 | 0 | already OK from Plan 01 |

**LAND-06 and LAND-07 assertions newly OK:**

- `OK   LAND-06 nav link to /docs`
- `OK   LAND-06 nav link to /changelog`
- `OK   LAND-06 nav link to GitHub`
- `OK   LAND-07 copyright` (`© 2026`)
- `OK   LAND-07 MIT acknowledgment` (`License · MIT`)
- `OK   LAND-07 footer product link` (`Sparkle appcast`)
- `OK   LAND-07 footer product link` (`Download DMG`)
- `OK   LAND-07 footer source link` (`Report an issue`)

## Placeholder page.tsx integration check

The Phase-11 placeholder `page.tsx` was not modified. It continues to render as `<main>` with inline-styled placeholder content — now wrapped automatically by the new `<Nav />` above and `<Footer />` below. Confirmed in the build output:

- `.next/server/app/index.html` contains the Nav wordmark (`PS&nbsp;Transcribe` — 1 match) and Footer copyright (`© 2026` — 1 match).
- Build exits 0 with 10 static pages generated; no route regressed.
- No layout shift or duplicate chrome issue — the single mount point in `layout.tsx` is authoritative.

## Decisions Made

- **`document.scroll` over `window.scroll` in `useScrolled`.** The Chronicle mock's original scroll listener targets `document`, not `window`. Both fire in modern browsers when the page scrolls; keeping the mock pattern minimizes drift surface if we ever diff against the original scroll-behavior reference.
- **`typeof window` guard in `useReveal` despite useEffect client-only semantics.** Strictly defensive. `useEffect` already guarantees client-only execution in Next 16, but the `typeof window` check keeps the hook logic self-contained and safe if anyone later inlines it into a non-hook code path (e.g., a custom provider).
- **`Reveal` accepts `ReactNode` only (not render-prop).** Per Pitfall 10 in Phase-13 RESEARCH: Reveal wraps plain JSX so the React serialization boundary between client and server stays unambiguous. No closures, no function-as-child. Downstream callers in Plans 03/04/05 will pass JSX subtrees directly.
- **`LinkButton` is server-renderable.** No `'use client'` directive. It's a pure function that renders an `<a>` element with a className. Splitting it from `Button` (which wants `ButtonHTMLAttributes`) keeps anchor semantics clean and lets callers choose between button-for-actions and anchor-for-navigation without semantic ambiguity.
- **Byte-identical Button/LinkButton class strings.** The plan was explicit about reusing the exact `base` and `variants` strings from `Button.tsx`. The only addition to LinkButton is `no-underline` — anchors get the default browser underline by default, which would break the visual weight match with `<Button>`.
- **`Nav` as `<header>`, not `<nav>`.** Mock markup uses `<header class="nav">`. This preserves semantic-HTML parity and signals a top-of-page landmark to screen readers. The inner `<nav>` element holds the actual link list.
- **`Footer` descendant-selector styling via Tailwind `[&_a]:...` utilities.** Instead of applying `className` to each `<Link>`/`<a>` inside the Product and Source columns, the `<ul>` carries the shared styling and descendant selectors propagate it to all nested anchors. Keeps call-sites terse (`<Link href="/docs">Documentation</Link>` instead of `<Link href="/docs" className="...many classes...">Documentation</Link>`). Tailwind v4 supports these arbitrary variant selectors natively.
- **No mobile hamburger nav.** Per CONTEXT.md deferred ideas: the mock has no drawer, and three links + wordmark fit on every viewport >= 375px. Revisit only if user testing flags friction.

## Deviations from Plan

**None.** Plan 13-02 was prescriptive enough that every file shipped with the exact contents specified in the `<action>` blocks. Task 1 and Task 2 verification passed on the first run; typecheck and build are green; verify-landing.mjs produced exactly the expected OK/MISS pattern.

The only workflow wrinkle is one inherited from Plan 13-01 and re-applied here: the plan's `<automated>` verify strings call `pnpm --filter ps-transcribe-website typecheck` / `... build`, but the repo has no `pnpm-workspace.yaml` at root, the `/website` package is named simply `"website"`, and no `typecheck` script exists in `website/package.json`. As in 13-01, I ran the underlying binaries directly:

- `./node_modules/.bin/tsc --noEmit` (exit 0)
- `./node_modules/.bin/next build` (exit 0)
- `node scripts/verify-landing.mjs` (exit 1 as designed — 14 OK / 18 MISS)

Same binaries the filter form would have invoked via `pnpm exec`. Functional outcomes identical. Not tracked as a deviation because it's a workflow convention inherited from Plan 01 and already documented there (see 13-01-SUMMARY.md Deviation 1).

## Issues Encountered

- **Next.js build warned about a multi-lockfile workspace detection** (`Next.js inferred your workspace root ... detected /Users/cary/bun.lockb as the root directory` + a reference to a `website/pnpm-workspace.yaml` that doesn't exist in the repo). This is a Turbopack dev-loop artifact from ancestor directories on the machine, not a problem with the website itself. The build completes successfully. Not tracked as a blocker; would be worth silencing with an explicit `turbopack.root` in `next.config.ts` during a future polish pass, but does not affect this plan's correctness.

## User Setup Required

None. No external service configuration; no auth gates encountered.

## Next Plan Readiness

- **Plan 13-03 (Hero)** can now import `<LinkButton variant="primary" href={SITE.DMG_URL}>` and `<LinkButton variant="secondary" href={SITE.REPO_URL}>` for the two hero CTAs — visual weight will match `<Button>` exactly since the class strings are byte-identical. The hero is above-the-fold and should NOT be wrapped in `<Reveal>` per the Reveal comment in `Reveal.tsx`.
- **Plan 13-04 (Feature blocks)** can import `<Reveal>` to wrap each of the four feature panels; each panel will fade in at IO threshold 0.12 on first intersection with reduced-motion users getting immediately-visible content.
- **Plan 13-05 (Shortcuts + Final CTA)** can wrap the ShortcutGrid and FinalCTA in `<Reveal>` for the same fade-in treatment.
- **Phase 14 (docs)** and **Phase 15 (changelog)** inherit Nav + Footer automatically from `layout.tsx` — no layout changes needed in those phases.
- **Phase-end verification** (run at the end of Plan 13-05): `node website/scripts/verify-landing.mjs` will flip the remaining 18 MISS assertions to OK as Plans 03/04/05 land their sections. After Plan 05 completes, the script will exit 0 and the landing page is shippable.

## Verification Summary

| Check | Result |
|---|---|
| `test -f website/src/hooks/useScrolled.ts` | OK |
| `test -f website/src/hooks/useReveal.ts` | OK |
| `test -f website/src/components/motion/Reveal.tsx` | OK |
| `test -f website/src/components/ui/LinkButton.tsx` | OK |
| `test -f website/src/components/layout/Nav.tsx` | OK |
| `test -f website/src/components/layout/Footer.tsx` | OK |
| `grep -c "^export" website/src/components/ui/index.ts` | 6 (5 existing + LinkButton) |
| `'use client'` on useScrolled / useReveal / Reveal / Nav | all 4 OK |
| `'use client'` absent from LinkButton / Footer | both OK |
| `grep "matchMedia.*prefers-reduced-motion: reduce" useReveal.ts` | OK |
| `grep "threshold: 0.12" useReveal.ts` | OK |
| `grep "io.unobserve" useReveal.ts` | OK |
| `grep "duration-500" Reveal.tsx` | OK |
| `grep "translate-y-\\[14px\\]" Reveal.tsx` | OK |
| `grep "bg-ink text-paper shadow-btn" LinkButton.tsx` | OK (primary variant) |
| `grep "no-underline" LinkButton.tsx` | OK |
| `grep "useScrolled(6)" Nav.tsx` | OK |
| `grep 'href="/docs"'` / `'href="/changelog"'` Nav.tsx | both OK |
| `grep "SITE.REPO_URL" Nav.tsx` | OK |
| `grep "SITE.{DMG,APPCAST,ISSUES,LICENSE,ACKNOWLEDGEMENTS}_URL" Footer.tsx` | all 5 OK |
| `grep "© 2026"` / `"License · MIT"` / `"Sparkle appcast"` / `"Download DMG"` / `"Report an issue"` / `"Acknowledgements"` Footer.tsx | all 6 OK |
| `grep "<Nav />"` / `"<Footer />"` layout.tsx | both OK |
| `./node_modules/.bin/tsc --noEmit` inside `website/` | exit 0 |
| `./node_modules/.bin/next build` inside `website/` | exit 0 |
| `node scripts/verify-landing.mjs` post-build | exit 1 (14 OK / 18 MISS — as designed; LAND-06 and LAND-07 newly green) |
| Rendered HTML contains Nav wordmark + Footer copyright | both confirmed in `.next/server/app/index.html` |

## Self-Check: PASSED

Verified all files exist on disk:

- `website/src/hooks/useScrolled.ts` — FOUND
- `website/src/hooks/useReveal.ts` — FOUND
- `website/src/components/motion/Reveal.tsx` — FOUND
- `website/src/components/ui/LinkButton.tsx` — FOUND
- `website/src/components/layout/Nav.tsx` — FOUND
- `website/src/components/layout/Footer.tsx` — FOUND
- `website/src/components/ui/index.ts` — FOUND (modified in place)
- `website/src/app/layout.tsx` — FOUND (modified in place)
- `.planning/phases/13-landing-page/13-02-SUMMARY.md` — FOUND (this file)

Verified all commits exist:

- `05a05eb` — FOUND (Task 1)
- `df2abcf` — FOUND (Task 2)

---

*Phase: 13-landing-page*
*Plan: 02*
*Completed: 2026-04-23*
