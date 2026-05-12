# Phase 26: QA Sweep + Visual UAT - Pattern Map

**Mapped:** 2026-05-08
**Files analyzed:** 1 UAT artifact (new) + 1 execution plan (new) + 0..N conditional fix plans + 0..N conditional deferred todos = 2 mandatory + N conditional file-level decisions
**Analogs found:** 4 / 4 mandatory file types (UAT artifact, execution plan, fix plan, deferred todo) — all in-house

This phase ships **Markdown only**. No Swift source code is modified. Every artifact pattern below is for YAML frontmatter, heading hierarchy, and per-row schema. The phase inherits the manual-UAT playbook locked by Phases 17 / 18.1 / 21 / 24 and uses Phase 25's `25-01-PLAN.md` as the canonical execution-plan shape (since `25-01-PLAN.md` is the most recent, executes `gsd-execute-phase`-driven, and was the input gsd-pattern-mapper used during the phase 25 sweep).

The only **load-bearing decision** for the planner: 26-UAT.md is **named after `18.1-UAT.md`** (per ROADMAP success criterion 1 + D-04), but it **structurally absorbs** patterns from three precedents:
1. `18.1-UAT.md` — frontmatter shape (`status` / `phase` / `source` / `started` / `updated` / `resolved` / `resolved_by`), per-scenario heading + `expected:` / `result:` rows, `## Summary` count block, `## Gaps` block.
2. `21-HUMAN-UAT.md` — citation-row format ("passed YYYY-MM-DD, user attestation") for QA-06..QA-09.
3. `24-HUMAN-UAT.md` — `approved-with-debt` terminal-state and the `approved-with-debt: N` line in `## Summary` (Phase 26 will likely land here due to QA-03 multi-monitor UNTESTABLE-this-cycle per D-01).

---

## File Classification

### Mandatory Files (Markdown artifacts)

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `.planning/phases/26-qa-sweep-visual-uat/26-UAT.md` | doc (UAT artifact) | manual-attestation (human reads scenarios, runs build, writes `result:` lines) | `18.1-UAT.md` (multi-scenario, frontmatter shape, per-row `expected:` / `result:`, `## Summary`, `## Gaps`) + `24-HUMAN-UAT.md` (`approved-with-debt` terminal state) + `21-HUMAN-UAT.md` (citation-row format for QA-06..09) | exact (composite of 3 in-house precedents) |
| `.planning/phases/26-qa-sweep-visual-uat/26-01-PLAN.md` | doc (execution plan) | task-driven (gsd-execute-phase reads frontmatter `must_haves` / `tasks` blocks; agent runs the sweep) | `25-01-PLAN.md` (most-recent execution plan in this project; carries the canonical `must_haves` / `tasks` / `verify` / `acceptance_criteria` / `success_criteria` shape expected by gsd-execute-phase) | exact |

### Conditional Files (only if D-02 batch-triage routes FAILs)

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `.planning/phases/26-qa-sweep-visual-uat/26-NN-PLAN.md` (e.g. `26-02-PLAN.md`) | doc (fix plan) | task-driven | `25-01-PLAN.md` (same shape as 26-01-PLAN.md but smaller scope — single-scenario fix) | exact |
| `.planning/todos/pending/qa-NN-<short>.md` | doc (deferred todo) | manual-tracker | `.planning/todos/pending/ci-build-check-failing-on-main.md` (only existing pending todo; canonical frontmatter + body shape) | exact |

---

## Pattern Assignments

### `26-UAT.md` — multi-scenario manual UAT artifact

**Reqs covered:** QA-01..QA-09 (all 9 scenarios; QA-04 WITHDRAWN, QA-03 split into 03a PASS-able / 03b UNTESTABLE-this-cycle, QA-06..09 citation rows pointing at `21-HUMAN-UAT.md`).
**Analogs:** Composite — `18.1-UAT.md` (primary structural template) + `24-HUMAN-UAT.md` (`approved-with-debt` terminal state) + `21-HUMAN-UAT.md` (citation rows for QA-06..09).

#### Frontmatter pattern (lifted from `18.1-UAT.md:1-20`, simplified per Phase 24/25 shape)

`18.1-UAT.md` lines 1-20 — full multi-scenario frontmatter with `resolved_by:` block:

```yaml
---
status: resolved
phase: 18.1-shared-save-destinations-local-file
source:
  - 18.1-01-SUMMARY.md
  - 18.1-02-SUMMARY.md
  - ... (one per execution-plan SUMMARY)
started: 2026-04-29T23:45:00Z
updated: 2026-04-30T17:55:00Z
resolved_by:
  - 18.1-07 (UAT issue #1: NSOpenPanel title)
  - 18.1-08 (UAT issue #2: DictationHUD live binding)
  - 18.1-09 (UAT issue #3: D-20 error auto-clear)
---
```

Phase 26 starts at `status: in-progress`. Possible terminal states:
- `resolved` — every scenario PASS / WITHDRAWN, no UNTESTABLE-this-cycle gaps (unlikely per D-01 QA-03b).
- `approved-with-debt` — at least one UNTESTABLE-this-cycle row (likely terminal state per D-01 + Specifics §"Phase 26 status terminal state").

