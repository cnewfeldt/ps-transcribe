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
    - "Production HTML emits <link rel=\"preload\"> (or equivalent next/font-injected tag) for Inter, Spectral, and JetBrains Mono webfonts served from /_next/static/media"
    - "layout.tsx exports a Viewport typed object with colorScheme: 'light'"
    - "No deprecated metadata.colorScheme usage"
    - "Body element has no inline fontFamily style (font resolution flows through Plan 01's globals.css body reset + font-sans utility chain)"
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
Add a `Viewport`-typed export to `website/src/app/layout.tsx` that sets `colorScheme: 'light'`, completing DESIGN-04 layer 3 (the pre-CSS-paint light-mode signal Next.js 16 emits as `<meta name="color-scheme" content="light">`). Simultaneously clean up the body inline `style={{ fontFamily: ... }}` Phase-11 placeholder so the body inherits the proper `--font-sans` chain from Plan 01's `@theme inline`, and replace an existing em-dash in the metadata title with the double-hyphen form per the global user rule.

Purpose: The final leg of the three-layer light-mode defense. Plan 01 handles layers 1 (strip dark block) and 2 (`color-scheme: light` in CSS). This plan handles layer 3 (HTML `<meta>` tag emitted before CSS paints). Without all three, a user with `prefers-color-scheme: dark` could see a flash of dark UA chrome before CSS loads.

Output: `layout.tsx` with a new `Viewport` import, a new `viewport` export, a cleaned-up `<body>` className (no inline font-family style, no Plan-01-dependent utilities), and the title string's em-dash replaced with `--`.
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
<!-- Allowed edits (per D-11 + RESEARCH.md Assumption A4 / Body font-family override section): -->
<!--   1. Add `Viewport` to the `import type` line from 'next' -->
<!--   2. Add `export const viewport: Viewport = { colorScheme: 'light' }` alongside existing metadata export -->
<!--   3. Replace the body's `style={{ fontFamily: 'var(--font-inter), system-ui, sans-serif' }}` with a Tailwind-only className that uses Tailwind-built-in utilities only (`font-sans antialiased`). Do NOT add bg-paper or text-ink utilities -- those depend on Plan 01's @theme inline. The body reset in Plan 01's globals.css (`body { background: var(--color-paper); color: var(--color-ink); ... }`) handles bg/color via CSS custom properties, so the body className only needs built-in utilities that resolve without Plan 01. This keeps Plan 02 independent of Plan 01 at wave 1. -->
<!--   4. Replace the em-dash in the metadata title `default` value with `--` per global user rule. -->

