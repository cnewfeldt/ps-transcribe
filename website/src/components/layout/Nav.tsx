'use client'

import Link from 'next/link'
import { useScrolled } from '@/hooks/useScrolled'
import { SITE } from '@/lib/site'

const linkBase =
  'font-mono text-[12px] tracking-[0.06em] uppercase text-ink-muted no-underline hover:text-ink transition-colors duration-[120ms]'

export function Nav() {
  const scrolled = useScrolled(6)
  return (
    <header
      className={`sticky top-0 z-50 backdrop-blur-[8px] backdrop-saturate-150 transition-[box-shadow,background-color] duration-[160ms] border-b-[0.5px] ${
        scrolled
          ? 'border-rule bg-paper-warm/92 shadow-btn'
          : 'border-transparent bg-paper/92'
      }`}
      data-nav-scrolled={scrolled ? 'true' : 'false'}
    >
      <div className="mx-auto max-w-[1200px] px-6 md:px-10 flex items-center justify-between h-16">
        <Link
          href="/"
          className="flex items-center gap-2 font-serif text-[19px] tracking-[-0.01em] text-ink font-medium no-underline"
        >
          <span
            className="inline-block w-[6px] h-[6px] rounded-full bg-accent-ink"
            aria-hidden
          />
          <span>PS&nbsp;Transcribe</span>
        </Link>
        <nav className="flex items-center gap-7">
          <Link className={linkBase} href="/docs">Docs</Link>
          <Link className={linkBase} href="/changelog">Changelog</Link>
          <a className={linkBase} href={SITE.REPO_URL}>GitHub</a>
        </nav>
      </div>
    </header>
  )
}
