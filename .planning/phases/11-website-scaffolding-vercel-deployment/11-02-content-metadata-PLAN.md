---
phase: 11
plan: 02
type: execute
wave: 2
depends_on: [01]
files_modified:
  - website/src/app/layout.tsx
  - website/src/app/page.tsx
  - website/src/app/sitemap.ts
  - website/src/app/robots.ts
  - website/src/app/manifest.ts
  - website/src/app/opengraph-image.tsx
  - website/src/app/icon.png
  - website/src/app/apple-icon.png
autonomous: true
requirements:
  - SITE-01
  - SITE-04
tags:
  - nextjs
  - fonts
  - metadata
  - placeholder
  - seo
must_haves:
  truths:
    - "Visiting `/` renders the Chronicle placeholder: paper background #FAFAF7, Spectral wordmark 'PS Transcribe', Inter sub-copy 'Private, on-device transcription for macOS.', JetBrains Mono meta label 'v1.1 · WEBSITE', and 'Site coming soon.' line"
    - "All three fonts (Inter, Spectral, JetBrains Mono) load via next/font/google as CSS custom properties on every page"
    - "Requesting `/sitemap.xml` returns XML containing `<loc>https://ps-transcribe.vercel.app</loc>`"
    - "Requesting `/robots.txt` returns a 200 with allow-all rules"
    - "Requesting `/manifest.webmanifest` returns JSON with theme_color `#FAFAF7`"
    - "Requesting `/opengraph-image.png` returns a 1200x630 PNG"
    - "Requesting `/icon.png` returns a 32x32 PNG (favicon)"
    - "Requesting `/apple-icon.png` returns a 180x180 PNG"
    - "`<title>` on `/` is 'PS Transcribe — Private, on-device transcription for macOS'"
  artifacts:
    - path: "website/src/app/layout.tsx"
      provides: "Root layout with next/font/google CSS-var wiring for Inter, Spectral, JetBrains Mono + static Metadata export"
      contains: "Spectral"
    - path: "website/src/app/page.tsx"
      provides: "Chronicle placeholder home page — ~40 lines of JSX with hardcoded colors"
      contains: "Site coming soon"
    - path: "website/src/app/sitemap.ts"
      provides: "MetadataRoute.Sitemap with single entry for /"
      contains: "https://ps-transcribe.vercel.app"
    - path: "website/src/app/robots.ts"
      provides: "MetadataRoute.Robots allow-all"
      contains: "allow: '/'"
    - path: "website/src/app/manifest.ts"
      provides: "MetadataRoute.Manifest with theme_color #FAFAF7"
      contains: "#FAFAF7"
    - path: "website/src/app/opengraph-image.tsx"
      provides: "1200x630 ImageResponse OG image with Spectral wordmark and paper background"
      contains: "1200"
    - path: "website/src/app/icon.png"
      provides: "32x32 favicon — auto-generates <link rel='icon'> tag"
    - path: "website/src/app/apple-icon.png"
      provides: "180x180 Apple touch icon — auto-generates <link rel='apple-touch-icon'> tag"
  key_links:
    - from: "website/src/app/layout.tsx"
      to: "next/font/google"
      via: "Inter, Spectral, JetBrains_Mono imports with CSS variable bindings on <html>"
      pattern: "className=.*variable"
    - from: "website/src/app/page.tsx"
      to: "CSS variables from layout"
      via: "var(--font-spectral), var(--font-inter), var(--font-jetbrains-mono) in inline style"
      pattern: "var\\(--font-(spectral|inter|jetbrains-mono)"
    - from: "website/src/app/manifest.ts"
      to: "website/src/app/icon.png + apple-icon.png"
      via: "icons array references /icon.png and /apple-icon.png"
      pattern: "/icon.png"
---

<objective>
Turn the scaffolded `/website/` into a Chronicle-flavored placeholder by wiring the three Chronicle fonts via `next/font/google`, replacing `page.tsx` with the ~40-line Chronicle placeholder JSX (D-15), and shipping the full Next.js 16 file-based metadata suite (D-17): `sitemap.ts`, `robots.ts`, `manifest.ts`, `opengraph-image.tsx`, and the two icon sizes resized from `assets/icon.png`.

