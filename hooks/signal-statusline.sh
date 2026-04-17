#!/usr/bin/env bash
# SIGNAL statusline badge for Claude Code (Unix)
FLAG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.signal-active"
if [[ -f "$FLAG" ]]; then
  echo '[SIGNAL]'
fi
