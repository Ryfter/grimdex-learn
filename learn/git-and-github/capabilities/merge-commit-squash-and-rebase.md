---
title: Merge commit, squash, and rebase
module_id: git-and-github
capabilities:
  - merge-commit-squash-and-rebase
context7_library: /websites/git-scm
context7_queries:
  - git merge true merge two parents merge commit fast-forward no-ff ORIG_HEAD
  - git merge --squash produce staged result single commit no MERGE_HEAD
  - git rebase reapply commits new hashes linear history --abort ORIG_HEAD
  - git merge --abort git rebase --abort recover pre-merge pre-rebase state
  - git reflog recover branch tip after failed rebase merge rewrite
  - GitHub pull request merge commit squash and merge rebase and merge history
official_sources:
  - https://git-scm.com/docs/git-merge
  - https://git-scm.com/docs/git-rebase
  - https://git-scm.com/docs/git-commit
  - https://git-scm.com/docs/git-reflog
  - https://git-scm.com/docs/user-manual
  - https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging
  - https://git-scm.com/book/en/v2/Git-Branching-Rebasing
  - https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/about-pull-request-merges
  - https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/merging-a-pull-request
  - https://cli.github.com/manual/gh_pr_merge
last_checked: 2026-08-01
last_material_update: 2026-08-01
status: current
claim_class: conditional
safety_class: destructive
version_stamp: fall-2026-0.1.0
admission:
  course_independent: true
  public_ready: true
  provenance: authored-against-official-docs
---

## What it is

Integrating one line of development into another is a Git operation with more
than one legitimate shape. Three common strategies — **merge commit**,
**squash**, and **rebase** — all bring the same *content* of a head branch onto
a base branch, but they produce different **histories**: different commit
graphs, different parent links, and (for rebase) new commit identities. Git
implements these with `git merge`, `git merge --squash` followed by an ordinary
commit, and `git rebase`. On GitHub, the same three ideas appear as pull request
merge methods — **merge commit**, **squash and merge**, and **rebase and
merge** — which are a forge dialect for choosing how the host updates the base
branch when a pull request is accepted. A pull request is not the Git command
`git pull`; merge method is repository and team **policy**, not a universal law.

## When it is useful

Use this capability when work on a topic branch is ready to join a base branch
(locally or by merging a pull request on a host): landing a feature, taking
upstream updates into a long-lived branch, or choosing how history should look
after integration. Reach for it after you can create commits on a branch, read
history, and (for shared work) push and open a pull request. Prefer understanding
all three histories before treating one as “the correct Git way” — different
projects legitimately choose differently.

## Prerequisites

- A Git repository with at least two related branch tips (or a base tip and a
  head tip that diverged from a common ancestor).
- The base branch checked out when running a local merge or squash into that
  base; the head branch checked out when rebasing that head onto a base.
- For host-side integration: a pull request (or equivalent) on a forge such as
  GitHub, with permission to merge and a repository policy that allows the
  chosen merge method.
- A clean working tree is strongly preferred before merge or rebase so you can
  abort cleanly if conflicts appear.

## Current syntax

```
git merge <branch>
git merge --no-ff <branch>
git merge --abort

git merge --squash <branch>
git commit -m "<message>"

git rebase <upstream>
git rebase --abort
git rebase --continue

git reflog
```

GitHub (pull request merge methods — UI or CLI dialect of the same three
histories):

```
# On the pull request: Merge commit | Squash and merge | Rebase and merge
gh pr merge --merge
gh pr merge --squash
gh pr merge --rebase
```

- `git merge <branch>` joins the named history into the current branch. When
  histories have diverged, Git creates a **merge commit** with two parents —
  the previous tip of the current branch and the tip of `<branch>` — so both
  lines remain reachable. When the current tip is already an ancestor of
  `<branch>`, Git may **fast-forward** instead: it moves the branch pointer
  forward with **no** new merge commit (the no-commit special case of merge).