Purpose: Prove that webfont loading, metadata routing, and icon conventions all work end-to-end before Plan 03 deploys to Vercel. De-risks phase 12 (which assumes font plumbing works) and phases 13–15 (which append to `sitemap.ts`).

Output:
- `src/app/layout.tsx` rewritten with three-font next/font wiring + full static Metadata export (including metadataBase)
- `src/app/page.tsx` rewritten as the Chronicle placeholder (hardcoded `#FAFAF7`, Spectral 48px wordmark, Inter sub-copy, JetBrains Mono meta label)
- `src/app/sitemap.ts` returning single-entry sitemap
- `src/app/robots.ts` returning allow-all
- `src/app/manifest.ts` returning web manifest with `#FAFAF7` theme_color
- `src/app/opengraph-image.tsx` returning 1200x630 ImageResponse
- `src/app/icon.png` (32x32, resized from `assets/icon.png`)
- `src/app/apple-icon.png` (180x180, resized from `assets/icon.png`)
- `pnpm build` passes; `curl` probes against `pnpm start` locally return expected headers/content
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/phases/11-website-scaffolding-vercel-deployment/11-CONTEXT.md
@.planning/phases/11-website-scaffolding-vercel-deployment/11-RESEARCH.md
@.planning/phases/11-website-scaffolding-vercel-deployment/11-VALIDATION.md
@.planning/research/CLAUDE-DESIGN-BRIEF.md

<interfaces>
<!-- next/font/google contract (Next.js 16.2.x) — extracted from RESEARCH.md §Pattern 2 -->
<!-- Executor uses these directly; do NOT explore next/font source. -->

From `next/font/google`:
```typescript
// Inter — variable font, weight optional
Inter({ subsets: ['latin'], display: 'swap', variable: '--font-inter' })

// Spectral — NON-VARIABLE, weight REQUIRED (build fails if omitted)
Spectral({ subsets: ['latin'], display: 'swap', weight: ['400', '600'], variable: '--font-spectral' })

// JetBrains_Mono — variable font, weight optional. Identifier uses underscore.
JetBrains_Mono({ subsets: ['latin'], display: 'swap', variable: '--font-jetbrains-mono' })
```

From `next/og`:
```typescript
import { ImageResponse } from 'next/og'  // NOT next/server (deprecated)

// opengraph-image.tsx file conventions:
export const alt: string
export const size: { width: number, height: number }  // must be 1200x630 for OG
export const contentType: 'image/png'
export default async function OGImage(): Promise<ImageResponse>
```

From `next` (MetadataRoute types):
```typescript
import type { MetadataRoute, Metadata } from 'next'

MetadataRoute.Sitemap  // array of { url, lastModified?, changeFrequency?, priority? }
MetadataRoute.Robots   // { rules: { userAgent, allow?, disallow? }, sitemap?: string }
MetadataRoute.Manifest // { name, short_name, description, start_url, display, background_color, theme_color, icons: [...] }
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Rewrite layout.tsx with three-font next/font wiring + full Metadata export</name>
  <files>website/src/app/layout.tsx</files>
  <read_first>
    - website/src/app/layout.tsx (current scaffolded version — see what create-next-app generated before replacing)
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-CONTEXT.md §decisions D-16 (three fonts) and D-17 (full metadata suite including metadataBase)
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-RESEARCH.md §Pattern 2 "Three-font next/font/google wiring" (exact import syntax, Spectral weight requirement)
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-RESEARCH.md §Pitfall 1 "Spectral weight missing → build failure" and §Pitfall 4 "metadataBase missing → relative OG URLs broken"
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-RESEARCH.md §Code Examples "Full metadata export in layout.tsx"
  </read_first>
  <action>
Replace the entire contents of `website/src/app/layout.tsx` with the following (verbatim — every weight array, every string, every CSS variable name is load-bearing):

```tsx
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
  weight: ['400', '600'],
  variable: '--font-spectral',
})

const jetbrainsMono = JetBrains_Mono({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-jetbrains-mono',
})

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
  },
  twitter: {
    card: 'summary_large_image',
    title: 'PS Transcribe',
    description: 'Private, on-device transcription for macOS.',
  },
  robots: { index: true, follow: true },
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

