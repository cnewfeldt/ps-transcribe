import type { MDXComponents } from 'mdx/types'
import type { ComponentPropsWithoutRef } from 'react'
import { Note } from '@/components/docs/Note'
import { Lede } from '@/components/docs/Lede'
import { Crumbs } from '@/components/docs/Crumbs'
import { PrevNext } from '@/components/docs/PrevNext'
import { ShortcutTable } from '@/components/docs/ShortcutTable'
import { ShortcutRow } from '@/components/docs/ShortcutRow'
import { Kbd } from '@/components/docs/Kbd'

/**
 * Element overrides apply a MINIMAL set of classes. The bulk of prose styles
 * live in `./components/docs/docs.css` under a `.prose` scope (imported by
 * globals.css). Element overrides here exist for:
 *   - inline `code` vs fenced `pre > code` disambiguation (DOCS-05)
 *   - fenced `pre` lang-label via a data-lang attribute read by CSS
 *   - `hr` soft variant
 * Everything else (h1/h2/h3/p/ul/ol/a/strong/em sizing) is handled by
 * `.prose` CSS so we avoid fighting MDX's element contract.
 */
const components: MDXComponents = {
  // Custom docs components — authors invoke <Note>, <Lede>, etc. directly.
  Note,
  Lede,
  Crumbs,
  PrevNext,
  ShortcutTable,
  ShortcutRow,
  Kbd,

  // Inline code — fenced blocks are handled by the `pre` override below,
  // which strips the inline styles via the `pre code` selector in docs.css.
  code: ({ className, children, ...rest }: ComponentPropsWithoutRef<'code'>) => (
    <code
      {...rest}
      className={`font-mono text-[13.5px] bg-paper-soft text-ink px-[6px] py-[2px] rounded-[4px]${className ? ' ' + className : ''}`}
    >
      {children}
    </code>
  ),

  // Fenced blocks. We derive the language label from the child <code>'s
  // className (`language-yaml` -> `yaml`) and stamp it as data-lang on <pre>
  // so the CSS `pre::before` rule can render it (matches mock's `data-lang`
  // attribute treatment).
  pre: ({ children, ...rest }: ComponentPropsWithoutRef<'pre'>) => {
    let lang = ''
    // MDX passes the <code> element as children. Extract its className.
    if (
      typeof children === 'object' &&
      children !== null &&
      'props' in children &&
      typeof (children as { props?: { className?: string } }).props?.className === 'string'
    ) {
      const m = /language-([\w-]+)/.exec(
        (children as { props: { className: string } }).props.className,
      )
      if (m) lang = m[1].toUpperCase()
    }
    return (
      <pre {...rest} data-lang={lang}>
        {children}
      </pre>
    )
  },

  // `<hr />` in MDX -> soft rule used between sections. Mock: `.soft` class.
  hr: (props: ComponentPropsWithoutRef<'hr'>) => (
    <hr {...props} className="hr-soft" />
  ),
}

export function useMDXComponents(): MDXComponents {
  return components
}
