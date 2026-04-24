---
phase: 14-docs-section
plan: 03
subsystem: website-docs
tags: [mdx, docs-content, getting-started, keyboard-shortcuts, chronicle-voice]
one_liner: "Shipped two mock-verbatim docs pages — Getting Started and Keyboard Shortcuts — with D-10 fixes (macOS 26, zero dead links) and fixed the Plan 01 rehype plugin loader so MDX actually compiles."
requires:
  - website/src/mdx-components.tsx                     # Plan 01 — MDX component namespace (Note, Lede, Crumbs, etc.)
  - website/src/components/docs/Kbd.tsx                # Plan 01 — tone-aware key chips
  - website/src/components/docs/ShortcutTable.tsx      # Plan 01 — wraps rows
  - website/src/components/docs/ShortcutRow.tsx        # Plan 01 — individual keystroke row
  - website/src/components/docs/Note.tsx               # Plan 01 — default + sage variants
  - website/src/components/docs/Lede.tsx               # Plan 01 — sub-H1 measure
  - website/src/components/docs/Crumbs.tsx             # Plan 01 — breadcrumb trail
  - website/src/components/docs/PrevNext.tsx           # Plan 02 — currentSlug auto-derivation
  - website/src/components/docs/TableOfContents.tsx    # Plan 02 — scroll-spy TOC
  - website/src/components/docs/sidebar-data.ts        # Plan 02 — consumer module
  - website/scripts/build-sidebar-data.mjs             # Plan 02 — prebuild codegen
  - website/src/app/docs/layout.tsx                    # Plan 02 — three-column grid
  - design/ps-transcribe-web-unzipped/docs.html        # Mock source (lines 247-402)
  - PSTranscribe/Package.swift                         # Source of truth for macOS minimum (.macOS(.v26))
provides:
  - "src/app/docs/getting-started/page.mdx — Getting Started doc page (DOCS-03), 6 H2 sections"
  - "src/app/docs/keyboard-shortcuts/page.mdx — Keyboard Shortcuts doc page, 3 H2 sections with 12 ShortcutRow entries"
  - "sidebar-data.generated.ts now has two entries (via Plan 02's prebuild codegen)"
affects:
  - website/next.config.ts                             # rehype plugin path fix (relative -> absolute)
  - website/src/lib/rehype-toc-export.mjs              # NEW — replaces .ts original
  - website/src/components/docs/sidebar-data.generated.ts  # auto-generated output, committed
tech_stack:
  added:
    - "(none — reused Plan 01 / Plan 02 infrastructure)"
  patterns:
    - "MDX page shape: no YAML frontmatter; ESM exports for metadata/doc/implicit-tableOfContents; <article> wrapper pins to grid column 2, <TableOfContents items={tableOfContents} /> pins to column 3"
    - "PrevNext currentSlug auto-derivation resolves forward/back links at render time from DOC_ORDER, so dead-link fixes for not-yet-shipped neighbors (mock's 'Frontmatter schema') are structurally safe"
    - "doc-export-as-sidebar-source: dropping a new page.mdx under src/app/docs/{slug}/ ships a live doc page + sidebar row + PrevNext + sitemap entry on next pnpm dev/build (SC-1 verified)"
key_files:
  created:
    - website/src/app/docs/getting-started/page.mdx
    - website/src/app/docs/keyboard-shortcuts/page.mdx
    - website/src/lib/rehype-toc-export.mjs
  modified:
    - website/next.config.ts
    - website/src/components/docs/sidebar-data.generated.ts
  removed:
    - website/src/lib/rehype-toc-export.ts               # replaced by .mjs
decisions:
  - "Converted Plan 01's custom rehype plugin from TypeScript to plain ESM (.mjs). Rationale: @next/mdx's mdx-js-loader resolves plugin strings via plain Node import() at build time — no TS transpilation layer — so a .ts source file is unloadable regardless of path. The .mjs rewrite drops the type annotations and keeps the behavior identical."
  - "Referenced the rehype plugin from next.config.ts via an absolute path computed from process.cwd() (not import.meta.url). Rationale: Next 16 compiles next.config.ts to CJS before executing it, so import.meta is undefined. process.cwd() is always the website/ root when pnpm build/dev runs, and an absolute path is Turbopack-serializable (plain string) while sidestepping @next/mdx's require.resolve({ paths }) quirk that would otherwise mis-resolve './'-relative strings."
  - "Replaced the mock's 'Apple Silicon recommended; Intel builds run noticeably slower during diarization' phrasing with 'Apple Silicon required' instead of porting verbatim. Rationale: .macOS(.v26) is the real Package.swift minimum, and macOS 26 does not support Intel, so the Intel-slowness qualifier is stale/misleading. Fact-correctness wins over mock-fidelity per D-10."
  - "Replaced the mock's 'Frontmatter schema' cross-reference sentence entirely rather than leaving it as a placeholder. The mock's 'see the Frontmatter schema reference' phrasing only works if that page exists; Phase 14 doesn't ship it. Rewrote to inline the four key fields (date, duration, participants, tags) so the sentence stands on its own without a forward reference."
