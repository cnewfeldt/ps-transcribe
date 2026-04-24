import type { HTMLAttributes, ReactNode } from 'react'

type Props = HTMLAttributes<HTMLParagraphElement> & { children: ReactNode }

export function Lede({ className = '', children, ...rest }: Props) {
  return (
    <p
      {...rest}
      className={`font-sans text-[18px] leading-[1.5] text-ink-muted mb-[28px] max-w-[56ch] ${className}`.trim()}
    >
      {children}
    </p>
  )
}
