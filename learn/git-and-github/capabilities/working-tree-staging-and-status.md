---
title: Working tree, staging, and status
module_id: git-and-github
capabilities:
  - working-tree-staging-and-status
context7_library: /websites/git-scm
context7_queries:
  - git three states working tree staging area index repository committed
  - git status untracked modified staged branch line short format
  - git add pathspec staging area index prepare next commit
  - git add -A --all update index match working tree removals
  - git restore --staged unstage path keep working tree edits
  - git diff working tree index --staged compare HEAD
official_sources:
  - https://git-scm.com/book/en/v2/Getting-Started-What-is-Git%3F
  - https://git-scm.com/docs/git-status
  - https://git-scm.com/docs/git-add
  - https://git-scm.com/docs/git-restore
  - https://git-scm.com/docs/git-diff
  - https://git-scm.com/docs/gitglossary
  - https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository
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

Every Git project has three areas that work together: the working tree (the
files you edit on disk), the staging area or index (the prepared snapshot for
the next commit), and the repository (the permanent object store of committed
history, usually under `.git`). Editing a file changes only the working tree.
Staging copies selected content into the index. Committing records whatever is
in the index as a new snapshot in the repository. This page owns that mental
model and the everyday commands that inspect and move content among the three
areas: `git status`, `git add`, and `git restore --staged`.

## When it is useful

Reach for this capability whenever you need a clear picture of what Git will
include in the next commit, or when you need to choose which edits enter that
commit. Typical moments: after editing files and before committing; when
separating one logical change from another still in progress; when a path was
staged by mistake and should leave the index without discarding the edits on
disk; and when an untracked file appears and you must decide whether to start
tracking it.

## Prerequisites

- A Git repository has been initialized (`git init`) or cloned, and the current
  directory is inside it.
- At least one path differs from the last commit, is new on disk, or is already
  staged — otherwise `git status` reports a clean working tree and there is
  nothing to stage or unstage.

## Current syntax

```
git status
git status -sb

git add <path>...
git add -A

git restore --staged <path>...

git diff
git diff --staged
```

- `git status` reports the current branch (or detached `HEAD`), paths that
  differ between the index and `HEAD` (what a commit would record), paths that
  differ between the working tree and the index (what you could still stage),
  and untracked paths that are not ignored.
- `git status -sb` combines short path status with the branch line in one
  compact view.
- `git add <path>...` copies the current contents of the listed paths from the
  working tree into the index (the staging area). The working-tree files
  themselves are not rewritten.
- `git add -A` (equivalently `--all`) updates the index across the whole
  working tree so that it matches the working tree: new files are added,
  modifications are staged, and removals of tracked paths are staged. Review
  with `git status` (and, when useful, `git diff` / `git diff --staged`) before
  using add-all, because every non-ignored change becomes part of the next
  commit preparation.
- `git restore --staged <path>...` restores the named paths in the index from
  `HEAD` by default. That unstages those paths: the index entry matches the
  last commit again, while the working-tree edits remain on disk.
- `git diff` (no arguments) compares the working tree against the index;
  `git diff --staged` (equivalently `--cached`) compares the index against
  `HEAD`. Detailed use of both forms is owned by the commits-and-history page;
  this page only places them in the three-area model.

Untracked means a path exists in the working tree, is not ignored by
`.gitignore`, and has no corresponding entry in the index — Git is not yet
recording that path's content for commits until you `git add` it.

## What happens (local and remote)

Locally, the three areas stay distinct until you deliberately move content
between them. Editing files updates only the working tree. `git add` updates
only the index for the paths you name (or, with `-A`, for the whole tree's
non-ignored changes, including staged deletions). `git restore --staged` updates
only the index for the paths you name, resetting those index entries toward
`HEAD` without touching the working-tree files. `git status` is read-only with
respect to your content: it may refresh cached stat information in the index for
performance, but it does not stage, unstage, or commit. None of these commands
contact a remote by themselves. Remotes, pushes, and forge workflows operate on
commits that already exist in the repository; staging and status are a purely
local preparation layer.

## Practical example

Starting from a small project with one already-committed file, `notes.txt`, and
a clean `git status`:

```
$ echo "Draft idea" >> notes.txt
$ echo "scratch" > todo.local.txt
$ git status
```

`git status` should list `notes.txt` under changes not staged for commit
(modified tracked file) and `todo.local.txt` under untracked files. Stage only
the note, then check again:

```
$ git add notes.txt
$ git status
$ git diff --staged
```

`notes.txt` now appears under changes to be committed. The untracked file is
still untracked. If the staged path was chosen too early, unstage it without
losing the edit:

```
$ git restore --staged notes.txt
$ git status
```

