BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'scripts' 'manifest-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'verify-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'stanza-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'lifecycle-lib.ps1')

    # Builds a minimal composed install: base file with a stanza, learn/,
    # course/, student zone, neverShip config files.
    function New-FixtureInstall {
        param([string]$Name)
        $root = Join-Path $TestDrive $Name
        New-Item -ItemType Directory -Path $root | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'GRIMDEX.md') -NoNewline -Value @"
# Grimdex
<!-- grimdex-learn:start -->
Learn module pointer.
<!-- grimdex-learn:end -->
base text
"@
        foreach ($d in 'learn/git-and-github/capabilities', 'course/wiki',
                       'course/journal', 'projects/personal', 'config') {
            New-Item -ItemType Directory -Path (Join-Path $root $d) -Force | Out-Null
        }
        $manifest = @{
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
        $manifest | ConvertTo-Json -Depth 6 |
            Set-Content -LiteralPath (Join-Path $root 'learn/manifest.json')
        Set-Content -LiteralPath (Join-Path $root 'learn/git-and-github/capabilities/page.md') -Value 'page'
        Set-Content -LiteralPath (Join-Path $root 'course/course.json') -Value '{"wikiUrl":"https://example.invalid/wiki"}'
        Set-Content -LiteralPath (Join-Path $root 'course/journal/schema.md') -Value 'journal schema'
        Set-Content -LiteralPath (Join-Path $root 'projects/personal/kb.md') -Value 'student knowledge'
        Set-Content -LiteralPath (Join-Path $root 'config/learn-progress.json') -Value '{"ledger":[]}'
        Set-Content -LiteralPath (Join-Path $root 'config/settings.json') -Value '{}'
        $root
    }
}

