import fs from 'node:fs'
import path from 'node:path'

export type ChangelogSection = { title: string; items: string[] }
export type ChangelogEntry = {
  version: string       // "2.1.0"
  versionShort: string  // "2.1" (strip trailing .0 if present)
  date: string          // "2026-04-20"
  dateHuman: string     // "Apr 20, 2026"
  sections: ChangelogSection[]
}

// Matches `## [2.1.0] — 2026-04-20` (em-dash) OR `## [2.1.0] - 2026-04-20` (hyphen).
// Both separators allowed because Markdown formatting drifts across releases.
const RE_VERSION = /^##\s*\[([^\]]+)\]\s*[—-]\s*(\d{4}-\d{2}-\d{2})\s*$/
const RE_SECTION = /^###\s+(.+)$/
const RE_BULLET = /^-\s+(.+)$/

let cached: ChangelogEntry[] | null = null

export function getAllReleases(): ChangelogEntry[] {
  if (cached) return cached
  // process.cwd() resolves to the Next.js project dir (/website). CHANGELOG is at repo root.
  const filePath = path.join(process.cwd(), '..', 'CHANGELOG.md')
  const raw = fs.readFileSync(filePath, 'utf8')
  const lines = raw.split('\n')
  const entries: ChangelogEntry[] = []
  let current: ChangelogEntry | null = null
  let currentSection: ChangelogSection | null = null

  for (const line of lines) {
    const v = line.match(RE_VERSION)
    if (v) {
      current = {
        version: v[1],
        versionShort: v[1].replace(/\.0$/, ''),
        date: v[2],
        dateHuman: humanDate(v[2]),
        sections: [],
      }
      currentSection = null
      entries.push(current)
      continue
    }
    if (!current) continue
    const s = line.match(RE_SECTION)
    if (s) {
      currentSection = { title: s[1].trim(), items: [] }
      current.sections.push(currentSection)
      continue
    }
    const b = line.match(RE_BULLET)
    if (b) {
      // Orphan-bullet case: 4 oldest releases (v1.0.0..v1.2.0) place bullets
      // directly under the `## [version]` line with no `### Section` heading.
      // Synthesize a default 'Changes' section so the card renders bullets
      // instead of an empty card. The classifier in lib/section-color.ts
      // routes 'Changes' to the 'default' bucket (visually quiet).
      if (!currentSection) {
        currentSection = { title: 'Changes', items: [] }
        current.sections.push(currentSection)
      }
      currentSection.items.push(b[1].trim())
    }
  }

  cached = entries
  return entries
}

export function getLatestRelease(): ChangelogEntry {
  const all = getAllReleases()
  if (!all.length) throw new Error('CHANGELOG.md contains no releases')
  return all[0]
}

function humanDate(iso: string): string {
  const [y, m, d] = iso.split('-').map(Number)
  const names = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
  return `${names[m - 1]} ${d}, ${y}`
}
