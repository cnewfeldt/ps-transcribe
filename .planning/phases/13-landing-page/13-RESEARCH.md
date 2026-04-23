# Phase 13: Landing Page - Research

**Researched:** 2026-04-22
**Domain:** Next.js 16 App Router + Tailwind CSS v4 + React 19 marketing landing page
**Confidence:** HIGH (almost all claims verified against the local node_modules docs, the actual repo files, and the existing code — three `[ASSUMED]` items flagged in the Assumptions Log)

## Summary

Phase 13 ports the 665-line `design/ps-transcribe-web-unzipped/index.html` mock (hero variant C, selected via `<body data-hero="C">`) into a native React implementation under `/website`. The mock's visual vocabulary (paper palette, Spectral headlines, JetBrains Mono meta labels, 0.5px hairlines, no animation beyond a fade-on-scroll reveal) is already fully token-available in `website/src/app/globals.css` thanks to Phase 12 — `bg-paper`, `text-ink-muted`, `bg-accent-tint`, `bg-spk2-bg`, `border-rule-strong`, `shadow-float`, `rounded-card`, `font-serif`, etc. all resolve correctly. The five Phase-12 primitives (`Button`, `Card`, `MetaLabel`, `SectionHeading`, `CodeBlock`) cover most atomic needs; Phase 13 adds higher-level layout and section components plus four mini-mockup components.

Three research findings override or clarify CONTEXT.md:

1. **The DMG filename has a space, not a dash.** `scripts/make_dmg.sh` line 6 sets `DMG_PATH="dist/PS Transcribe.dmg"`, and `.github/workflows/release-dmg.yml` line 140 URL-encodes it as `PS%20Transcribe.dmg`. **D-13's URL (`.../PS-Transcribe.dmg`) will 404.** The correct URL is `https://github.com/cnewfeldt/ps-transcribe/releases/latest/download/PS%20Transcribe.dmg`.
2. **macOS minimum is 26.0, not 14.** `PSTranscribe/Package.swift` line 7 declares `platforms: [.macOS(.v26)]`, the Sparkle appcast in `release-dmg.yml` line 160 emits `sparkle:minimumSystemVersion=26.0`, and `README.md` advertises `macOS 26+`. The mock's `macOS 14+ · Apple Silicon & Intel` copy is factually wrong (confirmed against the README badge and the Package.swift manifest) and must be replaced in the hero note and the final CTA note. "Apple Silicon & Intel" is also wrong — the README badge explicitly reads `Apple Silicon - Required`.
3. **`priority` was renamed to `preload` in Next.js 16.** The official Next 16 image docs (local `node_modules/next/dist/docs/01-app/03-api-reference/02-components/image.md` line 293) say: *"Starting with Next.js 16, the `priority` property has been deprecated in favor of the `preload` property in order to make the behavior clear."* The hero screenshot must use `preload={true}`, not `priority`.

Two further stack-level items the planner needs to address in Wave 0:

- **Spectral italic face is not currently loaded.** `layout.tsx` loads Spectral with `weight: ['400', '600']` and no `style` option. `next/font/google` defaults to `style: 'normal'`, so italic is synthesized by the browser, not rendered from the real italic cut. Since the hero headline and Feature 3 paragraph both rely on `<em>` for meaningful editorial italics, the Spectral loader must be changed to include `style: ['normal', 'italic']` (see `node_modules/next/dist/docs/01-app/03-api-reference/02-components/font.md` line 142). This is a small but visible fidelity fix. CONTEXT.md says "DO NOT modify font loading (Phase 12 D-02)" — that decision was about not re-registering or swapping fonts, not about refusing to pass an additional `style` option to the same loader. Flag this to the discuss-phase if needed, but the fidelity improvement is load-bearing.
- **There is no `src/app/metadata.ts` file.** Root metadata lives inline in `layout.tsx`. The CONTEXT.md "canonical refs" entry for `website/src/app/metadata.ts` references a file that doesn't exist. The planner should update the `metadata` export in `layout.tsx` directly (or create a co-located `metadata.ts` file that `layout.tsx` re-exports, as a stylistic choice — both work in Next 16).

**Primary recommendation:** Treat this as a faithful React port of a static HTML mock. Mount `<Nav />` and `<Footer />` in `layout.tsx` (so phases 14 and 15 inherit them), keep all four mini-mockups as server-component JSX with static inline heights (no canvas, no SVG animation, no hand-rolled library), put the two interactive hooks (`useScrolled`, `useReveal`) behind `"use client"` in a tiny wrapper component, and gate the build-time changelog read through `fs.readFileSync` at module scope in a new `src/lib/changelog.ts`. Use existing Phase-12 Tailwind tokens wherever the mock uses the same named value; fall back to `[...]`-arbitrary-value utilities only for the handful of pixel-exact values the tokens don't cover (`border-[0.5px]`, `rounded-[12px]`, `clamp(32px, 4vw, 44px)`, etc.).

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Fidelity & scope**
- **D-01:** Ship all seven mock sections — Nav, Hero, "Three things" strip, four Feature blocks, Shortcuts, Final CTA, Footer.
- **D-02:** Hero layout is variant C — centered editorial (`<h1>Your meeting audio<br><em>never leaves your Mac.</em></h1>`, wide deck below). Not variant A or B.
- **D-03:** Use the mock's copy verbatim. Only mechanical substitutions: version string (build-time fetched) and GitHub owner slug (`cnewfeldt/ps-transcribe`). Factual overrides (see D-specifics: macOS version) take precedence over verbatim.
- **D-04:** Extract all layout + section components. `src/components/layout/{Nav,Footer}.tsx` shared; `src/components/sections/{Hero,ThreeThingsStrip,FeatureBlock,ShortcutGrid,FinalCTA}.tsx` landing-only; `src/components/mocks/` holds the four mini-mockups.

**Hero app imagery**
- **D-05:** Use the existing PNG at `design/ps-transcribe-web-unzipped/assets/app-screenshot.png`. Copy to `website/public/app-screenshot.png`.
- **D-06:** Wrap the screenshot in the mock's `.app-shot` frame — `0.5px solid var(--color-rule-strong)`, `12px` radius, `shadow-float`, `paper` background, max-width `1080px` centered, `margin-inline: auto`.
- **D-07:** Hero image loads via `next/image` with `priority`. Use explicit `width={2260}` and `height={1408}`. (Research note: in Next 16, `priority` is deprecated — use `preload={true}` per the official docs.)
- **D-08:** Alt text = `"PS Transcribe — meeting transcript with Library, Transcript, and Details columns"`.

**Feature block visuals**
- **D-09:** Port the four mini-mockups as React components in `src/components/mocks/`. Static JSX + Tailwind.
- **D-10:** Port the tint wrapper variants. `<FeatureBlock tint="default" | "tint" | "sage">`. Feature 1 = `tint`, Feature 2 = `sage`, Feature 3 = `default`, Feature 4 = `tint`.
- **D-11:** No animation on any mini-mockup.
- **D-12:** Alternate layout every other feature block. Feature 1: copy-left / mock-right. Feature 2: mock-left / copy-right. Feature 3: copy-left / mock-right. Feature 4: mock-left / copy-right. Use Tailwind `order-*` utilities, not `direction: rtl`.

**Download CTA + version**
- **D-13:** Primary CTA href = `https://github.com/cnewfeldt/ps-transcribe/releases/latest/download/PS-Transcribe.dmg`. (Research note: correct filename is `PS%20Transcribe.dmg` — the dashed form will 404.)
- **D-14:** Secondary hero CTA = "View on GitHub →", `Button variant="secondary"` linking to `https://github.com/cnewfeldt/ps-transcribe`.
- **D-15:** Build-time version fetch from `CHANGELOG.md`. Shared helper at `src/lib/changelog.ts`. Shape: `{ version: string, date: string, sections: { title: string, items: string[] }[] }`.
- **D-16:** GitHub owner/repo slug = `cnewfeldt/ps-transcribe`. Stored as a single constant in `src/lib/site.ts` (or equivalent).

**Shared layout**
- **D-17:** `Nav` with scrolled-state behavior — transparent/paper bg at `scrollY <= 6`, slight shadow + `paper-warm` once scrolled. Wordmark on left (Spectral word + dot-mark), three links on right (Docs → `/docs`, Changelog → `/changelog`, GitHub → repo URL).
- **D-18:** `Footer` three-column grid: (col 1) brand blurb + `© 2026` + MIT line, (col 2) Product links, (col 3) Source links. Sparkle appcast link target = `https://github.com/cnewfeldt/ps-transcribe/releases.atom`.

**Motion**
- **D-19:** Reveal-on-scroll ported as a single `useReveal()` hook in `src/hooks/`. IntersectionObserver with `threshold: 0.12`, adds `is-in` class on first intersection, unobserves after. MUST honor `prefers-reduced-motion: reduce`.
- **D-20:** No other motion. No hover-scale, no parallax, no float, no continuous animation.

### Claude's Discretion

- Exact CSS for the `.app-shot` frame — Tailwind utility string vs scoped CSS snippet vs inline `style` vs `@layer components` rule.
- Whether `useReveal` is a hook consumed by a wrapper `<Reveal>` component or a primitive that attaches directly to a `ref`.
- Whether `useScrolled` watches `window.scrollY` or an IntersectionObserver sentinel.
- Exact file boundaries for mock components — single file per mock is fine; extracting `MockWindow.tsx` helper is permitted if it simplifies three or more mocks.
- Whether `Nav` uses `<nav>` or `<header>` as its outer element.
- Shortcut chip color assignments — match the mock: ⌘R = navy, ⌘⇧R = sage, ⌘. = default, ⌘⇧S = default.
- How `CHANGELOG.md` is parsed — regex, remark, unified, or a hand-rolled line splitter.
- Whether page-level `metadata` export for `/` moves into a `src/app/metadata.ts` file or stays inline.
- Exact Tailwind arbitrary values for sizes the tokens don't cover (`0.5px`, `clamp(32px, 4vw, 44px)`).
- Whether `<Reveal>` or the hook is opt-in per element (preferred: opt-in).
- Image priority tuning — only the hero screenshot gets `preload`.

### Deferred Ideas (OUT OF SCOPE)

