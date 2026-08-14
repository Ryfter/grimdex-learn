BeforeAll {
    $script:CliPath = Join-Path $PSScriptRoot '..' 'scripts' 'verify-student-zone.ps1'

    function New-CliFixture {
        param([string]$Root)
        New-Item -ItemType Directory -Path (Join-Path $Root 'projects/personal') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $Root 'projects/personal/notes.md') -Value 'my notes' -Encoding utf8NoBOM
        $manifestPath = Join-Path $Root 'manifest.json'
        Set-Content -LiteralPath $manifestPath -Encoding utf8NoBOM -Value @'
{
  "schemaVersion": 1,
  "moduleId": "learn-core",
  "baseGrimdex": { "pin": "v0.0.0-test" },
  "ownedPaths": ["learn/"],
  "pointerStanzas": [{ "file": "GRIMDEX.md" }],
  "neverShip": ["config/fleet.json", "config/learn-progress.json", "config/quota.json", "config/settings.json"],
  "studentRoots": ["projects/**"],
  "generatedRoots": ["logs/"],
  "lifecycle": { "install": { "student": "never-touch" } }
}
'@
        return $manifestPath
    }

    function New-CliFixtureNoStudentDir {
        param([string]$Root)
        New-Item -ItemType Directory -Path $Root -Force | Out-Null
        $manifestPath = Join-Path $Root 'manifest.json'
        Set-Content -LiteralPath $manifestPath -Encoding utf8NoBOM -Value @'
{
  "schemaVersion": 1,
  "moduleId": "learn-core",
  "baseGrimdex": { "pin": "v0.0.0-test" },
  "ownedPaths": ["learn/"],
  "pointerStanzas": [{ "file": "GRIMDEX.md" }],
  "neverShip": ["config/fleet.json", "config/learn-progress.json", "config/quota.json", "config/settings.json"],
  "studentRoots": ["projects/**"],
  "generatedRoots": ["logs/"],
  "lifecycle": { "install": { "student": "never-touch" } }
}
'@
        return $manifestPath
    }
}

Describe 'verify-student-zone.ps1' {
    It 'round-trips: snapshot then verify passes with exit 0' {
        $root = Join-Path $TestDrive 'cli1'
        $manifestPath = New-CliFixture -Root $root
        $snapPath = Join-Path $TestDrive 'snap1.json'
        pwsh -NoProfile -File $script:CliPath -Mode Snapshot -InstallRoot $root -ManifestPath $manifestPath -SnapshotPath $snapPath
        $LASTEXITCODE | Should -Be 0
        Test-Path -LiteralPath $snapPath | Should -BeTrue
        $out = pwsh -NoProfile -File $script:CliPath -Mode Verify -InstallRoot $root -ManifestPath $manifestPath -SnapshotPath $snapPath
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'STUDENT ZONE OK'
    }

    It 'exits 1 and names the violation when a student file changes' {
        $root = Join-Path $TestDrive 'cli2'
        $manifestPath = New-CliFixture -Root $root
        $snapPath = Join-Path $TestDrive 'snap2.json'
        pwsh -NoProfile -File $script:CliPath -Mode Snapshot -InstallRoot $root -ManifestPath $manifestPath -SnapshotPath $snapPath
        Set-Content -LiteralPath (Join-Path $root 'projects/personal/notes.md') -Value 'tampered' -Encoding utf8NoBOM
        $out = pwsh -NoProfile -File $script:CliPath -Mode Verify -InstallRoot $root -ManifestPath $manifestPath -SnapshotPath $snapPath
        $LASTEXITCODE | Should -Be 1
        ($out -join "`n") | Should -Match 'STUDENT ZONE VIOLATION'
        ($out -join "`n") | Should -Match 'modified: projects/personal/notes\.md'
    }

    It 'warns and still exits 0 when Snapshot resolves to 0 files (F1)' {
        $root = Join-Path $TestDrive 'cli3'
        $manifestPath = New-CliFixtureNoStudentDir -Root $root
        $snapPath = Join-Path $TestDrive 'snap3.json'
        $out = pwsh -NoProfile -File $script:CliPath -Mode Snapshot -InstallRoot $root -ManifestPath $manifestPath -SnapshotPath $snapPath
        $LASTEXITCODE | Should -Be 0
        Test-Path -LiteralPath $snapPath | Should -BeTrue
        ($out -join "`n") | Should -Match 'WARNING: student-zone snapshot scope resolved to 0 files'
    }
}
