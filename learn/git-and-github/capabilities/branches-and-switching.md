---
title: Branches and switching
module_id: git-and-github
capabilities:
  - branches-and-switching
context7_library: /websites/git-scm
context7_queries:
  - git branch list create current asterisk movable pointer ref commit
  - git switch branch -c create HEAD moves working tree index
  - git switch uncommitted local changes carried refused overwrite
  - git checkout older branch switch overloaded path restore
  - detached HEAD check out commit git switch - previous branch
  - default branch main master GitHub clone base pull request
official_sources:
  - https://git-scm.com/docs/git-branch
  - https://git-scm.com/docs/git-switch
  - https://git-scm.com/docs/git-checkout
  - https://git-scm.com/docs/gitglossary
  - https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell
  - https://git-scm.com/docs/user-manual
  - https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-branches
last_checked: 2026-08-01
last_material_update: 2026-08-01
status: current
claim_class: foundational
safety_class: normal
version_stamp: fall-2026-0.1.0
admission:
  course_independent: true
  public_ready: true
  provenance: authored-against-official-docs
---

## What it is

A branch in Git is a movable pointer (a ref) to a commit — the tip of a line of
development. Creating a branch does not copy the project; it records a new name
that points at an existing commit, which is why branches are cheap to create and
discard. Every repository has a current branch that `HEAD` tracks; switching
branches moves `HEAD` to that other name and updates the working tree and index
to match the commit at its tip. The default branch is the repository's primary
line of development: locally it is whatever branch a new repository starts on,
and on a forge such as GitHub it is the branch shown by default, checked out on
clone, and used as the usual base for new work.

## When it is useful

Reach for branches any time work should progress without disturbing another line
of history: a feature, a bug fix, an experiment, or a short-lived parallel
attempt. Switching is how you move your working tree between those lines so
commits land on the intended tip. Listing branches answers "what lines exist
here, and which one am I on?" Creating and switching early keeps unrelated
changes from stacking on the same tip before they are ready to integrate.

## Prerequisites

- A Git repository has been initialized (`git init`) or cloned, and the current
  directory is inside it.
- At least one commit exists so a branch tip can point at a real commit (a brand-new
  empty repository may still have an unborn default branch until the first commit).
- For switching between existing tips, those branch names already exist locally
  (or will be created as part of the switch).

## Current syntax

```
git branch
git branch <name>

git switch <branch>
git switch -c <new-branch>
git switch -
```

- `git branch` with no arguments lists local branches; the current branch is
  marked with an asterisk (`*`).
- `git branch <name>` creates a new branch that points at the current `HEAD`
  (or at a start-point if one is given) but does not switch to it.
- `git switch <branch>` switches to an existing branch: `HEAD` moves to that
  branch, and the working tree and index are updated to match its tip.
- `git switch -c <new-branch>` creates a new branch at the current commit (or a
  given start-point) and switches to it in one step.
- `git switch -` switches back to the previously checked-out branch (or commit).

Older material and some tools still use `git checkout` for the same branch
operations; it is the earlier, overloaded form that both switches branches and
restores files. Prefer `git switch` for branch changes.

## What happens (local and remote)

Locally, creating a branch writes a new ref under the branch namespace that
points at a commit. It does not change files by itself. Switching moves `HEAD`
to the chosen branch and updates the working tree and index to that tip, so the
files you see match the snapshot the branch currently names. New commits then
advance that branch's tip while other branch names stay where they were.

Uncommitted changes in the working tree or index do not always block a switch.
If those changes do not conflict with the files that differ between the current
tip and the target tip, Git carries them across and leaves them uncommitted on
the new branch. If switching would overwrite local modifications, Git refuses the
switch and leaves you on the original branch with those changes intact.

None of this publishes a branch name by itself. Local branch names exist only in
this repository until you push them to a remote. On GitHub, the default branch
is the repository's primary branch (commonly `main` for new repositories): it is
what visitors see first, what a clone checks out, and the usual base for pull
requests. A pull request is a forge review workflow for proposing to integrate
one branch into another; it is not the same thing as `git pull`, which fetches
from a remote and integrates into your current branch.

## Practical example

Starting from a project directory with an existing commit history on the current
branch, create a side line of work, switch to it, and list branches:

```
$ git branch feature-notes
$ git switch feature-notes
$ git branch
* feature-notes
  main
```

Or create and switch in one step, then return to the previous branch:

```
$ git switch -c feature-notes
$ echo "Draft note" >> notes.txt
$ git add notes.txt
$ git commit -m "Add a draft note on the feature branch"
$ git switch -
```

