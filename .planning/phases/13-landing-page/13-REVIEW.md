---
phase: 13-landing-page
reviewed: 2026-04-23T16:13:09Z
depth: standard
files_reviewed: 22
files_reviewed_list:
  - website/scripts/verify-landing.mjs
  - website/src/app/layout.tsx
  - website/src/app/page.tsx
  - website/src/components/layout/Footer.tsx
  - website/src/components/layout/Nav.tsx
  - website/src/components/mocks/ChatBubbleMock.tsx
  - website/src/components/mocks/DualStreamMock.tsx
  - website/src/components/mocks/MockWindow.tsx
  - website/src/components/mocks/NotionTableMock.tsx
  - website/src/components/mocks/ObsidianVaultMock.tsx
  - website/src/components/motion/Reveal.tsx
  - website/src/components/sections/FeatureBlock.tsx
  - website/src/components/sections/FinalCTA.tsx
  - website/src/components/sections/Hero.tsx
  - website/src/components/sections/ShortcutGrid.tsx
  - website/src/components/sections/ThreeThingsStrip.tsx
  - website/src/components/ui/index.ts
  - website/src/components/ui/LinkButton.tsx
  - website/src/hooks/useReveal.ts
  - website/src/hooks/useScrolled.ts
  - website/src/lib/changelog.ts
  - website/src/lib/site.ts
findings:
  critical: 0
  warning: 3
  info: 6
  total: 9
status: issues_found
---

# Phase 13: Code Review Report

**Reviewed:** 2026-04-23T16:13:09Z
**Depth:** standard
**Files Reviewed:** 22
**Status:** issues_found

## Summary

Phase 13 ships a marketing landing page for PS Transcribe (Next.js 16 App Router, Tailwind, server-first). Overall code quality is high: copy is all static so there is no user-input attack surface, content is rendered via JSX (no `dangerouslySetInnerHTML`, no `eval`), and secret handling is clean -- `changelog.ts` reads a public `CHANGELOG.md` at build time and does not touch credentials.

No critical issues were found. The warnings are focused on: (a) a likely hydration mismatch in `Nav` (`useScrolled` initial state diverges if the page loads already scrolled), (b) a potentially mis-scoped event listener in `useScrolled` (`document` instead of `window`), and (c) an accessibility gap where the hero download CTA does not announce that it triggers a file download. The info items cover minor code-quality nits (consistency on external link target/rel, a commented rationale that no longer matches the chosen approach, and a couple of dead/duplicate export patterns).

External-link safety is not a concern here because no link uses `target="_blank"` -- all external navigations replace the current tab. Noted, not flagged.

CLS contributors were checked: the hero `<Image>` has explicit `width`/`height` (2260x1408), fonts use `display: swap` with CSS variables, and the `<figure>` wrapper around the screenshot has a fixed `max-w-[1080px]` so intrinsic aspect-ratio is preserved. That is the correct pattern for Next 16.

## Warnings

### WR-01: Hydration mismatch risk in Nav when page loads already scrolled

**File:** `website/src/components/layout/Nav.tsx:11-20`
**Issue:** `useScrolled(6)` initializes `scrolled = false` on the server and only updates on the client after the `useEffect` mount. If a user navigates to a deep hash (e.g., `#download`), reloads mid-scroll, or uses browser scroll restoration, the browser may already be past the 6px threshold before hydration. The initial client render still starts at `scrolled = false`, then flips to `true` one frame later -- producing a visible flash of the unscrolled nav style and potentially a React hydration warning in dev.

The `data-nav-scrolled` attribute compounds this: its server-rendered value is `"false"`, and the client will immediately re-render it to `"true"`, which React will flag as a mismatch in strict mode.

**Fix:** Either (a) read the initial scroll position synchronously in `useEffect` and accept the post-mount flash as intentional, which is what you do today -- and suppress the attribute mismatch with `suppressHydrationWarning` on the relevant element; or (b) use a layout effect for a synchronous pre-paint read and omit the data attribute from SSR output.

