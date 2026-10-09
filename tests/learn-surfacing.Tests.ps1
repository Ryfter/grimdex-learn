BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'scripts' 'manifest-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'stanza-lib.ps1')
    $script:Cli = Join-Path $PSScriptRoot '..' 'scripts' 'learn-surfacing.ps1'
    # An installed Learn pack: manifest, index, and GRIMDEX.md with a stanza.
    function New-FixtureInstall {
        param([string]$Name)
        $root = Join-Path $TestDrive $Name
        New-Item -ItemType Directory -Path (Join-Path $root 'learn') -Force | Out-Null
        @{
            schemaVersion = 1; moduleId = 'm'; title = 't'; learnPackVersion = '0.1.0'
            contentAdmissionVersion = 'D29-v1'; ownedPaths = @('learn/'); pagesPath = 'learn/'
            pointerStanzas = @(@{ file = 'GRIMDEX.md' })
            neverShip = @('learn-progress/surfacing.json'); studentRoots = @('projects/**', 'learn-progress/**')
            generatedRoots = @('logs/')
            lifecycle = @{ install = @{ student = 'never-touch' }; update = @{ student = 'never-touch' }
                           graduate = @{ student = 'never-touch' }; remove = @{ student = 'never-touch' } }
        } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $root 'learn/manifest.json')
        @{ schemaVersion = 1; lessons = @(
            @{ id = 'a1'; module = 'm'; title = 'A1'; level = 1; capabilities = @('a1'); path = 'learn/m/capabilities/a1.md' }
            @{ id = 'b1'; module = 'm'; title = 'B1'; level = 2; capabilities = @('b1'); path = 'learn/m/capabilities/b1.md' }
        ) } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $root 'learn/index.json')
        Set-Content -LiteralPath (Join-Path $root 'GRIMDEX.md') -NoNewline `
            -Value "# Grimdex`n`n<!-- grimdex-learn:start -->`nold`n<!-- grimdex-learn:end -->`n"
        $root
    }
    function New-Transcript {
        param([string]$Path, [string[]]$Lessons)
        $lines = foreach ($l in $Lessons) {
            @{ type = 'assistant'; message = @{ role = 'assistant'; content = @(@{ type = 'text'; text = "Explained.`nLearn: $l" }) } } |
                ConvertTo-Json -Depth 6 -Compress
        }
        [IO.File]::WriteAllText($Path, (@($lines) -join "`n") + "`n")
        $Path
    }
}

