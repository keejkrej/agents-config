# Install agent configs from this repo into the target tool directories.
#
# Codex and opencode go to user config by default.
# Cursor and Grok are project-scoped, so use -ProjectDir for the target project.
#
# Usage:
#   .\install.ps1 [codex] [opencode] [cursor] [grok]
#   .\install.ps1 -ProjectDir C:\path\to\project cursor grok
#   .\install.ps1                  # codex + opencode
[CmdletBinding()]
param(
  [string]$ProjectDir = '',
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Tools = @()
)

$ErrorActionPreference = 'Stop'
$Here = $PSScriptRoot

function Show-Usage {
  Write-Host 'Usage: .\install.ps1 [-ProjectDir <path>] [codex] [opencode] [cursor] [grok]'
  Write-Host 'Without tools, installs codex and opencode.'
  Write-Host 'Cursor and Grok require -ProjectDir.'
}

if ($Tools -contains '/?' -or $Tools -contains '-h' -or $Tools -contains '--help') {
  Show-Usage
  exit 0
}

if ($Tools -contains 'all') {
  $Tools = @('codex', 'opencode', 'cursor', 'grok')
}
if ($Tools.Count -eq 0) {
  $Tools = @('codex', 'opencode')
}

foreach ($t in $Tools) {
  if (($t -eq 'cursor' -or $t -eq 'grok') -and [string]::IsNullOrWhiteSpace($ProjectDir)) {
    Write-Error 'ProjectDir is required for cursor and grok.'
    Show-Usage
    exit 1
  }
}

function Backup-And-Copy($Src, $Dest) {
  $destParent = Split-Path -Parent $Dest
  if (-not (Test-Path $destParent)) { New-Item -ItemType Directory -Path $destParent -Force | Out-Null }
  if (Test-Path $Dest) {
    $bak = "$Dest.bak.$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
    Move-Item $Dest $bak -Force
    Write-Host "  backed up $(Split-Path $Dest -Leaf)"
  }
  Copy-Item -LiteralPath $Src -Destination $Dest -Force
  Write-Host "  copied $(Split-Path $Src -Leaf)"
}

function Install-Codex {
  $destDir = if ($env:CODEX_DIR) { $env:CODEX_DIR } else { Join-Path $HOME '.codex' }
  Write-Host "==> Installing Codex config to $destDir"
  New-Item -ItemType Directory -Force -Path $destDir, (Join-Path $destDir 'agents') | Out-Null
  Backup-And-Copy (Join-Path $Here 'codex\instructions.md') (Join-Path $destDir 'AGENTS.md')
  Get-ChildItem -Path (Join-Path $Here 'codex\agents') -Filter '*.toml' -ErrorAction SilentlyContinue | ForEach-Object {
    Backup-And-Copy $_.FullName (Join-Path $destDir "agents\$($_.Name)")
  }
  $modules = Join-Path $Here 'codex\node_modules\smol-toml'
  if (-not (Test-Path $modules)) {
    npm install --prefix (Join-Path $Here 'codex') --omit=dev --no-fund --no-audit
  }
  $mergeScript = Join-Path $Here 'codex\scripts\merge_config.mjs'
  & node $mergeScript (Join-Path $Here 'codex\config.toml') (Join-Path $destDir 'config.toml')
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

function Install-Opencode {
  $destDir = if ($env:OPENCODE_DIR) { $env:OPENCODE_DIR } else { Join-Path $HOME '.config\opencode' }
  Write-Host "==> Installing opencode config to $destDir"
  New-Item -ItemType Directory -Force -Path $destDir, (Join-Path $destDir 'agent') | Out-Null
  Backup-And-Copy (Join-Path $Here 'opencode\instructions.md') (Join-Path $destDir 'AGENTS.md')
  Get-ChildItem -Path (Join-Path $Here 'opencode\agent') -Filter '*.md' -ErrorAction SilentlyContinue | ForEach-Object {
    Backup-And-Copy $_.FullName (Join-Path $destDir "agent\$($_.Name)")
  }
  if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "!! node not found; skipping opencode.json merge" -ForegroundColor Yellow
  } else {
    $mergeScript = Join-Path $Here 'opencode\scripts\merge-json.mjs'
    & node $mergeScript (Join-Path $Here 'opencode\opencode.json') (Join-Path $destDir 'opencode.json')
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  }
}

function Install-Cursor {
  $destDir = $ProjectDir
  Write-Host "==> Installing Cursor config to $destDir"
  New-Item -ItemType Directory -Force -Path $destDir | Out-Null
  Backup-And-Copy (Join-Path $Here 'cursor\instructions.md') (Join-Path $destDir 'AGENTS.md')
  $agentsDir = Join-Path $Here 'cursor\agents'
  if (Test-Path $agentsDir) {
    $cursorAgents = Join-Path $destDir '.cursor\agents'
    New-Item -ItemType Directory -Force -Path $cursorAgents | Out-Null
    Get-ChildItem -Path $agentsDir -Filter '*.md' -ErrorAction SilentlyContinue | ForEach-Object {
      Backup-And-Copy $_.FullName (Join-Path $cursorAgents $_.Name)
    }
  }
}

function Install-Grok {
  $destDir = $ProjectDir
  Write-Host "==> Installing Grok config to $destDir"
  New-Item -ItemType Directory -Force -Path $destDir | Out-Null
  Backup-And-Copy (Join-Path $Here 'grok\instructions.md') (Join-Path $destDir 'AGENTS.md')
  $agentsDir = Join-Path $Here 'grok\agents'
  if (Test-Path $agentsDir) {
    $grokAgents = Join-Path $destDir '.grok\agents'
    New-Item -ItemType Directory -Force -Path $grokAgents | Out-Null
    Get-ChildItem -Path $agentsDir -Filter '*.md' -ErrorAction SilentlyContinue | ForEach-Object {
      Backup-And-Copy $_.FullName (Join-Path $grokAgents $_.Name)
    }
  }
}

foreach ($t in $Tools) {
  switch ($t) {
    'codex' { Install-Codex }
    'opencode' { Install-Opencode }
    'cursor' { Install-Cursor }
    'grok' { Install-Grok }
    default { Write-Error "Unknown tool: $t"; Show-Usage; exit 1 }
  }
}

Write-Host ''
Write-Host '==> Done.'
