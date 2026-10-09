BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'scripts' 'learn-index-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'surfacing-lib.ps1')
    # Two lessons at level 1, one at level 2, one at level 3.
    function New-FixtureIndex {
        @{ schemaVersion = 1; lessons = @(
            @{ id = 'a1'; module = 'm'; title = 'A1'; level = 1; capabilities = @('a1'); path = 'learn/m/capabilities/a1.md' }
            @{ id = 'a2'; module = 'm'; title = 'A2'; level = 1; capabilities = @('a2'); path = 'learn/m/capabilities/a2.md' }
            @{ id = 'b1'; module = 'm'; title = 'B1'; level = 2; capabilities = @('b1'); path = 'learn/m/capabilities/b1.md' }
            @{ id = 'c1'; module = 'n'; title = 'C1'; level = 3; capabilities = @('c1'); path = 'learn/n/capabilities/c1.md' }
        ) }
    }
    function New-ClaudeJsonl {
        param([string]$Path, [string[]]$AssistantTexts, [switch]$TruncatedTail, [string]$SidechainText)
        $lines = [System.Collections.Generic.List[string]]::new()
        $lines.Add((@{ type = 'user'; sessionId = 's1'; message = @{ role = 'user'; content = 'Learn: m/a2 (typed by the user, must not count)' } } | ConvertTo-Json -Depth 6 -Compress))
        foreach ($t in $AssistantTexts) {
            $lines.Add((@{ type = 'assistant'; isSidechain = $false; message = @{ role = 'assistant'; content = @(
                @{ type = 'thinking'; thinking = 'Learn: m/b1 (thinking, must not count)' }
                @{ type = 'text'; text = $t }) } } | ConvertTo-Json -Depth 6 -Compress))
        }
        if ($SidechainText) {
            $lines.Add((@{ type = 'assistant'; isSidechain = $true; message = @{ role = 'assistant'; content = @(
                @{ type = 'text'; text = $SidechainText }) } } | ConvertTo-Json -Depth 6 -Compress))
        }
        if ($TruncatedTail) { $lines.Add('{"type":"assistant","message":{"content":[{"type":"text","text":"Learn: m/a1') }
        [IO.File]::WriteAllText($Path, ($lines -join "`n") + "`n")
        $Path
    }
}

