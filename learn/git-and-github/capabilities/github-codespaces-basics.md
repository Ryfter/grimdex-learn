---
title: GitHub Codespaces basics (recognition level)
module_id: git-and-github
capabilities:
  - github-codespaces-basics
context7_library: /websites/github_en
context7_queries:
  - What is a GitHub Codespace and how does it differ from github.dev?
  - How do I configure a repeatable development environment per project with Codespaces?
  - Can I run code and use a terminal in a browser-based GitHub editor?
official_sources:
  - https://docs.github.com/en/codespaces/overview/what-is-github-codespaces
  - https://docs.github.com/en/codespaces/overview/using-github-your-workspace
last_checked: 2026-09-20
last_material_update: 2026-09-20
status: current
claim_class: everyday
safety_class: normal
version_stamp: fall-2026-0.1.0
admission:
  course_independent: true
  public_ready: true
  provenance: authored-against-official-docs
---

## What it is

GitHub Codespaces is a cloud-based development environment. Each Codespace is a container-backed environment running on GitHub's infrastructure, with a real terminal, editor, and extensions. Unlike a plain browser editor, a Codespace can actually execute code -- build, test, and run the project you have open.

## When it is useful

- When you want to work on a repository without installing a local development setup.
- When a project needs a specific, reproducible environment and you want every contributor to get the same one.
- When you need to run the code or tests (not just edit files) from a browser-based environment.
- For quick onboarding: open a Codespace and start working instead of configuring a machine.

## Prerequisites

- A GitHub account with access to the repository.
- No local installation is required; everything runs in the browser or in a supported desktop editor connected to the cloud environment.

## Current syntax

Codespaces are launched from the repository page on github.com (Code button -> Codespaces tab) or via the GitHub CLI. Per-project configuration is done through repository files (dev container configuration) so the environment is defined in the repo itself and repeated for each new Codespace.

## What happens (local and remote)

When you start a Codespace, GitHub provisions a container for that repository, checks out the code, and opens an editor connected to that container. Any terminal commands run inside the container, so builds, tests, and running code work as they would on a local machine. Changes can be committed and pushed back to the repository from inside the Codespace. The environment can be discarded and recreated, so setups remain consistent.

## Practical example

A team member opens a repository on github.com, starts a Codespace, opens the terminal inside it, installs dependencies, runs the test suite, edits a file, commits, and pushes -- all without installing anything locally. A different teammate opens the same repository and gets the identical environment, because the configuration lives in the repository.

Contrast: github.dev (pressing `.` on a repository page, or changing `github.com` to `github.dev` in the URL) opens a browser-based VS Code editor for searching and lightweight multi-file edits. github.dev has no terminal and cannot run code. Codespaces can do both.

## Explanation guidance

### Essential

- Codespaces = a full cloud development environment (container-backed) with a real terminal and the ability to run code.
- github.dev = an in-browser editor only; no terminal, no running code.
- Environments are configurable per project so every contributor gets a repeatable setup.
- Recognition level: know what it is, when to reach for it, and how it differs from github.dev. Detailed setup/administration is not required.

### Experienced-user note

- Because the environment is defined by repository configuration, onboarding time drops and "works on my machine" issues shrink. Codespaces can also be opened from a pull request view to review and run changes in context.

### Optional deeper context

- A Codespace is disposable: it can be stopped, rebuilt, or deleted and recreated from the same repository configuration, so a broken environment can be replaced rather than repaired.
- Codespaces usage relates to account/quota considerations on GitHub-hosted infrastructure; check current GitHub plans for details.

## Cautions and common failures

- Confusing Codespaces with github.dev: only Codespaces can run code and use a terminal.
- Expecting long-running processes to persist forever: Codespaces are environments that can be stopped and restarted; unsaved work should be committed or pushed.
- Assuming configuration is automatic for every repo: repeatable environments depend on the repository shipping the appropriate dev container configuration.

## Related capabilities

- github-dev-quick-edits (github.dev, the edit-only in-browser editor)
- in-browser-commits (editing and committing a file directly on github.com)
- github-cli-for-prs (using the `gh` CLI, which can also be used inside a Codespace)
- pr-issue-templates (repo-level configuration files that shape contributor workflow)

## Official sources

- https://docs.github.com/en/codespaces/overview/what-is-github-codespaces -- GitHub's overview of what Codespaces is and how it works.
- https://docs.github.com/en/codespaces/overview/using-github-your-workspace -- GitHub documentation on using Codespaces as a development workspace.

## Provenance

This page was authored against GitHub's official Codespaces documentation (docs.github.com Codespaces overview and workspace pages), retrieved via Context7 (library `/websites/github_en`). It should be spot-checked against current docs before shipping, since GitHub's documentation paths reorganize periodically. Recognition level only: no Codespaces setup or administration depth is claimed.