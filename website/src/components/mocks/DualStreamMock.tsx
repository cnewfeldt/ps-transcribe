import { MockWindow } from '@/components/mocks/MockWindow'

// Bar heights ported from chronicle-mock.css / index.html lines 305-316 (mic)
// and 321-332 (sys audio). Inline style="height: X%" in the source; inline
// style here too because Tailwind arbitrary values can't cleanly express a
// literal percentage array without generating 12 separate classes per column.
// No motion timing offsets -- D-11 forbids animation on mini-mockups.
const MIC_BARS = [40, 80, 55, 90, 30, 70, 45, 85, 60, 35, 75, 50]
const SYS_BARS = [25, 55, 80, 40, 65, 30, 70, 85, 45, 60, 35, 55]

export function DualStreamMock() {
  return (
    <MockWindow title="Session · 00:14:32" className="p-[18px_20px] flex flex-col gap-[10px]">
      <div className="grid grid-cols-2 gap-[14px]">
        <StreamCard tone="navy" label="Microphone" name="You" bars={MIC_BARS} />
        <StreamCard tone="sage" label="System audio" name="Speaker 2" bars={SYS_BARS} />
      </div>
      <hr className="border-0 h-[0.5px] bg-rule mt-[10px]" />
      <div className="flex justify-between font-mono text-[10px] tracking-[0.05em] text-ink-faint pt-2">
        <span>VAD · trimming silences</span>
        <span>Parakeet-TDT · on-device</span>
      </div>
    </MockWindow>
  )
}

function StreamCard({
  tone,
  label,
  name,
  bars,
}: {
  tone: 'navy' | 'sage'
  label: string
  name: string
  bars: number[]
}) {
  const barColor = tone === 'navy' ? 'bg-accent-ink' : 'bg-spk2-rail'
  return (
    <div className="border-[0.5px] border-rule rounded-[8px] p-[12px] bg-paper">
      <h6 className="m-0 mb-2 flex justify-between font-mono text-[10px] uppercase tracking-[0.08em] text-ink-faint font-medium">
        <span>{label}</span>
        <span>{name}</span>
      </h6>
      <div className="flex items-end gap-[2px] h-[34px]" aria-hidden>
        {bars.map((h, i) => (
          <span
            key={i}
            className={`flex-1 rounded-[1px] ${barColor}`}
            style={{ height: `${h}%`, opacity: 0.55 }}
          />
        ))}
      </div>
    </div>
  )
}
