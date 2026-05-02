#!/usr/bin/env bash
# scripts/migrate-summary-frontmatter.sh
#
# ONE-SHOT migration of archived SUMMARY.md frontmatter to the Phase 22 canonical form.
# Per D-13: this script is executed exactly once, then `git rm`'d. Reproducibility
# lives in git history (this commit captures the script content; the next commit
# captures the SUMMARY edits + the script removal).
#
# Locks (.planning/milestones/v1.3-phases/22-process-frontmatter-standard/22-CONTEXT.md):
#   D-01: canonical key is `requirements-completed` (hyphen).
#   D-06: stripped sibling fields are re-attached as inline YAML comments above
#         `requirements-completed:` in the format
#         `# <sibling-name>: [<ids>]  # historical sibling field, retired in Phase 22`.
#   D-13: one-shot script — git rm in the same commit that produces the migration.
#         (See "Single migration commit on disk" deviation note in 22-06-SUMMARY.md
#          — the script is committed first so the migration commit can show it
#          removed without losing the script source from history.)
#   D-14: missing-field SUMMARYs receive `requirements-completed:` copied verbatim from
#         the sibling PLAN.md `requirements:` field.
#
# Operations (per group):
#   Group A — rename `requirements_completed:` → `requirements-completed:` (7 files).
#   Group B — strip sibling field, re-attach as inline comment (6 files).
#   Group C — add missing field by copying sibling PLAN.requirements (5 files).

set -euo pipefail

if ! command -v yq >/dev/null 2>&1; then
  echo "ERROR: yq is required (brew install yq)" >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# ---- Group A: rename underscore → hyphen ----
GROUP_A=(
  ".planning/milestones/v1.2-phases/16-foundation/16-01-SUMMARY.md"
  ".planning/milestones/v1.2-phases/16-foundation/16-02-SUMMARY.md"
  ".planning/milestones/v1.2-phases/16-foundation/16-03-SUMMARY.md"
  ".planning/milestones/v1.2-phases/16-foundation/16-04-SUMMARY.md"
  ".planning/milestones/v1.2-phases/18-hotkey-dictation-plain-folder-output/18-09-SUMMARY.md"
  ".planning/milestones/v1.2-phases/18.1-shared-save-destinations-local-file/18.1-07-SUMMARY.md"
  ".planning/milestones/v1.2-phases/18.1-shared-save-destinations-local-file/18.1-08-SUMMARY.md"
)

rename_underscore() {
  local f="$1"
  if grep -q '^requirements_completed:' "$f"; then
    perl -i -pe 's/^requirements_completed:/requirements-completed:/' "$f"
    echo "[A] renamed underscore key in $f"
  else
    echo "[A] (idempotent) $f already canonical"
  fi
}

# ---- Group B: strip sibling, re-attach as inline comment ----
GROUP_B=(
  ".planning/milestones/v1.2-phases/18-hotkey-dictation-plain-folder-output/18-01-SUMMARY.md|requirements-scaffolded"
  ".planning/milestones/v1.2-phases/18-hotkey-dictation-plain-folder-output/18-02-SUMMARY.md|requirements-scaffolded"
  ".planning/milestones/v1.2-phases/18-hotkey-dictation-plain-folder-output/18-03-SUMMARY.md|requirements-supports"
  ".planning/milestones/v1.2-phases/18-hotkey-dictation-plain-folder-output/18-04-SUMMARY.md|requirements-supports"
  ".planning/milestones/v1.2-phases/18-hotkey-dictation-plain-folder-output/18-05-SUMMARY.md|requirements-supports"
  ".planning/milestones/v1.2-phases/18-hotkey-dictation-plain-folder-output/18-07-SUMMARY.md|requirements-touched-but-not-completed"
)

