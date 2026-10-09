Set-StrictMode -Version 3.0

# teaching-lib.ps1 - parses the Marp-format slide lists under
# learn/teaching/workflows/*/slides.md, checks them against the slide contract
# (teaching-aids design §4) and renders the CSS-only deck.html (§6). Every piece
# of slide text is HTML-escaped before it is written; deck.html has no scripts.
# Requires learn-index-lib.ps1 to be dot-sourced first.

$script:NoteLabels = @('Graphic', 'Short note', 'Deep note', 'Lessons')
$script:LessonKeyRegex = '^[a-z0-9][a-z0-9-]*/[a-z0-9][a-z0-9-]*$'

function ConvertFrom-SlideNotes {
    param([Parameter(Mandatory)][string]$Text)
    $notes = @{ graphic = ''; short = ''; deep = ''; lessons = [string[]]@(); lessonsNone = $false; seen = [string[]]@() }
    $parts = [regex]::Split($Text, '\*\*(Graphic|Short note|Deep note|Lessons)\.\*\*')
    $seen = [System.Collections.Generic.List[string]]::new()
    for ($i = 1; $i -lt $parts.Count - 1; $i += 2) {
        $label = $parts[$i]
        $value = ($parts[$i + 1] -replace '\s+', ' ').Trim()
        if ($value) { $seen.Add($label) }
        switch ($label) {
            'Graphic'    { $notes.graphic = $value }
            'Short note' { $notes.short = $value }
            'Deep note'  { $notes.deep = $value }
            'Lessons'    {
                if ($value -eq 'none') { $notes.lessonsNone = $true }
                elseif ($value) { $notes.lessons = [string[]]@($value -split '\s*,\s*' | Where-Object { $_ }) }
            }
        }
    }
    $notes.seen = $seen.ToArray()
    $notes
}

function ConvertFrom-SlideChunk {
    param([Parameter(Mandatory)][string]$Chunk, [Parameter(Mandatory)][int]$Index)

    $notes = $null; $class = $null
    # The notes comment starts with **Graphic.**; any other comment is a Marp directive.
    foreach ($m in [regex]::Matches($Chunk, '(?s)<!--(.*?)-->')) {
        $inner = $m.Groups[1].Value.Trim()
        if ($inner.StartsWith('**Graphic.**')) { $notes = ConvertFrom-SlideNotes -Text $inner }
        elseif ($inner -match '^_class:\s*(\S+)$') { $class = $Matches[1] }
    }
    $lines = ([regex]::Replace($Chunk, '(?s)<!--.*?-->', '')) -split "`n"

    $heading = $null; $level = 0
    $blocks = [System.Collections.Generic.List[object]]::new()
    $i = 0
    while ($i -lt $lines.Count) {
        $line = $lines[$i]
        if ($line -match '^```(\S*)\s*$') {
            $lang = $Matches[1]
            $code = [System.Collections.Generic.List[string]]::new()
            $i++
            while ($i -lt $lines.Count -and $lines[$i] -notmatch '^```\s*$') { $code.Add($lines[$i]); $i++ }
            $i++
            $blocks.Add(@{ type = 'code'; lang = $lang; text = ($code -join "`n") })
            continue
        }
        if ($null -eq $heading -and $line -match '^(#{1,2})\s+(.+?)\s*$') {
            $level = $Matches[1].Length; $heading = $Matches[2]; $i++; continue
        }
        if ($line -match '^!\[([^\]]*)\]\(([^)\s]+)\)\s*$') {
            $blocks.Add(@{ type = 'image'; alt = $Matches[1]; src = $Matches[2] }); $i++; continue
        }
        if ($line -match '^[-*]\s+(.+?)\s*$') {
            $items = [System.Collections.Generic.List[object]]::new()
            while ($i -lt $lines.Count) {
                if ($lines[$i] -match '^[-*]\s+(.+?)\s*$') {
                    $items.Add(@{ text = $Matches[1]; children = [System.Collections.Generic.List[string]]::new() })
                } elseif ($lines[$i] -match '^\s{2,}[-*]\s+(.+?)\s*$' -and $items.Count -gt 0) {
                    $items[$items.Count - 1].children.Add($Matches[1])
                } else { break }
                $i++
            }
            foreach ($it in $items) { $it.children = $it.children.ToArray() }
            $blocks.Add(@{ type = 'bullets'; items = $items.ToArray() })
            continue
        }
        if ($line.Trim()) {
            $para = [System.Collections.Generic.List[string]]::new()
            while ($i -lt $lines.Count -and $lines[$i].Trim() -and
                   $lines[$i] -notmatch '^(```|#{1,2}\s|[-*]\s|!\[)') {
                $para.Add($lines[$i].Trim()); $i++
            }
            $blocks.Add(@{ type = 'para'; text = ($para -join ' ') })
            continue
        }
        $i++
    }
    @{ index = $Index; heading = $heading; headingLevel = $level; class = $class; blocks = $blocks.ToArray(); notes = $notes }
}

