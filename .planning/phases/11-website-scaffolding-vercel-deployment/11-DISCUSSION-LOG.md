# Phase 11: Website Scaffolding & Vercel Deployment - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `11-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-22
**Phase:** 11-website-scaffolding-vercel-deployment
**Areas discussed:** Stack specifics, Vercel monorepo setup, Dev tooling scope, Initial page content

---

## Stack Specifics

### Package manager

| Option | Description | Selected |
|--------|-------------|----------|
| pnpm (Recommended) | Fast, disk-efficient, Vercel-native. Deterministic lockfile. | ✓ |
| npm | Zero-setup, comes with Node. Slower installs, bigger node_modules. | |
| bun | Fastest installs, bundler built-in. Newer — occasional edge cases with Next.js plugins. | |

**User's choice:** pnpm

### Next.js major version

| Option | Description | Selected |
|--------|-------------|----------|
| Next.js 16 (Recommended) | Latest stable. Cache Components GA, React 19, Turbopack default. | ✓ |
| Next.js 15 | Previous major. Stable and documented. | |

**User's choice:** Next.js 16

### Node version pinning

| Option | Description | Selected |
|--------|-------------|----------|
| Both .nvmrc and package.json engines (Recommended) | Pin Node 22 LTS in both. | ✓ |
| .nvmrc only | Local convenience, but nothing prevents Vercel/CI mismatch. | |
| Neither | Rely on default. Fragile. | |

**User's choice:** Both .nvmrc and package.json engines

### Directory layout

| Option | Description | Selected |
|--------|-------------|----------|
| src/app (Recommended) | Everything Next.js under src/ — cleaner separation. | ✓ |
| app at root | Next.js default — shorter imports but clutters /website root. | |

**User's choice:** src/app

---

## Vercel Monorepo Setup

### Vercel link strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Vercel dashboard GitHub integration (Recommended) | Import repo, set Root Directory to 'website' in project settings. | ✓ |
| vercel CLI (vercel link + vercel.json) | Commit vercel.json at /website with build config. More explicit. | |
| Both — dashboard for deploys, vercel.json for build config | Belt-and-suspenders. | |

**User's choice:** Vercel dashboard GitHub integration

### Ignored build step for Swift-only commits

| Option | Description | Selected |
|--------|-------------|----------|
| Git diff check on /website path (Recommended) | Only rebuilds when /website (or cited files) changed. Saves build minutes. | ✓ |
| Always build | Every push rebuilds. Simpler, wastes build minutes. | |
| Use Vercel's auto-detection | Built-in monorepo detection. Minimal config. | |

**User's choice:** Git diff check on /website path

### Production URL plan

| Option | Description | Selected |
|--------|-------------|----------|
| ps-transcribe.vercel.app (Recommended) | Claim the exact slug; fallback if taken, log real URL. | ✓ |
| Let Vercel pick a slug | Auto-assigned slug. Zero collision risk. | |

**User's choice:** ps-transcribe.vercel.app

### CI gates

| Option | Description | Selected |
|--------|-------------|----------|
| Vercel's build is the gate (Recommended) | Vercel runs pnpm build on every push. No separate GH Actions job. | ✓ |
| Add a website-specific GitHub Actions job | Duplicates Vercel's checks but belt-and-suspenders. | |

**User's choice:** Vercel's build is the gate

---

## Dev Tooling Scope

### Tailwind CSS timing

| Option | Description | Selected |
|--------|-------------|----------|
| Install in phase 11 (Recommended) | create-next-app --tailwind flag. Phase 12 configures tokens. | ✓ |
| Defer to phase 12 | Plain CSS in phase 11, Tailwind at design port. | |

**User's choice:** Install in phase 11

### Linting / formatting

| Option | Description | Selected |
|--------|-------------|----------|
| create-next-app defaults (ESLint only) (Recommended) | next@16 ships ESLint flat config out of the box. | ✓ |
| ESLint + Prettier | Industry standard but doubles config files. | |
| Biome (replace ESLint) | Faster, single-binary — but not wired by create-next-app. | |

**User's choice:** create-next-app defaults (ESLint only)

### TypeScript strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Strict mode on (Recommended) | create-next-app default. strict: true. | ✓ |
| Default (strict on, no extras) | Exactly what create-next-app gives you. | |

**User's choice:** Strict mode on (same as default)

### Path alias style

| Option | Description | Selected |
|--------|-------------|----------|
| Single @/* root alias (Recommended) | '@/*' → 'src/*'. Predictable, simple. | ✓ |
| Multiple aliases (@components, @lib, @ui) | Granular but more config. | |

**User's choice:** Single @/* root alias

---

## Initial Page Content

### Placeholder content

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal Chronicle-flavored placeholder (Recommended) | Paper bg, Spectral wordmark, Inter sub-copy, mono meta label. ~40 lines JSX. | ✓ |
| Truly blank page | Empty body or 'Hello'. Meets spec but looks broken. | |
| Keep create-next-app's default homepage | Default Next.js landing. Off-brand. | |

**User's choice:** Minimal Chronicle-flavored placeholder

### Font loading timing

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — wire Inter + Spectral + JetBrains Mono now (Recommended) | next/font in layout.tsx. Proves webfont loading on Vercel. | ✓ |
| Defer to phase 12 | System fonts only in phase 11. | |

**User's choice:** Wire all three Chronicle fonts now

### Metadata scope

| Option | Description | Selected |
|--------|-------------|----------|
| Title + favicon only (Recommended) | <title> + 32x32/180x180 favicon from app icon. | |
| Full metadata suite now | OG image, robots.txt, sitemap.xml, web manifest. | ✓ |
| Default Next.js metadata | 'Create Next App' title. | |

**User's choice:** Full metadata suite now (deviated from recommendation — user wants complete metadata in phase 11)

---

## Claude's Discretion

- Exact create-next-app invocation flags beyond the specified set.
- Specific pnpm version pin (latest stable unless a reason emerges).
- Placeholder page structure (single file vs extracted — single file fine at this scale).
- OG image generation approach (Next.js ImageResponse vs static PNG).
- Exact OG/Twitter description text.
- Vercel project name + team selection.

## Deferred Ideas

- Chronicle Tailwind tokens (Phase 12).
- Reusable component primitives (Phase 12).
- Landing page content (Phase 13).
- MDX docs pipeline (Phase 14).
- CHANGELOG parsing (Phase 15).
- Custom domain (post-v1.1).
- Vercel Analytics decision (out of scope for v1.1).
- Website-specific GitHub Actions (revisit if PR quality slips).
