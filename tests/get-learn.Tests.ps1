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

    # Fetched tree: tiny learn/ + real scripts + real bootstrap.ps1 + get-learn.ps1.
    function New-PathBSource {
        param([string]$Name)
        $src = New-FixtureSource $Name
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'scripts') `
            -Destination (Join-Path $src 'scripts') -Recurse
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'bootstrap.ps1') `
            -Destination (Join-Path $src 'bootstrap.ps1')
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'get-learn.ps1') `
            -Destination (Join-Path $src 'get-learn.ps1')
        $src
    }

    # Restore the RELEASE_TAG sentinel on a fixture copy so the no-tag
    # refusal stays under test after the shipped script carries a real tag.
    # Neutralize Invoke-WebRequest as a dead-man's switch: even if the
    # guard is deleted, this fixture must not touch the network.
    function Set-FixturePathBSentinel {
        param([Parameter(Mandatory)][string]$CliPath)
        $text = [string](Get-Content -LiteralPath $CliPath -Raw)
        $text = $text -replace '(?m)^\$script:ReleaseTag = ''[^'']+''',
            '$script:ReleaseTag = ''RELEASE_TAG'''
        $text = $text -replace 'Invoke-WebRequest[^\r\n]+',
            'throw ''TEST-NETWORK-FORBIDDEN'''
        Set-Content -LiteralPath $CliPath -Value $text -NoNewline
        $verify = [string](Get-Content -LiteralPath $CliPath -Raw)
        if ($verify -notmatch '(?m)^\$script:ReleaseTag = ''RELEASE_TAG''') {
            throw "Fixture rewrite failed to restore the RELEASE_TAG sentinel; refusing to invoke (would hit the network)."
        }
        if ($verify -match '(?m)Invoke-WebRequest') {
            throw "Fixture rewrite failed to neutralize Invoke-WebRequest; refusing to invoke."
        }
    }
}

Describe 'get-learn.ps1 CLI' {
    It 'announces the trust hop, then installs via LocalSource without touching the network' {
        $src = New-PathBSource 'b-local-src'
        $root = New-FixtureInstall 'b-local-root'
        $cli = Join-Path $src 'get-learn.ps1'
        $out = pwsh -NoProfile -File $cli -InstallRoot $root `
            -WorkDir (Join-Path $TestDrive 'b-local-work') `
            -LocalSource $src -Accept
        $LASTEXITCODE | Should -Be 0
        $text = ($out -join "`n")
        $text | Should -Match 'relocates the clone'
        $text | Should -Match 'trust hop'
        $text | Should -Match 'does not remove the clone'
        $text | Should -Match 'INSTALLED'
        Test-Path (Join-Path $root 'learn/manifest.json') | Should -BeTrue
        (Get-PointerStanzaState -Path (Join-Path $root 'GRIMDEX.md')).state | Should -Be 'well-formed'
        [string](Get-Content -LiteralPath (Join-Path $root 'projects/personal/kb.md') -Raw) |
            Should -Match 'student knowledge'
    }

    It 'previews through LocalSource and changes nothing' {
        $src = New-PathBSource 'b-prev-src'
        $root = New-FixtureInstall 'b-prev-root'
        $cli = Join-Path $src 'get-learn.ps1'
        $out = pwsh -NoProfile -File $cli -InstallRoot $root `
            -WorkDir (Join-Path $TestDrive 'b-prev-work') `
            -LocalSource $src -Accept -Preview
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'PREVIEW'
        Test-Path (Join-Path $root 'learn') | Should -BeFalse
    }

    It 'exits 1 and does not fetch when RELEASE_TAG is still the sentinel' {
        $src = New-PathBSource 'b-sent-src'
        $root = New-FixtureInstall 'b-sent-root'
        $cli = Join-Path $src 'get-learn.ps1'
        Set-FixturePathBSentinel -CliPath $cli
        $out = pwsh -NoProfile -File $cli -InstallRoot $root `
            -WorkDir (Join-Path $TestDrive 'b-sent-work') -Accept 2>&1
        $LASTEXITCODE | Should -Be 1
        $text = ($out -join "`n")
        $text | Should -Match 'release tag'
        $text | Should -Not -Match 'Downloading'
        $text | Should -Not -Match 'INSTALLED'
        $text | Should -Not -Match 'TEST-NETWORK-FORBIDDEN'
        Test-Path (Join-Path $root 'learn') | Should -BeFalse
    }

    It 'exits 1 when LocalSource has no bootstrap.ps1' {
        $src = New-PathBSource 'b-noboot-src'
        $root = New-FixtureInstall 'b-noboot-root'
        Remove-Item -LiteralPath (Join-Path $src 'bootstrap.ps1')
        $cli = Join-Path $src 'get-learn.ps1'
        $out = pwsh -NoProfile -File $cli -InstallRoot $root `
            -WorkDir (Join-Path $TestDrive 'b-noboot-work') `
            -LocalSource $src -Accept 2>&1
        $LASTEXITCODE | Should -Be 1
        ($out -join "`n") | Should -Match 'bootstrap.ps1'
        Test-Path (Join-Path $root 'learn') | Should -BeFalse
    }

    It 'passes a missing GRIMDEX.md through as a readable Path A failure' {
        $src = New-PathBSource 'b-nogrim-src'
        $root = New-FixtureInstall 'b-nogrim-root'
        Remove-Item -LiteralPath (Join-Path $root 'GRIMDEX.md')
        $cli = Join-Path $src 'get-learn.ps1'
        $out = pwsh -NoProfile -File $cli -InstallRoot $root `
            -WorkDir (Join-Path $TestDrive 'b-nogrim-work') `
            -LocalSource $src -Accept 2>&1
        $LASTEXITCODE | Should -Be 1
        ($out -join "`n") | Should -Match 'not a Grimdex install'
        Test-Path (Join-Path $root 'learn') | Should -BeFalse
    }

    It 'propagates compose exit 1 on an invalid plan and leaves the install untouched' {
        $src = New-PathBSource 'b-badplan-src'
        $root = New-FixtureInstall 'b-badplan-root'
        # Real compose rejection (New-InstallPlan §7): ownedPaths is learn/,
        # studentRoots is rewritten to learn/** so every source file resolves
        # into a student root. Path B preflight still passes (LocalSource has
        # bootstrap.ps1), so compose is actually invoked through bootstrap.
        $manifestPath = Join-Path $src 'learn/manifest.json'
        $m = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -AsHashtable
        $m['studentRoots'] = @('learn/**')
        $m | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath
        $cli = Join-Path $src 'get-learn.ps1'
        $out = pwsh -NoProfile -File $cli -InstallRoot $root `
            -WorkDir (Join-Path $TestDrive 'b-badplan-work') `
            -LocalSource $src -Accept
        $LASTEXITCODE | Should -Be 1
        ($out -join "`n") | Should -Match 'INVALID PLAN'
        Test-Path (Join-Path $root 'learn') | Should -BeFalse
        [string](Get-Content -LiteralPath (Join-Path $root 'projects/personal/kb.md') -Raw) |
            Should -Match 'student knowledge'
    }
}

