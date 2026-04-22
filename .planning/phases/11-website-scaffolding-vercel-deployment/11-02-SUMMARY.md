---
phase: 11
plan: 02
subsystem: website-content-metadata
tags:
  - nextjs
  - fonts
  - metadata
  - placeholder
  - seo
  - chronicle
requirements_completed:
  - SITE-01
  - SITE-04
dependency_graph:
  requires:
    - 11-01 (website scaffold with /website Next.js 16 project, pnpm-lock.yaml, Node 22 pin)
  provides:
    - Chronicle-flavored placeholder at / (paper bg, Spectral wordmark, Inter sub-copy, JetBrains Mono meta label)
    - Three Chronicle webfonts wired via next/font/google as CSS variables
    - Static Metadata export with metadataBase, title template, OG, Twitter, robots
    - /sitemap.xml, /robots.txt, /manifest.webmanifest auto-served by Next.js file conventions
    - /icon.png (32x32) and /apple-icon.png (180x180) with auto-generated <link> tags
    - /opengraph-image (1200x630 PNG via ImageResponse)
  affects:
    - Plan 11-03 (Vercel deploy) — will verify all these routes serve 200 at production URL
    - Phase 12 (Chronicle token port) — will migrate hardcoded hex colors to Tailwind tokens
    - Phases 14-15 — will append to sitemap.ts (/docs/*, /changelog entries)
tech_stack:
  added: []
  patterns:
    - next/font/google with CSS-variable bindings (three fonts: Inter, Spectral weight ['400','600'], JetBrains_Mono)
    - Static Metadata export with metadataBase + title.default/.template
    - File-based metadata conventions (sitemap.ts, robots.ts, manifest.ts)
    - File-based app icons (icon.png, apple-icon.png auto-detected by dimensions)
    - ImageResponse OG generator via next/og (not next/server)
    - Hardcoded hex colors as inline style (Tailwind token port deferred to phase 12)
key_files:
  created:
    - path: website/src/app/sitemap.ts
      purpose: MetadataRoute.Sitemap with single entry for / at ps-transcribe.vercel.app
    - path: website/src/app/robots.ts
      purpose: MetadataRoute.Robots allow-all with sitemap URL pointer
    - path: website/src/app/manifest.ts
      purpose: MetadataRoute.Manifest with theme_color/background_color #FAFAF7 and icons array
    - path: website/src/app/opengraph-image.tsx
      purpose: 1200x630 ImageResponse with paper bg, generic serif wordmark
    - path: website/src/app/icon.png
      purpose: 32x32 favicon (auto-linked as <link rel="icon" sizes="32x32">)
    - path: website/src/app/apple-icon.png
      purpose: 180x180 Apple touch icon (auto-linked as <link rel="apple-touch-icon" sizes="180x180">)
  modified:
    - path: website/src/app/layout.tsx
      purpose: Rewrote root layout with three-font next/font wiring + full static Metadata export (including metadataBase)
    - path: website/src/app/page.tsx
      purpose: Rewrote home page as Chronicle placeholder (hardcoded hex colors per D-15)
  deleted:
    - path: website/src/app/favicon.ico
      purpose: Removed stale create-next-app scaffold favicon so icon.png becomes primary <link rel="icon">
decisions:
  - Used Next.js 16 docs bundled with the installed package (node_modules/next/dist/docs/) plus the 11-RESEARCH.md reference patterns — spot-checked sitemap and opengraph-image conventions against the in-tree docs before writing code to address AGENTS.md's "breaking changes vs training data" caveat
  - Removed website/src/app/favicon.ico (Rule 2 — missing critical functionality) so the new icon.png takes priority as primary <link rel="icon"> in the <head>. Without removal, browsers would use the stale create-next-app scaffold favicon instead of the Bot-on-Laptop 32x32 PNG. 11-01-SUMMARY already anticipated this (its favicon.ico entry says "replaced by icon.png in plan 11-02").
  - Used `PORT=3002` for local HTTP probes to avoid port collisions with parallel worktree agents (the wave runs multiple executors concurrently).
  - Kept ImageResponse rendering (not fallback static PNG) — bundle is well under 500KB cap (42KB on disk for the rendered PNG), generic serif is acceptable for a placeholder per D-17 and RESEARCH.md Open Question 2.
metrics:
  duration: "~4m wall clock"
  completed_date: "2026-04-22"
  tasks_completed: 4
  files_created: 6
  files_modified: 2
  files_deleted: 1
---

# Phase 11 Plan 02: Content & Metadata Summary

Turned the plan-11-01 scaffold into a Chronicle-flavored placeholder with three-font webfont loading and the full Next.js 16 file-based metadata suite. `/` now renders the paper-bg wordmark page, `/sitemap.xml`/`/robots.txt`/`/manifest.webmanifest`/`/opengraph-image`/`/icon.png`/`/apple-icon.png` all serve 200 locally, and the rendered `<title>` and `<link rel="icon">` match the plan spec exactly.

## What Shipped

### Layout rewrite (Task 1) — `feat(11-02): wire Chronicle fonts and full metadata into root layout` (`c9b03bb`)

- Replaced create-next-app's Geist/Geist_Mono imports with `Inter`, `Spectral`, `JetBrains_Mono` from `next/font/google`
- Spectral declared with `weight: ['400', '600']` (required — Spectral is non-variable per RESEARCH.md Pitfall 1)
- Three CSS variables (`--font-inter`, `--font-spectral`, `--font-jetbrains-mono`) bound to `<html>` via `inter.variable ${...}.variable` concat
- `<body>` default `fontFamily: 'var(--font-inter), system-ui, sans-serif'`
- Full `Metadata` export: `metadataBase: new URL('https://ps-transcribe.vercel.app')`, `title.default` / `title.template`, description, openGraph (no images — auto-injected), twitter (no images — auto-injected), robots
- **Omitted** `icons:` and `manifest:` keys — file conventions handle those

### Home page rewrite (Task 2) — `feat(11-02): replace home page with Chronicle placeholder` (`4118b0d`)

- ~40-line JSX matching D-15 byte-for-byte
- Paper bg `#FAFAF7`, ink `#1A1A17`
- Spectral 48px wordmark "PS Transcribe" via `var(--font-spectral)`, fontWeight 400, letterSpacing `-0.01em`
- Inter 16px sub-copy "Private, on-device transcription for macOS." in `#595954` (inkMuted)
- JetBrains Mono 11px meta label "v1.1 · Website" (source) rendered uppercase via `textTransform: 'uppercase'` → shows as "V1.1 · WEBSITE", color `#8A8A82` (inkFaint)
- 14px "Site coming soon." closing line in `#8A8A82`
- No `className=` attributes (no Tailwind tokens — deferred to phase 12 per D-15)

### Metadata route files (Task 3) — `feat(11-02): ship sitemap, robots, and manifest route conventions` (`4412e8c`)

- `sitemap.ts` — single entry for `/` at `https://ps-transcribe.vercel.app`, `priority: 1`, `changeFrequency: 'monthly'`, `lastModified: new Date()` (build-time evaluation)
- `robots.ts` — `userAgent: '*'`, `allow: '/'`, `sitemap: 'https://ps-transcribe.vercel.app/sitemap.xml'`
- `manifest.ts` — `theme_color` and `background_color: '#FAFAF7'`, `display: 'standalone'`, icons array referencing `/icon.png` and `/apple-icon.png`

### Icons + OG image (Task 4) — `feat(11-02): ship icons and OG image generator` (`acfa3da`)

- `sips -z 32 32 assets/icon.png --out website/src/app/icon.png` → 32x32 PNG RGBA
- `sips -z 180 180 assets/icon.png --out website/src/app/apple-icon.png` → 180x180 PNG RGBA
- `opengraph-image.tsx` — imports `ImageResponse` from `next/og`, exports `size: { width: 1200, height: 630 }`, `contentType: 'image/png'`, `alt` text, and default async function rendering paper-bg flexbox JSX with generic serif typography
- Deleted `website/src/app/favicon.ico` (Rule 2 deviation — see below)

## Rendered Output (from local `pnpm start` probe)

### `<title>`

```html
<title>PS Transcribe — Private, on-device transcription for macOS</title>
```

Exact match for layout metadata `title.default`.

### Auto-injected `<head>` tags

```html
<link rel="icon" href="/icon.png?icon.0ivywlz3vm~xp.png" sizes="32x32" type="image/png"/>
<link rel="apple-touch-icon" href="/apple-icon.png?apple-icon.0n~0soal8s5s..png" sizes="180x180" type="image/png"/>
<link rel="manifest" href="/manifest.webmanifest"/>
<meta property="og:image" content="https://ps-transcribe.vercel.app/opengraph-image?b95373646c5ba7eb"/>
```

All four tags are auto-generated from file conventions — no manual wiring in layout.tsx.

### Font CSS variables on `<html>`

```
--font-inter
--font-jetbrains-mono
--font-spectral
```

All three present in rendered HTML.

## HTTP Probe Results (local `pnpm start` on PORT=3002)

| Probe                                | Expected                            | Result   |
|--------------------------------------|-------------------------------------|----------|
| `GET /`                              | 200 + Chronicle placeholder HTML    | 200 + "Site coming soon" present |
| `GET /sitemap.xml`                   | 200 + `<loc>...ps-transcribe.vercel.app</loc>` | 200 + match |
| `GET /robots.txt`                    | 200 + "User-Agent: *\nAllow: /"     | 200 + match (with sitemap URL) |
| `GET /manifest.webmanifest`          | 200 + JSON with `theme_color: "#FAFAF7"` | 200 + match |
| `GET /icon.png`                      | 200                                 | 200 |
| `GET /apple-icon.png`                | 200                                 | 200 |
| `GET /opengraph-image`               | 200 + 1200x630 PNG                  | 200 + `PNG image data, 1200 x 630, 8-bit/color RGBA` |

Note on OG image URL: the plan text says `/opengraph-image.png`, but Next.js 16 actually exposes the generated OG at `/opengraph-image` (no `.png` extension — it's a Route Handler, not a static file). The `content-type: image/png` header and the rendered PNG bytes are correct. The `<meta property="og:image">` tag points at `/opengraph-image?<hash>` (correct URL form). This is Next.js 16 behavior, not a defect — probing `/opengraph-image.png` returns 404, probing `/opengraph-image` returns 200.

## OG Image Rendering Decision

**Chose ImageResponse (not static PNG fallback).** Rationale:
- Build succeeded without ImageResponse-size warnings
- Rendered PNG is 42KB on disk — well under the 500KB bundle cap
- Generic serif fontFamily keeps the bundle tiny (no `readFile` of a TTF)
- Visual output is acceptable for a placeholder page: paper bg, uppercase "PS TRANSCRIBE" label, 72px serif sub-copy. RESEARCH.md Open Question 2's fallback path (swap to `src/app/opengraph-image.png` static PNG) remains available if phase-gate visual review dislikes the serif rendering.

## Next.js 16 Pitfalls Encountered

**None.** Build ran clean on the first try after each task:
- No Spectral weight error (Pitfall 1) — weight explicitly set
- No metadataBase error (Pitfall 4) — `metadataBase: new URL(...)` set in layout
- No multi-lockfile warning (Pitfall 5) that blocked the build — the build still succeeded (the pre-existing `bun.lockb` warning from 11-01's SUMMARY is unchanged; not a blocker)
- No ImageResponse bundle-size warning (threat T-11-02-02) — well under cap
- No `next/server` deprecation — imported `ImageResponse` from `next/og` as the plan specified

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Removed stale `website/src/app/favicon.ico`**

- **Found during:** Task 4 (HTTP probe of `<head>` after `sips` + opengraph-image.tsx write)
- **Issue:** create-next-app had generated `website/src/app/favicon.ico` in plan 11-01 (committed in `666b75b`). Next.js 16's file-convention precedence: if both `favicon.ico` and `icon.png` exist in `src/app/`, `favicon.ico` wins the `<link rel="icon">` slot. The first post-Task-4 probe confirmed this: `<link rel="icon" href="/favicon.ico?..." sizes="256x256" type="image/x-icon"/>` instead of pointing at the new 32x32 `icon.png`. The intent of Task 4 and D-17 is for the Bot-on-Laptop PNG (derived from `assets/icon.png`) to be the primary favicon — without removing the old ICO, that doesn't happen.
- **Fix:** `git rm website/src/app/favicon.ico`. Rebuilt + re-probed: `<link rel="icon" href="/icon.png?..." sizes="32x32" type="image/png"/>` now points at our new PNG.
- **Files modified:** `website/src/app/favicon.ico` (deleted).
- **Commit:** `acfa3da` (bundled into the same Task-4 commit that adds icon.png, apple-icon.png, opengraph-image.tsx).
- **Precedent:** 11-01-SUMMARY.md's `key_files.created` entry for favicon.ico literally says "Default favicon (replaced by icon.png in plan 11-02)". The 11-01 author anticipated the 11-02 executor would remove it — this plan's Task 4 instructions assumed file-convention auto-injection worked cleanly, but didn't explicitly direct the delete. Applied Rule 2 autonomously.

### Adjustments (non-rule)

**1. Used `PORT=3002` for HTTP probes** instead of the default 3000. Multiple worktree agents run concurrently under the parallel-execution wave; port 3000 may be occupied by another executor's dev server. Choosing an unused port is a no-op for correctness and doesn't change any output.

**2. Pre-execution spot-check of Next.js 16 bundled docs.** `website/AGENTS.md` warns that "This is NOT the Next.js you know" and to read `node_modules/next/dist/docs/` before writing code. I verified the sitemap.ts and opengraph-image.tsx patterns against the bundled `01-app/03-api-reference/03-file-conventions/01-metadata/sitemap.md` and `opengraph-image.md` — both match the plan's code verbatim and match the 11-RESEARCH.md patterns. No adjustments needed; documenting the verification step here so the phase reviewer doesn't have to redo it.

## Observations (non-blocking)

- **bun.lockb workspace-root warning persists.** Same warning flagged in 11-01-SUMMARY. Source is `/Users/cary/bun.lockb` at the user's home, unrelated to this repo. Build still succeeds. Out of scope for phase 11 per that prior observation.
- **`<link rel="icon">` URL includes a hash query string** (`?icon.0ivywlz3vm~xp.png`). This is Next.js 16's cache-busting behavior — the file is still served at `/icon.png` regardless of query string. HTTP probe at `/icon.png` returns 200 without the query.
- **ImageResponse route exposes at `/opengraph-image` (no `.png` suffix).** The plan's acceptance criterion phrased as `GET /opengraph-image.png` is loose — the actual route is extension-less but returns `content-type: image/png`. Both the probe and the `<meta property="og:image">` tag use the extension-less form correctly.

## Commits

| Task | Commit    | Message                                                     |
|------|-----------|-------------------------------------------------------------|
| 1    | `c9b03bb` | feat(11-02): wire Chronicle fonts and full metadata into root layout |
| 2    | `4118b0d` | feat(11-02): replace home page with Chronicle placeholder   |
| 3    | `4412e8c` | feat(11-02): ship sitemap, robots, and manifest route conventions |
| 4    | `acfa3da` | feat(11-02): ship icons and OG image generator (includes favicon.ico removal) |

All four commits signed with `--no-verify` per parallel-execution protocol — the orchestrator will re-run hooks once after wave merge.

## Requirements Completed

- **SITE-01** — TypeScript strict still compiles (`pnpm build` exits 0), `@/*` alias still maps to `src/*`, Node 22 pin unchanged. This plan's rewrites don't regress any 11-01 infrastructure.
- **SITE-04** — Chronicle placeholder content that **will** be served at `https://ps-transcribe.vercel.app` once Plan 11-03 wires the Vercel project. The production-reachability half of SITE-04 is earned by 11-03; the content half ships here. Marking satisfied per the plan's `<output>` directive ("SITE-04's production reachability is fully earned in Plan 03 deploy, but this plan covers the content that will be served when production comes up").

## Known Stubs

**None.** The placeholder content is intentional per D-15 (not a stub — the site deliberately says "Site coming soon." until phases 13-15 build out the full landing/docs/changelog). The `opengraph-image.tsx` generic-serif fontFamily is a known acceptable trade-off per RESEARCH.md Open Question 2, not a stub — it renders a complete 1200x630 OG image today.

## Handoff Notes

- **Plan 11-03** will:
  1. Ask the user to create the Vercel project via dashboard (Root Directory = `website`, project slug `ps-transcribe`).
  2. Set the Ignored Build Step = `git diff HEAD^ HEAD --quiet -- .`.
  3. Push to `main`, wait for the first production deploy, then re-run the HTTP probe suite above against `https://ps-transcribe.vercel.app/*` (all URLs should return the same 200 results).
  4. If the `ps-transcribe` slug is taken, update the three hardcoded URLs: layout.tsx `metadataBase`, sitemap.ts `url`, robots.ts `sitemap`, manifest.ts (no URL — can stay).
- **Phase 12** will migrate the hardcoded hex colors in `page.tsx` and `opengraph-image.tsx` to Tailwind token classes. That work is scoped to phase 12 — not a deviation.
- **Phases 14-15** will append entries to `sitemap.ts` for `/docs/*` and `/changelog`.

## Metrics

| Metric               | Value              |
|----------------------|--------------------|
| Wall-clock duration  | ~4 minutes         |
| Tasks completed      | 4 / 4              |
| Files created        | 6                  |
| Files modified       | 2 (layout.tsx, page.tsx) |
| Files deleted        | 1 (favicon.ico)    |
| Commits              | 4 (c9b03bb, 4118b0d, 4412e8c, acfa3da) |
| Build result         | `pnpm build` exits 0, 7 static routes |
| Lint result          | `pnpm lint` clean  |
| Completed            | 2026-04-22         |

## Self-Check: PASSED

**Files verified present:**

```
website/src/app/layout.tsx            (modified)
website/src/app/page.tsx              (modified)
website/src/app/sitemap.ts            (new)
website/src/app/robots.ts             (new)
website/src/app/manifest.ts           (new)
website/src/app/opengraph-image.tsx   (new)
website/src/app/icon.png              (new, 32x32)
website/src/app/apple-icon.png        (new, 180x180)
```

`website/src/app/favicon.ico` verified **absent** (removed intentionally).

**Commits verified in `git log eee856a..HEAD`:**
- `c9b03bb` (Task 1)
- `4118b0d` (Task 2)
- `4412e8c` (Task 3)
- `acfa3da` (Task 4)
