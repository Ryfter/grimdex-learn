# Guard: a shipped test must not require a file that the published pack
# does not contain. The publication snapshot is exactly the
# -ShippingSurfaceOnly filter (learn/*, scripts/*, tests/*, INSTALL.md,
# bootstrap.ps1, QUICKSTART.md, get-learn.ps1, README.md, LICENSE).
# docs/, instruction files, and local scrub config are source-repo only.
# A presence-gated skip is fine; an unguarded Should -Exist is not.

Describe 'Shipping-surface test self-sufficiency' {
    It 'does not read a repo path outside the shipping surface without a skip' {
        $outOfSurface = @(
            'docs'
            'TO-WORK-ON'
            'CLAUDE.md'
            'AGENTS.md'
            'GEMINI.md'
            'GROK.md'
            'scrub-allow.txt'
            'scrub-terms.local.txt'
            '.cursorrules'
        )
        $escaped = ($outOfSurface | ForEach-Object { [regex]::Escape($_) }) -join '|'

        # Matches a Join-Path whose first remaining argument is an
        # out-of-surface name, when the root is $script:RepoRoot or
        # $PSScriptRoot/... . Fixture strings under TestDrive are not a hit.
        $joinPathPattern = [regex](
            'Join-Path\s+' +
            '(?:\$script:RepoRoot|\$PSScriptRoot\s+[''"]\.\.[''"])' +
            '\s+[''"](?:' + $escaped + ')[''"]'
        )

        $unguarded = [System.Collections.Generic.List[string]]::new()
        Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.Tests.ps1' | ForEach-Object {
            $text = [string](Get-Content -LiteralPath $_.FullName -Raw)
            $starts = [regex]::Matches($text, '(?m)^[ \t]*It\b')
            for ($i = 0; $i -lt $starts.Count; $i++) {
                $start = $starts[$i].Index
                $end = if ($i + 1 -lt $starts.Count) { $starts[$i + 1].Index } else { $text.Length }
                $block = $text.Substring($start, $end - $start)
                if (-not $joinPathPattern.IsMatch($block)) { continue }
                $hasSkip = $block -match '-Skip\s*:' -or $block -match 'Set-ItResult\s+-Skipped'
                if ($hasSkip) { continue }
                $nameMatch = [regex]::Match($block, "It\s+'([^']+)'")
                $name = if ($nameMatch.Success) { $nameMatch.Groups[1].Value } else { '(unnamed It)' }
                $unguarded.Add("$($_.Name): $name")
            }
        }

        $unguarded.Count | Should -Be 0 -Because (
            'a shipped test that reads docs/ or another out-of-surface path must skip when the file is absent. Unguarded: ' +
            (($unguarded | ForEach-Object { $_ }) -join '; ')
        )
    }
}
