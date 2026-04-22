# Phase 11: Website Scaffolding & Vercel Deployment - Context

**Gathered:** 2026-04-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Create a `/website` subdirectory in the ps-transcribe repo containing a working Next.js App Router + TypeScript project that auto-deploys to Vercel on every push, produces per-PR preview URLs, and serves production at `ps-transcribe.vercel.app`. No design-system work, no landing page content, no docs — a Chronicle-flavored placeholder is the production visible. The Swift package at repo root must continue to build untouched. Build artifacts (`.next/`, `node_modules/`) must never be committed.

In scope:
- Next.js 16 App Router + TypeScript project at `/website` with `src/app/` layout
- pnpm as package manager, Node 22 LTS pinned
- Tailwind CSS installed (configuration/tokens land in phase 12)
- Vercel project linked via dashboard GitHub integration, Root Directory = `website`
- Ignored Build Step so Swift-only commits don't redeploy
- `.gitignore` updates excluding `/website/.next/` and `/website/node_modules/`
- Minimal Chronicle-flavored placeholder page with Inter/Spectral/JetBrains Mono loaded
- Full site metadata suite (title, favicon, OG image, robots.txt, sitemap.xml, web manifest)

Out of scope (deferred to later phases):
- Chronicle palette tokens in Tailwind config → Phase 12
- Reusable component primitives (Button, Card, etc.) → Phase 12
- Landing page content → Phase 13
- Docs / MDX setup → Phase 14
- Changelog parsing → Phase 15
- Custom domain → post-v1.1

</domain>

<decisions>
## Implementation Decisions

### Stack
- **D-01:** Package manager is **pnpm**. Vercel-native, disk-efficient, deterministic lockfile. Requires `brew install pnpm` locally.
- **D-02:** **Next.js 16** (latest stable) — App Router, React 19, Turbopack default. Use `pnpm create next-app@latest` or `pnpx create-next-app@latest`.
- **D-03:** Node version pinned with **both** `.nvmrc` (value: `22`) and `package.json` `engines.node` (`>=22 <23`). Belt and suspenders: local auto-switch + Vercel/CI enforcement.
- **D-04:** **`src/app/` directory layout** — config files stay at `/website` root, application code under `/website/src/`.
- **D-05:** **TypeScript strict mode on** — create-next-app default, no extra flags beyond `strict: true`.
- **D-06:** **Single `@/*` path alias** mapped to `src/*`. No per-folder aliases.

### Vercel deployment
- **D-07:** **Vercel dashboard GitHub integration** — import the ps-transcribe repo from Vercel UI, set **Root Directory = `website`** in project settings. No `vercel.json` committed in this phase.
- **D-08:** **Production URL target: `ps-transcribe.vercel.app`**. Claim this exact project slug at creation. If the slug is taken, fall back to `ps-transcribe-web` (or similar) and log the real URL in PROJECT.md before phase 11 is marked done.
- **D-09:** **Ignored Build Step** set to a git-diff check against the `website/` path so Swift-only commits skip the deploy. Example Vercel Ignored Build Step command: `git diff HEAD^ HEAD --quiet -- .` (evaluated with Root Directory = `website`, so it only rebuilds when `/website/**` changed). Save Vercel build minutes during app-only release cycles.
- **D-10:** **Preview URLs auto-generated** per PR by the GitHub integration — no extra config needed.
- **D-11:** **No separate GitHub Actions job** for website in phase 11. Vercel's `pnpm build` (tsc + next build) is the only gate. If Vercel build fails, PR can't be safely merged.

### Dev tooling
- **D-12:** **Tailwind CSS installed in phase 11** via `create-next-app --tailwind`. Plumbing only — Chronicle token config and primitives land in phase 12.
- **D-13:** **Linting: ESLint only (create-next-app defaults)**. No Prettier, no Biome. Flat config that ships with Next.js 16.
- **D-14:** **`.gitignore`** at repo root extended with `website/.next/`, `website/node_modules/`, `website/.vercel/` (and `website/out/` for safety). Existing patterns (`.DS_Store`, `.env`, etc.) already cover most risks.

### Initial page content
- **D-15:** **Minimal Chronicle-flavored placeholder** at `src/app/page.tsx`. Paper background (`#FAFAF7`), Spectral wordmark "PS Transcribe" (~48px), Inter sub-copy "Private, on-device transcription for macOS.", JetBrains Mono meta label "v1.1 · WEBSITE", "Site coming soon." line. Hardcoded colors — no Tailwind config tokens yet (those arrive phase 12). ~40 lines of JSX.
- **D-16:** **All three Chronicle fonts wired via `next/font`** in phase 11 — Inter, Spectral, JetBrains Mono — in `src/app/layout.tsx`. Proves webfont loading works on Vercel and de-risks phase 12.
- **D-17:** **Full metadata suite ships in phase 11** (user chose this over minimal):
  - `<title>` = "PS Transcribe — Private, on-device transcription for macOS"
  - Favicon = reuse the app's "Bot on Laptop" icon at 32x32 / 180x180 (touch icon). Source: `assets/` directory (already in repo).
  - `og:image` = a simple 1200x630 paper-bg image with the Spectral wordmark — generated via Next.js `ImageResponse` (or a static PNG if simpler).
  - `robots.txt` = allow all (site is public marketing).
  - `sitemap.xml` = auto-generated listing `/` for now; phases 14–15 add docs/changelog routes.
  - `site.webmanifest` = app name + theme_color `#FAFAF7`.
  - OpenGraph + Twitter card meta tags in root `layout.tsx`.

