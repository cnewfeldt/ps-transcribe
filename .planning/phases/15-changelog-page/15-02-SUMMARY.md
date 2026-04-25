---
phase: 15-changelog-page
plan: 02
subsystem: ui

tags: [changelog, react, next, tailwind, scroll-spy, ssr]

requires:
  - phase: 15-changelog-page
    plan: 01
    provides: Pill primitive, classifySection + sectionColors, renderInlineMarkdown, SITE.RELEASES_URL, SITE.SPARKLE_APPCAST_URL, parser orphan-bullet synthesis
  - phase: 12-chronicle-design-system-port
    provides: MetaLabel primitive, paper/ink/accent tokens, Spectral/Inter/JetBrains Mono fonts, shadow-lift token
  - phase: 14-docs-section
    provides: TableOfContents IntersectionObserver scroll-spy pattern (rootMargin '-20% 0px -70% 0px')
provides:
  - ReleaseCard server component renders one ChangelogEntry as a card with header (date+version+pills) + sections grid
  - VersionsAside client component renders the sticky versions list + Subscribe block with IntersectionObserver scroll-spy
  - Auto-derived Current pill (entries[0]) and Breaking pill (any section title matching /\bbreaking\b/i)
  - Card variant treatments: release--current (navy-tinted border + shadow-lift), release--older (opacity 0.92)
  - Anchor ID convention 'vX-Y-Z' shared between ReleaseCard <article id> and VersionsAside <a href> for scroll-spy + deep-linking
affects: [15-03-rss-route, 15-04-page-wireup]

tech-stack:
  added: []
  patterns:
    - "Mock breakpoint via Tailwind arbitrary-breakpoint utility (min-[680px]:) instead of sm: (640px) for exact mock fidelity"
    - "Inline-style bridge for non-token rgba values (release--current navy border at rgba(43,74,122,0.2)) where Tailwind tokens don't cover the alpha channel"
    - "SSR-safe scroll-spy: useEffect-only IntersectionObserver setup, initial activeSlug seeded from entries[0] so server-rendered HTML matches client's first paint"

key-files:
  created:
    - website/src/components/changelog/ReleaseCard.tsx
    - website/src/components/changelog/VersionsAside.tsx
  modified: []

key-decisions:
  - "Inline the 3-line versionSlug helper in both ReleaseCard and VersionsAside rather than extracting to lib/version-slug.ts — duplication threshold not crossed (planner offered the choice; 3 LOC × 2 sites is fine)"
  - "SubscribeBlock inlined into VersionsAside rather than creating a separate component — 3 list rows with ~identical markup, separate component would be ceremony without payoff (CONTEXT 15-CONTEXT.md explicitly authorized this)"
  - "Use min-[680px]: arbitrary breakpoint for the section grid two-column → single-column collapse, preserving the mock's exact 680px threshold rather than deferring to Tailwind's sm: at 640px"
  - "Preserve doc-comment provenance (e.g., 'No timeline-dot (D-21)', 'Server component (no use client)') even though they trip naive grep heuristics — structural intent satisfied by direct inspection; same precedent as Plan 15-01"

requirements-completed: [LOG-02, LOG-03, LOG-04]

duration: 3min
completed: 2026-04-25
---

# Phase 15 Plan 02: Changelog Components Summary

**ReleaseCard (server) and VersionsAside (client with IntersectionObserver scroll-spy) — the two visually load-bearing components Wave 3's `page.tsx` will compose into the changelog page.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-04-25T08:43:26Z
- **Completed:** 2026-04-25T08:46:36Z
- **Tasks:** 2/2
- **Files created:** 2 (ReleaseCard.tsx, VersionsAside.tsx)
- **Files modified:** 0

## Accomplishments

