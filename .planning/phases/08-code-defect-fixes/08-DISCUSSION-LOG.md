# Phase 8: Code Defect Fixes - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-04-06
**Phase:** 08-code-defect-fixes
**Areas discussed:** Speaker data model, Crash recovery flow, LibraryEntryRow caching

---

## Speaker data model

| Option | Description | Selected |
|--------|-------------|----------|
| Add .named(String) case | Flexible, handles any label. Parser stores original string, UI displays directly. | ✓ |
| Add .speaker(Int) case | Typed, prevents invalid labels. Slightly stricter but less flexible. | |
| Keep enum, add displayLabel | Avoids enum change but splits identity from display. | |

**User's choice:** Add .named(String) case
**Notes:** Recommended option -- simple and future-proof.

| Option | Description | Selected |
|--------|-------------|----------|
| Raw label as-is | "Speaker 2", "Speaker 3" -- matches disk. No transformation. | |
| Colored badges per speaker | Each speaker gets a distinct color for visual differentiation. | ✓ |
| You decide | Claude picks simplest approach. | |

**User's choice:** Colored badges per speaker
**Notes:** Helps distinguish speakers in long transcripts.

---

## Crash recovery flow

| Option | Description | Selected |
|--------|-------------|----------|
| Yellow 'Incomplete' badge | Distinct badge, tapping loads content. Simple visual distinction. | ✓ |
| Separate 'Recovered' section | Prominent section above normal entries. More visible but new layout concept. | |
| Inline with subtle indicator | Small icon/text note. Least disruptive but easy to miss. | |

**User's choice:** Yellow 'Incomplete' badge
**Notes:** Consistent with existing badge pattern.

| Option | Description | Selected |
|--------|-------------|----------|
| Fully functional | All actions work. Badge is informational only. Simplest implementation. | ✓ |
| Read-only with 'Finalize' action | View-only until manually finalized. Safer but adds new action. | |

**User's choice:** Fully functional
**Notes:** No capability gate on recovered entries.

---

## LibraryEntryRow caching

| Option | Description | Selected |
|--------|-------------|----------|
| Compute on .onAppear, store in @State | Check once on appear. Stale until re-appear. Simplest. | ✓ |
| Add fileExists to LibraryEntry model | Centralized check on model. Adds stored property to Codable model. | |
| You decide | Claude picks simplest approach. | |

**User's choice:** @State on .onAppear
**Notes:** Stops per-render filesystem I/O.

---

## Claude's Discretion

- Exact color palette for speaker badges
- Codable/Sendable conformance for .named case
- Fix ordering within plans
- source/tome -> source/pstranscribe (mechanical)
- print() -> os.Logger (mechanical, 3 sites)
- transcriptStore.clear() wiring verification (mechanical)

## Deferred Ideas

None -- discussion stayed within phase scope.
