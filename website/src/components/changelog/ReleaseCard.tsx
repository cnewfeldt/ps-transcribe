import type { CSSProperties } from 'react'
import type { ChangelogEntry } from '@/lib/changelog'
import { Pill } from '@/components/ui'
import { classifySection, sectionColors } from '@/lib/section-color'
import { renderInlineMarkdown } from '@/lib/inline-markdown'

type Props = {
  entry: ChangelogEntry
  /** True for entries[0] — applies the navy-tinted border + shadow-lift treatment per D-10 and renders the "Current" pill per D-08. */
  isCurrent: boolean
  /** True for entries[2..] — applies the opacity 0.92 treatment per D-11. */
  isOlder: boolean
}

/**
 * Convert a dotted version string into a slug suitable for HTML anchor IDs.
 * "2.1.0" → "v2-1-0". Mirrors the slug used by VersionsAside scroll-spy and the
 * RSS Route Handler so the same anchor target works across all three.
 */
function versionSlug(version: string): string {
  return `v${version.replace(/\./g, '-')}`
}

/**
 * Renders one release as a card: header (date + version + auto-derived pills)
 * + sections grid. Server component (no 'use client') — pure data → DOM.
 *
 * Visual variants per Phase 15 D-10/D-11:
 *  - default: 0.5px ink-rule border
 *  - isCurrent: navy-tinted border (rgba 43,74,122,0.2) + shadow-lift
 *  - isOlder: opacity 0.92
 *
 * Pill rules per D-08:
 *  - Current pill renders when isCurrent is true (entries[0])
 *  - Breaking pill renders when ANY section title contains the word "breaking"
 *    (case-insensitive). Both pills can render simultaneously.
 *
 * Section coloring per D-03/D-04/D-05:
 *  - classifySection() maps each section.title to one of 5 buckets
 *  - sectionColors[bucket].label colors the H4 (mono 10px uppercase)
 *  - sectionColors[bucket].dot colors the 4px circular bullet dot
 *
 * Inline rendering per D-19:
 *  - Each bullet's text flows through renderInlineMarkdown(), which handles
 *    backticks, **bold**, and [text](url) with a URL allowlist (T-15-01).
 *
 * No timeline-dot (D-21), no foot row (D-20), no codename/summary (D-06/D-07).
 *
 * Legacy releases (v1.0.0..v1.2.0) whose CHANGELOG entries use flat bullets
 * with no `### Section` heading flow through the same code path: the parser
 * (Plan 15-01 Task 5) synthesizes a single `{ title: 'Changes', items: [...] }`
 * section, which classifies to the 'default' bucket — visually quiet by design.
 */
export function ReleaseCard({ entry, isCurrent, isOlder }: Props) {
  const slug = versionSlug(entry.version)
  const hasBreaking = entry.sections.some((s) => /\bbreaking\b/i.test(s.title))

  // Card chrome per .release / .release--current / .release--older mock values.
  // px-9 (36px) horizontal + py-8 (32px) vertical = mock's "padding: 32px 36px".
  // rounded-[10px] = mock's "border-radius: 10px".
  // border-[0.5px] = the half-pixel hairline pattern Phase 12 established.
  const baseClasses = 'relative border-[0.5px] rounded-[10px] px-9 py-8 bg-paper'
  let extraClasses = 'border-rule'
  let extraStyle: CSSProperties | undefined = undefined
  if (isCurrent) {
    // Navy-tinted border + shadow-lift per D-10. The rgba is a token-adjacent
    // value not in the Tailwind palette; inline style preserves mock fidelity
    // without inflating the JIT class set.
    extraClasses = 'shadow-lift'
    extraStyle = { borderColor: 'rgba(43, 74, 122, 0.2)' }
  } else if (isOlder) {
    extraClasses = 'border-rule opacity-[0.92]'
  }

  return (
    <article id={slug} className={`${baseClasses} ${extraClasses}`} style={extraStyle}>
      {/* HEAD: date + version (left) | pills (right). 18px pb / 20px mb. */}
      <div className="flex items-baseline justify-between gap-[18px] pb-[18px] mb-5 border-b-[0.5px] border-rule flex-wrap">
        <div className="flex items-baseline gap-5 flex-wrap">
          <span className="font-mono text-[11px] tracking-[0.08em] uppercase text-ink-faint">
            {entry.dateHuman}
          </span>
          <h2 className="font-serif text-[32px] font-normal tracking-[-0.01em] text-ink leading-none m-0">
            v{entry.version}
          </h2>
        </div>
        <div className="flex gap-2 items-center flex-wrap">
          {isCurrent ? <Pill variant="live">Current</Pill> : null}
          {hasBreaking ? <Pill variant="breaking">Breaking</Pill> : null}
        </div>
      </div>

      {/* SECTIONS GRID: 20px vertical gap between sections per .release__sections. */}
      <div className="grid gap-5">
        {entry.sections.map((section, sIdx) => {
          const bucket = classifySection(section.title)
          const colors = sectionColors[bucket]
          return (
            <div
              key={`${slug}-sec-${sIdx}`}
              // .sec layout: 110px label column / 1fr items column, gap 20px,
              // align-items: start. Below 680px (mock breakpoint, NOT Tailwind's
              // sm: 640px), collapse to single column with 4px gap. Use the
              // arbitrary breakpoint utility for exact mock fidelity.
              className="grid grid-cols-1 min-[680px]:grid-cols-[110px_1fr] gap-1 min-[680px]:gap-5 items-start"
            >
              <h4
                className="font-mono text-[10px] tracking-[0.1em] uppercase font-medium m-0 mt-1.5"
                style={{ color: colors.label }}
              >
                {section.title}
              </h4>
              <ul className="list-none m-0 p-0 grid gap-2">
                {section.items.map((item, iIdx) => (
                  <li
                    key={`${slug}-sec-${sIdx}-item-${iIdx}`}
                    className="flex gap-2.5 text-[14.5px] text-ink leading-[1.55]"
                  >
                    <span
                      aria-hidden
                      className="flex-shrink-0 w-1 h-1 rounded-full mt-2.5"
                      style={{ backgroundColor: colors.dot }}
                    />
                    <span className="min-w-0">
                      {renderInlineMarkdown(item, `${slug}-${sIdx}-${iIdx}`)}
                    </span>
                  </li>
                ))}
              </ul>
            </div>
          )
        })}
      </div>
      {/* No foot row (D-20). No timeline-dot (D-21). No codename/summary (D-06/D-07). */}
    </article>
  )
}
