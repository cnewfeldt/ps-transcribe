import { MockWindow } from '@/components/mocks/MockWindow'

type Bubble = {
  side: 'them' | 'me'
  name: string
  time: string
  text: string
  maxWidth: string // matches the mock's inline max-width on .bubble
}

// Bubble copy ported verbatim from design/.../index.html lines 362-380.
const BUBBLES: Bubble[] = [
  {
    side: 'them',
    name: 'Speaker 2',
    time: '14:22',
    text: 'Last thing, did the encoder change land?',
    maxWidth: '85%',
  },
  {
    side: 'me',
    name: 'You',
    time: '14:29',
    text: 'Yesterday. Running on main.',
    maxWidth: '70%',
  },
  {
    side: 'them',
    name: 'Speaker 2',
    time: '14:35',
    text: "Good. Let's queue up the diarizer next sprint.",
    maxWidth: '82%',
  },
]

export function ChatBubbleMock() {
  return (
    <MockWindow title="Chronicle · Transcript" className="p-[18px_20px] flex flex-col gap-[8px]">
      {BUBBLES.map((b, i) => (
        <ChatBubble key={i} bubble={b} />
      ))}
    </MockWindow>
  )
}

function ChatBubble({ bubble }: { bubble: Bubble }) {
  const isMe = bubble.side === 'me'
  const container = isMe ? 'self-end' : 'self-start'
  const bubbleCls = isMe
    ? 'bg-ink text-paper rounded-[12px] rounded-br-[4px] px-[14px] py-[10px]'
    : 'relative bg-spk2-bg text-spk2-fg rounded-[12px] rounded-bl-[4px] pl-[15px] pr-[14px] py-[10px]'
  return (
    <div className={`flex flex-col ${container}`} style={{ maxWidth: bubble.maxWidth }}>
      <span
        className={`mb-[4px] flex items-center gap-2 font-mono text-[9px] uppercase tracking-[0.08em] ${
          isMe ? 'text-paper/70 self-end' : 'text-spk2-fg/80'
        }`}
      >
        <span>{bubble.name}</span>
        <span className="opacity-60">{bubble.time}</span>
      </span>
      <div className={bubbleCls}>
        {!isMe && (
          <span
            className="absolute left-[5px] top-[8px] bottom-[8px] w-[2px] rounded-[1px] bg-spk2-rail"
            aria-hidden
          />
        )}
        <span className="font-sans text-[13.5px] leading-[1.5]">{bubble.text}</span>
      </div>
    </div>
  )
}
