import type { NextConfig } from 'next'
import createMDX from '@next/mdx'

const nextConfig: NextConfig = {
  pageExtensions: ['ts', 'tsx', 'mdx'],
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
      './src/lib/rehype-toc-export',
    ],
  },
})

export default withMDX(nextConfig)
