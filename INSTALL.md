# Installing the Learn module onto a Grimdex install

This document is written for an **agent** to follow, step by step, not for a human to
skim. Humans should start at `QUICKSTART.md`. Run the steps in order. Do not skip the
preview. Do not improvise commands.

## What this does

It composes the Learn layer onto an existing Grimdex install: it copies the `learn/`
content into the install and adds one pointer stanza to the install's `GRIMDEX.md`,
between the markers `<!-- grimdex-learn:start -->` and `<!-- grimdex-learn:end -->`.

It never writes anything under `projects/**`. That is the user's own knowledge base and
install treats it as untouchable; the post-state verify hashes that tree before and after.
Install's own changes (`learn/` and the pointer stanzas) are rolled back on failure. A
difference detected under the user's own paths is reported, not reverted — this tool never
copies the student zone anywhere, so it has nothing to restore it from.

There is no installer program. Obtaining the source — a `git clone` of a release tag,
or the Path B one-liner fetch — is the only network step. The compose step itself
(`scripts/install-learn.ps1`) performs no download and has no network access. Every
path the compose step takes is a local path that already exists on this machine.

## Platform support

Windows 10/11 with PowerShell 7 (`pwsh`) is the officially supported platform. macOS
with PowerShell 7 is best-effort: the scripts are path-agnostic and are expected to work,
but macOS problems carry no support obligation. Verify the shell first:

    pwsh -NoProfile -Command '$PSVersionTable.PSVersion'

Use single quotes exactly as shown so the calling shell does not expand the variable before
`pwsh` sees it. If that reports a major version below 7, stop and tell the user to install
PowerShell 7.

## Placeholders used below

- `<source>` — the directory holding this file (the checkout of this repository).
- `<repo-url>` — the URL to clone this repository from, if `<source>` is not already on
  disk. Get this from the user; do not guess or invent one.
- `<release-tag>` — the Learn pack release to install. Clone this tag, not `main`, so
  everyone in a term gets byte-identical content. Get the tag from the user; do not
  guess or invent one.
- `<install>` — the Grimdex install to compose onto. It must contain `GRIMDEX.md`.
- `<work>` — a **new or empty** scratch directory **outside** `<install>`. The scripts
  refuse to run if it is inside `<install>`, because the operation being verified must not
  be able to corrupt its own backup. Its `backup/` subdirectory is wiped and rewritten at
  the start of every install run: do not point `<work>` at an existing directory that
  holds anything the user wants to keep, and never store user data in a `backup/`
  subdirectory under it. Create a fresh sibling directory for it.

## Steps

1. **Confirm the target is a Grimdex install.** Check that `<install>/GRIMDEX.md` exists.
   If it does not, stop and report that the path is not a Grimdex install. Do not create
   the file.

2. **Locate this repository.** If `<source>` is not already on disk, clone the pinned
   release:

        git clone --branch <release-tag> <repo-url> <source>

   Then use the clone path as `<source>`. Confirm `<source>/learn/manifest.json` exists.
   Do not clone `main` for an install you will hand to a user.

3. **Create the work directory.** `<work>` must exist before the next step, and must be
   **outside** `<install>` — the scripts refuse to run otherwise (see Placeholders above).

        pwsh -NoProfile -Command "New-Item -ItemType Directory -Force -Path '<work>'"

4. **Snapshot the user's zone before touching anything.**

        pwsh -NoProfile -File <source>/scripts/verify-student-zone.ps1 -Mode Snapshot -InstallRoot <install> -ManifestPath <source>/learn/manifest.json -SnapshotPath <work>/student-zone-before.json

   Expect exit code 0.

5. **Run the preview. It changes nothing.**

        pwsh -NoProfile -File <source>/scripts/install-learn.ps1 -SourceRoot <source> -InstallRoot <install> -ManifestPath <source>/learn/manifest.json -WorkDir <work> -Preview

   Exit code 0 means the plan is valid. Exit code 1 means the plan is invalid; print the
   reported problems, stop, and do not attempt the install.

6. **Show the user the preview output and get their go-ahead.** Show the mode
   (`fresh` or `re-apply`), the file count, and the pointer-stanza target. Do not proceed
   without an affirmative answer.

7. **Run the install.**

        pwsh -NoProfile -File <source>/scripts/install-learn.ps1 -SourceRoot <source> -InstallRoot <install> -ManifestPath <source>/learn/manifest.json -WorkDir <work>

   - Exit 0: installed.
   - Exit 1: invalid plan, nothing changed. Report the problems and stop.
   - Exit 2: the post-state verify failed. Install's own changes (`learn/` and the pointer
     stanzas) were rolled back from backup. Report the failures verbatim. If the output
     names a student-zone path as unrepaired, that path was reported, not reverted — say so
     plainly and tell the user to inspect it themselves. Stop. Do not retry blindly.

8. **Verify the user's zone is untouched.**

        pwsh -NoProfile -File <source>/scripts/verify-student-zone.ps1 -Mode Verify -InstallRoot <install> -ManifestPath <source>/learn/manifest.json -SnapshotPath <work>/student-zone-before.json

   Expect exit code 0 and `STUDENT ZONE OK`. Exit code 1 is a serious failure: report
   every reported path and stop. Nothing under `projects/**` is ever repaired automatically;
   the user must inspect and resolve it themselves.

9. **Check the version match (if the pack is pinned).**

        pwsh -NoProfile -File <source>/scripts/version-check.ps1 -InstallRoot <install> -ManifestPath <install>/learn/manifest.json

   Always run this step. Exit 0 means either the Learn pack matches the base, or the
   pack is unpinned (no base claimed — a normal state; the script prints a NOTE). Exit 1
   means a version mismatch and exit 2 means the base could not be verified; in both of
   those cases relay the script's message to the user rather than paraphrasing it.

10. **Report results.** State: the mode, the number of files installed, the pointer-stanza
    action (`created`, `updated`, or `unchanged`), the student-zone verify result, and the
    version-check result.

## Re-running

Running the install again with the same inputs is safe and expected. It reports
`re-apply` mode, rewrites the content, and reports the pointer stanza as `unchanged`.
Re-running produces no diff.

## Removing it again

Removal is part of the graduation flow, not this document. See `docs/graduation.md`.
