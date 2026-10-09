BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'scripts' 'learn-index-lib.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'teaching-lib.ps1')
    $script:Keys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($k in 'm/a', 'm/b', 'n/c') { [void]$script:Keys.Add($k) }
    $script:Titles = @{ 'm/a' = 'Lesson A'; 'm/b' = 'Lesson B & more'; 'n/c' = 'Lesson C' }

    function New-SlideText {
        param([string]$Heading = 'A slide', [string]$Body = "- point one`n- point two", [string]$Lessons = 'm/a')
        "# $Heading`n`n$Body`n`n<!--`n**Graphic.** a picture`n**Short note.** say this`n**Deep note.** say more`n**Lessons.** $Lessons`n-->"
    }
    # A contract-valid deck: title slide + 9 content slides.
    function New-DeckText {
        param([string[]]$Extra = @())
        $slides = @((New-SlideText -Heading 'Title' -Body 'A subtitle line' -Lessons 'none'))
        foreach ($i in 2..10) { $slides += (New-SlideText -Heading "Slide $i") }
        $slides += $Extra
        "---`nmarp: true`ntitle: Test deck`npaginate: true`n---`n`n" + ($slides -join "`n`n---`n`n") + "`n"
    }
    function New-DeckFile {
        param([string]$Name, [string]$Text)
        $p = Join-Path $TestDrive $Name
        [IO.File]::WriteAllText($p, $Text)
        $p
    }
}

Describe 'Read-TeachingSlides' {
    It 'reads front matter, slides, headings, bullets and the four notes fields' {
        $d = Read-TeachingSlides -Path (New-DeckFile 'ok.md' (New-DeckText))
        $d.front['marp'] | Should -Be 'true'
        $d.front['title'] | Should -Be 'Test deck'
        @($d.slides).Count | Should -Be 10
        $s = $d.slides[1]
        $s.heading | Should -Be 'Slide 2'
        $s.headingLevel | Should -Be 1
        $b = @($s.blocks | Where-Object { $_.type -eq 'bullets' })[0]
        @($b.items | ForEach-Object { $_.text }) | Should -Be @('point one', 'point two')
        $s.notes.graphic | Should -Be 'a picture'
        $s.notes.short | Should -Be 'say this'
        $s.notes.deep | Should -Be 'say more'
        @($s.notes.lessons) | Should -Be @('m/a')
        $d.slides[0].notes.lessonsNone | Should -BeTrue
    }
    It 'does not split a slide on a --- line inside a fenced code block' {
        $code = New-SlideText -Heading 'Code' -Body "- before`n`n``````yaml`nkey: 1`n---`nkey: 2`n```````n"
        $d = Read-TeachingSlides -Path (New-DeckFile 'fence.md' (New-DeckText -Extra @($code)))
        @($d.slides).Count | Should -Be 11
        $c = @($d.slides[10].blocks | Where-Object { $_.type -eq 'code' })[0]
        $c.lang | Should -Be 'yaml'
        $c.text | Should -Be "key: 1`n---`nkey: 2"
    }
    It 'parses nested bullets, images, and a Marp class directive' {
        $s = "<!-- _class: lead -->`n" + (New-SlideText -Heading 'Nested' -Body "- top`n  - child one`n  - child two`n`n![The flow](infographic.svg)")
        $d = Read-TeachingSlides -Path (New-DeckFile 'nest.md' (New-DeckText -Extra @($s)))
        $sl = $d.slides[10]
        $sl.class | Should -Be 'lead'
        $b = @($sl.blocks | Where-Object { $_.type -eq 'bullets' })[0]
        @($b.items[0].children) | Should -Be @('child one', 'child two')
        $img = @($sl.blocks | Where-Object { $_.type -eq 'image' })[0]
        $img.src | Should -Be 'infographic.svg'
        $img.alt | Should -Be 'The flow'
    }
    It 'parses a CRLF file identically to its LF twin' {
        $lf = New-DeckText
        $a = Read-TeachingSlides -Path (New-DeckFile 'lf.md' $lf)
        $b = Read-TeachingSlides -Path (New-DeckFile 'crlf.md' ($lf -replace "`n", "`r`n"))
        (ConvertTo-TeachingDeckHtml -Deck $a -LessonTitles $script:Titles) |
            Should -BeExactly (ConvertTo-TeachingDeckHtml -Deck $b -LessonTitles $script:Titles)
    }
}

