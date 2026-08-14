# Graduation CLI (D19 in-place path). Exit codes: 0 previewed/graduated,
# 1 invalid plan, 2 post-state verify failed (changes rolled back).
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InstallRoot,
    [Parameter(Mandatory)][string]$ManifestPath,
    [ValidateSet('Keep', 'Remove')][string]$Retention = 'Keep',  # default KEEP (amended D19)
    [Parameter(Mandatory)][string]$WorkDir,
    [string]$RetentionCopyJson,
    [switch]$Preview
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'manifest-lib.ps1')
. (Join-Path $PSScriptRoot 'verify-lib.ps1')
. (Join-Path $PSScriptRoot 'stanza-lib.ps1')
. (Join-Path $PSScriptRoot 'lifecycle-lib.ps1')

$retentionCopy = @{}
if ($RetentionCopyJson) {
    $map = Get-Content -LiteralPath $RetentionCopyJson -Raw | ConvertFrom-Json
    foreach ($prop in $map.PSObject.Properties) { $retentionCopy[$prop.Name] = [string]$prop.Value }
}

$invokeArgs = @{
    InstallRoot  = $InstallRoot
    ManifestPath = $ManifestPath
    Retention    = $Retention
    WorkDir      = $WorkDir
    RetentionCopy = $retentionCopy
}
if ($Preview) { $invokeArgs['Preview'] = $true }
$result = Invoke-Graduation @invokeArgs

switch ($result.outcome) {
    'previewed' {
        Write-Host "PREVIEW — no changes made. Retention: $($result.plan.retention)."
        Write-Host "  course/ present: $($result.plan.coursePresent) (will be removed)"
        Write-Host "  learn/ present:  $($result.plan.learnPresent) (action: $(if ($Retention -eq 'Keep') { 'keep intact' } else { 'strip module + stanzas' }))"
        foreach ($c in $result.plan.retentionCopies) { Write-Host "  retention copy: $($c.source) -> $($c.dest)" }
        exit 0
    }
    'graduated' {
        Write-Host "GRADUATED. Post-state verify passed for retention $($result.plan.retention)."
        exit 0
    }
    'invalid-plan' {
        Write-Host "INVALID PLAN — nothing changed:"
        foreach ($e in $result.plan.errors) { Write-Host "  - $e" }
        exit 1
    }
    'rolled-back' {
        # 'rolled-back' covers three different situations and they must not be
        # reported with the same sentence. Claiming "changes rolled back" when
        # the rollback ITSELF failed is the worst of the three: it tells an
        # agent the graduation is clean when it may be half-applied.
        $rollbackFailed = @($result.failures | Where-Object { $_ -like 'Rollback itself failed*' }).Count -gt 0
        $mutateError    = @($result.failures | Where-Object { $_ -like 'Graduation aborted by an error during graduation*' }).Count -gt 0
        if ($rollbackFailed) {
            Write-Host '*** ROLLBACK FAILED - GRADUATION MAY BE PARTIALLY CHANGED ***'
            Write-Host 'Graduation hit an error AND could not undo its own changes. Do NOT assume this'
            Write-Host 'install is clean: course/, learn/, and the pointer stanza files may be'
            Write-Host 'partially changed. Inspect the install manually before using or re-running it.'
            Write-Host 'Reported problems:'
        } elseif ($mutateError) {
            Write-Host 'GRADUATION ERROR - graduation failed partway and its changes were rolled back:'
        } else {
            Write-Host "VERIFY FAILED — graduation changes rolled back:"
        }
        foreach ($f in $result.failures) { Write-Host "  - $f" }
        exit 2
    }
    default {
        Write-Host "UNEXPECTED OUTCOME '$($result.outcome)' - treat the graduation as failed."
        exit 2
    }
}
