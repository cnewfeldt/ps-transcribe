---
phase: 11-website-scaffolding-vercel-deployment
slug: website-scaffolding-vercel-deployment
verified: 2026-04-22T00:00:00Z
status: human_needed
score: 13/14 must-haves verified (1 human_needed — PR preview URL)
must_haves_checked: 14
must_haves_verified: 13
overrides_applied: 0
live_url: https://ps-transcribe-web.vercel.app
canonical_url_note: "ps-transcribe.vercel.app was claimed by another Vercel account before phase 11 setup; fallback slug ps-transcribe-web.vercel.app is the production host per PROJECT.md"
requirements_verified:
  - id: SITE-01
    status: satisfied
  - id: SITE-02
    status: satisfied
  - id: SITE-03
    status: human_needed
  - id: SITE-04
    status: satisfied
  - id: SITE-05
    status: satisfied
human_verification:
  - test: "Open a PR touching /website and confirm Vercel bot posts a preview-URL comment"
    expected: "PR page shows a comment from the Vercel GitHub App with a URL of the form https://ps-transcribe-web-git-<branch>-<user>.vercel.app that returns 200 and serves the branch build"
    why_human: "No PR has been opened yet for ps-transcribe (gh pr list returns []). Vercel preview-URL behavior can only be observed when a PR exists; the Vercel GitHub App is installed and Task 1 of Plan 11-03 completed the OAuth wiring, but the actual bot comment is only produced on the next PR creation."
    blocking: false
    deferred_trigger: "first PR touching /website"
  - test: "Push a Swift-only commit to main and verify Vercel deployment is marked 'Ignored Build Step' / Canceled"
    expected: "Vercel deployments list shows a Canceled deploy with status 'Ignored Build Step' for the Swift-only commit; no new production build produced"
    why_human: "D-09 behavior probe (PROBE-12 in 11-VALIDATION.md). The Ignored Build Step command is verified correctly configured in the Vercel dashboard (Task 1 Step 8 of Plan 11-03), but observing the skip behavior requires a Swift-only commit to land on main. Not blocking for phase 11 — the roadmap success criteria explicitly accept this as a deferred manual check."
    blocking: false
    deferred_trigger: "first Swift-only commit on main post phase 11"
---

# Phase 11: Website Scaffolding & Vercel Deployment — Verification Report

**Phase Goal:** A `/website` subdirectory exists with a working Next.js App Router + TypeScript project, deploys on every push, produces preview URLs per PR, and serves production at `ps-transcribe.vercel.app` — without polluting the Swift package or committing build artifacts.

**Production URL:** https://ps-transcribe-web.vercel.app (fallback slug; canonical `ps-transcribe.vercel.app` was claimed externally — see PROJECT.md commit `9afaffe`).

**Verified:** 2026-04-22
**Status:** human_needed — 13 of 14 roadmap+plan truths verified programmatically; 1 truth (PR preview URL) requires a live PR to observe.
**Re-verification:** No — initial verification.

## Goal Achievement

### Observable Truths

ROADMAP success criteria (5) plus unique plan-level truths (9) merged into a 14-truth matrix.

