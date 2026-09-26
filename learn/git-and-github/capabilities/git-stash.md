---
title: Shelving work in progress with git stash
module_id: git-and-github
capabilities:
  - git-stash
context7_library: /websites/git-scm
context7_queries:
  - How do I temporarily save uncommitted changes in git?
  - What is the difference between git stash pop and git stash apply?
  - How do I recover a stash I accidentally dropped?
official_sources:
  - https://git-scm.com/docs/git-stash
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

`git stash` temporarily saves your uncommitted changes and returns your working tree to a clean state. The saved changes are stored on a stack of "stashes" that you can re-apply later -- useful when you need to switch tasks but your work isn't ready to commit.

## When it is useful

- You need to switch branches or pull updates, but you have half-finished edits you don't want to commit yet.
- An urgent fix comes in and you want a clean working tree without discarding your current work.
- You want to test whether a bug exists in a clean copy of the code, then restore your changes afterward.

## Prerequisites

- Git installed locally.
- A repository with uncommitted changes in tracked files.
- Basic familiarity with committing and switching branches.

## Current syntax

```
git stash push -m "message"   # save current changes with a descriptive label
git stash list                # show all stashed entries
git stash pop                 # re-apply the most recent stash and remove it from the list
git stash apply               # re-apply the most recent stash but keep it on the list
git stash drop                # delete a stash entry without applying it
```

## What happens (local and remote)

Stashing is entirely local. `git stash push -m "message"` saves the uncommitted changes and cleans the working tree; nothing is sent to any remote. The stashed entries live in a local list until you pop, apply, or drop them. Popping or applying restores the changes to your working tree as uncommitted edits again.

If a conflict occurs during `git stash pop` (for example, because the files changed since the stash was made), the stash entry is **not** removed from the list. You resolve the conflict, then remove the entry manually with `git stash drop`. Using `git stash apply` instead keeps the entry on the list by design, so you can retry or discard it deliberately.

## Practical example

```
$ git stash push -m "draft homepage redesign"
Saved working directory and index state On main: draft homepage redesign

$ git stash list
stash@{0}: On main: draft homepage redesign

# ... fix the urgent issue, commit it ...

$ git stash pop
# changes return to the working tree as uncommitted edits,
# and the entry is removed from the stash list
```

## Explanation guidance

### Essential

Stash is a shelf, not a commit. `push` puts your changes on the shelf; `list` shows what's there; `pop` takes the most recent item off the shelf and back into your working tree; `apply` copies it back but leaves a copy on the shelf; `drop` throws an entry away. The key nuance to teach: on a pop conflict the entry stays until you resolve and drop it, so a conflicted pop doesn't lose your stashed work.

### Experienced-user note

Prefer `apply` when the working tree may have changed since you stashed -- it leaves the entry in place, so if the apply goes badly you can still drop or re-apply it. Only use `pop` when you're confident the restore will succeed and you want the entry gone in one step.

### Optional deeper context

If a stash is dropped or cleared by mistake, it can sometimes be recovered via `git fsck --unreachable`, which can surface the underlying commit objects that are no longer referenced. This is an aside, not a routine procedure -- treat it as a last-resort recovery tool.

## Cautions and common failures

- Stash entries are easy to forget. Run `git stash list` regularly; unclaimed stashes are a common source of "where did my work go?" confusion.
- A drop removes the entry without applying it -- there's no confirmation prompt.
- After a conflicted pop, remember the stash entry still exists; resolve the conflict and `git stash drop` it, or you'll end up with duplicate stashes.
- Stash covers uncommitted changes; it is not a substitute for committing and pushing important work to a remote.

## Related capabilities

- partial-staging (sorting unrelated edits within a file into separate commits)
- git-worktrees (working on two branches simultaneously without stashing)

## Official sources

- https://git-scm.com/docs/git-stash -- official git documentation for `git stash`, covering push, pop, apply, list, and drop behavior.

## Provenance

Authored against the official git documentation at git-scm.com/docs/git-stash, retrieved via Context7. Spot-check against the current docs before shipping, since documentation paths and tool behavior can change over time.