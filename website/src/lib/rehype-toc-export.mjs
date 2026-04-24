import { visit } from 'unist-util-visit'
import { toString } from 'mdast-util-to-string'
import { valueToEstree } from 'estree-util-value-to-estree'

/**
 * @typedef {{ depth: 2 | 3, id: string, text: string }} TocItem
 */

/**
 * Custom rehype plugin: collects H2 + H3 headings from the compiled HAST,
 * then injects `export const tableOfContents = [...]` into the MDX module's
 * mdxjsEsm tree so downstream code can do:
 *     import Page, { tableOfContents } from './page.mdx'
 *
 * MUST run AFTER rehype-slug so heading IDs are present.
 *
 * Ships as .mjs (not .ts) because @next/mdx's mdx-js-loader imports this
 * plugin via native Node `import()` at build time, and Node cannot load .ts
 * files without a loader. Types are documented via JSDoc.
 *
 * @returns {(tree: import('hast').Root) => void}
 */
export default function rehypeTocExport() {
  return (tree) => {
    /** @type {TocItem[]} */
    const items = []
    visit(tree, 'element', (node) => {
      if (node.tagName !== 'h2' && node.tagName !== 'h3') return
      const id = (node.properties && node.properties.id) || ''
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

    tree.children.unshift({
      type: 'mdxjsEsm',
      value: '',
      data: { estree },
    })
  }
}