metrics:
  completed_date: "2026-04-24"
  duration_approx: "~12 minutes from Task 1 start to final commit (includes ~6 minutes debugging the rehype-toc-export loader resolution that Plan 01 left as latent debt)"
  tasks_completed: 2
  files_created: 3
  files_modified: 2
  files_removed: 1
  word_counts:
    getting_started: 451
    keyboard_shortcuts: 385
requirements_completed:
  - DOCS-03
  - DOCS-05
---

# Phase 14 Plan 03: Getting Started + Keyboard Shortcuts Summary

Shipped the first two docs pages with mock-verbatim copy, applied D-10 mechanical fixes (macOS 26, zero dead links), and repaired a latent rehype-plugin loader bug from Plan 01 that blocked every MDX compile. After this plan, `/docs/getting-started` and `/docs/keyboard-shortcuts` both render, Plan 02's prebuild codegen has picked up both pages' `doc` exports, and the sidebar + PrevNext + sitemap are all wired automatically.

## What Landed

### Task 1 — /docs/getting-started (commit `4e76adf`)

- `website/src/app/docs/getting-started/page.mdx` — 451 words total.
- Crumbs → `# Getting started` → Lede (mock-verbatim: "Install, grant two permissions, point PS Transcribe at an Obsidian folder, and start recording. Five minutes.") → 5 H2 sections (Install, Grant permissions, Point at an Obsidian vault, Record something, Send to Notion).
- D-10 fix 1 (macOS version): `<Note label="Requirements">macOS 26 or later. Apple Silicon required.</Note>` — replaces the mock's "macOS 14 (Sonoma) or later. Apple Silicon recommended; Intel builds run noticeably slower during diarization." Per Package.swift the real minimum is `.macOS(.v26)`, and Intel is not a supported macOS 26 target so the Intel-slowness qualifier was dropped.
- D-10 fix 2 (dead links): Mock's `<a href="#">GitHub Releases</a>` → `[GitHub Releases](https://github.com/cnewfeldt/ps-transcribe/releases/latest)`. Mock's `<a href="#">Frontmatter schema</a>` cross-reference → rewritten sentence that inlines the four key frontmatter fields (date/duration/participants/tags) rather than pointing at a page that won't ship in Phase 14.
- YAML fenced block for the vault config renders verbatim from the mock (`Vault path: ~/Documents/Obsidian/Work ...`), picks up the `data-lang` attribute treatment from Plan 01's `pre` override, and displays the YAML badge via Plan 01's docs.css.
- Sage Note (`<Note variant="sage" label='What "on-device" actually means'>`) ports the mock's Parakeet-TDT / Silero VAD / Little Snitch verification call-out verbatim.
- `export const doc = { group: 'Start here', order: 1, navTitle: 'Getting started' }` — picked up by Plan 02's prebuild codegen on first `pnpm build` after this commit; `sidebar-data.generated.ts` gained the expected row.

### Task 2 — /docs/keyboard-shortcuts (commit `dfc1977`)

- `website/src/app/docs/keyboard-shortcuts/page.mdx` — 385 words total, 12 shortcut rows.
- Three `<ShortcutTable>` sections: Recording (5 rows), Transcript (4 rows), Layout (3 rows). Lede mock-verbatim ("PS Transcribe is built for the keyboard. Four shortcuts cover 90% of the app; the rest are for speaker management and navigation.").
- Tone assignments match the mock: `⌘R` → navy (both chips), `⌘⇧R` → sage (all three chips), every other row uses `tone: 'default'` via the Kbd component's default.
- Final `<Note label="Customize">` callout preserves the mock's rebinding note including the `~/Library/Application Support/PS Transcribe/shortcuts.json` path reference.
- `<PrevNext currentSlug="keyboard-shortcuts" />` — auto-derives from DOC_ORDER. Right now DOC_ORDER only has `getting-started` (Start here) and `keyboard-shortcuts` (Reference), so the forward link returns null (PrevNext renders the previous card only). Once Plan 04 ships notion-property-mapping (Reference, order 2), the next link will populate automatically on the next build — no edits to this file.
- D-10 fix: Mock's "Next → Frontmatter schema" (href="#") dead link is replaced by the currentSlug auto-derivation. The Frontmatter schema page isn't in Phase 14 scope, so there's no real target to link to; letting DOC_ORDER drive the pairing is the correct long-term pattern.

