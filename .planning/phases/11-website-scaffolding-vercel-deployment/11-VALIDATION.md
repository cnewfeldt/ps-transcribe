---
phase: 11
slug: website-scaffolding-vercel-deployment
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-22
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None (deferred) — `pnpm build` runs `tsc --noEmit` + ESLint, which covers scope-of-phase-11 behavior |
| **Config file** | none — Wave 0 installs nothing new (pnpm already present locally: `pnpm@10.13.1`) |
| **Quick run command** | `cd website && pnpm lint && pnpm build` |
| **Full suite command** | `cd website && pnpm lint && pnpm build && curl -sfI https://ps-transcribe.vercel.app \| head -1` |
| **Estimated runtime** | ~30-60s local build; +~5s HTTP probe suite |

**Rationale:** Phase 11 is infrastructure + placeholder. A test-runner install would be ceremony with no target. Next.js's own typecheck (`pnpm build` → `tsc --noEmit` internally) + ESLint cover the scoped changes. Phases 13–15 will add behavioral tests as page logic lands.

---

## Sampling Rate

- **After every task commit:** Run `cd website && pnpm lint && pnpm build` (local)
- **After every plan wave:** Run `cd website && pnpm lint && pnpm build` + verify `.gitignore` excludes
- **Before `/gsd-verify-work`:** Full HTTP probe suite (all 18 probes below) must return green against `https://ps-transcribe.vercel.app`
- **Max feedback latency:** ~60s local (build), ~30s remote (post-deploy HTTP probes)

---

## Per-Task Verification Map

> Populated by the planner from plan tasks. Initial rows seeded from RESEARCH.md probe list (see below).

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| _populated after planning_ | | | | | | | | | ⬜ pending |

### Requirement Probe Suite (from RESEARCH.md §Validation Architecture)

| Req ID | Behavior | Type | Automated Command |
|--------|----------|------|-------------------|
| SITE-01 | Next.js App Router scaffold exists | file-check | `test -f website/package.json && test -f website/tsconfig.json && test -d website/src/app` |
| SITE-01 | TypeScript strict compiles cleanly | build | `cd website && pnpm build` (exit 0) |
| SITE-01 | `@/*` alias maps to `src/*` | file-check + build | `grep -q '"@/\*": \["./src/\*"\]' website/tsconfig.json && cd website && pnpm build` |
| SITE-01 | Node 22 pinned in both places | file-check | `test "$(cat website/.nvmrc)" = "22" && node -e "const p=require('./website/package.json'); if(!/22/.test(p.engines?.node)) process.exit(1)"` |
| SITE-01 | pnpm is the package manager | file-check | `test -f website/pnpm-lock.yaml && ! test -f website/package-lock.json && ! test -f website/yarn.lock` |
| SITE-02 | Push triggers Vercel build | e2e | `gh api repos/:owner/ps-transcribe/commits/$(git rev-parse HEAD)/status --jq '.statuses[] \| select(.context\|startswith("Vercel")) \| .state'` → "success" |
| SITE-03 | PR gets a preview URL | e2e manual | Open PR; check for Vercel bot comment with `https://ps-transcribe-git-<branch>-<user>.vercel.app` |
| SITE-04 | Production reachable | HTTP | `curl -sfI https://ps-transcribe.vercel.app \| head -1` → `HTTP/2 200` |
| SITE-04 | Production renders Chronicle placeholder | HTTP | `curl -s https://ps-transcribe.vercel.app \| grep -q 'PS Transcribe'` |
| SITE-05 | `.gitignore` excludes build artifacts | file-check | `grep -q 'website/.next/' .gitignore && grep -q 'website/node_modules/' .gitignore` |
| SITE-05 | No build artifacts tracked in git | file-check | `git ls-files website/.next website/node_modules 2>/dev/null \| wc -l` = 0 |
| D-09 | Swift-only commits don't redeploy | manual | After a Swift-only commit on `main`, Vercel deployments list shows "Ignored Build Step" / Canceled |
| D-15 | All three fonts load on production | HTTP | `curl -s https://ps-transcribe.vercel.app \| grep -oE '--font-(inter\|spectral\|jetbrains-mono)' \| sort -u \| wc -l` → 3 |
| D-17 | robots.txt served | HTTP | `curl -sfI https://ps-transcribe.vercel.app/robots.txt \| head -1` → 200 |
| D-17 | sitemap.xml served | HTTP | `curl -sf https://ps-transcribe.vercel.app/sitemap.xml \| grep -q '<loc>https://ps-transcribe.vercel.app</loc>'` |
| D-17 | manifest served | HTTP | `curl -sfI https://ps-transcribe.vercel.app/manifest.webmanifest \| head -1` → 200 |
| D-17 | OG image served | HTTP | `curl -sfI https://ps-transcribe.vercel.app/opengraph-image.png \| head -1` → 200 |
| D-17 | Favicon served | HTTP | `curl -sfI https://ps-transcribe.vercel.app/icon.png \| head -1` → 200 |
| Guardrail | Swift package still builds | integration | `cd PSTranscribe && swift build` (exit 0) — unchanged from pre-phase-11 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `pnpm` already installed locally (`pnpm@10.13.1`). On fresh machines: `brew install pnpm`.
- [ ] No test framework scaffolding required — phase 11 validates via build + HTTP probes, not unit tests.
- [ ] Swift build verification (`swift build` exits 0) is a guardrail — no new tooling needed.

*Existing infrastructure covers all phase-11 verification needs. No Wave 0 test-runner install.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Vercel dashboard setup (repo import, Root Directory, Ignored Build Step) | SITE-02 | One-time dashboard configuration in Vercel UI, not a repo artifact | Follow dashboard runbook in Plan C; verify all 4 settings match CONTEXT.md D-07/D-08/D-09 |
| PR preview URL visibility | SITE-03 | Requires an open PR and the Vercel GitHub App installed | Open any PR touching `/website`; confirm Vercel bot comment appears with preview URL |
| Ignored Build Step behavior | D-09 | Requires a Swift-only commit on `main` post-setup to observe | After setup, push a Swift-only commit; verify Vercel shows "Ignored Build Step" status |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (N/A — no new test infra)
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s local / < 30s HTTP probe
- [ ] `nyquist_compliant: true` set in frontmatter (set after planner populates Per-Task Verification Map)

**Approval:** pending
