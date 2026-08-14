BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'scripts' 'manifest-lib.ps1')

    function New-ValidManifestJson {
        @'
{
  "schemaVersion": 1,
  "moduleId": "learn-core",
  "baseGrimdex": { "pin": "v0.0.0-test" },
  "ownedPaths": ["learn/"],
  "pointerStanzas": [{ "file": "GRIMDEX.md" }],
  "neverShip": ["config/fleet.json", "config/learn-progress.json", "config/quota.json", "config/settings.json"],
  "studentRoots": ["projects/**"],
  "generatedRoots": ["logs/", ".index/"],
  "lifecycle": { "install": { "student": "never-touch" }, "graduate": { "student": "never-touch" } }
}
'@
    }
}

Describe 'Read-LearnManifest' {
    It 'loads a valid manifest and returns its fields' {
        $path = Join-Path $TestDrive 'manifest.json'
        Set-Content -LiteralPath $path -Value (New-ValidManifestJson) -Encoding utf8NoBOM
        $m = Read-LearnManifest -Path $path
        $m.moduleId | Should -Be 'learn-core'
        $m.baseGrimdex.pin | Should -Be 'v0.0.0-test'
        $m.studentRoots | Should -Contain 'projects/**'
        $m.neverShip | Should -HaveCount 4
    }

    It 'throws when the file does not exist' {
        { Read-LearnManifest -Path (Join-Path $TestDrive 'missing.json') } |
            Should -Throw '*Manifest not found*'
    }

    It 'throws on invalid JSON' {
        $path = Join-Path $TestDrive 'bad.json'
        Set-Content -LiteralPath $path -Value '{ not json' -Encoding utf8NoBOM
        { Read-LearnManifest -Path $path } | Should -Throw '*not valid JSON*'
    }

    It 'throws naming every missing required field' {
        $path = Join-Path $TestDrive 'partial.json'
        Set-Content -LiteralPath $path -Value '{ "schemaVersion": 1, "moduleId": "x" }' -Encoding utf8NoBOM
        { Read-LearnManifest -Path $path } |
            Should -Throw '*missing required fields*ownedPaths*studentRoots*'
    }
}

Describe 'Get-ManifestPin' {
    It 'returns the pin for a hashtable manifest that declares one' {
        $m = @{ baseGrimdex = @{ pin = 'v0.8.0' } }
        Get-ManifestPin -Manifest $m | Should -Be 'v0.8.0'
    }
    It 'returns the pin for a pscustomobject manifest that declares one' {
        $m = [pscustomobject]@{ baseGrimdex = [pscustomobject]@{ pin = 'v0.8.0' } }
        Get-ManifestPin -Manifest $m | Should -Be 'v0.8.0'
    }
    It 'returns null when baseGrimdex is absent entirely' {
        Get-ManifestPin -Manifest (@{ moduleId = 'x' }) | Should -BeNullOrEmpty
    }
    It 'returns null when baseGrimdex is present but has no pin key' {
        Get-ManifestPin -Manifest (@{ baseGrimdex = @{ } }) | Should -BeNullOrEmpty
    }
    It 'returns null for the PINNED-RELEASE-TAG-SET-AT-INSTALL-PLAN placeholder' {
        $m = @{ baseGrimdex = @{ pin = 'PINNED-RELEASE-TAG-SET-AT-INSTALL-PLAN' } }
        Get-ManifestPin -Manifest $m | Should -BeNullOrEmpty
    }
    It 'returns null for an empty or whitespace-only pin' {
        Get-ManifestPin -Manifest (@{ baseGrimdex = @{ pin = '' } }) | Should -BeNullOrEmpty
        Get-ManifestPin -Manifest (@{ baseGrimdex = @{ pin = '   ' } }) | Should -BeNullOrEmpty
    }
    It 'trims surrounding whitespace from a real pin' {
        $m = @{ baseGrimdex = @{ pin = '  v0.8.0  ' } }
        Get-ManifestPin -Manifest $m | Should -Be 'v0.8.0'
    }
    It 'reads a manifest JSON file with no baseGrimdex key successfully' {
        $path = Join-Path $TestDrive 'no-pin.json'
        $json = (New-ValidManifestJson) -replace ',\s*"baseGrimdex": \{ "pin": "v0\.0\.0-test" \}', ''
        Set-Content -LiteralPath $path -Value $json -Encoding utf8NoBOM
        $m = Read-LearnManifest -Path $path
        $m.moduleId | Should -Be 'learn-core'
        Get-ManifestPin -Manifest $m | Should -BeNullOrEmpty
    }
}

