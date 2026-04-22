---
phase: 12
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - website/src/app/globals.css
autonomous: true
requirements: [DESIGN-01, DESIGN-02, DESIGN-04]
must_haves:
  truths:
    - "All 16 Chronicle color tokens resolvable as bg-*/text-*/border-* utilities AND as var(--color-*) in inline styles"
    - "5 radii tokens resolvable as rounded-* utilities AND as var(--radius-*)"
    - "3 named shadow tokens resolvable as shadow-* utilities AND as var(--shadow-*)"
    - "font-sans, font-serif, font-mono utilities fall back to SF Pro Text / New York / SF Mono if next/font webfonts fail"
    - "OS dark-mode preference cannot flip the page to dark -- the prefers-color-scheme: dark block is gone and color-scheme: light is pinned on <html>"
    - "pnpm run build compiles cleanly with the rewritten globals.css"
  artifacts:
    - path: website/src/app/globals.css
      provides: "Chronicle tokens (:root), Tailwind v4 @theme inline re-export, light-mode lock, body reset"
      contains: "@theme inline, --color-paper, --color-ink-muted, --color-spk2-bg, --radius-card, --shadow-btn, color-scheme: light"
  key_links:
    - from: "website/src/app/globals.css @theme inline block"
      to: "Tailwind v4 utility generator"
      via: "--color-* / --radius-* / --shadow-* / --font-* namespaces"
      pattern: "@theme inline"
---

<objective>
Rewrite `website/src/app/globals.css` (currently 27 lines of create-next-app placeholder) into the Chronicle design token source of truth: 16 palette colors + 5 radii + 3 named shadows + 3 font-family chains + light-mode lock. Every Chronicle token lands in `:root` as a raw value and is re-exported through `@theme inline` so Tailwind v4 generates `bg-paper`, `text-ink-muted`, `rounded-card`, `shadow-btn`, `font-serif`, etc. Strips the `@media (prefers-color-scheme: dark)` block entirely (DESIGN-04 layer 1) and adds `html { color-scheme: light; }` (DESIGN-04 layer 2).

Purpose: Establishes the single shared CSS surface every subsequent primitive, showcase, and phase-13/14/15 page compiles against. Without this, no primitive in Plan 03 can use `bg-paper` or `rounded-card`, and no page can trust `var(--color-ink)`.

Output: Rewritten `globals.css` with four sections -- `@import "tailwindcss"`, `:root` raw values, `@theme inline` re-exports, light-mode lock + minimal body reset.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/12-chronicle-design-system-port/12-CONTEXT.md
@.planning/phases/12-chronicle-design-system-port/12-RESEARCH.md
@.planning/phases/12-chronicle-design-system-port/12-VALIDATION.md
@design/ps-transcribe-web-unzipped/assets/tokens.css
@website/src/app/globals.css
@website/package.json

<interfaces>
<!-- Token naming: tokens.css uses bare names (--paper, --ink-muted, --r-card); -->
<!-- globals.css MUST prefix everything with Tailwind v4 namespaces (--color-paper, --color-ink-muted, --radius-card). -->
<!-- Tailwind v4 namespace -> utility mapping (from node_modules/tailwindcss/theme.css): -->
<!--   --color-*  -> bg-*, text-*, border-*, ring-*, fill-*, stroke-*, divide-*, outline-*, accent-*, caret-*, placeholder-* -->
<!--   --radius-* -> rounded-*, rounded-t-*, rounded-tl-*, etc. -->
<!--   --shadow-* -> shadow-* -->
<!--   --font-*   -> font-* (font-family only) -->

<!-- next/font variables already wired in layout.tsx (Phase 11 lock): -->
<!--   --font-inter, --font-spectral, --font-jetbrains-mono -->
<!-- globals.css composes fallback chains AROUND these via @theme inline. -->
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Rewrite globals.css with full Chronicle token set and @theme inline re-exports</name>
  <files>website/src/app/globals.css</files>
  <read_first>
    - website/src/app/globals.css (current 27-line placeholder -- see what is being replaced)
    - design/ps-transcribe-web-unzipped/assets/tokens.css (source of truth for the 16 hex values, 5 radii, 3 shadow strings; lines 1-48)
    - .planning/phases/12-chronicle-design-system-port/12-CONTEXT.md (locked decisions D-01 through D-14)
    - .planning/phases/12-chronicle-design-system-port/12-RESEARCH.md sections "Tailwind v4 @theme inline" and "next/font Fallback Chain" (exact syntax)
    - website/node_modules/tailwindcss/theme.css (verify --color-* / --radius-* / --shadow-* / --font-* namespace syntax)
    - website/src/app/layout.tsx (confirm --font-inter / --font-spectral / --font-jetbrains-mono are the existing next/font variable names -- do NOT modify this file in this task)
  </read_first>
  <action>
