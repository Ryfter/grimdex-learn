Set-StrictMode -Version 3.0

# surfacing-lib.ps1 - the post-hoc lesson ledger, mastery levels and suppression
# (lesson-surfacing design §3 C.3-C.4 and §4; mastery-levels design §4 and
# decision 4). Deterministic: no model, no network. The only file it writes is
# learn-progress/surfacing.json under the install root.
# Requires learn-index-lib.ps1 to be dot-sourced first.

$script:LedgerRelPath = 'learn-progress/surfacing.json'
$script:MaxLevel = 7
$script:LevelNames = @{
    1 = 'Prompt Novice'; 2 = 'Conversational Collaborator'; 3 = 'Task Delegator'
    4 = 'Systematic Context Engineer'; 5 = 'Multi-Agent Orchestrator'
    6 = 'Harness Engineer'; 7 = 'Autonomous Systems Architect'
}
# The marker on its own line. A leading '>' / list bullet, surrounding *,_,**,__,
# or backticks, a trailing '.', ',', ';' or ')', a markdown link, and a
# comma-separated list of ids are all tolerated because agents format the marker
# in different ways; mid-sentence mentions never count (see Get-TextLessonMarkers,
# which replaced one giant regex with a per-line normalise-then-extract pass for
# clarity).
$script:LessonIdPattern = '[a-z0-9][a-z0-9-]*'
$script:LessonKeyPattern = "^(${script:LessonIdPattern})/(${script:LessonIdPattern})$"

function New-EmptySurfacingLedger {
    @{ schemaVersion = 1; level = 1; counts = @{}; transcripts = @{}; suppressed = @() }
}

function Get-SurfacingLedgerPath {
    param([Parameter(Mandatory)][string]$InstallRoot)
    Join-Path $InstallRoot $script:LedgerRelPath
}

function Read-SurfacingLedger {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$InstallRoot)

    $path = Get-SurfacingLedgerPath -InstallRoot $InstallRoot
    if (-not (Test-Path -LiteralPath $path)) { return (New-EmptySurfacingLedger) }
    try {
        $raw = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json -AsHashtable -Depth 10
    } catch {
        throw "Surfacing ledger '$path' is not valid JSON: $($_.Exception.Message)"
    }
    if ($raw['schemaVersion'] -ne 1) { throw "Unsupported surfacing ledger schemaVersion '$($raw['schemaVersion'])'." }
    $ledger = New-EmptySurfacingLedger
    if ($null -ne $raw['level'])       { $ledger.level = [int]$raw['level'] }
    if ($null -ne $raw['counts'])      { foreach ($k in $raw['counts'].Keys) { $ledger.counts[$k] = [int]$raw['counts'][$k] } }
    if ($null -ne $raw['transcripts']) { foreach ($k in $raw['transcripts'].Keys) { $ledger.transcripts[$k] = [string[]]@($raw['transcripts'][$k]) } }
    if ($null -ne $raw['suppressed'])  { $ledger.suppressed = [string[]]@($raw['suppressed']) }
    $ledger
}

function Get-SortedKeys {
    param($Dictionary)
    $keys = [string[]]@($Dictionary.Keys)
    [Array]::Sort($keys, [System.StringComparer]::Ordinal)
    ,$keys
}

