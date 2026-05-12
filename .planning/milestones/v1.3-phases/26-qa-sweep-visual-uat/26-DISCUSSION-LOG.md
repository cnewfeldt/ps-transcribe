# Phase 26: QA Sweep + Visual UAT - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-08
**Phase:** 26-qa-sweep-visual-uat
**Areas discussed:** Test environment readiness, Failure routing protocol, Build provenance + evidence, Misc bundled (CI todo / artifact name / plan structure)

---

## Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| Test environment readiness | Maccy + Alfred installed (QA-01/02)? Multi-monitor rig available (QA-03)? Willing to reboot (QA-04)? Substitute when missing: install / mark UNTESTABLE / block phase? | ✓ |
| Failure routing protocol | Per success criterion 6, failures become in-phase fix plans OR deferred todos. When does each apply? Quick fixes inline, structural ones deferred? Or batch-triage after the full sweep? | ✓ |
| Build provenance + evidence | Local debug build vs notarized Sparkle release v2.2.0? Evidence weight: text attestation (Phase 24/21 precedent), screenshots, or screen recordings for visual UAT (QA-06..09)? | ✓ |
| Misc bundled (CI todo / name / plans) | (a) Fold the ci-build-check-failing-on-main todo into Phase 26 or leave deferred? (b) Artifact name 26-UAT.md (per ROADMAP) vs 26-HUMAN-UAT.md (per phase convention)? (c) One plan or split (prep vs execution)? | ✓ |

**User's choice:** All four areas selected (multi-select).

---

## Test environment readiness

### Sub-question 1: Maccy + Alfred environment

| Option | Description | Selected |
|--------|-------------|----------|
| Both already installed | Maccy and Alfred (with clipboard history enabled) are running on your Mac — we test live as written. | |
| Have one, missing the other | You have one installed; we'd need to install the second temporarily for the QA cycle. (Recommended if you only have one regular driver.) | ✓ |
| Neither installed — install temporarily | Install both via Homebrew (Maccy is free; Alfred Powerpack required for clipboard history) just for this QA, document, then uninstall. | |
| Mark UNTESTABLE-this-cycle | Skip QA-01/QA-02 with a documented gap; defer to a later milestone when environment is available. | |

**User's choice:** Have one, missing the other.
**Notes:** Which manager is missing will be confirmed at execution start; planner adds the install step as the first step of `26-01-PLAN.md`.

### Sub-question 2: Multi-monitor (QA-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Multi-monitor rig available | You have at least one external display you can rearrange in System Settings → Displays for primary/secondary/vertical configurations. (Recommended.) | |
| Single display — use Sidecar/iPad as 2nd | Use macOS Sidecar with an iPad as a secondary display to simulate the configurations. Real signal, slight latency — sufficient for HUD positioning checks. | |
| Single display only | Test only the single-display position case as PASS; mark the multi-monitor sub-scenarios UNTESTABLE-this-cycle with a documented gap. | ✓ |
| Synthesize via NSScreen mock in unit test | Skip live testing; write a unit test that injects fake `NSScreen` array and asserts HUD origin math. (Note: this turns QA-03 into a code phase, not a sweep.) | |

**User's choice:** Single display only.
**Notes:** QA-03 will split into `QA-03a` (single-display position PASS) + `QA-03b` (multi-monitor sub-scenarios UNTESTABLE-this-cycle), mirroring Phase 24/25's PARTIAL-row split pattern.

