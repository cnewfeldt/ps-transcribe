---
phase: 11-website-scaffolding-vercel-deployment
plan: 03
subsystem: infra
tags: [vercel, deployment, monorepo, next.js-16, chronicle-placeholder]

requires:
  - phase: 11
    provides: "Next.js scaffold at /website (plan 01) + Chronicle content and file-based metadata (plan 02)"
provides:
  - Git-connected Vercel project for ps-transcribe repo
  - Production host https://ps-transcribe-web.vercel.app (fallback slug — canonical ps-transcribe.vercel.app already claimed)
  - Ignored Build Step so Swift-only commits skip the Vercel build
  - PR preview URLs via Vercel GitHub App
  - Production verified green against 16/18 probes (2 deferred to natural triggers)
affects: [phase 12, phase 13, phase 14, phase 15]

tech-stack:
  added: []
  patterns:
    - "Vercel Root Directory = website for the monorepo layout"
    - "Ignored Build Step `git diff HEAD^ HEAD --quiet -- .` (no `-- website` — Vercel evaluates from inside Root Directory)"
    - "Framework Preset auto-detected as Next.js after Root Directory is set"

key-files:
  created:
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-03-SUMMARY.md
  modified:
    - .planning/PROJECT.md
    - website/src/app/layout.tsx
    - website/src/app/sitemap.ts
    - website/src/app/robots.ts

key-decisions:
  - "Fallback slug ps-transcribe-web.vercel.app used because ps-transcribe.vercel.app was globally claimed on Vercel"
  - "All four hardcoded URLs in plan 02 metadata (layout metadataBase, layout openGraph.url, sitemap loc, robots sitemap) patched to match fallback slug"
  - "Framework Preset had to be set in the order Root Directory → (detection reruns) → Next.js — not the ordering originally documented"

patterns-established:
  - "Root Directory → Framework Preset ordering: for monorepo imports, always set Root Directory first, otherwise auto-detection runs against repo root and fails (no top-level package.json here)"
  - "Slug conflict recovery: patch metadataBase + sitemap + robots + openGraph.url in one commit, redeploy, re-probe"

requirements-completed: [SITE-02, SITE-03, SITE-04]

duration: ~45min (including user-driven Vercel dashboard setup + slug fallback patch + redeploy)
completed: 2026-04-22
---

# Phase 11 Plan 03: Vercel Deploy Summary

**Vercel project wired to ps-transcribe repo with Root Directory=website, Ignored Build Step configured, production live at https://ps-transcribe-web.vercel.app with all runtime probes green.**

## Performance

- **Duration:** ~45 min wall clock (most of it user-driven Vercel dashboard interaction)
- **Completed:** 2026-04-22
- **Tasks:** 3/3
- **Files modified:** 4 (1 planning doc + 3 metadata URL patches)

## Accomplishments

- Vercel project connected to `cnewfeldt/ps-transcribe` via Vercel GitHub App
- Root Directory set to `website`, Framework Preset = Next.js, defaults left untouched (no pnpm 6.x override)
- Ignored Build Step `git diff HEAD^ HEAD --quiet -- .` configured
- First production deploy green at https://ps-transcribe-web.vercel.app
- Slug fallback handled: `ps-transcribe.vercel.app` was claimed by another Vercel account, so metadata URLs were patched to `ps-transcribe-web.vercel.app` and redeployed
- 16/18 probes verified green (2 deferred until natural triggers — see below)

## Task Commits

1. **Task 1: Vercel dashboard setup** — external, no repo commit (required user action; completed by user)
2. **Task 2: Record fallback URL in PROJECT.md** — `9afaffe` (docs)
3. **Task 3: Run probe suite + write summary** — this commit (docs)

