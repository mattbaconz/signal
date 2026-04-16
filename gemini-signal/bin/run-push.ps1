#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ExtensionRoot = Split-Path $PSScriptRoot -Parent
$PushPs1 = Join-Path $ExtensionRoot 'skills\signal-push\scripts\push.ps1'
if (-not (Test-Path -LiteralPath $PushPs1)) {
  Write-Host "x missing bundled script: $PushPs1" -ForegroundColor Red
  exit 1
}
& powershell -NoProfile -ExecutionPolicy Bypass -File $PushPs1 @args
exit $LASTEXITCODE
