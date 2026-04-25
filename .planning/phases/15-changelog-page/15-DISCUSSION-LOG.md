# Phase 15: Changelog Page - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-24
**Phase:** 15-changelog-page
**Areas discussed:** Section labels + color taxonomy, Mock-only metadata, Filter aside scope, Per-release actions + bullet markdown rendering

---

## Gray area selection

| Option | Description | Selected |
|--------|-------------|----------|
| Section labels + color taxonomy | Mock paints 4 fixed buckets (Features=navy, Interface=sage, Fixes=ink-muted, Breaking=red) for headings + bullet dots. Real CHANGELOG has 19 unique freeform headings ("Distribution / Tooling", "Auto-updates (Sparkle)", "UX / Redesign — Quiet Chronicle", "Housekeeping", "Notion Integration", etc.). Decide: render verbatim with no color, render verbatim with heuristic color mapping (recommended — preserves source fidelity + visual variety), or normalize to fixed buckets. | ✓ |
| Mock-only metadata (codename/summary/pills/DMG meta) | Mock card shows codename ("Quiet Chronicle"), italic summary line, status pills (Current/Recommended/Breaking/Patch/Minor), and DMG-size+minOS in the foot. None of this exists in CHANGELOG.md. Decide: drop entirely (recommended — keep CHANGELOG.md the single source), synthesize what's derivable (Current=newest, Breaking=section-name detect), or stub everything visually so the layout still matches the mock. | ✓ |
| Filter aside scope (versions list + Subscribe) | Mock left aside is 180px sticky with Versions list (4 entries, scroll-spy active) and Subscribe block (RSS / Sparkle appcast / GitHub releases). Decide: list all 10 versions or cap at N; which Subscribe links to ship (Sparkle appcast URL exists per CHANGELOG.md; RSS would need its own route; GitHub Releases page is free). | ✓ |
| Per-release actions + bullet markdown rendering | Mock shows "Download →" + "Diff from vX.X.X →" per release card (linkable to GitHub release tag + GitHub compare URL). Real CHANGELOG bullets contain backtick `code` (e.g., `Info.plist`, `SUFeedURL`, `notionAutoSendEnabled`) — currently parser stores them verbatim with backticks. Decide: ship Download/Diff actions or drop, and how to render inline backticks (plain text, naive backtick→<code> swap, or a small inline-markdown renderer that also handles `**bold**` and `[links](...)` if any). | ✓ |

**User's choice:** All four areas selected.

---

## Section labels + color taxonomy

### Q1: Color mapping approach

| Option | Description | Selected |
|--------|-------------|----------|
| Verbatim labels + heuristic color (Recommended) | Render real heading text exactly as written ('Auto-updates (Sparkle)', 'UX / Redesign — Quiet Chronicle'). Apply the 4 mock colors via keyword rules: 'Feature/Notion/Integration' → navy; 'UX/Layout/Library/Recording/Onboarding/Interface/Redesign' → sage; 'Fix/Bug/Internals' → ink-muted; 'Breaking/Scope reduction/Migration' → red. Unmatched labels (Docs/Milestone/Housekeeping/Testing/Tooling/Repo) → ink-faint default. Best of both: source fidelity + the mock's visual rhythm. | ✓ |
| Verbatim labels + no color | Real labels, but every label and bullet dot uses the same neutral treatment (ink-faint mono label, ink-ghost dot). Honest, simple, eliminates the heuristic-mapping rule table. Loses the mock's color-coded scanability. | |
| Normalize to 4 fixed buckets | Translate every real heading into one of Features / Interface / Fixes / Breaking via a mapping table. Tightest visual, matches mock 1:1, but loses information ('Auto-updates (Sparkle)' becomes 'Features' — less precise than the original). | |

**User's choice:** Verbatim labels + heuristic color (Recommended)

### Q2: Section order within a card

