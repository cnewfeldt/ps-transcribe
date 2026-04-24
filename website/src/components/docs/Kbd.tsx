import type { HTMLAttributes } from 'react'

export type KbdTone = 'default' | 'navy' | 'sage'

const toneClasses: Record<KbdTone, string> = {
  default: 'bg-paper border-rule-strong text-ink',
  navy: 'bg-accent-tint text-accent-ink border-[rgba(43,74,122,0.22)]',
  sage: 'bg-spk2-bg text-spk2-fg border-[rgba(127,160,147,0.4)]',
}

type KbdProps = HTMLAttributes<HTMLSpanElement> & { tone?: KbdTone }

export function Kbd({ tone = 'default', className = '', children, ...rest }: KbdProps) {
  return (
    <span
      {...rest}
      className={`inline-flex items-center justify-center min-w-[22px] px-[6px] py-[3px] font-mono text-[12px] border-[0.5px] border-b-[1px] rounded-[4px] ${toneClasses[tone]} ${className}`.trim()}
    >
      {children}
    </span>
  )
}
