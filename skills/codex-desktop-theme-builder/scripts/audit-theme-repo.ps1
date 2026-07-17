#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$RepoPath = '.',
    [switch]$IncludeHistory,
    [switch]$FailOnFinding
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RootPath = (Resolve-Path -LiteralPath $RepoPath).Path
$GitPath = Join-Path $RootPath '.git'
$Findings = New-Object 'System.Collections.Generic.List[object]'
$AuditScriptRelativePath = 'skills\codex-desktop-theme-builder\scripts\audit-theme-repo.ps1'

function Add-Finding {
    param(
        [string]$Severity,
        [string]$Kind,
        [string]$Path,
        [string]$Detail
    )
    $Findings.Add([pscustomobject]@{
        Severity = $Severity
        Kind = $Kind
        Path = $Path
        Detail = $Detail
    }) | Out-Null
}

function Get-RelativePath {
    param([string]$FullName)
    $prefix = $RootPath.TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
    if ($FullName.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        return $FullName.Substring($prefix.Length)
    }
    return $FullName
}

function Test-PngTextMetadata {
    param([string]$Path)
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 20) { return $false }
    $position = 8
    while ($position + 12 -le $bytes.Length) {
        $length = ([int64]$bytes[$position] -shl 24) -bor
                  ([int64]$bytes[$position + 1] -shl 16) -bor
                  ([int64]$bytes[$position + 2] -shl 8) -bor
                  [int64]$bytes[$position + 3]
        if ($length -lt 0 -or $position + 12 + $length -gt $bytes.Length) { break }
        $type = [Text.Encoding]::ASCII.GetString($bytes, $position + 4, 4)
        if ($type -in @('tEXt', 'iTXt', 'zTXt')) { return $true }
        $position += 12 + [int]$length
        if ($type -eq 'IEND') { break }
    }
    return $false
}

$SensitiveNamePattern = '(?i)(^|[\/])(?:\.env(?:\.|$)|[^\/]*(?:secret|password|credential|api[-_]?key)[^\/]*|id_rsa[^\/]*|[^\/]*\.(?:pem|key|pfx|p12|log|tmp))$'
$ReviewImageNamePattern = '(?i)(screenshot|screen[-_ ]?shot|preview|capture|clipboard|mockup|concept|task[-_ ]?(?:running|complete))'
$TextExtensions = @('.md', '.txt', '.json', '.yaml', '.yml', '.ps1', '.cmd', '.bat', '.js', '.mjs', '.cjs', '.ts', '.css', '.html', '.xml', '.svg', '.toml', '.ini')
$ContentPatterns = @(
    @{ Kind = 'literal-user-path'; Pattern = '(?i)([a-z]:\\users\\[^\\\r\n]+\\|(?:^|[\s"''(])/(?:users|home)/[^/\s]+/)' ; Detail = 'Literal user-profile path' },
    @{ Kind = 'credential-assignment'; Pattern = '(?i)(api[-_]?key|client[-_]?secret|password|access[-_]?token)\s*[:=]\s*\S{8,}' ; Detail = 'Credential-like assignment' },
    @{ Kind = 'token-signature'; Pattern = '(?i)(?:^|[^a-z0-9])(?:github_pat_|gh[pousr]_|sk-)[a-z0-9_-]{12,}' ; Detail = 'Token-like signature' },
    @{ Kind = 'private-key'; Pattern = '-----BEGIN [A-Z ]{0,30}PRIVATE KEY-----' ; Detail = 'Private-key header' },
    @{ Kind = 'email'; Pattern = '(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b' ; Detail = 'Email address' },
    @{ Kind = 'private-network'; Pattern = '\b(?:10\.\d{1,3}\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3}|172\.(?:1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3})\b' ; Detail = 'Private-network address' },
    @{ Kind = 'work-temp-path'; Pattern = '(?i)(appdata\\(?:local|roaming)\\temp|larkshell|sdk_storage|codex-clipboard)' ; Detail = 'Application/temp work path' }
)

