---
title: Glossary
module_id: git-and-github
capabilities:
  - glossary
context7_library: /websites/git-scm
context7_queries:
  - gitglossary repository branch HEAD working tree index commit origin upstream
  - git fetch pull push merge rebase fast-forward remote-tracking branch
  - git reflog detached HEAD tag gitignore ignore untracked patterns
  - GitHub pull request base head compare branch fork remote glossary
  - pull request not git pull merge request forge vocabulary mapping
official_sources:
  - https://git-scm.com/docs/gitglossary
  - https://git-scm.com/docs/git-clone
  - https://git-scm.com/docs/git-fetch
  - https://git-scm.com/docs/git-pull
  - https://git-scm.com/docs/git-push
  - https://git-scm.com/docs/git-merge
  - https://git-scm.com/docs/git-rebase
  - https://git-scm.com/docs/git-reflog
  - https://git-scm.com/docs/gitignore
  - https://docs.github.com/en/get-started/learning-about-github/github-glossary
  - https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests
  - https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/about-forks
  - https://docs.github.com/en/get-started/git-basics/about-remote-repositories
  - https://cli.github.com/manual/gh_pr
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

This capability is the shared vocabulary for the module: short, official-aligned
definitions of the Git terms every later page assumes, plus the forge-dialect
names for the same collaboration ideas. Git is the tool that records history and
moves objects; GitHub is one hosting and review dialect built on Git. The goal is
not a second encyclopedia, but a single place to look up what a word means when
docs, UIs, and teammates use it.

## When it is useful

Reach for this page whenever a term is unfamiliar, overloaded, or used as if two
different tools meant the same thing — especially when mapping host UI language
to plain Git, or reading material written for another forge. It is useful at the
start of the module, and again any time a later capability introduces a word that
needs a one-glance definition without reopening that whole page.

## Prerequisites

- No repository state is required; this page defines words rather than changing
  a project.
- Basic awareness that Git runs locally and hosts such as GitHub add
  collaboration features on top of remotes is enough context (see Git and
  GitHub).
- Optional: a local clone nearby so examples can be matched to real branch and
  remote names, but none of the definitions depend on a particular project.

## Current syntax

This page has no command syntax of its own. The table below is the capability:
each term is defined in one or two complete sentences aligned with official
docs and with the rest of this module.

| Term | Definition |
| --- | --- |
| **repository** | A collection of refs together with an object database of all objects reachable from those refs — the project’s stored history, often accompanied by a working tree. On a host, “repository” also names the hosted project folder that holds files and revision history. |
| **clone** | A full local copy of a repository (working-tree files, history, and branches), or the act of making that copy with `git clone`. After a clone, the source is usually registered as the remote named `origin`. |
| **fork** | A forge feature: a separate host-side repository that starts as a copy of another repository (the upstream), with its own settings and permissions, still connected to that upstream. Forking is not `git clone`; clone is how any one repository URL becomes a local copy, including a copy of a fork. |
| **branch** | A line of development whose tip is a named ref (a movable pointer) to a commit. Creating a branch does not copy the whole project; it records a new name for a tip commit. |
| **remote** | A named shortname for another repository URL that this repository talks to for fetch and push (and, in host docs, the hosted copy itself). Remotes are configuration, not live mirrors of every remote change until you fetch. |
| **origin** | The conventional default remote name. `git clone` usually creates a remote named `origin` pointing at the URL that was cloned; most projects use that name for their primary remote. |
| **upstream (tracking)** | The default remote branch associated with a local branch (`branch.<name>.remote` and `branch.<name>.merge`). When set, bare `git push` / `git pull` and status “ahead/behind” use that pair; people also say the local branch is tracking that remote-tracking branch. |
| **upstream (canonical remote)** | In fork and multi-remote workflows, the conventional shortname for the original or shared project remote (often registered as `upstream` beside a personal `origin` that points at your fork). GitHub docs use “upstream” for the original repository a fork was copied from. |
| **working tree** | The tree of checked-out files on disk — normally the contents of the `HEAD` commit’s tree plus any local edits not yet committed. |
| **staging area / index** | The prepared snapshot for the next commit: a stored version of selected paths that `git commit` will record. Staging copies content from the working tree into the index; the working-tree file itself is not rewritten by staging. |
| **HEAD** | The current commit reference: normally a symbolic ref to the tip of the current branch, so new commits advance that branch. The working tree is usually derived from the tree `HEAD` names. |
| **commit** | As a noun, a single recorded snapshot in history (with metadata such as author, message, and parent links). As a verb, the action of storing a new snapshot from the index and advancing `HEAD` to it. |
| **fetch** | Download objects and update remote-tracking branches from a remote without changing your current branch tip, index, or working tree by itself. |
| **pull** | Fetch from a remote and then integrate those updates into the current branch (by default merge, or rebase when configured or requested). A pull is a Git command on your machine, not a host review object. |
| **push** | Publish local commits to a remote by updating remote refs and sending objects the remote does not yet have. A non-fast-forward push fails when the remote tip is not an ancestor of your tip. |
| **merge** | As a verb, bring another branch’s history into the current branch. As a noun (unless it was a pure fast-forward), a merge commit with two or more parents that records the join. |
| **rebase** | Replay a series of commits onto a different base tip as new commits (new hashes), then move the branch tip to the result — a history rewrite of the rebased commits. |
| **squash** | Combine multiple commits into one recorded result. Locally, `git merge --squash` prepares a single staged tree without recording a multi-parent merge; on hosts, “squash and merge” is a common pull-request integration method. |
| **pull request / merge request** | A forge collaboration feature that proposes merging one branch into another after description, discussion, and review. On GitHub the name is **pull request**; on GitLab the usual name is **merge request**. Neither is the Git command `git pull`. |
| **tag** | A ref under `refs/tags/` that marks a particular object (typically a commit) and is not moved by ordinary commits the way a branch tip is. Tags commonly name releases or other fixed points in history. |
| **detached HEAD** | A state in which `HEAD` points at a commit directly instead of at a branch name. Inspection is fine; new commits are not attached to a branch tip until you create or switch to a branch that names them. |
| **reflog** | A local log of where a ref (including `HEAD` and branch tips) pointed over time in this repository. It is the usual recovery map after tip moves or rewrites, while entries remain. |
| **.gitignore** | A file of patterns naming intentionally untracked paths Git should ignore in status and when adding files. Patterns do not untrack paths that are already tracked. |
| **conflict** | Git’s signal that two sides changed the same region since a common ancestor, so automatic merge or rebase cannot choose a single result. Conflicted paths stay unmerged until a person resolves them and continues (or aborts) the operation. |
| **fast-forward** | A merge case where the branch being merged in is a descendant of the current tip: Git only moves the branch pointer forward and does not create a new merge commit. |
| **default branch** | The repository’s primary line of development by convention and host configuration (often `main`). On GitHub it is the branch shown by default, checked out on clone, and the usual base for new pull requests. |

