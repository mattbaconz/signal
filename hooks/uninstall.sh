#!/usr/bin/env bash
set -euo pipefail
command -v node >/dev/null 2>&1 || { echo "ERROR: node required"; exit 1; }
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="$CLAUDE_DIR/settings.json"
HOOKS_DIR="$CLAUDE_DIR/hooks"
[[ -f "$SETTINGS" ]] || { echo "No settings.json"; exit 0; }
cp -f "$SETTINGS" "$SETTINGS.bak"
export SIGNAL_SETTINGS="$SETTINGS"
export SIGNAL_HOOKS_DIR="$HOOKS_DIR"
node <<'NODE'
const fs = require('fs');
const p = process.env.SIGNAL_SETTINGS;
let s = JSON.parse(fs.readFileSync(p, 'utf8'));
if (s.hooks && s.hooks.SessionStart) {
  s.hooks.SessionStart = s.hooks.SessionStart.filter(e =>
    !(e.hooks && e.hooks.some(h => h.command && h.command.includes('signal-activate.js')))
  );
}
if (s.statusLine && s.statusLine.command && s.statusLine.command.includes('signal-statusline')) {
  delete s.statusLine;
  console.log(' Removed SIGNAL statusLine.');
}
fs.writeFileSync(p, JSON.stringify(s, null, 2) + '\n');
console.log(' settings.json cleaned.');
NODE
rm -f "$CLAUDE_DIR/.signal-active"
echo "Optional: rm $HOOKS_DIR/signal-*.js $HOOKS_DIR/signal-statusline.*"
