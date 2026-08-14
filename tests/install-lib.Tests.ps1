BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'scripts' 'manifest-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'verify-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'stanza-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'lifecycle-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'install-lib.ps1')

    # Test files must stand alone, so the fixture builders are defined here
    # rather than shared with tests/lifecycle-lib.Tests.ps1.
    function New-FixtureManifestObject {
        @{
            schemaVersion = 1; moduleId = 'git-and-github'; title = 't'
            description = 'd'; learnPackVersion = '0.1.0'
            contentAdmissionVersion = 'D29-v1'
            baseGrimdex = @{ pin = 'TEST-PIN' }
            ownedPaths = @('learn/'); pagesPath = 'learn/git-and-github/capabilities/'
            pointerStanzas = @(@{ file = 'GRIMDEX.md' })
            refresh = @{ schedule = 'manual-until-pipeline-shakedown-complete'; policyVersion = '1' }
            neverShip = @('config/fleet.json', 'config/learn-progress.json',
                          'config/quota.json', 'config/settings.json')
            studentRoots = @('projects/**')
            generatedRoots = @('logs/')
            lifecycle = @{
                install  = @{ student = 'never-touch' }
                update   = @{ student = 'never-touch' }
                graduate = @{ student = 'never-touch' }
                remove   = @{ student = 'never-touch' }
            }
        }
    }

    # The EDU-side source repo: learn/ content plus its manifest.
    function New-FixtureSource {
        param([string]$Name, [hashtable]$ManifestObject)
        if (-not $ManifestObject) { $ManifestObject = New-FixtureManifestObject }
        $src = Join-Path $TestDrive $Name
        New-Item -ItemType Directory -Path (Join-Path $src 'learn/git-and-github/capabilities') -Force | Out-Null
        $ManifestObject | ConvertTo-Json -Depth 6 |
            Set-Content -LiteralPath (Join-Path $src 'learn/manifest.json')
        Set-Content -LiteralPath (Join-Path $src 'learn/git-and-github/capabilities/page.md') -Value 'page one'
        Set-Content -LiteralPath (Join-Path $src 'learn/git-and-github/README.md') -Value 'module readme'
        $src
    }

    # A stock Grimdex install: GRIMDEX.md with no stanza, a student zone, config files.
    # GRIMDEX.md deliberately ends in a blank line so the stanza append/remove
    # round-trip is byte-exact.
    function New-FixtureInstall {
        param([string]$Name)
        $root = Join-Path $TestDrive $Name
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'GRIMDEX.md') -NoNewline -Value "# Grimdex`n`nbase text`n`n"
        foreach ($d in 'projects/personal', 'config') {
            New-Item -ItemType Directory -Path (Join-Path $root $d) -Force | Out-Null
        }
        Set-Content -LiteralPath (Join-Path $root 'projects/personal/kb.md') -Value 'student knowledge'
        Set-Content -LiteralPath (Join-Path $root 'config/learn-progress.json') -Value '{"ledger":[]}'
        Set-Content -LiteralPath (Join-Path $root 'config/settings.json') -Value '{}'
        $root
    }

    function Read-FixtureManifest {
        param([string]$SourceRoot)
        Read-LearnManifest -Path (Join-Path $SourceRoot 'learn/manifest.json')
    }
}

