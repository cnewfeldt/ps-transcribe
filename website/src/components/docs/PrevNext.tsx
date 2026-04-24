import Link from 'next/link'
import { DOC_ORDER } from './sidebar-data'

type Entry = { href: string; title: string }
type Props = {
  /** Slug of the current page (e.g. 'getting-started'). When provided, prev/next are auto-derived from DOC_ORDER. */
  currentSlug?: string
  /** Manual override; wins over currentSlug auto-derivation. */
  prev?: Entry
  /** Manual override; wins over currentSlug auto-derivation. */
  next?: Entry
}

function deriveFromSidebar(slug: string): { prev?: Entry; next?: Entry } {
  const idx = DOC_ORDER.findIndex((i) => i.slug === slug)
  if (idx === -1) return {}
  const prevItem = idx > 0 ? DOC_ORDER[idx - 1] : undefined
  const nextItem = idx < DOC_ORDER.length - 1 ? DOC_ORDER[idx + 1] : undefined
  return {
    prev: prevItem && { href: prevItem.href, title: prevItem.navTitle },
    next: nextItem && { href: nextItem.href, title: nextItem.navTitle },
  }
}

export function PrevNext({ currentSlug, prev, next }: Props) {
  const derived = currentSlug ? deriveFromSidebar(currentSlug) : {}
  const finalPrev = prev ?? derived.prev
  const finalNext = next ?? derived.next
  if (!finalPrev && !finalNext) return null

  const cardBase =
    'block px-[18px] py-[16px] border-[0.5px] border-rule rounded-[10px] bg-paper no-underline transition-colors duration-[120ms] hover:bg-paper-warm'
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 mt-14">
      {finalPrev ? (
        <Link href={finalPrev.href} className={cardBase}>
          <small className="block font-mono text-[10px] uppercase tracking-[0.08em] text-ink-faint mb-1">← Previous</small>
          <strong className="font-serif text-[16px] font-medium text-ink">{finalPrev.title}</strong>
        </Link>
      ) : (
        <span />
      )}
      {finalNext ? (
        <Link href={finalNext.href} className={`${cardBase} sm:text-right`}>
          <small className="block font-mono text-[10px] uppercase tracking-[0.08em] text-ink-faint mb-1">Next →</small>
          <strong className="font-serif text-[16px] font-medium text-ink">{finalNext.title}</strong>
        </Link>
      ) : (
        <span />
      )}
    </div>
  )
}