### Claude's Discretion
- Exact create-next-app invocation flags (beyond `--typescript --tailwind --eslint --src-dir --app --import-alias "@/*"`).
- Specific pnpm version pin — use latest stable unless a reason emerges.
- How to structure the placeholder page file (single component vs extracted sub-components — single file is fine at this scale).
- OG image generation approach (Next.js `ImageResponse` vs static PNG export from the design handoff).
- Exact text of OG description / Twitter card description.
- Vercel project name + team selection (personal vs team account).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & scope
- `.planning/REQUIREMENTS.md` §SITE — Requirements SITE-01 through SITE-05 (this phase's scope).
- `.planning/ROADMAP.md` §"Phase 11" — Phase goal, success criteria, phase dependencies.
- `.planning/PROJECT.md` §"Current Milestone: v1.1 Marketing Website" — Milestone context, scope boundaries.

### Design context (for placeholder styling + font wiring)
- `.planning/research/CLAUDE-DESIGN-BRIEF.md` — Full Chronicle design brief. Use §Palette for the placeholder's `#FAFAF7` paper background, §Typography for the three-font stack identity.

### Existing design handoff (informational — not used until phase 12+)
- `design/ps-transcribe-web-unzipped/` — HTML/CSS mocks from Claude Design for landing, docs, changelog. Visual input to phases 13–15, NOT phase 11. Do not import these into `/website` in this phase.

### Repository assets
- `assets/` — App icons including the "Bot on Laptop" icon adopted in the v1.0 → v1.1 transition. Source for favicon + apple-touch-icon.
- `CHANGELOG.md` (repo root) — Not consumed in phase 11, but phase 15 will parse it at build time. Don't move it.
- `README.md` (repo root) — Contains MIT license note referenced by later footer work.

### Next.js 16 docs (for implementation)
- Agents should use the `mcp__plugin_context7_context7__*` tools to fetch current Next.js 16 docs on: `create-next-app` flags, `src/app/` layout, `next/font` (for Inter/Spectral/JetBrains Mono), `metadata` API (for title + OG), `MetadataRoute.Sitemap`, `MetadataRoute.Robots`, `ImageResponse` (for OG image).
- Vercel docs on Root Directory + Ignored Build Step for monorepos.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **App icon (Bot on Laptop):** Present in `assets/` — reuse as favicon source at 32x32 and 180x180. Don't redesign.
- **`.gitignore` at repo root:** Already has patterns for `.DS_Store`, `.env`, `dist/`, Swift build outputs. Extend with website entries, don't replace.
- **No existing web code:** Confirmed — `ls /website` = nothing. Swift project entirely at `PSTranscribe/`. Zero risk of collision.

### Established Patterns
- Repo is Swift-first. `PSTranscribe/` holds all Swift Package code; `scripts/` has release automation; `dist/` is (git-ignored) release output.
- v1.0 shipped with `.github/` workflows — the `release-dmg.yml` is Swift-only and won't interact with `/website`.
- Root of repo has `LICENSE` (MIT), `README.md`, `CHANGELOG.md` — these are shared assets the website will reference in later phases but never duplicate.

### Integration Points
- **`/website/` subdirectory** is the sole new top-level directory. It is isolated from `PSTranscribe/`, `scripts/`, `assets/`.
- **`.gitignore`** (repo root) is the one shared file that must be extended.
- **Vercel project** is an external integration — configured in the Vercel dashboard, not the repo. The only repo-side artifact is the Ignored Build Step command (lives in Vercel UI).
- **GitHub repo** must be connected to Vercel via the GitHub App integration. One-time user action in Vercel UI.

</code_context>

<specifics>
## Specific Ideas

- **Placeholder tone** matches the Chronicle brief — "calm, precise, editorial." Avoid "Coming soon 🚀" or marketing cliche. Aim for Linear's in-progress page quality.
- **Meta label style:** `v1.1 · WEBSITE` in JetBrains Mono, uppercase, `inkFaint` color from the brief palette. Small touch that signals this is intentional, not abandoned.
- **Font loading:** All three fonts land via `next/font/google` (Inter, Spectral, JetBrains Mono are all on Google Fonts per the brief's constraints). No bundled font files — respect the "open-source, available on Google Fonts" constraint from the brief.
- **"Bot on Laptop" icon** was adopted in commit `cb9aa2e` as the v1.1 app icon. Reuse it as favicon so web + app identity match from day one.

</specifics>

<deferred>
## Deferred Ideas

- **Chronicle Tailwind tokens** — configuring `theme.extend.colors` with the full palette is Phase 12 work.
- **Reusable component primitives** (Button, Card, MetaLabel, SectionHeading, CodeBlock) — Phase 12.
- **Actual landing page content** (hero, feature blocks, download CTA) — Phase 13.
- **MDX pipeline + docs sidebar** — Phase 14.
- **CHANGELOG.md parser + release cards** — Phase 15.
- **Custom domain** — post-v1.1 (explicitly deferred in milestone scope).
- **Vercel Analytics enabling decision** — explicitly deferred per milestone scope.
- **Website-specific GitHub Actions workflow** — not needed in phase 11; reconsider if PR quality slips.

</deferred>

---

*Phase: 11-website-scaffolding-vercel-deployment*
*Context gathered: 2026-04-22*
