#!/usr/bin/env bash
# signal-commit/scripts/commit.sh
# Handles git mechanics for /signal-commit.
# The AGENT generates the commit message and passes it as an argument.
# This script handles: staging, committing, stat reporting, all flags, edge cases.
#
# Usage:
#   commit.sh [--draft] [--split] [--push] [--dry] [--] "commit message"
#   commit.sh [--draft] [--split] [--push] [--dry]       (message on stdin)

set -euo pipefail

# ── Flag parsing ──────────────────────────────────────────────────────────────
DRAFT=0
SPLIT=0
PUSH=0
DRY=0
MSG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --draft) DRAFT=1; shift ;;
    --split) SPLIT=1; shift ;;
    --push)  PUSH=1;  shift ;;
    --dry)   DRY=1;   shift ;;
    --)      shift; MSG="$*"; break ;;
    -*)      echo "✗ unknown flag: $1"; exit 1 ;;
    *)       MSG="$*"; break ;;
  esac
done

# Fall back to stdin if no positional message
if [[ -z "$MSG" && ! -t 0 ]]; then
  MSG=$(cat)
fi

# ── Pre-flight checks ─────────────────────────────────────────────────────────
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "✗ not a git repository"
  exit 1
fi

# Check for unresolved merge conflicts
if git diff --check 2>/dev/null | grep -q 'leftover conflict marker'; then
  CONFLICT_FILES=$(git diff --check 2>/dev/null | grep 'leftover conflict marker' | awk -F: '{print $1}' | sort -u | tr '\n' ' ')
  echo "✗ merge conflicts in ${CONFLICT_FILES% } — resolve before committing"
  exit 1
fi

# ── Diff snapshot ─────────────────────────────────────────────────────────────
STAGED=$(git diff --staged --name-only 2>/dev/null)
UNSTAGED=$(git diff --name-only 2>/dev/null)
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null)
ALL_CHANGED=$(printf '%s\n%s\n%s' "$STAGED" "$UNSTAGED" "$UNTRACKED" | grep -v '^$' | sort -u)

if [[ -z "$ALL_CHANGED" ]]; then
  echo "∅ nothing to commit"
  exit 0
fi

FILE_COUNT=$(echo "$ALL_CHANGED" | wc -l | tr -d ' ')

# ── Detached HEAD warning (non-fatal) ─────────────────────────────────────────
DETACHED=0
if ! git symbolic-ref -q HEAD > /dev/null 2>&1; then
  DETACHED=1
fi

# ── Stat helper ───────────────────────────────────────────────────────────────
get_stats() {
  # Requires all changes already staged. Returns "+N/-M".
  local diff_stat
  diff_stat=$(git diff --staged --numstat 2>/dev/null)
  local added removed
  added=$(echo "$diff_stat" | awk '{sum+=$1} END {print sum+0}')
  removed=$(echo "$diff_stat" | awk '{sum+=$2} END {print sum+0}')
  echo "+${added}/-${removed}"
}