Push-Location $RootPath
try {
    if ((git rev-parse --is-inside-work-tree 2>$null) -ne 'true') {
        throw "Not a Git repository: $RootPath"
    }

    $files = Get-ChildItem -LiteralPath $RootPath -Recurse -File -Force |
        Where-Object { -not $_.FullName.StartsWith($GitPath, [StringComparison]::OrdinalIgnoreCase) }

    foreach ($file in $files) {
        $relative = Get-RelativePath $file.FullName
        if ($relative -match $SensitiveNamePattern) {
            Add-Finding 'high' 'sensitive-filename' $relative 'Sensitive or local-only filename'
        }
        if ($file.Extension -match '(?i)^\.(png|jpe?g|webp|gif)$' -and $file.Name -match $ReviewImageNamePattern) {
            Add-Finding 'review' 'ui-image' $relative 'Review and normally remove UI screenshot/mockup before publishing'
        }
        if ($file.Extension -ieq '.png' -and (Test-PngTextMetadata $file.FullName)) {
            Add-Finding 'review' 'image-metadata' $relative 'PNG contains a text metadata chunk; inspect or strip it'
        }
        if ($TextExtensions -contains $file.Extension.ToLowerInvariant() -and
            $relative -ine $AuditScriptRelativePath -and $file.Length -le 2097152) {
            $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding utf8 -ErrorAction SilentlyContinue
            if ($null -ne $content) {
                foreach ($entry in $ContentPatterns) {
                    if ($content -match $entry.Pattern) {
                        Add-Finding 'high' $entry.Kind $relative $entry.Detail
                    }
                }
            }
        }
    }

    if ($IncludeHistory) {
        $identityLines = git log --all --format='%H%x09%ae%x09%ce'
        foreach ($line in $identityLines) {
            $parts = $line -split "`t"
            if ($parts.Count -lt 3) { continue }
            $commitId = $parts[0]
            foreach ($email in @($parts[1], $parts[2]) | Sort-Object -Unique) {
                if ($email -and $email -notmatch '(?i)@users\.noreply\.github\.com$') {
                    Add-Finding 'history' 'commit-email' $commitId.Substring(0, 8) 'Non-noreply email remains in Git commit metadata'
                }
            }
        }

        $historyNames = git log --all --name-only --pretty=format: |
            Where-Object { $_ -and $_.Trim().Length -gt 0 } |
            Sort-Object -Unique
        foreach ($path in $historyNames) {
            if ($path -match $SensitiveNamePattern) {
                Add-Finding 'history' 'sensitive-filename' $path 'Sensitive filename remains in reachable history'
            }
            if ([IO.Path]::GetExtension($path) -match '(?i)^\.(png|jpe?g|webp|gif)$' -and
                [IO.Path]::GetFileName($path) -match $ReviewImageNamePattern) {
                Add-Finding 'history' 'ui-image' $path 'UI image remains in reachable history'
            }
        }

        $historyPattern = '([a-zA-Z]:\\Users\\[^\\]+\\|(^|[[:space:]"''(])/(Users|home)/[^/[:space:]]+/|(^|[^a-zA-Z0-9])(github_pat_|gh[pousr]_|sk-)[a-zA-Z0-9_-]{12,}|-----BEGIN [A-Z ]{0,30}PRIVATE KEY-----|appdata\\(local|roaming)\\temp|larkshell|sdk_storage|codex-clipboard)'
        foreach ($commit in (git rev-list --all)) {
            $paths = git grep -l -I -E $historyPattern $commit -- . 2>$null
            foreach ($path in $paths) {
                Add-Finding 'history' 'sensitive-content' $path "Sensitive text path in commit $($commit.Substring(0, 8))"
            }
        }
    }

    $unique = @($Findings | Sort-Object Severity, Kind, Path, Detail -Unique)
    if ($unique.Count -eq 0) {
        Write-Host '[PASS] No privacy findings.' -ForegroundColor Green
    } else {
        $unique | Format-Table Severity, Kind, Path, Detail -AutoSize
        Write-Host "Findings: $($unique.Count)" -ForegroundColor Yellow
    }

    if ($FailOnFinding -and $unique.Count -gt 0) { exit 2 }
    $global:LASTEXITCODE = 0
} finally {
    Pop-Location
}
