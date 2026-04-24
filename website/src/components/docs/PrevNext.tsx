import Link from 'next/link'

type Entry = { href: string; title: string }
type Props = { prev?: Entry; next?: Entry }

// TODO(Plan 02): When sidebar-data.ts is available, accept an optional
// currentSlug prop and auto-derive prev/next from the sidebar order.
// For now, manual props only — Plan 01 only needs the element overrides
// to type-check; Plan 02 wires up auto-derivation before any MDX page
// actually invokes <PrevNext />.
export function PrevNext({ prev, next }: Props) {
  const cardBase =
    'block px-[18px] py-[16px] border-[0.5px] border-rule rounded-[10px] bg-paper no-underline transition-colors duration-[120ms] hover:bg-paper-warm'
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 mt-14">
      {prev && (
        <Link href={prev.href} className={`${cardBase}`}>
          <small className="block font-mono text-[10px] uppercase tracking-[0.08em] text-ink-faint mb-1">← Previous</small>
          <strong className="font-serif text-[16px] font-medium text-ink">{prev.title}</strong>
        </Link>
      )}
      {next && (
        <Link href={next.href} className={`${cardBase} text-right sm:text-right`}>
          <small className="block font-mono text-[10px] uppercase tracking-[0.08em] text-ink-faint mb-1">Next →</small>
          <strong className="font-serif text-[16px] font-medium text-ink">{next.title}</strong>
        </Link>
      )}
    </div>
  )
}
