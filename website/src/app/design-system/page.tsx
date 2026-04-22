import type { Metadata } from 'next'
import {
  Button,
  Card,
  CodeBlock,
  MetaLabel,
  SectionHeading,
} from '@/components/ui'

export const metadata: Metadata = {
  title: 'Design System',
  robots: {
    index: false,
    follow: false,
  },
}

type Swatch = {
  name: string
  hex: string
  textClass: string // so we pick a readable label color per swatch
}

const palette: Array<{ group: string; swatches: Swatch[] }> = [
  {
    group: 'Paper',
    swatches: [
      { name: 'paper', hex: '#FAFAF7', textClass: 'text-ink' },
      { name: 'paper-warm', hex: '#F4F1EA', textClass: 'text-ink' },
      { name: 'paper-soft', hex: '#EEEAE0', textClass: 'text-ink' },
    ],
  },
  {
    group: 'Rules',
    swatches: [
      { name: 'rule', hex: 'rgba(30,30,28,0.08)', textClass: 'text-ink' },
      { name: 'rule-strong', hex: 'rgba(30,30,28,0.14)', textClass: 'text-ink' },
    ],
  },
  {
    group: 'Ink',
    swatches: [
      { name: 'ink', hex: '#1A1A17', textClass: 'text-paper' },
      { name: 'ink-muted', hex: '#595954', textClass: 'text-paper' },
      { name: 'ink-faint', hex: '#8A8A82', textClass: 'text-paper' },
      { name: 'ink-ghost', hex: '#B8B8AF', textClass: 'text-ink' },
    ],
  },
  {
    group: 'Accents',
    swatches: [
      { name: 'accent-ink', hex: '#2B4A7A', textClass: 'text-paper' },
      { name: 'accent-soft', hex: '#DFE6F0', textClass: 'text-ink' },
      { name: 'accent-tint', hex: '#F1F4F9', textClass: 'text-ink' },
    ],
  },
  {
    group: 'Sage (Speaker 2)',
    swatches: [
      { name: 'spk2-bg', hex: '#E6ECEA', textClass: 'text-ink' },
      { name: 'spk2-fg', hex: '#2D4A43', textClass: 'text-paper' },
      { name: 'spk2-rail', hex: '#7FA093', textClass: 'text-paper' },
    ],
  },
  {
    group: 'Status',
    swatches: [
      { name: 'rec-red', hex: '#C24A3E', textClass: 'text-paper' },
      { name: 'live-green', hex: '#4A8A5E', textClass: 'text-paper' },
    ],
  },
]

