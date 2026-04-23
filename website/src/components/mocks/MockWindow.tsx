import type { ReactNode } from 'react'

/**
 * Shared mini-mockup chrome: three traffic-light dots + centered mono title.
 * Extracted once so all four feature mocks share the header pattern without
 * duplication. Per CONTEXT.md D-specifics: permitted when 3+ mocks share chrome.
 *
 * The traffic-light hex values are hardcoded (not Chronicle tokens) because
 * these are macOS window controls, not brand colors -- ported verbatim from
 * chronicle-mock.css lines 90-93. The titlebar gradient is likewise hardcoded.
 */
export function MockWindow({
  title,
  children,
  className = '',
}: {
  title: string
  children: ReactNode
  className?: string
}) {
  return (
    <div className="w-full bg-paper border-[0.5px] border-rule-strong rounded-[8px] shadow-lift overflow-hidden text-[12px]">
      <div
        className="h-[24px] border-b-[0.5px] border-rule flex items-center gap-[6px] px-[10px]"
        style={{ background: 'linear-gradient(to bottom, #F6F3EC, #EFECE3)' }}
        aria-hidden
      >
        <span className="w-[8px] h-[8px] rounded-full" style={{ background: '#EC6A5F' }} />
        <span className="w-[8px] h-[8px] rounded-full" style={{ background: '#F5BF4F' }} />
        <span className="w-[8px] h-[8px] rounded-full" style={{ background: '#61C554' }} />
        <b className="ml-2 font-mono font-normal text-[10px] text-ink-faint tracking-[0.04em]">
          {title}
        </b>
      </div>
      <div className={className}>{children}</div>
    </div>
  )
}
