# Contributing

This is a solo-development codebase. The conventions below exist so future-me (and any AI collaborators) can be productive without re-deriving the rules each session.

## Tests

The Swift test target is `PSTranscribeTests` under `PSTranscribe/Tests/`. Run the full suite:

```bash
cd PSTranscribe
swift test
```

Run only the visual regression suite:

```bash
cd PSTranscribe
swift test --filter VisualRegression
```

CI runs `swift test` on every PR against `main` via `.github/workflows/build-check.yml`. PRs are blocked on test failures.

## Visual Regression Baselines

The `VisualRegression` suite snapshot-tests 5 SwiftUI surfaces (ContentView, LibrarySidebar, SettingsView, ControlBar, DictationHUD) across 3 appearance variants (Light, Dark, System) for 15 baseline PNGs total. Baselines live at `PSTranscribe/Tests/PSTranscribeTests/__Snapshots__/VisualRegressionTests/` and are committed to `main`.

### After a legitimate UI change

If your change intentionally alters how a snapshotted surface renders, regenerate baselines locally:

```bash
cd PSTranscribe
SNAPSHOT_TESTING_RECORD=all swift test --filter VisualRegression
```

Then `git add` the changed PNGs under `Tests/PSTranscribeTests/__Snapshots__/` and include them in the same PR as the source change. The reviewer eyeballs the PNG diff in the PR.

### Env var contract

`SNAPSHOT_TESTING_RECORD` accepts one of: `all`, `failed`, `missing`, `never`. It does NOT accept `true` -- a common folk-wisdom mistake.

| Value | Behavior |
|-------|----------|
| `all` | Always overwrite baselines on every test run (the regen mode) |
| `failed` | Overwrite a baseline only when the test fails the diff |
| `missing` | Write a baseline only when none exists (the suite default) |
| `never` | Never write; fail if a baseline is missing or differs (CI mode) |

### CI safety

CI never sets `SNAPSHOT_TESTING_RECORD`. The `Build Check` workflow includes a guard step that fails fast if the env var is set in the runner environment -- this prevents silent baseline overwrite if anyone accidentally adds the variable in repo Settings.

### Strict precision

Baselines are compared at `precision: 1.0`, `perceptualPrecision: 0.99`. Loosening this globally is forbidden; per-test overrides require a justification comment in the test body. The product invariant: legitimate UI changes always require a baseline regen.

### Read more

- `.planning/codebase/TESTING.md` -- testing patterns reference (incl. Visual Regression section)
- `.planning/phases/23-visual-regression-infra/23-ADR-snapshot-framework.md` -- framework choice rationale and rejected alternatives

## Commit Hygiene

- Never include AI attribution footers in commit messages (no `Co-Authored-By: Claude`, no `Generated with` tag, no robot emoji)
- Subject + body, nothing else
- One logical change per commit when feasible
