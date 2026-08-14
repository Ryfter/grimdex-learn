---
title: Undoing and recovering work
module_id: git-and-github
capabilities:
  - undoing-and-recovering-work
context7_library: /websites/git-scm
context7_queries:
  - git revert new commit reverse earlier commit history preserved shared
  - git reset --soft --mixed --hard branch tip index working tree ORIG_HEAD
  - git restore path discard working tree edits --staged unstage index
  - git reflog recover lost HEAD branch tip local reference log
  - git reset restore revert differences public undo local only discard
official_sources:
  - https://git-scm.com/docs/git-revert
  - https://git-scm.com/docs/git-reset
  - https://git-scm.com/docs/git-restore
  - https://git-scm.com/docs/git-reflog
  - https://git-scm.com/docs/git
  - https://git-scm.com/docs/git-commit
  - https://git-scm.com/docs/user-manual
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

Undoing and recovering work is the decision map for reversing a mistake in Git
without confusing three different tools that share everyday English names. `git
revert` creates a *new* commit that undoes the effect of an earlier commit while
leaving history intact — the safe public undo for anything already shared.
`git reset` moves the tip of the *current* branch to a chosen commit and, by
mode, may also change the index and working tree — a local-history tool, not a
shared-branch default. `git restore` adjusts file content in the working tree
and/or index without moving the branch tip. The safety net under tip moves is
the *reflog*: a local log of where `HEAD` and branch tips pointed, so a lost
tip can often be found again. The honest boundary is simple: work that reached
a commit is almost always recoverable via the reflog while those entries remain;
uncommitted edits destroyed by `git reset --hard` or a discarding `git restore`
are not recoverable by Git.

## When it is useful

Reach for this capability when something must be undone and you need the right
tool for the situation: a bad commit already pushed to a shared branch; a local
commit (or few) you want off the tip before anyone else depends on it;
uncommitted edits you want out of one file or out of the index; or a tip that
seems to have vanished after a reset, amend, or rebase and must be found again.
It is also the page to reread before any command that rewrites history or
discards working-tree content.

## Prerequisites

- A Git repository has been initialized or cloned, and the current directory is
  inside it.
- You can identify the commit or path you care about (`git log`, `git status`,
  or a known hash / relative name such as `HEAD~1`).
- For `git revert`, the working tree should be clean relative to `HEAD` (no
  uncommitted modifications), as required by that command.
- You know whether the commits or branch tip involved have already been pushed
  or shared with others — that fact chooses between revert and reset.

## Current syntax

```
git revert <commit>
git reset --soft <commit>
git reset [--mixed] <commit>
git reset --hard <commit>
git restore <path>
git restore --staged <path>
git reflog
git reset --hard ORIG_HEAD
git reset --hard HEAD@{n}
git branch recover-tip HEAD@{n}
```

- `git revert <commit>` applies the inverse of `<commit>` and records a *new*
  commit that undoes that change. History is not rewritten; the original commit
  remains. Prefer this when the commit has already been pushed or shared.
- `git reset --soft <commit>` moves the current branch tip (and `HEAD`) to
  `<commit>` and leaves both the index and the working tree unchanged. Before
  the move, Git records the previous tip in `ORIG_HEAD`.
- `git reset` or `git reset --mixed <commit>` (mixed is the default) moves the
  tip to `<commit>` and updates the index to match that commit, but leaves the
  working tree alone. Staged content is cleared relative to the new tip; file
  contents on disk stay as they were.
- `git reset --hard <commit>` moves the tip, the index, *and* the working tree
  to match `<commit>`. Tracked files are overwritten or removed so the tree
  matches that commit. Uncommitted changes to tracked paths are discarded and
  are not recoverable by Git.
- `git restore <path>` restores the working-tree file from the index (by
  default), discarding uncommitted edits to that path. That discard is
  destructive for those edits; Git does not keep a reflog of uncommitted
  working-tree content.
- `git restore --staged <path>` restores the index entry for the path from
  `HEAD` (by default) without changing the working tree — a safe unstage.
- `git reflog` lists recent updates to `HEAD` (and, with a ref name, to that
  ref). Entries such as `HEAD@{1}` name where `HEAD` pointed one move ago.
- After a reset, `ORIG_HEAD` still names the tip as it was immediately before
  that reset. `git reset --hard ORIG_HEAD` (or `git reset --hard HEAD@{n}` once
  you pick the right reflog entry) can put the branch tip back. Prefer
  inspecting with `git reflog` and `git log` first; `--hard` again discards any
  uncommitted work present at recovery time. Creating a branch at a reflog
  entry (`git branch recover-tip HEAD@{n}`) is a non-destructive way to pin a
  found commit before deciding how to move the original branch.

