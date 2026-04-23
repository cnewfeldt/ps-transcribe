---
phase: 13-landing-page
plan: 05
subsystem: ui
tags: [nextjs, server-components, landing-page, page-assembly, verify-landing, human-uat, spectral-italic, lighthouse, prefers-reduced-motion]

requires:
  - phase: 13-landing-page
    plan: 01
    provides: SITE constants, getLatestRelease CHANGELOG parser, /app-screenshot.png asset, Spectral italic font face, verify-landing.mjs grep-suite (32 assertions)
  - phase: 13-landing-page
    plan: 02
    provides: Nav (sticky + scroll state), Footer (server three-column), LinkButton, Reveal + useReveal + useScrolled primitives
  - phase: 13-landing-page
    plan: 03
    provides: Hero, ThreeThingsStrip, ShortcutGrid, FinalCTA section components
  - phase: 13-landing-page
    plan: 04
    provides: FeatureBlock (with Tint + MetaTone types) and four mini-mockups (DualStream, ChatBubble, ObsidianVault, NotionTable)

provides:
  - Composed landing page at `/` — Hero → ThreeThingsStrip → 4× FeatureBlock (with hairline rules between) → ShortcutGrid → FinalCTA
  - Full production build passes (typecheck 0 / next build 0)
  - verify-landing.mjs flipped from 14 OK / 18 MISS (post-Plan-02 baseline) to 32 OK / 0 MISS / 0 BAD
  - Human UAT approval on all 5 visual-only criteria from VALIDATION.md §"Manual-Only Verifications" (Spectral italic fidelity, nav scroll state, prefers-reduced-motion fallback, responsive breakpoint collapse, Lighthouse LCP/CLS on production build)
  - Phase 13 closeout: LAND-01..LAND-07 all satisfied with rendered-HTML evidence

affects: [14-docs, 15-changelog]

tech-stack:
  added: []
  patterns:
    - "Top-level `page.tsx` as pure composition — imports 9 components (5 sections + 4 mocks), passes plan-prescribed props, renders nothing else; all logic lives in the children"
    - "Hairline <hr> rules between FeatureBlocks (`border-0 h-[0.5px] bg-rule`) — honors the Chronicle hairline detail inline rather than relying on FeatureBlock to own its own bottom border"
    - "Container pattern for the feature section (`mx-auto max-w-[1200px] px-6 md:px-10`) — consistent with Plan-02 Footer's max-width and Plan-03 section max-widths; matches the mock's content gutter"
    - "JSX-body for Feature 2 ObsidianVault — passes a fragment with `<em className=\"italic\">is</em>` so the word renders in the real Spectral italic face loaded in Plan 01 (not a browser-synthesized slant)"
    - "Non-autonomous plan closure via human UAT checkpoint — automation proves the grep-verifiable surface; the human confirms what greps cannot see (italic letterforms, scroll transitions, motion preferences, responsive integrity, Lighthouse metrics)"

key-files:
  created: []
  modified:
    - website/src/app/page.tsx

key-decisions:
  - "Feature 3 body uses `<em className=\"italic\">is</em>` (plain italic class, no `text-accent-ink`) — the mock renders the word in default ink, not navy-ink; the class was scoped deliberately to keep color unchanged while resolving the Spectral italic face from layout.tsx"
  - "Four explicit FeatureBlock call-sites over a `.map(features)` pattern — mixing JSX body nodes (Feature 3) with string bodies makes a typed feature array awkward; four explicit call-sites keep the compositional intent clear and let each block carry its own prop shape without discriminated-union ceremony"
  - "Hairline `<hr>` separators live at the page level, not inside FeatureBlock — keeps FeatureBlock presentation-agnostic about its neighbors and lets future callers decide whether to rule between blocks"
  - "Plan executed exactly as written — the plan's action block was fully prescriptive, so the composition shipped verbatim; no deviation rules triggered"

patterns-established:
  - "Landing composition pattern — all narrative sections go at the top of `page.tsx`, enclosed in `<main className=\"bg-paper text-ink\">` with Nav/Footer inherited from layout.tsx"
  - "UAT as closure gate — plans whose correctness depends on visual fidelity (italic glyphs, scroll behavior, responsive rendering, Lighthouse metrics) ship with a `checkpoint:human-verify` task that gates phase completion; automation handles everything grep-verifiable, and the human handles the rest"

