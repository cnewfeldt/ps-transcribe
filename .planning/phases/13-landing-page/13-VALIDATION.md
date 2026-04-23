---
phase: 13
slug: landing-page
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-22
updated: 2026-04-23
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

> **Source:** See `13-RESEARCH.md` §"Validation Architecture" for the grep-suite rationale and deterministic verification approach (static landing page + `.next/server/app/page.html` grep).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node.js script (`scripts/verify-landing.mjs`) — no Vitest/Jest/Playwright; plain `fs.readFileSync` + regex grep against built HTML |
| **Config file** | none — the script is self-contained; Wave 0 creates it |
| **Quick run command** | `pnpm --filter ps-transcribe-website build && node website/scripts/verify-landing.mjs` |
| **Full suite command** | `pnpm --filter ps-transcribe-website typecheck && pnpm --filter ps-transcribe-website build && node website/scripts/verify-landing.mjs` |
| **Estimated runtime** | ~25–45 seconds (Next 16 build dominates; script itself is <1s) |

---

## Sampling Rate

- **After every task commit:** Run `pnpm --filter ps-transcribe-website typecheck` (no build, ~3s)
- **After every plan wave:** Run `pnpm --filter ps-transcribe-website build && node website/scripts/verify-landing.mjs`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 45 seconds

---

## Per-Task Verification Map

