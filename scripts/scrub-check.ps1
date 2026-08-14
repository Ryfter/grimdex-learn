# Go-public scrub check (pre-visibility-flip guard): flags private references left in
# tracked files - Windows/POSIX absolute paths, emails, and locally-listed personal/
# institution terms - so the check does not depend on anyone remembering by hand.
# Read-only. Scans `git ls-files` output only; untracked/scratch files are never touched.
# Findings may be suppressed via an allowlist (scrub-allow.txt) of known-safe patterns.
# Exit codes: 0 = no findings (or all suppressed), 1 = findings present, 2 = could not run the check.
[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [string]$TermsFile,
    [string]$AllowFile,
    [switch]$ShippingSurfaceOnly,
    [switch]$Quiet,
    [switch]$ShowSuppressed
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$binaryExtensions = @(
    '.png', '.jpg', '.jpeg', '.gif', '.pdf', '.zip', '.ico', '.woff', '.woff2', '.exe', '.dll'
)

# Generic, portable detectors. None of these may embed a real private term - this
# script ships publicly; the only place private terms may live is the local,
# gitignored terms file loaded below.
$builtinPatterns = @(
    [pscustomobject]@{
        label   = 'Windows absolute path'
        pattern = '(?<![A-Za-z0-9])[A-Za-z]:[\\/]'
    }
    [pscustomobject]@{
        label   = 'POSIX home path'
        pattern = '/(Users|home)/[^/\s"''<>]+'
    }
    [pscustomobject]@{
        label   = 'Email address'
        pattern = '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
    }
)

function Get-NormalizedPath {
    param([string]$Path)
    return [System.IO.Path]::GetFullPath($Path).ToLowerInvariant().Replace('\', '/')
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host 'WARNING: git is not available on PATH; cannot enumerate tracked files.'
    Write-Host 'Summary: 0 finding(s) checked - exit 2 (could not run the check).'
    exit 2
}

$gitOutput = & git -C $RepoRoot ls-files 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: 'git -C $RepoRoot ls-files' failed: $($gitOutput | Out-String)"
    Write-Host 'Summary: 0 finding(s) checked - exit 2 (could not run the check).'
    exit 2
}
$files = @($gitOutput | Where-Object { $_ -ne '' })

if ($ShippingSurfaceOnly) {
    $files = @($files | Where-Object {
        $_ -like 'learn/*' -or $_ -like 'scripts/*' -or $_ -like 'tests/*' -or
        $_ -eq 'INSTALL.md' -or $_ -eq 'learn/manifest.json' -or
        $_ -eq 'bootstrap.ps1' -or $_ -eq 'QUICKSTART.md' -or $_ -eq 'get-learn.ps1' -or
        $_ -eq 'README.md' -or $_ -eq 'LICENSE'
    })
}

# Extra, local-only terms (personal names, institution names): -TermsFile wins,
# else the conventional local file if present. Never committed - see .gitignore.
$termsPath = $null
if ($TermsFile) {
    $termsPath = $TermsFile
} else {
    $defaultTermsPath = Join-Path $RepoRoot 'scrub-terms.local.txt'
    if (Test-Path -LiteralPath $defaultTermsPath) { $termsPath = $defaultTermsPath }
}

$extraTerms = @()
$termsNormalizedPath = $null
if ($termsPath) {
    if (-not (Test-Path -LiteralPath $termsPath)) {
        Write-Host "WARNING: terms file not found: $termsPath"
        Write-Host 'Summary: 0 finding(s) checked - exit 2 (could not run the check).'
        exit 2
    }
    try {
        $termsLines = Get-Content -LiteralPath $termsPath -ErrorAction Stop
    } catch {
        Write-Host "WARNING: cannot read terms file '$termsPath' ($($_.Exception.Message))."
        Write-Host 'Summary: 0 finding(s) checked - exit 2 (could not run the check).'
        exit 2
    }
    foreach ($line in @($termsLines)) {
        $t = $line.Trim()
        if ($t -eq '' -or $t.StartsWith('#')) { continue }
        $extraTerms += $t
    }
    $termsNormalizedPath = Get-NormalizedPath $termsPath
}

# Allowlist: known-safe patterns (committed). Overridable with -AllowFile.
# Format: one literal substring per line (matched case-insensitively against the line),
# blank lines and # comments are ignored.
$allowlistPath = $null
if ($AllowFile) {
    $allowlistPath = $AllowFile
} else {
    $defaultAllowPath = Join-Path $RepoRoot 'scrub-allow.txt'
    if (Test-Path -LiteralPath $defaultAllowPath) { $allowlistPath = $defaultAllowPath }
}

$allowlistEntries = @()
if ($allowlistPath) {
    if (-not (Test-Path -LiteralPath $allowlistPath)) {
        Write-Host "WARNING: allowlist file not found: $allowlistPath"
        Write-Host 'Summary: 0 finding(s) checked - exit 2 (could not run the check).'
        exit 2
    }
    try {
        $allowLines = Get-Content -LiteralPath $allowlistPath -ErrorAction Stop
    } catch {
        Write-Host "WARNING: cannot read allowlist file '$allowlistPath' ($($_.Exception.Message))."
        Write-Host 'Summary: 0 finding(s) checked - exit 2 (could not run the check).'
        exit 2
    }
    foreach ($line in @($allowLines)) {
        $a = $line.Trim()
        if ($a -eq '' -or $a.StartsWith('#')) { continue }
        $allowlistEntries += $a
    }
}

$allPatterns = [System.Collections.Generic.List[object]]::new()
foreach ($bp in $builtinPatterns) { $allPatterns.Add($bp) }
foreach ($t in $extraTerms) {
    $allPatterns.Add([pscustomobject]@{
        label   = "local term: $t"
        pattern = [regex]::Escape($t)
    })
}

$findings = [System.Collections.Generic.List[object]]::new()
$suppressed = [System.Collections.Generic.List[object]]::new()
$labelCounts = [ordered]@{}
$suppressedCounts = [ordered]@{}

foreach ($rel in $files) {
    $ext = [System.IO.Path]::GetExtension($rel).ToLowerInvariant()
    if ($binaryExtensions -contains $ext) { continue }

    $full = Join-Path $RepoRoot $rel
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
    if ($termsNormalizedPath -and (Get-NormalizedPath $full) -eq $termsNormalizedPath) { continue }

    $lines = Get-Content -LiteralPath $full -ErrorAction SilentlyContinue
    if ($null -eq $lines) { continue }

    $lineNum = 0
    foreach ($line in @($lines)) {
        $lineNum++
        foreach ($p in $allPatterns) {
            if ($line -match $p.pattern) {
                $trimmed = $line.Trim()
                if ($trimmed.Length -gt 120) { $trimmed = $trimmed.Substring(0, 120) }

                # Check if this line matches an allowlist entry (case-insensitive substring match)
                $isAllowed = $false
                foreach ($entry in $allowlistEntries) {
                    if ($line -like "*$entry*" -or $line.ToLowerInvariant().Contains($entry.ToLowerInvariant())) {
                        $isAllowed = $true
                        break
                    }
                }

                if ($isAllowed) {
                    $suppressed.Add([pscustomobject]@{
                        path  = $rel
                        line  = $lineNum
                        label = $p.label
                        text  = $trimmed
                    })
                    if (-not $suppressedCounts.Contains($p.label)) { $suppressedCounts[$p.label] = 0 }
                    $suppressedCounts[$p.label] = $suppressedCounts[$p.label] + 1
                } else {
                    $findings.Add([pscustomobject]@{
                        path  = $rel
                        line  = $lineNum
                        label = $p.label
                        text  = $trimmed
                    })
                    if (-not $labelCounts.Contains($p.label)) { $labelCounts[$p.label] = 0 }
                    $labelCounts[$p.label] = $labelCounts[$p.label] + 1
                }
            }
        }
    }
}

$total = $findings.Count
$totalSuppressed = $suppressed.Count

if ($Quiet) {
    foreach ($label in ($labelCounts.Keys | Sort-Object)) {
        Write-Host "${label}: $($labelCounts[$label])"
    }
} else {
    $grouped = $findings | Group-Object path | Sort-Object Name
    foreach ($g in $grouped) {
        foreach ($f in ($g.Group | Sort-Object line)) {
            Write-Host "$($f.path):$($f.line): [$($f.label)] $($f.text)"
        }
    }
}

if ($ShowSuppressed -and $totalSuppressed -gt 0) {
    Write-Host ""
    Write-Host "Suppressed findings (via allowlist):"
    $suppressedGrouped = $suppressed | Group-Object path | Sort-Object Name
    foreach ($g in $suppressedGrouped) {
        foreach ($f in ($g.Group | Sort-Object line)) {
            Write-Host "$($f.path):$($f.line): [$($f.label)] $($f.text)"
        }
    }
}

if ($totalSuppressed -gt 0) {
    Write-Host "Suppressed $totalSuppressed finding(s) via allowlist."
}

if ($total -eq 0) {
    Write-Host 'Summary: 0 findings - exit 0 (clean; no private references detected).'
    exit 0
} else {
    Write-Host "Summary: $total finding(s) - exit 1 (findings present; go-public scrub not clean)."
    exit 1
}
