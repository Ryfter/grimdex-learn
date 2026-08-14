---
title: Pull requests and review
module_id: git-and-github
capabilities:
  - pull-requests-and-review
context7_library: /websites/git-scm
context7_queries:
  - GitHub pull request collaboration feature not git pull propose merge branch
  - draft pull request ready for review base branch head compare branch
  - pull request review approve request changes comment conversation
  - merge pull request host updates base branch collaborators fetch pull
  - gh pr create view checkout GitHub CLI pull request basics
  - merge request GitLab same concept forge dialect vocabulary
official_sources:
  - https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests
  - https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request
  - https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-comparing-branches-in-pull-requests
  - https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews
  - https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/merging-a-pull-request
  - https://docs.github.com/en/get-started/learning-about-github/github-glossary
  - https://cli.github.com/manual/gh_pr
  - https://cli.github.com/manual/gh_pr_create
  - https://cli.github.com/manual/gh_pr_view
  - https://cli.github.com/manual/gh_pr_checkout
  - https://git-scm.com/docs/git-push
  - https://git-scm.com/docs/git-fetch
  - https://git-scm.com/docs/git-pull
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

A **pull request** is a collaboration feature on a Git hosting platform (a
**forge**), not a Git command. On GitHub, a pull request is a proposal to merge
one branch into another, with a place to describe the change, discuss it, review
the diff, and record decisions before the host updates the target branch. Opening
or merging a pull request does not run `git pull` on anyone's machine. The Git
command `git pull` fetches from a remote and integrates those updates into your
current local branch; a pull request is a host-side review-and-merge workflow for
shared repositories. Other forges use the same idea under different names — on
GitLab the usual term is **merge request** — while clone, fetch, and push remain
plain Git.

A pull request always compares two branches on the host. The **base** branch is
the branch that will receive the change when the pull request merges (often the
repository's default branch). The **head** branch (also called the **compare**
branch) is the branch that carries the proposed commits. Reviewers look at the
difference between those two tips, leave feedback, and eventually someone with
permission merges the proposal into the base on the host.

## When it is useful

Use this capability whenever a change that already lives on a pushed branch needs
review or an explicit merge decision on a shared repository: a feature branch
ready for teammates to inspect, a fix you want discussed before it lands on the
default branch, or work-in-progress you want visible as a draft without inviting
a full review yet. Reach for it after you can create commits on a branch and push
that branch to a remote. Prefer a pull request over pushing straight to a shared
default branch when the project expects review, checks, or a recorded discussion
before integration.

## Prerequisites

- A Git repository linked to a remote on a forge (commonly GitHub), with write
  access to the head branch you will push (or a fork workflow that lets you open
  a pull request into the upstream repository).
- Local commits on a branch other than the intended base, already pushed (or
  ready to push) so the host can see them.
- Network access and credentials that allow the forge UI or GitHub CLI to act on
  the repository.
- Optional for the CLI examples: the GitHub CLI (`gh`) installed and
  authenticated to your account.

## Current syntax

Git has no `git pull-request` command. The usual Git steps that feed a pull
request are branch, commit, and push; the pull request itself is created and
reviewed on the forge (web UI or host CLI).

```
git switch -c <topic-branch>
git add <path>...
git commit -m "<message>"
git push -u origin <topic-branch>
```

On GitHub, open a pull request in the web UI after the branch is on the remote
(Compare & pull request, or the New pull request flow). Choose the **base**
branch (where the change should land) and the **compare** / **head** branch
(your topic branch). You can create a full pull request ready for review or a
**draft** pull request.

GitHub CLI (concept-level; run from a clone of the repository):

```
gh pr create
gh pr create --base <base-branch> --head <head-branch>
gh pr create --draft
gh pr view
gh pr view <number>
gh pr checkout <number>
```

- `git switch -c <topic-branch>`, commit, and `git push -u origin <topic-branch>`
  publish a topic branch the host can use as the head of a pull request.
- `gh pr create` opens a pull request for the current branch (prompts for title
  and body unless you pass flags); `--base` and `--head` name the merge target
  and the branch that carries commits; `--draft` marks the pull request as a
  draft.
- `gh pr view` shows the pull request for the current branch (or a given number
  or URL); it prints title, body, and related metadata in the terminal.
- `gh pr checkout <number>` checks out the head of that pull request locally so
  you can run, test, or edit the proposed branch on your machine.

