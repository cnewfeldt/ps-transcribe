---
phase: 12
slug: chronicle-design-system-port
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-22
---

# Phase 12 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None installed — plain command-line verification only (grep + curl + build). No Jest/Vitest/Playwright in `website/package.json`. Justified by declarative/presentational scope; revisit in Phase 14 if MDX/changelog logic warrants unit tests. |
| **Config file** | — |
| **Quick run command** | `cd website && pnpm run build 2>&1 \| head -60` |
| **Full suite command** | `cd website && pnpm run build && pnpm run lint` |
| **Estimated runtime** | ~15-30 seconds for build; lint adds ~5 seconds |

---

## Sampling Rate

- **After every task commit:** `cd website && pnpm run build` (≈15-30s) + targeted grep probes for the files just changed
- **After every plan wave:** `cd website && pnpm run build && pnpm run lint` + all grep probes in the Per-Task Verification Map
- **Before `/gsd-verify-work`:** Full build green + every grep probe passes + manual browser-eye against the Vercel preview URL for visual fidelity vs `chronicle-mock.css`
- **Max feedback latency:** ~35 seconds (build + lint)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 12-01-01 | 01 (tokens+globals.css) | 1 | DESIGN-01 | — | N/A | grep | `grep -c '^@theme inline' website/src/app/globals.css` (expect 1) | ❌ W0 (rewrite) | ⬜ pending |
| 12-01-02 | 01 | 1 | DESIGN-01 | — | N/A | grep | `for c in paper paper-warm paper-soft rule rule-strong ink ink-muted ink-faint ink-ghost accent-ink accent-soft accent-tint spk2-bg spk2-fg spk2-rail rec-red live-green; do grep -q "^  --color-$c:" website/src/app/globals.css \|\| echo "MISSING: --color-$c"; done` (no output) | ❌ W0 | ⬜ pending |
| 12-01-03 | 01 | 1 | DESIGN-01 | — | N/A | grep | `for r in input btn card bubble pill; do grep -q "^  --radius-$r:" website/src/app/globals.css \|\| echo "MISSING: --radius-$r"; done` (no output) | ❌ W0 | ⬜ pending |
| 12-01-04 | 01 | 1 | DESIGN-01 | — | N/A | grep | `for s in lift btn float; do grep -q "^  --shadow-$s:" website/src/app/globals.css \|\| echo "MISSING: --shadow-$s"; done` (no output) | ❌ W0 | ⬜ pending |
| 12-01-05 | 01 | 1 | DESIGN-02 | — | N/A | grep | `grep -q '"SF Pro Text"' website/src/app/globals.css && grep -q '"New York"' website/src/app/globals.css && grep -q '"SF Mono"' website/src/app/globals.css` | ❌ W0 | ⬜ pending |
| 12-01-06 | 01 | 1 | DESIGN-04 | — | Light-mode enforcement | grep | `! grep -q "prefers-color-scheme" website/src/app/globals.css && grep -q "color-scheme: *light" website/src/app/globals.css` | ❌ W0 | ⬜ pending |
| 12-01-07 | 01 | 1 | DESIGN-01/02/04 | — | N/A | build | `cd website && pnpm run build` exits 0 | — | ⬜ pending |
| 12-02-01 | 02 (viewport colorScheme) | 1 | DESIGN-04 | — | Light-mode enforcement | grep | `grep -q "colorScheme: *'light'" website/src/app/layout.tsx` | ✅ (exists, add export) | ⬜ pending |
| 12-02-02 | 02 | 1 | DESIGN-04 | — | Light-mode enforcement | curl+grep | After build+start: `curl -s http://localhost:3000/ \| grep -q 'name="color-scheme" content="light"'` | — | ⬜ pending |
| 12-02-03 | 02 | 1 | DESIGN-02 | — | N/A | grep | `grep -q "next/font/google" website/src/app/layout.tsx && grep -q "Inter\\|Spectral\\|JetBrains_Mono" website/src/app/layout.tsx` (font loading preserved) | ✅ | ⬜ pending |
| 12-03-01 | 03 (primitives) | 2 | DESIGN-03 | — | N/A | fs | `for f in Button Card MetaLabel SectionHeading CodeBlock; do test -f website/src/components/ui/$f.tsx \|\| echo "MISSING: $f.tsx"; done` (no output) | ❌ W0 (5 files) | ⬜ pending |
| 12-03-02 | 03 | 2 | DESIGN-03 | — | N/A | grep | `! grep -rn "^[\"'\"]use client[\"'\"]" website/src/components/ui/` (server-component default) | ❌ W0 | ⬜ pending |
| 12-03-03 | 03 | 2 | DESIGN-03 | — | N/A | grep | `! grep -rn "@apply" website/src/components/ui/` (D-04 anti-pattern guard) | ❌ W0 | ⬜ pending |
| 12-03-04 | 03 | 2 | DESIGN-03 | — | N/A | grep | `! grep -rn "dark:" website/src/components/ui/` (DESIGN-04 guard) | ❌ W0 | ⬜ pending |
| 12-03-05 | 03 | 2 | DESIGN-03 | — | N/A | build | `cd website && pnpm run build` exits 0 after primitives added | — | ⬜ pending |
| 12-04-01 | 04 (design-system page) | 3 | DESIGN-03 | — | N/A | fs | `test -f website/src/app/design-system/page.tsx` | ❌ W0 | ⬜ pending |
| 12-04-02 | 04 | 3 | DESIGN-03 | — | N/A | grep | `grep -qE "Button\|Card\|MetaLabel\|SectionHeading\|CodeBlock" website/src/app/design-system/page.tsx` (all 5 imported) | ❌ W0 | ⬜ pending |
| 12-04-03 | 04 | 3 | DESIGN-01 | — | N/A | grep | `grep -Eq "bg-(paper\|ink\|accent-ink\|spk2-bg)" website/src/app/design-system/page.tsx` (palette utility used) | ❌ W0 | ⬜ pending |
| 12-04-04 | 04 | 3 | DESIGN-04 | — | Noindex dev page | grep | `grep -q "index: *false" website/src/app/design-system/page.tsx && grep -q "follow: *false" website/src/app/design-system/page.tsx` | ❌ W0 | ⬜ pending |
| 12-04-05 | 04 | 3 | DESIGN-04 | — | Sitemap exclusion | grep | `! grep -q "design-system" website/src/app/sitemap.ts` (route NOT listed) | ✅ (unchanged) | ⬜ pending |
| 12-04-06 | 04 | 3 | DESIGN-04 | — | Noindex dev page | curl+grep | After build+start: `curl -s http://localhost:3000/design-system \| grep -q 'name="robots" content="noindex'` | — | ⬜ pending |
| 12-04-07 | 04 | 3 | DESIGN-03 | — | N/A | curl+grep | After build+start: `curl -s http://localhost:3000/design-system \| grep -Ec 'class="[^"]*(bg-ink\|text-ink-faint\|border-rule\|rounded-card)'` (≥ 5) | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

