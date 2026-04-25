---
phase: 15-changelog-page
plan: 03
subsystem: web

tags: [changelog, react, next, tailwind, integration, page]

requires:
  - phase: 15-changelog-page
    plan: 01
    provides: getAllReleases() with synthesized 'Changes' section for legacy releases, MetaLabel/Pill primitives, SITE constants, classifySection + sectionColors, renderInlineMarkdown
  - phase: 15-changelog-page
    plan: 02
    provides: ReleaseCard server component, VersionsAside client component (sticky scroll-spy + Subscribe block)
  - phase: 14-docs-section
    provides: Nav docsActive pattern (mirrored here as changelogActive)
  - phase: 13-landing-page
    provides: Site-wide max-w-[1200px] container convention
provides:
  - "/changelog page (server component, statically generated at build time)"
  - "Nav 'Changelog' link active-state styling on /changelog/* (mirrors Docs)"
  - "/changelog and /changelog/rss.xml entries in sitemap.xml (priority 0.7 / 0.5 respectively)"
affects: []

tech-stack:
  added: []
  patterns:
    - "Server component composition: page.tsx calls getAllReleases() at module-eval time, wraps Wave 2 server (ReleaseCard) and client (VersionsAside) components in a hero + two-column grid layout"
    - "Container width locked at max-w-[1200px] per the Phase 13 site convention (overriding the mock's 1280px reference)"
    - "min-[820px]: arbitrary breakpoint preserves the mock's exact two-column → single-column collapse threshold"

key-files:
  created:
    - website/src/app/changelog/page.tsx
  modified:
    - website/src/components/layout/Nav.tsx
    - website/src/app/sitemap.ts

key-decisions:
  - "Container width fixed at max-w-[1200px] (NOT the mock's 1280px) — locks the changelog hero/stream to the site's converged width since Phase 13. Resolves the planner-flagged 1280-vs-1200 discrepancy authoritatively at the page-composition layer."
  - "Sitemap priority 0.7 for /changelog (matches DOC_ORDER convention for top-level content pages); 0.5 for /changelog/rss.xml (feed endpoint, not a human-browsable discovery page)"
  - "Nav's changelogActive mirrors the existing docsActive pattern verbatim — same linkBase / linkActive / linkIdle composition, same aria-current treatment. No new abstraction introduced."
  - "Metadata exports a Metadata object (title 'Changelog', description, openGraph) so search engines and OG link previews surface a tight identifier. Hero copy is left for visual presentation only."

requirements-completed: [LOG-01, LOG-02, LOG-03, LOG-04]

duration: 3min
completed: 2026-04-25
---

# Phase 15 Plan 03: Changelog Page Wireup Summary

**Server-component `/changelog` page composing the Wave 2 ReleaseCard + VersionsAside into a hero + two-column release stream; Nav active-state derivation for `/changelog/*`; sitemap extension with `/changelog` and `/changelog/rss.xml` entries.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-04-25T08:51:02Z
- **Completed:** 2026-04-25T08:54:54Z
- **Tasks:** 3/4 implementation tasks complete; Task 4 is a UAT checkpoint (pending human approval)
- **Files created:** 1 (page.tsx)
- **Files modified:** 2 (Nav.tsx, sitemap.ts)

## Accomplishments

- Shipped the server-component `/changelog` page that composes Wave 1 utilities + Wave 2 components into the final two-column release stream
- All 10 release cards from CHANGELOG.md render in reverse-chronological order at build time (verified via `pnpm build` — `/changelog` registered as `○ (Static)`)
- Container width locked at `max-w-[1200px]` matching the Phase 13 site convention (Nav, landing page, all section components)
- Nav's "Changelog" link picks up active-state styling on `/changelog/*` via the new `changelogActive` derivation, mirroring the existing `docsActive` pattern
- Sitemap extended with two new entries: `/changelog` (priority 0.7, matching DOC_ORDER convention) and `/changelog/rss.xml` (priority 0.5, with rationale comment for future maintainers)
- Hero copy renders verbatim per CONTEXT.md: MetaLabel "Changelog", H1 "Every release.", subcopy paragraph
- Metadata + OpenGraph tags set for canonical URL `https://ps-transcribe-web.vercel.app/changelog`
- `pnpm tsc --noEmit`, `pnpm lint`, and `pnpm build` all clean

## Task Commits

Each task was committed atomically:

1. **Task 1: Add changelogActive derivation to Nav.tsx** — `fe33b1b` (feat)
2. **Task 2: Add /changelog and /changelog/rss.xml to sitemap.ts** — `99d32ce` (feat)
3. **Task 3: Create changelog page.tsx (hero + two-column grid + cards)** — `843c1f5` (feat)
4. **Task 4: Human UAT — visual verification of /changelog** — checkpoint task; pending human approval (no file modifications)

