#requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ThemeRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$LauncherPath = Join-Path $ThemeRoot 'start-inori-theme.cmd'
$ShortcutName = 'Codex Inori Frost.lnk'
$DesktopPath = [Environment]::GetFolderPath('Desktop')
$ShortcutPaths = @(
    (Join-Path $ThemeRoot $ShortcutName),
    (Join-Path $DesktopPath $ShortcutName)
)

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

if (-not (Test-Path -LiteralPath $LauncherPath)) {
    throw "Shortcut dependency is missing: $LauncherPath"
}
$CodexExe = Find-CodexExe

$Shell = New-Object -ComObject WScript.Shell
foreach ($ShortcutPath in $ShortcutPaths) {
    $Shortcut = $Shell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $LauncherPath
    $Shortcut.WorkingDirectory = $ThemeRoot
    $Shortcut.IconLocation = "$CodexExe,0"
    $Shortcut.Description = 'Launch Codex with the Inori Frost theme.'
    $Shortcut.WindowStyle = 1
    $Shortcut.Save()
    Write-Host "Created shortcut: $ShortcutPath" -ForegroundColor Cyan
}
