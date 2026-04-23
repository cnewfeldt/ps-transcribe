# Phase 13: Landing Page - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-22
**Phase:** 13-landing-page
**Areas discussed:** Fidelity & scope, Hero app imagery, Feature block visuals, Download CTA link

---

## Gray-area selection

| Option | Description | Selected |
|--------|-------------|----------|
| Fidelity & scope | Mock has 7 sections; phase only requires 5. How closely to port the mock's variant-C layout, typography, and copy? | ✓ |
| Hero app imagery | Static screenshot PNG vs recreated three-column Chronicle mockup in React vs hybrid. | ✓ |
| Feature block visuals | React mini-mockups vs static PNG captures vs simple icons. | ✓ |
| Download CTA link | Hardcode vs `releases/latest/download` redirect vs build-time fetch. | ✓ |

**User's choice:** All four selected.

---

## Fidelity & scope

### Q1: Which sections should the landing page ship?

| Option | Description | Selected |
|--------|-------------|----------|
| All 7 mock sections | Nav + Hero + "Three things" + 4 Features + Shortcuts + Final CTA + Footer. Matches mock exactly. More work, stronger narrative arc. | ✓ |
| Minimum required (5) | Nav + Hero + 4 Features + Shortcuts + Footer. Ships what LAND-01..07 require. Drops strip and repeat CTA. | |
| 6 sections — drop strip, keep final CTA | Nav + Hero + 4 Features + Shortcuts + Final CTA + Footer. Closing CTA without intro preamble. (Recommended.) | |

**User's choice:** All 7 mock sections.

### Q2: Which hero layout variant from the mock?

| Option | Description | Selected |
|--------|-------------|----------|
| C — centered editorial | Headline centered, wide deck below. Mock's default. (Recommended.) | ✓ |
| A — asymmetric tilted deck | Copy-left / deck-right with perspective rotation on the app shot. | |
| B — capability-first wide | Copy-left / deck-right, wider deck, no tilt. | |

**User's choice:** C — centered editorial.

### Q3: How should we handle the mock's copy?

| Option | Description | Selected |
|--------|-------------|----------|
| Use verbatim | Keep every headline, lede, feature paragraph, bullet list as-written. (Recommended.) | ✓ |
| Light edits only | Port as starting point; tighten where product has shifted. | |
| Write fresh | Rewrite all marketing copy from scratch. | |

**User's choice:** Use verbatim.

### Q4: How granular should component extraction be?

| Option | Description | Selected |
|--------|-------------|----------|
| Extract all layout + section components | Nav, Footer, Hero, FeatureBlock, ShortcutGrid, FinalCTA. Phases 14/15 reuse Nav + Footer. (Recommended.) | ✓ |
| Extract only shared (Nav, Footer) | Sections stay inline in `page.tsx`. | |
| Single page.tsx file | Everything inline. Extract later. | |

**User's choice:** Extract all layout + section components.

---

## Hero app imagery

### Q1: Which screenshot for the hero deck?

| Option | Description | Selected |
|--------|-------------|----------|
| Use existing design/assets PNG | `design/.../app-screenshot.png` (2260×1408). Ship what designer calibrated against. (Recommended.) | ✓ |
| Capture fresh | New screenshot of current Chronicle UI. Adds a capture step. | |
| Defer to human task | Placeholder `<figure>`; surface a UAT item to drop in the final screenshot. | |

**User's choice:** Use existing design/assets PNG.

### Q2: How should the hero screenshot be framed?

| Option | Description | Selected |
|--------|-------------|----------|
| Mock's `.app-shot` frame | 0.5px `rule-strong` border, 12px radius, `shadow-float`, max-width 1080px. (Recommended.) | ✓ |
| Bare image, no frame | Drop border/shadow; let macOS chrome carry the signal. | |
| Custom frame — macOS-window chrome | Wrap in fake titlebar with traffic lights. More meta, more work. | |

**User's choice:** Mock's `.app-shot` frame.

### Q3: How should Next.js load the hero image?

| Option | Description | Selected |
|--------|-------------|----------|
| next/image with priority | Auto WebP/AVIF, responsive srcset, LCP-eager. (Recommended.) | ✓ |
| Static import via next/image | `import screenshot from '@/public/...'`; intrinsic dimensions at build time. | |
| Plain `<img>` | Simplest; no optimization; ships full 2260×1408 every load. | |

**User's choice:** next/image with priority.

### Q4: What should the screenshot alt text say?

| Option | Description | Selected |
|--------|-------------|----------|
| Mock's version | `PS Transcribe — meeting transcript with Library, Transcript, and Details columns`. (Recommended.) | ✓ |
| Feature-focused alt | Narrative, heavier. | |
| Minimal alt | `PS Transcribe main window.` | |

**User's choice:** Mock's version.

---

## Feature block visuals

### Q1: How should the four feature-block mini-mockups be implemented?

| Option | Description | Selected |
|--------|-------------|----------|
| Port as React components | Recreate dual-stream bars, chat bubbles, Obsidian tree, Notion table as React+Tailwind. Editorial fidelity, sharp at every DPI. (Recommended.) | ✓ |
| Static PNG captures | Render mock HTML in a browser, capture as optimized PNG. Fast now, brittle later. | |
| Simple iconography | Single illustrative icon per feature. Loses the "this is what it looks like" moment. | |

**User's choice:** Port as React components.

### Q2: How to treat the `.shot` / `.shot--tint` / `.shot--sage` tint wrapper?