Describe 'New-InstallPlan' {
    It 'computes a valid fresh plan' {
        $src = New-FixtureSource 'p1-src'
        $root = New-FixtureInstall 'p1-root'
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest (Read-FixtureManifest $src)
        $plan.errors        | Should -BeNullOrEmpty
        $plan.mode          | Should -Be 'fresh'
        $plan.copies.Count  | Should -Be 3
        $plan.stanzaFiles.Count | Should -Be 1
        $plan.stanzaFiles[0].rel   | Should -Be 'GRIMDEX.md'
        $plan.stanzaFiles[0].state | Should -Be 'absent'
        $plan.stanzaContent | Should -Match 'TEST-PIN'
    }
    It 'reports re-apply mode when the install already has a Learn-owned learn/' {
        $src = New-FixtureSource 'p2-src'
        $root = New-FixtureInstall 'p2-root'
        Copy-Item -LiteralPath (Join-Path $src 'learn') -Destination (Join-Path $root 'learn') -Recurse
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest (Read-FixtureManifest $src)
        $plan.errors | Should -BeNullOrEmpty
        $plan.mode   | Should -Be 're-apply'
    }
    It 'errors when the install root is missing' {
        $src = New-FixtureSource 'p3-src'
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot (Join-Path $TestDrive 'p3-nope') `
            -Manifest (Read-FixtureManifest $src)
        ($plan.errors -join ' ') | Should -Match 'is missing or is not a directory'
    }
    It 'errors when the install root has no GRIMDEX.md' {
        $src = New-FixtureSource 'p4-src'
        $root = New-FixtureInstall 'p4-root'
        Remove-Item -LiteralPath (Join-Path $root 'GRIMDEX.md')
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest (Read-FixtureManifest $src)
        ($plan.errors -join ' ') | Should -Match 'does not look like a Grimdex install'
    }
    It 'errors when the source learn/ directory is missing' {
        $src = New-FixtureSource 'p5-src'
        $root = New-FixtureInstall 'p5-root'
        $m = Read-FixtureManifest $src
        Remove-Item -LiteralPath (Join-Path $src 'learn') -Recurse -Force
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest $m
        ($plan.errors -join ' ') | Should -Match 'Source Learn module'
    }
    It 'hard-fails on a foreign learn/ directory with no manifest.json' {
        $src = New-FixtureSource 'p6-src'
        $root = New-FixtureInstall 'p6-root'
        New-Item -ItemType Directory -Path (Join-Path $root 'learn') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'learn/somebody-elses.md') -Value 'not ours'
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest (Read-FixtureManifest $src)
        ($plan.errors -join ' ') | Should -Match 'does not own'
    }
    It 'errors when a stanza target file does not exist' {
        $src = New-FixtureSource 'p7-src'
        $root = New-FixtureInstall 'p7-root'
        $m = Read-FixtureManifest $src
        Remove-Item -LiteralPath (Join-Path $root 'GRIMDEX.md')
        Set-Content -LiteralPath (Join-Path $root 'OTHER.md') -Value 'x'
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest $m
        ($plan.errors -join ' ') | Should -Match 'never creates base-owned files'
    }
    It 'errors when a stanza target is malformed' {
        $src = New-FixtureSource 'p8-src'
        $root = New-FixtureInstall 'p8-root'
        Set-Content -LiteralPath (Join-Path $root 'GRIMDEX.md') -NoNewline `
            -Value "# Grimdex`n<!-- grimdex-learn:start -->`nno end`n"
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest (Read-FixtureManifest $src)
        ($plan.errors -join ' ') | Should -Match 'malformed'
    }
    It 'errors when a stanza target already has two blocks' {
        $src = New-FixtureSource 'p9-src'
        $root = New-FixtureInstall 'p9-root'
        Set-Content -LiteralPath (Join-Path $root 'GRIMDEX.md') -NoNewline -Value (
            "# Grimdex`n<!-- grimdex-learn:start -->`nA`n<!-- grimdex-learn:end -->`n" +
            "<!-- grimdex-learn:start -->`nB`n<!-- grimdex-learn:end -->`n")
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest (Read-FixtureManifest $src)
        ($plan.errors -join ' ') | Should -Match 'ambiguous'
    }
    It 'errors when a stanza target escapes the install root' {
        $mo = New-FixtureManifestObject
        $mo.pointerStanzas = @(@{ file = '../escape.md' })
        $src = New-FixtureSource 'p10-src' $mo
        $root = New-FixtureInstall 'p10-root'
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest (Read-FixtureManifest $src)
        ($plan.errors -join ' ') | Should -Match 'escapes the install root'
    }
    It 'errors when a stanza target is inside a student root' {
        $mo = New-FixtureManifestObject
        $mo.pointerStanzas = @(@{ file = 'projects/personal/kb.md' })
        $src = New-FixtureSource 'p11-src' $mo
        $root = New-FixtureInstall 'p11-root'
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest (Read-FixtureManifest $src)
        ($plan.errors -join ' ') | Should -Match 'student root'
    }
    It 'errors on a source file that is not under an owned path' {
        $mo = New-FixtureManifestObject
        $mo.ownedPaths = @('docs/')
        $src = New-FixtureSource 'p12-src' $mo
        $root = New-FixtureInstall 'p12-root'
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest (Read-FixtureManifest $src)
        ($plan.errors -join ' ') | Should -Match 'not under a Learn-owned path'
    }
    It 'errors on a source file listed in neverShip' {
        $mo = New-FixtureManifestObject
        $mo.neverShip = @('config/fleet.json', 'config/learn-progress.json',
                          'config/quota.json', 'config/settings.json',
                          'learn/git-and-github/secret.json')
        $src = New-FixtureSource 'p13-src' $mo
        $root = New-FixtureInstall 'p13-root'
        Set-Content -LiteralPath (Join-Path $src 'learn/git-and-github/secret.json') -Value '{}'
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest (Read-FixtureManifest $src)
        ($plan.errors -join ' ') | Should -Match 'neverShip'
    }
    It 'errors on a source file that resolves into a student root' {
        $mo = New-FixtureManifestObject
        $mo.studentRoots = @('projects/**', 'learn/git-and-github/capabilities/**')
        $src = New-FixtureSource 'p14-src' $mo
        $root = New-FixtureInstall 'p14-root'
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest (Read-FixtureManifest $src)
        ($plan.errors -join ' ') | Should -Match 'never writes the student zone'
    }
    It 'records the source hash, resolves dest under the install root, and is order-stable' {
        $src = New-FixtureSource 'p15-src'
        $root = New-FixtureInstall 'p15-root'
        $m = Read-FixtureManifest $src
        $plan  = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest $m
        $again = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest $m
        $rels = @($plan.copies | ForEach-Object { $_.rel })
        # Sort both sides so the assertion does not depend on collation rules.
        ($rels | Sort-Object) | Should -Be (@(
            'learn/git-and-github/README.md',
            'learn/git-and-github/capabilities/page.md',
            'learn/manifest.json') | Sort-Object)
        # Two plans over the same input must order copies identically.
        ($rels -join '|') | Should -BeExactly (@($again.copies | ForEach-Object { $_.rel }) -join '|')
        $page = @($plan.copies | Where-Object { $_.rel -eq 'learn/git-and-github/capabilities/page.md' })[0]
        $page.hash | Should -Be (Get-FileHash -LiteralPath $page.source -Algorithm SHA256).Hash
        $page.dest | Should -Be (Join-Path $root 'learn/git-and-github/capabilities/page.md')
        $ledger = @($plan.neverShipBefore | Where-Object { $_.rel -eq 'config/learn-progress.json' })[0]
        $ledger.exists | Should -BeTrue
        $ledger.hash   | Should -Not -BeNullOrEmpty
    }
    It 'rejects a pointer-stanza target that resolves onto any neverShip path' {
        $neverShipTargets = @('config/fleet.json', 'config/learn-progress.json',
                              'config/quota.json', 'config/settings.json')
        foreach ($target in $neverShipTargets) {
            $safe = $target -replace '[\\/\.]', '-'
            $mo = New-FixtureManifestObject
            $mo.pointerStanzas = @(@{ file = $target })
            $src  = New-FixtureSource "p16-src-$safe" $mo
            $root = New-FixtureInstall "p16-root-$safe"
            $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest (Read-FixtureManifest $src)
            ($plan.errors -join ' ') | Should -Match 'neverShip' -Because "target '$target' must be rejected"
        }
    }
    It 'rejects a pointer-stanza target with a trailing space that normalizes onto a neverShip file' {
        $mo = New-FixtureManifestObject
        $mo.pointerStanzas = @(@{ file = 'config/settings.json ' })
        $src = New-FixtureSource 'p17-src' $mo
        $root = New-FixtureInstall 'p17-root'
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest (Read-FixtureManifest $src)
        ($plan.errors -join ' ') | Should -Match 'neverShip'
    }
    It 'rejects a copy destination that resolves onto a neverShip path even when neverShip carries a trailing space' {
        $mo = New-FixtureManifestObject
        $mo.neverShip = @('config/fleet.json', 'config/learn-progress.json',
                          'config/quota.json', 'config/settings.json',
                          'learn/git-and-github/secret.json ')
        $src = New-FixtureSource 'p18-src' $mo
        $root = New-FixtureInstall 'p18-root'
        Set-Content -LiteralPath (Join-Path $src 'learn/git-and-github/secret.json') -Value '{}'
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest (Read-FixtureManifest $src)
        ($plan.errors -join ' ') | Should -Match 'neverShip'
        @($plan.copies | Where-Object { $_.rel -eq 'learn/git-and-github/secret.json' }) | Should -BeNullOrEmpty
    }
    It 'refuses an existing learn/ whose manifest.json is malformed JSON' {
        $src = New-FixtureSource 'p19-src'
        $root = New-FixtureInstall 'p19-root'
        New-Item -ItemType Directory -Path (Join-Path $root 'learn') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'learn/manifest.json') -Value '{ this is not valid json'
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest (Read-FixtureManifest $src)
        $plan.mode | Should -Not -Be 're-apply'
        ($plan.errors -join ' ') | Should -Match 'does not own'
    }
    It 'refuses an existing learn/ whose manifest.json parses but has no moduleId' {
        $src = New-FixtureSource 'p20-src'
        $root = New-FixtureInstall 'p20-root'
        New-Item -ItemType Directory -Path (Join-Path $root 'learn') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'learn/manifest.json') -Value '{"title":"not ours"}'
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest (Read-FixtureManifest $src)
        $plan.mode | Should -Not -Be 're-apply'
        ($plan.errors -join ' ') | Should -Match 'does not own'
    }
    It 'still yields re-apply with no errors for a valid existing learn/manifest.json' {
        $src = New-FixtureSource 'p21-src'
        $root = New-FixtureInstall 'p21-root'
        Copy-Item -LiteralPath (Join-Path $src 'learn') -Destination (Join-Path $root 'learn') -Recurse
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest (Read-FixtureManifest $src)
        $plan.errors | Should -BeNullOrEmpty
        $plan.mode   | Should -Be 're-apply'
    }
}

