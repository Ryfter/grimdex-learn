# D27 doctor-style version-mismatch warning (UR-002 EDU-side fallback).
# Read-only. Exit codes: 0 match/unpinned, 1 mismatch, 2 base unverifiable.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InstallRoot,
    [string]$ManifestPath
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'manifest-lib.ps1')
. (Join-Path $PSScriptRoot 'version-lib.ps1')

if (-not $ManifestPath) { $ManifestPath = Join-Path $InstallRoot 'learn/manifest.json' }
try {
    $manifest = Read-LearnManifest -Path $ManifestPath
    $r = Test-LearnVersionMatch -InstallRoot $InstallRoot -Manifest $manifest
} catch {
    Write-Host "WARNING: cannot evaluate the Learn manifest at '$ManifestPath' ($($_.Exception.Message))."
    Write-Host "Learn guidance cannot be verified without a readable manifest; treat version-specific claims as potentially stale."
    exit 2
}

switch ($r.status) {
    'match' {
        Write-Host "OK: $($r.detail)"
        exit 0
    }
    'unpinned' {
        Write-Host "NOTE: $($r.detail)"
        exit 0
    }
    'unknown-base' {
        Write-Host "WARNING: $($r.detail)"
        Write-Host "Learn guidance cannot be verified against your base Grimdex version; treat version-specific claims as potentially stale."
        exit 2
    }
    'mismatch' {
        Write-Host "WARNING: $($r.detail)"
        Write-Host "Learn explanations are version-matched to '$($r.pin)'. Your honest options (D27):"
        Write-Host "  1. Move to a matching Learn pack for your base version, if one exists."
        Write-Host "  2. Stay on (or return to) the pinned base '$($r.pin)' for supported guidance."
        Write-Host "  3. Keep your base and deactivate Learn pointers - unsupported best-effort."
        Write-Host "A version mismatch is never silently presented as current, verified guidance."
        exit 1
    }
    default {
        Write-Host "WARNING: unrecognized version-check status '$($r.status)'; cannot verify guidance."
        exit 2
    }
}