> Every task has either an `<automated>` verify command OR an explicit Wave 0 dependency that will satisfy it. Task IDs use `{plan}-{task}` convention.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 1 | LAND-02, LAND-03 | T-13-01-02 | URL-encoded DMG filename; factually-correct macOS 26+ string | typecheck + grep | `test -f website/public/app-screenshot.png && grep -q "PS%20Transcribe.dmg" website/src/lib/site.ts && grep -q "macOS 26+" website/src/lib/site.ts && pnpm --filter ps-transcribe-website typecheck` | ⬜ W0-creates | ⬜ pending |
| 13-01-02 | 01 | 1 | LAND-01 (version stamp) | T-13-01-01 | Explicit throw on malformed CHANGELOG; no silent fallback | typecheck + grep | `grep -qE "throw new Error.*CHANGELOG" website/src/lib/changelog.ts && ! grep -q "'use client'" website/src/lib/changelog.ts && pnpm --filter ps-transcribe-website typecheck` | ⬜ W0-creates | ⬜ pending |
| 13-01-03 | 01 | 1 | LAND-01..07 (gate) | T-13-01-03 | Forbidden-string guard rejects `noindex`, `macOS 14+`, dashed DMG URL, `Apple Silicon & Intel` | build + script smoke | `grep -q "style: \['normal', 'italic'\]" website/src/app/layout.tsx && test -x website/scripts/verify-landing.mjs && pnpm --filter ps-transcribe-website build && (node website/scripts/verify-landing.mjs; test $? -eq 1)` | ✅ W0 | ⬜ pending |
| 13-02-01 | 02 | 2 | LAND-06 (nav), LAND-07 (footer) | T-13-02-01, T-13-02-02 | Scroll + IO listeners cleaned up on unmount; reduced-motion fallback | typecheck + grep | `test -f website/src/hooks/useScrolled.ts && test -f website/src/hooks/useReveal.ts && test -f website/src/components/motion/Reveal.tsx && test -f website/src/components/ui/LinkButton.tsx && grep -q "matchMedia.*prefers-reduced-motion: reduce" website/src/hooks/useReveal.ts && grep -q "threshold: 0.12" website/src/hooks/useReveal.ts && pnpm --filter ps-transcribe-website typecheck` | ✅ | ⬜ pending |
| 13-02-02 | 02 | 2 | LAND-06, LAND-07 | T-13-02-03 | No `target="_blank"` without `rel=noopener`; all absent | build + verify subset | `pnpm --filter ps-transcribe-website build && node website/scripts/verify-landing.mjs 2>&1 \| grep -q "OK   LAND-06 nav link to /docs" && node website/scripts/verify-landing.mjs 2>&1 \| grep -q "OK   LAND-07 copyright"` | ✅ | ⬜ pending |
| 13-03-01 | 03 | 3 | LAND-01, LAND-02, LAND-03 | T-13-03-01, T-13-03-02 | Hero uses `preload` (not `priority`); DMG URL from SITE constant; version stamp from CHANGELOG | typecheck + grep | `grep -q "preload" website/src/components/sections/Hero.tsx && ! grep -q "priority" website/src/components/sections/Hero.tsx && grep -q "getLatestRelease" website/src/components/sections/Hero.tsx && grep -q "width={2260}" website/src/components/sections/Hero.tsx && grep -c "<Reveal>" website/src/components/sections/ThreeThingsStrip.tsx && pnpm --filter ps-transcribe-website typecheck` | ✅ | ⬜ pending |
| 13-03-02 | 03 | 3 | LAND-05 (shortcuts) | T-13-03-04 | Combo literals (⌘⇧R etc.) present via `sr-only` for grep + a11y; aria-label on key row | typecheck + grep | `grep -qE "combo: '⌘⇧R'" website/src/components/sections/ShortcutGrid.tsx && grep -qE "combo: '⌘⇧S'" website/src/components/sections/ShortcutGrid.tsx && grep -q "sr-only" website/src/components/sections/ShortcutGrid.tsx && grep -q "OS_REQUIREMENTS_FINAL_CTA" website/src/components/sections/FinalCTA.tsx && pnpm --filter ps-transcribe-website typecheck` | ✅ | ⬜ pending |
| 13-04-01 | 04 | 3 | LAND-04 | T-13-04-03 | FeatureBlock alternation uses scoped `lg:order-*`; mobile stays copy-first | typecheck + grep | `grep -q "index % 2 === 1" website/src/components/sections/FeatureBlock.tsx && grep -c "lg:order-" website/src/components/sections/FeatureBlock.tsx && grep -q "order-1" website/src/components/sections/FeatureBlock.tsx && grep -q "Session · 00:14:32" website/src/components/mocks/DualStreamMock.tsx && ! grep -q "animation-delay" website/src/components/mocks/DualStreamMock.tsx && pnpm --filter ps-transcribe-website typecheck` | ✅ | ⬜ pending |
| 13-04-02 | 04 | 3 | LAND-04 | T-13-04-01 | Mock content verbatim from mock file (ChatBubble/ObsidianVault/NotionTable); no client directives | typecheck + grep | `grep -q "Chronicle · Transcript" website/src/components/mocks/ChatBubbleMock.tsx && grep -q "Obsidian · Vault" website/src/components/mocks/ObsidianVaultMock.tsx && grep -q "Notion · Meetings DB" website/src/components/mocks/NotionTableMock.tsx && grep -q "Product sync — Apr 22" website/src/components/mocks/NotionTableMock.tsx && ! grep -q "'use client'" website/src/components/mocks/ChatBubbleMock.tsx && pnpm --filter ps-transcribe-website typecheck` | ✅ | ⬜ pending |
| 13-05-01 | 05 | 4 | LAND-01..LAND-07 (all) | T-13-05-01, T-13-05-02, T-13-05-03, T-13-05-04 | Composition green; every LAND-01..07 asserted OK; all forbidden strings absent | full suite | `pnpm --filter ps-transcribe-website typecheck && pnpm --filter ps-transcribe-website build && node website/scripts/verify-landing.mjs` | ✅ | ⬜ pending |
| 13-05-02 | 05 | 4 | D-19 (reduced motion), D-17 (nav scroll), D-07 (LCP), D-specifics (Spectral italic), responsive | — | Visual-only criteria not expressible as greps | checkpoint:human-verify | N/A — blocking human UAT, see "Manual-Only Verifications" table below | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky · W0-creates = task creates the Wave-0 artifact itself*

**Wave distribution:**
- Wave 1 (Plan 01): 3 tasks — foundation (all W0 creation happens here).
- Wave 2 (Plan 02): 2 tasks — motion + Nav + Footer (depends on W1).
- Wave 3 (Plans 03 + 04): 4 tasks — sections + mocks, parallel (both depend only on W1+W2).
- Wave 4 (Plan 05): 2 tasks — composition + UAT (depends on W3).

