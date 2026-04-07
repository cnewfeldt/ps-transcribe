# Phase 9: Verification Sweep + Tracking Reconciliation - Context

**Gathered:** 2026-04-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Every implemented requirement has a formal VERIFICATION.md, REQUIREMENTS.md checkboxes and traceability table match verified reality, and ROADMAP.md progress is accurate. No code changes -- this is documentation reconciliation only.

</domain>

<decisions>
## Implementation Decisions

### Verification Approach
- **D-01:** Code inspection only for all requirements (Phase 4 and Phase 7) -- no human UAT or screenshots required
- **D-02:** Match existing VERIFICATION.md format used in Phases 1-3 (requirement-by-requirement with SATISFIED/BLOCKED/HUMAN_NEEDED verdicts and code evidence)
- **D-03:** Phase 4 VERIFICATION.md references existing VALIDATION.md (nyquist_compliant: true) but performs its own independent requirement checks
- **D-04:** Phase 7 verification bundles NOTN-01..05 verification AND adds them to REQUIREMENTS.md traceability in one pass

### Tracking Fix Scope
- **D-05:** Batch fix all 18+ REQUIREMENTS.md checkbox discrepancies in one pass -- cross-reference VERIFICATION.md files and flip confirmed-satisfied checkboxes to [x]
- **D-06:** Add full "### Notion Integration" section to REQUIREMENTS.md with NOTN-01..05 descriptions AND traceability rows (matching the structure of other requirement groups)

### Partial/Unsatisfied Requirements
- **D-07:** STAB-01 (crash recovery): verify whether Phase 8 execution fixed scanIncompleteCheckpoints() call site. Mark satisfied if fixed, document gap if not
- **D-08:** SESS-04 (clickable file path): accept right-click "Show in Finder" as SATISFIED with implementation note -- requirement intent is met
- **D-09:** REBR-08 (UserDefaults migration): carry forward HUMAN_NEEDED verdict -- code inspection cannot verify runtime behavior on a Tome-to-PSTranscribe upgrade

### ROADMAP.md Cleanup
- **D-10:** Fix all stale progress entries in one pass (Phases 1, 3, 7, 8) -- cross-reference SUMMARY.md files to confirm plan completion
- **D-11:** Reconcile top-level phase checklist ([ ]/[x] marks) to reflect completed phases -- Phases 1-4 and 7-8 should all be [x]

### Claude's Discretion
- Exact wording of verification evidence for each requirement
- Order of operations (verify first vs. fix tracking first)
- Whether to update REQUIREMENTS.md coverage counts at the bottom

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone audit (primary input)
- `.planning/v1.0-MILESTONE-AUDIT.md` -- Identifies all gaps: missing VERIFICATION.md files, checkbox discrepancies, NOTN traceability gaps, ROADMAP staleness

### Existing verification files (format reference)
- `.planning/phases/01-rebrand/01-VERIFICATION.md` -- Format template for VERIFICATION.md structure
- `.planning/phases/02-security-stability/02-VERIFICATION.md` -- Example of SATISFIED/BLOCKED verdicts
- `.planning/phases/03-session-management-recording-naming/03-VERIFICATION.md` -- Example of partial/gap handling

### Phase 4 artifacts (verification targets)
- `.planning/phases/04-mic-button-model-onboarding/04-CONTEXT.md` -- Phase 4 decisions and requirements
- `.planning/phases/04-mic-button-model-onboarding/04-VALIDATION.md` -- Nyquist validation (reference, not replace)
- `.planning/phases/04-mic-button-model-onboarding/04-01-PLAN.md` -- Engine errors, model download, onboarding
- `.planning/phases/04-mic-button-model-onboarding/04-02-PLAN.md` -- MicButton component, ControlBar, WaveformView deletion
- `.planning/phases/04-mic-button-model-onboarding/04-03-PLAN.md` -- Visual verification + ControlBar redesign

### Phase 7 artifacts (verification targets)
- `.planning/phases/07-notion-integration/07-01-PLAN.md` -- KeychainHelper + NotionService
- `.planning/phases/07-notion-integration/07-02-PLAN.md` -- Settings Notion section
- `.planning/phases/07-notion-integration/07-03-PLAN.md` -- NotionTagSheet + send flow + context menu

### Tracking reconciliation targets
- `.planning/REQUIREMENTS.md` -- Checkbox fixes, NOTN section addition, traceability table updates
- `.planning/ROADMAP.md` -- Progress table and phase checklist reconciliation

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Existing VERIFICATION.md files (Phases 1-3, 8) provide a proven template and format
- v1.0-MILESTONE-AUDIT.md contains pre-analyzed discrepancy lists -- no need to re-derive gaps

### Established Patterns
- VERIFICATION.md format: requirement ID, verdict (SATISFIED/BLOCKED/HUMAN_NEEDED), code evidence with file paths and line numbers
- REQUIREMENTS.md structure: grouped sections with checkboxes, traceability table at bottom
- ROADMAP.md: top-level checklist + progress table + phase detail blocks

### Integration Points
- VERIFICATION.md files live in their respective phase directories
- REQUIREMENTS.md and ROADMAP.md are project-level files in .planning/

</code_context>

<specifics>
## Specific Ideas

No specific requirements -- open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope

</deferred>

---

*Phase: 09-verification-sweep-tracking*
*Context gathered: 2026-04-07*
