BeforeAll {
    $script:ScrubScript = Join-Path $PSScriptRoot '..' 'scripts' 'scrub-check.ps1'

    # Minimal throwaway git repo under TestDrive. Files passed in $TrackedFiles are
    # written and `git add`-ed (tracked); files in $UntrackedFiles are written but
    # never added, so they stay out of `git ls-files`.
    function New-ScrubFixture {
        param(
            [string]$Name,
            [hashtable]$TrackedFiles = @{},
            [hashtable]$UntrackedFiles = @{}
        )
        $root = Join-Path $TestDrive $Name
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        git -C $root init -q
        git -C $root config user.email 't@t'
        git -C $root config user.name 't'

        foreach ($rel in $TrackedFiles.Keys) {
            $full = Join-Path $root $rel
            New-Item -ItemType Directory -Path (Split-Path $full -Parent) -Force | Out-Null
            Set-Content -LiteralPath $full -Value $TrackedFiles[$rel]
            git -C $root add -- $rel
        }
        foreach ($rel in $UntrackedFiles.Keys) {
            $full = Join-Path $root $rel
            New-Item -ItemType Directory -Path (Split-Path $full -Parent) -Force | Out-Null
            Set-Content -LiteralPath $full -Value $UntrackedFiles[$rel]
        }
        $root
    }
}

