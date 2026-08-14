Set-StrictMode -Version 3.0

# Requires stanza-lib.ps1, verify-lib.ps1, and manifest-lib.ps1 to be
# dot-sourced by the caller (stanza-lib needs Get-ManifestPin).
# (graduate.ps1 does this; tests do it in BeforeAll).

function Test-RelPathUnder {
    param(
        [string]$InstallRoot,
        [string]$Rel,
        [string[]]$RootPatterns
    )
    # Resolved-path containment: rejects rooted paths and ../ traversal that
    # would escape the pattern's directory, regardless of lexical prefix.
    if ([System.IO.Path]::IsPathRooted($Rel)) { return $false }
    $rootFull = [System.IO.Path]::GetFullPath($InstallRoot)
    $relFull  = [System.IO.Path]::GetFullPath((Join-Path $rootFull $Rel))
    foreach ($p in $RootPatterns) {
        $prefixRel  = ($p -replace '[\\/]\*\*$', '').TrimEnd('/', '\')
        $prefixFull = [System.IO.Path]::GetFullPath((Join-Path $rootFull $prefixRel)).TrimEnd('\', '/') +
                      [System.IO.Path]::DirectorySeparatorChar
        if ($relFull.StartsWith($prefixFull, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    $false
}

function New-GraduationPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)][ValidateSet('Keep', 'Remove')][string]$Retention,
        [hashtable]$RetentionCopy = @{}
    )

    $errors = @()
    $coursePresent = Test-Path -LiteralPath (Join-Path $InstallRoot 'course')
    $learnPresent  = Test-Path -LiteralPath (Join-Path $InstallRoot 'learn')

    $stanzaFiles = @($Manifest.pointerStanzas | ForEach-Object { $_.file -replace '\\', '/' })
    # Which of those stanza files actually exist right now (i.e. Backup-GraduationTargets
    # will actually back them up). Restore-GraduationBackup uses this — not the plain
    # stanzaFiles list — to know which backups it is entitled to expect, since Remove
    # retention does not require a stanza target to exist (unlike install's plan).
    $stanzaFilesPresent = @()
    $rootFullForStanza = [System.IO.Path]::GetFullPath($InstallRoot).TrimEnd('\', '/')
    foreach ($f in $stanzaFiles) {
        $contained = $false
        if (-not [System.IO.Path]::IsPathRooted($f)) {
            $fFull = [System.IO.Path]::GetFullPath((Join-Path $rootFullForStanza $f))
            $contained = $fFull.StartsWith($rootFullForStanza + [System.IO.Path]::DirectorySeparatorChar,
                [System.StringComparison]::OrdinalIgnoreCase)
        }
        if (-not $contained) {
            $errors += "Stanza file '$f' escapes the install root."
            continue
        }
        if (Test-RelPathUnder -InstallRoot $InstallRoot -Rel $f -RootPatterns (Get-EffectiveStudentRoots -Manifest $Manifest)) {
            $errors += "Stanza file '$f' is inside a student root; base-owned stanza files cannot live there."
            continue
        }
        $state = (Get-PointerStanzaState -Path (Join-Path $InstallRoot $f)).state
        if ($state -ne 'missing-file') { $stanzaFilesPresent += $f }
        if ($state -eq 'malformed') {
            $errors += "Stanza file '$f' has malformed grimdex-learn markers."
        }
        if ($Retention -eq 'Keep' -and $state -ne 'well-formed') {
            $errors += "Retention Keep requires a well-formed stanza in '$f' (found: $state)."
        }
    }

    $retentionCopies = @()
    if ($Retention -eq 'Keep' -and $RetentionCopy.Count -gt 0) {
        $errors += 'Retention copies are only valid with -Retention Remove (Keep retains all of learn/).'
    }
    if ($Retention -eq 'Remove') {
        $destSeen = @{}
        foreach ($source in $RetentionCopy.Keys) {
            $dest = [string]$RetentionCopy[$source]
            $destNorm = ($dest -replace '\\', '/')
            if ($destSeen.ContainsKey($destNorm)) {
                $errors += "Retention dest '$dest' is mapped from more than one source."
                continue
            }
            $destSeen[$destNorm] = $true
            $srcRel = $source -replace '\\', '/'
            if (-not (Test-RelPathUnder -InstallRoot $InstallRoot -Rel $srcRel -RootPatterns @($Manifest.ownedPaths | ForEach-Object { "$_**" }))) {
                $errors += "Retention source '$source' is not under a learn-owned path."
                continue
            }
            $srcAbs = Join-Path $InstallRoot $source
            if (-not (Test-Path -LiteralPath $srcAbs -PathType Leaf)) {
                $errors += "Retention source '$source' does not exist."
                continue
            }
            if (-not (Test-RelPathUnder -InstallRoot $InstallRoot -Rel $dest -RootPatterns (Get-EffectiveStudentRoots -Manifest $Manifest))) {
                $errors += "Retention dest '$dest' is not under a student root."
                continue
            }
            $destAbs = Join-Path $InstallRoot $dest
            if (Test-Path -LiteralPath $destAbs) {
                $errors += "Retention dest '$dest' already exists; graduation never overwrites student files."
                continue
            }
            $retentionCopies += [pscustomobject]@{
                source = $srcRel
                dest   = ($dest -replace '\\', '/')
                hash   = (Get-FileHash -LiteralPath $srcAbs -Algorithm SHA256).Hash
            }
        }
    }

    $neverShipPresent = @()
    foreach ($n in $Manifest.neverShip) {
        if (Test-Path -LiteralPath (Join-Path $InstallRoot $n)) {
            $neverShipPresent += ($n -replace '\\', '/')
        }
    }

    [pscustomobject]@{
        retention           = $Retention
        coursePresent       = $coursePresent
        learnPresent        = $learnPresent
        stanzaFiles         = @($stanzaFiles)
        stanzaFilesPresent  = @($stanzaFilesPresent)
        retentionCopies     = @($retentionCopies)
        neverShipPresent    = @($neverShipPresent | Sort-Object)
        errors              = @($errors)
    }
}

function Backup-GraduationTargets {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)]$Plan,
        [Parameter(Mandatory)][string]$BackupDir
    )

    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    $backedUp = @()

    $targets = @()
    if ($Plan.coursePresent) { $targets += 'course' }
    if ($Plan.retention -eq 'Remove' -and $Plan.learnPresent) { $targets += 'learn' }
    $targets += @($Plan.stanzaFiles)

    foreach ($rel in $targets) {
        $src = Join-Path $InstallRoot $rel
        if (-not (Test-Path -LiteralPath $src)) { continue }
        $dst = Join-Path $BackupDir $rel
        New-Item -ItemType Directory -Path (Split-Path -Parent $dst) -Force | Out-Null
        Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
        $backedUp += ($rel -replace '\\', '/')
    }

    # Record which parent directories of retention dests do NOT yet exist —
    # these are the only dirs rollback is allowed to prune.
    $createdDirs = @()
    foreach ($copy in $Plan.retentionCopies) {
        $dir = Split-Path -Parent (Join-Path $InstallRoot $copy.dest)
        while ($dir -and -not (Test-Path -LiteralPath $dir)) {
            $createdDirs += $dir
            $dir = Split-Path -Parent $dir
        }
    }
    $createdDirs = @($createdDirs | Select-Object -Unique)
    ConvertTo-Json -AsArray $createdDirs |
        Set-Content -LiteralPath (Join-Path $BackupDir 'created-dirs.json')

    [pscustomobject]@{ backedUp = @($backedUp) }
}

