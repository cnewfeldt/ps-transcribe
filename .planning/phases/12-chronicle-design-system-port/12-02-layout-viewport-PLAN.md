---
phase: 12
plan: 02
type: execute
wave: 1
depends_on: []
files_modified:
  - website/src/app/layout.tsx
autonomous: true
requirements: [DESIGN-02, DESIGN-04]
must_haves:
  truths:
    - "Production HTML of / emits <meta name=\"color-scheme\" content=\"light\"> in <head>"
    - "layout.tsx still imports Inter, Spectral, JetBrains_Mono from next/font/google with the same variable names as Phase 11"
    - "layout.tsx exports a Viewport typed object with colorScheme: 'light'"
    - "No deprecated metadata.colorScheme usage"
  artifacts:
    - path: website/src/app/layout.tsx
      provides: "Viewport export for light-mode lock (DESIGN-04 layer 3); unchanged font loading"
      contains: "export const viewport: Viewport = { colorScheme: 'light' }"
  key_links:
    - from: "website/src/app/layout.tsx viewport export"
      to: "Next.js 16 generateViewport API"
      via: "Viewport type import from 'next'"
      pattern: "export const viewport: Viewport"
---

<objective>
Add a `Viewport`-typed export to `website/src/app/layout.tsx` that sets `colorScheme: 'light'`, completing DESIGN-04 layer 3 (the pre-CSS-paint light-mode signal Next.js 16 emits as `<meta name="color-scheme" content="light">`). Simultaneously clean up the body inline `style={{ fontFamily: ... }}` Phase-11 placeholder so the body inherits the proper `--font-sans` chain from Plan 01's `@theme inline`.

Purpose: The final leg of the three-layer light-mode defense. Plan 01 handles layers 1 (strip dark block) and 2 (`color-scheme: light` in CSS). This plan handles layer 3 (HTML `<meta>` tag emitted before CSS paints). Without all three, a user with `prefers-color-scheme: dark` could see a flash of dark UA chrome before CSS loads.

Output: `layout.tsx` with a new `Viewport` import, a new `viewport` export, and a cleaned-up `<body>` className (no inline font-family style).
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/12-chronicle-design-system-port/12-CONTEXT.md
@.planning/phases/12-chronicle-design-system-port/12-RESEARCH.md
@.planning/phases/12-chronicle-design-system-port/12-VALIDATION.md
@website/src/app/layout.tsx
@website/AGENTS.md

<interfaces>
<!-- Current layout.tsx (Phase 11) -- DO NOT CHANGE the next/font imports, Inter/Spectral/JetBrains_Mono calls, or <html className> -->
<!-- Allowed edits (per D-11 + RESEARCH.md Body font-family override section): -->
<!--   1. Add `Viewport` to the `import type` line from 'next' -->
<!--   2. Add `export const viewport: Viewport = { colorScheme: 'light' }` alongside existing metadata export -->
<!--   3. Replace the body's `style={{ fontFamily: 'var(--font-inter), system-ui, sans-serif' }}` with a className that uses Tailwind utilities (font-sans bg-paper text-ink) OR remove the inline style entirely and let Plan 01's body reset in globals.css govern -->

<!-- Next.js 16 Viewport API (from node_modules/next/dist/docs/01-app/03-api-reference/04-functions/generate-viewport.md): -->
<!-- export const viewport: Viewport = { colorScheme: 'light' | 'dark' | 'normal' | 'light dark' } -->
<!-- NOT the deprecated metadata.colorScheme (deprecated since Next 14; AGENTS.md "heed deprecation notices") -->
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add Viewport export to layout.tsx and clean up body inline style</name>
  <files>website/src/app/layout.tsx</files>
  <read_first>
    - website/src/app/layout.tsx (current file -- must preserve font imports, Inter/Spectral/JetBrains_Mono calls, html className)
    - website/node_modules/next/dist/docs/01-app/03-api-reference/04-functions/generate-viewport.md (canonical Viewport export syntax; confirms colorScheme is a valid field)
    - website/node_modules/next/dist/docs/01-app/03-api-reference/04-functions/generate-metadata.md (confirm metadata.colorScheme is deprecated -- we are NOT using it)
    - .planning/phases/12-chronicle-design-system-port/12-CONTEXT.md (D-11: do NOT modify font loading; D-14 can be satisfied via CSS OR via Next viewport export)
    - .planning/phases/12-chronicle-design-system-port/12-RESEARCH.md section "Light-Mode Enforcement" (three-layer strategy; this plan owns layer 3)
    - .planning/phases/12-chronicle-design-system-port/12-RESEARCH.md section "next/font Fallback Chain -- Body font-family override" (Option A recommended: remove inline style, add className)
    - website/AGENTS.md ("This is NOT the Next.js you know... Heed deprecation notices.")
  </read_first>
  <action>
Edit `website/src/app/layout.tsx` with exactly three surgical changes. Do NOT touch the `Inter(...)`, `Spectral(...)`, `JetBrains_Mono(...)` function calls, their `variable:` assignments, or the `<html className={...}>` expression (Phase 11 lock per D-11).

**Change 1 -- Type import.** The current line 1 reads:
```tsx
import type { Metadata } from 'next'
```
Replace with:
```tsx
import type { Metadata, Viewport } from 'next'
```

**Change 2 -- Viewport export.** After the closing `}` of the existing `metadata` export (currently ends at `robots: { index: true, follow: true },\n}` around line 45), add one blank line then insert the viewport export as a new top-level export:
```tsx

export const viewport: Viewport = {
  colorScheme: 'light',
}
```

