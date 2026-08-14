---
title: Merge conflicts
module_id: git-and-github
capabilities:
  - merge-conflicts
context7_library: /websites/git-scm
context7_queries:
  - git merge conflict both sides same area common ancestor conflict markers
  - git merge --abort restore pre-merge state unmerged paths git status
  - how to resolve conflicts edit markers git add git commit merge continue
  - git checkout --ours --theirs unmerged paths stage 2 stage 3 discard side
  - git rebase conflict per commit rebase --continue rebase --abort
  - merge.conflictStyle diff3 zdiff3 base section conflict markers
official_sources:
  - https://git-scm.com/docs/git-merge
  - https://git-scm.com/docs/git-rebase
  - https://git-scm.com/docs/git-status
  - https://git-scm.com/docs/git-checkout
  - https://git-scm.com/docs/git-add
  - https://git-scm.com/docs/git-commit
  - https://git-scm.com/docs/git-reflog
  - https://git-scm.com/docs/merge-config
last_checked: 2026-08-01
last_material_update: 2026-08-01
status: current
claim_class: everyday
safety_class: destructive
version_stamp: fall-2026-0.1.0
admission:
  course_independent: true
  public_ready: true
  provenance: authored-against-official-docs
---

## What it is

A merge conflict is Git's signal that two lines of history both changed the same
region of a file since their common ancestor, so Git cannot pick one side
automatically. When that happens during a merge (or during a rebase that replays
a commit), Git stops with the conflicted paths left unmerged and writes conflict
markers into the working-tree files so a person can decide the intended result.
Conflicts are a normal part of integrating parallel work — not a broken
repository and not a failed tool — and resolving them is an expected skill
alongside branching, merging, and rebasing.

## When it is useful

Reach for this capability whenever a merge or rebase stops because both sides
edited the same content: combining a topic branch into a base branch, updating
a long-lived branch that diverged from its base, or replaying commits onto a
newer tip. Knowing how to read markers, finish a resolution, and abort safely is
also useful when someone else already started a merge and left unmerged paths
behind, or when a pull's integrate step surfaces the same three-way merge
machinery.

## Prerequisites

- A Git repository is available and the current directory is inside it.
- Two tips share a common ancestor but have diverged (for example a base branch
  and a topic branch), so a three-way merge or a rebase can produce overlapping
  changes.
- For a merge, the work that should be kept is already committed on each tip;
  starting a merge with non-trivial uncommitted changes is discouraged because
  recovery can be harder if the merge must be aborted.
- Basic staging and status fluency (`git status`, `git add`, `git commit`) is in
  place, because marking a path resolved is done by staging it.

## Current syntax

```
git merge <branch>
git status
git add <path>...
git commit
git merge --continue
git merge --abort

git rebase <upstream>
git rebase --continue
git rebase --abort

git checkout --ours -- <path>
git checkout --theirs -- <path>
git add <path>

git config merge.conflictStyle diff3
```

- `git merge <branch>` incorporates the named tip into the current branch; when
  both sides changed the same area, the merge stops with conflicts instead of
  creating a merge commit.
- `git status` lists unmerged (conflicted) paths while a conflicted merge or
  rebase is in progress.
- Edit each conflicted file to the intended final text, remove all conflict
  markers, then `git add <path>` for every resolved path so the index no longer
  treats them as unmerged.
- After a conflicted merge, `git commit` (or `git merge --continue`) records the
  merge commit once every conflict is staged as resolved.
- `git merge --abort` stops conflict resolution and tries to restore the
  pre-merge state (safe exit when the merge should not finish).
- During a rebase, resolve each stop the same way (edit, remove markers, `git
  add`), then `git rebase --continue`; `git rebase --abort` returns the branch
  to its pre-rebase tip.
- `git checkout --ours -- <path>` and `git checkout --theirs -- <path>` replace
  an unmerged path with only one side's version (stage 2 or stage 3); the other
  side's content is discarded from the working tree for that path until you
  recover it another way.