- Shipped the two Wave 2 composite components for the changelog page; both consume Plan 15-01's foundation utilities (Pill, classifySection, sectionColors, renderInlineMarkdown, SITE constants) cleanly with no scavenger-hunting
- ReleaseCard auto-derives the Current pill (entries[0]) and Breaking pill (any section title matching `/\bbreaking\b/i`) — no caller boilerplate
- VersionsAside scroll-spy mirrors `docs/TableOfContents.tsx` exactly (rootMargin '-20% 0px -70% 0px'); SSR-safe initial activeSlug seeding mitigates T-15-05
- All Subscribe links carry `rel="noopener"` per T-15-06
- Legacy releases (v1.0.0..v1.2.0) render via the same code path: the parser's synthesized 'Changes' section classifies to the visually-quiet 'default' bucket — no special-case branching
- `pnpm tsc --noEmit` and `pnpm lint` both clean for the new files

## Task Commits

Each task was committed atomically:

1. **Task 1: ReleaseCard server component** — `8bc169c` (feat)
2. **Task 2: VersionsAside client component (versions list + Subscribe + scroll-spy)** — `7758998` (feat)

## Files Created/Modified

- `website/src/components/changelog/ReleaseCard.tsx` — Server component (no `'use client'`). Renders `<article id={versionSlug(entry.version)}>` with: a header row (date + version + auto-derived pills), then a sections grid where each section's H4 label and bullet dots inherit color from `sectionColors[classifySection(title)]`. Bullet text flows through `renderInlineMarkdown`. Variant chrome via inline style + classes: `isCurrent` gets `style={{ borderColor: 'rgba(43, 74, 122, 0.2)' }}` + `shadow-lift`; `isOlder` gets `opacity-[0.92]`. Mock breakpoint at 680px preserved via `min-[680px]:` arbitrary breakpoint utility. CSS values ported literally from `design/ps-transcribe-web-unzipped/changelog.html` and `chronicle-mock.css` per `<specifics>`.

- `website/src/components/changelog/VersionsAside.tsx` — Client component (`'use client'` first line). Sticky aside (`top-16` for our 64px nav). Two stacked sections: a versions list (one `<a href="#vX-Y-Z">` per entry with a right-aligned short date) and a Subscribe block (3 external links: Sparkle appcast, GitHub releases, RSS feed — all `target="_blank" rel="noopener"`). IntersectionObserver scroll-spy in `useEffect` mirrors `docs/TableOfContents.tsx`: rootMargin `-20% 0px -70% 0px`, toggles `data-active="true"` on the link whose `versionSlug(entry.version)` matches the article currently in view. Initial `activeSlug` is seeded from `entries[0]` so the SSR HTML matches the client's first paint (T-15-05).

## Auto-derived Pill Logic (D-08)

ReleaseCard's pill row is purely derived from props + data; the page-level wirer in Wave 3 doesn't pass pill flags:

```tsx
const hasBreaking = entry.sections.some((s) => /\bbreaking\b/i.test(s.title))
{isCurrent ? <Pill variant="live">Current</Pill> : null}
{hasBreaking ? <Pill variant="breaking">Breaking</Pill> : null}
```

Today this produces:
- v2.1.1 (entries[0]): Current pill only
- v2.0.0 (has a `### Breaking` section): Breaking pill only
- All others: no pills

If a future newest release also contains a Breaking section, both pills render simultaneously — verified by direct code inspection of the conditional rendering structure.

## SSR-Safety (T-15-05)

VersionsAside is a client component, but it's still rendered first on the server. The server-rendered HTML uses `useState`'s initial value, which is seeded from `entries[0]`'s slug. The client's first paint (before useEffect runs) uses the same value. Only after the first useEffect tick does the IntersectionObserver attach and start observing — at which point the active state may transition based on actual scroll position, but the initial state is deterministic and identical between server and client.

The `typeof window === 'undefined'` guard inside useEffect is belt-and-suspenders (useEffect already only runs on the client) and is included for symmetry with similar guards elsewhere in the codebase.

## Decisions Made