**Change 3 -- Body cleanup.** The current body tag reads:
```tsx
<body style={{ fontFamily: 'var(--font-inter), system-ui, sans-serif' }}>
```
Replace with (Option A per RESEARCH.md -- let Plan 01's `globals.css` body reset + Tailwind utility govern):
```tsx
<body className="font-sans bg-paper text-ink antialiased">
```

This removes the inline `style` (which bypassed the `--font-sans` chain) in favor of Tailwind utilities that resolve to Plan 01's `@theme inline` tokens (`font-sans` → `var(--font-sans)` which is the full `var(--font-inter), "SF Pro Text", -apple-system, system-ui, sans-serif` chain). `bg-paper` and `text-ink` are redundant with the body reset in globals.css but make the intent explicit at the layout level.

Final `layout.tsx` shape (after edits) should be:

```tsx
import type { Metadata, Viewport } from 'next'
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
  metadataBase: new URL('https://ps-transcribe-web.vercel.app'),
  title: {
    default: 'PS Transcribe -- Private, on-device transcription for macOS',
    template: '%s · PS Transcribe',
  },
  description: 'Private, on-device transcription for macOS.',
  openGraph: {
    title: 'PS Transcribe',
    description: 'Private, on-device transcription for macOS.',
    url: 'https://ps-transcribe-web.vercel.app',
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

export const viewport: Viewport = {
  colorScheme: 'light',
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
      <body className="font-sans bg-paper text-ink antialiased">
        {children}
      </body>
    </html>
  )
}
```

Note: the existing title `default` string uses an em dash. Replace it with `--` (double hyphen) per the global user rule: `default: 'PS Transcribe -- Private, on-device transcription for macOS'`. Same for the description if any em dashes appear. Scan the whole file for em dashes (`—`) and replace each with `--` or rephrase.

Forbidden in this task:
- Do NOT use `metadata.colorScheme` (deprecated since Next 14).
- Do NOT modify the `Inter(...)`, `Spectral(...)`, `JetBrains_Mono(...)` constructor calls or their `variable:` names.
- Do NOT change `<html className={...}>` expression.
- Do NOT add `"use client"` at the top (root layout stays a server component).
- Do NOT introduce em dashes (`—`) anywhere.
  </action>
  <verify>
    <automated>cd website && grep -q "import type { Metadata, Viewport } from 'next'" src/app/layout.tsx && grep -q "export const viewport: Viewport" src/app/layout.tsx && grep -q "colorScheme: *'light'" src/app/layout.tsx && grep -q 'next/font/google' src/app/layout.tsx && grep -qE 'Inter\|Spectral\|JetBrains_Mono' src/app/layout.tsx && ! grep -q 'metadata.colorScheme\|colorScheme:.*inside.*metadata' src/app/layout.tsx && ! grep -P '\x{2014}' src/app/layout.tsx && pnpm run build</automated>
  </verify>
  <acceptance_criteria>
    - `grep -q "import type { Metadata, Viewport } from 'next'" website/src/app/layout.tsx` matches (Viewport imported)
    - `grep -q "export const viewport: Viewport" website/src/app/layout.tsx` matches
    - `grep -q "colorScheme: *'light'" website/src/app/layout.tsx` matches
    - Font imports preserved: `grep -q 'next/font/google' website/src/app/layout.tsx` AND `grep -qE 'Inter|Spectral|JetBrains_Mono' website/src/app/layout.tsx`
    - No deprecated API: colorScheme appears inside `export const viewport`, NOT inside `metadata` block
    - No em dashes: `! grep -P '\x{2014}' website/src/app/layout.tsx`
    - Body no longer uses inline font style: `! grep -q "style={{ fontFamily:" website/src/app/layout.tsx`
    - Body uses Tailwind utilities: `grep -q 'className="font-sans' website/src/app/layout.tsx`
    - `cd website && pnpm run build` exits 0
  </acceptance_criteria>
  <done>
layout.tsx exports `viewport: Viewport = { colorScheme: 'light' }`, body uses `className="font-sans bg-paper text-ink antialiased"`, font loading remains untouched from Phase 11, and build is green. Next.js will emit `<meta name="color-scheme" content="light">` into every page's `<head>` at production build time.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| None new for this plan | Only modifies server-rendered layout metadata. No user input. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-12-03 | Tampering | next/font supply chain | accept | Unchanged from Phase 11. `next/font/google` self-hosts webfonts during build; no runtime fetch. This plan does not modify font-loading calls. |
</threat_model>

<verification>
- `cd website && pnpm run build` exits 0
- All grep probes in acceptance_criteria pass
- Manual curl probe (during execution, after `pnpm run build && pnpm run start` in background): `curl -s http://localhost:3000/ | grep -q 'name="color-scheme" content="light"'` confirms the `<meta>` tag is in production HTML. This probe is in 12-VALIDATION.md as 12-02-02 and is verified during the Plan 04 build+start cycle; do not start dev/start servers during this plan's execution.
</verification>

<success_criteria>
- `viewport` export typed as `Viewport` with `colorScheme: 'light'` present
- Metadata block unchanged except for any em-dash cleanup
- Font loading constants and `<html className={...}>` expression byte-identical to Phase 11
- Body inline style replaced with Tailwind utility className
- Build green
</success_criteria>

<output>
After completion, create `.planning/phases/12-chronicle-design-system-port/12-02-SUMMARY.md` with:
- Diff summary of the three surgical changes
- Confirmation that next/font loading was NOT modified (lines matching before/after)
- Next step: Plan 03 builds primitives; Plan 04 verifies the color-scheme meta tag via curl after build+start
</output>
</content>
</invoke>