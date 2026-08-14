BeforeAll {
    $script:CheckScript = Join-Path $PSScriptRoot '..' 'scripts' 'version-check.ps1'

    # Minimal valid install: git repo (optionally tagged) + a full valid
    # learn/manifest.json with the requested pin.
    function New-CheckFixture {
        param([string]$Name, [string]$Tag, [string]$Pin)
        $root = Join-Path $TestDrive $Name
        New-Item -ItemType Directory -Path (Join-Path $root 'learn') -Force | Out-Null
        git -C $root init -q
        git -C $root -c user.email=t@t -c user.name=t commit --allow-empty -q -m 'base'
        if ($Tag) { git -C $root tag $Tag }
        $manifest = @{
            schemaVersion = 1; moduleId = 'git-and-github'; title = 't'
            description = 'd'; learnPackVersion = '0.1.0'
            contentAdmissionVersion = 'D29-v1'
            baseGrimdex = @{ pin = $Pin }
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
        $root
    }
}

Describe 'version-check.ps1' {
    It 'exits 0 and reports OK on a match' {
        $root = New-CheckFixture 'ok1' -Tag 'v0.8.0' -Pin 'v0.8.0'
        $out = pwsh -NoProfile -File $CheckScript -InstallRoot $root
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'OK'
    }
    It 'exits 0 with a NOTE on the unpinned sentinel' {
        $root = New-CheckFixture 'np1' -Tag 'v0.8.0' -Pin 'PINNED-RELEASE-TAG-SET-AT-INSTALL-PLAN'
        $out = pwsh -NoProfile -File $CheckScript -InstallRoot $root
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'NOTE'
    }
    It 'exits 0 with a NOTE when baseGrimdex is absent' {
        $root = New-CheckFixture 'np2' -Tag 'v0.8.0' -Pin 'v0.8.0'
        $mPath = Join-Path $root 'learn/manifest.json'
        $json = Get-Content -LiteralPath $mPath -Raw | ConvertFrom-Json
        $json.PSObject.Properties.Remove('baseGrimdex')
        $json | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $mPath
        $out = pwsh -NoProfile -File $CheckScript -InstallRoot $root
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'NOTE'
    }
    It 'exits 1 on a mismatch and prints the three D27 options' {
        $root = New-CheckFixture 'mm1' -Tag 'v0.9.0' -Pin 'v0.8.0'
        $out = pwsh -NoProfile -File $CheckScript -InstallRoot $root
        $LASTEXITCODE | Should -Be 1
        $text = $out -join "`n"
        $text | Should -Match 'WARNING'
        $text | Should -Match 'matching Learn pack'
        $text | Should -Match 'pinned base'
        $text | Should -Match 'deactivate Learn pointers'
        $text | Should -Match 'never silently'
    }
    It 'exits 2 with a warning when the base version is unverifiable' {
        $root = New-CheckFixture 'uk1' -Pin 'v0.8.0'   # git repo but no tag
        $out = pwsh -NoProfile -File $CheckScript -InstallRoot $root
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -Match 'WARNING'
    }
    It 'exits 2 with a clean warning when the manifest is missing' {
        $root = Join-Path $TestDrive 'nomanifest'
        New-Item -ItemType Directory -Path $root | Out-Null
        $out = pwsh -NoProfile -File $CheckScript -InstallRoot $root 2>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -Match 'WARNING'
    }
    It 'exits 0 with a NOTE when baseGrimdex has no pin (unpinned, not malformed)' {
        # Empty baseGrimdex is treated as unpinned (pinning is optional), not as
        # a hard error. A true unreadable-manifest failure is covered elsewhere.
        $root = New-CheckFixture 'badbase' -Tag 'v0.8.0' -Pin 'v0.8.0'
        $mPath = Join-Path $root 'learn/manifest.json'
        $json = Get-Content -LiteralPath $mPath -Raw | ConvertFrom-Json
        $json.baseGrimdex = [pscustomobject]@{}
        $json | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $mPath
        $out = pwsh -NoProfile -File $CheckScript -InstallRoot $root
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'NOTE'
    }
}
