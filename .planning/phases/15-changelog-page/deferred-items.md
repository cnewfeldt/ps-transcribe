# Deferred Items - Phase 15

## Out-of-Scope Issues Discovered During Plan 15-01

### Pre-existing lint error in `website/src/hooks/useReveal.ts`

**Discovered:** During plan 15-01 lint verification (Task 4).
**Origin:** Introduced in commit `05a05eb` (Phase 13-02 — useScrolled/useReveal hooks).
**Issue:** ESLint rule `react-hooks/set-state-in-effect` flags `setVisible(true)` at line 19 inside the effect synchronous path:

```
src/hooks/useReveal.ts
  19:7  error  Calling setState synchronously within an effect can trigger cascading renders
```

**Why deferred:** Pre-existing failure, not caused by plan 15-01 changes. Plan 15-01 lint passes when only its modified files are checked (`pnpm exec eslint src/lib/inline-markdown.tsx src/lib/section-color.ts src/lib/site.ts src/components/ui/Pill.tsx src/components/ui/index.ts` exits 0). Per execution scope-boundary rule (only auto-fix issues directly caused by current task changes), this stays out of scope for 15-01.

**Suggested follow-up:** Fix in a dedicated commit (Phase 15-04 or a separate hardening pass). The `prefers-reduced-motion` short-circuit at lines 17-21 of `useReveal.ts` should set the initial state via `useState(initial)` rather than calling `setVisible(true)` inside the effect.