### Cross-tool vocabulary (same idea, different names)

| Idea | GitHub dialect | Other forge dialect (example: GitLab) | Git / transferable core |
| --- | --- | --- | --- |
| Propose integrating one branch into another after review | Pull request | Merge request | Branch tips and commits still move with clone, fetch, push, and merge or rebase |
| Branch that receives the change when the proposal merges | Base branch | Target branch | The integration tip on the shared history |
| Branch that carries the proposed commits | Head branch (also compare branch) | Source branch | The topic tip being proposed |

Hold the naming trap firmly: **pull request ≠ `git pull`**. Opening or merging a
pull request on a host does not run `git pull` on anyone’s laptop; after a host
merge, local clones learn the result only when someone fetches or pulls.

## What happens (local and remote)

Learning a definition does not change a repository. Using the right word chooses
the right tool: local Git for commit, branch, fetch, pull, and push; the forge UI
or host CLI for fork and pull request. Locally, working tree, index, `HEAD`,
branch tips, and the object database are the places those Git words refer to.
Remotely, named remotes and remote-tracking branches store where other copies
live and what you last knew about them after fetch. Host features (fork, pull
request, default branch settings) sit on top of that model; they do not replace
clone, fetch, or push.

## Practical example

Suppose a GitLab-oriented sentence reads:

> Open a merge request from your source branch into the target branch of the
> upstream project.

Map it into the vocabulary this module uses with GitHub as the example forge:

> Open a **pull request** from your **head** (compare) branch into the **base**
> branch of the **upstream** repository.

The Git steps that feed that proposal are the same on any forge: create commits
on a topic branch, push that branch to a remote you can write to, then open the
host’s review object. After the host merges, update a local default branch with
fetch or pull — that local update is `git pull` (or fetch plus merge), not “the
pull request” itself.

```
# After a host-side merge into main, refresh a local clone:
$ git switch main
$ git pull
```

## Explanation guidance

### Essential

Treat this page as a dictionary, not a substitute for the capability pages that
teach each operation. Git terms (commit, branch, fetch, merge) name what the
tool does locally and over the network. Forge terms (fork, pull request) name
host workflows built on remotes and branches. When two products use different
words for the same idea, translate once (PR ↔ MR, base ↔ target, head ↔ source)
and keep the same mental model. Never collapse “pull request” into “pull.”

### Experienced-user note