- `git merge --no-ff <branch>` always creates a merge commit even when a
  fast-forward would have been possible. GitHub’s default **Merge pull
  request** option merges with the equivalent of `--no-ff`.
- `git merge --squash <branch>` updates the index and working tree as if a merge
  had been performed, but does **not** create a commit, move `HEAD`, or record
  `MERGE_HEAD`. A following `git commit` records **one** new commit on the base
  whose tree matches the squash result; that commit has a single parent (the
  pre-squash base tip). The original head commits are **not** linked into base
  history as parents.
- `git rebase <upstream>` rewrites the current branch by replaying its unique
  commits **one by one** onto `<upstream>` as **new** commits (new hashes). The
  branch tip moves to the last replayed commit; history is linear; the original
  pre-rebase commits are abandoned by the branch (still recoverable via
  reflog while entries remain).
- `git merge --abort` and `git rebase --abort` are safe exits mid-operation:
  they try to restore the pre-merge or pre-rebase state when a conflict (or
  other stop) has left the operation unfinished.
- `git reflog` lists recent movements of `HEAD` and branch tips so a completed
  but unwanted local rewrite can still be found by hash.
- `gh pr merge --merge` / `--squash` / `--rebase` select GitHub’s merge commit,
  squash and merge, or rebase and merge method for the open pull request (when
  the repository allows that method).

## What happens (local and remote)

**Merge commit (true merge).** Git combines the trees of the current branch and
the named branch. Except in a pure fast-forward, it records a new commit with
two parents, so `git log` on the base still reaches every commit from both
sides. Before the merge starts, Git sets `ORIG_HEAD` to the tip of the current
branch. Nothing is sent to a remote until you push the updated base (or a host
merges a pull request and you later fetch).

**Fast-forward.** If the base tip has not diverged and is an ancestor of the
head tip, a default `git merge` can simply move the base pointer to the head
tip. No merge commit appears; history stays a single chain. That is still a
merge *operation*, but not a two-parent merge *commit*.

**Squash.** `git merge --squash` stages the combined result without recording a
merge. Your next `git commit` is an ordinary single-parent commit on the base.
Collaborators who later look at base history see one commit for the whole
integration, not the individual head commits and not a merge parent link. On
GitHub, **Squash and merge** collapses the pull request’s commits into one
commit on the base (using a fast-forward-style update of the base tip after the
squash commit is prepared).

**Rebase.** `git rebase <upstream>` lists commits unique to the current branch
since it diverged from `<upstream>`, checks out the upstream tip, and replays
those commits in order (similar to cherry-picking each one). Each successful
replay creates a **new** commit object with a **new** identity. The branch is
updated to the final replayed tip; the old chain is no longer the branch’s
history. At the start of the rebase, `ORIG_HEAD` points at the tip of the
branch being rebased. On GitHub, **Rebase and merge** adds each pull request
commit onto the base without a merge commit, rewriting those commits with new
SHAs so the base history stays linear. GitHub’s rebase-and-merge behavior is
close to, but not identical to, local `git rebase` (for example, it always
produces new committer metadata and new SHAs, and it drops commits that were
empty to begin with).

**Host versus laptop.** Merging a pull request on GitHub updates the **remote**
base branch according to the chosen method. Local clones do not change until
someone fetches or pulls. Choosing a method is a **policy** decision for that
repository (and often enforced by which merge buttons the host enables); it is
not a rule of Git itself. Other forges offer the same three history shapes under
their own UI labels; clone, fetch, and push remain plain Git.

## Practical example

A small notes project has `main` and a topic branch `note-export` with two
commits. Histories have diverged slightly, so a plain merge would create a
merge commit.

**Option A — merge commit (preserve both lines):**

```
$ git switch main
$ git merge note-export
$ git log --oneline --graph --decorate -8
```

If Git stops with conflicts, abort safely and restore the pre-merge tip:

```
$ git merge --abort
```

**Option B — squash (one commit on main, no merge parent):**

