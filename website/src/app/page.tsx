import { Hero } from '@/components/sections/Hero'
import { ThreeThingsStrip } from '@/components/sections/ThreeThingsStrip'
import { FeatureBlock } from '@/components/sections/FeatureBlock'
import { ShortcutGrid } from '@/components/sections/ShortcutGrid'
import { FinalCTA } from '@/components/sections/FinalCTA'
import { DualStreamMock } from '@/components/mocks/DualStreamMock'
import { ChatBubbleMock } from '@/components/mocks/ChatBubbleMock'
import { ObsidianVaultMock } from '@/components/mocks/ObsidianVaultMock'
import { NotionTableMock } from '@/components/mocks/NotionTableMock'

export default function Home() {
  return (
    <main className="bg-paper text-ink">
      <Hero />
      <ThreeThingsStrip />

      <section className="py-10 md:py-14">
        <div className="mx-auto max-w-[1200px] px-6 md:px-10">
          <FeatureBlock
            index={0}
            tint="tint"
            metaLabel="Dual-stream capture"
            headline="Your mic and the call, on separate tracks."
            body="PS Transcribe captures your microphone and the other side of the call as two clean streams straight from macOS. No speakerphone, no bleed. Silence is skipped as you record, and when the session ends the app sorts out who said what."
            bullets={[
              'Your voice on one track, everyone else on another',
              'Silence is skipped automatically, on device',
              'Speakers grouped and labeled after the session ends',
            ]}
            mock={<DualStreamMock />}
          />

          <hr className="border-0 h-[0.5px] bg-rule" />

          <FeatureBlock
            index={1}
            tint="sage"
            metaTone="sage"
            metaLabel="Transcript view"
            headline="Chat bubbles. Not a wall of text."
            body="Your side sits right; Speaker 2 sits left. Timestamps are quietly recessed in 10pt mono. Every utterance is its own bubble so you can scan by speaker instead of reading a wall of text."
            bullets={[
              'Individual bubbles per utterance, no wall of text',
              '10pt mono timestamps, quietly recessed',
              'Your voice right, Speaker 2 left, both with distinct styling',
            ]}
            mock={<ChatBubbleMock />}
          />

          <hr className="border-0 h-[0.5px] bg-rule" />

          <FeatureBlock
            index={2}
            tint="default"
            metaTone="navy"
            metaLabel="Obsidian vault"
            headline="Every session lands where your notes already live."
            body={
              <>
                A Markdown note dropped into the folder you configure, with date, duration, attendees, and tags already filled in at the top. No proprietary format, no export step. The transcript <em className="italic">is</em> a note in your vault, instantly linkable.
              </>
            }
            bullets={[
              'Date, duration, attendees, and tags set automatically',
              'Separate folders for meetings and voice memos',
              'Works with Obsidian sync, git, iCloud, whatever you already use',
            ]}
            mock={<ObsidianVaultMock />}
          />

          <hr className="border-0 h-[0.5px] bg-rule" />

          <FeatureBlock
            index={3}
            tint="tint"
            metaLabel="Notion integration"
            headline="Finished sessions land in Notion, automatically."
            body="Configure a Notion database once. Turn on auto-send, and every finished recording becomes a new Notion page with the key details (date, duration, speakers, source app, tags) already filled in as properties. Leave it off and nothing syncs."
            bullets={[
              'Auto-filled Notion properties: date, duration, speakers, source app, tags',
              'Off by default, flip one toggle to auto-send every session',
              'Integration token stays in macOS Keychain',
            ]}
            mock={<NotionTableMock />}
          />
        </div>
      </section>

      <ShortcutGrid />
      <FinalCTA />
    </main>
  )
}
