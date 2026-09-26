---
title: Quick browser editing with github.dev
module_id: git-and-github
capabilities:
  - github-dev-quick-edits
context7_library: /websites/github_en
context7_queries:
  - How do I edit files in a GitHub repository directly in the browser?
  - What is the github.dev editor and how do I open it?
  - Can I run code or use a terminal in github.dev?
official_sources:
  - https://docs.github.com/en/codespaces/the-githubdev-web-based-editor
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

github.dev is a browser-based VS Code editor that opens on any GitHub repository. Pressing the `.` key while viewing a repository page on github.com, or changing `github.com` to `github.dev` in the repository URL, opens the repository in this editor. It provides a familiar VS Code interface for searching across the repository and making lightweight multi-file edits, with no local installation required.

## When it is useful

- Quickly searching or browsing code in a repository without cloning it locally.
- Making small, lightweight edits across one or more files without setting up a development environment.
- Working from a machine or browser where you cannot install tools.
- Reviewing and adjusting documentation, configuration, or text files in place.

## Prerequisites

- A GitHub account.
- A repository you can view on github.com (public or one you have access to).
- No local installation is needed; the editor runs entirely in the browser.

## Current syntax

There is no command syntax. Two ways to open github.dev:

1. While viewing any repository page on github.com, press the `.` (period) key.
2. Edit the URL directly: change `github.com` in the repository address to `github.dev`.

## What happens (local and remote)

- The repository opens in a browser-based VS Code editor at the github.dev domain.
- You can search the repository and edit files using the standard VS Code editing interface.
- Edits made here exist only in the browser session until you commit them back to the repository (for example, through the source-control view, which creates a commit and optionally a pull request).
- Nothing runs on your machine; there is no terminal and no ability to execute code. It is editing only.

## Practical example

You spot a typo in a repository's README while browsing github.com. Press `.` on the repository page. The repo opens in the browser editor. Fix the typo, open the source-control panel, write a short commit message, and commit the change directly, or start a pull request with the fix. The whole sequence takes under a minute and requires no local clone.

## Explanation guidance

### Essential

github.dev is a full VS Code editing experience in the browser, opened by pressing `.` on any GitHub repository page or by swapping `github.com` for `github.dev` in the URL. It is for searching and making lightweight edits to files in the repository. It cannot run code and has no terminal, so it cannot replace a real development environment.

### Experienced-user note

Do not confuse github.dev with GitHub Codespaces. Both let you edit in a browser, but a Codespace is a full container-backed environment with a terminal, extensions, and the ability to run code, while github.dev is strictly an editor with no execution capability. Choose github.dev for quick edits and Codespaces when you need to build, run, or test.

### Optional deeper context

github.dev sits at the lightest end of GitHub's editing options. The web file editor on github.com handles single-file edits with minimal tooling, github.dev adds a richer multi-file VS Code experience, and Codespaces provides a complete cloud development environment. Each serves a different level of investment in the change.

## Cautions and common failures

- Expecting to run builds, tests, or any commands: github.dev has no terminal and cannot execute code. Use Codespaces for that.
- Believing edits are saved automatically: changes persist only in the browser session until committed back to the repository.
- Attempting to use it on a private repository you do not have access to: authentication and repository permissions still apply.
- Pressing `.` expecting a shortcut in a non-repository page: the keyboard shortcut works on repository pages.

## Related capabilities

- github-codespaces-basics
- in-browser-commits
- markdown-for-prs-issues

## Official sources

- https://docs.github.com/en/codespaces/the-githubdev-web-based-editor -- GitHub documentation describing the github.dev web-based editor, how to open it, and its limitations.

## Provenance

This page was authored against GitHub's official documentation (docs.github.com, specifically the page covering the github.dev web-based editor), retrieved via Context7. GitHub's documentation paths reorganize periodically, so content should be spot-checked against the current docs before shipping.