- `merge.conflictStyle` set to `diff3` (or `zdiff3`) adds a base section between
  the usual markers so the common-ancestor text is visible while resolving.

## What happens (local and remote)

Locally, a true merge compares three trees: the common ancestor, the current
branch tip (`HEAD`, "ours"), and the tip being merged in (`MERGE_HEAD`,
"theirs"). Clean regions update the index and working tree automatically. Where
both sides changed the same area, Git leaves `HEAD` where it was, records the
other tip as `MERGE_HEAD`, stores up to three stages in the index for each
conflicted path (stage 1 ancestor, stage 2 ours, stage 3 theirs), and writes
conflict markers into the working-tree file. The merge does not finish until
every unmerged path is resolved and staged, then committed as a merge commit.

A rebase is different in shape but uses the same conflict presentation: each
commit is replayed one by one, so a conflict can stop the process at any
replayed commit. After resolving and staging, `git rebase --continue` moves on
to the next commit; another conflict may appear later in the same rebase.

None of this updates a remote by itself. Conflicts are a local integration
event. Publishing the result still requires an explicit push after the merge or
rebase completes. Force-pushing rewritten history after a rebase is a separate
destructive concern: never rewrite history that others already based work on
without an agreed recovery plan; use `git reflog` locally if a tip needs to be
found again after a mistaken rewrite.

## Practical example

Two branches both edited the same line of `greeting.txt` after they diverged.
On `main`:

```
$ cat greeting.txt
Hello from main
```

On `topic` (branched earlier, then changed the same line):

```
$ cat greeting.txt
Hello from topic
```

With `main` checked out:

```
$ git merge topic
# Git stops; git status lists greeting.txt as unmerged
$ git status
```

Open `greeting.txt`. Default markers look like:

```
<<<<<<< HEAD
Hello from main
=======
Hello from topic
>>>>>>> topic
```

Edit to the intended single result, for example:

```
Hello from both lines of work
```

Then finish the merge:

```
$ git add greeting.txt
$ git commit
# or: git merge --continue
```

If the merge was a mistake and nothing should be kept from this attempt:

```
$ git merge --abort
```

If the same overlap appears while rebasing `topic` onto `main`, resolve and
stage each stop, then:

```
$ git rebase --continue
```

or exit entirely with `git rebase --abort`.

## Explanation guidance

### Essential

A conflict means both sides changed the same region since the common ancestor,
and Git will not invent a preference between them. That is expected when people
work in parallel — treat it as a decision point, not an error. Read the markers:
the block after `<<<<<<<` is typically "ours" (current branch / `HEAD` in a
merge), the block after `=======` is typically "theirs" (the tip being merged
in), and everything between the outer markers must become one coherent file
with the markers removed. Then stage each path and complete the operation with
`git commit` / `git merge --continue` for a merge, or `git rebase --continue`
for a rebase. Prefer `git merge --abort` (or `git rebase --abort`) when you want
out without finishing.

### Experienced-user note

`git checkout --ours` and `git checkout --theirs` are shortcuts that discard one
side of an unmerged path entirely: they check out stage 2 (ours) or stage 3
(theirs) into the working tree for that path. Use them only when the intended
resolution really is "keep this whole file from one tip." During a rebase,
"ours" and "theirs" can feel swapped relative to everyday merge language —
`--ours` is the branch being rebased onto (so far), and `--theirs` is the commit
being replayed — so read the labels carefully before discarding a side. After
choosing `--ours` or `--theirs`, still `git add` the path to mark it resolved.
Setting `merge.conflictStyle` to `diff3` inserts a `|||||||` base section so
you can see the common ancestor between the two sides; that often makes a
better combined resolution obvious.

### Optional deeper context

While conflicts remain, the index holds multiple stages per path; `git ls-files
-u` and `git show :1:path` / `:2:path` / `:3:path` expose the ancestor, ours,
and theirs blobs. The same three-way machinery underlies `git pull` when pull
merges, and underpins forge features such as resolving conflicts in a pull
request on GitHub — but a pull request is a host collaboration object, not the
Git command `git pull`. Marker style (`merge`, `diff3`, `zdiff3`) only changes
how the working-tree file is written for humans; it does not change which paths
conflict.