Describe 'Backup-InstallTargets / Restore-InstallBackup' {
    It 'records created dirs and rolls a fresh install back to nothing' {
        $src = New-FixtureSource 'b1-src'
        $root = New-FixtureInstall 'b1-root'
        $m = Read-FixtureManifest $src
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest $m
        $work = Join-Path $TestDrive 'b1-work'
        $grimdexBefore = [string](Get-Content -LiteralPath (Join-Path $root 'GRIMDEX.md') -Raw)

        Backup-InstallTargets -InstallRoot $root -Plan $plan -WorkDir $work | Out-Null
        $created = [string](Get-Content -LiteralPath (Join-Path $work 'created-dirs.json') -Raw)
        $created | Should -Match 'learn'

        foreach ($c in $plan.copies) {
            New-Item -ItemType Directory -Path (Split-Path -Parent $c.dest) -Force | Out-Null
            Copy-Item -LiteralPath $c.source -Destination $c.dest -Force
        }
        Set-PointerStanza -Path (Join-Path $root 'GRIMDEX.md') -Content $plan.stanzaContent | Out-Null

        Restore-InstallBackup -InstallRoot $root -Plan $plan -WorkDir $work

        Test-Path (Join-Path $root 'learn') | Should -BeFalse
        [string](Get-Content -LiteralPath (Join-Path $root 'GRIMDEX.md') -Raw) |
            Should -BeExactly $grimdexBefore
    }
    It 'restores the previous learn/ tree on a re-apply rollback' {
        $src = New-FixtureSource 'b2-src'
        $root = New-FixtureInstall 'b2-root'
        Copy-Item -LiteralPath (Join-Path $src 'learn') -Destination (Join-Path $root 'learn') -Recurse
        Set-Content -LiteralPath (Join-Path $root 'learn/git-and-github/capabilities/page.md') -Value 'OLD PAGE'
        $m = Read-FixtureManifest $src
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest $m
        $plan.mode | Should -Be 're-apply'
        $work = Join-Path $TestDrive 'b2-work'

        Backup-InstallTargets -InstallRoot $root -Plan $plan -WorkDir $work | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'learn/git-and-github/capabilities/page.md') -Value 'NEW PAGE'
        Restore-InstallBackup -InstallRoot $root -Plan $plan -WorkDir $work

        Get-Content -LiteralPath (Join-Path $root 'learn/git-and-github/capabilities/page.md') |
            Should -Be 'OLD PAGE'
    }
    It 'reports which targets it backed up' {
        $src = New-FixtureSource 'b3-src'
        $root = New-FixtureInstall 'b3-root'
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest (Read-FixtureManifest $src)
        $work = Join-Path $TestDrive 'b3-work'
        $r = Backup-InstallTargets -InstallRoot $root -Plan $plan -WorkDir $work
        $r.backedUp | Should -Be @('GRIMDEX.md')
        Test-Path (Join-Path $work 'GRIMDEX.md') | Should -BeTrue
        Test-Path (Join-Path $work 'learn')      | Should -BeFalse
    }
    It 'writes an empty created-dirs list when every destination parent exists' {
        $src = New-FixtureSource 'b4-src'
        $root = New-FixtureInstall 'b4-root'
        Copy-Item -LiteralPath (Join-Path $src 'learn') -Destination (Join-Path $root 'learn') -Recurse
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest (Read-FixtureManifest $src)
        $work = Join-Path $TestDrive 'b4-work'
        Backup-InstallTargets -InstallRoot $root -Plan $plan -WorkDir $work | Out-Null
        $created = @([string[]]([string](Get-Content -LiteralPath (Join-Path $work 'created-dirs.json') -Raw) |
            ConvertFrom-Json) | Where-Object { $_ })
        $created.Count | Should -Be 0
    }
    It 'never prunes a directory that existed before the install' {
        $src = New-FixtureSource 'b5-src'
        $root = New-FixtureInstall 'b5-root'
        New-Item -ItemType Directory -Path (Join-Path $root 'learn/git-and-github') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'learn/manifest.json') -Value '{"moduleId":"git-and-github"}'
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest (Read-FixtureManifest $src)
        $plan.mode | Should -Be 're-apply'
        $work = Join-Path $TestDrive 'b5-work'
        Backup-InstallTargets -InstallRoot $root -Plan $plan -WorkDir $work | Out-Null
        Restore-InstallBackup -InstallRoot $root -Plan $plan -WorkDir $work
        Test-Path (Join-Path $root 'learn/git-and-github') | Should -BeTrue
    }
}

