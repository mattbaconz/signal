#!/usr/bin/env bash
# signal-pr/scripts/pr.sh
# Wraps push.sh with a gh pr create step.
# Agent generates commit message, PR title, and PR body — passes them as arguments.
#
# Usage:
#   pr.sh [--draft] [--dry] [--pr-draft] [--title "PR title"] [--body "PR body"] [--] "commit message"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PUSH_SCRIPT="${SCRIPT_DIR}/../../signal-push/scripts/push.sh"

# ── Flag parsing ──────────────────────────────────────────────────────────────
DRAFT=0
DRY=0
PR_DRAFT=0
PR_TITLE=""
PR_BODY=""
COMMIT_MSG=""
PUSH_FLAGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --draft)    DRAFT=1;    PUSH_FLAGS+=("--draft"); shift ;;
    --dry)      DRY=1;      PUSH_FLAGS+=("--dry");   shift ;;
    --pr-draft) PR_DRAFT=1; shift ;;
    --title)    PR_TITLE="$2"; shift 2 ;;
    --body)     PR_BODY="$2";  shift 2 ;;
    --)         shift; COMMIT_MSG="$*"; break ;;
    -*)         echo "✗ unknown flag: $1"; exit 1 ;;
    *)          COMMIT_MSG="$*"; break ;;
  esac
done

if [[ -z "$COMMIT_MSG" && ! -t 0 ]]; then
  COMMIT_MSG=$(cat)
fi

# ── Pre-flight checks ─────────────────────────────────────────────────────────
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "✗ not a git repository"
  exit 1
fi

if ! command -v gh > /dev/null 2>&1; then
  echo "✗ gh CLI required — install from cli.github.com"
  exit 1
fi

if ! gh auth status > /dev/null 2>&1; then
  echo "✗ gh not authenticated — run: gh auth login"
  exit 1
fi

# ── --draft mode ──────────────────────────────────────────────────────────────
if [[ $DRAFT -eq 1 ]]; then
  echo "Draft commit message:"
  echo "  ${COMMIT_MSG}"
  echo ""
  if [[ -n "$PR_TITLE" ]]; then
    echo "Draft PR title:"
    echo "  ${PR_TITLE}"
    echo ""
  fi
  if [[ -n "$PR_BODY" ]]; then
    echo "Draft PR body:"
    echo "$PR_BODY" | sed 's/^/  /'
    echo ""
  fi
  echo "Run /signal-pr to confirm."
  exit 0
fi

# ── --dry mode ────────────────────────────────────────────────────────────────
if [[ $DRY -eq 1 ]]; then
  bash "$PUSH_SCRIPT" --dry -- "$COMMIT_MSG"
  TITLE="${PR_TITLE:-$COMMIT_MSG}"
  echo "Would create PR: \"${TITLE}\""
  if [[ $PR_DRAFT -eq 1 ]]; then
    echo "Would create as draft PR"
  fi
  exit 0
fi

# ── Check for existing PR ─────────────────────────────────────────────────────
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
EXISTING_PR=$(gh pr view "$BRANCH" --json url --jq '.url' 2>/dev/null || true)
if [[ -n "$EXISTING_PR" ]]; then
  echo "✗ PR already open for this branch → ${EXISTING_PR}"
  exit 1
fi

# ── Commit + Push ─────────────────────────────────────────────────────────────
bash "$PUSH_SCRIPT" "${PUSH_FLAGS[@]}" -- "$COMMIT_MSG"

# ── Build PR title ────────────────────────────────────────────────────────────
if [[ -z "$PR_TITLE" ]]; then
  PR_TITLE="$COMMIT_MSG"
fi

# ── Build PR body ─────────────────────────────────────────────────────────────
if [[ -z "$PR_BODY" ]]; then
  # Minimal fallback body — agent should always supply this
  PR_BODY="## Changes
- ${COMMIT_MSG}

## Type
$(echo "$COMMIT_MSG" | grep -oE '^[a-z]+')"
fi

# ── Create PR ─────────────────────────────────────────────────────────────────
GH_FLAGS=("--title" "$PR_TITLE" "--body" "$PR_BODY")
if [[ $PR_DRAFT -eq 1 ]]; then
  GH_FLAGS+=("--draft")
fi

PR_URL=$(gh pr create "${GH_FLAGS[@]}" 2>/dev/null)
echo "✓ PR opened → ${PR_URL}"
