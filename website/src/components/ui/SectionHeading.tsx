import type { HTMLAttributes } from 'react'
import { createElement } from 'react'

type SectionHeadingProps = HTMLAttributes<HTMLHeadingElement> & {
  as?: 'h1' | 'h2' | 'h3' | 'h4'
}

export function SectionHeading({
  as = 'h2',
  className = '',
  children,
  ...rest
}: SectionHeadingProps) {
  return createElement(
    as,
    {
      ...rest,
      className: `font-serif font-normal text-[clamp(26px,3vw,32px)] leading-[1.15] tracking-[-0.01em] text-ink ${className}`.trim(),
    },
    children,
  )
}
