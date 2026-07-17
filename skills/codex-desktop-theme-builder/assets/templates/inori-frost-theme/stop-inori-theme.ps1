#requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProfilePath = Join-Path $env:APPDATA 'Codex-InoriFrost'
$StatePath = Join-Path $ProfilePath 'inori-frost-state.json'
$ThemeRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$InjectorPath = Join-Path $ThemeRoot 'injector.mjs'

function Test-ProcessOwnership([int]$Id, [string]$ExpectedCommandLineFragment) {
    $process = Get-CimInstance Win32_Process -Filter "ProcessId=$Id" -ErrorAction SilentlyContinue
    return $null -ne $process -and
        $null -ne $process.CommandLine -and
        $process.CommandLine.IndexOf($ExpectedCommandLineFragment, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
}

if (-not (Test-Path -LiteralPath $StatePath)) {
    Write-Host 'No running Inori Frost themed instance was found.'
    exit 0
}

$State = Get-Content -Raw -Encoding UTF8 -LiteralPath $StatePath | ConvertFrom-Json

if ($null -ne $State.injectorPid -and
    (Test-ProcessOwnership ([int]$State.injectorPid) $InjectorPath)) {
    Stop-Process -Id ([int]$State.injectorPid) -Force -ErrorAction SilentlyContinue
}

$ThemeProcessIds = @()
if ($null -ne $State.codexPid -and
    (Test-ProcessOwnership ([int]$State.codexPid) $ProfilePath)) {
    $ThemeProcessIds += [int]$State.codexPid
}
$ThemeProcessIds += @(Get-CimInstance Win32_Process -Filter "Name='ChatGPT.exe'" -ErrorAction SilentlyContinue |
    Where-Object {
        $null -ne $_.CommandLine -and
        $_.CommandLine.IndexOf($ProfilePath, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
    } |
    Select-Object -ExpandProperty ProcessId)

foreach ($ProcessId in @($ThemeProcessIds | Sort-Object -Unique)) {
    Stop-Process -Id $ProcessId -Force -ErrorAction SilentlyContinue
}

Remove-Item -LiteralPath $StatePath -Force -ErrorAction SilentlyContinue
Write-Host 'Inori Frost themed instance stopped. The official Codex installation was not changed.' -ForegroundColor Cyan