## What happens (local and remote)

Locally, the three tools touch different parts of the repository. `git revert`
writes a new commit object whose tree undoes an earlier commit's effect, then
advances the current branch to that new commit — same kind of local tip advance
as any ordinary commit. `git reset` with a commit argument moves the branch
pointer (and `HEAD`); depending on mode it may also rewrite the index and the
working tree to match the target. `git restore` never moves the branch tip; it
only rewrites selected paths in the working tree and/or index from a chosen
source (index or `HEAD` by default). Reference moves — including resets — are
recorded in the local reflog for that repository. None of these commands update
a remote by themselves. Publishing a revert is an ordinary push of a new
commit. Publishing a reset that rewound a tip that others already have requires
a history rewrite on the remote (typically a force push), which rewrites shared
history and must never be done on a shared branch without explicit coordination.
A pull request on a host such as GitHub is a forge collaboration feature for
proposing integration of one branch into another; it is not the Git command
`git pull`, and undoing work on a laptop is not the same as closing or changing
a pull request on the host.

## Practical example

Starting from a small project with committed history and a clean working tree,
undo a mistaken commit that is still only local, then recover if the wrong mode
was used:

```
$ git log --oneline
a1b2c3d Fix typo in summary
e4f5a6b Add project notes
$ git reset --soft HEAD~1
$ git status
# tip moved back; changes from the undone commit remain staged
```

If the mistaken commit had already been pushed and others may depend on it,
prefer a public-safe undo instead of resetting the shared tip:

```
$ git revert a1b2c3d
$ git log --oneline
# new tip: a commit that reverses a1b2c3d; a1b2c3d still in history
```

Discard uncommitted edits in one file, or only unstage it:

```
$ git restore notes.txt           # discards uncommitted edits to notes.txt
$ git restore --staged notes.txt  # unstages; working tree keeps edits
```

If a hard reset went too far, use the reflog (or `ORIG_HEAD` right after the
reset) to find the previous tip and recover:

```
$ git reset --hard HEAD~2
$ git reflog
# find the entry from before the reset (often HEAD@{1} or ORIG_HEAD)
$ git reset --hard ORIG_HEAD
# or: git branch recover-tip HEAD@{1}
```

## Explanation guidance

### Essential

Choose the tool by what you are undoing and whether anyone else already has the
commits. **Shared or pushed history → `git revert`:** it adds a new inverse
commit and leaves the old commits in place, so collaborators do not have their
history rewritten. **Local-only tip adjustment → `git reset`:** it moves the
current branch tip; `--soft` keeps index and working tree, `--mixed` (default)
resets the index but keeps the working tree, and `--hard` makes tip, index, and
working tree all match the target — discarding uncommitted work on tracked
paths. **File-level undo without moving the branch → `git restore`:** restore a
path in the working tree to drop uncommitted edits, or use `--staged` only to
unstage safely. **Lost tip after a move → `git reflog` (and often
`ORIG_HEAD`):** the commit usually still exists in the object database; the
reflog tells you its name so you can reset or branch to it while the entry
remains. Commit early and often: a commit is what makes recovery with Git
possible. Uncommitted work thrown away by `--hard` or a discarding restore is
outside that safety net.

### Experienced-user note

`git reset` and `git restore` overlap on unstaging: `git restore --staged
<path>` is the modern path-level form equivalent to resetting that path in the
index without moving `HEAD`. Prefer `restore` for path operations and reserve
`reset` for moving the branch tip. After any tip-moving reset, `ORIG_HEAD` is a
short-lived convenience for “where this branch was just before”; the reflog is
the longer local record and uses names such as `HEAD@{n}` and
`<branch>@{n}`. Reflog entries are local to that clone and are eventually
pruned (expiration is controlled by configuration such as `gc.reflogExpire`),
so recover sooner rather than later. Never combine a local reset of shared
commits with a force push to a branch others use without explicit agreement;
use `git revert` (or a coordinated, protected-branch workflow on the host)
instead.

### Optional deeper context

Official Git documentation groups the three names deliberately: *revert* makes
a new commit that reverses other commits; *restore* restores working-tree (and
optionally index) files and does not update the branch; *reset* updates the
branch tip and can rewrite which commits the branch contains, and can also
adjust the index in ways that overlap restore. A hard reset that drops commits
from a branch tip does not immediately delete those commit objects; they remain
reachable from the reflog and from any other ref that still names them until
garbage collection removes unreferenced objects after reflog expiry. That is
why “I reset too far” is usually fixable when the work had been committed, and
why “I never committed, then ran `--hard` or `restore`” is not.

