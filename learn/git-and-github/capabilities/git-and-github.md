---
title: Git and GitHub
module_id: git-and-github
capabilities:
  - git-and-github
context7_library: /websites/git-scm
context7_queries:
  - git distributed version control system free open source command line tool
  - git repository init clone local history self-contained
  - git remote origin hosting services GitLab GitHub ecosystem
  - GitHub hosts Git repositories platform collaboration pull requests
  - git pull fetch update local branch not the same as pull request
official_sources:
  - https://git-scm.com/
  - https://git-scm.com/about
  - https://git-scm.com/docs/git
  - https://git-scm.com/docs/git-init
  - https://git-scm.com/docs/git-clone
  - https://git-scm.com/docs/git-remote
  - https://docs.github.com/en/get-started/using-git/about-git
  - https://docs.github.com/en/get-started/start-your-journey/what-is-github
  - https://docs.github.com/en/repositories/creating-and-managing-repositories/about-repositories
  - https://docs.github.com/en/get-started/git-basics/about-remote-repositories
  - https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests
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

Git is a free and open source **distributed version control tool**: software you run
locally that records the history of a project as a chain of snapshots (commits), so
any earlier version can be recovered and multiple lines of work can develop in
parallel. GitHub is a **hosting and collaboration platform built around Git**. It
hosts Git repositories in the cloud and adds planning and collaboration features —
issues, code review, and pull requests — on top of the underlying Git model. Git is
not GitHub, and GitHub is not Git. The same Git tool works with any host that speaks
Git; GitHub is one widely used forge dialect among several.

A **repository** (often shortened to "repo") is the full collection of a project's
files and folders together with each file's revision history. Because Git is
distributed, every clone of a repository is a self-contained unit: anyone who has a
copy can access the entire codebase and its history without a constant connection to
a central server. A repository can live only on your machine (local), only on a host
(remote), or — in the usual workflow — as a local copy linked to one or more remotes.

## When it is useful

Reach for this capability first whenever you need the map of the territory: what Git
is for, how a host such as GitHub relates to it, and which later pages cover setup,
history, collaboration, and recovery. It is the right starting point before
initializing or cloning a project, before choosing a host, and any time the words
"Git" and "GitHub" are being used as if they meant the same thing. It is also the
place to orient yourself when another tool or forge (GitLab, Bitbucket, Codeberg, or
similar) appears in documentation: the transferable idea is Git; the host is a
dialect of collaboration on top of it.

## Prerequisites

- Git is installed on the machine you are using, or you are ready to install it
  (see the setup and configuration page, and the official install guidance for your
  platform at git-scm.com).
- Optional but useful for the remote side of the picture: an account on a Git
  hosting service (GitHub or another forge) if you intend to create or clone a
  hosted repository.
- No existing project is required to understand the concepts on this page; the
  practical example below starts from an empty directory.

## Current syntax

```
git --version
git init
git init <directory>
git clone <url>
git clone <url> <directory>
git remote
git remote -v
git remote add <name> <url>
git status
```

- `git --version` prints the installed Git version; use it to confirm the tool is
  available before anything else.
- `git init` (optionally with a directory name) creates a new local Git repository
  in the current or named directory by adding the hidden data structure Git needs
  for version control.
- `git clone <url>` creates a local copy of a repository that already exists at a
  remote URL, including its files, history, and branches.
- `git remote` and `git remote -v` list the named remotes configured for this
  repository; `-v` includes their fetch and push URLs.
- `git remote add <name> <url>` registers a remote so later commands can refer to it
  by name (the conventional first remote name is `origin`).
- `git status` reports the state of the working tree relative to the repository
  (untracked, modified, or staged changes).

These commands are the orientation set only. Staging, committing, branching,
pushing, pulling, pull requests, merging, and recovery each have their own
capability pages.

## What happens (local and remote)

Locally, Git stores project history in a repository on your machine. After
`git init`, that repository starts empty of commits but ready to track files. After
`git clone`, you receive a full copy of the remote project's history. Day-to-day
work — editing files, staging, committing, branching — happens against this local
copy and does not by itself change anything on a host.

A **remote** is Git's name for "the place where another copy of this repository
lives." That place can be a repository on GitHub, another person's fork, or a
completely different server. Git associates each remote URL with a short name;
after a clone, the default remote is usually called `origin`. Publishing commits so
others can see them, and downloading commits others have published, are separate
steps that move data between the local repository and a remote. Hosting platforms
such as GitHub store the remote copy and layer collaboration features (pull
requests, issues, review) on top; those platform features are not part of the Git
tool itself.

Other Git hosting services (forges) — including GitLab, Bitbucket, and Codeberg —
exist for the same role: they host Git repositories and provide collaboration
workflows around them. They all speak Git for clone, fetch, and push; the brand-
specific pieces (web UI, review model, CLI extras) are forge dialects. This module
uses GitHub as its primary dialect for platform examples while keeping Git concepts
transferable.

## Practical example

Create a local repository for a small notes project and inspect what Git created:

```
$ mkdir notes-project
$ cd notes-project
$ git init
$ git status
$ git --version
```

You now have a **local** repository: Git is tracking this directory, but nothing has
been shared with a host. Add a first file and confirm Git sees it as untracked
until you stage and commit (covered on the staging and commits pages):

```
$ echo "Project notes" > README.md
$ git status
```

To connect the same project to a **remote** host later, you would create an empty
repository on the host, then register it and publish:

```
$ git remote add origin https://github.com/<owner>/<repo>.git
$ git remote -v
```

