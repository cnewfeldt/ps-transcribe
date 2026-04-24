import type { ReactNode } from 'react'

export function ShortcutTable({ children }: { children: ReactNode }) {
  return (
    <div className="border-[0.5px] border-rule rounded-[10px] overflow-hidden mb-7">
      {children}
    </div>
  )
}
