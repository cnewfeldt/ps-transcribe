# Phase 18: Hotkey Dictation + Plain-Folder Output - Research

**Researched:** 2026-04-27
**Domain:** macOS native global hotkey + floating NSPanel HUD + clipboard write + plain-markdown file output, integrated against an existing Swift 6.2 / SwiftUI / FluidAudio actor-based transcription app
**Confidence:** HIGH (Phase 16 foundations verified by direct source inspection; KeyboardShortcuts 2.4.0 API confirmed via GitHub; NSPasteboard/NSPanel patterns are stable AppKit; pitfalls research from `.planning/research/PITFALLS.md` is authoritative)

## Summary

Phase 18 wires the user-facing dictation feature on top of Phase 16's already-shipped foundation. All "what should this look like" questions are locked in CONTEXT.md (D-01..D-16); research below answers "how to build it" — the concrete API shapes, NSPanel recipe, state machine, clipboard recipe, and validation architecture the planner needs to write Wave-by-Wave plans.

The architecture is **two coordinators in a clean dependency line**: `GlobalHotkeyService` (KeyboardShortcuts wrapper, fires onHotkey on MainActor) → `DictationCoordinator` (state machine, owns a SECOND `TranscriptionEngine` instance + private `TranscriptStore` + the existing `DictationLogger` actor) → `DictationWindowController` (NSPanel lifecycle) → `DictationHUD` (SwiftUI body hosted via `NSHostingView`). Existing services already in place (`SessionCoordinator`, `LibraryStore`, `AppSettings`, `DictationLogger`) are consumed by reference; no new actor types beyond the four files listed in CONTEXT.md "Source files Phase 18 modifies or creates."

**Primary recommendation:** Build in seven waves — (W1) `GlobalHotkeyService` + KeyboardShortcuts dependency + Settings recorder; (W2) `DictationLogger.discardSession()` + `LibraryEntry.filePath` Optional refactor; (W3) `DictationCoordinator` skeleton (state enum, isActive, mutual-exclusion guard); (W4) `DictationWindowController` + `DictationHUD` view; (W5) full begin/end/cancel flow with clipboard write/restore + library save; (W6) Settings UI + LibraryEntryRow already covers icon (already shipped at line 161); (W7) integration polish (menu-bar pulse, NotificationCenter, eager pre-warm). Wave 1 and Wave 2 can run in parallel; Wave 3 depends on both; Waves 4-7 chain.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### HUD Content & Visual Design
- **D-01:** HUD displays live partial transcript + elapsed timer (`mm:ss`) + visible Stop button. Three blocks in a single horizontal panel. (preview: `● 0:12   the quick brown fox…   [Stop]`)
- **D-02:** On stop, before dismiss, show a "Copied to clipboard" pill for ~1.0s, then fade. Satisfies ROADMAP Phase 18 success criterion #2 verbatim.
- **D-03:** Visual style is **native macOS HUD** — `NSVisualEffectView` with `.hudWindow` material, vibrancy blur, system-default appearance. NOT the Chronicle paper aesthetic.
- **D-04:** Position is bottom-center of the active screen (`NSScreen.main`). Vertically centered across the bottom ~quarter. Matches SuperWhisper / macOS Dictation default. No user configuration in v1.2.

#### Cancel & Hotkey Semantics
- **D-05:** **Toggle mode** — second hotkey tap = stop & commit (clipboard write + library save + plain-folder finalize per `DictationOutputMode`). Symmetric with first tap = start. Escape is the **only** way to cancel-without-commit.
- **D-06:** **30s cancel confirmation appears INLINE in HUD.** When Escape is pressed and session duration ≥ 30s, HUD subtitle changes to "Press Esc again to cancel" for ~3s. Second Esc within that window confirms cancel; otherwise revert to listening.
- **D-07:** **Press-and-hold mode** — release < 1s = silent cancel. Release ≥ 1s = commit. The 30s confirmation threshold from D-06 still applies.
- **D-08:** **Cancel cleanup is atomic.** Cancel → no clipboard write, no library entry, AND if `DictationLogger.startSession()` already opened a plain-folder file, that file is **deleted** (not truncated, not marked-cancelled). The `DictationLogger` API needs a `discardSession()` companion to `endSession()`.

#### Library Entry Handling
- **D-09:** **Every successful dictation gets a library entry.** No minimum word count, no minimum duration filter.
- **D-10:** **Auto-name from first ~5 words** of the final transcript. Truncate at ~50 chars, break on word boundary, append `…` if truncated, strip leading/trailing punctuation. Falls back to `Dictation YYYY-MM-DD HH:mm` if transcript is empty/whitespace-only.
- **D-11:** **Inline alongside meetings + voice memos**, distinguished by a `mic.fill` SF Symbol (or simple "D" badge) in `LibraryEntryRow`. No separate "Dictations" filter section.
- **D-12:** **Library row points at the plain-folder file directly** when `DictationOutputMode` is `.plainFolder` or `.both`. When mode is `.clipboard` only, library row stores the transcript text inline in `library.json` with no `filePath` (matches the existing `LibraryEntry` shape if it tolerates an empty path; verify during planning and adjust if needed).

#### Cold-Start & Failure UX
- **D-13:** **Eager pre-warm at app launch.** A separate `TranscriptionEngine` instance owned by `DictationCoordinator` is instantiated at app scope and `prepareModels()` runs in the background at launch.
- **D-14:** **Hotkey pressed during an active meeting recording** → HUD appears briefly with "Recording in progress — dictation unavailable", auto-dismisses after ~1.5s. Mutual exclusion gate is `SessionCoordinator.anySessionActive`.
- **D-15:** **Plain-folder write failure** → silent fallback to clipboard-only. Log to `os_log` for Console.app diagnostics. Library entry is still created (with empty `filePath`).
- **D-16:** **Models still loading when hotkey pressed** → HUD shows "Loading model…" state, transitions to live listening when `modelsReady = true`. Recording starts only when models are ready.

