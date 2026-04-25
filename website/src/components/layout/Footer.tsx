import Link from 'next/link'
import type { ReactNode } from 'react'
import { SITE } from '@/lib/site'

export function Footer() {
  return (
    <footer className="border-t-[0.5px] border-rule pt-16 pb-24 mt-24 bg-paper">
      <div className="mx-auto max-w-[1200px] px-6 md:px-10 grid grid-cols-1 md:grid-cols-[1.2fr_1fr_1fr] gap-10 items-start">
        <div>
          <div className="flex items-center gap-2 font-serif font-medium text-[17px] tracking-[-0.01em] text-ink">
            <span className="inline-block w-[6px] h-[6px] rounded-full bg-accent-ink" aria-hidden />
            <span>PS Transcribe</span>
          </div>
          <p className="mt-3 max-w-[34ch] font-mono text-[11px] leading-[1.6] tracking-[0.04em] text-ink-muted">
            A native macOS transcription tool. Released under MIT. Maintained as an indie side project.
          </p>
          <p className="mt-3 font-mono text-[11px] tracking-[0.04em] text-ink-muted">© 2026</p>
        </div>
        <FooterColumn title="Product">
          <Link href="/docs">Documentation</Link>
          <a href={SITE.DMG_URL}>Download DMG</a>
          <a href={SITE.APPCAST_URL}>Sparkle appcast</a>
        </FooterColumn>
        <FooterColumn title="Source">
          <a href={SITE.REPO_URL}>GitHub repository</a>
          <a href={SITE.ISSUES_URL}>Report an issue</a>
          <a href={SITE.ACKNOWLEDGEMENTS_URL}>Acknowledgements</a>
          <a href={SITE.LICENSE_URL}>License · MIT</a>
        </FooterColumn>
      </div>
    </footer>
  )
}

function FooterColumn({ title, children }: { title: string; children: ReactNode }) {
  const items = Array.isArray(children) ? children : [children]
  return (
    <div>
      <h4 className="font-mono text-[10px] uppercase tracking-[0.08em] text-ink-faint m-0 mb-[14px] font-medium">
        {title}
      </h4>
      <ul className="list-none m-0 p-0 grid gap-2 [&_a]:font-mono [&_a]:text-[11px] [&_a]:tracking-[0.04em] [&_a]:text-ink-muted [&_a]:no-underline hover:[&_a]:text-ink hover:[&_a]:underline [&_a]:underline-offset-[3px]">
        {items.map((item, i) => (
          <li key={i}>{item}</li>
        ))}
      </ul>
    </div>
  )
}
