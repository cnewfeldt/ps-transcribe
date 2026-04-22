---
milestone: v1.1
milestone_name: marketing-website
created: 2026-04-21
---

# Milestone v1.1 — Marketing Website Requirements

**Goal:** Build and ship a marketing website at `ps-transcribe.vercel.app` — landing, docs, and changelog — using Next.js on Vercel, reusing the Chronicle design system.

## Active Requirements

### BRIEF — Design brief (input for Claude Design)

- [x] **BRIEF-01**: Claude Design brief exists at `.planning/research/CLAUDE-DESIGN-BRIEF.md` with complete context (palette, typography, spacing, page scope, voice, deliverables) so Claude Design can produce site mocks

### SITE — Infrastructure & deployment

- [ ] **SITE-01**: `/website` subdirectory initialized with Next.js App Router + TypeScript inside the `ps-transcribe` repo, with its own `package.json` independent from the Swift package
- [ ] **SITE-02**: Site deploys to Vercel automatically on every push via GitHub integration
- [ ] **SITE-03**: Each PR gets a preview-deployment URL
- [ ] **SITE-04**: Production site is reachable at `ps-transcribe.vercel.app` from the `main` branch
- [ ] **SITE-05**: Repo `.gitignore` excludes website build artifacts (`.next/`, `node_modules/`)

### DESIGN — Chronicle design system port

- [ ] **DESIGN-01**: Chronicle color palette available as Tailwind tokens or CSS custom properties on every page (paper, paperWarm, paperSoft, ink, inkMuted, inkFaint, inkGhost, accentInk, accentSoft, spk2Bg, spk2Fg, spk2Rail, recRed, liveGreen, rule, ruleStrong)
- [ ] **DESIGN-02**: Inter + Spectral + JetBrains Mono loaded via `next/font` with system fallbacks (SF Pro / New York / SF Mono)
- [ ] **DESIGN-03**: Reusable primitives available: Button (primary/secondary), Card, MetaLabel, SectionHeading, CodeBlock
- [ ] **DESIGN-04**: Site renders in light mode only — no dark-mode CSS variants

### LAND — Landing page

- [ ] **LAND-01**: Landing page shows hero with Spectral headline, one-line value prop, and primary "Download for macOS" CTA
- [ ] **LAND-02**: Primary CTA links to the latest GitHub Release DMG asset
- [ ] **LAND-03**: Hero or adjacent section embeds at least one product screenshot of the Chronicle UI
- [ ] **LAND-04**: Feature blocks communicate dual-stream capture, chat-bubble transcript, Obsidian save-to-vault, Notion auto-send
- [ ] **LAND-05**: Keyboard-shortcuts callout displays ⌘R / ⌘⇧R / ⌘. / ⌘⇧S in mono key chips
- [ ] **LAND-06**: Top navigation includes links to `Docs`, `Changelog`, and `GitHub`
- [ ] **LAND-07**: Footer contains copyright, MIT license acknowledgment, and quick links

### DOCS — Documentation section

- [ ] **DOCS-01**: Docs pages render from MDX files using Next.js MDX support
- [ ] **DOCS-02**: Left-hand sidebar navigates between all doc pages with visible active-page styling
- [ ] **DOCS-03**: Initial MDX pages exist for *Getting Started*, *Keyboard Shortcuts*, *FAQ*, and *Troubleshooting*
- [ ] **DOCS-04**: Right-hand "On this page" TOC extracts page headings automatically (collapses below 1200px)
- [ ] **DOCS-05**: Inline code and code blocks render with JetBrains Mono; inline code uses `paperSoft` pill background

### LOG — Changelog page

- [ ] **LOG-01**: Changelog page parses the project's `CHANGELOG.md` at build time and renders each release as a Card
- [ ] **LOG-02**: Releases display in reverse chronological order (newest at top)
- [ ] **LOG-03**: Release cards preserve subsection grouping (e.g., UX / Features / Fixes) from the markdown source
- [ ] **LOG-04**: Each release card shows version, release date, and change bullets

## Coverage

- Total: 23 requirements
- Completed: 1 (BRIEF-01)
- Pending: 22

## Out of Scope

The following are deliberately not part of this milestone:

- **Custom domain.** Site lives at `ps-transcribe.vercel.app` only. Deferred.
- **Pricing page / commerce.** No license keys, no Stripe, no Gumroad. Download CTA is the sole conversion target.
- **Blog.** No editorial blog section.
- **Newsletter / email capture.** No signup forms.
- **Dark mode.** Light mode only. Aesthetic parity with the macOS app (which is also light-only).
- **Docs search (Cmd+K modal).** Basic sidebar navigation only.
- **Multi-language.** English-only site.
- **Analytics stack.** Vercel Analytics if enabled by default; no GA4, no Plausible, no tracking pixels in this milestone.
- **Testimonials / logo bar / case studies.** No social proof elements.
- **App Store deployment of the macOS app.** DMG from GitHub Releases remains the only distribution.

## Future Requirements (post-v1.1)

- Custom domain + DNS
- OWNER placeholder replacement in `SUFeedURL` (tracked separately)
- Docs search
- Localization

## Traceability

| REQ-ID | Phase | Plan | Status |
|--------|-------|------|--------|
| *To be filled by roadmapper* | | | |
