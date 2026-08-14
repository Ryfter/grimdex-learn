---
title: Commits and history
module_id: git-and-github
capabilities:
  - commits-and-history
context7_library: /websites/git-scm
context7_queries:
  - git commit recording changes staging area metadata author timestamp parent commit
  - git log viewing commit history --oneline git show single commit
  - git diff working tree staging area --staged compare last commit
  - git commit --amend rewrite history HEAD reflog recovery
  - git commit -m message imperative mood good commit message conventions HEAD current branch
official_sources:
  - https://git-scm.com/docs/git-commit
  - https://git-scm.com/docs/git-log
  - https://git-scm.com/docs/git-show
  - https://git-scm.com/docs/git-diff
  - https://git-scm.com/docs/git-reflog
  - https://git-scm.com/docs/SubmittingPatches
  - https://git-scm.com/docs/user-manual
last_checked: 2026-08-01
last_material_update: 2026-08-01
status: current
claim_class: foundational
safety_class: destructive
version_stamp: fall-2026-0.1.0
admission:
  course_independent: true
  public_ready: true
  provenance: authored-against-official-docs
---

## What it is

A commit is a recorded snapshot of a project's staged content, bundled with metadata:
the author, a timestamp, a message describing the change, and a reference to the
commit's parent (or parents). Committing does not save the working tree directly —
it saves whatever has been placed in the staging area (also called the index) at the
moment the commit is made. Each new commit points back to the commit it was made
from, so a repository's history is a chain of these snapshots linked parent to child.

## When it is useful

Commits are the basic unit of saved progress in Git. Reach for this capability any
time a meaningful, self-contained change is ready to be recorded: a working feature,
a bug fix, a documentation update, or any other checkpoint worth being able to return
to later. Because each commit is independently identifiable, commits are also the
unit that history-inspection commands, collaboration workflows, and code-review tools
all operate on.

## Prerequisites

- A Git repository has been initialized (`git init`) or cloned, and the current
  directory is inside it.
- At least one change exists in the working tree that has not yet been committed.
- The change has been staged with `git add <path>` (or `git add .` for everything
  changed), since `git commit` only records what is currently in the staging area.

## Current syntax

```
git add <path>...
git commit -m "<message>"

git log
git log --oneline
git show <commit>

git diff
git diff --staged

git commit --amend
git reflog
```

- `git add <path>...` copies the listed changes from the working tree into the
  staging area (the working-tree file itself is untouched).
- `git commit -m "<message>"` creates a new commit from whatever is currently
  staged, using `<message>` as the commit message.
- `git log` lists the commit history reachable from `HEAD`, most recent first;
  `git log --oneline` prints one condensed line per commit (abbreviated hash plus
  title).
- `git show <commit>` displays a single commit in full: its metadata and the changes
  it introduced.
- `git diff` (no arguments) compares the working tree against the staging area;
  `git diff --staged` (equivalently `--cached`) compares the staging area against
  the most recent commit (`HEAD`).
- `git commit --amend` replaces the most recent commit with a new one.
- `git reflog` lists the recent history of where `HEAD` and branch tips have
  pointed, independent of the commit graph itself.

A commit message convention worth adopting from the start: phrase the first line
(the summary) in the imperative mood — "Add the missing header" rather than
"Added the missing header" or "This adds the missing header" — as if the commit
were an instruction to the codebase. Commits are the unit of history that other
people, and tools such as `git log`, `git show`, and code-review interfaces, read
back later, so a clear, imperative summary line is what makes that history useful
to someone other than the person who wrote it.

## What happens (local and remote)

Locally, `git commit` writes a new commit object into the repository's object
database: a snapshot of the staged tree, plus author, timestamp, message, and the
identity of the parent commit(s). The current branch is then updated to point at
this new commit, and `HEAD` — the reference to the currently checked-out commit —
moves forward with it. A repository's history is simply the set of commits reachable
by following parent links backward from `HEAD` (or from any other branch or tag).
None of this touches a remote by itself: commits are a purely local operation until
they are pushed. `git commit --amend` does not edit the previous commit in place —
Git builds a brand-new commit object (usually with the same parent and author as the
one being replaced) and moves the branch pointer to it, leaving the original commit
unreferenced by any branch, though it still exists in the object database and in the
reflog until it is eventually pruned.

## Practical example

Starting from a project directory with one already-committed file, `notes.txt`:

```
$ echo "Add a new line" >> notes.txt
$ git add notes.txt
$ git commit -m "Add a note about the new line"
$ git log --oneline
```

