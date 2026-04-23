import Image from 'next/image'
import { LinkButton, MetaLabel } from '@/components/ui'
import { SITE } from '@/lib/site'
import { getLatestRelease } from '@/lib/changelog'

/**
 * Hero — variant C (centered headline + screenshot beneath).
 *
 * Server component. Renders above the fold; do NOT wrap in <Reveal>.
 * Eyebrow pulls from the build-time CHANGELOG parser so the version stamp
 * stays in lockstep with the most recent release entry. `<Image preload>`
 * is the Next 16 eager-load prop (the pre-16 above-the-fold prop is
 * deprecated).
 */
export function Hero() {
  const release = getLatestRelease()
  return (
    <section className="pt-14 pb-10 md:pt-16 md:pb-14" id="hero">
      <div className="mx-auto max-w-[1200px] px-6 md:px-10">
        <div className="grid grid-cols-1 gap-10 text-center">
          <div className="mx-auto max-w-[920px]">
            <div className="mb-[22px] inline-flex flex-wrap items-center justify-center gap-[10px]">
              <span
                className="inline-block w-[6px] h-[6px] rounded-full bg-live-green"
                style={{ boxShadow: '0 0 0 2px rgba(74,138,94,0.15)' }}
                aria-hidden
              />
              <MetaLabel className="text-accent-ink whitespace-nowrap">
                Ver {release.versionShort} · Released {release.dateHuman}
              </MetaLabel>
            </div>

            <h1 className="font-serif font-normal text-[clamp(44px,6vw,68px)] leading-[1.08] tracking-[-0.015em] text-ink text-balance">
              Your meeting audio<br />
              <em className="italic text-accent-ink">never leaves your Mac.</em>
            </h1>

            <p className="mt-6 mx-auto font-sans text-[18px] leading-[1.55] text-ink-muted max-w-[54ch] text-pretty">
              A native macOS transcriber built around one idea: call recordings are private, so the software that handles them should be too. No cloud APIs. No telemetry. Nothing uploaded, ever.
            </p>

            <div className="mt-7 flex items-center justify-center gap-[18px] flex-wrap">
              <LinkButton variant="primary" href={SITE.DMG_URL}>
                <span
                  className="w-[6px] h-[6px] rounded-full bg-rec-red"
                  style={{ boxShadow: '0 0 0 2px rgba(194,74,62,0.18)' }}
                  aria-hidden
                />
                Download for macOS
              </LinkButton>
              <LinkButton variant="secondary" href={SITE.REPO_URL}>
                View on GitHub →
              </LinkButton>
            </div>

            <p className="mt-[14px] font-mono text-[11px] tracking-[0.04em] text-ink-faint text-center">
              {SITE.OS_REQUIREMENTS}
            </p>
          </div>

          <div className="relative">
            <figure className="m-0 mx-auto max-w-[1080px] rounded-[12px] overflow-hidden border-[0.5px] border-rule-strong shadow-float bg-paper">
              <Image
                src="/app-screenshot.png"
                alt="PS Transcribe — meeting transcript with Library, Transcript, and Details columns"
                width={2260}
                height={1408}
                preload={true}
                decoding="async"
                className="block w-full h-auto"
              />
            </figure>
          </div>
        </div>
      </div>
    </section>
  )
}
