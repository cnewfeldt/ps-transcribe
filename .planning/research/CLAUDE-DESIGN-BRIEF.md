# Claude Design Brief — PS Transcribe Marketing Website

> Paste the contents of this file (below the `--- BEGIN BRIEF ---` line) into Claude Design to generate the site's visual mocks. Produced as part of milestone v1.1.

---

--- BEGIN BRIEF ---

# Brief: PS Transcribe — Marketing Website

## About the product

**PS Transcribe** is a native macOS app for private, on-device transcription of meetings and voice memos. Everything runs locally — no cloud APIs, no telemetry, no LLM analysis of transcript content. The app captures two parallel audio streams (microphone + system audio via ScreenCaptureKit), runs speech recognition through FluidAudio's Parakeet-TDT model, runs voice-activity detection via Silero VAD, and does post-session speaker diarization. Transcripts save as Markdown with YAML frontmatter into the user's configured Obsidian vault folders, with optional auto-send to a Notion database at end of recording.

It is an indie macOS-only app, distributed as a signed DMG via GitHub Releases using Sparkle for auto-updates. It is currently free and unmonetized. The audience is knowledge workers who run a lot of calls (founders, PMs, consultants, researchers), Obsidian/Notion power users, and privacy-conscious people who won't let their meeting audio leave their machine.

## What to design

A multi-page marketing website for PS Transcribe with three main areas:

1. **Landing page** — hero section, feature highlights, product screenshots, and a primary CTA button that downloads the latest DMG from GitHub Releases.
2. **Docs** — a help section for Getting Started, Keyboard Shortcuts, FAQ, and Troubleshooting. Written in MDX. Should have a left-hand sidebar nav and clean typographic body treatment.
3. **Changelog** — a styled release-notes page, one section per version, sourced from the app's `CHANGELOG.md`. Most recent version at the top.

The site will be built in Next.js (App Router) on Vercel, deployed at `ps-transcribe.vercel.app` for now. Custom domain is deferred.

## Design system

**The site must reuse the "Quiet Chronicle" design system already in use by the app.** The app's visual identity is editorial, paper-based, and quiet — it should feel like a serious tool, not a flashy SaaS landing. Match this. Don't reinvent it.

### Palette

All values are light-mode only. No dark mode in v1.

