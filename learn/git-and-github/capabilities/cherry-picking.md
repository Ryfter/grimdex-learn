---
title: Cherry-picking a single commit
module_id: git-and-github
capabilities:
  - cherry-picking
context7_library: /websites/git-scm
context7_queries:
  - How do I apply a single commit from one branch onto another branch in git?
  - What does git cherry-pick do and when should I use it?
  - How is cherry-picking different from merging a branch in git?
official_sources:
  - https://git-scm.com/docs/git-cherry-pick
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

Cherry-picking is a Git operation that takes one specific commit — and only that commit — and applies its changes onto your current branch as a brand-new commit. The command is:

```
git cherry-pick <commit>
```

Unlike a merge or rebase, which bring over an entire branch's history, cherry-pick copies the changes introduced by a single commit. It is a precise, one-commit-at-a-time operation.

## When it is useful

The classic use case is porting a bugfix to a release branch. Suppose a fix was committed on the main development branch, but a supported release branch (e.g. `release-1.4`) needs the same fix now, without pulling in all the newer development work. You check out the release branch and cherry-pick just that fix commit.

It is also useful when unrelated commits landed together on one branch and you only want one of them elsewhere, or when a commit went to the wrong branch and you want its changes on the right one.

## Prerequisites

- Git installed locally and basic familiarity with commits and branches.
- The commit you want must exist somewhere reachable — on another local or remote branch. Its commit hash (a short unique identifier is fine) is needed for the command.
- A clean working tree on the branch you are cherry-picking onto (commit or stash pending changes first; `git stash push -m "message"` can clear the tree temporarily).

## Current syntax

```
git cherry-pick <commit>
```

where `<commit>` is a commit reference such as a short or full hash (`a1b2c3d`), a branch name (picks that branch's tip commit), or any other commit expression Git understands. Plain `git cherry-pick <commit>` is the full scope of this capability; no other flags are required for the everyday use case.

## What happens (local and remote)

Cherry-picking is a local operation. Git computes the diff introduced by the chosen commit and applies it on top of your current branch, recording it as a **new commit**. The new commit has a different hash from the original — it is a separate object containing the same changes, with a new parent and identity. The original commit and its branch are untouched.

If the same changes already exist on the target branch, Git may report a conflict or an empty result; resolve conflicts as with any merge, or the operation may simply have nothing to add.

Cherry-picking does not push anything by itself. The new commit travels to the remote only when you `git push` the branch, exactly like any other local commit.

## Practical example

A fix for a login bug landed on `main` as commit `a1b2c3d`. The `release-1.4` branch needs it now:

```
git checkout release-1.4
git cherry-pick a1b2c3d
git push origin release-1.4
```

Git applies the login-fix changes onto `release-1.4` and creates a new commit there with the same message and author as the original, but a new hash. The release branch now contains the fix without any of `main`'s other recent work.

## Explanation guidance

### Essential

- Cherry-pick copies **one commit's changes** onto the branch you are currently on.
- It creates a **new commit** — same changes, same message by default, but a different commit hash. It is not the same object moved between branches.
- The most common scenario: a bugfix on the development branch is ported to a release branch without merging the whole branch.
- It is local until you push, like any other commit.

### Experienced-user note

- Because the cherry-picked commit is a new object, applying the same fix on many branches produces many distinct commits. If the branches later merge, Git normally handles the duplicated changes cleanly, but reviewers should be aware the fix appears under multiple hashes.
- The commit message and author are carried over by default, so attribution of the original fix is preserved on the release branch.
- If you cherry-pick the wrong commit or want to undo, the result is an ordinary commit on your branch — it can be reverted or the branch reset, depending on whether it has been pushed.

### Optional deeper context

- Cherry-picking is one of several ways to move work between branches; merges bring a whole branch's history, and rebase replays a series of commits. Cherry-pick is the narrowest tool: one commit, one application.
- Cherry-picked commits can conflict just like merges when the surrounding code has diverged; Git will pause and ask you to resolve, then continue, and the resulting commit is yours to finalize.

## Cautions and common failures

- **Conflicts.** If the code around the fix has changed on the target branch, cherry-pick can conflict. Resolve the conflicted files and complete the commit as usual.
- **Expecting the original hash.** The new commit has a different hash than the source commit. Tools or scripts referencing the original hash will not match.
- **Dirty working tree.** Start with uncommitted changes committed or stashed; cherry-pick applies on top of your current state.
- **Repeated fixes.** Cherry-picking the same fix onto several branches creates several near-identical commits; be deliberate about which branches need it.

## Related capabilities

- Branch protection & rulesets — release branches that receive cherry-picked fixes are commonly protected branches.
- Git stash — used to clear a dirty working tree before cherry-picking.
- Tags and GitHub Releases — release branches and tags often mark the versions that cherry-picked fixes ship in.
- GitHub CLI for PRs — a cherry-picked fix on a release branch may still go through a pull request on GitHub, depending on team workflow.

## Official sources

- https://git-scm.com/docs/git-cherry-pick — official git documentation for the `git cherry-pick` command.

## Provenance

This page was authored against the official Git documentation for `git cherry-pick` at git-scm.com, retrieved via Context7. GitHub's documentation paths reorganize periodically, and Git documentation evolves with releases; spot-check the cited source against the current docs before shipping.