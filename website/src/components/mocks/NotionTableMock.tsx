import { MockWindow } from '@/components/mocks/MockWindow'

type Row = {
  name: string
  date: string
  tag: string
  dur: string
  isNew?: boolean
}

// Rows ported verbatim from design/.../index.html lines 448-450.
// Last row carries isNew=true -- renders with accent-tint bg + accent-ink fg
// to match the mock's `.new` class highlight.
const ROWS: Row[] = [
  { name: 'Infra planning', date: 'Apr 18', tag: 'meeting', dur: '18m' },
  { name: 'Design review', date: 'Apr 19', tag: 'design', dur: '41m' },
  {
    name: 'Product sync — Apr 22',
    date: 'Just now',
    tag: 'product',
    dur: '32m',
    isNew: true,
  },
]

export function NotionTableMock() {
  return (
    <MockWindow title="Notion · Meetings DB" className="p-0">
      <div className="flex justify-between font-mono text-[10px] uppercase tracking-[0.08em] text-ink-faint border-b-[0.5px] border-rule px-[14px] py-[10px]">
        <span>Name</span>
        <span>4 properties</span>
      </div>
      <table className="w-full border-collapse">
        <tbody>
          {ROWS.map((r, i) => (
            <tr
              key={i}
              className={`${
                i < ROWS.length - 1 ? 'border-b-[0.5px] border-rule' : ''
              } ${r.isNew ? 'bg-accent-tint' : ''}`}
            >
              <td
                className={`px-[14px] py-[8px] font-sans text-[12px] ${
                  r.isNew ? 'text-accent-ink font-medium' : 'text-ink'
                }`}
              >
                {r.name}
              </td>
              <td
                className={`px-[14px] py-[8px] font-sans text-[12px] ${
                  r.isNew ? 'text-accent-ink' : 'text-ink-muted'
                }`}
              >
                {r.date}
              </td>
              <td className="px-[14px] py-[8px]">
                <span className="inline-block font-mono text-[9px] uppercase tracking-[0.05em] px-[6px] py-[2px] rounded-full bg-spk2-bg text-spk2-fg">
                  {r.tag}
                </span>
              </td>
              <td
                className={`px-[14px] py-[8px] font-sans text-[12px] text-right ${
                  r.isNew ? 'text-accent-ink' : 'text-ink-muted'
                }`}
              >
                {r.dur}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </MockWindow>
  )
}
