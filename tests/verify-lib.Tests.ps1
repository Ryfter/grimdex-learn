BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'scripts' 'manifest-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'verify-lib.ps1')

    function New-TestManifest {
        @{
            studentRoots = @('projects/**')
            neverShip    = @('config/fleet.json', 'config/learn-progress.json',
                             'config/quota.json', 'config/settings.json')
        }
    }

    function New-TestInstall {
        param([string]$Root)
        New-Item -ItemType Directory -Path (Join-Path $Root 'projects/personal') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $Root 'projects/personal/notes.md') -Value 'my notes' -Encoding utf8NoBOM
        Set-Content -LiteralPath (Join-Path $Root 'projects/inbox.md') -Value 'review me' -Encoding utf8NoBOM
        New-Item -ItemType Directory -Path (Join-Path $Root 'learn') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $Root 'learn/page.md') -Value 'learn content' -Encoding utf8NoBOM
    }
}

Describe 'New-StudentZoneSnapshot' {
    It 'hashes every file under student roots and nothing else' {
        $root = Join-Path $TestDrive 'install1'
        New-TestInstall -Root $root
        $snap = New-StudentZoneSnapshot -InstallRoot $root -Manifest (New-TestManifest)
        $snap.files.Keys | Sort-Object | Should -Be @('projects/inbox.md', 'projects/personal/notes.md')
        $snap.files['projects/personal/notes.md'] | Should -Match '^[0-9A-F]{64}$'
        $snap.installRoot | Should -Be $root
    }

    It 'skips a student root that does not exist' {
        $root = Join-Path $TestDrive 'install2'
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $snap = New-StudentZoneSnapshot -InstallRoot $root -Manifest (New-TestManifest)
        $snap.files.Count | Should -Be 0
    }
}

Describe 'Test-StudentZoneUntouched' {
    It 'passes when nothing changed' {
        $root = Join-Path $TestDrive 'cmp1'
        New-TestInstall -Root $root
        $m = New-TestManifest
        $before = New-StudentZoneSnapshot -InstallRoot $root -Manifest $m
        $after  = New-StudentZoneSnapshot -InstallRoot $root -Manifest $m
        $result = Test-StudentZoneUntouched -Before $before -After $after
        $result.passed | Should -BeTrue
        $result.modified | Should -HaveCount 0
        $result.missing  | Should -HaveCount 0
        $result.added    | Should -HaveCount 0
    }

    It 'fails and names modified, deleted, and added files' {
        $root = Join-Path $TestDrive 'cmp2'
        New-TestInstall -Root $root
        $m = New-TestManifest
        $before = New-StudentZoneSnapshot -InstallRoot $root -Manifest $m
        Set-Content -LiteralPath (Join-Path $root 'projects/personal/notes.md') -Value 'overwritten!' -Encoding utf8NoBOM
        Remove-Item -LiteralPath (Join-Path $root 'projects/inbox.md') -Force
        Set-Content -LiteralPath (Join-Path $root 'projects/intruder.md') -Value 'sneaky' -Encoding utf8NoBOM
        $after = New-StudentZoneSnapshot -InstallRoot $root -Manifest $m
        $result = Test-StudentZoneUntouched -Before $before -After $after
        $result.passed | Should -BeFalse
        $result.modified | Should -Be @('projects/personal/notes.md')
        $result.missing  | Should -Be @('projects/inbox.md')
        $result.added    | Should -Be @('projects/intruder.md')
    }
}

Describe 'Test-BundleExcludesNeverShip' {
    It 'passes for a bundle with no neverShip files' {
        $bundle = Join-Path $TestDrive 'bundle1'
        New-Item -ItemType Directory -Path (Join-Path $bundle 'learn') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $bundle 'learn/page.md') -Value 'ok' -Encoding utf8NoBOM
        $result = Test-BundleExcludesNeverShip -BundlePath $bundle -Manifest (New-TestManifest)
        $result.passed | Should -BeTrue
        $result.violations | Should -HaveCount 0
    }

    It 'fails and names every leaked neverShip file' {
        $bundle = Join-Path $TestDrive 'bundle2'
        New-Item -ItemType Directory -Path (Join-Path $bundle 'config') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $bundle 'config/fleet.json') -Value '{}' -Encoding utf8NoBOM
        Set-Content -LiteralPath (Join-Path $bundle 'config/quota.json') -Value '{}' -Encoding utf8NoBOM
        $result = Test-BundleExcludesNeverShip -BundlePath $bundle -Manifest (New-TestManifest)
        $result.passed | Should -BeFalse
        $result.violations | Should -Be @('config/fleet.json', 'config/quota.json')
    }
}
