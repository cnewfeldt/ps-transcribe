---
phase: 12
plan: 04
type: execute
wave: 3
depends_on: [12-01, 12-02, 12-03]
files_modified:
  - website/src/app/design-system/page.tsx
autonomous: true
requirements: [DESIGN-01, DESIGN-03, DESIGN-04]
must_haves:
  truths:
    - "/design-system route renders in the production build"
    - "Page displays a palette grid with all 16 Chronicle color tokens labeled with name + hex + var(--color-*) reference"
    - "Page displays a primitive gallery with Button (primary + secondary), Card, MetaLabel, SectionHeading (one example), CodeBlock (inline + block)"
    - "Page displays a typography-scale Card at the top showing hero / section / feature / body sizes using the brief's voice copy"
    - "Page emits <meta name=\"robots\" content=\"noindex, nofollow\"> in production HTML"
    - "/design-system is NOT listed in sitemap.ts"
    - "Production HTML of / emits <meta name=\"color-scheme\" content=\"light\">"
  artifacts:
    - path: website/src/app/design-system/page.tsx
      provides: "Design-system showcase route at /design-system"
      contains: "robots: { index: false, follow: false }"
  key_links:
    - from: "website/src/app/design-system/page.tsx"
      to: "website/src/components/ui (barrel)"
      via: "import { Button, Card, MetaLabel, SectionHeading, CodeBlock } from '@/components/ui'"
      pattern: "from '@/components/ui'"
    - from: "website/src/app/design-system/page.tsx metadata export"
      to: "Next.js 16 generateMetadata merging"
      via: "page-level metadata.robots overrides root layout's robots"
      pattern: "robots: { index: false"
---

<objective>
Create the `/design-system` showcase route at `website/src/app/design-system/page.tsx`. The page is the visual proof surface for Phase 12: it renders every Chronicle palette color as a swatch, exercises each primitive's variants, and displays the typography scale using the brief's voice copy. It exports its own `metadata` with `robots: { index: false, follow: false }` so search engines skip it (D-09), and `sitemap.ts` remains unchanged so the URL is not advertised. Reachable if you know the path; invisible to crawlers.

Purpose: Goal-backward proof that Plans 01-03 integrated correctly. If any token, utility, or primitive is broken, this page surfaces it visually. Also serves as the reference every Phase 13/14/15 page inherits visual parity from.

Output: One new file at `website/src/app/design-system/page.tsx`. Plus a browser-eye + curl verification cycle on the production build.
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
@website/src/app/globals.css
@website/src/app/sitemap.ts

<interfaces>
<!-- After Plans 01, 02, 03 ship, these are available: -->
<!--   - All 16 Tailwind color utilities: bg-paper, bg-paper-warm, bg-paper-soft, bg-rule, bg-rule-strong, bg-ink, bg-ink-muted, bg-ink-faint, bg-ink-ghost, bg-accent-ink, bg-accent-soft, bg-accent-tint, bg-spk2-bg, bg-spk2-fg, bg-spk2-rail, bg-rec-red, bg-live-green -->
<!--   - text-* and border-* counterparts -->
<!--   - rounded-card, rounded-btn, rounded-pill, shadow-lift, shadow-btn, shadow-float -->
<!--   - font-sans, font-serif, font-mono -->
<!--   - @/components/ui barrel exports: Button, Card, MetaLabel, SectionHeading, CodeBlock -->

<!-- Next.js 16 page metadata API (node_modules/next/dist/docs/.../generate-metadata.md): -->
<!--   export const metadata: Metadata = { title, robots: { index, follow }, ... } -->
<!-- Page-level metadata merges with root layout metadata; nested fields are overwritten by the last segment. -->
<!-- So page's robots: { index: false, follow: false } overrides root layout's robots: { index: true, follow: true }. -->

<!-- Current sitemap.ts returns only the root URL. DO NOT modify it -- D-09 requires /design-system to stay unlisted. -->

