import type { NextConfig } from 'next'
import createMDX from '@next/mdx'
import { resolve } from 'node:path'

const nextConfig: NextConfig = {
  pageExtensions: ['ts', 'tsx', 'mdx'],
}

// Turbopack requires plugins and options to be JSON-serializable, so plugins
// are passed as string paths (resolved by @next/mdx's mdx-js-loader) and the
// rehype-autolink-headings `content` option uses a static hast node instead of
// a build function. This is the D-14 "acceptable fallback" — anchors render as
// "#" (CSS handles positioning/styling) rather than per-heading lowercase
// labels like "# install".
//
// The custom local plugin is referenced via its absolute file path (computed
// from process.cwd(), which is always the website/ root when `pnpm build` or
// `pnpm dev` is invoked). @next/mdx's loader calls require.resolve(path, {
// paths: [loaderContext] }), which only honors `paths` for module-style
// lookups; `./`-style relative paths resolve from the loader's own __dirname
// (deep inside node_modules) and would fail. An absolute path sidesteps that
// entirely while remaining a plain string (Turbopack-safe).
//
// Note: We avoid `import.meta.url` here because Next 16 compiles next.config.ts
// to CJS before executing it, and `import.meta` is undefined in CJS.
const TOC_EXPORT_PLUGIN = resolve(process.cwd(), 'src/lib/rehype-toc-export.mjs')

const withMDX = createMDX({
  options: {
    remarkPlugins: ['remark-gfm'],
    rehypePlugins: [
      'rehype-slug',
      [
        'rehype-autolink-headings',
        {
          behavior: 'prepend',
          properties: { className: ['anchor'], 'aria-hidden': 'true', tabIndex: -1 },
          content: { type: 'text', value: '#' },
        },
      ],
      ['rehype-external-links', { target: '_blank', rel: ['noopener', 'noreferrer'] }],
      TOC_EXPORT_PLUGIN,
    ],
  },
})

export default withMDX(nextConfig)