CRITICAL constraints (do NOT paraphrase or change):
- **Spectral `weight: ['400', '600']`** — REQUIRED. Spectral is non-variable; omitting this fails the build per RESEARCH.md Pitfall 1.
- **`metadataBase: new URL('https://ps-transcribe.vercel.app')`** — REQUIRED. Absent → build errors on relative OG URLs per RESEARCH.md Pitfall 4.
- **Do NOT include `icons:` or `manifest:` keys in metadata** — file conventions (`src/app/icon.png`, `src/app/manifest.ts`) auto-inject these. Duplication is the anti-pattern called out in RESEARCH.md §Don't Hand-Roll.
- **Do NOT include `openGraph.images` or `twitter.images`** — `opengraph-image.tsx` auto-registers as the OG image per RESEARCH.md Pattern 5.
- **Import identifier `JetBrains_Mono`** — underscore, not space, not hyphen (RESEARCH.md Pattern 2).
- **Import `Metadata` type from `'next'`** — not from `'next/types'`.
- **`lang="en"`** — matches `openGraph.locale: 'en_US'`.

After writing, run `cd website && pnpm build` — MUST exit 0. Any build failure in this task means either a weight is missing or metadataBase is misplaced; fix inline, do not defer.
  </action>
  <verify>
    <automated>cd /Users/cary/Development/ai-development/ps-transcribe/website && grep -q "weight: \['400', '600'\]" src/app/layout.tsx && grep -q "metadataBase: new URL('https://ps-transcribe.vercel.app')" src/app/layout.tsx && grep -q "JetBrains_Mono" src/app/layout.tsx && grep -q "variable: '--font-inter'" src/app/layout.tsx && grep -q "variable: '--font-spectral'" src/app/layout.tsx && grep -q "variable: '--font-jetbrains-mono'" src/app/layout.tsx && ! grep -q "icons:" src/app/layout.tsx && ! grep -q "manifest:" src/app/layout.tsx && pnpm build</automated>
  </verify>
  <acceptance_criteria>
    - `website/src/app/layout.tsx` imports `Inter`, `Spectral`, `JetBrains_Mono` from `next/font/google`
    - Spectral call includes `weight: ['400', '600']` (exact match — single-quoted, in that order)
    - `metadataBase: new URL('https://ps-transcribe.vercel.app')` appears verbatim
    - The three CSS variables `--font-inter`, `--font-spectral`, `--font-jetbrains-mono` all declared
    - `<html>` element has `className` combining all three `font.variable` values
    - `<body>` style uses `var(--font-inter), system-ui, sans-serif` as `fontFamily`
    - Metadata `title.default` is exactly `'PS Transcribe — Private, on-device transcription for macOS'` (em dash, not double hyphen)
    - Metadata `title.template` is exactly `'%s · PS Transcribe'`
    - Metadata does NOT contain an `icons:` key (auto-injected from file conventions)
    - Metadata does NOT contain a `manifest:` key (auto-injected from manifest.ts)
    - Metadata does NOT contain `openGraph.images` or `twitter.images` (auto-injected from opengraph-image.tsx)
    - `cd website && pnpm build` exits 0 (proves all three font loaders resolve, metadataBase valid)
  </acceptance_criteria>
  <done>Layout renders three-font CSS variables on `<html>`, full static Metadata declared (including metadataBase), no icons/manifest/images duplication. Build passes.</done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Rewrite page.tsx with Chronicle placeholder content</name>
  <files>website/src/app/page.tsx</files>
  <read_first>
    - website/src/app/page.tsx (current scaffolded version — full replacement incoming)
    - website/src/app/layout.tsx (verify CSS variables `--font-inter`, `--font-spectral`, `--font-jetbrains-mono` are declared per Task 1)
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-CONTEXT.md §decisions D-15 (exact placeholder content: `#FAFAF7` background, Spectral wordmark "PS Transcribe" ~48px, Inter sub-copy "Private, on-device transcription for macOS.", JetBrains Mono meta label "v1.1 · WEBSITE", "Site coming soon." line)
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-RESEARCH.md §Code Examples "Chronicle placeholder page"
    - .planning/research/CLAUDE-DESIGN-BRIEF.md §Palette and §Typography (confirms `#FAFAF7` = paper, `#1A1A17` = ink, `#595954` = inkMuted, `#8A8A82` = inkFaint — these appear as hardcoded hex values per D-15 since Tailwind tokens are deferred to phase 12)
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-CONTEXT.md §specifics ("Meta label style: `v1.1 · WEBSITE` in JetBrains Mono, uppercase, 0.5 letter-spacing, inkFaint color")
  </read_first>
  <action>
