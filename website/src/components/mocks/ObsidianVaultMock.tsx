import { MockWindow } from '@/components/mocks/MockWindow'

/**
 * Feature 3 mock: Obsidian vault pane (tree + YAML-frontmatter file).
 *
 * YAML pane is a <pre> with whitespace-pre-wrap so the leading/trailing
 * `---` fence lines align. Explicit {'\n'} newlines separate children inside
 * the <pre> -- JSX collapses bare newlines between sibling elements, so we
 * emit them as explicit text children to preserve the rendered line breaks.
 * YAML keys (date/duration/participants/tags) get accent-ink styling per
 * the mock's `.k` span class.
 */
export function ObsidianVaultMock() {
  return (
    <MockWindow title="Obsidian · Vault" className="grid grid-cols-[160px_1fr] gap-0">
      {/* Tree pane */}
      <div className="border-r-[0.5px] border-rule p-[14px] font-mono text-[11px] leading-[1.7] text-ink-muted bg-paper">
        <div className="text-ink font-medium">Vault</div>
        <div className="pl-[10px]">
          <div className="text-ink font-medium">Meetings</div>
          <div className="pl-[10px]">
            <div>2026-04-20.md</div>
            <div className="inline-block -mx-[6px] px-[6px] py-[2px] rounded-[4px] bg-accent-tint text-accent-ink">
              2026-04-22.md
            </div>
          </div>
          <div className="mt-[4px] text-ink font-medium">Memos</div>
          <div className="pl-[10px]">
            <div>standups.md</div>
          </div>
        </div>
      </div>

      {/* File pane */}
      <div className="p-[14px] font-sans bg-paper">
        <pre className="m-0 border-b-[0.5px] border-rule pb-[10px] font-mono text-[11px] leading-[1.6] text-ink-muted whitespace-pre-wrap">
          {'---\n'}
          <span className="text-accent-ink">date</span>
          {': 2026-04-22T14:02\n'}
          <span className="text-accent-ink">duration</span>
          {': 32m\n'}
          <span className="text-accent-ink">participants</span>
          {': [You, Speaker 2]\n'}
          <span className="text-accent-ink">tags</span>
          {': [meeting, product]\n'}
          {'---'}
        </pre>
        <h6 className="mt-[10px] m-0 font-serif text-[15px] font-medium text-ink">
          Product sync — Apr 22
        </h6>
        <p className="mt-[6px] m-0 font-sans text-[12px] leading-[1.55] text-ink-muted">
          <strong className="font-semibold">Speaker 2 · 14:22</strong> — Last thing, did the encoder
          change land?
        </p>
        <p className="mt-[4px] m-0 font-sans text-[12px] leading-[1.55] text-ink-muted">
          <strong className="font-semibold">You · 14:29</strong> — Yesterday. Running on main.
        </p>
        <p className="mt-[4px] m-0 font-sans text-[12px] leading-[1.55] text-ink-muted">
          <strong className="font-semibold">Speaker 2 · 14:35</strong> — Good. Let&apos;s queue the
          diarizer next sprint.
        </p>
      </div>
    </MockWindow>
  )
}