requirements-completed: [LAND-01, LAND-02, LAND-03, LAND-04, LAND-05, LAND-06, LAND-07]

duration: ~8min (assembly + build + verify + UAT gate)
completed: 2026-04-23
---

# Phase 13 Plan 05: Landing Page — Wave 4 Page Assembly + UAT Closure Summary

**Composed all Phase-13 sections into `app/page.tsx` (Hero, ThreeThingsStrip, four FeatureBlocks with hairline rules, ShortcutGrid, FinalCTA), shipped a green production build, flipped `verify-landing.mjs` to 32 OK / 0 MISS / 0 BAD, and closed the phase via a human UAT approving all five visual-only criteria from VALIDATION.md.**

## Performance

- **Duration:** ~8 min across two agents (executor Task 1 ≈ 3 min; human UAT ≈ 5 min wall clock)
- **Tasks:** 2 (1 auto, 1 checkpoint:human-verify)
- **Files modified:** 1 (`website/src/app/page.tsx`)
- **Files created:** 0

## Accomplishments

### Task 1 — Compose `page.tsx` + run full build + verify suite (commit `a205597`)

- **`website/src/app/page.tsx`** (93 lines) — Replaced the Phase-11 placeholder wholesale. Top-level `<main className="bg-paper text-ink">` wraps (in order): `<Hero />`, `<ThreeThingsStrip />`, a `<section>` container with `max-w-[1200px]` housing four `<FeatureBlock>` calls separated by three hairline `<hr className="border-0 h-[0.5px] bg-rule" />` rules, `<ShortcutGrid />`, `<FinalCTA />`. The four FeatureBlocks carry their plan-prescribed props:
  - **Feature 0** — `index={0}`, `tint="tint"`, meta `Dual-stream capture`, headline `Microphone and system audio, recorded in parallel.`, string body ("ScreenCaptureKit … Silero VAD and diarization"), three bullets, `mock={<DualStreamMock />}`.
  - **Feature 1** — `index={1}`, `tint="sage"`, `metaTone="sage"`, meta `Transcript view`, headline `Chat bubbles. Not a wall of text.`, string body, three bullets, `mock={<ChatBubbleMock />}`.
  - **Feature 2** — `index={2}`, `tint="default"`, `metaTone="navy"`, meta `Obsidian vault`, headline `Every session lands where your notes already live.`, **JSX body** with `<em className="italic">is</em>` for "the transcript *is* a note in your vault", three bullets (last: "whatever you already use"), `mock={<ObsidianVaultMock />}`.
  - **Feature 3** — `index={3}`, `tint="tint"`, meta `Notion, on send`, headline `Push finished sessions to a database, one key away.`, string body, three bullets, `mock={<NotionTableMock />}`.

- **Typecheck** (`./node_modules/.bin/tsc --noEmit` inside `website/`) — exit 0.
- **Build** (`./node_modules/.bin/next build` inside `website/`) — exit 0; 10 static pages generated (`/`, `/_not-found`, `/design-system`, robots.txt, sitemap.xml, plus Next internals); `/` ships as a static Server Component with a tiny client-island footprint (Nav + Reveal).
- **verify-landing.mjs** — exit 0. **32 OK / 0 MISS / 0 BAD**, flipping the Plan-02 baseline (14 OK / 18 MISS) to full green:

  ```
  OK   LAND-01 hero eyebrow "Ver 2.1 · Released"
  OK   LAND-01 hero headline line 1 "Your meeting audio"
  OK   LAND-01 hero headline line 2 "never leaves your Mac"
  OK   LAND-02 primary CTA "Download for macOS"
  OK   LAND-02 DMG URL "PS%20Transcribe.dmg"
  OK   LAND-03 hero screenshot src "/app-screenshot.png"
  OK   LAND-03 hero screenshot alt text
  OK   LAND-04 feature meta "Dual-stream capture"
  OK   LAND-04 feature meta "Transcript view"
  OK   LAND-04 feature meta "Obsidian vault"
  OK   LAND-04 feature meta "Notion, on send"
  OK   LAND-04 feature headline "Microphone and system audio"
  OK   LAND-04 feature headline "Chat bubbles"
  OK   LAND-04 feature headline "where your notes already live"
  OK   LAND-04 feature headline "one key away"
  OK   LAND-05 shortcuts heading "Four shortcuts is all it takes"
  OK   LAND-05 shortcut combo "⌘R"
  OK   LAND-05 shortcut combo "⌘⇧R"
  OK   LAND-05 shortcut combo "⌘⇧S"
  OK   LAND-05 shortcut combo "⌘."
  OK   LAND-06 nav link to /docs
  OK   LAND-06 nav link to /changelog
  OK   LAND-06 nav link to GitHub
  OK   LAND-07 copyright "© 2026"
  OK   LAND-07 MIT acknowledgment "License · MIT"
  OK   LAND-07 footer product link "Sparkle appcast"
  OK   LAND-07 footer product link "Download DMG"
  OK   LAND-07 footer source link "Report an issue"
  OK   forbidden-absent "macOS 14+"
  OK   forbidden-absent "PS-Transcribe.dmg"
  OK   forbidden-absent "Apple Silicon & Intel"
  OK   forbidden-absent "content=\"noindex\""
  ```