```
$ git switch main
$ git merge --squash note-export
$ git commit -m "Add note export helpers"
$ git log --oneline --graph --decorate -8
```

**Option C — rebase (linear history; rewrites the topic branch only while still
local):**

```
$ git switch note-export
$ git rebase main
$ git log --oneline --graph --decorate -8
```

If a replay stops with conflicts and you want out without finishing:

```
$ git rebase --abort
```

After a successful local rebase of an **unpublished** topic branch, you can open
or update a pull request and let the host apply its configured method. Prefer
**not** rebasing a branch that others already pulled unless the team has agreed
how to recover.

On GitHub, the same three outcomes for a pull request into `main` correspond to
**Merge commit**, **Squash and merge**, and **Rebase and merge** (or
`gh pr merge` with `--merge`, `--squash`, or `--rebase`).

## Explanation guidance

### Essential

Think of integration as “put this work onto that line,” and then ask **what
history should look like afterward**. A **merge commit** is a true join: one new
commit with two parents, both prior histories preserved. A **fast-forward** is
the special case when the base never moved — Git only slides the pointer; no
extra merge commit. A **squash** builds one new single-parent commit on the base
that carries the combined tree; the head’s individual commits do not become
parents of that result. A **rebase** rebuilds the head’s commits on top of the
base as new objects (new hashes) so history reads as one straight line. Git’s
commands and GitHub’s three pull request merge methods are two interfaces for
those same history shapes. The method a team enables is **policy**, not
universal Git law — different projects legitimately choose differently. A pull
request is a forge review-and-merge workflow; it is not `git pull`.

### Experienced-user note

Default `git merge` will fast-forward when it can; force a recorded join with
`--no-ff` when you want an explicit merge node even for a trivial side branch.
`git merge --squash` deliberately omits `MERGE_HEAD`, so the next commit is not
a merge commit — that is why squash history looks “flat” on the base. Rebase’s
step “replay one by one” is why conflicts can appear mid-sequence and why
`--continue` / `--skip` / `--abort` exist. Treat any rebase of commits that have
already been pushed as a **history rewrite**: collaborators who based work on
the old hashes will diverge until everyone coordinates. Prefer rebase for
private cleanup of a topic branch; prefer merge commit or squash (per team
policy) for shared default branches. GitHub’s rebase-and-merge always mints new
SHAs on the base even when a local rebase might have been a no-op in edge
cases — read host docs when diagnosing “why did the hashes change?”

### Optional deeper context

A merge commit’s two parents are first-class objects in the commit graph; tools
that walk first-parent history (`git log --first-parent`) deliberately hide the
side line while full history still contains it. Squash discards that graph
structure on purpose: recovery of intermediate head commits after a squash
depends on the head branch (or reflog) still existing, not on base parents.
Rebase’s new commits reuse patch content but not object identity; `ORIG_HEAD`
and the branch reflog record the pre-rewrite tip for local recovery. Host-side
indirect merges (base already contains the head commits by another path) can
mark a pull request merged without pressing a merge button — uncommon, but
relevant to automation that assumes every “merged” PR used an explicit method.

## Cautions and common failures

- **Merge method is policy, not law.** Arguing that “real Git always merges” or
  “real teams always squash” confuses preference with requirement. Follow the
  repository’s documented or host-enforced method; different projects choose
  differently for good reasons (auditability, linear default branch, one PR =
  one commit, and so on).
- **Never rebase shared or already-pushed history without coordination
  (destructive).** Rebase replaces old commits with new hashes. Anyone who
  already fetched the old tip will have a divergent history; a later push of
  the rebased branch is a non-fast-forward rewrite and can force collaborators
  into painful recovery. Rewrite only private tips, or after an explicit team
  plan (including how others will reset or re-fetch).
- **Force-pushing a rebased shared branch without agreement is destructive.**
  Updating a remote branch after rebase usually requires a force-style push;
  that can drop others’ commits from the remote tip. Coordinate first; prefer
  safer push options only when the team has already agreed to the rewrite.