`24-HUMAN-UAT.md:1-7` — minimal `approved-with-debt` frontmatter (no `resolved_by:` because no plans landed to resolve issues):

```yaml
---
status: approved-with-debt
phase: 24-nyquist-sweep-v1-0
source: [24-VERIFICATION.md]
started: 2026-05-05T20:30:00Z
updated: 2026-05-05T20:55:00Z
---
```

**Phase 26 frontmatter (planner picks ISO timestamps, fills `source:` per D-04 + CONTEXT.md canonical_refs):**

```yaml
---
status: in-progress
phase: 26-qa-sweep-visual-uat
source:
  - .planning/REQUIREMENTS.md  # QA-01..QA-09 IDs
  - .planning/ROADMAP.md  # Phase 26 success criteria
  - .planning/research/PITFALLS.md  # QA-01..05 origin (Looks Done But Isn't)
  - .planning/milestones/v1.2-phases/21-appearance-override/21-HUMAN-UAT.md  # QA-06..09 citation source
  - .planning/phases/25-nyquist-sweep-v1-2/25-CONTEXT.md  # D-03 cross-ref contract
started: <ISO timestamp at sweep start>
updated: <ISO timestamp on close>
# At close, transition status to "resolved" or "approved-with-debt" and add:
# resolved: <ISO timestamp>  (only on "resolved")
# resolved_by:
#   - 26-NN (description of fix routed in-phase)  (only if D-02 in-phase plans landed)
---
```

#### `## Current Test` block (lifted from `18.1-UAT.md:22-24`)

```markdown
## Current Test

[testing paused — N items outstanding]
```

Or (close state):

```markdown
## Current Test

[complete]
```

`24-HUMAN-UAT.md:9-11` uses `[complete]` at close. Phase 26 follows.

#### Per-scenario row patterns

**PASS row** (lifted from `18.1-UAT.md:34-36`, three lines: heading + `expected:` + `result:`):

```markdown
### 2. Settings — Three Top-Level Destination Sections Present
expected: Settings window shows, in order: Audio Input, Local File, ...
result: pass
```

**Pass-with-note row** (lifted from `18.1-UAT.md:73-75`):

```markdown
### 10. Obsidian Destination — Single Folder With Session-Type Frontmatter
expected: Enable only Obsidian (Local File and Notion off). ...
result: pass
note: "User confirmed test passes after restarting app to clear the test 9 lingering-error state."
```

**FAIL / issue row with severity** (lifted from `18.1-UAT.md:28-33`):

```markdown
### 1. Cold Launch and Settings Open
expected: App launches clean from quit state. Settings window opens and renders without missing controls.
result: issue
reported: "(a) Choose-Folder button icon is not rendering correctly in the Obsidian section. ..."
severity: major
```

