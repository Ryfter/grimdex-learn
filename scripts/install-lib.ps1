Set-StrictMode -Version 3.0

# Requires manifest-lib.ps1, verify-lib.ps1, stanza-lib.ps1 and lifecycle-lib.ps1
# to be dot-sourced first, in that order (install-learn.ps1 does this; tests do
# it in BeforeAll). Install is the mirror image of graduation and deliberately
# reuses its plan / backup / verify / rollback patterns.

function Test-NeverShipPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)][string]$Rel,
        [Parameter(Mandatory)]$NeverShip
    )
    # Resolved-path comparison, not string equality: Windows silently strips
    # trailing spaces/dots from a path segment, so a manifest could name
    # "config/settings.json " (trailing space) and defeat an -eq / -contains
    # string check while still resolving onto the real protected file.
    # macOS/Linux do not strip, so strip trailing spaces/dots per segment
    # explicitly on every platform: over-matching fails closed, which is the
    # right direction for a secrets guard.
    $normalize = {
        param([string]$p)
        (($p -replace '\\', '/') -split '/' | ForEach-Object { $_.TrimEnd(' ', '.') }) -join '/'
    }
    $rootFull      = [System.IO.Path]::GetFullPath($InstallRoot)
    $candidateFull = & $normalize ([System.IO.Path]::GetFullPath((Join-Path $rootFull $Rel)))
    foreach ($n in @($NeverShip)) {
        $nRel  = ([string]$n) -replace '\\', '/'
        $nFull = & $normalize ([System.IO.Path]::GetFullPath((Join-Path $rootFull $nRel)))
        if ([string]::Equals($candidateFull, $nFull, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Test-RelPathHasColon {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Rel)
    # A legitimate relative path inside an install NEVER contains a colon. On
    # Windows a colon carries two hidden meanings that both defeat the guards:
    #   - NTFS alternate-data-stream syntax ('config/fleet.json::$DATA', or
    #     'config/fleet.json:hidden'), which [IO.Path]::GetFullPath preserves
    #     verbatim, so a resolved-path comparison against neverShip does not
    #     match while Test-Path and every write still land on the REAL file.
    #   - drive-relative form ('C:foo'), which resolves against that drive's
    #     current directory rather than the install root.
    # Reject the character outright, at plan time, before anything touches disk.
    return ([string]$Rel).Contains(':')
}

function New-InstallPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SourceRoot,
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)]$Manifest
    )

    $errors          = @()
    $copies          = @()
    $stanzaFiles     = @()
    $neverShipBefore = @()
    $stanzaContent   = ''
    $mode            = 'fresh'

    # 1. The install root must exist and be a directory.
    $rootOk = Test-Path -LiteralPath $InstallRoot -PathType Container
    if (-not $rootOk) {
        $errors += "Install root '$InstallRoot' is missing or is not a directory."
    }

    # 2. It must look like a Grimdex install. This is the guard that stops
    #    someone composing the Learn layer onto an arbitrary folder.
    if ($rootOk -and -not (Test-Path -LiteralPath (Join-Path $InstallRoot 'GRIMDEX.md') -PathType Leaf)) {
        $errors += "Install root '$InstallRoot' has no GRIMDEX.md; it does not look like a Grimdex install."
    }

    # 3. The source module must exist.
    $sourceLearn = Join-Path $SourceRoot 'learn'
    $sourceOk = Test-Path -LiteralPath $sourceLearn -PathType Container
    if (-not $sourceOk) {
        $errors += "Source Learn module '$sourceLearn' is missing."
    }

    # 4. Foreign-directory collision. A learn/ is a legal same-owner re-apply
    #    (D28) only when its manifest.json parses as JSON, carries a non-empty
    #    moduleId, AND that moduleId matches the incoming module's. Presence of
    #    a file named manifest.json is not enough — any unrelated directory
    #    could contain one, it could be malformed or empty, and a DIFFERENT
    #    Learn module's directory is not ours to overwrite either. Read and
    #    compare the content, don't just Test-Path it. Anything that is not a
    #    proven same-module re-apply is refused: nothing is overwritten.
    if ($rootOk) {
        $destLearn        = Join-Path $InstallRoot 'learn'
        $destManifestPath = Join-Path $destLearn 'manifest.json'
        # A non-directory 'learn' (a plain file, or a reparse point posing as
        # one) can never be a re-apply target, and it is not install's to
        # replace: the copy would fail mid-run and rollback would then delete
        # something this run never created. Reject it here, at plan time.
        if ((Test-Path -LiteralPath $destLearn) -and
            -not (Test-Path -LiteralPath $destLearn -PathType Container)) {
            $errors += "Install root path 'learn' exists but is not a directory; install refuses to replace it."
        } elseif (Test-Path -LiteralPath $destLearn -PathType Container) {
            $destManifest = $null
            $parsedOk     = $false
            if (Test-Path -LiteralPath $destManifestPath -PathType Leaf) {
                try {
                    $destManifest = Get-Content -LiteralPath $destManifestPath -Raw |
                        ConvertFrom-Json -AsHashtable -Depth 20
                    $parsedOk = $true
                } catch {
                    $parsedOk = $false
                }
            }
            $destModuleId = $null
            if ($parsedOk -and $destManifest -is [System.Collections.IDictionary]) {
                if ($destManifest.ContainsKey('moduleId')) {
                    $moduleId = $destManifest['moduleId']
                    if (($moduleId -is [string]) -and (-not [string]::IsNullOrWhiteSpace($moduleId))) {
                        $destModuleId = [string]$moduleId
                    }
                }
            }
            $sourceModuleId = $null
            if (($Manifest -is [System.Collections.IDictionary]) -and $Manifest.ContainsKey('moduleId')) {
                $sourceModuleId = [string]$Manifest['moduleId']
            }
            if ($null -eq $destModuleId) {
                $errors += "Install root already has a 'learn' directory whose manifest.json does not parse as a valid Learn manifest with a moduleId; the Learn module does not own it and install refuses to overwrite it."
            } elseif (-not [string]::Equals($destModuleId, $sourceModuleId, [System.StringComparison]::Ordinal)) {
                $errors += "Install root already has a 'learn' directory owned by module '$destModuleId', but this source installs '$sourceModuleId'; install refuses to overwrite another module's directory."
            } else {
                $mode = 're-apply'
            }
        }
    }

    # 5. The stanza body. Deterministic; failure here is a plan error, not a throw.
    try {
        $stanzaContent = Get-LearnStanzaContent -Manifest $Manifest
    } catch {
        $errors += "Cannot build the Learn pointer stanza: $($_.Exception.Message)"
        $stanzaContent = ''
    }

    # 6. Pointer-stanza targets.
    if ($rootOk) {
        $rootFullForStanza = [System.IO.Path]::GetFullPath($InstallRoot).TrimEnd('\', '/')
        foreach ($entry in $Manifest.pointerStanzas) {
            $rel = ([string]$entry.file) -replace '\\', '/'
            # FIRST, before any resolution or Test-Path: a colon is never valid
            # in a relative install path and is how NTFS stream syntax sneaks a
            # write into a neverShip secret. See Test-RelPathHasColon.
            if (Test-RelPathHasColon -Rel $rel) {
                $errors += "Stanza file '$rel' contains a colon; alternate-data-stream and drive-relative syntax are never valid install paths."
                continue
            }
            $contained = $false
            if (-not [System.IO.Path]::IsPathRooted($rel)) {
                $relFull = [System.IO.Path]::GetFullPath((Join-Path $rootFullForStanza $rel))
                $contained = $relFull.StartsWith($rootFullForStanza + [System.IO.Path]::DirectorySeparatorChar,
                    [System.StringComparison]::OrdinalIgnoreCase)
            }
            if (-not $contained) {
                $errors += "Stanza file '$rel' escapes the install root."
                continue
            }
            if (Test-NeverShipPath -InstallRoot $InstallRoot -Rel $rel -NeverShip $Manifest.neverShip) {
                $errors += "Stanza file '$rel' is a neverShip path; install never writes pointer stanzas into secret files."
                continue
            }
            if (Test-RelPathUnder -InstallRoot $InstallRoot -Rel $rel -RootPatterns (Get-EffectiveStudentRoots -Manifest $Manifest)) {
                $errors += "Stanza file '$rel' is inside a student root; install never writes the student zone."
                continue
            }
            $abs   = Join-Path $InstallRoot $rel
            $state = Get-PointerStanzaState -Path $abs
            if ($state.state -eq 'missing-file') {
                $errors += "Stanza file '$rel' does not exist; install never creates base-owned files."
                continue
            }
            if ($state.state -eq 'malformed') {
                $errors += "Stanza file '$rel' has malformed grimdex-learn markers."
                continue
            }
            if ($state.blocks -gt 1) {
                $errors += "Stanza file '$rel' already has $($state.blocks) learn blocks; refusing an ambiguous upsert target."
                continue
            }
            $stanzaFiles += [pscustomobject]@{ rel = $rel; path = $abs; state = $state.state }
        }
    }

    # 7. Source files. Every one must be Learn-owned, outside the student zone,
    #    and not a neverShip path.
    if ($sourceOk) {
        $sourceFullRoot = [System.IO.Path]::GetFullPath($SourceRoot).TrimEnd('\', '/')
        $ownedPatterns  = @($Manifest.ownedPaths | ForEach-Object { "$_**" })
        foreach ($file in (Get-ChildItem -LiteralPath $sourceLearn -Recurse -File -Force)) {
            $rel = [System.IO.Path]::GetRelativePath($sourceFullRoot, $file.FullName) -replace '\\', '/'
            # Same rule for copy destinations, and for the same reason: the
            # relative path is joined onto the install root, so stream syntax
            # here would write through a guard that resolved past it.
            if (Test-RelPathHasColon -Rel $rel) {
                $errors += "Source file '$rel' contains a colon; alternate-data-stream and drive-relative syntax are never valid install paths."
                continue
            }
            if (-not (Test-RelPathUnder -InstallRoot $InstallRoot -Rel $rel -RootPatterns $ownedPatterns)) {
                $errors += "Source file '$rel' is not under a Learn-owned path."
                continue
            }
            if (Test-RelPathUnder -InstallRoot $InstallRoot -Rel $rel -RootPatterns (Get-EffectiveStudentRoots -Manifest $Manifest)) {
                $errors += "Source file '$rel' resolves into a student root; install never writes the student zone."
                continue
            }
            if (Test-NeverShipPath -InstallRoot $InstallRoot -Rel $rel -NeverShip $Manifest.neverShip) {
                $errors += "Source file '$rel' is a neverShip path; install never places secret files."
                continue
            }
            $copies += [pscustomobject]@{
                rel    = $rel
                source = $file.FullName
                dest   = (Join-Path $InstallRoot $rel)
                hash   = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
            }
        }
    }
    $copies = @($copies | Sort-Object -Property rel)

    # 8. Pre-install state of every neverShip path, so the post-state verify can
    #    prove install neither created, modified, nor removed one.
    if ($rootOk) {
        foreach ($n in $Manifest.neverShip) {
            $rel    = ([string]$n) -replace '\\', '/'
            $abs    = Join-Path $InstallRoot $rel
            $exists = Test-Path -LiteralPath $abs -PathType Leaf
            $hash   = $null
            if ($exists) { $hash = (Get-FileHash -LiteralPath $abs -Algorithm SHA256).Hash }
            $neverShipBefore += [pscustomobject]@{ rel = $rel; exists = $exists; hash = $hash }
        }
    }

    [pscustomobject]@{
        mode            = $mode
        copies          = @($copies)
        stanzaFiles     = @($stanzaFiles)
        stanzaContent   = $stanzaContent
        neverShipBefore = @($neverShipBefore)
        errors          = @($errors)
    }
}

function Assert-NoReparsePoints {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Label
    )
    # Copy-Item -Recurse FOLLOWS junctions and symlinks. A junction planted under
    # learn/ that points at projects/ would therefore copy the student's files
    # into the WorkDir backup - silently, on an otherwise successful install -
    # contradicting the one promise this tool makes about the student zone: it is
    # never copied anywhere. Refuse rather than copy through a reparse point.
    # Get-ChildItem -Recurse does NOT traverse reparse points (that needs
    # -FollowSymlink), so this walk enumerates the link itself, never its target.
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $item = Get-Item -LiteralPath $Path -Force
    if ($item.Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint)) {
        throw "Backup-InstallTargets: '$Label' is a reparse point (junction or symlink); install refuses to back up or copy through one."
    }
    if ($item.PSIsContainer) {
        foreach ($child in (Get-ChildItem -LiteralPath $Path -Recurse -Force)) {
            if ($child.Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint)) {
                throw "Backup-InstallTargets: '$Label' contains a reparse point (junction or symlink) at '$($child.FullName)'; install refuses to back up or copy through one, because it can redirect into the student zone."
            }
        }
    }
}