Describe 'learn-surfacing.ps1' {
    It 'records transcripts, writes the ledger, and re-renders the stanza with the level' {
        $root = New-FixtureInstall 'c1'
        $dir = Join-Path $TestDrive 'c1-transcripts'; New-Item -ItemType Directory -Path $dir | Out-Null
        foreach ($i in 1..10) { New-Transcript (Join-Path $dir "s$i.jsonl") @('m/a1') | Out-Null }
        & pwsh -NoProfile -File $script:Cli -InstallRoot $root -TranscriptPath $dir | Out-Null
        $LASTEXITCODE | Should -Be 0
        $ledger = Get-Content -LiteralPath (Join-Path $root 'learn-progress/surfacing.json') -Raw | ConvertFrom-Json -AsHashtable
        $ledger.counts['m/a1'] | Should -Be 10
        $ledger.level | Should -Be 2
        $body = Get-PointerStanzaBody -Path (Join-Path $root 'GRIMDEX.md')
        $body | Should -Match 'Learner level: 2 of 7 \(Conversational Collaborator\)'
        $body | Should -Match 'Learn: <module-id>/<lesson-id>'
    }
    It 'is idempotent: a second run over the same transcripts changes nothing' {
        $root = New-FixtureInstall 'c2'
        $t = New-Transcript (Join-Path $TestDrive 'c2.jsonl') @('m/a1', 'm/b1')
        & pwsh -NoProfile -File $script:Cli -InstallRoot $root -TranscriptPath $t | Out-Null
        $first = [IO.File]::ReadAllText((Join-Path $root 'learn-progress/surfacing.json'))
        $grimdex = [IO.File]::ReadAllText((Join-Path $root 'GRIMDEX.md'))
        & pwsh -NoProfile -File $script:Cli -InstallRoot $root -TranscriptPath $t | Out-Null
        [IO.File]::ReadAllText((Join-Path $root 'learn-progress/surfacing.json')) | Should -BeExactly $first
        [IO.File]::ReadAllText((Join-Path $root 'GRIMDEX.md')) | Should -BeExactly $grimdex
    }
    It 'suppresses and unsuppresses a lesson and shows it in the stanza' {
        $root = New-FixtureInstall 'c3'
        & pwsh -NoProfile -File $script:Cli -InstallRoot $root -Suppress 'm/b1' | Out-Null
        $LASTEXITCODE | Should -Be 0
        Get-PointerStanzaBody -Path (Join-Path $root 'GRIMDEX.md') | Should -Match 'never surface these\): m/b1'
        & pwsh -NoProfile -File $script:Cli -InstallRoot $root -Unsuppress 'm/b1' | Out-Null
        Get-PointerStanzaBody -Path (Join-Path $root 'GRIMDEX.md') | Should -Not -Match 'Suppressed'
    }
    It 'rejects an unknown lesson with exit 1 and writes nothing' {
        $root = New-FixtureInstall 'c4'
        $before = [IO.File]::ReadAllText((Join-Path $root 'GRIMDEX.md'))
        & pwsh -NoProfile -File $script:Cli -InstallRoot $root -Suppress 'm/nope' | Out-Null
        $LASTEXITCODE | Should -Be 1
        Test-Path (Join-Path $root 'learn-progress') | Should -BeFalse
        [IO.File]::ReadAllText((Join-Path $root 'GRIMDEX.md')) | Should -BeExactly $before
    }
    It 'rejects a missing transcript path with exit 1 and writes nothing' {
        $root = New-FixtureInstall 'c5'
        & pwsh -NoProfile -File $script:Cli -InstallRoot $root -TranscriptPath (Join-Path $TestDrive 'nope.jsonl') | Out-Null
        $LASTEXITCODE | Should -Be 1
        Test-Path (Join-Path $root 'learn-progress') | Should -BeFalse
    }
    It 'exits 2 when the install has no lesson index' {
        $root = New-FixtureInstall 'c6'
        Remove-Item -LiteralPath (Join-Path $root 'learn/index.json')
        & pwsh -NoProfile -File $script:Cli -InstallRoot $root | Out-Null
        $LASTEXITCODE | Should -Be 2
    }
    It 'splits a comma-joined -TranscriptPath value into separate files (external pwsh -File invocation)' {
        $root = New-FixtureInstall 'c8'
        $t1 = New-Transcript (Join-Path $TestDrive 'c8-one.jsonl') @('m/a1')
        $t2 = New-Transcript (Join-Path $TestDrive 'c8-two.jsonl') @('m/b1')
        $joined = "$t1,$t2"
        $out = & pwsh -NoProfile -File $script:Cli -InstallRoot $root -TranscriptPath $joined
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match ([regex]::Escape([IO.Path]::GetFileName($t1)))
        ($out -join "`n") | Should -Match ([regex]::Escape([IO.Path]::GetFileName($t2)))
        $ledger = Get-Content -LiteralPath (Join-Path $root 'learn-progress/surfacing.json') -Raw | ConvertFrom-Json -AsHashtable
        $ledger.counts['m/a1'] | Should -Be 1
        $ledger.counts['m/b1'] | Should -Be 1
    }
    It 'warns when a transcript directory has no transcript files' {
        $root = New-FixtureInstall 'c9'
        $dir = Join-Path $TestDrive 'c9-empty'; New-Item -ItemType Directory -Path $dir | Out-Null
        $out = & pwsh -NoProfile -File $script:Cli -InstallRoot $root -TranscriptPath $dir
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'WARNING:.*no transcript files'
        ($out -join "`n") | Should -Match '~/.claude/projects/'
    }
    It 'warns when a jsonl transcript has no assistant text events' {
        $root = New-FixtureInstall 'c10'
        $p = Join-Path $TestDrive 'c10.jsonl'
        [IO.File]::WriteAllText($p, (@{ type = 'user'; message = @{ role = 'user'; content = 'hi' } } | ConvertTo-Json -Compress) + "`n")
        $out = & pwsh -NoProfile -File $script:Cli -InstallRoot $root -TranscriptPath $p
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'WARNING:.*assistant text events'
    }
    It 'reports unrecognised Learn: lines in the per-transcript output line' {
        $root = New-FixtureInstall 'c11'
        $p = New-Transcript (Join-Path $TestDrive 'c11.jsonl') @('not-a-valid-id', 'm/a1')
        $out = & pwsh -NoProfile -File $script:Cli -InstallRoot $root -TranscriptPath $p
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match '1 Learn: line\(s\) not recognised'
    }
    It 'touches nothing outside learn-progress/ and the stanza block' {
        $root = New-FixtureInstall 'c7'
        $manifestBefore = [IO.File]::ReadAllText((Join-Path $root 'learn/manifest.json'))
        $t = New-Transcript (Join-Path $TestDrive 'c7.jsonl') @('m/a1')
        & pwsh -NoProfile -File $script:Cli -InstallRoot $root -TranscriptPath $t | Out-Null
        [IO.File]::ReadAllText((Join-Path $root 'learn/manifest.json')) | Should -BeExactly $manifestBefore
        $files = @(Get-ChildItem -LiteralPath $root -Recurse -File | ForEach-Object {
            [IO.Path]::GetRelativePath($root, $_.FullName) -replace '\\', '/' } | Sort-Object)
        # Both sides through the same Sort-Object: culture ordering of '-' vs '/' varies.
        $files | Should -Be @(@('GRIMDEX.md', 'learn-progress/surfacing.json', 'learn/index.json', 'learn/manifest.json') | Sort-Object)
        [IO.File]::ReadAllText((Join-Path $root 'GRIMDEX.md')).StartsWith("# Grimdex`n`n") | Should -BeTrue
    }
}
