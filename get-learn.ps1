# Path B front door (D42). Fetched by the one-liner. This file is a
# bootstrapper, not the product: it downloads a pinned release and then
# runs the same bootstrap.ps1 that Path A uses. That relocates the clone
# and adds a trust hop. It does not remove the clone.
#
# Release tag matches learn/manifest.json learnPackVersion, with a v prefix.
# Test-PathBTagReady still refuses to fetch if this is ever reset to the
# sentinel RELEASE_TAG (a future bump could reintroduce one).
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InstallRoot,
    [string]$WorkDir,
    [switch]$Preview,
    [switch]$Accept,
    [string]$LocalSource
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# Public release repo (Q7 decided). HTTPS clone URL, no trailing slash, no .git.
$script:PublicReleaseRepoUrl = 'https://github.com/Ryfter/grimdex-learn'
$script:ReleaseTag = 'v0.2.0-fall2026-draft'

function Test-PathBTagReady {
    -not [string]::Equals(
        $script:ReleaseTag, 'RELEASE_TAG',
        [System.StringComparison]::Ordinal)
}

Write-Host 'This is the Grimdex-edu Learn installer (the one-liner path).'
Write-Host ''
Write-Host 'This script is a bootstrapper, not the product. It will download a'
Write-Host "pinned release ($($script:ReleaseTag)) and then run the same local"
Write-Host 'bootstrap.ps1 that the git-clone path uses. That relocates the clone'
Write-Host 'and adds a trust hop. It does not remove the clone.'
Write-Host ''
Write-Host "Download from:  $($script:PublicReleaseRepoUrl)"
Write-Host "Install onto:   $InstallRoot"
Write-Host 'Writes only:    learn/ and a pointer stanza in GRIMDEX.md'
Write-Host 'Never touches:  projects/ (your own notes)'
Write-Host ''

if (-not $Accept) {
    Write-Host 'Press Enter to continue, or Ctrl+C to cancel.'
    [void](Read-Host)
}

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "This script needs PowerShell 7 or later. You are running version $($PSVersionTable.PSVersion)."
    Write-Host 'Install PowerShell 7 from https://aka.ms/powershell and run this with pwsh, not powershell.'
    exit 1
}

$sourceRoot = $null
if (-not [string]::IsNullOrWhiteSpace($LocalSource)) {
    $sourceRoot = $LocalSource
} else {
    if (-not (Test-PathBTagReady)) {
        Write-Host 'Path B will not fetch until a release tag is cut. RELEASE_TAG is still unset.'
        Write-Host 'Use the taught path: clone the checkout you were given and run bootstrap.ps1 -InstallRoot <install>.'
        exit 1
    }

    $zipUrl = $script:PublicReleaseRepoUrl.TrimEnd('/') + '/archive/refs/tags/' + $script:ReleaseTag + '.zip'
    $stage  = Join-Path ([System.IO.Path]::GetTempPath()) ('grimdex-edu-fetch-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $stage -Force | Out-Null
    $zipPath = Join-Path $stage 'release.zip'
    Write-Host "Downloading $zipUrl"
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    Expand-Archive -LiteralPath $zipPath -DestinationPath $stage
    # GitHub tag zips contain exactly one top-level folder (repo-tag/).
    # release.zip itself is a file, so -Directory returns that folder.
    $top = @(Get-ChildItem -LiteralPath $stage -Directory)
    if ($top.Count -ne 1) {
        Write-Host "The downloaded archive did not contain exactly one folder. Contents of $stage :"
        Get-ChildItem -LiteralPath $stage | ForEach-Object { Write-Host "  $($_.Name)" }
        exit 1
    }
    $sourceRoot = $top[0].FullName
}

$boot = Join-Path $sourceRoot 'bootstrap.ps1'
if (-not (Test-Path -LiteralPath $boot -PathType Leaf)) {
    Write-Host "The downloaded (or -LocalSource) tree has no bootstrap.ps1 at '$boot'."
    Write-Host 'Path B only runs the same bootstrap.ps1 that Path A uses; it will not invent a second installer.'
    exit 1
}

# $bootArgs, never $args.
$bootArgs = @{ InstallRoot = $InstallRoot }
if (-not [string]::IsNullOrWhiteSpace($WorkDir)) { $bootArgs['WorkDir'] = $WorkDir }
if ($Preview) { $bootArgs['Preview'] = $true }

# bootstrap.ps1's exit ends only that script — not this process.
# Re-exit with its code so compose failures are not reported as success.
& $boot @bootArgs
exit $LASTEXITCODE
