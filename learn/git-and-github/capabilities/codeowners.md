---
title: CODEOWNERS and review routing
module_id: git-and-github
capabilities:
  - codeowners
context7_library: /websites/github_en
context7_queries:
  - "Where does GitHub look for the CODEOWNERS file in a repository?"
  - "How do I map file paths to owners in a CODEOWNERS file?"
  - "How are code owners requested as reviewers on a pull request from a fork?"
  - "Does CODEOWNERS control who can push to a repository?"
official_sources:
  - https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
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

A `CODEOWNERS` file is a plain text file you add to a repository that maps file paths (or path patterns) to individuals or teams. When a pull request modifies a file matching one of those paths, GitHub automatically requests the listed owners as reviewers on that pull request.

## When it is useful

CODEOWNERS is useful when different people or teams are responsible for different parts of a codebase, and you want review requests to be routed to the right people without anyone manually picking reviewers. It is also useful as an organizational convention: the file itself documents who owns which area.

## Prerequisites

- A GitHub repository (the CODEOWNERS mechanism is a GitHub feature, not a core git feature).
- The owners listed in the file must be valid GitHub usernames or team references.
- Someone with appropriate repository access to add and commit the file.

## Current syntax

The file must be named `CODEOWNERS` (no extension) and can live in one of three locations:

- `.github/CODEOWNERS`
- `CODEOWNERS` at the repository root
- `docs/CODEOWNERS`

GitHub checks these locations **in that order** and uses only the first one it finds. If you have the file in `.github/`, a copy at the root will be ignored.

Each non-comment line maps a path pattern to one or more owners:

```
# comment lines start with #
*           @alice
/docs/      @docs-team
*.js        @alice @frontend-team
```

Paths are relative to the repository root. Owners are GitHub usernames (`@username`) or team references (`@org/team-name`).

## What happens (local and remote)

When a pull request is opened and its changed files match one or more patterns in the CODEOWNERS file, GitHub automatically requests the matching owners as reviewers. Those owners appear in the PR's reviewer list with a "code owner" indicator.

One nuance matters for external contributions: **for a pull request coming from a fork, the CODEOWNERS file that GitHub uses is the one on the PR's base branch** (in the upstream repository, if the base is the upstream repo). Changes to CODEOWNERS made in the PR branch itself do not affect the routing of that PR.

## Practical example

A repository wants `@alice` to own everything by default, the platform team to own all files under `src/platform/`, and the design team to own everything under `design/`. The team adds `.github/CODEOWNERS`:

```
*                        @alice
/src/platform/           @acme-org/platform-team
/design/                 @acme-org/design-team
```

When anyone opens a PR touching `src/platform/api/handler.js`, the platform team is automatically requested for review. A PR touching only `README.md` routes to `@alice` via the catch-all `*` pattern.

## Explanation guidance

### Essential

- CODEOWNERS lives in `.github/`, the repo root, or `docs/`; GitHub uses the first one it finds in that order.
- Each line maps a path pattern to one or more owners; matching PRs automatically get those owners requested as reviewers.
- For fork PRs, the CODEOWNERS file on the PR's base branch is what determines routing.
- CODEOWNERS is about review routing only -- it does not grant or restrict who can push code.

### Experienced-user note

Because only the first CODEOWNERS file found is used, teams sometimes confuse themselves by editing a file in a location GitHub isn't actually reading. Verify the location before debugging routing behavior. Team references (`@org/team-name`) work only if the team exists in the organization that owns the repository.

### Optional deeper context

CODEOWNERS pairs well with branch protection or rulesets: if you require review approval before merge, code owners are the people whose approvals you typically want to require. The two mechanisms are separate -- CODEOWNERS decides who is *asked*; branch protection decides whether reviews are *required*.

## Cautions and common failures

- **Wrong location:** a CODEOWNERS file in a non-searched location (or a second one shadowed by a higher-priority location) does nothing.
- **Routing vs. permissions confusion:** CODEOWNERS does not control push access. Repository roles and branch protection govern who can push and merge.
- **Fork PR nuance:** edits to CODEOWNERS inside a PR branch do not change how that PR's reviewers are requested.
- **Invalid owner references:** usernames or teams that don't exist (or teams in a different organization) won't be requested.

## Related capabilities

- branch-protection-rulesets
- repository-access-roles
- pr-issue-templates

## Official sources

- https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners -- GitHub's official documentation "About code owners": file locations, search order, path-to-owner mapping, automatic reviewer requests, and the fork/base-branch behavior.

## Provenance

This page was authored against the cited official GitHub documentation (docs.github.com, "About code owners"), retrieved via Context7. GitHub's documentation paths reorganize periodically; spot-check the official source against the current docs before shipping.