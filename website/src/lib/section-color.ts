/**
 * Heuristic classifier mapping freeform CHANGELOG section headings to one of
 * five color buckets. Per Phase 15 D-03/D-04: rules apply in priority order;
 * order matters (e.g., "Scope reduction" must hit `breaking` before any
 * other rule could match).
 *
 * Returned keys are consumed by ReleaseCard for both the section H4 label
 * color and the bullet `::before` dot color.
 *
 * Note: the synthesized 'Changes' section title produced by the orphan-bullet
 * branch in lib/changelog.ts (for legacy releases v1.0.0..v1.2.0 with flat
 * bullets) falls through all rules and lands in the 'default' bucket -- which
 * is the desired visually-quiet treatment.
 */
export type SectionBucket = 'features' | 'ux' | 'fixes' | 'breaking' | 'default'

type Rule = { test: RegExp; bucket: SectionBucket }

// Priority-ordered rules. First match wins. See D-03 in 15-CONTEXT.md.
const RULES: Rule[] = [
  { test: /\b(breaking|migration|scope\s+reduction)\b/i, bucket: 'breaking' },
  { test: /\b(features?|integration|notion|sparkle|auto[-\s]?update|distribution)\b/i, bucket: 'features' },
  { test: /\b(ux|interface|layout|library|recording|onboarding|redesign|transcript)\b/i, bucket: 'ux' },
  { test: /\b(fix|fixes|bug|internals)\b/i, bucket: 'fixes' },
]

export function classifySection(title: string): SectionBucket {
  for (const rule of RULES) {
    if (rule.test.test(title)) return rule.bucket
  }
  return 'default'
}

/**
 * Token references for label and dot colors per bucket.
 * Consumed via inline `style={{ color: sectionColors[bucket].label }}` in ReleaseCard.
 * Keeping these as CSS variable strings (not Tailwind classes) lets us bind via inline
 * style without growing the Tailwind JIT class set per dynamic value.
 */
export const sectionColors: Record<SectionBucket, { label: string; dot: string }> = {
  breaking: { label: 'var(--color-rec-red)', dot: 'var(--color-rec-red)' },
  features: { label: 'var(--color-accent-ink)', dot: 'var(--color-accent-ink)' },
  ux: { label: 'var(--color-spk2-rail)', dot: 'var(--color-spk2-rail)' },
  fixes: { label: 'var(--color-ink-muted)', dot: 'var(--color-ink-ghost)' },
  default: { label: 'var(--color-ink-faint)', dot: 'var(--color-ink-ghost)' },
}
