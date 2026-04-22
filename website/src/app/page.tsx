export default function Home() {
  return (
    <main
      style={{
        minHeight: '100dvh',
        background: '#FAFAF7',
        color: '#1A1A17',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'center',
        alignItems: 'flex-start',
        padding: '96px 64px',
        gap: '28px',
        fontFamily: 'var(--font-inter), system-ui, sans-serif',
      }}
    >
      <div
        style={{
          fontFamily: 'var(--font-jetbrains-mono), Menlo, monospace',
          fontSize: '11px',
          letterSpacing: '0.8px',
          textTransform: 'uppercase',
          color: '#8A8A82',
        }}
      >
        v1.1 · Website
      </div>

      <h1
        style={{
          fontFamily: 'var(--font-spectral), Georgia, serif',
          fontSize: '48px',
          fontWeight: 400,
          lineHeight: 1.1,
          margin: 0,
          letterSpacing: '-0.01em',
        }}
      >
        PS Transcribe
      </h1>

      <p
        style={{
          fontSize: '16px',
          lineHeight: 1.6,
          color: '#595954',
          maxWidth: '44ch',
          margin: 0,
        }}
      >
        Private, on-device transcription for macOS.
      </p>

      <p style={{ fontSize: '14px', color: '#8A8A82', margin: 0 }}>
        Site coming soon.
      </p>
    </main>
  )
}