Describe 'Test-TeachingSlides' {
    It 'passes a valid deck' {
        $d = Read-TeachingSlides -Path (New-DeckFile 'v.md' (New-DeckText))
        @(Test-TeachingSlides -Deck $d -LessonKeys $script:Keys).Count | Should -Be 0
    }
    It 'names the slide with a missing notes label' {
        $bad = "# Bad`n`n- x`n`n<!--`n**Graphic.** g`n**Short note.** s`n**Lessons.** m/a`n-->"
        $d = Read-TeachingSlides -Path (New-DeckFile 'nolabel.md' (New-DeckText -Extra @($bad)))
        @(Test-TeachingSlides -Deck $d -LessonKeys $script:Keys) | Should -Contain 'Slide 11: notes are missing **Deep note.**'
    }
    It 'rejects an unknown lesson, a content slide citing none, and a slide without bullets' {
        $unknown = New-SlideText -Heading 'U' -Lessons 'm/zzz'
        $none = New-SlideText -Heading 'N' -Lessons 'none'
        $nobullets = New-SlideText -Heading 'P' -Body 'Just a paragraph.'
        $d = Read-TeachingSlides -Path (New-DeckFile 'bad.md' (New-DeckText -Extra @($unknown, $none, $nobullets)))
        $f = @(Test-TeachingSlides -Deck $d -LessonKeys $script:Keys)
        $f | Should -Contain "Slide 11: cites unknown lesson 'm/zzz'"
        $f | Should -Contain 'Slide 12: cites no lessons'
        $f | Should -Contain 'Slide 13: has no bullet points'
    }
    It 'rejects too few slides, missing marp front matter, and a non-local image' {
        $text = "---`ntitle: T`n---`n`n" + (New-SlideText -Heading 'Only' -Body "- a`n`n![x](https://example.com/x.png)")
        $d = Read-TeachingSlides -Path (New-DeckFile 'few.md' $text)
        $f = @(Test-TeachingSlides -Deck $d -LessonKeys $script:Keys)
        $f | Should -Contain 'Front matter must set marp: true'
        $f | Should -Contain 'Deck has 1 slides; expected 10 to 14'
        $f | Should -Contain "Slide 1: image 'https://example.com/x.png' must be a file in the same folder"
    }
    It 'rejects a slide with more than 6 bullets' {
        $body = (1..7 | ForEach-Object { "- point $_" }) -join "`n"
        $many = New-SlideText -Heading 'Many' -Body $body
        $d = Read-TeachingSlides -Path (New-DeckFile 'many.md' (New-DeckText -Extra @($many)))
        @(Test-TeachingSlides -Deck $d -LessonKeys $script:Keys) | Should -Contain 'Slide 11: has 7 bullets; keep slides to 6 or fewer'
    }
    It 'rejects a bullet over 30 words, reporting the slide, bullet number, and word count' {
        $longBullet = (1..31 | ForEach-Object { "word$_" }) -join ' '
        $body = "- short point`n- $longBullet"
        $long = New-SlideText -Heading 'Long' -Body $body
        $d = Read-TeachingSlides -Path (New-DeckFile 'long.md' (New-DeckText -Extra @($long)))
        @(Test-TeachingSlides -Deck $d -LessonKeys $script:Keys) | Should -Contain 'Slide 11: bullet 2 has 31 words; keep bullets under 30'
    }
}

