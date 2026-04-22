---
phase: 12-chronicle-design-system-port
reviewed: 2026-04-22T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - website/src/app/design-system/page.tsx
  - website/src/app/globals.css
  - website/src/app/layout.tsx
  - website/src/components/ui/Button.tsx
  - website/src/components/ui/Card.tsx
  - website/src/components/ui/CodeBlock.tsx
  - website/src/components/ui/MetaLabel.tsx
  - website/src/components/ui/SectionHeading.tsx
  - website/src/components/ui/index.ts
findings:
  critical: 0
  warning: 1
  info: 3
  total: 4
status: issues_found
---

# Phase 12: Code Review Report

**Reviewed:** 2026-04-22
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Phase 12 ports the macOS Chronicle design system to the Next.js website: CSS custom-property tokens wired through Tailwind v4 `@theme inline`, five UI primitives (Button, Card, CodeBlock, MetaLabel, SectionHeading), and a non-indexed `/design-system` showcase page. The implementation is tight, type-safe, and faithful to the tokens documented in `globals.css`. No security issues, no crash risks, no dead code.

One real bug: `CodeBlock`'s block variant spreads caller-provided HTML attributes onto the inner `<code>` element rather than the outer `<pre>`, so props like `id`, `aria-label`, or event handlers will land on the wrong element. Three minor quality nits around a hardcoded hover color, a duplicative body class, and an awkward key name.

The showcase page correctly sets `robots: { index: false, follow: false }` and is absent from `sitemap.ts`, so the "not indexed, not linked" claim in the footer matches reality.

## Warnings

### WR-01: CodeBlock block variant spreads props onto inner `<code>` instead of outer `<pre>`

**File:** `website/src/components/ui/CodeBlock.tsx:26-30`
**Issue:** In the block branch, `{...rest}` is forwarded to the inner `<code>` element while `className` is merged onto the outer `<pre>`. `CodeBlockProps` extends `HTMLAttributes<HTMLElement>`, so a caller reasonably expects props like `id`, `aria-label`, `onClick`, `data-*`, or `role` to apply to the root element (the `<pre>`). Today they silently land on the nested `<code>`, which breaks anchor links, accessibility labels, and any consumer that expects the outer block to be the interactive/identifiable node. This also splits behavior between the two branches: in the inline branch props land on `<code>` (the root), in the block branch they land on `<code>` (the inner child). Consistency is broken.

**Fix:** Forward `...rest` to the outer `<pre>` in the block variant:

```tsx
if (inline) {
  return (
    <code {...rest} className={`${inlineClasses} ${className}`.trim()}>
      {children}
    </code>
  )
}
return (
  <pre {...rest} className={`${blockClasses} ${className}`.trim()}>
    <code>{children}</code>
  </pre>
)
```

Note this also requires widening/adjusting the prop type, since `HTMLAttributes<HTMLElement>` applied to `<pre>` is fine, but if you want stricter typing consider `HTMLAttributes<HTMLPreElement>` for the block case. The simpler fix above preserves the current type contract and resolves the bug.

## Info

### IN-01: Hardcoded hover color `#2a2a25` bypasses the token system

**File:** `website/src/components/ui/Button.tsx:11`
**Issue:** The primary button hover uses an inline hex literal (`hover:bg-[#2a2a25]`) instead of a named token. The `globals.css` header comment calls tokens the "source of truth (per D-01 + D-11)," and every other color in the primitives routes through a `var(--color-*)`. This one-off hex is the only exception in the five components and the only magic color in the diff. If the ink ramp ever shifts, this value will drift silently.

**Fix:** Either add an `--color-ink-hover` (or similar) token in `globals.css`, or reuse an existing neighbor such as `text-ink` at reduced opacity / `bg-ink/95`. Example with a new token:

```css
/* globals.css */
--color-ink-hover: #2A2A25;
```

```tsx
// Button.tsx
primary: 'bg-ink text-paper shadow-btn hover:bg-ink-hover',
```

If the hover is intentionally a one-off and not worth a token, at minimum add a short comment in `Button.tsx` explaining why this color lives outside the palette.

### IN-02: Redundant `font-sans antialiased` on `<body>` duplicates `globals.css` body rule

**File:** `website/src/app/layout.tsx:61`
**Issue:** The `<body>` has `className="font-sans antialiased"`, but `globals.css` already sets `font-family: var(--font-sans)` and `-webkit-font-smoothing: antialiased` on the `body` selector. The utilities are harmless (they resolve to the same values), but the duplication means two places now own body typography defaults. If the CSS rule is updated in the future, the Tailwind class will silently override it.

**Fix:** Remove the className and let `globals.css` own body defaults:

```tsx
<body>{children}</body>
```

Or, if you prefer the Tailwind utility as the single source of truth, remove the `font-family` / `-webkit-font-smoothing` declarations from `globals.css body {}`. Pick one location.

### IN-03: Awkward `group.group` key access in palette loop

**File:** `website/src/app/design-system/page.tsx:128-129`
**Issue:** The palette data structure uses `{ group: string; swatches: Swatch[] }`, producing reads like `palette.map((group) => ... key={group.group} ... <MetaLabel>{group.group}</MetaLabel>`. Not a bug, but the repetition is a readability smell.

**Fix:** Rename the field or the loop variable:

```tsx
const palette: Array<{ name: string; swatches: Swatch[] }> = [
  { name: 'Paper', swatches: [...] },
  ...
]

// then
{palette.map((g) => (
  <div key={g.name}>
    <MetaLabel>{g.name}</MetaLabel>
    ...
  </div>
))}
```

---

_Reviewed: 2026-04-22_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
