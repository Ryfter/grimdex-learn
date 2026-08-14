---
title: Post-merge synchronization and cleanup
module_id: git-and-github
capabilities:
  - post-merge-synchronization-and-cleanup
context7_library: /websites/git-scm
context7_queries:
  - git switch main pull update local default branch after remote merge
  - git branch -d delete fully merged branch -D force delete unmerged
  - git push origin --delete remote branch delete empty refspec
  - git fetch --prune remove stale remote-tracking refs fetch.prune
  - git merge base into feature branch rebase private tip keep current
  - squash merge no ancestry branch -d refuses unmerged tip verify then delete
official_sources:
  - https://git-scm.com/docs/git-switch
  - https://git-scm.com/docs/git-pull
  - https://git-scm.com/docs/git-branch
  - https://git-scm.com/docs/git-push
  - https://git-scm.com/docs/git-fetch
  - https://git-scm.com/docs/git-config
  - https://git-scm.com/docs/git-merge
  - https://git-scm.com/docs/git-rebase
  - https://git-scm.com/docs/git-reflog
  - https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/merging-a-pull-request
  - https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/about-pull-request-merges
  - https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-the-automatic-deletion-of-branches
  - https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/deleting-and-restoring-branches-in-a-pull-request
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

After a pull request merges on a forge, the host base branch has moved, but every
local clone still holds whatever branch tips it last knew. Post-merge
synchronization and cleanup is the everyday loop that brings the local default
branch up to date, retires the merged topic branch (locally and, when needed, on
the remote), and removes stale remote-tracking names that still point at deleted
remote branches. Separately, while other work is still in flight, the same ideas
cover keeping a long-lived feature branch current with its base. A pull request
is a forge collaboration feature; it is not the Git command `git pull`. Merging
on the host does not update anyone's laptop until that person fetches or pulls.

## When it is useful

Reach for this capability whenever a pull request has just landed on the shared
default branch and you need a clean local workspace: switch to the default
branch, pull the merge result, delete the finished topic branch, and prune
remote-tracking refs that no longer exist on the host. Use the same hygiene after
closing a pull request without merging when the topic branch should go away. Use
the in-flight update pattern when a feature branch has lagged behind `main` (or
another base) and you need current base history before the next push or review.
Skip aggressive deletion when the topic tip still holds commits you have not
verified on the base — especially after a squash merge, where Git's merged-check
and the content landing on the base are not the same fact.

## Prerequisites

- A local clone that already has the default branch (for example `main`) and the
  topic branch that was the pull request head.
- Network access to the remote (`origin` or equivalent) so `git pull`,
  `git fetch`, and optional remote branch deletion can talk to the host.
- For remote deletion: permission to delete the head branch on the forge, or a
  repository setting that deletes head branches automatically after merge.
- A clean enough working tree to switch branches and pull without unfinished
  merge or rebase state you do not intend to keep.

## Current syntax

```
git switch main
git pull

git branch -d <topic-branch>
git branch -D <topic-branch>

git push origin --delete <topic-branch>
git push origin :<topic-branch>

git fetch --prune
git fetch -p
git config fetch.prune true

git switch <feature-branch>
git merge main
git rebase main

git reflog
```

- `git switch main` checks out the local default branch (use the real default
  name for the project if it is not `main`).
- `git pull` fetches from the configured upstream and integrates into the current
  branch so the local default tip matches the host after the pull request merge.
- `git branch -d <topic-branch>` deletes a local branch only when it is fully
  merged into its upstream (or into `HEAD` if no upstream is set) — the safety
  check that refuses unmerged work.
- `git branch -D <topic-branch>` is `--delete --force`: it deletes the branch
  regardless of merge status and can drop the only name pointing at unmerged
  commits.
- `git push origin --delete <topic-branch>` (equivalently
  `git push origin :<topic-branch>`) deletes the named branch on the remote.
  Some repositories also auto-delete head branches after a pull request merges.
- `git fetch --prune` (short `-p`) updates remote-tracking branches and removes
  local remote-tracking refs whose remote branches no longer exist. Setting
  `fetch.prune` to `true` makes prune part of ordinary fetches.
- On an in-flight feature branch, `git merge main` brings base history in with a
  merge; `git rebase main` replays the feature commits on top of the base when
  the tip is still private — both are covered in depth on the merge, squash, and
  rebase page.
- `git reflog` lists recent positions of `HEAD` and branch tips so a tip removed
  by a mistaken local delete can often be recovered while the entry remains.

## What happens (local and remote)