| #  | Truth | Source | Status | Evidence |
| -- | ----- | ------ | ------ | -------- |
| 1 | `pnpm install && pnpm dev` inside `/website` boots a Next.js App Router dev server with TypeScript compiling cleanly | ROADMAP SC1 + Plan 01 | VERIFIED | `cd website && pnpm build` → exit 0, TS finished in 773ms, 9 static routes generated. Same build path as dev for TS correctness. |
| 2 | Pushing any commit that touches `/website` produces a Vercel preview URL visible on the PR | ROADMAP SC2 + Plan 03 | HUMAN_NEEDED | No PR exists yet (`gh pr list` → `[]`). Vercel GitHub App is installed (confirmed by `Vercel` status check `state=success` on commit `4c18d5f` — `target_url=vercel.com/power-shifter-sandbox/ps-transcribe/...`). First PR will exercise SITE-03. |
| 3 | Production site (`ps-transcribe-web.vercel.app`) serves the latest `main`-branch build | ROADMAP SC3 + Plan 03 | VERIFIED | `curl -sfI https://ps-transcribe-web.vercel.app` → `HTTP/2 200`. `<title>PS Transcribe — Private, on-device transcription for macOS</title>` matches layout metadata verbatim. Slug fallback documented in PROJECT.md (canonical `ps-transcribe.vercel.app` claimed externally). |
| 4 | `git status` shows no `.next/` or `node_modules/` files ever staged from `/website` | ROADMAP SC4 + Plan 01 | VERIFIED | `git ls-files website/.next website/node_modules` → 0 entries. `.gitignore` contains all four `website/...` patterns. |
| 5 | Swift package at repo root still builds; website has its own isolated `package.json` | ROADMAP SC5 + Plan 01 | VERIFIED | `cd PSTranscribe && swift build` → `Build complete! (0.17s)`. `website/package.json` independent from Swift package (Node deps only, no Swift cross-references). |
| 6 | Node 22 pinned by both `.nvmrc` (value `22`) AND `package.json` engines.node (`>=22 <23`) | Plan 01 | VERIFIED | `cat website/.nvmrc` → `22`. `website/package.json` → `"engines": { "node": ">=22 <23" }`. |
| 7 | pnpm is the package manager (pnpm-lock.yaml exists; no package-lock.json, no yarn.lock) | Plan 01 | VERIFIED | `website/pnpm-lock.yaml` present; `website/package-lock.json` and `website/yarn.lock` absent. |
| 8 | `/` renders Chronicle placeholder: paper bg `#FAFAF7`, Spectral wordmark, Inter sub-copy, JetBrains Mono meta label, "Site coming soon." | Plan 02 | VERIFIED | Live HTML contains "PS Transcribe", "Private, on-device" sub-copy, "Site coming soon". `page.tsx` has literal `#FAFAF7`, `#1A1A17`, `#595954`, `#8A8A82`, 48px Spectral h1, 11px JetBrains Mono meta label, "v1.1 · Website" source text. |
| 9 | All three fonts (Inter, Spectral, JetBrains Mono) load via `next/font/google` as CSS custom properties on every page | Plan 02 | VERIFIED | `curl -s <PROD>` → 3 unique CSS vars (`--font-inter`, `--font-spectral`, `--font-jetbrains-mono`). `layout.tsx` imports all three from `next/font/google` with Spectral `weight: ['400','600']`. |
| 10 | `/sitemap.xml` returns XML containing `<loc>https://ps-transcribe-web.vercel.app</loc>` | Plan 02 (SC adjusted for fallback slug) | VERIFIED | `curl -s <PROD>/sitemap.xml` → valid `urlset` with exactly `<loc>https://ps-transcribe-web.vercel.app</loc>`, priority 1, changefreq monthly. |
| 11 | `/robots.txt` returns 200 with allow-all rules | Plan 02 | VERIFIED | `curl -sfI <PROD>/robots.txt` → `HTTP/2 200`. Body: `User-Agent: *\nAllow: /\n\nSitemap: https://ps-transcribe-web.vercel.app/sitemap.xml`. |
| 12 | `/manifest.webmanifest` returns JSON with `theme_color: #FAFAF7` | Plan 02 | VERIFIED | `curl -sfI <PROD>/manifest.webmanifest` → 200. Body contains `"theme_color":"#FAFAF7"`, `"background_color":"#FAFAF7"`, icons array referencing `/icon.png` (32x32) and `/apple-icon.png` (180x180). |
| 13 | `/opengraph-image` returns a 1200x630 PNG; `/icon.png` returns a 32x32 PNG; `/apple-icon.png` returns a 180x180 PNG | Plan 02 | VERIFIED | `curl -sfI <PROD>/opengraph-image` → 200, `content-type: image/png`, `content-length: 42386`. `/icon.png` → 200. `/apple-icon.png` → 200. Local files: `icon.png` = `32 x 32`, `apple-icon.png` = `180 x 180`. |
| 14 | Repo `.gitignore` excludes `website/.next/`, `website/node_modules/`, `website/.vercel/`, `website/out/`; build artifacts not tracked | Plan 01 (SITE-05) | VERIFIED | `.gitignore` lines 40-43 match the four patterns exactly. `git ls-files website/.next website/node_modules` → 0. |

