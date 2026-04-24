---
phase: 14-docs-section
plan: 04
subsystem: website-docs
tags: [mdx, docs, editorial-copy, chronicle-voice, notion, obsidian, faq, troubleshooting]
one_liner: "Fresh-copy docs: Configuring your vault, Notion property mapping, FAQ (10 Q&A), Troubleshooting (6 issues). All four pages compile, land in sidebar codegen automatically, and pass the banned-vocabulary grep."
requires:
  - website/src/components/docs/Note.tsx                   # Plan 01
  - website/src/components/docs/Lede.tsx                   # Plan 01
  - website/src/components/docs/Crumbs.tsx                 # Plan 01
  - website/src/components/docs/PrevNext.tsx               # Plan 02 (auto-derive signature)
  - website/src/components/docs/Kbd.tsx                    # Plan 01
  - website/src/components/docs/TableOfContents.tsx        # Plan 02
  - website/src/mdx-components.tsx                         # Plan 01/02
  - website/scripts/build-sidebar-data.mjs                 # Plan 02 (codegen)
provides:
  - "src/app/docs/configuring-your-vault/page.mdx — Start here group, order 2"
  - "src/app/docs/notion-property-mapping/page.mdx — Reference group, order 2"
  - "src/app/docs/faq/page.mdx — Help group, order 1"
  - "src/app/docs/troubleshooting/page.mdx — Help group, order 2 (last in DOC_ORDER)"
affects:
  - website/src/components/docs/sidebar-data.generated.ts   # regen'd from 0 entries -> 4 entries shipped by this plan
  - website/next.config.ts                                  # turbopack.root + absolute plugin path (Rule 3 unblock)
  - website/src/lib/rehype-toc-export.mjs                   # ported from .ts (same reason)
tech_stack:
  added:
    - "(none — pure editorial copy + build-pipeline unblock)"
  patterns:
    - "Editorial-voice anchors: every page cites a specific verifiable mechanism (FluidAudio, Little Snitch, macOS keychain, System Settings path, Sparkle feed URL) instead of making unqualified claims"
    - "FAQ Q&A as H2 structure — right-hand TOC becomes a question index at zero extra cost"
    - "Absolute plugin path in next.config.ts so Turbopack's `require.resolve(pluginPath, { paths: [this.context] })` can find a local rehype plugin regardless of which MDX file is being compiled"
key_files:
  created:
    - website/src/app/docs/configuring-your-vault/page.mdx
    - website/src/app/docs/notion-property-mapping/page.mdx
    - website/src/app/docs/faq/page.mdx
    - website/src/app/docs/troubleshooting/page.mdx
    - website/src/lib/rehype-toc-export.mjs
  modified:
    - website/next.config.ts
    - website/src/components/docs/sidebar-data.generated.ts
  removed:
    - website/src/lib/rehype-toc-export.ts
decisions:
  - "Absolute plugin path + .mjs rewrite for rehype-toc-export: @next/mdx's mdx-js-loader imports plugins via native Node `import()` from the .mdx file's directory at build time, so a relative path like `./src/lib/rehype-toc-export` cannot resolve and `.ts` cannot load. Absolute path + JSDoc-typed .mjs fixes both without introducing a TS build step."
  - "turbopack.root pinned to the website directory: Next 16 auto-detects workspace root by walking up looking for lockfiles and was selecting `/Users/cary/bun.lockb` in the user's home, which broke module resolution. Pinning explicitly silences the warning and makes the build reproducible."
  - "FAQ structured as 10 H2 questions (not an FAQ-component): keeps rehype-slug + rehypeTocExport behavior identical across pages, and the right-hand TOC auto-populates with each question as an anchor."
  - "Troubleshooting's Notion-sync section uses an ordered list of likely causes rather than nested subsections: 3 short diagnostic branches read better as a list than as 3 extra H3s."
metrics:
  completed_date: "2026-04-24"
  duration_approx: "~8 minutes from Task 1 start to Task 4 commit (including the MDX-pipeline unblock on Task 1)"
  tasks_completed: 4
  files_created: 5
  files_modified: 2
  files_removed: 1
requirements_completed:
  - DOCS-03
---

# Phase 14 Plan 04: Fresh-copy Docs Pages Summary

Shipped the four fresh-copy doc pages completing DOCS-03: `Configuring your vault`, `Notion property mapping`, `FAQ`, and `Troubleshooting`. All four were drafted per D-09 (Claude writes fresh, UAT reviews) from PROJECT.md + README + v1.0 app behavior, in the Chronicle voice, with each factual claim anchored to a specific verifiable mechanism. The pages land in `sidebar-data.generated.ts` automatically via Plan 02's codegen; no sidebar file was edited.