## Files Created/Modified

- `website/src/app/changelog/page.tsx` (new, ~81 lines) — Server component (no `'use client'`). Calls `getAllReleases()` at module-evaluation time. Exports a `metadata: Metadata` const (title "Changelog", description, openGraph). Renders a hero `<section>` with `MetaLabel`, H1 "Every release." (Spectral, clamp(40px,5vw,56px)), and the subcopy paragraph; below the hairline border, a two-column `<div>` grid (180px aside | 1fr stream, gap 48px desktop / 22px mobile, breakpoint at 820px). Maps over `entries`: `<ReleaseCard isCurrent={i === 0} isOlder={i >= 2} />`. `<VersionsAside entries={entries} />` is the sticky left column. Container is `mx-auto max-w-[1200px] px-6 md:px-10` for both the hero inner div and the stream wrapper. Nav + Footer come from `app/layout.tsx`.

- `website/src/components/layout/Nav.tsx` (modified, +8 / -1 lines) — Added `const changelogActive = pathname?.startsWith('/changelog') ?? false` immediately below the existing `docsActive` line. Replaced the previous `<Link className={`${linkBase} ${linkIdle}`} href="/changelog">Changelog</Link>` with the parallel-to-Docs structure: `className={`${linkBase} ${changelogActive ? linkActive : linkIdle}`}` plus `aria-current={changelogActive ? 'page' : undefined}`. Docs link, GitHub link, wordmark, sticky behavior, and scrolled state all preserved.

- `website/src/app/sitemap.ts` (modified, +16 / -0 lines) — Appended two entries to the array returned by `sitemap()`: `/changelog` (priority 0.7, monthly, matches existing DOC_ORDER entries) and `/changelog/rss.xml` (priority 0.5, monthly, with an inline comment explaining the lower priority — feed endpoint, not a human-browsable page). Both use the same `BASE` constant + template literal pattern as the existing entries. Imports, BASE constant, root entry, and DOC_ORDER spread all preserved.

## Container Width Decision (locked at 1200px)

The mock's `chronicle-mock.css` and CONTEXT.md `<specifics>` line 234 reference `max-width: 1280px`. The actual site has converged on `max-w-[1200px]` (verified in Nav.tsx line 28, page.tsx, all section components since Phase 13). The plan's `<container_width_decision>` block locked this at 1200px to match the rest of the site rather than introduce a 1280px island on the changelog page. The page hero `<div>` and the stream wrapper `<div>` both use `mx-auto max-w-[1200px] px-6 md:px-10` — verified by `grep -q "max-w-\[1200px\]" page.tsx` (PASS) and `! grep -q "max-w-\[1280px\]" page.tsx` (PASS).

## All 10 Releases Render with Bullets

This satisfies ROADMAP success criterion #4 ("each release card shows version + date + bulleted changes") for ALL releases, including the 4 legacy ones (v1.0.0, v1.0.1, v1.1.0, v1.2.0) that previously rendered empty cards. Per Plan 15-01 Task 5's parser fix, those releases now carry a synthesized `{ title: 'Changes', items: [...] }` section, which `classifySection` routes to the visually-quiet `default` bucket. The page.tsx wireup is unaware of this distinction — it just maps over `entry.sections` like any other release. Visual confirmation comes via Task 4 UAT.

## RSS Feed Status

`/changelog/rss.xml` is shipped by Plan 15-04 (Wave 2) — that route handler is already in place at `website/src/app/changelog/rss.xml/route.ts`. Production build registers `/changelog/rss.xml` as `ƒ (Dynamic)`. The Subscribe block in VersionsAside (Plan 15-02) already links to `/changelog/rss.xml`, so the full feed-discovery loop is closed.

## Decisions Made

- **Container width: max-w-[1200px], not 1280px.** Plan's `<container_width_decision>` was prescriptive; this was not executor discretion. The 1280 in the mock and CONTEXT.md `<specifics>` was stale — the site standardized on 1200 since Phase 13. Both the hero inner div and the stream wrapper use the identical `mx-auto max-w-[1200px] px-6 md:px-10` pattern, exactly matching Nav.tsx line 28.
- **Mirrored the docsActive pattern verbatim.** Could have abstracted both derivations into a `useNavActive()` hook that takes a path prefix, but with only two consumers (Docs, Changelog) and identical logic, the duplication is below the Rule-of-Three threshold. If a future top-level link needs the same treatment, that's the moment to extract.
- **Sitemap rationale comments inline.** Future maintainers will see the priority numbers (0.7 / 0.5) and ask why. The inline comment captures the intent (top-level content vs. feed endpoint) at the point of decision rather than burying it in a SUMMARY they won't read.
- **Metadata title is just "Changelog", not "Changelog · PS Transcribe".** Next prepends the app's `template` from layout.tsx if one is set; if not, the OG title carries the full identifier. Browser tabs see "Changelog" (tight), search engines and link previews see the full "Changelog · PS Transcribe" via OG.

