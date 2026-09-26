---
title: Working across branches with worktrees
module_id: git-and-github
capabilities:
  - git-worktrees
context7_library: /websites/git-scm
context7_queries:
  - How do I check out two branches at the same time with git worktree?
  - How do I work on another branch without stashing my current changes?
  - What does git worktree add do?
official_sources:
  - https://git-scm.com/docs/git-worktree
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

A git **worktree** is a second (or third) working directory linked to the same
repository. Instead of having one folder where you constantly switch branches, you
can check out a different branch into a separate directory and work on both at
the same time. The command to create one is:

```
git worktree add <path> <branch>
```

The new directory is a real folder on disk with its own checked-out files, but it
shares the same commit history and repository data as your main working copy.
It is not a second clone; it is the same repository, viewed from another
directory.

## When it is useful

- You are in the middle of unfinished work on one branch and need to urgently fix
  a bug on another branch. Normally you would have to stash or commit your
  in-progress changes first; with a worktree you simply work in the other
  directory and leave your in-progress work untouched.
- You want to compare two versions side by side (for example, run the old
  version in one folder and the new one in another).
- A long-running task (build, test run) is tied up one directory, and you want to
  keep working in the meantime.

## Prerequisites

- Git installed on your machine.
- An existing repository with at least one branch to check out.
- The branch you add to the new worktree must not already be checked out in
  another worktree (Git does not allow the same branch to be checked out in two
  places at once).

## Current syntax

```
git worktree add <path> <branch>
```

- `<path>` is where the new directory will be created (for example
  `../myrepo-hotfix`).
- `<branch>` is the branch to check out there.

## What happens (local and remote)

`git worktree add` creates a new directory on your machine, checks out the given
branch into it, and records the link between that directory and your repository.
All of this is local. The repository's commit history, branches, and remotes are
shared, so anything you commit in the worktree is visible from your main working
copy and, when you push, from the remote as usual. Nothing is pushed or fetched
by creating a worktree itself; normal `git push` / `git pull` behavior applies
from whichever directory you are working in.

## Practical example

You are working on a feature branch but a bug fix is needed on `main` right away:

```
git worktree add ../myproject-hotfix main
cd ../myproject-hotfix
# fix the bug, commit, push as usual
cd ../myproject
# your feature work is exactly as you left it -- no stashing was needed
```

You now have two directories: one on your feature branch, one on `main`, both
pointing at the same repository.

## Explanation guidance

### Essential

A worktree is a separate directory linked to the same repository, letting you
have two branches checked out at once -- one per directory. It removes the need
to stash or half-commit work just to switch tasks. Create one with
`git worktree add <path> <branch>` and work in that directory like any other
checkout.

### Experienced-user note

Because the directories share one repository, commits made in one worktree are
immediately visible in the other (just run `git log` or `git checkout` there).
A branch can only be checked out in one worktree at a time, which prevents
accidental conflicting edits to the same branch from two directories.

### Optional deeper context

Worktrees are useful for comparing behavior side by side -- for instance, keeping
the last released version checked out in one directory while developing in
another. When a worktree directory is no longer needed, it can be removed with
Git's worktree management commands so the repository's record of it stays clean.
This page covers the core `git worktree add` capability only, not full worktree
administration.

## Cautions and common failures

- The same branch cannot be checked out in two worktrees at once; if you try,
  Git refuses. Check out a different branch, or create the worktree for a new
  branch instead.
- The new directory is inside your repository's reach but is a real folder on
  disk -- deleting it by hand (rather than through Git's worktree removal)
  leaves a stale entry in the repository's worktree records.
- Uncommitted changes in a worktree are just that -- uncommitted. They are not
  shared or saved anywhere else; commit or stash them as you would in any
  working directory.
- It is easy to forget which directory you are in. Check the current branch
  before committing, since each directory has its own checked-out branch.

## Related capabilities

- `git-stash` -- the alternative for briefly setting aside uncommitted changes
  when switching branches in a single working copy.
- `github-cli-for-prs` -- `gh pr checkout` can target a separate worktree path
  when reviewing a PR locally.
- `cherry-picking` -- often used alongside multiple checkouts when porting a
  fix between branches.

## Official sources

- https://git-scm.com/docs/git-worktree -- official Git documentation for the
  `git worktree` command and how linked working trees behave.

## Provenance

This page was authored against the official Git documentation cited above
(git-scm.com, specifically the `git-worktree` manual page), retrieved via
Context7. Because Git's documentation site reorganizes URLs periodically and
behavior details can change between releases, the content should be
spot-checked against the current official docs before shipping.