### Claude's Discretion
- Exact HUD dimensions, font sizes, padding (research suggests ~360-440pt wide, but final values within native HUD style conventions).
- Exact Settings layout for the Dictation section — flat list vs sub-grouped. Phase 17 D-06 locks the section ORDER (…Speech Model → Dictation); internal layout is Claude's call within Pitfall #18 guardrails.
- Hotkey-recorder validation: warn-but-allow on system-reserved combinations, or hard-block. Lean: warn-but-allow.
- Clipboard restore semantics with `NSPasteboard.changeCount` race (Pitfall #6): use changeCount as a guard (skip restore if user copied something else during the window), don't fail loudly on mismatch.
- Pre-warm error handling — if dictation engine's `prepareModels()` fails at launch, defer to lazy load on first hotkey (D-16 path).
- Menu bar pulsing-mic icon design (DICT-03) — specific animation and SF Symbol choice.
- Engine pre-warm error path and any retry semantics.
- Whether `DictationCoordinator` needs its own `TranscriptStore` instance or can share a private utterance accumulator.
- Settings UI shape for `clipboardRestoreDelay` — slider, stepper, or hidden defaults-only.
- "First ~5 words" tokenization details (whitespace split, stop-word filtering, etc.).

### Deferred Ideas (OUT OF SCOPE)
- **Configurable HUD position** (DICT-FUT-01) — locked to bottom-center for v1.2.
- **Multi-locale dictation** (DICT-FUT-02) — inherits app's existing single locale.
- **Per-app hotkey behavior** (DICT-FUT-03) — deferred beyond v1.2.
- **Auto-paste via accessibility API** — explicitly out of scope (REQUIREMENTS.md).
- **Direct-inject text via accessibility** — explicitly out of scope (REQUIREMENTS.md).
- **Dictation history search** — out of scope for v1.2 (REQUIREMENTS.md).
- **LLM cleanup of dictated text** — out of scope (2026-04-04 scope reduction).
- **Configurable cancel threshold** — keep hardcoded for v1.2.
- **Min-words filter for library entries** — explicitly rejected per D-09.
- **Settings UI for `clipboardRestoreDelay`** — Claude's discretion.
- **Configurable HUD content density / visual style** — locked.
- **Separate "Dictations" filter / view in library** — rejected per D-11.
- **Library entry as a copy in app storage when plain-folder is configured** — rejected per D-12.
- **Hard-block on system-reserved hotkeys** — Claude's discretion: warn-but-allow per FEATURES.md.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DICT-01 | Configurable global hotkey, default `Cmd+Shift+D` | KeyboardShortcuts 2.4.0 wraps Carbon `RegisterEventHotKey` (no permissions); see Standard Stack + GlobalHotkeyService API |
| DICT-02 | Toggle vs. press-and-hold mode | KeyboardShortcuts exposes `onKeyDown` (toggle/start) and `onKeyUp` (release) — both wired by GlobalHotkeyService; mode-switch logic lives in DictationCoordinator (CONTEXT D-05/D-07) |
| DICT-03 | Menu bar indicator while recording | `MenuBarExtra` block at PSTranscribeApp.swift:82-93 — toggle SF Symbol based on `dictationCoordinator.isActive` (Code Examples §2) |
| DICT-04 | Floating HUD with live partial transcription | `DictationHUD` SwiftUI view + `DictationWindowController` NSPanel; partial text from dictation engine's `TranscriptStore.volatileYouText` (Code Examples §3, §4) |
| DICT-05 | Final transcript on clipboard on stop | `NSPasteboard.general.setString` + privacy markers (Code Examples §5) |
| DICT-06 | Previous clipboard contents restored after delay | Save before write, restore after `clipboardRestoreDelay` (default 3s) with changeCount guard (Pitfall #6, Code Examples §5) |
| DICT-07 | Each session saved to session library | `LibraryStore.addEntry(...)` from DictationCoordinator.endDictation; LibraryEntry.sessionType = .dictation; row icon already wired (LibraryEntryRow.swift:161) |
| DICT-08 | Escape / second hotkey cancels with no clipboard write; ≥30s confirmation | State machine §5 (DictationCoordinatorState enum), 3s confirmation window |
| DICT-09 | Pasteboard markers exclude from clipboard history | `org.nspasteboard.TransientType` + `org.nspasteboard.AutoGeneratedType` (Code Examples §5, Pitfall #5) |
| DICT-10 | HUD respects existing privacy mode | NSPanel `sharingType = .none` set at creation + AppDelegate observer auto-applies (Pitfall #17, Code Examples §3) |
| DICT-11 | Only one active recording session at a time | `SessionCoordinator.anySessionActive` mutual-exclusion gate at begin (Code Examples §6) |
| FOLDER-01 | Configurable plain folder via folder picker in Settings | Reuse existing `chooseFolder` helper at SettingsView.swift:585 (Code Examples §7) |
| FOLDER-02 | Clean markdown, no YAML frontmatter | `DictationLogger` already enforces this (Phase 16 16-03-SUMMARY.md, source-level grep returns 0 `---` matches) |
| FOLDER-03 | Human-readable filename, no collisions | `DictationLogger` filename `yyyy-MM-dd HH-mm-ss-SSS Dictation.md` (already shipped, Phase 16) |
| FOLDER-04 | Output mode: clipboard / plainFolder / both | `AppSettings.dictationOutputMode` (already shipped, Phase 16); branching in DictationCoordinator.endDictation (Code Examples §8) |
| FOLDER-05 | Plain-folder path persists across restarts | `AppSettings.dictationFolderPath` UserDefaults (already shipped, Phase 16) |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

The user's global CLAUDE.md applies to this project (no `./CLAUDE.md` at repo root). Material directives:

- **Verify before completing** — `/gsd-verify-work` runs deterministic proof; tests must actually pass before claiming done.
- **Never suppress errors** — no `try?` patterns that swallow failures, no empty `catch {}`. Plain-folder write fallback (D-15) is acceptable because it's an explicit policy with `os_log` recording, NOT silent suppression.
- **No commit attribution** — no `Co-Authored-By: Claude…` trailer, no robot footer, plain human-style commit messages.
- **Read before proposing** — RESEARCH.md cites concrete file paths and line numbers; planner should follow same discipline.
- **Hooks beat rules** — verifier (Geoffrey Pattern) catches what advisory rules miss; the Validation Architecture below is hook-style enforcement.

## Standard Stack

### Core (already in place — DO NOT re-add)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Swift | 6.2 | Language | [VERIFIED: Package.swift line 1] |
| FluidAudio | commit ea50062 | Streaming ASR (Parakeet-TDT v3) | [VERIFIED: Package.swift:9] — DICTATION USES A SECOND INSTANCE (Architecture Option B, locked) |
| Sparkle | 2.7.0 | App auto-update | [VERIFIED: Package.swift:10] — unrelated to Phase 18 |

### Net-new dependency for Phase 18

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| sindresorhus/KeyboardShortcuts | **2.4.0** | Global hotkey registration via Carbon `RegisterEventHotKey` + SwiftUI `Recorder` view | [VERIFIED: github.com/sindresorhus/KeyboardShortcuts confirmed 2.4.0 latest, released 2025-09-18] — only macOS API for global hotkeys with no Accessibility/Input Monitoring permission [CITED: STACK.md sources] |

**Verified package version (April 2026):**
- KeyboardShortcuts 2.4.0 [VERIFIED: WebFetch on github.com/sindresorhus/KeyboardShortcuts on 2026-04-27]
- macOS 26 deployment target [VERIFIED: Package.swift:7] is well within KeyboardShortcuts' macOS 10.15+ support [CITED: STACK.md]

**Installation (one new line each in two arrays):**

```swift
// In Package.swift dependencies array, after Sparkle:
.package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.4.0"),

// In PSTranscribe target dependencies array, after Sparkle product:
.product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
```

### Supporting (already imported, no work)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| AppKit | system | NSPanel, NSPasteboard, NSHostingView, NSVisualEffectView | All UI plumbing for the HUD and clipboard |
| Observation | system | `@Observable` macro on `DictationCoordinator` | Reactive UI from coordinator state |
| os | system | `Logger(subsystem:category:)` for diagnostics | Console.app debug + D-15 plain-folder failure logging |

### Alternatives Considered (already rejected in research)

| Instead of | Could Use | Tradeoff | Verdict |
|------------|-----------|----------|---------|
| KeyboardShortcuts | Raw Carbon `RegisterEventHotKey` | No SwiftUI Recorder view; manual UserDefaults persistence | REJECTED [CITED: STACK.md] |
| KeyboardShortcuts | `NSEvent.addGlobalMonitorForEvents` | Requires Accessibility permission — user-hostile | REJECTED [CITED: STACK.md, Pitfall #2] |
| KeyboardShortcuts | `CGEventTap` | Requires Input Monitoring + silent-disable race after re-sign | REJECTED [CITED: STACK.md, Pitfalls #1, #2, #4] |
| Architecture Option B (separate engine) | Option A (reuse engine with sessionType param) | Forks state machine; AVAudioEngine cannot run two instances on same device | REJECTED [CITED: ARCHITECTURE.md, Pitfall #16] |

## Architecture Patterns

### Recommended Project Structure

```
PSTranscribe/Sources/PSTranscribe/
├── App/
│   ├── PSTranscribeApp.swift              # MODIFIED: instantiate hotkey + dictation, MenuBarExtra label
│   ├── SessionCoordinator.swift           # MODIFIED: uncomment dictation slot at line 29-32
│   ├── DictationCoordinator.swift         # NEW: @Observable @MainActor coordinator
│   └── DictationWindowController.swift    # NEW: NSPanel lifecycle + positioning
├── Services/
│   ├── ModelUpdateService.swift           # already shipped Phase 17
│   └── GlobalHotkeyService.swift          # NEW: KeyboardShortcuts wrapper
├── Storage/
│   └── DictationLogger.swift              # MODIFIED: add discardSession()
├── Settings/
│   └── AppSettings.swift                  # NO CHANGES (Phase 16 added all 6 keys)
├── Models/
│   └── Models.swift                       # MAYBE MODIFIED: LibraryEntry.filePath: String? (verify D-12)
└── Views/
    ├── DictationHUD.swift                 # NEW: SwiftUI HUD body
    ├── ContentView.swift                  # MAYBE MODIFIED: NotificationCenter listener for library refresh
    ├── SettingsView.swift                 # MODIFIED: append Section("Dictation") AFTER Speech Model
    └── LibraryEntryRow.swift              # NO CHANGES (line 161 already shows mic.circle.fill for .dictation)
```

**Key insight from inspection:** `LibraryEntryRow.swift:155-162` already covers `case .dictation: return "mic.circle.fill"` — the Phase 16 enum addition propagated. **No work needed for D-11's icon requirement** beyond what already exists. Discretion item: pick `mic.fill` vs `mic.circle.fill` (current code uses the latter).

### Pattern 1: `@Observable @MainActor` Service Wrapping a System Framework

Mirrors `ModelUpdateService` (Phase 17). `GlobalHotkeyService` follows the same shape.

**What:** A class that owns one or more references to a system-level framework, exposes its state as `@Observable` properties, and dispatches all callbacks to MainActor.
**When to use:** Any time the app integrates with a non-Swift, non-Actor system service (KeyboardShortcuts wraps Carbon; ModelUpdateService wraps URLSession + FileManager).

**Source:** Inspected ModelUpdateService.swift:28-107 (lines 28: `@MainActor @Observable final class`; 31: `var updateState`; 88: stored task handle; 108-117: late-binding helper).

```swift
// Pattern lifted from ModelUpdateService.swift:28-107
@MainActor
@Observable
final class GlobalHotkeyService {
    /// User assigned this hotkey (nil if cleared).
    var hotkeyAssigned: Bool { /* read from KeyboardShortcuts.getShortcut(for:) */ false }

    /// Fires on the MainActor when the user presses the registered hotkey.
    /// Set by DictationCoordinator at app init.
    var onKeyDown: (@MainActor () -> Void)?

    /// Fires on the MainActor when the user releases the registered hotkey.
    /// Used by DictationCoordinator to detect press-and-hold release timing (D-07).
    var onKeyUp: (@MainActor () -> Void)?

    init() {
        // Wire KeyboardShortcuts callbacks once. Library handles persistence + recorder UI.
        // [VERIFIED: github.com/sindresorhus/KeyboardShortcuts README]
        KeyboardShortcuts.onKeyDown(for: .dictateGlobal) { [weak self] in
            self?.onKeyDown?()
        }
        KeyboardShortcuts.onKeyUp(for: .dictateGlobal) { [weak self] in
            self?.onKeyUp?()
        }
    }
}

extension KeyboardShortcuts.Name {
    /// Default `Cmd+Shift+D`. Library's `Defaults` system handles persistence to
    /// UserDefaults key `KeyboardShortcuts_dictateGlobal`. User can clear via the
    /// Recorder's built-in UI (Delete key in the recorded-shortcut field clears it).
    /// [CITED: github.com/sindresorhus/KeyboardShortcuts README, Initial Shortcut section]
    static let dictateGlobal = Self(
        "dictateGlobal",
        initial: .init(.d, modifiers: [.command, .shift])
    )
}
```

**Note on `initial:`:** The KeyboardShortcuts README cautions that publicly distributed apps should generally NOT pre-set a default shortcut because users find pre-claimed shortcuts annoying. We accept this for v1.2 because (a) `Cmd+Shift+D` is uncommon enough to rarely conflict, (b) the default is documented in onboarding/Settings, and (c) the Recorder lets users change it instantly. Discretion item: planner may choose to ship with NO initial and force users to set one in Settings on first run. Lean: ship the initial, document it.

### Pattern 2: Floating NSPanel Hosting a SwiftUI View via NSHostingView

The HUD must:
- float above other apps (not steal focus while user types into another app)
- be visible across all spaces and during fullscreen
- inherit the existing privacy mode (`sharingType = .none`)
- be positioned at bottom-center of the active screen

**Source:** AppKit documentation; pattern verified against multiple production macOS apps (SuperWhisper, Voxt floating overlay).

```swift
// File: App/DictationWindowController.swift
import AppKit
import SwiftUI

@MainActor
final class DictationWindowController: NSWindowController {
    init(rootView: AnyView) {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 56),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        // Float above other apps without stealing focus.
        panel.level = .floating
        // Visible across spaces, including fullscreen apps.
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        // Privacy: belt-and-suspenders. AppDelegate's didBecomeKeyNotification observer
        // (PSTranscribeApp.swift:116-131) ALSO catches new windows, but explicit set
        // prevents a brief window where sharingType is wrong. [Pitfall #17]
        panel.sharingType = .none
        // Don't activate the app on show — user keeps typing context.
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = false
        panel.backgroundColor = .clear  // NSVisualEffectView underneath provides material
        panel.hasShadow = true
        panel.isOpaque = false

        // Native HUD vibrancy (D-03): NSVisualEffectView with .hudWindow material.
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 12
        visualEffect.layer?.masksToBounds = true

        // SwiftUI body hosted via NSHostingView.
        let host = NSHostingView(rootView: rootView)
        host.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.addSubview(visualEffect)
        container.addSubview(host)
        visualEffect.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            visualEffect.topAnchor.constraint(equalTo: container.topAnchor),
            visualEffect.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            visualEffect.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            visualEffect.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            host.topAnchor.constraint(equalTo: container.topAnchor),
            host.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            host.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        panel.contentView = container

        super.init(window: panel)
        positionAtBottomCenter()
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    /// Position vertically centered within the bottom quarter of the active screen (D-04).
    private func positionAtBottomCenter() {
        guard let panel = window, let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let panelFrame = panel.frame
        // Bottom quarter = from screenFrame.minY to screenFrame.minY + (screenFrame.height / 4)
        // Vertically centered within that band.
        let bottomBandTop = screenFrame.minY + (screenFrame.height / 4)
        let bottomBandMid = (screenFrame.minY + bottomBandTop) / 2
        let x = screenFrame.midX - (panelFrame.width / 2)
        let y = bottomBandMid - (panelFrame.height / 2)
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    func show() {
        positionAtBottomCenter()  // re-position in case screen config changed
        window?.orderFrontRegardless()
    }

    func hide() {
        window?.orderOut(nil)
    }
}
```

**Critical NSPanel knobs justified:**
- `.nonactivatingPanel` — panel can be shown without making PS Transcribe the active app. User keeps typing context in their target app. [VERIFIED: Apple AppKit docs; ARCHITECTURE.md "DictationHUD: NSPanel" section]
- `.borderless` — no titlebar, no chrome.
- `.floating` level — above normal windows, below modal alerts. Standard for HUDs.
- `.canJoinAllSpaces, .fullScreenAuxiliary` — visible regardless of which space the user is on. `.stationary` keeps it on the current screen even when user switches spaces (matches macOS Dictation feedback).
- `sharingType = .none` — Pitfall #17 belt-and-suspenders: explicit on creation, plus AppDelegate observer at PSTranscribeApp.swift:116-131 catches it via `didBecomeKeyNotification`. [VERIFIED: source inspection of PSTranscribeApp.swift]

### Pattern 3: SwiftUI HUD body with state-driven appearance

```swift
// File: Views/DictationHUD.swift
import SwiftUI

struct DictationHUD: View {
    let state: DictationCoordinatorState
    let elapsed: TimeInterval
    let partialText: String
    let onStop: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Recording dot (red, pulsing in .listening; static dim otherwise)
            recordingIndicator
            // Elapsed timer mm:ss
            Text(formatElapsed(elapsed))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary)
            // Live partial transcript or status text
            Text(displayText)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            // Stop button (D-01) — also reflects "Copied" state visually
            Button("Stop", action: onStop)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .frame(width: 420, height: 56)
    }

    private var displayText: String {
        switch state {
        case .loadingModel:           return "Loading model…"
        case .listening:              return partialText.isEmpty ? "Listening…" : partialText
        case .cancellingPending:      return "Press Esc again to cancel"
        case .copied:                 return "Copied to clipboard"
        case .blockedSessionActive:   return "Recording in progress — dictation unavailable"
        case .idle:                   return ""
        }
    }
    // ...
}

enum DictationCoordinatorState: Equatable {
    case idle
    case loadingModel              // D-16: pre-warm in flight or failed
    case listening                 // active recording
    case cancellingPending         // D-06: 30s threshold, awaiting second Esc
    case copied                    // D-02: ~1.0s post-stop confirmation
    case blockedSessionActive      // D-14: meeting recording is active
}
```

### Pattern 4: Clipboard write with privacy markers + restore-with-changeCount-guard

See Code Examples §5 below.

### Anti-Patterns to Avoid

- **Reading from `NSPasteboard.general` in the dictation flow.** Triggers macOS 26 pasteboard privacy alert (Pitfall #7). Save before write, restore after delay — but never read again to "verify" the write succeeded. [CITED: PITFALLS.md #7]
- **Calling `dictationEngine.start(...)` synchronously inside the hotkey callback.** Even though KeyboardShortcuts uses Carbon (no Accessibility, no event-tap timeout), the ASR start can take hundreds of milliseconds. Always dispatch as `Task { @MainActor in await coordinator.beginDictation() }`. [CITED: PITFALLS.md #4 — applies even though we sidestepped CGEventTap]
- **Forking the recording state machine.** Architecture Option B (separate engine instance) is locked precisely because two `AVAudioEngine.start()` calls on the same device crash. Mutual exclusion via `SessionCoordinator.anySessionActive` is the only safe pattern. [CITED: PITFALLS.md #16]
- **Skipping privacy markers on the pasteboard write.** Every dictation pollutes Alfred/Maccy/Pasta history without them. [CITED: PITFALLS.md #5]
- **Reusing `TranscriptLogger.startSession` instead of `DictationLogger.startSession`.** TranscriptLogger writes YAML frontmatter; FOLDER-02 forbids it. DictationLogger is single-purpose by design. [CITED: 16-03-SUMMARY.md]
- **Trusting `LibraryEntry.filePath` to tolerate empty strings without inspection.** `LibraryEntry.filePath` is `let filePath: String` (non-optional) at Models.swift:85. Existing Phase 10 code reads `entry.filePath` for "Show in Finder" (LibraryEntryRow.swift:73-77) and would crash on `URL(fileURLWithPath: "")`. **Action required:** Wave 2 must either (a) refactor `filePath` to `String?` OR (b) always assign a sentinel value for clipboard-only entries. See Open Questions §1.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Global hotkey registration | Custom Carbon wrapper | KeyboardShortcuts 2.4.0 | Library wraps `RegisterEventHotKey`, supplies SwiftUI Recorder view, persistence via Defaults, conflict warning UI. Hand-rolling = 200+ lines of Carbon glue with no Recorder. |
| Plain-markdown writer | New writer or extension on `TranscriptLogger` | `DictationLogger` (already shipped Phase 16) | Already does collision-safe filenames, 0o600 perms, path validation. Adding `discardSession()` is the only delta. |
| Hotkey persistence to UserDefaults | Custom serialization | KeyboardShortcuts internal `Defaults` system (key `KeyboardShortcuts_dictateGlobal`) | Library handles encoding the Shortcut struct + restoring it on launch. Free. |
| Folder picker | Custom NSOpenPanel call site | `chooseFolder(message:onSelect:)` at SettingsView.swift:585 | Already DRY-extracted; reused by Obsidian + Notion folder pickers. |
| LibraryEntry.sessionType row icon | New view code | `LibraryEntryRow.swift:155-162` already returns `mic.circle.fill` for `.dictation` | Phase 16 enum addition propagated; no UI work needed beyond optionally swapping the symbol per D-11. |
| `prepareModels()` retry/fallback | Custom retry | Reuse `TranscriptionEngine.prepareModels()` (TranscriptionEngine.swift:117-143) | Already idempotent (`guard !modelsReady, asrManager == nil else { return }`); already sets `lastError` on failure. Pre-warm just calls it on the dictation engine instance. |
| NSPasteboard privacy markers | Custom encoding | Direct string types `org.nspasteboard.TransientType` and `org.nspasteboard.AutoGeneratedType` | Specification at nspasteboard.org; one-line API call per type. |
| Mutual-exclusion guard | NotificationCenter / Combine bridge | `SessionCoordinator.anySessionActive` (already shipped Phase 16) | Computed property reads each subsystem on demand. Single source of truth. |

**Key insight:** Phase 18's net-new SLOC is small because Phase 16 carved out exactly the seams Phase 18 needs. The biggest custom code is `DictationCoordinator` (state machine + lifecycle, ~250 lines estimated) and `DictationHUD`/`DictationWindowController` (~150 lines combined). `GlobalHotkeyService` is ~40 lines. Total Phase 18 net-new code is well under 600 lines including tests.

## Runtime State Inventory

Phase 18 is greenfield additive code — no rename, no migration, no refactor of stored state. State inventory not applicable. **Confirmed:** all 5 categories have no items because the phase introduces brand-new persisted keys (already added in Phase 16) and a brand-new file output format (already designed in Phase 16). No existing string is being renamed; no live service config is being mutated; no OS-registered tasks change.

One item that LOOKS like state but isn't: the user's hotkey selection persists in UserDefaults under `KeyboardShortcuts_dictateGlobal`. This is created the first time KeyboardShortcuts wires up; nothing to migrate. If Phase 16 ever shipped a stub key with that name, it would collide — verified via `grep -r "dictateGlobal" PSTranscribe/Sources/ PSTranscribe/Tests/` returning **0 matches**. Safe.

## Common Pitfalls

### Pitfall 1: NSPasteboard changeCount race on fast user paste sequences

**What goes wrong:** App saves changeCount before write, schedules restore in 3s. User pastes (Cmd+V), then copies something else manually within the 3s window. App's restore overwrites the user's manual copy.
**Why it happens:** changeCount is a global counter; saving the post-write value isn't sufficient to detect "did the user touch the clipboard between my write and my restore?"
**How to avoid:** After writing the dictation text, immediately record `let postWriteCount = NSPasteboard.general.changeCount`. In the restore Task, before restoring, check `NSPasteboard.general.changeCount == postWriteCount`. If different, **skip restore**. The user's intentional copy wins. [CITED: PITFALLS.md #6]
**Warning signs:** User reports "my copied text disappeared after a dictation" — they were the recipient of an over-eager restore.

### Pitfall 2: Press-and-hold release `< 1s` mistaken-tap silent cancel (D-07)

**What goes wrong:** In hold mode, KeyboardShortcuts fires `onKeyDown` immediately and `onKeyUp` on release. If the coordinator already started the recording engine on `onKeyDown`, a sub-1s tap costs ~500ms of audio capture for nothing.
**Why it happens:** Coordinator can't predict the release time. Engine start is eager.
**How to avoid:** Even in `.pressAndHold` mode, treat `onKeyDown` as `beginDictation` and `onKeyUp` as the natural commit point. Inside `onKeyUp`, check `Date().timeIntervalSince(sessionStartTime) < 1.0` → call `cancelDictation()` (which discards the file via `DictationLogger.discardSession()`, no clipboard write, no library entry). Mirrors Voxt's behavior. [CITED: FEATURES.md "Cancel Behavior" — `<1s hold should cancel rather than transcribe noise`]
**Warning signs:** Library has empty/single-word dictation entries from accidental hotkey taps. (D-09 says ALL successful dictations land in library; the `<1s` cancel prevents this case from ever being "successful.")

### Pitfall 3: 30s cancel-confirmation state machine race (D-06)

**What goes wrong:** User presses Esc twice rapidly within ~100ms — both events fire while `cancellingPending` flag is being set. Either the second Esc is dropped (no cancel) or the first is dropped (no confirmation, immediate cancel — not what D-06 says).
**Why it happens:** State transitions on `@MainActor` are sequential, but if both events arrive in the same runloop tick, ordering can be subtle.
**How to avoid:** Implement as a 3-state machine on the coordinator: `.listening` → `.cancellingPending(deadline: Date)` → either `.cancelled` (second Esc within window) or back to `.listening` (deadline expired via `Task.sleep(for: .seconds(3)) { revert }`). Use `Task` cancellation: when entering `.cancellingPending`, store the revert task; if a second Esc arrives, cancel the revert task and transition to `.cancelled`. Cancellation of the timer is the atomic signal.
**Warning signs:** Esc-double-tap results in inconsistent behavior (sometimes cancels, sometimes shows confirmation forever).

### Pitfall 4: AppDelegate `didBecomeKeyNotification` observer doesn't fire for `.nonactivatingPanel`

**What goes wrong:** The HUD never becomes the key window (by design — `.nonactivatingPanel`), so `didBecomeKeyNotification` doesn't fire, so the existing privacy-mode observer at PSTranscribeApp.swift:116-131 doesn't apply `sharingType` to the HUD.
**Why it happens:** Non-activating panels never claim key-window status.
**How to avoid:** Set `panel.sharingType = .none` explicitly in `DictationWindowController.init`. The AppDelegate observer is a fallback for windows that follow the normal key-window flow; the HUD doesn't, so we set it directly. [VERIFIED: AppKit docs; ARCHITECTURE.md notes this]
**Warning signs:** ScreenCaptureKit-based recording (Zoom screen share, QuickTime screen recording) shows the HUD anyway — but that's the documented unfixable limitation, not this bug. The bug here would be: legacy `CGWindowListCreateImage` capture also shows the HUD, which means `sharingType` was never set.

### Pitfall 5: Two `TranscriptionEngine` instances both calling `AsrModels.downloadAndLoad(version: .v3)` simultaneously at launch

**What goes wrong:** Existing meeting engine's `prepareModels()` and dictation engine's `prepareModels()` both run in background at app launch (D-13 + Phase 16's existing flow). FluidAudio's download path may not be re-entrant on the same cache directory.
**Why it happens:** Two `Task` blocks running concurrently. On a fresh install where the model isn't cached yet, both calls try to download to the same target directory.
**How to avoid:** Inspection of TranscriptionEngine.swift:117-143 shows `guard !modelsReady, asrManager == nil else { return }` — idempotent on a per-instance basis but NOT cross-instance. `AsrModels.downloadAndLoad` itself short-circuits via `DownloadUtils.allModelsExist` ([CITED: 17-CONTEXT.md D-13 reload note]) when files are already on disk. **First-launch concern:** the dictation engine's `prepareModels()` should be deferred until the meeting engine's completes, OR the dictation engine pre-warm should be skipped on first run (where models aren't yet downloaded) and triggered after onboarding. **Recommendation:** in PSTranscribeApp init, call `dictationCoordinator.preWarmAfter(meetingEngineReady:)` — coordinator awaits a notification or polls `meetingEngine.modelsReady` before starting its own `prepareModels()`. Discretion item: planner picks the exact synchronization shape.
**Warning signs:** First-launch download stuttering / partial files / model load failure on one engine but not the other.

### Pitfall 6: `LibraryEntry.filePath: String` (non-optional) breaks for clipboard-only entries

**What goes wrong:** D-12 wants library entries for clipboard-only mode to NOT point at any file. Current `LibraryEntry.filePath: String` (Models.swift:85) is non-optional. An empty string is structurally allowed but: LibraryEntryRow.swift:60-62 reads `FileManager.default.fileExists(atPath: entry.filePath)` (returns true for empty string oddly enough due to `/`), and lines 73-77 use `URL(fileURLWithPath: entry.filePath).deletingLastPathComponent().path` which on `""` returns `""`. The "Show in Finder" context menu would Finder-open `""`, surfacing the home directory or worse.
**Why it happens:** Phase 16 didn't refactor LibraryEntry; D-12 was deferred to Phase 18 verification.
**How to avoid:** Wave 2 task — refactor `filePath: String` to `filePath: String?`. Update all 19 call sites (grep for `entry.filePath`, `.filePath` on LibraryEntry). Adjust JSON Codable to encode nil-as-absent. Migration: existing `library.json` has `filePath` always present; decoder should accept old shape (always present, possibly empty) and new shape (optional, may be absent).
**Warning signs:** Library row shows a missing-file warning badge (red triangle, LibraryEntryRow.swift:138) for every clipboard-only dictation. "Show in Finder" opens nothing or wrong location.

### Pitfall 7: NSPasteboard write race when meeting recording is also writing transcripts

**What goes wrong:** Dictation finishes and writes to clipboard at the same moment the meeting recording's session-end Notion sender is also touching the clipboard (e.g., copying a URL).
**Why it happens:** Per Pitfall #11 (D-11), only one recording is active at a time, but the meeting export flow can still touch the pasteboard outside the recording window.
**How to avoid:** Coordinator's `endDictation` writes the pasteboard last in a synchronous run on MainActor. Existing meeting flow doesn't write to pasteboard during a session (verified by `grep -n "NSPasteboard" PSTranscribe/Sources/PSTranscribe/` — only future Phase 18 code will write). Low real-world risk; flag for code review.
**Warning signs:** Any test that writes to pasteboard during a meeting flow needs to be re-run with dictation flow.

## Code Examples

### §1. KeyboardShortcuts.Name registration (verified)

```swift
// File: Services/GlobalHotkeyService.swift  [Source: github.com/sindresorhus/KeyboardShortcuts README]
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// Default Cmd+Shift+D. Library handles persistence to UserDefaults
    /// key `KeyboardShortcuts_dictateGlobal`. The string ID survives across
    /// app launches and even hotkey-rebind events.
    static let dictateGlobal = Self(
        "dictateGlobal",
        initial: .init(.d, modifiers: [.command, .shift])
    )
}
```

### §2. MenuBarExtra pulsing-mic indicator (DICT-03)

```swift
// File: App/PSTranscribeApp.swift  — modify the existing block at lines 82-93
MenuBarExtra {
    // existing menu content unchanged
} label: {
    Image(systemName: dictationCoordinator.isActive ? "mic.fill" : "book.closed")
        .symbolRenderingMode(.monochrome)
        .symbolEffect(.pulse, isActive: dictationCoordinator.isActive)  // SF Symbols pulse animation
}
```

`.symbolEffect(.pulse, isActive:)` is the SwiftUI sugar for the SF Symbols pulse effect; available since macOS 14. [VERIFIED: Apple SF Symbols documentation]

### §3. NSPanel HUD configuration

(See Pattern 2 above — full DictationWindowController.swift block.)

### §4. DictationCoordinator API skeleton

```swift
// File: App/DictationCoordinator.swift
import AppKit
import Foundation
import Observation

@Observable
@MainActor
final class DictationCoordinator {
    // MARK: - State

    enum State: Equatable {
        case idle
        case loadingModel
        case listening
        case cancellingPending(deadline: Date)
        case copied
        case blockedSessionActive
    }

    private(set) var state: State = .idle
    private(set) var elapsed: TimeInterval = 0
    private(set) var partialText: String = ""

    /// Convenience flag read by SessionCoordinator and the menu-bar label.
    var isActive: Bool {
        switch state {
        case .listening, .cancellingPending, .loadingModel: return true
        case .idle, .copied, .blockedSessionActive: return false
        }
    }

    // MARK: - Dependencies

    private let settings: AppSettings
    private weak var sessionCoordinator: SessionCoordinator?
    private let libraryStore: LibraryStore
    private let dictationLogger: DictationLogger
    private let dictationStore: TranscriptStore
    private let dictationEngine: TranscriptionEngine
    private let windowController: DictationWindowController
    private let log = Logger(subsystem: "com.pstranscribe.app", category: "Dictation")

    // MARK: - Internal state

    private var sessionStartTime: Date?
    private var elapsedTimerTask: Task<Void, Never>?
    private var cancelRevertTask: Task<Void, Never>?
    private var copiedDismissTask: Task<Void, Never>?
    /// Non-empty path = plain-folder file is open; empty = clipboard-only or no session.
    private var openFolderFilePath: URL?
    /// Clipboard restore state (DICT-06).
    private var savedPasteboardItems: [NSPasteboardItem]?
    private var postWriteChangeCount: Int?
    private var restoreTask: Task<Void, Never>?

    init(settings: AppSettings,
         sessionCoordinator: SessionCoordinator,
         libraryStore: LibraryStore) {
        self.settings = settings
        self.sessionCoordinator = sessionCoordinator
        self.libraryStore = libraryStore
        self.dictationLogger = DictationLogger()
        self.dictationStore = TranscriptStore()
        self.dictationEngine = TranscriptionEngine(transcriptStore: dictationStore)
        self.windowController = DictationWindowController(rootView: AnyView(EmptyView()))
        // Recreate windowController content with our state-driven HUD
        // (window controller's NSHostingView gets pointed at a closure that reads `self`)
        self.windowController.installContent {
            AnyView(
                DictationHUD(
                    state: self.state,
                    elapsed: self.elapsed,
                    partialText: self.partialText,
                    onStop: { Task { @MainActor in await self.endDictation() } }
                )
            )
        }
    }

    // MARK: - Lifecycle

    /// Background pre-warm at app launch (D-13). Safe to call on a Task.
    func preWarmModels() async {
        await dictationEngine.prepareModels()
    }

    /// Begin dictation. Idempotent; no-op if already active. Mutual exclusion
    /// against the meeting engine via SessionCoordinator.anySessionActive (D-14).
    func beginDictation() async {
        guard !isActive else { return }
        if sessionCoordinator?.anySessionActive == true {
            // D-14: brief blocked-state HUD, auto-dismiss in ~1.5s.
            await showBlockedNotice()
            return
        }
        sessionStartTime = Date()
        partialText = ""
        elapsed = 0

        // Open plain-folder file BEFORE starting engine (so we can discard atomically on cancel).
        if settings.dictationOutputMode == .plainFolder || settings.dictationOutputMode == .both {
            do {
                try await dictationLogger.startSession(folderPath: settings.dictationFolderPath)
                openFolderFilePath = await dictationLogger.endSession()  // peek only — re-open below
                // Re-open after the peek (DictationLogger has no peek API; alternative:
                // expose currentFilePath getter on the actor — see Open Questions §3).
                try await dictationLogger.startSession(folderPath: settings.dictationFolderPath)
            } catch {
                log.error("Plain-folder open failed: \(error.localizedDescription, privacy: .public). Falling back to clipboard-only.")
                openFolderFilePath = nil
                // D-15: silent fallback to clipboard-only. Continue.
            }
        }

        // Show HUD.
        state = dictationEngine.modelsReady ? .listening : .loadingModel
        windowController.show()

        // Start elapsed-time ticker (drives HUD timer mm:ss).
        elapsedTimerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                guard let self else { return }
                if let start = self.sessionStartTime { self.elapsed = Date().timeIntervalSince(start) }
            }
        }

        // Wire dictationStore.volatileYouText → self.partialText
        // (Observation tracking handles this implicitly when DictationHUD reads dictationStore.)

        // Start the engine. If models not ready, await prepare first (D-16).
        await dictationEngine.start(
            locale: settings.locale,
            inputDeviceID: settings.inputDeviceID,
            appBundleID: nil
        )
        if dictationEngine.modelsReady && state == .loadingModel {
            state = .listening
        }
    }

    /// Stop & commit. Default termination path for D-05 toggle and D-07 hold-with-≥1s.
    func endDictation() async {
        guard case .listening = state else {
            // Also accepts .cancellingPending if user changed mind.
            if case .cancellingPending = state { state = .listening }
            else { return }
        }
        await dictationEngine.stop()
        elapsedTimerTask?.cancel(); elapsedTimerTask = nil

        // Assemble final transcript from utterances + lingering volatile text.
        let utterances = dictationStore.utterances.map { $0.text }
        let volatile = dictationStore.volatileYouText.trimmingCharacters(in: .whitespacesAndNewlines)
        let assembled = (utterances + (volatile.isEmpty ? [] : [volatile]))
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Plain-folder finalize.
        var finalFileURL: URL? = nil
        if openFolderFilePath != nil {
            finalFileURL = await dictationLogger.endSession()
        }

        // Clipboard write per output mode.
        let mode = settings.dictationOutputMode
        if mode == .clipboard || mode == .both {
            writeToClipboardWithPrivacyMarkers(assembled)
            scheduleClipboardRestore(after: settings.clipboardRestoreDelay)
        }

        // Library entry. D-09: every successful dictation lands. D-10: auto-name.
        await libraryStore.addEntry(
            LibraryEntry(
                id: UUID(),
                name: autoNameFromTranscript(assembled),
                sessionType: .dictation,
                startDate: sessionStartTime ?? Date(),
                duration: elapsed,
                filePath: finalFileURL?.path ?? "",  // OR nil pending Pitfall #6 fix
                sourceApp: "PSTranscribe",
                isFinalized: true,
                firstLinePreview: String(assembled.prefix(120)),
                notionPageURL: nil
            )
        )

        // D-02: copied confirmation pill ~1.0s.
        state = .copied
        copiedDismissTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(1000))
            guard let self else { return }
            self.windowController.hide()
            self.state = .idle
            self.cleanupSession()
        }

        // Notify ContentView library to refresh.
        NotificationCenter.default.post(name: .dictationSessionEnded, object: nil)
    }

    /// Cancel without commit. D-08 atomic: no clipboard, no library, delete plain-folder file.
    func cancelDictation() async {
        guard isActive else { return }
        await dictationEngine.stop()
        elapsedTimerTask?.cancel()
        cancelRevertTask?.cancel()

        if openFolderFilePath != nil {
            await dictationLogger.discardSession()  // NEW API — Wave 2
        }
        windowController.hide()
        state = .idle
        cleanupSession()
    }

    /// Esc handler: routes to immediate cancel (<30s) or transitions to .cancellingPending (≥30s).
    func handleEscape() async {
        guard case .listening = state else {
            // If already in cancellingPending, this is the confirming second Esc.
            if case .cancellingPending = state {
                await cancelDictation()
            }
            return
        }
        let duration = elapsed
        if duration < 30.0 {
            await cancelDictation()
        } else {
            // D-06: enter cancellingPending state, revert in 3s if no second Esc.
            let deadline = Date().addingTimeInterval(3.0)
            state = .cancellingPending(deadline: deadline)
            cancelRevertTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(3))
                guard let self else { return }
                if case .cancellingPending = self.state {
                    self.state = .listening
                }
            }
        }
    }

    /// Press-and-hold release handler (D-07). Called by GlobalHotkeyService.onKeyUp
    /// only when AppSettings.dictationHotkeyMode == .pressAndHold.
    func handleHoldRelease() async {
        guard case .listening = state, let start = sessionStartTime else { return }
        let held = Date().timeIntervalSince(start)
        if held < 1.0 {
            await cancelDictation()  // accidental tap, silent
        } else {
            await endDictation()      // commit
        }
    }

    // MARK: - Helpers

    private func cleanupSession() {
        sessionStartTime = nil
        elapsed = 0
        partialText = ""
        openFolderFilePath = nil
        dictationStore.clear()
    }

    private func showBlockedNotice() async {
        state = .blockedSessionActive
        windowController.show()
        try? await Task.sleep(for: .milliseconds(1500))
        windowController.hide()
        state = .idle
    }
}

extension Notification.Name {
    static let dictationSessionEnded = Notification.Name("com.pstranscribe.dictationSessionEnded")
}
```

### §5. Clipboard write with privacy markers + restore-with-changeCount-guard

```swift
// In DictationCoordinator:

private func writeToClipboardWithPrivacyMarkers(_ text: String) {
    let pb = NSPasteboard.general
    // Save before write — single read, never read again (Pitfall #7).
    let priorChangeCount = pb.changeCount
    savedPasteboardItems = pb.pasteboardItems?.compactMap { item in
        // Deep-copy the item: NSPasteboardItem retains references, so we re-create with current data.
        let copy = NSPasteboardItem()
        for type in item.types {
            if let data = item.data(forType: type) {
                copy.setData(data, forType: type)
            }
        }
        return copy
    }

    pb.clearContents()
    pb.setString(text, forType: .string)
    // Privacy markers (DICT-09 / Pitfall #5). [Source: nspasteboard.org spec]
    pb.setData(Data(), forType: NSPasteboard.PasteboardType("org.nspasteboard.TransientType"))
    pb.setData(Data(), forType: NSPasteboard.PasteboardType("org.nspasteboard.AutoGeneratedType"))

    // Record the change count post-write for the restore guard.
    postWriteChangeCount = pb.changeCount
    _ = priorChangeCount  // unused, kept for clarity if we later add validation
}

private func scheduleClipboardRestore(after delay: TimeInterval) {
    restoreTask?.cancel()
    restoreTask = Task { [weak self] in
        try? await Task.sleep(for: .seconds(delay))
        guard let self,
              let postWriteCount = self.postWriteChangeCount,
              let saved = self.savedPasteboardItems else { return }
        let pb = NSPasteboard.general
        // Pitfall #6: if user copied something else during the window, skip restore.
        guard pb.changeCount == postWriteCount else {
            self.log.info("Clipboard restore skipped — user copied something during the restore window.")
            self.savedPasteboardItems = nil
            self.postWriteChangeCount = nil
            return
        }
        pb.clearContents()
        pb.writeObjects(saved)
        self.savedPasteboardItems = nil
        self.postWriteChangeCount = nil
    }
}
```

### §6. SessionCoordinator update for dictation slot

```swift
// File: App/SessionCoordinator.swift — replace lines 29-32 (the comment) with:

/// Phase 18 (Hotkey Dictation). Held weakly: DictationCoordinator is owned at app
/// scope (PSTranscribeApp) and wired here via direct assignment in init.
weak var dictation: DictationCoordinator?

// And update anySessionActive at line 38-40:
var anySessionActive: Bool {
    (engine?.isRunning ?? false)
        || (modelUpdate?.isApplying ?? false)
        || (dictation?.isActive ?? false)
}
```

### §7. Settings UI for the Dictation section

```swift
// File: Views/SettingsView.swift — append AFTER Section("Speech Model") at line 65:
import KeyboardShortcuts

Section("Dictation") {
    KeyboardShortcuts.Recorder("Hotkey", name: .dictateGlobal)
        .font(.system(size: 12))
    Picker("Hotkey behavior", selection: $settings.dictationHotkeyMode) {
        Text("Toggle (tap to start, tap to stop)").tag(DictationHotkeyMode.toggle)
        Text("Hold (record while pressed)").tag(DictationHotkeyMode.pressAndHold)
    }
    .font(.system(size: 12))
    Picker("Output", selection: $settings.dictationOutputMode) {
        Text("Clipboard only").tag(DictationOutputMode.clipboard)
        Text("Plain folder only").tag(DictationOutputMode.plainFolder)
        Text("Both").tag(DictationOutputMode.both)
    }
    .font(.system(size: 12))
    HStack {
        Text("Folder")
        Text(settings.dictationFolderPath.isEmpty ? "Not set" : settings.dictationFolderPath)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
        Spacer()
        Button("Choose…") {
            chooseFolder(message: "Select dictation output folder") { path in
                settings.dictationFolderPath = path
            }
        }
    }
    .disabled(settings.dictationOutputMode == .clipboard)
    // clipboardRestoreDelay control (Claude's discretion):
    HStack {
        Text("Restore previous clipboard after")
        Stepper(value: $settings.clipboardRestoreDelay, in: 0...30, step: 0.5) {
            Text(String(format: "%.1fs", settings.clipboardRestoreDelay))
                .font(.system(.body, design: .monospaced))
        }
    }
    .font(.system(size: 12))
}
```

### §8. DictationLogger.discardSession() (NEW API)

```swift
// File: Storage/DictationLogger.swift — add after endSession() at line 100:

/// Cancel the active session: close the file handle and DELETE the file.
/// Idempotent — calling after a closed session is a no-op (returns silently).
/// Mirrors `endSession` but unlinks instead of returning the URL.
/// [Phase 18 D-08: cancel cleanup is atomic]
func discardSession() {
    try? fileHandle?.close()
    fileHandle = nil
    if let url = currentFilePath {
        try? FileManager.default.removeItem(at: url)
    }
    currentFilePath = nil
    sessionStartTime = nil
}
```

### §9. Auto-name algorithm (D-10)

```swift
// In DictationCoordinator (or extracted to a free function for testability):

/// Generates a library entry name from the transcript per D-10.
/// Take first ~5 whitespace-separated tokens, truncate to 50 chars on word boundary,
/// append `…` if truncated, strip leading/trailing ASCII punctuation. If empty after
/// stripping, fallback to "Dictation YYYY-MM-DD HH:mm".
private func autoNameFromTranscript(_ raw: String) -> String {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
        return fallbackTimestampName()
    }
    let tokens = trimmed.split(separator: " ", omittingEmptySubsequences: true).prefix(5)
    var candidate = tokens.joined(separator: " ")

    // Truncate at 50 chars on word boundary.
    if candidate.count > 50 {
        let limit = candidate.index(candidate.startIndex, offsetBy: 50)
        var sliceEnd = limit
        while sliceEnd > candidate.startIndex && candidate[sliceEnd] != " " {
            sliceEnd = candidate.index(before: sliceEnd)
        }
        if sliceEnd == candidate.startIndex {
            // No space found in first 50 chars — hard truncate.
            candidate = String(candidate.prefix(50))
        } else {
            candidate = String(candidate[..<sliceEnd])
        }
        candidate += "…"
    }

    // Strip leading/trailing ASCII punctuation.
    let punct = CharacterSet(charactersIn: ".,;:!?\"'()[]{}<>-_`~/\\")
    candidate = candidate.trimmingCharacters(in: punct)

    return candidate.isEmpty ? fallbackTimestampName() : candidate
}

private func fallbackTimestampName() -> String {
    let fmt = DateFormatter()
    fmt.locale = Locale(identifier: "en_US_POSIX")
    fmt.dateFormat = "yyyy-MM-dd HH:mm"
    return "Dictation \(fmt.string(from: Date()))"
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hand-rolled Carbon `RegisterEventHotKey` glue | KeyboardShortcuts 2.4.0 | 2025-09-18 (v2.4.0 release) | -200 lines of Carbon, free SwiftUI Recorder |
| `NSEvent.addGlobalMonitorForEvents` | KeyboardShortcuts (Carbon under the hood) | macOS 10.13+ | No Accessibility prompt = better install experience |
| `CGEventTap` for hotkeys | KeyboardShortcuts (Carbon under the hood) | always | No silent-disable race after re-sign (Pitfall #1 sidestepped entirely) |
| Pasteboard write without markers | `org.nspasteboard.TransientType` + `AutoGeneratedType` | nspasteboard.org spec, ~2018 | Excludes from Alfred/Maccy/Pasta |
| Reading pasteboard to "verify" write | Write only, never read | macOS 26 (planned) | Avoids upcoming pasteboard privacy alert (Pitfall #7) |
| `sharingType = .none` on main window only | Apply to every NSWindow + NSPanel | always | HUD inherits privacy mode (Pitfall #17) |
| Reuse single `TranscriptionEngine` across modes | Two instances, one per use case (Architecture Option B) | Phase 18 | No state-machine fork, no audio-engine collision |

**Deprecated/outdated:**
- Carbon `RegisterEventHotKey` is technically deprecated by Apple but stable; Apple has not shipped a replacement. KeyboardShortcuts hides it. [CITED: STACK.md "Version Compatibility"]
- `NSPasteboard.changeCount`-as-success-indicator pattern is anti-pattern in 2026 (Pitfall #6); use it only as a guard, not as verification.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | KeyboardShortcuts.Recorder allows users to clear the hotkey via Delete key in the recorder field | Pattern 1 / GlobalHotkeyService | Medium — if not, planner adds explicit "Clear" button; functional equivalent. The library README does not explicitly state this but most macOS hotkey-recorder controls including this one work this way. |
| A2 | Two `TranscriptionEngine` instances calling `AsrModels.downloadAndLoad(version: .v3)` against the same cache directory at app launch are safe (FluidAudio's `DownloadUtils.allModelsExist` short-circuits) on warm starts and we control first-launch ordering | Pitfall #5 | Medium — first-launch may need explicit serialization. If wrong, we add a `prepareModelsAfter(_ otherEngine:)` helper. Discretion item flagged for planner. |
| A3 | `LibraryEntry.filePath: String?` migration is safe; existing JSON decoder accepts both old (always-present) and new (optional) shapes via Swift Codable's automatic Optional handling | Pitfall #6 | Low — Codable optionals are backward-compat by default. Migration test required. |
| A4 | NSPasteboardItem deep-copy via `for type in item.types { copy.setData(item.data(forType: type), forType: type) }` correctly preserves all real-world clipboard types (RTF, image, file URL list) for restore | Code Examples §5 | Low — there are exotic flavors (e.g., promised file types) that may not survive. Acceptable: if restore is imperfect, log it; user's own copy was the lower-priority case anyway. |
| A5 | The `.symbolEffect(.pulse, isActive:)` modifier is available on macOS 14+; project targets macOS 26+ so it's available | Code Examples §2 | None — verified via Apple SF Symbols docs. |
| A6 | KeyboardShortcuts.onKeyDown and onKeyUp are both fired on the MainActor by the library | Pattern 1 | Low — library README's example code shows direct UI updates from the callback, implying MainActor. If wrong, our Task wrapping is a safe no-op. |

**Plan_check trigger:** A1, A2, A3 should each be verified by a test or code inspection during Wave 1/2; if any are wrong, the planner should add a small fixup task before later waves depend on them.

## Open Questions

1. **Should `LibraryEntry.filePath` become Optional, or do we always assign a sentinel like an empty string?**
   - What we know: D-12 says clipboard-only entries should not point at any file. `LibraryEntry.filePath: String` is non-optional. Existing call sites (LibraryEntryRow.swift:60, 73-77) read it without nil-checks.
   - What's unclear: whether the cleaner refactor (Optional) or the sentinel (`""`) is closer to the project's existing conventions. Looking at the codebase, other Optionals exist (`name: String?`, `firstLinePreview: String?`, `notionPageURL: String?`) — so Optional fits the pattern.
   - Recommendation: refactor to `String?`. Wave 2 task. Update all 19 read sites with `?? ""` or proper nil-handling. Add a test that decodes an old `library.json` with `filePath: ""` AND a new one with `filePath: nil` (or absent) — both should round-trip.

2. **Pre-warm timing on first launch — sequence the two `prepareModels()` calls or run concurrently?**
   - What we know: both `meeting engine.prepareModels()` and `dictation engine.prepareModels()` are called at app launch. They share the on-disk model cache. FluidAudio's `DownloadUtils.allModelsExist` short-circuits when files are present.
   - What's unclear: behavior on a fresh install where the model isn't cached. Two concurrent downloads to the same target?
   - Recommendation: in Wave 7 integration, dictationCoordinator.preWarmModels() awaits a notification or polls `meetingEngine.modelsReady == true OR meetingEngine.assetStatus == "Ready"` before calling its own prepareModels. On warm starts (already cached) this is instant. Cost: ~0ms warm, fully serialized cold.

3. **DictationLogger has no public getter for `currentFilePath`; how does DictationCoordinator know whether a file is open without re-opening?**
   - What we know: DictationLogger.swift:33 `private var currentFilePath: URL?`; only `endSession()` returns it. Coordinator tracks an `openFolderFilePath: URL?` independently.
   - What's unclear: whether to add a public getter (`var isSessionOpen: Bool` or `var currentURL: URL?`) on the actor, or rely on the coordinator's parallel state.
   - Recommendation: add a `var hasActiveSession: Bool { currentFilePath != nil }` async property to DictationLogger in Wave 2 (small, additive). Coordinator queries it instead of mirroring state. Reduces drift risk.

4. **HUD width if user's screen is narrower than 420pt** (e.g., compact-mode external display, edge case)?
   - What we know: NSPanel content rect is set to 420×56 in `DictationWindowController`.
   - What's unclear: whether to clamp to `min(420, screen.visibleFrame.width - 40)` or leave fixed.
   - Recommendation: clamp during `positionAtBottomCenter()` — if `panelFrame.width > screenFrame.width - 40`, reduce panelFrame.width and re-center. Edge case handling.

5. **Should the dictation-session library entry's `sourceApp` be `"PSTranscribe"` or the frontmost app at hotkey-press time?**
   - What we know: existing meeting/voice memo flows use `"PSTranscribe"` (verified via grep; the field is mostly informational).
   - What's unclear: whether dictation-from-Slack should record `sourceApp = "Slack"`. This requires reading `NSWorkspace.shared.frontmostApplication?.bundleIdentifier` at begin time.
   - Recommendation: ship with `"PSTranscribe"` (consistent with existing entries). Defer per-app source tracking to a future polish.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Swift toolchain | All Phase 18 code | ✓ | 6.2 (Package.swift:1) | — |
| FluidAudio | Dictation engine (second instance) | ✓ | ea50062 (Package.swift:9) | — |
| KeyboardShortcuts | GlobalHotkeyService (NEW) | ✗ | needs SwiftPM resolve | If resolve fails, hotkey functionality cannot ship; no fallback that preserves "no Accessibility permission" requirement |
| AppKit (NSPanel, NSPasteboard, NSVisualEffectView, NSHostingView) | DictationWindowController, clipboard write, HUD body | ✓ | system | — |
| macOS 14+ for `.symbolEffect(.pulse)` | DICT-03 menu bar pulse | ✓ | macOS 26+ deployment target (Package.swift:7) | If deployment target ever lowered, fall back to manual `.opacity` animation timer |
| Existing app entitlements (audio-input, screen-capture, NO sandbox) | Dictation engine audio capture | ✓ | PSTranscribe.entitlements verified [CITED: STACK.md] | — |

**Missing dependencies with no fallback:**
- KeyboardShortcuts SwiftPM resolution. If `swift package resolve` fails (network outage, SwiftPM cache corruption), Phase 18 cannot proceed. Resolution: the package is mature (released 2025-09-18, well within stability window) and hosted on github.com. Real-world risk: low.

**Missing dependencies with fallback:**
- None identified.

## Validation Architecture

> Nyquist validation is enabled (`workflow.nyquist_validation: true` in `.planning/config.json`). This section is REQUIRED.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Swift Testing (built-in to Xcode 16 / Swift 6.2) |
| Config file | `PSTranscribe/Package.swift` (test target at lines 22-26); no separate config |
| Quick run command | `cd PSTranscribe && swift test --filter <SuiteName> -c debug` |
| Full suite command | `cd PSTranscribe && swift test -c debug` |
| Existing tests passing baseline | 57+ tests across 11 suites (per Phase 16 16-03-SUMMARY) — Phase 17 added more, count to be confirmed in Wave 0 |

Inspection confirms:
- `PSTranscribe/Tests/PSTranscribeTests/` exists with 16 test files [VERIFIED: directory listing]
- Existing Phase 16/17 patterns: `@Suite("Name")`, `@Test @MainActor func ...`, `#expect(...)`
- Integration-tag pattern exists: `extension Tag { @Tag static var integration: Self }` at TestTags.swift:8 — used to mark tests requiring real FluidAudio model files

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DICT-01 | Hotkey registration with default Cmd+Shift+D | unit | `swift test --filter GlobalHotkeyServiceTests/defaultShortcutIsCmdShiftD` | ❌ Wave 0 |
| DICT-02 | Toggle vs hold mode behavior in coordinator | unit | `swift test --filter DictationCoordinatorTests/toggleSecondTapStops` and `.../holdReleaseAfterOneSecondCommits` | ❌ Wave 0 |
| DICT-03 | Menu bar reflects `dictationCoordinator.isActive` | manual UAT | (visual check) | manual |
| DICT-04 | HUD partial transcript binds to `dictationStore.volatileYouText` | unit (binding logic, no NSPanel) | `swift test --filter DictationCoordinatorTests/partialTextReflectsTranscriptStore` | ❌ Wave 0 |
| DICT-05 | Clipboard write on stop | unit (assert pasteboard string equals assembled transcript) | `swift test --filter DictationCoordinatorTests/endDictationWritesAssembledTranscriptToClipboard` | ❌ Wave 0 |
| DICT-06 | Previous clipboard restored after delay; skipped if user copied during window | unit | `swift test --filter DictationCoordinatorTests/clipboardRestoresAfterDelay` and `.../clipboardRestoreSkippedWhenChangeCountChanged` | ❌ Wave 0 |
| DICT-07 | Library entry created on stop (mode = .clipboard, .plainFolder, .both) | unit | `swift test --filter DictationCoordinatorTests/libraryEntryCreatedForEachOutputMode` | ❌ Wave 0 |
| DICT-08 | Esc cancels <30s immediately, ≥30s requires confirmation | unit | `swift test --filter DictationCoordinatorTests/escUnder30sCancelsImmediately` and `.../escAtOrOver30sEntersCancellingPending` and `.../secondEscWithinWindowConfirmsCancel` | ❌ Wave 0 |
| DICT-09 | Pasteboard markers TransientType + AutoGeneratedType present after write | unit (read pasteboard data for both types — note: this is OUR pasteboard write, in-test, so it's not the prohibited read-someone-else's-clipboard pattern) | `swift test --filter DictationCoordinatorTests/clipboardWriteIncludesPrivacyMarkers` | ❌ Wave 0 |
| DICT-10 | NSPanel `sharingType == .none` after init | unit | `swift test --filter DictationWindowControllerTests/panelHasNoneSharingType` | ❌ Wave 0 |
| DICT-11 | beginDictation no-ops when SessionCoordinator.anySessionActive == true | unit | `swift test --filter DictationCoordinatorTests/beginNoOpsWhenSessionAlreadyActive` | ❌ Wave 0 |
| FOLDER-01 | Settings folder picker writes to AppSettings.dictationFolderPath | manual UAT (Settings UI is the picker) | (visual + UserDefaults check) | manual |
| FOLDER-02 | Plain-folder file has no YAML frontmatter | already covered by `DictationLoggerTests/noYAMLFrontmatterAfterFullSession` (Phase 16) | `swift test --filter DictationLoggerTests/noYAMLFrontmatterAfterFullSession` | ✅ exists |
| FOLDER-03 | Filename pattern + millisecond suffix collision avoidance | already covered by `DictationLoggerTests/rapidSessionsNoCollision` (Phase 16) | `swift test --filter DictationLoggerTests/rapidSessionsNoCollision` | ✅ exists |
| FOLDER-04 | Output mode branching (clipboard / plainFolder / both) | unit | `swift test --filter DictationCoordinatorTests/clipboardOnlyModeWritesNoFile` and `.../plainFolderOnlyModeWritesNoClipboard` and `.../bothModeWritesFileAndClipboard` | ❌ Wave 0 |
| FOLDER-05 | dictationFolderPath persists across AppSettings re-init | already covered by AppSettingsTests (Phase 16) | `swift test --filter AppSettingsTests` | ✅ exists |

**Additional unit tests (not requirement-specific but architecturally critical):**

| Behavior | Command | Why |
|----------|---------|-----|
| `DictationLogger.discardSession()` deletes the file and is idempotent | `swift test --filter DictationLoggerTests/discardSessionDeletesFile` and `.../discardSessionIdempotent` | D-08 atomic cancel |
| `SessionCoordinator.anySessionActive` reflects `dictation.isActive` | `swift test --filter SessionCoordinatorTests/trueWhenDictationActive` | Wave 5 integration |
| `SessionCoordinator.dictation` is held weakly | `swift test --filter SessionCoordinatorTests/dictationHeldWeakly` | Mirrors existing `modelUpdateHeldWeakly` test |
| Auto-name algorithm (D-10) edge cases: empty, all-punctuation, very long, exactly 50, hyphenated word at 50 | `swift test --filter AutoNameTests` | D-10 correctness — seven edge cases |
| `GlobalHotkeyService.onKeyDown/onKeyUp` callbacks dispatch on MainActor | unit (use `MainActor.assertIsolated()`-style assertion in callback) | Race-condition prevention |

### Sampling Rate

- **Per task commit (within a wave):** `cd PSTranscribe && swift test --filter <ChangedSuite> -c debug` — < 5 seconds for any single suite.
- **Per wave merge:** Full unit suite + the touched integration tag. `cd PSTranscribe && swift test -c debug` — currently <30s for 57+ tests, expected to scale linearly.
- **Phase gate (`/gsd-verify-work`):** Full suite green AND manual UAT items checked off in `18-VERIFICATION.md`. Build also runs `swift build -c release` to catch any release-only compilation issues.

### Wave 0 Gaps

The following test infrastructure must land BEFORE Wave 1 implementation tasks (or in parallel, RED-then-GREEN per existing project pattern visible in 16-03-SUMMARY commit ordering: `de26a6c` test RED, `ce9a682` feat GREEN):

- [ ] `PSTranscribe/Tests/PSTranscribeTests/GlobalHotkeyServiceTests.swift` — covers DICT-01 default shortcut, callback wiring, MainActor dispatch.
- [ ] `PSTranscribe/Tests/PSTranscribeTests/DictationCoordinatorTests.swift` — covers DICT-02, DICT-04, DICT-05, DICT-06, DICT-07, DICT-08, DICT-09, DICT-11, FOLDER-04. ~15-20 test cases. Will need `MockClipboard` (or wrap NSPasteboard.general behind a small protocol so tests don't pollute the test runner's actual clipboard) — or accept that tests touch `NSPasteboard.general` and use `defer { NSPasteboard.general.clearContents() }`.
- [ ] `PSTranscribe/Tests/PSTranscribeTests/DictationWindowControllerTests.swift` — covers DICT-10 (NSPanel sharingType), bottom-center positioning math.
- [ ] `PSTranscribe/Tests/PSTranscribeTests/AutoNameTests.swift` — covers D-10 edge cases.
- [ ] Extend `PSTranscribe/Tests/PSTranscribeTests/DictationLoggerTests.swift` with `discardSession` cases.
- [ ] Extend `PSTranscribe/Tests/PSTranscribeTests/SessionCoordinatorTests.swift` with the 2 new dictation cases (mirror lines 65-99 modelUpdate pattern).
- [ ] Extend `PSTranscribe/Tests/PSTranscribeTests/LibraryEntryTests.swift` (or create) with `filePathOptionalRoundTrip` if Open Question §1 resolves to "Optional refactor."
- [ ] No framework install needed — Swift Testing is bundled.

**Manual UAT items (unavoidable, per ROADMAP success criteria):**

1. **Hotkey from arbitrary app smoke test (SC-1).** Open TextEdit, press Cmd+Shift+D, verify HUD appears within 200ms (visual judgment + screen recording with timestamp overlay), pulsing menu bar mic indicator visible. Speak a phrase. Stop via second hotkey tap. Cmd+V into TextEdit — verify pasted text matches dictation.
2. **Clipboard history exclusion (SC-2 / DICT-09).** Install at least one of Alfred, Maccy, or Pasta. Run a dictation. Open the clipboard manager UI — verify the dictation transcript does NOT appear. (If none of these can be installed in the test environment, mark this as documented in 18-VERIFICATION.md and require user attestation.)
3. **HUD visual style (D-03).** Visual confirmation that HUD uses the native macOS HUD vibrancy material, not the Chronicle paper aesthetic. Take a screenshot for the verification record.
4. **Plain-folder write 10-rapid-session test (SC-3).** Trigger 10 dictation sessions in <30s total. Verify exactly 10 distinct files in the configured folder. Verify each has `# Dictation -- ` header and no `---` YAML.
5. **Cancel via Esc, ≥30s confirmation (SC-4).** Start a dictation, speak for ~35s, press Esc once → HUD shows "Press Esc again to cancel". Wait 4s → HUD reverts to listening. Speak again, press Esc twice rapidly within 3s → HUD dismisses, no clipboard write, no file appears, no library entry.
6. **Press-and-hold short-tap silent cancel (D-07).** Switch to hold mode in Settings. Hold the hotkey for ~500ms then release → no HUD persists, no clipboard write, no library entry. Hold for >1s → commits as normal.
7. **Mutual exclusion with active meeting recording (SC-5 / DICT-11).** Start a meeting recording. Press dictation hotkey. Verify HUD shows "Recording in progress — dictation unavailable" and auto-dismisses in ~1.5s. Verify no dictation engine started (no audio interference with the meeting).
8. **Privacy mode HUD verification (DICT-10).** Enable "Hide from screen sharing." Use legacy `screencapture` CLI or QuickTime Player screen recording to capture the screen during a dictation. Verify the HUD is NOT in the legacy screencapture output. **Documented limitation:** ScreenCaptureKit-based capture (Zoom, Teams, OBS) WILL show the HUD — this is the unfixable macOS limitation per Pitfall #17. Document, don't fix.
9. **Eager pre-warm timing (D-13 / SC-1 200ms).** Cold-start the app. Wait 5 seconds (allow pre-warm to complete). Press hotkey. Stopwatch the time-to-HUD-visible. Should be ≤ 200ms.

## Security Domain

> Required: `security_enforcement` is not explicitly disabled in config.json (defaults to enabled).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No user accounts; on-device only |
| V3 Session Management | no | No web/network sessions |
| V4 Access Control | yes | mutual-exclusion via `SessionCoordinator.anySessionActive` (DICT-11); plain-folder path validation in DictationLogger (already shipped, rejects traversal/null bytes) |
| V5 Input Validation | yes | KeyboardShortcuts library validates the hotkey input internally; `chooseFolder` returns user-confirmed path only; `DictationLogger.validatedFolderPath` rejects `..` and null-bytes (already shipped) |
| V6 Cryptography | no | No cryptographic operations introduced; existing 0o600 perms on output files (already shipped) |
| V8 Data Protection | yes | Dictation transcript may contain sensitive content (medical/legal). Pasteboard markers exclude from history (DICT-09); 0o600 perms on plain-folder files (already shipped); on-device only (no telemetry, no cloud) |
| V12 File Handling | yes | Plain-folder file write — path validation, traversal rejection, atomic close (already shipped Phase 16); cancel-deletes-file is the new V12 surface (D-08) |
| V14 Logging | yes | os_log used for D-15 plain-folder failure; no transcript content logged (sensitive content protection); no PII in logs |

### Known Threat Patterns for Swift/macOS Audio + Clipboard Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Clipboard pollution leaks dictation to history apps | Information Disclosure | `org.nspasteboard.TransientType` + `AutoGeneratedType` markers (DICT-09 / Pitfall #5) |
| Plain-folder path traversal (user types `../../etc`) | Tampering | `DictationLogger.validatedFolderPath` rejects `..` and null-bytes BEFORE URL construction (already shipped Phase 16) |
| File permission leak (other users on shared Mac read transcripts) | Information Disclosure | 0o600 file perms set immediately after createFile (already shipped Phase 16) |
| HUD content captured by screen recording during sensitive dictation | Information Disclosure | `sharingType = .none` + AppDelegate observer (Pitfall #17). Documented unfixable for ScreenCaptureKit. |
| Pasteboard write race overwrites user's intentional copy | Tampering | changeCount guard before restore (Pitfall #6, Code Examples §5) |
| Two recording sessions race (audio-engine crash) | Denial of Service | `SessionCoordinator.anySessionActive` mutual-exclusion gate at begin (DICT-11) |
| Dictation cancellation leaves orphaned plain-folder file | Information Disclosure (residual sensitive content on disk) | `DictationLogger.discardSession()` deletes the file atomically (D-08, Wave 2) |
| Hotkey accidentally fires during password entry, exposing typed password to ASR | Information Disclosure | Press-and-hold mode + clear menu-bar indicator (DICT-03) — user must visually confirm the recording state. Toggle mode users are at higher risk; FEATURES.md notes this. Mitigation: default to a 3-modifier shortcut OR require user confirmation. We default to 2-modifier `Cmd+Shift+D` per CONTEXT D-01 — accept the risk; user can change to 3-modifier in Settings. |
| Sensitive content in os_log (D-15 plain-folder failure log) | Information Disclosure | Log path + error code only, NEVER transcript content. Use `privacy: .public` only on metadata; never log the assembled string. |

### Phase 18-Specific Threat Model Items

| Threat | Mitigation | Verified by |
|--------|------------|-------------|
| T-18-01 (HUD visible during screen sharing of sensitive content) | sharingType = .none on creation; AppDelegate observer fallback | Manual UAT #8 |
| T-18-02 (Cancelled dictation file persists on disk) | discardSession() unlinks file atomically | DictationLoggerTests/discardSessionDeletesFile |
| T-18-03 (Pasteboard write without privacy markers leaks to clipboard managers) | TransientType + AutoGeneratedType set on every write | DictationCoordinatorTests/clipboardWriteIncludesPrivacyMarkers + Manual UAT #2 |
| T-18-04 (Race-condition double-recording crashes AVAudioEngine) | SessionCoordinator.anySessionActive guard before begin | DictationCoordinatorTests/beginNoOpsWhenSessionAlreadyActive + Manual UAT #7 |
| T-18-05 (Restore overwrites user's intentional clipboard copy) | changeCount guard | DictationCoordinatorTests/clipboardRestoreSkippedWhenChangeCountChanged |
| T-18-06 (Plain-folder path with traversal pattern accepted) | validatedFolderPath rejects `..` (already shipped Phase 16) | DictationLoggerTests/rejectsTraversal + rejectsNullByte |
| T-18-07 (Transcript content in os_log) | Log only metadata; planner verifies grep for `transcript`, `assembled` in log strings returns 0 | Code review at Wave 5 |

## Sources

### Primary (HIGH confidence)
- Direct source inspection of `PSTranscribe/Sources/PSTranscribe/` — verified PSTranscribeApp.swift, SessionCoordinator.swift, DictationLogger.swift, AppSettings.swift, ModelUpdateService.swift, Models.swift (LibraryEntry shape), LibraryStore.swift, LibraryEntryRow.swift, SettingsView.swift, TranscriptionEngine.swift, AppUpdaterController.swift, Package.swift, TranscriptStore.swift on 2026-04-27.
- Direct source inspection of `PSTranscribe/Tests/PSTranscribeTests/` — verified 16 test files, Swift Testing patterns, integration tag.
- `.planning/phases/16-foundation/16-03-SUMMARY.md` — DictationLogger implementation details.
- `.planning/phases/16-foundation/16-04-SUMMARY.md` — SessionCoordinator wiring.
- `.planning/phases/17-model-auto-update/17-CONTEXT.md` — Settings section ordering, ModelUpdateService pattern.
- `.planning/research/ARCHITECTURE.md` §"Feature 1: Keyboard-Triggered Clipboard Dictation" + §"Feature 2: Plain-Folder Dictation Output".
- `.planning/research/PITFALLS.md` — pitfalls #5, #6, #7, #16, #17, #18 specifically.
- `.planning/research/STACK.md` — KeyboardShortcuts version + entitlement analysis.
- `.planning/research/FEATURES.md` — HUD position, toggle vs hold defaults, 30s threshold, filename convention.
- WebFetch on https://github.com/sindresorhus/KeyboardShortcuts on 2026-04-27 — confirmed v2.4.0 latest, API shape, Recorder semantics.

### Secondary (MEDIUM confidence)
- nspasteboard.org specification (referenced via STACK.md, PITFALLS.md #5).
- Apple Developer Forums thread 792152 (NSWindowSharingType limitations with ScreenCaptureKit) — referenced via PITFALLS.md #17.
- Apple SF Symbols documentation for `.symbolEffect(.pulse, isActive:)` — verified availability on macOS 14+.

### Tertiary (LOW confidence)
- KeyboardShortcuts.Recorder Delete-key clearing behavior (Assumption A1) — README does not explicitly state, but consistent with macOS hotkey-recorder UX conventions.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — KeyboardShortcuts version verified live; all other deps already in project.
- Architecture: HIGH — Phase 16 foundation verified by inspection; CONTEXT.md decisions are authoritative; ARCHITECTURE.md sections cited.
- API shapes (DictationCoordinator, GlobalHotkeyService, NSPanel recipe): HIGH — patterns match existing services (ModelUpdateService) and Apple AppKit/SwiftUI conventions.
- Pitfalls: HIGH — direct citations to PITFALLS.md research, verified via source inspection (e.g., `LibraryEntry.filePath: String` non-optional confirmed at Models.swift:85).
- Test architecture: HIGH — pattern verified against existing 16/17 test files; framework is built-in.

**Research date:** 2026-04-27
**Valid until:** 2026-05-27 (30 days; KeyboardShortcuts v2.4.0 is stable; no scheduled macOS API changes that would invalidate within this window).

---

## RESEARCH COMPLETE
