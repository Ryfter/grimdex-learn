BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'scripts' 'manifest-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'verify-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'stanza-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'lifecycle-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'install-lib.ps1')

    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

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

    # A Path A checkout: tiny learn/ plus the real compose scripts plus bootstrap.ps1.
    # $PSScriptRoot inside the copied bootstrap is this directory, so compose
    # runs against the fixture module, not the real one.
    function New-BootstrapSource {
        param([string]$Name)
        $src = New-FixtureSource $Name
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'scripts') `
            -Destination (Join-Path $src 'scripts') -Recurse
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'bootstrap.ps1') `
            -Destination (Join-Path $src 'bootstrap.ps1')
        $src
    }
}

Describe 'bootstrap.ps1 CLI' {
    It 'previews with exit 0, prints PREVIEW, and changes nothing' {
        $src = New-BootstrapSource 'boot-preview-src'
        $root = New-FixtureInstall 'boot-preview-root'
        $boot = Join-Path $src 'bootstrap.ps1'
        $out = pwsh -NoProfile -File $boot -InstallRoot $root `
            -WorkDir (Join-Path $TestDrive 'boot-preview-work') -Preview
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'PREVIEW'
        Test-Path (Join-Path $root 'learn') | Should -BeFalse
    }

    It 'installs with exit 0 and lands the content and the stanza' {
        $src = New-BootstrapSource 'boot-install-src'
        $root = New-FixtureInstall 'boot-install-root'
        $boot = Join-Path $src 'bootstrap.ps1'
        $out = pwsh -NoProfile -File $boot -InstallRoot $root `
            -WorkDir (Join-Path $TestDrive 'boot-install-work')
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'INSTALLED'
        Test-Path (Join-Path $root 'learn/git-and-github/capabilities/page.md') | Should -BeTrue
        (Get-PointerStanzaState -Path (Join-Path $root 'GRIMDEX.md')).state | Should -Be 'well-formed'
        [string](Get-Content -LiteralPath (Join-Path $root 'projects/personal/kb.md') -Raw) |
            Should -Match 'student knowledge'
    }

    It 'exits 1 with a readable message when InstallRoot has no GRIMDEX.md' {
        $src = New-BootstrapSource 'boot-nogrim-src'
        $root = New-FixtureInstall 'boot-nogrim-root'
        Remove-Item -LiteralPath (Join-Path $root 'GRIMDEX.md')
        $boot = Join-Path $src 'bootstrap.ps1'
        $out = pwsh -NoProfile -File $boot -InstallRoot $root `
            -WorkDir (Join-Path $TestDrive 'boot-nogrim-work') 2>&1
        $LASTEXITCODE | Should -Be 1
        $text = ($out -join "`n")
        $text | Should -Match 'not a Grimdex install'
        $text | Should -Match 'GRIMDEX.md'
        $text | Should -Not -Match 'ScriptStackTrace'
        Test-Path (Join-Path $root 'learn') | Should -BeFalse
    }

    It 'exits 1 with a readable message when InstallRoot is missing' {
        $src = New-BootstrapSource 'boot-missing-src'
        $boot = Join-Path $src 'bootstrap.ps1'
        $missing = Join-Path $TestDrive 'boot-no-such-install'
        $out = pwsh -NoProfile -File $boot -InstallRoot $missing `
            -WorkDir (Join-Path $TestDrive 'boot-missing-work') 2>&1
        $LASTEXITCODE | Should -Be 1
        ($out -join "`n") | Should -Match 'does not exist'
    }

    It 'exits 1 when learn/manifest.json is missing from the checkout' {
        $src = New-BootstrapSource 'boot-nomanifest-src'
        $root = New-FixtureInstall 'boot-nomanifest-root'
        Remove-Item -LiteralPath (Join-Path $src 'learn/manifest.json')
        $boot = Join-Path $src 'bootstrap.ps1'
        $out = pwsh -NoProfile -File $boot -InstallRoot $root `
            -WorkDir (Join-Path $TestDrive 'boot-nomanifest-work') 2>&1
        $LASTEXITCODE | Should -Be 1
        ($out -join "`n") | Should -Match 'learn/manifest.json'
        Test-Path (Join-Path $root 'learn') | Should -BeFalse
    }

    It 'exits 1 when WorkDir is inside the install root' {
        $src = New-BootstrapSource 'boot-workdir-src'
        $root = New-FixtureInstall 'boot-workdir-root'
        $boot = Join-Path $src 'bootstrap.ps1'
        $out = pwsh -NoProfile -File $boot -InstallRoot $root `
            -WorkDir (Join-Path $root 'work') 2>&1
        $LASTEXITCODE | Should -Be 1
        ($out -join "`n") | Should -Match 'outside'
        Test-Path (Join-Path $root 'learn') | Should -BeFalse
    }

    It 'defaults WorkDir and still installs when -WorkDir is omitted' {
        $src = New-BootstrapSource 'boot-defaultwd-src'
        $root = New-FixtureInstall 'boot-defaultwd-root'
        $boot = Join-Path $src 'bootstrap.ps1'
        $out = pwsh -NoProfile -File $boot -InstallRoot $root
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'INSTALLED'
        Test-Path (Join-Path $root 'learn/manifest.json') | Should -BeTrue
    }

    It 'is idempotent: a second run exits 0 and reports the stanza unchanged' {
        $src = New-BootstrapSource 'boot-idem-src'
        $root = New-FixtureInstall 'boot-idem-root'
        $work = Join-Path $TestDrive 'boot-idem-work'
        $boot = Join-Path $src 'bootstrap.ps1'
        pwsh -NoProfile -File $boot -InstallRoot $root -WorkDir $work | Out-Null
        $LASTEXITCODE | Should -Be 0
        $out = pwsh -NoProfile -File $boot -InstallRoot $root -WorkDir $work
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'unchanged'
    }

    It 'propagates compose exit 1 on an invalid plan and leaves the install untouched' {
        $src = New-BootstrapSource 'boot-badplan-src'
        $root = New-FixtureInstall 'boot-badplan-root'
        # Real compose rejection (New-InstallPlan §7): ownedPaths is learn/,
        # studentRoots is rewritten to learn/** so every source file resolves
        # into a student root. Bootstrap preflight still passes (GRIMDEX.md,
        # manifest, WorkDir outside), so compose is actually invoked.
        $manifestPath = Join-Path $src 'learn/manifest.json'
        $m = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -AsHashtable
        $m['studentRoots'] = @('learn/**')
        $m | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath
        $boot = Join-Path $src 'bootstrap.ps1'
        $out = pwsh -NoProfile -File $boot -InstallRoot $root `
            -WorkDir (Join-Path $TestDrive 'boot-badplan-work')
        $LASTEXITCODE | Should -Be 1
        ($out -join "`n") | Should -Match 'INVALID PLAN'
        Test-Path (Join-Path $root 'learn') | Should -BeFalse
        [string](Get-Content -LiteralPath (Join-Path $root 'projects/personal/kb.md') -Raw) |
            Should -Match 'student knowledge'
    }
}

Describe 'bootstrap.ps1 is a front door, not a second installer' {
    It 'delegates to install-learn.ps1 and never calls Invoke-LearnInstall or the network' {
        $p = Join-Path $script:RepoRoot 'bootstrap.ps1'
        $p | Should -Exist
        $text = [string](Get-Content -LiteralPath $p -Raw)
        $text | Should -Match 'install-learn\.ps1'
        $text | Should -Match '\$invokeArgs'
        $text | Should -Not -Match 'Invoke-LearnInstall'
        $text | Should -Not -Match 'New-InstallPlan'
        $text | Should -Not -Match 'Invoke-WebRequest'
        $text | Should -Not -Match '(?i)(?<![A-Za-z])irm(?![A-Za-z])'
        $text | Should -Not -Match 'Invoke-RestMethod'
        $text | Should -Not -Match 'PUBLIC_RELEASE_REPO_URL'
    }
}