**Score:** 13/14 truths verified; 1 truth deferred to human verification trigger (first PR).

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `website/package.json` | Node manifest with engines.node pin, Next 16 + React 19 | VERIFIED | `next@16.2.4`, `react@19.2.4`, `react-dom@19.2.4`; `engines.node: ">=22 <23"` present |
| `website/pnpm-lock.yaml` | pnpm lockfile committed | VERIFIED | Present, tracked (Vercel pnpm auto-detect anchor) |
| `website/tsconfig.json` | TS strict with `@/*` → `./src/*` | VERIFIED | `"strict": true`, `"paths": { "@/*": ["./src/*"] }` |
| `website/.nvmrc` | value `22` | VERIFIED | Single line `22` |
| `website/src/app/layout.tsx` | Root layout with 3-font wiring + full Metadata export including `metadataBase` | VERIFIED | Inter, Spectral (weight `['400','600']`), JetBrains_Mono imports from `next/font/google`; `metadataBase: new URL('https://ps-transcribe-web.vercel.app')`; CSS vars bound to `<html>`; no `icons:` / `manifest:` keys (auto-injected) |
| `website/src/app/page.tsx` | Chronicle placeholder, ~40 lines, hardcoded hex colors | VERIFIED | 59 lines. Contains all five D-15 locked strings and all four Chronicle palette hex literals. No Tailwind classes. |
| `website/src/app/sitemap.ts` | `MetadataRoute.Sitemap` with single entry for / | VERIFIED | Returns `[{url: 'https://ps-transcribe-web.vercel.app', ..., priority: 1}]` (URL patched from plan spec to fallback slug per `4c18d5f`) |
| `website/src/app/robots.ts` | `MetadataRoute.Robots` allow-all | VERIFIED | Returns `{rules: {userAgent: '*', allow: '/'}, sitemap: 'https://ps-transcribe-web.vercel.app/sitemap.xml'}` |
| `website/src/app/manifest.ts` | `MetadataRoute.Manifest` with `theme_color: #FAFAF7` | VERIFIED | Contains all required fields including icons array |
| `website/src/app/opengraph-image.tsx` | 1200x630 ImageResponse | VERIFIED | Imports from `next/og`, `size: {width:1200, height:630}`, flexbox JSX, paper bg `#FAFAF7`. Live OG image 42KB — well under 500KB cap. |
| `website/src/app/icon.png` | 32x32 PNG | VERIFIED | `file` confirms `PNG image data, 32 x 32` |
| `website/src/app/apple-icon.png` | 180x180 PNG | VERIFIED | `file` confirms `PNG image data, 180 x 180` |
| `.gitignore` | Extended with 4 website paths | VERIFIED | Lines 40-43 match exactly: `website/.next/`, `website/node_modules/`, `website/.vercel/`, `website/out/` |
| `.planning/PROJECT.md` | Logs fallback URL if non-canonical slug used | VERIFIED | Line 53 uses `ps-transcribe-web.vercel.app`; line 55 explains canonical-slug-claimed fallback; commit `9afaffe` |

### Key Link Verification