| Option | Description | Selected |
|--------|-------------|----------|
| Source order (Recommended) | Render in the exact order they appear in CHANGELOG.md. Preserves the author's intent (e.g., 'Breaking' first in v2.0.0 because that's the headline; 'UX/Redesign' first in v2.1.0 because that's the lede). No surprise reordering. Authoring stays trivial. | ✓ |
| Canonical order | Sort to a fixed sequence: Breaking → Features → Interface/UX → Fixes → everything else (Docs / Milestone / Housekeeping last). Predictable scanning across releases at the cost of overriding author intent. | |

**User's choice:** Source order (Recommended)

### Q3: Bullet dot color

| Option | Description | Selected |
|--------|-------------|----------|
| Inherit section color (Recommended) | Mock-faithful: 4px dots take the section's color (features=navy, ux=sage, breaking=red, fixes=ink-ghost). Cards become scannable left-to-right — you can see the breaking-change dots without reading labels. Default ink-ghost for unmatched sections. | ✓ |
| Always neutral ink-ghost | Every bullet dot is the same ink-ghost color regardless of section. Calmer visual, less hierarchy, easier to ship. Section color lives only in the H4 label. | |

**User's choice:** Inherit section color (Recommended)

---

## Mock-only metadata (codename / summary / pills / DMG meta)

### Q1: Codename

| Option | Description | Selected |
|--------|-------------|----------|
| Drop codename entirely (Recommended) | No codename slot in the rendered card. Simplest, fully data-driven. v2.1.0 loses 'Quiet Chronicle' — acceptable since the section heading 'UX / Redesign — Quiet Chronicle' already conveys it. | ✓ |
| Auto-extract from quoted subsection titles | When a subsection heading contains a quoted phrase (e.g., 'UX / Redesign — "Quiet Chronicle"'), lift it as the release codename. Only v2.1.0 in current CHANGELOG would have one. Brittle convention but free wins where present. | |
| Convention in CHANGELOG.md | Establish a new convention: optional `> codename` blockquote line under the version heading. CHANGELOG.md becomes the source. Requires backfilling old releases (or leaving blank) and sticking to the convention going forward. | |

**User's choice:** Drop codename entirely (Recommended)

### Q2: Summary line