function Read-TeachingSlides {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $text = ([System.IO.File]::ReadAllText($Path)) -replace "`r`n", "`n"
    if ($text -notmatch '(?s)^---\n(.*?)\n---\n(.*)$') { throw "Slides '$Path' have no front matter." }
    $frontText = $Matches[1]; $body = $Matches[2]
    $front = @{}
    foreach ($line in ($frontText -split "`n")) {
        if ($line -match '^([A-Za-z_]+):\s*(.*?)\s*$') { $front[$Matches[1]] = $Matches[2].Trim('"', "'") }
    }

    # Split on '---' lines, but never inside a fenced code block.
    $chunks = [System.Collections.Generic.List[string]]::new()
    $current = [System.Collections.Generic.List[string]]::new()
    $inFence = $false
    foreach ($line in ($body -split "`n")) {
        if ($line -match '^```') { $inFence = -not $inFence }
        if (-not $inFence -and $line -eq '---') { $chunks.Add(($current -join "`n")); $current.Clear(); continue }
        $current.Add($line)
    }
    $chunks.Add(($current -join "`n"))

    $slides = [System.Collections.Generic.List[object]]::new()
    foreach ($chunk in $chunks) {
        if ([string]::IsNullOrWhiteSpace($chunk)) { continue }
        $slides.Add((ConvertFrom-SlideChunk -Chunk $chunk -Index $slides.Count))
    }
    [pscustomobject]@{ path = $Path; front = $front; slides = $slides.ToArray() }
}

function Test-TeachingSlides {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Deck,
        [Parameter(Mandatory)][System.Collections.Generic.HashSet[string]]$LessonKeys
    )

    $f = [System.Collections.Generic.List[string]]::new()
    if ($Deck.front['marp'] -ne 'true') { $f.Add('Front matter must set marp: true') }
    if (-not $Deck.front['title']) { $f.Add('Front matter must set a title') }
    $n = @($Deck.slides).Count
    if ($n -lt 10 -or $n -gt 14) { $f.Add("Deck has $n slides; expected 10 to 14") }
    foreach ($s in @($Deck.slides)) {
        $k = $s.index + 1
        if (-not $s.heading) { $f.Add("Slide ${k}: has no heading") }
        $hasBullets = @($s.blocks | Where-Object { $_.type -eq 'bullets' }).Count -gt 0
        $hasPara = @($s.blocks | Where-Object { $_.type -eq 'para' }).Count -gt 0
        if ($s.index -gt 0 -and -not $hasBullets) { $f.Add("Slide ${k}: has no bullet points") }
        if ($s.index -eq 0 -and -not ($hasBullets -or $hasPara)) { $f.Add("Slide ${k}: needs a subtitle or bullet points") }
        # Budget: at most 6 bullets per slide, at most ~30 words per bullet, so
        # text does not clip at a 1280x720 projector size (teaching-aids final
        # fix wave, item 8).
        $bulletIndex = 0
        foreach ($list in @($s.blocks | Where-Object { $_.type -eq 'bullets' })) {
            $items = @($list.items)
            if ($items.Count -gt 6) { $f.Add("Slide ${k}: has $($items.Count) bullets; keep slides to 6 or fewer") }
            foreach ($it in $items) {
                $bulletIndex++
                $words = @($it.text -split '\s+' | Where-Object { $_ })
                if ($words.Count -gt 30) { $f.Add("Slide ${k}: bullet $bulletIndex has $($words.Count) words; keep bullets under 30") }
            }
        }
        foreach ($img in @($s.blocks | Where-Object { $_.type -eq 'image' })) {
            if ($img.src -notmatch '^[A-Za-z0-9._-]+\.(svg|png)$') {
                $f.Add("Slide ${k}: image '$($img.src)' must be a file in the same folder")
            }
        }
        if ($null -eq $s.notes) { $f.Add("Slide ${k}: has no presenter-notes comment starting with **Graphic.**"); continue }
        foreach ($label in $script:NoteLabels) {
            if ($label -eq 'Lessons') { continue }
            if (@($s.notes.seen) -notcontains $label) { $f.Add("Slide ${k}: notes are missing **$label.**") }
        }
        $lessons = @($s.notes.lessons)
        if ($lessons.Count -eq 0) {
            if ($s.index -gt 0 -or -not $s.notes.lessonsNone) { $f.Add("Slide ${k}: cites no lessons") }
        }
        foreach ($key in $lessons) {
            if ($key -notmatch $script:LessonKeyRegex -or -not $LessonKeys.Contains($key)) {
                $f.Add("Slide ${k}: cites unknown lesson '$key'")
            }
        }
    }
    $f.ToArray()
}