Describe 'Get-TranscriptLessonMarkers' {
    It 'counts only assistant text blocks: not user text, thinking, or sidechains' {
        $p = New-ClaudeJsonl (Join-Path $TestDrive 't1.jsonl') @("Here is how commits work.`n`nLearn: m/a1") -SidechainText "Learn: n/c1"
        Get-TranscriptLessonMarkers -Path $p | Should -Be @('m/a1')
    }
    It 'accepts markdown-wrapped markers and returns each lesson once, in first-seen order' {
        $p = New-ClaudeJsonl (Join-Path $TestDrive 't2.jsonl') @("x`n*Learn: m/b1*", "y`n> Learn: m/a1", "z`nLearn: m/b1")
        Get-TranscriptLessonMarkers -Path $p | Should -Be @('m/b1', 'm/a1')
    }
    It 'ignores a marker that is not on its own line' {
        $p = New-ClaudeJsonl (Join-Path $TestDrive 't3.jsonl') @('See Learn: m/a1 for more.')
        @(Get-TranscriptLessonMarkers -Path $p).Count | Should -Be 0
    }
    It 'skips a truncated trailing JSONL line instead of throwing' {
        $p = New-ClaudeJsonl (Join-Path $TestDrive 't4.jsonl') @("ok`nLearn: m/a2") -TruncatedTail
        Get-TranscriptLessonMarkers -Path $p | Should -Be @('m/a2')
    }
    It 'reads a non-JSONL transcript as plain text' {
        $p = Join-Path $TestDrive 'session.md'
        Set-Content -LiteralPath $p -Value "Assistant: explained branches.`nLearn: m/b1`n"
        Get-TranscriptLessonMarkers -Path $p | Should -Be @('m/b1')
    }
    It 'accepts "Learn: m/id." with a single trailing period' {
        $p = New-ClaudeJsonl (Join-Path $TestDrive 't-period.jsonl') @('Learn: m/a1.')
        Get-TranscriptLessonMarkers -Path $p | Should -Be @('m/a1')
    }
    It 'accepts a single trailing comma' {
        $p = New-ClaudeJsonl (Join-Path $TestDrive 't-comma.jsonl') @('Learn: m/a1,')
        Get-TranscriptLessonMarkers -Path $p | Should -Be @('m/a1')
    }
    It 'accepts a single trailing semicolon' {
        $p = New-ClaudeJsonl (Join-Path $TestDrive 't-semi.jsonl') @('Learn: m/a1;')
        Get-TranscriptLessonMarkers -Path $p | Should -Be @('m/a1')
    }
    It 'accepts a single trailing close-paren' {
        $p = New-ClaudeJsonl (Join-Path $TestDrive 't-paren.jsonl') @('Learn: m/a1)')
        Get-TranscriptLessonMarkers -Path $p | Should -Be @('m/a1')
    }
    It 'accepts a bold-wrapped "Learn:" label' {
        $p = New-ClaudeJsonl (Join-Path $TestDrive 't-bold.jsonl') @('**Learn:** m/a1')
        Get-TranscriptLessonMarkers -Path $p | Should -Be @('m/a1')
    }
    It 'accepts an underline-wrapped "Learn:" label' {
        $p = New-ClaudeJsonl (Join-Path $TestDrive 't-underline.jsonl') @('__Learn:__ m/a1')
        Get-TranscriptLessonMarkers -Path $p | Should -Be @('m/a1')
    }
    It 'accepts a backticked lesson id' {
        $p = New-ClaudeJsonl (Join-Path $TestDrive 't-backtick-id.jsonl') @('Learn: `m/a1`')
        Get-TranscriptLessonMarkers -Path $p | Should -Be @('m/a1')
    }
    It 'accepts a whole marker line wrapped in backticks' {
        $p = New-ClaudeJsonl (Join-Path $TestDrive 't-backtick-line.jsonl') @('`Learn: m/a1`')
        Get-TranscriptLessonMarkers -Path $p | Should -Be @('m/a1')
    }
    It 'accepts a hyphen list-bullet marker' {
        $p = New-ClaudeJsonl (Join-Path $TestDrive 't-bullet-hyphen.jsonl') @('- Learn: m/a1')
        Get-TranscriptLessonMarkers -Path $p | Should -Be @('m/a1')
    }
    It 'accepts an asterisk list-bullet marker' {
        $p = New-ClaudeJsonl (Join-Path $TestDrive 't-bullet-star.jsonl') @('* Learn: m/a1')
        Get-TranscriptLessonMarkers -Path $p | Should -Be @('m/a1')
    }
    It 'accepts a plus list-bullet marker' {
        $p = New-ClaudeJsonl (Join-Path $TestDrive 't-bullet-plus.jsonl') @('+ Learn: m/a1')
        Get-TranscriptLessonMarkers -Path $p | Should -Be @('m/a1')
    }
    It 'counts every lesson in a comma-separated list on one line' {
        $p = New-ClaudeJsonl (Join-Path $TestDrive 't-multi.jsonl') @('Learn: a/b, c/d')
        Get-TranscriptLessonMarkers -Path $p | Should -Be @('a/b', 'c/d')
    }
    It 'accepts a markdown link with the lesson id as the link text' {
        $p = New-ClaudeJsonl (Join-Path $TestDrive 't-link.jsonl') @('Learn: [m/a1](learn/m/capabilities/a1.md)')
        Get-TranscriptLessonMarkers -Path $p | Should -Be @('m/a1')
    }
}