Describe 'New-GraduationPlan' {
    It 'computes a valid Keep plan' {
        $root = New-FixtureInstall 'keep1'
        $m = Read-LearnManifest -Path (Join-Path $root 'learn/manifest.json')
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Keep
        $plan.errors           | Should -BeNullOrEmpty
        $plan.retention        | Should -Be 'Keep'
        $plan.coursePresent    | Should -BeTrue
        $plan.learnPresent     | Should -BeTrue
        $plan.stanzaFiles      | Should -Be @('GRIMDEX.md')
        $plan.neverShipPresent | Should -Be @('config/learn-progress.json', 'config/settings.json')
    }
    It 'validates retention copies on Remove (source under learn/, dest under a student root, dest new)' {
        $root = New-FixtureInstall 'rm1'
        $m = Read-LearnManifest -Path (Join-Path $root 'learn/manifest.json')
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Remove `
            -RetentionCopy @{ 'learn/git-and-github/capabilities/page.md' = 'projects/personal/refs/page.md' }
        $plan.errors | Should -BeNullOrEmpty
        $plan.retentionCopies.Count | Should -Be 1
        $plan.retentionCopies[0].hash | Should -Not -BeNullOrEmpty
    }
    It 'rejects a retention source outside learn/' {
        $root = New-FixtureInstall 'rm2'
        $m = Read-LearnManifest -Path (Join-Path $root 'learn/manifest.json')
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Remove `
            -RetentionCopy @{ 'GRIMDEX.md' = 'projects/personal/refs/g.md' }
        $plan.errors | Should -Not -BeNullOrEmpty
    }
    It 'rejects a retention dest outside student roots' {
        $root = New-FixtureInstall 'rm3'
        $m = Read-LearnManifest -Path (Join-Path $root 'learn/manifest.json')
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Remove `
            -RetentionCopy @{ 'learn/git-and-github/capabilities/page.md' = 'docs/page.md' }
        $plan.errors | Should -Not -BeNullOrEmpty
    }
    It 'rejects a retention dest that already exists (never overwrite student files)' {
        $root = New-FixtureInstall 'rm4'
        $m = Read-LearnManifest -Path (Join-Path $root 'learn/manifest.json')
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Remove `
            -RetentionCopy @{ 'learn/git-and-github/capabilities/page.md' = 'projects/personal/kb.md' }
        $plan.errors | Should -Not -BeNullOrEmpty
    }
    It 'rejects retention copies on Keep (Learn stays; nothing to salvage)' {
        $root = New-FixtureInstall 'keep2'
        $m = Read-LearnManifest -Path (Join-Path $root 'learn/manifest.json')
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Keep `
            -RetentionCopy @{ 'learn/git-and-github/capabilities/page.md' = 'projects/personal/refs/page.md' }
        $plan.errors | Should -Not -BeNullOrEmpty
    }
    It 'flags a malformed stanza file as a plan error' {
        $root = New-FixtureInstall 'bad1'
        Set-Content -LiteralPath (Join-Path $root 'GRIMDEX.md') -NoNewline `
            -Value "<!-- grimdex-learn:start -->`nno end"
        $m = Read-LearnManifest -Path (Join-Path $root 'learn/manifest.json')
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Keep
        $plan.errors | Should -Not -BeNullOrEmpty
    }
    It 'rejects a retention source that traverses out of learn/ via ..' {
        $root = New-FixtureInstall 'trav1'
        $m = Read-LearnManifest -Path (Join-Path $root 'learn/manifest.json')
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Remove `
            -RetentionCopy @{ 'learn/../GRIMDEX.md' = 'projects/personal/refs/g.md' }
        $plan.errors | Should -Not -BeNullOrEmpty
    }
    It 'rejects a retention dest that traverses out of the student root via ..' {
        $root = New-FixtureInstall 'trav2'
        $m = Read-LearnManifest -Path (Join-Path $root 'learn/manifest.json')
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Remove `
            -RetentionCopy @{ 'learn/git-and-github/capabilities/page.md' = 'projects/../docs/evil.md' }
        $plan.errors | Should -Not -BeNullOrEmpty
    }
    It 'rejects an absolute retention dest' {
        $root = New-FixtureInstall 'trav3'
        $m = Read-LearnManifest -Path (Join-Path $root 'learn/manifest.json')
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Remove `
            -RetentionCopy @{ 'learn/git-and-github/capabilities/page.md' = 'C:\evil\dest.md' }
        $plan.errors | Should -Not -BeNullOrEmpty
    }
    It 'flags a stanza file that escapes the install root as a plan error' {
        $root = New-FixtureInstall 'esc1'
        $mPath = Join-Path $root 'learn/manifest.json'
        $json = Get-Content -LiteralPath $mPath -Raw | ConvertFrom-Json
        $json.pointerStanzas[0].file = '../escape.md'
        $json | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $mPath
        $m = Read-LearnManifest -Path $mPath
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Remove
        ($plan.errors -join ' ') | Should -Match 'escapes the install root'
    }
    It 'flags a stanza file inside a student root as a plan error' {
        $root = New-FixtureInstall 'esc2'
        $mPath = Join-Path $root 'learn/manifest.json'
        $json = Get-Content -LiteralPath $mPath -Raw | ConvertFrom-Json
        $json.pointerStanzas[0].file = 'projects/personal/kb.md'
        $json | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $mPath
        $m = Read-LearnManifest -Path $mPath
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Remove
        ($plan.errors -join ' ') | Should -Match 'inside a student root'
    }
    It 'rejects two retention sources mapping to the same dest' {
        $root = New-FixtureInstall 'dup1'
        $m = Read-LearnManifest -Path (Join-Path $root 'learn/manifest.json')
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Remove `
            -RetentionCopy @{
                'learn/git-and-github/capabilities/page.md' = 'projects/personal/refs/x.md'
                'learn/manifest.json'                       = 'projects/personal/refs/x.md'
            }
        ($plan.errors -join ' ') | Should -Match 'more than one source'
    }
}