## Verification

### Acceptance-criteria greps (both pages)

**Task 1 greps:**
- `export const metadata = {` → line 3 ✓
- `export const doc = {` → line 8 ✓
- `group: 'Start here'` → line 9 ✓
- `# Getting started` → line 18 ✓
- `macOS 26` → line 31 ✓
- `macOS 14` → 0 occurrences ✓
- `href="#"` → 0 occurrences ✓
- `Install, grant two permissions` → line 20 (inside Lede) ✓
- `Vault path:` → line 48 ✓
- YAML fence `^```yaml` → line 47 ✓
- `variant="sage"` → line 62 ✓
- `Parakeet-TDT` → line 63 ✓
- `<PrevNext currentSlug="getting-started"` → line 74 ✓
- `<TableOfContents items={tableOfContents}` → line 78 ✓

**Task 2 greps:**
- `export const metadata` → line 3 ✓
- `group: 'Reference'` → line 9 ✓
- `navTitle: 'Keyboard shortcuts'` → line 11 ✓
- `# Keyboard shortcuts` → line 18 ✓
- `<ShortcutTable>` opening tags → 3 ✓
- `<ShortcutRow` opening tags → 12 ✓
- `Four shortcuts cover 90% of the app` → line 5, 20 ✓
- `tone: 'navy'` → line 28 ✓
- `tone: 'sage'` → line 33 ✓
- `<Note label="Customize"` → line 99 ✓
- `shortcuts.json` → line 100 ✓
- `<PrevNext currentSlug="keyboard-shortcuts"` → line 103 ✓
- `href="#"` → 0 occurrences ✓

### Integration verification

- `cd website && pnpm build` exits 0 after Task 2. Build output shows both routes prerendered as static: `○ /docs/getting-started` and `○ /docs/keyboard-shortcuts`.
- `sidebar-data.generated.ts` contains two entries after the build:
  - `{ slug: 'getting-started', group: 'Start here', order: 1 }`
  - `{ slug: 'keyboard-shortcuts', group: 'Reference', order: 1 }`
- SC-1 wiring probe passes: the codegen picked up both pages' `doc` exports without a single edit to sidebar-data.ts or any config.
- TableOfContents items rendering was NOT manually verified in `pnpm dev` (the Task 2 build was the only runtime check); however, the injected `tableOfContents` export is produced by the rehype-toc-export plugin after Plan 01's pipeline (`rehype-slug` → `rehype-autolink-headings` → `rehype-external-links` → `rehype-toc-export`), and the build succeeded without runtime errors, which means the plugin ran and produced a serializable export for each page.

### Threat-model residuals

- T-14-12 (macOS version drift) → mitigated: `grep -c "macOS 14"` = 0 on both pages.
- T-14-13 (dead `href="#"`) → mitigated: `grep -c 'href="#"'` = 0 on both pages.
- T-14-14 (reverse tabnabbing) → Plan 01's `rehype-external-links` stamps `rel='noopener noreferrer'` + `target='_blank'` automatically; only external link shipped in this plan is the GitHub Releases URL, which was verified in the plan-level threat model as external and thus covered.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Plan 01's rehype-toc-export plugin was unloadable by @next/mdx**

- **Found during:** Task 1, first `pnpm build` after authoring the Getting Started page.
- **Issue:** Plan 01 shipped `src/lib/rehype-toc-export.ts` and registered it in `next.config.ts` as a relative string `'./src/lib/rehype-toc-export'`. That build succeeded in Plan 01/02 because no `.mdx` files existed to exercise the loader. The moment an MDX page was compiled, `@next/mdx`'s `mdx-js-loader` failed with `Error: Cannot find module './src/lib/rehype-toc-export'`. Two latent defects compounded:
  1. The loader calls `require.resolve(pluginPath, { paths: [loaderContext] })`. Node's `paths` option only applies to module-name lookups; `./`-prefixed relative paths resolve from the loader's own `__dirname` (deep inside `node_modules/@next/mdx/`), which has no knowledge of the website root. The string path Plan 01 used was never going to resolve.
  2. Even if the path resolved, the plugin source was TypeScript. `@next/mdx` uses plain Node `import()` on the resolved path — there's no TS loader in the chain. The `.ts` file would be unloadable regardless.