<!-- The 16 palette tokens and their hex values (source: Plan 01 :root block): -->
<!--   paper #FAFAF7, paper-warm #F4F1EA, paper-soft #EEEAE0 -->
<!--   rule rgba(30,30,28,0.08), rule-strong rgba(30,30,28,0.14) -->
<!--   ink #1A1A17, ink-muted #595954, ink-faint #8A8A82, ink-ghost #B8B8AF -->
<!--   accent-ink #2B4A7A, accent-soft #DFE6F0, accent-tint #F1F4F9 -->
<!--   spk2-bg #E6ECEA, spk2-fg #2D4A43, spk2-rail #7FA093 -->
<!--   rec-red #C24A3E, live-green #4A8A5E -->
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create /design-system showcase page with palette grid, primitive gallery, and typography scale</name>
  <files>website/src/app/design-system/page.tsx</files>
  <read_first>
    - website/src/components/ui/index.ts (Plan 03 barrel; confirm available exports)
    - website/src/components/ui/Button.tsx, Card.tsx, MetaLabel.tsx, SectionHeading.tsx, CodeBlock.tsx (Plan 03 outputs; confirm prop APIs)
    - website/src/app/globals.css (Plan 01 output; confirm utility names)
    - website/src/app/sitemap.ts (confirm /design-system is NOT listed; do NOT modify)
    - website/node_modules/next/dist/docs/01-app/03-api-reference/04-functions/generate-metadata.md (robots field syntax -- line ~551)
    - .planning/phases/12-chronicle-design-system-port/12-CONTEXT.md (D-08 new route, D-09 noindex + sitemap exclusion, D-10 showcase content, Specifics "showcase demo content should quote the brief's own voice")
    - .planning/phases/12-chronicle-design-system-port/12-RESEARCH.md section "Showcase Route Setup"
    - .planning/research/CLAUDE-DESIGN-BRIEF.md sections Typography (hero 48-56px / section 28-32px / feature 24-28px / body 15-16px sans) and Tone of voice (example: "Records both sides of your Zoom call, locally.")
  </read_first>
  <action>
Create the directory `website/src/app/design-system/` and then create `website/src/app/design-system/page.tsx` with the exact content below. This is a server component -- no `"use client"`. Imports are from Plan 03's barrel.