Describe 'Backup-GraduationTargets / Restore-GraduationBackup' {
    It 'round-trips: mutate after backup, restore returns install to pre-state' {
        $root = New-FixtureInstall 'bk1'
        $m = Read-LearnManifest -Path (Join-Path $root 'learn/manifest.json')
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Remove `
            -RetentionCopy @{ 'learn/git-and-github/capabilities/page.md' = 'projects/personal/refs/page.md' }
        $bk = Join-Path $TestDrive 'bk1-backup'

        $before = New-StudentZoneSnapshot -InstallRoot $root -Manifest $m
        $grimdexBefore = [string](Get-Content -LiteralPath (Join-Path $root 'GRIMDEX.md') -Raw)

        Backup-GraduationTargets -InstallRoot $root -Plan $plan -BackupDir $bk | Out-Null

        # Simulate the graduation mutations (and the retention copy)
        New-Item -ItemType Directory -Path (Join-Path $root 'projects/personal/refs') | Out-Null
        Copy-Item (Join-Path $root 'learn/git-and-github/capabilities/page.md') `
                  (Join-Path $root 'projects/personal/refs/page.md')
        Remove-Item -Recurse -Force (Join-Path $root 'course')
        Remove-Item -Recurse -Force (Join-Path $root 'learn')
        Remove-PointerStanza -Path (Join-Path $root 'GRIMDEX.md') | Out-Null

        Restore-GraduationBackup -InstallRoot $root -Plan $plan -BackupDir $bk

        Test-Path (Join-Path $root 'course/course.json')      | Should -BeTrue
        Test-Path (Join-Path $root 'learn/manifest.json')     | Should -BeTrue
        Test-Path (Join-Path $root 'projects/personal/refs')  | Should -BeFalse
        [string](Get-Content -LiteralPath (Join-Path $root 'GRIMDEX.md') -Raw) |
            Should -Be $grimdexBefore
        $after = New-StudentZoneSnapshot -InstallRoot $root -Manifest $m
        (Test-StudentZoneUntouched -Before $before -After $after).passed | Should -BeTrue
    }
    It 'Keep plan backs up course and stanza files but not learn/' {
        $root = New-FixtureInstall 'bk2'
        $m = Read-LearnManifest -Path (Join-Path $root 'learn/manifest.json')
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Keep
        $bk = Join-Path $TestDrive 'bk2-backup'
        $r = Backup-GraduationTargets -InstallRoot $root -Plan $plan -BackupDir $bk
        Test-Path (Join-Path $bk 'course/course.json') | Should -BeTrue
        Test-Path (Join-Path $bk 'GRIMDEX.md')         | Should -BeTrue
        Test-Path (Join-Path $bk 'learn')              | Should -BeFalse
    }
    It 'rollback preserves a pre-existing empty student directory' {
        $root = New-FixtureInstall 'pre1'
        New-Item -ItemType Directory -Path (Join-Path $root 'projects/personal/refs') | Out-Null
        $m = Read-LearnManifest -Path (Join-Path $root 'learn/manifest.json')
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Remove `
            -RetentionCopy @{ 'learn/git-and-github/capabilities/page.md' = 'projects/personal/refs/page.md' }
        $bk = Join-Path $TestDrive 'pre1-bk'
        Backup-GraduationTargets -InstallRoot $root -Plan $plan -BackupDir $bk | Out-Null
        Copy-Item (Join-Path $root 'learn/git-and-github/capabilities/page.md') `
                  (Join-Path $root 'projects/personal/refs/page.md')
        Restore-GraduationBackup -InstallRoot $root -Plan $plan -BackupDir $bk
        Test-Path (Join-Path $root 'projects/personal/refs')         | Should -BeTrue
        Test-Path (Join-Path $root 'projects/personal/refs/page.md') | Should -BeFalse
    }
}

