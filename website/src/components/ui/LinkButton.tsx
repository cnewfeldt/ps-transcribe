import type { AnchorHTMLAttributes } from 'react'

type LinkButtonProps = Omit<AnchorHTMLAttributes<HTMLAnchorElement>, 'href'> & {
  variant?: 'primary' | 'secondary'
  href: string
}

// Keep these strings byte-identical to ui/Button.tsx so visual weight matches.
const base =
  'inline-flex items-center gap-2 px-4 py-[10px] rounded-btn font-sans text-[14px] font-medium leading-none transition-colors duration-[120ms] no-underline focus-visible:outline focus-visible:outline-2 focus-visible:outline-accent-ink focus-visible:outline-offset-2'

const variants: Record<NonNullable<LinkButtonProps['variant']>, string> = {
  primary: 'bg-ink text-paper shadow-btn hover:bg-[#2a2a25]',
  secondary: 'bg-paper text-ink border-[0.5px] border-rule-strong hover:bg-paper-soft',
}

export function LinkButton({
  variant = 'primary',
  href,
  className = '',
  children,
  ...rest
}: LinkButtonProps) {
  return (
    <a
      href={href}
      className={`${base} ${variants[variant]} ${className}`.trim()}
      {...rest}
    >
      {children}
    </a>
  )
}
