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
  ]
}