**Nyquist sampling continuity:** Every task has an `<automated>` command except 13-05-02 which is an explicit `checkpoint:human-verify` gate for criteria that grep cannot assert. No three-consecutive-task gap without automated verify.

---

## Wave 0 Requirements

- [ ] `website/scripts/verify-landing.mjs` — grep-suite script asserting every LAND-01..LAND-07 criterion against `.next/server/app/**/*.html` (creator: Task 13-01-03)
- [ ] `website/public/app-screenshot.png` — copied from `design/ps-transcribe-web-unzipped/assets/app-screenshot.png` (creator: Task 13-01-01)
- [ ] `website/src/lib/site.ts` — GitHub owner/slug + URL constants (creator: Task 13-01-01)
- [ ] `website/src/lib/changelog.ts` — build-time CHANGELOG parser (creator: Task 13-01-02)

*Next.js + Tailwind v4 + TypeScript toolchain was installed in Phase 11; no framework install required.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `prefers-reduced-motion: reduce` renders hero + all sections immediately visible (no transition) | D-19 | Emulation requires a real browser with media-query override; grep on built HTML can't prove the runtime behavior | 1) Run `pnpm dev`. 2) DevTools → Rendering → Emulate CSS media feature `prefers-reduced-motion: reduce`. 3) Hard-reload `/`. 4) Confirm hero + every feature/strip/CTA/footer section is fully opaque and positioned before any scroll — no fade-in transition visible. |
| Nav scrolled-state transitions smoothly (transparent → `paper-warm` + `shadow-btn`) at `scrollY > 6` | D-17 | Scroll-driven class change; grep can assert the CSS rule exists but not that it's applied at the right threshold | 1) Run `pnpm dev`. 2) Load `/`. 3) Confirm nav is transparent at the top. 4) Scroll down 8px. 5) Confirm nav gains a subtle shadow + warm-paper background. 6) Scroll back to top and confirm it reverts. |
| Hero screenshot loads eagerly (LCP image) without layout shift | D-07 | Perf measurement; not a correctness check. Automated grep asserts `preload` and explicit `width`/`height` are present; actual LCP timing needs a browser perf audit | 1) Run `pnpm build && pnpm start`. 2) Chrome DevTools → Lighthouse → Performance audit on `/`. 3) Confirm LCP ≤ 2.5s on emulated cable + desktop. 4) Confirm CLS = 0. |
| Spectral italic `<em>` in hero renders the real italic cut, not a synthesized slant | D-specifics | Visual verification only — can be confirmed by the presence of `style: ['normal', 'italic']` in the font config, but the actual rendered glyphs need eyeball-level inspection | 1) Run `pnpm dev`. 2) Zoom the hero `<em>` in the browser. 3) Compare 'a', 'e', 'y' glyphs against a reference Spectral italic specimen (e.g., Google Fonts page). Correct italic has distinct stroke terminals; synthesized slant just skews the upright glyphs. |
| Responsive breakpoints collapse correctly (hero ≤980px, feature ≤900px, strip ≤820px) | CONTEXT.md "Responsive breakpoints" | Layout visual — grep on CSS can assert the media queries exist but not that the collapsed layout is sensible | 1) Run `pnpm dev`. 2) DevTools → responsive mode. 3) Drag viewport to 979px → hero stacks. 4) Drag to 899px → feature grid collapses to single column **copy-first**. 5) Drag to 819px → three-things strip collapses to single column. 6) Verify no horizontal scrollbar at any width ≥360px. |

Gate: Task 13-05-02 is a blocking `checkpoint:human-verify` that cannot be auto-approved; Phase 13 cannot ship until the human returns "approved" on all five criteria.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or explicit manual-UAT checkpoint
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (verify-landing.mjs, app-screenshot.png, site.ts, changelog.ts) — all created by Plan 01
- [x] No watch-mode flags (no `pnpm dev` in verification commands)
- [x] Feedback latency < 45s (build ≈ 25–35s + script ≈ 1s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved — plans 13-01..13-05 ready for `/gsd-execute-phase 13`.