function Backup-InstallTargets {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)]$Plan,
        [Parameter(Mandatory)][string]$WorkDir
    )

    New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
    $backedUp = @()

    $targets = @()
    if ($Plan.mode -eq 're-apply') { $targets += 'learn' }
    foreach ($s in $Plan.stanzaFiles) { $targets += $s.rel }

    # Refuse the WHOLE operation before copying anything if any target - most
    # importantly the learn/ tree - holds a reparse point that could redirect
    # the copy out of the install-owned zone.
    foreach ($rel in $targets) {
        Assert-NoReparsePoints -Path (Join-Path $InstallRoot $rel) -Label $rel
    }

    foreach ($rel in $targets) {
        $src = Join-Path $InstallRoot $rel
        if (-not (Test-Path -LiteralPath $src)) { continue }
        $dst = Join-Path $WorkDir $rel
        New-Item -ItemType Directory -Path (Split-Path -Parent $dst) -Force | Out-Null
        Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
        $backedUp += ($rel -replace '\\', '/')
    }

    # Record which destination parent directories do NOT yet exist — these are
    # the only dirs rollback is allowed to prune. Same walk-up technique as
    # Backup-GraduationTargets. Split-Path -Parent of a drive root returns '',
    # which terminates the loop.
    $createdDirs = @()
    foreach ($copy in $Plan.copies) {
        $dir = Split-Path -Parent $copy.dest
        while ($dir -and -not (Test-Path -LiteralPath $dir)) {
            $createdDirs += $dir
            $dir = Split-Path -Parent $dir
        }
    }
    $createdDirs = @($createdDirs | Select-Object -Unique)
    ConvertTo-Json -AsArray $createdDirs |
        Set-Content -LiteralPath (Join-Path $WorkDir 'created-dirs.json')

    [pscustomobject]@{ backedUp = @($backedUp) }
}

