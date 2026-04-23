'use client'

import type { ReactNode } from 'react'
import { useReveal } from '@/hooks/useReveal'

/**
 * Opt-in scroll-reveal wrapper. Apply sparingly (three-things cards,
 * feature blocks, final CTA). Do NOT wrap the hero — it's above the fold
 * and should render immediately visible on every load.
 */
export function Reveal({
  children,
  className = '',
}: {
  children: ReactNode
  className?: string
}) {
  const { ref, visible } = useReveal<HTMLDivElement>()
  return (
    <div
      ref={ref}
      className={`transition-[opacity,transform] duration-500 ease-out ${
        visible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-[14px]'
      } ${className}`.trim()}
      data-reveal={visible ? 'in' : 'out'}
    >
      {children}
    </div>
  )
}
