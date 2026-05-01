#Requires -Version 5.1
[CmdletBinding()]
param(
  [ValidateSet('Static', 'Output', 'InputCompress', 'SkillOverhead', 'CompareCaveman')]
  [string]$Category = 'Static',

  [switch]$DryRun,

  [switch]$Live,

  [string]$Model,

  [int]$MaxScenarios = 0,

  [int]$PerCallTimeoutSeconds = 90,

  [switch]$WriteResults,

  [string]$OutFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = $PSScriptRoot
$RepoRoot = Split-Path $Root -Parent
$Fixtures = Join-Path $Root 'fixtures'
$Results = Join-Path $Root 'results'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Get-EstimatedTokens([string]$Text) {
  if ([string]::IsNullOrEmpty($Text)) { return 0 }
  return [int][math]::Ceiling($Text.Length / 4.0)
}

function Get-GitSha {
  $sha = (git -C $RepoRoot rev-parse --short HEAD 2>$null)
  if ($LASTEXITCODE -ne 0 -or -not $sha) { return 'unknown' }
  return $sha.Trim()
}

function New-ResultRow(
  [string]$ScenarioId,
  [string]$Arm,
  [string]$Model,
  [int]$InputTokens,
  [int]$OutputTokens,
  [int]$Chars,
  [bool]$Success,
  [double]$FidelityScore
) {
  [pscustomobject][ordered]@{
    scenario_id = $ScenarioId
    arm = $Arm
    model = $Model
    input_tokens = $InputTokens
    output_tokens = $OutputTokens
    total_tokens = $InputTokens + $OutputTokens
    chars = $Chars
    success = $Success
    fidelity_score = $FidelityScore
    timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    git_sha = Get-GitSha
  }
}

function Test-RequiredTerms([string]$Text, [object[]]$Terms) {
  foreach ($term in $Terms) {
    if (-not $Text.Contains([string]$term)) { return $false }
  }
  return $true
}

function Get-InputCompressionRows {
  $path = Join-Path $Fixtures 'input-compress.json'
  $items = Get-Content -LiteralPath $path -Raw -Encoding utf8 | ConvertFrom-Json
  $rows = @()
  foreach ($item in $items) {
    $ok = Test-RequiredTerms $item.compressed @($item.required_terms)
    $score = if ($ok) { 1.0 } else { 0.0 }
    $rows += (New-ResultRow `
      -ScenarioId $item.scenario_id `
      -Arm 'signal' `
      -Model 'static-char4' `
      -InputTokens (Get-EstimatedTokens $item.original) `
      -OutputTokens (Get-EstimatedTokens $item.compressed) `
      -Chars $item.compressed.Length `
      -Success $ok `
      -FidelityScore $score)
  }
  return @($rows)
}

function Get-SkillOverheadRows {
  $rows = @()
  $pairs = Get-ChildItem -Path (Join-Path $RepoRoot 'skills') -Filter '*.md' -File |
    Where-Object { $_.Name -notmatch '\.min\.md$' }
  foreach ($canonical in $pairs) {
    $min = Join-Path $canonical.DirectoryName ($canonical.BaseName + '.min.md')
    if (-not (Test-Path -LiteralPath $min)) { continue }
    $canonicalText = Get-Content -LiteralPath $canonical.FullName -Raw -Encoding utf8
    $minText = Get-Content -LiteralPath $min -Raw -Encoding utf8
    $ok = ($minText.Length -lt $canonicalText.Length)
    $rows += (New-ResultRow `
      -ScenarioId $canonical.BaseName `
      -Arm 'signal-minified-skill' `
      -Model 'static-char4' `
      -InputTokens (Get-EstimatedTokens $canonicalText) `
      -OutputTokens (Get-EstimatedTokens $minText) `
      -Chars $minText.Length `
      -Success $ok `
      -FidelityScore $(if ($ok) { 1.0 } else { 0.0 }))
  }
  return @($rows)
}

function Show-DryRunPlan([string]$Name) {
  $scenarios = Get-Content -LiteralPath (Join-Path $Fixtures 'output-scenarios.json') -Raw -Encoding utf8 | ConvertFrom-Json
  $arms = @('baseline', 'terse-control', 'caveman-style', 'signal')
  Write-Host "SIGNAL proof benchmark dry run: $Name"
  Write-Host 'Arms: baseline | terse-control | caveman-style | signal'
  Write-Host 'Schema: scenario_id, arm, model, input_tokens, output_tokens, total_tokens, chars, success, fidelity_score, timestamp, git_sha'
  foreach ($scenario in $scenarios) {
    foreach ($arm in $arms) {
      Write-Host ("  {0} :: {1}" -f $scenario.scenario_id, $arm)
    }
  }
}

function New-ArmPrompt([string]$Arm, [string]$Prompt) {
  switch ($Arm) {
    'baseline' { return $Prompt }
    'terse-control' { return "Answer concisely. Preserve technical terms.`n`n$Prompt" }
    'caveman-style' { return "Telegraphic terse style. No filler. Preserve exact technical terms, paths, code, and errors.`n`n$Prompt" }
    'signal' { return "/signal3`n$Prompt" }
  }
}

function New-ArmWorkspace([string]$Arm, [string]$Parent) {
  $dir = Join-Path $Parent $Arm
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
  if ($Arm -eq 'signal') {
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'GEMINI.md') -Destination (Join-Path $dir 'GEMINI.md') -Force
  } elseif ($Arm -eq 'terse-control') {
    Set-Content -LiteralPath (Join-Path $dir 'GEMINI.md') -Value 'Answer concisely. Preserve technical tokens exactly.' -Encoding utf8
  } elseif ($Arm -eq 'caveman-style') {
    Set-Content -LiteralPath (Join-Path $dir 'GEMINI.md') -Value 'Telegraphic terse style. No filler. Preserve technical tokens exactly.' -Encoding utf8
  }
  return $dir
}

