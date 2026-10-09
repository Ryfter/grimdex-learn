# Lesson surfacing CLI (lesson-surfacing design §3 C.3-C.4, §4). Run from the
# grimdex-edu checkout against a student's install. Reads transcripts post hoc,
# counts 'Learn: <module-id>/<lesson-id>' markers (one per lesson per transcript),
# recomputes the mastery level, and re-renders the pointer stanza. Writes only
# learn-progress/surfacing.json and the grimdex-learn stanza block.
# Exit codes: 0 ok, 1 bad input (nothing written), 2 cannot read install state
# or cannot update the stanza.
[CmdletBinding(DefaultParameterSetName = 'Record')]
param(
    [Parameter(Mandatory)][string]$InstallRoot,
    [Parameter(ParameterSetName = 'Record')][string[]]$TranscriptPath = @(),
    [Parameter(ParameterSetName = 'Suppress', Mandatory)][string]$Suppress,
    [Parameter(ParameterSetName = 'Unsuppress', Mandatory)][string]$Unsuppress,
    [ValidateRange(1, 1000)][int]$PromotionThreshold = 10
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'manifest-lib.ps1')
. (Join-Path $PSScriptRoot 'stanza-lib.ps1')
. (Join-Path $PSScriptRoot 'learn-index-lib.ps1')
. (Join-Path $PSScriptRoot 'surfacing-lib.ps1')

try {
    $manifest = Read-LearnManifest -Path (Join-Path $InstallRoot 'learn' 'manifest.json')
    $index    = Read-LearnIndex -Path (Join-Path $InstallRoot 'learn' 'index.json')
    $ledger   = Read-SurfacingLedger -InstallRoot $InstallRoot
} catch {
    Write-Host "ERROR: cannot read the Learn install at '$InstallRoot' ($($_.Exception.Message))."
    exit 2
}

# `pwsh -File script.ps1 -TranscriptPath a.jsonl,b.jsonl` hands the whole
# comma-joined text to the host as ONE argument; PowerShell only splits a
# comma-literal into an array when the engine itself parses the call (e.g. from
# inside a script), never for a raw external invocation. Split every element on
# ',' ourselves so both invocation styles work the same way.
$TranscriptPath = @($TranscriptPath | ForEach-Object { $_ -split ',' } |
    ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })

# Resolve every input before changing anything, so bad input writes nothing.
# Non-recursive on purpose: a Claude Code project folder's subagents/ subfolder
# holds turns the student never saw, and those must never be scanned.
$transcriptExtensions = @('.jsonl', '.md', '.txt', '.log')
$files = [System.Collections.Generic.List[string]]::new()
foreach ($t in $TranscriptPath) {
    if (Test-Path -LiteralPath $t -PathType Container) {
        $inDir = @(Get-ChildItem -LiteralPath $t -File |
            Where-Object { $transcriptExtensions -contains $_.Extension.ToLowerInvariant() } |
            ForEach-Object { $_.FullName })
        if ($inDir.Count -eq 0) {
            Write-Host "WARNING: no transcript files (.jsonl/.md/.txt/.log) found in '$t'. Claude Code keeps one transcript folder per project under ~/.claude/projects/ - point -TranscriptPath at that project's folder (not a parent or a subagents/ subfolder)."
        }
        [Array]::Sort($inDir, [System.StringComparer]::Ordinal)
        foreach ($f in $inDir) { $files.Add($f) }
    } elseif (Test-Path -LiteralPath $t -PathType Leaf) {
        $files.Add((Resolve-Path -LiteralPath $t).Path)
    } else {
        Write-Host "ERROR: transcript not found: $t"
        exit 1
    }
}

try {
    if ($PSCmdlet.ParameterSetName -eq 'Suppress') {
        Set-LessonSuppression -Ledger $ledger -Index $index -Lesson $Suppress -Suppressed $true
        Write-Host "Suppressed $Suppress."
    } elseif ($PSCmdlet.ParameterSetName -eq 'Unsuppress') {
        Set-LessonSuppression -Ledger $ledger -Index $index -Lesson $Unsuppress -Suppressed $false
        Write-Host "Unsuppressed $Unsuppress."
    }
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    exit 1
}

foreach ($f in $files) {
    $r = Add-TranscriptExposures -Ledger $ledger -Index $index -TranscriptPath $f
    $line = "$($r.transcript): $(@($r.added).Count) new lesson exposure(s)"
    if (@($r.unknown).Count -gt 0) { $line += "; ignored unknown marker(s): $(@($r.unknown) -join ', ')" }
    if ([int]$r.unrecognized -gt 0) { $line += "; $($r.unrecognized) Learn: line(s) not recognised" }
    Write-Host $line
    if ($null -ne $r.assistantEvents -and [int]$r.assistantEvents -eq 0) {
        Write-Host "WARNING: '$($r.transcript)' is a .jsonl file but has no Claude Code assistant text events; it may not be a Claude Code transcript, or the transcript format changed."
    }
}

$before = [int]$ledger.level
$after  = Update-MasteryLevel -Ledger $ledger -Index $index -Threshold $PromotionThreshold
Save-SurfacingLedger -InstallRoot $InstallRoot -Ledger $ledger

$summary = Get-SurfacingSummary -Ledger $ledger -Index $index -Threshold $PromotionThreshold
if ($after -gt $before) { Write-Host "PROMOTED: level $before -> level $after." }
Write-Host "Level: $($summary.level) of $($summary.maxLevel) ($($summary.levelName)). Lessons at this level seen $PromotionThreshold+ times: $($summary.atThreshold) of $($summary.levelTotal)."

$content = Get-LearnStanzaContent -Manifest $manifest -Surfacing $summary
$stanzaFailed = $false
foreach ($s in @($manifest.pointerStanzas)) {
    $target = Join-Path $InstallRoot ($s.file -replace '\\', '/')
    try {
        $applied = Set-PointerStanza -Path $target -Content $content
        Write-Host "Pointer stanza in $($s.file): $($applied.action)."
    } catch {
        Write-Host "WARNING: the ledger was saved, but the pointer stanza in $($s.file) could not be updated ($($_.Exception.Message))."
        $stanzaFailed = $true
    }
}
if ($stanzaFailed) { exit 2 }
exit 0