- Docs routing, MDX pipeline, sidebar, right-hand TOC → Phase 14
- Changelog parsing for release cards (the version-stamp helper is reused, but `/changelog` itself is Phase 15)
- Mobile hamburger / drawer nav — not in mock
- Dark-mode variants — blocked by DESIGN-04
- Analytics / tracking pixels
- Custom domain
- Any copy from `chronicle-mock.css` semantic classes — mock CSS is reference-only
- The mock's `#tweaks` dev overlay
- OWNER placeholder replacement in `SUFeedURL` / `release-dmg.yml`
- Fresh app screenshot capture
- Translations, pricing, testimonials, email capture
- `MockWindow` wrapper — optional
- Playwright / visual-regression tests
- OG image refresh

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LAND-01 | Hero with Spectral headline + one-line value prop + primary "Download for macOS" CTA | Hero variant C in `design/.../index.html` lines 229-253; Spectral `font-serif` utility produces from the existing `@theme inline --font-serif` token in `globals.css`; `Button variant="primary"` exists in `ui/Button.tsx` ready to use; hero eyebrow + headline + lede + CTA all copy verbatim from mock |
| LAND-02 | Primary CTA links to latest GitHub Release DMG asset | Correct URL is `https://github.com/cnewfeldt/ps-transcribe/releases/latest/download/PS%20Transcribe.dmg` (confirmed via `scripts/make_dmg.sh` line 6 and `.github/workflows/release-dmg.yml` line 140); store as constant in `src/lib/site.ts` so Footer's "Download DMG" link reuses the same source |
| LAND-03 | Hero or adjacent section embeds a product screenshot of the Chronicle UI | `design/ps-transcribe-web-unzipped/assets/app-screenshot.png` exists (2260×1408 PNG, 108 KB); copy to `website/public/app-screenshot.png`; render with `next/image` + `preload={true}` (Next 16 replaces `priority`) inside the `.app-shot` frame |
| LAND-04 | Feature blocks describe dual-stream capture, chat-bubble transcript, Obsidian save-to-vault, Notion auto-send | All four features are in the mock as `<div class="feature">` blocks; each has a `meta` label, `h3.h-feature` sub-headline, `p.body` paragraph, and a `<ul>` of three bullets. Mini-mockups match: DualStream (2-col bar meters), ChatBubble (speaker rows), ObsidianVault (tree + YAML frontmatter), NotionTable (DB rows with `.new` highlight) |
| LAND-05 | Shortcuts callout shows ⌘R, ⌘⇧R, ⌘., ⌘⇧S as JetBrains Mono key chips | Mock lines 467-502; `.kbd` styles in `chronicle-mock.css` (min-width 22px, JetBrains Mono 12px, 0.5px rule-strong border, 4px radius). Variant colors: `.kbd--navy` (accent-tint bg + accent-ink fg), `.kbd--sage` (spk2-bg + spk2-fg). Assignments: ⌘R = navy, ⌘⇧R = sage, ⌘. + ⌘⇧S = default |
| LAND-06 | Top nav has links to Docs, Changelog, GitHub | Mock lines 217-226; links hit `/docs` and `/changelog` (both 404 locally until Phases 14/15; that's acceptable per CONTEXT) and `https://github.com/cnewfeldt/ps-transcribe` |
| LAND-07 | Footer contains copyright, MIT license acknowledgment, and quick links | Mock lines 524-549 — three-column grid: brand blurb + © 2026 + "Released under MIT" line, Product col (Docs/Changelog/Download DMG/Sparkle appcast), Source col (GitHub repo/Report issue/Acknowledgements/License · MIT). Quick-links target all four LAND-06 destinations |

</phase_requirements>

## Project Constraints (from CLAUDE.md)

The user's global CLAUDE.md (Opus 4.7, 1M context) encodes the following directives that bear on Phase 13:

1. **Inspect before proposing.** Every claim about a file's contents in this research was verified by reading the file (not inferred from file names or training memory).
2. **Build only what's requested.** Phase 13 covers seven mock sections + two shared layout components + four mini-mockups + two hooks + one changelog helper + one site-constants file. No extras. No speculative abstractions. No `MockWindow` unless three+ mocks share chrome (D-specifics permits, doesn't require).
3. **Verification before completion.** Every success criterion (LAND-01 through LAND-07) maps to a deterministic check — see Validation Architecture section.
4. **Never suppress errors.** The changelog parser must throw (not silently fallback) if `CHANGELOG.md` is missing or malformed at build time. A build-time failure is the correct behavior; shipping a landing page with blank version info would be a regression.
5. **Hairlines are 0.5px.** Phase 12 specifics already encode this; Phase 13 continues it. Do not "fix" `border-[0.5px]` to `border`.
6. **Copy is editorial.** The communication rule "never use em dashes" applies to assistant responses and internal docs, NOT to production marketing copy inside the site itself. The mock uses em-dashes deliberately ("Markdown with YAML frontmatter dropped into the folder you configure. Optional one-click send to a Notion database.", "We're a small indie shop — we ship fast, we fix fast.", etc.). Ship them as written.
7. **No attribution in git commits.** Any Phase 13 commits must not carry `Co-Authored-By: Claude ...` or the "🤖 Generated with Claude Code" footer. Applies to the plan-generation commits, implementation commits, and any verification scripts.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `next` | `16.2.4` | App Router framework, `next/image`, `next/font`, Metadata API, `ImageResponse` | [VERIFIED: `website/package.json` line 15]. Already installed. Phase 13 does not add a newer version. |
| `react` | `19.2.4` | Server components by default, `"use client"` for hooks | [VERIFIED: `website/package.json` line 16]. Client boundary pattern is load-bearing for this phase. |
| `react-dom` | `19.2.4` | DOM reconciler | [VERIFIED: `website/package.json` line 17] |
| `tailwindcss` | `^4` (resolved `4.x`) | CSS-first utility framework; no `tailwind.config.ts` | [VERIFIED: `website/package.json` line 26]. All theme config in `globals.css` via `@theme inline`. |
| `@tailwindcss/postcss` | `^4` | PostCSS integration for Tailwind v4 | [VERIFIED: `website/package.json` line 20] |
| `typescript` | `^5` | Strict TS, Phase 11 config | [VERIFIED: `website/package.json` line 27] |

### Supporting (zero new dependencies)