### Sub-question 3: Reboot for QA-04

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, reboot during the sweep | Test both halves as written: select folder → record dictation → quit app → relaunch → verify; then full macOS reboot → launch → verify. (Recommended — highest-fidelity coverage.) | |
| App relaunch only; defer reboot half | Test app-relaunch survival now; mark the reboot half as UNTESTABLE-this-cycle with a todo. Splits QA-04 into 04a/04b like Phase 25's PARTIAL pattern. | |
| Skip both — cite Apple's bookmark guarantee | Trust the security-scoped bookmark API contract per Apple's documentation; mark QA-04 WITHDRAWN with a citation. (Weakest — doesn't catch our usage bugs.) | ✓ |

**User's choice:** Skip both — cite Apple's bookmark guarantee.
**Notes:** Codebase verification during CONTEXT writing strengthened this choice. PS Transcribe is non-sandboxed (entitlements: `audio-input` + `screen-capture` only); folder URLs persist as plain `String` in `UserDefaults`, not security-scoped bookmarks. WITHDRAW reason in CONTEXT.md is the codebase-verified one ("API not in use here") rather than the speculative "trust Apple's API" framing.

---

## Failure routing protocol

### Sub-question 1: When to triage

| Option | Description | Selected |
|--------|-------------|----------|
| Batch-triage after full sweep | Run all 9 scenarios, log PASS/FAIL only in 26-UAT.md, then read the FAILs as a group and decide which become in-phase plans vs todos. Lets you see the full picture before deciding scope. (Recommended.) | ✓ |
| Inline triage as failures occur | Each FAIL gets routed to plan or todo immediately. Faster commit cadence but risks scope creep — a FAIL might look fixable until you see a related FAIL elsewhere. | |
| Sweep is doc-only — every FAIL becomes a todo | Phase 26 produces no fix code; every FAIL goes to .planning/todos/pending/ for a future phase. Cleanest scope, slowest fix cycle. | |

**User's choice:** Batch-triage after full sweep.

### Sub-question 2: Plan vs todo rule

| Option | Description | Selected |
|--------|-------------|----------|
| Size-based: small fix → plan, large → todo | If fix is < 1 hour and touches ≤ 2 files (e.g., HUD origin math, missing privacy marker), it becomes 26-NN-PLAN.md. Anything bigger or architectural becomes a todo. (Recommended — keeps Phase 26 scope tight.) | ✓ |
| Severity-based: blocking → plan, non-blocking → todo | Anything blocking shipping v1.3 gets fixed in-phase regardless of size; cosmetic/nice-to-have FAILs become todos. | |
| Always plan, never todo | Every FAIL gets an in-phase fix plan. Phase 26 doesn't ship until all 9 pass. Tightest quality gate, longest phase. | |
| Always todo, never plan | Phase 26 is doc-only; every FAIL is deferred. | |

**User's choice:** Size-based.

---

## Build provenance + evidence

### Sub-question 1: Build target

| Option | Description | Selected |
|--------|-------------|----------|
| Local debug build from main HEAD | Build with `swift build -c debug` (or Xcode Run) from current main. Fastest cycle, includes any uncommitted post-Phase 25 changes. (Recommended — matches Phase 24/21 precedent.) | ✓ |
| Local release build from main HEAD | Build with `-c release` from current main. Catches optimization-only bugs but no signing/notarization differences. | |
| Notarized Sparkle release v2.2.0 | Test against the actual shipped artifact users have. Highest production fidelity but stale (pre-Phase 25 commits not represented). | |
| Both local debug AND notarized v2.2.0 | Cross-check: any FAIL on local debug must reproduce on v2.2.0 to count as a real bug. Doubles execution time. | |

**User's choice:** Local debug build from main HEAD.

### Sub-question 2: Evidence weight

| Option | Description | Selected |
|--------|-------------|----------|
| Text attestation only | Per Phase 24/21 precedent: user states 'expected: … / result: passed'. No screenshots required. Trust-based but consistent with established convention. (Recommended.) | ✓ |
| Screenshots for visual UAT (QA-06..09) only | Titlebar visual scenarios get a screenshot inline; QA-01..05 stay text-only. Best signal-to-effort ratio for the genuinely visual items. | |
| Screenshots for all 9 scenarios | Every scenario gets a screenshot. Maximum auditability but high friction. | |
| Screen recording for the full sweep | Record the entire UAT cycle as a single screen recording linked from 26-UAT.md. Strong evidence; large artifact, awkward to review. | |

**User's choice:** Text attestation only.

### Sub-question 3: QA-06..09 handling

| Option | Description | Selected |
|--------|-------------|----------|
| Fresh re-execution, ignore prior result | Treat 21-HUMAN-UAT.md as historical context only; run all 4 scenarios fresh on current build, write fresh expected/result lines in 26-UAT.md. (Recommended — honors Phase 25's contract.) | |
| Cite prior result, smoke-test only | Open Settings, flip preference once for each of L/D/S, confirm titlebar still flips correctly; cite 21-HUMAN-UAT.md for full coverage. Faster but weaker re-verification. | |
| Skip — cite 21-HUMAN-UAT.md as canonical | Don't re-run; mark QA-06..09 as cross-ref'd to 21-HUMAN-UAT.md. Conflicts with Phase 25 D-03 expectation. | ✓ |

**User's choice:** Skip — cite 21-HUMAN-UAT.md as canonical.
**Notes:** User explicitly opts to cite the prior pass rather than re-run. Phase 25 D-03 cross-ref contract is satisfied by the citation rows existing in 26-UAT.md; the rows defer to `21-HUMAN-UAT.md` (Tests 1–4, passed 2026-05-01, user attestation) for evidence. The "(Recommended)" hint in option 1 was overridden — captured here so future readers see the explicit choice.

---

## Misc bundled (CI todo / artifact name / plan structure)

### Sub-question 1: CI todo

| Option | Description | Selected |
|--------|-------------|----------|
| Leave deferred — not Phase 26's scope | Phase 26 is QA execution against the **app**; the todo is about CI **infrastructure**. Different surface. Tracked via the existing todo file. (Recommended — keeps Phase 26 scope crisp.) | |
| Fold in — Phase 26 owns CI green too | Phase 26 won't ship unless CI is green AND all 9 QA pass. Adds 1–2 plans for Swift 6 fixes + Xcode runner tweak. Bigger phase, broader 'QA Sweep' interpretation. | |
| Note in CONTEXT.md but don't fold | Same as 'leave deferred', but record the cross-ref so a future reader sees the todo was considered and intentionally excluded. | ✓ |

**User's choice:** Note in CONTEXT.md but don't fold.

### Sub-question 2: Artifact name

| Option | Description | Selected |
|--------|-------------|----------|
| 26-UAT.md (per ROADMAP) | Honor the explicit ROADMAP wording. Matches 18.1-UAT.md precedent. (Recommended — no rewriting, ROADMAP wins.) | ✓ |
| 26-HUMAN-UAT.md (per recent convention) | Matches Phase 24/21/17. Updates ROADMAP wording to track the convention. | |

**User's choice:** 26-UAT.md.

### Sub-question 3: Plan structure

| Option | Description | Selected |
|--------|-------------|----------|
| Single plan: 26-01 executes the whole sweep | One plan that produces 26-UAT.md with all 9 results, plus any fix plans get added as 26-02, 26-03 … after batch-triage. (Recommended — the sweep itself is one atomic execution; fixes are conditional.) | ✓ |
| Two plans: 26-01 prep, 26-02 execute | Plan 1 sets up environment (install Maccy/Alfred, verify build, draft 26-UAT.md skeleton); Plan 2 runs scenarios and fills results. Cleaner separation but artificial — prep is mostly a checklist. | |
| Per-scenario plans (26-01..26-09) | Each QA gets its own plan. Maximum atomicity, but absurdly granular for a 9-item manual sweep — the whole sweep is one human session. | |

**User's choice:** Single plan: 26-01 executes the whole sweep.

---

## Claude's Discretion

Captured in CONTEXT.md `<decisions>` → `### Claude's Discretion`. Items the planner picks within established conventions:

- 26-UAT.md frontmatter and per-scenario row schema (modeled on `18.1-UAT.md`).
- Order of scenarios in 26-UAT.md (default numerical; planner may regroup by surface cluster).
- Which clipboard manager (Maccy or Alfred) the user already has — confirmed at execution start.
- QA-03 single-display PASS criteria language.
- QA-05 disk-space test mechanism (bias: lower threshold via debug build flag in `ModelUpdateService.swift` rather than fill the disk).
- Routing-decision recording field shape on FAIL rows.
- Trailing `## Cross-References` section in 26-UAT.md.

## Deferred Ideas

- **Multi-monitor HUD QA when hardware is available** — capture QA-03 multi-monitor sub-scenarios in a future opportunistic phase. Not promoted to a todo (hardware-availability question, resolves naturally).
- **Real-disk-fill QA-05 mechanism** — revisit if debug-build threshold-lowering proves insufficient.
- **Snapshot-test coverage for QA-06..QA-09** — future Phase-23-extension if manual UAT should become a CI gate.
- **Sandbox-mode investigation** — reactivates QA-04 framing if PS Transcribe ever ships sandboxed (e.g., Mac App Store).

### Reviewed Todos (not folded)

- **`ci-build-check-failing-on-main.md`** — score 0.6 match. Not folded: surface mismatch (CI infrastructure vs user-facing app QA). Existing todo file remains canonical tracker.
