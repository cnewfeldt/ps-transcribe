import { Kbd, type KbdTone } from './Kbd'

type KeySpec = { k: string; tone?: KbdTone }
type Props = { keys: KeySpec[]; label: string; sub?: string }

export function ShortcutRow({ keys, label, sub }: Props) {
  return (
    <div className="grid grid-cols-[170px_1fr] gap-3.5 px-[18px] py-3 border-b-[0.5px] border-rule bg-paper items-center last:border-b-0">
      <div className="flex gap-1">
        {keys.map((key, i) => (
          <Kbd key={i} tone={key.tone ?? 'default'}>{key.k}</Kbd>
        ))}
      </div>
      <div className="text-ink text-[14.5px]">
        {label}
        {sub && <small className="block text-ink-muted text-[13px] mt-0.5">{sub}</small>}
      </div>
    </div>
  )
}
