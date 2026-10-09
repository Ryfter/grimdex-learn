# Builds learn/teaching/workflows/*/deck.html from each slides.md (teaching-aids
# design §6). Run after editing a slides.md.
# Exit codes: 0 written or current, 1 -Check found a stale deck, 2 a deck failed to
# parse or broke the slide contract (nothing is written for that deck).
[CmdletBinding()]
param(
    [string]$RepoRoot = (Join-Path $PSScriptRoot '..'),
    [switch]$Check
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'learn-index-lib.ps1')
. (Join-Path $PSScriptRoot 'teaching-lib.ps1')

try {
    $index = Read-LearnIndex -Path (Join-Path $RepoRoot 'learn' 'index.json')
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    exit 2
}
$keys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
$titles = @{}
foreach ($l in @($index.lessons)) {
    $key = Get-LessonKey -Lesson $l
    [void]$keys.Add($key)
    $titles[$key] = [string]$l.title
}

$root = Join-Path $RepoRoot 'learn' 'teaching' 'workflows'
if (-not (Test-Path -LiteralPath $root)) { Write-Host 'No teaching workflows found.'; exit 0 }
$dirs = [string[]]@(Get-ChildItem -LiteralPath $root -Directory | ForEach-Object { $_.FullName })
[Array]::Sort($dirs, [System.StringComparer]::Ordinal)

$bad = $false
$stale = [System.Collections.Generic.List[string]]::new()
foreach ($dir in $dirs) {
    $name = Split-Path -Leaf $dir
    $slidesPath = Join-Path $dir 'slides.md'
    if (-not (Test-Path -LiteralPath $slidesPath)) { continue }
    try {
        $deck = Read-TeachingSlides -Path $slidesPath
    } catch {
        Write-Host "ERROR: ${name}: $($_.Exception.Message)"
        $bad = $true
        continue
    }
    $failures = @(Test-TeachingSlides -Deck $deck -LessonKeys $keys)
    if ($failures.Count -gt 0) {
        foreach ($f in $failures) { Write-Host "ERROR: ${name}: $f" }
        $bad = $true
        continue
    }
    $html = ConvertTo-TeachingDeckHtml -Deck $deck -LessonTitles $titles
    $out = Join-Path $dir 'deck.html'
    $current = $null
    if (Test-Path -LiteralPath $out) { $current = ([System.IO.File]::ReadAllText($out)) -replace "`r`n", "`n" }
    if ($Check) {
        if ($current -cne $html) { $stale.Add($name) }
        continue
    }
    if ($current -cne $html) {
        [System.IO.File]::WriteAllText($out, $html, [System.Text.UTF8Encoding]::new($false))
        Write-Host "Wrote $name/deck.html ($(@($deck.slides).Count) slides)."
    } else {
        Write-Host "$name/deck.html is current."
    }
}

if ($bad) { exit 2 }
if ($Check) {
    if ($stale.Count -gt 0) {
        Write-Host "STALE: $($stale -join ', '); run scripts/build-teaching-decks.ps1."
        exit 1
    }
    Write-Host 'OK: every teaching deck is current.'
}
exit 0