export default function DesignSystemPage() {
  return (
    <main className="bg-paper text-ink min-h-dvh">
      <div className="mx-auto max-w-[1200px] px-10 py-16 md:py-24">
        <header className="mb-16">
          <MetaLabel>Phase 12 -- Chronicle design system</MetaLabel>
          <SectionHeading as="h1" className="mt-3 text-[clamp(36px,4.5vw,52px)]">
            The quiet chronicle, ported to the web.
          </SectionHeading>
          <p className="mt-4 max-w-[54ch] font-sans text-[17px] leading-[1.55] text-ink-muted">
            Records both sides of your Zoom call, locally. This page exists to verify the
            palette, primitives, and typography render with the same editorial calm as the
            macOS app. Not indexed. Not linked from the site.
          </p>
        </header>

        <section className="mb-16">
          <MetaLabel>Typography scale</MetaLabel>
          <Card className="mt-3">
            <div className="space-y-6">
              <div>
                <MetaLabel>Hero -- Spectral</MetaLabel>
                <p className="mt-2 font-serif text-[clamp(40px,5.2vw,56px)] leading-[1.08] tracking-[-0.015em] text-ink">
                  Transcription that stays on your machine.
                </p>
              </div>
              <div>
                <MetaLabel>Section -- Spectral</MetaLabel>
                <p className="mt-2 font-serif text-[clamp(26px,3vw,32px)] leading-[1.15] tracking-[-0.01em] text-ink">
                  One recording, two clean streams.
                </p>
              </div>
              <div>
                <MetaLabel>Feature -- Spectral</MetaLabel>
                <p className="mt-2 font-serif text-[clamp(22px,2.4vw,26px)] leading-[1.2] tracking-[-0.005em] text-ink">
                  Save to the vault, auto-send to the database.
                </p>
              </div>
              <div>
                <MetaLabel>Body -- Inter</MetaLabel>
                <p className="mt-2 font-sans text-[15px] leading-[1.65] text-ink-muted max-w-[54ch]">
                  PS Transcribe is a native macOS app for private, on-device transcription of
                  meetings and voice memos. Everything runs locally -- no cloud APIs, no
                  telemetry, no LLM analysis of transcript content.
                </p>
              </div>
            </div>
          </Card>
        </section>

        <section className="mb-16">
          <MetaLabel>Palette</MetaLabel>
          <SectionHeading className="mt-3">Sixteen tokens, light mode only.</SectionHeading>
          <div className="mt-6 space-y-8">
            {palette.map((group) => (
              <div key={group.group}>
                <MetaLabel>{group.group}</MetaLabel>
                <div className="mt-3 grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
                  {group.swatches.map((s) => (
                    <div
                      key={s.name}
                      className={`${s.textClass} border-[0.5px] border-rule rounded-card p-4`}
                      style={{ backgroundColor: `var(--color-${s.name})` }}
                    >
                      <div className="font-mono text-[11px] tracking-[0.04em]">{s.name}</div>
                      <div className="mt-1 font-mono text-[11px] tracking-[0.04em] opacity-70">
                        {s.hex}
                      </div>
                      <div className="mt-2 font-mono text-[10px] tracking-[0.04em] opacity-50">
                        var(--color-{s.name})
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </section>

        <section className="mb-16">
          <MetaLabel>Primitives</MetaLabel>
          <SectionHeading className="mt-3">Five components, one surface.</SectionHeading>

          <div className="mt-6 space-y-10">
            <div>
              <MetaLabel>Button</MetaLabel>
              <div className="mt-3 flex flex-wrap items-center gap-3">
                <Button variant="primary">Download for macOS</Button>
                <Button variant="secondary">View on GitHub</Button>
              </div>
            </div>

            <div>
              <MetaLabel>Card</MetaLabel>
              <div className="mt-3">
                <Card>
                  <MetaLabel>Private by default</MetaLabel>
                  <SectionHeading as="h3" className="mt-2 text-[clamp(22px,2.4vw,26px)]">
                    No cloud, no telemetry.
                  </SectionHeading>
                  <p className="mt-3 font-sans text-[15px] leading-[1.65] text-ink-muted max-w-[54ch]">
                    Speech recognition runs on-device through a local FluidAudio model. Your
                    meeting audio never leaves the machine.
                  </p>
                </Card>
              </div>
            </div>

            <div>
              <MetaLabel>MetaLabel</MetaLabel>
              <div className="mt-3 flex flex-wrap items-center gap-6">
                <MetaLabel>Features</MetaLabel>
                <MetaLabel>Changelog</MetaLabel>
                <MetaLabel>Apr 20, 2026</MetaLabel>
              </div>
            </div>

            <div>
              <MetaLabel>SectionHeading</MetaLabel>
              <div className="mt-3">
                <SectionHeading>Records both sides of your call.</SectionHeading>
              </div>
            </div>

            <div>
              <MetaLabel>CodeBlock</MetaLabel>
              <div className="mt-3 space-y-4">
                <p className="font-sans text-[15px] leading-[1.65] text-ink-muted">
                  Inline: press <CodeBlock inline>{'\u2318R'}</CodeBlock> to start a meeting
                  recording, or <CodeBlock inline>{'\u2318\u21e7R'}</CodeBlock> for a voice
                  memo.
                </p>
                <CodeBlock>{`import { Button } from '@/components/ui'

export function CTA() {
  return <Button variant="primary">Download for macOS</Button>
}`}</CodeBlock>
              </div>
            </div>
          </div>
        </section>

        <footer className="mt-24 border-t-[0.5px] border-rule pt-8">
          <MetaLabel>Not indexed. Not in sitemap.</MetaLabel>
          <p className="mt-2 font-sans text-[13px] leading-[1.6] text-ink-faint max-w-[54ch]">
            This page is reachable only if you know the URL. Search engines receive a
            noindex, nofollow signal and sitemap.ts does not list it.
          </p>
        </footer>
      </div>
    </main>
  )
}
