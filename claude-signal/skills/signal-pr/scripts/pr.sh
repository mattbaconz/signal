#!/usr/bin/env bash
set -euo pipefail

dry=0
draft=0
pr_draft=0
forward=()

while (($#)); do
  case "$1" in
    --dry|-dry) dry=1; forward+=("--dry"); shift ;;
    --draft|-draft) draft=1; forward+=("--draft"); shift ;;
    --pr-draft|-pr-draft) pr_draft=1; shift ;;
    *) forward+=("$1"); shift ;;
  esac
done

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

if ((dry || draft)); then
  bash "$ROOT/signal-push/scripts/push.sh" "${forward[@]}"
  ((dry)) && echo "Would open PR with gh pr create --fill"
  ((draft)) && echo "Draft would open PR with gh pr create --fill"
  exit 0
fi

command -v gh >/dev/null || { echo "x gh CLI required"; exit 1; }
bash "$ROOT/signal-push/scripts/push.sh" "${forward[@]}"
args=(pr create --fill)
((pr_draft)) && args+=(--draft)
exec gh "${args[@]}"