Describe 'Test-InstallPostState' {
    # Pester 5 runs code placed directly in a Describe body during DISCOVERY
    # only, so helper functions must live in BeforeAll to exist at run time.
    BeforeAll {
        function Invoke-FixtureMutation {
            param($Plan, [string]$Root)
            foreach ($c in $Plan.copies) {
                New-Item -ItemType Directory -Path (Split-Path -Parent $c.dest) -Force | Out-Null
                Copy-Item -LiteralPath $c.source -Destination $c.dest -Force
            }
            Set-PointerStanza -Path (Join-Path $Root 'GRIMDEX.md') -Content $Plan.stanzaContent | Out-Null
        }
    }

    BeforeEach {
        $suffix = [guid]::NewGuid().ToString('n').Substring(0, 8)
        $script:src  = New-FixtureSource "ps-src-$suffix"
        $script:root = New-FixtureInstall "ps-root-$suffix"
        $script:m    = Read-FixtureManifest $script:src
        $script:plan = New-InstallPlan -SourceRoot $script:src -InstallRoot $script:root -Manifest $script:m
        $script:before = New-StudentZoneSnapshot -InstallRoot $script:root -Manifest $script:m
    }

    It 'passes a correctly applied install' {
        Invoke-FixtureMutation -Plan $script:plan -Root $script:root
        $r = Test-InstallPostState -InstallRoot $script:root -Manifest $script:m `
            -Plan $script:plan -SnapshotBefore $script:before
        $r.failures | Should -BeNullOrEmpty
        $r.passed   | Should -BeTrue
    }
    It 'fails when a planned file never landed' {
        Invoke-FixtureMutation -Plan $script:plan -Root $script:root
        Remove-Item -LiteralPath (Join-Path $script:root 'learn/git-and-github/capabilities/page.md')
        $r = Test-InstallPostState -InstallRoot $script:root -Manifest $script:m `
            -Plan $script:plan -SnapshotBefore $script:before
        $r.passed | Should -BeFalse
        ($r.failures -join ' ') | Should -Match 'missing after install'
    }
    It 'fails when a planned file has the wrong content' {
        Invoke-FixtureMutation -Plan $script:plan -Root $script:root
        Set-Content -LiteralPath (Join-Path $script:root 'learn/git-and-github/capabilities/page.md') `
            -Value 'tampered'
        $r = Test-InstallPostState -InstallRoot $script:root -Manifest $script:m `
            -Plan $script:plan -SnapshotBefore $script:before
        $r.passed | Should -BeFalse
        ($r.failures -join ' ') | Should -Match 'content mismatch'
    }
    It 'fails when the stanza is absent after install' {
        foreach ($c in $script:plan.copies) {
            New-Item -ItemType Directory -Path (Split-Path -Parent $c.dest) -Force | Out-Null
            Copy-Item -LiteralPath $c.source -Destination $c.dest -Force
        }
        $r = Test-InstallPostState -InstallRoot $script:root -Manifest $script:m `
            -Plan $script:plan -SnapshotBefore $script:before
        $r.passed | Should -BeFalse
        ($r.failures -join ' ') | Should -Match 'not well-formed'
    }
    It 'fails when the stanza body does not match the planned content' {
        Invoke-FixtureMutation -Plan $script:plan -Root $script:root
        Set-PointerStanza -Path (Join-Path $script:root 'GRIMDEX.md') -Content 'someone edited this' | Out-Null
        $r = Test-InstallPostState -InstallRoot $script:root -Manifest $script:m `
            -Plan $script:plan -SnapshotBefore $script:before
        $r.passed | Should -BeFalse
        ($r.failures -join ' ') | Should -Match 'does not match the planned'
    }
    It 'fails when a student file was modified' {
        Invoke-FixtureMutation -Plan $script:plan -Root $script:root
        Set-Content -LiteralPath (Join-Path $script:root 'projects/personal/kb.md') -Value 'overwritten'
        $r = Test-InstallPostState -InstallRoot $script:root -Manifest $script:m `
            -Plan $script:plan -SnapshotBefore $script:before
        $r.passed | Should -BeFalse
        ($r.failures -join ' ') | Should -Match 'Student file modified'
    }
    It 'fails when a student file was added' {
        Invoke-FixtureMutation -Plan $script:plan -Root $script:root
        Set-Content -LiteralPath (Join-Path $script:root 'projects/personal/intruder.md') -Value 'x'
        $r = Test-InstallPostState -InstallRoot $script:root -Manifest $script:m `
            -Plan $script:plan -SnapshotBefore $script:before
        $r.passed | Should -BeFalse
        ($r.failures -join ' ') | Should -Match 'Student file added'
    }
    It 'fails when a student file went missing' {
        Invoke-FixtureMutation -Plan $script:plan -Root $script:root
        Remove-Item -LiteralPath (Join-Path $script:root 'projects/personal/kb.md')
        $r = Test-InstallPostState -InstallRoot $script:root -Manifest $script:m `
            -Plan $script:plan -SnapshotBefore $script:before
        $r.passed | Should -BeFalse
        ($r.failures -join ' ') | Should -Match 'Student file missing'
    }
    It 'fails when a neverShip file was created' {
        Invoke-FixtureMutation -Plan $script:plan -Root $script:root
        Set-Content -LiteralPath (Join-Path $script:root 'config/fleet.json') -Value '{}'
        $r = Test-InstallPostState -InstallRoot $script:root -Manifest $script:m `
            -Plan $script:plan -SnapshotBefore $script:before
        $r.passed | Should -BeFalse
        ($r.failures -join ' ') | Should -Match 'created by install'
    }
    It 'fails when a neverShip file was modified' {
        Invoke-FixtureMutation -Plan $script:plan -Root $script:root
        Set-Content -LiteralPath (Join-Path $script:root 'config/settings.json') -Value '{"changed":true}'
        $r = Test-InstallPostState -InstallRoot $script:root -Manifest $script:m `
            -Plan $script:plan -SnapshotBefore $script:before
        $r.passed | Should -BeFalse
        ($r.failures -join ' ') | Should -Match 'neverShip file modified'
    }
    It 'fails when a neverShip file disappeared' {
        Invoke-FixtureMutation -Plan $script:plan -Root $script:root
        Remove-Item -LiteralPath (Join-Path $script:root 'config/settings.json')
        $r = Test-InstallPostState -InstallRoot $script:root -Manifest $script:m `
            -Plan $script:plan -SnapshotBefore $script:before
        $r.passed | Should -BeFalse
        ($r.failures -join ' ') | Should -Match 'disappeared'
    }
    It 'fails when the stanza file grew a second block' {
        Invoke-FixtureMutation -Plan $script:plan -Root $script:root
        Add-Content -LiteralPath (Join-Path $script:root 'GRIMDEX.md') -NoNewline `
            -Value "`n<!-- grimdex-learn:start -->`nsecond`n<!-- grimdex-learn:end -->`n"
        $r = Test-InstallPostState -InstallRoot $script:root -Manifest $script:m `
            -Plan $script:plan -SnapshotBefore $script:before
        $r.passed | Should -BeFalse
        ($r.failures -join ' ') | Should -Match 'expected exactly 1'
    }
    It 'passes a re-apply that overwrites an older learn/ tree' {
        $root2 = New-FixtureInstall 'ps-reapply-root'
        Copy-Item -LiteralPath (Join-Path $script:src 'learn') -Destination (Join-Path $root2 'learn') -Recurse
        Set-Content -LiteralPath (Join-Path $root2 'learn/git-and-github/capabilities/page.md') -Value 'stale'
        $plan2 = New-InstallPlan -SourceRoot $script:src -InstallRoot $root2 -Manifest $script:m
        $before2 = New-StudentZoneSnapshot -InstallRoot $root2 -Manifest $script:m
        Invoke-FixtureMutation -Plan $plan2 -Root $root2
        $r = Test-InstallPostState -InstallRoot $root2 -Manifest $script:m `
            -Plan $plan2 -SnapshotBefore $before2
        $r.failures | Should -BeNullOrEmpty
        $r.passed   | Should -BeTrue
    }
    It 'reports every failure it finds rather than stopping at the first' {
        Invoke-FixtureMutation -Plan $script:plan -Root $script:root
        Remove-Item -LiteralPath (Join-Path $script:root 'learn/git-and-github/capabilities/page.md')
        Set-Content -LiteralPath (Join-Path $script:root 'projects/personal/kb.md') -Value 'overwritten'
        $r = Test-InstallPostState -InstallRoot $script:root -Manifest $script:m `
            -Plan $script:plan -SnapshotBefore $script:before
        $r.failures.Count | Should -BeGreaterOrEqual 2
    }
}

