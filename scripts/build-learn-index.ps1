# Builds learn/index.json from capability-page front matter (lesson-surfacing
# design §6 step 1). Run after adding, renaming, or re-levelling a page.
# Exit codes: 0 written or current, 1 -Check found it stale, 2 a page could not be indexed.
[CmdletBinding()]
param(
    [string]$RepoRoot = (Join-Path $PSScriptRoot '..'),
    [switch]$Check
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'learn-index-lib.ps1')

$outPath = Join-Path $RepoRoot 'learn' 'index.json'
try {
    $index = New-LearnIndex -RepoRoot $RepoRoot
    $json  = ConvertTo-LearnIndexJson -Index $index
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    exit 2
}

$current = $null
if (Test-Path -LiteralPath $outPath) {
    $current = ([System.IO.File]::ReadAllText($outPath)) -replace "`r`n", "`n"
}
if ($Check) {
    if ($current -ceq $json) {
        Write-Host "OK: learn/index.json is current ($(@($index.lessons).Count) lessons)."
        exit 0
    }
    Write-Host 'STALE: learn/index.json does not match the pages; run scripts/build-learn-index.ps1.'
    exit 1
}
[System.IO.File]::WriteAllText($outPath, $json, [System.Text.UTF8Encoding]::new($false))
Write-Host "Wrote learn/index.json ($(@($index.lessons).Count) lessons)."
exit 0
