---
phase: 12
plan: 03
type: execute
wave: 2
depends_on: [12-01]
files_modified:
  - website/src/components/ui/Button.tsx
  - website/src/components/ui/Card.tsx
  - website/src/components/ui/MetaLabel.tsx
  - website/src/components/ui/SectionHeading.tsx
  - website/src/components/ui/CodeBlock.tsx
  - website/src/components/ui/index.ts
autonomous: true
requirements: [DESIGN-03]
must_haves:
  truths:
    - "Five reusable primitive React components exist in src/components/ui/ and can be imported from '@/components/ui'"
    - "Each primitive renders server-side (no 'use client' directive)"
    - "Each primitive spreads remaining HTML attributes via ...rest"
    - "Button supports 'primary' and 'secondary' variants via a discriminated string union"
    - "CodeBlock supports an inline prop that switches between <code> (inline) and <pre><code> (block) output"
    - "No dark: variants anywhere; no @apply; no forwardRef; no external component libraries"
  artifacts:
    - path: website/src/components/ui/Button.tsx
      provides: "Button primitive (primary or secondary variants)"
      contains: "variant?: 'primary' | 'secondary'"
    - path: website/src/components/ui/Card.tsx
      provides: "Card primitive (paper bg, 0.5px rule, 10px radius)"
      contains: "border-[0.5px] border-rule rounded-card"
    - path: website/src/components/ui/MetaLabel.tsx
      provides: "MetaLabel primitive (10px JetBrains Mono uppercase, 0.08em tracking)"
      contains: "font-mono text-[10px] uppercase tracking-[0.08em]"
    - path: website/src/components/ui/SectionHeading.tsx
      provides: "SectionHeading primitive (Spectral serif at section scale, polymorphic as prop)"
      contains: "font-serif"
    - path: website/src/components/ui/CodeBlock.tsx
      provides: "CodeBlock primitive (inline pill or block pre/code)"
      contains: "inline?: boolean"
    - path: website/src/components/ui/index.ts
      provides: "Barrel export for clean imports in Plan 04 design-system page"
      contains: "export { Button } from './Button'"
  key_links:
    - from: "each primitive's className"
      to: "Plan 01's @theme inline tokens (bg-paper, text-ink, rounded-card, shadow-btn, font-*)"
      via: "Tailwind v4 utility generation"
      pattern: "bg-paper|text-ink|border-rule|rounded-card|shadow-btn|font-sans|font-serif|font-mono"
---

<objective>
Build five presentational React primitives in `website/src/components/ui/` using Tailwind utility class strings composed against Plan 01's Chronicle tokens: `Button`, `Card`, `MetaLabel`, `SectionHeading`, `CodeBlock`. Plus an optional barrel `index.ts` for clean imports. Per D-04, no `@apply`. Per D-05, one file per primitive, named exports. Per D-06, discriminated string unions for variants. Per D-07, minimal props surface (only what Phase 12 needs; `MetaLabel` ships default-only with no `tone` prop; no `forwardRef`; no `asChild`). All primitives stay server components (no `"use client"`).

Purpose: Gives Phase 12's `/design-system` showcase page real components to render, and gives Phases 13/14/15 a consistent primitive surface to compose landing, docs, and changelog pages against.

Output: Six files under `website/src/components/ui/`. Build green after creation.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/12-chronicle-design-system-port/12-CONTEXT.md
@.planning/phases/12-chronicle-design-system-port/12-RESEARCH.md
@.planning/phases/12-chronicle-design-system-port/12-VALIDATION.md
@.planning/research/CLAUDE-DESIGN-BRIEF.md
@design/ps-transcribe-web-unzipped/assets/chronicle-mock.css
@website/src/app/globals.css

<interfaces>
<!-- After Plan 01 ships, these Tailwind utilities resolve to Chronicle tokens: -->
<!--   bg-paper, bg-paper-warm, bg-paper-soft, bg-ink, bg-spk2-bg -->
<!--   text-paper, text-ink, text-ink-muted, text-ink-faint, text-ink-ghost, text-spk2-fg, text-accent-ink -->
<!--   border-rule, border-rule-strong, border-spk2-rail -->
<!--   rounded-input, rounded-btn, rounded-card, rounded-bubble, rounded-pill -->
<!--   shadow-lift, shadow-btn, shadow-float -->
<!--   font-sans (Inter + SF Pro Text + system), font-serif (Spectral + New York + Georgia), font-mono (JetBrains Mono + SF Mono + Menlo) -->