Describe 'scrub-check.ps1' {
    It 'exits 0 on a clean repo with no private references' {
        $root = New-ScrubFixture 'clean1' -TrackedFiles @{
            'scripts/foo.ps1' = "Write-Host 'hello world'"
        }
        $out = pwsh -NoProfile -File $ScrubScript -RepoRoot $root
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'Summary: 0 findings'
    }

    It 'flags a Windows absolute path and exits 1' {
        $root = New-ScrubFixture 'winpath1' -TrackedFiles @{
            'scripts/leak.ps1' = "# see C:\Users\Testington\project\notes.txt for details"
        }
        $out = pwsh -NoProfile -File $ScrubScript -RepoRoot $root
        $text = $out -join "`n"
        $LASTEXITCODE | Should -Be 1
        $text | Should -Match '\[Windows absolute path\]'
        $text | Should -Match 'scripts/leak\.ps1:1:'
    }

    It 'flags an email address and exits 1' {
        $root = New-ScrubFixture 'email1' -TrackedFiles @{
            'notes.txt' = 'contact someone at test.person@example.com for questions'
        }
        $out = pwsh -NoProfile -File $ScrubScript -RepoRoot $root
        $text = $out -join "`n"
        $LASTEXITCODE | Should -Be 1
        $text | Should -Match '\[Email address\]'
    }

    It 'flags a custom term from the default local terms file, case-insensitively' {
        $root = New-ScrubFixture 'terms1' -TrackedFiles @{
            'docs/page.md' = 'This was reviewed at THE EXAMPLE INSTITUTE last week.'
        }
        Set-Content -LiteralPath (Join-Path $root 'scrub-terms.local.txt') -Value @(
            '# comment line, ignored'
            ''
            'the example institute'
        )
        $out = pwsh -NoProfile -File $ScrubScript -RepoRoot $root
        $text = $out -join "`n"
        $LASTEXITCODE | Should -Be 1
        $text | Should -Match '\[local term: the example institute\]'
    }

    It 'flags a custom term supplied via an explicit -TermsFile override' {
        $root = New-ScrubFixture 'terms2' -TrackedFiles @{
            'docs/page.md' = 'Written by Jane Q. Example for the class.'
        }
        $termsFile = Join-Path $TestDrive 'terms2-external-terms.txt'
        Set-Content -LiteralPath $termsFile -Value 'Jane Q. Example'
        $out = pwsh -NoProfile -File $ScrubScript -RepoRoot $root -TermsFile $termsFile
        $text = $out -join "`n"
        $LASTEXITCODE | Should -Be 1
        $text | Should -Match '\[local term: Jane Q\. Example\]'
    }

    It 'ignores a hit under docs/ when -ShippingSurfaceOnly is set' {
        $root = New-ScrubFixture 'surface1' -TrackedFiles @{
            'docs/private.md'  = 'internal contact: someone@example.com'
            'scripts/clean.ps1' = "Write-Host 'nothing private here'"
        }
        $out = pwsh -NoProfile -File $ScrubScript -RepoRoot $root -ShippingSurfaceOnly
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'Summary: 0 findings'
    }

    It 'does not scan untracked files' {
        $root = New-ScrubFixture 'untracked1' `
            -TrackedFiles @{ 'scripts/clean.ps1' = "Write-Host 'clean'" } `
            -UntrackedFiles @{ 'scratch/leak.txt' = 'contact scratch@example.com' }
        $out = pwsh -NoProfile -File $ScrubScript -RepoRoot $root
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'Summary: 0 findings'
    }

    It 'skips files with a binary-denylisted extension' {
        $root = New-ScrubFixture 'binary1' -TrackedFiles @{
            'scripts/icon.png' = 'C:\Users\Testington\hidden.txt'
        }
        $out = pwsh -NoProfile -File $ScrubScript -RepoRoot $root
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'Summary: 0 findings'
    }

    It '-Quiet prints per-label counts and a total, not per-line detail' {
        $root = New-ScrubFixture 'quiet1' -TrackedFiles @{
            'notes.txt' = @(
                'first: one@example.com'
                'second: two@example.com'
            ) -join "`n"
        }
        $out = pwsh -NoProfile -File $ScrubScript -RepoRoot $root -Quiet
        $text = $out -join "`n"
        $LASTEXITCODE | Should -Be 1
        $text | Should -Match 'Email address: 2'
        $text | Should -Match 'Summary: 2 finding'
        $text | Should -Not -Match 'notes\.txt:1:'
    }

    It 'exits 2 with a warning when RepoRoot is not a git repository' {
        $root = Join-Path $TestDrive 'notagitrepo'
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        $out = pwsh -NoProfile -File $ScrubScript -RepoRoot $root 2>$null
        $LASTEXITCODE | Should -Be 2
        ($out -join "`n") | Should -Match 'WARNING'
    }

    It 'suppresses an allowlisted finding and exits 0' {
        $root = New-ScrubFixture 'allowlist1' -TrackedFiles @{
            'docs/page.md' = 'contact someone at test@example.com for help'
        }
        Set-Content -LiteralPath (Join-Path $root 'scrub-allow.txt') -Value 'example.com'
        $out = pwsh -NoProfile -File $ScrubScript -RepoRoot $root
        $text = $out -join "`n"
        $LASTEXITCODE | Should -Be 0
        $text | Should -Match 'Suppressed 1 finding'
        $text | Should -Match 'Summary: 0 findings'
    }

    It 'reports suppressed count and remaining findings' {
        $root = New-ScrubFixture 'allowlist2' -TrackedFiles @{
            'notes.txt' = @(
                'safe: test@example.com'
                'unsafe: bad@invalid.com'
            ) -join "`n"
        }
        Set-Content -LiteralPath (Join-Path $root 'scrub-allow.txt') -Value 'example.com'
        $out = pwsh -NoProfile -File $ScrubScript -RepoRoot $root
        $text = $out -join "`n"
        $LASTEXITCODE | Should -Be 1
        $text | Should -Match 'Suppressed 1 finding'
        $text | Should -Match 'Summary: 1 finding'
    }

    It 'non-allowlisted findings still cause exit 1 even with an allowlist file' {
        $root = New-ScrubFixture 'allowlist3' -TrackedFiles @{
            'docs/page.md' = 'C:\Users\Testington\file.txt is dangerous'
        }
        Set-Content -LiteralPath (Join-Path $root 'scrub-allow.txt') -Value 'example.com'
        $out = pwsh -NoProfile -File $ScrubScript -RepoRoot $root
        $text = $out -join "`n"
        $LASTEXITCODE | Should -Be 1
        $text | Should -Match '\[Windows absolute path\]'
        $text | Should -Not -Match 'Suppressed'
    }

    It '-ShowSuppressed lists suppressed entries in full' {
        $root = New-ScrubFixture 'allowlist4' -TrackedFiles @{
            'scripts/doc.md' = 'example at admin@example.com and another@example.com both safe'
        }
        Set-Content -LiteralPath (Join-Path $root 'scrub-allow.txt') -Value 'example.com'
        $out = pwsh -NoProfile -File $ScrubScript -RepoRoot $root -ShowSuppressed
        $text = $out -join "`n"
        $LASTEXITCODE | Should -Be 0
        $text | Should -Match 'Suppressed findings \(via allowlist\):'
        $text | Should -Match 'scripts/doc.md:1:'
        $text | Should -Match 'Email address'
    }

    It 'proceeds normally when allowlist file is missing (optional feature)' {
        $root = New-ScrubFixture 'allowlist5' -TrackedFiles @{
            'scripts/clean.ps1' = "Write-Host 'nothing private'"
        }
        $out = pwsh -NoProfile -File $ScrubScript -RepoRoot $root
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'Summary: 0 findings'
    }

    It 'scans bootstrap.ps1, QUICKSTART.md and get-learn.ps1 under -ShippingSurfaceOnly' {
        $root = New-ScrubFixture 'surface-d42' -TrackedFiles @{
            'bootstrap.ps1'   = 'contact bootstrap@example.com'
            'QUICKSTART.md'   = 'contact quickstart@example.com'
            'get-learn.ps1'   = 'contact getlearn@example.com'
            'docs/private.md' = 'contact docs@example.com'
            'scripts/ok.ps1'  = "Write-Host 'nothing private here'"
        }
        $out = pwsh -NoProfile -File $ScrubScript -RepoRoot $root -ShippingSurfaceOnly
        $text = $out -join "`n"
        $LASTEXITCODE | Should -Be 1
        $text | Should -Match 'bootstrap\.ps1'
        $text | Should -Match 'QUICKSTART\.md'
        $text | Should -Match 'get-learn\.ps1'
        $text | Should -Not -Match 'docs/private'
    }

    It 'scans README.md and LICENSE under -ShippingSurfaceOnly' {
        $root = New-ScrubFixture 'surface-readme-license' -TrackedFiles @{
            'README.md'       = 'contact readme@example.com'
            'LICENSE'         = 'contact license@example.com'
            'docs/private.md' = 'contact docs@example.com'
            'scripts/ok.ps1'  = "Write-Host 'nothing private here'"
        }
        $out = pwsh -NoProfile -File $ScrubScript -RepoRoot $root -ShippingSurfaceOnly
        $text = $out -join "`n"
        $LASTEXITCODE | Should -Be 1
        $text | Should -Match 'README\.md'
        $text | Should -Match 'LICENSE'
        $text | Should -Not -Match 'docs/private'
    }
}