function Save-SurfacingLedger {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)][hashtable]$Ledger
    )

    $counts = [ordered]@{}
    foreach ($k in (Get-SortedKeys $Ledger.counts)) { $counts[$k] = [int]$Ledger.counts[$k] }
    $transcripts = [ordered]@{}
    foreach ($k in (Get-SortedKeys $Ledger.transcripts)) {
        $v = [string[]]@($Ledger.transcripts[$k]); [Array]::Sort($v, [System.StringComparer]::Ordinal)
        $transcripts[$k] = $v
    }
    $suppressed = [string[]]@($Ledger.suppressed); [Array]::Sort($suppressed, [System.StringComparer]::Ordinal)
    $doc = [ordered]@{
        schemaVersion = 1
        level         = [int]$Ledger.level
        counts        = $counts
        transcripts   = $transcripts
        suppressed    = $suppressed
    }
    $json = (($doc | ConvertTo-Json -Depth 6) -replace "`r`n", "`n") + "`n"

    $path = Get-SurfacingLedgerPath -InstallRoot $InstallRoot
    $dir  = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    # Write-then-rename: a crash mid-write leaves the previous ledger intact.
    $tmp = "$path.tmp"
    [System.IO.File]::WriteAllText($tmp, $json, [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::Move($tmp, $path, $true)
}

function Get-TranscriptTextBlocks {
    param([Parameter(Mandatory)][string]$Path)

    if ([System.IO.Path]::GetExtension($Path) -ne '.jsonl') {
        # Deliberately not comma-protected: every caller either pipes this
        # (Pester's -Be, foreach) or wraps it in @() itself, both of which
        # unroll correctly; a comma-wrapped single-element array instead
        # travels as one object through a pipe, breaking those comparisons.
        return @([System.IO.File]::ReadAllText($Path))
    }
    # Claude Code JSONL: one event per line. Only the assistant's visible text
    # counts: user text, thinking, tool calls and subagent (sidechain) turns are
    # not something the student was shown.
    $blocks = [System.Collections.Generic.List[string]]::new()
    foreach ($line in [System.IO.File]::ReadLines($Path)) {
        # Cheap pre-filter: transcripts are large and most lines hold no marker.
        if ($line.IndexOf('Learn:', [System.StringComparison]::Ordinal) -lt 0) { continue }
        try { $evt = $line | ConvertFrom-Json -AsHashtable -Depth 20 } catch { continue }
        if ($evt -isnot [System.Collections.IDictionary]) { continue }
        if ($evt['type'] -ne 'assistant' -or $evt['isSidechain'] -eq $true) { continue }
        $msg = $evt['message']
        if ($msg -isnot [System.Collections.IDictionary]) { continue }
        $content = $msg['content']
        if ($content -is [string]) { $blocks.Add($content); continue }
        foreach ($c in @($content)) {
            if ($c -is [System.Collections.IDictionary] -and $c['type'] -eq 'text' -and $c['text'] -is [string]) {
                $blocks.Add($c['text'])
            }
        }
    }
    $blocks.ToArray()
}

function Get-TextLessonMarkers {
    # Scans one text blob line by line for 'Learn:' marker lines. A line counts as
    # a marker *candidate* only when, after stripping an optional leading list
    # bullet (-, *, + followed by whitespace) and/or blockquote '>', and an
    # optional whole-line backtick wrap, it STARTS with 'Learn:' (itself optionally
    # wrapped in *, _, ** or __). That anchor is what keeps a mid-sentence mention
    # ("See Learn: m/a1 for more.") from ever matching: such a line does not start
    # with the label at all. A candidate line that parses to zero valid ids is
    # still a candidate - it is reported via $unrecognized, not silently dropped.
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)

    $ids = [System.Collections.Generic.List[string]]::new()
    $unrecognized = 0
    foreach ($rawLine in ($Text -split "`n")) {
        $work = $rawLine.TrimEnd("`r").Trim()
        if ($work -eq '') { continue }

        # Strip a leading list bullet and/or blockquote marker (either order).
        $changed = $true
        while ($changed) {
            $changed = $false
            if ($work -match '^[-*+][ \t]+(.*)$') { $work = $Matches[1]; $changed = $true; continue }
            if ($work -match '^>[ \t]*(.*)$')     { $work = $Matches[1]; $changed = $true; continue }
        }

        # A whole line wrapped in a single pair of backticks, e.g. `Learn: m/id`.
        if ($work.Length -ge 2 -and $work[0] -eq '`' -and $work[-1] -eq '`') {
            $work = $work.Substring(1, $work.Length - 2)
        }

        # The line must START with 'Learn:', optionally wrapped in emphasis
        # (**Learn:**, __Learn:__) - this is the anchor that excludes mid-sentence use.
        if ($work -notmatch '^(?:\*\*|__|\*|_)?Learn:(?:\*\*|__)?[ \t]*(.*)$') { continue }
        $rest = $Matches[1].Trim()
        # A trailing emphasis run left over from wrapping the whole phrase, e.g.
        # "*Learn: m/id*" (the leading '*' was already consumed above).
        $rest = ($rest -replace '[*_]+$', '').Trim()

        $candidates = [System.Collections.Generic.List[string]]::new()
        $link = [regex]::Match($rest, '^\[([^\]]+)\]\([^)]*\)$')
        if ($link.Success) {
            $candidates.Add($link.Groups[1].Value.Trim())
        } else {
            # A single trailing sentence-punctuation character.
            $rest = $rest -replace '[.,;)]$', ''
            # The whole remainder wrapped in one pair of backticks, e.g. `m/id`.
            # Only for a single id - a comma-separated list is split first below.
            if ($rest -notmatch ',' -and $rest.Length -ge 2 -and $rest[0] -eq '`' -and $rest[-1] -eq '`') {
                $rest = $rest.Substring(1, $rest.Length - 2)
            }
            foreach ($part in ($rest -split ',')) {
                $t = $part.Trim().Trim('`', '*', '_')
                if ($t -ne '') { $candidates.Add($t) }
            }
        }

        $any = $false
        foreach ($c in $candidates) {
            if ($c -match $script:LessonKeyPattern) {
                $ids.Add("$($Matches[1])/$($Matches[2])")
                $any = $true
            }
        }
        if (-not $any) { $unrecognized++ }
    }
    [pscustomobject]@{ ids = $ids.ToArray(); unrecognized = $unrecognized }
}

