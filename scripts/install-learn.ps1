# Learn install / composition CLI. Per D6/D18 there is no installer product:
# an agent follows INSTALL.md and runs this script.
# Exit codes: 0 installed or previewed, 1 invalid plan or aborted before any
# change, 2 post-state verify failed (changes rolled back).
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SourceRoot,
    [Parameter(Mandatory)][string]$InstallRoot,
    [Parameter(Mandatory)][string]$ManifestPath,
    [Parameter(Mandatory)][string]$WorkDir,
    [switch]$Preview
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'manifest-lib.ps1')
. (Join-Path $PSScriptRoot 'verify-lib.ps1')
. (Join-Path $PSScriptRoot 'stanza-lib.ps1')
. (Join-Path $PSScriptRoot 'lifecycle-lib.ps1')
. (Join-Path $PSScriptRoot 'install-lib.ps1')

# $invokeArgs, never $args - $args is an automatic variable.
$invokeArgs = @{
    SourceRoot   = $SourceRoot
    InstallRoot  = $InstallRoot
    ManifestPath = $ManifestPath
    WorkDir      = $WorkDir
}
if ($Preview) { $invokeArgs['Preview'] = $true }

# Manifest reading and orchestration are wrapped so a malformed manifest or a
# bad WorkDir produces a clear message and a deliberate exit code, never a raw
# stack trace.
try {
    $result = Invoke-LearnInstall @invokeArgs
} catch {
    Write-Host "INSTALL ABORTED - $($_.Exception.Message)"
    Write-Host 'Nothing was installed. Fix the reported problem and run the preview again.'
    exit 1
}

switch ($result.status) {
    'previewed' {
        Write-Host "PREVIEW - no changes made. Mode: $($result.plan.mode)."
        Write-Host "  source root:  $SourceRoot"
        Write-Host "  install root: $InstallRoot"
        Write-Host "  files to copy: $($result.plan.copies.Count)"
        foreach ($s in $result.plan.stanzaFiles) {
            Write-Host "  pointer stanza: $($s.rel) (current state: $($s.state))"
        }
        Write-Host '  student paths (projects/**) are never written by install.'
        exit 0
    }
    'installed' {
        Write-Host "INSTALLED. Mode: $($result.plan.mode). Files: $($result.plan.copies.Count)."
        foreach ($a in $result.stanzaActions) {
            Write-Host "  pointer stanza $($a.rel): $($a.action)"
        }
        exit 0
    }
    'invalid-plan' {
        Write-Host 'INVALID PLAN - nothing changed:'
        foreach ($e in $result.errors) { Write-Host "  - $e" }
        exit 1
    }
    'rolled-back' {
        # 'rolled-back' covers three different situations and they must not be
        # reported with the same sentence. Claiming "changes rolled back" when
        # the rollback ITSELF failed is the worst of the three: it tells an
        # agent the install is clean when it may be half-applied.
        $rollbackFailed = @($result.failures | Where-Object { $_ -like 'Rollback itself failed*' }).Count -gt 0
        $installError   = @($result.failures | Where-Object { $_ -like 'Install aborted by an error during install*' }).Count -gt 0
        if ($rollbackFailed) {
            Write-Host '*** ROLLBACK FAILED - INSTALL MAY BE PARTIALLY CHANGED ***'
            Write-Host 'Install hit an error AND could not undo its own changes. Do NOT assume this'
            Write-Host 'install is clean: learn/ and the pointer stanza files may be partially'
            Write-Host 'written. Inspect the install manually before using or re-running it.'
            Write-Host 'Reported problems:'
        } elseif ($installError) {
            Write-Host 'INSTALL ERROR - install failed partway and its changes were rolled back:'
        } else {
            Write-Host 'VERIFY FAILED - install changes rolled back:'
        }
        foreach ($f in $result.failures) { Write-Host "  - $f" }
        if ($result.studentZoneUnrepaired) {
            Write-Host ''
            Write-Host '*** STUDENT ZONE NOT REPAIRED ***'
            Write-Host 'Install-owned files (learn/ and the pointer stanzas) were restored from'
            Write-Host 'backup. A change was ALSO detected under the student''s own paths (projects/**),'
            Write-Host 'and that change was NOT reverted - this installer never copies the student'
            Write-Host 'zone anywhere, by design, so it has no backup to restore it from. Inspect the'
            Write-Host 'paths below yourself:'
            foreach ($f in $result.failures) {
                if ($f -like 'Student file *') { Write-Host "  - $f" }
            }
        }
        exit 2
    }
    default {
        Write-Host "UNEXPECTED STATUS '$($result.status)' - treat the install as failed."
        exit 2
    }
}