Describe 'Add-TranscriptExposures' {
    It 'counts one exposure per lesson per transcript and reports unknown markers' {
        $ledger = New-EmptySurfacingLedger
        $p = New-ClaudeJsonl (Join-Path $TestDrive 'e1.jsonl') @("Learn: m/a1", "Learn: m/a1", "Learn: zz/nope")
        $r = Add-TranscriptExposures -Ledger $ledger -Index (New-FixtureIndex) -TranscriptPath $p
        $r.added | Should -Be @('m/a1')
        $r.unknown | Should -Be @('zz/nope')
        $ledger.counts['m/a1'] | Should -Be 1
    }
    It 'is idempotent for a re-run, but counts a lesson newly cited in a grown transcript' {
        $ledger = New-EmptySurfacingLedger
        $p = Join-Path $TestDrive 'e2.jsonl'
        New-ClaudeJsonl $p @("Learn: m/a1") | Out-Null
        Add-TranscriptExposures -Ledger $ledger -Index (New-FixtureIndex) -TranscriptPath $p | Out-Null
        Add-TranscriptExposures -Ledger $ledger -Index (New-FixtureIndex) -TranscriptPath $p | Out-Null
        $ledger.counts['m/a1'] | Should -Be 1
        New-ClaudeJsonl $p @("Learn: m/a1", "Learn: m/a2") | Out-Null
        $r = Add-TranscriptExposures -Ledger $ledger -Index (New-FixtureIndex) -TranscriptPath $p
        $r.added | Should -Be @('m/a2')
        $ledger.counts['m/a1'] | Should -Be 1
        $ledger.counts['m/a2'] | Should -Be 1
    }
    It 'counts the same lesson again in a different transcript' {
        $ledger = New-EmptySurfacingLedger
        foreach ($n in 'f1', 'f2') {
            $p = New-ClaudeJsonl (Join-Path $TestDrive "$n.jsonl") @("Learn: m/a1")
            Add-TranscriptExposures -Ledger $ledger -Index (New-FixtureIndex) -TranscriptPath $p | Out-Null
        }
        $ledger.counts['m/a1'] | Should -Be 2
    }
    It 'reports unrecognized when a Learn: line has no valid id' {
        $ledger = New-EmptySurfacingLedger
        $p = New-ClaudeJsonl (Join-Path $TestDrive 'unrec1.jsonl') @('Learn: not-a-valid-id', 'Learn: m/a1')
        $r = Add-TranscriptExposures -Ledger $ledger -Index (New-FixtureIndex) -TranscriptPath $p
        $r.unrecognized | Should -Be 1
        $r.added | Should -Be @('m/a1')
    }
    It 'reports zero unrecognized when every Learn: line parses' {
        $ledger = New-EmptySurfacingLedger
        $p = New-ClaudeJsonl (Join-Path $TestDrive 'unrec2.jsonl') @('Learn: m/a1')
        $r = Add-TranscriptExposures -Ledger $ledger -Index (New-FixtureIndex) -TranscriptPath $p
        $r.unrecognized | Should -Be 0
    }
    It 'reports the count of assistant text events for a jsonl transcript' {
        $ledger = New-EmptySurfacingLedger
        $p = New-ClaudeJsonl (Join-Path $TestDrive 'events1.jsonl') @('no marker here', 'Learn: m/a1')
        $r = Add-TranscriptExposures -Ledger $ledger -Index (New-FixtureIndex) -TranscriptPath $p
        $r.assistantEvents | Should -Be 2
    }
    It 'reports zero assistant events for a jsonl transcript with no assistant text' {
        $ledger = New-EmptySurfacingLedger
        $p = Join-Path $TestDrive 'events2.jsonl'
        [IO.File]::WriteAllText($p, (@{ type = 'user'; message = @{ role = 'user'; content = 'hi' } } | ConvertTo-Json -Compress) + "`n")
        $r = Add-TranscriptExposures -Ledger $ledger -Index (New-FixtureIndex) -TranscriptPath $p
        $r.assistantEvents | Should -Be 0
    }
    It 'reports null assistant events for a non-jsonl transcript' {
        $ledger = New-EmptySurfacingLedger
        $p = Join-Path $TestDrive 'events3.md'
        Set-Content -LiteralPath $p -Value "Learn: m/a1`n"
        $r = Add-TranscriptExposures -Ledger $ledger -Index (New-FixtureIndex) -TranscriptPath $p
        $r.assistantEvents | Should -Be $null
    }
}

Describe 'Update-MasteryLevel' {
    It 'promotes when every current-level lesson reaches the threshold, and can climb several levels' {
        $ledger = New-EmptySurfacingLedger
        $ledger.counts = @{ 'm/a1' = 10; 'm/a2' = 10; 'm/b1' = 10 }
        Update-MasteryLevel -Ledger $ledger -Index (New-FixtureIndex) | Should -Be 3
        $ledger.level | Should -Be 3
    }
    It 'does not promote while one current-level lesson is under the threshold' {
        $ledger = New-EmptySurfacingLedger
        $ledger.counts = @{ 'm/a1' = 10; 'm/a2' = 9 }
        Update-MasteryLevel -Ledger $ledger -Index (New-FixtureIndex) | Should -Be 1
    }
    It 'honours a custom threshold' {
        $ledger = New-EmptySurfacingLedger
        $ledger.counts = @{ 'm/a1' = 2; 'm/a2' = 2 }
        Update-MasteryLevel -Ledger $ledger -Index (New-FixtureIndex) -Threshold 2 | Should -Be 2
    }
    It 'does not let a suppressed lesson block promotion' {
        $ledger = New-EmptySurfacingLedger
        $ledger.counts = @{ 'm/a1' = 10 }
        $ledger.suppressed = @('m/a2')
        Update-MasteryLevel -Ledger $ledger -Index (New-FixtureIndex) | Should -Be 2
    }
    It 'never lowers a level already reached' {
        $ledger = New-EmptySurfacingLedger
        $ledger.level = 3
        Update-MasteryLevel -Ledger $ledger -Index (New-FixtureIndex) | Should -Be 3
    }
    It 'stops at level 7' {
        $ledger = New-EmptySurfacingLedger
        $ledger.level = 7
        Update-MasteryLevel -Ledger $ledger -Index (New-FixtureIndex) | Should -Be 7
    }
}

