BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'scripts' 'manifest-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'verify-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'stanza-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'lifecycle-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'install-lib.ps1')

    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:Cli = Join-Path $script:RepoRoot 'scripts' 'install-learn.ps1'

    # Test files must stand alone, so the fixture builders are repeated here.
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
    function New-FixtureSource {
        param([string]$Name)
        $src = Join-Path $TestDrive $Name
        New-Item -ItemType Directory -Path (Join-Path $src 'learn/git-and-github/capabilities') -Force | Out-Null
        (New-FixtureManifestObject) | ConvertTo-Json -Depth 6 |
            Set-Content -LiteralPath (Join-Path $src 'learn/manifest.json')
        Set-Content -LiteralPath (Join-Path $src 'learn/git-and-github/capabilities/page.md') -Value 'page one'
        Set-Content -LiteralPath (Join-Path $src 'learn/git-and-github/README.md') -Value 'module readme'
        $src
    }
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
}

Describe 'install-learn.ps1 CLI' {
    It 'previews with exit 0 and changes nothing' {
        $src = New-FixtureSource 'c1-src'
        $root = New-FixtureInstall 'c1-root'
        $out = pwsh -NoProfile -File $script:Cli -SourceRoot $src -InstallRoot $root `
            -ManifestPath (Join-Path $src 'learn/manifest.json') `
            -WorkDir (Join-Path $TestDrive 'c1-work') -Preview
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'PREVIEW'
        ($out -join "`n") | Should -Match 'GRIMDEX.md'
        Test-Path (Join-Path $root 'learn') | Should -BeFalse
    }
    It 'installs with exit 0 and lands the content and the stanza' {
        $src = New-FixtureSource 'c2-src'
        $root = New-FixtureInstall 'c2-root'
        $out = pwsh -NoProfile -File $script:Cli -SourceRoot $src -InstallRoot $root `
            -ManifestPath (Join-Path $src 'learn/manifest.json') `
            -WorkDir (Join-Path $TestDrive 'c2-work')
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'INSTALLED'
        Test-Path (Join-Path $root 'learn/git-and-github/capabilities/page.md') | Should -BeTrue
        (Get-PointerStanzaState -Path (Join-Path $root 'GRIMDEX.md')).state | Should -Be 'well-formed'
    }
    It 'exits 1 on an invalid plan and changes nothing' {
        $src = New-FixtureSource 'c3-src'
        $root = New-FixtureInstall 'c3-root'
        Remove-Item -LiteralPath (Join-Path $root 'GRIMDEX.md')
        $out = pwsh -NoProfile -File $script:Cli -SourceRoot $src -InstallRoot $root `
            -ManifestPath (Join-Path $src 'learn/manifest.json') `
            -WorkDir (Join-Path $TestDrive 'c3-work')
        $LASTEXITCODE | Should -Be 1
        ($out -join "`n") | Should -Match 'INVALID PLAN'
        Test-Path (Join-Path $root 'learn') | Should -BeFalse
    }
    It 'exits 1 with a readable message, not a stack trace, on a malformed manifest' {
        $src = New-FixtureSource 'c4-src'
        $root = New-FixtureInstall 'c4-root'
        Set-Content -LiteralPath (Join-Path $src 'learn/manifest.json') -Value '{ not json'
        $out = pwsh -NoProfile -File $script:Cli -SourceRoot $src -InstallRoot $root `
            -ManifestPath (Join-Path $src 'learn/manifest.json') `
            -WorkDir (Join-Path $TestDrive 'c4-work') 2>&1
        $LASTEXITCODE | Should -Be 1
        $text = ($out -join "`n")
        $text | Should -Match 'INSTALL ABORTED'
        $text | Should -Not -Match 'ScriptStackTrace'
    }
    It 'exits 1 when the WorkDir is inside the install root' {
        $src = New-FixtureSource 'c5-src'
        $root = New-FixtureInstall 'c5-root'
        $out = pwsh -NoProfile -File $script:Cli -SourceRoot $src -InstallRoot $root `
            -ManifestPath (Join-Path $src 'learn/manifest.json') `
            -WorkDir (Join-Path $root 'work') 2>&1
        $LASTEXITCODE | Should -Be 1
        ($out -join "`n") | Should -Match 'outside'
    }
    It 'is idempotent from the CLI: a second run exits 0 and reports the stanza unchanged' {
        $src = New-FixtureSource 'c6-src'
        $root = New-FixtureInstall 'c6-root'
        $work = Join-Path $TestDrive 'c6-work'
        pwsh -NoProfile -File $script:Cli -SourceRoot $src -InstallRoot $root `
            -ManifestPath (Join-Path $src 'learn/manifest.json') -WorkDir $work | Out-Null
        $LASTEXITCODE | Should -Be 0
        $out = pwsh -NoProfile -File $script:Cli -SourceRoot $src -InstallRoot $root `
            -ManifestPath (Join-Path $src 'learn/manifest.json') -WorkDir $work
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'unchanged'
    }
}

