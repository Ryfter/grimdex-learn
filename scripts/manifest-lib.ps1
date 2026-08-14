Set-StrictMode -Version 3.0

$script:RequiredManifestFields = @(
    'schemaVersion', 'moduleId', 'ownedPaths', 'pointerStanzas',
    'neverShip', 'studentRoots', 'generatedRoots', 'lifecycle'
)

$script:ForbiddenManifestKeys = @(
    'hooks', 'hook', 'exec', 'execute', 'run', 'command', 'commands',
    'script', 'scripts', 'shell', 'onInstall', 'onUpdate', 'onRemove', 'onGraduate'
)

function Assert-NoExecutableKeys {
    param($Node, [string]$Trail)

    if ($Node -is [System.Collections.IDictionary]) {
        foreach ($key in @($Node.Keys)) {
            if ($script:ForbiddenManifestKeys -contains $key) {
                throw "Executable hook declaration forbidden by D28: '$Trail.$key'"
            }
            Assert-NoExecutableKeys -Node $Node[$key] -Trail "$Trail.$key"
        }
    } elseif ($Node -is [System.Collections.IEnumerable] -and $Node -isnot [string]) {
        $i = 0
        foreach ($item in $Node) {
            Assert-NoExecutableKeys -Node $item -Trail "$Trail[$i]"
            $i++
        }
    }
}

function Get-EffectiveStudentRoots {
    <#
      The student-root patterns a check must actually enforce: whatever the manifest
      declares, UNIONED with the built-in floor. Call this instead of reading
      $Manifest.studentRoots directly anywhere the student-zone guarantee is enforced.
      Returns the manifest's own roots unchanged when the floor is already present.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Manifest)

    $floor = 'projects/**'
    $roots = @()
    if (($Manifest -is [System.Collections.IDictionary]) -and $Manifest.ContainsKey('studentRoots')) {
        $roots = @($Manifest['studentRoots'])
    } elseif ($null -ne $Manifest -and $null -ne $Manifest.PSObject.Properties['studentRoots']) {
        $roots = @($Manifest.studentRoots)
    }
    foreach ($r in $roots) {
        if ($null -eq $r) { continue }
        $norm = (([string]$r) -replace '\\', '/').Trim()
        if ([string]::Equals($norm, $floor, [System.StringComparison]::OrdinalIgnoreCase)) {
            return @($roots)
        }
    }
    @($roots) + $floor
}

function Get-ManifestPin {
    <#
      The base-Grimdex pin a manifest declares, or $null when it declares none.
      A Learn pack is NOT required to be version-matched (D27, amended 2026-08-02):
      pages explaining external tools do not go stale when the base engine cuts a
      release, so pinning is opt-in. Every consumer calls this instead of reaching
      into baseGrimdex.pin, so "is this pack pinned?" has exactly one answer.
      Handles both manifest shapes: the hashtable Read-LearnManifest returns and a
      PSCustomObject built directly by a caller or a test.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Manifest)

    $base = $null
    if ($Manifest -is [System.Collections.IDictionary]) {
        if ($Manifest.ContainsKey('baseGrimdex')) { $base = $Manifest['baseGrimdex'] }
    } elseif ($null -ne $Manifest -and $null -ne $Manifest.PSObject.Properties['baseGrimdex']) {
        $base = $Manifest.baseGrimdex
    }
    if ($null -eq $base) { return $null }

    $pin = $null
    if ($base -is [System.Collections.IDictionary]) {
        if ($base.ContainsKey('pin')) { $pin = [string]$base['pin'] }
    } elseif ($null -ne $base.PSObject.Properties['pin']) {
        $pin = [string]$base.pin
    }
    if ([string]::IsNullOrWhiteSpace($pin)) { return $null }
    # The historical placeholder means "never set", not "matched to a tag literally
    # named PINNED-RELEASE-TAG-SET-AT-INSTALL-PLAN". Manifests in the wild carry it.
    if ($pin.Trim() -eq 'PINNED-RELEASE-TAG-SET-AT-INSTALL-PLAN') { return $null }
    $pin.Trim()
}

function Read-LearnManifest {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Manifest not found: $Path"
    }
    $raw = Get-Content -LiteralPath $Path -Raw
    try {
        $manifest = $raw | ConvertFrom-Json -AsHashtable -Depth 20
    } catch {
        throw "Manifest is not valid JSON: $($_.Exception.Message)"
    }
    $missing = @($script:RequiredManifestFields | Where-Object { -not $manifest.ContainsKey($_) })
    if ($missing.Count -gt 0) {
        throw "Manifest missing required fields: $($missing -join ', ')"
    }

    $studentRoots = $manifest['studentRoots']
    $isEnumerable = ($studentRoots -is [System.Collections.IEnumerable]) -and ($studentRoots -isnot [string])
    $studentRootsValid = $false
    if ($isEnumerable) {
        $rootsArray = @($studentRoots)
        if ($rootsArray.Count -gt 0) {
            $badEntries = @($rootsArray | Where-Object { ($_ -isnot [string]) -or ([string]::IsNullOrEmpty($_)) })
            $studentRootsValid = ($badEntries.Count -eq 0)
        }
    }
    if (-not $studentRootsValid) {
        throw 'Manifest studentRoots must be a non-empty array of path patterns'
    }

    # HARD FLOOR: 'projects/**' is ALWAYS a student root, whatever the manifest says.
    #
    # The manifest is UNTRUSTED DATA. It ships with the module, it can be authored by
    # anyone, and validating its shape says nothing about its intent. "the student's
    # projects/** is never written" is the most important guarantee this design makes,
    # and every check that enforces it reads its scope from this one field:
    # New-InstallPlan's stanza-target and source-file checks, New-GraduationPlan,
    # New-StudentZoneSnapshot / Test-StudentZoneUntouched (the pre/post verify), and
    # the out-of-band scripts/verify-student-zone.ps1. A manifest that could REPLACE
    # studentRoots would relocate the protected zone and blind all of them at once —
    # e.g. studentRoots ["some-other-dir/**"] plus a pointer stanza aimed at
    # projects/mine/notes.md writes the student's own file and still reports
    # verify.passed. So the manifest's value is UNIONED with the built-in floor, never
    # substituted for it: a manifest may only ever ADD protected roots, never remove or
    # relocate the built-in one. Do not turn this back into an assignment.
    # Applying the floor here alone would be POSITIONAL protection: it only binds
    # manifests that arrived through this function. Every enforcement point calls
    # Get-EffectiveStudentRoots instead of reading the field, so the floor holds
    # however the manifest object was obtained.
    $manifest['studentRoots'] = @(Get-EffectiveStudentRoots -Manifest $manifest)

    Assert-NoExecutableKeys -Node $manifest -Trail 'manifest'
    return $manifest
}
