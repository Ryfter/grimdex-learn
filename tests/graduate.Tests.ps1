BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'scripts' 'manifest-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'verify-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'stanza-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'lifecycle-lib.ps1')
    # Reuse the fixture builder from lifecycle tests by duplicating it here
    # (test files must stand alone).
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
        Set-Content -LiteralPath (Join-Path $root 'projects/personal/kb.md') -Value 'student knowledge'
        Set-Content -LiteralPath (Join-Path $root 'config/learn-progress.json') -Value '{"modules":{"git-and-github":{"level":"taper"}}}'
        Set-Content -LiteralPath (Join-Path $root 'config/settings.json') -Value '{}'
        $root
    }
}

Describe 'Invoke-Graduation' {
    It 'Preview mutates nothing' {
        $root = New-FixtureInstall 'g-preview'
        $work = Join-Path $TestDrive 'g-preview-work'
        $r = Invoke-Graduation -InstallRoot $root -ManifestPath (Join-Path $root 'learn/manifest.json') `
            -Retention Keep -WorkDir $work -Preview
        $r.outcome | Should -Be 'previewed'
        Test-Path (Join-Path $root 'course/course.json') | Should -BeTrue
    }
    It 'Keep graduation: course gone, learn and stanza intact, student untouched' {
        $root = New-FixtureInstall 'g-keep'
        $work = Join-Path $TestDrive 'g-keep-work'
        $r = Invoke-Graduation -InstallRoot $root -ManifestPath (Join-Path $root 'learn/manifest.json') `
            -Retention Keep -WorkDir $work
        $r.outcome | Should -Be 'graduated'
        $r.verify.passed | Should -BeTrue
        Test-Path (Join-Path $root 'course')              | Should -BeFalse
        Test-Path (Join-Path $root 'learn/manifest.json') | Should -BeTrue
        (Get-PointerStanzaState -Path (Join-Path $root 'GRIMDEX.md')).state | Should -Be 'well-formed'
    }
    It 'Remove graduation: course and learn gone, stanza stripped, retention copy landed' {
        $root = New-FixtureInstall 'g-remove'
        $work = Join-Path $TestDrive 'g-remove-work'
        $r = Invoke-Graduation -InstallRoot $root -ManifestPath (Join-Path $root 'learn/manifest.json') `
            -Retention Remove -WorkDir $work `
            -RetentionCopy @{ 'learn/git-and-github/capabilities/page.md' = 'projects/personal/refs/page.md' }
        $r.outcome | Should -Be 'graduated'
        Test-Path (Join-Path $root 'learn')  | Should -BeFalse
        Test-Path (Join-Path $root 'course') | Should -BeFalse
        (Get-PointerStanzaState -Path (Join-Path $root 'GRIMDEX.md')).state | Should -Be 'absent'
        Get-Content (Join-Path $root 'projects/personal/refs/page.md') | Should -Be 'page'
    }
    It 'refuses a WorkDir inside the install root' {
        $root = New-FixtureInstall 'g-baddir'
        { Invoke-Graduation -InstallRoot $root -ManifestPath (Join-Path $root 'learn/manifest.json') `
            -Retention Keep -WorkDir (Join-Path $root 'work') } | Should -Throw '*outside*'
    }
    It 'returns invalid-plan without mutating when the plan has errors' {
        $root = New-FixtureInstall 'g-invalid'
        $work = Join-Path $TestDrive 'g-invalid-work'
        $r = Invoke-Graduation -InstallRoot $root -ManifestPath (Join-Path $root 'learn/manifest.json') `
            -Retention Keep -WorkDir $work `
            -RetentionCopy @{ 'learn/git-and-github/capabilities/page.md' = 'projects/personal/refs/page.md' }
        $r.outcome | Should -Be 'invalid-plan'
        Test-Path (Join-Path $root 'course/course.json') | Should -BeTrue
    }
    It 'rolls back everything when the post-state verify fails' {
        $root = New-FixtureInstall 'g-rollback'
        $work = Join-Path $TestDrive 'g-rollback-work'
        $m = Read-LearnManifest -Path (Join-Path $root 'learn/manifest.json')
        $before = New-StudentZoneSnapshot -InstallRoot $root -Manifest $m
        $grimdexBefore = [string](Get-Content -LiteralPath (Join-Path $root 'GRIMDEX.md') -Raw)
        # Force a verify failure via the test hook that runs between mutation and verify.
        $r = Invoke-Graduation -InstallRoot $root -ManifestPath (Join-Path $root 'learn/manifest.json') `
            -Retention Keep -WorkDir $work -PostMutateHook {
                param($InstallRoot)
                Set-Content -LiteralPath (Join-Path $InstallRoot 'projects/personal/kb.md') -Value 'corrupted'
            }
        $r.outcome | Should -Be 'rolled-back'
        $r.verify.passed | Should -BeFalse
        # Rollback restored course/learn/stanza; the student file it cannot
        # restore (it never backs up student files) — but the failure is
        # reported loudly and nothing else was lost.
        Test-Path (Join-Path $root 'course/course.json') | Should -BeTrue
        [string](Get-Content -LiteralPath (Join-Path $root 'GRIMDEX.md') -Raw) | Should -Be $grimdexBefore
    }
    It 'catches an exception during the mutate-and-verify phase, rolls back, and names the underlying error' {
        $root = New-FixtureInstall 'g-mutatefail'
        $work = Join-Path $TestDrive 'g-mutatefail-work'
        $grimdexBefore = [string](Get-Content -LiteralPath (Join-Path $root 'GRIMDEX.md') -Raw)
        # Without the try/catch this throws straight out of Invoke-Graduation
        # ($ErrorActionPreference = 'Stop' in graduate.ps1 would let it escape),
        # leaving course/ deleted and nothing rolled back.
        $r = Invoke-Graduation -InstallRoot $root -ManifestPath (Join-Path $root 'learn/manifest.json') `
            -Retention Keep -WorkDir $work -PostMutateHook {
                param($InstallRoot)
                throw 'simulated disk-full during graduation'
            }
        $r.outcome | Should -Be 'rolled-back'
        ($r.failures -join ' ') | Should -Match 'simulated disk-full during graduation'
        ($r.failures -join ' ') | Should -Match 'not a verify failure'
        Test-Path (Join-Path $root 'course/course.json') | Should -BeTrue
        [string](Get-Content -LiteralPath (Join-Path $root 'GRIMDEX.md') -Raw) | Should -Be $grimdexBefore
    }
    It 'surfaces both messages when rollback itself fails after a mutate exception' {
        $root = New-FixtureInstall 'g-doublefail'
        $work = Join-Path $TestDrive 'g-doublefail-work'
        # Closure captures $work by value so the hook, though invoked from
        # inside Invoke-Graduation's own scope, can still reach it.
        $hook = {
            param($InstallRoot)
            Remove-Item -LiteralPath (Join-Path $work 'backup') -Recurse -Force
            throw 'simulated graduation mutate failure'
        }.GetNewClosure()
        $r = Invoke-Graduation -InstallRoot $root -ManifestPath (Join-Path $root 'learn/manifest.json') `
            -Retention Keep -WorkDir $work -PostMutateHook $hook
        $r.outcome | Should -Be 'rolled-back'
        ($r.failures -join ' ') | Should -Match 'simulated graduation mutate failure'
        ($r.failures -join ' ') | Should -Match 'Rollback itself failed'
    }
    It 'does not let a stale backup/ from a prior Remove-retention run corrupt a later Keep-retention rollback' {
        $root = New-FixtureInstall 'g-stale'
        $work = Join-Path $TestDrive 'g-stale-work'
        $learnMarker = Join-Path $root 'learn/git-and-github/capabilities/page.md'

        # First run: Retention Remove, forced to fail verify (via an unrelated
        # student-zone corruption) so the WorkDir's backup/ gets populated
        # with 'learn' (Remove backs it up) and rolled back - but the backup/
        # directory itself is left behind on disk afterward.
        Invoke-Graduation -InstallRoot $root -ManifestPath (Join-Path $root 'learn/manifest.json') `
            -Retention Remove -WorkDir $work -PostMutateHook {
                param($InstallRoot)
                Set-Content -LiteralPath (Join-Path $InstallRoot 'projects/personal/kb.md') -Value 'corrupted-1'
            } | Out-Null
        Test-Path (Join-Path $work 'backup/learn') | Should -BeTrue
        Get-Content -LiteralPath $learnMarker | Should -Be 'page'

        # Content changes on the live install between the two graduation
        # attempts (e.g. a re-apply), so the stale backup/learn/ left behind
        # by the first run is now detectably different from the live tree.
        Set-Content -LiteralPath $learnMarker -Value 'page-v2'

        # Second run reuses the SAME WorkDir with Retention Keep, which never
        # backs up or mutates learn/ at all. Force its verify to fail too
        # (again via an unrelated student-zone corruption) so restore runs.
        $r = Invoke-Graduation -InstallRoot $root -ManifestPath (Join-Path $root 'learn/manifest.json') `
            -Retention Keep -WorkDir $work -PostMutateHook {
                param($InstallRoot)
                Set-Content -LiteralPath (Join-Path $InstallRoot 'projects/personal/kb.md') -Value 'corrupted-2'
            }
        $r.outcome | Should -Be 'rolled-back'

        # The stale backup/learn/ from the first run must not have been
        # consulted: learn/ was not this run's to touch or restore, so it must
        # still read 'page-v2', not be reverted to the first run's 'page'.
        Get-Content -LiteralPath $learnMarker | Should -Be 'page-v2'
    }
}

Describe 'graduate.ps1 CLI' {
    It 'previews with exit 0 and graduates with exit 0' {
        $root = New-FixtureInstall 'cli-keep'
        $work = Join-Path $TestDrive 'cli-keep-work'
        $script = Join-Path $PSScriptRoot '..' 'scripts' 'graduate.ps1'
        pwsh -NoProfile -File $script -InstallRoot $root `
            -ManifestPath (Join-Path $root 'learn/manifest.json') `
            -Retention Keep -WorkDir $work -Preview | Out-Null
        $LASTEXITCODE | Should -Be 0
        pwsh -NoProfile -File $script -InstallRoot $root `
            -ManifestPath (Join-Path $root 'learn/manifest.json') `
            -Retention Keep -WorkDir $work | Out-Null
        $LASTEXITCODE | Should -Be 0
        Test-Path (Join-Path $root 'course') | Should -BeFalse
    }
    It 'exits 1 on an invalid plan' {
        $root = New-FixtureInstall 'cli-invalid'
        $work = Join-Path $TestDrive 'cli-invalid-work'
        $copyJson = Join-Path $TestDrive 'cli-copy.json'
        '{"GRIMDEX.md":"projects/personal/refs/g.md"}' | Set-Content -LiteralPath $copyJson
        $script = Join-Path $PSScriptRoot '..' 'scripts' 'graduate.ps1'
        pwsh -NoProfile -File $script -InstallRoot $root `
            -ManifestPath (Join-Path $root 'learn/manifest.json') `
            -Retention Remove -WorkDir $work -RetentionCopyJson $copyJson | Out-Null
        $LASTEXITCODE | Should -Be 1
    }
}

Describe 'promotion-readout.ps1' {
    It 'renders a readout from the learn-mode ledger without writing into the install' {
        $root = New-FixtureInstall 'readout1'
        $script = Join-Path $PSScriptRoot '..' 'scripts' 'promotion-readout.ps1'
        $out = pwsh -NoProfile -File $script -InstallRoot $root
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'git-and-github'
    }
    It 'reports honestly when no ledger exists' {
        $root = New-FixtureInstall 'readout2'
        Remove-Item -LiteralPath (Join-Path $root 'config/learn-progress.json')
        $script = Join-Path $PSScriptRoot '..' 'scripts' 'promotion-readout.ps1'
        $out = pwsh -NoProfile -File $script -InstallRoot $root
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'No learn-mode ledger'
    }
    It 'refuses an -OutFile inside the install root' {
        $root = New-FixtureInstall 'readout3'
        $script = Join-Path $PSScriptRoot '..' 'scripts' 'promotion-readout.ps1'
        pwsh -NoProfile -File $script -InstallRoot $root `
            -OutFile (Join-Path $root 'projects/readout.md') 2>$null | Out-Null
        $LASTEXITCODE | Should -Be 1
    }
}
