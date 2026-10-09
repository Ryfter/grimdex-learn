BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'scripts' 'manifest-lib.ps1')
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:ManifestPath = Join-Path $script:RepoRoot 'learn' 'manifest.json'
}

Describe 'learn/manifest.json (golden module, D32)' {
    It 'loads through Read-LearnManifest without error' {
        { Read-LearnManifest -Path $script:ManifestPath } | Should -Not -Throw
    }

    It 'declares moduleId git-and-github' {
        (Read-LearnManifest -Path $script:ManifestPath).moduleId | Should -Be 'git-and-github'
    }

    It 'carries the D32 fields: title, learnPackVersion, contentAdmissionVersion' {
        $m = Read-LearnManifest -Path $script:ManifestPath
        $m.title | Should -Not -BeNullOrEmpty
        $m.learnPackVersion | Should -Not -BeNullOrEmpty
        $m.contentAdmissionVersion | Should -Not -BeNullOrEmpty
    }

    It 'lists the exact neverShip files, including the surfacing ledger' {
        $m = Read-LearnManifest -Path $script:ManifestPath
        $m.neverShip | Should -Be @(
            'config/fleet.json',
            'config/learn-progress.json',
            'config/quota.json',
            'config/settings.json',
            'learn-progress/surfacing.json'
        )
    }

    It 'registers learn-progress/ as a student root so install and graduation never write it' {
        $m = Read-LearnManifest -Path $script:ManifestPath
        $m.studentRoots | Should -Contain 'learn-progress/**'
    }

    It 'has the required module scaffold files on disk' {
        foreach ($f in @('README.md','source-registry.md','refresh-policy.md',
                         'update-log.md','provenance.md','claims/baseline.yaml')) {
            (Join-Path $script:RepoRoot 'learn' 'git-and-github' $f) | Should -Exist
        }
    }
}

Describe 'Golden page: commits-and-history' {
    BeforeAll {
        . (Join-Path $PSScriptRoot '..' 'scripts' 'learn-lib.ps1')
        $script:PagePath = Join-Path $script:RepoRoot 'learn' 'git-and-github' `
            'capabilities' 'commits-and-history.md'
    }

    It 'exists and passes the D32 page contract' {
        $script:PagePath | Should -Exist
        $r = Test-CapabilityPageContract -Path $script:PagePath
        $r.failures | Should -BeNullOrEmpty
        $r.passed | Should -BeTrue
    }

    It 'declares safety_class destructive and includes reflog recovery' {
        $text = Get-Content -Path $script:PagePath -Raw
        $text | Should -Match '(?m)^safety_class: destructive\r?$'
        $text | Should -Match 'git reflog'
    }

    It 'has claims registered in baseline.yaml' {
        $baseline = Get-Content -Raw (Join-Path $script:RepoRoot 'learn' 'git-and-github' `
            'claims' 'baseline.yaml')
        $baseline | Should -Match 'commits-and-history'
        $baseline | Should -Not -Match '(?m)^claims: \[\]'
    }
}

Describe 'All capability pages conform to the D32 contract' {
    BeforeAll {
        . (Join-Path $PSScriptRoot '..' 'scripts' 'learn-lib.ps1')
    }

    # Every module under learn/, not just the first one: a module added without
    # conformance coverage is exactly how a broken page reaches a student.
    It 'page <_.Directory.Parent.Name>/<_.Name> passes Test-CapabilityPageContract' -ForEach (
        Get-ChildItem -Path (Join-Path $PSScriptRoot '..' 'learn') -Directory |
            ForEach-Object { Join-Path $_.FullName 'capabilities' } |
            Where-Object { Test-Path -LiteralPath $_ } |
            ForEach-Object { Get-ChildItem -Path $_ -Filter '*.md' -File }
    ) {
        $r = Test-CapabilityPageContract -Path $_.FullName
        $r.failures | Should -BeNullOrEmpty
        $r.passed | Should -BeTrue
    }
}

Describe 'Every Learn module carries the D32 scaffold' {
    It 'module <_.Name> has all required scaffold files' -ForEach (
        Get-ChildItem -Path (Join-Path $PSScriptRoot '..' 'learn') -Directory |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'capabilities') }
    ) {
        foreach ($f in @('README.md','source-registry.md','refresh-policy.md',
                         'update-log.md','provenance.md','claims/baseline.yaml')) {
            (Join-Path $_.FullName $f) | Should -Exist
        }
    }
}