### Task 2 — Human UAT checkpoint (no code commit)

Human approved all **5/5** visual-only criteria from `.planning/phases/13-landing-page/13-VALIDATION.md` §"Manual-Only Verifications":

| # | Criterion | Result | Evidence |
|---|-----------|--------|----------|
| 1 | Spectral italic fidelity (D-specifics) | **PASS** | Real Spectral italic glyphs on the hero headline's `never leaves your Mac.` — distinct letterforms vs. upright cut (not a browser-synthesized slant). Matches the Google Fonts Spectral italic specimen. |
| 2 | Nav scroll state transition (D-17) | **PASS** | Transparent/paper at scroll=0; `paper-warm/92 + shadow-btn` when scrolled; smooth transition both directions; no jitter or flash. |
| 3 | prefers-reduced-motion fallback (D-19) | **PASS** | With DevTools Rendering → `prefers-reduced-motion: reduce` emulation + hard reload, all Reveal-wrapped blocks (three-things cards, feature blocks, final CTA) render fully opaque on first paint. No fade-in observed anywhere. |
| 4 | Responsive breakpoint collapse (CONTEXT "Responsive breakpoints") | **PASS** | No horizontal scroll at 1440 / 980 / 899 / 819 / 390 px. FeatureBlocks collapse copy-first at ≤899px — heading renders before mock, no reading-order inversion. |
| 5 | Hero LCP + CLS (D-07) on production build | **PASS** | Lighthouse against `next build && next start`: **LCP ≤ 2.5s**, **CLS ≤ 0.01**. |

UAT resume signal: `approved`.

## Task Commits

1. **Task 1 — Compose page.tsx** — `a205597` (feat)
2. **Task 2 — Human UAT checkpoint** — no code commit (verification-only; human approval recorded in this SUMMARY)

Plan metadata (this SUMMARY) is committed by the executor after UAT approval with `--no-verify`.

## Files Created / Modified

| Path | Lines | Kind | Role |
|---|---|---|---|
| `website/src/app/page.tsx` | 93 | modified (wholesale replace) | Landing-page composition: Hero → ThreeThingsStrip → 4× FeatureBlock → ShortcutGrid → FinalCTA |

No new files. Every component consumed by `page.tsx` was shipped by Plans 01-04.

## Decisions Made

- **Four explicit FeatureBlock call-sites, not a `.map(features)` loop.** Feature 2's body is a JSX fragment (`<>…<em className="italic">is</em>…</>`) while Features 0/1/3 use plain strings. Building a discriminated-union feature-object type would have added ceremony without improving readability; four explicit call-sites keep each block's props visible at the call-site and let TypeScript infer the `body: ReactNode` shape per-block.
- **`<em className="italic">` on Feature 2 — no color modifier.** The plan's feature-spec table wrote `<em className="italic">is</em>`. The mock renders the italic word in default ink (not the navy/accent variant); adding `text-accent-ink` would have changed the glyph color. Keeping only `italic` preserves both the real Spectral italic face (loaded in `layout.tsx` Plan 01) and the mock's tonal intent.
- **Hairline `<hr>` rules at page-level, not inside FeatureBlock.** The plan prescribed this pattern (three `<hr>` elements between four blocks). Ruling from the outside keeps FeatureBlock presentation-agnostic about its neighbors — callers decide whether to rule between blocks, and the rule strength is consistent with the `border-rule` token used elsewhere.
- **Container `max-w-[1200px] px-6 md:px-10`.** Matches Plan-02's Footer `max-w-[1200px]` and Plan-03's Hero section gutter. Keeps vertical rhythm aligned across the page without ad-hoc widths.
- **Plan executed exactly as written.** Task 1's `<action>` block gave the full file contents; I shipped it verbatim. No deviation rules (Rules 1-3) triggered.

