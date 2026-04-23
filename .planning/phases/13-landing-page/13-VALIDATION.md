---
phase: 13
slug: landing-page
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-22
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

> The planner fills this out as each task is defined. Every task gets either an automated command or an explicit Wave 0 dependency. Empty rows here are placeholders for the planner to populate.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-XX-XX | XX | N | LAND-0X | — | N/A (static site) | grep/build | `{command from RESEARCH.md}` | ⬜ / ✅ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `website/scripts/verify-landing.mjs` — grep-suite script asserting every LAND-01..LAND-07 criterion against `.next/server/app/page.html` (or equivalent build output)
- [ ] `website/public/app-screenshot.png` — copied from `design/ps-transcribe-web-unzipped/assets/app-screenshot.png` (unblocks LAND-02 verification)
- [ ] `website/src/lib/site.ts` — GitHub owner/slug constant (unblocks DMG URL, GitHub link, Sparkle appcast assertions)
- [ ] `website/src/lib/changelog.ts` — build-time CHANGELOG parser (unblocks version-string presence assertions)

*Next.js + Tailwind v4 + TypeScript toolchain was installed in Phase 11; no framework install required.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `prefers-reduced-motion: reduce` renders hero + all sections immediately visible (no transition) | D-19 | Emulation requires a real browser with media-query override; grep on built HTML can't prove the runtime behavior | 1) Run `pnpm dev`. 2) DevTools → Rendering → Emulate CSS media feature `prefers-reduced-motion: reduce`. 3) Hard-reload `/`. 4) Confirm hero + every feature/strip/CTA/footer section is fully opaque and positioned before any scroll — no fade-in transition visible. |
| Nav scrolled-state transitions smoothly (transparent → `paper-warm` + `shadow-btn`) at `scrollY > 6` | D-17 | Scroll-driven class change; grep can assert the CSS rule exists but not that it's applied at the right threshold | 1) Run `pnpm dev`. 2) Load `/`. 3) Confirm nav is transparent at the top. 4) Scroll down 8px. 5) Confirm nav gains a subtle shadow + warm-paper background. 6) Scroll back to top and confirm it reverts. |
| Hero screenshot loads eagerly (LCP image) without layout shift | D-07 | Perf measurement; not a correctness check. Automated grep asserts `preload={true}` and explicit `width`/`height` are present; actual LCP timing needs a browser perf audit | 1) Run `pnpm build && pnpm start`. 2) Chrome DevTools → Lighthouse → Performance audit on `/`. 3) Confirm LCP ≤ 2.5s on emulated cable + desktop. 4) Confirm CLS = 0. |
| Spectral italic `<em>` in hero renders the real italic cut, not a synthesized slant | D-specifics | Visual verification only — can be confirmed by the presence of `italic: true` in the font config, but the actual rendered glyphs need eyeball-level inspection | 1) Run `pnpm dev`. 2) Zoom the hero `<em>` in the browser. 3) Compare 'a', 'e', 'y' glyphs against a reference Spectral italic specimen (e.g., Google Fonts page). Correct italic has distinct stroke terminals; synthesized slant just skews the upright glyphs. |
| Responsive breakpoints collapse correctly (hero ≤980px, feature ≤900px, strip ≤820px) | CONTEXT.md "Responsive breakpoints" | Layout visual — grep on CSS can assert the media queries exist but not that the collapsed layout is sensible | 1) Run `pnpm dev`. 2) DevTools → responsive mode. 3) Drag viewport to 979px → hero stacks. 4) Drag to 899px → feature grid collapses to single column. 5) Drag to 819px → three-things strip collapses to single column. 6) Verify no horizontal scrollbar at any width ≥360px. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (verify-landing.mjs, app-screenshot.png, site.ts, changelog.ts)
- [ ] No watch-mode flags (no `pnpm dev` in verification commands)
- [ ] Feedback latency < 45s
- [ ] `nyquist_compliant: true` set in frontmatter (set by planner after per-task map filled)

**Approval:** pending