Describe 'Every capability page has baseline claims' {
    It 'module <_.Name> registers each page in claims/baseline.yaml' -ForEach (
        Get-ChildItem -Path (Join-Path $PSScriptRoot '..' 'learn') -Directory |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'capabilities') }
    ) {
        $baseline = Get-Content -Raw -LiteralPath (Join-Path $_.FullName 'claims' 'baseline.yaml')
        $missing = @(Get-ChildItem -Path (Join-Path $_.FullName 'capabilities') -Filter '*.md' -File |
            Where-Object { $baseline -notmatch ('(?m)^    page: capabilities/' + [regex]::Escape($_.Name) + '\s*$') } |
            ForEach-Object { $_.Name })
        $missing | Should -BeNullOrEmpty
    }
    It 'module <_.Name> baseline entries use a consistent two-space list indent' -ForEach (
        Get-ChildItem -Path (Join-Path $PSScriptRoot '..' 'learn') -Directory |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'claims' 'baseline.yaml') }
    ) {
        # A mis-indented entry silently breaks YAML parsing for the whole file.
        $lines = Get-Content -LiteralPath (Join-Path $_.FullName 'claims' 'baseline.yaml')
        @($lines | Where-Object { $_ -match '^\s*- id:' -and $_ -notmatch '^  - id:' }) | Should -BeNullOrEmpty
        @($lines | Where-Object { $_ -match '^\s+(page|claim|source|last_verified|kind|verification):' -and
                                  $_ -notmatch '^    \w' }) | Should -BeNullOrEmpty
    }
}

Describe 'Manifest enumerates every module on disk' {
    It 'modules[] matches the module directories under learn/' {
        $m = Read-LearnManifest -Path $script:ManifestPath
        $declared = @($m.modules | ForEach-Object { $_.moduleId }) | Sort-Object
        $onDisk = @(
            Get-ChildItem -Path (Join-Path $script:RepoRoot 'learn') -Directory |
                Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'capabilities') } |
                ForEach-Object { $_.Name }
        ) | Sort-Object
        $declared | Should -Be $onDisk
    }

    It 'every declared pagesPath exists' {
        $m = Read-LearnManifest -Path $script:ManifestPath
        foreach ($mod in $m.modules) {
            (Join-Path $script:RepoRoot $mod.pagesPath) | Should -Exist
        }
    }
}

Describe 'Every capability page declares a mastery level' {
    BeforeAll {
        $script:AllPages = @(
            Get-ChildItem -Path (Join-Path $PSScriptRoot '..' 'learn') -Directory |
                ForEach-Object { Join-Path $_.FullName 'capabilities' } |
                Where-Object { Test-Path -LiteralPath $_ } |
                ForEach-Object { Get-ChildItem -Path $_ -Filter '*.md' -File }
        )
        function Get-PageLevel([string]$Path) {
            $t = [string](Get-Content -LiteralPath $Path -Raw)
            if ($t -match '(?s)^---\r?\n(.*?)\r?\n---' -and $Matches[1] -match '(?m)^level:[ \t]*([1-7])[ \t]*\r?$') {
                return [int]$Matches[1]
            }
            $null
        }
    }
    # -ForEach is evaluated at discovery, before BeforeAll runs, so the page list
    # is inlined here (same pattern as the file's other -ForEach tests).
    It 'page <_.Directory.Parent.Name>/<_.Name> has level 1-7' -ForEach (
        Get-ChildItem -Path (Join-Path $PSScriptRoot '..' 'learn') -Directory |
            ForEach-Object { Join-Path $_.FullName 'capabilities' } |
            Where-Object { Test-Path -LiteralPath $_ } |
            ForEach-Object { Get-ChildItem -Path $_ -Filter '*.md' -File }
    ) {
        Get-PageLevel $_.FullName | Should -BeIn @(1, 2, 3, 4, 5, 6, 7)
    }
    It 'level counts match mastery spec Appendix A (11/26/46/17/27/5/5)' {
        $counts = @{}
        foreach ($p in $script:AllPages) { $l = Get-PageLevel $p.FullName; $counts[$l] = 1 + [int]$counts[$l] }
        @(1..7 | ForEach-Object { [int]$counts[$_] }) | Should -Be @(11, 26, 46, 17, 27, 5, 5)
    }
}