Describe 'get-learn.ps1 is a bootstrapper, not a second installer' {
    It 'fetches a zip, delegates to bootstrap.ps1, and never calls Invoke-LearnInstall' {
        $p = Join-Path $script:RepoRoot 'get-learn.ps1'
        $p | Should -Exist
        $text = [string](Get-Content -LiteralPath $p -Raw)
        $text | Should -Match 'https://github.com/Ryfter/grimdex-learn'
        $text | Should -Match 'v0\.1\.0-fall2026-draft'
        $text | Should -Match 'Test-PathBTagReady'
        $text | Should -Match 'archive/refs/tags'
        $text | Should -Match 'Invoke-WebRequest'
        $text | Should -Match 'bootstrap\.ps1'
        $text | Should -Match 'relocates the clone'
        $text | Should -Match 'trust hop'
        $text | Should -Not -Match 'Invoke-LearnInstall'
        $text | Should -Not -Match 'New-InstallPlan'
        $text | Should -Not -Match 'install-learn\.ps1'
    }
}

Describe 'QUICKSTART Path B' {
    It 'documents the one-liner, the review command, and the trust hop' {
        $p = Join-Path $script:RepoRoot 'QUICKSTART.md'
        $text = [string](Get-Content -LiteralPath $p -Raw)
        $text | Should -Match 'irm https://github.com/Ryfter/grimdex-learn/raw/v0\.1\.0-fall2026-draft/get-learn.ps1'
        $text | Should -Not -Match 'filled in when the first release is cut'
        $text | Should -Match 'relocates the clone'
        $text | Should -Match 'trust hop'
        $text | Should -Match 'does not remove the clone'
        $text | Should -Match 'not the taught path'
    }
}