Replace the entire contents of `website/src/app/page.tsx` with the following (verbatim — every hex color, every pixel value, every string literal is locked by D-15):

```tsx
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

      <p
        style={{
          fontSize: '16px',
          lineHeight: 1.6,
          color: '#595954',
          maxWidth: '44ch',
          margin: 0,
        }}
      >
        Private, on-device transcription for macOS.
      </p>

      <p style={{ fontSize: '14px', color: '#8A8A82', margin: 0 }}>
        Site coming soon.
      </p>
    </main>
  )
}
```

Locked values per D-15 (do NOT substitute synonyms — these exact strings are grep targets in validation):
- Meta label text: `v1.1 · Website` (middle-dot U+00B7 between `v1.1` and `Website`, capital W in "Website" in source — CSS `textTransform: uppercase` makes it render as `V1.1 · WEBSITE`)
- Hero text: `PS Transcribe`
- Sub-copy: `Private, on-device transcription for macOS.`
- Closing line: `Site coming soon.`
- Paper bg: `#FAFAF7` (hex literal — no Tailwind class, no CSS var)
- Ink: `#1A1A17`
- inkMuted (sub-copy color): `#595954`
- inkFaint (meta label + closing line color): `#8A8A82`
- Spectral size: `48px` (D-15 says "~48px" — exactly 48)
- Meta label size: `11px` (matches Chronicle brief §Typography "bubble-style content in the app uses 10pt mono … 0.5 letter-spacing" — 11px with 0.8px letter-spacing is the calibrated marketing variant from 11-CONTEXT.md §specifics)

