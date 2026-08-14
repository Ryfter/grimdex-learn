BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'scripts' 'learn-lib.ps1')

    function script:New-FixturePage {
        param([string]$Name, [string]$Content)
        $p = Join-Path $TestDrive $Name
        Set-Content -Path $p -Value $Content -Encoding utf8NoBOM
        return $p
    }

    $script:ConformingPage = @'
---
title: Fixture page
module_id: git-and-github
capabilities:
  - git example
context7_library: /websites/git-scm
context7_queries:
  - "example query"
official_sources:
  - https://git-scm.com/docs/git-example
last_checked: 2026-08-01
last_material_update: 2026-08-01
status: current
claim_class: foundational
safety_class: normal
version_stamp: fall-2026-0.1.0
admission:
  course_independent: true
  public_ready: true
  provenance: authored-against-official-docs
---

## What it is

Text.

## When it is useful

Text.

## Prerequisites

Text.

## Current syntax

Text.

## What happens (local and remote)

Text.

## Practical example

Text.

## Explanation guidance

Text.

## Cautions and common failures

Text.

## Related capabilities

Text.

## Official sources

- <https://git-scm.com/docs/git-example>

## Provenance

Text.
'@
}

Describe 'Test-CapabilityPageContract' {
    It 'passes a fully conforming page' {
        $p = New-FixturePage -Name 'ok.md' -Content $script:ConformingPage
        $r = Test-CapabilityPageContract -Path $p
        $r.failures | Should -BeNullOrEmpty
        $r.passed | Should -BeTrue
    }

    It 'fails when a section is missing' {
        $broken = $script:ConformingPage -replace '(?s)## Prerequisites\r?\n\r?\nText\.\r?\n\r?\n', ''
        $p = New-FixturePage -Name 'missing-section.md' -Content $broken
        $r = Test-CapabilityPageContract -Path $p
        $r.passed | Should -BeFalse
        ($r.failures -join ' ') | Should -Match 'Prerequisites'
    }

    It 'fails when sections are out of order' {
        $swapped = $script:ConformingPage.Replace('## What it is', '## ZZTEMP').
            Replace('## When it is useful', '## What it is').
            Replace('## ZZTEMP', '## When it is useful')
        $p = New-FixturePage -Name 'out-of-order.md' -Content $swapped
        (Test-CapabilityPageContract -Path $p).passed | Should -BeFalse
    }

    It 'fails on a missing front-matter key' {
        $broken = $script:ConformingPage -replace '(?m)^version_stamp:.*\r?\n', ''
        $p = New-FixturePage -Name 'missing-key.md' -Content $broken
        $r = Test-CapabilityPageContract -Path $p
        $r.passed | Should -BeFalse
        ($r.failures -join ' ') | Should -Match 'version_stamp'
    }

    It 'fails on an invalid enum value' {
        $broken = $script:ConformingPage -replace 'safety_class: normal', 'safety_class: mostly-fine'
        $p = New-FixturePage -Name 'bad-enum.md' -Content $broken
        $r = Test-CapabilityPageContract -Path $p
        $r.passed | Should -BeFalse
        ($r.failures -join ' ') | Should -Match 'safety_class'
    }

    It 'fails when the admission block is incomplete' {
        $broken = $script:ConformingPage -replace '(?m)^  public_ready: true\r?\n', ''
        $p = New-FixturePage -Name 'no-admission.md' -Content $broken
        $r = Test-CapabilityPageContract -Path $p
        $r.passed | Should -BeFalse
        ($r.failures -join ' ') | Should -Match 'public_ready'
    }

    It 'fails when a heading is a reworded superset of the frozen heading' {
        $broken = $script:ConformingPage.Replace('## Prerequisites', '## Prerequisites and setup')
        $p = New-FixturePage -Name 'heading-prefix-spoof.md' -Content $broken
        $r = Test-CapabilityPageContract -Path $p
        $r.passed | Should -BeFalse
        ($r.failures -join ' ') | Should -Match 'Prerequisites'
    }

    It 'fails when an enum key has no value' {
        $broken = $script:ConformingPage -replace 'status: current', 'status:'
        $p = New-FixturePage -Name 'empty-enum.md' -Content $broken
        $r = Test-CapabilityPageContract -Path $p
        $r.passed | Should -BeFalse
        ($r.failures -join ' ') | Should -Match "'status'"
    }

    It 'fails when an enum value carries a trailing comment' {
        $broken = $script:ConformingPage -replace 'status: current', 'status: current  # reviewed'
        $p = New-FixturePage -Name 'comment-enum.md' -Content $broken
        (Test-CapabilityPageContract -Path $p).passed | Should -BeFalse
    }

    It 'returns a failed result (not a crash) on an empty file' {
        $p = Join-Path $TestDrive 'empty.md'
        Set-Content -Path $p -Value '' -NoNewline -Encoding utf8NoBOM
        $r = Test-CapabilityPageContract -Path $p
        $r.passed | Should -BeFalse
    }

    It 'returns a failed result (not a crash) on a missing file' {
        $r = Test-CapabilityPageContract -Path (Join-Path $TestDrive 'nope.md')
        $r.passed | Should -BeFalse
        ($r.failures -join ' ') | Should -Match 'not found'
    }
}
