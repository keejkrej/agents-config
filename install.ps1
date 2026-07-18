# Install agent configs from this repo into user/global tool directories.
#
# Codex  -> ~/.codex
# opencode -> ~/.config/opencode
# Cursor -> ~/.cursor/rules/orchestration.mdc + ~/.cursor/agents/
# Grok   -> ~/.grok/AGENTS.md + ~/.grok/agents/ + ~/.grok/config.toml
#
# Usage:
#   .\install.ps1              # install all four
#   .\install.ps1 codex opencode  # install only selected tools
[CmdletBinding()]
param(
  [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
  [string[]]$Tools = @()
)

$ErrorActionPreference = 'Stop'
$Here = $PSScriptRoot

function Show-Usage {
  Write-Host 'Usage: .\install.ps1 [codex] [opencode] [cursor] [grok]'
  Write-Host 'Without arguments, installs all four to their user/global directories.'
}

if ($Tools -contains '/?' -or $Tools -contains '-h' -or $Tools -contains '--help') {
  Show-Usage
  exit 0
}

if ($Tools -contains 'all') {
  $Tools = @('codex', 'opencode', 'cursor', 'grok')
}
if ($Tools.Count -eq 0) {
  $Tools = @('codex', 'opencode', 'cursor', 'grok')
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
  $cursorDir = if ($env:CURSOR_DIR) { $env:CURSOR_DIR } else { Join-Path $HOME '.cursor' }
  Write-Host "==> Installing Cursor global config to $cursorDir"
  New-Item -ItemType Directory -Force -Path (Join-Path $cursorDir 'rules'), (Join-Path $cursorDir 'agents') | Out-Null

  $mdcPath = Join-Path $cursorDir 'rules\orchestration.mdc'
  if (Test-Path $mdcPath) {
    $bak = "$mdcPath.bak.$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
    Move-Item $mdcPath $bak -Force
    Write-Host "  backed up orchestration.mdc"
  }

  $frontmatter = @"
---
name: Orchestration
description: Global orchestration guidance for Cursor
globs: ["**/*"]
alwaysApply: true
---

"@
  $content = Get-Content -Raw (Join-Path $Here 'cursor\instructions.md')
  ($frontmatter + $content) | Set-Content -NoNewline -Path $mdcPath
  Write-Host "  wrote orchestration.mdc"

  Get-ChildItem -Path (Join-Path $Here 'cursor\agents') -Filter '*.md' -ErrorAction SilentlyContinue | ForEach-Object {
    Backup-And-Copy $_.FullName (Join-Path $cursorDir "agents\$($_.Name)")
  }
}

function Ensure-GrokSubagents($GrokDir) {
  $config = Join-Path $GrokDir 'config.toml'
  if (Test-Path $config) {
    if ((Get-Content $config -Raw) -match '\[subagents\]') {
      Write-Host "  $config already has a [subagents] section; leaving it unchanged"
    } else {
      Add-Content $config "`n[subagents]`nenabled = true`n"
      Write-Host "  appended [subagents] enabled = true to $config"
    }
  } else {
    Copy-Item (Join-Path $Here 'grok\config.toml') $config -Force
    Write-Host "  copied config.toml (subagents enabled)"
  }
}

function Install-Grok {
  $grokDir = if ($env:GROK_DIR) { $env:GROK_DIR } else { Join-Path $HOME '.grok' }
  Write-Host "==> Installing Grok global config to $grokDir"
  New-Item -ItemType Directory -Force -Path $grokDir, (Join-Path $grokDir 'agents') | Out-Null
  Backup-And-Copy (Join-Path $Here 'grok\instructions.md') (Join-Path $grokDir 'AGENTS.md')
  Get-ChildItem -Path (Join-Path $Here 'grok\agents') -Filter '*.md' -ErrorAction SilentlyContinue | ForEach-Object {
    Backup-And-Copy $_.FullName (Join-Path $grokDir "agents\$($_.Name)")
  }
  Ensure-GrokSubagents $grokDir
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
