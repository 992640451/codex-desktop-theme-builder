#requires -Version 5.1
[CmdletBinding()]
param(
    [int]$PreferredPort = 9333
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ThemeRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$CssPath = Join-Path $ThemeRoot 'theme.css'
$ImagePath = Join-Path $ThemeRoot 'assets\inori-original-crystal-hero.png'
$InjectorPath = Join-Path $ThemeRoot 'injector.mjs'
$ProfilePath = Join-Path $env:APPDATA 'Codex-InoriFrost'
$StatePath = Join-Path $ProfilePath 'inori-frost-state.json'
$StdoutLog = Join-Path $ProfilePath 'injector.log'
$StderrLog = Join-Path $ProfilePath 'injector-error.log'

function Test-ProcessAlive([int]$Id) {
    return $null -ne (Get-Process -Id $Id -ErrorAction SilentlyContinue)
}

function Test-ProcessOwnership([int]$Id, [string]$ExpectedCommandLineFragment) {
    $process = Get-CimInstance Win32_Process -Filter "ProcessId=$Id" -ErrorAction SilentlyContinue
    return $null -ne $process -and
        $null -ne $process.CommandLine -and
        $process.CommandLine.IndexOf($ExpectedCommandLineFragment, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
}

function Test-Cdp([int]$Port) {
    foreach ($attempt in 1..3) {
        try {
            $targets = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/json/list" -TimeoutSec 5
            if (@($targets | Where-Object { $_.type -eq 'page' -and $_.url -like 'app://-/index.html*' }).Count -gt 0) {
                return $true
            }
        } catch {
            if ($attempt -lt 3) { Start-Sleep -Milliseconds 250 }
        }
    }
    return $false
}

function Test-PortInUse([int]$Port) {
    return $null -ne (Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -First 1)
}

function Find-FreePort([int]$StartPort) {
    foreach ($candidate in $StartPort..($StartPort + 20)) {
        if (-not (Test-PortInUse $candidate)) { return $candidate }
    }
    throw "Could not find a free local port between $StartPort and $($StartPort + 20)."
}

function Find-CodexExe {
    $package = Get-AppxPackage -Name 'OpenAI.Codex' -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1
    if ($null -ne $package) {
        $candidate = Join-Path $package.InstallLocation 'app\ChatGPT.exe'
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }

    $running = Get-Process -Name 'ChatGPT' -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -like '*OpenAI.Codex*\app\ChatGPT.exe' } |
        Select-Object -First 1
    if ($null -ne $running -and (Test-Path -LiteralPath $running.Path)) { return $running.Path }
    throw 'Codex Desktop was not found. Install or start the official Codex app first.'
}

function Find-NodeExe {
    $bundled = Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\bin\node.exe'
    if (Test-Path -LiteralPath $bundled) { return $bundled }
    $command = Get-Command node.exe -ErrorAction SilentlyContinue
    if ($null -ne $command) { return $command.Source }
    throw 'Node.js 22+ was not found. The Codex bundled Node runtime is normally used automatically.'
}

function Start-Injector([string]$NodeExe, [int]$Port) {
    $arguments = "`"$InjectorPath`" --port $Port --css `"$CssPath`" --image `"$ImagePath`""
    return Start-Process -FilePath $NodeExe -ArgumentList $arguments -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput $StdoutLog -RedirectStandardError $StderrLog
}

foreach ($required in @($CssPath, $ImagePath, $InjectorPath)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Theme file is missing: $required" }
}

New-Item -ItemType Directory -Path $ProfilePath -Force | Out-Null
$NodeExe = Find-NodeExe

$state = $null
$launchNew = $true
if (Test-Path -LiteralPath $StatePath) {
    try {
        $state = Get-Content -Raw -Encoding UTF8 -LiteralPath $StatePath | ConvertFrom-Json
    } catch {
        Write-Verbose "Ignoring unreadable state: $($_.Exception.Message)"
    }
}

if ($null -ne $state) {
    $rootAlive = Test-ProcessOwnership ([int]$state.codexPid) $ProfilePath
    $injectorAlive = Test-ProcessOwnership ([int]$state.injectorPid) $InjectorPath
    $portAlive = Test-PortInUse ([int]$state.port)
    $cdpAlive = Test-Cdp ([int]$state.port)
    Write-Verbose "State health: root=$rootAlive injector=$injectorAlive port=$portAlive cdp=$cdpAlive"
    if ($injectorAlive -and $portAlive -and $cdpAlive) {
        Write-Host "Inori Frost theme is already running." -ForegroundColor Cyan
        $launchNew = $false
    } elseif ($portAlive -and $cdpAlive) {
        $newInjector = Start-Injector $NodeExe ([int]$state.port)
        $state.injectorPid = $newInjector.Id
        $state.startedAt = (Get-Date).ToString('o')
        $state | ConvertTo-Json | Set-Content -Encoding UTF8 -LiteralPath $StatePath
        Write-Host "Inori Frost theme injection was restored." -ForegroundColor Cyan
        $launchNew = $false
    } elseif ($rootAlive -or $portAlive) {
        throw "The existing themed Codex instance is still starting. Wait a few seconds and run this launcher again."
    }
}

if ($launchNew) {
    $Port = Find-FreePort $PreferredPort
    $CodexExe = Find-CodexExe
    $CodexArguments = @("--remote-debugging-port=$Port", "--user-data-dir=$ProfilePath", '--no-first-run')
    $CodexProcess = Start-Process -FilePath $CodexExe -ArgumentList $CodexArguments -PassThru

    $ready = $false
    $deadline = (Get-Date).AddSeconds(45)
    while ((Get-Date) -lt $deadline) {
        if (Test-Cdp $Port) { $ready = $true; break }
        if (-not (Test-ProcessAlive $CodexProcess.Id)) { break }
        Start-Sleep -Milliseconds 750
    }

    if (-not $ready) {
        if (Test-ProcessAlive $CodexProcess.Id) { Stop-Process -Id $CodexProcess.Id -Force -ErrorAction SilentlyContinue }
        throw "Codex started, but its local theme endpoint did not become ready on port $Port."
    }

    $InjectorProcess = Start-Injector $NodeExe $Port
    $state = [ordered]@{
        version = '1.7.2'
        codexPid = $CodexProcess.Id
        injectorPid = $InjectorProcess.Id
        port = $Port
        profilePath = $ProfilePath
        codexExe = $CodexExe
        startedAt = (Get-Date).ToString('o')
    }
    $state | ConvertTo-Json | Set-Content -Encoding UTF8 -LiteralPath $StatePath

    Write-Host "Inori Frost theme started." -ForegroundColor Cyan
    Write-Host "Isolated profile: $ProfilePath"
    Write-Host "Run stop-inori-theme.cmd to close the themed instance."
}
