import type { Plugin } from 'unified'
import type { Root, Element } from 'hast'
import { visit } from 'unist-util-visit'
import { toString } from 'mdast-util-to-string'
import { valueToEstree } from 'estree-util-value-to-estree'

export type TocItem = { depth: 2 | 3; id: string; text: string }

/**
 * Custom rehype plugin: collects H2 + H3 headings from the compiled HAST,
 * then injects `export const tableOfContents = [...]` into the MDX module's
 * mdxjsEsm tree so downstream code can do:
 *     import Page, { tableOfContents } from './page.mdx'
 *
 * MUST run AFTER rehype-slug so heading IDs are present.
 */
export const rehypeTocExport: Plugin<[], Root> = () => (tree) => {
  const items: TocItem[] = []
  visit(tree, 'element', (node: Element) => {
    if (node.tagName !== 'h2' && node.tagName !== 'h3') return
    const id = (node.properties?.id as string) ?? ''
    if (!id) return
    items.push({
      depth: node.tagName === 'h2' ? 2 : 3,
      id,
      text: toString(node).trim(),
    })
  })

  const estree = {
    type: 'Program',
    sourceType: 'module',
    body: [
      {
        type: 'ExportNamedDeclaration',
        specifiers: [],
        declaration: {
          type: 'VariableDeclaration',
          kind: 'const',
          declarations: [
            {
              type: 'VariableDeclarator',
              id: { type: 'Identifier', name: 'tableOfContents' },
              init: valueToEstree(items),
            },
          ],
        },
      },
    ],
  }

  // Inject an mdxjsEsm node at the top of the tree. MDX compiler hoists it
  // into the compiled module's ES exports.
  tree.children.unshift({
    type: 'mdxjsEsm' as never,
    value: '',
    data: { estree },
  } as never)
}
