---
phase: 14-docs-section
reviewed: 2026-04-24T00:00:00Z
depth: standard
files_reviewed: 27
files_reviewed_list:
  - website/next.config.ts
  - website/package.json
  - website/scripts/build-sidebar-data.mjs
  - website/src/app/docs/configuring-your-vault/page.mdx
  - website/src/app/docs/faq/page.mdx
  - website/src/app/docs/getting-started/page.mdx
  - website/src/app/docs/keyboard-shortcuts/page.mdx
  - website/src/app/docs/layout.tsx
  - website/src/app/docs/notion-property-mapping/page.mdx
  - website/src/app/docs/page.tsx
  - website/src/app/docs/troubleshooting/page.mdx
  - website/src/app/globals.css
  - website/src/app/sitemap.ts
  - website/src/components/docs/Crumbs.tsx
  - website/src/components/docs/Kbd.tsx
  - website/src/components/docs/Lede.tsx
  - website/src/components/docs/Note.tsx
  - website/src/components/docs/PrevNext.tsx
  - website/src/components/docs/ShortcutRow.tsx
  - website/src/components/docs/ShortcutTable.tsx
  - website/src/components/docs/Sidebar.tsx
  - website/src/components/docs/TableOfContents.tsx
  - website/src/components/docs/docs.css
  - website/src/components/docs/sidebar-data.generated.ts
  - website/src/components/docs/sidebar-data.ts
  - website/src/components/layout/Nav.tsx
  - website/src/lib/rehype-toc-export.mjs
  - website/src/mdx-components.tsx
findings:
  critical: 0
  warning: 2
  info: 8
  total: 10
status: issues_found
---

# Phase 14: Code Review Report

**Reviewed:** 2026-04-24
**Depth:** standard
**Files Reviewed:** 27
**Status:** issues_found

## Summary

Phase 14 ships the `/docs` section: six MDX pages, a build-time sidebar generator, a rehype plugin that auto-exports a per-page table of contents, and supporting layout/UI components. The implementation is cohesive and follows the documented design contracts well. No security vulnerabilities or bugs that would break rendering were found.

Two warnings identify real but narrow UX/correctness issues: the scroll-spy logic in `TableOfContents` can highlight the wrong heading when multiple headings intersect the viewport simultaneously, and the MDXComponents registration pattern in `mdx-components.tsx` diverges from the Next.js-expected merge-aware signature (cosmetic for this app, but worth a note). The rest are small maintainability nits: redundant imports, hardcoded strings, a dead ref.

## Warnings

### WR-01: TableOfContents scroll-spy: active heading is non-deterministic when multiple headings intersect

**File:** `website/src/components/docs/TableOfContents.tsx:26-35`
**Issue:** The IntersectionObserver callback iterates through all entries and unconditionally calls `setActiveId(entry.target.id)` for every entry where `isIntersecting` is true. When the page is scrolled such that two or more headings both fall inside the `-20%/-70%` rootMargin band, the "active" heading becomes whichever entry the browser happens to emit last in the entries array. Browser ordering of IntersectionObserver entries is not guaranteed to match document order, so the active link can flicker or point to the wrong heading on fast scrolls.

This also means that when a heading leaves the band by scrolling past it, no callback fires with `isIntersecting: false`, so the previously active heading stays highlighted until another heading enters — usually fine, but combined with the above produces visible jitter at section boundaries.

**Fix:** Track intersecting entries and select by document order (top-most visible heading wins):
```tsx
const observer = new IntersectionObserver(
  (entries) => {
    // Collect currently-intersecting entries; pick the one closest to the top.
    const visible = entries
      .filter((e) => e.isIntersecting)
      .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top)
    if (visible.length > 0) {
      setActiveId(visible[0].target.id)
    }
  },
  { rootMargin: '-20% 0px -70% 0px' },
)
```
Or maintain a `Set<string>` of currently-visible IDs and resolve to the first one in `items` order.

### WR-02: useMDXComponents signature drops caller-provided components

**File:** `website/src/mdx-components.tsx:75-77`
**Issue:** `useMDXComponents()` is declared with no parameters and returns only this project's overrides. Next.js's `@next/mdx` and the MDX contract expect the signature `useMDXComponents(components: MDXComponents): MDXComponents` so that provider-supplied components can be merged with per-project overrides. As written, any components passed in from an upstream `<MDXProvider>` (or from nested routes that inject their own) are silently dropped.

For this app today there is no nested MDX provider and no consumer passing extra components, so behavior is correct. But the divergence is a latent foot-gun: a future author who adds `<MDXProvider components={{...}}>` at a layout boundary will find those components ignored inside `/docs/*` with no error and no warning.

**Fix:** Accept and merge incoming components:
```tsx
export function useMDXComponents(incoming: MDXComponents = {}): MDXComponents {
  return { ...incoming, ...components }
}
```
(Order of spread determines which side wins on collision — adjust to project preference.)

## Info

### IN-01: Redundant `TableOfContents` import in every page.mdx

**File:** `website/src/app/docs/configuring-your-vault/page.mdx:1`, `faq/page.mdx:1`, `getting-started/page.mdx:1`, `keyboard-shortcuts/page.mdx:1`, `notion-property-mapping/page.mdx:1`, `troubleshooting/page.mdx:1`
**Issue:** Each `page.mdx` does `import { TableOfContents } from '@/components/docs/TableOfContents'`, but `TableOfContents` is already registered globally in `src/mdx-components.tsx:31`. The local import shadows the global registration. Not harmful, but adds six lines of boilerplate that the component registry was meant to eliminate; other globals (`Note`, `Lede`, `Crumbs`, `Kbd`, `PrevNext`, `ShortcutTable`, `ShortcutRow`) are used without import, which is inconsistent.
**Fix:** Drop the import line from each page.mdx; rely on the global registry. Or, if the import is kept intentionally (e.g., for editor IntelliSense on the `items={tableOfContents}` prop), document why in a one-line comment.