Replace the ENTIRE contents of `website/src/app/globals.css` with the following exact structure. Do not keep any lines from the current placeholder file (no `--background`, no `--foreground`, no `--font-geist-*`, no Arial body reset, no dark-mode media query).

Per D-01 (hybrid tokens), D-02 (full token set), D-03 (kebab-case with Tailwind-v4 prefixes), D-13 (strip dark block), D-14 (color-scheme: light on html).

```css
@import "tailwindcss";

/* Chronicle tokens -- raw values (source of truth, per D-01 + D-11) */
:root {
  /* Paper */
  --color-paper:        #FAFAF7;
  --color-paper-warm:   #F4F1EA;
  --color-paper-soft:   #EEEAE0;

  /* Rules (0.5px hairlines use these) */
  --color-rule:         rgba(30, 30, 28, 0.08);
  --color-rule-strong:  rgba(30, 30, 28, 0.14);

  /* Ink */
  --color-ink:          #1A1A17;
  --color-ink-muted:    #595954;
  --color-ink-faint:    #8A8A82;
  --color-ink-ghost:    #B8B8AF;

  /* Accents */
  --color-accent-ink:   #2B4A7A;
  --color-accent-soft:  #DFE6F0;
  --color-accent-tint:  #F1F4F9;

  /* Sage (speaker 2) */
  --color-spk2-bg:      #E6ECEA;
  --color-spk2-fg:      #2D4A43;
  --color-spk2-rail:    #7FA093;

  /* Status */
  --color-rec-red:      #C24A3E;
  --color-live-green:   #4A8A5E;

  /* Radii */
  --radius-input:       4px;
  --radius-btn:         6px;
  --radius-card:        10px;
  --radius-bubble:      12px;
  --radius-pill:        999px;

  /* Shadows -- primary button intentionally two-layer (outer drop + inset highlight) */
  --shadow-lift:        0 1px 3px rgba(30, 30, 28, 0.08);
  --shadow-btn:         0 1px 2px rgba(30, 30, 28, 0.20), inset 0 1px 0 rgba(255, 255, 255, 0.08);
  --shadow-float:       0 8px 24px rgba(30, 30, 28, 0.12), 0 1px 3px rgba(30, 30, 28, 0.06);
}

/* Tailwind v4 theme re-export -- utilities reference var() not value (per D-01) */
@theme inline {
  /* Colors -- produces bg-paper, text-ink-muted, border-rule, ring-accent-ink, etc. */
  --color-paper:        var(--color-paper);
  --color-paper-warm:   var(--color-paper-warm);
  --color-paper-soft:   var(--color-paper-soft);
  --color-rule:         var(--color-rule);
  --color-rule-strong:  var(--color-rule-strong);
  --color-ink:          var(--color-ink);
  --color-ink-muted:    var(--color-ink-muted);
  --color-ink-faint:    var(--color-ink-faint);
  --color-ink-ghost:    var(--color-ink-ghost);
  --color-accent-ink:   var(--color-accent-ink);
  --color-accent-soft:  var(--color-accent-soft);
  --color-accent-tint:  var(--color-accent-tint);
  --color-spk2-bg:      var(--color-spk2-bg);
  --color-spk2-fg:      var(--color-spk2-fg);
  --color-spk2-rail:    var(--color-spk2-rail);
  --color-rec-red:      var(--color-rec-red);
  --color-live-green:   var(--color-live-green);

  /* Radii -- produces rounded-input, rounded-btn, rounded-card, rounded-bubble, rounded-pill */
  --radius-input:       var(--radius-input);
  --radius-btn:         var(--radius-btn);
  --radius-card:        var(--radius-card);
  --radius-bubble:      var(--radius-bubble);
  --radius-pill:        var(--radius-pill);

  /* Shadows -- produces shadow-lift, shadow-btn, shadow-float */
  --shadow-lift:        var(--shadow-lift);
  --shadow-btn:         var(--shadow-btn);
  --shadow-float:       var(--shadow-float);

  /* Font families -- compose cross-platform fallback chains around next/font variables from layout.tsx (per DESIGN-02) */
  --font-sans:  var(--font-inter),          "SF Pro Text", -apple-system, system-ui, sans-serif;
  --font-serif: var(--font-spectral),       "New York",    Georgia,       serif;
  --font-mono:  var(--font-jetbrains-mono), "SF Mono",     Menlo,         monospace;
}

/* Light-mode lock (DESIGN-04 layer 2 per D-14) */
html {
  color-scheme: light;
}

/* Minimal body reset -- Tailwind preflight handles most; this sets page defaults to Chronicle */
body {
  font-family: var(--font-sans);
  color: var(--color-ink);
  background: var(--color-paper);
  font-feature-settings: "ss01", "cv11";
  -webkit-font-smoothing: antialiased;
}
```

