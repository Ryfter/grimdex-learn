---
title: Creating and cloning repositories
module_id: git-and-github
capabilities:
  - creating-and-cloning-repositories
context7_library: /websites/git-scm
context7_queries:
  - git init empty repository .git directory safe reinitialize existing
  - git clone full copy history branches origin remote default checkout
  - git remote add origin push local repository to remote host
  - gitignore untracked files patterns already tracked not affected
  - git init existing codebase then add commit remote push workflow
official_sources:
  - https://git-scm.com/docs/git-init
  - https://git-scm.com/docs/git-clone
  - https://git-scm.com/docs/gitignore
  - https://git-scm.com/docs/git-remote
  - https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-new-repository
  - https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository
  - https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/adding-locally-hosted-code-to-github
  - https://docs.github.com/en/get-started/git-basics/about-remote-repositories
  - https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/about-forks
  - https://docs.github.com/en/get-started/git-basics/ignoring-files
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

Creating a repository means giving a project directory a Git history store so
changes can be recorded as commits. Cloning a repository means making a full
local copy of an existing repository — working-tree files, commit history, and
branches — and wiring that copy to the source as a remote so later fetches and
pushes know where to go. A repository can start empty on a host and be cloned
down, or it can start on a local machine and be linked to a host afterward;
both paths end with the same model: one local repository plus one or more
named remotes.

## When it is useful

Reach for this capability at the start of any project that should be versioned
with Git: a brand-new local directory that has never been a repository, an
existing folder of files that should become one, or an existing remote project
that should live as a full copy on a local machine. It is also the capability
used when connecting a local repository to a host so collaborators can fetch
and push. Cloning is always per repository: each `git clone` produces one local
repository from one remote URL.

## Prerequisites

- Git is installed and available on the command line.
- For `git init`, a project directory already exists (or will be created by
  the command when a directory argument is given).
- For `git clone`, a repository URL is available (HTTPS, SSH, or another
  transport Git accepts), and the destination directory does not already
  contain a non-empty clone target.
- For connecting a local repository to a host and pushing, the host has an
  empty or intended remote repository ready, and authentication to that host
  is configured.

## Current syntax

```
git init
git init -b <branch-name>

git clone <url>
git clone <url> <directory>

git remote add <name> <url>
git remote -v
git push -u origin <branch>

# in a .gitignore file (one pattern per line):
# build/
# *.log
# !important.log
```

- `git init` creates an empty Git repository in the current directory
  (a `.git` directory with the object store, refs, and templates) and sets up
  an initial branch with no commits yet. Running it again in an existing
  repository is safe: it does not overwrite what is already there.
- `git init -b <branch-name>` (equivalently `--initial-branch=`) names the
  initial branch explicitly instead of using the configured default.
- `git clone <url>` creates a new directory, copies the remote repository into
  it (files, history, and remote-tracking branches), creates a remote named
  `origin` pointing at `<url>` by default, and checks out the remote's
  currently active (default) branch into the working tree. An optional second
  argument sets the destination directory name.
- `git remote add <name> <url>` registers a remote so later `git fetch`,
  `git pull`, and `git push` can use `<name>` instead of the full URL.
  After a clone, `origin` is already set; after a local `git init`, this
  command is how the remote is attached.
- `git remote -v` lists configured remotes and their URLs.
- `git push -u origin <branch>` publishes the local branch to the remote
  named `origin` and sets upstream tracking so later plain `git push` /
  `git pull` know the default remote branch.
- A `.gitignore` file lists patterns for intentionally untracked paths Git
  should ignore. Patterns control untracked noise; they do **not** untrack
  files that are already tracked.

Vocabulary note: a **fork** on a forge such as GitHub is a separate host-side
repository copied from another repository, with its own settings and
permissions, still connected to the upstream. Forking is a forge feature.
`git clone` is a Git operation that copies one repository (upstream or fork)
onto a local machine. Cloning is not forking, and a fork is not created by
`git clone`.

## What happens (local and remote)

Locally, `git init` only creates the repository machinery under `.git`. It
does not stage files, create commits, or talk to a network. Existing project
files stay untracked until they are added and committed. Running `git init`
inside a directory that already has a repository is safe and does not destroy
existing history or configuration.

`git clone` is the opposite starting point: it creates a new local repository
that already has history. Git creates remote-tracking branches for the
branches present on the remote (under `refs/remotes/origin/` by default),
initializes `remote.origin.url` and `remote.origin.fetch`, and checks out an
initial local branch forked from the remote's currently active branch. After
the clone, a plain `git fetch` updates remote-tracking branches; a plain
`git pull` fetches and merges into the current branch. None of that is the
same as opening a pull request on a forge — a pull request is a host-side
review mechanism, not the `git pull` command.

Remotely, nothing is created by `git init` alone. To publish a local-first
repository, a remote must exist on a host and be registered with
`git remote add`, after which `git push` sends local commits to that remote.
To start host-first, create the empty (or seeded) repository on the host,
then `git clone` its URL. Both flows leave a local repository with an
`origin` remote; they differ only in which side held the first history.

A `.gitignore` file (usually committed at the root of the working tree)
affects only untracked paths. Files already recorded in the index and history
keep being tracked even if a later pattern would match them; stopping
tracking requires a separate untrack step (for example `git rm --cached`),
then adding a pattern so the path stays untracked going forward.

## Practical example

Two common starts for a small project directory named `notes-app`.

**Host first, then clone** (repository already exists on the host):

```
$ git clone https://example.com/you/notes-app.git
$ cd notes-app
$ git remote -v
```

The working tree has the default branch checked out, full history is local,
and `origin` already points at the host URL.