Several everyday words are overloaded on purpose. **Upstream** means tracking
configuration for a local branch *and*, in multi-remote and fork talk, the
canonical remote shortname. **Origin** is only a convention, not a special
object type. **HEAD** is a ref, not “the latest commit on every branch.”
**Merge** and **pull request merge** share the idea of integration but differ in
where the decision and the resulting tip update happen (local branch tip versus
host base branch). Prefer precise terms when teaching or writing docs so
listeners do not apply a host UI step to a local-only situation or the reverse.

### Optional deeper context

Official Git vocabulary is collected in `gitglossary`; host glossaries add product
names on top of the same core. Internally, commits form a DAG of snapshots,
branches and tags are refs into that graph, remotes configure transport, and the
index is the staged tree for the next commit object. Detached `HEAD` and the
reflog matter because history tools move refs without always keeping a permanent
branch name for every intermediate tip. Cross-forge portability comes from
learning those Git objects first, then treating each host’s labels as a thin
dialect layer.

## Cautions and common failures

- **Pull request is not `git pull`.** A pull request (or merge request) is a host
  review-and-merge proposal. `git pull` fetches and integrates into your current
  local branch.
- **Fork is not clone.** A fork is another repository on the host. A clone is a
  local copy of one repository URL (upstream or fork).
- **Origin is a name, not a law.** `origin` is the usual default remote shortname
  after clone; other remotes (including a remote named `upstream`) are ordinary
  configuration.
- **Two meanings of upstream.** Branch upstream/tracking config and “the
  upstream remote/repository” in fork workflows are related ideas but different
  settings; say which one you mean.
- **Ignore files do not untrack.** Adding a path to `.gitignore` does not remove
  it from the index if it is already tracked.
- **Detached `HEAD` loses easy branch advancement.** Commits made while detached
  are easy to misplace unless you create a branch (or recover via reflog) before
  switching away.
- **Forge labels vary; Git objects do not.** Searching only for “pull request” on
  a GitLab-centered project will miss merge-request docs that describe the same
  propose-review-merge flow.

## Related capabilities

- Git and GitHub — the tool-versus-forge map this vocabulary sits on.
- Creating and cloning repositories — repository, clone, origin, `.gitignore`,
  and fork versus clone.
- Working tree, staging, and status — working tree, index/staging area, and
  `HEAD` in daily use.
- Commits and history — commit as snapshot and how history is read back.
- Branches and switching — branch tips, default branch, and detached `HEAD`.
- Remotes, fetch, and pull — remote, origin, fetch, pull, and remote-tracking
  branches.
- Push and upstream branches — push and branch upstream/tracking configuration.
- Pull requests and review — pull request versus `git pull`, base/head naming,
  and review flow.
- Merge, commit, squash, and rebase — merge, squash, rebase, and fast-forward
  outcomes.
- Merge conflicts — what a conflict is and how resolution continues or aborts.
- Undoing and recovering work — reflog as the local recovery map after tip moves.

## Official sources

- <https://git-scm.com/docs/gitglossary> — official Git definitions for
  repository, branch, `HEAD`, detached `HEAD`, working tree, index, commit,
  origin, upstream branch, fetch, pull, push, merge, rebase, fast-forward,
  remote-tracking branch, tag, and reflog.
- <https://git-scm.com/docs/git-clone> — clone creates a local repository and
  default remote.
- <https://git-scm.com/docs/git-fetch> — fetch updates remote-tracking branches
  without integrating into the current branch by itself.
- <https://git-scm.com/docs/git-pull> — pull as fetch plus integrate (not a pull
  request).
- <https://git-scm.com/docs/git-push> — push updates remote refs and sends
  missing objects.
- <https://git-scm.com/docs/git-merge> — merge, fast-forward, and merge commits.
- <https://git-scm.com/docs/git-rebase> — rebase as replaying commits onto a new
  base.
- <https://git-scm.com/docs/git-reflog> — reflog as local history of ref tips.
- <https://git-scm.com/docs/gitignore> — ignore patterns for untracked paths.
- <https://docs.github.com/en/get-started/learning-about-github/github-glossary>
  — GitHub glossary entries for clone, fork, origin, upstream, pull request,
  base branch, head/compare branch, default branch, remote, and related terms.
- <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests>
  — what a pull request is on GitHub.
- <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/about-forks>
  — fork as a host-side copy connected to an upstream repository.
- <https://docs.github.com/en/get-started/git-basics/about-remote-repositories>
  — remote repositories on a host and relation to local clones.
- <https://cli.github.com/manual/gh_pr> — GitHub CLI surface for pull requests
  (host dialect, not `git pull`).

## Provenance

Authored 2026-08-01 against the official Git documentation and GitHub Docs
cited above, retrieved via Context7 (`/websites/git-scm`) and cross-checked
directly against the linked pages. Definitions are kept consistent with sibling
capability pages in this module. Module-level provenance policy and source
registry live in `../provenance.md` and `../source-registry.md`.