Forbidden in this task:
- Do NOT add `@media (prefers-color-scheme: dark)` (D-13).
- Do NOT preserve `--background`, `--foreground`, `--font-geist-sans`, `--font-geist-mono`, or `font-family: Arial, Helvetica, sans-serif` from the current placeholder.
- Do NOT import or reference `chronicle-mock.css` (D-12).
- Do NOT create `tailwind.config.ts` -- Tailwind v4 is CSS-first; JS config is a v3 pattern.
- Do NOT use em dashes anywhere in the file (use `--` or rephrase).
- Do NOT modify `website/src/app/layout.tsx` in this task -- font loading and viewport are Plan 02's scope.
  </action>
  <verify>
    <automated>cd website && grep -c '^@theme inline' src/app/globals.css | grep -q '^1$' && for c in paper paper-warm paper-soft rule rule-strong ink ink-muted ink-faint ink-ghost accent-ink accent-soft accent-tint spk2-bg spk2-fg spk2-rail rec-red live-green; do grep -q "^  --color-$c:" src/app/globals.css || { echo "MISSING: --color-$c"; exit 1; }; done && for r in input btn card bubble pill; do grep -q "^  --radius-$r:" src/app/globals.css || { echo "MISSING: --radius-$r"; exit 1; }; done && for s in lift btn float; do grep -q "^  --shadow-$s:" src/app/globals.css || { echo "MISSING: --shadow-$s"; exit 1; }; done && grep -q '"SF Pro Text"' src/app/globals.css && grep -q '"New York"' src/app/globals.css && grep -q '"SF Mono"' src/app/globals.css && ! grep -q 'prefers-color-scheme' src/app/globals.css && grep -q 'color-scheme: *light' src/app/globals.css && ! grep -q 'Geist\|geist' src/app/globals.css && ! LC_ALL=C grep -l $'\xe2\x80\x94' src/app/globals.css</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c '^@theme inline' website/src/app/globals.css` outputs exactly `1`
    - All 16 `--color-*` tokens present: for c in paper paper-warm paper-soft rule rule-strong ink ink-muted ink-faint ink-ghost accent-ink accent-soft accent-tint spk2-bg spk2-fg spk2-rail rec-red live-green; grep finds `^  --color-$c:` in globals.css (no missing output)
    - All 5 `--radius-*` tokens present: input, btn, card, bubble, pill
    - All 3 `--shadow-*` tokens present: lift, btn, float
    - `--shadow-btn` contains both outer and inset layers: `grep -E 'shadow-btn:.*inset 0 1px 0' website/src/app/globals.css` matches
    - Font fallback chain present: `grep -q '"SF Pro Text"' website/src/app/globals.css` AND `grep -q '"New York"' website/src/app/globals.css` AND `grep -q '"SF Mono"' website/src/app/globals.css`
    - Dark-mode block absent: `! grep -q 'prefers-color-scheme' website/src/app/globals.css`
    - Light-mode lock present: `grep -q 'color-scheme: *light' website/src/app/globals.css`
    - No Geist references remain: `! grep -qi 'geist' website/src/app/globals.css`
    - No em dashes (portable, BSD+GNU grep compatible): `! LC_ALL=C grep -l $'\xe2\x80\x94' website/src/app/globals.css`
  </acceptance_criteria>
  <done>
globals.css is rewritten with all 16 color tokens, 5 radii, 3 shadows, 3 font-family chains, light-mode lock, and minimal body reset. No dark-mode block, no Geist references, no Arial fallback. Ready for Plan 03 primitives to consume `bg-paper`, `text-ink`, `rounded-card`, `shadow-btn` utilities.
  </done>
</task>

<task type="auto">
  <name>Task 2: Verify build compiles cleanly with rewritten globals.css</name>
  <files>(build check only, no files modified)</files>
  <read_first>
    - website/src/app/globals.css (the file just rewritten in Task 1)
    - website/package.json (confirm pnpm scripts: build, lint)
  </read_first>
  <action>
Run `cd website && pnpm run build` and capture output. The build must exit 0. Tailwind v4 must ingest the new `@theme inline` block without warnings about unknown namespaces. PostCSS must not complain about the token declarations. Next.js must compile TypeScript + route files without new errors introduced by this plan (`page.tsx` and `layout.tsx` remain untouched at this point -- Plan 02 handles layout viewport).

If the build fails, the likely causes are:
- Typo in a `:root` declaration (syntax error in a color/radius/shadow string)
- Missing semicolon or unclosed brace in `@theme inline`
- `--font-inter`, `--font-spectral`, or `--font-jetbrains-mono` referenced but not yet defined (these come from `layout.tsx` via next/font at runtime; static CSS lint should NOT flag them -- if a PostCSS warning appears about undefined custom properties, that is expected and not a build failure)

Do NOT start the dev server (`pnpm run dev`) -- it is a watch process that never exits. Use the one-shot `pnpm run build`.
  </action>
  <verify>
    <automated>cd website && pnpm run build</automated>
  </verify>
  <acceptance_criteria>
    - `cd website && pnpm run build` exits with code 0
    - No new TypeScript errors introduced (compared to pre-plan baseline)
    - No Tailwind v4 warnings about unknown `@theme inline` namespaces (`--color-*`, `--radius-*`, `--shadow-*`, `--font-*` are all canonical per node_modules/tailwindcss/theme.css)
    - Build output shows the / route still compiles (page.tsx untouched)
  </acceptance_criteria>
  <done>
Build green. globals.css rewrite is production-compilable. Plan 02 (layout viewport) and Plan 03 (primitives) can proceed against this token foundation.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| None new for this plan | This plan only rewrites static CSS tokens. No user input crosses any boundary here. Trust surface unchanged from Phase 11. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-12-01 | Tampering / XSS | `CodeBlock` children rendering | n/a (not in scope) | No `CodeBlock` component exists in this plan; mitigation owned by Plan 03. Cross-reference only for traceability. |
| T-12-02 | Information disclosure | Showcase content leaking internal strings | n/a (not in scope) | Plan 01 emits only CSS tokens and standard Tailwind utilities; no product copy or showcase content present. Owned by Plan 04. Cross-reference only. |
| T-12-03 | Tampering | next/font Google Fonts loading | accept | Already mitigated in Phase 11 via `next/font/google` which self-hosts webfonts during build (no runtime fetch from Google). This plan does not change font loading -- it only composes fallback chains in `@theme inline`. No new supply-chain surface introduced. |
</threat_model>

<verification>
After both tasks complete:
- `cd website && pnpm run build` exits 0
- All grep probes in acceptance_criteria pass
- globals.css is the single authoritative source of Chronicle tokens; no other CSS file in `/website` defines `--color-*`, `--radius-*`, or `--shadow-*` values
</verification>

<success_criteria>
- 16 Chronicle palette colors, 5 radii, 3 named shadows, and 3 font-family chains all declared in `globals.css` under the Tailwind v4 namespaces
- `@theme inline` re-exports every token so `bg-paper`, `text-ink-muted`, `rounded-card`, `shadow-btn`, `font-serif`, etc. become usable Tailwind utilities in Plan 03+
- Dark-mode media query removed; `html { color-scheme: light; }` locks native UA controls to light
- `pnpm run build` green
</success_criteria>

<output>
After completion, create `.planning/phases/12-chronicle-design-system-port/12-01-SUMMARY.md` with:
- What was rewritten (exact before/after line count in globals.css)
- Every token name present with its raw value
- Any build warnings encountered + resolution
- Confirmation: no dark-mode block anywhere, color-scheme: light present
- Next step: Plan 02 adds viewport export; Plan 03 builds primitives against these tokens
</output>
</content>
