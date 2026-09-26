# Learn

Learn is the education module for the [Grimdex](https://github.com/Ryfter/Grimdex)
coding harness. It does two things:

- Routes you onward to deeper documentation when you want more than the essentials.
- Gives more verbose, educational responses where stock Grimdex is terser.

It is not a course, not a classroom install, and not an "education edition" of
Grimdex. Course content is out of scope.

## Depth

Learn covers essentials only: what and why, plus a bit of how, then a link to
official documentation. Stopping early is the design, not an omission.

## Prerequisites

- An existing [Grimdex](https://github.com/Ryfter/Grimdex) install.
- Windows 10 or 11 with PowerShell 7 (`pwsh`) is the official platform.
- macOS with PowerShell 7 is best-effort, with no support obligation.

## Install

Humans follow [`QUICKSTART.md`](QUICKSTART.md). Agents follow
[`INSTALL.md`](INSTALL.md).

The taught path is two commands. Clone a release tag, not `main`:

    git clone --branch v0.2.0-fall2026-draft https://github.com/Ryfter/grimdex-learn <source>
    pwsh <source>/bootstrap.ps1 -InstallRoot <install>

A one-liner path (Path B) is documented in `QUICKSTART.md`. It is a convenience,
not the taught path, and it adds a trust hop.

## What it installs, and what it never touches

Install copies `learn/` into the Grimdex install and adds one pointer stanza to
`GRIMDEX.md`. It never writes under `projects/**`. That tree is the user's own
knowledge base.

## What's in the pack

Two modules, 18 pages:

- **Git and GitHub field guide** — 14 pages. Transferable git concepts; GitHub
  as one forge dialect.
- **Working with coding agents** — 4 pages. Prompting and verifying coding
  agents.

## Verifying

The test suite ships with the pack:

    pwsh -NoProfile -Command "Invoke-Pester -Path ./tests -CI"

## License

MIT. See [`LICENSE`](LICENSE).