## Deviations from Plan

None — plan executed exactly as written. All three task verifications passed:
- Task 1: 5/5 acceptance grep checks PASS, `pnpm tsc --noEmit` clean, `pnpm exec eslint src/components/layout/Nav.tsx` clean
- Task 2: All structural acceptance criteria PASS (the `${BASE}/changelog` literal is present at lines 23 and 32; `priority: 0.7` for /changelog at line 26; `priority: 0.5` for rss.xml at line 35; root entry and DOC_ORDER spread preserved); `pnpm tsc --noEmit` clean
- Task 3: 16/16 source-content acceptance grep checks PASS, `pnpm tsc --noEmit` clean, `pnpm exec eslint src/app/changelog/page.tsx` clean, full `pnpm build` succeeds with `/changelog` registered as `○ (Static)` in the route table

One pre-existing ESLint error remains at `website/src/hooks/useReveal.ts:19` (`react-hooks/set-state-in-effect`, introduced in commit `05a05eb` from Phase 13-02). This was already captured in Plan 15-01's deferred-items.md and is explicitly out-of-scope for this plan (the file is not touched by Plan 15-03). Lint is clean for all three files modified by this plan.

## Issues Encountered

- **Worktree had no `node_modules`.** The fresh worktree was checked out without `pnpm install` having been run. `pnpm tsc` would have failed with "command not found". Resolved by running `pnpm install` once (~2 seconds via cached pnpm store, no lockfile changes). Same pattern noted in Plan 15-02 SUMMARY — apparently endemic to fresh worktrees in this repo. Did not commit `pnpm-lock.yaml` (no lock changes occurred).
- **Heredoc-style grep with `${BASE}/changelog` literal in single quotes.** One acceptance criterion check appeared to fail in a chained shell command but the literal IS present in the file (verified via `grep -F` fixed-string match). Same precedent set by Plan 15-01 / 15-02 / 15-04: structural intent satisfied by direct inspection takes precedence over fragile shell quoting.

## Threat Flags

None — no new threat surface introduced beyond the plan's `<threat_model>` (T-15-09 through T-15-12, all accept-disposition for static hard-coded JSX content with no user input). React's default escaping covers all the inline string literals; usePathname is read-only and only drives visual state.

## User Setup Required

None — pure file additions/modifications. No env vars, no external services, no DB changes.

## Next Phase Readiness

- Task 4 (Human UAT) is pending — must be approved before this plan can be marked complete
- Once UAT is approved, Phase 15 is fully shipped: 4/4 plans complete (15-01 Foundation Utilities, 15-02 Components, 15-03 Page Wireup, 15-04 RSS Feed)
- Phase 15 success criteria from ROADMAP are now satisfied:
  1. Adding a new entry to CHANGELOG.md and rebuilding produces a new card — TRUE because page.tsx calls `getAllReleases()` at build time
  2. Reverse chronological order — TRUE because the parser returns entries in source order (newest-first per CHANGELOG.md convention)
  3. Subsections preserved — TRUE because ReleaseCard maps over `entry.sections` in source order
  4. Version + date + bullets per card — TRUE for ALL 10 cards (legacy v1.0.0..v1.2.0 use the synthesized 'Changes' section from 15-01 Task 5)

## Self-Check

- [x] `website/src/app/changelog/page.tsx` exists — FOUND
- [x] `website/src/components/layout/Nav.tsx` exists (modified) — FOUND
- [x] `website/src/app/sitemap.ts` exists (modified) — FOUND
- [x] Commit `fe33b1b` exists (Task 1: Nav changelogActive)
- [x] Commit `99d32ce` exists (Task 2: sitemap entries)
- [x] Commit `843c1f5` exists (Task 3: page.tsx)
- [x] `pnpm tsc --noEmit` exits 0 — VERIFIED
- [x] `pnpm exec eslint src/app/changelog/page.tsx src/components/layout/Nav.tsx` exits 0 — VERIFIED
- [x] `pnpm build` succeeds with `/changelog` registered as `○ (Static)` — VERIFIED

## Self-Check: PASSED

---
*Phase: 15-changelog-page*
*Completed: 2026-04-25 (implementation); Task 4 UAT pending human approval*