Describe 'Restore-GraduationBackup aborts before deleting live content on an incomplete backup' {
    It 'throws and leaves live course/ untouched when its backup is missing' {
        $root = New-FixtureInstall 'rg1'
        $m = Read-LearnManifest -Path (Join-Path $root 'learn/manifest.json')
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Keep
        $bk = Join-Path $TestDrive 'rg1-backup'
        Backup-GraduationTargets -InstallRoot $root -Plan $plan -BackupDir $bk | Out-Null
        # Simulate an interrupted/externally-cleaned backup: the course/ backup
        # disappears after Backup-GraduationTargets already copied it.
        Remove-Item -LiteralPath (Join-Path $bk 'course') -Recurse -Force
        { Restore-GraduationBackup -InstallRoot $root -Plan $plan -BackupDir $bk } |
            Should -Throw '*missing*'
        # Nothing was deleted: course/ and learn/ are exactly as they were
        # before the (failed) restore attempt.
        Test-Path (Join-Path $root 'course/course.json')  | Should -BeTrue
        Test-Path (Join-Path $root 'learn/manifest.json') | Should -BeTrue
    }
    It 'throws and leaves the live stanza file untouched when its backup is missing (Remove retention)' {
        $root = New-FixtureInstall 'rg2'
        $m = Read-LearnManifest -Path (Join-Path $root 'learn/manifest.json')
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Remove
        $bk = Join-Path $TestDrive 'rg2-backup'
        Backup-GraduationTargets -InstallRoot $root -Plan $plan -BackupDir $bk | Out-Null
        $grimdexBefore = [string](Get-Content -LiteralPath (Join-Path $root 'GRIMDEX.md') -Raw)
        # course/ and learn/ backups are intact; only the stanza file's backup
        # goes missing, so only that check should trip - but it must trip
        # before ANYTHING (including course/learn) gets removed.
        Remove-Item -LiteralPath (Join-Path $bk 'GRIMDEX.md') -Force
        { Restore-GraduationBackup -InstallRoot $root -Plan $plan -BackupDir $bk } |
            Should -Throw '*missing*'
        [string](Get-Content -LiteralPath (Join-Path $root 'GRIMDEX.md') -Raw) | Should -Be $grimdexBefore
        Test-Path (Join-Path $root 'course/course.json')  | Should -BeTrue
        Test-Path (Join-Path $root 'learn/manifest.json') | Should -BeTrue
    }
}