function Get-TranscriptMarkerScan {
    # Per-transcript scan: markers deduplicated in first-seen order (across every
    # text block), unrecognized counted raw (not deduplicated - each bad line is
    # its own reportable event).
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $seen = [System.Collections.Generic.List[string]]::new()
    $unrecognized = 0
    foreach ($text in (Get-TranscriptTextBlocks -Path $Path)) {
        $scan = Get-TextLessonMarkers -Text $text
        foreach ($id in $scan.ids) { if (-not $seen.Contains($id)) { $seen.Add($id) } }
        $unrecognized += $scan.unrecognized
    }
    [pscustomobject]@{ markers = $seen.ToArray(); unrecognized = $unrecognized }
}

function Get-TranscriptLessonMarkers {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    # Deliberately not comma-protected: callers pipe this directly into
    # Should -Be or wrap it in @() (see Get-TranscriptTextBlocks above for why).
    (Get-TranscriptMarkerScan -Path $Path).markers
}

function Get-TranscriptAssistantEventCount {
    # Total count of Claude Code assistant (non-sidechain) events that carry
    # visible text, regardless of whether any mention 'Learn:'. Only meaningful
    # for .jsonl transcripts; used to tell "this transcript has 0 lesson citations"
    # apart from "this file is not a Claude Code transcript at all" (surfacing
    # design §3 C.4 / 2026-09-26 final review finding 4b).
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $count = 0
    foreach ($line in [System.IO.File]::ReadLines($Path)) {
        try { $evt = $line | ConvertFrom-Json -AsHashtable -Depth 20 } catch { continue }
        if ($evt -isnot [System.Collections.IDictionary]) { continue }
        if ($evt['type'] -ne 'assistant' -or $evt['isSidechain'] -eq $true) { continue }
        $msg = $evt['message']
        if ($msg -isnot [System.Collections.IDictionary]) { continue }
        $content = $msg['content']
        if ($content -is [string]) {
            if ($content -ne '') { $count++ }
            continue
        }
        $hasText = $false
        foreach ($c in @($content)) {
            if ($c -is [System.Collections.IDictionary] -and $c['type'] -eq 'text' -and $c['text'] -is [string]) {
                $hasText = $true
                break
            }
        }
        if ($hasText) { $count++ }
    }
    $count
}

function Get-IndexLessonKeys {
    param([Parameter(Mandatory)]$Index)
    $set = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($l in @($Index.lessons)) { [void]$set.Add((Get-LessonKey -Lesson $l)) }
    ,$set
}

