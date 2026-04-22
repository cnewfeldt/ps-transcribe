---
phase: 11
plan: 03
type: execute
wave: 2
depends_on: [01]
files_modified:
  - .planning/PROJECT.md
autonomous: false
requirements:
  - SITE-02
  - SITE-03
  - SITE-04
tags:
  - vercel
  - deployment
  - monorepo
  - runbook
must_haves:
  truths:
    - "Vercel project is connected to the ps-transcribe GitHub repo with Root Directory = `website`"
    - "Pushing any commit that touches `/website` to main triggers a Vercel production build"
    - "Pushing any Swift-only commit (no files under `website/`) to main is skipped by the Ignored Build Step"
    - "Each PR branch that touches `/website` produces a Vercel preview URL, announced by the Vercel bot in a PR comment"
    - "Production site is reachable at `https://ps-transcribe.vercel.app` (or fallback slug logged in PROJECT.md)"
    - "All 18 production HTTP probes from 11-VALIDATION.md pass green"
  artifacts:
    - path: "Vercel Dashboard → ps-transcribe project"
      provides: "Git-connected project with Root Directory = website and Ignored Build Step configured"
      contains: "external — not a repo file"
    - path: ".planning/PROJECT.md"
      provides: "Production URL logged if non-default slug used (fallback path)"
      contains: "vercel.app"
  key_links:
    - from: "GitHub repo ps-transcribe"
      to: "Vercel project ps-transcribe"
      via: "Vercel GitHub App integration"
      pattern: "auto-comment on PRs"
    - from: "Vercel build"
      to: "website/ directory"
      via: "Root Directory setting"
      pattern: "Root Directory = website"
    - from: "Vercel Ignored Build Step"
      to: "website/ file changes"
      via: "git diff HEAD^ HEAD --quiet -- . evaluated inside Root Directory"
      pattern: "exit 0 = skip, exit 1 = build"
---

<objective>
Connect the Vercel project to the ps-transcribe GitHub repo via the Vercel dashboard with the exact settings locked in CONTEXT.md (D-07 Root Directory = `website`, D-08 production slug `ps-transcribe`, D-09 Ignored Build Step `git diff HEAD^ HEAD --quiet -- .`, D-10 preview URLs auto-enabled), trigger the first production deploy, and verify all 18 probes from 11-VALIDATION.md pass against `https://ps-transcribe.vercel.app`.

Purpose: This plan is the phase gate — once it completes, SITE-02/SITE-03/SITE-04 are earned (push → deploy → preview → production reachable). Plan 02 shipped the content that this plan deploys; without Plan 03 the site is localhost-only. The only in-repo change is `PROJECT.md` if the `ps-transcribe` Vercel slug is already taken and we need to log a fallback URL.

Output:
- Vercel project exists and is connected to the GitHub repo with all 4 settings verified
- First production deploy completes with status "Ready"
- `https://ps-transcribe.vercel.app` (or fallback) serves the Plan 02 Chronicle placeholder
- All 18 HTTP/file probes from 11-VALIDATION.md return green
- `.planning/PROJECT.md` updated only if fallback slug was needed

