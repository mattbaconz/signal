#!/usr/bin/env bash
# signal-push/scripts/push.sh
# Wraps commit.sh with a push step.
# Agent generates commit message and passes it as an argument.
#
# Usage:
#   push.sh [--draft] [--split] [--dry] [--] "commit message"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMIT_SCRIPT="${SCRIPT_DIR}/../../signal-commit/scripts/commit.sh"

# ── Flag parsing ──────────────────────────────────────────────────────────────
DRAFT=0
DRY=0
SPLIT=0
MSG=""
PASSTHROUGH_FLAGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --draft) DRAFT=1; PASSTHROUGH_FLAGS+=("--draft"); shift ;;
    --dry)   DRY=1;   PASSTHROUGH_FLAGS+=("--dry");   shift ;;
    --split) SPLIT=1; PASSTHROUGH_FLAGS+=("--split"); shift ;;
    --)      shift; MSG="$*"; break ;;
    -*)      echo "✗ unknown flag: $1"; exit 1 ;;
    *)       MSG="$*"; break ;;
  esac
done

if [[ -z "$MSG" && ! -t 0 ]]; then
  MSG=$(cat)
fi

# ── Pre-flight ────────────────────────────────────────────────────────────────
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "✗ not a git repository"
  exit 1
fi

# Detect detached HEAD before any commit attempt
if ! git symbolic-ref -q HEAD > /dev/null 2>&1; then
  if [[ $DRY -eq 1 ]]; then
    echo "✗ cannot push in detached HEAD — checkout a branch first"
    exit 0
  fi
fi

# ── Remote check ──────────────────────────────────────────────────────────────
if ! git remote get-url origin > /dev/null 2>&1; then
  echo "✗ no remote configured — add remote first"
  exit 1
fi

# ── --dry mode ────────────────────────────────────────────────────────────────
if [[ $DRY -eq 1 ]]; then
  BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")
  bash "$COMMIT_SCRIPT" --dry "${PASSTHROUGH_FLAGS[@]}" -- "$MSG"
  echo "Would push → origin/${BRANCH}"
  exit 0
fi

# ── --draft mode ──────────────────────────────────────────────────────────────
if [[ $DRAFT -eq 1 ]]; then
  bash "$COMMIT_SCRIPT" --draft -- "$MSG"
  exit 0
fi

# ── Commit ────────────────────────────────────────────────────────────────────
bash "$COMMIT_SCRIPT" "${PASSTHROUGH_FLAGS[@]}" -- "$MSG"

# ── Push ──────────────────────────────────────────────────────────────────────
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

if [[ "$BRANCH" == "HEAD" ]]; then
  echo "✗ cannot push in detached HEAD — checkout a branch first"
  exit 1
fi

if git push 2>/dev/null; then
  echo "✓ pushed → origin/${BRANCH}"
else
  # Try with --set-upstream for new branches
  if git push --set-upstream origin "$BRANCH" 2>/dev/null; then
    echo "✓ pushed → origin/${BRANCH}"
  else
    echo "✗ push rejected — pull and rebase first"
    exit 1
  fi
fi
