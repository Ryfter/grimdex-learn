---
title: Push and upstream branches
module_id: git-and-github
capabilities:
  - push-and-upstream-branches
context7_library: /websites/git-scm
context7_queries:
  - git push update remote refs send objects origin branch
  - git push -u --set-upstream tracking branch remote push pull defaults
  - upstream branch @{upstream} status ahead behind push.default simple
  - non-fast-forward push rejection remote moved fetch integrate again
  - git push --force-with-lease expected remote-tracking vs --force overwrite
  - branch protection forge force push shared history coordination
official_sources:
  - https://git-scm.com/docs/git-push
  - https://git-scm.com/docs/git-fetch
  - https://git-scm.com/docs/git-pull
  - https://git-scm.com/docs/git-status
  - https://git-scm.com/docs/git-reflog
  - https://git-scm.com/book/en/v2/Git-Basics-Working-with-Remotes
  - https://git-scm.com/book/en/v2/Git-Branching-Remote-Branches
  - https://docs.github.com/en/get-started/git-basics/about-remote-repositories
  - https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
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

`git push` publishes local commits to a remote repository: it updates one or more
branch refs (or other refs) on the remote and sends any objects the remote does
not already have. The simplest form names a remote and a branch, for example
`git push origin main`. An **upstream** (also called tracking information) is
the default remote branch associated with a local branch. Once set, plain
`git push` and `git pull` can use that remote-and-branch pair without repeating
the names, and commands such as `git status` can report how far the local branch
is ahead of or behind that upstream. `git push -u origin <branch>` (equivalently
`--set-upstream`) pushes the branch and records that upstream for later
argument-less push and pull.

## When it is useful

Use this capability whenever local commits that exist only on your machine need
to appear on a shared remote: after finishing a coherent set of commits, when
publishing a new branch so others can see it, and when re-publishing after you
have integrated remote updates. Setting upstream on the first push of a branch
is the habit that makes later bare `git push` and `git pull` work. When a push
is rejected because the remote branch moved, treat that as a signal to fetch and
reconcile — not as a reason to force the remote to match your tip blindly.

## Prerequisites

- A Git repository exists and the current directory is inside it.
- At least one remote is configured (commonly `origin` from clone, or
  `git remote add`).
- Local commits exist that are not yet on the remote branch you intend to
  update (or you are creating that branch on the remote for the first time).
- Network access and credentials (or SSH keys) allow write access to the remote.
- For argument-less `git push` after the first time, the current branch should
  have an upstream configured (or `push.default` and related settings must
  otherwise resolve a destination).

## Current syntax

```
git push
git push <remote> <branch>
git push -u origin <branch>
git push --set-upstream origin <branch>

git fetch
git status
```

- `git push <remote> <branch>` updates the named branch on `<remote>` from the
  matching local branch (for example `git push origin main` updates `main` on
  `origin` from local `main`) and transfers any missing objects.
- `git push` with no arguments uses the current branch's configured upstream
  (and related `push.default` rules) when that information is set; without an
  upstream, Git may refuse or require an explicit remote and branch.
- `git push -u origin <branch>` (same as `--set-upstream`) pushes successfully
  and then stores upstream tracking so later plain `git push` / `git pull` and
  status ahead/behind reporting know the default remote branch.
- `git fetch` downloads remote updates and refreshes remote-tracking branches
  without changing your working tree — the first step when a push is rejected.
- `git status` reports, among other things, how the current branch relates to
  its upstream (ahead, behind, or diverged) when tracking is configured.

Pushing a branch name that does not yet exist on the remote creates that branch
there at the tip you are publishing.

## What happens (local and remote)

Locally, nothing about your commits or working tree is rewritten by a normal
push: Git reads the commits reachable from the ref you are sending and talks to
the remote. On the remote, the destination ref is updated only when the update
is allowed. By default, Git refuses a non-fast-forward update — that is, when
the remote tip is not an ancestor of the commit you are pushing, so accepting
your tip would drop commits that currently exist only on the remote (or that
you never integrated). That refusal is the usual "remote rejected / non-fast-
forward" failure when someone else pushed (or you pushed from another clone)
while you still had older remote history.

After a successful push of a new branch name, the remote has a branch tip that
did not exist before, and other clones can fetch it. After `-u` / `--set-
upstream`, your local branch records which remote and remote branch are its
upstream; later plain push and pull default to that pair, and status can
compare your tip to that upstream's last-known position (via remote-tracking
refs updated by fetch).

None of this is a pull request. A pull request on a forge such as GitHub is a
hosted proposal-and-review workflow for integrating one branch into another; it
is not the `git push` or `git pull` command.

## Practical example

Starting from a cloned project with local commits on a new branch that only
exists on your machine:

```
$ git switch -c note-export
# ... edit, add, and commit ...
$ git push -u origin note-export
```

That publishes `note-export` on `origin` and sets upstream tracking. Later,
after more local commits on the same branch:

```
$ git push
$ git status
```

If push is rejected because the remote branch advanced:

```
$ git fetch origin
$ git log --oneline HEAD..@{upstream}
# inspect, then integrate (merge or rebase — see merging and rebasing), then:
$ git push
```

Never skip straight from a non-fast-forward rejection to a blind force push on
a branch others use.

## Explanation guidance

### Essential