$script:BannedMarkupTags = 'iframe', 'object', 'embed', 'base', 'form'
# href/src/xlink:href values must be a bare fragment (#id) or a relative local
# path (optionally with a trailing #fragment); any URI scheme -- javascript:,
# data:, http(s):, in any case -- is rejected because ':' is not in the
# allowed character class. The relative-path branch is anchored so it cannot
# start with '//': without that, a protocol-relative URL like "//evil.example/x"
# would pass, since it contains no ':' either. xmlns / xmlns:xlink namespace
# attributes are not matched by this regex (they are not named href/src/
# xlink:href), so they are implicitly exempt.
$script:SafeMarkupRefRegex = '^(#[\w-]+|(?!//)[A-Za-z0-9._/-]+(#[\w-]+)?)$'
$script:MarkupRefAttrRegex = '(?i)\b(?<attr>href|src|xlink:href)\s*=\s*(?:"(?<dq>[^"]*)"|''(?<sq>[^'']*)''|(?<uq>[^\s"''>]+))'

function Test-TeachingMarkupSafety {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)

    $f = [System.Collections.Generic.List[string]]::new()

    if ($Text -match '(?i)<script') { $f.Add('contains a <script> element') }
    if ($Text -match '(?i)\son[a-z]+\s*=') { $f.Add('contains an on*= event handler attribute') }
    foreach ($tag in $script:BannedMarkupTags) {
        if ($Text -match "(?i)<$tag(\s|>|/)") { $f.Add("contains a banned <$tag> element") }
    }
    if ($Text -match '(?i)<meta\b[^>]*\shttp-equiv\s*=') { $f.Add('contains a banned <meta http-equiv> element') }

    foreach ($m in [regex]::Matches($Text, $script:MarkupRefAttrRegex)) {
        $value = if ($m.Groups['dq'].Success) { $m.Groups['dq'].Value }
                 elseif ($m.Groups['sq'].Success) { $m.Groups['sq'].Value }
                 else { $m.Groups['uq'].Value }
        if ($value -notmatch $script:SafeMarkupRefRegex) {
            $f.Add("disallowed $($m.Groups['attr'].Value) value '$value'")
        }
    }
    $f.ToArray()
}

function ConvertTo-InlineHtml {
    param([AllowEmptyString()][string]$Text)
    $out = [System.Text.StringBuilder]::new()
    # Code spans first, so nothing inside backticks is treated as emphasis or a link.
    foreach ($part in [regex]::Split($Text, '(`[^`]+`)')) {
        if ($part.Length -ge 2 -and $part.StartsWith('`') -and $part.EndsWith('`')) {
            [void]$out.Append('<code>' + [System.Net.WebUtility]::HtmlEncode($part.Substring(1, $part.Length - 2)) + '</code>')
            continue
        }
        $e = [System.Net.WebUtility]::HtmlEncode($part)
        $e = [regex]::Replace($e, '\[([^\]]+)\]\(([^)\s]+)\)', {
            param($m)
            $url = $m.Groups[2].Value
            # Only https:// or same-repo relative links; anything with a scheme
            # (javascript:, data:, http:) is shown as plain text.
            if ($url -match '^https://' -or $url -match '^[A-Za-z0-9._/#-]+$') {
                '<a href="' + $url + '">' + $m.Groups[1].Value + '</a>'
            } else { $m.Groups[1].Value }
        })
        $e = [regex]::Replace($e, '\*\*(.+?)\*\*', '<strong>$1</strong>')
        # Single-asterisk emphasis requires a non-space character on each side of the
        # marker inside the span, and the opening marker must not be immediately
        # followed by '.' -- otherwise a line with two globs on it (e.g. "*.log and
        # *.tmp") gets misread as one emphasis span running between them.
        $e = [regex]::Replace($e, '(?<![*\w])\*(?!\.)(\S(?:[^*]*?\S)?)\*(?![*\w])', '<em>$1</em>')
        [void]$out.Append($e)
    }
    $out.ToString()
}