Describe 'Invoke-LearnInstall' {
    # Pester 5 runs code placed directly in a Describe body during DISCOVERY
    # only, so helper functions must live in BeforeAll to exist at run time.
    BeforeAll {
        # -ExcludePrefixes lets callers scope the fingerprint to what rollback
        # actually guarantees. Rollback restores learn/ and the stanza files
        # only - it never repairs the student zone (privacy by design) - so a
        # fingerprint taken across the whole tree after a student-zone
        # corruption is deliberately left uncorrected would always mismatch.
        # Passing -ExcludePrefixes 'projects/' scopes the comparison to the
        # install-owned paths that rollback is actually responsible for.
        function Get-TreeFingerprint {
            param([string]$Root, [string[]]$ExcludePrefixes = @())
            $lines = @()
            foreach ($f in (Get-ChildItem -LiteralPath $Root -Recurse -File -Force | Sort-Object -Property FullName)) {
                $rel = [System.IO.Path]::GetRelativePath($Root, $f.FullName) -replace '\\', '/'
                $excluded = $false
                foreach ($prefix in $ExcludePrefixes) {
                    if ($rel.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) { $excluded = $true; break }
                }
                if ($excluded) { continue }
                $lines += ($rel + ' ' + (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash)
            }
            [string]::Join("`n", $lines)
        }
    }

    It 'installs a fresh Learn layer and verifies the post-state' {
        $src = New-FixtureSource 'i1-src'
        $root = New-FixtureInstall 'i1-root'
        $r = Invoke-LearnInstall -SourceRoot $src -InstallRoot $root `
            -ManifestPath (Join-Path $src 'learn/manifest.json') `
            -WorkDir (Join-Path $TestDrive 'i1-work')
        $r.status | Should -Be 'installed'
        $r.verify.passed | Should -BeTrue
        Test-Path (Join-Path $root 'learn/git-and-github/capabilities/page.md') | Should -BeTrue
        (Get-PointerStanzaState -Path (Join-Path $root 'GRIMDEX.md')).state | Should -Be 'well-formed'
        Get-PointerStanzaBody -Path (Join-Path $root 'GRIMDEX.md') | Should -BeExactly $r.plan.stanzaContent
        @($r.stanzaActions | Where-Object { $_.rel -eq 'GRIMDEX.md' })[0].action | Should -Be 'created'
    }
    It 'Preview mutates nothing' {
        $src = New-FixtureSource 'i2-src'
        $root = New-FixtureInstall 'i2-root'
        $fingerprint = Get-TreeFingerprint -Root $root
        $r = Invoke-LearnInstall -SourceRoot $src -InstallRoot $root `
            -ManifestPath (Join-Path $src 'learn/manifest.json') `
            -WorkDir (Join-Path $TestDrive 'i2-work') -Preview
        $r.status | Should -Be 'previewed'
        $r.verify | Should -BeNullOrEmpty
        $r.plan.copies.Count | Should -Be 3
        Get-TreeFingerprint -Root $root | Should -BeExactly $fingerprint
    }
    It 'refuses a WorkDir inside the install root' {
        $src = New-FixtureSource 'i3-src'
        $root = New-FixtureInstall 'i3-root'
        { Invoke-LearnInstall -SourceRoot $src -InstallRoot $root `
            -ManifestPath (Join-Path $src 'learn/manifest.json') `
            -WorkDir (Join-Path $root 'work') } | Should -Throw '*outside*'
    }
    It 'refuses a WorkDir equal to the install root' {
        $src = New-FixtureSource 'i4-src'
        $root = New-FixtureInstall 'i4-root'
        { Invoke-LearnInstall -SourceRoot $src -InstallRoot $root `
            -ManifestPath (Join-Path $src 'learn/manifest.json') `
            -WorkDir $root } | Should -Throw '*outside*'
    }
    It 'accepts a sibling WorkDir whose path merely shares a prefix with the install root' {
        $src = New-FixtureSource 'i5-src'
        $root = New-FixtureInstall 'i5-root'
        $r = Invoke-LearnInstall -SourceRoot $src -InstallRoot $root `
            -ManifestPath (Join-Path $src 'learn/manifest.json') `
            -WorkDir ($root + '-work')
        $r.status | Should -Be 'installed'
    }
    It 'returns invalid-plan and mutates nothing when the plan has errors' {
        $src = New-FixtureSource 'i6-src'
        $root = New-FixtureInstall 'i6-root'
        Remove-Item -LiteralPath (Join-Path $root 'GRIMDEX.md')
        $fingerprint = Get-TreeFingerprint -Root $root
        $r = Invoke-LearnInstall -SourceRoot $src -InstallRoot $root `
            -ManifestPath (Join-Path $src 'learn/manifest.json') `
            -WorkDir (Join-Path $TestDrive 'i6-work')
        $r.status | Should -Be 'invalid-plan'
        $r.errors | Should -Not -BeNullOrEmpty
        Get-TreeFingerprint -Root $root | Should -BeExactly $fingerprint
    }
    It 'rolls a fresh install back to its pre-install bytes when the verify fails' {
        $src = New-FixtureSource 'i7-src'
        $root = New-FixtureInstall 'i7-root'
        $fingerprint = Get-TreeFingerprint -Root $root
        $r = Invoke-LearnInstall -SourceRoot $src -InstallRoot $root `
            -ManifestPath (Join-Path $src 'learn/manifest.json') `
            -WorkDir (Join-Path $TestDrive 'i7-work') -PostMutateHook {
                param($InstallRoot)
                Remove-Item -LiteralPath (Join-Path $InstallRoot 'learn/git-and-github/capabilities/page.md') -Force
            }
        $r.status | Should -Be 'rolled-back'
        $r.failures | Should -Not -BeNullOrEmpty
        Test-Path (Join-Path $root 'learn') | Should -BeFalse
        Get-TreeFingerprint -Root $root | Should -BeExactly $fingerprint
    }
    It 'rolls back to the previous learn/ tree when a re-apply fails verify' {
        $src = New-FixtureSource 'i8-src'
        $root = New-FixtureInstall 'i8-root'
        Invoke-LearnInstall -SourceRoot $src -InstallRoot $root `
            -ManifestPath (Join-Path $src 'learn/manifest.json') `
            -WorkDir (Join-Path $TestDrive 'i8-work') | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'learn/git-and-github/capabilities/page.md') -Value 'LOCAL EDIT'
        # Scoped to install-owned paths: this hook corrupts the student zone,
        # which rollback never repairs by design (see the 'studentZoneUnrepaired'
        # tests below), so a whole-tree fingerprint would mismatch on
        # projects/personal/kb.md even after a fully correct rollback.
        $fingerprint = Get-TreeFingerprint -Root $root -ExcludePrefixes @('projects/')
        $r = Invoke-LearnInstall -SourceRoot $src -InstallRoot $root `
            -ManifestPath (Join-Path $src 'learn/manifest.json') `
            -WorkDir (Join-Path $TestDrive 'i8-work2') -PostMutateHook {
                param($InstallRoot)
                Set-Content -LiteralPath (Join-Path $InstallRoot 'projects/personal/kb.md') -Value 'corrupted'
            }
        $r.status | Should -Be 'rolled-back'
        Get-Content -LiteralPath (Join-Path $root 'learn/git-and-github/capabilities/page.md') |
            Should -Be 'LOCAL EDIT'
        Get-TreeFingerprint -Root $root -ExcludePrefixes @('projects/') | Should -BeExactly $fingerprint
    }
    It 'is idempotent: a second run installs again with no diff and no stanza change' {
        $src = New-FixtureSource 'i9-src'
        $root = New-FixtureInstall 'i9-root'
        $work = Join-Path $TestDrive 'i9-work'
        $first = Invoke-LearnInstall -SourceRoot $src -InstallRoot $root `
            -ManifestPath (Join-Path $src 'learn/manifest.json') -WorkDir $work
        $first.status | Should -Be 'installed'
        $fingerprint = Get-TreeFingerprint -Root $root
        $second = Invoke-LearnInstall -SourceRoot $src -InstallRoot $root `
            -ManifestPath (Join-Path $src 'learn/manifest.json') -WorkDir $work
        $second.status    | Should -Be 'installed'
        $second.plan.mode | Should -Be 're-apply'
        @($second.stanzaActions | ForEach-Object { $_.action }) | Should -Be @('unchanged')
        Get-TreeFingerprint -Root $root | Should -BeExactly $fingerprint
    }
    It 'never writes the student zone' {
        $src = New-FixtureSource 'i10-src'
        $root = New-FixtureInstall 'i10-root'
        $m = Read-FixtureManifest $src
        $before = New-StudentZoneSnapshot -InstallRoot $root -Manifest $m
        Invoke-LearnInstall -SourceRoot $src -InstallRoot $root `
            -ManifestPath (Join-Path $src 'learn/manifest.json') `
            -WorkDir (Join-Path $TestDrive 'i10-work') | Out-Null
        $after = New-StudentZoneSnapshot -InstallRoot $root -Manifest $m
        (Test-StudentZoneUntouched -Before $before -After $after).passed | Should -BeTrue
    }
    It 'catches an exception during the mutate-and-verify phase, rolls back, and reports rolled-back' {
        $src = New-FixtureSource 'i11-src'
        $root = New-FixtureInstall 'i11-root'
        $fingerprint = Get-TreeFingerprint -Root $root
        $r = Invoke-LearnInstall -SourceRoot $src -InstallRoot $root `
            -ManifestPath (Join-Path $src 'learn/manifest.json') `
            -WorkDir (Join-Path $TestDrive 'i11-work') -PostMutateHook {
                param($InstallRoot)
                throw 'simulated disk-full during install'
            }
        $r.status | Should -Be 'rolled-back'
        ($r.failures -join ' ') | Should -Match 'simulated disk-full during install'
        ($r.failures -join ' ') | Should -Match 'not a verify failure'
        $r.studentZoneUnrepaired | Should -BeFalse
        Test-Path (Join-Path $root 'learn') | Should -BeFalse
        Get-TreeFingerprint -Root $root | Should -BeExactly $fingerprint
    }
    It 'flags studentZoneUnrepaired true when the verify failure is a student-zone change' {
        $src = New-FixtureSource 'i12-src'
        $root = New-FixtureInstall 'i12-root'
        $r = Invoke-LearnInstall -SourceRoot $src -InstallRoot $root `
            -ManifestPath (Join-Path $src 'learn/manifest.json') `
            -WorkDir (Join-Path $TestDrive 'i12-work') -PostMutateHook {
                param($InstallRoot)
                Set-Content -LiteralPath (Join-Path $InstallRoot 'projects/personal/kb.md') -Value 'corrupted'
            }
        $r.status | Should -Be 'rolled-back'
        $r.studentZoneUnrepaired | Should -BeTrue
        # Rollback restores learn/ and the stanza files; it never repairs the
        # student zone, so the corruption is still there after rollback.
        Get-Content -LiteralPath (Join-Path $root 'projects/personal/kb.md') | Should -Be 'corrupted'
        Test-Path (Join-Path $root 'learn') | Should -BeFalse
    }
    It 'flags studentZoneUnrepaired false when a normal verify failure has no student-zone involvement' {
        $src = New-FixtureSource 'i13-src'
        $root = New-FixtureInstall 'i13-root'
        $r = Invoke-LearnInstall -SourceRoot $src -InstallRoot $root `
            -ManifestPath (Join-Path $src 'learn/manifest.json') `
            -WorkDir (Join-Path $TestDrive 'i13-work') -PostMutateHook {
                param($InstallRoot)
                Remove-Item -LiteralPath (Join-Path $InstallRoot 'learn/git-and-github/capabilities/page.md') -Force
            }
        $r.status | Should -Be 'rolled-back'
        $r.studentZoneUnrepaired | Should -BeFalse
        ($r.failures -join ' ') | Should -Match 'missing after install'
    }
    It 'surfaces both messages when rollback itself fails after a mutate exception' {
        $src = New-FixtureSource 'i14-src'
        $root = New-FixtureInstall 'i14-root'
        $work = Join-Path $TestDrive 'i14-work'
        # Closure captures $work by value so the hook, though invoked from
        # inside Invoke-LearnInstall's own scope, can still reach it.
        $hook = {
            param($InstallRoot)
            Remove-Item -LiteralPath (Join-Path $work 'backup') -Recurse -Force
            throw 'simulated mutate failure'
        }.GetNewClosure()
        $r = Invoke-LearnInstall -SourceRoot $src -InstallRoot $root `
            -ManifestPath (Join-Path $src 'learn/manifest.json') `
            -WorkDir $work -PostMutateHook $hook
        $r.status | Should -Be 'rolled-back'
        ($r.failures -join ' ') | Should -Match 'simulated mutate failure'
        ($r.failures -join ' ') | Should -Match 'Rollback itself failed'
    }
}

