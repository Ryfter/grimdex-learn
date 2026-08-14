# UR-001 EDU-side fallback: render a "where you were -> where you are"
# readout from the local learn-mode ledger (config/learn-progress.json).
# Read-only over the install; the ledger is neverShip and stays local.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InstallRoot,
    [string]$OutFile
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

if ($OutFile) {
    $rootFull   = [System.IO.Path]::GetFullPath($InstallRoot).TrimEnd('\', '/')
    $rootPrefix = $rootFull + [System.IO.Path]::DirectorySeparatorChar
    $outFull    = [System.IO.Path]::GetFullPath($OutFile)
    if ($outFull.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Error "OutFile must be outside the install root (the readout is not install content)."
        exit 1
    }
}

$ledgerPath = Join-Path $InstallRoot 'config/learn-progress.json'
$lines = @('# Promotion readout', '')
if (-not (Test-Path -LiteralPath $ledgerPath)) {
    $lines += 'No learn-mode ledger found at config/learn-progress.json — nothing to report.'
} else {
    $ledger = Get-Content -LiteralPath $ledgerPath -Raw | ConvertFrom-Json
    $modules = if ($ledger.PSObject.Properties.Name -contains 'modules') { $ledger.modules } else { $null }
    if ($null -eq $modules -or @($modules.PSObject.Properties).Count -eq 0) {
        $lines += 'Ledger present but records no module progress yet.'
    } else {
        $lines += 'Recorded learn-mode progress (data already kept locally — no ceremony):'
        $lines += ''
        foreach ($prop in $modules.PSObject.Properties) {
            $detail = ($prop.Value | ConvertTo-Json -Compress -Depth 5)
            $lines += "- **$($prop.Name)** — $detail"
        }
    }
}

$text = $lines -join [Environment]::NewLine
Write-Output $text
if ($OutFile) { Set-Content -LiteralPath $OutFile -Value $text }
exit 0
