---
title: Remotes, fetch, and pull
module_id: git-and-github
capabilities:
  - remotes-fetch-and-pull
context7_library: /websites/git-scm
context7_queries:
  - git remote -v named remote origin URL manage tracked repositories
  - git fetch download objects refs update remote-tracking branches origin/main
  - git pull fetch then integrate merge current branch --rebase option
  - remote-tracking branch refs/remotes last known snapshot not live view
  - git log main..origin/main compare local branch remote-tracking before integrate
  - pull request forge feature not git pull GitHub collaboration
official_sources:
  - https://git-scm.com/docs/git-remote
  - https://git-scm.com/docs/git-fetch
  - https://git-scm.com/docs/git-pull
  - https://git-scm.com/docs/git-log
  - https://git-scm.com/docs/gitrevisions
  - https://git-scm.com/book/en/v2/Git-Basics-Working-with-Remotes
  - https://git-scm.com/book/en/v2/Git-Branching-Remote-Branches
  - https://docs.github.com/en/get-started/git-basics/about-remote-repositories
  - https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests
last_checked: 2026-08-01
last_material_update: 2026-08-01
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

A remote is a named shortname for a repository URL that Git uses when talking
to another copy of the project — most often the shared copy on a host. The
conventional name for the primary remote is `origin` (the default name Git
assigns when you clone). `git remote -v` lists those shortnames and the fetch
and push URLs stored for each one.

Remote-tracking branches such as `origin/main` are local references that
record your last-known snapshot of a branch on a remote. They live under
`refs/remotes/` and are updated when you fetch; they are not a live window into
the remote, and they do not move when someone else pushes until you fetch again.

`git fetch` downloads commits and other objects you do not yet have and updates
remote-tracking branches to match the remote. It does not change your working
tree, your index, or your local branch tips. `git pull` is fetch followed by an
integration step into the current branch — by default that integration merges
(or fast-forwards) the fetched history into what you have checked out. A pull
request on a forge such as GitHub is a separate collaboration feature for
proposing that one branch be merged into another; it is not the `git pull`
command.

## When it is useful

Use this capability whenever local work needs to stay aligned with a shared
repository: after clone, before you start a new day of work, before you push,
and any time you want to see what landed on the remote without immediately
changing your own branch. Prefer fetch-then-inspect when you want to review
incoming commits first; use pull when you intentionally want fetch and
integration in one step. Knowing remotes and remote-tracking branches is also
how multi-remote setups (upstream plus a personal fork, for example) stay
legible.

## Prerequisites

- A Git repository exists and the current directory is inside it.
- At least one remote is configured (clone creates `origin`; otherwise
  `git remote add <name> <url>` has been run).
- Network access and credentials (or SSH keys) are available for the remote if
  it is not a local path.
- For a plain `git pull` with no arguments, the current branch should have an
  upstream configured so Git knows which remote branch to integrate.

## Current syntax

```
git remote -v
git remote add <name> <url>

git fetch
git fetch <remote>
git fetch origin

git pull
git pull <remote> <branch>
git pull --rebase

git log --oneline main..origin/main
git log --oneline HEAD..@{upstream}
```

- `git remote -v` lists each remote shortname with its fetch and push URLs.
- `git remote add <name> <url>` registers a new named remote; afterward
  `git fetch <name>` can create and update remote-tracking branches of the form
  `<name>/<branch>`.
- `git fetch` (or `git fetch origin`) contacts the remote, downloads missing
  objects and refs, and updates remote-tracking branches; it leaves the working
  tree and local branches alone.
- `git pull` runs `git fetch` and then integrates the chosen remote branch into
  the current branch (merge by default when reconciling histories that way;
  `git pull --rebase` uses rebase instead — see merging and rebasing for those
  semantics).
- `git log main..origin/main` lists commits reachable from `origin/main` that
  are not reachable from `main` — a common way to inspect what a fetch brought
  in before integrating. `HEAD..@{upstream}` does the same relative to the
  current branch's configured upstream after a fetch.

## What happens (local and remote)

Remotes are configuration: a name mapped to one or more URLs and default
refspecs. They do not themselves hold commits. When you run `git fetch` against
a remote (commonly `origin`), Git contacts that URL, receives objects needed to
complete the histories being fetched, and updates the corresponding
remote-tracking branches (for example moving `origin/main` to the tip that
exists on the remote right now). Those remote-tracking refs are ordinary local
refs under `refs/remotes/`; after the fetch finishes they are only as current as
that fetch. Nothing in your working tree, index, or local branch (for example
`main`) is rewritten by fetch alone.

`git pull` performs that fetch, then integrates into the branch you currently
have checked out. The default integration path merges the remote-tracking (or
fetched) history into the current branch, which may fast-forward your branch
tip or create a merge commit if histories have diverged. Optionally,
`git pull --rebase` rebases local commits onto the updated upstream instead;
that option only exists here as a pointer — merge and rebase behavior, conflict
handling, and history-rewrite cautions belong on the merging and rebasing page.

Comparing before integrating is a local history walk after fetch: ranges such
as `main..origin/main` show commits on the remote-tracking branch that your
local branch does not yet contain, so you can decide whether to merge, rebase,
or wait. A pull request on GitHub (or another forge) never runs this sequence
by itself; it is a hosted proposal and review workflow that may later result in
a merge on the forge, which you would then fetch or pull like any other remote
update.

## Practical example

Starting from a cloned project with `origin` already configured and the local
branch `main` checked out:

```
$ git remote -v
origin  https://example.com/team/notes.git (fetch)
origin  https://example.com/team/notes.git (push)

$ git fetch origin
$ git log --oneline main..origin/main
```

