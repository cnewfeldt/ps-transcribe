type Props = { trail: string[] }

export function Crumbs({ trail }: Props) {
  return (
    <div className="font-mono text-[11px] tracking-[0.06em] uppercase text-ink-faint mb-[22px]">
      {trail.map((seg, i) => (
        <span key={i}>
          {i === trail.length - 1 ? (
            <b className="text-ink-muted font-normal">{seg}</b>
          ) : (
            <span>{seg}</span>
          )}
          {i < trail.length - 1 && <span> / </span>}
        </span>
      ))}
    </div>
  )
}
