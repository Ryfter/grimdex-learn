#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Audit Grimdex-edu Learn curriculum — shipped pages vs curriculum-backlog.yaml.
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$Json
)

$ErrorActionPreference = 'Stop'

function Read-SimpleYamlList {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    # Minimal parse: enough for curriculum-backlog structure (no external YAML module).
    $text = Get-Content -LiteralPath $Path -Raw
    return $text
}

function Get-ShippedCapabilityPages {
    param([string]$Root)
    $learn = Join-Path $Root 'learn'
    if (-not (Test-Path -LiteralPath $learn)) { return @() }
    return @(Get-ChildItem -LiteralPath $learn -Recurse -Filter '*.md' -File |
        Where-Object { $_.FullName -match '[\\/]capabilities[\\/]' -and $_.Name -ne 'README.md' })
}

function Get-BacklogLessonIds {
    param([string]$YamlText)
    $ids = [System.Collections.ArrayList]@()
    $currentModule = ''
    foreach ($line in ($YamlText -split "`n")) {
        if ($line -match '^\s{2}-\s+id:\s+(\S+)') {
            $currentModule = $Matches[1]
            continue
        }
        if ($line -match '^\s{6}-\s+id:\s+(\S+)') {
            if ($currentModule) {
                [void]$ids.Add("$currentModule/$($Matches[1])")
            }
        }
    }
    return @($ids)
}

$backlogPath = Join-Path $RepoRoot 'learn/curriculum-backlog.yaml'
$yaml = Read-SimpleYamlList -Path $backlogPath
$shipped = @(Get-ShippedCapabilityPages -Root $RepoRoot)
$lessonIds = if ($yaml) { Get-BacklogLessonIds -YamlText $yaml } else { @() }

$modules = @{}
foreach ($f in $shipped) {
    if ($f.FullName -match '[\\/]learn[\\/]([^\\/]+)[\\/]capabilities[\\/]([^\\/]+)\.md$') {
        $mod = $Matches[1]
        if (-not $modules.ContainsKey($mod)) { $modules[$mod] = 0 }
        $modules[$mod]++
    }
}

$out = [ordered]@{
    root       = $RepoRoot
    shipped    = $shipped.Count
    backlog    = $lessonIds.Count
    pending    = $lessonIds.Count
    modules    = @($modules.GetEnumerator() | Sort-Object Name | ForEach-Object {
        @{ id = $_.Key; pages = $_.Value }
    })
    lesson_ids = $lessonIds
}

if ($Json) {
    $out | ConvertTo-Json -Depth 6
} else {
    Write-Host "grimdex-edu curriculum: shipped=$($out.shipped) backlog-lessons=$($out.backlog) pending~=$($out.pending)"
    foreach ($m in @($out.modules)) { Write-Host "  $($m.id): $($m.pages) pages" }
}
exit 0
