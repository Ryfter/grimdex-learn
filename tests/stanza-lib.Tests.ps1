BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'scripts' 'manifest-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'stanza-lib.ps1')
    function New-StanzaFile {
        param([string]$Name, [string]$Content)
        $p = Join-Path $TestDrive $Name
        Set-Content -LiteralPath $p -Value $Content -NoNewline
        $p
    }
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
}

Describe 'Get-LearnStanzaContent' {
    It 'renders the pagesPath and the base pin from the manifest' {
        $c = Get-LearnStanzaContent -Manifest (New-FixtureManifestObject)
        $c | Should -Match 'Learn module \(grimdex-edu\)'
        $c | Should -Match 'learn/git-and-github/capabilities/'
        $c | Should -Match 'TEST-PIN'
    }
    It 'points at the checkout for tooling and never implies scripts live in the install' {
        # Install copies only learn/, which is non-executable data by constraint.
        # version-check.ps1 and graduate.ps1 take -InstallRoot and are designed to
        # run from the grimdex-edu checkout against a target install.
        $c = Get-LearnStanzaContent -Manifest (New-FixtureManifestObject)
        $c | Should -Match 'runs from your grimdex-edu checkout'
        $c | Should -Match '-InstallRoot'
        $c | Should -Not -Match 'pwsh scripts/'
    }
    It 'is deterministic: identical input produces byte-identical output' {
        $m = New-FixtureManifestObject
        $a = Get-LearnStanzaContent -Manifest $m
        Start-Sleep -Milliseconds 5
        $b = Get-LearnStanzaContent -Manifest $m
        $a | Should -BeExactly $b
    }
    It 'contains no backtick characters and no marker text' {
        $c = Get-LearnStanzaContent -Manifest (New-FixtureManifestObject)
        $c.IndexOf([char]96) | Should -Be -1
        $c | Should -Not -Match 'grimdex-learn:'
    }
    It 'lists every declared module with its title and pages path' {
        $m = New-FixtureManifestObject
        $m.modules = @(
            @{ moduleId = 'git-and-github'; title = 'Git field guide'; pagesPath = 'learn/git-and-github/capabilities/' }
            @{ moduleId = 'testing-basics'; title = 'Testing basics'; pagesPath = 'learn/testing-basics/capabilities/' }
        )
        $c = Get-LearnStanzaContent -Manifest $m
        $c | Should -Match 'Modules installed:'
        $c | Should -Match '  - Git field guide: learn/git-and-github/capabilities/'
        $c | Should -Match '  - Testing basics: learn/testing-basics/capabilities/'
    }
    It 'omits the module list when the manifest declares no modules' {
        $c = Get-LearnStanzaContent -Manifest (New-FixtureManifestObject)
        $c | Should -Not -Match 'Modules installed:'
    }
    It 'throws when the manifest has no pagesPath' {
        $m = New-FixtureManifestObject
        $m.Remove('pagesPath')
        { Get-LearnStanzaContent -Manifest $m } | Should -Throw '*pagesPath*'
    }
    It 'omits the pin line for an unpinned manifest' {
        $m = New-FixtureManifestObject
        $m.Remove('baseGrimdex')
        $c = Get-LearnStanzaContent -Manifest $m
        $c | Should -Match 'Capability pages live under:'
        $c | Should -Match 'runs from your grimdex-edu checkout'
        $c | Should -Match '-InstallRoot'
        $c | Should -Not -Match 'matched to base Grimdex pin'
    }
    It 'still renders the pin line for a pinned manifest' {
        $c = Get-LearnStanzaContent -Manifest (New-FixtureManifestObject)
        $c | Should -Match 'matched to base Grimdex pin: TEST-PIN'
    }
    It 'omits the pin line and never prints the historical placeholder sentinel' {
        $m = New-FixtureManifestObject
        $m['baseGrimdex'] = @{ pin = 'PINNED-RELEASE-TAG-SET-AT-INSTALL-PLAN' }
        $c = Get-LearnStanzaContent -Manifest $m
        $c | Should -Not -Match 'matched to base Grimdex pin'
        $c | Should -Not -Match 'PINNED-RELEASE-TAG-SET-AT-INSTALL-PLAN'
    }
}

