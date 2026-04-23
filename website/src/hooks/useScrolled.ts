'use client'

import { useEffect, useState } from 'react'

/**
 * Returns true once window.scrollY crosses the given threshold.
 * Per CONTEXT.md D-17, Nav uses threshold=6. Exposed as a parameter
 * so phases 14/15 can reuse the hook with their own thresholds if needed.
 */
export function useScrolled(threshold: number = 6): boolean {
  const [scrolled, setScrolled] = useState(false)
  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > threshold)
    onScroll()
    document.addEventListener('scroll', onScroll, { passive: true })
    return () => document.removeEventListener('scroll', onScroll)
  }, [threshold])
  return scrolled
}
