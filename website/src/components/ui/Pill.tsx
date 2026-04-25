import type { HTMLAttributes, ReactNode } from 'react'

type PillVariant = 'live' | 'breaking'

type PillProps = HTMLAttributes<HTMLSpanElement> & {
  variant: PillVariant
  children: ReactNode
}

/**
 * Small pill used in the changelog's release card meta row.
 * - variant="live": navy "Current" badge with a 6px LED dot
 * - variant="breaking": red-tinted badge for releases containing breaking changes
 *
 * Per Phase 15 D-08 (CONTEXT.md). Variant union, no boolean flags.
 */
export function Pill({ variant, className = '', children, ...rest }: PillProps) {
  const base =
    'inline-flex items-center gap-1.5 font-mono text-[10px] uppercase tracking-[0.08em] leading-none px-2 py-0.5 rounded-full border-[0.5px]'

  if (variant === 'live') {
    return (
      <span
        {...rest}
        className={`${base} bg-accent-soft border-accent-ink text-accent-ink ${className}`.trim()}
      >
        <span
          aria-hidden
          className="inline-block w-1.5 h-1.5 rounded-full bg-accent-ink"
        />
        {children}
      </span>
    )
  }

  // variant === 'breaking'
  return (
    <span
      {...rest}
      className={`${base} text-rec-red ${className}`.trim()}
      style={{
        backgroundColor: 'rgba(194, 74, 62, 0.08)',
        borderColor: 'rgba(194, 74, 62, 0.2)',
      }}
    >
      {children}
    </span>
  )
}
