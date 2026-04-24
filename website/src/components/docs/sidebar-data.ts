/**
 * Authoritative sidebar descriptor for /docs/*.
 *
 * Assembled at build time from the `doc` exports of every
 * src/app/docs/*\/page.mdx (via scripts/build-sidebar-data.mjs, which runs
 * on `pnpm predev` and `pnpm prebuild`).
 *
 * Phase 14 D-08: sidebar structure is build-time assembled from the `doc`
 * exports of each page.mdx. Authors add a new page by creating
 * src/app/docs/{slug}/page.mdx with a `doc` export — no edits to this file
 * or any other config are required (ROADMAP SC-1).
 *
 * Consumers:
 *   - Sidebar.tsx     → renders groups + links
 *   - PrevNext.tsx    → auto-derives prev/next from DOC_ORDER
 *   - sitemap.ts      → emits /docs/* URLs
 *   - Plan 03/04 doc exports are the authoritative source for their own slugs
 */

import { DISCOVERED_DOCS } from './sidebar-data.generated'

export type SidebarItem = {
  slug: string
  href: string
  navTitle: string
}

export type SidebarGroup = {
  label: string
  items: SidebarItem[]
}

/** Canonical group render order. Groups absent from DISCOVERED_DOCS simply do not render. */
const GROUP_ORDER = ['Start here', 'Reference', 'Help'] as const

function buildSidebar(): SidebarGroup[] {
  const byGroup = new Map<string, { navTitle: string; slug: string; href: string; order: number }[]>()
  for (const d of DISCOVERED_DOCS) {
    const bucket = byGroup.get(d.group) ?? []
    bucket.push({ navTitle: d.navTitle, slug: d.slug, href: d.href, order: d.order })
    byGroup.set(d.group, bucket)
  }

  const groups: SidebarGroup[] = []
  for (const label of GROUP_ORDER) {
    const bucket = byGroup.get(label)
    if (!bucket || bucket.length === 0) continue
    const items = bucket
      .slice()
      .sort((a, b) => a.order - b.order)
      .map(({ navTitle, slug, href }) => ({ navTitle, slug, href }))
    groups.push({ label, items })
  }
  // Any ad-hoc groups discovered that aren't in GROUP_ORDER are appended at the end,
  // alphabetically. This keeps SC-1 honest: a new page with a new group name still ships.
  const known = new Set<string>(GROUP_ORDER as readonly string[])
  const extras = Array.from(byGroup.keys()).filter((g) => !known.has(g)).sort()
  for (const label of extras) {
    const bucket = byGroup.get(label)!
    const items = bucket
      .slice()
      .sort((a, b) => a.order - b.order)
      .map(({ navTitle, slug, href }) => ({ navTitle, slug, href }))
    groups.push({ label, items })
  }
  return groups
}

export const sidebar: SidebarGroup[] = buildSidebar()

/** Flattened linear order for PrevNext auto-derivation and sitemap emission. */
export const DOC_ORDER: SidebarItem[] = sidebar.flatMap((g) => g.items)