```tsx
// Option A: keep useEffect, suppress warning on the single attribute that flips
<header
  suppressHydrationWarning
  data-nav-scrolled={scrolled ? 'true' : 'false'}
  className={...}
>
```

```ts
// Option B: skip SSR for the derived class entirely (hook returns undefined on first render)
export function useScrolled(threshold = 6): boolean | undefined {
  const [scrolled, setScrolled] = useState<boolean | undefined>(undefined)
  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > threshold)
    onScroll()
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [threshold])
  return scrolled
}
// then in Nav: treat `undefined` as "not scrolled" visually
```

### WR-02: `useScrolled` listens on `document` instead of `window`

**File:** `website/src/hooks/useScrolled.ts:15-16`
**Issue:** The handler reads `window.scrollY`, but the listener is attached to `document`:

```ts
document.addEventListener('scroll', onScroll, { passive: true })
return () => document.removeEventListener('scroll', onScroll)
```

In practice this works today because scroll events bubble from the scrolling element through `document` to `window`, and both `document.addEventListener('scroll')` and `window.addEventListener('scroll')` receive them. But it is non-idiomatic (the MDN guidance and virtually every React example uses `window`), and it breaks if any ancestor of the scrolling element calls `stopPropagation` -- something a future portal/modal component could reasonably do.

**Fix:** Attach to `window` for consistency with the value being read.

```ts
window.addEventListener('scroll', onScroll, { passive: true })
return () => window.removeEventListener('scroll', onScroll)
```

### WR-03: Hero and FinalCTA download CTAs do not announce "file download" to screen readers

**File:** `website/src/components/sections/Hero.tsx:43-50`, `website/src/components/sections/FinalCTA.tsx:41-53`
**Issue:** The primary CTA is an anchor to a `.dmg` file (`SITE.DMG_URL`). Screen readers announce "link, Download for macOS" -- which is technically accurate, but the link actually initiates a ~100MB binary download rather than navigating to a page. Users who rely on assistive tech may miss that distinction. In addition, the anchor lacks a `download` attribute, so browsers rely on the server's `Content-Disposition` header (GitHub's `releases/latest/download/...` does set this, but it's implicit behavior not expressed in the markup).

This is a warning rather than info because the CTA is the single most important interaction on the page.

**Fix:** Add `download` and an `aria-describedby` (or descriptive `aria-label`) that includes the file size when known.

```tsx
<LinkButton
  variant="primary"
  href={SITE.DMG_URL}
  download
  aria-label="Download PS Transcribe disk image for macOS"
>
  ...
  Download for macOS
</LinkButton>
```

If `LinkButton` does not currently forward `download` through `...rest`, verify -- it does in the current implementation (spreads `...rest` onto `<a>`), so the prop will pass through.

## Info

### IN-01: `ObsidianVaultMock` uses `<strong>` purely for styling, not emphasis