## Deviations from Plan

**None — plan executed exactly as written.**

Task 1's `<action>` block contained the complete `page.tsx` contents, and the file shipped byte-for-byte as specified. Typecheck and build passed on first run. verify-landing.mjs exited 0 on first run. Task 2 (UAT) ran to completion with all 5/5 criteria approved by the human on first review.

The workflow wrinkle inherited from Plans 01-04 (the plan's `pnpm --filter ps-transcribe-website` verify strings vs. the repo's actual single-package layout — no workspace file, no `typecheck` script) was handled the same way: ran `./node_modules/.bin/tsc --noEmit` and `./node_modules/.bin/next build` directly inside `website/`. Already documented in 13-01-SUMMARY Deviation 1; not re-tracked here.

## Issues Encountered

- **Phantom git-status noise inherited from the parent branch snapshot.** As in Plans 01-04, the worktree carries unrelated `.planning/STATE.md` modifications + four `assets/screenshot-*.png` deletions + one `design/…` screenshot modification from the parent branch. None touch this plan's surface; the committed file was exclusively `website/src/app/page.tsx` (commit `a205597`).
- **Next.js turbopack-root inference warning.** Still present during `next build` (inherits from Plans 01-04). Build completes cleanly; this is ancestor-lockfile noise, not a correctness issue. Logged as a future polish candidate (`turbopack.root` in `next.config.ts`).

## User Setup Required

None. No external services, no auth gates, no secrets. The UAT required a running dev server (`pnpm dev`) plus a production build (`next build && next start`) for Lighthouse — both run locally with zero configuration.

## UAT Outcome

**Approved.** All 5 visual-only criteria passed on first inspection. No gap-closure plan scheduled. Phase 13 shipped.

The `<resume-signal>` contract was satisfied exactly as specified: the human returned `approved` after verifying:

1. Spectral italic letterforms match the Google Fonts specimen.
2. Nav scroll state transitions smoothly between transparent→shadowed→transparent.
3. `prefers-reduced-motion: reduce` emulation shows no Reveal fade-ins anywhere.
4. No horizontal scroll at any tested width (1440 / 980 / 899 / 819 / 390 px); feature blocks read heading-first at ≤899px.
5. Lighthouse on `next start` (production build) measured LCP ≤ 2.5s and CLS ≤ 0.01.

## Build Bundle Size

Informational — not a phase gate. Directional note: the composed landing page is a static Server Component; the only client-island JS on `/` ships from `Nav` (useScrolled) and `Reveal` (useReveal IntersectionObserver). The four mini-mocks and all four FeatureBlocks are pure server JSX — zero runtime JS for their markup. The hero image is the largest asset at 408 KB (`/app-screenshot.png`, 2260×1408 PNG); it eager-loads above the fold via `<Image preload>` (Next 16). The Phase-12 placeholder had a trivial bundle (inline styles, no sections); the Phase-13 page is heavier by design — sections, mocks, typography, and imagery are the phase's entire deliverable.

## Deferred Follow-ups

None identified during UAT. Candidate micro-polish items (not blocking phase closure):

- Silence the Next.js turbopack-root inference warning by pinning `turbopack.root` in `next.config.ts` (inherited from Plans 01-04; not a correctness issue).
- Add a `"typecheck": "tsc --noEmit"` script to `website/package.json` so future plan verify-strings that call `pnpm typecheck` resolve cleanly without the direct-binary workaround.

Both are pure housekeeping; neither is required by Phase 13 verification.

## Next Phase Readiness

- **Phase 14 (docs)** inherits Nav + Footer from `layout.tsx` automatically. The `/docs` route currently 404s (expected per UAT bonus sanity check); Phase 14 will populate it.
- **Phase 15 (changelog)** inherits the same chrome. The `/changelog` route currently 404s (expected); Phase 15 will render the parsed CHANGELOG via `getAllReleases()` from Plan 01.
- **Vercel preview deploys** (auto-generated from PRs) will reproduce the same build, since the production commands are identical to what ran locally.
- **All LAND-01..LAND-07 requirements are satisfied with rendered-HTML evidence** — every assertion has a green OK line in `verify-landing.mjs` output plus visual confirmation from the human UAT.