- **Fix:** Two changes, bundled into the Task 1 commit because the Task 1 build depended on them:
  1. Renamed `rehype-toc-export.ts` → `rehype-toc-export.mjs`, stripped the TypeScript type annotations, preserved the plugin behavior identically (visit HAST for H2/H3, inject an `mdxjsEsm` node that exports `tableOfContents`).
  2. Updated `next.config.ts` to compute the plugin path as an absolute file path via `resolve(process.cwd(), 'src/lib/rehype-toc-export.mjs')`. Used `process.cwd()` instead of `import.meta.url` because Next 16 compiles `next.config.ts` to CJS before executing it — `import.meta` is undefined under CJS and the config load fails with `ReferenceError: exports is not defined` (verified during debugging). Absolute-path strings are JSON-serializable (Turbopack-safe) and bypass the `require.resolve({ paths })` quirk.
- **Files modified:** `website/next.config.ts`, `website/src/lib/rehype-toc-export.mjs` (new), `website/src/lib/rehype-toc-export.ts` (removed).
- **Commit:** folded into `4e76adf`.

None of the other work deviated from the plan. The two MDX files match the plan's EXACT contents byte-for-byte (modulo the `{ }` balance noted in the plan's YAML-safety note, which MDX parsed cleanly in both files).

## Authentication Gates

None. Pure content + build-chrome work; no credentials, no external services touched.

## Output Notes (per plan's `<output>` section)

- **Final word counts:** getting-started = 451 words, keyboard-shortcuts = 385 words. (Counts via `wc -w` against raw MDX source, so they include component syntax like `<ShortcutRow keys={...}>` in addition to prose — rough proxy for content density, not "reading word count".)
- **Did `<TableOfContents>` items render correctly on `pnpm dev`?** Not manually verified. The `pnpm build` pipeline succeeded end-to-end including the rehype-toc-export plugin, which means each page's compiled MDX module has a valid `tableOfContents` export. Runtime validation of the scroll-spy behavior is appropriate for Phase 14's human-verify checkpoint at the end of the phase (post-Plan 04), not this plan.
- **MDX parser quirks encountered:** Two worth recording:
  1. `<Note variant="sage" label='What "on-example" actually means'>` needed single-quoted JSX string attributes because the label contains double quotes. MDX/JSX tolerates both quote styles; swapping to single quotes is cleaner than escaping.
  2. `{{year}}` / `{{month}}` / `{{date}}` inside the YAML fenced block rendered verbatim without needing escaping. MDX only interprets `{...}` JSX expressions in prose, not inside code fences — the fenced text is passed to rehype unchanged.
- **Confirmation `grep -c 'href="#"'` = 0 on both files:** Yes. `getting-started` returned 0 and `keyboard-shortcuts` returned 0.
- **Confirmation `sidebar-data.generated.ts` picked up both pages:** Yes. Two entries after Task 2's build: `getting-started` (Start here, order 1) and `keyboard-shortcuts` (Reference, order 1).

## Known Stubs

None introduced. Both pages ship with their full intended content. The only "stub-adjacent" situation is `<PrevNext currentSlug="keyboard-shortcuts" />` with its next-link returning null today — but that's a correctness decision, not a stub: there's no next page yet, and PrevNext's D-behavior is to render only the previous card when next is missing. Plan 04's notion-property-mapping page will populate the forward link automatically on its first build.

## Threat Flags

None introduced beyond what the plan's `<threat_model>` documented. The rehype-plugin loader fix is orthogonal to the threat register (no security surface added — the plugin already ran, it just couldn't be loaded before).

## Self-Check: PASSED

**Created files exist:**
- FOUND: website/src/app/docs/getting-started/page.mdx
- FOUND: website/src/app/docs/keyboard-shortcuts/page.mdx
- FOUND: website/src/lib/rehype-toc-export.mjs

**Modified files reflect the fix:**
- FOUND: website/next.config.ts contains `resolve(process.cwd(), 'src/lib/rehype-toc-export.mjs')` on line 26
- FOUND: website/src/components/docs/sidebar-data.generated.ts contains both `getting-started` and `keyboard-shortcuts` entries

**Commits exist:**
- FOUND: 4e76adf — feat(14-03): ship /docs/getting-started with mock-verbatim copy + plugin loader fix
- FOUND: dfc1977 — feat(14-03): ship /docs/keyboard-shortcuts with mock-verbatim copy via ShortcutTable/Row

**Build status:**
- `cd website && pnpm build` → exits 0. Route list includes both new routes; build manifest prerendered both as static.