After the pull request is open, more commits on the same head branch that you
push to the remote appear on the pull request automatically. Reviewers submit
feedback as comments or as a formal review with one of three decisions:
**Comment** (feedback without approving or blocking), **Approve** (ready to
merge from that reviewer's perspective), or **Request changes** (the author
should address the feedback before merge). When requirements are met, someone
merges the pull request on the host. Collaborators then use `git fetch` or
`git pull` on their own clones to download the updated base branch.

Vocabulary across forges:

| Idea | GitHub (this module's dialect) | Other forges (example) |
|---|---|---|
| Propose integrating one branch into another with discussion and review | Pull request | Merge request (GitLab) |
| Branch that receives the merge | Base branch | Target / target branch (wording varies) |
| Branch that carries the proposed commits | Head branch / compare branch | Source branch (wording varies) |

## What happens (local and remote)

Locally, you still do ordinary Git work: create a branch, commit snapshots, and
push the branch so a remote ref exists. None of those steps creates a pull
request by itself. Opening a pull request is a host operation: the forge records
that you want branch *head* merged into branch *base*, stores the description
and conversation, and shows the diff for review. Draft pull requests on GitHub
cannot be merged and do not automatically request reviews from code owners;
marking a draft ready for review is a separate stage change on the host.

As you push more commits to the same head branch, the open pull request's commit
list and diff update to match that branch tip. Review activity lives on the host
(conversation timeline, line comments, formal review decisions). Merging the
pull request updates the **base branch on the remote**: the host integrates the
head's changes into the base using the repository's configured merge method
(merge commit, squash and merge, or rebase and merge, depending on settings).
That host-side update does not change anyone's local working tree. Other
collaborators still need `git fetch` (to refresh remote-tracking branches) and
an integrate step such as `git pull` or merge/rebase on their local base branch
to see the landed work. Closing a pull request without merging leaves the base
branch unchanged on the host.

## Practical example

Shared notes project on GitHub, default branch `main`. You add a short guide on
a topic branch and open a pull request for review:

```
$ git switch -c docs/add-setup-notes
$ echo "Document the first-run setup steps." >> SETUP.md
$ git add SETUP.md
$ git commit -m "Add first-run setup notes"
$ git push -u origin docs/add-setup-notes
```

Create the pull request with GitHub CLI (or use the web UI's Compare & pull
request flow with base `main` and compare `docs/add-setup-notes`):

```
$ gh pr create --base main --title "Add first-run setup notes" --body "Documents the steps a new contributor runs before the first successful build."
$ gh pr view
```

A teammate reviews on GitHub, leaves comments, and may Approve or Request
changes. You address feedback with more commits on the same branch and push
again:

```
$ echo "Mention the required runtime version." >> SETUP.md
$ git add SETUP.md
$ git commit -m "Note required runtime version in setup notes"
$ git push
```

When the pull request is approved and merge requirements are satisfied, merge it
on GitHub (web UI or `gh pr merge`). On another machine that still has the old
`main`, refresh from the remote:

```
$ git switch main
$ git pull
```

That `git pull` is how the laptop learns what the merge already did on the host;
it is not what created or merged the pull request.

## Explanation guidance

### Essential

A pull request is a forge feature for proposing that one branch become part of
another after people have looked at the change. Git is still the tool that
records commits and moves them with push and fetch; GitHub (or another host)
adds the request, conversation, review decisions, and merge button. The central
naming trap is **pull request ≠ `git pull`**: `git pull` updates *your* current
branch from a remote; a pull request asks the *host* to merge *head* into
*base* after review. The standard flow is branch → commit → push → open pull
request → review conversation → push more commits to the same head if needed →
merge on the forge → collaborators fetch or pull to update their clones. Base is
the landing branch; head (compare) is the branch that carries the proposal.
Drafts share the work without treating it as ready to merge. On other forges the
same collaboration idea often appears as a merge request.

### Experienced-user note

After the first push of a topic branch, further pushes to that same remote branch
update an open pull request without reopening it. Reviewers submit either
informal comments or a formal review decision (Comment, Approve, or Request
changes); branch protection on the base can require approvals or status checks
before the host allows merge. `gh pr create`, `gh pr view`, and
`gh pr checkout` cover the common CLI loop — open, inspect, and get the head
branch locally — without replacing the web conversation for deep review. Merge
methods on the host (merge commit, squash, rebase) change how history appears on
the base branch after merge; they still only rewrite or extend history *on the
remote base* at merge time, and every collaborator still has to fetch or pull to
see the result. When reading docs from GitLab or similar hosts, map "merge
request," "source," and "target" onto pull request, head, and base rather than
learning a second mental model.

### Optional deeper context

GitHub's pull request UI organizes collaboration around conversation, commits,
checks, and the files-changed diff for the head-versus-base comparison. The host
may create temporary refs for the pull request head (and sometimes a test merge)
for integrations and local checkout; day-to-day contributors mostly meet those
refs through the UI or `gh pr checkout`. Diffs on a pull request are aimed at
what the head introduces relative to the merge base with the base branch, which
is why updating the head (or refreshing from base when the project asks you to)
keeps the review focused. Cross-repository pull requests (fork head into
upstream base) use the same base/head vocabulary; permission rules differ, but
the Git objects still move with ordinary fetch and push.

## Cautions and common failures

- **Pull request is not `git pull`.** Opening, reviewing, or merging a pull
  request on GitHub does not run `git pull` on your laptop or on anyone else's.
  After a merge, update local clones with fetch/pull yourself.
- **Push is not a pull request.** `git push` only updates remote refs; a pull
  request is a separate forge object you create in the UI or with `gh pr create`.
- **Wrong base or head.** A pull request that targets the wrong base branch
  proposes the wrong integration. Confirm base (landing branch) and compare/head
  (your topic branch) before asking for review.
- **Nothing to review until the branch is on the remote.** Commits that exist
  only locally cannot form a host-side pull request until they are pushed (or
  otherwise available to the forge).
- **Drafts do not merge.** Draft pull requests on GitHub cannot be merged until
  they are marked ready for review; use drafts for early visibility, not as a
  finished merge path.
- **Requested changes and protection rules block merge.** An open "Request
  changes" review, missing required approvals, failing required checks, or merge
  conflicts can prevent merge even when the author considers the work done.
  Address the host's requirements, then merge.
- **Merge updates the host, not every clone.** Collaborators who never fetch or
  pull will keep outdated local base branches and may push non-fast-forward
  updates or open conflicting work by mistake.
- **Vocabulary differs by forge; the idea does not.** Searching only for "pull
  request" on a GitLab-centered project will miss merge-request docs that
  describe the same propose-review-merge flow.

## Related capabilities

- Branches and switching — creating the topic branch that becomes a pull
  request head.
- Commits and history — the snapshots a pull request proposes to integrate.
- Push and upstream branches — publishing the head branch so the forge can open
  a pull request against it.
- Remotes, fetch, and pull — how collaborators download a merged base branch;
  the distinction between `git pull` and a pull request.
- Git and GitHub — the tool-versus-forge map and why pull requests are a host
  collaboration feature.

## Official sources

- <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests>
  — what a pull request is, draft pull requests, and collaboration models.
- <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request>
  — creating a pull request, base and compare branches, drafts, and updating
  the head with more commits.
- <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-comparing-branches-in-pull-requests>
  — base versus head/compare branches and how pull request diffs relate to
  those branches.
- <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews>
  — review decisions: Comment, Approve, and Request changes.
- <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/merging-a-pull-request>
  — merging on the host, draft non-mergeability, and merge methods.
- <https://docs.github.com/en/get-started/learning-about-github/github-glossary>
  — glossary definitions for pull request, base branch, head branch, and
  compare branch.
- <https://cli.github.com/manual/gh_pr> — GitHub CLI `gh pr` command group.
- <https://cli.github.com/manual/gh_pr_create> — `gh pr create`, including
  `--base`, `--head`, and `--draft`.
- <https://cli.github.com/manual/gh_pr_view> — `gh pr view`.
- <https://cli.github.com/manual/gh_pr_checkout> — `gh pr checkout`.
- <https://git-scm.com/docs/git-push> — publishing the head branch that a pull
  request proposes to merge.
- <https://git-scm.com/docs/git-fetch> — refreshing remote-tracking branches
  after a host-side merge.
- <https://git-scm.com/docs/git-pull> — fetch-plus-integrate on a local branch
  (not a pull request).

## Provenance

Authored 2026-08-01 against the official GitHub Docs, GitHub CLI manual, and
Git documentation cited above, retrieved via Context7 (`/websites/git-scm`) and
cross-checked directly against the linked pages. Module-level provenance policy
and source registry live in `../provenance.md` and `../source-registry.md`.
