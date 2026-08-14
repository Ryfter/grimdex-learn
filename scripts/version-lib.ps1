# scripts/version-lib.ps1
Set-StrictMode -Version 3.0

# Requires manifest-lib.ps1 to be dot-sourced by the caller: Test-LearnVersionMatch
# reads the optional base pin via Get-ManifestPin rather than reaching into
# baseGrimdex.pin directly.

function Get-BaseGrimdexVersion {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$InstallRoot)

    if (-not (Test-Path -LiteralPath (Join-Path $InstallRoot '.git'))) {
        return [pscustomobject]@{ known = $false; version = $null; reason = 'not a git repository' }
    }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        return [pscustomobject]@{ known = $false; version = $null; reason = 'git is not available on PATH' }
    }
    $exact = git -C $InstallRoot describe --tags --exact-match 2>$null
    if ($LASTEXITCODE -eq 0 -and $exact) {
        return [pscustomobject]@{ known = $true; version = [string]$exact; reason = 'exact release tag' }
    }
    $near = git -C $InstallRoot describe --tags 2>$null
    if ($LASTEXITCODE -eq 0 -and $near) {
        return [pscustomobject]@{ known = $true; version = [string]$near; reason = 'ahead of nearest release tag' }
    }
    [pscustomobject]@{ known = $false; version = $null; reason = 'no release tags found' }
}

function Test-LearnVersionMatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)]$Manifest
    )

    $pin = Get-ManifestPin -Manifest $Manifest
    if ($null -eq $pin) {
        return [pscustomobject]@{
            status = 'unpinned'; pin = $null; actual = $null
            detail = 'This Learn pack does not claim to be matched to a base Grimdex version, so there is nothing to compare. Pinning is optional.'
        }
    }
    $base = Get-BaseGrimdexVersion -InstallRoot $InstallRoot
    if (-not $base.known) {
        return [pscustomobject]@{
            status = 'unknown-base'; pin = $pin; actual = $null
            detail = "Cannot determine the installed base version ($($base.reason))."
        }
    }
    if ($base.version -ceq $pin) {
        return [pscustomobject]@{
            status = 'match'; pin = $pin; actual = $base.version
            detail = "Installed base '$($base.version)' matches the Learn pack pin."
        }
    }
    [pscustomobject]@{
        status = 'mismatch'; pin = $pin; actual = $base.version
        detail = "Installed base '$($base.version)' does not match the Learn pack pin '$pin'."
    }
}
