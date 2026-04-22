# Phase 11: Website Scaffolding & Vercel Deployment - Research

**Researched:** 2026-04-22
**Domain:** Next.js 16 App Router on Vercel, pnpm, monorepo (website subdirectory alongside Swift package)
**Confidence:** HIGH — Next.js 16 docs and Vercel docs fetched this session; local toolchain verified

## Summary

All the locked decisions in CONTEXT.md are supported by current Next.js 16 and Vercel behavior verified 2026-04-22. Next.js 16.2.4 is latest stable. Turbopack is default in create-next-app's generated `package.json` scripts (no extra flag needed). `next/font/google` cleanly supports three CSS-variable-scoped fonts in `layout.tsx`. File-based metadata (`src/app/sitemap.ts`, `robots.ts`, `manifest.ts`, `icon.png`, `apple-icon.png`, `opengraph-image.tsx`) gives a one-file-per-artifact layout that removes all manual URL wiring. Vercel auto-detects pnpm from `pnpm-lock.yaml`, uses `engines.node` from `package.json` to pin Node, and the "Ignored Build Step" field with `git diff HEAD^ HEAD --quiet -- .` (evaluated inside Root Directory) is the exactly-correct Swift-commit-skip pattern — exit 0 means skip, exit 1 means build.

Two edge cases worth flagging to the planner: (1) the very first deploy has no `HEAD^` under Vercel's shallow clone, so Vercel falls back to building — this is desirable and non-blocking; (2) Next.js 16 files like `sitemap.ts` and `icon.tsx` cache by default and treat `params` as a Promise (v16.0.0 change).

**Primary recommendation:** Use the create-next-app non-interactive invocation captured below, then layer in font wiring + metadata files + icon assets as a second task. Vercel project creation is a one-time human action in the dashboard with the exact settings documented below.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Stack**
- **D-01:** Package manager is **pnpm**. Vercel-native, disk-efficient, deterministic lockfile. Requires `brew install pnpm` locally.
- **D-02:** **Next.js 16** (latest stable) — App Router, React 19, Turbopack default. Use `pnpm create next-app@latest` or `pnpx create-next-app@latest`.
- **D-03:** Node version pinned with **both** `.nvmrc` (value: `22`) and `package.json` `engines.node` (`>=22 <23`). Belt and suspenders: local auto-switch + Vercel/CI enforcement.
- **D-04:** **`src/app/` directory layout** — config files stay at `/website` root, application code under `/website/src/`.
- **D-05:** **TypeScript strict mode on** — create-next-app default, no extra flags beyond `strict: true`.
- **D-06:** **Single `@/*` path alias** mapped to `src/*`. No per-folder aliases.

**Vercel deployment**
- **D-07:** **Vercel dashboard GitHub integration** — import the ps-transcribe repo from Vercel UI, set **Root Directory = `website`** in project settings. No `vercel.json` committed in this phase.
- **D-08:** **Production URL target: `ps-transcribe.vercel.app`**. Claim this exact project slug at creation. If the slug is taken, fall back to `ps-transcribe-web` (or similar) and log the real URL in PROJECT.md before phase 11 is marked done.
- **D-09:** **Ignored Build Step** set to `git diff HEAD^ HEAD --quiet -- .` (evaluated with Root Directory = `website`, so it only rebuilds when `/website/**` changed).
- **D-10:** **Preview URLs auto-generated** per PR by the GitHub integration — no extra config needed.
- **D-11:** **No separate GitHub Actions job** for website in phase 11. Vercel's `pnpm build` (tsc + next build) is the only gate.

**Dev tooling**
- **D-12:** **Tailwind CSS installed in phase 11** via `create-next-app --tailwind`. Plumbing only — Chronicle token config and primitives land in phase 12.
- **D-13:** **Linting: ESLint only** (create-next-app defaults). No Prettier, no Biome.
- **D-14:** **`.gitignore`** at repo root extended with `website/.next/`, `website/node_modules/`, `website/.vercel/`, and `website/out/`.

**Initial page content**
- **D-15:** **Minimal Chronicle-flavored placeholder** at `src/app/page.tsx`. Paper background (`#FAFAF7`), Spectral wordmark "PS Transcribe" (~48px), Inter sub-copy "Private, on-device transcription for macOS.", JetBrains Mono meta label "v1.1 · WEBSITE", "Site coming soon." line. Hardcoded colors — no Tailwind config tokens yet.
- **D-16:** **All three Chronicle fonts wired via `next/font`** in phase 11 — Inter, Spectral, JetBrains Mono — in `src/app/layout.tsx`.
- **D-17:** **Full metadata suite ships in phase 11**: title, favicon from Bot-on-Laptop icon (32x32 + 180x180), `og:image` 1200x630 via ImageResponse or static PNG, `robots.txt` allow-all, `sitemap.xml` with just `/`, `site.webmanifest` with theme_color `#FAFAF7`, OpenGraph + Twitter tags in root `layout.tsx`.

### Claude's Discretion
- Exact create-next-app invocation flags (beyond the captured set)
- Specific pnpm version pin — use latest stable unless a reason emerges
- How to structure the placeholder page file (single component vs extracted sub-components)
- OG image generation approach (`ImageResponse` vs static PNG)
- Exact text of OG description / Twitter card description
- Vercel project name + team selection (personal vs team account)