Describe 'Read-LearnManifest D28 pure-data enforcement' {
    It 'rejects a top-level executable key' {
        $path = Join-Path $TestDrive 'hooked.json'
        $json = (New-ValidManifestJson) -replace '"lifecycle":', '"hooks": ["setup.ps1"], "lifecycle":'
        Set-Content -LiteralPath $path -Value $json -Encoding utf8NoBOM
        { Read-LearnManifest -Path $path } |
            Should -Throw "*forbidden by D28*manifest.hooks*"
    }

    It 'rejects a nested executable key with its full trail' {
        $path = Join-Path $TestDrive 'nested.json'
        $json = (New-ValidManifestJson) -replace '\{ "file": "GRIMDEX.md" \}', '{ "file": "GRIMDEX.md", "onInstall": "x" }'
        Set-Content -LiteralPath $path -Value $json -Encoding utf8NoBOM
        { Read-LearnManifest -Path $path } |
            Should -Throw '*forbidden by D28*manifest.pointerStanzas`[0`].onInstall*'
    }

    It 'accepts the valid manifest unchanged' {
        $path = Join-Path $TestDrive 'clean.json'
        Set-Content -LiteralPath $path -Value (New-ValidManifestJson) -Encoding utf8NoBOM
        { Read-LearnManifest -Path $path } | Should -Not -Throw
    }
}

Describe 'Read-LearnManifest studentRoots validation (F1)' {
    It 'throws when studentRoots is an empty array' {
        $path = Join-Path $TestDrive 'empty-roots.json'
        $json = (New-ValidManifestJson) -replace '"studentRoots": \["projects/\*\*"\]', '"studentRoots": []'
        Set-Content -LiteralPath $path -Value $json -Encoding utf8NoBOM
        { Read-LearnManifest -Path $path } |
            Should -Throw '*Manifest studentRoots must be a non-empty array of path patterns*'
    }

    It 'throws when studentRoots is null' {
        $path = Join-Path $TestDrive 'null-roots.json'
        $json = (New-ValidManifestJson) -replace '"studentRoots": \["projects/\*\*"\]', '"studentRoots": null'
        Set-Content -LiteralPath $path -Value $json -Encoding utf8NoBOM
        { Read-LearnManifest -Path $path } |
            Should -Throw '*Manifest studentRoots must be a non-empty array of path patterns*'
    }

    It 'throws when studentRoots contains a non-string entry' {
        $path = Join-Path $TestDrive 'bad-entry-roots.json'
        $json = (New-ValidManifestJson) -replace '"studentRoots": \["projects/\*\*"\]', '"studentRoots": [123]'
        Set-Content -LiteralPath $path -Value $json -Encoding utf8NoBOM
        { Read-LearnManifest -Path $path } |
            Should -Throw '*Manifest studentRoots must be a non-empty array of path patterns*'
    }

    It 'throws when studentRoots contains an empty string entry' {
        $path = Join-Path $TestDrive 'blank-entry-roots.json'
        $json = (New-ValidManifestJson) -replace '"studentRoots": \["projects/\*\*"\]', '"studentRoots": [""]'
        Set-Content -LiteralPath $path -Value $json -Encoding utf8NoBOM
        { Read-LearnManifest -Path $path } |
            Should -Throw '*Manifest studentRoots must be a non-empty array of path patterns*'
    }
}