<!-- Path alias @/* maps to ./src/* in website/tsconfig.json compilerOptions.paths -->
<!-- So `import { Button } from '@/components/ui'` resolves to `./src/components/ui/index.ts` -->

<!-- 0.5px hairline is INTENTIONAL (Specifics bullet: "Hairlines must be 0.5px, not 1px. Use `border: 0.5px solid var(--color-rule)` literally"). -->
<!-- Tailwind v4 arbitrary value syntax: border-[0.5px] -->

<!-- Two-layer primary button shadow: --shadow-btn in globals.css contains both the outer drop and inset highlight. -->
<!-- Do NOT special-case the inset layer in React; `className="shadow-btn"` emits the whole comma-separated box-shadow. -->
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create all five primitive component files plus barrel export</name>
  <files>
    website/src/components/ui/Button.tsx
    website/src/components/ui/Card.tsx
    website/src/components/ui/MetaLabel.tsx
    website/src/components/ui/SectionHeading.tsx
    website/src/components/ui/CodeBlock.tsx
    website/src/components/ui/index.ts
  </files>
  <read_first>
    - website/src/app/globals.css (Plan 01 output -- confirms utilities exist: bg-paper, text-ink, rounded-card, shadow-btn, font-sans/serif/mono)
    - .planning/phases/12-chronicle-design-system-port/12-CONTEXT.md sections Decisions (D-04 through D-07) and Specifics (MetaLabel calibration, Button shadow, Card defensive defaults, hairlines at 0.5px, CodeBlock inline pill padding)
    - .planning/phases/12-chronicle-design-system-port/12-RESEARCH.md section "Primitive Component Patterns" (exact Button.tsx example; per-primitive table)
    - .planning/research/CLAUDE-DESIGN-BRIEF.md sections Buttons (primary/secondary specs), Typography (Spectral sizes, mono meta-label conventions), Component idioms from the app to borrow (MetaLabel 10px mono, Card paper + 0.5px rule + 10px radius)
    - design/ps-transcribe-web-unzipped/assets/chronicle-mock.css lines 70-78 (.meta sizing reference), lines 83-116 (.btn reference), lines 132-137 (.card reference) -- REFERENCE ONLY, do NOT import
    - website/tsconfig.json (confirm `@/*` alias maps to `./src/*` so '@/components/ui' resolves correctly)
  </read_first>
  <action>
Create directory `website/src/components/ui/` then create the six files below. Exact class strings prescribed; do not paraphrase. Each primitive under about 30 lines. All server components (no `"use client"`). All named exports. No `forwardRef`. No `@apply`. No `dark:` variants anywhere. No `cn()` helper. No external deps.

### File 1: `website/src/components/ui/Button.tsx`

```tsx
import type { ButtonHTMLAttributes } from 'react'

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: 'primary' | 'secondary'
}

const base =
  'inline-flex items-center gap-2 px-4 py-[10px] rounded-btn font-sans text-[14px] font-medium leading-none transition-colors duration-[120ms] focus-visible:outline focus-visible:outline-2 focus-visible:outline-accent-ink focus-visible:outline-offset-2'

const variants: Record<NonNullable<ButtonProps['variant']>, string> = {
  primary: 'bg-ink text-paper shadow-btn hover:bg-[#2a2a25]',
  secondary: 'bg-paper text-ink border-[0.5px] border-rule-strong hover:bg-paper-soft',
}

export function Button({ variant = 'primary', className = '', ...rest }: ButtonProps) {
  return (
    <button
      {...rest}
      className={`${base} ${variants[variant]} ${className}`.trim()}
    />
  )
}
```

Key notes:
- Padding `px-4 py-[10px]` matches the mock's `padding: 10px 16px` (chronicle-mock.css line 87).
- Primary background hover `#2a2a25` is the mock's `.btn--primary:hover` color (line 103).
- `shadow-btn` emits the full two-layer `--shadow-btn` per Plan 01.
- 0.5px border on secondary: `border-[0.5px] border-rule-strong` (D-11 "hairlines must be 0.5px").

### File 2: `website/src/components/ui/Card.tsx`

```tsx
import type { HTMLAttributes } from 'react'

type CardProps = HTMLAttributes<HTMLDivElement>

export function Card({ className = '', children, ...rest }: CardProps) {
  return (
    <div
      {...rest}
      className={`bg-paper border-[0.5px] border-rule rounded-card p-[22px] ${className}`.trim()}
    >
      {children}
    </div>
  )
}
```

Key notes:
- `bg-paper` NOT `bg-paper-warm` (Specifics: "Card is defensive by default; paperWarm variant is a Phase 13 concern").
- `border-[0.5px] border-rule` (not `border-rule-strong`; hairline uses the lighter alpha per chronicle-mock.css line 134).
- `rounded-card` = 10px radius.
- `p-[22px]` matches the mock's 22px padding (chronicle-mock.css line 136).

### File 3: `website/src/components/ui/MetaLabel.tsx`

```tsx
import type { HTMLAttributes } from 'react'

type MetaLabelProps = HTMLAttributes<HTMLSpanElement>

export function MetaLabel({ className = '', children, ...rest }: MetaLabelProps) {
  return (
    <span
      {...rest}
      className={`font-mono text-[10px] uppercase tracking-[0.08em] leading-none text-ink-faint ${className}`.trim()}
    >
      {children}
    </span>
  )
}
```

Key notes:
- No `tone` prop for Phase 12 (deferred to Phase 13 if landing page needs sage/navy variants per Deferred Ideas + Discretion).
- `0.08em` letter-spacing (Specifics: "Follow the brief's .meta rule in chronicle-mock.css as the sizing reference: letter-spacing: 0.08em"). This intentionally diverges from the brief's "0.5-0.8px" early copy; the mock's 0.08em is authoritative.
- `text-ink-faint` for default color per chronicle-mock.css line 76.
- Consumers can override color by passing `className="text-accent-ink"` etc. via the spread pattern.

### File 4: `website/src/components/ui/SectionHeading.tsx`

```tsx
import type { HTMLAttributes } from 'react'
import { createElement } from 'react'

type SectionHeadingProps = HTMLAttributes<HTMLHeadingElement> & {
  as?: 'h1' | 'h2' | 'h3' | 'h4'
}

export function SectionHeading({
  as = 'h2',
  className = '',
  children,
  ...rest
}: SectionHeadingProps) {
  return createElement(
    as,
    {
      ...rest,
      className: `font-serif font-normal text-[clamp(26px,3vw,32px)] leading-[1.15] tracking-[-0.01em] text-ink ${className}`.trim(),
    },
    children,
  )
}
```

Key notes:
- `as` prop is the only variant (Discretion: polymorphic element allowed). Default is `h2`; consumers pick `h1`/`h3`/`h4`.
- `font-serif` resolves to the Spectral + New York + Georgia chain.
- `clamp(26px, 3vw, 32px)` matches the brief's "Section titles 28-32px serif" and chronicle-mock.css `.h-section` line 222.
- `font-normal` (400) because Spectral regular is the design intent (not bold).
- Uses `createElement` to pick the tag at runtime without breaking the server-component constraint.

### File 5: `website/src/components/ui/CodeBlock.tsx`

```tsx
import type { HTMLAttributes } from 'react'

type CodeBlockProps = HTMLAttributes<HTMLElement> & {
  inline?: boolean
}

const inlineClasses =
  'font-mono text-[14px] bg-paper-soft text-ink px-[6px] py-[2px] rounded-[4px]'

const blockClasses =
  'font-mono text-[14px] bg-paper-soft text-ink border-[0.5px] border-rule rounded-card p-4 overflow-x-auto'

export function CodeBlock({
  inline = false,
  className = '',
  children,
  ...rest
}: CodeBlockProps) {
  if (inline) {
    return (
      <code {...rest} className={`${inlineClasses} ${className}`.trim()}>
        {children}
      </code>
    )
  }
  return (
    <pre className={`${blockClasses} ${className}`.trim()}>
      <code {...rest}>{children}</code>
    </pre>
  )
}
```

Key notes:
- Inline uses `<code>` alone; block uses `<pre><code>` per semantic HTML (Discretion).
- Inline pill: `px-[6px] py-[2px] rounded-[4px]` per Specifics ("keep padding tight; 2px 6px; rounded 4px = radius-input").
- Block border: `border-[0.5px] border-rule rounded-card` matching Card's hairline.
- No syntax highlighting (deferred to Phase 14 per CONTEXT).
- `children` rendered via text interpolation, NOT `dangerouslySetInnerHTML` (T-12-01 mitigation).

### File 6: `website/src/components/ui/index.ts` (barrel export)

```tsx
export { Button } from './Button'
export { Card } from './Card'
export { MetaLabel } from './MetaLabel'
export { SectionHeading } from './SectionHeading'
export { CodeBlock } from './CodeBlock'
```

Keeps Plan 04's design-system page import to a single line: `import { Button, Card, MetaLabel, SectionHeading, CodeBlock } from '@/components/ui'`.

### Forbidden in this task

- No `"use client"` at the top of any primitive (server components only).
- No `@apply` directives (D-04).
- No `forwardRef` (deferred per Discretion + RESEARCH.md anti-patterns).
- No `dark:` variants (DESIGN-04 guard).
- No default exports (D-05: named exports only).
- No import of `chronicle-mock.css` or use of its class names (D-12).
- No `asChild` / Radix / shadcn / clsx / tailwind-merge / CVA installs (D-07 + RESEARCH.md anti-patterns).
- No `dangerouslySetInnerHTML` in CodeBlock (T-12-01 mitigation).
- No em dashes in any file.
  </action>
  <verify>
    <!-- Note on dark: regex tightening: this plan uses `dark:(bg|text|border|ring)` which is stricter -->
    <!-- than VALIDATION.md probe 12-03-04's loose `dark:` pattern. Rationale: the loose pattern would -->
    <!-- false-positive on legitimate Tailwind utilities that happen to contain "dark:" as a literal substring -->
    <!-- (e.g., a className string referencing darker/darkest color names). The tightened form matches only -->
    <!-- the four utility categories that would actually introduce dark-mode styling (bg, text, border, ring). -->
    <!-- A loose second pass (`grep -rn 'dark:'`) is also run below as belt-and-suspenders for any missed variant. -->
    <automated>cd website && for f in Button Card MetaLabel SectionHeading CodeBlock; do test -f src/components/ui/$f.tsx || { echo "MISSING: $f.tsx"; exit 1; }; done && test -f src/components/ui/index.ts && ! grep -rn "^['\"]use client['\"]" src/components/ui/ && ! grep -rn "@apply" src/components/ui/ && ! grep -rn "forwardRef" src/components/ui/ && ! grep -rnE "dark:(bg|text|border|ring)" src/components/ui/ && ! grep -rn "dark:" src/components/ui/ && ! grep -rn "dangerouslySetInnerHTML" src/components/ui/ && grep -q "variant?: 'primary' | 'secondary'" src/components/ui/Button.tsx && grep -q "shadow-btn" src/components/ui/Button.tsx && grep -q "border-\[0.5px\] border-rule" src/components/ui/Card.tsx && grep -q "rounded-card" src/components/ui/Card.tsx && grep -q "tracking-\[0.08em\]" src/components/ui/MetaLabel.tsx && grep -q "font-serif" src/components/ui/SectionHeading.tsx && grep -q "inline?: boolean" src/components/ui/CodeBlock.tsx && grep -q "export { Button }" src/components/ui/index.ts && ! LC_ALL=C grep -rl $'\xe2\x80\x94' src/components/ui/ && pnpm run build</automated>
  </verify>
  <acceptance_criteria>
    - All 5 primitive files exist: `for f in Button Card MetaLabel SectionHeading CodeBlock; do test -f website/src/components/ui/$f.tsx; done` (all pass)
    - Barrel export exists: `test -f website/src/components/ui/index.ts`
    - No "use client" anywhere: `! grep -rn "^['\"]use client['\"]" website/src/components/ui/`
    - No @apply: `! grep -rn "@apply" website/src/components/ui/`
    - No forwardRef: `! grep -rn "forwardRef" website/src/components/ui/`
    - No dark: variants (strict category-scoped): `! grep -rnE "dark:(bg|text|border|ring)" website/src/components/ui/`
    - No dark: variants (loose belt-and-suspenders matching VALIDATION.md probe 12-03-04): `! grep -rn "dark:" website/src/components/ui/`
    - No dangerouslySetInnerHTML: `! grep -rn "dangerouslySetInnerHTML" website/src/components/ui/` (T-12-01 mitigation verified)
    - Button has primary/secondary union: `grep -q "variant?: 'primary' | 'secondary'" website/src/components/ui/Button.tsx`
    - Button uses shadow-btn utility: `grep -q "shadow-btn" website/src/components/ui/Button.tsx`
    - Card has 0.5px rule hairline: `grep -q "border-\[0.5px\] border-rule" website/src/components/ui/Card.tsx`
    - Card uses rounded-card: `grep -q "rounded-card" website/src/components/ui/Card.tsx`
    - MetaLabel has 0.08em tracking: `grep -q "tracking-\[0.08em\]" website/src/components/ui/MetaLabel.tsx`
    - SectionHeading uses font-serif: `grep -q "font-serif" website/src/components/ui/SectionHeading.tsx`
    - CodeBlock has inline prop: `grep -q "inline?: boolean" website/src/components/ui/CodeBlock.tsx`
    - Barrel exports all 5: grep finds `export { Button }`, `export { Card }`, `export { MetaLabel }`, `export { SectionHeading }`, `export { CodeBlock }` in index.ts
    - No em dashes (portable, BSD+GNU grep compatible): `! LC_ALL=C grep -rl $'\xe2\x80\x94' website/src/components/ui/`
    - `cd website && pnpm run build` exits 0
  </acceptance_criteria>
  <done>
All 5 primitive components + barrel export exist under `website/src/components/ui/`. Each is a pure server component consuming Plan 01's `@theme inline` tokens via Tailwind utilities. Plan 04 can now import from `@/components/ui` and render the showcase gallery.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| `CodeBlock` children boundary | In Phases 14/15, MDX-authored content and CHANGELOG entries will be rendered through `CodeBlock`. This plan establishes the safe rendering pattern (text interpolation only) before those consumers exist. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-12-01 | Tampering / XSS | `CodeBlock` primitive rendering author content from MDX (Phase 14) or CHANGELOG.md (Phase 15) | mitigate | `CodeBlock` renders `children` via React text interpolation (`{children}` inside `<code>` or `<pre><code>`). Explicitly forbids `dangerouslySetInnerHTML`. Verified by grep probe in acceptance_criteria: `! grep -rn "dangerouslySetInnerHTML" website/src/components/ui/`. React auto-escapes HTML/JS in string children, so untrusted code strings render as literal text, not as DOM. |
| T-12-02 | Information disclosure | Future dev-only showcase content leaking internal strings | accept | Primitives are presentational only and accept any caller content. No secrets are hard-coded in these files. The showcase content (Plan 04) will use only the brief's public voice copy. |
| T-12-03 | Tampering | next/font supply chain | n/a (not in scope) | Owned by Plan 02 (layout/font loading). Cross-reference only for traceability. |
</threat_model>

<verification>
- All 5 primitives compile with `pnpm run build`
- Each primitive is around 30 lines or fewer (target; SectionHeading is slightly higher due to createElement, which is fine)
- Each primitive spreads `...rest` so consumers can override HTML attrs
- No primitive imports from another primitive (they are independent leaves)
</verification>

<success_criteria>
- `Button`, `Card`, `MetaLabel`, `SectionHeading`, `CodeBlock` all exist as named-export server components
- Each consumes Plan 01's Chronicle tokens via Tailwind utilities
- Barrel `index.ts` provides `@/components/ui` import surface
- Build green
</success_criteria>

<output>
After completion, create `.planning/phases/12-chronicle-design-system-port/12-03-SUMMARY.md` with:
- Line counts for each primitive (target 30 or fewer)
- Confirmation: no "use client", no @apply, no forwardRef, no dark: variants, no dangerouslySetInnerHTML
- The exact className string used by each primitive (for Plan 04 to render matching DOM signatures)
- Next step: Plan 04 renders the showcase gallery consuming these primitives
</output>
</content>