Push sends *your* commits *to* a remote branch; it does not pull remote commits
into your branch. Upstream is the remembered default remote-and-branch pair for
the branch you are on — the thing plain `git push` and `git pull` aim at, and
the reference `git status` uses for "ahead/behind." The first push of a brand-
new branch name creates that branch on the remote. When the remote already has
commits you do not have on the tip you are replacing, Git rejects a normal push
so those commits are not silently discarded. The correct response is fetch,
inspect, integrate those commits into your history, then push again.

### Experienced-user note

`push.default` (often `simple`) and whether upstream is set decide what bare
`git push` does; when in doubt, name the remote and branch explicitly. Upstream
is stored in config as `branch.<name>.remote` and `branch.<name>.merge`; the
shorthand `@{upstream}` refers to the upstream of the current branch after
tracking is set. Remote-tracking names such as `origin/note-export` still only
move when you fetch (or when a push updates your view of what you just sent).
Treat force-style updates as exceptional and team-coordinated; prefer the
safer lease form when a rewrite is truly required — see Cautions.

### Optional deeper context

A push refspec describes which local object updates which remote ref; a plain
branch name expands to updating the same-named branch on the remote. Fast-
forward means the remote tip is an ancestor of the new tip, so history only
grows. Non-fast-forward updates require an explicit force-style option and can
leave commits unreferenced on the remote. Hosts may add further push rules
(hooks, deny options, or branch protection) on top of Git's own checks.

## Cautions and common failures

- **Rejected non-fast-forward is a stop sign, not a force hint.** When the
  remote tip moved, run `git fetch`, inspect the new commits (for example with
  `git log` against `@{upstream}` or the remote-tracking branch), integrate
  them into your branch, and push again. Do not answer a rejection with a
  blind force push.
- **`--force-with-lease` versus `--force` (destructive).** Plain
  `git push --force` (or a `+` refspec) disables the fast-forward check and
  overwrites the remote ref unconditionally; it can delete collaborators'
  commits from that branch tip. `--force-with-lease` still rewrites the remote
  tip, but only if the remote ref is still at the value your remote-tracking
  branch last recorded — if someone else pushed since your last fetch, the
  lease fails and the overwrite is refused. Prefer lease over plain force when
  any force-style push is unavoidable. **Never force-push shared branches
  without explicit team coordination.** Recovery if a force push discarded
  remote tips others needed: those collaborators often still hold the lost
  commits in their own clones (and in local reflogs); re-fetch is not enough if
  the remote tip was moved — someone who still has the old commits can
  re-publish them after coordination. Hosts may also retain or protect history
  (for example GitHub branch protection blocking force pushes by default on
  protected branches). On your own machine, `git reflog` records where your
  branch and `HEAD` pointed before local resets or rewrites so you can recover
  local tips; recover promptly because reflog entries are eventually pruned.
- **Upstream not set.** Argument-less `git push` or `git pull` may fail or do
  nothing useful until you pass remote and branch or set upstream with
  `-u` / `--set-upstream`.
- **Push is not a pull request.** Publishing a branch with `git push` does not
  open a pull request; opening a pull request on GitHub does not run `git push`
  or `git pull` on anyone's laptop.
- **Branch protection on forges.** Hosts such as GitHub can protect important
  branches with rules that block force pushes, require reviews, or otherwise
  constrain who may update those branches — expect protected default branches
  to reject operations that would be allowed on an unprotected topic branch.

## Related capabilities

- Remotes, fetch, and pull — downloading remote history and integrating it
  before a retry push after a rejection.
- Branches and switching — creating and checking out the local branch you are
  about to publish.
- Commits and history — the snapshots push publishes; reading ranges after
  fetch with `git log`.
- Merging and rebasing — how to integrate remote commits after a rejected push.
- Working tree, staging, and status — `git status` ahead/behind relative to
  upstream after tracking is set.
- Pull requests on a forge — proposing branch integration on GitHub (or another
  host), distinct from `git push` and `git pull`.

## Official sources

- <https://git-scm.com/docs/git-push> — `git push`, `-u` / `--set-upstream`,
  upstream branches, non-fast-forward refusal, `--force`, and
  `--force-with-lease`.
- <https://git-scm.com/docs/git-fetch> — refreshing remote-tracking branches
  before inspecting or integrating after a rejected push.
- <https://git-scm.com/docs/git-pull> — argument-less pull using the configured
  upstream after tracking is set.
- <https://git-scm.com/docs/git-status> — ahead/behind reporting relative to the
  upstream branch.
- <https://git-scm.com/docs/git-reflog> — recovering previous tip positions after
  local reference moves.
- <https://git-scm.com/book/en/v2/Git-Basics-Working-with-Remotes> — pushing to
  remotes and rejected pushes when the remote advanced.
- <https://git-scm.com/book/en/v2/Git-Branching-Remote-Branches> — publishing
  local branches and tracking relationships.
- <https://docs.github.com/en/get-started/git-basics/about-remote-repositories>
  — remote repositories and the usual `origin` name on GitHub.
- <https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches>
  — branch protection rules, including default blocking of force pushes on
  protected branches.

## Provenance

Authored 2026-08-01 against the official Git and GitHub documentation cited
above, retrieved via Context7 (`/websites/git-scm`) and cross-checked directly
against the linked pages. Module-level provenance policy and source registry
live in `../provenance.md` and `../source-registry.md`.
