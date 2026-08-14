Set-StrictMode -Version 3.0

# Requires manifest-lib.ps1 to be dot-sourced by the caller: Get-LearnStanzaContent
# reads the optional base pin via Get-ManifestPin rather than reaching into
# baseGrimdex.pin directly.

$script:StanzaStart = '<!-- grimdex-learn:start -->'
$script:StanzaEnd   = '<!-- grimdex-learn:end -->'

function Get-PointerStanzaState {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{ state = 'missing-file'; blocks = 0 }
    }
    $text   = [string](Get-Content -LiteralPath $Path -Raw)
    $starts = [regex]::Matches($text, [regex]::Escape($script:StanzaStart))
    $ends   = [regex]::Matches($text, [regex]::Escape($script:StanzaEnd))

    if ($starts.Count -eq 0 -and $ends.Count -eq 0) {
        return [pscustomobject]@{ state = 'absent'; blocks = 0 }
    }
    if ($starts.Count -ne $ends.Count) {
        return [pscustomobject]@{ state = 'malformed'; blocks = 0 }
    }
    # Pairing check: markers must strictly alternate start,end,start,end...
    $events = @()
    foreach ($m in $starts) { $events += [pscustomobject]@{ pos = $m.Index; kind = 'start' } }
    foreach ($m in $ends)   { $events += [pscustomobject]@{ pos = $m.Index; kind = 'end' } }
    $events = @($events | Sort-Object pos)
    for ($i = 0; $i -lt $events.Count; $i++) {
        $expected = if ($i % 2 -eq 0) { 'start' } else { 'end' }
        if ($events[$i].kind -ne $expected) {
            return [pscustomobject]@{ state = 'malformed'; blocks = 0 }
        }
    }
    [pscustomobject]@{ state = 'well-formed'; blocks = $starts.Count }
}

function Remove-PointerStanza {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $state = Get-PointerStanzaState -Path $Path
    if ($state.state -eq 'missing-file') { return [pscustomobject]@{ removed = 0 } }
    if ($state.state -eq 'absent')       { return [pscustomobject]@{ removed = 0 } }
    if ($state.state -eq 'malformed') {
        throw "Pointer stanza markers in '$Path' are malformed; refusing to strip."
    }

    $text    = [string](Get-Content -LiteralPath $Path -Raw)
    $pattern = '(?s)' + [regex]::Escape($script:StanzaStart) + '.*?' +
               [regex]::Escape($script:StanzaEnd) + '(\r?\n)?'
    $newText = [regex]::Replace($text, $pattern, '')
    Set-Content -LiteralPath $Path -Value $newText -NoNewline
    [pscustomobject]@{ removed = $state.blocks }
}

function Get-LearnStanzaContent {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Manifest)

    $pagesPath = $null
    if ($Manifest -is [System.Collections.IDictionary]) {
        if ($Manifest.ContainsKey('pagesPath')) { $pagesPath = [string]$Manifest['pagesPath'] }
    } elseif ($null -ne $Manifest -and $null -ne $Manifest.PSObject.Properties['pagesPath']) {
        $pagesPath = [string]$Manifest.pagesPath
    }
    if ([string]::IsNullOrWhiteSpace($pagesPath)) {
        throw 'Manifest has no pagesPath; cannot build the Learn pointer stanza.'
    }
    $pin = Get-ManifestPin -Manifest $Manifest

    # Plain markdown, no backticks (they are PowerShell escape characters), no
    # timestamps, no randomness, no host paths - byte-identical for identical input,
    # which is what makes install idempotent.
    $lines = @(
        '## Learn module (grimdex-edu)'
        ''
        'The Learn layer is installed. It explains what commands do and why, while you work.'
        ''
        "- Capability pages live under: $pagesPath"
    )
    # An unpinned pack claims no base version rather than printing a placeholder
    # into the student's GRIMDEX.md.
    if ($pin) { $lines += "- Explanations are matched to base Grimdex pin: $pin" }
    $lines += '- Learn tooling (version check, graduation) runs from your grimdex-edu checkout, not'
    $lines += '  from here, and takes this install as its -InstallRoot. See INSTALL.md in that checkout.'

    [string]::Join("`n", $lines)
}

function Set-PointerStanza {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content
    )

    $state = Get-PointerStanzaState -Path $Path
    if ($state.state -eq 'missing-file') {
        throw "Pointer stanza target '$Path' does not exist; install never creates base-owned files."
    }
    if ($state.state -eq 'malformed') {
        throw "Pointer stanza markers in '$Path' are malformed; refusing to upsert."
    }
    if ($state.state -eq 'well-formed' -and $state.blocks -gt 1) {
        throw "Pointer stanza target '$Path' has $($state.blocks) learn blocks; refusing an ambiguous upsert."
    }

    $block = $script:StanzaStart + "`n" + $Content + "`n" + $script:StanzaEnd

    # Get-Content -Raw on an empty file yields AutomationNull, and [string] of that
    # is still $null — normalise before touching any string member.
    $text = [string](Get-Content -LiteralPath $Path -Raw)
    if ($null -eq $text) { $text = '' }

    if ($state.state -eq 'absent') {
        $separator = ''
        if ($text.Length -gt 0) {
            if ($text -match '(\r?\n)(\r?\n)$')  { $separator = '' }
            elseif ($text -match '(\r?\n)$')     { $separator = "`n" }
            else                                 { $separator = "`n`n" }
        }
        Set-Content -LiteralPath $Path -Value ($text + $separator + $block + "`n") -NoNewline
        return [pscustomobject]@{ action = 'created' }
    }

    # Index arithmetic, never [regex]::Replace with a string replacement: a '$1'
    # or '$&' in $Content would otherwise be read as substitution syntax.
    $pattern = '(?s)' + [regex]::Escape($script:StanzaStart) + '.*?' + [regex]::Escape($script:StanzaEnd)
    $m = [regex]::Match($text, $pattern)
    if (-not $m.Success) {
        throw "Pointer stanza block in '$Path' could not be located; refusing to guess."
    }
    if ($m.Value -eq $block) {
        return [pscustomobject]@{ action = 'unchanged' }
    }
    $newText = $text.Substring(0, $m.Index) + $block + $text.Substring($m.Index + $m.Length)
    Set-Content -LiteralPath $Path -Value $newText -NoNewline
    [pscustomobject]@{ action = 'updated' }
}

function Get-PointerStanzaBody {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $state = Get-PointerStanzaState -Path $Path
    if ($state.state -ne 'well-formed') { return $null }

    $text = [string](Get-Content -LiteralPath $Path -Raw)
    if ($null -eq $text) { $text = '' }

    $pattern = '(?s)' + [regex]::Escape($script:StanzaStart) + '(.*?)' +
               [regex]::Escape($script:StanzaEnd)
    $m = [regex]::Match($text, $pattern)
    if (-not $m.Success) { return $null }

    # Strip exactly one framing newline at each end. Never use -replace with a
    # '$' anchor here: in .NET, '$' also matches before a final newline and
    # -replace replaces every match, so it would strip two newlines, not one.
    $body = $m.Groups[1].Value
    if     ($body.StartsWith("`r`n")) { $body = $body.Substring(2) }
    elseif ($body.StartsWith("`n"))   { $body = $body.Substring(1) }
    if     ($body.EndsWith("`r`n"))   { $body = $body.Substring(0, $body.Length - 2) }
    elseif ($body.EndsWith("`n"))     { $body = $body.Substring(0, $body.Length - 1) }
    $body
}
