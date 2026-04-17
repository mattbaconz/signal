#!/usr/bin/env bash
# SIGNAL — Claude Code hook installer (macOS / Linux)
set -euo pipefail
FORCE=false
[[ "${1:-}" == "-f" || "${1:-}" == "--force" ]] && FORCE=true

command -v node >/dev/null 2>&1 || { echo "ERROR: node required"; exit 1; }

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS="$CLAUDE_DIR/settings.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

HOOK_FILES=(signal-activate.js signal-statusline.ps1 signal-statusline.sh package.json)

mkdir -p "$HOOKS_DIR"
for f in "${HOOK_FILES[@]}"; do
  cp -f "$SCRIPT_DIR/$f" "$HOOKS_DIR/$f"
  echo "  Installed: $HOOKS_DIR/$f"
done

[[ -f "$SETTINGS" ]] || echo '{}' > "$SETTINGS"
cp -f "$SETTINGS" "$SETTINGS.bak" 2>/dev/null || true

export SIGNAL_SETTINGS="$SETTINGS"
export SIGNAL_HOOKS_DIR="$HOOKS_DIR"

node <<'NODE'
const fs = require('fs');
const path = require('path');
const settingsPath = process.env.SIGNAL_SETTINGS;
const hooksDir = process.env.SIGNAL_HOOKS_DIR;
const win = process.platform === 'win32';
const statusScript = path.join(hooksDir, win ? 'signal-statusline.ps1' : 'signal-statusline.sh').replace(/\\/g, '/');
const activate = path.join(hooksDir, 'signal-activate.js').replace(/\\/g, '/');
const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
if (!settings.hooks) settings.hooks = {};
if (!settings.hooks.SessionStart) settings.hooks.SessionStart = [];
const has = settings.hooks.SessionStart.some(e =>
  e.hooks && e.hooks.some(h => h.command && h.command.includes('signal-activate.js'))
);
if (!has) {
  settings.hooks.SessionStart.push({
    hooks: [{
      type: 'command',
      command: 'node "' + activate + '"',
      timeout: 30,
      statusMessage: 'SIGNAL session defaults'
    }]
  });
}
if (!settings.statusLine) {
  const cmd = win
    ? 'powershell -ExecutionPolicy Bypass -File "' + statusScript + '"'
    : 'bash "' + statusScript + '"';
  settings.statusLine = { type: 'command', command: cmd };
  console.log(' Statusline [SIGNAL] configured.');
} else {
  console.log(' NOTE: statusLine already set — left unchanged.');
}
fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
console.log(' settings.json updated.');
NODE

echo "Done. Restart Claude Code."