Plan/Wave/Task numbering is provisional — the planner may adjust grouping, but every probe above must land on at least one task's `verification_criteria`.

---

## Wave 0 Requirements

All files below DO NOT exist yet and must be created by Phase 12. No test-framework install needed.

- [ ] `website/src/app/globals.css` — rewrite (currently 27 lines of placeholder) to ship tokens + `@theme inline` + light-mode CSS
- [ ] `website/src/components/ui/Button.tsx` — primary + secondary variants
- [ ] `website/src/components/ui/Card.tsx` — paper bg + 0.5px rule + 10px radius
- [ ] `website/src/components/ui/MetaLabel.tsx` — 10px JetBrains Mono uppercase, 0.08em letter-spacing
- [ ] `website/src/components/ui/SectionHeading.tsx` — Spectral serif at section scale
- [ ] `website/src/components/ui/CodeBlock.tsx` — inline + block, no syntax highlighting
- [ ] `website/src/app/design-system/page.tsx` — palette swatch grid + primitive gallery, noindex
- [ ] `website/src/app/layout.tsx` — add `export const viewport: Viewport = { colorScheme: 'light' }` (do NOT modify font loading)

Optional helper:
- [ ] `website/src/components/ui/index.ts` — barrel export for clean imports

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual fidelity vs `chronicle-mock.css` (button shadow layering, card hairline, typography scale, color accuracy on retina display) | DESIGN-01, DESIGN-03 | No visual regression framework installed; sub-pixel rendering and font rendering need eyeball confirmation | Open Vercel preview URL for `/design-system`, compare side-by-side with `design/ps-transcribe-web-unzipped/index.html` or the app screenshot. Confirm paper palette, primitive shadow fidelity, 0.5px hairline visibility at DPR ≥ 2. |
| OS dark-mode preference doesn't flip the page | DESIGN-04 | Requires toggling macOS System Settings → Appearance → Dark and reloading — not scriptable in CI | Set macOS to Dark mode. Reload `/` and `/design-system`. Confirm paper bg persists, scrollbars stay light, native form control styles (if any) stay light. |
| Webfont fallback visually matches when network blocked | DESIGN-02 | Fallback fonts (SF Pro / New York / SF Mono) only render if Google webfonts fail — requires network throttling | DevTools → Network → block `fonts.gstatic.com`. Reload. Confirm page still renders with recognizable serif + sans + mono fallbacks (SF family on macOS). |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify commands or Wave 0 dependencies flagged
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify (build runs after every commit)
- [ ] Wave 0 covers all MISSING-file references above
- [ ] No watch-mode flags in verify commands (`pnpm run build`, not `pnpm run dev`)
- [ ] Feedback latency < 35s
- [ ] `nyquist_compliant: true` set in frontmatter once planner confirms every probe lands on a task

**Approval:** pending