(Substitute any forge's HTTPS or SSH clone URL for the GitHub form above; the
`git remote` commands are the same.) Cloning someone else's project is the reverse
direction: `git clone <url>` creates the local repository and usually sets `origin`
for you.

## Explanation guidance

### Essential

Hold this separation firmly: **Git is the tool; GitHub is one platform that hosts
Git repositories and adds collaboration features.** A repository is the project
plus its history. Local work is complete and useful on its own; a remote is an
optional named location for another copy of that history, often used for backup and
collaboration. When documentation or teammates say "push it to Git" they almost
always mean "use Git to publish commits to a remote host" — the host may be GitHub
or another forge. A **pull request** is a platform feature for proposing and
discussing a set of changes before they are integrated; it is not the same thing as
the Git command `git pull`, which updates a local branch from its remote
counterpart.

### Experienced-user note

Once the Git-versus-host split is clear, the rest of this module is a map of
capabilities that all rest on the same object model: working tree, staging area
(index), commits, branches, and remotes. Setup and cloning get a repository onto a
machine; staging and commits record history; branches isolate lines of work;
remotes, push, and pull move history between machines; pull requests (GitHub's
review dialect), merging, and conflict resolution integrate concurrent work;
cleanup and recovery handle the mistakes and rewrites that history tools make
possible. Prefer learning the transferable Git concept first, then the forge-
specific UI or CLI for the same idea.

### Optional deeper context

Git is a distributed version control system (DVCS): every developer who clones a
project receives a full copy of the project and its history, so collaboration does
not require a permanent connection to a single central server. Hosts such as GitHub
still play a practical "shared hub" role for teams, but that hub is a convenient
remote, not a requirement of the Git data model. Forge features — pull requests on
GitHub, merge requests on other platforms, issues, checks — sit above Git's
transfer and storage primitives. Treating them as layers (tool, then remote, then
platform workflow) keeps skills portable when a project moves host or when a team
uses more than one forge.

## Cautions and common failures

- **Treating "Git" and "GitHub" as synonyms.** Installing Git does not create a
  GitHub account, and creating a GitHub repository does not by itself put Git on
  your machine. Local history and hosted collaboration are related but separate
  steps.
- **Confusing a pull request with `git pull`.** A pull request (sometimes called a
  merge request on other forges) is a request on the hosting platform to review and
  integrate changes. `git pull` is a local Git command that fetches from a remote
  and updates the current branch. Using one phrase for the other causes the wrong
  tool to be opened and the wrong expectation about what will change.
- **Assuming the only remote is GitHub.** Any URL Git can speak to can be a remote.
  Workflows learned with GitHub's clone URL transfer to other forges; only the host
  UI and product-specific commands change.
- **Expecting `git init` alone to publish anything.** `git init` creates a local
  repository only. Sharing requires a remote, credentials the host accepts, and an
  explicit publish step (covered under remotes and push).
- **Skipping orientation when joining an existing project.** Cloning first
  (`git clone`) is usually simpler than initializing an empty local repo and wiring
  remotes by hand when a hosted project already exists.

## Related capabilities

- Setup — installing Git and configuring identity (user name and email) before the
  first commit.
- Cloning — creating a local copy of an existing remote repository.
- Staging and the working tree — choosing what enters the next commit.
- Commits and history — recording snapshots and reading them back.
- Branches — parallel lines of development within one repository.
- Remotes — naming and managing other copies of the repository.
- Push — publishing local commits to a remote.
- Pull requests — proposing and reviewing changes on a hosting platform (GitHub
  dialect; not `git pull`).
- Merging — combining lines of development.
- Conflicts — resolving overlapping edits during integration.
- Cleanup — discarding or rearranging unneeded local state safely.
- Recovery — finding commits again after mistakes (including reflog where
  applicable).
- Glossary — short definitions of the shared vocabulary used across these pages.

## Official sources

- <https://git-scm.com/> — Git as a free and open source distributed version
  control system.
- <https://git-scm.com/about> — Git as a command-line tool and the ecosystem of
  hosting services (including GitLab and GitHub).
- <https://git-scm.com/docs/git> — Git as a distributed revision control system and
  the high-level command set.
- <https://git-scm.com/docs/git-init> — `git init` and creating a new repository.
- <https://git-scm.com/docs/git-clone> — `git clone` and obtaining a full local copy
  of a remote project.
- <https://git-scm.com/docs/git-remote> — managing named remotes.
- <https://docs.github.com/en/get-started/using-git/about-git> — Git as a DVCS,
  repository definition, how GitHub hosts Git repositories, and basic commands.
- <https://docs.github.com/en/get-started/start-your-journey/what-is-github> —
  GitHub as a platform that builds on Git by hosting repositories and adding
  collaboration tools.
- <https://docs.github.com/en/repositories/creating-and-managing-repositories/about-repositories> —
  repositories on GitHub as code, files, and revision history; clone and remote
  vocabulary.
- <https://docs.github.com/en/get-started/git-basics/about-remote-repositories> —
  remote URLs, `origin`, and publishing local commits to a host.
- <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests> —
  pull requests as a collaboration feature distinct from `git pull`.

## Provenance

Authored 2026-08-01 against the official Git and GitHub documentation cited above,
retrieved via Context7 (`/websites/git-scm`) and cross-checked directly against the
linked pages. This page is the module overview for the `git-and-github` module; the
module-level provenance policy and source registry live in `../provenance.md` and
`../source-registry.md`.