If uncommitted edits would be overwritten by a switch, Git aborts and keeps you
on the current branch so those edits are not lost. Commit, stash, or otherwise
resolve the conflicting paths before switching again.

## Explanation guidance

### Essential

A branch is a named pointer to a commit, not a full copy of the project. Create
with `git branch` (pointer only) or `git switch -c` (create and move there).
Switch with `git switch` so `HEAD` follows the chosen name and the working tree
matches that tip. The asterisk in `git branch` output marks the current branch.
Uncommitted work comes along when it is compatible with the target; if a switch
would overwrite local changes, Git refuses. Branch names stay local until you
push them. Prefer `git switch` over the older multi-purpose `git checkout` for
branch movement.

### Experienced-user note

`git switch -c <name>` is the transactional equivalent of `git branch <name>`
followed by `git switch <name>`: the new branch is not left half-created if the
switch cannot complete. `git switch -` (and the `@{-1}` form) undoes the last
branch or commit switch without you having to remember the previous name. The
default branch is a convention plus forge configuration, not a special Git object
type: any branch can hold that role. On GitHub, the default branch is also the
usual base for pull requests; integrating that work still means merging or
rebasing Git history, not treating the pull request as a substitute for `git pull`.

### Optional deeper context

Branch heads live as refs (classically under `refs/heads/`) that store the object
name of the tip commit; creating a branch is essentially writing that small ref.
`HEAD` is normally a symbolic ref to the current branch head, so commits advance
the branch automatically. When `HEAD` points at a raw commit instead of a branch
name, you are in detached `HEAD` state: new commits are reachable only through
`HEAD` (and the reflog) until a branch or tag names them. The working tree and
index update on switch is the same checkout machinery used elsewhere; the refuse-
on-overwrite rule exists so a branch change never silently discards uncommitted
work that collides with the target tree.

## Cautions and common failures

- **`git branch <name>` does not switch.** It only creates the pointer. Run
  `git switch <name>` (or use `git switch -c` from the start) before expecting
  new commits to land on that branch.
- **Switch refused because of local changes.** If paths you modified differ
  between the current tip and the target tip, Git aborts with an error instead of
  overwriting those files. Commit the work, move it aside (for example with
  stash), or otherwise resolve the conflict before switching.
- **Assuming a local branch exists on the remote.** Creating or committing on a
  branch only updates this repository. Until you push the branch name, remotes
  and collaborators cannot see it under that name.
- **Detached `HEAD` from checking out a commit directly.** Checking out a raw
  commit (or tag that resolves to a commit) rather than a branch name puts `HEAD`
  on that commit without a branch tip to advance. Inspection is fine; if you need
  to keep new commits, create a branch there (`git switch -c <name>`). To leave
  detached state and return to the previous branch, use `git switch -` or
  `git switch <branch>`.
- **Confusing a pull request with `git pull`.** A pull request is a GitHub (or
  similar forge) proposal to integrate branches. `git pull` is a local Git
  command that fetches and then merges or rebases into your current branch.

## Related capabilities

- Commits and history — branch tips point at commits; switching chooses which
  tip new commits extend.
- Staging and the working tree (`git add`, `git status`) — uncommitted work
  interacts with switch as described here.
- Merging and integrating branches — how parallel tips are combined after work
  on a branch is ready.
- Pushing and remotes — how a local branch name becomes visible on a remote.

## Official sources

- <https://git-scm.com/docs/git-branch> — list, create, and current-branch
  marker for branches.
- <https://git-scm.com/docs/git-switch> — switch, create-and-switch (`-c`),
  previous branch (`-`), and refuse-on-overwrite behavior for local changes.
- <https://git-scm.com/docs/git-checkout> — older overloaded form for branch
  switching and file restore; detached `HEAD` section.
- <https://git-scm.com/docs/gitglossary> — branch, `HEAD`, detached `HEAD`, and
  related terms.
- <https://git-scm.com/book/en/v2/Git-Branching-Branches-in-a-Nutshell> —
  branch as a movable pointer, cheap creation, and `HEAD` movement on switch.
- <https://git-scm.com/docs/user-manual> — what a branch is and how history is
  named by refs.
- <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-branches>
  — default branch on GitHub, clone checkout, and pull request base role.

## Provenance

Authored 2026-08-01 against the official Git and GitHub documentation cited
above, retrieved via Context7 (`/websites/git-scm`) and cross-checked directly
against the linked pages. This page follows the golden capability page structure
for the `git-and-github` module; the module-level provenance policy and source
registry live in `../provenance.md` and `../source-registry.md`.
