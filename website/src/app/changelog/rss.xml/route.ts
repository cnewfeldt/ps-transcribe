import { getAllReleases, type ChangelogEntry, type ChangelogSection } from '@/lib/changelog'

const HOST = 'https://ps-transcribe-web.vercel.app'

/**
 * Static RSS feed. Resolved at build time (no `dynamic`, no `revalidate`).
 * Content-Type per RSS 2.0 spec recommendation.
 *
 * Per Phase 15 D-17 (15-CONTEXT.md). Path segment `rss.xml` is a literal
 * Next 16 route segment name -- the resulting URL is /changelog/rss.xml.
 */
export async function GET() {
  const entries = getAllReleases()
  const body = renderRss(entries)
  return new Response(body, {
    status: 200,
    headers: {
      'Content-Type': 'application/rss+xml; charset=utf-8',
      'Cache-Control': 'public, max-age=3600',
    },
  })
}

function versionSlug(version: string): string {
  return `v${version.replace(/\./g, '-')}`
}

/**
 * RFC 822 / 1123 pubDate from an ISO date.
 * `new Date('2026-04-23').toUTCString()` produces 'Thu, 23 Apr 2026 00:00:00 GMT'
 * which is RFC 1123 (a stricter subset of RFC 822) -- accepted by all RSS readers.
 */
function rfc822(iso: string): string {
  return new Date(`${iso}T00:00:00Z`).toUTCString()
}

/**
 * XML-escape a string for use in XML element text or attribute values
 * OUTSIDE a CDATA section. Used for: channel/item titles, links, guid,
 * pubDate, atom:link href, <a href> attribute values inside CDATA.
 *
 * NOT sufficient for HTML element content inside CDATA (where the consumer
 * parses as HTML, not XML) -- use htmlEscape() for that.
 */
function xmlEscape(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;')
}

/**
 * HTML-escape a string for use as element content INSIDE a CDATA block.
 * Feed readers parse <description> CDATA as HTML -- so a raw `<` would open
 * a stray HTML element. Mitigation per checker Issue #4: escape `&`, `<`,
 * `>` so user content like "Use `arr[0] < 5`" renders correctly.
 *
 * Quotes (`"`, `'`) don't need escaping for HTML element content (only
 * for HTML attribute values, but we're not putting user text into
 * attributes -- only into element content via this function).
 */
function htmlEscape(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
}

/**
 * Defang any CDATA-end-sequence appearing in user content.
 * Without this, a bullet containing the literal ']]>' would terminate the
 * CDATA block early and let subsequent characters be parsed as XML --
 * a classic CDATA-section injection. Mitigation: insert a `]]><![CDATA[`
 * boundary so the content is split across two CDATA sections, neither
 * of which contains the kill sequence.
 */
function defangCdataEnd(s: string): string {
  return s.replace(/]]>/g, ']]]]><![CDATA[>')
}

/**
 * Compose htmlEscape() then defangCdataEnd() for any user text destined
 * for HTML element content inside a CDATA block. Order matters: htmlEscape
 * first (turns user `<` into `&lt;`), then defang (handles literal `]]>`
 * -- which htmlEscape can't produce since it doesn't introduce `]` chars).
 */
function escapeForCdataHtml(s: string): string {
  return defangCdataEnd(htmlEscape(s))
}

/**
 * Whitelist URL schemes for inline links in the RSS description.
 * Same policy as renderInlineMarkdown (15-01 Task 4): only http(s), `/`, `#`.
 */
