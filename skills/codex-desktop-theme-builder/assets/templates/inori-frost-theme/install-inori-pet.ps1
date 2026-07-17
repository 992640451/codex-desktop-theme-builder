#requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceRoot = Join-Path $RepoRoot 'pet\inori-pet'
$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
$TargetRoot = Join-Path $CodexHome 'pets\inori-pet'
$RuntimeFiles = @('pet.json', 'spritesheet.webp', 'validation.json')

foreach ($name in $RuntimeFiles) {
    $source = Join-Path $SourceRoot $name
    if (-not (Test-Path -LiteralPath $source)) {
        throw "Pet package file is missing: $source"
    }
}

New-Item -ItemType Directory -Path $TargetRoot -Force | Out-Null
foreach ($name in $RuntimeFiles) {
    Copy-Item -LiteralPath (Join-Path $SourceRoot $name) -Destination (Join-Path $TargetRoot $name) -Force
}

Write-Host "Inori pet installed to $TargetRoot" -ForegroundColor Cyan
Write-Host 'Restart Codex Desktop, then select the Inori pet.'
