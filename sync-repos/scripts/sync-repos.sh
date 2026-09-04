#!/usr/bin/env bash
# sync-repos.sh — sync all git repos in the workspace to their non-prod branch
# Usage:
#   bash sync-repos.sh              # sync all repos
#   bash sync-repos.sh --dry-run    # report only, no changes
#   bash sync-repos.sh --repo NAME  # sync a single repo by directory name

set -euo pipefail

DRY_RUN=false
TARGET_REPO=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --repo)    TARGET_REPO="$2"; shift ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
  shift
done

WORKSPACE_ROOT="$(pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RESULTS=()

# ---------------------------------------------------------------
# Determine the non-prod branch for a given repo directory.
# Reads remote branches and excludes main/master.
# Falls back to the first non-main/master branch found.
# Returns empty string if none found (caller handles this).
# ---------------------------------------------------------------
get_nonprod_branch() {
  local repo_dir="$1"
  local preferred=("develop" "staging" "pre-prod" "preprod" "uat" "test")

  # fetch remote branches quietly
  git -C "$repo_dir" fetch --quiet 2>/dev/null || true

  local remote_branches
  remote_branches=$(git -C "$repo_dir" branch -r 2>/dev/null \
    | sed 's|origin/||' \
    | tr -d ' ' \
    | grep -vE '^HEAD$|^main$|^master$' \
    || true)

  for branch in "${preferred[@]}"; do
    if echo "$remote_branches" | grep -qx "$branch"; then
      echo "$branch"
      return
    fi
  done

  # no preferred branch found — return empty so the agent can resolve it
  echo ""
}

# ---------------------------------------------------------------
# Sync a single repo
# ---------------------------------------------------------------
sync_repo() {
  local repo_dir="$1"
  local repo_name
  repo_name="$(basename "$repo_dir")"

  local target_branch
  target_branch="$(get_nonprod_branch "$repo_dir")"

  if [[ -z "$target_branch" ]]; then
    RESULTS+=("[UNKNOWN] $repo_name | Could not determine non-prod branch -- needs manual discovery")
    return
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    RESULTS+=("[DRY RUN] $repo_name | would sync to '$target_branch'")
    return
  fi

  # stash any uncommitted changes
  local stash_msg="sync-repos auto-stash $TIMESTAMP"
  local stash_output
  stash_output=$(git -C "$repo_dir" stash push -m "$stash_msg" 2>&1 || true)
  local stashed=false
  if echo "$stash_output" | grep -q "Saved working directory"; then
    stashed=true
  fi

  # checkout and pull
  if git -C "$repo_dir" checkout "$target_branch" --quiet 2>/dev/null; then
    if git -C "$repo_dir" pull --ff-only --quiet 2>/dev/null; then
      if [[ "$stashed" == "true" ]]; then
        RESULTS+=("[STASHED] $repo_name | synced to '$target_branch' -- run 'git stash pop' to restore changes")
      else
        RESULTS+=("[OK]      $repo_name | '$target_branch' is up to date")
      fi
    else
      RESULTS+=("[ERROR]   $repo_name | pull --ff-only failed on '$target_branch' (diverged or conflict)")
    fi
  else
    RESULTS+=("[ERROR]   $repo_name | could not checkout '$target_branch'")
  fi
}

# ---------------------------------------------------------------
# Main
# ---------------------------------------------------------------
for dir in "$WORKSPACE_ROOT"/*/; do
  [[ -d "$dir/.git" ]] || continue
  repo_name="$(basename "$dir")"
  [[ -n "$TARGET_REPO" && "$repo_name" != "$TARGET_REPO" ]] && continue
  sync_repo "$dir"
done

# Print results table
echo ""
echo "--- sync-repos result ---"
for line in "${RESULTS[@]}"; do
  echo "  $line"
done
echo ""