function Restore-GraduationBackup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)]$Plan,
        [Parameter(Mandatory)][string]$BackupDir
    )

    # Verify the backup is complete BEFORE any destructive removal below.
    # 'course' is expected whenever Plan.coursePresent was true; 'learn' only
    # when retention is Remove and Plan.learnPresent was true (Keep never backs
    # it up, because Keep never mutates it); each pointer-stanza file only when
    # it existed at plan time (Plan.stanzaFilesPresent — Remove retention does
    # not require a stanza target to exist, unlike install's plan, so a bare
    # Plan.stanzaFiles would over-claim). This mirrors exactly what
    # Backup-GraduationTargets actually copied. If a backup that should exist
    # is missing — the backup directory was cleared, the process was
    # interrupted mid-backup, or restore is being called against the wrong
    # directory — continuing would delete live content with nothing to put
    # back in its place. Abort here, before anything is touched, rather than
    # silently skipping it (which used to leave the live file just deleted)
    # or deleting course/learn and then finding there was nothing to copy back.
    if ($Plan.coursePresent) {
        $bakCourse = Join-Path $BackupDir 'course'
        if (-not (Test-Path -LiteralPath $bakCourse)) {
            throw "Restore-GraduationBackup: expected backup for 'course' at '$bakCourse' but it is missing. The backup directory is missing or incomplete; nothing has been touched."
        }
    }
    if ($Plan.retention -eq 'Remove' -and $Plan.learnPresent) {
        $bakLearn = Join-Path $BackupDir 'learn'
        if (-not (Test-Path -LiteralPath $bakLearn)) {
            throw "Restore-GraduationBackup: retention is 'Remove' but the expected backup of 'learn/' at '$bakLearn' is missing. The backup directory is missing or incomplete; nothing has been touched."
        }
    }
    foreach ($f in $Plan.stanzaFilesPresent) {
        $bakStanza = Join-Path $BackupDir $f
        if (-not (Test-Path -LiteralPath $bakStanza -PathType Leaf)) {
            throw "Restore-GraduationBackup: expected backup for stanza file '$f' at '$bakStanza' but it is missing. The backup directory is missing or incomplete; nothing has been touched."
        }
    }

    # Undo retention copies first: delete exactly the dest files this
    # graduation created, then prune any directories that became empty —
    # never anything else under a student root.
    $createdDirsPath = Join-Path $BackupDir 'created-dirs.json'
    $createdDirs = @()
    if (Test-Path -LiteralPath $createdDirsPath) {
        $createdDirs = @([string[]]([string](Get-Content -LiteralPath $createdDirsPath -Raw) | ConvertFrom-Json))
    }
    foreach ($copy in $Plan.retentionCopies) {
        $destAbs = Join-Path $InstallRoot $copy.dest
        if (Test-Path -LiteralPath $destAbs) {
            Remove-Item -LiteralPath $destAbs -Force
        }
    }
    # Prune ONLY dirs recorded as created by this graduation, deepest first,
    # and only if empty — a pre-existing student directory is never touched.
    # Where-Object drops nulls explicitly: an empty created-dirs.json ('[]')
    # round-trips into a one-element array holding $null, and
    # Test-Path -LiteralPath $null throws under $ErrorActionPreference='Stop'.
    # Sort-Object happens to discard that element today, but rollback safety
    # must not rest on a side effect of sorting.
    foreach ($dir in ($createdDirs | Where-Object { $_ } | Sort-Object -Property Length -Descending)) {
        if ((Test-Path -LiteralPath $dir) -and -not (Get-ChildItem -LiteralPath $dir -Force)) {
            Remove-Item -LiteralPath $dir -Force
        }
    }

    # Restore backed-up trees: remove the (possibly mutated) live copy,
    # then copy the backup back in.
    foreach ($rel in @('course', 'learn') + @($Plan.stanzaFiles)) {
        $bak = Join-Path $BackupDir $rel
        if (-not (Test-Path -LiteralPath $bak)) { continue }
        $live = Join-Path $InstallRoot $rel
        if (Test-Path -LiteralPath $live) {
            Remove-Item -LiteralPath $live -Recurse -Force
        }
        New-Item -ItemType Directory -Path (Split-Path -Parent $live) -Force | Out-Null
        Copy-Item -LiteralPath $bak -Destination $live -Recurse -Force
    }
}

