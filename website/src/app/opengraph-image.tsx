import { ImageResponse } from 'next/og'

export const alt = 'PS Transcribe — Private, on-device transcription for macOS'
export const size = { width: 1200, height: 630 }
export const contentType = 'image/png'

export default async function OGImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'flex-start',
          background: '#FAFAF7',
          padding: '96px',
          fontFamily: 'serif',
          color: '#1A1A17',
        }}
      >
        <div
          style={{
            fontSize: 28,
            letterSpacing: 2,
            color: '#8A8A82',
            textTransform: 'uppercase',
          }}
        >
          PS Transcribe
        </div>
        <div style={{ fontSize: 72, lineHeight: 1.1, marginTop: 24 }}>
          Private, on-device transcription for macOS.
        </div>
      </div>
    ),
    { ...size }
  )
}
