---
title: Install, bootstrap, and first agent session
module_id: grimdex-harness
capabilities:
  - install-and-bootstrap
context7_library:
context7_queries:
official_sources:
  - https://github.com/Ryfter/grimdex-learn
last_checked: 2026-09-20
last_material_update: 2026-09-20
status: current
claim_class: foundational
safety_class: normal
version_stamp: fall-2026-0.1.0
admission:
  course_independent: true
  public_ready: true
  provenance: authored-against-product-decision-record
---

## What it is

Installing the Learn module means adding it on top of a Grimdex install you already have. Learn does not install Grimdex itself. A Grimdex install is simply a folder that already contains a file named `GRIMDEX.md`; the Learn installer composes its files onto that existing folder.

There are two front doors, and both run the exact same installer script (`install-learn.ps1`). There is no separate or parallel install path behind the scenes. Both paths pin to a release tag rather than a moving branch, so everyone installing in the same term gets byte-identical content.

## When it is useful

Use this procedure the first time you set up Learn, and any time you want to re-apply or update it. Re-running the installer is safe and idempotent.

## Prerequisites

- Windows 10 or 11.
- PowerShell 7 (`pwsh`). Check with:

  ```
  pwsh -NoProfile -Command '$PSVersionTable.PSVersion'
  ```

  The major version must be 7 or higher.
- An existing Grimdex install: a folder containing a file named `GRIMDEX.md`.
- For Path A, Git must be available.

macOS with PowerShell 7 is best-effort, not officially supported.

## Current syntax

**Path A — taught, primary path (what students are taught):**

```
git clone --branch v0.2.0-fall2026-draft https://github.com/Ryfter/grimdex-learn <source>
pwsh <source>/bootstrap.ps1 -InstallRoot <install>
```

To preview what would happen without changing anything, add `-Preview` to the same bootstrap command.

**Path B — secondary one-liner (for people not being taught Git):**

First review the script without running it (this only prints it):

```
irm https://github.com/Ryfter/grimdex-learn/raw/v0.2.0-fall2026-draft/get-learn.ps1
```

Then run it:

```
iex "& { $(irm https://github.com/Ryfter/grimdex-learn/raw/v0.2.0-fall2026-draft/get-learn.ps1) } -InstallRoot '<install>'"
```

Path B fetches a small bootstrapper, which itself downloads the pinned release and runs the same `bootstrap.ps1` as Path A. Say it plainly: Path B relocates the clone and adds a trust hop; it does not remove the clone. It does not skip cloning entirely.

## What happens (local and remote)

Path A downloads the pinned release repository to a source folder on your machine, then runs its bootstrap script against your existing Grimdex install folder. The script is on disk before anything runs, so you can read it first — that reviewability is a deliberate part of the design.

Path B downloads a bootstrapper over the network, which then performs the same steps as Path A.

On success the script prints `INSTALLED. Mode: fresh. Files: N.` plus a line for the pointer stanza. On a later run it prints `Mode: re-apply` and `unchanged` for the stanza.

On failure the script stops with a plain-language message, not a stack trace. Typical stops:

- PowerShell is older than 7.
- The `<install>` value is not a folder.
- The folder has no `GRIMDEX.md`.

To confirm the install actually worked: the script printed `INSTALLED` and exited with code 0; `<install>/learn/manifest.json` exists; and `<install>/GRIMDEX.md` contains the markers `<!-- grimdex-learn:start -->` and `<!-- grimdex-learn:end -->`.

## Practical example

A student with a Grimdex install at `C:\grimdex` runs:

```
git clone --branch v0.2.0-fall2026-draft https://github.com/Ryfter/grimdex-learn C:\learn-src
pwsh C:\learn-src\bootstrap.ps1 -InstallRoot C:\grimdex
```

The script prints `INSTALLED. Mode: fresh. Files: N.` and the pointer stanza line. A later re-run prints `Mode: re-apply` and `unchanged` for the stanza — confirming nothing was disturbed.

## Explanation guidance

### Essential

Two front doors, one installer. Path A is the taught path because it uses the tool the module teaches (most shipped capability pages are Git/GitHub), it is reviewable, and updating later is just `git pull`. Path B exists for non-students who are not being taught Git. Both paths pin to the same release tag.

### Experienced-user note

Path B adds a trust hop: you are executing a script fetched over the network rather than one already on disk. Review the printed script before running it. Path A keeps the clone on disk, which is what makes updates a simple `git pull`.

### Optional deeper context

The installer composes only the module's own files onto the existing tree. Your own notes under `projects/` are never touched by install, update, graduate, or remove. Agents follow `INSTALL.md`, a separate agent-facing procedure, rather than the human-facing quickstart these commands come from.

## Cautions and common failures

- Running without PowerShell 7 — the most common stop. Verify the version first.
- Pointing `-InstallRoot` at a folder with no `GRIMDEX.md` — Learn composes onto an existing Grimdex install; it does not create one.
- Implying or believing the one-liner skips cloning. It does not; it only relocates and re-fetches.
- Pinning matters: both paths use the release tag, not a moving branch. Do not substitute `main`.

## Related capabilities

- what-is-grimdex — the earlier page in this module covering what Learn is and how it relates to the base Grimdex harness.

## Official sources

- https://github.com/Ryfter/grimdex-learn — the public release repo; this is literally where the install commands and pinned release live.

## Provenance

This page was authored against this product's own locked decision records (D42 and the shipped QUICKSTART.md for install/bootstrap behavior; D28 for the path and ownership contract that guarantees student roots are never touched), not an external vendor doc. It should be fact-checked against those records before shipping.