## Verification Summary

| Check | Result |
|---|---|
| `test -f website/src/app/page.tsx` | OK |
| `wc -l website/src/app/page.tsx` | 93 lines (≥ 80 min) |
| `grep -q "import { Hero }"` page.tsx | OK |
| `grep -q "import { ThreeThingsStrip }"` page.tsx | OK |
| `grep -q "import { FeatureBlock }"` page.tsx | OK |
| `grep -q "import { ShortcutGrid }"` page.tsx | OK |
| `grep -q "import { FinalCTA }"` page.tsx | OK |
| `grep -q "DualStreamMock"` / `ChatBubbleMock` / `ObsidianVaultMock` / `NotionTableMock` | all 4 OK |
| `grep -c "index={" page.tsx` | 4 (indexes 0..3) |
| `grep -q 'the transcript <em' page.tsx` | OK (Feature 2 italic `is` preserved) |
| `! grep -q "Site coming soon" page.tsx` | OK (placeholder removed) |
| `! grep -qE 'style=\{\{' page.tsx` | OK (no inline style blocks) |
| `./node_modules/.bin/tsc --noEmit` inside `website/` | exit 0 |
| `./node_modules/.bin/next build` inside `website/` | exit 0 |
| `node website/scripts/verify-landing.mjs` | exit 0 |
| `verify-landing.mjs` tally | **32 OK / 0 MISS / 0 BAD** |
| UAT criterion 1 (Spectral italic) | PASS |
| UAT criterion 2 (Nav scroll state) | PASS |
| UAT criterion 3 (prefers-reduced-motion) | PASS |
| UAT criterion 4 (Responsive breakpoints 1440/980/899/819/390) | PASS |
| UAT criterion 5 (Lighthouse LCP ≤ 2.5s, CLS ≤ 0.01 on production build) | PASS |

## Known Stubs

None. The composed page renders real content end-to-end: SITE constants flow through Hero CTAs + Footer, `getLatestRelease()` powers the hero eyebrow and FinalCTA stamp, the four FeatureBlocks carry real copy + real mini-mocks with real visual data. No TODOs, no FIXMEs, no "coming soon" placeholders, no empty-array props that flow to UI rendering.

The only 404 routes (`/docs`, `/changelog`) are explicitly documented as Phase 14/15 deliverables in CONTEXT.md and the UAT script; they are deferred by design, not stubs in this plan.

## Threat Flags

None. No new trust boundaries, endpoints, or auth paths. `page.tsx` is pure composition — it introduces zero new network surface, storage surface, or authorization logic. All external URLs flow through `SITE.*` (already covered by prior plans' threat registers). The Phase-13 threat register T-13-05-01..T-13-05-05 all resolved as mitigated or accepted per plan:

- **T-13-05-01** (Tampering — Feature 2 JSX body serialization) mitigated: `next build` succeeded, confirming plain-JSX children serialized cleanly across the Server → Reveal (Client) boundary.
- **T-13-05-02** (Integrity — forbidden strings) mitigated: verify-landing.mjs's four `forbidden-absent` assertions all OK.
- **T-13-05-03** (DoS — missing prerendered HTML) mitigated: verify-landing.mjs found `/index.html` in `.next/server/app/` on first candidate path.
- **T-13-05-04** (Info disclosure — `noindex` leak) mitigated: forbidden-absent assertion for `content="noindex"` OK.
- **T-13-05-05** (EoP — tabnabbing via `target="_blank"`) accepted: no `target="_blank"` attributes anywhere in Phase-13 rendered HTML.

## Self-Check: PASSED

Verified all files exist on disk:

- `website/src/app/page.tsx` — FOUND (93 lines, modified in-place)
- `.planning/phases/13-landing-page/13-05-SUMMARY.md` — FOUND (this file)

Verified Task 1 commit exists:

- `a205597` — FOUND (`feat(13-05): compose landing page sections in page.tsx`)

Task 2 (UAT) correctly produced no code commit — human approval is documented in this SUMMARY's UAT section and was required for this SUMMARY to be written.

---

*Phase: 13-landing-page*
*Plan: 05*
*Completed: 2026-04-23*