Do NOT add Tailwind classes in this plan — phase 12 handles the token-to-Tailwind port. Hardcoded hex colors are intentional per D-15.
Do NOT add any additional visual elements (no logo, no button, no image, no footer — the placeholder is deliberately sparse).
Do NOT wrap the content in any additional layout primitives (no header, no container) — `<main>` as the flex root is the full page.
  </action>
  <verify>
    <automated>cd /Users/cary/Development/ai-development/ps-transcribe/website && grep -q "background: '#FAFAF7'" src/app/page.tsx && grep -q "PS Transcribe" src/app/page.tsx && grep -q "Private, on-device transcription for macOS\." src/app/page.tsx && grep -q "Site coming soon\." src/app/page.tsx && grep -q "v1\.1 · Website" src/app/page.tsx && grep -q "var(--font-spectral)" src/app/page.tsx && grep -q "var(--font-jetbrains-mono)" src/app/page.tsx && grep -q "var(--font-inter)" src/app/page.tsx && grep -q "fontSize: '48px'" src/app/page.tsx && pnpm build</automated>
  </verify>
  <acceptance_criteria>
    - `website/src/app/page.tsx` default-exports a function `Home` that returns a `<main>` element
    - File contains literal string `#FAFAF7` (paper background per D-15)
    - File contains literal string `PS Transcribe` (hero text)
    - File contains literal string `Private, on-device transcription for macOS.` (sub-copy — exact including period)
    - File contains literal string `Site coming soon.` (closing line)
    - File contains literal string `v1.1 · Website` (meta label source text)
    - File contains literal string `fontSize: '48px'` (Spectral hero sized per D-15)
    - File uses `var(--font-spectral)` for the `<h1>` font-family
    - File uses `var(--font-jetbrains-mono)` for the meta label font-family
    - File uses `var(--font-inter)` for the `<main>` default font-family
    - File contains literal `#1A1A17` (ink primary)
    - File contains literal `#595954` (inkMuted — used on sub-copy)
    - File contains literal `#8A8A82` (inkFaint — used on meta label and closing line)
    - File does NOT contain any Tailwind class names (no `className="..."` except what's in layout) — verify: `! grep -q 'className=' src/app/page.tsx` passes
    - `cd website && pnpm build` exits 0
  </acceptance_criteria>
  <done>Home page renders the exact Chronicle placeholder specified in D-15. Build passes.</done>
</task>

<task type="auto" tdd="false">
  <name>Task 3: Ship file-based metadata suite (sitemap.ts, robots.ts, manifest.ts)</name>
  <files>website/src/app/sitemap.ts, website/src/app/robots.ts, website/src/app/manifest.ts</files>
  <read_first>
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-CONTEXT.md §decisions D-17 (full metadata suite — exact requirements: robots allow-all, sitemap listing `/`, manifest with theme_color `#FAFAF7`)
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-RESEARCH.md §Pattern 3 "File-based metadata (sitemap / robots / manifest)" (exact type signatures and examples)
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-RESEARCH.md §Pitfall 7 "sitemap.ts cached" (OK for phase 11 — static `/` only)
  </read_first>
  <action>
Create three new files, each ~10-25 lines. Every URL, every field name is locked — copy verbatim.

**File 1 — `website/src/app/sitemap.ts`:**

```ts
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
```

Served at `/sitemap.xml`. Phases 14–15 will append `/docs/*` and `/changelog` entries. For phase 11, a single entry for the root URL is sufficient per D-17 ("sitemap.xml = auto-generated listing `/` for now").

**File 2 — `website/src/app/robots.ts`:**

```ts
import type { MetadataRoute } from 'next'

export default function robots(): MetadataRoute.Robots {
  return {
    rules: { userAgent: '*', allow: '/' },
    sitemap: 'https://ps-transcribe.vercel.app/sitemap.xml',
  }
}
```

Served at `/robots.txt`. Allow-all per D-17 ("site is public marketing").

**File 3 — `website/src/app/manifest.ts`:**

```ts
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
```

Served at `/manifest.webmanifest`. `theme_color: '#FAFAF7'` locked by D-17 ("site.webmanifest = app name + theme_color #FAFAF7"). The `icons` array references the PNGs generated in Task 4 below — they live at `website/src/app/icon.png` and `website/src/app/apple-icon.png` per Next.js file conventions, served at `/icon.png` and `/apple-icon.png` (Next strips `src/app/` when generating URLs).

Constraints:
- Do NOT add `robots.ts` disallow entries for `/api/*` or `/admin/*` — no such routes exist in phase 11 (confirmed in RESEARCH.md §Security Domain: "Phase 11 sitemap contains only `/`. No `/admin`, `/api/*`, `/internal/*` paths to leak.").
- Do NOT hard-code `lastModified` in sitemap — `new Date()` evaluates at build time, giving a fresh timestamp per deploy (acceptable per RESEARCH.md Pitfall 7 since sitemap is static).
- Do NOT use a different URL than `https://ps-transcribe.vercel.app` — this is the production target per D-08. If the slug is taken during Plan 03 Vercel setup, Plan 03 handles the URL fallback and returns here to edit these three files.

After all three files exist, run `cd website && pnpm build` — MUST exit 0. Then run `cd website && pnpm start &` in background, wait 3 seconds, and probe:

```bash
curl -sfI http://localhost:3000/robots.txt | head -1  # HTTP/1.1 200 OK
curl -sf http://localhost:3000/sitemap.xml | grep -q '<loc>https://ps-transcribe.vercel.app</loc>'
curl -sfI http://localhost:3000/manifest.webmanifest | head -1  # HTTP/1.1 200 OK
```

Kill the background server after probes (`kill %1` or similar). If any probe fails, the metadata file has an error — fix before proceeding.
  </action>
  <verify>
    <automated>cd /Users/cary/Development/ai-development/ps-transcribe/website && test -f src/app/sitemap.ts && test -f src/app/robots.ts && test -f src/app/manifest.ts && grep -q "https://ps-transcribe.vercel.app" src/app/sitemap.ts && grep -q "userAgent: '\*'" src/app/robots.ts && grep -q "theme_color: '#FAFAF7'" src/app/manifest.ts && grep -q "background_color: '#FAFAF7'" src/app/manifest.ts && pnpm build</automated>
  </verify>
  <acceptance_criteria>
    - `website/src/app/sitemap.ts` exists and default-exports a function returning `MetadataRoute.Sitemap`
    - `sitemap.ts` contains literal `https://ps-transcribe.vercel.app` (URL for the sole entry)
    - `sitemap.ts` contains `priority: 1` for the root entry
    - `website/src/app/robots.ts` exists and default-exports a function returning `MetadataRoute.Robots`
    - `robots.ts` contains `userAgent: '*'` and `allow: '/'`
    - `robots.ts` contains the sitemap URL `https://ps-transcribe.vercel.app/sitemap.xml`
    - `website/src/app/manifest.ts` exists and default-exports a function returning `MetadataRoute.Manifest`
    - `manifest.ts` contains `theme_color: '#FAFAF7'` (exact string — D-17 lock)
    - `manifest.ts` contains `background_color: '#FAFAF7'`
    - `manifest.ts` `icons` array references `/icon.png` (32x32) and `/apple-icon.png` (180x180)
    - `cd website && pnpm build` exits 0
    - HTTP probe `curl -sfI http://localhost:3000/robots.txt` returns 200 (or equivalent during local `pnpm start`)
    - HTTP probe `curl -sf http://localhost:3000/sitemap.xml` contains the literal substring `<loc>https://ps-transcribe.vercel.app</loc>`
    - HTTP probe `curl -sfI http://localhost:3000/manifest.webmanifest` returns 200
  </acceptance_criteria>
  <done>Three metadata-route files exist and serve correctly under local `pnpm start`. Build passes.</done>
</task>

<task type="auto" tdd="false">
  <name>Task 4: Generate icon.png + apple-icon.png from assets/icon.png, ship opengraph-image.tsx</name>
  <files>website/src/app/icon.png, website/src/app/apple-icon.png, website/src/app/opengraph-image.tsx</files>
  <read_first>
    - /Users/cary/Development/ai-development/ps-transcribe/assets/icon.png (verify source file exists at 1024x1024 — `file assets/icon.png` should report PNG image data)
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-CONTEXT.md §decisions D-17 (favicon from "Bot on Laptop" at 32x32 + 180x180; OG image 1200x630 via ImageResponse OR static PNG)
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-RESEARCH.md §Pattern 4 "Icons via file conventions" (sips recipe)
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-RESEARCH.md §Pattern 5 "Dynamic OG image via `opengraph-image.tsx`" (full example + 500KB bundle / flexbox-only caveats)
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-RESEARCH.md §Open Questions #2 (ImageResponse vs static PNG — default to ImageResponse, document fallback)
  </read_first>
  <action>
Three artifacts, in order:

**Artifact 1 — Generate `website/src/app/icon.png` (32x32):**

```bash
cd /Users/cary/Development/ai-development/ps-transcribe
sips -z 32 32 assets/icon.png --out website/src/app/icon.png
```

`sips` is macOS built-in (verified in RESEARCH.md §Environment Availability). `-z H W` resamples bicubic to the given pixel dimensions. Source `assets/icon.png` is 1024x1024 PNG per Task read_first verification — downscale quality is fine for a flat bot-on-laptop mark.

**Artifact 2 — Generate `website/src/app/apple-icon.png` (180x180):**

```bash
cd /Users/cary/Development/ai-development/ps-transcribe
sips -z 180 180 assets/icon.png --out website/src/app/apple-icon.png
```

Next.js 16 auto-detects both files by name and emits:
```html
<link rel="icon" href="/icon?<hash>" type="image/png" sizes="32x32" />
<link rel="apple-touch-icon" href="/apple-icon?<hash>" type="image/png" sizes="180x180" />
```
(Per RESEARCH.md Pattern 4 and Next.js docs at nextjs.org/docs app-icons.)

**Artifact 3 — Create `website/src/app/opengraph-image.tsx`:**

Write this file verbatim (the generic-serif `fontFamily` is deliberate per RESEARCH.md Pattern 5 — loading a custom Spectral TTF via `readFile` is deferred to phase 12+ to keep the ImageResponse bundle well under the 500KB cap):

```tsx
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
          fontFamily: 'serif',
          color: '#1A1A17',
        }}
      >
        <div
          style={{
            fontSize: 28,
            letterSpacing: 2,
            color: '#8A8A82',
            textTransform: 'uppercase',
          }}
        >
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
```

CRITICAL per RESEARCH.md Pattern 5:
- Import from `next/og`, NOT `next/server` (deprecated in Next 14+).
- `size` must be `{ width: 1200, height: 630 }` — this is the OG spec.
- Use `display: 'flex'` — ImageResponse only supports a flexbox CSS subset; NO `display: 'grid'`.
- `fontFamily: 'serif'` is a generic fallback; Spectral isn't loaded here (would require `readFile` of a TTF, adds complexity + bundle size). Visual fallback path documented in RESEARCH.md Open Questions #2: if the serif rendering looks wrong at phase gate, replace this file with a static PNG at `website/src/app/opengraph-image.png`. That swap is a one-line change; not doing it preemptively.
- `alt` text attribute is the literal string `'PS Transcribe — Private, on-device transcription for macOS'` (em dash).

After all three files exist:
- `cd website && pnpm build` MUST exit 0. If the build fails with "ImageResponse bundle exceeded 500KB", remove the OG file and fall back to a static PNG (document in SUMMARY).
- `cd website && pnpm start &` then probe:
  ```bash
  curl -sfI http://localhost:3000/icon.png | head -1       # 200
  curl -sfI http://localhost:3000/apple-icon.png | head -1 # 200
  curl -sfI http://localhost:3000/opengraph-image.png | head -1 # 200
  curl -s http://localhost:3000/ | grep -oE 'property="og:image"[^>]*' | head -1  # should find og:image meta tag
  file website/src/app/icon.png        # must report: PNG image data, 32 x 32
  file website/src/app/apple-icon.png  # must report: PNG image data, 180 x 180
  ```
- Kill the background server. If `<title>` of the rendered home page is not exactly `PS Transcribe — Private, on-device transcription for macOS`, Task 1's layout metadata is wrong — go back and fix.
  </action>
  <verify>
    <automated>cd /Users/cary/Development/ai-development/ps-transcribe && test -f website/src/app/icon.png && test -f website/src/app/apple-icon.png && test -f website/src/app/opengraph-image.tsx && file website/src/app/icon.png | grep -qE '32 x 32' && file website/src/app/apple-icon.png | grep -qE '180 x 180' && grep -q "from 'next/og'" website/src/app/opengraph-image.tsx && grep -q "width: 1200, height: 630" website/src/app/opengraph-image.tsx && grep -q "background: '#FAFAF7'" website/src/app/opengraph-image.tsx && cd website && pnpm build</automated>
  </verify>
  <acceptance_criteria>
    - `website/src/app/icon.png` exists AND `file` reports dimensions `32 x 32`
    - `website/src/app/apple-icon.png` exists AND `file` reports dimensions `180 x 180`
    - `website/src/app/opengraph-image.tsx` exists
    - `opengraph-image.tsx` imports `ImageResponse` from `'next/og'` (NOT `'next/server'`)
    - `opengraph-image.tsx` exports `size` as `{ width: 1200, height: 630 }`
    - `opengraph-image.tsx` exports `contentType` as `'image/png'`
    - `opengraph-image.tsx` exports `alt` as exactly `'PS Transcribe — Private, on-device transcription for macOS'`
    - `opengraph-image.tsx` JSX uses `background: '#FAFAF7'` (paper hex, no token)
    - `opengraph-image.tsx` JSX uses `display: 'flex'` on the root div (flexbox only — Satori constraint)
    - `cd website && pnpm build` exits 0
    - `pnpm build` output does NOT print any ImageResponse size warnings (bundle stays under 500KB cap)
    - Local HTTP probe: `curl -sfI http://localhost:3000/icon.png` returns 200
    - Local HTTP probe: `curl -sfI http://localhost:3000/apple-icon.png` returns 200
    - Local HTTP probe: `curl -sfI http://localhost:3000/opengraph-image.png` returns 200
    - Local HTTP probe: `curl -s http://localhost:3000/ | grep -q 'property="og:image"'` (meta tag auto-injected)
    - Local HTTP probe: `curl -s http://localhost:3000/ | grep -q '<title>PS Transcribe — Private, on-device transcription for macOS</title>'` (confirms layout metadata from Task 1 renders correctly end-to-end)
  </acceptance_criteria>
  <done>Two icon PNGs at correct dimensions, OG image file ships with ImageResponse JSX rendering 1200x630 at build time. All file-convention routes return 200 locally. Build passes.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Google Fonts CDN → Vercel build | `next/font/google` downloads font files at build time, inlines base64/self-hosts per Next.js font pipeline |
| Build output → public web | Generated `/opengraph-image.png`, `/icon.png`, `/apple-icon.png`, `/sitemap.xml`, `/robots.txt`, `/manifest.webmanifest` are publicly accessible |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-11-02-01 | Information disclosure | `sitemap.ts` leaking internal routes | mitigate | Sitemap contains only `/`. No `/admin`, `/api/*`, `/internal/*` routes exist in phase 11 (nothing to leak). Phases 14–15 that append entries will re-evaluate. |
| T-11-02-02 | DoS (availability during build) | `opengraph-image.tsx` ImageResponse bundle exceeds 500KB → build fails | accept | Generic serif font (no custom font readFile), minimal JSX (~20 lines), no images imported. Well under cap by design. Fallback: swap to static PNG if Next emits a size warning (RESEARCH.md Pattern 5 caveat). |
| T-11-02-03 | Information disclosure | `opengraph-image.tsx` embedded copy leaks unreleased product claims | accept | Copy matches public `description` in layout metadata and CONTEXT.md D-17. No unreleased feature names or internal wording. |
| T-11-02-04 | Tampering | Font loader downloads different Inter/Spectral/JetBrains Mono than expected (Google Fonts swap-out) | accept | Google-hosted fonts from `fonts.google.com/specimen/*` — trusted upstream. `next/font/google` hashes the downloaded files and commits them to the build output; any swap would change build hashes and be caught on code review of the first deployment diff. |
| T-11-02-05 | Information disclosure | Robots.txt allows indexing of future protected routes | accept | No protected routes in phase 11. Phases that add admin/internal routes must update `robots.ts` disallow rules at that time. |

**Out of scope (public marketing placeholder, no user input/auth/crypto/sessions):** V2, V3, V4, V5, V6 per RESEARCH.md §Security Domain.
</threat_model>

<verification>
- `cd website && pnpm lint && pnpm build` exits 0
- All three fonts declared as CSS vars in `layout.tsx` with Spectral weight `['400','600']` present
- `page.tsx` contains all five D-15 hardcoded strings (see acceptance criteria)
- `sitemap.ts`, `robots.ts`, `manifest.ts` all exist and compile
- `icon.png` and `apple-icon.png` exist at correct dimensions (file command confirms 32x32 and 180x180)
- `opengraph-image.tsx` imports from `next/og` with `size = { width: 1200, height: 630 }`
- Local HTTP probes: `/`, `/sitemap.xml`, `/robots.txt`, `/manifest.webmanifest`, `/icon.png`, `/apple-icon.png`, `/opengraph-image.png` all return 200 under `pnpm start`
- `<title>` rendered as exactly `PS Transcribe — Private, on-device transcription for macOS`
- `<meta property="og:image">` auto-injected by Next.js from the opengraph-image.tsx file
</verification>

<success_criteria>
Plan complete when:
1. Home page at `/` renders the Chronicle placeholder: paper bg, Spectral wordmark, Inter sub-copy, JetBrains Mono meta label, "Site coming soon."
2. All three Chronicle fonts load as CSS variables — locally visible in generated HTML as `--font-inter`, `--font-spectral`, `--font-jetbrains-mono` on `<html>`
3. `<title>` matches layout metadata verbatim
4. `/sitemap.xml`, `/robots.txt`, `/manifest.webmanifest`, `/opengraph-image.png`, `/icon.png`, `/apple-icon.png` all serve 200 locally under `pnpm start`
5. `<meta property="og:image">` auto-injected in `<head>`
6. `cd website && pnpm build` exits 0
7. No new dependencies added beyond what create-next-app ships (all work uses `next/font/google`, `next/og`, and `next` types that come with Next.js 16)
</success_criteria>

<output>
After completion, create `.planning/phases/11-website-scaffolding-vercel-deployment/11-02-SUMMARY.md` documenting:
- Actual `<title>` string rendered (paste from `curl -s http://localhost:3000/ | grep -oE '<title>[^<]+</title>'`)
- OG image rendering decision taken (ImageResponse vs fallback static PNG — if fallback was used, explain trigger)
- Any Next.js 16 pitfalls encountered (font weight errors, metadataBase issues, bundle-size warnings)
- HTTP probe results from the 6 local probes run in Tasks 3+4
- `requirements_completed: [SITE-01, SITE-04]` — SITE-04's production reachability is fully earned in Plan 03 deploy, but this plan covers the content that will be served when production comes up
</output>