| Need | Solution | Reasoning |
|------|----------|-----------|
| Build-time markdown parse for CHANGELOG.md | Hand-rolled regex in `src/lib/changelog.ts` (Node `fs.readFileSync` at module scope) | [VERIFIED: project conventions per CONTEXT D-specifics]. No `remark`, `unified`, `gray-matter`, `marked`, or `mdx-bundler` dependency. The shape we need is trivial to extract — top-level `## [X.Y.Z] — YYYY-MM-DD` heading, then `###` subsection headings, then `-`-prefixed bullets. Adding a markdown library here would bloat the bundle and create a second source of truth with Phase 14's MDX pipeline (which will install `remark`/`rehype` plugins of its own). |
| IntersectionObserver hook | `useEffect` + native `IntersectionObserver` (`"use client"` component) | [CITED: MDN `IntersectionObserver`]. First-class browser API; no library. Honors `window.matchMedia('(prefers-reduced-motion: reduce)')` for the motion-safe fallback. |
| Scroll listener for Nav | `useEffect` + `window.addEventListener('scroll', ..., { passive: true })` | [VERIFIED: mock line 586]. Already passive. IntersectionObserver sentinel is a valid alternative (Claude's discretion) — my recommendation is `scrollY` because it's simpler and the threshold (6px) is far too small for an observer's `rootMargin` to give useful hysteresis. |
| Class composition | Template-literal string concatenation (existing Phase-12 pattern) | [VERIFIED: `website/src/components/ui/Button.tsx` lines 15-21]. No `cn()` / `clsx` needed; the existing primitives work without it and adding it mid-phase creates a half-migrated codebase. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-rolled changelog regex | `remark-parse` + custom visitor | Library adds ~80KB to build dep tree; our needs (split by `## [x.y.z] — date`, group by `###`, collect `-` bullets) are ~40 lines of code. Phase 15 may reach for unified when it needs to render full markdown-to-HTML, but the metadata-extraction helper can stay regex-based. |
| `next/image` with `preload={true}` | `<img>` with `loading="eager"` + manual srcset | `next/image` auto-generates WebP/AVIF responsive sources, emits the `<link rel="preload">` tag, and enforces layout-stable reservation via `width`/`height`. [CITED: `node_modules/next/dist/docs/01-app/03-api-reference/02-components/image.md` line 274] |
| Writing a `<Reveal>` wrapper component | Single `useReveal(ref)` hook used inline | Wrapper is cleaner for the ~6 opt-in elements (3 strip cards, 4 feature blocks, 1 final CTA). Recommendation: ship `<Reveal>` that accepts `children` and applies the `data-reveal` + transition classes. Hook `useReveal()` is a one-liner inside it. |

**Installation:**

```bash
# No new npm dependencies needed. Phase 13 is pure React + Next + Tailwind + existing primitives.
cd website
pnpm install   # confirms lockfile still matches; no new packages
```

**Version verification:**

```
$ jq '.dependencies, .devDependencies' website/package.json
```

Confirms: `next@16.2.4`, `react@19.2.4`, `react-dom@19.2.4`, `tailwindcss@^4`, `@tailwindcss/postcss@^4`, `typescript@^5`. [VERIFIED: `website/package.json`]

## Architecture Patterns

### Recommended Project Structure

```
website/src/
├── app/
│   ├── layout.tsx            # MODIFY: mount <Nav /> + <Footer />; add Spectral italic style; update root metadata
│   ├── page.tsx              # REWRITE wholesale: imports Hero, ThreeThingsStrip, Feature blocks x4, ShortcutGrid, FinalCTA
│   ├── globals.css           # NO CHANGE (Phase 12 tokens are sufficient)
│   ├── design-system/        # unchanged
│   ├── opengraph-image.tsx   # unchanged
│   ├── sitemap.ts            # unchanged (already lists `/`)
│   ├── robots.ts             # unchanged
│   ├── manifest.ts           # unchanged
│   └── [metadata updates happen in layout.tsx]
├── components/
│   ├── ui/                   # unchanged (reuse Button, Card, MetaLabel, SectionHeading, CodeBlock)
│   ├── layout/
│   │   ├── Nav.tsx           # NEW: client component (scrolled state via useScrolled)
│   │   └── Footer.tsx        # NEW: server component
│   ├── sections/
│   │   ├── Hero.tsx          # NEW: server component with app-shot figure
│   │   ├── ThreeThingsStrip.tsx  # NEW: server component
│   │   ├── FeatureBlock.tsx  # NEW: server component with tint prop and alternating layout
│   │   ├── ShortcutGrid.tsx  # NEW: server component with KeyChip subcomponent
│   │   └── FinalCTA.tsx      # NEW: server component with led-dot stamp
│   ├── mocks/
│   │   ├── DualStreamMock.tsx    # NEW: server component, 12-bar meters x 2
│   │   ├── ChatBubbleMock.tsx    # NEW: server component, 3 bubbles
│   │   ├── ObsidianVaultMock.tsx # NEW: server component, tree + file pane + YAML
│   │   ├── NotionTableMock.tsx   # NEW: server component, 3 table rows w/ .new highlight
│   │   └── MockWindow.tsx        # OPTIONAL: shared titlebar chrome (D-specifics permits)
│   └── motion/
│       └── Reveal.tsx        # NEW: client component, opt-in wrapper for scroll reveal
├── hooks/
│   ├── useScrolled.ts        # NEW: client hook for Nav
│   └── useReveal.ts          # NEW: client hook consumed by <Reveal>
├── lib/
│   ├── site.ts               # NEW: shared constants (repo URL, DMG URL, appcast URL, MIT line)
│   └── changelog.ts          # NEW: build-time CHANGELOG.md parser; Phase 15 will reuse
└── public/
    └── app-screenshot.png    # NEW: copied from design/.../assets/
```

**Why this layout:**

- `src/components/layout/` is reserved for chrome shared across every route (Nav, Footer). Phase 14 (docs) and Phase 15 (changelog) get these for free via `layout.tsx`.
- `src/components/sections/` is landing-only. Phase 14 won't import these.
- `src/components/mocks/` holds the four mini-mockups. They could live under `sections/` but extracting them makes the `FeatureBlock` file small and the mocks independently navigable/testable.
- `src/hooks/` is new — no hooks shipped in Phases 11 or 12. Naming follows React convention (`useX.ts`).
- `src/lib/` is new — `site.ts` holds the canonical `SITE.REPO_URL` / `SITE.DMG_URL` / `SITE.APPCAST_URL` constants so any future owner rename is a one-line change. `changelog.ts` is the build-time helper.
- `website/public/app-screenshot.png` is the one new static asset; `next/image` resolves `/app-screenshot.png` from the site root.

### Pattern 1: Server Components by Default, `"use client"` Only Where Needed

**What:** In the App Router, every component is a Server Component unless the file starts with `"use client"`. Server components can't use hooks, refs, or browser-only APIs (no `useEffect`, no `window`, no `document`).

**When to use:** Apply `"use client"` only to the leaves that need it. Server components are cheaper (no JS shipped to the client) and static by default.

**Concrete mapping for Phase 13:**

| Component | Server or Client? | Why |
|-----------|-------------------|-----|
| `Nav.tsx` | Client (`"use client"`) | Uses `useScrolled()` which calls `window.addEventListener` |
| `Footer.tsx` | Server | Pure JSX; links only |
| `Hero.tsx` | Server | `next/image` is server-compatible; no hooks |
| `ThreeThingsStrip.tsx` | Server | Static JSX; wrap the three cards in `<Reveal>` to opt-in to fade |
| `FeatureBlock.tsx` | Server | Layout component; children are static |
| `ShortcutGrid.tsx` | Server | Static JSX |
| `FinalCTA.tsx` | Server | Static JSX |
| All four `Mock.tsx` | Server | Static JSX with inline styles for bar heights |
| `Reveal.tsx` | Client (`"use client"`) | Needs `useEffect` + IntersectionObserver + refs |
| `MockWindow.tsx` (optional) | Server | Static chrome |

**Example:**

```tsx
// Source: repo convention + Next 16 docs
// src/components/layout/Nav.tsx
"use client"

import Link from "next/link"
import { useScrolled } from "@/hooks/useScrolled"
import { SITE } from "@/lib/site"

export function Nav() {
  const scrolled = useScrolled(6)
  return (
    <header
      className={`sticky top-0 z-50 backdrop-blur-[8px] backdrop-saturate-150 transition-[border-color] duration-[160ms] border-b-[0.5px] ${
        scrolled ? "border-rule bg-paper/92" : "border-transparent bg-paper/92"
      }`}
    >
      <div className="mx-auto max-w-[1200px] px-10 md:px-10 flex items-center justify-between h-16">
        <Link href="/" className="font-serif text-[19px] tracking-[-0.01em] text-ink font-medium no-underline">
          <span className="inline-block w-[6px] h-[6px] rounded-full bg-accent-ink mr-2 align-[3px]" />
          PS&nbsp;Transcribe
        </Link>
        <nav className="flex items-center gap-7">
          <Link className="font-mono text-[12px] tracking-[0.06em] uppercase text-ink-muted hover:text-ink" href="/docs">Docs</Link>
          <Link className="font-mono text-[12px] tracking-[0.06em] uppercase text-ink-muted hover:text-ink" href="/changelog">Changelog</Link>
          <a className="font-mono text-[12px] tracking-[0.06em] uppercase text-ink-muted hover:text-ink" href={SITE.REPO_URL}>GitHub</a>
        </nav>
      </div>
    </header>
  )
}
```

### Pattern 2: Build-time Filesystem Read via `fs.readFileSync` at Module Scope

**What:** Next.js 16 App Router supports reading arbitrary files from the project during the server build. `process.cwd()` resolves to the Next.js project directory (`/website`), so the CHANGELOG at the repo root is `../CHANGELOG.md`.

**When to use:** For data derived from files in the repo that don't change between builds. Evaluates once at build time (`next build`); results are cached in the output.

**Verification:** [CITED: `node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/01-metadata/opengraph-image.md` line 113] confirms `process.cwd()` is the Next.js project directory. [CITED: `node_modules/next/dist/docs/01-app/01-getting-started/08-caching.md` line 238] confirms `fs.readFileSync` pattern is documented and supported.

**Example:**

```tsx
// Source: Next.js 16 docs + project convention
// src/lib/changelog.ts
import fs from "node:fs"
import path from "node:path"

export type ChangelogSection = { title: string; items: string[] }
export type ChangelogEntry = {
  version: string       // "2.1.0"
  versionShort: string  // "2.1" (version minus trailing .0 if present)
  date: string          // "2026-04-20"
  dateHuman: string     // "Apr 20, 2026"
  sections: ChangelogSection[]
}

const RE_VERSION = /^##\s*\[([^\]]+)\]\s*[—-]\s*(\d{4}-\d{2}-\d{2})\s*$/
const RE_SECTION = /^###\s+(.+)$/
const RE_BULLET = /^-\s+(.+)$/

let cached: ChangelogEntry[] | null = null

export function getAllReleases(): ChangelogEntry[] {
  if (cached) return cached
  const raw = fs.readFileSync(path.join(process.cwd(), "..", "CHANGELOG.md"), "utf8")
  const lines = raw.split("\n")
  const entries: ChangelogEntry[] = []
  let current: ChangelogEntry | null = null
  let currentSection: ChangelogSection | null = null

  for (const line of lines) {
    const v = line.match(RE_VERSION)
    if (v) {
      current = {
        version: v[1],
        versionShort: v[1].replace(/\.0$/, ""),
        date: v[2],
        dateHuman: humanDate(v[2]),
        sections: [],
      }
      currentSection = null
      entries.push(current)
      continue
    }
    if (!current) continue
    const s = line.match(RE_SECTION)
    if (s) {
      currentSection = { title: s[1].trim(), items: [] }
      current.sections.push(currentSection)
      continue
    }
    if (!currentSection) continue
    const b = line.match(RE_BULLET)
    if (b) currentSection.items.push(b[1].trim())
  }

  cached = entries
  return entries
}

export function getLatestRelease(): ChangelogEntry {
  const all = getAllReleases()
  if (!all.length) throw new Error("CHANGELOG.md contains no releases")
  return all[0]
}

function humanDate(iso: string): string {
  const [y, m, d] = iso.split("-").map(Number)
  const names = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
  return `${names[m - 1]} ${d}, ${y}`
}
```

Consumed in `Hero.tsx`:

```tsx
import { getLatestRelease } from "@/lib/changelog"

export function Hero() {
  const release = getLatestRelease()
  // release.versionShort = "2.1", release.dateHuman = "Apr 20, 2026", release.version = "2.1.0"
  return (
    // ...
    <MetaLabel className="text-accent-ink">Ver {release.versionShort} · Released {release.dateHuman}</MetaLabel>
    // ...
  )
}
```

### Pattern 3: Client Hook for Scroll Position

```tsx
// Source: repo convention + MDN
// src/hooks/useScrolled.ts
"use client"

import { useEffect, useState } from "react"

export function useScrolled(threshold: number = 6): boolean {
  const [scrolled, setScrolled] = useState(false)
  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > threshold)
    onScroll()
    document.addEventListener("scroll", onScroll, { passive: true })
    return () => document.removeEventListener("scroll", onScroll)
  }, [threshold])
  return scrolled
}
```

### Pattern 4: Reveal-on-Scroll Hook with Reduced-Motion Fallback

```tsx
// Source: repo convention + MDN IntersectionObserver, prefers-reduced-motion
// src/hooks/useReveal.ts
"use client"

import { useEffect, useRef, useState } from "react"

export function useReveal<T extends HTMLElement = HTMLDivElement>() {
  const ref = useRef<T | null>(null)
  const [visible, setVisible] = useState(false)

  useEffect(() => {
    // Fallback: prefers-reduced-motion → immediately visible, no observer.
    if (typeof window !== "undefined" &&
        window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      setVisible(true)
      return
    }
    const el = ref.current
    if (!el) return
    const io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (e.isIntersecting) {
            setVisible(true)
            io.unobserve(e.target)
          }
        }
      },
      { threshold: 0.12 }
    )
    io.observe(el)
    return () => io.disconnect()
  }, [])

  return { ref, visible }
}
```

```tsx
// src/components/motion/Reveal.tsx
"use client"

import type { ReactNode } from "react"
import { useReveal } from "@/hooks/useReveal"

export function Reveal({ children, className = "" }: { children: ReactNode; className?: string }) {
  const { ref, visible } = useReveal<HTMLDivElement>()
  return (
    <div
      ref={ref}
      className={`transition-[opacity,transform] duration-500 ease-out ${
        visible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-[14px]"
      } ${className}`.trim()}
      data-reveal={visible ? "in" : "out"}
    >
      {children}
    </div>
  )
}
```

### Anti-Patterns to Avoid

- **Importing `design/ps-transcribe-web-unzipped/assets/chronicle-mock.css` into `/website`.** Phase 12 policy (D-12) is explicit: reference-only. Use Phase-12 Tailwind utilities and arbitrary values for anything the tokens don't cover.
- **Re-declaring Chronicle tokens in Phase 13.** `globals.css` already has the full 16-color palette, 5 radii, and 3 shadows. Don't add more.
- **Using `priority` on `<Image>`.** Deprecated in Next 16 — use `preload={true}`.
- **Using `direction: rtl` for alternating feature blocks.** D-12 explicitly rejects it ("rtl leaks into nested text content"). Use Tailwind `order-*` on the grid children.
- **Wrapping the entire page in `<Reveal>`.** Opt-in per section (D-specifics + D-19). Wrap the three strip cards, the four feature blocks, and the final CTA. Leave the hero visible from the start (it's above the fold).
- **Canvas / SVG animation in mock components.** D-11 forbids it.
- **Client-side fetching of the GitHub release.** D-15 mandates build-time from `CHANGELOG.md`. Do not call `fetch('https://api.github.com/repos/...')` in a server or client component.
- **Creating a new `metadata.ts` file because CONTEXT.md references one.** That file doesn't exist. Update the `metadata` export in `layout.tsx` directly (or create the file and re-export — both work; `layout.tsx` is simpler).
- **Introducing `cn()` / `clsx` mid-phase.** Phase 12 components don't use it. Keep the existing template-literal pattern for consistency.
- **Loading a fresh screenshot from `design/`.** Next.js build won't reach outside the `/website` directory for static assets. Copy to `website/public/app-screenshot.png` first (D-05).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Responsive image with WebP/AVIF + srcset + preload link | A custom `<img>` + `<source>` element with a manual sizes list | `next/image` with `preload={true}` | Next 16 handles the entire responsive pipeline, including automatic format negotiation per `Accept` header |
| Asset URL from `/public` directory | Relative `./public/...` path | `/app-screenshot.png` (Next.js serves `/public/**` at the root) | Standard Next convention; anything else breaks when deployed |
| Font loading with variable exposure | Custom `<link rel="preconnect">` + `<link rel="stylesheet">` + `@font-face` | `next/font/google` (already wired in `layout.tsx`) | Self-hosted, zero Google network requests per [CITED: `node_modules/next/dist/docs/01-app/03-api-reference/02-components/font.md` line 13] |
| Passing class lists around | String manipulation + conditional logic inline | Template literals with `${...}` interpolation (existing Phase-12 pattern) | Consistent with `ui/Button.tsx`, `ui/Card.tsx`, etc. |
| IntersectionObserver fallback for old browsers | Polyfill injection | Nothing — Safari 12.1+, Chrome 51+, Firefox 55+ all support natively | Our deploy target is Vercel (modern browsers only); the mock already uses native IO |
| Build-time JSON caching / `unstable_cache` wrapping | `unstable_cache(async () => {...})` around the changelog parse | Module-scope `let cached: X \| null = null` (standard Node pattern) | The file is read once per build; `unstable_cache` is for request-scoped caching, not build-time memoization |

**Key insight:** Everything Phase 13 needs is either already in Next 16 + React 19 + the existing Phase-12 tokens/primitives, or is 20-60 lines of hand-rolled hook/helper code. No npm installs.

## Runtime State Inventory

This is NOT a rename/refactor phase — it's a greenfield landing page build. Section intentionally omitted per the research-agent schema ("Include this section for rename/refactor/migration phases only. Omit entirely for greenfield phases.").

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js 22.x | `next build`, `pnpm install`, `fs.readFileSync` | ✓ | per `.nvmrc` (Phase 11 D-03) | — |
| pnpm | All build/dev commands | ✓ | Phase 11 D-01 pinned as package manager | — |
| `next@16.2.4` | Build, `next/image`, `next/font`, Metadata API | ✓ | `website/package.json` | — |
| `react@19.2.4`, `react-dom@19.2.4` | UI rendering | ✓ | `website/package.json` | — |
| `tailwindcss@^4` + `@tailwindcss/postcss@^4` | CSS utilities | ✓ | `website/package.json` | — |
| `CHANGELOG.md` at repo root | Build-time version fetch (D-15) | ✓ | file exists, top entry is `[2.1.0] — 2026-04-20` | — |
| `design/ps-transcribe-web-unzipped/assets/app-screenshot.png` | Hero screenshot (D-05) | ✓ | 2260×1408 PNG, 108 KB | — |
| Vercel build environment | Auto-deploys website changes (Phase 11) | ✓ | Phase 11 D-07 | — |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** none.

**Conclusion:** Phase 13 has zero environment blockers. The planner can proceed directly to task creation.

## Common Pitfalls

### Pitfall 1: Using `priority` on `next/image`
**What goes wrong:** The hero screenshot ships but Next 16 emits a console deprecation warning, or (worse) silently falls back to lazy loading.
**Why it happens:** Next 16 renamed `priority` to `preload`. Training data from Next 13/14/15 says `priority`.
**How to avoid:** Use `preload={true}`. [CITED: `node_modules/next/dist/docs/01-app/03-api-reference/02-components/image.md` line 293]
**Warning signs:** Lighthouse LCP warnings in the build output; the hero image not appearing in `<link rel="preload">` in the rendered HTML.

### Pitfall 2: Wrong DMG URL
**What goes wrong:** The "Download for macOS" button 404s because `PS-Transcribe.dmg` doesn't exist — the real filename is `PS Transcribe.dmg` (URL-encoded `PS%20Transcribe.dmg`).
**Why it happens:** CONTEXT.md D-13 says `PS-Transcribe.dmg`. The actual `scripts/make_dmg.sh` produces `dist/PS Transcribe.dmg` (with a space). The release workflow URL-encodes it as `%20`.
**How to avoid:** Use `https://github.com/cnewfeldt/ps-transcribe/releases/latest/download/PS%20Transcribe.dmg` — store as `SITE.DMG_URL` in `src/lib/site.ts` so the Footer "Download DMG" and the Final CTA primary button both consume the same constant.
**Warning signs:** Clicking the CTA in a preview deploy returns "Not Found" from GitHub.

### Pitfall 3: macOS version string inaccuracy
**What goes wrong:** Hero note and Final CTA note read "macOS 14+ · Apple Silicon & Intel" — both wrong. Real minimum is macOS 26.0 (per `Package.swift`), Intel is not supported (per README badge: `Apple Silicon - Required`).
**Why it happens:** Mock was authored before the macOS-26 platform bump landed. Mock copy is verbatim per D-03, but D-specifics explicitly overrides verbatim when factual correctness is at stake.
**How to avoid:** Ship the string `"macOS 26+ · Apple Silicon · Free & open source"` in both hero note and Final CTA note. Store as `SITE.OS_REQUIREMENTS` in `src/lib/site.ts` so both callers agree.
**Warning signs:** Users with Sonoma-era Macs try to download and get a "cannot be opened on this version of macOS" error.

### Pitfall 4: Spectral italic synthesized, not loaded
**What goes wrong:** The hero headline's `<em>never leaves your Mac.</em>` renders as CSS-synthesized italic (slant applied algorithmically), not the real Spectral italic cut. The difference is visible — real italics have different letterforms (especially lowercase `a`, `e`, `g`).
**Why it happens:** `layout.tsx` loads `Spectral({ weight: ['400', '600'] })` with no `style` option. Defaults to `style: 'normal'` only. Browser synthesizes the italic for `<em>`.
**How to avoid:** Update the Spectral loader to `Spectral({ subsets: ['latin'], display: 'swap', weight: ['400', '600'], style: ['normal', 'italic'], variable: '--font-spectral' })`. [CITED: `node_modules/next/dist/docs/01-app/03-api-reference/02-components/font.md` line 142]
**Warning signs:** Hero italic reads "leaned" rather than "italic"; letterforms look identical to upright Spectral just slanted.

### Pitfall 5: Module-scope `fs.readFileSync` in a Client Component
**What goes wrong:** `next build` fails with `fs.readFileSync is not a function` or `Module not found: Can't resolve 'fs'`. This happens if someone accidentally puts the changelog helper behind `"use client"`.
**Why it happens:** Node's `fs` module has no browser-side shim. Client components run in the browser bundle where `fs` doesn't exist.
**How to avoid:** Keep `src/lib/changelog.ts` free of `"use client"` and import it from server components only (Hero, FinalCTA, Footer — all server by default).
**Warning signs:** Build error at module resolution; `Hero.tsx` unintentionally marked `"use client"`.

### Pitfall 6: `.app-shot` frame not clipping the image
**What goes wrong:** The 12px-radius frame is visible, but the image itself is rendered with square corners bleeding past the frame's rounding.
**Why it happens:** `next/image` wraps the `<img>` in a `<span>` (or similar) and applies its own styles. `overflow: hidden` on the parent isn't always sufficient depending on where the rounding lives.
**How to avoid:** Apply `rounded-[12px] overflow-hidden` to the `<figure>` that contains the `<Image>`, and set `className="block w-full h-auto"` on the `Image` itself. The mock's CSS uses the same pattern — `figure.app-shot { border-radius: 12px; overflow: hidden; }` plus `.app-shot img { display: block; width: 100%; height: auto; }`.
**Warning signs:** Visible square corners over rounded frame at high zoom.

### Pitfall 7: Feature alternation broken on mobile
**What goes wrong:** On narrow viewports the `order-*` classes keep mock-left on Feature 2, so the mock appears before the copy in a stacked layout where the user expects "heading first, then supporting imagery."
**Why it happens:** `order-*` applies at all breakpoints unless scoped. The mock uses `@media (max-width: 900px) { .feature { grid-template-columns: 1fr; gap: 28px; direction: ltr; } }` — note the `direction: ltr` reset.
**How to avoid:** Use responsive order utilities: `order-2 lg:order-1` for copy in even-indexed features, `order-1 lg:order-2` for mock. On mobile (single column), copy always comes first; on desktop, alternation kicks in.
**Warning signs:** Mobile flow reads Mock → Copy → Mock → Copy → … which is disorienting.

### Pitfall 8: Nav backdrop-blur invisible on older Safari
**What goes wrong:** The scrolled-state translucent blur doesn't render on Safari 13-.
**Why it happens:** `backdrop-filter` needs `-webkit-backdrop-filter` too. Tailwind v4's `backdrop-blur-*` utilities emit both, but arbitrary values like `backdrop-blur-[8px]` need verification.
**How to avoid:** Use `backdrop-blur-[8px] backdrop-saturate-150` (which Tailwind emits with both prefixes) and accept that pre-Safari-14 users see a slightly more opaque `paper/92` background — still readable, just not frosty.
**Warning signs:** Nav looks opaque on some test devices.

### Pitfall 9: Build-time changelog parse fails silently
**What goes wrong:** A malformed CHANGELOG.md (e.g., missing date in heading) causes the parser to skip that entry, and the hero shows an older version than actually shipped.
**Why it happens:** Defensive-by-default parsing that swallows errors. Violates CLAUDE.md sacred rule "never suppress errors."
**How to avoid:** `getLatestRelease()` throws explicitly if no entries parse. Let `next build` fail so the developer sees the error, rather than shipping stale data.
**Warning signs:** Wrong version stamp on the production page.

### Pitfall 10: `<Reveal>` wrapping breaks server-only content
**What goes wrong:** Wrapping a server component that contains an image or a child that can't be serialized — React may warn about serialization boundaries.
**Why it happens:** `<Reveal>` is a client component (`"use client"`). When it wraps server components, React must serialize the children across the boundary. This usually works for plain JSX, but breaks if children are functions or non-plain objects.
**How to avoid:** Only wrap plain JSX subtrees (divs, text, images via the `next/image` component — `next/image` is serialization-safe). Pass children as nodes, not as render functions.
**Warning signs:** Build-time error about "Only plain objects can be passed to Client Components from Server Components."

## Code Examples

### Example 1: `src/lib/site.ts` — shared constants

```tsx
// Source: project convention; single source of truth for every URL.
// All owner/repo renames become a one-line change here.
export const SITE = {
  OWNER: "cnewfeldt",
  REPO: "ps-transcribe",
  REPO_URL: "https://github.com/cnewfeldt/ps-transcribe",
  DMG_URL: "https://github.com/cnewfeldt/ps-transcribe/releases/latest/download/PS%20Transcribe.dmg",
  APPCAST_URL: "https://github.com/cnewfeldt/ps-transcribe/releases.atom",
  ISSUES_URL: "https://github.com/cnewfeldt/ps-transcribe/issues/new",
  LICENSE_URL: "https://github.com/cnewfeldt/ps-transcribe/blob/main/LICENSE",
  ACKNOWLEDGEMENTS_URL: "https://github.com/cnewfeldt/ps-transcribe#acknowledgments",
  OS_REQUIREMENTS: "macOS 26+ · Apple Silicon · Free & open source",
  OS_REQUIREMENTS_FINAL_CTA: "Free · Open source · macOS 26+ (Apple Silicon)",
} as const
```

### Example 2: `src/components/sections/Hero.tsx` — server component with `.app-shot` frame

```tsx
// Source: port of mock lines 229-253, hero variant C.
import Image from "next/image"
import { Button, MetaLabel } from "@/components/ui"
import { getLatestRelease } from "@/lib/changelog"
import { SITE } from "@/lib/site"

export function Hero() {
  const release = getLatestRelease()
  return (
    <section className="pt-14 pb-10 md:pt-14 md:pb-10" id="hero">
      <div className="mx-auto max-w-[1200px] px-10">
        <div className="grid grid-cols-1 gap-10 text-center">
          <div className="max-w-[920px] mx-auto">
            <div className="inline-flex items-center gap-[10px] mb-[22px] flex-wrap justify-center">
              <span
                className="w-[6px] h-[6px] rounded-full bg-live-green"
                style={{ boxShadow: "0 0 0 2px rgba(74,138,94,0.15)" }}
                aria-hidden
              />
              <MetaLabel className="text-accent-ink whitespace-nowrap">
                Ver {release.versionShort} · Released {release.dateHuman}
              </MetaLabel>
            </div>
            <h1 className="font-serif font-normal text-[clamp(44px,6vw,68px)] leading-[1.08] tracking-[-0.015em] text-ink text-balance">
              Your meeting audio<br />
              <em className="italic text-accent-ink">never leaves your Mac.</em>
            </h1>
            <p className="mt-6 mx-auto font-sans text-[18px] leading-[1.55] text-ink-muted max-w-[54ch] text-pretty">
              A native macOS transcriber built around one idea: call recordings are private, so the software that handles them should be too. No cloud APIs. No telemetry. Nothing uploaded, ever.
            </p>
            <div className="mt-7 flex gap-[18px] items-center flex-wrap justify-center">
              <Button asChild variant="primary">
                <a href={SITE.DMG_URL}>
                  <span
                    className="w-[6px] h-[6px] rounded-full bg-rec-red"
                    style={{ boxShadow: "0 0 0 2px rgba(194,74,62,0.18)" }}
                    aria-hidden
                  />
                  Download for macOS
                </a>
              </Button>
              <Button asChild variant="secondary">
                <a href={SITE.REPO_URL}>View on GitHub →</a>
              </Button>
            </div>
            <p className="mt-[14px] font-mono text-[11px] tracking-[0.04em] text-ink-faint text-center">
              {SITE.OS_REQUIREMENTS}
            </p>
          </div>
          <div className="relative">
            <figure
              className="m-0 max-w-[1080px] mx-auto rounded-[12px] overflow-hidden border-[0.5px] border-rule-strong shadow-float bg-paper"
            >
              <Image
                src="/app-screenshot.png"
                alt="PS Transcribe — meeting transcript with Library, Transcript, and Details columns"
                width={2260}
                height={1408}
                preload
                decoding="async"
                className="block w-full h-auto"
              />
            </figure>
          </div>
        </div>
      </div>
    </section>
  )
}
```

> **Note on `Button asChild`:** The existing `Button` component spreads onto a `<button>`. For anchor semantics we need `<a>`. Options:
>
> 1. Add an `asChild` prop to `Button` that renders the prop's child wrapped with the button's styling. This is the shadcn/ui pattern and is mechanical to add.
> 2. Use the Button's className string applied directly to `<a>`.
>
> Both work. Option 2 is simpler for Phase 13 and doesn't modify the primitive. Recommended:
>
> ```tsx
> <a className="inline-flex items-center gap-2 px-4 py-[10px] rounded-btn font-sans text-[14px] font-medium leading-none bg-ink text-paper shadow-btn hover:bg-[#2a2a25] focus-visible:outline focus-visible:outline-2 focus-visible:outline-accent-ink focus-visible:outline-offset-2" href={SITE.DMG_URL}>
>   <span className="w-[6px] h-[6px] rounded-full bg-rec-red" style={{ boxShadow: "0 0 0 2px rgba(194,74,62,0.18)" }} aria-hidden />
>   Download for macOS
> </a>
> ```
>
> The planner should pick one approach and be consistent. I recommend extracting a small `LinkButton` wrapper in `src/components/ui/LinkButton.tsx` that reuses the Button class strings — keeps `Button` untouched and gives us a clean `<LinkButton variant="primary" href={...}>` API.

### Example 3: `src/components/sections/FeatureBlock.tsx` — alternating grid with tint prop

```tsx
// Source: port of mock lines 284-454, reusable for all 4 features.
import type { ReactNode } from "react"
import { MetaLabel } from "@/components/ui"
import { Reveal } from "@/components/motion/Reveal"

type Tint = "default" | "tint" | "sage"

const tintMap: Record<Tint, string> = {
  default: "bg-paper-warm border-rule",
  tint:    "bg-accent-tint border-rule",
  sage:    "bg-spk2-bg border-rule",
}

type MetaTone = "default" | "navy" | "sage"
const metaToneMap: Record<MetaTone, string> = {
  default: "",
  navy:    "text-accent-ink",
  sage:    "text-spk2-rail",
}

export function FeatureBlock({
  index,
  tint,
  metaTone = "default",
  metaLabel,
  headline,
  body,
  bullets,
  mock,
}: {
  index: number              // 0..3 — used to compute alternating layout
  tint: Tint
  metaTone?: MetaTone
  metaLabel: string
  headline: string
  body: ReactNode
  bullets: string[]
  mock: ReactNode
}) {
  const altLayout = index % 2 === 1   // odd = mock-left, copy-right
  const copyOrder  = altLayout ? "lg:order-2" : "lg:order-1"
  const mockOrder  = altLayout ? "lg:order-1" : "lg:order-2"

  return (
    <Reveal>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-14 items-center py-12">
        <div className={`min-w-0 ${copyOrder} order-1`}>
          <MetaLabel className={`${metaToneMap[metaTone]} inline-block mb-[14px]`}>{metaLabel}</MetaLabel>
          <h3 className="font-serif font-normal text-[clamp(22px,2.4vw,26px)] leading-[1.2] tracking-[-0.005em] text-ink mb-[14px]">
            {headline}
          </h3>
          <p className="font-sans text-[15px] leading-[1.65] text-ink-muted">{body}</p>
          <ul className="list-none mt-[18px] p-0 grid gap-2">
            {bullets.map((b, i) => (
              <li key={i} className={`flex gap-[10px] text-[14.5px] text-ink-muted before:content-[''] before:flex-none before:w-[5px] before:h-[5px] before:rounded-full before:mt-[9px] ${tint === "sage" ? "before:bg-spk2-rail" : "before:bg-accent-ink"}`}>
                {b}
              </li>
            ))}
          </ul>
        </div>
        <div className={`min-h-[280px] p-7 rounded-[14px] border-[0.5px] flex items-center justify-center ${tintMap[tint]} ${mockOrder} order-2`}>
          {mock}
        </div>
      </div>
    </Reveal>
  )
}
```

### Example 4: `src/components/mocks/DualStreamMock.tsx`

```tsx
// Source: port of mock lines 298-345 (Feature 1 mini).
export function DualStreamMock() {
  // 12 bars per stream; heights from the mock's inline style attributes.
  const micBars = [40, 80, 55, 90, 30, 70, 45, 85, 60, 35, 75, 50]
  const sysBars = [25, 55, 80, 40, 65, 30, 70, 85, 45, 60, 35, 55]

  return (
    <div className="w-full bg-paper border-[0.5px] border-rule-strong rounded-[8px] shadow-lift overflow-hidden text-[12px]">
      <MockTitlebar title="Session · 00:14:32" />
      <div className="p-[18px_20px] flex flex-col gap-[10px]">
        <div className="grid grid-cols-2 gap-[14px]">
          <StreamCard tone="navy" head={["Microphone", "You"]} bars={micBars} />
          <StreamCard tone="sage" head={["System audio", "Speaker 2"]} bars={sysBars} />
        </div>
        <hr className="border-0 h-[0.5px] bg-rule mt-[10px]" />
        <div className="flex justify-between font-mono text-[10px] text-ink-faint tracking-[0.05em] pt-2">
          <span>VAD · trimming silences</span>
          <span>Parakeet-TDT · on-device</span>
        </div>
      </div>
    </div>
  )
}

function StreamCard({ tone, head, bars }: { tone: "navy" | "sage"; head: [string, string]; bars: number[] }) {
  const barColor = tone === "navy" ? "bg-accent-ink" : "bg-spk2-rail"
  return (
    <div className="border-[0.5px] border-rule rounded-[8px] p-[12px] bg-paper">
      <h6 className="m-0 mb-2 font-mono text-[10px] tracking-[0.08em] uppercase text-ink-faint font-medium flex justify-between">
        <span>{head[0]}</span><span>{head[1]}</span>
      </h6>
      <div className="flex gap-[2px] h-[34px] items-end" aria-hidden>
        {bars.map((h, i) => (
          <span key={i} className={`flex-1 ${barColor} rounded-[1px]`} style={{ height: `${h}%`, opacity: 0.55 }} />
        ))}
      </div>
    </div>
  )
}

function MockTitlebar({ title }: { title: string }) {
  return (
    <div className="h-[24px] border-b-[0.5px] border-rule flex items-center gap-[6px] px-[10px]"
         style={{ background: "linear-gradient(to bottom, #F6F3EC, #EFECE3)" }}>
      <span className="w-[8px] h-[8px] rounded-full" style={{ background: "#EC6A5F" }} />
      <span className="w-[8px] h-[8px] rounded-full" style={{ background: "#F5BF4F" }} />
      <span className="w-[8px] h-[8px] rounded-full" style={{ background: "#61C554" }} />
      <b className="ml-2 font-mono font-normal text-[10px] text-ink-faint tracking-[0.04em]">{title}</b>
    </div>
  )
}
```

The other three mocks follow the same structure. Below are the exact content values to embed.

### Exact Mini-Mockup Content (Fidelity Reference)

#### DualStreamMock — `design/.../index.html` lines 298-345
- Titlebar: `Session · 00:14:32`
- Mic column header: `Microphone` / `You` (right-aligned)
- Mic bar heights (%): 40, 80, 55, 90, 30, 70, 45, 85, 60, 35, 75, 50
- Sys column header: `System audio` / `Speaker 2`
- Sys bar heights (%): 25, 55, 80, 40, 65, 30, 70, 85, 45, 60, 35, 55
- Footer split row: `VAD · trimming silences` (left) / `Parakeet-TDT · on-device` (right)
- Tint wrapper: `shot--tint` → our `tint="tint"`

#### ChatBubbleMock — lines 362-380
- Titlebar: `Chronicle · Transcript`
- Bubble 1 (them, max-width 85%): `Speaker 2` `14:22` — `Last thing — did the encoder change land?`
- Bubble 2 (me, max-width 70%): `You` `14:29` — `Yesterday. Running on main.`
- Bubble 3 (them, max-width 82%): `Speaker 2` `14:35` — `Good. Let's queue up the diarizer next sprint.`
- Bubble styles per `chronicle-mock.css` lines 149-194:
  - `me`: `bg-ink text-paper`, `rounded-[12px] rounded-br-[4px]`, `self-end`, 9px/13.5px mono-label + body
  - `them`: `bg-spk2-bg text-spk2-fg`, `rounded-[12px] rounded-bl-[4px]`, `self-start`, left rail `bg-spk2-rail` 2px × (bubble height - 16px), `pl-[15px]`, with the 5px left offset for the rail

- Tint wrapper: `shot--sage` → our `tint="sage"`

#### ObsidianVaultMock — lines 396-426
- Titlebar: embedded as the `shot` frame's content; mock uses no `.mini__bar` for this feature — the whole thing is a 2-col grid with its own frame. See the mock's `.vault` and `.vault__tree`/`.vault__file` CSS.
- Tree (2-col layout, left pane):
  ```
  Vault
    Meetings
      2026-04-20.md
      2026-04-22.md   ← active (accent-ink on accent-tint background, 4px radius, -6px/-6px margin+padding)
    Memos
      standups.md
  ```
  Tree uses `font-mono text-[11px] leading-[1.7] text-ink-muted`. `.folder` in `text-ink`. Active row uses `text-accent-ink bg-accent-tint px-[6px] py-[2px] -mx-[6px] rounded-[4px]`.
- File pane (right):
  - YAML frontmatter as `<pre>`-style text (mono, 11px, line-height 1.6, border-bottom 0.5px rule):
    ```
    ---
    date: 2026-04-22T14:02
    duration: 32m
    participants: [You, Speaker 2]
    tags: [meeting, product]
    ---
    ```
    where the keys `date`, `duration`, `participants`, `tags` are in `text-accent-ink`.
  - H6 title: `Product sync — Apr 22` (Spectral, 15px, font-weight 500)
  - Three paragraphs (12px `text-ink-muted`):
    - `**Speaker 2 · 14:22** — Last thing, did the encoder change land?`
    - `**You · 14:29** — Yesterday. Running on main.`
    - `**Speaker 2 · 14:35** — Good. Let's queue the diarizer next sprint.`
    - (Note: the bold portion uses `<strong>`, no color change; the em-dash is a real em-dash per editorial preference.)
- Tint wrapper: no `shot--*` — default `paper-warm` → our `tint="default"`

#### NotionTableMock — lines 442-454
- Outer `.mini__bar` titlebar: `Notion · Meetings DB`
- Table head row (not a thead, styled as bar): `Name` (left) / `4 properties` (right)
- Table rows (all 12px; first column `text-ink`, others `text-ink-muted`; rows separated by `border-b-[0.5px] border-rule`, last row no border):
  - Row 1: `Infra planning` | `Apr 18` | `<span class="tag">meeting</span>` | `18m`
  - Row 2: `Design review` | `Apr 19` | `<span class="tag">design</span>` | `41m`
  - Row 3 (`.new` — `bg-accent-tint text-accent-ink`): `Product sync — Apr 22` | `Just now` | `<span class="tag">product</span>` | `32m`
- `.tag` pill style per mock line 119: `inline-block font-mono text-[9px] px-[6px] py-[2px] rounded-full bg-spk2-bg text-spk2-fg tracking-[0.05em] uppercase`
- Tint wrapper: `shot--tint` → our `tint="tint"`

### Example 5: `src/components/sections/ShortcutGrid.tsx`

```tsx
// Source: port of mock lines 461-504.
import { MetaLabel, SectionHeading } from "@/components/ui"

type ChipTone = "default" | "navy" | "sage"

const chipToneMap: Record<ChipTone, string> = {
  default: "bg-paper border-rule-strong text-ink",
  navy:    "bg-accent-tint text-accent-ink border-[rgba(43,74,122,0.22)]",
  sage:    "bg-spk2-bg text-spk2-fg border-[rgba(127,160,147,0.4)]",
}

function KeyChip({ tone = "default", children }: { tone?: ChipTone; children: string }) {
  return (
    <span className={`inline-flex items-center justify-center min-w-[22px] px-[6px] py-[3px] font-mono text-[12px] border-[0.5px] border-b-[1px] rounded-[4px] ${chipToneMap[tone]}`}>
      {children}
    </span>
  )
}

export function ShortcutGrid() {
  return (
    <section className="py-16 md:py-16">
      <div className="mx-auto max-w-[1200px] px-10">
        <div className="mb-[22px]">
          <MetaLabel>Keyboard-first</MetaLabel>
          <SectionHeading className="mt-[10px]">Four shortcuts is all it takes.</SectionHeading>
        </div>
        <div className="bg-accent-tint rounded-[12px] px-8 py-7 grid grid-cols-2 lg:grid-cols-4 gap-6 items-center">
          <Shortcut keys={[{ tone: "navy", k: "⌘" }, { tone: "navy", k: "R" }]} lbl="Start meeting" desc="Records mic + system audio." />
          <Shortcut keys={[{ tone: "sage", k: "⌘" }, { tone: "sage", k: "⇧" }, { tone: "sage", k: "R" }]} lbl="Quick memo" desc="Mic only, single-speaker." />
          <Shortcut keys={[{ tone: "default", k: "⌘" }, { tone: "default", k: "." }]} lbl="Stop & save" desc="Runs VAD + diarization." />
          <Shortcut keys={[{ tone: "default", k: "⌘" }, { tone: "default", k: "⇧" }, { tone: "default", k: "S" }]} lbl="Toggle sidebar" desc="Hide library & inspector." />
        </div>
      </div>
    </section>
  )
}

function Shortcut({ keys, lbl, desc }: { keys: { tone: ChipTone; k: string }[]; lbl: string; desc: string }) {
  return (
    <div className="flex flex-col gap-2">
      <div className="flex gap-1 items-center">
        {keys.map((k, i) => <KeyChip key={i} tone={k.tone}>{k.k}</KeyChip>)}
      </div>
      <span className="font-mono text-[11px] text-ink-muted tracking-[0.04em] uppercase">{lbl}</span>
      <span className="font-serif text-[15px] text-ink">{desc}</span>
    </div>
  )
}
```

### Example 6: `src/components/layout/Footer.tsx`

```tsx
// Source: port of mock lines 524-549, server component.
import Link from "next/link"
import { SITE } from "@/lib/site"

export function Footer() {
  return (
    <footer className="border-t-[0.5px] border-rule pt-16 pb-24 mt-24 bg-paper">
      <div className="mx-auto max-w-[1200px] px-10 grid grid-cols-1 md:grid-cols-[1.2fr_1fr_1fr] gap-10 items-start">
        <div>
          <div className="font-serif font-medium text-[17px] tracking-[-0.01em] text-ink">
            <span className="inline-block w-[6px] h-[6px] rounded-full bg-accent-ink mr-2 align-[3px]" />
            PS Transcribe
          </div>
          <p className="mt-3 max-w-[34ch] font-mono text-[11px] tracking-[0.04em] text-ink-muted">
            A native macOS transcription tool. Released under MIT. Maintained as an indie side project.
          </p>
          <p className="mt-3 font-mono text-[11px] tracking-[0.04em] text-ink-muted">© 2026</p>
        </div>
        <FooterColumn title="Product">
          <Link href="/docs">Documentation</Link>
          <Link href="/changelog">Changelog</Link>
          <a href={SITE.DMG_URL}>Download DMG</a>
          <a href={SITE.APPCAST_URL}>Sparkle appcast</a>
        </FooterColumn>
        <FooterColumn title="Source">
          <a href={SITE.REPO_URL}>GitHub repository</a>
          <a href={SITE.ISSUES_URL}>Report an issue</a>
          <a href={SITE.ACKNOWLEDGEMENTS_URL}>Acknowledgements</a>
          <a href={SITE.LICENSE_URL}>License · MIT</a>
        </FooterColumn>
      </div>
    </footer>
  )
}

function FooterColumn({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <h4 className="font-mono text-[10px] uppercase tracking-[0.08em] text-ink-faint m-0 mb-[14px] font-medium">{title}</h4>
      <ul className="list-none m-0 p-0 grid gap-2 [&_a]:font-mono [&_a]:text-[11px] [&_a]:tracking-[0.04em] [&_a]:text-ink-muted [&_a]:no-underline hover:[&_a]:text-ink hover:[&_a]:underline [&_a]:underline-offset-[3px]">
        {Array.isArray(children)
          ? children.map((c, i) => <li key={i}>{c}</li>)
          : <li>{children}</li>}
      </ul>
    </div>
  )
}
```

### Example 7: Mounting Nav + Footer in the root layout

```tsx
// Modify: src/app/layout.tsx (add Nav, Footer, Spectral italic style)
// ...existing font imports...
const spectral = Spectral({
  subsets: ['latin'],
  display: 'swap',
  weight: ['400', '600'],
  style: ['normal', 'italic'],   // NEW — load the italic cut for <em>
  variable: '--font-spectral',
})

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${inter.variable} ${spectral.variable} ${jetbrainsMono.variable}`}>
      <body className="font-sans antialiased">
        <Nav />
        {children}
        <Footer />
      </body>
    </html>
  )
}
```

### Example 8: Top-level page assembly

```tsx
// REWRITE: src/app/page.tsx
import { Hero } from "@/components/sections/Hero"
import { ThreeThingsStrip } from "@/components/sections/ThreeThingsStrip"
import { FeatureBlock } from "@/components/sections/FeatureBlock"
import { ShortcutGrid } from "@/components/sections/ShortcutGrid"
import { FinalCTA } from "@/components/sections/FinalCTA"
import { DualStreamMock } from "@/components/mocks/DualStreamMock"
import { ChatBubbleMock } from "@/components/mocks/ChatBubbleMock"
import { ObsidianVaultMock } from "@/components/mocks/ObsidianVaultMock"
import { NotionTableMock } from "@/components/mocks/NotionTableMock"