function Test-GraduationPostState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)]$Plan,
        [Parameter(Mandatory)]$BeforeSnapshot
    )

    $failures = @()

    # Course always detaches.
    if (Test-Path -LiteralPath (Join-Path $InstallRoot 'course')) {
        $failures += "course/ still present — course must detach on every graduation."
    }

    # Learn per retention choice.
    $learnExists = Test-Path -LiteralPath (Join-Path $InstallRoot 'learn')
    if ($Plan.retention -eq 'Keep' -and -not $learnExists) {
        $failures += "learn/ missing — retention Keep must leave the Learn module intact."
    }
    if ($Plan.retention -eq 'Remove' -and $learnExists) {
        $failures += "learn/ still present — retention Remove must strip the Learn module."
    }

    # Stanzas per retention choice.
    foreach ($f in $Plan.stanzaFiles) {
        $state = (Get-PointerStanzaState -Path (Join-Path $InstallRoot $f)).state
        if ($Plan.retention -eq 'Keep' -and $state -ne 'well-formed') {
            $failures += "Stanza in '$f' not well-formed after Keep graduation (found: $state)."
        }
        if ($Plan.retention -eq 'Remove' -and $state -notin 'absent', 'missing-file') {
            $failures += "Stanza markers survive in '$f' after Remove graduation (found: $state)."
        }
    }

    # Student zone: untouched except the exact allow-listed retention copies.
    $after = New-StudentZoneSnapshot -InstallRoot $InstallRoot -Manifest $Manifest
    $zone  = Test-StudentZoneUntouched -Before $BeforeSnapshot -After $after
    foreach ($rel in $zone.modified) { $failures += "Student file modified: $rel" }
    foreach ($rel in $zone.missing)  { $failures += "Student file missing: $rel" }
    $allowed = @{}
    foreach ($copy in $Plan.retentionCopies) { $allowed[$copy.dest] = $copy.hash }
    foreach ($rel in $zone.added) {
        if (-not $allowed.ContainsKey($rel)) {
            $failures += "Unexpected student-zone addition: $rel"
        } elseif ($after.files[$rel] -ne $allowed[$rel]) {
            $failures += "Retention copy content mismatch at: $rel"
        }
    }
    foreach ($dest in $allowed.Keys) {
        if (-not $after.files.ContainsKey($dest)) {
            $failures += "Planned retention copy missing: $dest"
        }
    }

    # neverShip files that existed before must still exist (never deleted, never exported).
    foreach ($n in $Plan.neverShipPresent) {
        if (-not (Test-Path -LiteralPath (Join-Path $InstallRoot $n))) {
            $failures += "neverShip file disappeared: $n"
        }
    }

    [pscustomobject]@{
        passed   = ($failures.Count -eq 0)
        failures = @($failures)
    }
}

