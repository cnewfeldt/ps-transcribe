import type { MetadataRoute } from 'next'
import { DOC_ORDER } from '@/components/docs/sidebar-data'

const BASE = 'https://ps-transcribe-web.vercel.app'

export default function sitemap(): MetadataRoute.Sitemap {
  const now = new Date()
  return [
    {
      url: BASE,
      lastModified: now,
      changeFrequency: 'monthly',
      priority: 1,
    },
    ...DOC_ORDER.map((doc) => ({
      url: `${BASE}${doc.href}`,
      lastModified: now,
      changeFrequency: 'monthly' as const,
      priority: 0.7,
    })),
    {
      // Changelog page: matches docs-page priority (0.7) — top-level content
      url: `${BASE}/changelog`,
      lastModified: now,
      changeFrequency: 'monthly',
      priority: 0.7,
    },
    {
      // RSS feed endpoint: lower priority (0.5) — feed-reader discovery target,
      // not a human-browsable page. Also discoverable via <atom:link rel="self">
      // in the feed itself, but inclusion here aids initial sitemap-driven crawls.
      url: `${BASE}/changelog/rss.xml`,
      lastModified: now,
      changeFrequency: 'monthly',
      priority: 0.5,
    },
  ]
}
