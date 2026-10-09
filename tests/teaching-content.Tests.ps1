BeforeDiscovery {
    $wfRoot = Join-Path $PSScriptRoot '..' 'learn' 'teaching' 'workflows'
    $script:Workflows = @()
    if (Test-Path -LiteralPath $wfRoot) {
        $script:Workflows = @(Get-ChildItem -LiteralPath $wfRoot -Directory | ForEach-Object { @{ Name = $_.Name; Dir = $_.FullName } })
    }
    $teach = Join-Path $PSScriptRoot '..' 'learn' 'teaching'
    $script:MarkupFiles = @()
    if (Test-Path -LiteralPath $teach) {
        $script:MarkupFiles = @(Get-ChildItem -LiteralPath $teach -Recurse -File -Include '*.html', '*.svg' |
            ForEach-Object { @{ Name = [IO.Path]::GetRelativePath($teach, $_.FullName); Path = $_.FullName } })
    }
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'scripts' 'learn-index-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'teaching-lib.ps1')
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:Keys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($l in @((Read-LearnIndex -Path (Join-Path $script:RepoRoot 'learn' 'index.json')).lessons)) {
        [void]$script:Keys.Add((Get-LessonKey -Lesson $l))
    }
}

Describe 'Teaching workflow <Name>' -ForEach $script:Workflows -AllowNullOrEmptyForEach {
    It 'has slides.md, deck.html, infographic.svg and exercise.md' {
        foreach ($f in 'slides.md', 'deck.html', 'infographic.svg', 'exercise.md') { Join-Path $Dir $f | Should -Exist }
    }
    It 'slides.md passes the slide contract' {
        $deck = Read-TeachingSlides -Path (Join-Path $Dir 'slides.md')
        @(Test-TeachingSlides -Deck $deck -LessonKeys $script:Keys) | Should -BeNullOrEmpty
    }
    It 'shows the infographic on at least one slide' {
        $deck = Read-TeachingSlides -Path (Join-Path $Dir 'slides.md')
        @($deck.slides | ForEach-Object { $_.blocks } | Where-Object { $_.type -eq 'image' -and $_.src -eq 'infographic.svg' }).Count |
            Should -BeGreaterThan 0
    }
    It 'exercise.md has its front matter, sections in order, a checkpoint per step, and known lessons' {
        $t = ([IO.File]::ReadAllText((Join-Path $Dir 'exercise.md'))) -replace "`r`n", "`n"
        $t | Should -Match '(?s)^---\n.*?\n---\n'
        $front = ([regex]::Match($t, '(?s)^---\n(.*?)\n---\n')).Groups[1].Value
        foreach ($k in 'title', 'workflow', 'time_minutes', 'level') { $front | Should -Match "(?m)^${k}:\s*\S" }
        $front | Should -Match "(?m)^workflow:\s*$([regex]::Escape($Name))\s*$"
        $last = -1
        foreach ($h in 'Goal', 'You will need', 'Steps', 'What good looks like', 'If you get stuck', 'Lessons used') {
            $m = [regex]::Match($t, "(?m)^## $([regex]::Escape($h))\s*$")
            $m.Success | Should -BeTrue -Because "section '## $h' is required"
            $m.Index | Should -BeGreaterThan $last -Because "'## $h' must come in order"
            $last = $m.Index
        }
        $steps = [regex]::Split($t, '(?m)^(?=### Step \d+: )') | Where-Object { $_ -match '^### Step \d+: ' }
        @($steps).Count | Should -BeGreaterThan 2
        foreach ($s in $steps) {
            ($s -split '(?m)^## ')[0] | Should -Match '\*\*Checkpoint:\*\*' -Because ($s -split "`n")[0]
        }
        $used = ($t -split '(?m)^## Lessons used\s*$')[1]
        # One lesson key per list item, e.g. "- git-and-github/branches-and-switching" (backticks allowed).
        $cited = @([regex]::Matches($used, '(?m)^\s*[-*]\s+`?([a-z0-9][a-z0-9-]*/[a-z0-9][a-z0-9-]*)') |
            ForEach-Object { $_.Groups[1].Value })
        $cited.Count | Should -BeGreaterThan 0
        foreach ($c in $cited) { $script:Keys.Contains($c) | Should -BeTrue -Because "lesson '$c' must exist" }
    }
    It 'infographic.svg is well-formed, accessible, and self-contained' {
        $xml = [xml]([IO.File]::ReadAllText((Join-Path $Dir 'infographic.svg')))
        $svg = $xml.DocumentElement
        $svg.LocalName | Should -Be 'svg'
        $svg.GetAttribute('viewBox') | Should -Not -BeNullOrEmpty
        @($svg.ChildNodes | Where-Object { $_.LocalName -eq 'title' }).Count | Should -Be 1
        @($svg.ChildNodes | Where-Object { $_.LocalName -eq 'desc' }).Count | Should -Be 1
        $xml.SelectNodes("//*[local-name()='script' or local-name()='foreignObject']").Count | Should -Be 0
        $xml.SelectNodes("//@*[starts-with(local-name(),'on')]").Count | Should -Be 0
        $xml.SelectNodes("//@*[local-name()='href'][starts-with(.,'http') or starts-with(.,'//')]").Count | Should -Be 0
    }
}