```tsx
import type { Metadata } from 'next'
import {
  Button,
  Card,
  CodeBlock,
  MetaLabel,
  SectionHeading,
} from '@/components/ui'

export const metadata: Metadata = {
  title: 'Design System',
  robots: {
    index: false,
    follow: false,
  },
}

type Swatch = {
  name: string
  hex: string
  textClass: string // so we pick a readable label color per swatch
}

const palette: Array<{ group: string; swatches: Swatch[] }> = [
  {
    group: 'Paper',
    swatches: [
      { name: 'paper', hex: '#FAFAF7', textClass: 'text-ink' },
      { name: 'paper-warm', hex: '#F4F1EA', textClass: 'text-ink' },
      { name: 'paper-soft', hex: '#EEEAE0', textClass: 'text-ink' },
    ],
  },
  {
    group: 'Rules',
    swatches: [
      { name: 'rule', hex: 'rgba(30,30,28,0.08)', textClass: 'text-ink' },
      { name: 'rule-strong', hex: 'rgba(30,30,28,0.14)', textClass: 'text-ink' },
    ],
  },
  {
    group: 'Ink',
    swatches: [
      { name: 'ink', hex: '#1A1A17', textClass: 'text-paper' },
      { name: 'ink-muted', hex: '#595954', textClass: 'text-paper' },
      { name: 'ink-faint', hex: '#8A8A82', textClass: 'text-paper' },
      { name: 'ink-ghost', hex: '#B8B8AF', textClass: 'text-ink' },
    ],
  },
  {
    group: 'Accents',
    swatches: [
      { name: 'accent-ink', hex: '#2B4A7A', textClass: 'text-paper' },
      { name: 'accent-soft', hex: '#DFE6F0', textClass: 'text-ink' },
      { name: 'accent-tint', hex: '#F1F4F9', textClass: 'text-ink' },
    ],
  },
  {
    group: 'Sage (Speaker 2)',
    swatches: [
      { name: 'spk2-bg', hex: '#E6ECEA', textClass: 'text-ink' },
      { name: 'spk2-fg', hex: '#2D4A43', textClass: 'text-paper' },
      { name: 'spk2-rail', hex: '#7FA093', textClass: 'text-paper' },
    ],
  },
  {
    group: 'Status',
    swatches: [
      { name: 'rec-red', hex: '#C24A3E', textClass: 'text-paper' },
      { name: 'live-green', hex: '#4A8A5E', textClass: 'text-paper' },
    ],
  },
]

export default function DesignSystemPage() {
  return (
    <main className="bg-paper text-ink min-h-dvh">
      <div className="mx-auto max-w-[1200px] px-10 py-16 md:py-24">
        <header className="mb-16">
          <MetaLabel>Phase 12 -- Chronicle design system</MetaLabel>
          <SectionHeading as="h1" className="mt-3 text-[clamp(36px,4.5vw,52px)]">
            The quiet chronicle, ported to the web.
          </SectionHeading>
          <p className="mt-4 max-w-[54ch] font-sans text-[17px] leading-[1.55] text-ink-muted">
            Records both sides of your Zoom call, locally. This page exists to verify the
            palette, primitives, and typography render with the same editorial calm as the
            macOS app. Not indexed. Not linked from the site.
          </p>
        </header>

        <section className="mb-16">
          <MetaLabel>Typography scale</MetaLabel>
          <Card className="mt-3">
            <div className="space-y-6">
              <div>
                <MetaLabel>Hero -- Spectral</MetaLabel>
                <p className="mt-2 font-serif text-[clamp(40px,5.2vw,56px)] leading-[1.08] tracking-[-0.015em] text-ink">
                  Transcription that stays on your machine.
                </p>
              </div>
              <div>
                <MetaLabel>Section -- Spectral</MetaLabel>
                <p className="mt-2 font-serif text-[clamp(26px,3vw,32px)] leading-[1.15] tracking-[-0.01em] text-ink">
                  One recording, two clean streams.
                </p>
              </div>
              <div>
                <MetaLabel>Feature -- Spectral</MetaLabel>
                <p className="mt-2 font-serif text-[clamp(22px,2.4vw,26px)] leading-[1.2] tracking-[-0.005em] text-ink">
                  Save to the vault, auto-send to the database.
                </p>
              </div>
              <div>
                <MetaLabel>Body -- Inter</MetaLabel>
                <p className="mt-2 font-sans text-[15px] leading-[1.65] text-ink-muted max-w-[54ch]">
                  PS Transcribe is a native macOS app for private, on-device transcription of
                  meetings and voice memos. Everything runs locally -- no cloud APIs, no
                  telemetry, no LLM analysis of transcript content.
                </p>
              </div>
            </div>
          </Card>
        </section>

        <section className="mb-16">
          <MetaLabel>Palette</MetaLabel>
          <SectionHeading className="mt-3">Sixteen tokens, light mode only.</SectionHeading>
          <div className="mt-6 space-y-8">
            {palette.map((group) => (
              <div key={group.group}>
                <MetaLabel>{group.group}</MetaLabel>
                <div className="mt-3 grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
                  {group.swatches.map((s) => (
                    <div
                      key={s.name}
                      className={`bg-${s.name} ${s.textClass} border-[0.5px] border-rule rounded-card p-4`}
                      style={{ backgroundColor: `var(--color-${s.name})` }}
                    >
                      <div className="font-mono text-[11px] tracking-[0.04em]">{s.name}</div>
                      <div className="mt-1 font-mono text-[11px] tracking-[0.04em] opacity-70">
                        {s.hex}
                      </div>
                      <div className="mt-2 font-mono text-[10px] tracking-[0.04em] opacity-50">
                        var(--color-{s.name})
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </section>

        <section className="mb-16">
          <MetaLabel>Primitives</MetaLabel>
          <SectionHeading className="mt-3">Five components, one surface.</SectionHeading>

          <div className="mt-6 space-y-10">
            <div>
              <MetaLabel>Button</MetaLabel>
              <div className="mt-3 flex flex-wrap items-center gap-3">
                <Button variant="primary">Download for macOS</Button>
                <Button variant="secondary">View on GitHub</Button>
              </div>
            </div>

            <div>
              <MetaLabel>Card</MetaLabel>
              <div className="mt-3">
                <Card>
                  <MetaLabel>Private by default</MetaLabel>
                  <SectionHeading as="h3" className="mt-2 text-[clamp(22px,2.4vw,26px)]">
                    No cloud, no telemetry.
                  </SectionHeading>
                  <p className="mt-3 font-sans text-[15px] leading-[1.65] text-ink-muted max-w-[54ch]">
                    Speech recognition runs on-device through a local FluidAudio model. Your
                    meeting audio never leaves the machine.
                  </p>
                </Card>
              </div>
            </div>

            <div>
              <MetaLabel>MetaLabel</MetaLabel>
              <div className="mt-3 flex flex-wrap items-center gap-6">
                <MetaLabel>Features</MetaLabel>
                <MetaLabel>Changelog</MetaLabel>
                <MetaLabel>Apr 20, 2026</MetaLabel>
              </div>
            </div>

            <div>
              <MetaLabel>SectionHeading</MetaLabel>
              <div className="mt-3">
                <SectionHeading>Records both sides of your call.</SectionHeading>
              </div>
            </div>

            <div>
              <MetaLabel>CodeBlock</MetaLabel>
              <div className="mt-3 space-y-4">
                <p className="font-sans text-[15px] leading-[1.65] text-ink-muted">
                  Inline: press <CodeBlock inline>{'\u2318R'}</CodeBlock> to start a meeting
                  recording, or <CodeBlock inline>{'\u2318\u21e7R'}</CodeBlock> for a voice
                  memo.
                </p>
                <CodeBlock>{`import { Button } from '@/components/ui'

