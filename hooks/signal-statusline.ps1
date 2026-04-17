# SIGNAL statusline badge for Claude Code (Windows)
$ErrorActionPreference = 'SilentlyContinue'
$flag = Join-Path $env:USERPROFILE '.claude\.signal-active'
if (Test-Path -LiteralPath $flag) {
  Write-Output '[SIGNAL]'
}