function Invoke-LiveOutputRows([string]$Name) {
  . (Join-Path $Root 'lib\gemini-invoke.ps1')
  $bundle = Get-GeminiNodeBundle
  $scenarios = Get-Content -LiteralPath (Join-Path $Fixtures 'output-scenarios.json') -Raw -Encoding utf8 | ConvertFrom-Json
  if ($MaxScenarios -gt 0) {
    $scenarios = @($scenarios | Select-Object -First $MaxScenarios)
  }
  $arms = @('baseline', 'terse-control', 'caveman-style', 'signal')
  $rows = @()
  $tmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('signal-proof-' + [Guid]::NewGuid().ToString('n'))
  New-Item -ItemType Directory -Path $tmpRoot -Force | Out-Null
  try {
    foreach ($arm in $arms) { New-ArmWorkspace -Arm $arm -Parent $tmpRoot | Out-Null }
    foreach ($scenario in $scenarios) {
      foreach ($arm in $arms) {
        $workDir = Join-Path $tmpRoot $arm
        $promptText = New-ArmPrompt -Arm $arm -Prompt ([string]$scenario.prompt)
        Write-Host ("live {0}|{1}" -f $scenario.scenario_id, $arm)
        try {
          $raw = Invoke-GeminiNodePromptJson -WorkingDir $workDir -PromptText $promptText -Model $Model -GeminiJs $bundle.GeminiJs -NodeExe $bundle.NodeExe -MaxRetries 1 -PerCallTimeoutMs ($PerCallTimeoutSeconds * 1000)
          $obj = Parse-GeminiJson $raw
          $f = Get-FirstModelTokenFields $obj.stats
          $resp = if ($obj.response) { [string]$obj.response } else { "" }
          $ok = Test-RequiredTerms $resp @($scenario.required_terms)
          $rows += (New-ResultRow `
            -ScenarioId $scenario.scenario_id `
            -Arm $arm `
            -Model $(if ($f.model) { $f.model } elseif ($Model) { $Model } else { 'gemini-cli' }) `
            -InputTokens $(if ($null -ne $f.prompt) { [int]$f.prompt } else { Get-EstimatedTokens $promptText }) `
            -OutputTokens $(if ($null -ne $f.output) { [int]$f.output } else { Get-EstimatedTokens $resp }) `
            -Chars $resp.Length `
            -Success $ok `
            -FidelityScore $(if ($ok) { 1.0 } else { 0.0 }))
        } catch {
          $rows += (New-ResultRow `
            -ScenarioId $scenario.scenario_id `
            -Arm $arm `
            -Model $(if ($Model) { $Model } else { 'gemini-cli' }) `
            -InputTokens (Get-EstimatedTokens $promptText) `
            -OutputTokens 0 `
            -Chars 0 `
            -Success $false `
            -FidelityScore 0.0)
          Write-Host ("  failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        }
      }
    }
  } finally {
    Remove-Item -LiteralPath $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
  return @($rows)
}

function Write-Summary([object[]]$Rows) {
  if ($Rows.Count -eq 0) {
    Write-Host 'No rows.'
    return
  }
  $passed = @($Rows | Where-Object { $_.success }).Count
  $medianSave = @()
  foreach ($row in $Rows) {
    if ($row.input_tokens -gt 0) {
      $medianSave += [math]::Round(100.0 * ($row.input_tokens - $row.output_tokens) / $row.input_tokens, 1)
    }
  }
  $sorted = @($medianSave | Sort-Object)
  $median = if ($sorted.Count -gt 0) { $sorted[[int][math]::Floor(($sorted.Count - 1) / 2)] } else { 0 }
  Write-Host ("Rows: {0}; fidelity pass: {1}/{0}; median static savings: {2}%" -f $Rows.Count, $passed, $median)
  foreach ($row in $Rows) {
    Write-Host ("  {0}|{1}|in={2}|out={3}|ok={4}|fid={5}" -f $row.scenario_id, $row.arm, $row.input_tokens, $row.output_tokens, $row.success, $row.fidelity_score)
  }
}

$rows = @()
switch ($Category) {
  'Static' {
    $rows = @(Get-InputCompressionRows) + @(Get-SkillOverheadRows)
  }
  'InputCompress' {
    if ($DryRun) {
      Write-Host 'SIGNAL input-compress dry run: fixtures/input-compress.json'
      Write-Host 'Gate: every required_terms item must appear verbatim in compressed text.'
    }
    $rows = @(Get-InputCompressionRows)
  }
  'SkillOverhead' {
    $rows = @(Get-SkillOverheadRows)
  }
  'Output' {
    Show-DryRunPlan 'Output'
    if ($Live) {
      $rows = @(Invoke-LiveOutputRows 'Output')
      break
    } elseif (-not $DryRun) {
      Write-Host 'Live output benchmark is opt-in: add -Live after confirming the dry-run plan.'
    }
    exit 0
  }
  'CompareCaveman' {
    Show-DryRunPlan 'CompareCaveman'
    if ($Live) {
      $rows = @(Invoke-LiveOutputRows 'CompareCaveman')
      break
    } elseif (-not $DryRun) {
      Write-Host 'CompareCaveman live benchmark is opt-in: add -Live after confirming the dry-run plan.'
    }
    exit 0
  }
}

Write-Summary $rows
$allLiveRowsFailed = ($Live -and $rows.Count -gt 0 -and @($rows | Where-Object { $_.success }).Count -eq 0)

if ($WriteResults) {
  if (-not (Test-Path -LiteralPath $Results)) {
    New-Item -ItemType Directory -Path $Results -Force | Out-Null
  }
  $target = if ($OutFile) { $OutFile } else { Join-Path $Results 'v0.4-static.generated.json' }
  $json = [ordered]@{
    schema_version = '0.4.0'
    category = $Category
    rows = $rows
  } | ConvertTo-Json -Depth 8
  $targetParent = Split-Path -Parent $target
  if (-not $targetParent) { $targetParent = (Get-Location).Path }
  if (-not (Test-Path -LiteralPath $targetParent)) {
    New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
  }
  $targetFull = Join-Path (Resolve-Path -LiteralPath $targetParent).Path (Split-Path -Leaf $target)
  [System.IO.File]::WriteAllText($targetFull, $json, $Utf8NoBom)
  Write-Host "Wrote $target"
}

if ($allLiveRowsFailed) {
  Write-Host 'Live benchmark produced zero fidelity-passing rows.' -ForegroundColor Red
  exit 1
}