export function CTA() {
  return <Button variant="primary">Download for macOS</Button>
}`}</CodeBlock>
              </div>
            </div>
          </div>
        </section>

        <footer className="mt-24 border-t-[0.5px] border-rule pt-8">
          <MetaLabel>Not indexed. Not in sitemap.</MetaLabel>
          <p className="mt-2 font-sans text-[13px] leading-[1.6] text-ink-faint max-w-[54ch]">
            This page is reachable only if you know the URL. Search engines receive a
            noindex, nofollow signal and sitemap.ts does not list it.
          </p>
        </footer>
      </div>
    </main>
  )
}
```

Implementation notes / rationale:
- Path alias: imports use `@/components/ui` which resolves to `./src/components/ui/index.ts` per tsconfig.json paths.
- Swatch rendering: uses inline `style={{ backgroundColor: 'var(--color-${s.name})' }}` so the 16 swatches render even if Tailwind's JIT misses any dynamic `bg-${s.name}` utility. This is defensive -- the styling purpose is verification, so we use CSS custom properties directly (D-01 allows both and verifies they resolve to the same value).
- Typography card uses inline Tailwind arbitrary values (`text-[clamp(...)]`, `leading-[...]`, `tracking-[...]`) to match chronicle-mock.css `.h-hero`, `.h-section`, `.h-feature`, `.lede` declarations literally.
- Copy draws exclusively from the brief's voice examples ("Records both sides of your Zoom call, locally.", "No cloud, no telemetry.", "Private by default"). No Lorem ipsum. No em dashes -- uses `--` or rephrases.
- The Unicode escapes `\u2318` (cmd) and `\u21e7` (shift) appear inside the CodeBlock inline demo so the literal keyboard glyphs render without needing the literal chars in the source (belt-and-suspenders against any editor mangling; the literal chars are also fine).
- No `Metadata` import for `title`: we pass a simple string which Next will plug into the root layout's title template `%s · PS Transcribe` → "Design System · PS Transcribe".

Forbidden in this task:
- Do NOT modify `website/src/app/sitemap.ts` (D-09: must not list /design-system).
- Do NOT modify `website/src/app/page.tsx` (D-08 + Specifics: Phase 13 rewrites it; touching it in Phase 12 is churn).
- Do NOT modify `website/src/app/layout.tsx` (Plan 02 owns that; any needed viewport work is done there).
- Do NOT add `"use client"` (pure presentational page).
- Do NOT use `dangerouslySetInnerHTML` for the CodeBlock content.
- Do NOT use em dashes (`—`). Use `--` or rephrase.
- Do NOT add /design-system to any sitemap or robots.ts file.
  </action>
  <verify>
    <automated>cd website && test -f src/app/design-system/page.tsx && grep -q "from '@/components/ui'" src/app/design-system/page.tsx && grep -q "Button" src/app/design-system/page.tsx && grep -q "Card" src/app/design-system/page.tsx && grep -q "MetaLabel" src/app/design-system/page.tsx && grep -q "SectionHeading" src/app/design-system/page.tsx && grep -q "CodeBlock" src/app/design-system/page.tsx && grep -Eq "bg-(paper|ink|accent-ink|spk2-bg)" src/app/design-system/page.tsx && grep -q "index: *false" src/app/design-system/page.tsx && grep -q "follow: *false" src/app/design-system/page.tsx && ! grep -q "design-system" src/app/sitemap.ts && ! grep -P '\x{2014}' src/app/design-system/page.tsx && ! grep -n "^['\"]use client['\"]" src/app/design-system/page.tsx && ! grep -q "dangerouslySetInnerHTML" src/app/design-system/page.tsx && pnpm run build</automated>
  </verify>
  <acceptance_criteria>
    - Page file exists: `test -f website/src/app/design-system/page.tsx`
    - Imports from barrel: `grep -q "from '@/components/ui'" website/src/app/design-system/page.tsx`
    - All 5 primitives referenced: grep finds Button AND Card AND MetaLabel AND SectionHeading AND CodeBlock in the page
    - Palette utility used: `grep -Eq "bg-(paper|ink|accent-ink|spk2-bg)" website/src/app/design-system/page.tsx`
    - Noindex metadata present: `grep -q "index: *false" website/src/app/design-system/page.tsx && grep -q "follow: *false" website/src/app/design-system/page.tsx`
    - Sitemap unchanged: `! grep -q "design-system" website/src/app/sitemap.ts`
    - No em dashes: `! grep -P '\x{2014}' website/src/app/design-system/page.tsx`
    - Server component: `! grep -n "^['\"]use client['\"]" website/src/app/design-system/page.tsx`
    - No dangerouslySetInnerHTML: `! grep -q "dangerouslySetInnerHTML" website/src/app/design-system/page.tsx`
    - `cd website && pnpm run build` exits 0
  </acceptance_criteria>
  <done>