Describe 'Teaching markup file <Name>' -ForEach $script:MarkupFiles -AllowNullOrEmptyForEach {
    It 'passes the markup-safety allowlist' {
        $t = [IO.File]::ReadAllText($Path)
        @(Test-TeachingMarkupSafety -Text $t) | Should -BeNullOrEmpty
    }
}

Describe 'Test-TeachingMarkupSafety bypasses' {
    It 'catches a javascript: href' {
        @(Test-TeachingMarkupSafety -Text '<a href="javascript:alert(1)">x</a>') | Should -Not -BeNullOrEmpty
    }
    It 'catches a data: href' {
        @(Test-TeachingMarkupSafety -Text '<a href="data:text/html,<script>alert(1)</script>">x</a>') | Should -Not -BeNullOrEmpty
    }
    It 'catches a single-quoted external URL' {
        @(Test-TeachingMarkupSafety -Text "<img src='https://evil.example/x.png'>") | Should -Not -BeNullOrEmpty
    }
    It 'catches an unquoted external URL' {
        @(Test-TeachingMarkupSafety -Text '<img src=https://evil.example/x.png>') | Should -Not -BeNullOrEmpty
    }
    It 'catches a protocol-relative // URL in href, src, and xlink:href, quoted either way or unquoted' {
        @(Test-TeachingMarkupSafety -Text '<a href="//evil.example/x">x</a>') | Should -Not -BeNullOrEmpty
        @(Test-TeachingMarkupSafety -Text "<a href='//evil.example/x'>x</a>") | Should -Not -BeNullOrEmpty
        @(Test-TeachingMarkupSafety -Text '<a href=//evil.example/x>x</a>') | Should -Not -BeNullOrEmpty
        @(Test-TeachingMarkupSafety -Text '<img src="//evil.example/x.png">') | Should -Not -BeNullOrEmpty
        @(Test-TeachingMarkupSafety -Text '<use xlink:href="//evil.example/x.svg#y">') | Should -Not -BeNullOrEmpty
    }
    It 'catches banned iframe, object, embed, base, and form elements' {
        foreach ($tag in '<iframe src="x">', '<object data="x">', '<embed src="x">', '<base href="x">', '<form action="x">') {
            @(Test-TeachingMarkupSafety -Text $tag).Count | Should -BeGreaterThan 0
        }
    }
    It 'catches a meta http-equiv redirect' {
        @(Test-TeachingMarkupSafety -Text '<meta http-equiv="refresh" content="0;url=https://evil.example">') | Should -Not -BeNullOrEmpty
    }
    It 'catches uppercase HTTPS: and JAVASCRIPT: schemes in SVG' {
        @(Test-TeachingMarkupSafety -Text '<a href="HTTPS://evil.example">x</a>') | Should -Not -BeNullOrEmpty
        @(Test-TeachingMarkupSafety -Text '<a href="JAVASCRIPT:alert(1)">x</a>') | Should -Not -BeNullOrEmpty
    }
    It 'allows a relative path, a bare fragment, and the svg/xhtml xmlns namespace attributes' {
        @(Test-TeachingMarkupSafety -Text '<a href="../../../git-and-github/capabilities/x.md">x</a>') | Should -BeNullOrEmpty
        @(Test-TeachingMarkupSafety -Text '<img src="infographic.svg">') | Should -BeNullOrEmpty
        @(Test-TeachingMarkupSafety -Text '<a href="#s1">x</a>') | Should -BeNullOrEmpty
        @(Test-TeachingMarkupSafety -Text '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"></svg>') | Should -BeNullOrEmpty
    }
}

Describe 'Teaching decks are current' {
    It 'build-teaching-decks.ps1 -Check passes' {
        & pwsh -NoProfile -File (Join-Path $script:RepoRoot 'scripts' 'build-teaching-decks.ps1') -Check | Out-Null
        $LASTEXITCODE | Should -Be 0
    }
}

Describe 'The first four teaching workflows ship' {
    It 'has exactly the four approved workflow folders' {
        $names = @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot '..' 'learn' 'teaching' 'workflows') -Directory | ForEach-Object { $_.Name } | Sort-Object)
        $names | Should -Be @('one-change-start-to-finish', 'recovering-when-it-breaks', 'starting-a-project-safely', 'working-with-an-agent-safely')
    }
}