Plan 03 (parallel worktree) ships Getting started and Keyboard shortcuts; this plan owns the other four. Together Wave 3 closes out the docs content layer for DOCS-01/02/03/04/05.

## What Landed

### Task 1 — `/docs/configuring-your-vault` (commit `b039d5c`)

- **Group:** Start here, order 2. Follows Plan 03's Getting started (order 1) in `DOC_ORDER`; `<PrevNext currentSlug="configuring-your-vault" />` auto-derives prev=getting-started, next=keyboard-shortcuts once Plan 03 lands.
- **Structure:** 4 H2 sections — *Set the vault path*, *Understand the path tokens*, *What gets written to frontmatter*, *Meetings and memos take different paths*. One `<Note label="On-device">` after the path-tokens section clarifying that vault location does not affect processing.
- **Factual anchors:** template tokens `{{year}} / {{month}} / {{date}} / {{title}}`; frontmatter fields `date / duration / participants / tags`; `<Kbd>⌘</Kbd> <Kbd>E</Kbd>` speaker rename; Obsidian-vault-optional framing ("any folder; the files are plain markdown").
- **Word count:** 492 (target 350–500; minor overage on richer example payload, still inside plan's 350–600 overall band).

This task's commit also folds in the MDX-pipeline unblock documented under **Deviations** below.

### Task 2 — `/docs/notion-property-mapping` (commit `2f20dd6`)

- **Group:** Reference, order 2. Follows Plan 03's Keyboard shortcuts (Reference order 1). `<PrevNext currentSlug="notion-property-mapping" />` will auto-derive prev=keyboard-shortcuts, next=faq after the sidebar-codegen regenerates with Plan 03's pages in place.
- **Structure:** 4 H2 sections — *Connect the integration*, *Pick a destination database*, *Map frontmatter to Notion properties*, *Fields Notion ignores*. One `<Note label="No token, no traffic">` inside the Connect section as a privacy anchor.
- **GFM table:** 4-row frontmatter → Notion property-type table (`date`/Date, `duration`/Number, `participants`/Multi-select, `tags`/Multi-select). remark-gfm handles the parse; React escapes cell contents.
- **Factual anchors:** integration URL (`https://www.notion.so/my-integrations`), macOS keychain token storage, Connections → Add connections flow, silent-skip behavior on property type mismatch, "PS Transcribe does not modify your database schema".
- **Word count:** 517.

### Task 3 — `/docs/faq` (commit `d8a3787`)

- **Group:** Help, order 1. `<PrevNext currentSlug="faq" />` auto-derives prev=notion-property-mapping, next=troubleshooting.
- **Structure:** 10 H2 questions (plan band 8–12). Each question becomes a TOC entry so the right-hand TOC functions as a question index — zero additional component work needed.
- **Questions (exact order shipped):**
  1. Does PS Transcribe send audio to any cloud service?
  2. Which macOS versions are supported?
  3. Do I need Apple Silicon?
  4. Does it work on Intel Macs?
  5. Can I use it without an Obsidian vault?
  6. Is there a mobile version?
  7. What's the file format for saved transcripts?
  8. Can I edit transcripts after recording?
  9. How accurate is speaker diarization?
  10. How do updates work?
- **Factual anchors:** FluidAudio (on-device processing), Little Snitch + Network-tab verification recipe, Sparkle release-feed URL implicit via XML feed reference, macOS 26 requirement stated twice (supported versions + Intel answer), Rosetta not supported, 2–3 speaker diarization quality caveat.
- **Word count:** 493.

### Task 4 — `/docs/troubleshooting` (commit `23730c6`)

- **Group:** Help, order 2. **Last page in `DOC_ORDER`** — `<PrevNext currentSlug="troubleshooting" />` renders only the prev card (FAQ). Plan 02's PrevNext.tsx returns `null` when no neighbor is found on one side, so the next-card slot collapses gracefully (actually renders an empty `<span />` placeholder for the grid, which is the correct layout behavior).
- **Structure:** 6 H2 symptoms (plan band 5–8), each with a prose fix below:
  1. The app can't hear the other side of the call (ScreenCaptureKit permission)
  2. Speaker names are wrong (⌘E rename, diarizer limits)
  3. Models didn't download on first launch (Preferences → Models → Redownload)
  4. Notion sync failed (3-step diagnostic ordered list)
  5. Transcript is slow to appear after I stopped (end-of-session passes)
  6. Sparkle didn't show the update banner (launch-time poll, feed URL)
- Note block on disk-space inside the Models section (`<Note label="Disk space">`).
- **Factual anchors:** *System Settings → Privacy & Security → Screen & System Audio Recording* (exact OS settings path), Parakeet-TDT + diarization models ~400 MB download / 800 MB unpacked / 1.5 GB free recommended, Notion *Connections → Add connections* flow, appcast feed URL `https://github.com/cnewfeldt/ps-transcribe/releases.atom`, `<Kbd>⌘</Kbd> <Kbd>.</Kbd>` stop-recording shortcut.
- **Word count:** 561 (target 350–550; 11-word overage on the Notion-sync ordered list which reads cleaner than chopping a step).

## Verification

- `cd website && pnpm build` exits 0 after every task. Final build emits routes for all six docs slugs: `/docs`, `/docs/configuring-your-vault`, `/docs/faq`, `/docs/notion-property-mapping`, `/docs/troubleshooting` (plus Plan 03's getting-started and keyboard-shortcuts once its commits land).
- `grep -ciE 'seamless|empower|revolutioniz|cutting-edge|harness|unlock|leverage|game-chang' <page>` returns **0** for all 4 pages.
- `grep -c 'macOS 14' <page>` returns **0** for all 4 pages. Every version reference is `macOS 26`.
- `grep -c 'href="#"' <page>` returns **0** for all 4 pages — no placeholder links slipped in.
- `sidebar-data.generated.ts` now contains 4 entries after Plan 04's Task 4 build (will be 6 once Plan 03's commits merge). Entries:
  - `{"slug":"configuring-your-vault","group":"Start here","order":2}`
  - `{"slug":"notion-property-mapping","group":"Reference","order":2}`
  - `{"slug":"faq","group":"Help","order":1}`
  - `{"slug":"troubleshooting","group":"Help","order":2}`
- Acceptance-criteria SC-1 wiring probe passed per task: `grep '<slug>' sidebar-data.generated.ts` returned a match after each build.

Runtime-only checks (active-state highlight, TOC scroll-spy populating, PrevNext's `null` forward-link render on Troubleshooting) are deferred to UAT per the plan's explicit UAT scope.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking] Local rehype plugin path unresolvable at MDX build time**
- **Found during:** Task 1's first `pnpm build` (immediately after writing `configuring-your-vault/page.mdx`).
- **Issue:** Plan 01 shipped `next.config.ts` with `'./src/lib/rehype-toc-export'` as a string plugin path, and `rehype-toc-export.ts` as a TypeScript source. Plan 01 and Plan 02 both reported "build passes" because neither built an actual `.mdx` page through the plugin. When Task 1's `.mdx` was the first file to compile through the plugin stack, two bugs surfaced in sequence:
  - `@next/mdx/mdx-js-loader.js` calls `require.resolve(pluginPath, { paths: [this.context] })` where `this.context` is the directory of the `.mdx` file being compiled, not the project root. A relative path like `./src/lib/rehype-toc-export` therefore cannot resolve.
  - Even once the path was made absolute, Node's native `await import(path)` cannot load `.ts` files without a loader, producing `Unknown file extension ".ts"`.
  - A third pre-existing issue surfaced at the same time: Turbopack's workspace-root auto-detection selected `/Users/cary/bun.lockb` over the website's `pnpm-lock.yaml`, emitting a warning and (more importantly) anchoring module resolution at the wrong directory.
- **Fix:**
  - Rewrote `src/lib/rehype-toc-export.ts` as `src/lib/rehype-toc-export.mjs`. Types preserved via JSDoc (`@typedef TocItem`, `@returns (tree) => void`). Runs natively in Node at MDX build time.
  - `next.config.ts`: pinned `turbopack.root` to the website directory via `dirname(fileURLToPath(import.meta.url))`.
  - `next.config.ts`: computed an absolute `REHYPE_TOC_EXPORT_PATH` using `path.join(HERE, 'src', 'lib', 'rehype-toc-export.mjs')` and replaced the relative string with this constant in the `rehypePlugins` array.
  - Deleted `src/lib/rehype-toc-export.ts` (nothing else imported it; `next.config.ts` was the sole consumer).
- **Files modified:** `website/next.config.ts`, `website/src/lib/rehype-toc-export.ts` (deleted), `website/src/lib/rehype-toc-export.mjs` (new).
- **Commit:** folded into `b039d5c` alongside Task 1's page.mdx, per the plan's Rule 3 deviation protocol (blocking fix surfaced during the task that exposed it).

No Rule 4 (architectural) deviations. No user-facing copy required adjustment from the plan's EXACT-contents blocks. No banned vocabulary slipped in on any draft. No factual claim required softening to pass the no-telemetry / no-cloud threat-register check (T-14-17) — every privacy claim is anchored to a verifiable mechanism.

### Voice Guide — Where It Felt Restrictive

Per the plan's `<output>` instruction to flag any restrictions:
- **Zero friction on banned vocabulary.** None of the drafts needed a word substitution at review — the Chronicle voice (concrete, anchored, mechanism-citing) naturally excludes the banned list.
- **Em-dash rule worked cleanly.** Used `--` (double hyphen) throughout, except inside the one direct quotation in Plan 03's landing-page touchstone ("Auto-updates are handled by Sparkle -- future releases appear as a quiet banner in the app, nothing forced.") which the plan already wrote with `--`. No em-dashes slipped in.
- **Target word-count bands were appropriate** (configuring-your-vault came in 492, nearest to the upper bound; troubleshooting came in 561, 11 over). No evidence of padding to hit counts or cutting content to stay under.

Nothing flagged for retrospective.

## Authentication Gates

None. Pure editorial content work. No credentials, tokens, external services touched at build time. The Notion integration is described in prose only; the only URLs written into MDX (`https://www.notion.so/my-integrations`, `https://github.com/cnewfeldt/ps-transcribe/releases.atom`) are static documentation links.

## Known Stubs

None. Every page renders complete content. No placeholder text, no TODO comments, no empty-component wiring. `DOC_ORDER` is populated end-to-end once Plan 03's commits also land (Plan 04's 4 entries + Plan 03's 2 entries = 6 pages in the sidebar).

## Threat Flags

None introduced beyond the plan's `<threat_model>` coverage.
- T-14-17 (false privacy claims): every privacy-related statement on FAQ + Troubleshooting anchors to a named mechanism (FluidAudio, Little Snitch, Network tab, macOS keychain, Sparkle feed URL) — all verifiable against the codebase and runtime.
- T-14-18 (reverse tabnabbing): `rehype-external-links` (Plan 01) adds `rel='noopener noreferrer' target='_blank'` at compile time to every external link.
- T-14-19 (marketing-voice leakage): banned-vocabulary grep returned 0 on all 4 pages.
- T-14-20 (stale platform claims): `macOS 14` grep returned 0; every version reference is macOS 26.
- T-14-21 (GFM table XSS): notion-property-mapping's table uses only literal strings and inline code; no `dangerouslySetInnerHTML`.
- T-14-22 (sidebar drift): structurally prevented — Plan 02's codegen IS the sidebar. Each page's `doc` export is the single source of truth and lands in `sidebar-data.generated.ts` automatically.

## MDX Parse Issues

Per the plan's `<output>` question ("Did any MDX parse issues require escaping of `&`, `{`, `}` inside prose?"):

- **Troubleshooting** used `&` in the prose phrase *"Screen & System Audio Recording"* and *"Privacy & Security"*. MDX compiled these without escaping — remark-gfm + MDX's prose parser tolerate literal `&` outside tag context.
- **Configuring-your-vault** used template-token placeholders `{{year}}` / `{{month}}` / `{{date}}` / `{{title}}` inside fenced code blocks (```text and ```yaml). Code fences isolate contents from MDX parsing; no escaping needed.
- **No `{` or `}` appeared outside of fenced code.** The `export const doc = { ... }` literals sit at the top of each file where MDX correctly recognizes them as mdxjsEsm nodes.
- **Notion property mapping** used backticks inside GFM table cells (e.g. `` `date` ``, `` `Multi-select` ``). remark-gfm's cell parser handles these cleanly.

No escaping workarounds required in any of the four pages.

## Self-Check: PASSED

**Created files exist:**
- FOUND: website/src/app/docs/configuring-your-vault/page.mdx
- FOUND: website/src/app/docs/notion-property-mapping/page.mdx
- FOUND: website/src/app/docs/faq/page.mdx
- FOUND: website/src/app/docs/troubleshooting/page.mdx
- FOUND: website/src/lib/rehype-toc-export.mjs

**Sidebar-generated entries:**
- FOUND: `"slug": "configuring-your-vault"` in sidebar-data.generated.ts
- FOUND: `"slug": "notion-property-mapping"` in sidebar-data.generated.ts
- FOUND: `"slug": "faq"` in sidebar-data.generated.ts
- FOUND: `"slug": "troubleshooting"` in sidebar-data.generated.ts

**Commits exist:**
- FOUND: b039d5c — feat(14-04): ship /docs/configuring-your-vault + fix MDX plugin resolution
- FOUND: 2f20dd6 — feat(14-04): ship /docs/notion-property-mapping
- FOUND: d8a3787 — feat(14-04): ship /docs/faq
- FOUND: 23730c6 — feat(14-04): ship /docs/troubleshooting

**Build status:**
- `cd website && pnpm build` exits 0 on every task-verification run. Final Route (app) manifest includes all 4 Plan-04 routes alongside Plan 02's /docs redirect.

**Voice and factual greps:**
- banned-vocabulary grep returns 0 on all 4 pages
- `macOS 14` grep returns 0 on all 4 pages
- `href="#"` grep returns 0 on all 4 pages