`/design-system` route file compiles and renders palette + primitives + typography. Build is green. Page metadata emits noindex/nofollow. Sitemap is unchanged. Ready for the production HTML probes in Task 2.
  </done>
</task>

<task type="auto">
  <name>Task 2: Production HTML probes against built site (robots + color-scheme + primitive DOM signatures)</name>
  <files>(no files modified -- verification only)</files>
  <read_first>
    - .planning/phases/12-chronicle-design-system-port/12-VALIDATION.md Per-Task Verification Map rows 12-02-02, 12-04-06, 12-04-07
    - website/src/app/design-system/page.tsx (the file just created in Task 1)
    - website/src/app/layout.tsx (to confirm viewport export from Plan 02)
  </read_first>
  <action>
This task verifies that the final production HTML carries the signals Plans 02 and 04 promised. It runs `pnpm run build`, starts the production server in the background with `pnpm run start` on port 3000, curls three URLs, greps for the required `<meta>` tags and DOM class signatures, then kills the server.

Commands to run (adjust only if port 3000 is occupied; check with `lsof -i :3000` first):

```bash
cd website
pnpm run build

# Start production server in the background
pnpm run start &
SERVER_PID=$!

# Give Next a moment to bind the port (poll, do not sleep-and-hope)
for i in 1 2 3 4 5 6 7 8 9 10; do
  curl -fsS http://localhost:3000/ > /dev/null 2>&1 && break
  sleep 1
done

# Probe 1: root page emits color-scheme meta (DESIGN-04 layer 3 / Plan 02 verify)
curl -s http://localhost:3000/ | grep -q 'name="color-scheme" content="light"' \
  || { echo "FAIL: no color-scheme meta on /"; kill $SERVER_PID; exit 1; }

# Probe 2: /design-system emits noindex (D-09 / Plan 04 verify)
curl -s http://localhost:3000/design-system | grep -q 'name="robots" content="noindex' \
  || { echo "FAIL: /design-system missing noindex meta"; kill $SERVER_PID; exit 1; }

# Probe 3: /design-system renders primitive DOM signatures (bg-ink / border-rule / rounded-card etc.)
DOM_HITS=$(curl -s http://localhost:3000/design-system | grep -Ec 'class="[^"]*(bg-ink|text-ink-faint|border-rule|rounded-card)')
if [ "$DOM_HITS" -lt 5 ]; then
  echo "FAIL: design-system page missing primitive DOM signatures (found $DOM_HITS, expected >=5)"
  kill $SERVER_PID
  exit 1
fi

# Kill the server
kill $SERVER_PID
wait $SERVER_PID 2>/dev/null

echo "All probes green."
```

If Probe 1 fails: check `website/src/app/layout.tsx` for `export const viewport: Viewport = { colorScheme: 'light' }`. Plan 02 owns this; if it is missing, return to Plan 02 verification.

If Probe 2 fails: check `website/src/app/design-system/page.tsx` metadata export for `robots: { index: false, follow: false }`.

If Probe 3 fails: the primitives are not being rendered, or Tailwind's JIT did not generate the utilities. Check that Plan 03's primitive files have the literal class strings listed in their acceptance criteria.