function isSafeUrl(url: string): boolean {
  return /^(https?:\/\/|\/|#)/i.test(url)
}

/**
 * Server-side renderer of inline markdown to HTML string for the RSS
 * description. Mirrors lib/inline-markdown.tsx but emits HTML strings
 * instead of React nodes (we cannot ship React JSX inside an XML
 * Response body).
 *
 * Order: code > bold > link > plain. No nested handling.
 *
 * Security: every user-text touch-point passes through escapeForCdataHtml()
 * -- HTML-escapes `<`/`&`/`>` then defangs `]]>`. URL attribute values
 * pass through xmlEscape().
 */
function renderInlineMarkdownHtml(text: string): string {
  const RE_CODE = /`([^`]+)`/
  const RE_BOLD = /\*\*([^*]+)\*\*/
  const RE_LINK = /\[([^\]]+)\]\(([^)]+)\)/

  let out = ''
  let remaining = text
  // Cap iterations defensively to avoid infinite loops on pathological input.
  for (let safety = 0; safety < 1000 && remaining.length > 0; safety++) {
    const code = remaining.match(RE_CODE)
    const bold = remaining.match(RE_BOLD)
    const link = remaining.match(RE_LINK)
    const candidates: Array<{ idx: number; type: 'code' | 'bold' | 'link'; m: RegExpMatchArray }> = []
    if (code && code.index !== undefined) candidates.push({ idx: code.index, type: 'code', m: code })
    if (bold && bold.index !== undefined) candidates.push({ idx: bold.index, type: 'bold', m: bold })
    if (link && link.index !== undefined) candidates.push({ idx: link.index, type: 'link', m: link })
    if (candidates.length === 0) {
      out += escapeForCdataHtml(remaining)
      break
    }
    candidates.sort((a, b) => {
      if (a.idx !== b.idx) return a.idx - b.idx
      const order = { code: 0, bold: 1, link: 2 } as const
      return order[a.type] - order[b.type]
    })
    const winner = candidates[0]
    if (winner.idx > 0) out += escapeForCdataHtml(remaining.slice(0, winner.idx))
    if (winner.type === 'code') {
      out += `<code>${escapeForCdataHtml(winner.m[1])}</code>`
    } else if (winner.type === 'bold') {
      out += `<strong>${escapeForCdataHtml(winner.m[1])}</strong>`
    } else {
      // link
      const linkText = winner.m[1]
      const url = winner.m[2]
      if (!isSafeUrl(url)) {
        out += escapeForCdataHtml(`[${linkText}](${url})`)
      } else {
        const isExternal = /^https?:\/\//i.test(url)
        const escUrl = xmlEscape(url)            // attribute value: XML escape
        const escText = escapeForCdataHtml(linkText) // element content: HTML escape + CDATA defang
        const rel = isExternal ? ' rel="noopener"' : ''
        out += `<a href="${escUrl}"${rel}>${escText}</a>`
      }
    }
    remaining = remaining.slice(winner.idx + winner.m[0].length)
  }
  return out
}

function renderSectionHtml(section: ChangelogSection): string {
  const title = escapeForCdataHtml(section.title)
  const items = section.items
    .map((item) => `<li>${renderInlineMarkdownHtml(item)}</li>`)
    .join('')
  return `<h4>${title}</h4><ul>${items}</ul>`
}

function renderItem(entry: ChangelogEntry): string {
  const slug = versionSlug(entry.version)
  const url = `${HOST}/changelog#${slug}`
  const descriptionHtml = entry.sections.map(renderSectionHtml).join('')
  // CDATA wraps the inner HTML -- every user-text touch-point above passed
  // through escapeForCdataHtml() (htmlEscape + defangCdataEnd), so the
  // wrapper is safe from both HTML injection and CDATA-section injection.
  return [
    '    <item>',
    `      <title>${xmlEscape(`v${entry.version}`)}</title>`,
    `      <link>${xmlEscape(url)}</link>`,
    `      <guid isPermaLink="true">${xmlEscape(url)}</guid>`,
    `      <pubDate>${rfc822(entry.date)}</pubDate>`,
    `      <description><![CDATA[${descriptionHtml}]]></description>`,
    '    </item>',
  ].join('\n')
}

function renderRss(entries: ChangelogEntry[]): string {
  const lastBuild = entries.length > 0 ? rfc822(entries[0].date) : new Date().toUTCString()
  const items = entries.map(renderItem).join('\n')
  return [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">',
    '  <channel>',
    '    <title>PS Transcribe — Changelog</title>',
    `    <link>${HOST}/changelog</link>`,
    '    <description>Release notes for PS Transcribe.</description>',
    '    <language>en-us</language>',
    `    <atom:link rel="self" href="${HOST}/changelog/rss.xml" type="application/rss+xml" />`,
    `    <lastBuildDate>${lastBuild}</lastBuildDate>`,
    items,
    '  </channel>',
    '</rss>',
    '',
  ].join('\n')
}
