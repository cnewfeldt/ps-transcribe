# Roadmap

## Shipped Milestones

- **v1.0 — PS Transcribe** (2026-04-02 → 2026-04-14): Full rebrand from Tome, security/stability hardening, session library + recording naming, three-state mic button + model onboarding, Notion integration, Obsidian deep-link, defect cleanup. 8 active phases, 45 requirements, 28 plans. Archived: [`milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md) · Requirements: [`milestones/v1.0-REQUIREMENTS.md`](milestones/v1.0-REQUIREMENTS.md) · Tag: `v1.0`.

## Current Milestone

### v1.1 — Marketing Website (in progress)

**Milestone goal:** Ship a marketing website for PS Transcribe at `ps-transcribe.vercel.app` — landing page, docs, and changelog — built in Next.js on Vercel and reusing the Chronicle design system already shipping in the macOS app.

**Approach:** Work outside-in: scaffold the Next.js project and Vercel deployment first (so every later change previews on a URL), port the Chronicle design tokens and primitives second (so every later page inherits the visual system), then build the three content pages in the order of dependency weight — landing, docs, changelog. The user will feed the Claude Design brief (already at `.planning/research/CLAUDE-DESIGN-BRIEF.md`, BRIEF-01 complete) into Claude Design to get HTML/CSS mocks; those mocks become the visual input to phases 13–15.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3...): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)
- v1.1 continues v1.0's numbering; first v1.1 phase is 11.

- [ ] **Phase 11: Website Scaffolding & Vercel Deployment** — `/website` subdir with Next.js + TypeScript, Vercel auto-deploy, preview URLs, production on `ps-transcribe.vercel.app`
- [ ] **Phase 12: Chronicle Design System Port** — palette tokens, font loading (Inter + Spectral + JetBrains Mono), reusable primitives, light-mode only
- [ ] **Phase 13: Landing Page** — hero with download CTA, feature blocks, keyboard-shortcuts callout, nav + footer
- [ ] **Phase 14: Docs Section** — MDX-rendered doc pages with sidebar nav, initial pages (Getting Started, Shortcuts, FAQ, Troubleshooting), right-hand TOC
- [ ] **Phase 15: Changelog Page** — build-time parsing of `CHANGELOG.md` rendered as release cards in reverse chronological order

## Phase Details

### Phase 11: Website Scaffolding & Vercel Deployment
**Goal**: A `/website` subdirectory exists with a working Next.js App Router + TypeScript project, deploys on every push, produces preview URLs per PR, and serves production at `ps-transcribe.vercel.app` — without polluting the Swift package or committing build artifacts.
**Depends on**: Nothing (first v1.1 phase; v1.0 complete)
**Requirements**: SITE-01, SITE-02, SITE-03, SITE-04, SITE-05
**Success Criteria** (what must be TRUE):
  1. Running `npm install && npm run dev` inside `/website` boots a Next.js App Router dev server on localhost with TypeScript compiling cleanly
  2. Pushing any commit that touches `/website` to a branch produces a Vercel preview URL visible on the PR
  3. `ps-transcribe.vercel.app` serves the latest `main`-branch build (blank-but-live is acceptable at this phase)
  4. `git status` shows no `.next/` or `node_modules/` files ever staged from the `/website` subdir
  5. The Swift package at the repo root still builds; the website has its own isolated `package.json`
**Plans**: TBD
**UI hint**: yes

### Phase 12: Chronicle Design System Port
**Goal**: Every page rendered by the Next.js site inherits the Chronicle visual language — the exact paper palette from the macOS app, the Inter + Spectral + JetBrains Mono font stack, and a small set of reusable primitives — so landing/docs/changelog can all be built against a consistent base without reinventing styles.
**Depends on**: Phase 11
**Requirements**: DESIGN-01, DESIGN-02, DESIGN-03, DESIGN-04
**Success Criteria** (what must be TRUE):
  1. All Chronicle color tokens (paper, paperWarm, paperSoft, ink, inkMuted, inkFaint, inkGhost, accentInk, accentSoft, spk2Bg, spk2Fg, spk2Rail, recRed, liveGreen, rule, ruleStrong) are reachable from any component as Tailwind classes or CSS custom properties
  2. Inter, Spectral, and JetBrains Mono load via `next/font` on every page; system fallbacks (SF Pro, New York, SF Mono) appear if webfonts fail
  3. A Button (primary + secondary), Card, MetaLabel, SectionHeading, and CodeBlock component exist in the codebase and render correctly on a dev page
  4. Visiting the site in a browser set to "prefers dark" still renders the light-mode paper palette — no dark-mode variants ship
**Plans**: TBD
**UI hint**: yes

### Phase 13: Landing Page
**Goal**: `ps-transcribe.vercel.app/` shows a complete landing page that communicates what PS Transcribe does, shows the Chronicle UI in-situ, and converts visitors to the GitHub Releases DMG download — navigable to Docs, Changelog, and GitHub from both nav and footer.
**Depends on**: Phase 12
**Requirements**: LAND-01, LAND-02, LAND-03, LAND-04, LAND-05, LAND-06, LAND-07
**Success Criteria** (what must be TRUE):
  1. The landing page renders a Spectral hero headline, a one-line value prop, and a primary "Download for macOS" button that links to the latest GitHub Release DMG asset
  2. A real product screenshot of the Chronicle UI is visible above the fold or in an adjacent hero-anchored section
  3. Feature blocks describe dual-stream capture, chat-bubble transcript, Obsidian save-to-vault, and Notion auto-send — each with a meta label, sub-headline, and short paragraph
  4. A shortcuts callout shows `⌘R`, `⌘⇧R`, `⌘.`, and `⌘⇧S` as JetBrains Mono key chips
  5. Top nav and footer both surface working links to Docs, Changelog, and GitHub; footer includes copyright and MIT license line
**Plans**: TBD
**UI hint**: yes

### Phase 14: Docs Section
**Goal**: `ps-transcribe.vercel.app/docs/*` renders editorial-quality help content from MDX files, with a left sidebar to navigate between pages and a right-hand on-this-page TOC that collapses on narrow viewports — the first four pages (Getting Started, Keyboard Shortcuts, FAQ, Troubleshooting) ship populated.
**Depends on**: Phase 12
**Requirements**: DOCS-01, DOCS-02, DOCS-03, DOCS-04, DOCS-05
**Success Criteria** (what must be TRUE):
  1. Creating a new `.mdx` file under the docs content directory produces a live doc page without any other code changes
  2. The left-hand sidebar lists all doc pages and visibly styles the currently active page differently from the others
  3. `Getting Started`, `Keyboard Shortcuts`, `FAQ`, and `Troubleshooting` each render with real content (not lorem ipsum)
  4. The right-hand "On this page" TOC auto-populates from H2/H3 headings and disappears below 1200px viewport width
  5. Code samples — both inline backticks and fenced blocks — render in JetBrains Mono, with inline code on a `paperSoft` pill background
**Plans**: TBD
**UI hint**: yes

### Phase 15: Changelog Page
**Goal**: `ps-transcribe.vercel.app/changelog` renders the project's `CHANGELOG.md` as styled release cards — parsed at build time, sorted newest-first, preserving the subsection structure (UX / Features / Fixes) from the source markdown so the site stays in sync with the app's release history without duplication.
**Depends on**: Phase 12
**Requirements**: LOG-01, LOG-02, LOG-03, LOG-04
**Success Criteria** (what must be TRUE):
  1. Adding a new version entry to the repo's `CHANGELOG.md` and rebuilding the site produces a new release card on `/changelog`
  2. Release cards appear in reverse chronological order with the latest release at the top of the page
  3. Subsection groupings from the markdown source (e.g., `### UX`, `### Features`, `### Fixes`) render as visually distinct sections within each card
  4. Each release card shows version number, release date, and the bulleted changes for that release
**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 11 → 12 → 13 → 14 → 15. Phases 13, 14, and 15 all depend only on Phase 12 and can technically parallelize, but default execution runs them sequentially.

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 11. Website Scaffolding & Vercel Deployment | v1.1 | 0/TBD | Not started | - |
| 12. Chronicle Design System Port | v1.1 | 0/TBD | Not started | - |
| 13. Landing Page | v1.1 | 0/TBD | Not started | - |
| 14. Docs Section | v1.1 | 0/TBD | Not started | - |
| 15. Changelog Page | v1.1 | 0/TBD | Not started | - |