Describe 'ConvertTo-TeachingDeckHtml' {
    It 'escapes HTML in slide text and notes, so injected markup is shown, not run' {
        $evil = New-SlideText -Heading 'Tags <b>&</b>' -Body "- <script>alert(1)</script> & `"quotes`""
        $d = Read-TeachingSlides -Path (New-DeckFile 'evil.md' (New-DeckText -Extra @($evil)))
        $h = ConvertTo-TeachingDeckHtml -Deck $d -LessonTitles $script:Titles
        $h | Should -Not -Match '<script'
        $h | Should -Match '&lt;script&gt;alert\(1\)&lt;/script&gt;'
        $h | Should -Match 'Tags &lt;b&gt;&amp;&lt;/b&gt;'
        $h | Should -Match 'Lesson B &amp; more|Lesson A'
    }
    It 'renders the inline Markdown subset and refuses javascript: links' {
        $s = New-SlideText -Heading 'Inline' -Body "- **bold** and *it* and ``git status`` and [docs](https://git-scm.com/docs) and [bad](javascript:alert(1))`n- Ignore *.log and *.tmp together"
        $d = Read-TeachingSlides -Path (New-DeckFile 'inline.md' (New-DeckText -Extra @($s)))
        $h = ConvertTo-TeachingDeckHtml -Deck $d -LessonTitles $script:Titles
        $h | Should -Match '<strong>bold</strong>'
        $h | Should -Match '<em>it</em>'
        $h | Should -Match '<code>git status</code>'
        $h | Should -Match '<a href="https://git-scm.com/docs">docs</a>'
        $h | Should -Not -Match 'href="javascript'
        # Two globs on one line must not be mangled into emphasis spanning both
        # (a naive *...*  regex would turn "*.log and *.tmp" into "<em>.log and </em>.tmp").
        $h | Should -Match 'Ignore \*\.log and \*\.tmp together'
        $h | Should -Not -Match '<em>\.log'
    }
    It 'does not run a script injected through an unescaped lesson-link href, even without a contract check' {
        $evilKey = 'm/a"><script>alert(1)</script>'
        $s = New-SlideText -Heading 'Evil lesson' -Lessons $evilKey
        $d = Read-TeachingSlides -Path (New-DeckFile 'evillessons.md' (New-DeckText -Extra @($s)))
        # Rendered directly, with no Test-TeachingSlides call in between.
        $h = ConvertTo-TeachingDeckHtml -Deck $d -LessonTitles $script:Titles
        $h | Should -Not -Match '<script'
    }
    It 'links cited lessons to their pages by relative path, with notes in details panels' {
        $d = Read-TeachingSlides -Path (New-DeckFile 'links.md' (New-DeckText))
        $h = ConvertTo-TeachingDeckHtml -Deck $d -LessonTitles $script:Titles
        $h | Should -Match '<a href="\.\./\.\./\.\./m/capabilities/a\.md">Lesson A</a>'
        $h | Should -Match '<details class="notes">'
        $h | Should -Match '<details class="deep">'
    }
    It 'is deterministic, LF-only, ends with a newline, and has no script or event handler' {
        $d = Read-TeachingSlides -Path (New-DeckFile 'det.md' (New-DeckText))
        $a = ConvertTo-TeachingDeckHtml -Deck $d -LessonTitles $script:Titles
        $b = ConvertTo-TeachingDeckHtml -Deck $d -LessonTitles $script:Titles
        $a | Should -BeExactly $b
        $a | Should -Not -Match "`r"
        $a.EndsWith("`n") | Should -BeTrue
        $a | Should -Not -Match '(?i)<script|\son[a-z]+\s*='
    }
}

Describe 'build-teaching-decks.ps1' {
    BeforeAll {
        $script:Cli = Join-Path $PSScriptRoot '..' 'scripts' 'build-teaching-decks.ps1'
        function New-FixtureRepo {
            param([string]$Name, [string]$DeckText)
            $root = Join-Path $TestDrive $Name
            $wf = Join-Path $root 'learn' 'teaching' 'workflows' 'demo'
            New-Item -ItemType Directory -Path $wf -Force | Out-Null
            @{ schemaVersion = 1; lessons = @(
                @{ id = 'a'; module = 'm'; title = 'Lesson A'; level = 1; capabilities = @('a'); path = 'learn/m/capabilities/a.md' }
                @{ id = 'b'; module = 'm'; title = 'Lesson B'; level = 1; capabilities = @('b'); path = 'learn/m/capabilities/b.md' }
                @{ id = 'c'; module = 'n'; title = 'Lesson C'; level = 1; capabilities = @('c'); path = 'learn/n/capabilities/c.md' }
            ) } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $root 'learn' 'index.json')
            [IO.File]::WriteAllText((Join-Path $wf 'slides.md'), $DeckText)
            $root
        }
    }
    It 'writes deck.html, then -Check reports it current' {
        $root = New-FixtureRepo 'b1' (New-DeckText)
        & pwsh -NoProfile -File $script:Cli -RepoRoot $root | Out-Null
        $LASTEXITCODE | Should -Be 0
        Join-Path $root 'learn/teaching/workflows/demo/deck.html' | Should -Exist
        & pwsh -NoProfile -File $script:Cli -RepoRoot $root -Check | Out-Null
        $LASTEXITCODE | Should -Be 0
    }
    It '-Check exits 1 when slides.md changed after the deck was built' {
        $root = New-FixtureRepo 'b2' (New-DeckText)
        & pwsh -NoProfile -File $script:Cli -RepoRoot $root | Out-Null
        [IO.File]::WriteAllText((Join-Path $root 'learn/teaching/workflows/demo/slides.md'), (New-DeckText -Extra @((New-SlideText -Heading 'New'))))
        & pwsh -NoProfile -File $script:Cli -RepoRoot $root -Check | Out-Null
        $LASTEXITCODE | Should -Be 1
    }
    It 'exits 2 and writes nothing when a deck breaks the contract' {
        $root = New-FixtureRepo 'b3' (New-DeckText -Extra @((New-SlideText -Heading 'U' -Lessons 'm/zzz')))
        $out = & pwsh -NoProfile -File $script:Cli -RepoRoot $root
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -Match "demo: Slide 11: cites unknown lesson 'm/zzz'"
        Join-Path $root 'learn/teaching/workflows/demo/deck.html' | Should -Not -Exist
    }
}