function Add-TranscriptExposures {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Ledger,
        [Parameter(Mandatory)]$Index,
        [Parameter(Mandatory)][string]$TranscriptPath
    )

    # Keyed by file name: a transcript re-read after it grew (a live or resumed
    # session) only adds lessons it had not already contributed.
    $key = [System.IO.Path]::GetFileName($TranscriptPath)
    $known = Get-IndexLessonKeys -Index $Index
    $already = [System.Collections.Generic.List[string]]::new()
    if ($Ledger.transcripts.ContainsKey($key)) { foreach ($x in @($Ledger.transcripts[$key])) { $already.Add($x) } }

    $added = [System.Collections.Generic.List[string]]::new()
    $unknown = [System.Collections.Generic.List[string]]::new()
    $scan = Get-TranscriptMarkerScan -Path $TranscriptPath
    foreach ($marker in $scan.markers) {
        if (-not $known.Contains($marker)) { $unknown.Add($marker); continue }
        if ($already.Contains($marker)) { continue }
        $Ledger.counts[$marker] = 1 + [int]$Ledger.counts[$marker]
        $already.Add($marker)
        $added.Add($marker)
    }
    if ($already.Count -gt 0) { $Ledger.transcripts[$key] = $already.ToArray() }

    # Only .jsonl has a notion of "assistant events" to count; $null for other
    # transcript formats means the question does not apply, not that it is zero.
    $assistantEvents = $null
    if ([System.IO.Path]::GetExtension($TranscriptPath) -eq '.jsonl') {
        $assistantEvents = Get-TranscriptAssistantEventCount -Path $TranscriptPath
    }
    [pscustomobject]@{
        transcript       = $key
        added            = $added.ToArray()
        unknown          = $unknown.ToArray()
        unrecognized     = $scan.unrecognized
        assistantEvents  = $assistantEvents
    }
}

function Get-LevelLessonKeys {
    param([Parameter(Mandatory)]$Index, [Parameter(Mandatory)][int]$Level, [string[]]$Suppressed = @())
    # Comma-protected: every call site does a bare `$keys = Get-LevelLessonKeys
    # ...` assignment (not a pipe), and Get-SurfacingSummary reads $keys.Count
    # directly, so a 0- or 1-match result must stay an array, never $null or a
    # bare string.
    ,@(@($Index.lessons) | Where-Object { [int]$_.level -eq $Level } |
        ForEach-Object { Get-LessonKey -Lesson $_ } | Where-Object { $Suppressed -notcontains $_ })
}

function Update-MasteryLevel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Ledger,
        [Parameter(Mandatory)]$Index,
        [int]$Threshold = 10
    )

    # Sticky: start from the stored level and only climb. Unsuppressing a
    # low-count lesson later must not demote the student.
    $level = [Math]::Min([Math]::Max([int]$Ledger.level, 1), $script:MaxLevel)
    while ($level -lt $script:MaxLevel) {
        $keys = Get-LevelLessonKeys -Index $Index -Level $level -Suppressed @($Ledger.suppressed)
        $short = @($keys | Where-Object { [int]$Ledger.counts[$_] -lt $Threshold })
        if ($short.Count -gt 0) { break }
        $level++
    }
    $Ledger.level = $level
    $level
}

function Get-LevelWeights {
    [CmdletBinding()]
    param([Parameter(Mandatory)][int]$Level)
    # Mastery decision 4: halve per level below the current one, floor 5%.
    foreach ($i in $Level..1) {
        [pscustomobject]@{
            level   = $i
            percent = [int][Math]::Max(5, [Math]::Floor(100 / [Math]::Pow(2, $Level - $i)))
        }
    }
}

function Get-SurfacingSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Ledger,
        [Parameter(Mandatory)]$Index,
        [int]$Threshold = 10
    )

    $level = [Math]::Min([Math]::Max([int]$Ledger.level, 1), $script:MaxLevel)
    $keys = Get-LevelLessonKeys -Index $Index -Level $level -Suppressed @($Ledger.suppressed)
    $suppressed = [string[]]@($Ledger.suppressed); [Array]::Sort($suppressed, [System.StringComparer]::Ordinal)
    [pscustomobject]@{
        level       = $level
        levelName   = $script:LevelNames[$level]
        maxLevel    = $script:MaxLevel
        weights     = @(Get-LevelWeights -Level $level)
        suppressed  = $suppressed
        atThreshold = @($keys | Where-Object { [int]$Ledger.counts[$_] -ge $Threshold }).Count
        levelTotal  = $keys.Count
    }
}

function Set-LessonSuppression {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Ledger,
        [Parameter(Mandatory)]$Index,
        [Parameter(Mandatory)][string]$Lesson,
        [Parameter(Mandatory)][bool]$Suppressed
    )

    if (-not (Get-IndexLessonKeys -Index $Index).Contains($Lesson)) {
        throw "Unknown lesson '$Lesson'. Use <module-id>/<lesson-id> as listed in learn/index.json."
    }
    $set = [System.Collections.Generic.SortedSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($s in @($Ledger.suppressed)) { [void]$set.Add($s) }
    if ($Suppressed) { [void]$set.Add($Lesson) } else { [void]$set.Remove($Lesson) }
    $Ledger.suppressed = [string[]]@($set)
}