<!-- Next.js 16 Viewport API (from node_modules/next/dist/docs/01-app/03-api-reference/04-functions/generate-viewport.md): -->
<!-- export const viewport: Viewport = { colorScheme: 'light' | 'dark' | 'normal' | 'light dark' } -->
<!-- NOT the deprecated metadata.colorScheme (deprecated since Next 14; AGENTS.md "heed deprecation notices") -->
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add Viewport export to layout.tsx, clean up body inline style, fix em-dash in title</name>
  <files>website/src/app/layout.tsx</files>
  <read_first>
    - website/src/app/layout.tsx (current file -- must preserve font imports, Inter/Spectral/JetBrains_Mono calls, html className; note line 27 has a literal em-dash in the metadata title that MUST be replaced as part of this task)
    - website/node_modules/next/dist/docs/01-app/03-api-reference/04-functions/generate-viewport.md (canonical Viewport export syntax; confirms colorScheme is a valid field)
    - website/node_modules/next/dist/docs/01-app/03-api-reference/04-functions/generate-metadata.md (confirm metadata.colorScheme is deprecated -- we are NOT using it)
    - .planning/phases/12-chronicle-design-system-port/12-CONTEXT.md (D-11: do NOT modify font loading; D-14 can be satisfied via CSS OR via Next viewport export)
    - .planning/phases/12-chronicle-design-system-port/12-RESEARCH.md section "Light-Mode Enforcement" (three-layer strategy; this plan owns layer 3)
    - .planning/phases/12-chronicle-design-system-port/12-RESEARCH.md Assumption A4 "Body font-family override — Option A vs B" (Option A is the chosen interpretation: drop the body inline style AND avoid Plan-01-dependent utilities on body so Plan 02 stays at wave 1. Option A preserves font-family resolution via Tailwind's built-in font-sans utility chain composed in Plan 01's @theme inline, which is applied by Plan 01's body reset against CSS custom properties -- not by Tailwind utilities on the body element.)
    - .planning/phases/12-chronicle-design-system-port/12-RESEARCH.md section "next/font Fallback Chain -- Body font-family override" (Option A recommended)
    - website/src/app/globals.css (reference only: confirm bg-paper/text-ink utilities exist after Plan 01 if body uses them. Currently Option A DROPS those utilities from body, so this read is informational -- it documents the alternative path Option B would take if this plan gained a depends_on: [12-01] and wave: 2.)
    - website/AGENTS.md ("This is NOT the Next.js you know... Heed deprecation notices.")
  </read_first>
  <action>
Edit `website/src/app/layout.tsx` with exactly four surgical changes. Do NOT touch the `Inter(...)`, `Spectral(...)`, `JetBrains_Mono(...)` function calls, their `variable:` assignments, or the `<html className={...}>` expression (Phase 11 lock per D-11).

<!--
  READ FIRST NOTE (RESEARCH.md Assumption A4):
  Option A is the chosen interpretation for this plan. The body className below uses
  ONLY Tailwind built-in utilities (`font-sans antialiased`) -- NOT bg-paper or text-ink.
  Rationale: bg-paper/text-ink are emitted by Plan 01's @theme inline block. If this plan
  used them on <body>, Plan 02 would race Plan 01 at wave 1 (Tailwind v4 errors on
  unknown utilities if Plan 02 builds first). Plan 01's globals.css body reset already
  sets `background: var(--color-paper); color: var(--color-ink);` via CSS custom
  properties, so the visible result is identical to a belt-and-suspenders className
  without the dependency risk. Font resolution still flows through `font-sans` (a
  Tailwind built-in that maps to --font-sans, which Plan 01's @theme inline composes as
  the full Inter + SF Pro Text + system chain). `antialiased` is a Tailwind built-in
  that does not depend on Plan 01.
-->

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

**Change 3 -- Body cleanup (Option A per RESEARCH.md Assumption A4).** The current body tag reads:
```tsx
<body style={{ fontFamily: 'var(--font-inter), system-ui, sans-serif' }}>
```
Replace with:
```tsx
<body className="font-sans antialiased">
```

Why only `font-sans antialiased` and NOT `bg-paper text-ink`: both `font-sans` and `antialiased` are Tailwind-built-in utilities that resolve without depending on Plan 01's `@theme inline` block. `bg-paper` and `text-ink`, by contrast, are emitted ONLY after Plan 01 adds `--color-paper` / `--color-ink` to `@theme inline`. Keeping those off the body lets Plan 02 stay at `wave: 1` / `depends_on: []`. Plan 01's body reset in globals.css still sets `background: var(--color-paper); color: var(--color-ink);` via CSS custom properties, so the rendered result is identical.

**Change 4 -- Em-dash in metadata title.** The current line 27 reads:
```tsx
    default: 'PS Transcribe — Private, on-device transcription for macOS',
```
Replace the em-dash (U+2014) with a double hyphen so it reads:
```tsx
    default: 'PS Transcribe -- Private, on-device transcription for macOS',
```
This follows the global user rule ("Never use em dashes in any output -- use double hyphens instead"). Also scan the rest of the file for any other em dashes (`—`) and replace each with `--` or rephrase; as of Phase 11 the title is the only known occurrence, but the grep in `<verify>` catches any that slip in.

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
      <body className="font-sans antialiased">
        {children}
      </body>
    </html>
  )
}
```

Forbidden in this task:
- Do NOT use `metadata.colorScheme` (deprecated since Next 14).
- Do NOT modify the `Inter(...)`, `Spectral(...)`, `JetBrains_Mono(...)` constructor calls or their `variable:` names.
- Do NOT change `<html className={...}>` expression.
- Do NOT add `"use client"` at the top (root layout stays a server component).
- Do NOT introduce em dashes (`—`) anywhere. The existing one on line 27 MUST be removed by Change 4.
- Do NOT add `bg-paper`, `text-ink`, or any Plan-01-token-dependent Tailwind utility to the body className. Those utilities only exist after Plan 01 extends `@theme inline`; adding them here would force Plan 02 to depend_on 12-01 and move to wave 2.
  </action>
  <verify>
    <automated>cd website && grep -q "import type { Metadata, Viewport } from 'next'" src/app/layout.tsx && grep -q "export const viewport: Viewport" src/app/layout.tsx && grep -q "colorScheme: *'light'" src/app/layout.tsx && grep -q 'next/font/google' src/app/layout.tsx && grep -qE 'Inter|Spectral|JetBrains_Mono' src/app/layout.tsx && ! grep -q 'metadata\.colorScheme' src/app/layout.tsx && ! LC_ALL=C grep -l $'\xe2\x80\x94' src/app/layout.tsx && ! grep -q "style={{ fontFamily:" src/app/layout.tsx && grep -q 'className="font-sans antialiased"' src/app/layout.tsx && ! grep -q 'className="[^"]*bg-paper' src/app/layout.tsx && ! grep -q 'className="[^"]*text-ink' src/app/layout.tsx && pnpm run build</automated>
  </verify>
  <acceptance_criteria>
    - `grep -q "import type { Metadata, Viewport } from 'next'" website/src/app/layout.tsx` matches (Viewport imported)
    - `grep -q "export const viewport: Viewport" website/src/app/layout.tsx` matches
    - `grep -q "colorScheme: *'light'" website/src/app/layout.tsx` matches
    - Font imports preserved: `grep -q 'next/font/google' website/src/app/layout.tsx` AND `grep -qE 'Inter|Spectral|JetBrains_Mono' website/src/app/layout.tsx`
    - No deprecated API: `! grep -q 'metadata\.colorScheme' website/src/app/layout.tsx` (colorScheme appears inside `export const viewport`, NOT inside `metadata` block)
    - No em dashes (portable, BSD+GNU grep compatible): `! LC_ALL=C grep -l $'\xe2\x80\x94' website/src/app/layout.tsx`
    - Body no longer uses inline font style: `! grep -q "style={{ fontFamily:" website/src/app/layout.tsx`
    - Body uses only Tailwind built-in utilities (Option A guard): `grep -q 'className="font-sans antialiased"' website/src/app/layout.tsx`
    - Body does NOT use Plan-01-dependent utilities: `! grep -q 'className="[^"]*bg-paper' website/src/app/layout.tsx` AND `! grep -q 'className="[^"]*text-ink' website/src/app/layout.tsx`
    - `cd website && pnpm run build` exits 0
  </acceptance_criteria>
  <done>
layout.tsx exports `viewport: Viewport = { colorScheme: 'light' }`, body uses `className="font-sans antialiased"` (Tailwind built-ins only, no Plan 01 dependency), title string em-dash replaced with `--`, font loading remains untouched from Phase 11, and build is green. Plan 02 remains at wave 1 with depends_on: []. Next.js will emit `<meta name="color-scheme" content="light">` into every page's `<head>` at production build time.
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
| T-12-01 | Tampering / XSS | `CodeBlock` children rendering | n/a (not in scope) | No `CodeBlock` children rendered in this plan; mitigation owned by Plan 03. Cross-reference only for traceability. |
| T-12-02 | Information disclosure | Showcase content leaking internal strings | n/a (not in scope) | Layout does not render showcase content; owned by Plan 04. Cross-reference only. |
| T-12-03 | Tampering | next/font supply chain | accept | Unchanged from Phase 11. `next/font/google` self-hosts webfonts during build; no runtime fetch. This plan does not modify font-loading calls. |
</threat_model>

<verification>
- `cd website && pnpm run build` exits 0
- All grep probes in acceptance_criteria pass
- Manual curl probe (during execution, after `pnpm run build && pnpm run start` in background): `curl -s http://localhost:3000/ | grep -q 'name="color-scheme" content="light"'` confirms the `<meta>` tag is in production HTML. This probe is in 12-VALIDATION.md as 12-02-02 and is verified during the Plan 04 build+start cycle; do not start dev/start servers during this plan's execution.
</verification>

<success_criteria>
- `viewport` export typed as `Viewport` with `colorScheme: 'light'` present
- Metadata block unchanged except for the em-dash replacement in `title.default`
- Font loading constants and `<html className={...}>` expression byte-identical to Phase 11
- Body inline style replaced with `className="font-sans antialiased"` (no Plan-01-dependent utilities)
- Plan 02 remains at wave 1 with depends_on: [] (no build race against Plan 01)
- Build green
</success_criteria>

<output>
After completion, create `.planning/phases/12-chronicle-design-system-port/12-02-SUMMARY.md` with:
- Diff summary of the four surgical changes
- Confirmation that next/font loading was NOT modified (lines matching before/after)
- Confirmation that body className contains ONLY Tailwind built-in utilities (no bg-paper/text-ink)
- Next step: Plan 03 builds primitives; Plan 04 verifies the color-scheme meta tag via curl after build+start
</output>
</content>
