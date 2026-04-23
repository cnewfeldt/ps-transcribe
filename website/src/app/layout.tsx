import type { Metadata, Viewport } from 'next'
import { Inter, Spectral, JetBrains_Mono } from 'next/font/google'
import './globals.css'
import { Nav } from '@/components/layout/Nav'
import { Footer } from '@/components/layout/Footer'

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-inter',
})

const spectral = Spectral({
  subsets: ['latin'],
  display: 'swap',
  weight: ['400', '600'],
  style: ['normal', 'italic'],
  variable: '--font-spectral',
})

const jetbrainsMono = JetBrains_Mono({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-jetbrains-mono',
})

export const metadata: Metadata = {
  metadataBase: new URL('https://ps-transcribe-web.vercel.app'),
  title: {
    default: 'PS Transcribe -- Private, on-device transcription for macOS',
    template: '%s · PS Transcribe',
  },
  description: 'A native macOS transcriber. Call recordings stay on your machine — no cloud APIs, no telemetry, no uploads.',
  openGraph: {
    title: 'PS Transcribe — Private, on-device transcription for macOS',
    description: 'A native macOS transcriber. Call recordings stay on your machine — no cloud APIs, no telemetry, no uploads.',
    url: 'https://ps-transcribe-web.vercel.app',
    siteName: 'PS Transcribe',
    type: 'website',
    locale: 'en_US',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'PS Transcribe — Private, on-device transcription for macOS',
    description: 'A native macOS transcriber. Call recordings stay on your machine — no cloud APIs, no telemetry, no uploads.',
  },
  robots: { index: true, follow: true },
}

export const viewport: Viewport = {
  colorScheme: 'light',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html
      lang="en"
      className={`${inter.variable} ${spectral.variable} ${jetbrainsMono.variable}`}
    >
      <body className="font-sans antialiased">
        <Nav />
        {children}
        <Footer />
      </body>
    </html>
  )
}
