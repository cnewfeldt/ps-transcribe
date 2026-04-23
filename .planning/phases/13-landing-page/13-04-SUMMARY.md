---
phase: 13-landing-page
plan: 04
subsystem: ui
tags: [nextjs, server-components, jsx, tailwind, mocks, feature-section]

requires:
  - phase: 13-landing-page
    plan: 01
    provides: SITE constants, getLatestRelease helper (not consumed by this plan; reserved for Plan 05 composition)
  - phase: 13-landing-page
    plan: 02
    provides: Reveal wrapper (consumed by FeatureBlock), MetaLabel primitive (consumed by FeatureBlock)
  - phase: 12-chronicle-design-system-port
    provides: Chronicle tokens (bg-paper, bg-paper-warm, bg-accent-tint, bg-spk2-bg, text-accent-ink, text-spk2-fg, bg-spk2-rail, border-rule, border-rule-strong, shadow-lift, font-sans/serif/mono)

provides:
  - FeatureBlock -- reusable section component with tint ("default" | "tint" | "sage") + metaTone ("default" | "navy" | "sage") + alternating layout via index % 2
  - MockWindow -- shared mini-mockup chrome (traffic-light dots + centered mono title; hex values hardcoded per macOS-control source)
  - DualStreamMock -- Feature 1 visual; two 12-bar meter columns (mic/sys audio) + VAD/Parakeet footer line
  - ChatBubbleMock -- Feature 2 visual; three bubbles (them/me/them); sage rail on "them" bubbles; ink-bg on "me" bubble
  - ObsidianVaultMock -- Feature 3 visual; 160px tree + YAML-frontmatter file pane; YAML keys (date/duration/participants/tags) in accent-ink
  - NotionTableMock -- Feature 4 visual; 3-row database table; last row highlighted via isNew flag (accent-tint bg + accent-ink fg)
  - Tint + MetaTone type exports on FeatureBlock for Plan 05 consumers

affects: [13-05 shortcuts-and-final-cta]

tech-stack:
  added: []
  patterns:
    - "Shared mock chrome via MockWindow helper -- extracted once, consumed 4 times, matches D-specifics permission for 3+ mocks sharing chrome"
    - "Server-only mocks -- zero runtime JS for visual content; all four mocks are pure JSX with no 'use client' directive"
    - "lg-scoped order-* for alternating feature layout (`order-1 lg:order-1|2`, `order-2 lg:order-2|1`) -- mobile always renders copy-first (heading-first reading flow), alternation kicks in at lg+"
    - "Traffic-light hex colors hardcoded (not Chronicle tokens) -- these are macOS window-control colors, not brand; ported verbatim from chronicle-mock.css lines 90-93"
    - "Inline percentage-height styles on bar spans -- 12 values per column is unwieldy as Tailwind arbitrary-value classes; inline style is the right tool and keeps the data/presentation boundary clean"
    - "Explicit {'\\n'} text children inside <pre> for ObsidianVaultMock -- JSX collapses bare newlines between sibling elements, so template-literal newlines are needed to preserve the YAML-block line breaks while still allowing <span> elements to wrap the accent-ink keys"
    - "Client/server split: FeatureBlock is server BUT consumes Reveal (client); Next's RSC boundary handles the transition automatically since Reveal is imported, not inlined"

key-files:
  created:
    - website/src/components/mocks/MockWindow.tsx
    - website/src/components/sections/FeatureBlock.tsx
    - website/src/components/mocks/DualStreamMock.tsx
    - website/src/components/mocks/ChatBubbleMock.tsx
    - website/src/components/mocks/ObsidianVaultMock.tsx
    - website/src/components/mocks/NotionTableMock.tsx
  modified: []

key-decisions:
  - "Shared MockWindow extracted preemptively -- all four mocks share titlebar chrome (traffic-light dots + centered title); extraction is explicitly permitted by D-specifics when 3+ mocks share and saves ~25 duplicated lines across the four mock files"
  - "FeatureBlock wraps whole block in <Reveal> at the section level (not per-element) -- a single observer per feature is more efficient than per-child observers and matches the mock's scroll-reveal semantics"
  - "Bar heights are inline style={{ height: `${h}%` }} instead of Tailwind arbitrary-value classes -- Tailwind's JIT can generate arbitrary heights but producing 12 distinct classes per column makes the intent opaque; the array-driven inline-style pattern keeps data at module scope and presentation at render site"
  - "ObsidianVaultMock uses explicit {'\\n'} text children + <span> elements inside <pre> (whitespace-pre-wrap) -- the plan's literal code block would collapse JSX newlines; the explicit-newline pattern preserves the YAML fence alignment and lets accent-ink keys render inline"
  - "Traffic-light dot hex values hardcoded (#EC6A5F / #F5BF4F / #61C554) -- chronicle-mock.css comment notes these are macOS control colors, not brand tokens; hardcoding is correct"