- **Mid-operation exits.** If a merge or rebase stops for conflicts and you are
  not ready to finish, use `git merge --abort` or `git rebase --abort` rather
  than ad-hoc resets you do not fully understand. Abort reconstructs the
  pre-operation state when possible; uncommitted changes present *before* the
  operation can still make recovery harder — commit or stash first.
- **Recovery after a completed but unwanted local merge or rebase.** The old tip
  is usually still in the object database. Check `ORIG_HEAD` immediately after
  the operation (Git sets it at the start of merge and rebase) and run
  `git reflog` to find the pre-rewrite `HEAD` or branch entry (for example
  `HEAD@{1}` or the reflog line for the rebase/merge). Restore with a deliberate
  recovery such as `git reset --hard <that-commit>` **only** when discarding the
  current tip is intended and the work is still local — **never** hard-reset a
  shared branch others rely on without coordination. Reflog entries are local
  and are eventually pruned; recover promptly.
- **Squash is not a merge commit.** After squash, base history will not show the
  original multi-commit head chain or a two-parent join. Keep the head branch
  until you are sure you no longer need those intermediate commits.
- **Pull request ≠ `git pull`.** Choosing **Merge commit**, **Squash and
  merge**, or **Rebase and merge** on GitHub updates the host base; it does not
  run `git pull` on anyone’s machine. Collaborators still fetch or pull to
  update local clones.
- **Conflicts are not a failed product.** They mean both sides edited the same
  region. Resolve and continue, or abort; do not delete conflict markers without
  choosing a real resolution.

## Related capabilities

- Commits and history — what a commit records, parent links, and how
  `--amend` rewrites identity (same “never rewrite shared history” rule).
- Branches and switching — creating and checking out the base and head tips
  you integrate.
- Remotes, fetch, and pull — downloading a base that moved on the host after a
  pull request merge; pull’s integrate step may itself merge or rebase.
- Push and upstream branches — publishing a topic branch or an updated base;
  why a post-rebase push is often non-fast-forward.
- Pull requests and review — proposing head-into-base on a forge, distinct
  from `git pull`, before a merge method is chosen.
- Working tree, staging, and status — clean trees before merge/rebase and
  staging resolutions during conflicts.

## Official sources

- <https://git-scm.com/docs/git-merge> — true merge, two-parent merge commits,
  fast-forward, `--no-ff`, `--squash`, `ORIG_HEAD`, and `git merge --abort`.
- <https://git-scm.com/docs/git-rebase> — replaying commits onto a new base,
  new commit chain, `ORIG_HEAD`, and `git rebase --abort` / `--continue`.
- <https://git-scm.com/docs/git-commit> — the ordinary commit used after
  `git merge --squash` to record a single-parent result.
- <https://git-scm.com/docs/git-reflog> — recovering previous `HEAD` and branch
  tip positions after local rewrites.
- <https://git-scm.com/docs/user-manual> — merge commits in the object model and
  rewriting history safely.
- <https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging> —
  merge commits and fast-forwards in narrative form.
- <https://git-scm.com/book/en/v2/Git-Branching-Rebasing> — rebase diagrams and
  the danger of rebasing published work.
- <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/about-pull-request-merges>
  — merge commit, squash and merge, and rebase and merge; history each produces;
  relation to `--no-ff` and fast-forward; note that host rebase always creates
  new SHAs.
- <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/merging-a-pull-request>
  — merging a pull request on GitHub.
- <https://cli.github.com/manual/gh_pr_merge> — `gh pr merge` and `--merge`,
  `--squash`, and `--rebase`.

## Provenance

Authored 2026-08-01 against the official Git and GitHub documentation cited
above, retrieved via Context7 (`/websites/git-scm`) and cross-checked directly
against the linked pages. Module-level provenance policy and source registry
live in `../provenance.md` and `../source-registry.md`.
