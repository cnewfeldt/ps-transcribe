---
phase: 11
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - website/package.json
  - website/pnpm-lock.yaml
  - website/tsconfig.json
  - website/.nvmrc
  - website/next.config.ts
  - website/postcss.config.mjs
  - website/eslint.config.mjs
  - website/next-env.d.ts
  - website/src/app/layout.tsx
  - website/src/app/page.tsx
  - website/src/app/globals.css
  - website/public/
  - .gitignore
autonomous: true
requirements:
  - SITE-01
  - SITE-05
tags:
  - nextjs
  - scaffolding
  - pnpm
  - typescript
  - monorepo
must_haves:
  truths:
    - "A /website subdirectory exists with its own package.json independent from the Swift package"
    - "Running pnpm install && pnpm dev inside /website boots a Next.js App Router dev server with TypeScript compiling cleanly"
    - "Node 22 is pinned by both .nvmrc (value '22') and package.json engines.node ('>=22 <23')"
    - "pnpm is the package manager — pnpm-lock.yaml exists, no package-lock.json, no yarn.lock"
    - "Repo .gitignore excludes website/.next/, website/node_modules/, website/.vercel/, website/out/"
    - "Swift package at repo root still builds untouched"
  artifacts:
    - path: "website/package.json"
      provides: "Node package manifest with engines.node pin, Next 16 + React 19 deps"
      contains: '"engines"'
    - path: "website/pnpm-lock.yaml"
      provides: "pnpm lockfile (commit to git so Vercel auto-detects pnpm)"
    - path: "website/tsconfig.json"
      provides: "TypeScript strict config with @/* alias mapped to src/*"
      contains: '"@/*": ["./src/*"]'
    - path: "website/.nvmrc"
      provides: "Local Node auto-switch pin"
      contains: "22"
    - path: "website/src/app/layout.tsx"
      provides: "Root layout scaffolded by create-next-app (content rewrite in plan 02)"
    - path: "website/src/app/page.tsx"
      provides: "Default home page scaffolded by create-next-app (content rewrite in plan 02)"
    - path: ".gitignore"
      provides: "Repo root gitignore extended with four website/ paths"
      contains: "website/.next/"
  key_links:
    - from: "Vercel"
      to: "website/pnpm-lock.yaml"
      via: "auto-detection"
      pattern: "lockfileVersion"
    - from: "Vercel"
      to: "website/package.json engines.node"
      via: "Node version resolution"
      pattern: '"node": ">=22 <23"'
---

<objective>
Scaffold a Next.js 16 App Router + TypeScript project at `/website` using the non-interactive `create-next-app` invocation that matches every locked decision in 11-CONTEXT.md (D-01 through D-06, D-12, D-13), pin Node 22 in both `.nvmrc` and `package.json` engines (D-03), and extend the repo root `.gitignore` with the four website build-artifact paths (D-14).

Purpose: Establish the subdirectory, lockfile, and ignore rules that every later plan (02 content/metadata, 03 Vercel deployment) and every later phase (12 design system, 13 landing, 14 docs, 15 changelog) depends on. This plan is Wave 1 — nothing in the phase can progress until `/website` exists with a working `pnpm build`.

Output:
- `/website/` directory populated by `create-next-app` (TypeScript, Tailwind, ESLint, src-dir, App Router, `@/*` alias, pnpm)
- `website/.nvmrc` with value `22`
- `website/package.json` with `engines.node: ">=22 <23"`
- Extended `.gitignore` with the four website paths
- `pnpm build` completes successfully locally (verifies TS strict compiles, Tailwind plumbed, ESLint config valid)
- Swift package at repo root still builds (guardrail)
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/11-website-scaffolding-vercel-deployment/11-CONTEXT.md
@.planning/phases/11-website-scaffolding-vercel-deployment/11-RESEARCH.md
@.planning/phases/11-website-scaffolding-vercel-deployment/11-VALIDATION.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Scaffold Next.js 16 project at /website via create-next-app</name>
  <files>website/package.json, website/pnpm-lock.yaml, website/tsconfig.json, website/next.config.ts, website/postcss.config.mjs, website/eslint.config.mjs, website/next-env.d.ts, website/src/app/layout.tsx, website/src/app/page.tsx, website/src/app/globals.css, website/public/</files>
  <read_first>
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-CONTEXT.md §decisions (D-01 through D-06, D-12, D-13 are all implemented by this single create-next-app invocation)
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-RESEARCH.md §Pattern 1 "Non-interactive create-next-app" (exact flags) and §Anti-Patterns ("Running create-next-app inside the repo without --disable-git")
    - /Users/cary/Development/ai-development/ps-transcribe/ (verify `ls website` returns nothing before running — collision check)
  </read_first>
  <action>
