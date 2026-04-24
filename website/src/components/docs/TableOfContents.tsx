'use client'

import { useEffect, useRef, useState } from 'react'

export type TocItem = { depth: 2 | 3; id: string; text: string }

type Props = { items: TocItem[] }

/**
 * Renders the "On this page" column. Designed to sit at the top level of the
 * docs grid (alongside, not inside, the page's <article>). Each page.mdx in
 * Plan 03/04 renders:
 *
 *   <article className="docs-article prose lg:col-start-2 lg:col-end-3 ..."> ... </article>
 *   <TableOfContents items={tableOfContents} />
 *
 * The outer docs/layout.tsx wraps {children} in a `display: contents` div so
 * both the <article> and this <nav> become direct grid children.
 */
export function TableOfContents({ items }: Props) {
  const [activeId, setActiveId] = useState<string | null>(null)
  const observerRef = useRef<IntersectionObserver | null>(null)

  useEffect(() => {
    if (items.length === 0) return
    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) {
            setActiveId(entry.target.id)
          }
        }
      },
      { rootMargin: '-20% 0px -70% 0px' },
    )
    observerRef.current = observer
    items.forEach(({ id }) => {
      const el = document.getElementById(id)
      if (el) observer.observe(el)
    })
    return () => {
      observer.disconnect()
      observerRef.current = null
    }
  }, [items])

  if (items.length === 0) return null

  return (
    <nav
      aria-label="On this page"
      className="hidden lg:block lg:col-start-3 lg:col-end-4 lg:row-start-1 sticky top-16 self-start h-[calc(100vh-64px)] overflow-y-auto px-[22px] pt-14 pb-14"
    >
      <h6 className="font-mono text-[10px] font-medium uppercase tracking-[0.1em] text-ink-faint m-0 mb-3">
        On this page
      </h6>
      <ul className="list-none m-0 p-0 grid gap-1 border-l-[0.5px] border-rule">
        {items.map((item) => {
          const isActive = activeId === item.id
          const base =
            'block px-3 py-1 font-mono text-[10.5px] tracking-[0.04em] uppercase no-underline -ml-[0.5px] border-l-[1px] transition-colors duration-[120ms]'
          const activeClasses = 'text-ink border-l-accent-ink'
          const idleClasses = 'text-ink-faint border-l-transparent hover:text-ink'
          const indent = item.depth === 3 ? 'pl-6' : ''
          return (
            <li key={item.id}>
              <a
                href={`#${item.id}`}
                className={`${base} ${indent} ${isActive ? activeClasses : idleClasses}`}
              >
                {item.text}
              </a>
            </li>
          )
        })}
      </ul>
    </nav>
  )
}