Describe 'Test-GraduationPostState' {
    BeforeEach {
        $script:root = New-FixtureInstall "ps-$([guid]::NewGuid().ToString('n').Substring(0,8))"
        $script:m = Read-LearnManifest -Path (Join-Path $root 'learn/manifest.json')
    }

    It 'passes a correct Keep post-state' {
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Keep
        $before = New-StudentZoneSnapshot -InstallRoot $root -Manifest $m
        Remove-Item -Recurse -Force (Join-Path $root 'course')
        $r = Test-GraduationPostState -InstallRoot $root -Manifest $m -Plan $plan -BeforeSnapshot $before
        $r.failures | Should -BeNullOrEmpty
        $r.passed   | Should -BeTrue
    }
    It 'passes a correct Remove post-state including the allow-listed retention copy' {
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Remove `
            -RetentionCopy @{ 'learn/git-and-github/capabilities/page.md' = 'projects/personal/refs/page.md' }
        $before = New-StudentZoneSnapshot -InstallRoot $root -Manifest $m
        New-Item -ItemType Directory -Path (Join-Path $root 'projects/personal/refs') | Out-Null
        Copy-Item (Join-Path $root 'learn/git-and-github/capabilities/page.md') `
                  (Join-Path $root 'projects/personal/refs/page.md')
        Remove-Item -Recurse -Force (Join-Path $root 'course')
        Remove-PointerStanza -Path (Join-Path $root 'GRIMDEX.md') | Out-Null
        Remove-Item -Recurse -Force (Join-Path $root 'learn')
        $r = Test-GraduationPostState -InstallRoot $root -Manifest $m -Plan $plan -BeforeSnapshot $before
        $r.failures | Should -BeNullOrEmpty
        $r.passed   | Should -BeTrue
    }
    It 'fails when course/ survives' {
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Keep
        $before = New-StudentZoneSnapshot -InstallRoot $root -Manifest $m
        $r = Test-GraduationPostState -InstallRoot $root -Manifest $m -Plan $plan -BeforeSnapshot $before
        $r.passed | Should -BeFalse
        ($r.failures -join ' ') | Should -Match 'course'
    }
    It 'fails Keep when the stanza was stripped anyway' {
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Keep
        $before = New-StudentZoneSnapshot -InstallRoot $root -Manifest $m
        Remove-Item -Recurse -Force (Join-Path $root 'course')
        Remove-PointerStanza -Path (Join-Path $root 'GRIMDEX.md') | Out-Null
        (Test-GraduationPostState -InstallRoot $root -Manifest $m -Plan $plan -BeforeSnapshot $before).passed |
            Should -BeFalse
    }
    It 'fails Remove when learn/ survives or a stanza survives' {
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Remove
        $before = New-StudentZoneSnapshot -InstallRoot $root -Manifest $m
        Remove-Item -Recurse -Force (Join-Path $root 'course')
        $r = Test-GraduationPostState -InstallRoot $root -Manifest $m -Plan $plan -BeforeSnapshot $before
        $r.passed | Should -BeFalse
        ($r.failures -join ' ') | Should -Match 'learn'
    }
    It 'fails on an unexpected student-zone addition (not in the allow-list)' {
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Keep
        $before = New-StudentZoneSnapshot -InstallRoot $root -Manifest $m
        Remove-Item -Recurse -Force (Join-Path $root 'course')
        Set-Content -LiteralPath (Join-Path $root 'projects/personal/intruder.md') -Value 'x'
        (Test-GraduationPostState -InstallRoot $root -Manifest $m -Plan $plan -BeforeSnapshot $before).passed |
            Should -BeFalse
    }
    It 'fails when an allow-listed retention copy has the wrong content' {
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Remove `
            -RetentionCopy @{ 'learn/git-and-github/capabilities/page.md' = 'projects/personal/refs/page.md' }
        $before = New-StudentZoneSnapshot -InstallRoot $root -Manifest $m
        New-Item -ItemType Directory -Path (Join-Path $root 'projects/personal/refs') | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'projects/personal/refs/page.md') -Value 'tampered'
        Remove-Item -Recurse -Force (Join-Path $root 'course')
        Remove-PointerStanza -Path (Join-Path $root 'GRIMDEX.md') | Out-Null
        Remove-Item -Recurse -Force (Join-Path $root 'learn')
        (Test-GraduationPostState -InstallRoot $root -Manifest $m -Plan $plan -BeforeSnapshot $before).passed |
            Should -BeFalse
    }
    It 'fails when a student file was modified' {
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Keep
        $before = New-StudentZoneSnapshot -InstallRoot $root -Manifest $m
        Remove-Item -Recurse -Force (Join-Path $root 'course')
        Set-Content -LiteralPath (Join-Path $root 'projects/personal/kb.md') -Value 'overwritten'
        (Test-GraduationPostState -InstallRoot $root -Manifest $m -Plan $plan -BeforeSnapshot $before).passed |
            Should -BeFalse
    }
    It 'fails when a neverShip file disappeared' {
        $plan = New-GraduationPlan -InstallRoot $root -Manifest $m -Retention Keep
        $before = New-StudentZoneSnapshot -InstallRoot $root -Manifest $m
        Remove-Item -Recurse -Force (Join-Path $root 'course')
        Remove-Item -LiteralPath (Join-Path $root 'config/learn-progress.json')
        (Test-GraduationPostState -InstallRoot $root -Manifest $m -Plan $plan -BeforeSnapshot $before).passed |
            Should -BeFalse
    }
}