On the forge, merging a pull request updates the base branch on the remote and
may leave the head branch in place, delete it from the pull request UI, or
delete it automatically if the repository is configured to remove head branches
after merge. None of that rewrites your local branches by itself. Locally,
`git switch main` moves `HEAD` to the default branch; `git pull` then downloads
new objects and advances the local default tip so it includes the merge result.
Deleting a local branch with `git branch -d` or `-D` only removes a name in this
repository: the commits remain in the object database until garbage collection,
but without a branch name they are easy to lose track of. Deleting a remote
branch with `git push --delete` removes that ref on the host; your clone may
still list a stale `origin/<topic-branch>` until a prune fetch removes the
remote-tracking ref. `git fetch --prune` compares remote-tracking names to what
the remote still has and drops the obsolete ones. Squash-and-merge on a forge
creates a new commit on the base whose content comes from the head branch but
whose ancestry does not include the old head tip, so Git's "fully merged" check
for `git branch -d` often still fails even though the change is already on the
base.

## Practical example

A pull request for `feature/add-greeting` has just been merged into `main` on
the host. On a laptop that still has the old topic branch checked out:

```
$ git switch main
$ git pull
$ git branch -d feature/add-greeting
$ git push origin --delete feature/add-greeting
$ git fetch --prune
```

If the repository already deleted the remote head branch automatically, the
`git push --delete` step is unnecessary; `git fetch --prune` still clears the
stale `origin/feature/add-greeting` remote-tracking name.

If the merge method was squash and `git branch -d` refuses because the tip is
not reachable from `main`, verify that the change is on the default branch, then
force-delete only after that check:

```
$ git log --oneline main -5
$ git branch -D feature/add-greeting
```

While another feature is still open and has fallen behind `main`:

```
$ git switch feature/in-progress
$ git merge main
# or, only while the feature tip remains private and unshared:
# git rebase main
```

If a local branch was force-deleted by mistake and the commits are still needed,
recover while the reflog still records them:

```
$ git reflog
$ git branch feature/add-greeting <commit-from-reflog>
```

Do not treat that recovery as a license to rewrite shared remote history;
restoring a private local name is local, while force-pushing recovered tips to a
shared remote needs explicit coordination.

## Explanation guidance

### Essential

After a host-side merge, three local jobs remain: update the default branch,
retire the finished topic branch, and clean remote-tracking names that no longer
exist on the remote. Prefer `git branch -d` over `-D` because `-d` only deletes
when Git believes the work is already reachable from the upstream or from
`HEAD` — that is the safety rail. Remote cleanup is separate: either delete the
remote branch yourself with `git push origin --delete`, or rely on the forge's
auto-delete setting, then run `git fetch --prune` so `origin/*` matches reality.
Keep the vocabulary straight: a **pull request** is the forge's propose-and-merge
workflow; **`git pull`** is how this clone fetches and integrates into the branch
you currently have checked out.

### Experienced-user note

`git branch -d` tests reachability of the branch tip from the configured
upstream (or from `HEAD`), not "did a pull request UI say merged." After a true
merge commit, the old head tip is usually an ancestor of the updated base, so
`-d` succeeds once you are on a pulled `main`. After **squash and merge**, the
base gains a new single commit that is not a descendant of the old head tip in
the commit graph, so `-d` correctly reports the branch as not fully merged even
though the product change landed. The safe habit is verify-then-delete: confirm
the PR is merged and that the content (or squash commit) is on the default
branch, then use `-D` only for that cleaned-up tip. Pruning is about
remote-tracking refs under `refs/remotes/`, not about deleting local topic
branches; `fetch.prune` simply makes every fetch do the remote-tracking cleanup
you would otherwise remember as `--prune`. Keeping an in-flight feature branch
current is ordinary integration: merge the base into the feature for a shared or
already-pushed tip, or rebase onto the base only while the feature history is
still private — never rewrite shared feature history without coordination.

### Optional deeper context

Branch deletion removes a ref; it does not immediately purge objects. Git keeps
unreachable commits until maintenance and expiration remove them, and
`git reflog` (and related recovery tools) can still name a tip that no branch
points at — but branch deletion also drops that branch's own reflog, and all
reflog entries are local and eventually expire, so recovery is time-bounded.
Remote deletion with an empty source refspec (`:`*dst* or `--delete`) is the
push protocol's way of asking the remote to drop a ref; hosts may further
restrict deletes via protection rules. Forge auto-delete of head branches is
repository policy layered on top of Git: the remote ref disappears without a
local `git push --delete`, which is why prune remains useful even when you never
deleted anything yourself. Squash's missing ancestry link is the same graph fact
that makes squash history linear on the base: content was copied into a new
commit, not joined with a second parent that preserves the head tip.

## Cautions and common failures

- **Pull request is not `git pull`.** Merging on GitHub (or another forge)
  updates the remote base only. Every clone still needs `git switch` to the
  default branch and `git pull` (or an equivalent fetch-plus-integrate) to see
  the result.
