BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'scripts' 'learn-index-lib.ps1')
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    function New-FixturePage {
        param([string]$Root, [string]$Module, [string]$Id, [string]$Title, [int]$Level, [string[]]$Caps)
        $dir = Join-Path $Root 'learn' $Module 'capabilities'
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        $capLines = ($Caps | ForEach-Object { "  - $_" }) -join "`n"
        $body = "---`ntitle: $Title`nmodule_id: $Module`nlevel: $Level`ncapabilities:`n$capLines`nstatus: current`n---`n`n## What it is`n"
        Set-Content -LiteralPath (Join-Path $dir "$Id.md") -Value $body -NoNewline
    }
}

Describe 'New-LearnIndex' {
    It 'indexes every page with id, module, title, level, capabilities and path' {
        $root = Join-Path $TestDrive 'idx1'
        New-FixturePage $root 'mod-b' 'beta' 'Beta page' 2 @('beta')
        New-FixturePage $root 'mod-a' 'alpha' '"Alpha: quoted title"' 1 @('alpha', 'alpha-two')
        $idx = New-LearnIndex -RepoRoot $root
        $idx.schemaVersion | Should -Be 1
        @($idx.lessons).Count | Should -Be 2
        $a = $idx.lessons[0]
        $a.id | Should -Be 'alpha'
        $a.module | Should -Be 'mod-a'
        $a.title | Should -Be 'Alpha: quoted title'
        $a.level | Should -Be 1
        $a.capabilities | Should -Be @('alpha', 'alpha-two')
        $a.path | Should -Be 'learn/mod-a/capabilities/alpha.md'
        (Get-LessonKey -Lesson $idx.lessons[1]) | Should -Be 'mod-b/beta'
    }
    It 'sorts ordinally so hyphens do not reorder ids by culture rules' {
        $root = Join-Path $TestDrive 'idx2'
        New-FixturePage $root 'm' 'gitignore' 'G' 1 @('g')
        New-FixturePage $root 'm' 'git-lfs' 'L' 1 @('l')
        $idx = New-LearnIndex -RepoRoot $root
        @($idx.lessons | ForEach-Object { $_.id }) | Should -Be @('git-lfs', 'gitignore')
    }
    It 'throws when a page has no level' {
        $root = Join-Path $TestDrive 'idx3'
        $dir = Join-Path $root 'learn' 'm' 'capabilities'
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $dir 'x.md') -Value "---`ntitle: X`nmodule_id: m`ncapabilities:`n  - x`n---`n" -NoNewline
        { New-LearnIndex -RepoRoot $root } | Should -Throw '*level*'
    }
    It 'throws when module_id does not match the module directory' {
        $root = Join-Path $TestDrive 'idx4'
        New-FixturePage $root 'dir-name' 'x' 'X' 1 @('x')
        $p = Join-Path $root 'learn/dir-name/capabilities/x.md'
        (Get-Content -LiteralPath $p -Raw) -replace 'module_id: dir-name', 'module_id: other' |
            Set-Content -LiteralPath $p -NoNewline
        { New-LearnIndex -RepoRoot $root } | Should -Throw '*module_id*'
    }
}

Describe 'ConvertTo-LearnIndexJson / Read-LearnIndex' {
    It 'emits LF-only JSON with a trailing newline that reads back' {
        $root = Join-Path $TestDrive 'idx5'
        New-FixturePage $root 'm' 'one' 'One' 3 @('one')
        $json = ConvertTo-LearnIndexJson -Index (New-LearnIndex -RepoRoot $root)
        $json | Should -Not -Match "`r"
        $json.EndsWith("`n") | Should -BeTrue
        $p = Join-Path $TestDrive 'idx5.json'
        [IO.File]::WriteAllText($p, $json)
        $back = Read-LearnIndex -Path $p
        $back.lessons[0].level | Should -Be 3
        @($back.lessons[0].capabilities) | Should -Be @('one')
    }
    It 'rejects an index with the wrong schemaVersion' {
        $p = Join-Path $TestDrive 'bad.json'
        Set-Content -LiteralPath $p -Value '{"schemaVersion":2,"lessons":[]}'
        { Read-LearnIndex -Path $p } | Should -Throw '*schemaVersion*'
    }
}

Describe 'The committed learn/index.json' {
    It 'is current with the page front matter (run scripts/build-learn-index.ps1 if not)' {
        & pwsh -NoProfile -File (Join-Path $script:RepoRoot 'scripts' 'build-learn-index.ps1') -Check | Out-Null
        $LASTEXITCODE | Should -Be 0
    }
    It 'lists all 137 lessons' {
        @((Read-LearnIndex -Path (Join-Path $script:RepoRoot 'learn' 'index.json')).lessons).Count | Should -Be 137
    }
}