**File:** `website/src/components/mocks/ObsidianVaultMock.tsx:52,55,58`
**Issue:** Speaker names are wrapped in `<strong class="font-semibold">` for visual weight, but the surrounding paragraph is decorative mockup content (aria context is the parent `MockWindow`'s mock title). Screen readers will announce "strong, Speaker 2, 14:22" three times. Since these are mockups, not real transcript data, the emphasis is cosmetic.

**Fix:** Swap `<strong>` for `<span className="font-semibold">`, or wrap the entire mock in `aria-hidden` if the content is purely illustrative (preferred -- the `MockWindow` title already conveys "Obsidian · Vault" contextually, and the mock's contents aren't meant to be read). Consistent with `DualStreamMock`'s `aria-hidden` on the bar grid and `ChatBubbleMock`'s lack of semantic markup.

### IN-02: `Reveal`-wrapped mock might not fire on reduced-motion users past initial viewport

**File:** `website/src/hooks/useReveal.ts:16-21`
**Issue:** When `prefers-reduced-motion: reduce` is set, the hook sets `visible = true` immediately and returns -- this is correct and good. However, the effect runs only on mount; if the user toggles reduced-motion mid-session (rare but possible on macOS via System Settings), the hook does not re-check. Not a bug today, just a subtle UX edge case. Flagging as info.

**Fix:** Optional. Listen to `matchMedia` change events:

```ts
useEffect(() => {
  const mq = window.matchMedia('(prefers-reduced-motion: reduce)')
  const apply = () => mq.matches && setVisible(true)
  apply()
  if (mq.matches) return
  // ...existing IntersectionObserver code...
  mq.addEventListener('change', apply)
  return () => { io.disconnect(); mq.removeEventListener('change', apply) }
}, [])
```

### IN-03: `ui/index.ts` re-exports components that don't exist in this review scope

**File:** `website/src/components/ui/index.ts:1-6`
**Issue:** `index.ts` exports `Button`, `Card`, `MetaLabel`, `SectionHeading`, `CodeBlock`, `LinkButton`. Only `MetaLabel`, `SectionHeading`, and `LinkButton` are consumed by the files in this phase. `Button`, `Card`, and `CodeBlock` exist in the `ui/` directory but are not imported anywhere in the phase-13 scope (they're presumably reserved for docs/changelog pages in future phases 14/15).

This isn't a problem -- it's expected given the barrel-export pattern -- but tree-shaking depends on the bundler and `sideEffects: false` in package.json. If absent, unused exports add weight to the landing page bundle.

**Fix:** Verify `package.json` has `"sideEffects": false` (or an allowlist) in the `ps-transcribe-website` package. If not, either add it or import directly from each file instead of through the barrel.

### IN-04: `changelog.ts` cache is module-level and will survive hot reloads in dev

**File:** `website/src/lib/changelog.ts:19`
**Issue:** `let cached: ChangelogEntry[] | null = null` is a module-scoped cache that persists for the lifetime of the Node process. In production this is fine -- builds are static and the cache is populated once. In development with `next dev`, editing `CHANGELOG.md` will NOT bust the cache until the dev server restarts, because the module is already in memory.

Low-severity info: the typical author workflow is to edit CHANGELOG, then build, which will repopulate. But someone iterating on hero copy while editing CHANGELOG will see stale dates.

**Fix:** Skip caching in development, or key cache on file mtime.

```ts
if (cached && process.env.NODE_ENV === 'production') return cached
```

### IN-05: Mock traffic-light colors are hardcoded hex strings (by design, per comment)

**File:** `website/src/components/mocks/MockWindow.tsx:28-30`
**Issue:** Flagging for completeness since grep for hex literals hits this file. The comment at line 9 already documents the rationale (these are macOS window controls, not brand colors). No action needed -- this is correct; they should not be promoted to theme tokens.

### IN-06: `ShortcutGrid` uses a visually-hidden span solely to satisfy a grep assertion

**File:** `website/src/components/sections/ShortcutGrid.tsx:85-91`
**Issue:** The `<span className="sr-only" data-combo>` exists so `verify-landing.mjs` can grep for substrings like `⌘⇧R` in the rendered HTML, because the chips emit each key as a separate element. The comment is honest about this. But:

1. A screen reader user will now hear the combo twice: once from `sr-only` (`⌘⇧R`) and once from the `aria-label="⌘⇧R"` on the sibling key row (line 92). That's the definition of redundancy.
2. Tying production markup to a build-time grep check is a code smell. If verify-landing were parsing the DOM (via a headless browser or `cheerio`), the sr-only escape hatch wouldn't be needed.

**Fix:** Either drop the sr-only span and make `verify-landing.mjs` concatenate per-chip contents, or drop the `aria-label` on the chip row and rely only on the sr-only span. The first option is cleaner long-term but costs some script work.

```tsx
// Minimal fix: drop the aria-label, keep sr-only as the only combo announcement
<div className="flex items-center gap-1">
  {s.keys.map(...)}
</div>
```

---

_Reviewed: 2026-04-23T16:13:09Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
