Set-StrictMode -Version 3.0

# Requires manifest-lib.ps1 to be dot-sourced by the caller: the student-zone
# snapshot enforces the 'projects/**' floor via Get-EffectiveStudentRoots rather
# than trusting the manifest's own studentRoots value.

function New-StudentZoneSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)]$Manifest
    )

    $files = @{}
    foreach ($rootPattern in (Get-EffectiveStudentRoots -Manifest $Manifest)) {
        # 'projects/**' -> 'projects'
        $rootDir = $rootPattern -replace '[\\/]\*\*$', ''
        $abs = Join-Path $InstallRoot $rootDir
        if (-not (Test-Path -LiteralPath $abs)) { continue }
        foreach ($file in (Get-ChildItem -LiteralPath $abs -Recurse -File -Force)) {
            $rel = [System.IO.Path]::GetRelativePath($InstallRoot, $file.FullName) -replace '\\', '/'
            $files[$rel] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        }
    }
    [pscustomobject]@{
        installRoot = $InstallRoot
        files       = $files
    }
}

function Test-StudentZoneUntouched {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Before,
        [Parameter(Mandatory)]$After
    )

    $modified = @()
    $missing  = @()
    $added    = @()

    foreach ($rel in $Before.files.Keys) {
        if (-not $After.files.ContainsKey($rel)) {
            $missing += $rel
        } elseif ($After.files[$rel] -ne $Before.files[$rel]) {
            $modified += $rel
        }
    }
    foreach ($rel in $After.files.Keys) {
        if (-not $Before.files.ContainsKey($rel)) {
            $added += $rel
        }
    }

    [pscustomobject]@{
        passed   = (($modified.Count + $missing.Count + $added.Count) -eq 0)
        modified = @($modified | Sort-Object)
        missing  = @($missing | Sort-Object)
        added    = @($added | Sort-Object)
    }
}

function Test-BundleExcludesNeverShip {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BundlePath,
        [Parameter(Mandatory)]$Manifest
    )

    $violations = @()
    foreach ($never in $Manifest.neverShip) {
        $candidate = Join-Path $BundlePath $never
        if (Test-Path -LiteralPath $candidate) {
            $violations += ($never -replace '\\', '/')
        }
    }
    [pscustomobject]@{
        passed     = ($violations.Count -eq 0)
        violations = @($violations | Sort-Object)
    }
}