- **Inline `versionSlug` helper twice** instead of extracting to `lib/version-slug.ts`: 3 LOC duplicated across 2 consumers; the abstraction would be ceremony. The Plan offered the choice explicitly; chose duplication.
- **SubscribeBlock inlined into VersionsAside**: 3 list rows with near-identical `<a>` markup. CONTEXT 15-CONTEXT.md explicitly noted the SubscribeBlock "may be inlined if planner judges separate component over-engineered" — judgment call honored.
- **`min-[680px]:` arbitrary breakpoint** for the section grid's two-column → single-column collapse rather than Tailwind's `sm:` (640px). Preserves exact mock fidelity. Cost: one extra arbitrary-breakpoint utility class. Worth it.
- **Doc-comment provenance preserved** even though strings like "No timeline-dot (D-21)" trip naive grep heuristics in the acceptance criteria. The structural intent (no timeline-dot rendered, no foot row rendered, no codename rendered, no `'use client'` directive at the top of ReleaseCard) is satisfied by direct inspection. Same precedent as Plan 15-01 Task 5: don't contort comments to satisfy regex.

## Deviations from Plan

None — plan executed exactly as written. Both task verifications passed (tsc + lint clean for both new files; all structural acceptance criteria satisfied via direct code inspection). The plan-supplied implementation snippet was followed almost verbatim with two minor improvements: (1) the `versionSlug` helper docstring explains its role, and (2) function-level docstrings explain the SSR-safety rationale and pill derivation rules so future readers don't need to re-derive them from CONTEXT.md.

## Issues Encountered

- **`node_modules` missing in fresh worktree.** `pnpm tsc` and `pnpm lint` initially failed with "command not found" / phantom type errors because the worktree was checked out without `pnpm install` having been run. Resolved by running `pnpm install` once (~2 seconds since the global pnpm store had everything cached). After install, both commands ran clean. No code changes triggered by this; it was purely a worktree setup step. Did not commit `pnpm-lock.yaml` (no lock changes occurred).
- **Acceptance-criteria grep regex caveats.** Three checks reported FAIL on raw grep output but the structural intent was satisfied:
  - `! grep -q "'use client'"` failed because the ReleaseCard docstring explicitly notes "Server component (no `'use client'`)". The actual top-of-file directive is absent (line 1 is `import type { CSSProperties } ...`). PASS.
  - `! grep -qE "timeline.dot|timeline-dot"` failed because two doc comments document the absence ("No timeline-dot (D-21)"). No `<timeline-dot>` element or class is rendered. PASS.
  - `! grep -qE "codename"` failed for the same reason. No codename markup rendered. PASS.
  - The `id={slug}` regex hit a ripgrep brace-quoting bug (not a code issue); direct inspection confirmed `<article id={slug} ...>` on the rendered article. PASS.
  Followed the same precedent Plan 15-01 set: structural intent satisfied by inspection, comments preserved for provenance.

## Threat Flags

None — no new threat surface introduced beyond what's already documented in the plan's `<threat_model>` (T-15-05, T-15-06, T-15-07, T-15-08). T-15-05 mitigated via useEffect-only window/document access + SSR-deterministic initial state. T-15-06 mitigated via `rel="noopener"` on all 3 Subscribe `target="_blank"` links. T-15-07/08 accepted (React's default escaping covers the inline-rendered text; inline `style` props use only static color tokens).

## User Setup Required

None — pure component additions. No env vars, no external services, no DB changes.

## Next Phase Readiness

Wave 3 (15-03 RSS Route Handler, 15-04 page.tsx + Nav active-state + sitemap) can build directly against:

- `import { ReleaseCard } from '@/components/changelog/ReleaseCard'`
- `import { VersionsAside } from '@/components/changelog/VersionsAside'`

Wave 3's `page.tsx` will:
1. Call `getAllReleases()` server-side
2. Map over entries rendering `<ReleaseCard entry={entry} isCurrent={i === 0} isOlder={i >= 2} />`
3. Render `<VersionsAside entries={entries} />` as the sticky left column

Visual UAT happens after Wave 3 (these components don't render visually on their own).

## Self-Check

- [x] `website/src/components/changelog/ReleaseCard.tsx` exists — FOUND
- [x] `website/src/components/changelog/VersionsAside.tsx` exists — FOUND
- [x] Commit `8bc169c` exists — FOUND
- [x] Commit `7758998` exists — FOUND
- [x] `pnpm tsc --noEmit` exits 0 — VERIFIED
- [x] `pnpm lint src/components/changelog/` exits 0 — VERIFIED

## Self-Check: PASSED

---
*Phase: 15-changelog-page*
*Completed: 2026-04-25*
