'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { sidebar } from './sidebar-data'

export function Sidebar() {
  const pathname = usePathname()
  return (
    <aside className="bg-paper-warm border-r-[0.5px] border-rule px-[22px] pt-10 pb-16 sticky top-16 self-start h-[calc(100vh-64px)] overflow-y-auto hidden md:block">
      {sidebar.map((group) => (
        <div key={group.label}>
          <h5 className="font-mono text-[10px] font-medium uppercase tracking-[0.1em] text-ink-faint mx-2 mt-[22px] mb-[10px]">
            {group.label}
          </h5>
          <ul className="list-none m-0 p-0 grid gap-px">
            {group.items.map((item) => {
              const isActive = pathname === item.href
              const base =
                'block px-[10px] py-[7px] text-[13.5px] no-underline rounded-[6px] leading-[1.35] border-[0.5px] transition-colors duration-[120ms]'
              const activeClasses =
                'bg-paper text-ink border-rule shadow-lift font-medium'
              const idleClasses =
                'text-ink-muted border-transparent hover:text-ink hover:bg-white/50'
              return (
                <li key={item.slug}>
                  <Link
                    href={item.href}
                    className={`${base} ${isActive ? activeClasses : idleClasses}`}
                    aria-current={isActive ? 'page' : undefined}
                  >
                    {item.navTitle}
                  </Link>
                </li>
              )
            })}
          </ul>
        </div>
      ))}
    </aside>
  )
}