Note on parallelism: This plan runs in Wave 2 alongside Plan 02. They share zero files in the repo (Plan 02 touches `website/src/app/*`; Plan 03 only touches Vercel dashboard + conditionally `PROJECT.md`). Plan 03 cannot meaningfully complete until Plan 02 is deployed (the HTTP probes assert Plan 02's content is live), so the actual execution order within Wave 2 is: Plan 03 Task 1 (Vercel setup — can start when Plan 01 is on main) → Plan 02 completes and lands on main → Plan 03 Task 2 waits for that deploy → Plan 03 Task 3 runs HTTP probe suite.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/phases/11-website-scaffolding-vercel-deployment/11-CONTEXT.md
@.planning/phases/11-website-scaffolding-vercel-deployment/11-RESEARCH.md
@.planning/phases/11-website-scaffolding-vercel-deployment/11-VALIDATION.md
</context>

<tasks>

<task type="checkpoint:human-action" gate="blocking">
  <name>Task 1: Vercel dashboard setup (import repo + configure 4 settings)</name>
  <files>(none — external Vercel dashboard configuration)</files>
  <read_first>
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-CONTEXT.md §decisions D-07 (dashboard GitHub integration, Root Directory = `website`), D-08 (slug `ps-transcribe`, fallback `ps-transcribe-web`), D-09 (Ignored Build Step exact command), D-10 (preview URLs)
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-RESEARCH.md §Pattern 6 "Vercel project setup (one-time human action)" (exact steps 1-8)
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-RESEARCH.md §Pitfall 2 "Ignored Build Step path wrong after setting Root Directory" (why `-- .` not `-- website`)
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-RESEARCH.md §Pitfall 6 "Vercel uses oldest pnpm version if installCommand is overridden" (do NOT enable the Install Command override)
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-CONTEXT.md §decisions D-11 (no separate GitHub Actions; Vercel's pnpm build is the only gate)
  </read_first>
  <what-built>
    Wave 1 (Plan 01) scaffolded `/website/` on main. Now the Vercel dashboard needs one-time configuration to connect the repo, set Root Directory to `website`, claim the production slug, and configure the Ignored Build Step so Swift-only commits don't rebuild the site. This is the only task in the entire phase that genuinely requires human action — Vercel's first-time repo import is an OAuth dance + dashboard form that has no CLI/API path suitable for initial project creation (the Vercel CLI `vercel link` presumes a project already exists).
  </what-built>
  <how-to-verify>
Follow RESEARCH.md §Pattern 6 steps 1-8 in the Vercel dashboard. Each step corresponds to one locked decision — DO NOT skip or paraphrase.

**Step 1 — Import the repo:**
Go to https://vercel.com/new → "Import Git Repository" → authorize the Vercel GitHub App if prompted → select `ps-transcribe` from the repo list. [D-07]

**Step 2 — Project name (claim the production slug):**
Enter project name: `ps-transcribe` (lowercase, no dashes beyond the one already present). This produces the production URL `https://ps-transcribe.vercel.app`. [D-08]

**IF the slug `ps-transcribe` is already taken globally (unlikely but possible):**
- Fall back to `ps-transcribe-web` (or another available variant).
- Record the actual production URL. This triggers the in-repo PROJECT.md edit in Task 2.
- Do NOT proceed past Step 2 if no acceptable slug is available — stop and ask user for a decision.

**Step 3 — Framework preset:**
Confirm auto-detected as `Next.js`. Do NOT change it.

**Step 4 — Root Directory (CRITICAL — D-07):**
Click "Edit" next to Root Directory → select `website` from the folder picker (NOT the repo root). This scopes every subsequent operation — build, lockfile detection, Ignored Build Step, Node version resolution — to `/website`. If this is wrong, nothing else works. [D-07]

**Step 5 — Build & Development Settings:**
Leave ALL defaults. Do NOT override:
- Install Command (per RESEARCH.md Pitfall 6 — override forces oldest pnpm 6.x behavior)
- Build Command (defaults to `next build` which Next.js 16 runs with Turbopack)
- Output Directory
- Development Command

Vercel will auto-detect `pnpm-lock.yaml` inside `website/` (because Root Directory is scoped there) and use pnpm 10. [D-01]

**Step 6 — Node.js Version:**
Leave default. Vercel reads `engines.node: ">=22 <23"` from `website/package.json` (shipped in Plan 01 Task 2) and deploys Node 22.x — this takes precedence over the dashboard default per RESEARCH.md §Standard Stack (Assumption A1). [D-03]

**Step 7 — First deploy:**
Click **Deploy**. This triggers a production build from `main`. Expected build time: ~60-120s (Turbopack, small bundle). If the build fails, read the Vercel build log — the most common causes are (a) lockfile mismatch if pnpm version differs from what generated the file, (b) engines.node unsatisfiable if someone misedited the pin, (c) Next.js ImageResponse 500KB cap if OG image from Plan 02 is too big.

After first deploy succeeds, the project dashboard will show `Ready` status and link to `https://ps-transcribe.vercel.app` (or the fallback slug).

**Step 8 — Ignored Build Step (CRITICAL — D-09):**
Project → Settings → Git → **Ignored Build Step** → select **"Custom"** → enter exactly:

```
git diff HEAD^ HEAD --quiet -- .
```

**DO NOT TYPE**:
- `git diff HEAD^ HEAD --quiet -- website` (WRONG — the command runs INSIDE Root Directory, so `website` resolves to `website/website` which doesn't exist, causing every build to skip per RESEARCH.md Pitfall 2)
- `git diff HEAD~1 HEAD ...` (different semantics under Vercel's shallow clone)
- Any multi-line script — Vercel's field is a single command.

Exit code semantics (RESEARCH.md §Common Pitfalls): **exit 0 = skip deploy, exit 1 = build**. The first deploy has no `HEAD^` (shallow clone depth = 10, only 1 new commit), so `git diff` errors out with non-zero → Vercel builds (this is the desired fail-open behavior per Pitfall 3).

Click **Save**. This setting applies to every future deploy; swift-only commits on `main` (nothing under `website/`) will now be skipped.

**Present the completion summary to Claude with:**
1. Final project slug used (`ps-transcribe` or fallback)
2. Production URL (from Vercel dashboard header)
3. Confirmation of all 4 settings: Root Directory = `website`, framework = Next.js, Node = 22.x (visible in first build log), Ignored Build Step = `git diff HEAD^ HEAD --quiet -- .`
4. First-deploy build status (`Ready` expected)
  </how-to-verify>
  <resume-signal>
    Reply with `vercel-ready: <production-url>` where `<production-url>` is the exact `https://<slug>.vercel.app` URL shown on the Vercel dashboard. Claude uses this URL in subsequent HTTP probes. If the slug is NOT `ps-transcribe`, include a note `fallback-slug: <slug>` so Task 2 triggers the PROJECT.md edit.
  </resume-signal>
  <action>
    Human follows the Vercel dashboard runbook captured in `<how-to-verify>` above. Claude cannot automate first-time Vercel project import (no CLI for initial repo connect + dashboard setting entry). Executor role here: present the runbook to the user, wait for `resume-signal`, and parse the returned production URL for downstream tasks.
  </action>
  <verify>
    <automated>echo "MANUAL — blocked on Vercel dashboard configuration; resume-signal format: vercel-ready: https://&lt;slug&gt;.vercel.app"</automated>
  </verify>
  <done>User has completed all 8 steps of RESEARCH.md §Pattern 6 in the Vercel dashboard and replied with resume-signal containing the production URL.</done>
</task>

<task type="auto">
  <name>Task 2: Log fallback slug in PROJECT.md (only if non-default slug used)</name>
  <files>.planning/PROJECT.md</files>
  <read_first>
    - /Users/cary/Development/ai-development/ps-transcribe/.planning/PROJECT.md (read current state — target §"Current Milestone: v1.1 Marketing Website" and Key Decisions table)
    - Resume signal from Task 1 — extract the actual production URL; only execute this task if `fallback-slug:` is set (i.e., the Vercel slug is NOT `ps-transcribe`)
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-CONTEXT.md §decisions D-08 (fallback contract: "If the slug is taken, fall back to `ps-transcribe-web` (or similar) and log the real URL in PROJECT.md before phase 11 is marked done")
  </read_first>
  <action>
**Conditional execution:** Skip this task entirely if Task 1's resume signal was `vercel-ready: https://ps-transcribe.vercel.app` (the canonical slug was available).

**If and only if** Task 1 reported a fallback slug:

Edit `.planning/PROJECT.md` to log the real production URL. Two edits:

**Edit 1 — Update the milestone-goal sentence in §"Current Milestone: v1.1 Marketing Website":**

Find the line:
> **Goal:** Build and ship a marketing website at `ps-transcribe.vercel.app` …

Replace `ps-transcribe.vercel.app` with the actual slug (e.g., `ps-transcribe-web.vercel.app`). Keep the rest of the sentence verbatim.

**Edit 2 — Append to Key Decisions table:**

Add a new row at the bottom of the `| Decision | Rationale | Outcome |` table:

| Vercel project slug = `<fallback-slug>` | Canonical `ps-transcribe` slug unavailable globally; fallback keeps subdomain close to project name | -- Validated phase 11 |

Also update the v1.1 milestone context in any other sections of PROJECT.md that embed the literal string `ps-transcribe.vercel.app` (use grep to find them): replace those occurrences with the fallback slug too. Likely locations based on current file: §"Current Milestone", possibly §"Scope boundaries".

Do NOT edit other planning files (ROADMAP.md, STATE.md, REQUIREMENTS.md) in this task — those are owned by `/gsd-transition` at phase completion. The PROJECT.md edit is the single canonical location for the URL per D-08.

Do NOT edit the Next.js source (layout.tsx `metadataBase`, sitemap.ts url, robots.ts sitemap url, manifest.ts) in this task — if the slug changed, those need to change too and should be handled via an orchestrator-level decision (potentially a revision to Plan 02) since they affect the rendered output of every probe in Task 3. **If a fallback slug was used, stop this task after the PROJECT.md edit and escalate to the orchestrator** noting that Plan 02 metadata URLs must be revised before Task 3 probes can pass.
  </action>
  <verify>
    <automated>cd /Users/cary/Development/ai-development/ps-transcribe && if grep -q "ps-transcribe-web\|ps-transcribe-site" .planning/PROJECT.md 2>/dev/null; then grep -q "<fallback-slug>.vercel.app" .planning/PROJECT.md && grep -q "Vercel project slug" .planning/PROJECT.md; else echo "no fallback needed — skipping"; fi</automated>
  </verify>
  <acceptance_criteria>
    - **If Task 1 reported the canonical slug (`ps-transcribe.vercel.app`):** This task is a no-op. Acceptance = skip marker documented in summary. No file changes.
    - **If Task 1 reported a fallback slug:**
      - `.planning/PROJECT.md` §"Current Milestone" Goal sentence references the fallback slug (e.g., `ps-transcribe-web.vercel.app`), NOT `ps-transcribe.vercel.app`
      - Key Decisions table gains a new row naming the fallback slug and its outcome tagged "Validated phase 11"
      - Every pre-existing literal `ps-transcribe.vercel.app` in PROJECT.md has been replaced with the fallback (verify: `grep -c 'ps-transcribe\.vercel\.app' .planning/PROJECT.md` returns 0 after edit)
      - No other planning files were edited (verify: `git diff --name-only` shows only `.planning/PROJECT.md` in the diff)
      - Orchestrator escalation issued noting Plan 02 metadata URLs need revision before probes pass
  </acceptance_criteria>
  <done>Either no-op (canonical slug acquired) or PROJECT.md updated with fallback slug and escalation raised.</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 3: Verify production deploy + run 18-probe validation suite</name>
  <files>(none — read-only verification)</files>
  <read_first>
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-VALIDATION.md §"Requirement Probe Suite" (full 18-probe table — every probe is a deterministic curl/file-check/e2e command)
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-RESEARCH.md §"Validation Architecture" → "Phase Requirements → Test Map" (same 18 probes with expected outputs)
    - Resume signal from Task 1 — production URL to probe against (use this URL, not a hard-coded `ps-transcribe.vercel.app` if a fallback slug was used)
    - .planning/phases/11-website-scaffolding-vercel-deployment/11-CONTEXT.md §decisions D-09 (D-09 verification is the one probe that requires waiting for a Swift-only commit; this is documented as "manual" in validation and may legitimately be verified in a follow-up commit cycle rather than blocking phase exit)
  </read_first>
  <what-built>
    Plan 01 shipped `/website/` scaffold + .gitignore. Plan 02 shipped content + metadata files. Task 1 of this plan connected Vercel. Now all 18 validation probes must run green against the actual production deploy to prove SITE-02/03/04 are earned. Tasks 1-2 of the 18 probe table are repo-local file checks (already green after Plan 01); tasks 3-6 are more file checks (green after Plan 01/02); tasks 7-17 are HTTP probes against the live Vercel URL; task 18 is the Swift guardrail.
  </what-built>
  <how-to-verify>
Use the production URL from Task 1's resume signal. If Task 1 reported `https://ps-transcribe.vercel.app`, every command below is verbatim. If Task 1 reported a fallback slug, replace `ps-transcribe.vercel.app` with the actual slug in every probe (AND confirm Plan 02 metadata URLs were revised per Task 2's escalation — otherwise probes 14 and 15 will fail because the rendered sitemap/robots contents still point at the canonical URL).

Run this probe suite in order; report pass/fail for each. This IS the phase gate.

**Group A — Repo-local file checks (should already be green from Plans 01 + 02, re-run for safety):**

```bash
cd /Users/cary/Development/ai-development/ps-transcribe

# Probe 1 — SITE-01: Next.js App Router scaffold exists
test -f website/package.json && test -f website/tsconfig.json && test -d website/src/app && echo "PROBE-1: PASS"

# Probe 2 — SITE-01: TypeScript strict compiles cleanly
cd website && pnpm build && echo "PROBE-2: PASS" ; cd ..

# Probe 3 — SITE-01: @/* alias maps to src/*
grep -q '"@/\*": \["./src/\*"\]' website/tsconfig.json && echo "PROBE-3: PASS"

# Probe 4 — SITE-01: Node 22 pinned in both places
test "$(cat website/.nvmrc)" = "22" && \
  node -e "const p=require('./website/package.json'); if(!/22/.test(p.engines?.node)) process.exit(1)" && \
  echo "PROBE-4: PASS"

# Probe 5 — SITE-01: pnpm is the sole package manager
test -f website/pnpm-lock.yaml && \
  test ! -f website/package-lock.json && \
  test ! -f website/yarn.lock && \
  echo "PROBE-5: PASS"

# Probe 10 — SITE-05: .gitignore excludes build artifacts
grep -q '^website/\.next/$' .gitignore && \
  grep -q '^website/node_modules/$' .gitignore && \
  echo "PROBE-10: PASS"

# Probe 11 — SITE-05: No build artifacts tracked in git
test "$(git ls-files website/.next website/node_modules 2>/dev/null | wc -l | tr -d ' ')" = "0" && \
  echo "PROBE-11: PASS"

# Probe 18 (guardrail) — Swift package still builds
cd PSTranscribe && swift build && echo "PROBE-18: PASS" ; cd ..
```

**Group B — Vercel integration probes (require a push to main + Vercel deploy to have happened):**

```bash
# Probe 6 — SITE-02: Push triggers Vercel build (verifies last commit has a Vercel status check)
gh api repos/:owner/ps-transcribe/commits/$(git rev-parse HEAD)/status \
  --jq '.statuses[] | select(.context|startswith("Vercel")) | .state' \
  | grep -q '^success$' && \
  echo "PROBE-6: PASS"

# Probe 7 — SITE-03: PR preview URL (human-verify — open any PR touching /website and confirm Vercel bot comment)
# This is a manual check. Open https://github.com/<owner>/ps-transcribe/pulls
# Confirm the most recent PR that touched /website shows a Vercel bot comment with a preview URL of the form:
#   https://ps-transcribe-git-<branch>-<user>.vercel.app
echo "PROBE-7: MANUAL — check GitHub PR for Vercel bot comment"
```

**Group C — Production HTTP probes (run against the actual production URL from Task 1):**

```bash
# Set the production URL (adjust if Task 1 reported a fallback)
PROD=https://ps-transcribe.vercel.app

# Probe 8 — SITE-04: Production reachable
curl -sfI "$PROD" | head -1 | grep -qE 'HTTP/[12](\.[01])? 200' && echo "PROBE-8: PASS"

# Probe 9 — SITE-04: Production renders Chronicle placeholder
curl -s "$PROD" | grep -q 'PS Transcribe' && echo "PROBE-9: PASS"

# Probe 13 — D-15: All three fonts load on production (check for CSS vars in HTML)
COUNT=$(curl -s "$PROD" | grep -oE -- '--font-(inter|spectral|jetbrains-mono)' | sort -u | wc -l | tr -d ' ')
test "$COUNT" = "3" && echo "PROBE-13: PASS (fonts=$COUNT)"

# Probe 14 — D-17: robots.txt served
curl -sfI "$PROD/robots.txt" | head -1 | grep -qE 'HTTP/[12](\.[01])? 200' && echo "PROBE-14: PASS"

# Probe 15 — D-17: sitemap.xml served with correct entry
curl -sf "$PROD/sitemap.xml" | grep -q "<loc>$PROD</loc>" && echo "PROBE-15: PASS"

# Probe 16 — D-17: manifest served
curl -sfI "$PROD/manifest.webmanifest" | head -1 | grep -qE 'HTTP/[12](\.[01])? 200' && echo "PROBE-16: PASS"

# Probe 17 — D-17: OG image served
curl -sfI "$PROD/opengraph-image.png" | head -1 | grep -qE 'HTTP/[12](\.[01])? 200' && echo "PROBE-17: PASS"

# Probe (extra from RESEARCH) — D-17: Favicon served
curl -sfI "$PROD/icon.png" | head -1 | grep -qE 'HTTP/[12](\.[01])? 200' && echo "PROBE-ICON: PASS"
```

**Group D — D-09 Ignored Build Step verification (deferred-OK):**

```bash
# Probe 12 — D-09: Swift-only commits don't redeploy
# This is a manual check that can only be verified AFTER a Swift-only commit lands on main post-setup.
# At phase 11 close, either:
#   (a) A Swift-only commit has already landed (check Vercel deployments list — should show "Ignored Build Step" / Canceled), OR
#   (b) No Swift-only commit has landed yet — schedule verification for the first Swift-only commit in phases 12+ and document in SUMMARY.
#
# The configuration is correct if Task 1 Step 8 was completed correctly. Confidence in the command itself is HIGH per RESEARCH.md Pitfall 2.
echo "PROBE-12: DEFERRED (verified on next Swift-only commit to main)"
```

**Overall result:** All 18 probes (minus PROBE-7 manual and PROBE-12 deferred) must return PASS. Any RED probe blocks phase exit.

**Present the completion summary to Claude with:**
- Pass/fail/manual status for all 18 probes
- Raw `curl -sI` headers for each of the 5 production routes (confirms Vercel response headers, cache-control, content-type)
- Link to the production URL and the first PR preview URL (for SITE-03 manual record)
- Any probes that failed + their raw output
  </how-to-verify>
  <resume-signal>
    Reply with `probes-green` if all 16 non-deferred probes passed. Reply with `probes-red: <probe-numbers>` with the failing probe numbers otherwise. If `probes-red`, include the raw curl/grep output so Claude can diagnose and route a gap-closure plan.
  </resume-signal>
  <action>
    Human (or Claude with access to the production URL) runs the 18-probe validation suite captured in `<how-to-verify>` above. For Group A (repo-local) and Group C (HTTP) probes, Claude can execute directly after receiving the production URL from Task 1. Group B probe 7 (PR preview URL) is human-verify only. Probe 12 (Ignored Build Step behavior) is deferred until the first Swift-only commit lands post-setup. Record pass/fail for all 18 in the SUMMARY.
  </action>
  <verify>
    <automated>bash -c 'cd /Users/cary/Development/ai-development/ps-transcribe &amp;&amp; test -f website/package.json &amp;&amp; test -d website/src/app &amp;&amp; grep -q "website/.next/" .gitignore &amp;&amp; curl -sfI https://ps-transcribe.vercel.app | head -1 | grep -qE "HTTP/[12](\.[01])? 200" &amp;&amp; curl -s https://ps-transcribe.vercel.app | grep -q "PS Transcribe" &amp;&amp; curl -sfI https://ps-transcribe.vercel.app/robots.txt | head -1 | grep -qE "HTTP/[12](\.[01])? 200" &amp;&amp; curl -sfI https://ps-transcribe.vercel.app/sitemap.xml | head -1 | grep -qE "HTTP/[12](\.[01])? 200" &amp;&amp; curl -sfI https://ps-transcribe.vercel.app/manifest.webmanifest | head -1 | grep -qE "HTTP/[12](\.[01])? 200" &amp;&amp; curl -sfI https://ps-transcribe.vercel.app/opengraph-image.png | head -1 | grep -qE "HTTP/[12](\.[01])? 200" &amp;&amp; curl -sfI https://ps-transcribe.vercel.app/icon.png | head -1 | grep -qE "HTTP/[12](\.[01])? 200"'</automated>
  </verify>
  <done>All 16 non-deferred probes from 11-VALIDATION.md return PASS. User has confirmed Probe 7 manually (PR preview URL). Probe 12 is scheduled for first Swift-only commit in phase 12+.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| GitHub repo → Vercel | OAuth GitHub App grants Vercel read access to the repo and write access to status checks + PR comments |
| Vercel build env → production URL | Build output served publicly at `*.vercel.app`; preview URLs publicly accessible if URL is known |
| User → Vercel dashboard | Human-entered project settings (project name, Root Directory, Ignored Build Step) become persistent deploy configuration |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-11-03-01 | Information disclosure | Vercel preview URL leak of pre-merge content (preview URLs are guessable-random, not indexed, but publicly accessible if URL known) | accept | Phase 11 content is a placeholder — no unreleased features or internal info beyond what's already on GitHub. Preview URLs are not indexed by default (per RESEARCH.md §Security Domain). Phases 12+ that might ship non-public drafts should enable Vercel Deployment Protection at that time. |
| T-11-03-02 | Tampering | Misconfigured Ignored Build Step causes every deploy to silently skip (wrong path per RESEARCH.md Pitfall 2) | mitigate | Task 1 Step 8 calls out the exact correct command (`git diff HEAD^ HEAD --quiet -- .`) and the wrong one (`git diff HEAD^ HEAD --quiet -- website`). Task 3 Probe 6 verifies the FIRST deploy produced a Vercel status check on the HEAD commit — if Ignored Build Step were wrong-on-arrival, probe 6 would fail. Followup: phase 12+ should include a deliberate Swift-only commit to verify ignore behavior (Probe 12 deferred to then). |
| T-11-03-03 | Elevation of privilege | Vercel GitHub App scope creep — if the user accidentally grants repo-write during OAuth | accept | Vercel GitHub App default scope is read-only for contents + write for statuses/PR comments. No mitigation action needed if user accepts default permissions during Task 1 Step 1 OAuth flow. |
| T-11-03-04 | Information disclosure | Production URL fallback (`ps-transcribe-web.vercel.app`) leaks internal project-name convention | accept | No sensitive info in slug — it's a public marketing site. Fallback scenarios documented in PROJECT.md (via Task 2). |
| T-11-03-05 | Tampering | Someone overrides Install Command in Vercel dashboard and forces oldest pnpm (RESEARCH.md Pitfall 6) | mitigate | Task 1 Step 5 explicitly says "Leave ALL defaults" and flags the Install Command override as the Pitfall-6 trap. First-deploy build logs should show `pnpm 10.x.x`; if they show `pnpm 6.x`, the dashboard override was flipped and must be cleared. |

**Out of scope (public marketing placeholder):** V2 Authentication, V3 Session Management, V4 Access Control, V5 Input Validation, V6 Cryptography per RESEARCH.md §Security Domain.
</threat_model>

<verification>
- Vercel project exists and is linked to the ps-transcribe GitHub repo
- Project settings show: Root Directory = `website`, Framework = Next.js, Install Command default (no override), Node.js version = 22.x in build logs, Ignored Build Step = `git diff HEAD^ HEAD --quiet -- .`
- First production deploy status = Ready
- `curl -sfI https://ps-transcribe.vercel.app` (or fallback) returns 200
- Page content includes `PS Transcribe` and all three font CSS variables
- `/sitemap.xml`, `/robots.txt`, `/manifest.webmanifest`, `/opengraph-image.png`, `/icon.png` all return 200
- 16 of 18 probes PASS; 2 are manual/deferred (PROBE-7 PR preview, PROBE-12 Ignored Build Step verification)
- Swift package still builds (PROBE-18)
</verification>

<success_criteria>
Phase 11 complete when:
1. Vercel dashboard shows project `ps-transcribe` (or fallback) connected to the GitHub repo with Root Directory = `website`
2. `git diff HEAD^ HEAD --quiet -- .` is set as the Ignored Build Step
3. `https://ps-transcribe.vercel.app` (or fallback) returns 200 and renders the Chronicle placeholder from Plan 02
4. Three font CSS variables (`--font-inter`, `--font-spectral`, `--font-jetbrains-mono`) appear in the production HTML
5. Metadata routes `/sitemap.xml`, `/robots.txt`, `/manifest.webmanifest`, `/opengraph-image.png`, `/icon.png`, `/apple-icon.png` all serve 200
6. PR preview URLs get a Vercel bot comment (manual verify)
7. PROJECT.md is either unchanged (canonical slug used) or updated with the real fallback URL
8. Swift package still builds
9. All 16 non-deferred probes from 11-VALIDATION.md pass
</success_criteria>

<output>
After completion, create `.planning/phases/11-website-scaffolding-vercel-deployment/11-03-SUMMARY.md` documenting:
- Production URL actually in use (canonical or fallback)
- Vercel project settings confirmed (Root Directory, Node version from build logs, Ignored Build Step command, Install/Build Command status)
- Pass/fail status for every probe 1-18 with raw output for any reds
- First-deploy build log excerpt showing `pnpm 10.x` detected (addresses Pitfall 6) and Node 22.x used (addresses A1)
- First PR preview URL format observed (for SITE-03 manual verification)
- Deferred probes list (PROBE-12 Ignored Build Step behavior) with a scheduled verification owner (next Swift-only commit in phase 12 or beyond)
- `requirements_completed: [SITE-02, SITE-03, SITE-04]`
</output>
