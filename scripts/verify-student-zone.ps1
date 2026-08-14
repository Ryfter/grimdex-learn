[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Snapshot', 'Verify')][string]$Mode,
    [Parameter(Mandatory)][string]$InstallRoot,
    [Parameter(Mandatory)][string]$ManifestPath,
    [Parameter(Mandatory)][string]$SnapshotPath
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'manifest-lib.ps1')
. (Join-Path $PSScriptRoot 'verify-lib.ps1')

$manifest = Read-LearnManifest -Path $ManifestPath

switch ($Mode) {
    'Snapshot' {
        $snap = New-StudentZoneSnapshot -InstallRoot $InstallRoot -Manifest $manifest
        $snap | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $SnapshotPath -Encoding utf8NoBOM
        Write-Host "Snapshot written: $SnapshotPath ($($snap.files.Count) files)"
        if ($snap.files.Count -eq 0) {
            Write-Host 'WARNING: student-zone snapshot scope resolved to 0 files - check studentRoots and InstallRoot.'
        }
        exit 0
    }
    'Verify' {
        $beforeRaw = Get-Content -LiteralPath $SnapshotPath -Raw | ConvertFrom-Json -AsHashtable
        $before = [pscustomobject]@{
            installRoot = $beforeRaw.installRoot
            files       = $beforeRaw.files
        }
        $after  = New-StudentZoneSnapshot -InstallRoot $InstallRoot -Manifest $manifest
        if ($before.files.Count -eq 0 -and $after.files.Count -eq 0) {
            Write-Host 'WARNING: student-zone snapshot scope resolved to 0 files - check studentRoots and InstallRoot.'
        }
        $result = Test-StudentZoneUntouched -Before $before -After $after
        if ($result.passed) {
            Write-Host 'STUDENT ZONE OK - untouched.'
            exit 0
        }
        Write-Host 'STUDENT ZONE VIOLATION:'
        foreach ($f in $result.modified) { Write-Host "  modified: $f" }
        foreach ($f in $result.missing)  { Write-Host "  missing:  $f" }
        foreach ($f in $result.added)    { Write-Host "  added:    $f" }
        exit 1
    }
}