Describe 'Install documentation' {
    It 'INSTALL.md gives an agent the platform line, the preview command and the student promise' {
        $p = Join-Path $script:RepoRoot 'INSTALL.md'
        $p | Should -Exist
        $text = [string](Get-Content -LiteralPath $p -Raw)
        $text | Should -Match 'Windows 10/11'
        $text | Should -Match 'PowerShell 7'
        $text | Should -Match 'macOS'
        $text | Should -Match 'install-learn\.ps1'
        $text | Should -Match '-Preview'
        $text | Should -Match 'verify-student-zone\.ps1'
        $text | Should -Match 'version-check\.ps1'
        $text | Should -Match 'projects/\*\*'
        $text | Should -Match 'compose step'
        $text | Should -Match 'no network access'
        $text | Should -Not -Match 'There is no installer program, no download, and no network access\.'
    }
    It 'INSTALL.md pins the clone to a release tag and keeps compose local' {
        $p = Join-Path $script:RepoRoot 'INSTALL.md'
        $text = [string](Get-Content -LiteralPath $p -Raw)
        $text | Should -Match 'git clone --branch <release-tag>'
        $text | Should -Match 'scripts/install-learn\.ps1'
        $text | Should -Match 'only network step'
        $text | Should -Not -Match 'PUBLIC_RELEASE_REPO_URL'
    }
    It 'QUICKSTART.md teaches Path A and says the one-liner is a trust hop' {
        $p = Join-Path $script:RepoRoot 'QUICKSTART.md'
        $p | Should -Exist
        $text = [string](Get-Content -LiteralPath $p -Raw)
        $text | Should -Match 'git clone --branch v0\.2\.0-fall2026-draft'
        $text | Should -Match 'https://github.com/Ryfter/grimdex-learn'
        $text | Should -Match 'bootstrap\.ps1'
        $text | Should -Match '-InstallRoot'
        $text | Should -Match 'INSTALLED'
        $text | Should -Match 'grimdex-learn:start'
        $text | Should -Match 'trust hop'
        $text | Should -Match 'relocates the clone'
        $text | Should -Not -Match 'Invoke-LearnInstall'
        $text | Should -Not -Match 'install-learn\.ps1'
        $install = [string](Get-Content -LiteralPath (Join-Path $script:RepoRoot 'INSTALL.md') -Raw)
        $install | Should -Match 'QUICKSTART.md'
    }
}

# Internal design doc — not on the shipping surface. Runs in the source
# repo; skips in a published snapshot so the pack suite stays green.
Describe 'Source-repo install documentation' {
    It 'docs/install.md documents the exit codes and the known limitations' {
        $p = Join-Path $script:RepoRoot 'docs' 'install.md'
        if (-not (Test-Path -LiteralPath $p)) {
            Set-ItResult -Skipped -Because 'source-repo only; docs/ is not on the shipping surface'
            return
        }
        $text = [string](Get-Content -LiteralPath $p -Raw)
        $text | Should -Match '(?m)^## Known limitations'
        $text | Should -Match 'exit 0'
        $text | Should -Match 'exit 1'
        $text | Should -Match 'exit 2'
    }
}