| Option | Description | Selected |
|--------|-------------|----------|
| Port wrapper + tint variants | `<FeatureBlock tint="default"|"tint"|"sage">`. Preserves the mock's color rhythm (Feature 1 tint, 2 sage, 3 default, 4 tint). (Recommended.) | ✓ |
| Default panel only | All four use `paper-warm`. Simpler; monotone. | |
| No panel — inline on paper | Weakest product-ad vibe. | |

**User's choice:** Port wrapper + tint variants.

### Q3: Should the dual-stream mini animate?

| Option | Description | Selected |
|--------|-------------|----------|
| Static as in mock | Fixed bar heights, fixed content. Editorial, calm. (Recommended.) | ✓ |
| Subtle animation on scroll-reveal | Bars breathe once, then hold. Respects `prefers-reduced-motion`. | |
| Continuous ambient animation | Bars loop while visible. CPU-heavy; fights the minimalist tone. | |

**User's choice:** Static as in mock.

### Q4: Keep the mock's alternation (`feature--alt`)?

| Option | Description | Selected |
|--------|-------------|----------|
| Alternate as in mock | Feature 1 copy-left, Feature 2 alt, Feature 3 default, Feature 4 alt. Prevents listy reading. (Recommended.) | ✓ |
| All same orientation | Every feature copy-left / mock-right. Simpler; monotone. | |

**User's choice:** Alternate as in mock.

---

## Download CTA link

### Q1: How should the primary CTA resolve the DMG?

| Option | Description | Selected |
|--------|-------------|----------|
| `releases/latest/download` redirect | `github.com/{owner}/{repo}/releases/latest/download/PS-Transcribe.dmg`. GitHub redirects to latest. Zero build-time fetch. (Recommended.) | ✓ |
| Build-time fetch | Hit GitHub API at `next build`; inject resolved asset URL + version. Stale until next rebuild. | |
| Hardcode current release | Constant DMG URL. Breaks on every release. | |

**User's choice:** `releases/latest/download` redirect.

### Q2: What GitHub owner/repo should the CTA and footer links point at?

| Option | Description | Selected |
|--------|-------------|----------|
| I'll provide now | User types the owner/repo slug as free text. | ✓ |
| Flag as blocker | Capture a `TODO(repo-slug)`; block phase from merging. | |
| Use a placeholder for now | Hardcode `OWNER/ps-transcribe`. Same problem as v1.0. | |

**User's choice:** `cnewfeldt/ps-transcribe` (provided as free-text follow-up).

### Q3: Include the mock's version stamps?

| Option | Description | Selected |
|--------|-------------|----------|
| Include, resolve at build time | Parse top CHANGELOG.md entry at build; inject version + date into hero eyebrow and final CTA stamp. (Recommended.) | ✓ |
| Include, hardcode for now | Fixed string (e.g., `v1.0.0 · Apr 14, 2026`). Drifts every release. | |
| Skip version stamps | Remove eyebrow version + final CTA `.stamp`. Loses a trust signal. | |

**User's choice:** Include, resolve at build time.

### Q4: Keep the secondary "View on GitHub →" hero button?

| Option | Description | Selected |
|--------|-------------|----------|
| Keep — View on GitHub | Secondary Button linking to repo root. Reinforces "free + open source." (Recommended.) | ✓ |
| Drop — single primary CTA | Only Download button. GitHub still in nav. | |

**User's choice:** Keep — View on GitHub.

---

## Side conversation

User asked (mid-discussion): "Are you able to translate to another language using Parakeet-TDT v3 so, english to korean for example?"

**Answer given:** Parakeet-TDT is an ASR model (speech → source-language text), not a translation model. v3 added multilingual ASR but for European languages; Korean is not in the set. English → Korean would require a separate MT pipeline. Also conflicts with PROJECT.md's "no LLM analysis of transcripts" stance (scope reduction 2026-04-04).

**Follow-up:** User clarified "no, just curious" — not a scope addition. Captured as a deferred idea in CONTEXT.md for future exploratory reference.

---

## Claude's Discretion

- Exact CSS for `.app-shot` frame (utility string vs scoped CSS vs inline style vs `@layer components`)
- Whether `useReveal` is a hook + wrapper `<Reveal>` or attaches via ref primitive
- Whether `useScrolled` uses `window.scrollY` or IntersectionObserver sentinel
- File boundaries for mini-mockups (individual vs shared `<MockWindow>` helper)
- `<nav>` vs `<header>` for Nav's outer element
- Shortcut chip color assignments (match the mock: ⌘R navy, ⌘⇧R sage, ⌘. default, ⌘⇧S default)
- `CHANGELOG.md` parser (regex vs remark vs unified vs hand-rolled)
- `metadata` export location (`src/app/metadata.ts` vs inline)
- Arbitrary-value utility usage (`border-[0.5px]`, `text-[clamp(...)]`)
- Where `<Nav>` and `<Footer>` mount (prefer `layout.tsx` so phases 14/15 inherit)

## Deferred Ideas

- Mobile hamburger / drawer navigation — add if post-ship testing surfaces friction
- Fresh app screenshot capture — polish pass, not a phase-blocker
- Dark-mode variants — blocked by DESIGN-04
- Analytics, testimonials, pricing, email capture — milestone out of scope
- Multi-language / translation (raised as curiosity) — not in v1.1; ASR model isn't a translator, and revisiting would reopen scope cut 2026-04-04
- Mock's `#tweaks` dev overlay — dev-only, not production
- `MockWindow` wrapper extraction — planner's call during implementation
- Playwright / visual-regression tests — post-v1.1 hardening
- Per-page custom OG images — post-ship polish