## Cautions and common failures

- **Conflicts are normal, not corruption.** Stopping mid-merge with unmerged
  paths is the designed outcome when both sides changed the same region. Do not
  delete the whole repository or force-reset casually just because markers
  appeared.
- **Do not delete markers without choosing a resolution.** Removing
  `<<<<<<<` / `=======` / `>>>>>>>` (and any `|||||||` base block) without
  deciding which lines should remain can leave a file that stages cleanly but
  is logically wrong. Edit to the intended content first, then remove markers,
  then `git add`.
- **`git merge --abort` is the safe exit.** It aborts conflict resolution and
  tries to reconstruct the pre-merge state. Prefer committing or stashing local
  work before starting a merge; if uncommitted changes existed when the merge
  began, abort may not always restore every pre-merge working-tree edit.
- **`git checkout --ours` / `--theirs` discard one side for that path.** The
  discarded side's content is no longer in the working-tree file. The other
  tip's full tree still exists in its commits: inspect it with `git show
  <commit>:<path>`, or recover versions via the index stages before they are
  cleared, or with `git reflog` / branch tips if later history moves. After a
  mistaken choice, restore the other side from the still-present commit or
  stage rather than assuming the bytes are gone from the object database.
- **Never rewrite shared history to "fix" a conflict.** Resolving conflicts does
  not require force-pushing. If a rebase rewrites commits that others already
  pulled, do not force-push to a shared branch without agreement; recover local
  tips with `git reflog` if a rebase goes wrong, and use `git rebase --abort`
  while the rebase is still in progress.
- **Rebase conflicts can repeat.** Each replayed commit can stop independently.
  Finishing one conflict does not mean later commits will apply cleanly; expect
  multiple resolve → `git add` → `git rebase --continue` cycles on long rebases.

## Related capabilities

- Merge commit, squash, and rebase — the integration shapes that can surface
  conflicts, and when a merge commit versus a rebase is chosen.
- Branches and switching — creating the parallel tips whose overlapping edits
  produce conflicts.
- Commits and history — recording the merge commit or the rewritten rebase
  commits after resolution; `git reflog` for finding previous tips.
- Working tree, staging, and status — `git status` unmerged paths and `git add`
  as the mark-resolved step.
- Remotes, fetch, and pull — how a pull's integrate step can stop with the same
  conflict machinery; distinct from a host pull request.
- Pull requests and review — forge-side review and conflict handling on a host
  such as GitHub after local resolution and push.

## Official sources

- <https://git-scm.com/docs/git-merge> — true merge behavior, how conflicts are
  presented, how to resolve them, and `git merge --abort` / `--continue`.
- <https://git-scm.com/docs/git-rebase> — conflicts while replaying commits,
  `git rebase --continue`, and `git rebase --abort`.
- <https://git-scm.com/docs/git-status> — unmerged paths during a conflicted
  merge or rebase.
- <https://git-scm.com/docs/git-checkout> — `--ours` and `--theirs` for unmerged
  paths, and the rebase note that ours/theirs may appear swapped.
- <https://git-scm.com/docs/git-add> — staging a path after resolution to mark
  the conflict resolved.
- <https://git-scm.com/docs/git-commit> — recording the merge commit once
  conflicts are resolved and staged.
- <https://git-scm.com/docs/git-reflog> — recovering previous `HEAD` and branch
  tip positions after a mistaken rewrite or lost tip reference.
- <https://git-scm.com/docs/merge-config> — `merge.conflictStyle` (`merge`,
  `diff3`, and related styles) for base-visible conflict markers.

## Provenance

Authored 2026-08-01 against the official Git documentation cited above,
retrieved via Context7 (`/websites/git-scm`) and cross-checked directly against
the linked pages. Module-level provenance policy and source registry live in
`../provenance.md` and `../source-registry.md`.
