#Requires -Version 5.1
# Single entrypoint for SIGNAL benchmarks (proof suite + live Gemini).
# Extra args are forwarded (e.g. -Mode LongSession -Quick -Smoke, -Mode Output -DryRun).
#
# Note: Array splatting (& script @('-Pair','EqualContext')) binds POSITIONALLY and
# breaks named params (e.g. -Pair lands in $Model). When Passthrough is non-empty we
# spawn a nested powershell -File so the child parses arguments like an interactive invocation.
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('Static', 'Output', 'InputCompress', 'SkillOverhead', 'CompareCaveman', 'Chess', 'LongSession')]
  [string]$Mode,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Passthrough = @()
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$repoRoot = Split-Path $root -Parent

$script = switch ($Mode) {
  'Static' { Join-Path $root "proof-suite.ps1" }
  'Output' { Join-Path $root "proof-suite.ps1" }
  'InputCompress' { Join-Path $root "proof-suite.ps1" }
  'SkillOverhead' { Join-Path $root "proof-suite.ps1" }
  'CompareCaveman' { Join-Path $root "proof-suite.ps1" }
  'Chess' { Join-Path $root "benchmark chess\run_chess_compare.ps1" }
  'LongSession' { Join-Path $root "long-session\run_long_session.ps1" }
}

if ($Mode -in @('Static', 'Output', 'InputCompress', 'SkillOverhead', 'CompareCaveman')) {
  if ($Passthrough.Count -gt 0) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script -Category $Mode @Passthrough
  } else {
    & $script -Category $Mode
  }
} elseif ($Passthrough.Count -gt 0) {
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script @Passthrough
} else {
  & $script
}
exit $LASTEXITCODE
