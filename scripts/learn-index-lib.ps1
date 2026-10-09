Set-StrictMode -Version 3.0

# learn-index-lib.ps1 - builds and reads learn/index.json, the lesson index the
# pointer stanza tells the agent to consult (lesson-surfacing design §3 C.1).
# Local files only: no network, no content mutation.

function Get-LessonKey {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Lesson)
    "$($Lesson.module)/$($Lesson.id)"
}

function Get-PageIndexFields {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $text = [string](Get-Content -LiteralPath $Path -Raw)
    if ($text -notmatch '(?s)^---\r?\n(.*?)\r?\n---(\r?\n|$)') {
        throw "Page '$Path' has no front matter."
    }
    $title = $null; $moduleId = $null; $level = $null
    $caps = [System.Collections.Generic.List[string]]::new()
    $inCaps = $false
    foreach ($line in ($Matches[1] -split '\r?\n')) {
        if ($inCaps) {
            if ($line -match '^\s+-\s+(\S+)\s*$') { $caps.Add($Matches[1]); continue }
            $inCaps = $false
        }
        if ($line -match '^title:\s*(.*?)\s*$') {
            $title = $Matches[1]
            # Titles containing ': ' are quoted (plain YAML would be invalid).
            if ($title -match '^"(.*)"$')     { $title = $Matches[1] -replace '\\"', '"' }
            elseif ($title -match "^'(.*)'$") { $title = $Matches[1] -replace "''", "'" }
        }
        elseif ($line -match '^module_id:\s*(\S+)\s*$') { $moduleId = $Matches[1] }
        elseif ($line -match '^level:\s*(\d+)\s*$')     { $level = [int]$Matches[1] }
        elseif ($line -match '^capabilities:\s*$')      { $inCaps = $true }
    }
    if ([string]::IsNullOrWhiteSpace($title)) { throw "Page '$Path' has no title." }
    if (-not $moduleId)                       { throw "Page '$Path' has no module_id." }
    if ($null -eq $level -or $level -lt 1 -or $level -gt 7) {
        throw "Page '$Path' has no level between 1 and 7."
    }
    [pscustomobject]@{ title = $title; moduleId = $moduleId; level = $level; capabilities = $caps.ToArray() }
}

function New-LearnIndex {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$RepoRoot)

    $lessons = [System.Collections.Generic.List[object]]::new()
    foreach ($modDir in (Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'learn') -Directory)) {
        $capDir = Join-Path $modDir.FullName 'capabilities'
        if (-not (Test-Path -LiteralPath $capDir)) { continue }
        foreach ($page in (Get-ChildItem -LiteralPath $capDir -Filter '*.md' -File)) {
            $f = Get-PageIndexFields -Path $page.FullName
            if ($f.moduleId -ne $modDir.Name) {
                throw "Page '$($page.FullName)' declares module_id '$($f.moduleId)' but lives in '$($modDir.Name)'."
            }
            $lessons.Add([ordered]@{
                id           = $page.BaseName
                module       = $modDir.Name
                title        = $f.title
                level        = $f.level
                capabilities = [string[]]$f.capabilities
                path         = "learn/$($modDir.Name)/capabilities/$($page.Name)"
            })
        }
    }
    # Ordinal, never culture-aware: culture comparers can ignore hyphens, which
    # would make the committed index differ between machines.
    $lessons.Sort([System.Comparison[object]] {
        param($a, $b) [string]::CompareOrdinal("$($a.module)/$($a.id)", "$($b.module)/$($b.id)")
    })
    [ordered]@{ schemaVersion = 1; lessons = $lessons.ToArray() }
}

function ConvertTo-LearnIndexJson {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Index)
    # ConvertTo-Json uses the platform newline; the committed file must be
    # byte-identical on Windows and macOS.
    (($Index | ConvertTo-Json -Depth 6) -replace "`r`n", "`n") + "`n"
}

function Read-LearnIndex {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { throw "Lesson index not found: $Path" }
    try {
        $index = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -AsHashtable -Depth 10
    } catch {
        throw "Lesson index is not valid JSON: $($_.Exception.Message)"
    }
    if ($index['schemaVersion'] -ne 1) { throw "Unsupported lesson index schemaVersion '$($index['schemaVersion'])'." }
    if ($null -eq $index['lessons'])   { throw 'Lesson index has no lessons array.' }
    $index
}
