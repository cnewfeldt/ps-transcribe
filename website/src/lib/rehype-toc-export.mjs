/**
 * Custom rehype plugin: collects H2 + H3 headings from the compiled HAST,
 * then injects `export const tableOfContents = [...]` into the MDX module's
 * mdxjsEsm tree so downstream code can do:
 *     import Page, { tableOfContents } from './page.mdx'
 *
 * MUST run AFTER rehype-slug so heading IDs are present.
 *
 * NOTE: This file is authored as `.mjs` (not `.ts`) because Next 16's
 * `@next/mdx` loader resolves plugins via plain Node `import()` at build time,
 * which cannot execute TypeScript source files. The TS types we care about
 * are enforced in consumers (TableOfContents.tsx) via a local TocItem type.
 */
import { visit } from 'unist-util-visit'
import { toString } from 'mdast-util-to-string'
import { valueToEstree } from 'estree-util-value-to-estree'

export const rehypeTocExport = () => (tree) => {
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

  // Inject an mdxjsEsm node at the top of the tree. MDX compiler hoists it
  // into the compiled module's ES exports.
  tree.children.unshift({
    type: 'mdxjsEsm',
    value: '',
    data: { estree },
  })
}

export default rehypeTocExport
