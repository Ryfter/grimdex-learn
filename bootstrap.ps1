# Path A front door (D42). The user has already cloned this repository.
# Prerequisite checks, then delegate to scripts/install-learn.ps1 — never
# reimplement compose. Exit codes are install-learn.ps1's: 0 / 1 / 2.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InstallRoot,
    [string]$WorkDir,
    [switch]$Preview
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "This script needs PowerShell 7 or later. You are running version $($PSVersionTable.PSVersion)."
    Write-Host 'Install PowerShell 7 from https://aka.ms/powershell and run this with pwsh, not powershell.'
    exit 1
}

$sourceRoot   = $PSScriptRoot
$manifestPath = Join-Path $sourceRoot 'learn' 'manifest.json'
$installCli   = Join-Path $sourceRoot 'scripts' 'install-learn.ps1'

if (-not (Test-Path -LiteralPath $installCli -PathType Leaf)) {
    Write-Host 'I cannot find scripts/install-learn.ps1 next to this script.'
    Write-Host 'Run bootstrap.ps1 from the Grimdex-edu folder you cloned, not from a copy of this file alone.'
    Write-Host "Looked in: $installCli"
    exit 1
}

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    Write-Host 'I cannot find learn/manifest.json in this folder.'
    Write-Host 'bootstrap.ps1 must run from the Grimdex-edu folder you cloned (the one that contains learn/ and scripts/).'
    Write-Host "Looked in: $manifestPath"
    exit 1
}

if (-not (Test-Path -LiteralPath $InstallRoot -PathType Container)) {
    Write-Host "The install path '$InstallRoot' does not exist or is not a folder."
    Write-Host '-InstallRoot must point at your existing Grimdex install.'
    exit 1
}

$grimdexMd = Join-Path $InstallRoot 'GRIMDEX.md'
if (-not (Test-Path -LiteralPath $grimdexMd -PathType Leaf)) {
    Write-Host "The path '$InstallRoot' is not a Grimdex install."
    Write-Host 'A Grimdex install is a folder that already contains a file named GRIMDEX.md.'
    Write-Host 'Install Grimdex first, then run this again with -InstallRoot pointing at that folder.'
    exit 1
}

if ([string]::IsNullOrWhiteSpace($WorkDir)) {
    $WorkDir = Join-Path ([System.IO.Path]::GetTempPath()) ('grimdex-edu-install-' + [guid]::NewGuid().ToString('N'))
}

# Prefix-safe containment: same rule install-learn.ps1 enforces, with a
# human-readable message. 'install-work' is NOT under 'install'.
$rootFull   = [System.IO.Path]::GetFullPath($InstallRoot).TrimEnd('\', '/')
$rootPrefix = $rootFull + [System.IO.Path]::DirectorySeparatorChar
$workFull   = [System.IO.Path]::GetFullPath($WorkDir).TrimEnd('\', '/')
if ($workFull.Equals($rootFull, [System.StringComparison]::OrdinalIgnoreCase) -or
    $workFull.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Host 'The work directory must be outside the Grimdex install.'
    Write-Host "-WorkDir '$WorkDir' sits inside -InstallRoot '$InstallRoot'."
    Write-Host 'Omit -WorkDir to let this script pick a temporary folder, or pass a path next to the install rather than inside it.'
    exit 1
}

Write-Host "Composing the Learn module onto: $InstallRoot"
Write-Host "Source checkout:                 $sourceRoot"
if ($Preview) {
    Write-Host 'Preview only — nothing will be written.'
}

# $invokeArgs, never $args — $args is an automatic variable.
$invokeArgs = @{
    SourceRoot   = $sourceRoot
    InstallRoot  = $InstallRoot
    ManifestPath = $manifestPath
    WorkDir      = $WorkDir
}
if ($Preview) { $invokeArgs['Preview'] = $true }

# install-learn.ps1 calls exit, which ends only that script — not this
# process. Re-exit with its code so compose failures (1 invalid plan,
# 2 rollback) are not reported as success.
& $installCli @invokeArgs
exit $LASTEXITCODE