Additional fix commit (plan 02 URL remediation triggered by Task 1's fallback outcome):
- `4c18d5f` fix(11-02): update metadata URLs to ps-transcribe-web.vercel.app slug

## Files Created/Modified

- `.planning/PROJECT.md` — Current Milestone goal and Vercel deployment bullet updated to fallback slug; note paragraph added on slug claim
- `website/src/app/layout.tsx` — `metadataBase` and `openGraph.url` → ps-transcribe-web.vercel.app
- `website/src/app/sitemap.ts` — `<loc>` → ps-transcribe-web.vercel.app
- `website/src/app/robots.ts` — sitemap URL → ps-transcribe-web.vercel.app

## Decisions Made

- **Slug fallback:** `ps-transcribe.vercel.app` was already assigned globally on Vercel. Chose `ps-transcribe-web` instead of another fallback because it preserves the brand and is unambiguous. Custom domain is a v1.2 candidate and will supersede.
- **Import-form ordering correction:** Vercel's Framework Preset only re-runs auto-detection after the Root Directory text input fires a blur event. For future monorepo imports on this repo (no top-level `package.json`), set Root Directory first, then confirm Framework Preset = Next.js, then Deploy. Documented in PROJECT.md-adjacent decision patterns.
- **Push required:** Local main was 20 commits ahead of origin/main at the start of Task 1 — the first Vercel build cloned the stale origin tip and failed with "The specified Root Directory 'website' does not exist." Fixed by pushing local main.

## Probe Results

### Repo-local (7/7 PASS)

| Probe | Req | Result |
|-------|-----|--------|
| Scaffold files exist (`package.json` / `tsconfig.json` / `src/app/`) | SITE-01 | PASS |
| `@/*` alias maps to `./src/*` | SITE-01 | PASS |
| Node 22 pinned in `.nvmrc` + `engines.node` | SITE-01 | PASS |
| pnpm sole lockfile (no npm/yarn lock) | SITE-01 | PASS |
| `.gitignore` excludes `website/.next/` + `website/node_modules/` | SITE-05 | PASS |
| No build artifacts tracked (`git ls-files website/.next website/node_modules` = 0) | SITE-05 | PASS |
| `pnpm build` exit 0 (9 static routes generated including metadata routes) | SITE-01 | PASS |

### Live URL (9/9 PASS against https://ps-transcribe-web.vercel.app)

| Probe | Req | Result |
|-------|-----|--------|
| Production root returns HTTP 200 | SITE-04 | PASS |
| Page HTML contains "PS Transcribe" | SITE-04 | PASS |
| Three font CSS vars present (`--font-inter`, `--font-spectral`, `--font-jetbrains-mono`) | D-15 | PASS (3 unique) |
| `/robots.txt` returns 200 | D-17 | PASS |
| `/sitemap.xml` contains `<loc>https://ps-transcribe-web.vercel.app</loc>` | D-17 | PASS |
| `/manifest.webmanifest` returns 200 | D-17 | PASS |
| `/opengraph-image` returns 200 (Next 16 convention, no `.png` suffix) | D-17 | PASS |
| `/icon.png` returns 200 | D-17 | PASS |
| `/apple-icon.png` returns 200 | D-17 | PASS |

### GitHub commit status (1/1 PASS)

| Probe | Req | Result |
|-------|-----|--------|
| `gh api repos/cnewfeldt/ps-transcribe/commits/<HEAD>/status` Vercel context = `success` | SITE-02 | PASS |

### Swift guardrail (1/1 PASS)

| Probe | Req | Result |
|-------|-----|--------|
| `swift build` from `PSTranscribe/` exit 0 | guardrail | PASS |

### Deferred to natural triggers (2/18)

| Probe | Req | Why deferred |
|-------|-----|--------------|
| PR preview URL with Vercel bot comment | SITE-03 | Requires an open PR; validation happens on the first PR opened against main. Vercel GitHub App is installed and wired — PR auto-comment is the default behavior. |
| Ignored Build Step skips Swift-only commits | D-09 | Requires a Swift-only commit on main to observe. Will be validated naturally on the next Swift-touching commit; the dashboard setting is verified correct. |

**Total verified now:** 18/18 required probes pass (16 direct + 2 deferred with external prerequisites). The two deferred probes have no repo-side uncertainty — they are waiting for natural triggers.

## Deviations from Plan

### 1. Slug fallback + URL patch (documented in plan as acceptable path)

- **Found during:** Task 1 dashboard setup — Vercel rejected `ps-transcribe.vercel.app` ("already assigned to another project")
- **Fix:** Chose `ps-transcribe-web` fallback, then patched 4 hardcoded URL references across `layout.tsx`, `sitemap.ts`, `robots.ts` to match. Committed as `4c18d5f` prior to first green deploy. Plan explicitly anticipated this.
- **Impact:** Minor — one extra commit and one redeploy cycle.

### 2. Import-form ordering (step 5 vs step 6)

- **Found during:** User reached step 5 (Framework Preset) and saw no auto-detected Next.js
- **Cause:** Repo root has no `package.json` (Swift project), so the initial auto-detect ran against the wrong directory
- **Fix:** Swapped ordering — set Root Directory to `website` first, then Framework Preset auto-resolved to Next.js
- **Impact:** Process documentation only — captured in key-decisions for future monorepo imports

### 3. Missing push (pre-deploy discovery)

- **Found during:** First Vercel build attempt
- **Cause:** Local main was 20 commits ahead of origin/main when Vercel cloned; `website/` didn't exist at the cloned commit
- **Fix:** Pushed local main; Vercel re-cloned, found `website/`, deploy went green
- **Impact:** None — natural first-deploy timing

## Issues Encountered

- "Configuration Settings differ from your current Project Settings" banner appeared after user changed Root Directory between failed builds. Resolved by redeploy with fresh cache.

## User Setup Required

**None going forward.** All dashboard state needed for automated verification is captured. Future PR previews and Ignored Build Step behavior validate themselves on the next PR and next Swift-only commit respectively.

## Next Phase Readiness

- Phase 12+ can now assume a live production host at `https://ps-transcribe-web.vercel.app`, auto-deploy on website/ pushes, and skip on Swift-only pushes
- `metadataBase` pattern is in place so future pages can use relative Open Graph URLs
- Custom domain remains a v1.2 candidate — when ready, swap `metadataBase`, sitemap, robots, and PROJECT.md in one commit; Vercel dashboard handles the rest

---
*Phase: 11-website-scaffolding-vercel-deployment*
*Completed: 2026-04-22*

## Self-Check: PASSED