Describe 'Set-PointerStanza' {
    It 'throws rather than creating a base-owned file that does not exist' {
        { Set-PointerStanza -Path (Join-Path $TestDrive 'sp-missing.md') -Content 'body' } |
            Should -Throw '*does not exist*'
    }
    It 'throws on malformed markers' {
        $p = New-StanzaFile 'sp-bad.md' "x`n<!-- grimdex-learn:start -->`nno end`n"
        { Set-PointerStanza -Path $p -Content 'body' } | Should -Throw '*malformed*'
    }
    It 'throws when the file already has more than one block' {
        $p = New-StanzaFile 'sp-two.md' ("<!-- grimdex-learn:start -->`nA`n<!-- grimdex-learn:end -->`n" +
                                         "<!-- grimdex-learn:start -->`nB`n<!-- grimdex-learn:end -->`n")
        { Set-PointerStanza -Path $p -Content 'body' } | Should -Throw '*ambiguous*'
    }
    It 'appends with one separator newline when the file ends in a single newline' {
        $p = New-StanzaFile 'sp-one.md' "base text`n"
        (Set-PointerStanza -Path $p -Content 'body').action | Should -Be 'created'
        $text = [string](Get-Content -LiteralPath $p -Raw)
        $text | Should -BeExactly ("base text`n`n<!-- grimdex-learn:start -->`nbody`n<!-- grimdex-learn:end -->`n")
    }
    It 'appends with no separator to an empty file' {
        $p = Join-Path $TestDrive 'sp-empty.md'
        Set-Content -LiteralPath $p -Value '' -NoNewline
        (Set-PointerStanza -Path $p -Content 'body').action | Should -Be 'created'
        [string](Get-Content -LiteralPath $p -Raw) |
            Should -BeExactly ("<!-- grimdex-learn:start -->`nbody`n<!-- grimdex-learn:end -->`n")
    }
    It 'appends with a blank-line separator when the file has no trailing newline' {
        $p = New-StanzaFile 'sp-nonl.md' 'base text'
        (Set-PointerStanza -Path $p -Content 'body').action | Should -Be 'created'
        [string](Get-Content -LiteralPath $p -Raw) |
            Should -BeExactly ("base text`n`n<!-- grimdex-learn:start -->`nbody`n<!-- grimdex-learn:end -->`n")
    }
    It 'appends with no separator when the file already ends in a blank line' {
        $p = New-StanzaFile 'sp-blank.md' "base text`n`n"
        (Set-PointerStanza -Path $p -Content 'body').action | Should -Be 'created'
        [string](Get-Content -LiteralPath $p -Raw) |
            Should -BeExactly ("base text`n`n<!-- grimdex-learn:start -->`nbody`n<!-- grimdex-learn:end -->`n")
    }
    It 'returns unchanged and does not write when the content is already identical' {
        $p = New-StanzaFile 'sp-same.md' "base`n`n"
        Set-PointerStanza -Path $p -Content 'body' | Out-Null
        $item = Get-Item -LiteralPath $p
        $item.LastWriteTimeUtc = [datetime]::new(2000, 1, 1, 0, 0, 0, [System.DateTimeKind]::Utc)
        (Set-PointerStanza -Path $p -Content 'body').action | Should -Be 'unchanged'
        (Get-Item -LiteralPath $p).LastWriteTimeUtc.Year | Should -Be 2000
    }
    It 'replaces the block in place when the content differs' {
        $p = New-StanzaFile 'sp-diff.md' "head`n`n"
        Set-PointerStanza -Path $p -Content 'old body' | Out-Null
        (Set-PointerStanza -Path $p -Content 'new body').action | Should -Be 'updated'
        $text = [string](Get-Content -LiteralPath $p -Raw)
        $text | Should -Match 'new body'
        $text | Should -Not -Match 'old body'
        (Get-PointerStanzaState -Path $p).blocks | Should -Be 1
    }
    It 'preserves a body containing regex substitution syntax verbatim' {
        $p = New-StanzaFile 'sp-regex.md' "head`n`n"
        $tricky = 'literal $1 and $& and $$ stay put'
        Set-PointerStanza -Path $p -Content 'placeholder' | Out-Null
        (Set-PointerStanza -Path $p -Content $tricky).action | Should -Be 'updated'
        [string](Get-Content -LiteralPath $p -Raw) | Should -Match ([regex]::Escape($tricky))
    }
    It 'is idempotent: a second upsert is unchanged and byte-identical' {
        $p = New-StanzaFile 'sp-idem.md' "head`n`n"
        Set-PointerStanza -Path $p -Content 'body' | Out-Null
        $first = [string](Get-Content -LiteralPath $p -Raw)
        (Set-PointerStanza -Path $p -Content 'body').action | Should -Be 'unchanged'
        [string](Get-Content -LiteralPath $p -Raw) | Should -BeExactly $first
    }
    It 'upsert then Remove-PointerStanza restores the original bytes' {
        $original = "# Base`n`nbase text`n`n"
        $p = New-StanzaFile 'sp-round.md' $original
        Set-PointerStanza -Path $p -Content 'body' | Out-Null
        Remove-PointerStanza -Path $p | Out-Null
        [string](Get-Content -LiteralPath $p -Raw) | Should -BeExactly $original
    }
}

