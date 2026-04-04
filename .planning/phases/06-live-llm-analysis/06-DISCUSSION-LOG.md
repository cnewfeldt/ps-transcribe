# Phase 6: Live LLM Analysis - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-04-04
**Phase:** 06-live-llm-analysis
**Areas discussed:** Panel layout, Update strategy, Prompt design, Persistence format

---

## Panel Layout

### Where should the analysis panel appear?

| Option | Description | Selected |
|--------|-------------|----------|
| Right side panel | Three-column: Library Sidebar, Transcript, Analysis. Natural reading flow | ✓ |
| Below transcript | Bottom section under transcript. Full width but reduces vertical space | |
| Toggleable drawer | Hidden by default with button to slide in from right | |

**User's choice:** Right side panel
**Notes:** None

### Auto-show vs manual toggle?

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-show if Ollama connected | Panel appears automatically when recording starts and Ollama available | |
| Always manual toggle | User clicks button to show/hide. Full control | ✓ |
| Auto-show with dismiss | Auto-appears but user can close. Remembers preference | |

**User's choice:** Always manual toggle
**Notes:** None

### Toggle button location?

| Option | Description | Selected |
|--------|-------------|----------|
| Control bar | In ControlBar near recording controls. Visible during recording | ✓ |
| Recording name bar | In RecordingNameField top bar alongside sidebar/settings buttons | |
| You decide | Claude picks based on existing layout | |

**User's choice:** Control bar
**Notes:** None

### Recording-only or recording + review?

| Option | Description | Selected |
|--------|-------------|----------|
| Recording + review | Shows live during recording AND saved analysis when reviewing past sessions | ✓ |
| Recording only | Only during active recording. Past sessions don't show panel | |

**User's choice:** Recording + review
**Notes:** None

---

## Update Strategy

### How should analysis updates be triggered?

| Option | Description | Selected |
|--------|-------------|----------|
| Utterance count threshold | Update after every N new utterances. Scales with conversation pace | ✓ |
| Fixed timer interval | Update every N seconds regardless of content | |
| You decide | Claude picks based on TranscriptStore and Ollama behavior | |

**User's choice:** Utterance count threshold
**Notes:** None

### Minimum cooldown between updates?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, 30s minimum cooldown | Don't send new request until 30s after last one started | ✓ |
| No cooldown | Fire whenever utterance threshold hit | |
| You decide | Claude picks the right balance | |

**User's choice:** Yes, 30s minimum cooldown
**Notes:** None

---

## Prompt Design

### Single call or separate calls per section?

| Option | Description | Selected |
|--------|-------------|----------|
| Single call | One prompt for all three sections. Faster, cheaper, full context | ✓ |
| Separate calls per section | Three generate() calls. Independent updates but 3x load | |

**User's choice:** Single call
**Notes:** None

### How much transcript context per update?

| Option | Description | Selected |
|--------|-------------|----------|
| Full transcript so far | Entire transcript accumulated. 16K context handles most meetings | ✓ |
| Rolling window | Last N minutes or utterances. Bounded but risks missing early context | |
| Full + previous analysis | Full transcript plus previous output for continuity | |

**User's choice:** Full transcript so far
**Notes:** None

---

## Persistence Format

### How should analysis be saved at session end?

| Option | Description | Selected |
|--------|-------------|----------|
| Appended to transcript markdown | `## Analysis` section at end of .md file. Single file, Obsidian-visible | ✓ |
| Separate companion file | .analysis.md file next to transcript. Clean but two files | |
| YAML frontmatter | Embedded in frontmatter block. Machine-readable but less human-friendly | |

**User's choice:** Appended to transcript markdown
**Notes:** User confirmed checkbox format (`- [ ]`) for action items

---

## Claude's Discretion

- Exact utterance count threshold
- Prompt wording and structure
- Response parsing strategy
- Panel width and internal styling
- Analysis state management architecture
- OllamaService timeout for generate() calls
- Past-session analysis loading approach

## Deferred Ideas

None -- discussion stayed within phase scope
