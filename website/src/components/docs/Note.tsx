import type { HTMLAttributes, ReactNode } from 'react'

type NoteProps = HTMLAttributes<HTMLDivElement> & {
  variant?: 'default' | 'sage'
  label?: string
  children: ReactNode
}

export function Note({ variant = 'default', label, className = '', children, ...rest }: NoteProps) {
  const base =
    'border-[0.5px] border-rule rounded-[8px] px-[18px] py-[14px] mb-[22px] text-[14.5px] text-ink border-l-[2px]'
  const variantClasses =
    variant === 'sage'
      ? 'border-l-spk2-rail bg-spk2-bg'
      : 'border-l-accent-ink bg-accent-tint'
  const labelClasses =
    variant === 'sage'
      ? 'block font-mono text-[10px] uppercase tracking-[0.1em] text-spk2-fg mb-[4px] font-medium'
      : 'block font-mono text-[10px] uppercase tracking-[0.1em] text-ink-faint mb-[4px] font-medium'
  return (
    <div {...rest} className={`${base} ${variantClasses} ${className}`.trim()}>
      {label && <strong className={labelClasses}>{label}</strong>}
      {children}
    </div>
  )
}
