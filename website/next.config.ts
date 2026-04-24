import type { NextConfig } from 'next'
import createMDX from '@next/mdx'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

// Pin Turbopack's workspace root to this directory. Without this, Next 16's
// auto-detection walks up the filesystem looking for a lockfile and can
// select a stray `bun.lockb` in the user's home, which breaks relative
// plugin paths like `./src/lib/rehype-toc-export` during `next build`.
const HERE = dirname(fileURLToPath(import.meta.url))

// Absolute path to the local rehype plugin. @next/mdx's mdx-js-loader calls
// `require.resolve(pluginPath, { paths: [this.context] })` where `this.context`
// is the directory of the .mdx file being compiled, not the project root.
// A relative path like `./src/lib/rehype-toc-export` therefore cannot resolve.
// Using an absolute path computed from next.config.ts's own directory sidesteps
// the issue entirely and still keeps the option JSON-serializable for Turbopack.
const REHYPE_TOC_EXPORT_PATH = join(HERE, 'src', 'lib', 'rehype-toc-export.mjs')

const nextConfig: NextConfig = {
  pageExtensions: ['ts', 'tsx', 'mdx'],
  turbopack: {
    root: HERE,
  },
}

// Turbopack requires plugins and options to be JSON-serializable, so plugins
// are passed as string paths (resolved by @next/mdx's mdx-js-loader) and the
// rehype-autolink-headings `content` option uses a static hast node instead of
// a build function. This is the D-14 "acceptable fallback" — anchors render as
// "#" (CSS handles positioning/styling) rather than per-heading lowercase
// labels like "# install".
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
      REHYPE_TOC_EXPORT_PATH,
    ],
  },
})

export default withMDX(nextConfig)
