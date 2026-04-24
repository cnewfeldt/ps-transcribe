import type { ReactNode } from 'react'
import { Sidebar } from '@/components/docs/Sidebar'

/**
 * Docs section layout. Three-column CSS grid.
 *
 * Columns:
 *   1 (240px): <Sidebar /> — rendered here, sticky positioned internally
 *   2 (1fr):   the page.mdx <article>, which pins itself via
 *              `lg:col-start-2 lg:col-end-3 md:col-start-2 md:col-end-3
 *               col-start-1 col-end-2`
 *   3 (200px): <TableOfContents />, rendered by the page.mdx, pinned to
 *              column 3 via `lg:col-start-3 lg:col-end-4 lg:row-start-1`
 *              and hidden below lg via `hidden lg:block`
 *
 * Responsive collapse:
 *   ≤ 820px (default `grid-cols-1`): only the <article> column; sidebar
 *     hidden via `hidden md:block` in Sidebar.tsx; TOC hidden via
 *     `hidden lg:block` in TableOfContents.tsx.
 *   820–1200px (`md:grid-cols-[240px_1fr]`): sidebar + article; TOC hidden.
 *   ≥ 1200px (`lg:grid-cols-[240px_1fr_200px]`): all three columns visible.
 *
 * The children wrapper uses `display: contents` so <article> and
 * <TableOfContents> rendered inside page.mdx become direct children of the
 * outer grid. That is the only contract page.mdx authors need to know.
 */
export default function DocsLayout({ children }: { children: ReactNode }) {
  return (
    <div className="mx-auto max-w-[1280px] min-h-[calc(100vh-64px)] grid grid-cols-1 md:grid-cols-[240px_1fr] lg:grid-cols-[240px_1fr_200px]">
      <Sidebar />
      <div className="contents">{children}</div>
    </div>
  )
}
