# SIGNAL — Claude Code hook installer (Windows)
# Installs SessionStart hook + optional statusline badge.
# Usage: powershell -ExecutionPolicy Bypass -File hooks\install.ps1 [-Force]
param([switch]$Force)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  Write-Host "ERROR: Node.js is required (used to merge settings.json safely)." -ForegroundColor Red
  exit 1
}

$ClaudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE '.claude' }
$HooksDir = Join-Path $ClaudeDir 'hooks'
$Settings = Join-Path $ClaudeDir 'settings.json'
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

$HookFiles = @('signal-activate.js', 'signal-statusline.ps1', 'signal-statusline.sh', 'package.json')

if (-not $Force) {
  $ok = $true
  foreach ($h in $HookFiles) {
    if (-not (Test-Path (Join-Path $HooksDir $h))) { $ok = $false; break }
  }
  if ($ok -and (Test-Path $Settings)) {
    try {
      $so = Get-Content $Settings -Raw | ConvertFrom-Json
      $wired = $false
      if ($so.hooks -and $so.hooks.SessionStart) {
        foreach ($e in $so.hooks.SessionStart) {
          if ($e.hooks) {
            foreach ($x in $e.hooks) {
              if ($x.command -and $x.command -match 'signal-activate\.js') { $wired = $true }
            }
          }
        }
      }
      if ($wired) {
        Write-Host 'SIGNAL hooks already appear wired. Re-run with -Force to reinstall.'
        exit 0
      }
    } catch { }
  }
}

Write-Host 'Installing SIGNAL hooks...'
if (-not (Test-Path $HooksDir)) { New-Item -ItemType Directory -Path $HooksDir -Force | Out-Null }

foreach ($h in $HookFiles) {
  $src = Join-Path $ScriptDir $h
  $dst = Join-Path $HooksDir $h
  if (-not (Test-Path $src)) { Write-Error "Missing $src"; exit 1 }
  Copy-Item -LiteralPath $src -Destination $dst -Force
  Write-Host "  Installed: $dst"
}

if (-not (Test-Path $Settings)) { Set-Content -Path $Settings -Value '{}' }
Copy-Item $Settings "$Settings.bak" -Force -ErrorAction SilentlyContinue

$env:SIGNAL_SETTINGS = ($Settings -replace '\\', '/')
$env:SIGNAL_HOOKS_DIR = ($HooksDir -replace '\\', '/')

$nodeScript = @'
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
  console.log(' NOTE: statusLine already set — left unchanged. Merge manually if you want [SIGNAL].');
}
fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
console.log(' settings.json updated.');
'@

node -e $nodeScript
Write-Host 'Done. Restart Claude Code.' -ForegroundColor Green
exit 0
