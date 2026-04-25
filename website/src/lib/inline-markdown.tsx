import type { ReactNode } from 'react'

/**
 * Inline-only Markdown renderer for CHANGELOG bullet text.
 * Supports: backtick code, **bold**, [text](url) links.
 * No block-level support, no nested handling.
 *
 * Per Phase 15 D-19 (15-CONTEXT.md). Library choice: roll a small renderer
 * (~30 lines) instead of pulling react-markdown -- overkill for inline-only
 * handling.
 *
 * Security: only http(s) and relative URLs render as <a>. Other schemes
 * (javascript:, data:, file:, etc.) render as plain bracket-text fallback
 * to prevent XSS via malicious links pasted into CHANGELOG.md.
 */
const RE_CODE = /`([^`]+)`/
const RE_BOLD = /\*\*([^*]+)\*\*/
const RE_LINK = /\[([^\]]+)\]\(([^)]+)\)/

type Match = { index: number; length: number; node: ReactNode }

function isSafeUrl(url: string): boolean {
  // Allow only http(s) absolute URLs and relative URLs starting with `/` or `#`
  return /^(https?:\/\/|\/|#)/i.test(url)
}

function nextMatch(text: string, keyPrefix: string, keyIndex: number): Match | null {
  const code = text.match(RE_CODE)
  const bold = text.match(RE_BOLD)
  const link = text.match(RE_LINK)

  // Pick the earliest-index match. Tie-break: code > bold > link (priority).
  const candidates: Array<{ m: RegExpMatchArray; type: 'code' | 'bold' | 'link' }> = []
  if (code && code.index !== undefined) candidates.push({ m: code, type: 'code' })
  if (bold && bold.index !== undefined) candidates.push({ m: bold, type: 'bold' })
  if (link && link.index !== undefined) candidates.push({ m: link, type: 'link' })
  if (candidates.length === 0) return null
  candidates.sort((a, b) => {
    if (a.m.index !== b.m.index) return (a.m.index ?? 0) - (b.m.index ?? 0)
    const order = { code: 0, bold: 1, link: 2 } as const
    return order[a.type] - order[b.type]
  })
  const winner = candidates[0]
  const index = winner.m.index ?? 0
  const fullLength = winner.m[0].length
  const key = `${keyPrefix}-${keyIndex}`

  let node: ReactNode
  if (winner.type === 'code') {
    node = (
      <code
        key={key}
        className="font-mono text-[12.5px] bg-paper-soft text-ink rounded px-1.5 py-0.5"
      >
        {winner.m[1]}
      </code>
    )
  } else if (winner.type === 'bold') {
    node = (
      <strong key={key} className="font-semibold text-ink">
        {winner.m[1]}
      </strong>
    )
  } else {
    // link
    const linkText = winner.m[1]
    const url = winner.m[2]
    if (!isSafeUrl(url)) {
      // Fallback: render the bracketed text as plain text, dropping the unsafe URL.
      node = `[${linkText}](${url})`
    } else {
      const isExternal = /^https?:\/\//i.test(url)
      node = (
        <a
          key={key}
          href={url}
          className="text-accent-ink underline decoration-rule underline-offset-2 hover:decoration-accent-ink"
          {...(isExternal ? { target: '_blank', rel: 'noopener' } : {})}
        >
          {linkText}
        </a>
      )
    }
  }
  return { index, length: fullLength, node }
}

export function renderInlineMarkdown(text: string, keyPrefix = 'inl'): ReactNode[] {
  const out: ReactNode[] = []
  let remaining = text
  let i = 0
  while (remaining.length > 0) {
    const m = nextMatch(remaining, keyPrefix, i)
    if (!m) {
      out.push(remaining)
      break
    }
    if (m.index > 0) out.push(remaining.slice(0, m.index))
    out.push(m.node)
    // Advance past the matched portion. Position is implicit in the
    // sliced `remaining` string -- no separate cursor variable needed
    // (and ESLint flags an unused-let if we declare one).
    remaining = remaining.slice(m.index + m.length)
    i++
  }
  return out
}
