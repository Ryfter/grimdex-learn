# learn-lib.ps1 — static conformance checks for Learn module content (D32 page contract).
# Lint over local files only: no network, no content mutation (D31 automation boundary).
Set-StrictMode -Version 3.0

function Test-CapabilityPageContract {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $failures = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{
            passed   = $false
            failures = @("File not found: $Path")
        }
    }
    # [string] cast: Get-Content -Raw returns AutomationNull on an empty file, which
    # under StrictMode breaks the -notmatch/$Matches pattern below.
    $text = [string](Get-Content -LiteralPath $Path -Raw)

    $front = ''
    if ($text -notmatch '(?s)^---\r?\n(.*?)\r?\n---(\r?\n|$)') {
        $failures.Add('Missing YAML front-matter block delimited by ---')
    } else {
        $front = $Matches[1]
    }

    $requiredKeys = @(
        'title','module_id','capabilities','context7_library','context7_queries',
        'official_sources','last_checked','last_material_update','status',
        'claim_class','safety_class','version_stamp','admission'
    )
    foreach ($k in $requiredKeys) {
        if ($front -notmatch "(?m)^${k}:") {
            $failures.Add("Front matter missing required key: $k")
        }
    }

    $enums = @{
        status       = @('current','material-update-applied','review-required','refresh-failed')
        claim_class  = @('foundational','everyday','conditional','automation-security','advanced')
        safety_class = @('normal','destructive','secrets','auth')
    }
    foreach ($k in $enums.Keys) {
        if ($front -match "(?m)^${k}:[ \t]*(.*)$") {
            # Whole rest-of-line must be exactly one bare enum token: an empty value,
            # a quoted scalar, or a trailing comment all fail rather than skip.
            $value = $Matches[1].Trim()
            if ($enums[$k] -notcontains $value) {
                $failures.Add("Front matter key '$k' has invalid value '$value'")
            }
        }
    }

    foreach ($sub in @('course_independent','public_ready','provenance')) {
        if ($front -notmatch "(?m)^\s+${sub}:") {
            $failures.Add("Admission block missing required field: $sub")
        }
    }

    $sections = @(
        'What it is','When it is useful','Prerequisites','Current syntax',
        'What happens (local and remote)','Practical example','Explanation guidance',
        'Cautions and common failures','Related capabilities','Official sources','Provenance'
    )
    $lastIndex = -1
    foreach ($s in $sections) {
        # Anchored whole-line match: "## Prerequisites and setup" must not satisfy
        # "## Prerequisites" (the frozen contract requires the exact heading).
        $m = [regex]::Match($text, "(?m)^## $([regex]::Escape($s))[ \t]*\r?$")
        if (-not $m.Success) {
            $failures.Add("Missing section: ## $s")
        } elseif ($m.Index -lt $lastIndex) {
            $failures.Add("Section out of order: ## $s")
        } else {
            $lastIndex = $m.Index
        }
    }

    if ($text -notmatch 'https://\S+') {
        $failures.Add('No https:// official source links found')
    }

    [pscustomobject]@{
        passed   = ($failures.Count -eq 0)
        failures = @($failures)
    }
}
