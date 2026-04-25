import type { Metadata } from 'next'
import { getAllReleases } from '@/lib/changelog'
import { MetaLabel } from '@/components/ui'
import { ReleaseCard } from '@/components/changelog/ReleaseCard'
import { VersionsAside } from '@/components/changelog/VersionsAside'

/**
 * Changelog page metadata.
 *
 * Title and description are concise — feed/preview consumers (OG cards, browser
 * tab, search engine snippets) want a tight identifier here, not the long-form
 * hero copy.
 */
export const metadata: Metadata = {
  title: 'Changelog',
  description: 'Release notes for PS Transcribe — every version, newest first.',
  openGraph: {
    title: 'Changelog · PS Transcribe',
    description: 'Release notes for PS Transcribe — every version, newest first.',
    type: 'website',
    url: 'https://ps-transcribe-web.vercel.app/changelog',
  },
}

/**
 * Server component: parses CHANGELOG.md at build time via getAllReleases() and
 * composes Wave 2's ReleaseCard + VersionsAside into the two-column changelog
 * layout described in the design mock (chronicle-mock).
 *
 * Layout:
 *   1. Hero — bordered bottom, MetaLabel + serif H1 + paragraph subcopy
 *   2. Stream — 180px aside | 1fr release stream, gap 48px desktop / 22px mobile
 *
 * Container width is locked at max-w-[1200px] (the site convention since
 * Phase 13). The mock referenced 1280px but the rest of the site converged
 * on 1200px — see <container_width_decision> in 15-03-PLAN.md.
 *
 * Variant treatment per Phase 15 D-10/D-11:
 *   - entries[0] gets isCurrent=true (navy-tinted border + shadow-lift, Current pill)
 *   - entries[2..] get isOlder=true (opacity 0.92)
 *   - entries[1] gets neither (default border, no opacity adjustment)
 *
 * Nav + Footer come from app/layout.tsx — DO NOT re-mount them here.
 */
export default function ChangelogPage() {
  const entries = getAllReleases()

  return (
    <>
      {/* HERO: padding 64px top / 40px bottom, hairline border below */}
      <section className="border-b-[0.5px] border-rule">
        <div className="mx-auto max-w-[1200px] px-6 md:px-10 pt-16 pb-10">
          <MetaLabel className="block mb-[18px]">Changelog</MetaLabel>
          <h1 className="font-serif font-normal text-[clamp(40px,5vw,56px)] tracking-[-0.015em] leading-[1.08] m-0 text-ink">
            Every release.
          </h1>
          <p className="text-ink-muted max-w-[52ch] mt-[18px] text-[17px] leading-[1.55]">
            Notes from each version of PS Transcribe, newest first. Auto-update through Sparkle will always bring you here if you want the full picture.
          </p>
        </div>
      </section>

      {/* STREAM: 180px aside | 1fr stream, gap 48px (gap-12), max-w 1200px (site convention).
          Below 820px: single column, gap 22px (gap-[22px]).
          pt-12 = 48px, pb-24 = 96px (mock values for top/bottom padding around the stream). */}
      <div className="mx-auto max-w-[1200px] px-6 md:px-10 pt-12 pb-24 grid gap-[22px] min-[820px]:grid-cols-[180px_1fr] min-[820px]:gap-12">
        <VersionsAside entries={entries} />
        <main className="flex flex-col gap-7">
          {entries.map((entry, i) => (
            <ReleaseCard
              key={entry.version}
              entry={entry}
              isCurrent={i === 0}
              isOlder={i >= 2}
            />
          ))}
        </main>
      </div>
    </>
  )
}
