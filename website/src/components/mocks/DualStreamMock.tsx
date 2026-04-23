import { MockWindow } from '@/components/mocks/MockWindow'

// Dual-stream timeline. Two horizontal tracks sharing a time axis.
// The mic and system arrays are deliberately complementary: when one person
// is speaking the other's track is near-silent. This visualizes three things
// at once -- turn-taking (separate streams), silence detection (gaps stay
// visibly low), and clean separation even during the brief overlap region.
// Heights are 0-100. 0 = total silence (trimmed); 2-4 = ambient floor.
// No animation per D-11 (mini-mockups are static).
const MIC_TRACK = [
  0, 4, 28, 60, 78, 82, 70, 55, 40, 22, 8, 0,
  0, 2, 0, 0, 0, 0, 2, 0, 0, 4, 0, 0,
  18, 48, 72, 85, 78, 60, 52, 65, 78, 42, 24, 8,
  0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 4, 0,
]
const SYS_TRACK = [
  0, 0, 2, 0, 0, 4, 0, 0, 0, 2, 0, 0,
  12, 38, 68, 82, 90, 78, 62, 48, 32, 18, 6, 0,
  0, 2, 0, 0, 0, 2, 18, 42, 38, 22, 8, 0,
  22, 58, 80, 88, 74, 60, 45, 32, 55, 72, 50, 28,
]

const TIME_TICKS = ['00:00', '00:04', '00:08', '00:12']
const PLAYHEAD_PERCENT = 92 // ~00:14:32 position within a 16-minute window

export function DualStreamMock() {
  return (
    <MockWindow title="Session · 00:14:32" className="p-[18px_20px] flex flex-col gap-[10px]">
      <TrackRow tone="navy" label="MIC" name="YOU" samples={MIC_TRACK} />
      <TrackRow tone="sage" label="SYSTEM" name="SPEAKER 2" samples={SYS_TRACK} />
      <TimeAxis ticks={TIME_TICKS} playheadPercent={PLAYHEAD_PERCENT} />
      <hr className="border-0 h-[0.5px] bg-rule mt-[4px]" />
      <div className="flex justify-between font-mono text-[10px] tracking-[0.05em] text-ink-faint">
        <span>VAD · trimming silences</span>
        <span>Speech recognition · on-device</span>
      </div>
    </MockWindow>
  )
}

function TrackRow({
  tone,
  label,
  name,
  samples,
}: {
  tone: 'navy' | 'sage'
  label: string
  name: string
  samples: number[]
}) {
  const barColor = tone === 'navy' ? 'bg-accent-ink' : 'bg-spk2-rail'
  return (
    <div>
      <div className="flex justify-between font-mono text-[10px] uppercase tracking-[0.08em] text-ink-faint font-medium mb-[4px]">
        <span>{label} · {name}</span>
      </div>
      <div
        className="relative border-[0.5px] border-rule rounded-[4px] bg-paper h-[32px] px-[4px] flex items-center gap-[2px] overflow-hidden"
        aria-hidden
      >
        {samples.map((h, i) => (
          <span
            key={i}
            className={`flex-1 rounded-[0.5px] ${barColor}`}
            style={{ height: `${Math.max(h, 1)}%`, opacity: h > 6 ? 0.78 : 0.18 }}
          />
        ))}
      </div>
    </div>
  )
}

function TimeAxis({
  ticks,
  playheadPercent,
}: {
  ticks: string[]
  playheadPercent: number
}) {
  return (
    <div className="relative mt-[2px] pt-[6px]">
      <div className="flex justify-between font-mono text-[9px] tracking-[0.05em] text-ink-faint">
        {ticks.map((t) => (
          <span key={t}>{t}</span>
        ))}
      </div>
      <span
        className="absolute top-0 bottom-[-4px] w-[1px] bg-accent-ink"
        style={{ left: `${playheadPercent}%`, opacity: 0.55 }}
        aria-hidden
      />
      <span
        className="absolute font-mono text-[9px] tracking-[0.05em] text-accent-ink whitespace-nowrap"
        style={{ left: `calc(${playheadPercent}% - 20px)`, top: '-14px' }}
        aria-hidden
      >
        ▼ 00:14
      </span>
    </div>
  )
}
