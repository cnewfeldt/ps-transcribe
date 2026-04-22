---
phase: 11-website-scaffolding-vercel-deployment
reviewed: 2026-04-22T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - website/src/app/layout.tsx
  - website/src/app/page.tsx
  - website/src/app/sitemap.ts
  - website/src/app/robots.ts
  - website/src/app/manifest.ts
  - website/src/app/opengraph-image.tsx
  - website/src/app/globals.css
  - website/package.json
  - website/next.config.ts
findings:
  critical: 0
  warning: 2
  info: 4
  total: 6
status: issues_found
---

# Phase 11: Code Review Report

**Reviewed:** 2026-04-22
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Phase 11 shipped a clean Next.js 16 scaffold, Chronicle placeholder content, and a full file-based metadata suite. The source files I reviewed conform to Next.js 16 conventions verified against the bundled docs in `website/node_modules/next/dist/docs/` -- `MetadataRoute.*` types are used correctly, `ImageResponse` is imported from `next/og` (not the deprecated `next/server`), Spectral is declared with explicit `weight`, and `metadataBase` is set. TypeScript strict mode is honored; no `any`, no loose assertions.

The findings below are all **quality/consistency** issues, not correctness defects. Two warnings concern a stale `globals.css` that contradicts the project's light-mode-only design requirement (DESIGN-04) and an inline-style vs. stylesheet conflict in the root layout. The four info items note dead code, a trivially empty `next.config.ts` where a known warning could be resolved, a minor divergence from the documented OG image function-name convention, and the absence of `lang` metadata on the manifest. None of these block phase completion; all are already partially acknowledged by `11-VERIFICATION.md` or explicitly deferred to phase 12 by D-12.

Security scan: no hardcoded secrets, no `eval` / `innerHTML` / `dangerouslySetInnerHTML`, no injection vectors in metadata routes, no unvalidated user input (all content is static). The `.gitignore` correctly excludes `.env*`, keychains, and build artifacts at both repo root and inside `website/`.

## Warnings

### WR-01: `globals.css` retains create-next-app defaults that contradict DESIGN-04 (light-mode only)

**File:** `website/src/app/globals.css:15-20`
**Issue:** The stylesheet still contains a `@media (prefers-color-scheme: dark)` block that flips `--background` to `#0a0a0a` and `--foreground` to `#ededed`, and `body` consumes those variables (`background: var(--background)`). Phase 11's placeholder page renders a full-viewport `<main>` with its own hardcoded `#FAFAF7` background, so the dark body is not visible on the home route today. But any future route that doesn't paint its own full-viewport background (or any overscroll / rubber-band scroll on macOS Safari) will expose the dark body, which directly violates `DESIGN-04` (light-mode only). This is also a scaffolding leftover -- the `--font-geist-sans` / `--font-geist-mono` references here are dead since `layout.tsx` switched to Inter / Spectral / JetBrains Mono. `11-VERIFICATION.md` already flagged this file as "Info / deferred to phase 12 per D-12 scope", so this warning is an upgrade on that assessment because of the DESIGN-04 conflict -- the dark-mode block is not purely cosmetic.

**Fix:** Before phase 12 lands (or as a small hygiene commit during phase 12 kickoff), strip the dark-mode media query and the unused Geist font variables. Minimal safe edit:

```css
@import "tailwindcss";

:root {
  --background: #FAFAF7;
  --foreground: #1A1A17;
}

@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
}

body {
  background: var(--background);
  color: var(--foreground);
}
```

Removes the dark-mode branch, the `font-family: Arial, Helvetica, sans-serif` line (body font is set via inline style in `layout.tsx` -- see WR-02), and the dead Geist variable references. Aligns with DESIGN-04 and unblocks phase 12's Chronicle token migration.

### WR-02: `body` font-family is defined in two places with different values

**File:** `website/src/app/layout.tsx:57` and `website/src/app/globals.css:25`
**Issue:** `layout.tsx` sets an inline style on `<body>`: `style={{ fontFamily: 'var(--font-inter), system-ui, sans-serif' }}`. `globals.css` also sets `body { font-family: Arial, Helvetica, sans-serif; }`. The inline style wins due to specificity, but the two declarations disagree (Inter vs. Arial) and make future maintenance brittle -- someone updating the stylesheet will assume Arial is the body font and be surprised that it's not. This is also a Next.js 16 anti-pattern: `next/font/google` is designed so you bind the CSS variable to `<html>` (already done) and then set `font-family` **in the stylesheet**, not inline. The inline style bypasses CSS cascade rules that would let later pages override the body font.

