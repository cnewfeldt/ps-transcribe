#!/usr/bin/env bash
# scripts/lint-summaries.sh
#
# Lint check for SUMMARY.md frontmatter — enforces the Phase 22 canonical contract.
#
# Locks (.planning/milestones/v1.3-phases/22-process-frontmatter-standard/22-CONTEXT.md):
#   D-01: canonical key is `requirements-completed` (hyphen).
#   D-04: empty list `[]` is valid.
#   D-05: sibling fields (requirements-scaffolded, requirements-supports,
#         requirements-touched-but-not-completed) are deprecated.
#   D-07: lint depth = presence + subset (SUMMARY.requirements-completed ⊆ PLAN.requirements).
#   D-10: implementation = bash + yq only (no other interpreters or package managers).
#
# Checks:
#   C1 (FAIL):  SUMMARY frontmatter contains `requirements-completed:` key.
#   C2 (FAIL):  SUMMARY frontmatter does NOT contain `requirements_completed:` (underscore form).
#   C3 (FAIL):  Every ID in SUMMARY.requirements-completed appears in sibling PLAN.requirements.
#               (Skipped if sibling PLAN.md is missing — emits notice.)
#   C4 (WARN):  SUMMARY frontmatter contains a deprecated sibling field.
#
# Exit codes:
#   0  no failures (warnings allowed)
#   1  one or more failures
#   2  yq not installed
#
# Usage:
#   bash scripts/lint-summaries.sh           # scan default tree (.planning/milestones/)
#   bash scripts/lint-summaries.sh --help    # show this help
#   bash scripts/lint-summaries.sh path/to/file-SUMMARY.md [more files...]
#     # scan only the listed files (used by CI path-filtered runs)

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
DEFAULT_ROOT=".planning/milestones"

RED=$'\033[0;31m'
YELLOW=$'\033[0;33m'
GREEN=$'\033[0;32m'
DIM=$'\033[2m'
RESET=$'\033[0m'

print_help() {
  sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  print_help
  exit 0
fi

if ! command -v yq >/dev/null 2>&1; then
  printf '%sERROR%s yq is not installed. Install with: brew install yq\n' "$RED" "$RESET" >&2
  exit 2
fi

# Collect target files.
declare -a TARGETS=()
if [[ $# -gt 0 ]]; then
  TARGETS=("$@")
else
  while IFS= read -r -d '' f; do
    TARGETS+=("$f")
  done < <(find "$DEFAULT_ROOT" -type f -name '*-SUMMARY.md' -print0 2>/dev/null)
fi

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  printf '%sNOTICE%s no SUMMARY files found under %s/\n' "$DIM" "$RESET" "$DEFAULT_ROOT"
  exit 0
fi

fail_count=0
warn_count=0
file_count=0

yq_fm() {
  # Read a frontmatter value with explicit --front-matter=extract.
  # Returns empty string and exit 0 when yq fails (e.g., the archive contains
  # legacy SUMMARYs whose YAML has unquoted colons that yq rejects).
  yq --front-matter=extract eval "$1" "$2" 2>/dev/null || true
}

fm_has_key_grep() {
  # Fallback presence check: scan the frontmatter block (between the first
  # two `---` lines) for the literal key. Used when yq parse fails.
  local file="$1"
  local key="$2"
  awk -v k="^${key}:" '/^---$/{n++; if(n==2) exit} n==1 && $0 ~ k{found=1} END{exit !found}' "$file"
}

check_summary() {
  local summary="$1"
  local plan="${summary%-SUMMARY.md}-PLAN.md"
  local rel_summary
  rel_summary="${summary#./}"

  # C2 — underscore form forbidden (raw grep on frontmatter; cheaper than yq).
  if awk '/^---$/{n++; if(n==2) exit} n==1 && /^requirements_completed:/' "$summary" | grep -q .; then
    printf '%s[FAIL C2]%s %s: contains deprecated underscore key `requirements_completed:` — rename to `requirements-completed:` (D-01).\n' "$RED" "$RESET" "$rel_summary"
    ((fail_count++)) || true
  fi

  # C1 — presence of canonical key. Use yq when it can parse, fall back to grep.
  local has_canonical
  has_canonical="$(yq_fm 'has("requirements-completed")' "$summary")"
  if [[ -z "$has_canonical" ]]; then
    # yq parse failed — fall back to grep-based presence check.
    if fm_has_key_grep "$summary" "requirements-completed"; then
      has_canonical="true"
    else
      has_canonical="false"
    fi
  fi
  if [[ "$has_canonical" != "true" ]]; then
    printf '%s[FAIL C1]%s %s: missing `requirements-completed:` key (D-07).\n' "$RED" "$RESET" "$rel_summary"
    ((fail_count++)) || true
    # No point continuing C3 if C1 failed.
  else
    # C3 — subset check.
    if [[ -f "$plan" ]]; then
      # Extract IDs from each. yq emits one per line; empty list → no output.
      local summary_ids plan_ids
      summary_ids="$(yq_fm '.["requirements-completed"][]' "$summary" 2>/dev/null || true)"
      plan_ids="$(yq_fm '.requirements[]' "$plan" 2>/dev/null || true)"

      if [[ -n "$summary_ids" ]]; then
        local missing=()
        while IFS= read -r id; do
          [[ -z "$id" ]] && continue
          if ! grep -Fxq "$id" <<< "$plan_ids"; then
            missing+=("$id")
          fi
        done <<< "$summary_ids"

        if [[ ${#missing[@]} -gt 0 ]]; then
          printf '%s[FAIL C3]%s %s: requirement IDs not in sibling PLAN.requirements: %s (D-07 subset).\n' \
            "$RED" "$RESET" "$rel_summary" "${missing[*]}"
          ((fail_count++)) || true
        fi
      fi
    else
      printf '%s[NOTE]%s %s: sibling PLAN.md not found (%s) — C3 subset check skipped.\n' \
        "$DIM" "$RESET" "$rel_summary" "${plan#./}"
    fi
  fi

  # C4 — deprecated sibling fields (warning). Falls back to grep on yq parse failure.
  local has_siblings
  has_siblings="$(yq_fm 'has("requirements-scaffolded") or has("requirements-supports") or has("requirements-touched-but-not-completed")' "$summary")"
  if [[ -z "$has_siblings" ]]; then
    if fm_has_key_grep "$summary" "requirements-scaffolded" \
      || fm_has_key_grep "$summary" "requirements-supports" \
      || fm_has_key_grep "$summary" "requirements-touched-but-not-completed"; then
      has_siblings="true"
    else
      has_siblings="false"
    fi
  fi
  if [[ "$has_siblings" == "true" ]]; then
    printf '%s[WARN C4]%s %s: contains deprecated sibling field — strip per Plan 22-06 migration (D-05/D-06).\n' \
      "$YELLOW" "$RESET" "$rel_summary"
    ((warn_count++)) || true
  fi

  ((file_count++)) || true
}

for f in "${TARGETS[@]}"; do
  check_summary "$f"
done

printf '\n%d SUMMARY files checked, %d failures, %d warnings\n' "$file_count" "$fail_count" "$warn_count"

if [[ $fail_count -gt 0 ]]; then
  printf '%sFAILED%s — see [FAIL ...] lines above.\n' "$RED" "$RESET" >&2
  exit 1
fi

printf '%sOK%s — no failures.\n' "$GREEN" "$RESET"
exit 0
