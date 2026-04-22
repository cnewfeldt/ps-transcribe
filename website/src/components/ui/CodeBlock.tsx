import type { HTMLAttributes } from 'react'

type CodeBlockProps = HTMLAttributes<HTMLElement> & {
  inline?: boolean
}

const inlineClasses =
  'font-mono text-[14px] bg-paper-soft text-ink px-[6px] py-[2px] rounded-[4px]'

const blockClasses =
  'font-mono text-[14px] bg-paper-soft text-ink border-[0.5px] border-rule rounded-card p-4 overflow-x-auto'

export function CodeBlock({
  inline = false,
  className = '',
  children,
  ...rest
}: CodeBlockProps) {
  if (inline) {
    return (
      <code {...rest} className={`${inlineClasses} ${className}`.trim()}>
        {children}
      </code>
    )
  }
  return (
    <pre className={`${blockClasses} ${className}`.trim()}>
      <code {...rest}>{children}</code>
    </pre>
  )
}