**Fix:** Move the font-family from inline style into `globals.css` and drop the `style` prop from `<body>`. Combined with WR-01's cleanup:

```tsx
// layout.tsx
<body>{children}</body>
```

```css
/* globals.css */
body {
  background: var(--background);
  color: var(--foreground);
  font-family: var(--font-inter), system-ui, sans-serif;
}
```

Single source of truth, follows the documented `next/font` pattern, and lets page-level components use `fontFamily` overrides predictably.

## Info

### IN-01: `next.config.ts` is empty but the bun.lockb workspace-root warning could be suppressed here

**File:** `website/next.config.ts:1-7`
**Issue:** The config is the default create-next-app scaffold (empty `NextConfig` object). Both `11-01-SUMMARY.md` and `11-02-SUMMARY.md` observe a persistent Turbopack warning during `pnpm build`: "We detected multiple lockfiles and selected the directory of /Users/cary/bun.lockb as the root directory." The warning comes from a stray `~/bun.lockb` on the developer's machine, not anything in this repo. It doesn't break the build but it adds noise that makes future build-log review harder.

**Fix:** Add an explicit `turbopack.root` pointing at the `/website` directory so Turbopack doesn't traverse up to the user's home and discover the stray lockfile. Single-line change:

```ts
import type { NextConfig } from "next";
import path from "node:path";

const nextConfig: NextConfig = {
  turbopack: {
    root: path.join(__dirname),
  },
};

export default nextConfig;
```

Low-risk, eliminates a known noisy warning, and documents the repo's monorepo intent in code rather than leaving it implicit.

### IN-02: `globals.css` still imports `tailwindcss` but page.tsx uses no Tailwind utility classes

**File:** `website/src/app/globals.css:1`
**Issue:** The `@import "tailwindcss";` line pulls in the full Tailwind 4 stylesheet, but `page.tsx` uses zero `className=` attributes -- everything is inline-styled hex literals per D-15. This is intentional per D-12 (Tailwind plumbing lands in phase 11, token port deferred to phase 12), so I'm not flagging it as dead code. Recording it here so the phase 12 owner knows: after phase 12 ports the Chronicle palette and migrates `page.tsx` to utility classes, this import does load-bearing work. For phase 11 alone, it's unused plumbing that still ships to production (~17 KB gzipped of Tailwind base styles), but this is a deliberate trade-off, not a bug.

**Fix:** No action required for phase 11. Phase 12 should verify the Tailwind import actually gets used once token classes land on `page.tsx`.

### IN-03: `opengraph-image.tsx` default export named `OGImage` diverges from Next.js 16 docs convention

**File:** `website/src/app/opengraph-image.tsx:7`
**Issue:** The Next.js 16 docs (`node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/01-metadata/opengraph-image.md` lines 112, 168, 345, etc.) consistently name the default export `Image`. This file uses `OGImage`. Next.js doesn't care about the function name -- the framework reads the default export regardless of identifier -- so this is purely a stylistic divergence, not a defect. Flagging because it's an inconsistency with the documented convention, which matters for grep-ability / "does this look like the framework's canonical example".

**Fix:** Rename for consistency with the framework's own examples:

```tsx
export default async function Image() {
  return new ImageResponse(...)
}
```

Zero runtime impact, one-line change.

### IN-04: `manifest.ts` omits `lang` field (web app manifest best practice)

**File:** `website/src/app/manifest.ts:1-17`
**Issue:** The manifest defines `name`, `short_name`, `description`, `start_url`, `display`, colors, and icons, but no `lang` field. Per the W3C Web App Manifest spec, `lang` lets the browser apply correct language-specific rendering (font selection, hyphenation, text direction). Without it, the browser falls back to the document `lang` attribute (set correctly to `"en"` in `layout.tsx:54`), so this is not a bug -- but the manifest JSON is the authoritative source for PWA installation flows and would be richer with an explicit `"lang": "en-US"` (matching the OG locale).

**Fix:**

```ts
return {
  name: 'PS Transcribe',
  short_name: 'PS Transcribe',
  description: 'Private, on-device transcription for macOS',
  lang: 'en-US',
  start_url: '/',
  // ...
}
```

Single line, improves PWA metadata quality with no downside. Low priority -- site isn't installable today and may never be (it's a marketing site, not a PWA).

---

_Reviewed: 2026-04-22_
_Reviewer: Claude (gsd-code-reviewer), Opus 4.7 (1M context)_
_Depth: standard_