`notes.txt` is modified in the working tree again and no longer staged.
`todo.local.txt` remains untracked until explicitly added. Prefer path-specific
`git add` when only some changes belong in the next commit; use `git add -A`
only after reviewing the full set of working-tree changes, including deletions
and new files.

## Explanation guidance

### Essential

Think in three places, not one: the working tree is where you edit, the staging
area (index) is what the next commit will record, and the repository holds
committed history. `git status` is the map of those places for every path:
untracked (not in the index), modified but not staged (working tree differs
from index), and staged (index differs from `HEAD`). `git add` moves content
from the working tree into the index; `git restore --staged` moves the index
back toward `HEAD` for selected paths while leaving your disk edits alone.
`git add -A` is powerful because it stages the whole picture at once — which is
why reading `git status` first is part of the safe habit, not an optional extra.

### Experienced-user note

The index is not a temporary clipboard that empties on commit in the sense of
forgetting paths: after a commit, the index and `HEAD` agree on those trees, and
further edits reappear as working-tree differences until you stage again. Partial
staging (`git add <path>` or interactive hunk staging) is how one working tree
supports multiple focused commits. `git restore --staged` is the modern
unstage path for the index; restoring the working tree without `--staged` is a
different operation that can discard uncommitted edits and is outside the safe
unstage workflow this page recommends.

### Optional deeper context

`git status` short format uses a two-letter code: the first character describes
the index relative to `HEAD`, and the second describes the working tree relative
to the index; untracked paths show as `??`. `git add` records the content at the
moment you run it — further edits to the same file require another `git add` if
they should enter the same commit. `git diff` and `git diff --staged` are the
line-level views of the same three-way comparison that status summarizes;
see commits and history for reading those diffs before you commit.

## Cautions and common failures

- **Status sections name different comparisons.** "Changes to be committed"
  means index versus `HEAD`. "Changes not staged for commit" means working tree
  versus index. "Untracked files" means present on disk, not ignored, and not
  in the index. Mixing those up leads to committing less — or more — than
  intended.
- **`git add -A` stages removals and new files too.** If a tracked file was
  deleted on disk, `-A` stages that deletion. If a new file is not ignored, `-A`
  stages it. Run `git status` first so secrets, build artifacts, and unrelated
  edits do not ride along.
- **Staging is a snapshot in time.** Editing a file after `git add` leaves the
  newer content only in the working tree until you stage again. `git status`
  will show the path as both staged and further modified when that happens.
- **Unstage is not discard.** `git restore --staged <path>` only adjusts the
  index. To throw away working-tree edits is a different, destructive restore
  path and is not the unstage procedure described here.
- **Ignored paths stay invisible to normal status and add.** Patterns in
  `.gitignore` keep matching untracked paths out of the default status list and
  out of ordinary `git add`; that is intentional. Already-tracked paths are not
  made untracked by adding an ignore rule alone.
- **A pull request is not `git pull`.** Staging and status are local
  preparation. `git pull` updates a local branch from a remote. A pull request
  is a forge workflow for proposing integration of one branch into another.

## Related capabilities

- Commits and history — recording the staged snapshot, reading history, and
  the detailed roles of `git diff` and `git diff --staged`.
- Creating and cloning repositories — how a working tree and `.git` store come
  into existence before staging begins.
- Ignoring files (`.gitignore`) — keeping untracked noise out of status and
  accidental `git add -A` runs.
- Branching and switching — the branch line in `git status` is the current
  line of work; switching branches interacts with a dirty working tree and
  index.

## Official sources

- <https://git-scm.com/book/en/v2/Getting-Started-What-is-Git%3F> — the three
  main sections of a Git project (working tree, staging area/index, Git
  directory) and the modified / staged / committed states.
- <https://git-scm.com/docs/git-status> — `git status` comparisons (index vs
  `HEAD`, working tree vs index, untracked paths) and branch-oriented output.
- <https://git-scm.com/docs/git-add> — `git add`, the index as staging area,
  and `-A` / `--all` updating the index to match the working tree.
- <https://git-scm.com/docs/git-restore> — `git restore --staged` restoring
  index content (default source `HEAD`) without requiring a worktree restore.
- <https://git-scm.com/docs/git-diff> — `git diff` (working tree vs index) and
  `git diff --staged` / `--cached` (index vs `HEAD`).
- <https://git-scm.com/docs/gitglossary> — definitions of working tree, index,
  repository, and related terms.
- <https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository>
  — lifecycle of file status (untracked, modified, staged) and everyday
  `git status` / `git add` workflow.

## Provenance

Authored 2026-08-01 against the official Git documentation cited above,
retrieved via Context7 (`/websites/git-scm`) and cross-checked directly against
the linked pages. Module-level provenance policy and source registry live in
`../provenance.md` and `../source-registry.md`.
