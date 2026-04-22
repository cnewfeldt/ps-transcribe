import type { HTMLAttributes } from 'react'

type CardProps = HTMLAttributes<HTMLDivElement>

export function Card({ className = '', children, ...rest }: CardProps) {
  return (
    <div
      {...rest}
      className={`bg-paper border-[0.5px] border-rule rounded-card p-[22px] ${className}`.trim()}
    >
      {children}
    </div>
  )
}