To review what changed before staging, and again after staging:

```
$ git diff            # working tree vs. staging area
$ git add notes.txt
$ git diff --staged    # staging area vs. the last commit
```

To look at one commit in detail, and at the condensed history:

```
$ git show HEAD
$ git log --oneline
```

## Explanation guidance

### Essential

A commit is a snapshot, not a diff — Git stores the full state of the staged
content at that point, plus who made the change, when, and why (the message), and
which commit it came from. Nothing is committed unless it was staged first, so
`git add` and `git commit` are two separate steps: staging chooses what goes into
the next snapshot, and committing takes that snapshot. `git log` and `git show` are
how you read history back out; `git diff` (in its two forms) is how you check what
you are about to stage or commit before you do it.

### Experienced-user note

`git commit --amend` is a convenience for "I want the last commit to look
different" — it is implemented as building a new commit object with (by default)
the same parent and author as the current tip, then moving the branch pointer to
it. That means amending is a history rewrite: the old commit's identity (its hash)
does not survive. Treat `--amend`, and history rewriting in general, as something
that only ever touches commits that are still local and not yet shared — see
Cautions below. `git log --oneline` and `git show` are worth knowing well because
almost every other history-reading and history-editing command (rebase, cherry-pick,
bisect) is built on the same "chain of commits reachable from a reference" model.

### Optional deeper context

Internally, a commit object references a tree object (the recorded snapshot of
file contents and directory structure) and zero or more parent commit objects; a
commit with no parent is a repository's root commit, and a commit with more than
one parent is a merge commit. `git diff` and `git diff --staged` are shorthand for
comparing specific pairs of these three states — working tree, staging area (index),
and the tree of `HEAD` — and the same three-way comparison underlies status
reporting, merges, and conflict resolution elsewhere in Git.

## Cautions and common failures

- **Nothing staged, nothing committed.** Running `git commit` without having
  staged anything (or without `-a`) commits nothing new for those files; check
  `git diff --staged` first if a commit looks empty or incomplete.
- **`--amend` rewrites history — never amend a commit that has already been
  pushed or shared.** Because amending replaces the previous commit with a new
  one under a new identity, anyone who already has the old commit (a collaborator
  who pulled it, or a remote branch) will diverge from the rewritten history. Only
  amend commits that are still local and unpublished.
- **Recovering from a mistaken amend.** If `--amend` is run by mistake — the
  wrong message, the wrong content, or on a commit that turned out to already be
  shared — the previous commit is not gone. Git's reflog records where the branch
  and `HEAD` pointed before the amend, even though no branch points there anymore.
  Run `git reflog` to find the entry for the commit as it was before the amend
  (it will show as the `HEAD@{n}` entry immediately before the amend action), then
  recover it, for example with `git reset --hard <that-commit>` or by checking out
  that commit and creating a new branch from it. Reflog entries are local to the
  repository and are eventually pruned, so recover promptly rather than assuming
  they persist indefinitely.
- **`git diff` alone can be misleading about what will be committed.** Because
  plain `git diff` only shows working-tree-vs-staging-area changes, it will not
  show changes that are already staged. Use `git diff --staged` to see what a
  `git commit` right now would actually record.

## Related capabilities

- Staging and the working tree (`git add`, `git status`) — not yet a separate page
  in this module; referenced here because commits depend on staging.
- Branching and merging — builds on the commit-chain model introduced here.
- Rewriting history beyond `--amend` (interactive rebase) — a further destructive
  capability that shares the "never rewrite shared history" rule.

## Official sources

- <https://git-scm.com/docs/git-commit> — `git commit`, staging-to-commit
  behavior, and `--amend`.
- <https://git-scm.com/docs/git-log> — `git log` and `--oneline`.
- <https://git-scm.com/docs/git-show> — `git show`.
- <https://git-scm.com/docs/git-diff> — `git diff` and `git diff --staged`.
- <https://git-scm.com/docs/git-reflog> — `git reflog` and recovery from
  reference changes.
- <https://git-scm.com/docs/SubmittingPatches> — imperative-mood commit message
  guidance.
- <https://git-scm.com/docs/user-manual> — the commit object model, `HEAD`, and
  "Fixing a mistake by rewriting history."

## Provenance

Authored 2026-08-01 against the official Git documentation cited above, retrieved
via Context7 (`/websites/git-scm`) and cross-checked directly against the linked
pages. This page is the first golden capability page for the `git-and-github`
module; the module-level provenance policy and source registry live in
`../provenance.md` and `../source-registry.md`.