### IN-02: `observerRef` is assigned but never read

**File:** `website/src/components/docs/TableOfContents.tsx:22,36,43`
**Issue:** `observerRef` is declared, assigned inside the effect, and nulled on cleanup, but the ref value is never read anywhere. The cleanup disconnects the local `observer` const, not the ref. The ref is dead code.
**Fix:** Remove the ref entirely:
```tsx
useEffect(() => {
  if (items.length === 0) return
  const observer = new IntersectionObserver(/* ... */)
  items.forEach(({ id }) => {
    const el = document.getElementById(id)
    if (el) observer.observe(el)
  })
  return () => observer.disconnect()
}, [items])
```

### IN-03: `docs/page.tsx` hardcodes the redirect target

**File:** `website/src/app/docs/page.tsx:4`
**Issue:** The `/docs` index hardcodes `redirect('/docs/getting-started')`. If the first doc is renamed or a different doc takes its place at the top of the sidebar (changing its `group`/`order`), the redirect silently points to a stale/404 path and the SC-1 "new pages without code changes" contract is broken at the index level.
**Fix:** Derive from the single source of truth:
```tsx
import { redirect } from 'next/navigation'
import { DOC_ORDER } from '@/components/docs/sidebar-data'

export default function DocsIndex() {
  redirect(DOC_ORDER[0]?.href ?? '/')
}
```

### IN-04: Sitemap BASE URL is hardcoded and duplicated from site config

**File:** `website/src/app/sitemap.ts:4`
**Issue:** `const BASE = 'https://ps-transcribe-web.vercel.app'` hardcodes the deployment origin. The repo already has `@/lib/site` (referenced by `Nav.tsx`), which is the natural home for this. Hardcoding means a domain move requires grepping for the literal.
**Fix:** Move the canonical URL into `SITE` (or a sibling constant) and import it here. If `SITE.BASE_URL` doesn't exist yet, add it.

### IN-05: `build-sidebar-data.mjs` regex relies on a flat `doc` object with no nested braces

**File:** `website/scripts/build-sidebar-data.mjs:30`
**Issue:** `extractDocLiteral` uses `\{([\s\S]*?)\}` — non-greedy match to the first closing brace. If a future `doc` export includes any nested object (e.g., `{ navTitle: {...} }` or even a string value containing a literal `}`), the extraction terminates early and `pullValue` returns `null` for keys past the premature close. The script then silently skips the page. The contract is documented in the header comment, but there is no runtime assertion that the parsed body actually closes the literal cleanly.
**Fix:** Either (a) add a comment warning on the `doc` literal inside each page.mdx, or (b) convert the extractor to a proper balanced-brace walk (track depth, increment/decrement on `{`/`}` while respecting string and comment contexts). A minimal guard is to log a warning when a page.mdx contains an `export const doc` but yields no parsed entries — currently the warning only fires when the regex matches but the keys are missing.

### IN-06: `build-sidebar-data.mjs` does not detect duplicate `(group, order)` pairs

**File:** `website/scripts/build-sidebar-data.mjs:73`
**Issue:** Two docs with the same `group` and the same `order` will sort in stable but implementation-defined order (JavaScript's `sort` with `a.order - b.order === 0` preserves relative order, but the source iteration order is directory order, which depends on filesystem). This means `DOC_ORDER[0]` — which `PrevNext` and the soon-to-be-fixed `/docs` redirect consume — is not deterministic across machines.
**Fix:** Log a warning (or fail the build) when `sidebar-data.ts::buildSidebar` detects a duplicate `(group, order)` pair. Cheap to add inside `buildSidebar()`:
```ts
const seen = new Set<string>()
for (const d of DISCOVERED_DOCS) {
  const key = `${d.group}/${d.order}`
  if (seen.has(key)) console.warn(`[sidebar] duplicate (group, order) pair: ${key}`)
  seen.add(key)
}
```

### IN-07: Inconsistent entity escaping in getting-started.mdx

**File:** `website/src/app/docs/getting-started/page.mdx:39,41`
**Issue:** Uses `&amp;` (HTML entity) for ampersands — `Screen &amp; System Audio Recording` and `Privacy &amp; Security`. Other pages use `&` directly (e.g., `troubleshooting/page.mdx:26` writes `Privacy & Security`). Both render correctly in MDX but the inconsistency is jarring on code review and will bite anyone grepping for `Privacy & Security`.
**Fix:** Change `&amp;` to `&` on lines 39 and 41 of `getting-started/page.mdx` to match the other pages.

### IN-08: `Crumbs` uses array-index React keys on a static list

**File:** `website/src/components/docs/Crumbs.tsx:7`
**Issue:** `key={i}` on the outer `<span>` is the array index. Standard anti-pattern when the list can reorder, but here `trail` is a fixed-length static array that never reorders, so the warning does not apply in practice. Called out only for completeness — no action required unless you want to silence ESLint's `react/no-array-index-key` globally.
**Fix:** None required. If you want explicit keys, `key={seg}` works for unique-segment trails.

---

_Reviewed: 2026-04-24_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