| From | To | Via | Status | Evidence |
| ---- | -- | --- | ------ | -------- |
| `layout.tsx` | `next/font/google` | Inter/Spectral/JetBrains_Mono imports with CSS variables on `<html>` | WIRED | Live HTML contains all three `--font-*` CSS vars; layout `<html>` className combines all three `font.variable` values |
| `page.tsx` | CSS variables from layout | `var(--font-spectral)`, `var(--font-inter)`, `var(--font-jetbrains-mono)` in inline styles | WIRED | All three `var(--font-*)` occurrences present in page.tsx source |
| `manifest.ts` | `/icon.png` + `/apple-icon.png` | icons array references | WIRED | Live manifest JSON contains both icon entries with correct sizes |
| Vercel project | `/website/` directory | Root Directory = `website` setting | WIRED | First production deploy succeeded; pushes to main with `/website` changes produce Vercel builds (status=success on `4c18d5f`) |
| Vercel build | `pnpm-lock.yaml` auto-detect | lockfile in Root Directory | WIRED | `pnpm-lock.yaml` tracked in git; live build generated 9 static routes (matches local `pnpm build` output) |
| `engines.node` | Vercel Node version | `>=22 <23` read from `website/package.json` | WIRED | Deploy succeeded at commit pinning Node 22 (Vercel honors engines.node over dashboard default per Plan 01 A1) |
| Ignored Build Step | `/website` change detection | `git diff HEAD^ HEAD --quiet -- .` inside Root Directory | CONFIGURED (behavioral verification deferred) | Dashboard setting verified correct by user in Plan 03 Task 1 Step 8; skip-behavior can only be observed on next Swift-only commit |
| GitHub repo | Vercel project | Vercel GitHub App integration | WIRED | Commit status check `Vercel` → `state=success`, target `vercel.com/power-shifter-sandbox/ps-transcribe/F4P5FhzFfmchmWLDtufwiFdLHb1V` |
| `head` auto-injected links | `/manifest.webmanifest`, `/icon.png`, `/apple-icon.png`, `/opengraph-image` | Next.js file conventions | WIRED | Live `<head>` contains `<link rel="manifest">`, `<link rel="icon">`, `<link rel="apple-touch-icon">`, `<meta property="og:image">` — all auto-generated |

### Data-Flow Trace (Level 4)

