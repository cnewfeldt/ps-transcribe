import type { Metadata } from 'next'
import { Inter, Spectral, JetBrains_Mono } from 'next/font/google'
import './globals.css'

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-inter',
})

const spectral = Spectral({
  subsets: ['latin'],
  display: 'swap',
  weight: ['400', '600'],
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
    default: 'PS Transcribe — Private, on-device transcription for macOS',
    template: '%s · PS Transcribe',
  },
  description: 'Private, on-device transcription for macOS.',
  openGraph: {
    title: 'PS Transcribe',
    description: 'Private, on-device transcription for macOS.',
    url: 'https://ps-transcribe-web.vercel.app',
    siteName: 'PS Transcribe',
    type: 'website',
    locale: 'en_US',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'PS Transcribe',
    description: 'Private, on-device transcription for macOS.',
  },
  robots: { index: true, follow: true },
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
      <body style={{ fontFamily: 'var(--font-inter), system-ui, sans-serif' }}>
        {children}
      </body>
    </html>
  )
}
