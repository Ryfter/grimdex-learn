---
title: GitHub Desktop essentials
module_id: git-and-github
capabilities:
  - github-desktop-essentials
context7_library: /websites/github_en
context7_queries:
  - How do I clone, stage, commit, and push with GitHub Desktop?
  - Can I create branches and pull requests in GitHub Desktop without the terminal?
  - Who is GitHub Desktop designed for compared to the command line?
official_sources:
  - https://docs.github.com/en/desktop
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

GitHub Desktop is GitHub's official graphical (GUI) client for working with Git and GitHub. It is a desktop application that covers the core version-control workflow -- cloning a repository, staging changes, committing, pushing, creating branches, and opening pull requests -- through a visual interface, with no terminal commands required.

## When it is useful

It is aimed at users who prefer a visual workflow over typing commands. Typical situations include:

- You are new to version control and want to learn commit, branch, and push concepts without also learning command syntax.
- Your work is mostly editing files and saving snapshots, not complex repository surgery.
- You want a clear visual of which files changed and which lines are staged before committing.
- You manage documents, configs, or content rather than doing daily software builds.

## Prerequisites

- A GitHub account.
- GitHub Desktop installed on your computer (it is a free download from GitHub).
- Basic understanding of what a repository, commit, and branch are.

## Current syntax

GitHub Desktop is operated through its interface rather than commands. The equivalent actions map to familiar git operations:

- **Clone**: File > Clone Repository.
- **Stage**: check files (or individual lines/hunks) in the Changes panel.
- **Commit**: write a summary (and optional description), then click Commit.
- **Push/pull/fetch**: the Repository menu or the toolbar buttons.
- **Branch**: the Current Branch dropdown, then New Branch.
- **Pull request**: the Branch menu's "Create Pull Request" option, which opens a draft PR on github.com.

## What happens (local and remote)

Everything happens against the same underlying git repository you would use on the command line, so the two tools stay in sync. Cloning copies the repository from GitHub to your machine. Staging selects which changes go into the next commit; committing records them locally. Pushing uploads your commits to GitHub so others can see them; pulling brings others' commits down. Creating a branch gives you an isolated line of work, and creating a pull request proposes merging it into another branch on GitHub, where teammates review it.

## Practical example

1. Install GitHub Desktop and sign in to your GitHub account.
2. Choose File > Clone Repository, pick a repository, and choose a local folder.
3. Edit a few files in your editor, then return to GitHub Desktop: the changed files appear in the Changes panel.
4. Tick the files to stage, write a short summary such as "Update intro text," and click Commit.
5. Click Push origin to send the commit to GitHub.
6. Later, open the Current Branch dropdown, create a branch called `update-docs`, make commits on it, and use Branch > Create Pull Request to propose the change on GitHub.

## Explanation guidance

### Essential

Frame GitHub Desktop as the same git, different surface: every button performs a real git operation (stage, commit, push, branch), and anything done in Desktop is visible to colleagues using the command line and vice versa. Emphasize that beginners can learn the *concepts* of version control here without memorizing command-line flags.

### Experienced-user note

Desktop handles the common workflow well, but complex operations -- interactive rebases, cherry-picks, partial-file staging at hunk granularity in some edge cases, stash management, and worktrees -- are either limited or absent, so experienced users often keep a terminal alongside it. Desktop and the CLI can be mixed freely on the same repository.

### Optional deeper context

GitHub Desktop is one of several ways to interact with GitHub without memorizing commands; others include the `gh` command-line tool, editing files directly on github.com, and the github.dev browser editor. Each suits a different weight of task: Desktop for a visual local workflow, `gh` for scripted/terminal workflows, the web editors for quick changes with no local setup.

## Cautions and common failures

- Not every git operation is available in the GUI; some tasks still require the command line.
- Large binary files can still bloat the repository; Git LFS is a separate setup topic.
- Pushing frequently (small commits) is safer than accumulating a huge, hard-to-review commit.
- If a teammate has force-pushed or history has diverged, Desktop may prompt to pull or discard -- read the prompt before confirming, since discarding loses local changes.

## Related capabilities

- github-cli-for-prs
- in-browser-commits
- github-dev-quick-edits
- git-worktrees
- partial-staging

## Official sources

- https://docs.github.com/en/desktop -- GitHub Desktop official documentation hub on docs.github.com.

## Provenance

This page was authored against GitHub's official Desktop documentation (docs.github.com/en/desktop), retrieved via Context7. GitHub's documentation paths reorganize periodically, so spot-check the cited URL against current docs before shipping.