function Invoke-Graduation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)][string]$ManifestPath,
        [ValidateSet('Keep', 'Remove')][string]$Retention = 'Keep',  # default KEEP (amended D19)
        [Parameter(Mandatory)][string]$WorkDir,
        [hashtable]$RetentionCopy = @{},
        [switch]$Preview,
        [scriptblock]$PostMutateHook  # test seam: runs between mutation and verify
    )

    # Prefix-safe containment check: 'install-work' is NOT under 'install'.
    $rootFull   = [System.IO.Path]::GetFullPath($InstallRoot).TrimEnd('\', '/')
    $rootPrefix = $rootFull + [System.IO.Path]::DirectorySeparatorChar
    $workFull   = [System.IO.Path]::GetFullPath($WorkDir).TrimEnd('\', '/')
    if ($workFull.Equals($rootFull, [System.StringComparison]::OrdinalIgnoreCase) -or
        $workFull.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "WorkDir must be outside the install root (got '$WorkDir' under '$InstallRoot')."
    }

    $manifest = Read-LearnManifest -Path $ManifestPath
    $plan = New-GraduationPlan -InstallRoot $InstallRoot -Manifest $manifest `
        -Retention $Retention -RetentionCopy $RetentionCopy

    if ($plan.errors.Count -gt 0) {
        return [pscustomobject]@{ outcome = 'invalid-plan'; plan = $plan; verify = $null; failures = @() }
    }
    if ($Preview) {
        return [pscustomobject]@{ outcome = 'previewed'; plan = $plan; verify = $null; failures = @() }
    }

    New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
    $backupDir = Join-Path $WorkDir 'backup'
    # Start from a clean backup so a reused WorkDir cannot restore stale files
    # (e.g. a 'learn/' tree left over from a prior Remove-retention run leaking
    # into a later Keep-retention rollback that never touches learn/ at all).
    if (Test-Path -LiteralPath $backupDir) { Remove-Item -LiteralPath $backupDir -Recurse -Force }

    $before = New-StudentZoneSnapshot -InstallRoot $InstallRoot -Manifest $manifest
    Backup-GraduationTargets -InstallRoot $InstallRoot -Plan $plan -BackupDir $backupDir | Out-Null

    # Mutate-and-verify, guarded: $ErrorActionPreference = 'Stop' (set by the
    # CLI) means any of Copy-Item / Remove-Item / Remove-PointerStanza throwing
    # here (a file lock, permission error, antivirus interference) would
    # otherwise escape this function with the install half-graduated and the
    # backup never consulted — rollback would never run. Catch it, attempt
    # rollback, and report a distinct status rather than let the exception
    # propagate.
    $verify          = $null
    $mutateException = $null
    try {
        # Retention copies first, then detach course, then apply retention.
        foreach ($copy in $plan.retentionCopies) {
            $destAbs = Join-Path $InstallRoot $copy.dest
            New-Item -ItemType Directory -Path (Split-Path -Parent $destAbs) -Force | Out-Null
            Copy-Item -LiteralPath (Join-Path $InstallRoot $copy.source) -Destination $destAbs
        }
        $coursePath = Join-Path $InstallRoot 'course'
        if (Test-Path -LiteralPath $coursePath) {
            Remove-Item -LiteralPath $coursePath -Recurse -Force
        }
        if ($Retention -eq 'Remove') {
            foreach ($f in $plan.stanzaFiles) {
                Remove-PointerStanza -Path (Join-Path $InstallRoot $f) | Out-Null
            }
            $learnPath = Join-Path $InstallRoot 'learn'
            if (Test-Path -LiteralPath $learnPath) {
                Remove-Item -LiteralPath $learnPath -Recurse -Force
            }
        }

        if ($PostMutateHook) { & $PostMutateHook $InstallRoot }

        $verify = Test-GraduationPostState -InstallRoot $InstallRoot -Manifest $manifest `
            -Plan $plan -BeforeSnapshot $before
    } catch {
        $mutateException = $_.Exception.Message
    }

    if ($mutateException) {
        $failures = @("Graduation aborted by an error during graduation (not a verify failure): $mutateException")
        try {
            Restore-GraduationBackup -InstallRoot $InstallRoot -Plan $plan -BackupDir $backupDir
        } catch {
            # Never let a rollback failure hide the original error - report both.
            $failures += "Rollback itself failed: $($_.Exception.Message)"
        }
        return [pscustomobject]@{ outcome = 'rolled-back'; plan = $plan; verify = $null; failures = @($failures) }
    }

    if (-not $verify.passed) {
        $failures = @($verify.failures)
        try {
            Restore-GraduationBackup -InstallRoot $InstallRoot -Plan $plan -BackupDir $backupDir
        } catch {
            $failures += "Rollback itself failed: $($_.Exception.Message)"
        }
        return [pscustomobject]@{ outcome = 'rolled-back'; plan = $plan; verify = $verify; failures = @($failures) }
    }
    [pscustomobject]@{ outcome = 'graduated'; plan = $plan; verify = $verify; failures = @() }
}