function Restore-InstallBackup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)]$Plan,
        [Parameter(Mandatory)][string]$WorkDir
    )

    # Verify the backup is complete BEFORE any destructive removal below. A
    # stanza whose 'rel' the plan recorded, or a re-apply's learn/ tree,
    # always existed before install (the plan rejects a missing stanza target,
    # and re-apply mode only fires when a prior learn/ was there to back up) —
    # so a backup copy must be on disk. If it is not, the WorkDir is missing or
    # incomplete (e.g. cleared, or restore is being called against the wrong
    # backup), and continuing would delete live content with nothing to put
    # back in its place. Abort here, before anything is touched, rather than
    # silently skipping (which used to leave the live file just deleted) or
    # deleting learn/ and then finding there was nothing to copy back.
    $bakLearn = Join-Path $WorkDir 'learn'
    foreach ($s in $Plan.stanzaFiles) {
        $bak = Join-Path $WorkDir $s.rel
        if (-not (Test-Path -LiteralPath $bak -PathType Leaf)) {
            throw "Restore-InstallBackup: expected backup for stanza file '$($s.rel)' at '$bak' but it is missing. The work directory is missing or incomplete; nothing has been touched."
        }
    }
    if ($Plan.mode -eq 're-apply' -and -not (Test-Path -LiteralPath $bakLearn)) {
        throw "Restore-InstallBackup: mode is 're-apply' but the expected backup of 'learn/' at '$bakLearn' is missing. The work directory is missing or incomplete; nothing has been touched."
    }

    # Stanza files always existed before install (the plan rejects missing ones),
    # so a backup copy is always available (checked above).
    foreach ($s in $Plan.stanzaFiles) {
        $bak = Join-Path $WorkDir $s.rel
        $live = Join-Path $InstallRoot $s.rel
        if (Test-Path -LiteralPath $live) { Remove-Item -LiteralPath $live -Recurse -Force }
        New-Item -ItemType Directory -Path (Split-Path -Parent $live) -Force | Out-Null
        Copy-Item -LiteralPath $bak -Destination $live -Force
    }

    # learn/: on re-apply put the backed-up tree back (its presence was verified
    # above). On a fresh install NOTHING was backed up, so removing learn/
    # wholesale would be a deletion this function cannot undo and never had a
    # right to make — it would destroy whatever happened to sit at that path.
    # The correct fresh-mode restore is to delete exactly what this run created:
    # the planned copy destinations, then the directories recorded as created,
    # pruned below only while empty.
    $liveLearn = Join-Path $InstallRoot 'learn'
    if ($Plan.mode -eq 're-apply') {
        if (Test-Path -LiteralPath $liveLearn) {
            Remove-Item -LiteralPath $liveLearn -Recurse -Force
        }
        Copy-Item -LiteralPath $bakLearn -Destination $liveLearn -Recurse -Force
    } else {
        foreach ($copy in $Plan.copies) {
            if (Test-Path -LiteralPath $copy.dest -PathType Leaf) {
                Remove-Item -LiteralPath $copy.dest -Force
            }
        }
    }

    # Prune ONLY dirs recorded as created by this install, deepest first, and
    # only when empty. A directory that existed before is never touched — which
    # is what lets fresh-mode rollback empty out learn/ without ever issuing a
    # recursive delete of a path it did not create. On a re-apply the loop finds
    # nothing to do: the tree was already restored wholesale just above.
    # '[]' | ConvertFrom-Json cast to [string[]] and wrapped in @() yields a
    # one-element array holding $null, and Test-Path -LiteralPath $null errors —
    # hence the Where-Object filter.
    $createdDirsPath = Join-Path $WorkDir 'created-dirs.json'
    $createdDirs = @()
    if (Test-Path -LiteralPath $createdDirsPath) {
        $createdDirs = @([string[]]([string](Get-Content -LiteralPath $createdDirsPath -Raw) |
            ConvertFrom-Json) | Where-Object { $_ })
    }
    foreach ($dir in ($createdDirs | Sort-Object -Property Length -Descending)) {
        if ((Test-Path -LiteralPath $dir) -and -not (Get-ChildItem -LiteralPath $dir -Force)) {
            Remove-Item -LiteralPath $dir -Force
        }
    }
}