## Cautions and common failures

- **Committed work is usually recoverable; uncommitted work discarded by Git is
  not.** After `git reset --hard` or `git restore <path>` discards uncommitted
  edits, those bytes are not in a commit and not in the reflog. Git cannot
  reconstruct them. The real safety habit is to commit (or otherwise copy)
  work you care about before destructive commands.
- **`git reset --hard` rewrites the tip and the working tree.** It overwrites
  tracked files to match the target commit. Recovery of a *previous tip* uses
  `git reflog` or `ORIG_HEAD`, then e.g. `git reset --hard <found-commit>` or
  `git branch recover-tip <found-commit>`. Recovery does not bring back
  uncommitted edits that `--hard` already destroyed. **Never use
  `reset --hard` on a shared branch tip and force-push the result without
  coordination** — that rewrites history others may already have.
- **`git reset` (any mode that moves a published tip) is local-only by
  intent.** Soft and mixed resets still move the branch pointer. If those
  commits were already pushed, making the remote match requires a force-style
  push, which is a shared-history rewrite. Prefer `git revert` for public undo.
  If you already reset locally by mistake, `git reflog` / `ORIG_HEAD` can put
  the tip back before you push anything.
- **`git restore <path>` discards uncommitted working-tree edits for that
  path.** There is no reflog entry for those edits. Confirm with `git diff`
  before restoring. `git restore --staged <path>` only changes the index and
  keeps working-tree edits — use that when you meant to unstage, not discard.
- **`git revert` needs a clean working tree** and creates a new commit; it does
  not delete the bad commit from history. If the revert conflicts, resolve,
  stage, and continue (or abort) as with other sequenced operations — the
  original commit remains either way.
- **Never rewrite shared history to “fix” a mistake.** Do not reset a shared
  branch and force-push, and do not revert-then-force-push in a way that
  removes commits others depend on, without explicit coordination. Hosts such
  as GitHub may also block force pushes on protected branches. Local recovery
  of your own tip after a bad reset still starts with `git reflog`.
- **A pull request is not `git pull`.** Closing or superseding a pull request
  on a forge does not run these undo commands on anyone's laptop; conversely,
  `git revert` / `git reset` / `git restore` only affect your local repository
  until you push.

## Related capabilities

- Commits and history — what a commit records, `git commit --amend` as another
  local rewrite, and reading history with `git log` / `git show`.
- Working tree, staging, and status — the three areas reset and restore adjust;
  `git status` and `git diff` before destructive commands; safe unstage with
  `git restore --staged`.
- Branches and switching — the current branch tip that `git reset` moves;
  creating a recovery branch from a reflog entry.
- Push and upstream branches — publishing a revert with an ordinary push;
  why force-pushing a rewritten tip is dangerous on shared branches.
- Remotes, fetch, and pull — how remote-tracking branches relate to what others
  already have when you choose revert over reset.
- Merge commit, squash, and rebase — other history-changing workflows that
  share the “never rewrite shared history without coordination” rule and also
  rely on the reflog when a rewrite goes wrong.

## Official sources

- <https://git-scm.com/docs/git-revert> — `git revert` as recording new commits
  that reverse earlier ones; contrast with reset/hard for discarding
  uncommitted work.
- <https://git-scm.com/docs/git-reset> — `git reset` modes (`--soft`, `--mixed`
  default, `--hard`), moving `HEAD`, and setting `ORIG_HEAD` before the
  operation.
- <https://git-scm.com/docs/git-restore> — restoring working-tree paths from the
  index; `--staged` restoring the index from `HEAD`.
- <https://git-scm.com/docs/git-reflog> — reference logs recording when branch
  tips and other refs were updated locally; `HEAD@{n}`-style recovery names.
- <https://git-scm.com/docs/git> — “Reset, restore and revert”: revert makes a
  new inverse commit; restore does not update the branch; reset moves the
  branch tip (and can change history).
- <https://git-scm.com/docs/git-commit> — commits as the durable recorded
  snapshots recovery depends on.
- <https://git-scm.com/docs/user-manual> — history, `HEAD`, and fixing mistakes
  in the context of the commit graph.

## Provenance

Authored 2026-08-01 against the official Git documentation cited above,
retrieved via Context7 (`/websites/git-scm`) and cross-checked directly against
the linked pages. Module-level provenance policy and source registry live in
`../provenance.md` and `../source-registry.md`.