requirements-completed: [LAND-04]

duration: 3min 29s
completed: 2026-04-23
---

# Phase 13 Plan 04: Landing Page -- Feature Blocks + Mini-Mockups Summary

**Shipped the FeatureBlock section component and the four mini-mockups (DualStream, ChatBubble, ObsidianVault, Notion) that visualize each feature. All six files are server components; typecheck is clean; LAND-04 surface is fully in place and ready for Plan 05 to compose in page.tsx.**

## Performance

- **Duration:** ~3m 29s (executor run; 2026-04-23T07:45:36Z -> 2026-04-23T07:49:05Z)
- **Started:** 2026-04-23T07:45:36Z
- **Completed:** 2026-04-23T07:49:05Z
- **Tasks:** 2
- **Files created:** 6

## Accomplishments

### Task 1: FeatureBlock + MockWindow + DualStreamMock

- **`website/src/components/mocks/MockWindow.tsx`** (38 lines) -- Server component; shared titlebar chrome for all four feature mocks. Renders a 24px gradient bar with three 8px traffic-light dots (red #EC6A5F, yellow #F5BF4F, green #61C554 -- macOS-control hex values, not Chronicle tokens) plus a JetBrains Mono 10px centered title. Titlebar carries `aria-hidden` so screen readers skip the decorative chrome. `overflow-hidden` + `rounded-[8px]` on the outer frame gives the rounded-window aesthetic without needing per-mock radius overrides.
- **`website/src/components/sections/FeatureBlock.tsx`** (84 lines) -- Server component; reusable two-column section with tint + metaTone + alternating-layout props. Wraps the entire block in `<Reveal>` so it fades in on first scroll intersection. Exports `Tint` (`'default' | 'tint' | 'sage'`) and `MetaTone` (`'default' | 'navy' | 'sage'`) as named types so Plan 05 can type-literal the feature array safely. Alternation lives in `lg:order-*` utilities only -- mobile (<`lg`) always renders copy before mock so the heading-first reading flow stays intact.
- **`website/src/components/mocks/DualStreamMock.tsx`** (56 lines) -- Server component. Consumes MockWindow with the title `Session · 00:14:32`. Two StreamCard children (Microphone/You navy, System audio/Speaker 2 sage) each render 12 bars with heights drawn from module-scope arrays (MIC_BARS, SYS_BARS) ported verbatim from the mock's inline-style values. Bars are inline-styled `height: {n}%` + `opacity: 0.55`. No animation-delay anywhere (D-11 enforced). Footer `<hr>` + two mono spans carry the `VAD · trimming silences` / `Parakeet-TDT · on-device` captions.

### Task 2: ChatBubbleMock + ObsidianVaultMock + NotionTableMock

- **`website/src/components/mocks/ChatBubbleMock.tsx`** (73 lines) -- Server component. Title `Chronicle · Transcript`. Renders three chat bubbles from a typed `BUBBLES` array: Speaker 2 (them) on the left with sage bg + sage rail, You (me) on the right with ink bg + paper fg, Speaker 2 (them) again. Each bubble carries its original max-width (85% / 70% / 82%) as an inline style so the visual weight matches the source mock. Copy ported verbatim -- em-dashes, curly apostrophes, and sentence ordering all preserved.
- **`website/src/components/mocks/ObsidianVaultMock.tsx`** (65 lines) -- Server component. Title `Obsidian · Vault`. Two-column grid: 160px mono tree pane on the left (Vault / Meetings / 2026-04-20.md / 2026-04-22.md [active] / Memos / standups.md) with the active file highlighted via accent-tint bg + accent-ink fg, and a file pane on the right with a YAML `<pre>` + a Spectral serif heading + three diarized speaker-quote paragraphs. YAML keys (date, duration, participants, tags) are each wrapped in `<span className="text-accent-ink">` inside the `<pre>` so they render in navy-ink while the values stay ink-muted. Line breaks inside the `<pre>` are explicit `{'\n'}` text children -- JSX collapses bare newlines between sibling elements, so template-literal newlines are required to preserve the YAML fence alignment.
- **`website/src/components/mocks/NotionTableMock.tsx`** (74 lines) -- Server component. Title `Notion · Meetings DB`. Header row with "Name" / "4 properties" in mono 10px uppercase. A `<table>` with three `<tr>` rows drawn from a typed `ROWS` array (Infra planning, Design review, Product sync -- Apr 22). The last row carries `isNew: true` and renders with `bg-accent-tint` on the `<tr>` plus `text-accent-ink` + `font-medium` on the name cell; the non-new rows use `text-ink` / `text-ink-muted`. Tag cells render a sage pill (`bg-spk2-bg text-spk2-fg`) with the `meeting` / `design` / `product` tag string.

## Task Commits

Each task was committed atomically with `--no-verify` (parallel executor flag):

1. **Task 1: FeatureBlock + MockWindow + DualStreamMock** -- `691b72e` (feat)
2. **Task 2: ChatBubble, ObsidianVault, NotionTable mocks** -- `9ed6a1c` (feat)

Plan metadata (this SUMMARY) will be committed by the orchestrator after wave aggregation.

## Files Created / Modified

| Path | Lines | Kind | Role |
|---|---|---|---|
| `website/src/components/mocks/MockWindow.tsx` | 38 | created | Shared titlebar chrome (4 consumers) |
| `website/src/components/sections/FeatureBlock.tsx` | 84 | created | Reusable 2-col section with tint + alternation |
| `website/src/components/mocks/DualStreamMock.tsx` | 56 | created | Feature 1 visual |
| `website/src/components/mocks/ChatBubbleMock.tsx` | 73 | created | Feature 2 visual |
| `website/src/components/mocks/ObsidianVaultMock.tsx` | 65 | created | Feature 3 visual |
| `website/src/components/mocks/NotionTableMock.tsx` | 74 | created | Feature 4 visual |
| **Total** | **390** | 6 new files | -- |

Every min-lines acceptance criterion met (MockWindow >=20, FeatureBlock >=60, DualStream >=45, ChatBubble >=40, Obsidian >=60, Notion >=40).

## Design Decisions

- **Shared MockWindow was worth the extraction.** All four mocks carry the same titlebar pattern (3 traffic-light dots + centered mono title). CONTEXT D-specifics explicitly permit extraction at 3+ consumers, and the alternative (inlining the 14-line titlebar markup into each mock) would duplicate ~56 lines of JSX with zero flexibility gain.
- **Mobile-safe order utilities.** `FeatureBlock.tsx` uses `order-1 lg:order-1` / `order-1 lg:order-2` / `order-2 lg:order-2` / `order-2 lg:order-1` pairings so mobile always renders the heading before the mock and the alternation only activates at the large breakpoint. The plan's Pitfall 7 warns against leaking unscoped `order-*` classes; this implementation satisfies that explicitly (verified via `grep -c lg:order-` = 2).
- **`<Reveal>` wraps the whole FeatureBlock, not each child.** A single observer per feature is cheaper than per-bullet observers, and the mock's reveal semantics are section-level anyway. Reduced-motion users still get immediately-visible content via Plan 02's `useReveal` early-return.
- **Hex values for traffic-light dots.** These are macOS-control colors (chronicle-mock.css comment calls them out explicitly), not Chronicle brand tokens. Using `bg-rec-red` for the red dot would be semantically wrong -- that's the recording-indicator color, not a macOS window control. Hardcoding the three hex values is correct.
- **Inline percentage heights for bars.** Tailwind can produce `h-[40%]` / `h-[80%]` / ... but a 12-element array of arbitrary values makes the data/presentation split opaque. Keeping bar heights as a const array at module scope and rendering them through inline `style={{ height: \`${h}%\` }}` keeps the data layer readable and avoids compiling 12 single-use arbitrary classes per mock.
- **Explicit `{'\n'}` children inside `<pre>` for ObsidianVaultMock's YAML frontmatter.** The plan's sketch placed bare newlines between JSX elements inside the `<pre>`; React/JSX collapses those. Emitting each newline as a text child (template-literal string) preserves the rendered line breaks while still allowing inline `<span className="text-accent-ink">` wrappers for the YAML keys. Same visual result, explicit semantics.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 -- Bug] Removed the literal string "animation-delay" from a comment in DualStreamMock.tsx**