function Test-InstallPostState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)]$Plan,
        [Parameter(Mandatory)]$SnapshotBefore
    )

    $failures = @()

    # Every planned copy landed with the hash recorded at plan time.
    foreach ($copy in $Plan.copies) {
        if (-not (Test-Path -LiteralPath $copy.dest -PathType Leaf)) {
            $failures += "Planned file missing after install: $($copy.rel)"
            continue
        }
        $hash = (Get-FileHash -LiteralPath $copy.dest -Algorithm SHA256).Hash
        if ($hash -ne $copy.hash) {
            $failures += "Installed file content mismatch: $($copy.rel)"
        }
    }

    # Every stanza file has exactly one well-formed block holding exactly the
    # planned body.
    foreach ($s in $Plan.stanzaFiles) {
        $abs   = Join-Path $InstallRoot $s.rel
        $state = Get-PointerStanzaState -Path $abs
        if ($state.state -ne 'well-formed') {
            $failures += "Stanza in '$($s.rel)' is not well-formed after install (found: $($state.state))."
            continue
        }
        if ($state.blocks -ne 1) {
            $failures += "Stanza in '$($s.rel)' has $($state.blocks) learn blocks after install; expected exactly 1."
            continue
        }
        $body = Get-PointerStanzaBody -Path $abs
        if ($body -ne $Plan.stanzaContent) {
            $failures += "Stanza body in '$($s.rel)' does not match the planned Learn stanza content."
        }
    }

    # The student zone is untouched. Install has no allow-list at all: any
    # addition, modification, or removal under studentRoots is a failure (D28).
    # $studentZoneFailed is carried on the result so callers (Invoke-LearnInstall)
    # can tell a student-zone problem apart from any other verify failure without
    # re-parsing failure message text — rollback never repairs the student zone
    # (privacy by design), so that distinction has to be reported honestly.
    $after = New-StudentZoneSnapshot -InstallRoot $InstallRoot -Manifest $Manifest
    $zone  = Test-StudentZoneUntouched -Before $SnapshotBefore -After $after
    foreach ($rel in $zone.modified) { $failures += "Student file modified: $rel" }
    foreach ($rel in $zone.missing)  { $failures += "Student file missing: $rel" }
    foreach ($rel in $zone.added)    { $failures += "Student file added: $rel" }
    $studentZoneFailed = -not $zone.passed

    # neverShip paths are unchanged in existence and content.
    foreach ($n in $Plan.neverShipBefore) {
        $abs       = Join-Path $InstallRoot $n.rel
        $existsNow = Test-Path -LiteralPath $abs -PathType Leaf
        if ($existsNow -ne $n.exists) {
            if ($existsNow) { $failures += "neverShip file created by install: $($n.rel)" }
            else            { $failures += "neverShip file disappeared: $($n.rel)" }
            continue
        }
        if ($existsNow) {
            $hashNow = (Get-FileHash -LiteralPath $abs -Algorithm SHA256).Hash
            if ($hashNow -ne $n.hash) {
                $failures += "neverShip file modified: $($n.rel)"
            }
        }
    }

    [pscustomobject]@{
        passed             = ($failures.Count -eq 0)
        failures           = @($failures)
        studentZoneFailed  = $studentZoneFailed
    }
}

