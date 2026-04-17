# Remove SIGNAL hook entries from Claude Code settings.json (Windows)
$ErrorActionPreference = 'Stop'
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  Write-Host 'ERROR: node required'
  exit 1
}
$ClaudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE '.claude' }
$Settings = Join-Path $ClaudeDir 'settings.json'
$HooksDir = Join-Path $ClaudeDir 'hooks'
if (-not (Test-Path $Settings)) {
  Write-Host 'No settings.json — nothing to do.'
  exit 0
}
Copy-Item $Settings "$Settings.bak" -Force
$env:SIGNAL_SETTINGS = ($Settings -replace '\\', '/')
$env:SIGNAL_HOOKS_DIR = ($HooksDir -replace '\\', '/')
node -e @'
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
'@
$flag = Join-Path $ClaudeDir '.signal-active'
if (Test-Path $flag) { Remove-Item $flag -Force }
Write-Host 'Optional: delete hook scripts from' $HooksDir
exit 0