| Token | Value | Use |
|---|---|---|
| `paper` | `#FAFAF7` | Primary page background |
| `paperWarm` | `#F4F1EA` | Secondary surfaces, sidebar bg, cards |
| `paperSoft` | `#EEEAE0` | Hover/pressed state |
| `rule` | `rgba(30,30,28,0.08)` | Hairline dividers (0.5pt/0.5px) |
| `ruleStrong` | `rgba(30,30,28,0.14)` | Button borders |
| `ink` | `#1A1A17` | Primary text, dark elements |
| `inkMuted` | `#595954` | Secondary text |
| `inkFaint` | `#8A8A82` | Meta labels, timestamps |
| `inkGhost` | `#B8B8AF` | Disabled / tertiary |
| `accentInk` | `#2B4A7A` | Navy accent for links, focus rings, accent dots |
| `accentSoft` | `#DFE6F0` | Accent hover |
| `accentTint` | `#F1F4F9` | Accent section backgrounds |
| `spk2Bg` | `#E6ECEA` | Sage-green speaker bubble (used in the app's transcript) |
| `spk2Fg` | `#2D4A43` | Sage-green text |
| `spk2Rail` | `#7FA093` | Sage-green rail / dots |
| `recRed` | `#C24A3E` | Record/destructive accent (use sparingly on marketing) |
| `liveGreen` | `#4A8A5E` | "Synced" / live status dot |

### Typography

Three-font stack with web fallbacks:

- **Sans** — Inter (primary body + UI). Fallback: system UI sans.
- **Serif** — Spectral (window/page titles and hero headline moments). Fallback: Georgia, New York, serif.
- **Mono** — JetBrains Mono (meta labels, timestamps, code snippets, keyboard-shortcut hints). Fallback: Menlo, monospace.

Uppercase mono meta labels use 0.5–0.8px letter-spacing. Line-height 1.5 for body text. Bubble-style content in the app uses 10pt mono for timestamps at 0.5 opacity.

Hero type can go to ~44–56px serif. Section titles 28–32px serif. Body 15–16px sans with 1.6 line-height on marketing pages.

### Spacing, radii, shadows

Spacing scale in px: 4, 6, 8, 10, 14, 18, 22, 28, 40, 64, 96.

Radii: 4 (inputs), 6 (buttons, list items), 10 (cards), 12 (bubbles), 999 (pills).

Shadows are soft and close to the surface. The app uses:

- Selected list-item lift: `0 1 3 rgba(30,30,28,0.08)` + inset hairline
- Primary button depth: `0 1 2 rgba(30,30,28,0.20)`, `inset 0 1 0 rgba(255,255,255,0.08)`
- Floating lift: `0 8 24 rgba(30,30,28,0.12), 0 1 3 rgba(30,30,28,0.06)`

### Buttons

Primary = dark `ink` bg with paper text, 6px radius, 8/12 padding, 12–14px sans medium. Small red accent dot or `video.fill` glyph in the app's version — on marketing, a clean "Download for macOS" label with a chevron or a small macOS/Apple glyph is fine. No drop shadows stronger than those listed above.

Secondary = paper bg, 0.5px ruleStrong border, 6px radius, ink text.

Text links in body use `accentInk` with `text-underline-offset: 3px` and subtle underline on hover.

### Component idioms from the app to borrow

- **Meta label**: 10px JetBrains Mono, uppercase, 0.5 letter-spacing, `inkFaint` color, sits above section headings (e.g., a tiny `FEATURES` label above a hero headline).
- **Card with hairline**: `paper` bg, 0.5px `rule` border, 10px radius. Good for feature grids and changelog entries.
- **Sage-green speaker bubble**: used in the app for the "them" side of a transcript. Works beautifully as a product screenshot accent — consider showing a real bubble pair (dark You bubble + sage Speaker 2 bubble) in hero imagery.

## Pages to design

### Landing (required)

Sections, top to bottom:

1. **Nav bar** — thin, paper bg, left: wordmark "PS Transcribe" (serif Spectral 18–20px), right: nav links (`Docs`, `Changelog`, `GitHub`) in 13–14px mono or muted sans. No sticky drop-shadow; just a 0.5px hairline at the bottom when scrolled.
2. **Hero** — big serif headline (Spectral, ~48–56px), one-line value prop beneath in 16–18px sans, primary "Download for macOS" button and a secondary "View on GitHub" text link. Could optionally have a small tagline above the headline in uppercase mono meta-label style. Right side (or below, stacked): product screenshot with a subtle drop shadow, probably the three-column Chronicle UI showing an active recording with chat bubbles visible.
3. **"Three things" strip** — a row of three small cards (paper bg, 0.5px rule, 10px radius), each with an uppercase mono meta label, a short headline, and one line of body text. Suggested themes: *Private by default* (no cloud, all on-device), *Works with your vault* (Obsidian + Notion), *Quiet interface* (designed to disappear while you work).
4. **Feature showcase** — alternating left/right screenshot-with-copy blocks. Three to four of them, covering:
   - Dual-stream capture (mic + system audio) with speaker diarization
   - Chat-bubble transcript view with inline rename
   - Auto-save to Obsidian vault folders
   - One-click sync to Notion database
   Each block has a meta label, a serif sub-headline (~24–28px), a short paragraph, and a single screenshot anchored with subtle paper-warm background.
5. **Keyboard shortcuts callout** — small card or strip showing `⌘R` = Meeting, `⌘⇧R` = Memo, `⌘.` = Stop, `⌘⇧S` = Toggle sidebar. JetBrains Mono typography, sage-green or navy key chips.
6. **Final CTA** — centered paper-warm panel, serif headline ("Start transcribing privately."), download button, subtle note beneath: "Free. Open source. macOS 14+."
7. **Footer** — thin, paper bg with 0.5px rule on top, three-column: left = copyright + license note, center = quick links (Docs, Changelog, GitHub, Sparkle updates URL), right = small wordmark or attribution line. 11–12px mono for meta.

### Docs page (required)

- Left sidebar (220–260px wide, `paperWarm` bg, 0.5px right rule) with section nav. Uppercase mono section labels, indented sans page links underneath. Active page gets a paper-bg card treatment (mirrors the Library row pattern from the app).
- Main content area (flex, `paper` bg), with MDX body: H1 in Spectral 36px, H2 in Spectral 24px with a small `# ANCHOR` mono label hovering to the left, body in Inter 16px/1.6. Inline code uses JetBrains Mono 14px on a `paperSoft` pill background.
- Right-hand "On this page" mini-TOC in a 180px column, JetBrains Mono 11px uppercase, each link `inkFaint` → `ink` on hover. Collapses below 1200px width.

Initial pages (Claude Design should show at least two as examples):
- *Getting Started*
- *Keyboard shortcuts*
- *FAQ*
- *Troubleshooting*

### Changelog (required)

- Hero strip: meta label `CHANGELOG` + serif "Every release." tagline.
- Then a vertical stack of release cards. Each card:
  - `paper` bg with 0.5px rule border, 10px radius
  - Uppercase mono date (`APR 20, 2026`) at top-left
  - Serif version headline `v2.1.0` inline to the right of the date
  - Body copy grouped by subsection (UX / Features / Fixes) — section headings in uppercase mono 11px, bullet points in 14–15px sans
  - A small sage-green/navy tag pill if the release is "Current" or "Breaking"
- Latest release at the top, older releases beneath with slightly reduced prominence.

## Tone of voice

- Calm, precise, editorial. Not "GREAT for VIBES 🔥".
- Favor concrete capability statements over buzzwords. "Records both sides of your Zoom call, locally" beats "AI-powered transcription experience."
- Keep JavaScript-y words out: no "seamless", no "empower", no "revolutionize".
- The app is quiet; the site should be quiet too. Think Linear release notes, Things 3 marketing page, or Notion's early documentation — not Gumroad product pages.

## What NOT to do

- No dark mode.
- No gradient heroes, no glows, no animated blobs.
- No stock photography of laptops and coffee.
- No "testimonials from real users" section (we don't have enough).
- No pricing page — there's no pricing. Download CTA is the only conversion target.
- No chat widget, no intercom bubble.
- No cookie banner (no analytics stack committed yet).
- No generic "Trusted by Fortune 500" logo bar — we have no partners.

## Assets available

- The macOS app itself. Screenshots can be captured of the real Chronicle UI at 1280×820 default window size.
- The CHANGELOG.md (lives at repo root).
- The README.md (lives at repo root; has the acknowledgments + open-source positioning).
- Icons: SF Symbols for in-app icons. Can reuse `video.fill`, `mic.fill`, `phone.fill`, `waveform`, `gearshape`, etc.

## Deliverables requested from Claude Design

1. **HTML + CSS mocks** of all three pages (landing, one docs page, changelog) at desktop width (1280–1440px). Responsive breakpoints down to ~768px (tablet) and ~420px (mobile). Mobile doesn't need to be pixel-perfect; just demonstrate the layout collapses sensibly.
2. **Reusable component sketches** in JSX or HTML snippets: Button (primary, secondary), Card, MetaLabel, SectionHeading, CodeBlock, Navbar, Sidebar, ChangelogEntry, FeatureBlock.
3. **Tokens file** mirroring the palette/typography/spacing values above, in a format that can be ported to Tailwind config or CSS custom properties.
4. **Icon + illustration guidance** — if any inline illustrations are needed (empty states, feature blocks), state the style: line-art, sage-and-navy accents, editorial — same restraint as the app.
5. **Copy suggestions** for the hero headline, the "three things" strip, and the final CTA panel. Keep them short and specific.

## Constraints

- Light mode only.
- No bundled web fonts beyond Inter + Spectral + JetBrains Mono (open-source, available on Google Fonts).
- Must be accessible: AA color contrast minimum, visible focus rings (navy on paper), keyboard navigation for all interactive elements.
- Page weight budget: <200KB HTML/CSS/JS per page after gzip for landing. Docs can be heavier due to MDX content.
- No JavaScript frameworks in the mocks — prefer plain HTML/CSS for the design-handoff bundle.

## Out of scope for this brief

- Email capture / newsletter signup
- Blog
- Search functionality in docs (Ctrl+K modal etc.)
- Multi-language support
- Server-side components or dynamic content (the whole site will be static-rendered)

--- END BRIEF ---

## How to use this document

1. Copy everything between `--- BEGIN BRIEF ---` and `--- END BRIEF ---` above.
2. Paste it into Claude Design as the design brief.
3. Claude Design will return an HTML/CSS handoff bundle (similar format to `design_handoff_ps_transcribe.zip` that produced the Chronicle app redesign).
4. Drop the zip at `design/ps-transcribe-web.zip` and ask Claude Code to unzip and begin implementation.

The resulting handoff becomes the input to phase 1 (or 2) of this milestone's roadmap.