# ── Message validation ────────────────────────────────────────────────────────
validate_msg() {
  local msg="$1"
  if [[ ${#msg} -gt 72 ]]; then
    echo "? message exceeds 72 chars (${#msg}) — truncating description" >&2
    # Truncate only the description part, keep type(scope):
    local prefix="${msg%%: *}: "
    local desc="${msg#*: }"
    local max_desc=$(( 72 - ${#prefix} ))
    msg="${prefix}${desc:0:$max_desc}"
  fi
  echo "$msg"
}

# ── --draft mode ──────────────────────────────────────────────────────────────
if [[ $DRAFT -eq 1 ]]; then
  echo "Draft commit message:"
  echo "  ${MSG}"
  echo ""
  echo "Run /signal-commit to confirm, or edit and pass as: /signal-commit \"your message\""
  exit 0
fi

# ── --dry mode ────────────────────────────────────────────────────────────────
if [[ $DRY -eq 1 ]]; then
  echo "Would stage: ${FILE_COUNT} file(s)"
  echo "Would commit: ${MSG}"
  if [[ $PUSH -eq 1 ]]; then
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")
    echo "Would push → origin/${BRANCH}"
  else
    echo "Would not push (use --push to push)"
  fi
  exit 0
fi

# ── Validate and normalise message(s) ────────────────────────────────────────
# MSG may contain multiple newline-separated conventional commit messages when
# --split was requested by the agent. Each line = one atomic commit.

if [[ $SPLIT -eq 1 && "$MSG" == *$'\n'* ]]; then
  # ── Split commit path ──────────────────────────────────────────────────────
  # Stage everything first so get_stats works; we re-stage strategically per commit.
  git add -A

  # Read messages into array
  mapfile -t MESSAGES <<< "$MSG"
  TOTAL_STATS=$(get_stats)

  # For each message, attempt a selective commit.
  # Strategy: derive a path hint from the scope in the commit message, use it
  # to stage only matching files. Fall back to staging all remaining changes.
  COMMITTED=0
  for commit_msg in "${MESSAGES[@]}"; do
    [[ -z "$commit_msg" ]] && continue
    commit_msg=$(validate_msg "$commit_msg")

    # Extract scope from type(scope): ... — e.g. "(auth)" → "auth"
    scope=$(echo "$commit_msg" | grep -oP '\(\K[^)]+' || true)

    # Reset staging area to unstaged-only
    git restore --staged . 2>/dev/null || true

    if [[ -n "$scope" ]]; then
      # Stage files whose paths contain the scope name
      matching=$(git diff --name-only | grep -i "$scope" || true)
      untracked_matching=$(git ls-files --others --exclude-standard | grep -i "$scope" || true)
      all_matching=$(printf '%s\n%s' "$matching" "$untracked_matching" | grep -v '^$' || true)

      if [[ -n "$all_matching" ]]; then
        echo "$all_matching" | xargs git add --
      else
        # No scope-matched files; stage everything remaining
        git add -A
      fi
    else
      git add -A
    fi

    # Skip if nothing staged
    staged=$(git diff --staged --name-only)
    if [[ -z "$staged" ]]; then
      continue
    fi

    fcount=$(echo "$staged" | wc -l | tr -d ' ')
    stats=$(get_stats)
    git commit -m "$commit_msg" --quiet
    echo "✓ ${commit_msg} [${fcount} file(s), ${stats}]"
    COMMITTED=$(( COMMITTED + 1 ))
  done

  # Stage and commit anything left over (files not matched by any scope)
  remaining_staged=$(git diff --name-only)
  remaining_untracked=$(git ls-files --others --exclude-standard)
  if [[ -n "$remaining_staged" || -n "$remaining_untracked" ]]; then
    git add -A
    leftover_count=$(git diff --staged --name-only | wc -l | tr -d ' ')
    leftover_stats=$(get_stats)
    # Reuse last message type for leftover, or fall back to chore
    fallback_type=$(echo "${MESSAGES[-1]}" | grep -oE '^[a-z]+' || echo "chore")
    fallback_msg="${fallback_type}: apply remaining changes"
    fallback_msg=$(validate_msg "$fallback_msg")
    git commit -m "$fallback_msg" --quiet
    echo "✓ ${fallback_msg} [${leftover_count} file(s), ${leftover_stats}]"
  fi

  if [[ $DETACHED -eq 1 ]]; then
    echo "? detached HEAD — push will require explicit ref"
  fi

else
  # ── Single commit path ─────────────────────────────────────────────────────
  MSG=$(validate_msg "$MSG")

  do_commit() {
    local msg="$1"
    git add -A
    local stats
    stats=$(get_stats)
    local fcount
    fcount=$(git diff --staged --name-only | wc -l | tr -d ' ')
    git commit -m "$msg" --quiet
    echo "✓ ${msg} [${fcount} file(s), ${stats}]"
    if [[ $DETACHED -eq 1 ]]; then
      echo "? detached HEAD — push will require explicit ref"
    fi
  }

  do_commit "$MSG"
fi

# ── --push ────────────────────────────────────────────────────────────────────
if [[ $PUSH -eq 1 ]]; then
  BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")
  if git push 2>/dev/null; then
    echo "✓ pushed → origin/${BRANCH}"
  else
    git push --set-upstream origin "$BRANCH"
    echo "✓ pushed → origin/${BRANCH}"
  fi
fi
