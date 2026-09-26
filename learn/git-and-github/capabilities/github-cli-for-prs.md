---
title: GitHub CLI (gh) for PRs
module_id: git-and-github
capabilities:
  - github-cli-for-prs
context7_library: /websites/github_en
context7_queries:
  - How do I create a pull request from the command line with gh pr create?
  - What flags does gh pr create support like draft, fill, reviewer, and base?
  - How do I check out a pull request locally with gh pr checkout and put it in a worktree?
official_sources:
  - https://cli.github.com/manual/gh_pr_create
  - https://cli.github.com/manual/gh_pr_status
  - https://cli.github.com/manual/gh_pr_checkout
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

The GitHub CLI (`gh`) is GitHub's official command-line tool. It lets you work with GitHub-hosted features -- most importantly pull requests -- directly from a terminal, without opening a browser. The three pull-request commands covered here are `gh pr create` (open a PR), `gh pr status` (see where your PRs stand), and `gh pr checkout` (pull someone else's PR onto your local machine to try or review it).

## When it is useful

- You already work in a terminal with git and want to open a PR in the same breath as your push, instead of switching to the browser.
- You want to open a pull request as a draft first (`--draft`), or pre-fill the title and description from your commit messages (`--fill`).
- You want a quick, at-a-glance summary of your open PRs, their CI checks, and review status.
- You want to download and test a teammate's pull request locally before approving it.

## Prerequisites

- Git installed and a basic working knowledge of commits and branches.
- The GitHub CLI installed (`gh`) and authenticated with your GitHub account.
- A repository hosted on GitHub (your own, or one you have write access to).

## Current syntax

Open a pull request:

```
gh pr create
```

Common flags:

- `-d` / `--draft` -- create the PR as a draft.
- `-f` / `--fill` -- use your commit information for the title and body instead of being prompted.
- `-r` / `--reviewer` -- request a specific reviewer.
- `-B` / `--base` -- set the branch the PR should merge into.
- `-w` / `--web` -- open the browser for the PR instead of finishing in the terminal.

See a summary of your PRs:

```
gh pr status
```

For more detailed CI check output, use `gh pr checks`.

Check out a pull request locally:

```
gh pr checkout <number>
```

`gh pr checkout` can also be run with no number to interactively pick from recent PRs. The `--worktree <path>` option checks the PR out into a separate git worktree directory, so you do not disturb your current working copy.

## What happens (local and remote)

- `gh pr create` sends a request to GitHub to open a PR from your pushed branch into the target base branch. Nothing is merged yet -- it creates the reviewable proposal on github.com. GitHub's web UI, PR/issue templates, and CODEOWNERS review requests all apply exactly as if you had opened the PR in a browser.
- `gh pr status` is read-only: it lists the PRs most relevant to you with their numbers, titles, CI check results, and review status.
- `gh pr checkout <number>` fetches the PR's changes and checks them out as a local branch in your working copy, so you can build, run, and test them. With `--worktree <path>`, the PR is checked out into a separate directory linked to the same repository, and your main working copy is untouched.

## Practical example

You have just pushed a bugfix branch and want a draft PR with reviewers, without leaving the terminal:

```
gh pr create --draft --fill --reviewer alicet --base main
```

Check how the PR and your other open PRs are doing:

```
gh pr status
```

A teammate's PR #42 needs testing on your machine. Check it out into a separate directory so your own in-progress work is not disturbed:

```
gh pr checkout 42 --worktree ../pr-42-test
```

Test it, then return to your own branch in your original directory as normal.

## Explanation guidance

### Essential

The core mental model: `gh pr create` opens a PR (a proposal to merge one branch into another); it does not merge anything. `gh pr status` is a read-only dashboard. `gh pr checkout` is the "let me actually run this code" step -- it brings the PR's changes onto your machine as an ordinary git checkout, and everything you already know about running and testing code applies.

### Experienced-user note

`--fill` is a time-saver when your commit messages are already well written: the PR title and body are derived from your commit info, so you skip the interactive prompts. `--draft` pairs well with it for opening an early, clearly-not-final PR. The `--worktree` option on `gh pr checkout` relies on git worktrees under the hood -- a second directory sharing the same repository -- which is why your original checkout stays intact.

### Optional deeper context

`gh pr checkout` without a number runs interactively, letting you pick from recent PRs rather than typing one. `gh pr checks` gives a more detailed view of CI checks than the summary in `gh pr status`. The `--web` flag on `gh pr create` is a middle path: start the PR from the terminal, then finish reviewing it in the browser.

## Cautions and common failures

- `gh pr create` will fail if your branch has not been pushed yet; push first.
- If the branch is not authenticated (`gh auth login` not done), `gh` commands will fail.
- Checking out a PR locally gives you its code, not its eventual result -- CI failures on the PR will not show up until you run or observe the checks; use `gh pr status` or `gh pr checks` for that.
- `gh pr checkout` changes your working copy to the PR's branch; if you have uncommitted work, stash it first (`git stash push -m "message"`) or use the `--worktree` option to avoid touching your current checkout.
- A draft PR (`--draft`) cannot be merged until it is marked ready for review on GitHub.

## Related capabilities

- git-and-github:git-worktrees -- the underlying mechanism behind `gh pr checkout --worktree`.
- git-and-github:forks-create-sync-contribute -- PRs from forks follow the same review flow.
- git-and-github:markdown-for-prs-issues -- formatting PR descriptions (which `--fill` populates from commits).
- git-and-github:linking-issues-to-PRs -- closing keywords in PR descriptions auto-close issues on merge.
- git-and-github:branch-protection-rulesets -- rules that must pass before a PR can merge.
- git-and-github:pr-issue-templates -- templates that pre-fill PR descriptions.

## Official sources

- https://cli.github.com/manual/gh_pr_create -- GitHub CLI manual page for `gh pr create`, including the `--draft`, `--fill`, `--reviewer`, `--base`, and `--web` flags.
- https://cli.github.com/manual/gh_pr_status -- GitHub CLI manual page for `gh pr status`, the PR summary command.
- https://cli.github.com/manual/gh_pr_checkout -- GitHub CLI manual page for `gh pr checkout`, including interactive selection and the `--worktree` option.

## Provenance

This page was authored against the official GitHub CLI documentation at cli.github.com (the `gh pr create`, `gh pr status`, and `gh pr checkout` manual pages), retrieved via Context7. It should be spot-checked against the current CLI docs before shipping, since documentation paths and command behavior can change between `gh` releases.