- **Found during:** Task 1 acceptance-criteria verification
- **Issue:** The acceptance criterion `! grep -q "animation-delay" website/src/components/mocks/DualStreamMock.tsx` was meant to enforce D-11 (no animation). My initial comment in that file said `// No animation-delay -- D-11 forbids animation on mini-mockups.` -- the verbatim string `animation-delay` in the comment matched the grep and would have failed the check despite no actual animation code existing.
- **Fix:** Rephrased the comment to `// No motion timing offsets -- D-11 forbids animation on mini-mockups.` Same meaning, no forbidden-string collision.
- **Files modified:** `website/src/components/mocks/DualStreamMock.tsx` (comment line only; no runtime change)
- **Verification:** `grep -q "animation-delay"` on the file now returns exit 1 (absent); acceptance criterion passes.
- **Committed in:** `691b72e` (rolled into Task 1 commit since the fix was inline during the verification step, before any commit landed)

**2. [Rule 3 -- Blocking] ObsidianVaultMock `<pre>` newline handling**

- **Found during:** Task 2, writing ObsidianVaultMock
- **Issue:** The plan's reference code for the YAML block wrote `<pre>` children across multiple source lines with bare newlines separating `<span>` elements from text nodes. React/JSX collapses bare whitespace-only lines between child elements, which would have merged the YAML lines into a single rendered line inside the `<pre>`.
- **Fix:** Emit each line break as an explicit `{'\n'}` text child inside the `<pre>`. For example: `<span className="text-accent-ink">date</span>{': 2026-04-22T14:02\n'}<span className="text-accent-ink">duration</span>...`. This preserves both the YAML key styling (accent-ink spans) and the line breaks (template-literal newlines).
- **Files modified:** `website/src/components/mocks/ObsidianVaultMock.tsx` (structural; reflected in the initial Write)
- **Verification:** Typecheck clean; acceptance criterion `grep -qE "text-accent-ink.{0,10}date"` matches on the span wrapping the `date` key.
- **Committed in:** `9ed6a1c`
- **Note:** The plan's output section specifically called this out as an expected deviation surface ("Any deviations from the RESEARCH skeletons (e.g., ObsidianVaultMock's `<pre>` + inline spans for YAML keys)"), so this was anticipated by the planner.