The only dynamic data flow in phase 11 is build-time: `sitemap.ts` / `robots.ts` / `manifest.ts` are pure returns, `opengraph-image.tsx` is a build-time ImageResponse. All artifacts render real (non-empty, non-stub) content confirmed by probes 8-13 above. No data sources are hardcoded-empty or disconnected. `page.tsx` is static JSX by design (D-15 locks it as a deliberate placeholder). Status: FLOWING.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Next.js production build succeeds | `cd website && pnpm build` | Exit 0, 9 static routes, TS 773ms, compiled 952ms | PASS |
| Swift guardrail build | `cd PSTranscribe && swift build` | `Build complete! (0.17s)` | PASS |
| Production root reachable | `curl -sfI https://ps-transcribe-web.vercel.app` | `HTTP/2 200` | PASS |
| Placeholder content live | `curl -s <PROD>` | Contains `PS Transcribe`, `Private, on-device transcription for macOS.`, `Site coming soon.` | PASS |
| Page title matches spec | `curl -s <PROD> | grep -oE '<title>[^<]+</title>'` | `<title>PS Transcribe — Private, on-device transcription for macOS</title>` | PASS |
| Three font CSS vars rendered | `curl -s <PROD> | grep -oE -- '--font-(inter|spectral|jetbrains-mono)' | sort -u | wc -l` | 3 | PASS |
| robots.txt serves | `curl -sfI <PROD>/robots.txt` | 200 + correct body | PASS |
| sitemap.xml serves with correct loc | `curl -sf <PROD>/sitemap.xml` | 200 + `<loc>https://ps-transcribe-web.vercel.app</loc>` | PASS |
| manifest.webmanifest serves | `curl -sfI <PROD>/manifest.webmanifest` | 200 + JSON with `#FAFAF7` | PASS |
| icon.png serves | `curl -sfI <PROD>/icon.png` | 200 | PASS |
| apple-icon.png serves | `curl -sfI <PROD>/apple-icon.png` | 200 | PASS |
| opengraph-image serves as PNG | `curl -sfI <PROD>/opengraph-image` | 200 + `content-type: image/png` + `content-length: 42386` | PASS |
| Vercel status check on deployed commit | `gh api .../commits/4c18d5f/status` | `state=success`, context=`Vercel` | PASS |
| Auto-injected `<link rel="manifest">`, `<link rel="icon">`, `<link rel="apple-touch-icon">`, `<meta property="og:image">` | `curl -s <PROD> | grep -oE '<link rel=...>|<meta property="og:image"...>'` | All four tags present and resolvable | PASS |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
| ----------- | -------------- | ----------- | ------ | -------- |
| SITE-01 | 11-01, 11-02 | `/website` subdirectory with Next.js App Router + TypeScript, independent `package.json` | SATISFIED | `website/package.json` Next 16.2.4 + React 19 + TS strict; pnpm-lock.yaml only lockfile; Node 22 pinned in both layers; `@/*` alias mapped to `./src/*`; pnpm build exits 0 |
| SITE-02 | 11-03 | Site deploys to Vercel automatically on every push via GitHub integration | SATISFIED | Vercel GitHub App connected; commit `4c18d5f` on main shows Vercel status=success; deploy URL resolvable; integration live |
| SITE-03 | 11-03 | Each PR gets a preview-deployment URL | HUMAN_NEEDED | Vercel GitHub App installed and configured; no PRs exist yet to exercise preview behavior. See human_verification item 1. |
| SITE-04 | 11-02, 11-03 | Production site reachable at `ps-transcribe.vercel.app` from main | SATISFIED (with fallback) | Production live at `ps-transcribe-web.vercel.app` (fallback slug — canonical claimed externally). PROJECT.md commit `9afaffe` documents the substitution. Every production probe green. |
| SITE-05 | 11-01 | Repo `.gitignore` excludes website build artifacts (`.next/`, `node_modules/`) | SATISFIED | All four `website/...` patterns present in `.gitignore`; `git ls-files website/.next website/node_modules` returns 0 entries |

All 5 requirement IDs accounted for. No orphans (no extra REQ-IDs mapped to phase 11 in REQUIREMENTS.md beyond SITE-01..05). No requirements declared outside the plans' `requirements` frontmatter.

### Anti-Patterns Found

Scanned key phase files: layout.tsx, page.tsx, sitemap.ts, robots.ts, manifest.ts, opengraph-image.tsx, globals.css.

| File | Finding | Severity | Impact |
| ---- | ------- | -------- | ------ |
| `website/src/app/globals.css` | Default create-next-app color tokens untouched (`--background`, `--foreground`, `--font-geist-sans`, `--font-geist-mono`, dark-mode media query) | Info | Non-blocking. Phase 11 placeholder uses inline styles only — none of these globals.css tokens are consumed by `page.tsx` or `layout.tsx`. REQUIREMENTS.md DESIGN-04 explicitly requires light-mode only; the leftover `@media (prefers-color-scheme: dark)` block should be removed when phase 12 ports the Chronicle palette. Not in phase 11 scope per D-12 ("Tailwind plumbing only — token config lands in phase 12"). |
| `website/AGENTS.md` | Contains stale Geist/Geist_Mono tokens in `@theme inline` block (same as globals.css) | Info | Auto-generated by create-next-app. Kept as-is per 11-01-SUMMARY decision to commit scaffold authoritative output. |
| None | No TODO/FIXME/placeholder comments | — | — |
| None | No empty implementations (`return null`, `return []`, etc.) beyond intentional placeholder copy | — | — |
| None | No hardcoded-empty props or stub state | — | — |

No blockers. One informational item (`globals.css` cleanup deferred to phase 12) is outside phase 11 scope.

### Human Verification Required

#### 1. PR preview URL (SITE-03)