- **Prefer `git branch -d`; treat `git branch -D` as destructive.** `-d` refuses
  when the tip is not fully merged into the upstream or `HEAD`. `-D` skips that
  check and can remove the only easy name for unmerged commits. If `-D` was a
  mistake, run `git reflog` promptly, find the tip as it was before the delete
  (often a recent `HEAD@{n}` entry from when that branch was checked out), and
  recreate the branch with `git branch <name> <commit>`. Reflog entries are
  local and are eventually pruned — recover while they remain.
- **Never force-delete shared work you have not verified elsewhere.** If other
  people still need the tip and it is not on the base, coordinate before `-D` or
  remote deletion. Restoring a local name from the reflog does not put the
  branch back on the remote; republishing may require a push, and rewriting a
  shared remote tip still needs team agreement.
- **Squash-merged branches often look "unmerged" to `-d`.** Squash lands content
  under a new commit without making the old head tip an ancestor of the base, so
  `git branch -d` may refuse. Verify the merge and the content on the default
  branch first, then delete with `-D` only after that check — do not force-delete
  blindly because the pull request page said "merged."
- **Remote branch may already be gone.** Auto-delete on the host or a teammate's
  `git push --delete` can remove the remote head before you try. A failed remote
  delete is then expected; still prune remote-tracking refs so local names do
  not lie.
- **Stale remote-tracking refs confuse status and completion tools.** Without
  `git fetch --prune` (or `fetch.prune`), `origin/<deleted-branch>` can linger
  and look like a live remote branch. Prune updates the map; it does not delete
  your local topic branches.
- **Cannot delete the branch you have checked out.** Switch to another branch
  (usually the updated default) before `git branch -d` / `-D`.
- **Updating an in-flight feature branch can be destructive if you rebase shared
  history.** Merging the base into the feature is the safer default for tips
  others already use. Rebase rewrites commit identities; **never rebase a shared
  or already-pushed feature branch without explicit coordination**, and never
  force-push the result onto a shared remote without agreement. Local recovery
  after a bad rebase uses `git reflog` / `ORIG_HEAD` while those records remain;
  see the merge, squash, and rebase page for the full recovery pattern.

## Related capabilities

- Pull requests and review — how a pull request merges on the forge before this
  local cleanup loop runs.
- Remotes, fetch, and pull — `git pull` and `git fetch` as the way clones learn
  that the remote base moved; prune as part of fetch hygiene.
- Branches and switching — creating and checking out default and topic branches
  with `git switch`.
- Push and upstream branches — publishing topic branches and deleting remote
  refs with `git push`.
- Merge commit, squash, and rebase — merge methods on the host, why squash lacks
  a head-tip ancestry link, and merge-versus-rebase when refreshing an in-flight
  feature branch.
- Commits and history — reading the default branch after pull and using
  `git reflog` when a local tip must be recovered.

## Official sources

- <https://git-scm.com/docs/git-switch> — checking out the local default branch
  before updating it.
- <https://git-scm.com/docs/git-pull> — fetch-plus-integrate into the current
  branch after a remote merge.
- <https://git-scm.com/docs/git-branch> — `git branch -d` / `--delete` merged
  check, `-D` force delete, and deleting remote-tracking names with `-d -r`.
- <https://git-scm.com/docs/git-push> — `git push --delete` and empty-source
  refspecs that delete a remote branch.
- <https://git-scm.com/docs/git-fetch> — `--prune` / `-p` and the pruning model
  for stale remote-tracking refs.
- <https://git-scm.com/docs/git-config> — `fetch.prune` and related fetch
  configuration.
- <https://git-scm.com/docs/git-merge> — merging a base branch into an in-flight
  feature branch.
- <https://git-scm.com/docs/git-rebase> — rebasing a private feature tip onto an
  updated base.
- <https://git-scm.com/docs/git-reflog> — recovering previous tip positions after
  a local branch delete or rewrite.
- <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/merging-a-pull-request>
  — merging a pull request on the host and optional head-branch deletion.
- <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/about-pull-request-merges>
  — merge commit, squash and merge, and rebase and merge history shapes.
- <https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-the-automatic-deletion-of-branches>
  — automatically deleting head branches after pull requests merge.
- <https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/deleting-and-restoring-branches-in-a-pull-request>
  — deleting and restoring a pull request head branch on GitHub.

## Provenance

Authored 2026-08-01 against the official Git documentation and GitHub Docs cited
above, retrieved via Context7 (`/websites/git-scm`) and cross-checked directly
against the linked pages. Module-level provenance policy and source registry
live in `../provenance.md` and `../source-registry.md`.