Do NOT leave the `pnpm run start` process running. The `kill $SERVER_PID` at the end is mandatory -- a dangling server would block port 3000 for the next task.

Do NOT modify any source file in this task. All three failure modes above point back to earlier plans (02 or 03) for remediation; this task is read-only verification.
  </action>
  <verify>
    <automated>cd website && pnpm run build && (pnpm run start & SERVER_PID=$!; for i in 1 2 3 4 5 6 7 8 9 10; do curl -fsS http://localhost:3000/ > /dev/null 2>&1 && break; sleep 1; done; R1=$(curl -s http://localhost:3000/ | grep -c 'name="color-scheme" content="light"'); R2=$(curl -s http://localhost:3000/design-system | grep -c 'name="robots" content="noindex'); R3=$(curl -s http://localhost:3000/design-system | grep -Ec 'class="[^"]*(bg-ink|text-ink-faint|border-rule|rounded-card)'); kill $SERVER_PID; wait $SERVER_PID 2>/dev/null; test "$R1" -ge 1 && test "$R2" -ge 1 && test "$R3" -ge 5)</automated>
  </verify>
  <acceptance_criteria>
    - `curl -s http://localhost:3000/` returns HTML containing `name="color-scheme" content="light"` at least once (DESIGN-04 layer 3)
    - `curl -s http://localhost:3000/design-system` returns HTML containing `name="robots" content="noindex` at least once (D-09)
    - `curl -s http://localhost:3000/design-system | grep -Ec 'class="[^"]*(bg-ink|text-ink-faint|border-rule|rounded-card)'` returns >= 5 (primitives rendered)
    - Server process killed at end of task (no dangling `pnpm run start` on port 3000)
    - Build completed successfully as part of this task's run
  </acceptance_criteria>
  <done>
Production HTML verified end-to-end: color-scheme meta is emitted, /design-system is noindexed, primitive DOM signatures render. Phase 12 success criteria 1-4 are all covered.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Public web → `/design-system` route | The route is publicly reachable (just not indexed or advertised). Any content leaked here is effectively public. |
| `CodeBlock` children boundary | The showcase renders static strings only; no user input flows in. In Phases 14/15 this boundary becomes active when MDX authors and CHANGELOG.md feed content. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-12-02 | Information disclosure | `/design-system` page content | mitigate | Showcase copy uses only the brief's public voice examples ("Records both sides of your Zoom call, locally.", "No cloud, no telemetry.", "Private by default"). No internal URLs, no API keys, no credentials, no unreleased product strings. Plus `robots: { index: false, follow: false }` signals crawlers to skip the URL (defense in depth; not relied upon as the sole control). |
| T-12-01 | Tampering / XSS | `CodeBlock` rendering within showcase | mitigate | Page passes static string literals to `CodeBlock`. `CodeBlock` itself (Plan 03) forbids `dangerouslySetInnerHTML`. Verified by acceptance_criteria grep. |
</threat_model>

<verification>
- Task 1: `cd website && pnpm run build` exits 0; all grep probes in Task 1 acceptance_criteria pass.
- Task 2: Production server cycle passes all three curl probes; server process cleanly terminated.
- Manual browser check (optional, not blocking): visit the Vercel preview URL on the PR and confirm swatches render with correct backgrounds, hairlines are visible, primary button shows the two-layer shadow, MetaLabel is 10px uppercase mono.
</verification>

<success_criteria>
- `/design-system` renders with palette grid (16 swatches), primitive gallery (Button primary+secondary, Card, MetaLabel, SectionHeading, CodeBlock inline+block), and typography scale
- `<meta name="robots" content="noindex, nofollow">` appears in `/design-system` HTML
- `<meta name="color-scheme" content="light">` appears in `/` HTML
- `sitemap.ts` remains unchanged (does not list /design-system)
- Build green; production server cycle green
</success_criteria>

<output>
After completion, create `.planning/phases/12-chronicle-design-system-port/12-04-SUMMARY.md` with:
- Confirmation of all 16 swatches rendered with correct var(--color-*) backing
- Confirmation of noindex meta emission (quote the HTML line from Probe 2)
- Confirmation of color-scheme meta emission (quote the HTML line from Probe 1)
- Primitive DOM signature count (quote the integer from Probe 3)
- Phase 12 success criteria 1-4 checklist (all must be checked)
- Next step: Phase 12 complete; ready for /gsd-verify-work
</output>
</content>
</invoke>