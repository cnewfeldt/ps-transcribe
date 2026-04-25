'use client'

import { useEffect, useState } from 'react'
import type { ChangelogEntry } from '@/lib/changelog'
import { MetaLabel } from '@/components/ui'
import { SITE } from '@/lib/site'

type Props = { entries: ChangelogEntry[] }

/**
 * Convert a dotted version string into a slug suitable for HTML anchor IDs.
 * "2.1.0" → "v2-1-0". Mirrors the slug used by ReleaseCard so href="#vX-Y-Z"
 * matches the rendered article id.
 */
function versionSlug(version: string): string {
  return `v${version.replace(/\./g, '-')}`
}

/**
 * Format an ISO date like "2026-04-23" as a short "Apr 23" for the right-aligned
 * date next to each version in the aside list (per D-14).
 */
function shortDate(iso: string): string {
  const [, m, d] = iso.split('-').map(Number)
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ]
  return `${names[m - 1]} ${String(d).padStart(2, '0')}`
}

/**
 * Sticky left aside for the changelog page. Renders the Versions list and the
 * Subscribe block, with an IntersectionObserver scroll-spy that toggles
 * data-active on the link matching the release currently in view.
 *
 * Client component (per D-13). Mirrors the IntersectionObserver pattern from
 * docs/TableOfContents.tsx: rootMargin '-20% 0px -70% 0px', observer set up
 * in useEffect (SSR-safe). Initial activeSlug seeded from entries[0] so the
 * server-rendered HTML matches the client's first paint (T-15-05).
 *
 * Subscribe block (D-16): three external links — Sparkle appcast, GitHub
 * releases, RSS feed. All open in a new tab with rel="noopener" to prevent
 * reverse-tabnabbing of the marketing site (T-15-06).
 *
 * Sticky offset is top-16 (64px), matching our nav height. The mock used 84px,
 * which was its own nav height — adjusted per <specifics>.
 */
export function VersionsAside({ entries }: Props) {
  const [activeSlug, setActiveSlug] = useState<string | null>(
    entries.length > 0 ? versionSlug(entries[0].version) : null,
  )

  useEffect(() => {
    if (typeof window === 'undefined') return
    if (entries.length === 0) return
    const slugs = entries.map((e) => versionSlug(e.version))
    const observer = new IntersectionObserver(
      (intersections) => {
        for (const intersection of intersections) {
          if (intersection.isIntersecting) {
            setActiveSlug(intersection.target.id)
          }
        }
      },
      { rootMargin: '-20% 0px -70% 0px' },
    )
    for (const slug of slugs) {
      const el = document.getElementById(slug)
      if (el) observer.observe(el)
    }
    return () => observer.disconnect()
  }, [entries])

  // .cl-filters a base styling per <specifics>:
  //   display: flex; justify-content: space-between; padding: 5px 10px;
  //   border-radius: 6px; mono 11px / 0.04em; var(--color-ink-muted); no underline.
  // Hover and active state both use bg-paper-warm + text-ink (D-14).
  const linkBase =
    'flex items-center justify-between px-2.5 py-1 rounded-md font-mono text-[11px] tracking-[0.04em] no-underline text-ink-muted transition-colors duration-[120ms]'
  const linkActive = 'bg-paper-warm text-ink'
  const linkHover = 'hover:bg-paper-warm hover:text-ink'

  return (
    <aside className="sticky top-16 self-start">
      <MetaLabel className="block mb-3">Versions</MetaLabel>
      <ul className="list-none m-0 mb-7 p-0 grid gap-1">
        {entries.map((entry) => {
          const slug = versionSlug(entry.version)
          const isActive = activeSlug === slug
          return (
            <li key={slug}>
              <a
                href={`#${slug}`}
                data-active={isActive ? 'true' : undefined}
                className={`${linkBase} ${isActive ? linkActive : linkHover}`}
              >
                <span>v{entry.version}</span>
                <small className="text-ink-ghost">{shortDate(entry.date)}</small>
              </a>
            </li>
          )
        })}
      </ul>

      <MetaLabel className="block mb-3">Subscribe</MetaLabel>
      <ul className="list-none m-0 p-0 grid gap-1">
        <li>
          <a
            href={SITE.SPARKLE_APPCAST_URL}
            target="_blank"
            rel="noopener"
            className={`${linkBase} ${linkHover}`}
          >
            <span>Sparkle appcast</span>
          </a>
        </li>
        <li>
          <a
            href={SITE.RELEASES_URL}
            target="_blank"
            rel="noopener"
            className={`${linkBase} ${linkHover}`}
          >
            <span>GitHub releases</span>
          </a>
        </li>
        <li>
          <a
            href="/changelog/rss.xml"
            target="_blank"
            rel="noopener"
            className={`${linkBase} ${linkHover}`}
          >
            <span>RSS feed</span>
          </a>
        </li>
      </ul>
    </aside>
  )
}