**Test:** Open a PR on `cnewfeldt/ps-transcribe` that touches any file under `website/` and wait ~30 seconds after push.
**Expected:** A comment from the `vercel[bot]` account appears on the PR containing a preview URL in the form `https://ps-transcribe-web-git-<branch>-<user>.vercel.app`. The URL returns 200 and renders the branch's build of the Chronicle placeholder (possibly different from main if the branch changed page.tsx).
**Why human:** No PR has been opened yet (`gh pr list` → `[]`). The Vercel GitHub App OAuth completed during Plan 11-03 Task 1, and the first production build succeeded, so the integration is fully wired — but the preview-URL comment is only produced when a PR exists. This is inherent to GitHub PR workflow, not a gap in the phase deliverables.
**Deferred trigger:** First PR touching `/website`. Phase 12 (design system port) is expected to open the first such PR.

#### 2. Ignored Build Step skip behavior (D-09)

**Test:** Push a commit to main that modifies only files under `PSTranscribe/`, `scripts/`, `.planning/`, `assets/`, or repo root (no files under `website/`). Wait ~30 seconds and inspect the Vercel project → Deployments list.
**Expected:** A new deployment row appears with status "Ignored Build Step" / Canceled. No new production build runs.
**Why human:** Phase 11 deliberately only contains commits that touch `/website`, so the skip condition has not been exercised yet. The Ignored Build Step command was verified correctly configured in the Vercel dashboard during Plan 11-03 Task 1 Step 8 (`git diff HEAD^ HEAD --quiet -- .` — evaluated from inside Root Directory, per RESEARCH.md Pitfall 2). The behavioral verification is naturally deferred to the first Swift-only commit.
**Deferred trigger:** First Swift-only commit on main post phase 11 close.

### Gaps Summary

**No blocking gaps.** Every roadmap success criterion and every plan-level must-have is either verified end-to-end against the live production deploy (13 of 14) or covered by an installed integration whose observable behavior requires a natural trigger that didn't exist at phase close (1 of 14 — SITE-03 PR preview URL).

The SITE-03 deferral is structural, not a defect. Vercel's preview-URL emission fires on PR creation; phase 11 hasn't produced a PR because all phase commits landed directly on main per the Wave execution model. The Vercel GitHub App connection is proven live by the successful `Vercel` commit status check on the main deploy, so the plumbing is in place — only the observable event is pending.

The D-09 Ignored Build Step skip is likewise a natural-trigger deferral (no Swift-only commit exists in the phase 11 window). The command is configured correctly in the Vercel dashboard and the RESEARCH.md Pitfall 2 guidance was followed precisely, so the configuration is high-confidence correct.

**Deviations from the original plan** (all resolved and documented in plan summaries; none blocking):

> _D1 — Production slug._ `ps-transcribe-web.vercel.app` instead of `ps-transcribe.vercel.app` — canonical slug was claimed externally. PROJECT.md line 55 logs the substitution; plan 11-02 metadata URLs were patched in commit `4c18d5f` before the green deploy. **Status: RESOLVED.**
>
> _D2 — OG image URL._ Live URL is `/opengraph-image` (no `.png` suffix) — Next.js 16 serves it as a Route Handler with `content-type: image/png`, not a static file. The `<meta property="og:image">` tag correctly references the extension-less form. Plan 11-02 verification text said `/opengraph-image.png` which would 404; the summary flags this as Next.js 16 behavior, not a defect. Probe adjusted accordingly. **Status: RESOLVED.**
>
> _D3 — Favicon handoff._ `website/src/app/favicon.ico` was deleted in plan 11-02 so `icon.png` wins the `<link rel="icon">` slot. Plan 11-01's SUMMARY anticipated this (line "replaced by icon.png in plan 11-02"). Not a deviation — planned handoff. **Status: RESOLVED.**

---

_Verified: 2026-04-22_
_Verifier: Claude (gsd-verifier), Opus 4.7 (1M context)_