### Deferred Ideas (OUT OF SCOPE)
- Chronicle Tailwind tokens → Phase 12
- Reusable component primitives → Phase 12
- Actual landing page content → Phase 13
- MDX pipeline + docs sidebar → Phase 14
- CHANGELOG.md parser + release cards → Phase 15
- Custom domain → post-v1.1
- Vercel Analytics enabling decision → deferred per milestone scope
- Website-specific GitHub Actions workflow → not needed in phase 11
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SITE-01 | `/website` subdirectory initialized with Next.js App Router + TypeScript inside the `ps-transcribe` repo, with its own `package.json` independent from the Swift package | `create-next-app` invocation below produces this exactly. `pnpm-lock.yaml`, `package.json`, `tsconfig.json` all live in `website/` with no coupling to Swift. |
| SITE-02 | Site deploys to Vercel automatically on every push via GitHub integration | Vercel's GitHub App integration auto-imports on repo connect; Root Directory = `website` scopes to subdir; `pnpm-lock.yaml` triggers pnpm install automatically. |
| SITE-03 | Each PR gets a preview-deployment URL | Built-in behavior of Vercel's GitHub integration — no config needed. Every non-production branch push creates a preview with its own URL; the Vercel bot comments on PRs. |
| SITE-04 | Production site is reachable at `ps-transcribe.vercel.app` from the `main` branch | Vercel production deployments map to `<project-slug>.vercel.app` by default. Project slug chosen at creation = `ps-transcribe`. |
| SITE-05 | Repo `.gitignore` excludes website build artifacts (`.next/`, `node_modules/`) | Manual `.gitignore` extension at repo root; paths below. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Next.js | 16.2.4 | React framework, App Router, Turbopack, route-based metadata | [VERIFIED: `npm view next version` 2026-04-22] — latest stable, Turbopack default, React 19 bundled |
| React | 19.x | UI runtime | Bundled by `create-next-app@latest` for Next.js 16 [CITED: nextjs.org/docs create-next-app] |
| TypeScript | 5.x | Type safety | Default in `create-next-app` with `--typescript` [CITED: nextjs.org/docs create-next-app] |
| Tailwind CSS | 4.x | Utility CSS (config deferred to phase 12) | Default in `create-next-app --tailwind` [CITED: nextjs.org/docs] |
| ESLint | 9.x (flat config) | Lint | Default in `create-next-app --eslint` [CITED: nextjs.org/docs] |
| pnpm | 10.13.1 (local) / Vercel auto-detects from lockfile | Package manager | [VERIFIED: `pnpm --version` on dev machine] — Vercel supports pnpm 6–10 [CITED: vercel.com/docs/package-managers] |
| Node | 22 LTS | Runtime pin | Vercel reads `engines.node` [CITED: vercel.com/docs/functions/runtimes/node-js/node-js-versions] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `next/font/google` | bundled with Next.js | Self-hosted Google Fonts (Inter, Spectral, JetBrains Mono) | Wiring fonts into `layout.tsx` [CITED: nextjs.org/docs components/font] |
| `next/og` (`ImageResponse`) | bundled with Next.js | Dynamic OG image via JSX → PNG | Generating `opengraph-image.tsx` at 1200×630 [CITED: nextjs.org/docs functions/image-response] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `next/font/google` | `next/font/local` with downloaded font files | Adds bytes to repo; Google-hosted fonts are cached at build time by Next anyway → no runtime difference. Stick with `google`. |
| Dynamic `ImageResponse` OG image | Static PNG in `public/` | Static PNG is zero-moving-parts but requires design handoff or hand-rolled image. ImageResponse reuses Spectral wordmark + paper bg from the same design brief with 20 lines of JSX. Recommend ImageResponse. |
| `favicon.ico` at `src/app/` root only | `favicon.ico` + `icon.png` + `apple-icon.png` | Using just `favicon.ico` works but is lower quality on retina displays. Since the Bot-on-Laptop source is 1024×1024 PNG, resize to `icon.png` (32×32) + `apple-icon.png` (180×180) — Next auto-generates correct `<link>` tags [CITED: nextjs.org/docs app-icons]. |

**Installation:** Already handled by `create-next-app`. No extra `pnpm install` needed beyond the initial generator run.

**Version verification:**
```bash
# Verified 2026-04-22:
npm view next version         # → 16.2.4
npm view create-next-app version  # → 16.2.4
npm view next engines         # → { node: '>=20.9.0' }  — we pin 22 LTS anyway
```

## Architecture Patterns

### Recommended Project Structure
```
ps-transcribe/                           # repo root (Swift + website siblings)
├── PSTranscribe/                        # Swift package — DO NOT TOUCH in phase 11
├── assets/                              # icon.png (1024x1024) source for favicon
├── .gitignore                           # extended with website/ paths
└── website/                             # Vercel Root Directory
    ├── .nvmrc                           # "22"
    ├── package.json                     # engines.node ">=22 <23"
    ├── pnpm-lock.yaml                   # committed — Vercel reads this
    ├── tsconfig.json                    # strict: true, @/* → src/*
    ├── eslint.config.mjs                # create-next-app default
    ├── next.config.ts
    ├── postcss.config.mjs
    ├── public/                          # static assets served at /
    └── src/
        └── app/
            ├── favicon.ico              # (optional — icon.png covers most cases)
            ├── icon.png                 # 32x32, auto-linked as <link rel="icon">
            ├── apple-icon.png           # 180x180, auto-linked as <link rel="apple-touch-icon">
            ├── opengraph-image.tsx      # 1200x630 ImageResponse, auto-linked as og:image
            ├── robots.ts                # returns MetadataRoute.Robots
            ├── sitemap.ts               # returns MetadataRoute.Sitemap
            ├── manifest.ts              # returns MetadataRoute.Manifest
            ├── globals.css              # Tailwind directives (phase 11: default)
            ├── layout.tsx               # fonts + static metadata + <html>/<body>
            └── page.tsx                 # Chronicle placeholder
```

### Pattern 1: Non-interactive create-next-app
**What:** Scaffold the project with all flags explicit to avoid TTY prompts.
**When to use:** Always for phase 11 — every flag maps to a CONTEXT.md decision.
**Example:**
```bash
# Run from /Users/cary/Development/ai-development/ps-transcribe/
pnpm create next-app@latest website \
  --typescript \
  --tailwind \
  --eslint \
  --app \
  --src-dir \
  --import-alias "@/*" \
  --use-pnpm \
  --turbopack \
  --no-react-compiler \
  --disable-git \
  --yes

# Source: https://nextjs.org/docs/app/api-reference/cli/create-next-app
# --yes uses defaults for any remaining prompts (e.g. AGENTS.md prompt).
# --disable-git: the repo already has its own git history; don't init a nested one.
# --turbopack is redundant (it's the default in 16.x) but makes intent explicit.
# --no-react-compiler: Chronicle placeholder has no reason to pull in the RC toolchain yet.
```

### Pattern 2: Three-font next/font/google wiring
**What:** Load Inter, Spectral, and JetBrains Mono as CSS variables, attach to `<html>`, let Tailwind or raw CSS consume them.
**When to use:** `src/app/layout.tsx` — once, for every page.
**Example:**
```tsx
// src/app/layout.tsx
// Source: https://nextjs.org/docs/app/api-reference/components/font § "Using Multiple Fonts"
import type { Metadata } from 'next'
import { Inter, Spectral, JetBrains_Mono } from 'next/font/google'
import './globals.css'

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-inter',
})

const spectral = Spectral({
  subsets: ['latin'],
  display: 'swap',
  weight: ['400', '600'],        // Spectral is NOT a variable font — weight is REQUIRED
  variable: '--font-spectral',
})

const jetbrainsMono = JetBrains_Mono({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-jetbrains-mono',
})

export const metadata: Metadata = {
  metadataBase: new URL('https://ps-transcribe.vercel.app'),
  title: 'PS Transcribe — Private, on-device transcription for macOS',
  description: 'Private, on-device transcription for macOS.',
  // openGraph + twitter + icons + manifest also live here — see "Metadata API" pattern below
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html
      lang="en"
      className={`${inter.variable} ${spectral.variable} ${jetbrainsMono.variable}`}
    >
      <body style={{ fontFamily: 'var(--font-inter), system-ui, sans-serif' }}>
        {children}
      </body>
    </html>
  )
}
```