export default function Home() {
  return (
    <main className="bg-paper text-ink">
      <Hero />
      <ThreeThingsStrip />
      <section className="py-16 md:py-24">
        <div className="mx-auto max-w-[1200px] px-10">
          <FeatureBlock
            index={0}
            tint="tint"
            metaLabel="Dual-stream capture"
            headline="Microphone and system audio, recorded in parallel."
            body={<>Uses ScreenCaptureKit to pull the other side of the call cleanly, while your mic is captured separately. After the session ends, Silero VAD and diarization resolve who said what.</>}
            bullets={[
              "You on mic, them via system audio — two distinct streams",
              "Voice-activity detection runs locally; silences are trimmed",
              "Post-session speaker diarization clusters unknown voices",
            ]}
            mock={<DualStreamMock />}
          />
          <hr className="border-0 h-[0.5px] bg-rule" />
          <FeatureBlock
            index={1}
            tint="sage"
            metaTone="sage"
            metaLabel="Transcript view"
            headline="Chat bubbles. Not a wall of text."
            body={<>Your side sits right; Speaker 2 sits left with a sage rail. Rename any speaker inline, and every subsequent bubble updates. Click any timestamp to scrub the session.</>}
            bullets={[
              "10pt mono timestamps, quietly recessed",
              "Inline speaker rename with ⌘E",
              "Full-text search with ⌘F, scoped to the session",
            ]}
            mock={<ChatBubbleMock />}
          />
          <hr className="border-0 h-[0.5px] bg-rule" />
          <FeatureBlock
            index={2}
            tint="default"
            metaTone="navy"
            metaLabel="Obsidian vault"
            headline="Every session lands where your notes already live."
            body={<>Markdown file, YAML frontmatter, saved to the folder you configure. No proprietary format, no export step — the transcript <em className="italic">is</em> a note in your vault, instantly linkable.</>}
            bullets={[
              "Template frontmatter: date, duration, participants, tags",
              "Configurable path templates per recording type",
              "Works with Obsidian sync, git, iCloud — whatever you already use",
            ]}
            mock={<ObsidianVaultMock />}
          />
          <hr className="border-0 h-[0.5px] bg-rule" />
          <FeatureBlock
            index={3}
            tint="tint"
            metaLabel="Notion, on send"
            headline="Push finished sessions to a database, one key away."
            body={<>Configure a Notion database once. When you stop recording, PS Transcribe can send the transcript as a new page — with the same frontmatter mapped into properties. Leave it off and nothing syncs.</>}
            bullets={[
              "Property mapping for participants, tags, duration",
              "Opt-in per recording, or default on",
              "Integration token stays in Keychain",
            ]}
            mock={<NotionTableMock />}
          />
        </div>
      </section>
      <ShortcutGrid />
      <FinalCTA />
    </main>
  )
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `next/image` `priority={true}` | `next/image` `preload={true}` | Next.js 16 | Rename only; behavior identical per Next 16 docs |
| `@media (prefers-color-scheme: dark)` variants alongside light | Single light-mode palette with `color-scheme: light` on `<html>` | Phase 12 (DESIGN-04 D-14) | Simplifies token surface by 50%; aligned with macOS app (also light-only) |
| Tailwind v3 `tailwind.config.ts` `theme.extend.colors` | Tailwind v4 `@theme inline` in `globals.css` | Phase 12; Tailwind v4 release | No JS config file; everything in CSS; utility names auto-derived from token names |
| `Inter + Spectral + JetBrains Mono` via `<link>` to Google Fonts | Same three fonts via `next/font/google` (self-hosted, no Google request at runtime) | Phase 11 | Privacy improvement; layout-stable webfont load |
| Whole-page wrapping with `<Reveal>` | Opt-in `<Reveal>` per section | Mock's original pattern + D-19 | Cheaper DOM cost; mobile-friendly |

**Deprecated / outdated:**

- `next/image` `priority` prop — deprecated in Next 16. Use `preload`.
- Tailwind v3 JIT compilation hints in a `content` array — in v4 this is replaced by automatic content detection via the `@source` directive (we don't need this explicitly; Tailwind v4 detects `src/**/*.{ts,tsx}` automatically).
- `direction: rtl` tricks for alternating layouts — use CSS grid `order` instead.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The hero eyebrow should show `Ver 2.1 · Released Apr 20, 2026` computed from the CHANGELOG's top entry. Mock hardcodes this exact string; our parser returns the same from `[2.1.0] — 2026-04-20`. | Hero / D-15 | Low — the format is trivial to adjust if the planner wants `v2.1.0` in the hero instead of `Ver 2.1`. |
| A2 | `.github/workflows/release-dmg.yml` is the only place the DMG filename is authored. No other workflow produces a different DMG asset name. | Pitfall 2, SITE.DMG_URL | Low — single grep of `.github/workflows/` confirms this is the only DMG workflow. |
| A3 | The `src/hooks/` and `src/lib/` directories are acceptable additions to the project layout. Phase 11 / 12 CONTEXT shows `src/app/`, `src/components/ui/` only; CONTEXT.md Phase 13 implies `src/hooks/` and `src/lib/` are fine but doesn't explicitly codify their locations. | Architecture Patterns | Low — the paths are conventional React/Next locations; if the planner prefers `src/lib/` replaced with `src/utils/` or similar, it's a one-line path rename. |

**Confidence assessment:** All non-assumption claims are tagged `[VERIFIED: ...]` (tool-confirmed) or `[CITED: ...]` (docs-backed). Only the three items above rely on reasonable inference; none are load-bearing enough to block planning.

## Open Questions (RESOLVED)

1. **Should Spectral italic face be loaded?** — **RESOLVED:** Plan 13-01 Task 3 adds `style: ['normal', 'italic']` to the Spectral loader in `layout.tsx`; hero `<em>` renders the real italic cut, not a synthesized slant.
   - What we know: The mock uses `<em>` in the hero headline and in Feature 3's paragraph (`the transcript <em>is</em> a note in your vault`). The current Spectral loader doesn't load italic. Synthesized italic is visibly lower-quality than the real cut.
   - What's unclear: CONTEXT.md says "DO NOT modify font loading (Phase 12 D-02)", but that decision was about not re-registering or swapping fonts — adding `style: ['normal', 'italic']` to the same loader isn't a swap.
   - Recommendation: Add `style: ['normal', 'italic']` to the Spectral loader in `layout.tsx`. Flag this to the planner as a fidelity fix rather than a font-loading change. If the planner wants to keep the strict reading, ship synthesized italic — the hero still works; the fidelity is just lower.

2. **Should `Button` gain `asChild` or should we add a separate `LinkButton`?** — **RESOLVED:** Plan 13-02 Task 1 ships `src/components/ui/LinkButton.tsx` reusing `Button` class strings; Phase-12 `Button` primitive is untouched.
   - What we know: Phase 12's `Button` renders a `<button>`. Both primary CTAs on the landing page are links (DMG download, GitHub repo, Final CTA download) — so they need `<a>` semantics.
   - What's unclear: Adding `asChild` is a minor API change to an existing primitive; extracting `LinkButton` keeps `Button` unchanged but adds a new primitive.
   - Recommendation: Add `LinkButton` to `src/components/ui/LinkButton.tsx` that re-uses the `Button` class strings. Ship it as a new primitive — cleaner than modifying `Button`, no Phase-12 primitive is touched.

3. **Metadata file location: `layout.tsx` inline or new `src/app/metadata.ts`?** — **RESOLVED:** Plan 13-01 Task 3 updates metadata inline in `layout.tsx` (tuned title/description/OG for the landing page); no new `src/app/metadata.ts` file created.
   - What we know: CONTEXT.md canonical_refs lists `website/src/app/metadata.ts` but that file doesn't exist. Metadata currently lives inline in `layout.tsx`.
   - What's unclear: The discrepancy may be a typo or may indicate the original plan for a metadata file that was dropped in Phase 11.
   - Recommendation: Keep metadata inline in `layout.tsx`. Updating the root-level `metadata` and `viewport` exports to be tuned for the landing page (title, description, OG) is a 10-line edit to an existing file. Adding a new file just for metadata is extra indirection.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | **None currently** (no vitest/jest/playwright). Phase 13 does NOT require introducing one — all LAND-01..LAND-07 checks can be deterministic shell / Node scripts against the `next build` output. |
| Config file | none — see Wave 0 |
| Quick run command | `pnpm --filter website build` then grep the `.next/server/app/index.html` and the static HTML produced at `/website/.next/server/app/page.html` |
| Full suite command | `pnpm --filter website build && node scripts/verify-landing.mjs` (new script — see Wave 0) |
| Phase gate | Full suite green + manual Vercel preview visual smoke before `/gsd-verify-work` |

Rationale: Phase 13 is a static landing page. The success criteria (LAND-01 through LAND-07) are all DOM-observable: "Spectral headline present," "Primary CTA href matches DMG URL," "⌘R / ⌘⇧R / ⌘. / ⌘⇧S chips present," "nav and footer link to /docs, /changelog, GitHub." These are ideally verified by grepping the build output, not by spinning up a browser. A small Node script that reads the prerendered HTML and asserts substrings is faster, deterministic, and cheaper than Playwright — and it matches the project's minimal-dependencies philosophy (see DOCS-01 / LOG-01 which also avoid runtime dependencies).

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LAND-01 | Hero with Spectral headline + one-line value prop + primary "Download for macOS" CTA | build-output grep | `grep -q 'Your meeting audio' website/.next/server/app/page.html && grep -q 'never leaves your Mac' website/.next/server/app/page.html && grep -q 'Download for macOS' website/.next/server/app/page.html && grep -q 'font-serif' website/.next/server/app/page.html` | ❌ Wave 0 |
| LAND-02 | Primary CTA links to the latest GitHub Release DMG asset | build-output grep | `grep -q 'https://github.com/cnewfeldt/ps-transcribe/releases/latest/download/PS%20Transcribe.dmg' website/.next/server/app/page.html` | ❌ Wave 0 |
| LAND-03 | Hero or adjacent section embeds a product screenshot of the Chronicle UI | build-output grep + file check | `test -f website/public/app-screenshot.png && grep -q 'app-screenshot' website/.next/server/app/page.html && grep -q 'meeting transcript with Library, Transcript, and Details columns' website/.next/server/app/page.html` | ❌ Wave 0 |
| LAND-04 | Feature blocks: dual-stream, chat-bubble, Obsidian, Notion — with meta + heading + paragraph | build-output grep | four greps, one per feature: `Dual-stream capture`, `Transcript view`, `Obsidian vault`, `Notion, on send`; plus headlines `Microphone and system audio`, `Chat bubbles. Not a wall of text.`, `Every session lands where your notes already live.`, `Push finished sessions to a database, one key away.` | ❌ Wave 0 |
| LAND-05 | Shortcuts callout: ⌘R, ⌘⇧R, ⌘., ⌘⇧S as JetBrains Mono key chips | build-output grep + class-name grep | grep for `⌘R`, `⌘⇧R`, `⌘.`, `⌘⇧S` literal; grep for `font-mono` within the shortcut section; grep for the `min-w-[22px]` sentinel class | ❌ Wave 0 |
| LAND-06 | Top nav has working links to Docs, Changelog, GitHub | build-output grep for each href in nav | `grep -q 'href="/docs"' + grep -q 'href="/changelog"' + grep -q 'href="https://github.com/cnewfeldt/ps-transcribe"' (all within the `<header>` block) | ❌ Wave 0 |
| LAND-07 | Footer contains copyright, MIT license acknowledgment, and quick links | build-output grep | `grep -q '© 2026'`, `grep -q 'License · MIT'`, `grep -q 'Sparkle appcast'`, `grep -q 'Download DMG'`, `grep -q 'Report an issue'` | ❌ Wave 0 |
| D-15 | Hero eyebrow shows `Ver X.Y · Released <Month Day, Year>` | build-output grep, derived from CHANGELOG top entry | parse `CHANGELOG.md` for `^## \[([0-9.]+)\] — (\d{4}-\d{2}-\d{2})` then grep `website/.next/server/app/page.html` for the matching rendered string | ❌ Wave 0 |
| D-19 (motion-safe) | `prefers-reduced-motion: reduce` causes Reveal to be visible immediately | unit test (optional) OR manual DevTools emulation | If a test framework lands: Vitest + `@testing-library/react` exercising `useReveal` with `matchMedia` mocked to return `matches: true`. Otherwise: manual Chrome DevTools → Rendering → Emulate CSS media feature prefers-reduced-motion → no fade observed. | — |
| D-13 URL correctness | CTA href exactly matches the filename produced by `scripts/make_dmg.sh` | script-level check | `bash scripts/make_dmg.sh --dry-run || true; grep -q 'PS%20Transcribe.dmg' website/.next/server/app/page.html` (dry run not currently supported; simpler: assert the URL literal against the filename constant in `release-dmg.yml`) | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `pnpm --filter website build` must succeed (catches tsc / Next errors immediately).
- **Per wave merge:** `pnpm --filter website build && node scripts/verify-landing.mjs` (the grep suite described below).
- **Phase gate:** Full suite green + a manual eyeball of the Vercel preview URL on at least one of {iPhone simulator width 390px, iPad 820px, desktop 1440px} to catch any obvious layout regressions the greps won't see (spacing, image crop, alternating layout correctness).

### Wave 0 Gaps

- [ ] `website/scripts/verify-landing.mjs` — new Node script that runs after `next build`, reads `website/.next/server/app/page.html` (or the static export if we flip to `output: 'export'`), and asserts every substring / class-name listed in the map above. Exits non-zero on any miss. ~80 lines.
- [ ] `website/scripts/verify-landing.spec.md` — a one-page human-readable doc that lists the visual criteria a human should eyeball on a preview URL. Covers: (a) alternating feature layouts at lg+ but stacked heading-first on mobile; (b) hero headline italic reads as actual Spectral italic, not synthesized slant; (c) nav goes from transparent to subtle-shadow on scroll; (d) `prefers-reduced-motion` removes the fade; (e) the DMG URL actually downloads the DMG (manual click).
- [ ] No existing test framework, no test files. Phase 13 does NOT require introducing Vitest / Jest / Playwright. The grep suite is sufficient for the DOM-observable criteria. The one criterion that would benefit from a framework (`prefers-reduced-motion` unit test for `useReveal`) can be deferred to a post-v1.1 hardening pass, matching the project's deferred-test stance for v1.1.

**Alternative if higher confidence is wanted:** Install `vitest` + `@testing-library/react` (~20MB devDeps) and write ~15 lines of unit tests for `useReveal` and `changelog.ts`. This is NOT required for Phase 13 acceptance — CONTEXT.md lists Playwright / visual-regression as deferred — but it's the natural next step for Phase 14 (docs) which will need more unit coverage.

### Sketch: `website/scripts/verify-landing.mjs`

```js
#!/usr/bin/env node
// Source: Phase 13 Nyquist validation strategy
import fs from "node:fs"
import path from "node:path"

// Find the prerendered index HTML. Next 16 App Router puts this at
// .next/server/app/page.html for the root route (confirm via `ls` on a real build).
const candidates = [
  ".next/server/app/page.html",
  ".next/server/app/index.html",
  ".next/server/app/(root)/page.html",
]
let html = null
for (const c of candidates) {
  const p = path.join(process.cwd(), c)
  if (fs.existsSync(p)) { html = fs.readFileSync(p, "utf8"); break }
}
if (!html) {
  console.error("ERR: could not find prerendered page.html — run `pnpm build` first")
  process.exit(2)
}

const must = [
  // LAND-01
  ["Your meeting audio", "LAND-01 hero headline line 1"],
  ["never leaves your Mac", "LAND-01 hero headline line 2 (italic em)"],
  ["Download for macOS", "LAND-01 primary CTA text"],
  // LAND-02
  ["releases/latest/download/PS%20Transcribe.dmg", "LAND-02 DMG URL"],
  // LAND-03
  ["app-screenshot", "LAND-03 screenshot asset reference"],
  ["meeting transcript with Library, Transcript, and Details columns", "LAND-03 alt text"],
  // LAND-04
  ["Dual-stream capture", "LAND-04 feature 1 meta"],
  ["Microphone and system audio, recorded in parallel.", "LAND-04 feature 1 headline"],
  ["Transcript view", "LAND-04 feature 2 meta"],
  ["Chat bubbles. Not a wall of text.", "LAND-04 feature 2 headline"],
  ["Obsidian vault", "LAND-04 feature 3 meta"],
  ["Every session lands where your notes already live.", "LAND-04 feature 3 headline"],
  ["Notion, on send", "LAND-04 feature 4 meta"],
  ["Push finished sessions to a database, one key away.", "LAND-04 feature 4 headline"],
  // LAND-05
  ["⌘R", "LAND-05 chip ⌘R"],
  ["⌘⇧R", "LAND-05 chip ⌘⇧R"],
  ["⌘.", "LAND-05 chip ⌘."],
  ["⌘⇧S", "LAND-05 chip ⌘⇧S"],
  // LAND-06
  ['href="/docs"', "LAND-06 nav link to /docs"],
  ['href="/changelog"', "LAND-06 nav link to /changelog"],
  ['href="https://github.com/cnewfeldt/ps-transcribe"', "LAND-06 nav link to GitHub"],
  // LAND-07
  ["© 2026", "LAND-07 copyright"],
  ["License · MIT", "LAND-07 MIT acknowledgment"],
  ["Sparkle appcast", "LAND-07 footer link"],
  ["Download DMG", "LAND-07 footer product link"],
  ["Report an issue", "LAND-07 footer source link"],
  // D-15
  ["Ver ", "D-15 hero eyebrow version label prefix"],
  ["Released ", "D-15 hero eyebrow release-date prefix"],
]

const forbidden = [
  ["macOS 14+", "outdated macOS min (should be 26+)"],
  ["PS-Transcribe.dmg", "wrong DMG filename (should be PS%20Transcribe.dmg)"],
  ["Apple Silicon & Intel", "outdated arch requirement (Apple Silicon only)"],
]

let failed = 0
for (const [needle, label] of must) {
  if (!html.includes(needle)) { console.error(`MISS ${label}: "${needle}"`); failed++ }
  else                         console.log(`OK   ${label}`)
}
for (const [needle, label] of forbidden) {
  if (html.includes(needle))  { console.error(`BAD  ${label}: found forbidden "${needle}"`); failed++ }
  else                         console.log(`OK   forbidden-absent: ${label}`)
}

if (failed > 0) { console.error(`\n${failed} failure(s)`); process.exit(1) }
console.log("\nAll assertions passed.")
```

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V1 Architecture | yes (low) | Static site, no user input, no auth surface, no backend. Security posture is minimal. |
| V2 Authentication | no | No auth on the site. |
| V3 Session Management | no | No sessions. |
| V4 Access Control | no | Everything is public. |
| V5 Input Validation | no | No forms, no query params consumed, no user input surface. |
| V6 Cryptography | no | No crypto primitives in-app. Vercel handles TLS. |
| V12 Files & Resources | yes (low) | Only static files under `public/`; no file upload / download. `CHANGELOG.md` read is at build time, never from user input. |
| V13 API | no | No API routes. Only static App Router routes. |
| V14 Config & Errors | yes (low) | Metadata robots tag must NOT set `noindex` on `/` (production landing page should be indexed). Phase 12's `/design-system` route is already `noindex`. |

### Known Threat Patterns for {stack}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| XSS via injected copy | Tampering | Not applicable — all copy is at build time in React components, auto-escaped by React |
| Broken external links (especially the DMG CTA) | Denial of Service (of the conversion) | Use a constant in `src/lib/site.ts`; verify against `release-dmg.yml` at build time via a check in `verify-landing.mjs` that the URL is syntactically well-formed and matches the workflow's filename |
| Outdated dependency | Multiple | Vercel's build runs `pnpm install --frozen-lockfile`; lockfile-pinned versions; no fresh resolution at deploy time |
| Accidental `noindex` on production | Information Disclosure (reverse — accidentally hiding) | Root-level `metadata.robots` must stay `{ index: true, follow: true }` (it already is in `layout.tsx` line 44) — a verification step should grep the built HTML for `meta name="robots" content="noindex"` and fail if present on `/` |
| Outbound linking to unsupported scheme | Integrity | All external links use `https://`; no `http://`, no `mailto:` in Phase 13 |
| Open redirect | Redirection | No redirect logic in Phase 13. Next.js `redirects()` not used. |

**Explicit non-concerns:** no CSRF, no auth tokens, no cookies, no server-side session state, no user inputs. Phase 13 is a static marketing page. The only security-relevant asset is the DMG URL's correctness — covered above.

## Sources

### Primary (HIGH confidence)

- `node_modules/next/dist/docs/01-app/03-api-reference/02-components/image.md` — Next 16 Image component reference. Confirmed `priority → preload` rename (line 293), `preload` prop semantics (lines 265-288), `width`/`height` required (lines 100-113).
- `node_modules/next/dist/docs/01-app/03-api-reference/02-components/font.md` — Next 16 `next/font` reference. Confirmed `style` prop accepts `'normal' | 'italic'` or array (line 142).
- `node_modules/next/dist/docs/01-app/01-getting-started/08-caching.md` — Confirms `fs.readFileSync` is a supported build-time pattern (line 238).
- `node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/01-metadata/opengraph-image.md` — Confirms `process.cwd()` resolves to the Next.js project directory (line 113).
- `node_modules/tailwindcss/theme.css` — Tailwind v4 default theme. Confirmed `--font-sans` / `--font-serif` / `--font-mono` tokens auto-generate `font-sans` / `font-serif` / `font-mono` utilities (lines 2, 494).
- `website/package.json` — Confirmed exact versions: `next@16.2.4`, `react@19.2.4`, `react-dom@19.2.4`, `tailwindcss@^4`.
- `website/src/app/globals.css` — Chronicle token source of truth (lines 4-98). 16 color tokens + 5 radii + 3 shadows + font variables all exported via `@theme inline`.
- `website/src/components/ui/*.tsx` — Button, Card, MetaLabel, SectionHeading, CodeBlock all read; all reuse-ready with no modifications needed for Phase 13.
- `website/src/app/layout.tsx` — Existing font wiring + metadata. Must be modified to add `style: ['normal', 'italic']` to Spectral, and to mount `<Nav />` / `<Footer />` in the body.
- `website/src/app/page.tsx` — Existing Phase-11 placeholder. Confirmed to be rewritten wholesale in Phase 13.
- `design/ps-transcribe-web-unzipped/index.html` — 665-line primary mock, read in full. Hero variant C confirmed on line 214 (`<body data-hero="C">`). All seven sections + reveal-on-scroll behavior + nav scroll behavior sourced here.
- `design/ps-transcribe-web-unzipped/assets/chronicle-mock.css` — 237 lines, reference-only, read in full for sizing / border / radius / shadow port values.
- `design/ps-transcribe-web-unzipped/assets/tokens.css` — Token source verified to match globals.css one-to-one (Phase 12 port is complete).
- `design/ps-transcribe-web-unzipped/assets/app-screenshot.png` — 2260 × 1408 PNG, 108 KB (confirmed via `file` command).
- `CHANGELOG.md` — Top entry `## [2.1.0] — 2026-04-20` confirmed; grammar of entries matches the parser shape.
- `.github/workflows/release-dmg.yml` — Line 140 confirms DMG URL pattern `PS%20Transcribe.dmg`; line 160 confirms `sparkle:minimumSystemVersion=26.0`.
- `scripts/make_dmg.sh` — Line 6 `DMG_PATH="dist/PS Transcribe.dmg"` (with space) — confirms DMG filename source of truth.
- `PSTranscribe/Package.swift` — Line 7 `platforms: [.macOS(.v26)]` confirms minimum macOS version.
- `README.md` — Lines 9-11 badges: `macOS 26+`, `Apple Silicon - Required`, `MIT`.
- `.planning/phases/11-website-scaffolding-vercel-deployment/11-CONTEXT.md` — Stack decisions (pnpm, Next 16, TS strict, `src/app/` layout, `@/*` alias).
- `.planning/phases/12-chronicle-design-system-port/12-CONTEXT.md` — Token architecture, primitive API patterns, `chronicle-mock.css` reference-only policy.
- `.planning/config.json` — `workflow.nyquist_validation: true` confirmed; Validation Architecture section is mandatory.

### Secondary (MEDIUM confidence)

- MDN `IntersectionObserver` — used as a behavioral reference for the `threshold` and `unobserve` patterns. Not cited inline; behavior is stable across Safari 12.1+, Chrome 51+, Firefox 55+.
- MDN `matchMedia` + `(prefers-reduced-motion: reduce)` — standard motion-safe pattern.

### Tertiary (LOW confidence)

- None. No WebSearch was required; all findings are grounded in the local docs or the actual repo files.

## Metadata

**Confidence breakdown:**

- **Standard stack:** HIGH. Exact versions verified against `package.json`; Next 16 image / font behavior verified against local docs.
- **Architecture:** HIGH. Every recommended folder, file, and hook pattern matches either an existing Phase-12 convention, an explicit CONTEXT.md decision, or a Next 16 doc excerpt.
- **Pitfalls:** HIGH. Three of the ten pitfalls (priority→preload, DMG URL, macOS version) are verified against authoritative sources and flagged as CONTEXT.md discrepancies.
- **Validation:** HIGH. The grep-suite strategy uses fully deterministic checks against static HTML; no test framework dependency introduced.
- **Security:** HIGH. Phase 13 is a static marketing page with no auth / no input / no API — attack surface is minimal and documented.

**Research date:** 2026-04-22
**Valid until:** 2026-05-22 (30 days — the stack is stable; the only time-sensitive claim is the current CHANGELOG top entry, which updates with each release).

---

## Planner Handoff

The planner should sequence Phase 13 as approximately **five plans** (matching Phase 12's granularity of 4 plans for comparable scope):

1. **13-01: site-constants + changelog helper + screenshot asset + Spectral italic + metadata**
   - Add `src/lib/site.ts` with all the constants listed in Example 1.
   - Add `src/lib/changelog.ts` with the parser described in Pattern 2.
   - Copy `design/ps-transcribe-web-unzipped/assets/app-screenshot.png` to `website/public/app-screenshot.png`.
   - Update `layout.tsx`: add `style: ['normal', 'italic']` to the Spectral loader; update root `metadata` with the landing-specific title/description/OG tags.
   - No visual changes yet; sets up everything the section components will consume.

2. **13-02: motion + hooks + Reveal wrapper**
   - Add `src/hooks/useScrolled.ts` and `src/hooks/useReveal.ts`.
   - Add `src/components/motion/Reveal.tsx`.
   - Add `src/components/ui/LinkButton.tsx` (or accept the plain `<a className="...">` pattern — planner picks; my recommendation: LinkButton).
   - Sanity render: temporary `/__motion-test` page that mounts `<Reveal><p>hi</p></Reveal>` to confirm the client boundary works. Delete before phase ship.

3. **13-03: Nav + Footer (shared chrome)**
   - Add `src/components/layout/Nav.tsx` (client component, `useScrolled`).
   - Add `src/components/layout/Footer.tsx` (server component).
   - Mount both in `layout.tsx`.
   - After this plan ships, the existing placeholder `page.tsx` will have Nav/Footer wrapping it — first visible change on the preview deploy.

4. **13-04: Hero + ThreeThingsStrip + Final CTA (content sections with no mini-mockups)**
   - Add `src/components/sections/Hero.tsx` — consumes `getLatestRelease()`, renders the `.app-shot` frame around `next/image`.
   - Add `src/components/sections/ThreeThingsStrip.tsx` — three cards, each wrapped in `<Reveal>`.
   - Add `src/components/sections/FinalCTA.tsx` — card with `.stamp` top-right, primary CTA button.
   - Rewrite `page.tsx` to show Hero + ThreeThingsStrip + FinalCTA (feature blocks still missing; shortcuts still missing). First time the site is publicly "real."

5. **13-05: FeatureBlock + 4 Mocks + ShortcutGrid + verification**
   - Add `src/components/sections/FeatureBlock.tsx`, `ShortcutGrid.tsx`.
   - Add `src/components/mocks/{DualStreamMock,ChatBubbleMock,ObsidianVaultMock,NotionTableMock}.tsx` (+ optional `MockWindow.tsx` if 3+ share chrome — D-specifics permits).
   - Complete `page.tsx` with all four features + shortcuts section between CTA and footer.
   - Add `website/scripts/verify-landing.mjs` (from the Wave 0 sketch).
   - Add a small `website/scripts/verify-landing.spec.md` for the visual criteria.
   - Final plan gates on `pnpm build && node scripts/verify-landing.mjs` passing.

**Single open decision the planner should pick before writing plans:**
- Ship the Spectral italic face fix (+1 line in `layout.tsx`), or accept synthesized italic? Strong recommendation: ship it. Low-risk, high-fidelity. If the planner hesitates, the discuss-phase is the right place to confirm.

**Three CONTEXT.md items the planner MUST override:**
1. D-13's DMG URL: change `PS-Transcribe.dmg` → `PS%20Transcribe.dmg`.
2. D-07's `priority` prop: use `preload={true}` on `next/image` (Next 16 rename).
3. The mock's hero note + Final CTA note: replace `macOS 14+ · Apple Silicon & Intel` / `macOS 14+ (Sonoma & later)` with the project's real minimum, `macOS 26+ · Apple Silicon` (per `Package.swift` + `README.md`).

Each override is well-grounded. The planner should document each in the plan's "Context deviations" or equivalent section so the verify step doesn't flag the change as a bug.

---

*Phase: 13-landing-page*
*Research complete: 2026-04-22*
