---
title: Standardizing projects with repository templates
module_id: git-and-github
capabilities:
  - repository-templates
context7_library: /websites/github_en
context7_queries:
  - How do I mark a repository as a template repository on GitHub?
  - What gets copied when I generate a new repository from a template?
  - What is the difference between generating from a template and forking a repository?
official_sources:
  - https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template
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

A GitHub repository can be marked as a **template repository** in its settings. Once marked, anyone can generate a brand-new repository from it: the files and directory structure are copied into the new repository, but the template's git history is **not** carried over. The new repository starts fresh.

## When it is useful

- You maintain a standard project skeleton (README, folder layout, config files, templates) and want every new project to start from the same baseline.
- Teams want repeatable project setup without copy-pasting files manually.
- You want to share a starting point publicly without people depending on or linking back to your original repository.

## Prerequisites

- A GitHub account.
- A repository containing the files and structure you want to standardize.
- Permission to change the repository's settings (to mark it as a template).

## Current syntax

There is no git command for this; it is a GitHub platform feature managed in the repository's Settings page. Under repository settings, there is a template option to mark the repository as a template. From then on, the GitHub UI (and the repository page's "Use this template" option) lets users generate a new repository from it.

## What happens (local and remote)

- Marking a repository as a template changes nothing inside the repository itself -- no commits, no branches, no files are modified.
- Generating a new repository from the template copies the files and structure into a new, independent repository. The template's commit history is not included; the new repo starts with its own fresh history.
- The new repository is not linked to the template (unlike a fork).

## Practical example

1. A team lead prepares a repository named `project-starter` containing a standard README, directory layout, and configuration files.
2. In the repository's Settings, they mark `project-starter` as a template repository.
3. When a new project starts, any team member goes to `project-starter` on GitHub and uses "Use this template" to generate a new repository, e.g. `customer-portal`.
4. `customer-portal` now contains the same files and structure as `project-starter`, but with no inherited git history and no ongoing link to the template.

## Explanation guidance

### Essential

- A template repository is a **starting-point factory**: mark one repo as a template, and anyone can stamp out fresh copies of its files and structure.
- The key difference from a fork: **a template copy has no git history and is not linked to the source**, while a fork keeps the full history and stays connected to the original (forks are used to propose changes back via pull requests).
- Templates are for *starting new, independent projects*; forks are for *contributing to or building on an existing project*.

### Experienced-user note

- Teams can keep multiple templates (e.g. one for web apps, one for scripts) and pick the right one per project.
- Since the generated repository is independent, changes to the template do **not** propagate to repositories already generated from it -- updates must be applied to each project separately.

### Optional deeper context

- Template repositories pair well with other standardization tools: PR/issue templates pre-fill descriptions in the new repos, and CODEOWNERS files can be included so review routing carries over to each generated project.

## Cautions and common failures

- **History is not copied.** If you expected the generated repo to preserve the template's commit history, use a fork instead.
- **No automatic updates.** Changes made to the template after generation do not appear in previously generated repositories.
- **Settings access required.** You must be able to modify repository settings to mark a repo as a template; you cannot do this with a plain `git` command.

## Related capabilities

- `forks-create-sync-contribute` -- forking keeps history and stays linked to the source; the complementary behavior.
- `pr-issue-templates` -- templates often ship alongside PR/issue templates in standard project setups.
- `codeowners` -- another file commonly included in a project template for consistent review routing.

## Official sources

- https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template -- GitHub Docs: creating a repository from a template (marking a repo as a template, what is copied, template vs. fork).

## Provenance

This page was authored against the cited official GitHub documentation (docs.github.com, "Creating a repository from a template"), retrieved via Context7. GitHub's documentation paths reorganize periodically, so spot-check the URLs against current docs before shipping.