Run this EXACT command from the repo root `/Users/cary/Development/ai-development/ps-transcribe/` (do not substitute flags, do not paraphrase — every flag maps to a locked decision):

```bash
cd /Users/cary/Development/ai-development/ps-transcribe
pnpm create next-app@latest website \
  --typescript \
  --tailwind \
  --eslint \
  --app \
  --src-dir \
  --import-alias "@/*" \
  --use-pnpm \
  --turbopack \
  --no-react-compiler \
  --disable-git \
  --yes
```

Flag-to-decision mapping (do not omit any):
- `--typescript` → D-05 (TypeScript strict mode; create-next-app sets `strict: true` by default)
- `--tailwind` → D-12 (Tailwind CSS plumbing installed, tokens deferred to phase 12)
- `--eslint` → D-13 (ESLint flat config defaults; no Prettier, no Biome)
- `--app` → D-02 (App Router)
- `--src-dir` → D-04 (src/app/ layout)
- `--import-alias "@/*"` → D-06 (single @/* alias to src/*)
- `--use-pnpm` → D-01 (pnpm package manager; generates pnpm-lock.yaml)
- `--turbopack` → D-02 note (Turbopack is default in Next.js 16 but making it explicit per RESEARCH.md Pattern 1)
- `--no-react-compiler` → RESEARCH.md Pattern 1 (placeholder has no reason to pull RC toolchain)
- `--disable-git` → prevents nested .git/ init inside the existing repo (RESEARCH.md Anti-Patterns)
- `--yes` → accepts defaults for any remaining prompts (e.g., AGENTS.md prompt) so execution is non-interactive

Expected Next.js version: 16.2.4 (verified 2026-04-22 via `npm view next version`). If newer minor (16.2.5, 16.3.x) ships between research and execution, accept it — majors only break this plan. If pnpm is not installed, run `brew install pnpm` first; local machine has pnpm 10.13.1 per RESEARCH.md §Environment Availability.

Do NOT run `pnpm install` separately — create-next-app runs it as part of the scaffold. Do NOT add any extra dependencies in this task. Do NOT modify any of the generated files in this task (modifications to layout.tsx and page.tsx happen in plan 02).

After scaffold completes, verify the structure:
```bash
ls website/src/app/          # should list: favicon.ico, globals.css, layout.tsx, page.tsx
cat website/tsconfig.json    # should contain "strict": true and "@/*": ["./src/*"]
test -f website/pnpm-lock.yaml && echo "lockfile present"
test ! -f website/package-lock.json && test ! -f website/yarn.lock && echo "no foreign lockfiles"
test ! -d website/.git && echo "no nested git repo"
```
  </action>
  <verify>
    <automated>cd /Users/cary/Development/ai-development/ps-transcribe && test -f website/package.json && test -f website/tsconfig.json && test -d website/src/app && test -f website/pnpm-lock.yaml && test ! -f website/package-lock.json && test ! -f website/yarn.lock && test ! -d website/.git && grep -q '"@/\*": \["./src/\*"\]' website/tsconfig.json && grep -q '"strict": true' website/tsconfig.json</automated>
  </verify>
  <acceptance_criteria>
    - `website/package.json` exists
    - `website/tsconfig.json` exists AND contains the exact string `"@/*": ["./src/*"]` (grep passes)
    - `website/tsconfig.json` contains `"strict": true`
    - `website/src/app/` directory exists
    - `website/pnpm-lock.yaml` exists (committable lockfile)
    - `website/package-lock.json` does NOT exist
    - `website/yarn.lock` does NOT exist
    - `website/.git` does NOT exist (no nested git repo)
    - `website/package.json` declares `"next"` with version starting with `16.` (grep: `grep -E '"next":\s*"\^?16\.' website/package.json`)
    - `website/src/app/layout.tsx` exists (scaffold default — content updated in plan 02)
    - `website/src/app/page.tsx` exists (scaffold default — content updated in plan 02)
    - `website/src/app/globals.css` exists with Tailwind directives
    - `website/eslint.config.mjs` exists (flat config per Next.js 16 default)
  </acceptance_criteria>
  <done>`/website/` scaffolded with all files above present. No nested .git/. Next.js version is 16.x. pnpm-lock.yaml committable.</done>
</task>

<task type="auto">
  <name>Task 2: Pin Node 22 and extend .gitignore with website paths</name>
  <files>website/.nvmrc, website/package.json, .gitignore</files>
  <read_first>
    - /Users/cary/Development/ai-development/ps-transcribe/.gitignore (read current state before appending — do not replace existing patterns)
    - website/package.json (read scaffolded version before editing; create-next-app produces a baseline package.json without engines)
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-CONTEXT.md §decisions D-03 (Node pin requires BOTH .nvmrc and engines.node) and D-14 (exact four paths)
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-RESEARCH.md §Code Examples "Root package.json engines pin" and ".gitignore additions"
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-RESEARCH.md §Anti-Patterns "Setting Node version only in .nvmrc" (explains why both files are required — Vercel reads engines.node, not .nvmrc)
  </read_first>
  <action>
Three edits, in order:

**Edit 1 — Create `website/.nvmrc`:** Write the file `website/.nvmrc` with exactly these bytes: `22\n` (the literal digits "22" followed by a single newline — no "v", no "v22", no quotes). This is consumed by local fnm/nvm for auto-switching. Vercel ignores it.

**Edit 2 — Add `engines.node` to `website/package.json`:** Add a top-level `"engines"` key with exact value `{ "node": ">=22 <23" }`. Place it immediately after the existing `"private"` key (or before `"scripts"` if `"private"` is absent) to match typical ordering. Do NOT change any other field. Do NOT add `packageManager` — auto-detection from pnpm-lock.yaml is preferred per RESEARCH.md Pitfall 6.

The final engines block must be exactly:
```json
  "engines": {
    "node": ">=22 <23"
  },
```

**Edit 3 — Extend repo root `.gitignore`:** Append a new section at the END of `/Users/cary/Development/ai-development/ps-transcribe/.gitignore` (after the last existing line). Append EXACTLY this block, preserving blank line before the `# Next.js / website build artifacts` comment:

```
# Next.js / website build artifacts
website/.next/
website/node_modules/
website/.vercel/
website/out/
```

Do NOT add `website/next-env.d.ts` to .gitignore — per RESEARCH.md Open Question 3, commit `next-env.d.ts` (Next.js guidance).
Do NOT remove, reorder, or modify any existing .gitignore entries (existing entries: `PSTranscribe/.build/`, `dist/`, `build/`, `.DS_Store`, `.env`, `*.env.*`, `*.p12`, `*.cer`, `*.pem`, `*.key`, `*.keychain`, `*.keychain-db`, `*.mobileprovision`, `*.xcconfig`, `.claude/`, `.worktrees/`, `SECURITY-SCAN.md` — all must remain untouched).

After all three edits:
- Run `cd website && pnpm build` — MUST exit 0. This verifies TS strict compiles, Tailwind CSS processes, ESLint passes. Expected runtime: 30-60s per RESEARCH.md §Validation Architecture.
- Run `cd PSTranscribe && swift build` — MUST exit 0. This is the guardrail probe from 11-VALIDATION.md confirming the Swift package still builds after website scaffold lands (RESEARCH.md §Validation Architecture final row).
  </action>
  <verify>
    <automated>cd /Users/cary/Development/ai-development/ps-transcribe && test "$(cat website/.nvmrc)" = "22" && node -e "const p=require('./website/package.json'); if(!/>=22\s*<23/.test(p.engines?.node||'')) { console.error('engines.node missing or wrong'); process.exit(1); }" && grep -q '^website/\.next/$' .gitignore && grep -q '^website/node_modules/$' .gitignore && grep -q '^website/\.vercel/$' .gitignore && grep -q '^website/out/$' .gitignore && cd website && pnpm build</automated>
  </verify>
  <acceptance_criteria>
    - `cat website/.nvmrc` returns exactly `22` (no trailing characters besides the newline)
    - `website/package.json` contains an `engines` key with `"node"` matching the regex `>=22\s*<23`
    - `.gitignore` contains the literal line `website/.next/`
    - `.gitignore` contains the literal line `website/node_modules/`
    - `.gitignore` contains the literal line `website/.vercel/`
    - `.gitignore` contains the literal line `website/out/`
    - `.gitignore` does NOT contain `website/next-env.d.ts` (this file must be committed, not ignored)
    - `cd website && pnpm build` exits 0 (full production build succeeds — proves TS strict, Tailwind, ESLint all green)
    - `cd PSTranscribe && swift build` exits 0 (guardrail — Swift package untouched)
    - `git status` shows `website/` directory as tracked, with NO entries under `website/.next/` or `website/node_modules/` (run `git ls-files website/.next website/node_modules 2>/dev/null | wc -l` → should output `0`)
    - Pre-existing .gitignore entries remain intact (spot-check: `grep -c '^\.DS_Store$' .gitignore` returns 1, `grep -c '^\.env$' .gitignore` returns 1, `grep -c '^SECURITY-SCAN\.md$' .gitignore` returns 1)
  </acceptance_criteria>
  <done>Node 22 pinned in both `.nvmrc` (value `22`) and `package.json` engines (`>=22 <23`). `.gitignore` extended with the four `website/` paths. `pnpm build` succeeds. `swift build` still succeeds. No build artifacts tracked by git.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| npm registry → local machine | `pnpm create next-app` + transitive deps enter the repo via lockfile |
| Local machine → git remote | pnpm-lock.yaml tree and package.json get pushed to GitHub |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-11-01 | Tampering | `pnpm create next-app` dependency chain — possible typosquat or supply-chain injection via transitive deps in the initial scaffold | mitigate | (a) Using `pnpm create next-app@latest` — resolves to the official `create-next-app` package on npm (verified registry entry). (b) `pnpm-lock.yaml` commits the exact resolved tree so reviewers can inspect the dep closure on first PR. (c) Review `pnpm-lock.yaml` diff on first commit for any unexpected packages (known-safe: next, react, react-dom, typescript, tailwindcss, eslint, @types/*). |
| T-11-02 | Information disclosure | Accidental `.env.local` or secret commit when scaffolding | accept | Existing repo `.gitignore` already covers `.env` and `*.env.*` (verified by read). Phase 11 introduces zero env vars — no API keys, no secrets. No new exposure surface. |
| T-11-03 | Tampering | Nested `.git/` created inside `website/` would corrupt the parent repo | mitigate | `--disable-git` flag passed to create-next-app (per RESEARCH.md Anti-Patterns). Acceptance criterion `test ! -d website/.git` confirms. |
| T-11-04 | Availability | Swift package build breaks due to repo-level file collision | mitigate | `/website/` is a new top-level directory isolated from `PSTranscribe/`, `scripts/`, `assets/` (per CONTEXT.md §code_context). `.gitignore` extension preserves all pre-existing Swift ignore patterns. Acceptance criterion runs `swift build` as guardrail. |

**Out of scope (public marketing site, no auth/input/crypto):** V2 Authentication, V3 Session Management, V4 Access Control, V5 Input Validation, V6 Cryptography — no user surfaces in phase 11 per RESEARCH.md §Security Domain. ASVS L1 V14 Configuration (env/secrets) covered by T-11-02.
</threat_model>

<verification>
- `cd website && pnpm lint && pnpm build` exits 0 (runs ESLint + tsc + next build via Turbopack)
- `cd PSTranscribe && swift build` exits 0 (guardrail — Swift package unchanged)
- `grep -q '"@/\*": \["./src/\*"\]' website/tsconfig.json` passes
- `test "$(cat website/.nvmrc)" = "22"` passes
- All four `website/...` entries present in repo root `.gitignore`
- No build artifacts tracked: `git ls-files website/.next website/node_modules 2>/dev/null | wc -l` returns `0`
</verification>

<success_criteria>
Plan complete when:
1. `/website/package.json`, `/website/tsconfig.json`, `/website/src/app/` exist
2. `/website/.nvmrc` contains `22`; `/website/package.json` `engines.node` matches `>=22 <23`
3. Only lockfile in `/website/` is `pnpm-lock.yaml` (no `package-lock.json`, no `yarn.lock`)
4. Repo root `.gitignore` contains `website/.next/`, `website/node_modules/`, `website/.vercel/`, `website/out/` (and preserves all prior entries)
5. `cd website && pnpm build` exits 0
6. `cd PSTranscribe && swift build` exits 0
7. No nested `website/.git/` directory
8. No files tracked under `website/.next/` or `website/node_modules/` per `git ls-files`
</success_criteria>

<output>
After completion, create `.planning/phases/11-website-scaffolding-vercel-deployment/11-01-SUMMARY.md` describing:
- Next.js version resolved by `create-next-app@latest` (from `website/package.json`)
- pnpm version that generated the lockfile (from `packageManager` field if present, else `pnpm --version` at time of run)
- Any create-next-app interactive prompts encountered (should be none with `--yes`)
- Build time of final `pnpm build` run
- `requirements_completed: [SITE-01, SITE-05]`
</output>