function Invoke-LearnInstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SourceRoot,
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)][string]$ManifestPath,
        [Parameter(Mandatory)][string]$WorkDir,
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
    $plan = New-InstallPlan -SourceRoot $SourceRoot -InstallRoot $InstallRoot -Manifest $manifest

    if ($plan.errors.Count -gt 0) {
        return [pscustomobject]@{
            status = 'invalid-plan'; plan = $plan; verify = $null
            errors = @($plan.errors); failures = @(); stanzaActions = @()
        }
    }
    if ($Preview) {
        return [pscustomobject]@{
            status = 'previewed'; plan = $plan; verify = $null
            errors = @(); failures = @(); stanzaActions = @()
        }
    }

    New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
    $backupDir = Join-Path $WorkDir 'backup'
    # Start from a clean backup so a reused WorkDir cannot restore stale files.
    if (Test-Path -LiteralPath $backupDir) { Remove-Item -LiteralPath $backupDir -Recurse -Force }

    $before = New-StudentZoneSnapshot -InstallRoot $InstallRoot -Manifest $manifest
    Backup-InstallTargets -InstallRoot $InstallRoot -Plan $plan -WorkDir $backupDir | Out-Null

    # Mutate-and-verify, guarded: $ErrorActionPreference = 'Stop' (set by the
    # CLI) means any of Copy-Item / New-Item / Set-PointerStanza throwing
    # here (disk full, antivirus lock, permission denied, source removed
    # after planning) would otherwise escape this function with the tree
    # half-installed and the backup orphaned — rollback would never run.
    # Catch it, attempt rollback, and report a distinct status rather than
    # let the exception propagate.
    $stanzaActions   = @()
    $verify          = $null
    $mutateException = $null
    try {
        foreach ($copy in $plan.copies) {
            New-Item -ItemType Directory -Path (Split-Path -Parent $copy.dest) -Force | Out-Null
            Copy-Item -LiteralPath $copy.source -Destination $copy.dest -Force
        }
        foreach ($s in $plan.stanzaFiles) {
            $applied = Set-PointerStanza -Path (Join-Path $InstallRoot $s.rel) -Content $plan.stanzaContent
            $stanzaActions += [pscustomobject]@{ rel = $s.rel; action = $applied.action }
        }

        if ($PostMutateHook) { & $PostMutateHook $InstallRoot }

        $verify = Test-InstallPostState -InstallRoot $InstallRoot -Manifest $manifest `
            -Plan $plan -SnapshotBefore $before
    } catch {
        $mutateException = $_.Exception.Message
    }

    if ($mutateException) {
        $failures = @("Install aborted by an error during install (not a verify failure): $mutateException")
        try {
            Restore-InstallBackup -InstallRoot $InstallRoot -Plan $plan -WorkDir $backupDir
        } catch {
            # Never let a rollback failure hide the original error - report both.
            $failures += "Rollback itself failed: $($_.Exception.Message)"
        }
        return [pscustomobject]@{
            status = 'rolled-back'; plan = $plan; verify = $null
            errors = @(); failures = @($failures); stanzaActions = @($stanzaActions)
            studentZoneUnrepaired = $false
        }
    }

    if (-not $verify.passed) {
        # verify.studentZoneFailed distinguishes a student-zone verify failure
        # from any other: rollback below restores learn/ and the stanza files
        # only, so if the student zone is what tripped verify, that change is
        # NOT undone (privacy by design - install never copies the student
        # zone anywhere). studentZoneUnrepaired lets the CLI say so honestly
        # instead of implying 'rolled-back' undid everything.
        $failures = @($verify.failures)
        try {
            Restore-InstallBackup -InstallRoot $InstallRoot -Plan $plan -WorkDir $backupDir
        } catch {
            $failures += "Rollback itself failed: $($_.Exception.Message)"
        }
        return [pscustomobject]@{
            status = 'rolled-back'; plan = $plan; verify = $verify
            errors = @(); failures = @($failures); stanzaActions = @($stanzaActions)
            studentZoneUnrepaired = [bool]$verify.studentZoneFailed
        }
    }
    [pscustomobject]@{
        status = 'installed'; plan = $plan; verify = $verify
        errors = @(); failures = @(); stanzaActions = @($stanzaActions)
        studentZoneUnrepaired = $false
    }
}
