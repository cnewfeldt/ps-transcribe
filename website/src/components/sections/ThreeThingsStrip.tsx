import { Reveal } from '@/components/motion/Reveal'

type Card = {
  meta: string
  metaTone: 'default' | 'navy' | 'sage'
  title: string
  body: string
}

const metaToneMap: Record<Card['metaTone'], string> = {
  default: 'text-ink-faint',
  navy: 'text-accent-ink',
  sage: 'text-spk2-fg',
}

// Copy is verbatim from design/ps-transcribe-web-unzipped/index.html (lines 261-277).
const CARDS: Card[] = [
  {
    meta: '· 01 · Private by default',
    metaTone: 'default',
    title: 'Audio never leaves the machine.',
    body: 'Speech recognition runs on-device. No upload step, no API keys, no cloud fallback.',
  },
  {
    meta: '· 02 · Works with your vault',
    metaTone: 'sage',
    title: 'Saves to Obsidian, Notion, or both.',
    body: 'Works with your Obsidian vault or a Notion database to store transcriptions.',
  },
  {
    meta: '· 03 · Quiet interface',
    metaTone: 'navy',
    title: 'Designed to disappear while you work.',
    body: 'Paper palette, hairline rules, keyboard-first. One window, three columns. No tutorials, no modals, no celebrations.',
  },
]

export function ThreeThingsStrip() {
  return (
    <section className="py-10 md:py-14">
      <div className="mx-auto max-w-[1200px] px-6 md:px-10">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {CARDS.map((c, i) => (
            <Reveal key={i}>
              <div className="h-full rounded-card border-[0.5px] border-rule bg-paper p-6 shadow-lift">
                <span
                  className={`block font-mono text-[10px] uppercase tracking-[0.08em] ${metaToneMap[c.metaTone]}`}
                >
                  {c.meta}
                </span>
                <h4 className="mt-2 font-serif text-[20px] font-medium leading-[1.25] tracking-[-0.005em] text-ink">
                  {c.title}
                </h4>
                <p className="mt-2 font-sans text-[14.5px] leading-[1.55] text-ink-muted">
                  {c.body}
                </p>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  )
}
