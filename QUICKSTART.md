# Install Learn

You already have Grimdex. This adds the Learn layer: short explanations of the
commands you are seeing, while you work.

## Check these first

- Windows 10 or 11, with PowerShell 7 (`pwsh`). macOS with PowerShell 7 is
  best-effort and is not supported.
- A Grimdex install: a folder that already contains a file named `GRIMDEX.md`.

Check the shell:

    pwsh -NoProfile -Command '$PSVersionTable.PSVersion'

The major version must be 7 or more. Use the single quotes exactly as written.

## The taught path

Two commands. Clone a release tag, not `main`, so everyone gets the same bytes.

    git clone --branch v0.3.0-fall2026-draft https://github.com/Ryfter/grimdex-learn <source>
    pwsh <source>/bootstrap.ps1 -InstallRoot <install>

Optional, changes nothing — run this first if you want to see the plan:

    pwsh <source>/bootstrap.ps1 -InstallRoot <install> -Preview

## What you will see

1. A line that it is composing Learn onto `<install>`.
2. Either `PREVIEW - no changes made` (if you passed `-Preview`) or
   `INSTALLED. Mode: fresh. Files: N.` plus a line for the pointer stanza.
3. On a later run, `Mode: re-apply` and `unchanged` for the stanza. Running
   it again is safe.

If something is wrong you get a plain-language stop, not a stack trace.
Typical stops: PowerShell is older than 7; `<install>` is not a folder; the
folder has no `GRIMDEX.md`.

## How to tell it worked

- The script printed `INSTALLED` and the command exited 0.
- `<install>/learn/manifest.json` exists.
- `<install>/GRIMDEX.md` contains the markers `<!-- grimdex-learn:start -->`
  and `<!-- grimdex-learn:end -->`.

Your own notes under `projects/` are not touched.

## Updating

From `<source>`, check out the new release tag (or `git pull` if you were
told to track that tag), then run `bootstrap.ps1` again with the same
`-InstallRoot`. Re-running rewrites Learn and leaves your notes alone.

## The one-liner path

Not the taught path. For people who are not being taught git.

This one-liner retrieves a small bootstrapper. The bootstrapper then
downloads the pinned release itself and runs the same `bootstrap.ps1`
as the taught path. That relocates the clone and adds a trust hop. It
does not remove the clone.

Review the bootstrapper first (this prints the script; it does not run it):

    irm https://github.com/Ryfter/grimdex-learn/raw/v0.3.0-fall2026-draft/get-learn.ps1

Run it only if you accept that trust hop:

    iex "& { $(irm https://github.com/Ryfter/grimdex-learn/raw/v0.3.0-fall2026-draft/get-learn.ps1) } -InstallRoot '<install>'"

What you will see, and how to tell it worked, are the same as the taught
path after the announcement: `INSTALLED`, `<install>/learn/manifest.json`
present, `<!-- grimdex-learn:start -->` in `GRIMDEX.md`.

## Track which lessons you've seen (optional)

When your agent finishes a piece of work, it reports what it did first, then adds a short
**Lesson** section that defines the terms involved and ends with lines like
`Learn: git-and-github/commits-and-history`. From your grimdex-edu checkout, run this
now and then to count those lines and update your level:

    pwsh ./scripts/learn-surfacing.ps1 -InstallRoot <your Grimdex folder> -TranscriptPath <your session logs folder>

Claude Code keeps session logs under `~/.claude/projects/`, in a folder named after
your project's path. Seeing every lesson at your level 10 or more times moves you up
a level, out of 7. Lower-level lessons still come up now and then.

To stop a lesson from being shown:

    pwsh ./scripts/learn-surfacing.ps1 -InstallRoot <your Grimdex folder> -Suppress git-and-github/glossary

`-Unsuppress` turns it back on. Your progress lives in `learn-progress/` in your
Grimdex folder. It is yours and is never uploaded or overwritten by an update.

## Teaching aids

For teaching or presenting Learn's material, `learn/teaching/README.md` points to four
workflows: one change start to finish, recovering when it breaks, starting a project
safely, and working with an agent safely. Each has slides, a ready-to-present HTML
deck, a one-page infographic, and a guided exercise.

## Agents

Agents follow `INSTALL.md`, not this page.