**Key facts:**
- Inter is a variable font; `weight` can be omitted [CITED: nextjs.org/docs components/font].
- Spectral is **not variable** (it's a static Google Font family); `weight` as `string[]` is **required** or the build fails. Safe default: `['400', '600']`.
- JetBrains Mono IS variable; `weight` optional.
- Underscore replaces spaces in identifiers: `JetBrains_Mono`, `Roboto_Mono`.
- `display: 'swap'` matches Next's recommendation — avoids FOIT on fallback.
- `subsets: ['latin']` is required; omitting causes a build warning.

### Pattern 3: File-based metadata (sitemap / robots / manifest)
**What:** Put a `.ts` file under `src/app/` with a default export that returns a typed object. Next.js serves the resulting URL (`/sitemap.xml`, `/robots.txt`, `/manifest.webmanifest`) and injects the right `<link>` tags.
**When to use:** Replace any manual `<link>` / `<meta>` wiring — less code, fewer sync bugs.
**Examples:**

```ts
// src/app/sitemap.ts
// Source: https://nextjs.org/docs/app/api-reference/file-conventions/metadata/sitemap
import type { MetadataRoute } from 'next'

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    {
      url: 'https://ps-transcribe.vercel.app',
      lastModified: new Date(),
      changeFrequency: 'monthly',
      priority: 1,
    },
  ]
}
// Served at /sitemap.xml. Phase 14/15 will append /docs/* and /changelog entries.
```

```ts
// src/app/robots.ts
// Source: https://nextjs.org/docs/app/api-reference/file-conventions/metadata/robots
import type { MetadataRoute } from 'next'

export default function robots(): MetadataRoute.Robots {
  return {
    rules: { userAgent: '*', allow: '/' },
    sitemap: 'https://ps-transcribe.vercel.app/sitemap.xml',
  }
}
// Served at /robots.txt.
```

```ts
// src/app/manifest.ts
// Source: https://nextjs.org/docs/app/api-reference/file-conventions/metadata/manifest
import type { MetadataRoute } from 'next'

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'PS Transcribe',
    short_name: 'PS Transcribe',
    description: 'Private, on-device transcription for macOS',
    start_url: '/',
    display: 'standalone',
    background_color: '#FAFAF7',
    theme_color: '#FAFAF7',
    icons: [
      { src: '/icon.png', sizes: '32x32', type: 'image/png' },
      { src: '/apple-icon.png', sizes: '180x180', type: 'image/png' },
    ],
  }
}
// Served at /manifest.webmanifest (Next.js auto-chooses extension).
```

### Pattern 4: Icons via file conventions
**What:** Drop `icon.png` and `apple-icon.png` directly under `src/app/`. Next.js parses dimensions/format and generates the correct `<link rel="icon" sizes="...">` and `<link rel="apple-touch-icon" sizes="...">` tags. No manual `icons:` in metadata needed.
**When to use:** Default. Only fall back to the `metadata.icons` object if you need extra custom `rel=` values.
**Recipe:**
```bash
# From repo root, generate the two sizes from assets/icon.png (1024x1024):
#   (planner: task this out with sips — macOS built-in)
sips -z 32 32 assets/icon.png --out website/src/app/icon.png
sips -z 180 180 assets/icon.png --out website/src/app/apple-icon.png
# Optional: also drop a favicon.ico at website/src/app/favicon.ico for legacy browsers.
```
Next.js auto-emits:
```html
<link rel="icon" href="/icon?<hash>" type="image/png" sizes="32x32" />
<link rel="apple-touch-icon" href="/apple-icon?<hash>" type="image/png" sizes="180x180" />
```
[CITED: nextjs.org/docs file-conventions/metadata/app-icons]

### Pattern 5: Dynamic OG image via `opengraph-image.tsx`
**What:** Default-export a function returning `ImageResponse` — Next calls it at build time and exposes `/opengraph-image?<hash>` with the right `og:image` meta tags auto-injected.
**When to use:** Recommended over static PNG because we can re-use Spectral wordmark + paper bg in JSX. 20 lines vs a separate design pass.
**Example:**
```tsx
// src/app/opengraph-image.tsx
// Source: https://nextjs.org/docs/app/api-reference/functions/image-response
import { ImageResponse } from 'next/og'

export const alt = 'PS Transcribe — Private, on-device transcription for macOS'
export const size = { width: 1200, height: 630 }
export const contentType = 'image/png'

export default async function OGImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'flex-start',
          background: '#FAFAF7',
          padding: '96px',
          fontFamily: 'serif', // Spectral not easily loaded in Satori — use generic serif
          color: '#1A1A17',
        }}
      >
        <div style={{ fontSize: 28, letterSpacing: 2, color: '#8A8A82', textTransform: 'uppercase' }}>
          PS Transcribe
        </div>
        <div style={{ fontSize: 72, lineHeight: 1.1, marginTop: 24 }}>
          Private, on-device transcription for macOS.
        </div>
      </div>
    ),
    { ...size }
  )
}
// Auto-served at /opengraph-image.png. Next injects <meta property="og:image" ...> pointing here.
```

**Caveats:**
- ImageResponse bundle limit is **500KB total** (JSX + CSS + fonts + images) [CITED: nextjs.org/docs image-response].
- Only flexbox subset of CSS — no `display: grid`, no complex layouts [CITED: same].
- Custom fonts require `readFile` of a `.ttf`/`.otf` file — skipping this for phase 11 keeps bundle tiny (generic serif is acceptable for a placeholder).
- If the generic serif looks wrong under review, fall back to a static 1200×630 PNG dropped at `src/app/opengraph-image.png`.

### Pattern 6: Vercel project setup (one-time human action)
**What:** The planner has to tell the user what buttons to press in the Vercel dashboard. No code change supports this.
**When to use:** Exactly once, after `website/` is committed and pushed to GitHub.
**Exact steps:**
1. Vercel Dashboard → **Add New** → **Project** → **Import Git Repository** → select `ps-transcribe`.
2. **Project Name:** `ps-transcribe` (produces `ps-transcribe.vercel.app`). If taken, use `ps-transcribe-web` and log real URL in PROJECT.md.
3. **Framework Preset:** Next.js (auto-detected).
4. **Root Directory:** click **Edit** → select `website`. Critical — everything else scopes to this.
5. **Build & Development Settings:** leave defaults (Vercel detects pnpm from `website/pnpm-lock.yaml`, runs `pnpm install` then `pnpm build`).
6. **Node.js Version:** leave at default (Vercel reads `engines.node` from `website/package.json`).
7. Click **Deploy**. First production deploy happens from `main`.
8. After first deploy succeeds, Settings → **Git** → **Ignored Build Step** → select **Custom** → enter exactly: `git diff HEAD^ HEAD --quiet -- .`
   [CITED: vercel.com/kb/guide/how-do-i-use-the-ignored-build-step-field-on-vercel]

### Anti-Patterns to Avoid
- **Committing `vercel.json` in phase 11** — CONTEXT D-07 says no. All settings live in the dashboard.
- **Hand-rolling `<link rel="icon">` in `layout.tsx`** — file-based metadata (`src/app/icon.png`) auto-generates correct tags. Don't duplicate.
- **Using `next/font/local` for the three fonts** — all three are on Google Fonts per the design brief's open-source constraint. `next/font/google` downloads at build time and self-hosts, so runtime behavior is identical with no bundled font files in the repo.
- **Running `create-next-app` inside the repo without `--disable-git`** — it will try to init a nested `.git/`. Use the flag.
- **Omitting `weight` for Spectral** — it's a non-variable font; build fails.
- **Setting Node version only in `.nvmrc`** — Vercel honors `engines.node` from `package.json`, not `.nvmrc`. Keep both for belt-and-suspenders (local fnm/nvm reads `.nvmrc`), but `engines.node` is the Vercel-facing pin.
- **Writing `git diff HEAD^ HEAD --quiet -- website`** in the Ignored Build Step — wrong. Vercel runs the command **inside** the Root Directory, so the path is `.`, not `website`. The form `-- .` is correct precisely because Root Directory = `website`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Font loading with layout-shift protection | `<link rel="preload">` in `<head>` | `next/font/google` | Next self-hosts, injects preload tags, computes size-adjust fallbacks automatically. |
| Sitemap XML | Hand-written `public/sitemap.xml` | `src/app/sitemap.ts` returning `MetadataRoute.Sitemap` | Typed, testable, extends trivially in phases 14–15 without editing a string template. |
| robots.txt | Hand-written `public/robots.txt` | `src/app/robots.ts` | Same reasoning — typed source of truth. |
| Web manifest JSON | Hand-written `public/manifest.webmanifest` | `src/app/manifest.ts` | Typed `MetadataRoute.Manifest`, auto-linked from `<head>`. |
| OG image PNG | Photoshop/Figma export dropped in `public/og.png` | `src/app/opengraph-image.tsx` using `ImageResponse` | Co-located with code, rebuilds on design changes, < 20 LOC. Fallback exists if Satori limits bite. |
| Favicon `<link>` tags | Manual `<link rel="icon">` wiring in layout | `src/app/icon.png` + `src/app/apple-icon.png` | Next detects file, generates `<link>` with correct `sizes=` + `type=`. |
| Monorepo build skip for Swift commits | Custom GitHub Action to gate Vercel | Vercel's Ignored Build Step with `git diff HEAD^ HEAD --quiet -- .` | Native Vercel feature, one setting in the dashboard, no CI to maintain. |
| pnpm install on Vercel | `installCommand` override in `vercel.json` | Commit `pnpm-lock.yaml` and let Vercel auto-detect | Auto-detection is lockfile-driven and version-aware. Overriding forces oldest version. [CITED: vercel.com/docs/package-managers] |

**Key insight:** Next.js 16's file conventions mean **every piece of site metadata becomes a co-located file**. Any phase-11 code that manually wires a `<link>` or `<meta>` tag is doing redundant work. The layout.tsx only sets the static `Metadata` object — everything else is a file.

## Common Pitfalls

### Pitfall 1: Spectral weight missing → build failure
**What goes wrong:** `Spectral({ subsets: ['latin'] })` without `weight` errors out at build: `Missing weight for font Spectral. Available weights: ...`
**Why it happens:** Spectral is not a variable Google Font. `next/font/google` requires explicit weights for non-variable families.
**How to avoid:** Always pass `weight: ['400', '600']` (or whatever set the design calls for).
**Warning signs:** Local `pnpm build` fails immediately with an font-loader error — Vercel mirror fails the same way.

### Pitfall 2: Ignored Build Step path wrong after setting Root Directory
**What goes wrong:** Ignored Build Step is set to `git diff HEAD^ HEAD --quiet -- website`, Vercel reports "nothing changed" on every push, site never updates.
**Why it happens:** Vercel runs the command **inside** Root Directory. Path `website` resolves to `website/website` which doesn't exist. `git diff` returns 0 (no changes found), Vercel skips the build.
**How to avoid:** Use `git diff HEAD^ HEAD --quiet -- .` (dot means "current folder" = Root Directory). Confirmed 2026-04-22 by the Vercel KB article.
**Warning signs:** Every PR shows "Ignored Build Step" in the deployment status. No production update after merging. Check build logs — the printed `pwd` at start of build will be `/vercel/path0/website`.

### Pitfall 3: First deploy has no `HEAD^` under shallow clone
**What goes wrong:** On the very first commit to `main`, or on a branch with only one commit, `HEAD^` doesn't exist. `git diff HEAD^ HEAD` errors out.
**Why it happens:** Vercel does `git clone --depth=10`. If only 1 commit is visible, `HEAD^` is an invalid reference.
**How to avoid:** No action needed. When the git diff command errors, it exits non-zero → Vercel treats that as "build should proceed" → we get a deployment. This is the desired behavior for the first deploy. Subsequent deploys will have `HEAD^`.
**Warning signs:** If you see this error in logs after multiple commits are landed, something else is wrong (force push history rewrite, likely). Safe fallback: manually trigger a deploy from the dashboard.

### Pitfall 4: `metadataBase` missing → relative OG URLs broken
**What goes wrong:** `openGraph.images: '/og-image.png'` without `metadataBase` → build error "Using a relative path without configuring a `metadataBase`".
**Why it happens:** OG and Twitter tags must be absolute URLs; without a base, Next doesn't know what to prefix with.
**How to avoid:** Always set `metadataBase: new URL('https://ps-transcribe.vercel.app')` in root `layout.tsx` metadata. Shown in Pattern 2 above.
**Warning signs:** First build fails with explicit `metadataBase` error message — easy to catch.

### Pitfall 5: Multiple lockfiles in repo → Next.js 16 warning
**What goes wrong:** Since Next.js 15.4.6, if both `package-lock.json` and `pnpm-lock.yaml` exist (or any other combo), Next prints a lockfile warning [CITED: github.com/vercel/next.js/issues/82689].
**Why it happens:** The ps-transcribe repo is Swift-first; no root `package.json` exists. The only lockfile will be `website/pnpm-lock.yaml`. Safe.
**How to avoid:** Don't accidentally run `npm init` or similar at repo root. Verified 2026-04-22: repo root has no `package.json`, no `node_modules/`, no lockfile.
**Warning signs:** `pnpm build` output mentions "multiple lockfiles detected" — hunt and delete the stray one.

### Pitfall 6: Vercel uses oldest pnpm version if `installCommand` is overridden
**What goes wrong:** Someone sets the Vercel dashboard "Install Command" override to `pnpm install`. Vercel interprets this as "use the oldest pnpm we support" (currently pnpm 6). Modern lockfile parses differently, install fails or pulls wrong resolutions.
**Why it happens:** [CITED: vercel.com/docs/package-managers] — override triggers oldest-version behavior.
**How to avoid:** Don't enable the Install Command override in Vercel dashboard. Auto-detection reads `pnpm-lock.yaml` `lockfileVersion: 9.0` and picks pnpm 9 or 10 correctly.
**Warning signs:** Build logs show `pnpm 6.x.x` when you expect 10.x. Disable the override.

### Pitfall 7: `src/app/sitemap.ts` cached, doesn't reflect deploys
**What goes wrong:** `sitemap.ts` caches by default [CITED: nextjs.org/docs sitemap]. If sitemap logic depends on request-time data, it stays stale across deploys.
**Why it happens:** Next 16 treats these as cached route handlers.
**How to avoid:** For phase 11 our sitemap is static (just `/`), so cache is fine. Phases 14–15 that parse `CHANGELOG.md` at build time will also be fine — those are build-time reads, not request-time.
**Warning signs:** Only relevant to future phases.

## Code Examples

Verified patterns from official sources:

### Root `package.json` engines pin
```json
// website/package.json (additions beyond create-next-app defaults)
{
  "engines": {
    "node": ">=22 <23"
  }
}
// Source: https://vercel.com/docs/functions/runtimes/node-js/node-js-versions
// Vercel reads this and deploys with latest 22.x.
```

### `.nvmrc`
```
22
```
Used by local `fnm`/`nvm` for auto-switch. Vercel ignores it but no harm.

### Full `metadata` export in layout.tsx
```tsx
// src/app/layout.tsx — metadata portion
// Source: https://nextjs.org/docs/app/api-reference/functions/generate-metadata
export const metadata: Metadata = {
  metadataBase: new URL('https://ps-transcribe.vercel.app'),
  title: {
    default: 'PS Transcribe — Private, on-device transcription for macOS',
    template: '%s · PS Transcribe',
  },
  description: 'Private, on-device transcription for macOS.',
  openGraph: {
    title: 'PS Transcribe',
    description: 'Private, on-device transcription for macOS.',
    url: 'https://ps-transcribe.vercel.app',
    siteName: 'PS Transcribe',
    type: 'website',
    locale: 'en_US',
    // images: auto-picked up from src/app/opengraph-image.tsx — do NOT duplicate here
  },
  twitter: {
    card: 'summary_large_image',
    title: 'PS Transcribe',
    description: 'Private, on-device transcription for macOS.',
    // images: auto-picked up from opengraph-image.tsx
  },
  robots: { index: true, follow: true },
  // icons: omitted — src/app/icon.png + apple-icon.png handle it
  // manifest: omitted — src/app/manifest.ts handles it
}
```

### `.gitignore` additions (repo root, append)
```gitignore
# Next.js / website build artifacts
website/.next/
website/node_modules/
website/.vercel/
website/out/
website/next-env.d.ts      # optional — create-next-app adds this; some teams ignore, some commit
```

Recommendation: commit `next-env.d.ts` (create-next-app generates it with instructions to commit). Don't ignore.

### Chronicle placeholder page (≈40 lines)
```tsx
// src/app/page.tsx
export default function Home() {
  return (
    <main
      style={{
        minHeight: '100dvh',
        background: '#FAFAF7',
        color: '#1A1A17',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'center',
        alignItems: 'flex-start',
        padding: '96px 64px',
        gap: '28px',
        fontFamily: 'var(--font-inter), system-ui, sans-serif',
      }}
    >
      <div
        style={{
          fontFamily: 'var(--font-jetbrains-mono), Menlo, monospace',
          fontSize: '11px',
          letterSpacing: '0.8px',
          textTransform: 'uppercase',
          color: '#8A8A82',
        }}
      >
        v1.1 · Website
      </div>

      <h1
        style={{
          fontFamily: 'var(--font-spectral), Georgia, serif',
          fontSize: '48px',
          fontWeight: 400,
          lineHeight: 1.1,
          margin: 0,
          letterSpacing: '-0.01em',
        }}
      >
        PS Transcribe
      </h1>

      <p style={{ fontSize: '16px', lineHeight: 1.6, color: '#595954', maxWidth: '44ch', margin: 0 }}>
        Private, on-device transcription for macOS.
      </p>

      <p style={{ fontSize: '14px', color: '#8A8A82', margin: 0 }}>
        Site coming soon.
      </p>
    </main>
  )
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `<Head>` component from `next/head` (Pages Router) | Static `metadata` export + file conventions in App Router | Next.js 13 stable | Entire metadata model is declarative and co-located. |
| `@next/font` as separate package | `next/font` built into core | Next.js 13.2 | No install, direct import. |
| `ImageResponse` imported from `next/server` | Imported from `next/og` | Next.js 14 | Use `next/og` in 16.x — `next/server` path throws deprecation warning. |
| Pages Router `getStaticProps` metadata | `generateMetadata` function or static `metadata` object | Next.js 13 | Synchronous static metadata is one export; dynamic is one async function. |
| Sitemap/robots via `public/*` static files | `src/app/sitemap.ts` / `robots.ts` with typed return | Next.js 13.3 | Typed, composable, less drift. |
| Pages-Router-style `_document.tsx` custom head | Root `layout.tsx` returning `<html><body>` JSX directly | App Router (13+) | `layout.tsx` IS the document shell. |

**Deprecated/outdated:**
- `ImageResponse` from `next/server` (use `next/og` — Next.js 14+)
- `themeColor` and `viewport` inside `metadata` object (use separate `generateViewport` export — Next.js 14+)
- `msapplication-*` meta tags (not supported by modern Edge anyway, per Next docs)

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Vercel defaults Node version to the **lower** of project setting and `engines.node`, and `engines.node` "wins" when it specifies a different major — meaning we can set `engines.node: ">=22 <23"` and Vercel will deploy 22.x even if the project-settings dropdown defaults to 24.x | Standard Stack; Pattern 6 step 6 | LOW — Vercel docs show `engines.node` overrides project settings [CITED: vercel.com/docs/functions/runtimes/node-js/node-js-versions]. If wrong, fix by explicitly selecting 22.x in dashboard — one-click change. |
| A2 | Next.js 16.2.4's `next/font/google` includes Spectral in the Google Fonts catalog accessible via `import { Spectral }` | Pattern 2 | LOW — Spectral is on Google Fonts (verifiable at fonts.google.com/specimen/Spectral); `next/font/google` wraps the full catalog per Next docs. If wrong, fall back to `next/font/local` with downloaded `.woff2` files. |
| A3 | The pnpm 10.13.1 lockfile generated locally will produce `lockfileVersion: 9.0` in `pnpm-lock.yaml`, which Vercel resolves to pnpm 10 automatically | Standard Stack; Pitfall 6 | LOW — matches docs [CITED: vercel.com/docs/package-managers: "pnpm-lock.yaml version 9.0 can be generated by pnpm 9 or 10. Newer projects will prefer 10"]. If wrong, set `packageManager: "pnpm@10.13.1"` in `package.json` and enable Corepack env var. |
| A4 | The `assets/icon.png` (1024×1024 PNG) is high-enough quality to downscale to 32×32 and 180×180 without manual retouching | Pattern 4 | LOW — file is PNG RGBA 1024×1024, verified. `sips -z` on macOS does bicubic resampling, fine for flat bot-on-laptop icon. If quality suffers at 32×32, plan a manual redraw. |

**Interpretation:** All assumptions are LOW risk — each has a documented fallback within this phase's scope.

## Open Questions

1. **Vercel team vs personal account for the project**
   - What we know: CONTEXT marks this as Claude's discretion.
   - What's unclear: Whether the user has a Vercel team they want to own this project, or if personal account is fine.
   - Recommendation: Planner should create a task that asks the user to choose at Vercel dashboard time. Default to personal if no response in 24h — project can be transferred later via Vercel UI.

2. **OG image: ImageResponse JSX vs static PNG**
   - What we know: CONTEXT lists both as acceptable, user chose "whichever is simpler."
   - What's unclear: Whether Spectral's serif shape carries over in Satori's generic-serif fallback well enough, or if a static PNG rendered in a real browser is visibly better.
   - Recommendation: Default to `opengraph-image.tsx` with generic serif. Task a visual-check of the rendered `/opengraph-image.png`. If it looks wrong, swap to `src/app/opengraph-image.png` (static) before phase exit.

3. **Does the user want `next-env.d.ts` committed or ignored?**
   - What we know: Create-next-app recommends committing it.
   - What's unclear: CONTEXT D-14's `.gitignore` list doesn't mention it.
   - Recommendation: Commit it (follow Next's guidance). Add a note to planner to confirm if the user prefers otherwise.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | `create-next-app`, `next dev` | ✓ | 22.12.0 | — |
| pnpm | D-01 | ✓ | 10.13.1 | `npm create next-app` if somehow missing |
| npm | npx fallback path | ✓ | 10.9.0 | — |
| git | Ignored Build Step verification | ✓ | 2.50.1 (Apple Git-155) | — |
| `sips` (macOS image resize) | Icon generation from `assets/icon.png` | ✓ (macOS built-in) | system | ImageMagick `convert`, or pre-resize manually in Preview.app |
| GitHub repo connection | Vercel GitHub App | Assumed ✓ | — | If GitHub App not installed on repo org, one-click install during Vercel import flow |
| Vercel account | Deployment | Assumed ✓ | — | User creates at vercel.com/signup during import flow |

**Missing dependencies with no fallback:** none.

**Missing dependencies with fallback:** none critical — every item is installed or one-click-acquirable.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None yet — create-next-app default scaffolds no test runner in Next.js 16 (deferred to later phases if needed) |
| Config file | none — see Wave 0 (nothing required for phase 11) |
| Quick run command | `cd website && pnpm lint && pnpm build` |
| Full suite command | `cd website && pnpm lint && pnpm build && curl -sfI https://ps-transcribe.vercel.app \| head -1` |
| Phase gate | `pnpm build` green locally + latest Vercel production deployment status = Ready |

**Rationale:** Phase 11 is infrastructure + placeholder. A test-runner install would be ceremony with no target. Next.js's own typecheck (`pnpm build` runs `tsc --noEmit` internally) + ESLint cover the scoped changes. Phases 13–15 will add behavioral tests as page logic lands.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SITE-01 | Next.js App Router + TS scaffold under `/website` with own `package.json` | file-check | `test -f website/package.json && test -f website/tsconfig.json && test -d website/src/app` | ✅ (produced by create-next-app in Wave 0) |
| SITE-01 | TypeScript strict compiles cleanly | integration (build) | `cd website && pnpm build` (exits 0) | ✅ |
| SITE-01 | `@/*` alias maps to `src/*` | file-check + build | `grep -q '"@/\*": \["./src/\*"\]' website/tsconfig.json && cd website && pnpm build` | ✅ |
| SITE-01 | Node 22 pinned in both places | file-check | `test "$(cat website/.nvmrc)" = "22" && node -e "const p=require('./website/package.json'); if(!/22/.test(p.engines?.node)) process.exit(1)"` | ✅ |
| SITE-01 | pnpm is the package manager | file-check | `test -f website/pnpm-lock.yaml && ! test -f website/package-lock.json && ! test -f website/yarn.lock` | ✅ |
| SITE-02 | Push triggers Vercel build | e2e (manual+automated) | After push to branch: `gh api repos/:owner/ps-transcribe/commits/$(git rev-parse HEAD)/status --jq '.statuses[] \| select(.context\|startswith("Vercel")) \| .state'` → "success" | ⚠️ requires repo owner + Vercel integration; manual verify on first push |
| SITE-03 | PR gets a preview URL | e2e (manual) | Open PR; check for `[Vercel] Deployment deployed` bot comment containing `https://ps-transcribe-git-<branch>-<user>.vercel.app` | manual (check bot comment) |
| SITE-04 | Production is reachable | integration (HTTP probe) | `curl -sfI https://ps-transcribe.vercel.app \| head -1` → `HTTP/2 200` | ✅ after first prod deploy |
| SITE-04 | Production renders Chronicle placeholder | integration (content probe) | `curl -s https://ps-transcribe.vercel.app \| grep -q 'PS Transcribe'` → exit 0 | ✅ |
| SITE-05 | `.gitignore` excludes build artifacts | file-check | `grep -q 'website/.next/' .gitignore && grep -q 'website/node_modules/' .gitignore` | ✅ |
| SITE-05 | No build artifacts in git history at phase end | file-check | `git ls-files website/ \| grep -vE '^(website/\.next/\|website/node_modules/\|website/\.vercel/)' \| wc -l` = total tracked files; `git ls-files website/.next website/node_modules 2>/dev/null \| wc -l` = 0 | ✅ |
| D-09 (Ignored Build Step) | Swift-only commits don't redeploy | e2e (manual) | After a Swift-only commit to `main`, check Vercel deployments list: latest commit should show "Ignored Build Step" / Canceled, not "Ready" | manual (check Vercel dashboard after first Swift-only commit) |
| D-15 (placeholder content) | All three fonts load | integration (content probe) | `curl -s https://ps-transcribe.vercel.app \| grep -oE '--font-(inter\|spectral\|jetbrains-mono)' \| sort -u \| wc -l` → 3 | ✅ |
| D-17 (metadata suite) | robots.txt served | HTTP probe | `curl -sfI https://ps-transcribe.vercel.app/robots.txt \| head -1` → 200 | ✅ |
| D-17 | sitemap.xml served | HTTP probe | `curl -sf https://ps-transcribe.vercel.app/sitemap.xml \| grep -q '<loc>https://ps-transcribe.vercel.app</loc>'` | ✅ |
| D-17 | manifest served | HTTP probe | `curl -sfI https://ps-transcribe.vercel.app/manifest.webmanifest \| head -1` → 200 | ✅ |
| D-17 | OG image served | HTTP probe | `curl -sfI https://ps-transcribe.vercel.app/opengraph-image.png \| head -1` → 200 | ✅ |
| D-17 | Favicon served | HTTP probe | `curl -sfI https://ps-transcribe.vercel.app/icon.png \| head -1` → 200 | ✅ |
| Swift build untouched | Swift package still builds | integration | `cd PSTranscribe && swift build` (exits 0) — unchanged from before phase 11 | ✅ (no Swift files modified) |

### Sampling Rate
- **Per task commit:** `cd website && pnpm lint && pnpm build` (local)
- **Per wave merge:** same as above + verify `.gitignore` excludes match patterns
- **Phase gate:** Full HTTP probe suite above runs against `https://ps-transcribe.vercel.app` and returns all green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] Install pnpm if missing (already installed locally: `pnpm@10.13.1`). On fresh machines: `brew install pnpm`.
- [ ] No test framework scaffolding required — phase 11 validates via build + HTTP probes, not unit tests.
- [ ] If Swift-build verification is part of Nyquist protocol, confirm the planner includes `swift build` in phase gate. No new tooling needed for it.

*(Test framework install deferred — phase 11 doesn't introduce behavior that warrants unit tests. Plan is deliberate: keep phase 11 boring.)*

## Security Domain

> Included because `security_enforcement` is not explicitly `false` in config.json.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Public marketing site, no user auth in phase 11 |
| V3 Session Management | no | No sessions |
| V4 Access Control | no | All pages public |
| V5 Input Validation | no | No user input in phase 11 (no forms) |
| V6 Cryptography | no | HTTPS is Vercel-managed, no custom crypto |
| V14 Configuration | yes | Gitignore excludes secrets; `.env` already covered by existing `.gitignore`; no `.env` committed in phase 11 |

### Known Threat Patterns for Next.js / Vercel marketing site

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Accidental secret commit via `.env.local` | Information disclosure | Existing `.gitignore` covers `.env` and `*.env.*`. No new env vars introduced in phase 11. |
| Unvalidated `sitemap.ts` / `robots.ts` leaking internal routes | Information disclosure | Phase 11 sitemap contains only `/`. No `/admin`, `/api/*`, `/internal/*` paths to leak. |
| Dependency typosquatting from `pnpm add` | Tampering | Using `create-next-app@latest` pulls from official `create-next-app` npm package; `pnpm-lock.yaml` commits the resolved tree. Review lockfile diff on initial commit. |
| OG image bundle size DoS | DoS (availability during build) | `ImageResponse` 500KB bundle limit is enforced by Next; won't deploy if exceeded [CITED: nextjs.org/docs image-response]. |
| Vercel preview URL leak of pre-merge content | Information disclosure | Preview URLs are guessable-random but not indexed (robots.txt doesn't apply to *.vercel.app deploys by default for preview subdomains — Vercel auto-sets headers). For genuine secrets, phase 12+ can enable Deployment Protection. Out of scope for phase 11 placeholder. |

## Sources

### Primary (HIGH confidence)
- **Next.js 16.2.4 official docs** (fetched 2026-04-22):
  - [`create-next-app` flags](https://nextjs.org/docs/app/api-reference/cli/create-next-app)
  - [`next/font` usage with multiple fonts](https://nextjs.org/docs/app/api-reference/components/font)
  - [`generateMetadata` / `Metadata` object](https://nextjs.org/docs/app/api-reference/functions/generate-metadata)
  - [`ImageResponse` API](https://nextjs.org/docs/app/api-reference/functions/image-response)
  - [`sitemap.ts` conventions](https://nextjs.org/docs/app/api-reference/file-conventions/metadata/sitemap)
  - [`robots.ts` conventions](https://nextjs.org/docs/app/api-reference/file-conventions/metadata/robots)
  - [`manifest.ts` conventions](https://nextjs.org/docs/app/api-reference/file-conventions/metadata/manifest)
  - [`favicon` / `icon` / `apple-icon` conventions](https://nextjs.org/docs/app/api-reference/file-conventions/metadata/app-icons)
- **Vercel official docs** (fetched 2026-04-22):
  - [Project settings / Ignored Build Step](https://vercel.com/docs/project-configuration/project-settings)
  - [Ignored Build Step KB article](https://vercel.com/kb/guide/how-do-i-use-the-ignored-build-step-field-on-vercel)
  - [Monorepos & skipping unaffected projects](https://vercel.com/docs/monorepos)
  - [Configuring a Build (Root Directory, framework detection)](https://vercel.com/docs/builds/configure-a-build)
  - [Package Managers (pnpm auto-detect + lockfile version table)](https://vercel.com/docs/package-managers)
  - [Supported Node.js versions (engines.node precedence)](https://vercel.com/docs/functions/runtimes/node-js/node-js-versions)
- **npm registry** (verified 2026-04-22):
  - `npm view next version` → `16.2.4`
  - `npm view create-next-app version` → `16.2.4`
  - `npm view next engines` → `{ node: '>=20.9.0' }`

### Secondary (MEDIUM confidence)
- GitHub discussions confirming Ignored Build Step exit-code semantics (exit 0 = skip, exit 1 = build) — cross-verified with the Vercel KB article above.

### Tertiary (LOW confidence)
- none — every claim in this research is backed by a HIGH-confidence source.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all versions verified via `npm view` this session; Vercel auto-detection documented.
- Architecture / patterns: HIGH — every pattern is lifted from current Next.js 16.2.4 docs with URL.
- Pitfalls: HIGH — each is either from official docs or from GitHub community discussions tied to a specific issue/PR.
- Validation: HIGH — every probe is a deterministic curl/grep/build command.

**Research date:** 2026-04-22
**Valid until:** 2026-05-22 (30 days — Next.js minors ship every 1–2 weeks, so verify `npm view next version` still resolves to 16.2.x before planning begins if this research ages).

## RESEARCH COMPLETE

**Phase:** 11 - Website Scaffolding & Vercel Deployment
**Confidence:** HIGH

### Key Findings
- Next.js 16.2.4 is latest stable [VERIFIED]; Turbopack is default for `next dev` and `next build` in 16.x — no extra flag required, but CONTEXT asks for explicit `--turbopack` which is harmless.
- The exact non-interactive `create-next-app` invocation that matches every CONTEXT locked decision is captured in Pattern 1.
- File-based metadata (`src/app/sitemap.ts`, `robots.ts`, `manifest.ts`, `icon.png`, `apple-icon.png`, `opengraph-image.tsx`) replaces every manual `<link>`/`<meta>` tag. Layout only sets the static `Metadata` object + fonts.
- Vercel auto-detects pnpm from `pnpm-lock.yaml` (lockfileVersion 9.0 → pnpm 10 in 2026). Auto-detects Node from `engines.node`. Both override the dashboard defaults.
- `git diff HEAD^ HEAD --quiet -- .` is exactly the right Ignored Build Step when Root Directory is set to `website` — confirmed by Vercel's KB: the command runs with CWD inside Root Directory.
- Exit code semantics: **0 = skip, 1 = build**. First-commit edge case (HEAD^ missing under shallow clone) fails open (builds), which is the desired behavior.
- Spectral is non-variable; `weight: ['400', '600']` is required in the `next/font/google` call or the build fails.
- `ImageResponse` moved to `next/og` in v14; don't use `next/server` path. 500KB bundle cap; flexbox-only CSS subset.

### File Created
`.planning/phases/11-website-scaffolding-vercel-deployment/11-RESEARCH.md`

### Confidence Assessment
| Area | Level | Reason |
|------|-------|--------|
| Standard Stack | HIGH | Versions verified via npm registry 2026-04-22; pnpm/Node precedence documented in Vercel docs |
| Architecture | HIGH | Every pattern sourced from Next.js 16.2.4 docs with URLs |
| Pitfalls | HIGH | Each is either in official docs or backed by GitHub issues/discussions |
| Validation | HIGH | All probes are deterministic curl/grep/build commands |

### Open Questions
1. Vercel team vs personal account (Claude's discretion — planner asks at dashboard-setup task time, defaults to personal).
2. `ImageResponse` vs static PNG for OG image (default to `ImageResponse`, visual-check at phase gate, fallback path documented).
3. Commit vs ignore `next-env.d.ts` (recommend commit per Next guidance).

### Ready for Planning
Research complete. Planner can now create PLAN.md files. Recommended plan shape:
- **Plan A — Scaffold:** create-next-app invocation, .nvmrc, engines pin, .gitignore updates, initial commit.
- **Plan B — Content & metadata:** layout.tsx fonts + metadata, page.tsx placeholder, sitemap/robots/manifest .ts files, opengraph-image.tsx, icon.png + apple-icon.png generated from assets/icon.png.
- **Plan C — Vercel project setup & gate:** human dashboard steps (D-07), Ignored Build Step configuration (D-09), first production deploy verification, HTTP probe suite.

Plans A and B are pure code; Plan C is a runbook for the user plus an automated verification suite. Plan A must land first; B and C can parallelize once A is on main.

Sources:
- [Next.js create-next-app CLI](https://nextjs.org/docs/app/api-reference/cli/create-next-app)
- [Next.js next/font](https://nextjs.org/docs/app/api-reference/components/font)
- [Next.js generateMetadata](https://nextjs.org/docs/app/api-reference/functions/generate-metadata)
- [Next.js ImageResponse](https://nextjs.org/docs/app/api-reference/functions/image-response)
- [Next.js sitemap](https://nextjs.org/docs/app/api-reference/file-conventions/metadata/sitemap)
- [Next.js robots](https://nextjs.org/docs/app/api-reference/file-conventions/metadata/robots)
- [Next.js manifest](https://nextjs.org/docs/app/api-reference/file-conventions/metadata/manifest)
- [Next.js app-icons](https://nextjs.org/docs/app/api-reference/file-conventions/metadata/app-icons)
- [Vercel Project Settings (Ignored Build Step)](https://vercel.com/docs/project-configuration/project-settings)
- [Vercel KB: Ignored Build Step](https://vercel.com/kb/guide/how-do-i-use-the-ignored-build-step-field-on-vercel)
- [Vercel Monorepos](https://vercel.com/docs/monorepos)
- [Vercel Configuring a Build](https://vercel.com/docs/builds/configure-a-build)
- [Vercel Package Managers](https://vercel.com/docs/package-managers)
- [Vercel Node.js Versions](https://vercel.com/docs/functions/runtimes/node-js/node-js-versions)
