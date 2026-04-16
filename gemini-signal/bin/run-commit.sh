#!/usr/bin/env bash
# Forward to bundled signal-commit script. Invoke with cwd = git repository root.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec bash "$ROOT/skills/signal-commit/scripts/commit.sh" "$@"
