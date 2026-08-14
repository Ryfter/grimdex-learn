# tests/version-lib.Tests.ps1
BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'scripts' 'manifest-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'version-lib.ps1')

    # Throwaway git repo with one commit; optionally tagged; optionally one
    # commit past the tag.
    function New-GitFixture {
        param([string]$Name, [string]$Tag, [switch]$AheadOfTag)
        $root = Join-Path $TestDrive $Name
        New-Item -ItemType Directory -Path $root | Out-Null
        git -C $root init -q
        git -C $root -c user.email=t@t -c user.name=t commit --allow-empty -q -m 'base'
        if ($Tag) {
            git -C $root tag $Tag
            if ($AheadOfTag) {
                git -C $root -c user.email=t@t -c user.name=t commit --allow-empty -q -m 'later'
            }
        }
        $root
    }
    function New-PinManifest {
        param([string]$Pin)
        [pscustomobject]@{ baseGrimdex = [pscustomobject]@{ pin = $Pin } }
    }
}

Describe 'Get-BaseGrimdexVersion' {
    It 'reports unknown for a non-git directory' {
        $root = Join-Path $TestDrive 'plain'
        New-Item -ItemType Directory -Path $root | Out-Null
        $r = Get-BaseGrimdexVersion -InstallRoot $root
        $r.known | Should -BeFalse
    }
    It 'reports the exact release tag when HEAD is tagged' {
        $root = New-GitFixture 'tagged' -Tag 'v0.8.0'
        $r = Get-BaseGrimdexVersion -InstallRoot $root
        $r.known   | Should -BeTrue
        $r.version | Should -Be 'v0.8.0'
    }
    It 'reports a describe suffix when HEAD is ahead of the tag' {
        $root = New-GitFixture 'ahead' -Tag 'v0.8.0' -AheadOfTag
        $r = Get-BaseGrimdexVersion -InstallRoot $root
        $r.known   | Should -BeTrue
        $r.version | Should -Match '^v0\.8\.0-1-g'
    }
    It 'reports unknown for a git repo with no tags' {
        $root = New-GitFixture 'untagged'
        (Get-BaseGrimdexVersion -InstallRoot $root).known | Should -BeFalse
    }
    It 'reports unknown when git is not on PATH' {
        $root = New-GitFixture 'nopath' -Tag 'v0.8.0'
        $libPath = Join-Path $PSScriptRoot '..' 'scripts' 'version-lib.ps1'
        $out = pwsh -NoProfile -Command "`$env:PATH=''; . '$libPath'; (Get-BaseGrimdexVersion -InstallRoot '$root').known"
        $out | Should -Be 'False'
    }
}

Describe 'Test-LearnVersionMatch' {
    It 'returns unpinned for the installer-plan sentinel without touching git' {
        $root = Join-Path $TestDrive 'sentinel-dir'  # deliberately does not exist
        $r = Test-LearnVersionMatch -InstallRoot $root `
            -Manifest (New-PinManifest 'PINNED-RELEASE-TAG-SET-AT-INSTALL-PLAN')
        $r.status | Should -Be 'unpinned'
        $r.pin    | Should -BeNullOrEmpty
    }
    It 'returns unpinned when baseGrimdex is absent without touching git' {
        $root = Join-Path $TestDrive 'no-pin-dir'  # deliberately does not exist
        $r = Test-LearnVersionMatch -InstallRoot $root -Manifest ([pscustomobject]@{})
        $r.status | Should -Be 'unpinned'
        $r.pin    | Should -BeNullOrEmpty
    }
    It 'returns match when the installed tag equals the pin' {
        $root = New-GitFixture 'm1' -Tag 'v0.8.0'
        $r = Test-LearnVersionMatch -InstallRoot $root -Manifest (New-PinManifest 'v0.8.0')
        $r.status | Should -Be 'match'
        $r.actual | Should -Be 'v0.8.0'
    }
    It 'returns mismatch when the installed tag differs from the pin' {
        $root = New-GitFixture 'm2' -Tag 'v0.9.0'
        $r = Test-LearnVersionMatch -InstallRoot $root -Manifest (New-PinManifest 'v0.8.0')
        $r.status | Should -Be 'mismatch'
        $r.detail | Should -Match 'v0\.9\.0'
    }
    It 'returns mismatch when HEAD moved past the pinned tag' {
        $root = New-GitFixture 'm3' -Tag 'v0.8.0' -AheadOfTag
        (Test-LearnVersionMatch -InstallRoot $root -Manifest (New-PinManifest 'v0.8.0')).status |
            Should -Be 'mismatch'
    }
    It 'returns unknown-base when the base version cannot be determined' {
        $root = Join-Path $TestDrive 'nogit'
        New-Item -ItemType Directory -Path $root | Out-Null
        (Test-LearnVersionMatch -InstallRoot $root -Manifest (New-PinManifest 'v0.8.0')).status |
            Should -Be 'unknown-base'
    }
    It 'treats a case-different pin as a mismatch (git tags are case-sensitive)' {
        $root = New-GitFixture 'case1' -Tag 'v0.8.0'
        (Test-LearnVersionMatch -InstallRoot $root -Manifest (New-PinManifest 'V0.8.0')).status |
            Should -Be 'mismatch'
    }
}