---

**Total deviations:** 2 auto-fixed (1 × Rule 1 comment-collision, 1 × Rule 3 JSX-semantics), 0 architectural, 0 user-facing impact. Both were documentation/semantics refinements that preserve the plan's intent while producing working output.

## Issues Encountered

- **Phantom file deletions in `git status` inherited from branch snapshot.** Same as Plans 01 and 02: the worktree carries `.planning/ROADMAP.md` modifications + four `assets/screenshot-*.png` deletions + one `design/...` screenshot modification from the parent branch. None touch this plan's surface; did not stage any of them.

## User Setup Required

None. No external services, no auth gates, no manual steps.

## Verification Summary

| Check | Result |
|---|---|
| `test -f website/src/components/mocks/MockWindow.tsx` | OK |
| `test -f website/src/components/sections/FeatureBlock.tsx` | OK |
| `test -f website/src/components/mocks/DualStreamMock.tsx` | OK |
| `test -f website/src/components/mocks/ChatBubbleMock.tsx` | OK |
| `test -f website/src/components/mocks/ObsidianVaultMock.tsx` | OK |
| `test -f website/src/components/mocks/NotionTableMock.tsx` | OK |
| `'use client'` absent from all 6 files | OK (0 matches) |
| `grep -c "lg:order-" FeatureBlock.tsx` >= 2 | OK (2) |
| `grep "order-1" FeatureBlock.tsx` (mobile default) | OK |
| `grep "<Reveal>" FeatureBlock.tsx` | OK |
| `grep "index % 2 === 1" FeatureBlock.tsx` | OK |
| `grep "export type Tint" FeatureBlock.tsx` | OK |
| `grep "export type MetaTone" FeatureBlock.tsx` | OK |
| `grep "bg-accent-tint" / "bg-spk2-bg" / "bg-paper-warm" FeatureBlock.tsx` | all 3 OK |
| Traffic-light hex values in MockWindow.tsx (#EC6A5F / #F5BF4F / #61C554) | all 3 OK |
| `grep "Session · 00:14:32" / "Microphone" / "System audio" / "Speaker 2" DualStreamMock.tsx` | all 4 OK |
| `grep "VAD · trimming silences" / "Parakeet-TDT · on-device" DualStreamMock.tsx` | both OK |
| `! grep "animation-delay" DualStreamMock.tsx` | OK |
| `grep "Chronicle · Transcript" ChatBubbleMock.tsx` | OK |
| `grep "Last thing — did the encoder change land?" ChatBubbleMock.tsx` | OK |
| `grep "Yesterday. Running on main." ChatBubbleMock.tsx` | OK |
| `grep "queue up the diarizer" ChatBubbleMock.tsx` | OK |
| `grep "bg-spk2-rail" / "bg-ink text-paper" ChatBubbleMock.tsx` | both OK |
| `grep "Obsidian · Vault" / "2026-04-22.md" / "Product sync — Apr 22" ObsidianVaultMock.tsx` | all 3 OK |
| `grep -E "text-accent-ink.{0,10}date" / "participants" / "bg-accent-tint text-accent-ink" ObsidianVaultMock.tsx` | all 3 OK |
| `grep "Notion · Meetings DB" / "4 properties" / "Infra planning" / "Design review" / "Product sync — Apr 22" / "isNew: true" / "bg-accent-tint" NotionTableMock.tsx` | all 7 OK |
| `./node_modules/.bin/tsc --noEmit` inside `website/` | exit 0 |
| Min-line acceptance criteria (MockWindow>=20, FeatureBlock>=60, DualStream>=45, ChatBubble>=40, Obsidian>=60, Notion>=40) | all 6 OK |

## Next Plan Readiness

- **Plan 13-05 (ShortcutGrid + Final CTA + page.tsx composition)** can now import all six components. Expected usage pattern in page.tsx:
  ```tsx
  <FeatureBlock index={0} tint="tint" metaLabel="Dual-stream capture" headline="..." body={...} bullets={[...]} mock={<DualStreamMock />} />
  <FeatureBlock index={1} tint="sage" metaTone="sage" metaLabel="Transcript view" headline="..." body={...} bullets={[...]} mock={<ChatBubbleMock />} />
  <FeatureBlock index={2} tint="default" metaTone="navy" metaLabel="Obsidian vault" headline="..." body={<>...<em>is</em>...</>} bullets={[...]} mock={<ObsidianVaultMock />} />
  <FeatureBlock index={3} tint="tint" metaLabel="Notion, on send" headline="..." body={...} bullets={[...]} mock={<NotionTableMock />} />
  ```
  The tint/metaTone rhythm (tint / sage / default / tint) matches CONTEXT D-10.
- **verify-landing.mjs expected state after this plan:** unchanged from post-Plan-02. LAND-04 still shows 8 MISS (no page.tsx consumption yet). Plan 05 flips those to OK when it wires the FeatureBlocks into `/`.
- **No downstream refactor risk.** The FeatureBlock API (props signature, Tint + MetaTone exports) is frozen; Plan 05 will consume it as-is without any FeatureBlock.tsx edits.

## Self-Check: PASSED

Verified all files exist on disk:

- `website/src/components/mocks/MockWindow.tsx` -- FOUND (38 lines)
- `website/src/components/sections/FeatureBlock.tsx` -- FOUND (84 lines)
- `website/src/components/mocks/DualStreamMock.tsx` -- FOUND (56 lines)
- `website/src/components/mocks/ChatBubbleMock.tsx` -- FOUND (73 lines)
- `website/src/components/mocks/ObsidianVaultMock.tsx` -- FOUND (65 lines)
- `website/src/components/mocks/NotionTableMock.tsx` -- FOUND (74 lines)
- `.planning/phases/13-landing-page/13-04-SUMMARY.md` -- FOUND (this file)

Verified all commits exist:

- `691b72e` -- FOUND (Task 1: feat(13-04): add FeatureBlock + MockWindow + DualStreamMock)
- `9ed6a1c` -- FOUND (Task 2: feat(13-04): add ChatBubble, ObsidianVault, NotionTable mocks)

---

*Phase: 13-landing-page*
*Plan: 04*
*Completed: 2026-04-23*