Describe 'Restore-InstallBackup aborts before deleting live content on an incomplete backup' {
    It 'throws and leaves the stanza file untouched when its backup is missing' {
        $src = New-FixtureSource 'r1-src'
        $root = New-FixtureInstall 'r1-root'
        $m = Read-FixtureManifest $src
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest $m
        $plan.mode | Should -Be 'fresh'
        $grimdexBefore = [string](Get-Content -LiteralPath (Join-Path $root 'GRIMDEX.md') -Raw)
        # Apply the stanza live, as install would, but never populate a backup
        # WorkDir for it - simulates a missing/incomplete work directory.
        Set-PointerStanza -Path (Join-Path $root 'GRIMDEX.md') -Content $plan.stanzaContent | Out-Null
        $work = Join-Path $TestDrive 'r1-work'
        New-Item -ItemType Directory -Path $work -Force | Out-Null
        { Restore-InstallBackup -InstallRoot $root -Plan $plan -WorkDir $work } |
            Should -Throw '*missing*'
        # Nothing was deleted: the live file still has the stanza applied
        # exactly as it was before the (failed) restore attempt.
        (Get-PointerStanzaState -Path (Join-Path $root 'GRIMDEX.md')).state | Should -Be 'well-formed'
        Test-Path (Join-Path $root 'GRIMDEX.md') | Should -BeTrue
    }
    It 'throws and leaves the live learn/ tree untouched when the re-apply backup is missing' {
        $src = New-FixtureSource 'r2-src'
        $root = New-FixtureInstall 'r2-root'
        Copy-Item -LiteralPath (Join-Path $src 'learn') -Destination (Join-Path $root 'learn') -Recurse
        $m = Read-FixtureManifest $src
        $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest $m
        $plan.mode | Should -Be 're-apply'
        # Back up only the stanza file, never 'learn' - simulates an
        # incomplete work directory for the re-apply case.
        $work = Join-Path $TestDrive 'r2-work'
        New-Item -ItemType Directory -Path $work -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $root 'GRIMDEX.md') -Destination (Join-Path $work 'GRIMDEX.md')
        { Restore-InstallBackup -InstallRoot $root -Plan $plan -WorkDir $work } |
            Should -Throw '*missing*'
        Test-Path (Join-Path $root 'learn') | Should -BeTrue
        Test-Path (Join-Path $root 'learn/git-and-github/capabilities/page.md') | Should -BeTrue
    }
}