function Get-TeachingDeckCss {
@'
:root{--bg:#f4f1ea;--card:#fffdf8;--ink:#1b2230;--muted:#5d6676;--accent:#d9480f;--accent-2:#1971c2;--rule:#e4ddd0;--code-bg:#1b2230;--code-ink:#f1f3f5;--shadow:0 18px 50px rgba(27,34,48,.14)}
@media (prefers-color-scheme:dark){:root{--bg:#0f131a;--card:#171d27;--ink:#e9edf2;--muted:#9aa5b4;--accent:#ff8a3d;--accent-2:#5aa9ff;--rule:#283141;--code-bg:#0a0d12;--code-ink:#e9edf2;--shadow:0 18px 50px rgba(0,0,0,.45)}}
*{box-sizing:border-box}
html{scroll-snap-type:y mandatory;background:var(--bg)}
body{margin:0;color:var(--ink);font-family:system-ui,-apple-system,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif;line-height:1.45}
.slide{scroll-snap-align:start;min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:3vh 3vw}
.frame{position:relative;width:min(94vw,calc(84vh*16/9));aspect-ratio:16/9;background:radial-gradient(135% 110% at 100% 0%,color-mix(in srgb,var(--accent-2) 7%,var(--card)) 0%,var(--card) 55%),var(--card);border-radius:20px;box-shadow:var(--shadow);padding:4.5% 6% 5%;overflow:hidden;font-size:clamp(13px,1.9vw,30px);display:flex;flex-direction:column;justify-content:safe center;gap:.4em}
.frame::before{content:"";position:absolute;inset:0 0 auto 0;height:.45em;background:linear-gradient(90deg,var(--accent),var(--accent-2))}
.frame::after{content:"";position:absolute;right:-12%;bottom:-18%;width:46%;aspect-ratio:1;border-radius:50%;background:radial-gradient(closest-side,color-mix(in srgb,var(--accent) 9%,transparent),transparent 72%);pointer-events:none}
.kicker{font-size:.55em;letter-spacing:.14em;text-transform:uppercase;color:var(--muted);margin:0}
h1,h2{margin:0;line-height:1.08;letter-spacing:-.015em;font-size:1.85em}
.lead .frame,.slide:first-child .frame{justify-content:safe center;background:radial-gradient(120% 140% at 0% 0%,color-mix(in srgb,var(--accent) 16%,var(--card)) 0%,var(--card) 55%)}
.lead h1,.slide:first-child h1{font-size:2.6em}
.subtitle{font-size:1.1em;color:var(--muted);margin:0;max-width:30em}
ul{margin:0;padding-left:1.15em}
li{margin:.28em 0}
li::marker{color:var(--accent)}
li ul{font-size:.82em;color:var(--muted);margin-top:.15em}
p{margin:.4em 0}
code{font-family:ui-monospace,"Cascadia Code","SF Mono",Consolas,monospace;font-size:.9em;background:color-mix(in srgb,var(--accent-2) 14%,transparent);padding:.05em .3em;border-radius:.3em}
pre{margin:0;background:var(--code-bg);color:var(--code-ink);padding:.7em 1em;border-radius:12px;font-size:.68em;line-height:1.5;overflow:auto}
pre code{background:none;padding:0;font-size:1em}
.visual{flex:1;min-height:0;display:flex;align-items:center;justify-content:center}
.visual img{max-width:100%;max-height:100%;object-fit:contain}
a{color:var(--accent-2)}
.num{position:absolute;right:3.2%;bottom:3.4%;font-size:.5em;color:var(--muted);font-variant-numeric:tabular-nums}
.notes{width:min(94vw,calc(84vh*16/9));margin-top:1.4vh;background:var(--card);border:1px solid var(--rule);border-radius:14px;padding:.55em 1.1em;font-size:15px}
.notes summary{cursor:pointer;font-weight:650;color:var(--accent-2)}
.notes .short{font-size:1.05em}
.notes .deep{margin:.4em 0;padding-left:.8em;border-left:3px solid var(--rule)}
.notes .graphic{color:var(--muted)}
.notes .lessons{margin:.3em 0 .2em;padding-left:1.1em}
.notes .lessons span{color:var(--muted);font-size:.85em}
@media print{html{scroll-snap-type:none;background:#fff}.notes{display:none}.slide{min-height:0;padding:0;break-after:page}.frame{width:100%;box-shadow:none;border:1px solid #ccc}@page{size:landscape;margin:8mm}}
'@
}

function ConvertTo-TeachingDeckHtml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Deck,
        [Parameter(Mandatory)][hashtable]$LessonTitles
    )

    $enc = { param($s) [System.Net.WebUtility]::HtmlEncode([string]$s) }
    $title = & $enc $Deck.front['title']
    $n = @($Deck.slides).Count
    $L = [System.Collections.Generic.List[string]]::new()
    $L.Add('<!doctype html>')
    $L.Add('<html lang="en">')
    $L.Add('<head>')
    $L.Add('<meta charset="utf-8">')
    $L.Add('<meta name="viewport" content="width=device-width, initial-scale=1">')
    $L.Add("<title>$title</title>")
    $L.Add('<style>')
    $L.Add((Get-TeachingDeckCss).TrimEnd())
    $L.Add('</style>')
    $L.Add('</head>')
    $L.Add('<body>')
    $L.Add('<main class="deck">')
    foreach ($s in @($Deck.slides)) {
        $k = $s.index + 1
        $cls = 'slide'
        if ($s.class) { $cls += ' ' + (& $enc $s.class) }
        $L.Add("<section class=""$cls"" id=""s$k"" aria-label=""Slide $k of $n"">")
        $L.Add('<div class="frame">')
        if ($s.index -gt 0) { $L.Add("<p class=""kicker"">$title</p>") }
        $tag = if ($s.headingLevel -eq 2) { 'h2' } else { 'h1' }
        if ($s.heading) { $L.Add("<$tag>$(ConvertTo-InlineHtml $s.heading)</$tag>") }
        foreach ($b in @($s.blocks)) {
            switch ($b.type) {
                'bullets' {
                    $L.Add('<ul>')
                    foreach ($it in @($b.items)) {
                        $kids = @($it.children)
                        if ($kids.Count -eq 0) { $L.Add("<li>$(ConvertTo-InlineHtml $it.text)</li>"); continue }
                        $L.Add("<li>$(ConvertTo-InlineHtml $it.text)<ul>")
                        foreach ($c in $kids) { $L.Add("<li>$(ConvertTo-InlineHtml $c)</li>") }
                        $L.Add('</ul></li>')
                    }
                    $L.Add('</ul>')
                }
                'para' {
                    $pc = if ($s.index -eq 0) { ' class="subtitle"' } else { '' }
                    $L.Add("<p$pc>$(ConvertTo-InlineHtml $b.text)</p>")
                }
                'code' { $L.Add('<pre><code>' + (& $enc $b.text) + '</code></pre>') }
                'image' {
                    $L.Add('<div class="visual"><img src="' + (& $enc $b.src) + '" alt="' + (& $enc $b.alt) + '"></div>')
                }
            }
        }
        $L.Add("<p class=""num"">$k / $n</p>")
        $L.Add('</div>')
        if ($null -ne $s.notes) {
            $L.Add('<details class="notes">')
            $L.Add('<summary>Presenter notes</summary>')
            $L.Add("<p class=""short"">$(ConvertTo-InlineHtml $s.notes.short)</p>")
            $L.Add('<details class="deep">')
            $L.Add('<summary>Deeper notes</summary>')
            $L.Add("<p>$(ConvertTo-InlineHtml $s.notes.deep)</p>")
            $L.Add('</details>')
            $L.Add("<p class=""graphic""><strong>Suggested graphic:</strong> $(ConvertTo-InlineHtml $s.notes.graphic)</p>")
            $lessons = @($s.notes.lessons)
            if ($lessons.Count -gt 0) {
                $L.Add('<ul class="lessons">')
                foreach ($key in $lessons) {
                    $mod, $id = $key -split '/', 2
                    $t = if ($LessonTitles.ContainsKey($key)) { $LessonTitles[$key] } else { $key }
                    $href = '../../../' + (& $enc $mod) + '/capabilities/' + (& $enc $id) + '.md'
                    $L.Add("<li><a href=""$href"">$(& $enc $t)</a> <span>($(& $enc $key))</span></li>")
                }
                $L.Add('</ul>')
            }
            $L.Add('</details>')
        }
        $L.Add('</section>')
    }
    $L.Add('</main>')
    $L.Add('</body>')
    $L.Add('</html>')
    ($L -join "`n") + "`n"
}
