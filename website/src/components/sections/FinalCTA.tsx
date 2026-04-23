import { Reveal } from '@/components/motion/Reveal'
import { LinkButton, MetaLabel, SectionHeading } from '@/components/ui'
import { SITE } from '@/lib/site'
import { getLatestRelease } from '@/lib/changelog'

/**
 * FinalCTA — full-width download card at the bottom of the page.
 *
 * Stamp in the top-right shows `v{full version} · {human date}` with a
 * live-green dot. Uses `SITE.OS_REQUIREMENTS_FINAL_CTA` (the shorter form
 * `Free · Open source · macOS 26+ (Apple Silicon)`), NOT the hero's longer
 * form. Wrapped in <Reveal> so it fades in on first intersection.
 */
export function FinalCTA() {
  const release = getLatestRelease()
  return (
    <section id="download" className="py-16 md:py-20">
      <div className="mx-auto max-w-[1200px] px-6 md:px-10">
        <Reveal>
          <div className="relative rounded-[14px] border-[0.5px] border-rule bg-paper-warm px-8 py-10 md:px-12 md:py-14 text-center">
            <div className="absolute right-7 top-7 flex items-center gap-2">
              <span
                className="inline-block w-[6px] h-[6px] rounded-full bg-live-green"
                style={{ boxShadow: '0 0 0 2px rgba(74,138,94,0.15)' }}
                aria-hidden
              />
              <MetaLabel className="text-accent-ink whitespace-nowrap">
                v{release.version} · {release.dateHuman}
              </MetaLabel>
            </div>

            <MetaLabel>Ready when you are</MetaLabel>
            <SectionHeading className="mt-[10px] text-[clamp(32px,4vw,44px)] leading-[1.1]">
              Start transcribing privately.
            </SectionHeading>
            <p className="mt-4 mx-auto max-w-[54ch] font-sans text-[18px] leading-[1.55] text-ink-muted">
              No sign-up. No telemetry. One download, one app, one folder in your vault.
            </p>

            <div className="mt-7 flex items-center justify-center">
              <LinkButton
                variant="primary"
                href={SITE.DMG_URL}
                className="px-5 py-[12px] text-[15px]"
              >
                <span
                  className="w-[6px] h-[6px] rounded-full bg-rec-red"
                  style={{ boxShadow: '0 0 0 2px rgba(194,74,62,0.18)' }}
                  aria-hidden
                />
                Download for macOS
              </LinkButton>
            </div>

            <p className="mt-[18px] font-mono text-[11px] tracking-[0.04em] text-ink-faint text-center">
              {SITE.OS_REQUIREMENTS_FINAL_CTA}
            </p>
          </div>
        </Reveal>
      </div>
    </section>
  )
}