Describe 'Security regressions found by the final adversarial review' {

    Context 'C1 - a manifest cannot relocate the student zone' {
        It 'blocks a stanza aimed at projects/** even when studentRoots is redefined' {
            $src  = New-FixtureSource -Name 'c1src'
            $root = New-FixtureInstall -Name 'c1inst'
            $m = New-FixtureManifestObject
            $m.studentRoots   = @('some-other-dir/**')      # the attack
            $m.pointerStanzas = @(@{ file = 'projects/personal/kb.md' })
            $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest $m
            ($plan.errors -join ' ') | Should -Match 'student root'
            (Get-Content -LiteralPath (Join-Path $root 'projects/personal/kb.md') -Raw) |
                Should -Match 'student knowledge'
        }

        It 'still snapshots projects/** when the manifest omits it' {
            $root = New-FixtureInstall -Name 'c1snap'
            $snap = New-StudentZoneSnapshot -InstallRoot $root -Manifest @{ studentRoots = @('some-other-dir/**') }
            @($snap.files.Keys) -join ',' | Should -Match 'kb\.md'
        }

        It 'Get-EffectiveStudentRoots adds the floor, and leaves it alone when already present' {
            (Get-EffectiveStudentRoots -Manifest @{ studentRoots = @('a/**') }) |
                Should -Contain 'projects/**'
            @(Get-EffectiveStudentRoots -Manifest @{ studentRoots = @('projects/**') }).Count |
                Should -Be 1
        }
    }

    Context 'C2 - a colon is never a valid install path' {
        It 'rejects an NTFS alternate-data-stream stanza target' {
            $src  = New-FixtureSource -Name 'c2src'
            $root = New-FixtureInstall -Name 'c2inst'
            Set-Content -LiteralPath (Join-Path $root 'config/fleet.json') -Value 'SECRET' -NoNewline
            $m = New-FixtureManifestObject
            $m.pointerStanzas = @(@{ file = 'config/fleet.json::$DATA' })
            $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest $m
            ($plan.errors -join ' ') | Should -Match 'colon'
            (Get-Content -LiteralPath (Join-Path $root 'config/fleet.json') -Raw) | Should -BeExactly 'SECRET'
        }

        It 'rejects a drive-relative stanza target' {
            $src  = New-FixtureSource -Name 'c2src2'
            $root = New-FixtureInstall -Name 'c2inst2'
            $m = New-FixtureManifestObject
            $m.pointerStanzas = @(@{ file = 'C:notes.md' })
            (New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest $m).errors -join ' ' |
                Should -Match 'colon'
        }
    }

    Context 'I3 / M8 - what may be treated as our own learn/ directory' {
        It 'refuses a learn path that exists but is not a directory' {
            $src  = New-FixtureSource -Name 'i3src'
            $root = New-FixtureInstall -Name 'i3inst'
            Set-Content -LiteralPath (Join-Path $root 'learn') -Value 'not a directory' -NoNewline
            (New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest (New-FixtureManifestObject)).errors -join ' ' |
                Should -Match 'not a directory'
        }

        It 'refuses a learn/ directory owned by a different module' {
            $src  = New-FixtureSource -Name 'm8src'
            $root = New-FixtureInstall -Name 'm8inst'
            New-Item -ItemType Directory -Path (Join-Path $root 'learn') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $root 'learn/manifest.json') -Value '{"moduleId":"someone-elses-module"}'
            (New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest (New-FixtureManifestObject)).errors -join ' ' |
                Should -Match 'owned by module'
        }

        It 'still accepts a learn/ directory owned by the same module as a re-apply' {
            $src  = New-FixtureSource -Name 'm8src2'
            $root = New-FixtureInstall -Name 'm8inst2'
            New-Item -ItemType Directory -Path (Join-Path $root 'learn') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $root 'learn/manifest.json') -Value '{"moduleId":"git-and-github"}'
            $plan = New-InstallPlan -SourceRoot $src -InstallRoot $root -Manifest (New-FixtureManifestObject)
            $plan.errors | Should -BeNullOrEmpty
            $plan.mode   | Should -Be 're-apply'
        }
    }
}