**Phase 26 FAIL row addition (per CONTEXT.md Claude's Discretion §routing):** add a `routing:` field. Schema choice (planner picks, but bias is below):

```markdown
### N. QA-NN — <short scenario description>
expected: <one-line scenario expectation>
result: fail
reported: "<concrete observation, logs, console excerpt>"
severity: major | minor
routing: in-phase: 26-02-PLAN.md  # OR: todo: qa-NN-<short>.md
```

**WITHDRAWN row** (no precise prior-art; closest is the WITHDRAWN row pattern from Phase 24/25 VALIDATION.md tables — but those are table cells. For UAT-row WITHDRAWN, follow the Phase 18.1 free-form row shape):

```markdown
### 4. QA-04 — Security-scoped bookmark survival across relaunch + reboot
expected: <original PITFALLS.md framing — folder URLs persist via bookmarkData(options: .withSecurityScope) and survive both relaunch and reboot>
result: WITHDRAWN
reason: "PS Transcribe is non-sandboxed (PSTranscribe.entitlements has audio-input + screen-capture only; no com.apple.security.app-sandbox key). localFileRoot and obsidianFolderPath persist as raw String paths in UserDefaults (AppSettings.swift:82,97), not as security-scoped bookmark data. There is no startAccessing / stopAccessing call in PSTranscribe/Sources (verified via grep, zero hits). The QA-04 premise from PITFALLS.md line 519 was speculative about a sandboxed scenario that did not materialize; UserDefaults string-path persistence is guaranteed by Apple's UserDefaults contract and survives both relaunch and reboot trivially."
```

**UNTESTABLE-this-cycle row** (no exact in-house precedent; combines Phase 24's `approved-with-debt` terminal-state philosophy with the WITHDRAWN row body shape):

```markdown
### 3b. QA-03b — Multi-monitor HUD positioning sub-scenarios
expected: HUD renders at the correct position across the 4-config matrix (primary / secondary-left / secondary-right / vertical) plus mid-recording disconnect, using NSScreen.screens positioning math at DictationWindowController.swift.
result: untestable-this-cycle
reason: "User does not have a multi-monitor rig available for this cycle. Synthesized NSScreen mock test rejected (D-01) — turns QA-03 into a code phase, conflicts with the manual-sweep boundary of this phase. Sidecar / iPad as second display rejected — adds latency and a confounding factor."
gap: "Capture this case in a future opportunistic phase or one-off when an external display is on hand. Not promoted to a todo to avoid creating debt for a hardware-availability question that resolves naturally on the next cycle."
code_ref: "PSTranscribe/Sources/PSTranscribe/App/DictationWindowController.swift (NSScreen.screens positioning math)"
```

**Citation row** (lifted from `21-HUMAN-UAT.md:16-19` — passed user attestation; combine with 18.1 row shape):

```markdown
### 6. QA-06 — Titlebar Scenario A revisited (picker = Dark, macOS = Light)
expected: Main window titlebar strip flips dark (no cream paper background, dynamic system label color on toolbar title), and re-flips to cream when picker is set back to Light or System (with macOS in Light). The cream Chronicle paper background must NOT persist over a dark-rendered SwiftUI content area.
result: pass (citation)
source: .planning/milestones/v1.2-phases/21-appearance-override/21-HUMAN-UAT.md (Test 1, passed 2026-05-01, user attestation)
```

Phase 26 emits one such row per QA-06 / QA-07 / QA-08 / QA-09 — mapping to `21-HUMAN-UAT.md` Tests 1-4 respectively (per CONTEXT.md Specifics §"QA-06..QA-09 citation row format").

#### `## Summary` block (lifted from `18.1-UAT.md:86-93` + `24-HUMAN-UAT.md:19-27`)

`18.1-UAT.md` shape:

```markdown
## Summary

total: 12
passed: 8
issues: 3
pending: 0
skipped: 0
blocked: 1
```

`24-HUMAN-UAT.md` adds `approved-with-debt`:

```markdown
## Summary

total: 1
passed: 0
issues: 0
pending: 0
skipped: 0
blocked: 0
approved-with-debt: 1
```

**Phase 26 Summary** (planner builds from sweep results — counts must equal `total`):

```markdown
## Summary

total: 9
passed: <count>
issues: <count>  # FAIL rows
withdrawn: <count>  # QA-04 = 1 minimum
untestable-this-cycle: <count>  # QA-03b = 1 minimum
citations: <count>  # QA-06..09 = 4 minimum
pending: 0
skipped: 0
blocked: 0
# Add this line ONLY if final status is approved-with-debt:
approved-with-debt: <count>
```

Note: row counts may exceed `total: 9` if QA-03 splits into 03a + 03b; planner picks whether `total` counts split rows separately or as one. **Bias: split rows count separately (matches Phase 24/25 D-04 PARTIAL a/b convention used in VALIDATION.md), so `total` may be 10 or 11 depending on splits.**

#### `## Gaps` block (lifted from `18.1-UAT.md:96-147` + `24-HUMAN-UAT.md:29-31`)

`24-HUMAN-UAT.md` form (no gaps inside scope, debt cross-referenced):

```markdown
## Gaps

None for Phase 24's scope. CI infrastructure debt deferred to a follow-up phase (see `.planning/todos/pending/ci-build-check-failing-on-main.md`).
```

`18.1-UAT.md` form (per-issue structured block; planner uses this shape only if FAILs are routed in-phase per D-02):

```markdown
## Gaps

- truth: "<observable behavior the test asserts>"
  status: resolved
  resolved_by: 26-NN
  reason: "<concrete observation>"
  severity: major | minor
  test: <scenario number>
  root_cause: "<analysis>"
  artifacts:
    - path: "<source file path>"
      issue: "<line refs + diagnosis>"
  missing:
    - "<concrete fix item 1>"
    - "<concrete fix item 2>"
  debug_session: ".planning/debug/26-uat-issue-N-<slug>.md"  # if a debug session was opened
```

**Bias for Phase 26:** if FAILs route to in-phase plan, the FAILs need a `## Gaps` entry mirroring the 18.1 shape. If FAILs route to a deferred todo, the row's `routing: todo: qa-NN-<short>.md` is sufficient — no `## Gaps` entry needed (the todo file is the canonical tracker).

#### Trailing `## Cross-References` block (CONTEXT.md Claude's Discretion §"trailing summary footer")

No exact precedent. Closest analog is the `source:` frontmatter list. Planner adds a Markdown-body equivalent:

```markdown
## Cross-References

- **REQUIREMENTS.md** lines 15-23 — QA-01..QA-09 requirement IDs
- **ROADMAP.md** §"Phase 26: QA Sweep + Visual UAT" — phase goal + 6 success criteria
- **research/PITFALLS.md** lines 513-528 — "Looks Done But Isn't" Checklist (origin of QA-01..05)
- **milestones/v1.2-phases/21-appearance-override/21-HUMAN-UAT.md** — citation source for QA-06..09 (passed 2026-05-01)
- **phases/25-nyquist-sweep-v1-2/25-CONTEXT.md** D-03 — Phase 25's cross-reference contract that QA-06..09 lives in 26-UAT.md
- **todos/pending/ci-build-check-failing-on-main.md** — CI infrastructure debt; reviewed at score 0.6 by gsd-sdk query todo.match-phase 26, NOT folded into Phase 26 (D-04, surface mismatch)
```

---

### `26-01-PLAN.md` — single execution plan covering full sweep + 26-UAT.md authoring

**Analog:** `.planning/phases/25-nyquist-sweep-v1-2/25-01-PLAN.md` (most recent execution plan; canonical `gsd-execute-phase` shape).

**Match quality caveat:** `25-01-PLAN.md` is a code-and-doc plan (Swift Testing files + VALIDATION.md). Phase 26's `26-01-PLAN.md` is a **doc-and-manual-driver plan** — the agent's `<action>` blocks instruct a human (the user) to run scenarios in a live build, not write code. The frontmatter and skeleton transfer directly; the `<task>` shapes shift from `tdd="true"` Swift edits to `tdd="false"` manual-driver checklists.

#### Frontmatter pattern (lifted from `25-01-PLAN.md:1-62`)

```yaml
---
phase: 26-qa-sweep-visual-uat
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/phases/26-qa-sweep-visual-uat/26-UAT.md
autonomous: false  # human-in-the-loop sweep; DIFFERS from 25-01 which was autonomous: true
requirements: [QA-FUT-01]  # PROJECT.md line 61 — QA-FUT-01 is the umbrella; QA-01..QA-09 are sub-IDs
tags: [qa, visual-uat, manual-attestation, phase-21-bridge, phase-19-backlog, v1.3]

must_haves:
  truths:
    - "Honors D-01 (hybrid environment): QA-01 / QA-02 ran live with both Maccy and Alfred installed; QA-03 split into 03a (single-display PASS) and 03b (multi-monitor UNTESTABLE-this-cycle); QA-04 WITHDRAWN with codebase-verified non-sandboxed reasoning"
    - "Honors D-02 (batch-triage size-based routing): all 9 scenarios run before any fix decision; FAILs <1hr AND ≤2 files route to 26-NN-PLAN.md, larger route to .planning/todos/pending/qa-NN-<short>.md"
    - "Honors D-03 (text attestation, citation rows): no screenshots / recordings; QA-06..QA-09 cite 21-HUMAN-UAT.md (Tests 1-4, passed 2026-05-01) rather than re-execute"
    - "Honors D-04 (single execution plan + 26-UAT.md filename): one 26-01-PLAN.md covers full sweep; artifact filename is 26-UAT.md (not 26-HUMAN-UAT.md)"
    - "Build provenance: local debug build from main HEAD via `swift build -c debug` (or Xcode Run); not v2.2.0 release notarized binary"
    - "26-UAT.md created at .planning/phases/26-qa-sweep-visual-uat/26-UAT.md with frontmatter status starting as in-progress, transitioning to resolved or approved-with-debt at close"
    - "26-UAT.md contains rows for QA-01, QA-02, QA-03a, QA-03b, QA-04, QA-05, QA-06, QA-07, QA-08, QA-09 (10 row IDs across 9 scenarios)"
    - "26-UAT.md QA-06..09 citation rows literally contain `Source: .planning/milestones/v1.2-phases/21-appearance-override/21-HUMAN-UAT.md (Test N, passed 2026-05-01, user attestation)`"
    - "QA-04 row reasoning explicitly cites entitlements file path AND AppSettings.swift:82,97 — not the speculative bookmark framing from PITFALLS.md line 519"
    - "Each FAIL row has a routing: line valued either `in-phase: 26-NN-PLAN.md` or `todo: qa-NN-<short>.md`"
    - "## Summary block totals match row count (split rows count separately per Phase 24/25 PARTIAL convention)"
    - "## Cross-References footer cites REQUIREMENTS.md / ROADMAP.md / PITFALLS.md / 21-HUMAN-UAT.md / 25-CONTEXT.md D-03 / ci-build-check-failing-on-main.md (deferred)"
  artifacts:
    - path: ".planning/phases/26-qa-sweep-visual-uat/26-UAT.md"
      provides: "Manual UAT attestation for QA-01..QA-09 (10 rows across 9 scenarios)"
      contains: "status: in-progress (start) / resolved | approved-with-debt (close)"
      min_lines: 120
  key_links:
    - from: ".planning/phases/26-qa-sweep-visual-uat/26-UAT.md"
      to: ".planning/milestones/v1.2-phases/21-appearance-override/21-HUMAN-UAT.md"
      via: "QA-06..09 citation rows literally cite 21-HUMAN-UAT.md (Tests 1-4)"
      pattern: "21-HUMAN-UAT\\.md.*passed 2026-05-01"
    - from: ".planning/phases/26-qa-sweep-visual-uat/26-UAT.md"
      to: ".planning/REQUIREMENTS.md"
      via: "QA-NN row IDs match REQUIREMENTS.md QA-01..QA-09 definitions"
      pattern: "QA-0[1-9]"
    - from: ".planning/phases/26-qa-sweep-visual-uat/26-UAT.md"
      to: "PSTranscribe/Sources/PSTranscribe/PSTranscribe.entitlements"
      via: "QA-04 WITHDRAWN reasoning explicitly cites the entitlements file (no com.apple.security.app-sandbox key)"
      pattern: "PSTranscribe\\.entitlements|com\\.apple\\.security\\.app-sandbox"
---
```

#### Top-level `<objective>` block (lifted shape from `25-01-PLAN.md:64-74`)

```markdown
<objective>
Run the 9 deferred QA scenarios (5 from Phase 19's "Looks Done But Isn't" backlog, 4 from Phase 21's titlebar visual UAT cross-ref) against a local debug build of PS Transcribe from `main` HEAD and produce `26-UAT.md` documenting PASS / FAIL / WITHDRAWN / UNTESTABLE-this-cycle per scenario. Failures are batch-triaged after the full sweep and routed per D-02.

Purpose: ROADMAP success criterion 1 + Phase 25 D-03 (forward cross-ref to Phase 26 for QA-06..09) + QA-FUT-01 closure.

Output:
- 1 new artifact: 26-UAT.md with 10 rows (QA-01, QA-02, QA-03a, QA-03b, QA-04, QA-05, QA-06, QA-07, QA-08, QA-09) at frontmatter status: in-progress -> resolved | approved-with-debt
- 0..N conditional: 26-NN-PLAN.md fix plans for in-phase remediations per D-02 (size threshold: <1hr AND ≤2 files)
- 0..N conditional: .planning/todos/pending/qa-NN-<short>.md deferred fix todos per D-02 (anything bigger / architectural)
- 1 SUMMARY.md (created at plan close, includes `requirements-completed: [QA-FUT-01]`)
</objective>
```

#### `<execution_context>` block (lifted exactly from `25-01-PLAN.md:76-79`)

```markdown
<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>
```

#### `<context>` block (lifted shape from `25-01-PLAN.md:81-97`; planner picks exact files)

```markdown
<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/STATE.md
@.planning/phases/26-qa-sweep-visual-uat/26-CONTEXT.md
@.planning/phases/26-qa-sweep-visual-uat/26-PATTERNS.md
@.planning/research/PITFALLS.md
@.planning/milestones/v1.2-phases/18.1-shared-save-destinations-local-file/18.1-UAT.md
@.planning/milestones/v1.2-phases/21-appearance-override/21-HUMAN-UAT.md
@.planning/phases/24-nyquist-sweep-v1-0/24-HUMAN-UAT.md
@.planning/phases/25-nyquist-sweep-v1-2/25-CONTEXT.md
@PSTranscribe/Sources/PSTranscribe/PSTranscribe.entitlements
@PSTranscribe/Sources/PSTranscribe/Settings/AppSettings.swift
@PSTranscribe/Sources/PSTranscribe/App/DictationCoordinator.swift
@PSTranscribe/Sources/PSTranscribe/App/DictationWindowController.swift
@PSTranscribe/Sources/PSTranscribe/Views/DictationHUD.swift
@PSTranscribe/Sources/PSTranscribe/Services/ModelUpdateService.swift
@PSTranscribe/Sources/PSTranscribe/Services/SaveDestinations.swift
</context>
```

#### `<task>` shape — **modified from `25-01-PLAN.md` Swift Testing pattern**

`25-01-PLAN.md:160-273` defines a Swift-edits task with `<files>` / `<read_first>` / `<behavior>` / `<action>` / `<verify><automated>` / `<acceptance_criteria>` / `<done>`.

**Phase 26 task shape (manual-driver variant):** keep the structural skeleton, but:
- `type="auto"` → `type="manual"` (human-in-the-loop)
- `tdd="true"` → omit `tdd` attribute (no test code)
- `<action>` describes user-driven steps, not code edits
- `<verify><automated>` → `<verify><manual>` with text attestation (e.g., `User runs scenario, observes outcome, types result line in 26-UAT.md`)
- `<acceptance_criteria>` shifts from grep counts to **markdown grep counts** against `26-UAT.md` (e.g., `grep -c '^### N\. QA-NN' 26-UAT.md` returns 1 per row)

**Example task scaffold for Phase 26 (planner builds from this):**

```markdown
<task type="manual">
  <name>Task 1: Pre-flight setup — install missing clipboard manager + build app from main HEAD</name>
  <files>none</files>
  <read_first>
    - .planning/phases/26-qa-sweep-visual-uat/26-CONTEXT.md (D-01 — hybrid environment; user has Maccy OR Alfred, not both)
  </read_first>
  <behavior>
    Identify which clipboard manager is missing (ask user). Install it. Build PS Transcribe from main HEAD. Confirm dictation hotkey fires.
  </behavior>
  <action>
    1. Ask user: "Which clipboard manager do you currently have installed — Maccy or Alfred?"
    2. Install the missing one:
       - If Maccy missing: `brew install --cask maccy` (free)
       - If Alfred missing: download from https://www.alfredapp.com (Powerpack required for clipboard history)
    3. Build PS Transcribe: `cd PSTranscribe && swift build -c debug` (or Xcode Run)
    4. Launch the built binary and confirm dictation hotkey triggers a session.
    5. Note the installed-version + temporary-install fact in 26-UAT.md preamble for later cleanup.
  </action>
  <verify>
    <manual>User confirms both clipboard managers are running, the debug build launches, and dictation hotkey fires.</manual>
  </verify>
  <acceptance_criteria>
    - Both Maccy and Alfred running concurrently (D-01)
    - swift build -c debug exits 0 from main HEAD
    - Dictation hotkey triggers a session in the debug build (smoke test)
  </acceptance_criteria>
  <done>Environment ready for QA sweep.</done>
</task>

<task type="manual">
  <name>Task 2: Run QA-01 — clipboard exclusion under Maccy</name>
  ... (per-scenario task; one task per scenario or grouped per cluster per CONTEXT.md Claude's Discretion §"Order of scenarios")
</task>

... (more tasks)

<task type="auto">
  <name>Task N: Author 26-UAT.md from sweep results + batch-triage FAILs per D-02</name>
  <files>.planning/phases/26-qa-sweep-visual-uat/26-UAT.md</files>
  <read_first>
    - .planning/phases/26-qa-sweep-visual-uat/26-PATTERNS.md (this file — see §26-UAT.md skeleton)
    - .planning/milestones/v1.2-phases/18.1-shared-save-destinations-local-file/18.1-UAT.md (frontmatter + row shapes)
    - .planning/phases/24-nyquist-sweep-v1-0/24-HUMAN-UAT.md (approved-with-debt terminal-state shape)
    - sweep notes from prior tasks
  </read_first>
  <behavior>
    Use the Write tool to create 26-UAT.md per the §26-UAT.md pattern in 26-PATTERNS.md. Group routing decisions for FAILs per D-02 size rule. For in-phase fixes, append the fix-plan number to the row's routing: line and create 26-NN-PLAN.md (separate plan, lands inside this phase). For deferred fixes, append the todo filename to the row's routing: line and create the todo file.
  </behavior>
  <action>
    Write 26-UAT.md following the patterns in 26-PATTERNS.md §26-UAT.md. Confirm row count matches Summary count. Set status to `resolved` only if every scenario is PASS / WITHDRAWN with no UNTESTABLE-this-cycle gaps; otherwise `approved-with-debt`.
  </action>
  <verify>
    <automated>test -f .planning/phases/26-qa-sweep-visual-uat/26-UAT.md && grep -c '^### ' .planning/phases/26-qa-sweep-visual-uat/26-UAT.md && grep -cE 'QA-0[1-9]' .planning/phases/26-qa-sweep-visual-uat/26-UAT.md</automated>
  </verify>
  <acceptance_criteria>
    - File exists at .planning/phases/26-qa-sweep-visual-uat/26-UAT.md
    - `grep -cE '^### [0-9]+(a|b)?\. QA-0[1-9]' 26-UAT.md` returns at least 9 (one per QA-NN; allows 03a/03b split = 10)
    - `grep -c 'WITHDRAWN' 26-UAT.md` returns at least 1 (QA-04)
    - `grep -c '21-HUMAN-UAT\.md' 26-UAT.md` returns at least 4 (one per QA-06..09 citation row)
    - `grep -c 'passed 2026-05-01, user attestation' 26-UAT.md` returns 4
    - Frontmatter `status:` is exactly one of `resolved` or `approved-with-debt`
    - `grep -c '^total: ' 26-UAT.md` returns 1 (Summary block)
    - `grep -c 'PSTranscribe.entitlements' 26-UAT.md` returns at least 1 (QA-04 WITHDRAWN reasoning)
    - `grep -cE 'AppSettings\.swift:(82|97)' 26-UAT.md` returns at least 1 (QA-04 WITHDRAWN reasoning)
  </acceptance_criteria>
  <done>26-UAT.md authored with all rows + Summary + Cross-References + frontmatter at terminal status.</done>
</task>
```

#### `<verification>` block (lifted shape from `25-01-PLAN.md:654-664`)

```markdown
<verification>
- 26-UAT.md exists at the correct path with valid YAML frontmatter
- All 9 QA-NN scenarios have rows (with QA-03 split into 03a/03b)
- QA-06..09 rows cite 21-HUMAN-UAT.md with `passed 2026-05-01, user attestation`
- QA-04 WITHDRAWN reasoning cites PSTranscribe.entitlements + AppSettings.swift:82,97 (not the speculative bookmark framing)
- Summary block counts equal row counts
- Status is `resolved` (no UNTESTABLE-this-cycle) or `approved-with-debt` (at least one UNTESTABLE-this-cycle)
- For each in-phase routed FAIL: a 26-NN-PLAN.md exists in the same phase directory
- For each deferred FAIL: a todo at .planning/todos/pending/qa-NN-<short>.md exists with status: pending
</verification>
```

#### `<success_criteria>` block (lifted shape from `25-01-PLAN.md:666-673`)

```markdown
<success_criteria>
1. 26-UAT.md authored at correct path with frontmatter at terminal status (resolved or approved-with-debt)
2. All 9 QA-NN scenarios attested (with QA-03 PARTIAL split into 03a/03b)
3. QA-06..09 cite 21-HUMAN-UAT.md without re-execution
4. QA-04 WITHDRAWN with codebase-verified reasoning
5. ROADMAP success criterion 1 satisfied (26-UAT.md exists)
6. ROADMAP success criterion 6 satisfied (FAIL routing dual-track honored — in-phase plans + deferred todos as appropriate)
7. SUMMARY.md frontmatter `requirements-completed: [QA-FUT-01]` (PROCESS-01 in effect)
</success_criteria>
```

#### `<output>` block (lifted shape from `25-01-PLAN.md:675-685`)

```markdown
<output>
After completion, create .planning/phases/26-qa-sweep-visual-uat/26-01-SUMMARY.md with:
- Frontmatter: requirements-completed: [QA-FUT-01]
- What shipped: 26-UAT.md + 0..N 26-NN-PLAN.md + 0..N todos
- D-01 referenced explicitly (hybrid environment + QA-03 PARTIAL + QA-04 WITHDRAWN)
- D-02 referenced explicitly (batch-triage routing decisions for each FAIL)
- D-03 referenced explicitly (text attestation only; QA-06..09 cite 21-HUMAN-UAT.md)
- D-04 referenced explicitly (single 26-01-PLAN.md; 26-UAT.md filename per ROADMAP)

Commit message style: NO Claude attribution (per user-level CLAUDE.md). Subject: `feat(26-01): QA sweep + visual UAT (QA-FUT-01)` or similar; body explains the WITHDRAWN, UNTESTABLE-this-cycle, and citation row decisions.
</output>
```

---

### `26-NN-PLAN.md` (conditional fix plan)

**Analog:** `25-01-PLAN.md` — same shape as 26-01-PLAN.md but smaller scope (single-scenario fix).

**Pattern:** identical to `26-01-PLAN.md` skeleton above, with:
- `plan: NN` incremented (02, 03, ...)
- `requirements:` updated to the specific QA-NN being fixed
- `depends_on: [01]` (the sweep plan must complete first to identify the FAIL)
- `<objective>` scoped to one scenario
- `files_modified:` includes the production source file(s) being patched (e.g., `PSTranscribe/Sources/PSTranscribe/App/DictationWindowController.swift` for an HUD origin off-by-one) AND `.planning/phases/26-qa-sweep-visual-uat/26-UAT.md` (re-run row update from FAIL to PASS)
- `autonomous: true` (most fixes are mechanical — Swift edit + re-run scenario)
- Re-run-the-scenario task at the end to flip the row in 26-UAT.md from FAIL to PASS

Per D-02, fix plans only ship if **<1hr AND ≤2 files**. For larger fixes, route to a deferred todo (next pattern).

---

### `qa-NN-<short>.md` (conditional deferred todo)

**Analog:** `.planning/todos/pending/ci-build-check-failing-on-main.md` (the only existing pending todo; canonical shape).

**Frontmatter pattern (lifted from `ci-build-check-failing-on-main.md:1-8`):**

```yaml
---
title: <short description of fix needed>
status: pending
created: 2026-05-08
priority: high | medium | low
blocking: false
source: phase-26
---
```

**Body pattern (lifted shape from `ci-build-check-failing-on-main.md:10-60`):**

```markdown
## Context

<one paragraph: what FAIL surfaced this todo, which QA scenario, which CONTEXT.md decision routed it here per D-02 size rule>

## Issue

<concrete reproduction steps, observed vs. expected behavior, log excerpts>

**Code paths involved:**
- `PSTranscribe/Sources/PSTranscribe/<file>.swift:<line>` — <what's there now>
- ...

**Suggested fixes:**
- <option 1>
- <option 2>

## Why deferred from Phase 26

<per D-02: fix exceeds <1hr OR >2 files threshold; OR architectural change requiring its own planning cycle>

## Acceptance criteria for closing this todo

- [ ] <concrete deterministic check 1>
- [ ] <concrete deterministic check 2>
- [ ] QA-NN re-run in a future UAT cycle PASSes
```

**Filename convention** (per CONTEXT.md Claude's Discretion §routing): `qa-NN-<short>.md` — title prefix matches the QA-NN that surfaced it. Example: `qa-03b-multi-monitor-positioning.md`, `qa-05-disk-space-preflight-warning.md`.

---

## Shared Patterns

### YAML frontmatter convention — UAT artifacts

**Source:** `18.1-UAT.md:1-20` + `24-HUMAN-UAT.md:1-7` + `21-HUMAN-UAT.md:1-8`
**Apply to:** `26-UAT.md`

Required keys: `status`, `phase`, `source` (list), `started`, `updated`. Optional at terminal: `resolved`, `resolved_by` (list).

`status` lifecycle: `in-progress` → (`resolved` | `approved-with-debt`).

### YAML frontmatter convention — execution + fix plans

**Source:** `25-01-PLAN.md:1-62`
**Apply to:** `26-01-PLAN.md`, `26-NN-PLAN.md`

Required keys: `phase`, `plan`, `type`, `wave`, `depends_on`, `files_modified`, `autonomous`, `requirements`, `tags`, `must_haves` (with `truths` / `artifacts` / `key_links` sub-blocks).

`autonomous: true` for code edits; `autonomous: false` for human-in-the-loop sweeps.

### Per-scenario row schema — UAT artifacts

**Source:** `18.1-UAT.md:28-84` (canonical shape) + `21-HUMAN-UAT.md:16-30` (citation variant)
**Apply to:** every QA-NN row in `26-UAT.md`

Heading shape: `### N[a|b]. QA-NN — <short scenario title>`. Body fields:
- `expected:` (always)
- `result:` (always — values: `pass` | `fail` | `issue` | `WITHDRAWN` | `untestable-this-cycle` | `pass (citation)` | `blocked`)
- `note:` / `reported:` / `severity:` / `reason:` / `gap:` / `code_ref:` / `source:` / `routing:` (conditional, see per-row patterns above)

### `## Summary` count block — UAT artifacts

**Source:** `18.1-UAT.md:86-93` + `24-HUMAN-UAT.md:19-27`
**Apply to:** `26-UAT.md`

Required keys: `total`, `passed`, `issues`, `pending`, `skipped`, `blocked`. Phase 26 additions: `withdrawn`, `untestable-this-cycle`, `citations`. Conditional at close: `approved-with-debt`.

Counts must equal `total`. Split rows count separately (planner bias, matches Phase 24/25 PARTIAL convention).

### Citation-row provenance string format

**Source:** `21-HUMAN-UAT.md:18` literal "passed (user attestation 2026-05-01)" + Phase 24/25 audit conventions
**Apply to:** QA-06..09 rows in `26-UAT.md`

Bias format: `Source: .planning/milestones/v1.2-phases/21-appearance-override/21-HUMAN-UAT.md (Test N, passed 2026-05-01, user attestation)` — file path + Test number + ISO date + attestation type. Date format `YYYY-MM-DD` (no time).

### `must_haves` `truths` array — execution plans

**Source:** `25-01-PLAN.md:16-31`
**Apply to:** `26-01-PLAN.md`

Each truth references a CONTEXT.md decision (D-NN) and states a verifiable fact. Bias: at least one truth per `D-` decision in CONTEXT.md, plus build-provenance, plus per-artifact existence assertions.

### `key_links` — execution plans

**Source:** `25-01-PLAN.md:46-61`
**Apply to:** `26-01-PLAN.md`

Each entry: `from:` (artifact this plan produces) / `to:` (artifact it cross-references) / `via:` (how) / `pattern:` (regex grep that proves the link).

### Heredoc-free file creation

**Source:** Project CLAUDE.md global instruction + global gsd-pattern-mapper rule
**Apply to:** every new file in Phase 26

Always use the Write tool. Never `cat << 'EOF'`. Already enforced by gsd-execute-phase.

### Commit message — no Claude attribution

**Source:** Project CLAUDE.md global instruction + `25-01-PLAN.md:684-685`
**Apply to:** every commit produced by Phase 26 plans

No `Co-Authored-By: Claude`. No `🤖 Generated with`. Subject + body only.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| (none) | — | — | All Phase 26 file types have in-house analogs (18.1-UAT.md / 24-HUMAN-UAT.md / 21-HUMAN-UAT.md / 25-01-PLAN.md / ci-build-check-failing-on-main.md). The composite nature of 26-UAT.md (drawing from three precedents simultaneously) is novel, but each individual pattern has a clear in-house source. |

**Notes for planner about composite shape:**
- `routing:` field on FAIL rows has no exact in-house analog — closest is the `note:` / `reason:` free-form string convention from `18.1-UAT.md`. Planner picks the exact field shape (per CONTEXT.md Claude's Discretion §routing).
- `untestable-this-cycle` row state has no exact in-house analog — derived from Phase 24's `approved-with-debt` terminal-state philosophy + Phase 24/25 PARTIAL `a/b` split convention. Planner picks exact wording for the `result:` value (bias: `untestable-this-cycle` lowercase-hyphenated to mirror `approved-with-debt`).
- Citation rows referencing a prior phase's user-attestation UAT have no exact in-house analog — derived from `21-HUMAN-UAT.md` user-attestation phrasing. Planner picks exact `Source:` string format (bias above).

---

## Metadata

**Analog search scope:**
- `.planning/milestones/v1.2-phases/18.1-shared-save-destinations-local-file/18.1-UAT.md`
- `.planning/milestones/v1.2-phases/21-appearance-override/21-HUMAN-UAT.md`
- `.planning/phases/24-nyquist-sweep-v1-0/24-HUMAN-UAT.md`
- `.planning/phases/24-nyquist-sweep-v1-0/24-PATTERNS.md` (cross-checked for shared-pattern conventions)
- `.planning/phases/25-nyquist-sweep-v1-2/25-01-PLAN.md` (canonical execution-plan shape)
- `.planning/phases/25-nyquist-sweep-v1-2/25-PATTERNS.md` (cross-checked for shared-pattern conventions)
- `.planning/todos/pending/ci-build-check-failing-on-main.md` (only existing pending todo)
- `.planning/phases/26-qa-sweep-visual-uat/26-CONTEXT.md` (mandatory upstream input)

**Files scanned:** 8 (full reads of all 8; no large-file targeted reads needed — every analog ≤ 700 lines).
**Pattern extraction date:** 2026-05-08
