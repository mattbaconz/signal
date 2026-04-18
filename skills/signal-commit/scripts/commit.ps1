# SIGNAL v0.3.0 - commit.ps1
# Usage: .\commit.ps1 [-dry] "message"

$dry = $args -contains "-dry"
$msg = $args | Where-Object { $_ -ne "-dry" } | Select-Object -First 1

if ($dry) { Write-Host "Dry run: git commit -m '$msg'"; exit 0 }
if (-not $msg) { Write-Error "Missing commit message"; exit 1 }

git add -A
git commit -m $msg
