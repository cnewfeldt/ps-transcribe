#!/usr/bin/env node
// Phase 13 landing-page validator.
// Asserts LAND-01..LAND-07 against the prerendered landing HTML from `next build`.
// Run AFTER `pnpm --filter ps-transcribe-website build`.

import fs from 'node:fs'
import path from 'node:path'

const root = process.cwd()
// Likely locations where Next 16 emits the prerendered `/` route.
const candidates = [
  '.next/server/app/index.html',
  '.next/server/app/page.html',
  '.next/server/app/(root)/page.html',
  '.next/server/app/(landing)/page.html',
]
let htmlPath = null
for (const c of candidates) {
  const p = path.join(root, c)
  if (fs.existsSync(p)) { htmlPath = p; break }
}
// Fallback: scan .next/server/app/**/*.html for any file containing the hero headline.
if (!htmlPath) {
  const appDir = path.join(root, '.next/server/app')
  if (fs.existsSync(appDir)) {
    const walk = (dir) => {
      for (const name of fs.readdirSync(dir)) {
        const full = path.join(dir, name)
        const stat = fs.statSync(full)
        if (stat.isDirectory()) { const hit = walk(full); if (hit) return hit }
        else if (name.endsWith('.html')) {
          const content = fs.readFileSync(full, 'utf8')
          if (content.includes('Your meeting audio')) return full
        }
      }
      return null
    }
    htmlPath = walk(appDir)
  }
}
if (!htmlPath) {
  console.error('ERR: could not find the prerendered landing HTML under .next/server/app/.')
  console.error('     Run `pnpm --filter ps-transcribe-website build` first.')
  process.exit(2)
}
const html = fs.readFileSync(htmlPath, 'utf8')
console.log(`Scanning ${path.relative(root, htmlPath)}\n`)

const must = [
  // LAND-01 — hero headline + value prop + CTA
  ['Your meeting audio', 'LAND-01 hero headline line 1'],
  ['never leaves your Mac', 'LAND-01 hero headline line 2 (italic em)'],
  ['Download for macOS', 'LAND-01 primary CTA text'],
  // LAND-02 — DMG URL
  ['releases/latest/download/PS%20Transcribe.dmg', 'LAND-02 DMG URL (URL-encoded)'],
  // LAND-03 — screenshot + alt
  ['app-screenshot', 'LAND-03 screenshot asset reference'],
  ['meeting transcript with Library, Transcript, and Details columns', 'LAND-03 alt text'],
  // LAND-04 — four features
  ['Dual-stream capture', 'LAND-04 feature 1 meta'],
  ['Microphone and system audio, recorded in parallel.', 'LAND-04 feature 1 headline'],
  ['Transcript view', 'LAND-04 feature 2 meta'],
  ['Chat bubbles. Not a wall of text.', 'LAND-04 feature 2 headline'],
  ['Obsidian vault', 'LAND-04 feature 3 meta'],
  ['Every session lands where your notes already live.', 'LAND-04 feature 3 headline'],
  ['Notion, on send', 'LAND-04 feature 4 meta'],
  ['Push finished sessions to a database, one key away.', 'LAND-04 feature 4 headline'],
  // LAND-05 — shortcut chips
  ['⌘R', 'LAND-05 chip ⌘R'],
  ['⌘⇧R', 'LAND-05 chip ⌘⇧R'],
  ['⌘.', 'LAND-05 chip ⌘.'],
  ['⌘⇧S', 'LAND-05 chip ⌘⇧S'],
  // LAND-06 — nav links
  ['href="/docs"', 'LAND-06 nav link to /docs'],
  ['href="/changelog"', 'LAND-06 nav link to /changelog'],
  ['href="https://github.com/cnewfeldt/ps-transcribe"', 'LAND-06 nav link to GitHub'],
  // LAND-07 — footer
  ['© 2026', 'LAND-07 copyright'],
  ['License · MIT', 'LAND-07 MIT acknowledgment'],
  ['Sparkle appcast', 'LAND-07 footer product link'],
  ['Download DMG', 'LAND-07 footer product link'],
  ['Report an issue', 'LAND-07 footer source link'],
  // D-15 — build-time version stamp
  ['Ver ', 'D-15 hero eyebrow version label prefix'],
  ['Released ', 'D-15 hero eyebrow release-date prefix'],
]

const forbidden = [
  ['macOS 14+', 'outdated macOS min (should be 26+)'],
  ['PS-Transcribe.dmg', 'wrong DMG filename (should be PS%20Transcribe.dmg)'],
  ['Apple Silicon & Intel', 'outdated arch (Apple Silicon only)'],
  ['content="noindex"', 'noindex must NOT ship on the landing page'],
]

let failed = 0
for (const [needle, label] of must) {
  if (!html.includes(needle)) { console.error(`MISS ${label}: "${needle}"`); failed++ }
  else                         console.log(`OK   ${label}`)
}
for (const [needle, label] of forbidden) {
  if (html.includes(needle))  { console.error(`BAD  ${label}: found forbidden "${needle}"`); failed++ }
  else                         console.log(`OK   forbidden-absent: ${label}`)
}

if (failed > 0) { console.error(`\n${failed} failure(s) — fix before shipping.`); process.exit(1) }
console.log('\nAll assertions passed.')