**Local first, then add a remote and push** (project already has files on
disk; create an empty repository on the host first, without seeding README
or license files if the local history should be the first push):

```
$ cd notes-app
$ git init -b main
$ printf "build/\n*.log\n" > .gitignore
$ git add .
$ git commit -m "Add initial notes-app files"
$ git remote add origin https://example.com/you/notes-app.git
$ git push -u origin main
```

After the push, the host and the local repository share the same history tip
for `main`, and later clones of that URL receive the same full copy.

## Explanation guidance

### Essential

A repository is the combination of a working tree and the `.git` store that
holds objects and refs. `git init` builds that store in place and leaves the
working tree alone; `git clone` builds a new working tree and store by
copying an existing repository over the network (or from another path). After
a clone, `origin` is the default remote name for the source; after a local
init, the remote is added explicitly with `git remote add`. Starting on the
host and cloning, or starting locally and pushing, are two routes to the same
shape. `.gitignore` keeps untracked noise out of status and commits; it does
not change files that are already tracked. Forks are a forge-level copy of a
repository; `git clone` is how any one repository URL becomes a local copy.

### Experienced-user note

`git clone` creates remote-tracking branches for each branch on the remote
and checks out the branch the remote `HEAD` points at unless `-b` /
`--branch` is given. The default remote name is `origin` and can be changed
with `-o` / `--origin` or `clone.defaultRemoteName`. Cloning into an
existing path is only allowed when that directory is empty. Re-running
`git init` is the documented way to pick up newly added templates without
destroying an existing repository. When pushing a brand-new local history to
a host that already has a README or other initial commit, histories diverge
and a non-fast-forward push fails; for a clean first push, create the remote
empty or pull and reconcile first.

### Optional deeper context

Under the hood, `git init` populates `$GIT_DIR` (usually `.git`) with
`objects`, `refs/heads`, `refs/tags`, and template content such as sample
hooks and exclude patterns. `git clone` initializes a repository, configures
the remote, fetches objects and refs, and performs an initial checkout —
roughly the same stages one would wire by hand with `git init`,
`git remote add`, `git fetch`, and a checkout of the default branch.
Ignore rules are layered: patterns from the command line (where supported),
`.gitignore` files from the path up to the working-tree root,
`$GIT_DIR/info/exclude`, and the file named by `core.excludesFile`, with
later matches at a given precedence level winning. Shared project ignores
belong in a committed `.gitignore`; machine-local ignores belong in
`info/exclude` or the global excludes file.

## Cautions and common failures

- **`git init` does not commit anything.** After init, files are still
  untracked until `git add` and `git commit`. An empty repository on the host
  after only `git init` is expected until the first push of real commits.
- **`.gitignore` does not untrack already-tracked files.** Adding a pattern
  for a path that is already in the index leaves that path tracked. Untrack
  it deliberately (for example with `git rm --cached <path>`), keep the
  working-tree copy if needed, then rely on the ignore pattern so it stays
  untracked.
- **Clone destination must be empty (or unused).** `git clone` creates a new
  directory by default; cloning into an existing non-empty directory fails.
  Choose a free path or pass a new directory name as the second argument.
- **Local-first push against a seeded remote diverges.** If the host
  repository was created with a README, license, or `.gitignore` commit and
  the local repository has a different root commit, a plain first push is not
  a fast-forward. Prefer an empty remote for the first push, or fetch and
  reconcile histories before publishing.
- **Fork ≠ clone.** Creating a fork on a forge makes another host-side
  repository. Cloning copies one repository URL to a local machine. Use fork
  when the collaboration model needs a separate host repository; use clone
  whenever a local working copy is needed, including of a fork.
- **A pull request is not `git pull`.** `git pull` updates the current local
  branch from its remote counterpart. A pull request is a forge workflow for
  proposing and reviewing integration of one branch into another.

## Related capabilities

- Commits and history — recording snapshots after a repository exists.
- Staging and the working tree (`git add`, `git status`) — selecting what
  enters the first and later commits.
- Remotes, fetch, and push beyond the first connection — ongoing
  synchronization after init or clone.
- Branching and pull requests on a forge — collaboration after a repository
  is shared; distinct from `git pull`.

## Official sources

- <https://git-scm.com/docs/git-init> — `git init`, empty repository layout,
  and safe reinitialization in an existing repository.
- <https://git-scm.com/docs/git-clone> — `git clone`, full copy behavior,
  default `origin` remote, and checkout of the remote's active branch.
- <https://git-scm.com/docs/gitignore> — `.gitignore` purpose, pattern
  format, and the rule that already-tracked files are not affected.
- <https://git-scm.com/docs/git-remote> — `git remote add` and managing named
  remotes.
- <https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-new-repository>
  — creating a repository on GitHub (one forge's host-side create flow).
- <https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository>
  — cloning a GitHub repository as a full local copy.
- <https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/adding-locally-hosted-code-to-github>
  — local `git init`, then `git remote add origin` and push.
- <https://docs.github.com/en/get-started/git-basics/about-remote-repositories>
  — remote URLs and the default remote name `origin`.
- <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/about-forks>
  — forks as separate forge repositories connected to an upstream.
- <https://docs.github.com/en/get-started/git-basics/ignoring-files>
  — repository `.gitignore`, untracking with `git rm --cached`, and local
  exclude options.

## Provenance

Authored 2026-08-01 against the official Git and GitHub documentation cited
above, retrieved via Context7 (`/websites/git-scm`) and cross-checked
directly against the linked pages. This page follows the golden capability
page structure for the `git-and-github` module; the module-level provenance
policy and source registry live in `../provenance.md` and
`../source-registry.md`.
