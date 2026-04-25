---
phase: 15-changelog-page
plan: 04
subsystem: web

tags: [changelog, rss, next, route-handler, security, xml]

requires:
  - phase: 15-changelog-page
    plan: 01
    provides: getAllReleases() with synthesized 'Changes' section for legacy releases (v1.0.0..v1.2.0) so every entry has sections.length >= 1
provides:
  - RSS 2.0 feed at /changelog/rss.xml (Next 16 Route Handler)
  - Server-side HTML renderer for inline markdown (renderInlineMarkdownHtml) — emits HTML strings for use inside CDATA, parallel to lib/inline-markdown.tsx (which emits React nodes)
  - Reusable XML/HTML escape pipeline (xmlEscape, htmlEscape, defangCdataEnd, escapeForCdataHtml) for future feed-style routes
affects: []

tech-stack:
  added: []
  patterns:
    - "Next 16 Route Handler with literal `.xml` segment name (`app/changelog/rss.xml/route.ts`)"
    - "CDATA injection-safe HTML rendering: htmlEscape user-text first, then defang `]]>` sequences via insertion of `]]><![CDATA[` boundary"
    - "Two-tier escape policy: htmlEscape for CDATA element content (HTML consumer), xmlEscape for URL attribute values (XML consumer)"

key-files:
  created:
    - website/src/app/changelog/rss.xml/route.ts
  modified: []

key-decisions:
  - "Server-side re-implementation of inline-markdown rendering as HTML strings rather than reusing lib/inline-markdown.tsx — that module returns React nodes which cannot be serialized into the XML Response body. Same regex order, same isSafeUrl() allowlist, same external-link rel='noopener'."
  - "HOST is hardcoded to https://ps-transcribe-web.vercel.app (production deploy URL per 15-CONTEXT.md <specifics>) — NOT ps-transcribe.vercel.app, which was claimed by another Vercel account at Phase 11 setup time."
  - "Cache-Control: public, max-age=3600 advisory — Vercel will likely treat this as static since the handler reads no request state."
  - "Two distinct escape functions (htmlEscape vs xmlEscape) instead of one universal escaper — the consumers parse differently (RSS readers parse <description> CDATA as HTML; <link>/<guid>/href values are parsed as XML)."

requirements-completed: [LOG-01]

duration: 5min
completed: 2026-04-25
---

# Phase 15 Plan 04: RSS Feed Route Handler Summary

**Next 16 Route Handler at `/changelog/rss.xml` emitting valid RSS 2.0 with all 10 PS Transcribe releases, CDATA-wrapped HTML descriptions, and a hardened escape pipeline (htmlEscape + defangCdataEnd + xmlEscape) that mitigates XML/HTML injection at the CHANGELOG.md → feed-reader trust boundary.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-04-25T08:43:49Z
- **Completed:** 2026-04-25T08:46:50Z
- **Tasks:** 2/2 (Task 1 implementation; Task 2 UAT auto-approved per active auto-mode)
- **Files created:** 1 (`website/src/app/changelog/rss.xml/route.ts`)
- **Files modified:** 0

## Accomplishments

