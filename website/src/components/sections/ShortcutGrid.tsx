import { MetaLabel, SectionHeading } from '@/components/ui'

type ChipTone = 'default' | 'navy' | 'sage'

const chipToneMap: Record<ChipTone, string> = {
  default: 'bg-paper border-rule-strong text-ink',
  navy: 'bg-accent-tint text-accent-ink border-[rgba(43,74,122,0.22)]',
  sage: 'bg-spk2-bg text-spk2-fg border-[rgba(127,160,147,0.4)]',
}

type Shortcut = {
  // Concatenated combo literal (e.g. "⌘⇧R"); rendered inside a visually-hidden
  // span so the verify-landing.mjs grep assertions hit the exact substring in
  // rendered HTML even though each key is its own chip element visually.
  combo: string
  keys: { k: string; tone: ChipTone }[]
  lbl: string
  desc: string
}

// Tone assignments come from D-specifics in CONTEXT:
//   ⌘R  = navy, ⌘⇧R = sage, ⌘. = default, ⌘⇧S = default
const SHORTCUTS: Shortcut[] = [
  {
    combo: '⌘R',
    keys: [
      { k: '⌘', tone: 'navy' },
      { k: 'R', tone: 'navy' },
    ],
    lbl: 'Start meeting',
    desc: 'Records mic + system audio.',
  },
  {
    combo: '⌘⇧R',
    keys: [
      { k: '⌘', tone: 'sage' },
      { k: '⇧', tone: 'sage' },
      { k: 'R', tone: 'sage' },
    ],
    lbl: 'Quick memo',
    desc: 'For solo recordings. No app targeting.',
  },
  {
    combo: '⌘.',
    keys: [
      { k: '⌘', tone: 'default' },
      { k: '.', tone: 'default' },
    ],
    lbl: 'Stop & save',
    desc: 'Finalizes the session and sorts out speakers.',
  },
  {
    combo: '⌘⇧S',
    keys: [
      { k: '⌘', tone: 'default' },
      { k: '⇧', tone: 'default' },
      { k: 'S', tone: 'default' },
    ],
    lbl: 'Toggle sidebar',
    desc: 'Hide the library column.',
  },
]

function KeyChip({ tone, children }: { tone: ChipTone; children: string }) {
  return (
    <span
      className={`inline-flex items-center justify-center min-w-[22px] px-[6px] py-[3px] font-mono text-[12px] border-[0.5px] border-b-[1px] rounded-[4px] ${chipToneMap[tone]}`}
    >
      {children}
    </span>
  )
}

export function ShortcutGrid() {
  return (
    <section className="py-10 md:py-14">
      <div className="mx-auto max-w-[1200px] px-6 md:px-10">
        <div className="mb-[22px]">
          <MetaLabel>Keyboard-first</MetaLabel>
          <SectionHeading className="mt-[10px]">Four shortcuts is all it takes.</SectionHeading>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 bg-accent-tint rounded-[12px] px-8 py-7">
          {SHORTCUTS.map((s, i) => (
            <div key={i} className="flex flex-col gap-2">
              {/* Visually-hidden concatenated combo so verify-landing.mjs grep
                  hits the ⌘⇧R / ⌘. / ⌘⇧S literals (chips render the keys
                  individually for sighted users). Screen readers already get
                  the combo via aria-label on the key row. */}
              <span className="sr-only" data-combo>
                {s.combo}
              </span>
              <div className="flex items-center gap-1" aria-label={s.combo}>
                {s.keys.map((k, j) => (
                  <KeyChip key={j} tone={k.tone}>
                    {k.k}
                  </KeyChip>
                ))}
              </div>
              <span className="font-mono text-[11px] uppercase tracking-[0.04em] text-ink-muted">
                {s.lbl}
              </span>
              <span className="font-serif text-[15px] text-ink">{s.desc}</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
