---
title: "Forks: create, sync, and contribute"
module_id: git-and-github
capabilities:
  - forks-create-sync-contribute
context7_library: /websites/github_en
context7_queries:
  - What is a fork and how is it different from a clone?
  - How do I create a fork and open a pull request to the upstream repository?
  - How do I sync a fork with its upstream repository on GitHub?
official_sources:
  - https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/about-forks
  - https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/syncing-a-fork
  - https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork
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

A fork is a personal copy of someone else's repository under your own GitHub account. You do not get write access to the original (the "upstream") repository, but your fork is fully yours: you can push commits to it freely. A clone, by contrast, is just a local copy of a repository on your machine -- it changes nothing about where you have permission to push. A common contributing workflow uses both: fork the repository on GitHub, clone your fork locally, work there, and push to your fork.

Because your fork is under your account, you can open a pull request from it into the upstream repository. The maintainers review and merge that PR into the original project. This is the standard way to propose changes to repositories you cannot push to directly.

Over time the upstream repository moves forward while your fork stays put. "Syncing a fork" means pulling the upstream's recent commits into your fork so it does not drift stale. GitHub's web interface and `gh repo fork` both offer a way to sync a fork with its upstream.

## When it is useful

- Contributing to an open-source project or any repository you do not have write access to.
- Making experimental changes to a project without affecting the original repository.
- Maintaining a long-lived personal variation of someone else's project while still keeping it up to date with upstream improvements.
- Any situation where you want your own GitHub-hosted copy of a repository to push to.

## Prerequisites

- A GitHub account.
- The upstream repository's URL (or just its GitHub page).
- Optional: the `gh` CLI or Git installed locally if you prefer working from the command line rather than the GitHub web interface.

## Current syntax

Forking and contributing are done through GitHub's interface; the underlying pushes and commits use ordinary Git commands.

- Fork on GitHub: the "Fork" button on the repository's page, or `gh repo fork <owner>/<repo>`.
- Clone your fork: `git clone <your-fork-url>`.
- Commit and push to your fork: `git add`, `git commit`, then `git push` to your fork's branch.
- Open the pull request: from your fork's GitHub page (GitHub offers a "Compare & pull request" prompt after a new push), or with `gh pr create` run from your fork's clone, targeting the upstream repository as the base.
- Sync the fork: via the "Sync fork" control on your fork's GitHub page, or via `gh repo fork --sync` style syncing offered by the GitHub CLI. This pulls the upstream's changes into your fork.

## What happens (local and remote)

Creating a fork happens entirely on GitHub's servers: GitHub copies the repository (with its history) into a new repository under your account. Nothing on your machine changes yet.

Cloning your fork brings that copy down to your local machine. When you push, the commits go to your fork on GitHub -- the upstream repository is untouched. Opening a pull request from your fork into the upstream creates a PR owned by the upstream project, where maintainers can review it, request changes, and merge it. Once merged, the changes exist in the upstream repository; your fork still contains its own history.

Syncing updates your fork on GitHub's side from the upstream. If your fork has its own commits that conflict with recent upstream changes, syncing can require resolving those conflicts. Without periodic syncing, a fork drifts stale: future pull requests from it may include unrelated merge noise or conflict with upstream work, making review harder.

## Practical example

You want to fix a typo in a project's README that you cannot push to.

1. On the project's GitHub page, click "Fork". You now have `yourname/project`.
2. Clone your fork: `git clone https://github.com/yourname/project.git` and `cd` into it.
3. Create a branch for the fix: `git checkout -b fix-readme-typo`.
4. Edit the README, then stage and commit: `git add README.md` and `git commit -m "Fix typo in README"`.
5. Push to your fork: `git push origin fix-readme-typo`. Your fork's page now shows a prompt to open a pull request against the upstream.
6. Open the PR from your fork into the upstream repository's default branch. Maintainers review and merge it.
7. A week later, before your next contribution, you sync your fork with upstream (via the "Sync fork" button or the `gh` CLI) so it includes the merged fix and any other recent changes. Your next branch starts from current upstream code.

## Explanation guidance

### Essential

A fork is your copy on GitHub; a clone is your copy on your machine. You push to your fork (you own it) and open a pull request from it into the original repository (you don't own that one). Sync the fork periodically so it doesn't fall behind the original -- stale forks make messy pull requests.

### Experienced-user note

Fork and clone serve different layers: fork solves the permission problem (where you can push), clone solves the location problem (where you work). A frequent pattern is fork-on-GitHub plus clone-of-the-fork locally. For commits that reference upstream issues, note that GitHub links issues to PRs via closing keywords in the PR description or commit message (e.g. "Closes #42"), which auto-closes the issue when the PR merges into the default branch.

### Optional deeper context

Your fork keeps full git history from the moment of forking, but it does not automatically receive later upstream commits -- that is exactly what syncing addresses. Internally, a PR from a fork is compared against the upstream branch you designate as its base, so keeping your fork's branch closely aligned with upstream reduces the diff a maintainer has to review. Repositories that accept many fork-based contributions often publish contributing guides asking that each PR come from a short-lived, freshly-synced branch rather than a long-lived one.

## Cautions and common failures

- Confusing fork with clone: cloning the upstream directly gives you a local copy, but you still cannot push to it. Without forking first, you have nowhere to push your branch and cannot open a PR from it.
- Forks drift stale. If you fork once and contribute months later from the stale fork, your PR may include unrelated old commits or conflicts. Sync before starting new work.
- Pushing to the wrong remote: after forking and cloning, verify `git remote -v` points at your fork (commonly called `origin`), not the upstream.
- A merged PR does not automatically update your fork. Your fork retains its own history until you sync it.
- Long-lived personal divergences from upstream can accumulate conflicts that make syncing increasingly painful; sync small and often.

## Related capabilities

- branch-protection-rulesets (upstream maintainers may require reviews or checks before your PR can merge)
- codeowners (the upstream's CODEOWNERS file determines who gets requested as reviewers on your PR)
- markdown-for-prs-issues (formatting your PR description well)
- linking-issues-to-prs (referencing and auto-closing issues from your PR)
- github-cli-for-prs (`gh pr create`, `gh pr status`, `gh pr checkout` for fork-based workflows)

## Official sources

- https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/about-forks -- GitHub's explanation of what forks are and how they differ from clones.
- https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/syncing-a-fork -- GitHub's guide to syncing a fork with its upstream repository.
- https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork -- GitHub's guide to opening a pull request from a fork.

## Provenance

This page was authored against GitHub's official documentation (docs.github.com pages on forks, syncing a fork, and creating a pull request from a fork), retrieved via Context7. It should be spot-checked against current docs before shipping, since GitHub's documentation paths reorganize periodically.