- Shipped a build-time-resolvable RSS 2.0 feed sourced from CHANGELOG.md via the Wave 1 parser
- Every release card visible on the feed, including the 4 legacy releases (v1.0.0..v1.2.0) which now carry a synthesized `<h4>Changes</h4>` section thanks to Plan 15-01 Task 5's orphan-bullet fix
- Hardened the CHANGELOG → external-feed-reader trust boundary against XML injection (T-15-13), XSS via inline links (T-15-14), URL-attribute tampering (T-15-15), DoS via pathological regex input (T-15-17), and HTML injection via raw `<`/`&` in bullet text (T-15-NEW per checker Issue #4)
- Established the Next 16 Route Handler convention for non-UI XML responses; future feeds (Atom, alternate RSS variants, sitemap-style aggregates) can copy this template

## Task Commits

Each task was committed atomically:

1. **Task 1: Create RSS Route Handler at app/changelog/rss.xml/route.ts** — `5791c69` (feat)
2. **Task 2: Human UAT — RSS feed validation** — auto-approved per active auto-mode; no file changes, no commit

## Files Created/Modified

- `website/src/app/changelog/rss.xml/route.ts` — Single-file Route Handler. Exports `GET()` returning a `Response` with `Content-Type: application/rss+xml; charset=utf-8` and a 1-hour `Cache-Control`. Internal helpers: `versionSlug` (e.g., `v2.1.0` → `v2-1-0`), `rfc822` (ISO date → RFC 1123 via `Date.toUTCString()`), three escape functions (`xmlEscape` / `htmlEscape` / `defangCdataEnd`), the `escapeForCdataHtml` composer, `isSafeUrl` URL allowlist, `renderInlineMarkdownHtml` (mirror of lib/inline-markdown.tsx but emitting HTML strings), `renderSectionHtml`, `renderItem`, `renderRss`. ~207 lines total including JSDoc explaining each security mitigation.

## Verify Script Results

All 11 OK markers printed:

```
CT_OK            (Content-Type: application/rss+xml)
XML_DECL_OK      (<?xml version="1.0"?>)
RSS_ROOT_OK      (<rss version="2.0">)
CHANNEL_TITLE_OK (<title>PS Transcribe — Changelog</title>)
ATOM_SELF_OK     (<atom:link rel="self" .../>)
PUBDATE_RFC822_OK (e.g., <pubDate>Thu, 23 Apr 2026 00:00:00 GMT</pubDate>)
ITEM_TITLE_OK    (<title>v2.1.1</title>)
GUID_OK          (<guid isPermaLink="true">https://ps-transcribe-web.vercel.app/changelog#v2-1-1</guid>)
CDATA_OPEN_OK    (<![CDATA[)
H4_OK            (<h4>)
CODE_OK          (<code>)
```

Item count: 10 (newest-first: v2.1.1, v2.1.0, v2.0.0, v1.4.1, v1.4.0, v1.3.0, v1.2.0, v1.1.0, v1.0.1, v1.0.0). Legacy v1.0.0 spot-check confirmed `<h4>Changes</h4>` section is present in the CDATA payload.

All 17 source-content acceptance criteria pass (file exists, directory literal, GET handler exported, Content-Type literal, getAllReleases import, HOST production constant, NOT wrong host, defangCdataEnd fn declared, defang split sequence used, htmlEscape fn, escapeForCdataHtml composer, URL safety check, rel=noopener, xmlEscape fn, atom namespace, channel title, language en-us).

## Threat-Model Mitigations

- **T-15-13 (CDATA-section injection):** `defangCdataEnd()` splits any `]]>` in user content into `]]]]><![CDATA[>` so the CDATA block can't be terminated early. Composed with htmlEscape via `escapeForCdataHtml()` and applied to every user-text element-content insertion in the CDATA block. Confirmed by `grep -q "function defangCdataEnd" route.ts` + `grep -q "]]]]>" route.ts`.
- **T-15-14 (XSS via feed reader inline links):** `isSafeUrl()` allowlist (`^(https?://|/|#)`) gates `<a>` rendering. Unsafe schemes (javascript:, data:, file:, etc.) fall back to plain bracketed text. External links carry `rel="noopener"`. Same policy as 15-01 Task 4's renderInlineMarkdown.
- **T-15-15 (URL attribute tampering):** All URL values (`<link>`, `<guid>`, `<atom:link href>`, `<a href>`) pass through `xmlEscape()` which entity-encodes `&`, `<`, `>`, `"`, `'`. Confirmed by `grep -q "function xmlEscape" route.ts`.
- **T-15-NEW (HTML injection in CDATA per Issue #4):** Feed readers parse `<description>` CDATA as HTML, so a raw `<` or `&` in a CHANGELOG bullet would otherwise open a stray HTML element. `htmlEscape()` (composed into `escapeForCdataHtml()`) is applied to every user-text element-content insertion before it lands in the RSS template. Confirmed by `grep -q "function htmlEscape" route.ts` + `grep -q "function escapeForCdataHtml" route.ts`.
- **T-15-17 (DoS via pathological regex):** The `renderInlineMarkdownHtml` loop is capped at 1000 iterations as a defense-in-depth; combined with the linear consumption pattern (always slice past the matched portion), pathological input cannot wedge the handler.
- **T-15-18 (build-time fs read of CHANGELOG.md):** Inherited from Wave 1 — accepted disposition; if CHANGELOG.md is malformed, the parser throws and the build fails (loud, surfaceable in CI).

## Decisions Made

- **Re-implement inline-markdown as HTML emitter:** `lib/inline-markdown.tsx` returns `ReactNode[]` for client-side rendering — those nodes can't be serialized into an XML Response body. The RSS handler ships a parallel `renderInlineMarkdownHtml()` that walks the same regex/priority/safety rules but emits HTML strings. ~50 LOC of duplication, but the consumer contracts are different and conflating them would muddy both. Library choice is locked in (no react-markdown) for parity with 15-01 D-19.
- **Two distinct escape functions:** `xmlEscape()` (5 chars: `&<>"'`) for XML attribute/element values OUTSIDE CDATA; `htmlEscape()` (3 chars: `&<>`) for HTML element content INSIDE CDATA (where the consumer is an HTML parser, not an XML parser). Mixing them either over-escapes (turns a valid URL `&amp;` into `&amp;amp;`) or under-escapes (lets a raw `<` open a stray HTML element).
- **Order matters: htmlEscape THEN defangCdataEnd:** htmlEscape can't introduce `]` characters, so it can't accidentally produce a new `]]>`. Reverse order would risk feeding `&lt;...` to the defang regex (still safe, but the order chosen is the one that requires the least proof-by-cases).
- **HOST hardcoded, not env-var-driven:** Vercel runtime supplies `process.env.VERCEL_URL` for preview deployments, but the production URL is stable and the channel/atom-self refs need to point at the canonical host regardless of preview. Hardcoding matches Phase 13's `SITE` constant pattern.
- **Cache-Control: public, max-age=3600:** Advisory only — Vercel will likely cache this as a static asset since `getAllReleases()` reads no request state and the result depends only on CHANGELOG.md (build-time). The header is best-effort hinting for clients/CDNs that don't introspect Next's static-route metadata.

## Auto-Mode Note

This worktree-agent run was invoked under active auto mode (system reminder). Task 2 (`checkpoint:human-verify`) was auto-approved per the auto-mode checkpoint protocol — no file modifications occur during a UAT-gate task, and Task 1's verify suite already exercised the same assertions a manual UAT would surface (Content-Type header, item count, RFC 822 pubDate format, CDATA payload structure, legacy-release `<h4>Changes</h4>` synthesis). The orchestrator can re-run the UAT manually at any time via `pnpm dev` and visiting `http://localhost:3000/changelog/rss.xml` if a human-eyes pass is desired before merge.

## Deviations from Plan

**1. [Rule 1 - Bug] verify-script grep escape sequence does not match on macOS BSD grep**

- **Found during:** Task 1 verify run.
- **Issue:** The plan's verify-script line `curl -sI ... | grep -qi "Content-Type: application/rss\\+xml" && echo "CT_OK"` uses `\+` to escape the `+` in `application/rss+xml`. On macOS BSD grep (BRE mode by default), `\+` is treated as a literal `\` followed by `+`, which fails to match the actual response header `content-type: application/rss+xml; charset=utf-8`. GNU grep treats `\+` as the BRE quantifier (one-or-more), but macOS does not.
- **Fix:** During verification I switched to fixed-string matching (`grep -Fqi "Content-Type: application/rss+xml"`) which is portable across both grep implementations. The implementation file is unaffected — the response header itself is correct (verified directly via `curl -sI ... | grep -i content-type` → `content-type: application/rss+xml; charset=utf-8`). Only the verify-script grep semantics needed adjusting in-session.
- **Files modified:** None (verify-script bug, not implementation bug).
- **Commit:** N/A (no source change).

The remaining 10 verify-script grep lines all use `-q` with literal patterns and match correctly on both grep implementations. No other verify-script issues encountered.

## Issues Encountered

- One pre-existing ESLint error remains at `website/src/hooks/useReveal.ts:19` (`react-hooks/set-state-in-effect`, introduced in commit `05a05eb` from Phase 13-02). Captured in Plan 15-01's deferred-items.md and explicitly out-of-scope for this plan (file is not touched). `pnpm exec eslint src/app/changelog/rss.xml/route.ts` exits 0 — the new file is lint-clean.

## Threat Flags

None — the new threat surface (CDATA-wrapped HTML rendered by external feed readers) is fully covered by the plan's `<threat_model>` items T-15-13/T-15-14/T-15-15/T-15-17/T-15-NEW, all mitigated as designed.

## User Setup Required

None — pure addition of a static route. No env vars, no external services, no DB changes. Production deploy will register `/changelog/rss.xml` automatically once Wave 2 lands and the phase is merged. Subscribers will reach it via the SubscribeBlock that 15-02 ReleaseCard / 15-03 VersionsAside (Wave 2 partner plans) wire up to `SITE.RSS_URL` (or equivalent — confirmed in their own SUMMARYs).

## Next Phase Readiness

Plan 15-04 is independent of Wave 2's component work (15-02 ReleaseCard, 15-03 VersionsAside) and runs in parallel with them. The RSS feed is a leaf — nothing depends on it. After all three Wave 2 plans land:

- Phase orchestrator runs validation (verifier + Nyquist if enabled per project config)
- Production build re-confirmed clean
- Live deploy to Vercel exposes `/changelog/rss.xml` at the public URL

No blockers. Wave 2 partner plans can ship without coordinating with this one.

## Self-Check

- [x] `website/src/app/changelog/rss.xml/route.ts` exists — FOUND
- [x] Commit `5791c69` exists — FOUND
- [x] tsc clean (full project) — PASS
- [x] eslint clean on new file — PASS
- [x] Production build succeeds with `/changelog/rss.xml` registered as ƒ (Dynamic) — PASS
- [x] Live curl returns Content-Type `application/rss+xml; charset=utf-8` — PASS
- [x] All 11 verify-script OK markers print — PASS
- [x] Item count: 10 — PASS
- [x] Legacy v1.0.0 has synthesized `<h4>Changes</h4>` section — PASS

## Self-Check: PASSED

---
*Phase: 15-changelog-page*
*Completed: 2026-04-25*
