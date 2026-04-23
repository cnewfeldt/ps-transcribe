'use client'

import { useEffect, useRef, useState } from 'react'

/**
 * IntersectionObserver-backed one-shot reveal hook.
 * - threshold: 0.12 (matches the original mock)
 * - unobserves on first intersection (no duplicate class toggling on rescroll)
 * - honors prefers-reduced-motion: reduce → immediately visible, no IO created
 * Per CONTEXT.md D-19.
 */
export function useReveal<T extends HTMLElement = HTMLDivElement>() {
  const ref = useRef<T | null>(null)
  const [visible, setVisible] = useState(false)

  useEffect(() => {
    if (typeof window !== 'undefined' &&
        window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      setVisible(true)
      return
    }
    const el = ref.current
    if (!el) return
    const io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (e.isIntersecting) {
            setVisible(true)
            io.unobserve(e.target)
          }
        }
      },
      { threshold: 0.12 }
    )
    io.observe(el)
    return () => io.disconnect()
  }, [])

  return { ref, visible }
}
