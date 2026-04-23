import type { ReactNode } from 'react'
import { MetaLabel } from '@/components/ui'
import { Reveal } from '@/components/motion/Reveal'

export type Tint = 'default' | 'tint' | 'sage'
export type MetaTone = 'default' | 'navy' | 'sage'

const tintMap: Record<Tint, string> = {
  default: 'bg-paper-warm border-rule',
  tint: 'bg-accent-tint border-rule',
  sage: 'bg-spk2-bg border-rule',
}

const metaToneMap: Record<MetaTone, string> = {
  default: '',
  navy: 'text-accent-ink',
  sage: 'text-spk2-fg',
}

/**
 * Reusable feature block. Consumed 4 times in page.tsx with different tint +
 * metaTone + headline + body + bullets + mock. Alternates layout via
 * `index % 2` using lg-scoped `order-*` utilities (never unscoped -- that
 * would leak into mobile and break the heading-first reading flow). Wraps the
 * whole block in <Reveal> so it fades in on first scroll intersection.
 */
export function FeatureBlock({
  index,
  tint,
  metaTone = 'default',
  metaLabel,
  headline,
  body,
  bullets,
  mock,
}: {
  index: number
  tint: Tint
  metaTone?: MetaTone
  metaLabel: string
  headline: string
  body: ReactNode
  bullets: string[]
  mock: ReactNode
}) {
  const altLayout = index % 2 === 1
  // At lg+, alternate which column holds copy vs mock. On mobile (< lg),
  // copy ALWAYS precedes mock (heading-first reading flow).
  const copyOrder = altLayout ? 'lg:order-2' : 'lg:order-1'
  const mockOrder = altLayout ? 'lg:order-1' : 'lg:order-2'

  const bulletMarker = tint === 'sage' ? 'before:bg-spk2-rail' : 'before:bg-accent-ink'

  return (
    <Reveal>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-14 items-center py-12">
        <div className={`min-w-0 order-1 ${copyOrder}`}>
          <MetaLabel className={`${metaToneMap[metaTone]} inline-block mb-[14px]`}>
            {metaLabel}
          </MetaLabel>
          <h3 className="font-serif font-normal text-[clamp(22px,2.4vw,26px)] leading-[1.2] tracking-[-0.005em] text-ink mb-[14px]">
            {headline}
          </h3>
          <p className="font-sans text-[15px] leading-[1.65] text-ink-muted">{body}</p>
          <ul className="list-none mt-[18px] p-0 grid gap-2">
            {bullets.map((b, i) => (
              <li
                key={i}
                className={`flex gap-[10px] font-sans text-[14.5px] leading-[1.55] text-ink-muted before:content-[''] before:flex-none before:w-[5px] before:h-[5px] before:rounded-full before:mt-[9px] ${bulletMarker}`}
              >
                <span>{b}</span>
              </li>
            ))}
          </ul>
        </div>
        <div
          className={`min-h-[280px] p-7 rounded-[14px] border-[0.5px] flex items-center justify-center order-2 ${mockOrder} ${tintMap[tint]}`}
        >
          {mock}
        </div>
      </div>
    </Reveal>
  )
}
