import type { HTMLAttributes } from 'react'

type MetaLabelProps = HTMLAttributes<HTMLSpanElement>

export function MetaLabel({ className = '', children, ...rest }: MetaLabelProps) {
  return (
    <span
      {...rest}
      className={`font-mono text-[10px] uppercase tracking-[0.08em] leading-none text-ink-faint ${className}`.trim()}
    >
      {children}
    </span>
  )
}