If the log shows commits you are ready to take, integrate them into the current
branch:

```
$ git pull origin main
```

Or, if you prefer the two-step habit explicitly:

```
$ git fetch origin
$ git log --oneline main..origin/main
$ git merge origin/main
```

A one-shot pull with the optional rebase integration path (semantics on the
merging and rebasing page):

```
$ git pull --rebase origin main
```

## Explanation guidance

### Essential

Think of a remote as a bookmark: a short name (`origin`) for a URL. Think of
`origin/main` as a sticky note of where `main` on that remote was the last time
you fetched — not a live connection. `git fetch` refreshes those sticky notes
and downloads the commits behind them, without touching the files you are
editing or the branch you are on. `git pull` means “fetch, then fold those
updates into my current branch,” usually by merge. Inspecting
`main..origin/main` after a fetch is how you look before you fold. A pull
request is a forge UI and workflow for proposing branch integration; it is not
`git pull`.

### Experienced-user note

After clone, `origin` and the default branch's upstream are usually already set
so bare `git fetch` and `git pull` do the useful thing. Remote-tracking
branches update only for the refspecs configured on that remote (typically
`+refs/heads/*:refs/remotes/origin/*`). Fetch can prune stale remote-tracking
names with `--prune` when branches were deleted on the remote. Prefer
fetch-then-`git log` (or `git log HEAD..@{upstream}`) on shared branches when
incoming history might be large, rebased, or surprising; use pull when the
integration policy for the branch is already agreed. `git pull --rebase` exists
for teams that prefer a linear local history; treat it as “fetch plus rebase,”
not as a different download mechanism.

### Optional deeper context

Fetch writes the names and object IDs of fetched tips to `.git/FETCH_HEAD` and
updates remote-tracking refs according to refspecs. Pull's second step decides
which remote branch to integrate (the current branch's upstream when you pass
no arguments) and then runs merge or rebase accordingly. Range notation
`A..B` in `git log` means commits reachable from `B` excluding those reachable
from `A`, which is why `main..origin/main` is the natural “what would I gain by
integrating?” query after a fetch. Forges may expose additional remotes (a
fork's `origin` plus an `upstream` for the canonical project); Git's model is
the same for every remote name.

## Cautions and common failures

- **Fetch is not update-my-branch.** After `git fetch`, `git status` may report
  that the local branch is behind its upstream; the working tree still matches
  the local branch until you merge, rebase, or pull.
- **Stale remote-tracking branches mislead comparisons.** `origin/main` only
  moves when you fetch (or pull). Comparing against it without a recent fetch
  can hide commits that already exist on the remote.
- **Pull integrates immediately.** If you need to read the incoming commits or
  avoid an unexpected merge commit on a dirty or carefully shaped history,
  fetch and inspect first rather than pulling by habit.
- **Pull can stop on conflicts.** Integration may leave the repository in a
  conflicted merge or rebase state; finish or abort that integration using the
  merge/rebase tools, not by fetching again and hoping the conflict disappears.
- **Upstream must be set for argument-less pull.** `git pull` with no arguments
  needs a configured upstream for the current branch; otherwise name the remote
  and branch explicitly (`git pull origin main`).
- **A pull request is not `git pull`.** Opening or merging a pull request on
  GitHub does not run `git pull` on anyone's laptop. After a PR lands on the
  default branch, contributors still fetch or pull to update their local
  clones.
- **Multiple remotes mean multiple shortnames.** Fetching `origin` does not
  update tracking branches for `upstream` or other remotes; fetch each remote
  you care about (or use a configured remote group).

## Related capabilities

- Creating and cloning repositories — how `origin` is established on clone and
  how remotes are added to a local-only repository.
- Branches and switching — local branches versus remote-tracking names, and
  checking out work that tracks a remote branch.
- Commits and history — reading ranges such as `main..origin/main` with
  `git log` after a fetch.
- Merging and rebasing — what pull's integrate step actually does, including
  `git pull --rebase`, fast-forwards, and conflict recovery.
- Pushing to remotes — sending local commits to a remote after fetch/pull have
  aligned history.
- Pull requests on a forge — proposing and reviewing branch integration on
  GitHub (or another host), distinct from the `git pull` command.

## Official sources

- <https://git-scm.com/docs/git-remote> — named remotes, `git remote -v`, and
  how fetch updates remote-tracking branches for a remote.
- <https://git-scm.com/docs/git-fetch> — download objects and refs; update
  remote-tracking branches without integrating into the current branch.
- <https://git-scm.com/docs/git-pull> — fetch then integrate into the current
  branch; merge versus `--rebase`.
- <https://git-scm.com/docs/git-log> — viewing commit ranges after fetch.
- <https://git-scm.com/docs/gitrevisions> — `A..B` range meaning used in
  comparisons such as `main..origin/main`.
- <https://git-scm.com/book/en/v2/Git-Basics-Working-with-Remotes> — remotes,
  `origin`, fetch versus pull.
- <https://git-scm.com/book/en/v2/Git-Branching-Remote-Branches> —
  remote-tracking branches as last-known remote state.
- <https://docs.github.com/en/get-started/git-basics/about-remote-repositories>
  — remote URLs and the usual `origin` name on GitHub.
- <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests>
  — pull requests as a GitHub collaboration feature.

## Provenance

Authored 2026-08-01 against the official Git and GitHub documentation cited
above, retrieved via Context7 (`/websites/git-scm`) and cross-checked directly
against the linked pages. Module-level provenance policy and source registry
live in `../provenance.md` and `../source-registry.md`.