| Option | Description | Selected |
|--------|-------------|----------|
| Drop summary line (Recommended) | Card jumps straight from header to sections. Cleanest, no synthesis logic, no maintenance. Matches the philosophy of CHANGELOG.md being the single source. | ✓ |
| First bullet of first section | Auto-promote the first bullet of the first section as summary text. Cheap synthesis but reads weirdly when the first bullet is technical (e.g., v2.1.1 starts with 'New public releases repo...' which isn't a summary). | |
| Convention in CHANGELOG.md | New convention: optional plain paragraph between `## [version] — date` and the first `###` section, parsed as the summary. Future-friendly; backfilling old entries optional. Adds a parser branch. | |

**User's choice:** Drop summary line (Recommended)

### Q3: Pills

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-derive Current + Breaking only (Recommended) | 'Current' = `entries[0]` (newest, navy 'live' pill). 'Breaking' = section named 'Breaking' present in the release. Both are derivable from the parsed data. Skip 'Recommended', 'Patch', 'Minor' — they're either subjective ('Recommended') or noisy when computed from semver (we have 1.4.1, 2.0.0, 2.1.0, 2.1.1 — lots of 'Patch' clutter). | ✓ |
| Drop all pills | No pill row. The card is just date + version, no status indicators. Simpler still. Loses the at-a-glance 'this is current / this is breaking' affordance. | |
| Auto-derive Current + Breaking + semver (Major/Minor/Patch) | Adds Major/Minor/Patch pills computed from version diffs (X.0.0=Major, X.Y.0=Minor, X.Y.Z=Patch). Most visually rich. Risk: 5/10 releases get 'Patch' label — visual noise. | |

**User's choice:** Auto-derive Current + Breaking only (Recommended)

### Q4: DMG meta

| Option | Description | Selected |
|--------|-------------|----------|
| Drop DMG meta line (Recommended) | Card foot becomes just the action links (Download/Diff, see area 4) or is omitted entirely. No build-time GitHub API calls, no hardcoded version strings to drift. | ✓ |
| Show 'macOS 26+' only, hardcoded | Pull min-OS from `SITE.OS_REQUIREMENTS` (already 'macOS 26+'). Skip DMG byte size (would need GitHub Releases API at build time). Modest visual richness, zero new infrastructure. | |
| Fetch DMG size from GitHub Releases API at build time | Add a build-time fetch from `api.github.com/repos/.../releases` to populate size + asset URL per release. Highest fidelity to mock; introduces a network dependency at build (graceful fallback needed for CI without GH_TOKEN). | |

**User's choice:** Drop DMG meta line (Recommended)

---

## Filter aside scope (Versions list + Subscribe)

### Q1: Versions list contents

| Option | Description | Selected |
|--------|-------------|----------|
| All 10 versions, scroll-spy active (Recommended) | Show every version in the aside (mono 11px, version + date small). IntersectionObserver toggles active state as the user scrolls. With 10 entries the aside is ~280px tall — fits comfortably under the sticky offset, no scroll needed inside the aside itself. | ✓ |
| Cap at most-recent 6, link 'older' to anchor | Aside shows the 6 newest; an 'Older releases' link jumps to an anchor in the stream. Tighter visually but adds an extra UI element to maintain. Old entries still render in the stream. | |
| All 10 versions in scrollable aside | Show all 10 in a fixed-height aside (`max-height: calc(100vh - 200px)`) with internal scroll. Future-proofs for when the changelog grows past ~15 entries. Slight UX cost (two scrollbars on long pages). | |

**User's choice:** All 10 versions, scroll-spy active (Recommended)

### Q2: Subscribe links (multiSelect)

| Option | Description | Selected |
|--------|-------------|----------|
| Sparkle appcast (Recommended) | Link to `raw.githubusercontent.com/cnewfeldt/ps-transcribe-releases/main/appcast.xml` (per CHANGELOG v2.1.1). The actual mechanism the macOS app uses for updates. Useful for power users wiring their own tooling. | ✓ |
| GitHub releases (Recommended) | Link to `github.com/cnewfeldt/ps-transcribe-releases/releases` (the public releases repo per v2.1.1) or its `.atom` feed. Already in `SITE.APPCAST_URL` constant. One-click subscribe via GitHub's RSS-friendly Atom feed. | ✓ |
| RSS feed (separate Next route) | Build a `/changelog/rss.xml` route that emits an RSS feed derived from `getAllReleases()`. New surface area: a route file + RSS XML serialization. Not strictly necessary if GitHub Releases Atom covers it. | ✓ |

**User's choice:** All three (Sparkle appcast, GitHub releases, AND RSS feed). User opted in to building the new RSS Route Handler.

### Q3: Aside heading

| Option | Description | Selected |
|--------|-------------|----------|
| Match mock: 'Versions' (Recommended) | Mono 10px uppercase, ink-faint — same `<MetaLabel>` treatment used elsewhere. Concise. Matches the mock exactly. | ✓ |
| 'On this page' | Mirrors the docs TOC label for visual consistency across the site. But changelog isn't really a TOC — it's a version index. Slight semantic mismatch. | |
| Drop the heading entirely | List is self-evident (versions and dates). Saves vertical space. Loses the explicit cue. | |

**User's choice:** Match mock: 'Versions' (Recommended)

---

## Per-release actions, bullet rendering, card foot

### Q1: Per-release actions (Download / Diff)

| Option | Description | Selected |
|--------|-------------|----------|
| Drop per-release actions; one global GitHub link (Recommended) | Card foot has no Download/Diff per release. The aside's 'GitHub releases' link covers download discoverability, and a single 'View on GitHub' or release-tag link in the foot is enough. No tag backfilling needed, no broken links. Cards stay clean and dataset-honest. | ✓ |
| Per-release actions, conditional on tag existence | Render Download + Diff only when a matching git tag exists for that version (and the previous one for diff). Today that means actions appear on v2.0.0 only. Graceful degradation; ages well as future releases get tags. Adds tag-existence check to the build (parser would need to read git or a static manifest). | |
| Backfill missing git tags, then ship actions everywhere | Preflight task in this phase: create the 8 missing version tags retroactively (v1.0.0..v1.4.1 + v2.1.0 + v2.1.1) so all 10 cards have working Download/Diff links. More upfront work; cleanest result. | |

**User's choice:** Drop per-release actions; one global GitHub link (Recommended)

**Notes:** Tag backfill is captured under Deferred Ideas in CONTEXT.md.

### Q2: Inline bullet rendering

| Option | Description | Selected |
|--------|-------------|----------|
| Inline parser: backticks + bold + links (Recommended) | Small custom inline-markdown renderer (regex-based or `react-markdown` with paragraph-stripped output) that handles `code` → <code>, **bold** → <strong>, [text](url) → <a>. ~30 lines of code. Covers everything CHANGELOG actually uses today. Inline `<code>` styled per Phase 14 D-18 (paperSoft pill, JetBrains Mono 12.5px per the mock's `.sec li code` rule). | ✓ |
| Backticks only, drop bold and links | Tiny regex `/`([^`]+)`/g` swap. Loses the 2 bold emphasis lines (Breaking section) and the 1 Markdown link (Tome credit) — they'd render as raw `**text**` and `[text](url)` strings. Simplest, but visibly wrong on those entries. | |
| Render plain text, drop all formatting | Strip backticks/bold/links during render. Bullets become raw prose. Cleanest code, ugliest output (`SUFeedURL` and `Info.plist` lose their visual distinction from prose). | |

**User's choice:** Inline parser: backticks + bold + links (Recommended)

### Q3: Card foot row

| Option | Description | Selected |
|--------|-------------|----------|
| Drop the foot row entirely (Recommended) | Card ends after the sections grid. Cleaner, fewer rules. The 0.5px hairline between sections and foot in the mock disappears. Pairs naturally with 'drop per-release actions' (foot would be empty anyway). | ✓ |
| Foot row with permalink + GitHub release link | Mono 10px row: `# v2.1.1` permalink (clicking copies the URL anchor) on the left; 'View on GitHub →' link to the release-tag page (or releases repo) on the right. Low cost, gives editorial closure to each card. | |
| Foot with timeline-dot + permalink only | Mock ships a `.timeline-dot` (10px circle absolutely positioned at left:-24px) on every card; the foot is just the permalink. Adds the timeline visual cue (vertical thread of dots down the left margin) without action links. | |

**User's choice:** Drop the foot row entirely (Recommended)

---

## Closing question

**Q:** We've captured the 4 selected areas. Any remaining gray areas to explore before writing CONTEXT.md?

| Option | Description | Selected |
|--------|-------------|----------|
| I'm ready for context (Recommended) | Write 15-CONTEXT.md and 15-DISCUSSION-LOG.md now. Smaller decisions captured under 'Claude's Discretion'. | ✓ |
| Explore more gray areas | Surface 2–3 more candidate areas. | |

**User's choice:** I'm ready for context (Recommended)

---

## Claude's Discretion

The following implementation details were not asked of the user; the planner picks reasonable defaults that match the mock + prior phase patterns. Captured in CONTEXT.md `<decisions>` section under "Claude's Discretion":

- Hero copy verbatim from mock ("Every release." + sub)
- Mobile breakpoints match the mock (820px aside collapse, 680px sec grid collapse)
- Container max-width matches Phase 13's landing
- `<Pill>` primitive shape (variant-union props, two variants only)
- Heuristic keyword classifier lives in `lib/section-color.ts`
- Inline `<code>` styling values reused from Phase 14 D-18
- No anchor "copy link" affordance per release
- Filter aside vertical spacing matches mock
- Pure static page, no `revalidate`

## Deferred Ideas

Captured in CONTEXT.md `<deferred>` section. Highlights:

- Backfilling missing git tags (would unlock per-release Download/Diff later)
- Codename / summary conventions in CHANGELOG.md
- DMG byte size + minOS via GitHub Releases API
- Atom feed (RSS 2.0 covers today's need)
- Search / pagination (10 entries doesn't justify them)
- Reading public `release-notes/v<version>.md` files (separate concern)
- Custom domain, dark mode, localization (all out of milestone)
- Timeline-dot visual element

## Reviewed Todos (not folded)

None — `gsd-tools todo match-phase 15` returned 0 results.