Describe 'Get-PointerStanzaBody' {
    It 'returns the body between the markers without the framing newlines' {
        $p = New-StanzaFile 'gb-1.md' "head`n<!-- grimdex-learn:start -->`nline one`nline two`n<!-- grimdex-learn:end -->`n"
        Get-PointerStanzaBody -Path $p | Should -BeExactly "line one`nline two"
    }
    It 'returns null when the file has no stanza' {
        $p = New-StanzaFile 'gb-2.md' "nothing here`n"
        Get-PointerStanzaBody -Path $p | Should -BeNullOrEmpty
    }
    It 'round-trips exactly what Set-PointerStanza wrote, including dollar signs' {
        $p = New-StanzaFile 'gb-3.md' "head`n`n"
        $body = "alpha `$1 beta`ngamma `$& delta"
        Set-PointerStanza -Path $p -Content $body | Out-Null
        Get-PointerStanzaBody -Path $p | Should -BeExactly $body
    }
}

Describe 'Get-PointerStanzaState' {
    It 'reports missing-file' {
        (Get-PointerStanzaState -Path (Join-Path $TestDrive 'nope.md')).state |
            Should -Be 'missing-file'
    }
    It 'reports absent when no markers' {
        $p = New-StanzaFile 'a.md' "# Title`n`nplain text`n"
        (Get-PointerStanzaState -Path $p).state | Should -Be 'absent'
    }
    It 'reports well-formed with block count' {
        $p = New-StanzaFile 'b.md' @"
# Title
<!-- grimdex-learn:start -->
learn pointer content
<!-- grimdex-learn:end -->
middle
<!-- grimdex-learn:start -->
second block
<!-- grimdex-learn:end -->
"@
        $r = Get-PointerStanzaState -Path $p
        $r.state  | Should -Be 'well-formed'
        $r.blocks | Should -Be 2
    }
    It 'reports malformed on unbalanced markers' {
        $p = New-StanzaFile 'c.md' "x`n<!-- grimdex-learn:start -->`nnever closed`n"
        (Get-PointerStanzaState -Path $p).state | Should -Be 'malformed'
    }
    It 'reports malformed on end-before-start' {
        $p = New-StanzaFile 'd.md' "<!-- grimdex-learn:end -->`n<!-- grimdex-learn:start -->`n"
        (Get-PointerStanzaState -Path $p).state | Should -Be 'malformed'
    }
}

Describe 'Remove-PointerStanza' {
    It 'strips every block including markers, leaves the rest byte-intact' {
        $p = New-StanzaFile 'e.md' "before`n<!-- grimdex-learn:start -->`ninjected`n<!-- grimdex-learn:end -->`nafter`n"
        $r = Remove-PointerStanza -Path $p
        $r.removed | Should -Be 1
        $text = [string](Get-Content -LiteralPath $p -Raw)
        $text | Should -Not -Match 'grimdex-learn'
        $text | Should -Match '(?s)before.*after'
    }
    It 'is a no-op on a file without markers' {
        $p = New-StanzaFile 'f.md' "untouched`n"
        (Remove-PointerStanza -Path $p).removed | Should -Be 0
        [string](Get-Content -LiteralPath $p -Raw) | Should -Be "untouched`n"
    }
    It 'throws on malformed markers rather than guessing' {
        $p = New-StanzaFile 'g.md' "<!-- grimdex-learn:start -->`nno end`n"
        { Remove-PointerStanza -Path $p } | Should -Throw '*malformed*'
    }
}