strip_sibling() {
  local entry="$1"
  local f="${entry%%|*}"
  local sibling="${entry##*|}"
  local short_name="${sibling#requirements-}"

  if ! grep -q "^${sibling}:" "$f"; then
    echo "[B] (idempotent) ${sibling} already stripped from $f"
    return 0
  fi

  local sibling_line
  sibling_line="$(grep "^${sibling}:" "$f" | head -1)"

  local sibling_value
  sibling_value="$(printf '%s\n' "$sibling_line" | sed -nE 's/^[^:]+:[[:space:]]*(\[[^]]*\]).*/\1/p')"

  if [[ -z "$sibling_value" ]]; then
    local yq_value
    yq_value="$(yq --front-matter=extract eval ".[\"${sibling}\"]" "$f" 2>/dev/null || true)"
    if [[ -z "$yq_value" || "$yq_value" == "null" ]]; then
      sibling_value="[]"
    else
      sibling_value="$(printf '[%s]' "$(echo "$yq_value" | sed -E 's/^- //; s/^"(.*)"$/\1/' | paste -sd ',' - | sed 's/,/, /g')")"
    fi
  fi

  local comment_line="# ${short_name}: ${sibling_value}  # historical sibling field, retired in Phase 22"

  COMMENT_LINE="$comment_line" SIBLING="$sibling" perl -i -pe '
    BEGIN { $c = $ENV{COMMENT_LINE}; $s = $ENV{SIBLING}; $inserted = 0; }
    if (!$inserted && /^requirements-completed:/) {
      print "$c\n";
      $inserted = 1;
    }
  ' "$f"
  perl -i -ne "print unless /^${sibling}:/" "$f"
  echo "[B] stripped ${sibling} from $f → comment: ${comment_line}"
}

# ---- Group C: add missing field by copying sibling PLAN.requirements ----
GROUP_C=(
  ".planning/milestones/v1.2-phases/17-model-auto-update/17-01-SUMMARY.md"
  ".planning/milestones/v1.2-phases/17-model-auto-update/17-02-SUMMARY.md"
  ".planning/milestones/v1.2-phases/17-model-auto-update/17-03-SUMMARY.md"
  ".planning/milestones/v1.2-phases/17-model-auto-update/17-05-SUMMARY.md"
  ".planning/milestones/v1.2-phases/18.1-shared-save-destinations-local-file/18.1-09-SUMMARY.md"
)

add_missing_field() {
  local summary="$1"
  local plan="${summary%-SUMMARY.md}-PLAN.md"

  if grep -q '^requirements-completed:' "$summary"; then
    echo "[C] (idempotent) $summary already has requirements-completed:"
    return 0
  fi

  local payload
  if [[ ! -f "$plan" ]]; then
    echo "[C] WARNING: sibling PLAN.md missing for $summary — emitting empty list" >&2
    payload="[]"
  else
    # Prefer the original inline-flow form from the PLAN's frontmatter (preserves
    # author spacing and avoids yq's habit of re-bracketing already-bracketed values).
    local inline
    inline="$(awk '/^---$/{n++; if(n==2) exit} n==1 && /^requirements:/' "$plan" | sed -nE 's/^requirements:[[:space:]]*(\[[^]]*\]).*/\1/p' | head -1)"
    if [[ -n "$inline" ]]; then
      payload="$inline"
    else
      local raw
      raw="$(yq --front-matter=extract eval '.requirements' "$plan" 2>/dev/null || true)"
      if [[ -z "$raw" || "$raw" == "null" ]]; then
        payload="[]"
      elif [[ "$raw" == \[*\] ]]; then
        payload="$raw"
      else
        payload="$(printf '[%s]' "$(echo "$raw" | sed -E 's/^- //; s/^"(.*)"$/\1/' | paste -sd ',' - | sed 's/,/, /g')")"
      fi
    fi
  fi

  INSERT_LINE="requirements-completed: ${payload}" perl -i -pe '
    BEGIN { $line = $ENV{INSERT_LINE}; $count = 0; $inserted = 0; }
    if (/^---$/) {
      $count++;
      if ($count == 2 && !$inserted) {
        print "$line\n";
        $inserted = 1;
      }
    }
  ' "$summary"
  echo "[C] added requirements-completed: ${payload} to $summary (from ${plan#./})"
}

echo "=== Group A: rename underscore key → hyphen key ==="
for f in "${GROUP_A[@]}"; do
  rename_underscore "$f"
done

echo
echo "=== Group B: strip sibling field, re-attach as comment ==="
for entry in "${GROUP_B[@]}"; do
  strip_sibling "$entry"
done

echo
echo "=== Group C: add missing field from sibling PLAN.md ==="
for f in "${GROUP_C[@]}"; do
  add_missing_field "$f"
done

echo
echo "Migration complete. Run 'bash scripts/lint-summaries.sh' to verify."