Describe 'Get-LevelWeights' {
    It 'halves per level below the current one with a 5% floor' {
        $w = Get-LevelWeights -Level 7
        @($w | ForEach-Object { $_.level })   | Should -Be @(7, 6, 5, 4, 3, 2, 1)
        @($w | ForEach-Object { $_.percent }) | Should -Be @(100, 50, 25, 12, 6, 5, 5)
    }
    It 'is just the current level at level 1' {
        $w = @(Get-LevelWeights -Level 1)
        $w.Count | Should -Be 1
        $w[0].percent | Should -Be 100
    }
}

Describe 'Set-LessonSuppression' {
    It 'adds and removes a lesson, keeping the list sorted and unique' {
        $ledger = New-EmptySurfacingLedger
        Set-LessonSuppression -Ledger $ledger -Index (New-FixtureIndex) -Lesson 'n/c1' -Suppressed $true
        Set-LessonSuppression -Ledger $ledger -Index (New-FixtureIndex) -Lesson 'm/a1' -Suppressed $true
        Set-LessonSuppression -Ledger $ledger -Index (New-FixtureIndex) -Lesson 'm/a1' -Suppressed $true
        $ledger.suppressed | Should -Be @('m/a1', 'n/c1')
        Set-LessonSuppression -Ledger $ledger -Index (New-FixtureIndex) -Lesson 'm/a1' -Suppressed $false
        $ledger.suppressed | Should -Be @('n/c1')
    }
    It 'rejects a lesson that is not in the index' {
        $ledger = New-EmptySurfacingLedger
        { Set-LessonSuppression -Ledger $ledger -Index (New-FixtureIndex) -Lesson 'm/nope' -Suppressed $true } |
            Should -Throw '*m/nope*'
    }
}

Describe 'Ledger persistence' {
    It 'returns an empty ledger when none exists yet' {
        $root = Join-Path $TestDrive 'p0'; New-Item -ItemType Directory -Path $root | Out-Null
        (Read-SurfacingLedger -InstallRoot $root).level | Should -Be 1
    }
    It 'round-trips through learn-progress/surfacing.json as LF-only, deterministic JSON' {
        $root = Join-Path $TestDrive 'p1'; New-Item -ItemType Directory -Path $root | Out-Null
        $ledger = New-EmptySurfacingLedger
        $ledger.level = 2
        $ledger.counts = @{ 'm/b1' = 3; 'm/a1' = 12 }
        $ledger.transcripts = @{ 'x.jsonl' = @('m/a1') }
        $ledger.suppressed = @('n/c1')
        Save-SurfacingLedger -InstallRoot $root -Ledger $ledger
        $path = Join-Path $root 'learn-progress' 'surfacing.json'
        $first = [IO.File]::ReadAllText($path)
        $first | Should -Not -Match "`r"
        $first.IndexOf('"m/a1"') | Should -BeLessThan $first.IndexOf('"m/b1"')
        $back = Read-SurfacingLedger -InstallRoot $root
        $back.level | Should -Be 2
        $back.counts['m/a1'] | Should -Be 12
        @($back.transcripts['x.jsonl']) | Should -Be @('m/a1')
        @($back.suppressed) | Should -Be @('n/c1')
        Save-SurfacingLedger -InstallRoot $root -Ledger $back
        [IO.File]::ReadAllText($path) | Should -BeExactly $first
    }
    It 'refuses a ledger with an unknown schemaVersion' {
        $root = Join-Path $TestDrive 'p2'
        New-Item -ItemType Directory -Path (Join-Path $root 'learn-progress') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'learn-progress' 'surfacing.json') -Value '{"schemaVersion":9}'
        { Read-SurfacingLedger -InstallRoot $root } | Should -Throw '*schemaVersion*'
    }
}

Describe 'Get-SurfacingSummary' {
    It 'reports level, name, weights, suppressed list, and progress at the current level' {
        $ledger = New-EmptySurfacingLedger
        $ledger.level = 2
        $ledger.counts = @{ 'm/b1' = 10 }
        $ledger.suppressed = @('m/a2')
        $s = Get-SurfacingSummary -Ledger $ledger -Index (New-FixtureIndex)
        $s.level | Should -Be 2
        $s.levelName | Should -Be 'Conversational Collaborator'
        $s.maxLevel | Should -Be 7
        @($s.weights | ForEach-Object { $_.percent }) | Should -Be @(100, 50)
        $s.suppressed | Should -Be @('m/a2')
        $s.atThreshold | Should -Be 1
        $s.levelTotal | Should -Be 1
    }
}
