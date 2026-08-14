---
title: Setup, configuration, and authentication
module_id: git-and-github
capabilities:
  - setup-configuration-and-authentication
context7_library: /websites/git-scm
context7_queries:
  - git config user.name user.email identity global local system scopes
  - git config --global --system --local configuration files layering override
  - gitcredentials credential.helper HTTPS password personal access token cache store
  - GitHub authentication HTTPS SSH personal access token credential manager
  - gh auth login GitHub CLI authenticate git protocol ssh https
official_sources:
  - https://git-scm.com/docs/git-config
  - https://git-scm.com/book/en/v2/Getting-Started-First-Time-Git-Setup
  - https://git-scm.com/docs/gitcredentials
  - https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-authentication-to-github
  - https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
  - https://docs.github.com/en/get-started/git-basics/caching-your-github-credentials-in-git
  - https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository
  - https://cli.github.com/manual/gh_auth_login
last_checked: 2026-08-01
last_material_update: 2026-08-01
status: current
claim_class: foundational
safety_class: auth
version_stamp: fall-2026-0.1.0
admission:
  course_independent: true
  public_ready: true
  provenance: authored-against-official-docs
---

## What it is

Setup, configuration, and authentication are the steps that make Git usable on a
machine and that prove who you are when talking to a remote host. Configuration is
how Git stores settings such as the name and email address that every commit records
as its author. Authentication is how a host — for example GitHub — accepts or rejects
your connection when you clone, fetch, or push over the network. Git itself is the
local tool; a host such as GitHub is one forge dialect among several. The same identity
and credential ideas apply across hosts, even though each host's login surface differs.

## When it is useful

Reach for this capability before the first commit on a new machine, whenever a
repository needs a different author identity than the machine-wide default, and
whenever a remote operation fails because the host does not yet know who you are.
It also applies whenever you must choose how secrets reach Git (credential helper,
environment, or host-side secret storage) instead of being typed into a file that
could be committed.

## Prerequisites

- Git is installed and available on the command line (`git --version` succeeds).
- For host authentication examples that use GitHub CLI, `gh` is installed and can
  reach the network.
- For per-repository identity overrides, the current directory is inside a Git
  repository (local config lives in that repository's `.git/config`).

## Current syntax

```
git config --global user.name "<name>"
git config --global user.email "<email>"
git config user.name "<name>"
git config user.email "<email>"

git config --list --show-origin
git config --global --list
git config --local --list
git config user.name
git config user.email

git config --global credential.helper <helper>

gh auth login
gh auth status
```

- `git config --global user.name "<name>"` and
  `git config --global user.email "<email>"` write the author identity used for all
  repositories on this user account unless a more specific scope overrides them.
- The same keys without `--global` (or with `--local`) write only into the current
  repository's config, overriding the global values for that repository alone.
- `git config --list --show-origin` lists effective settings and which file each
  value came from; `git config user.name` (or `user.email`) prints the resolved value
  after all scopes are applied.
- `git config --global credential.helper <helper>` tells Git which program to use
  when it needs a username and password (or token) for HTTPS remotes — for example
  a platform credential manager, or the built-in `cache` / `store` helpers.
- `gh auth login` authenticates the GitHub CLI with a GitHub host (default
  `github.com`), optionally configuring the preferred Git protocol (`https` or
  `ssh`) and storing a token in the system credential store when available.
- `gh auth status` reports which host accounts the CLI is currently authenticated
  for and where credentials are stored.

## What happens (local and remote)

Locally, `git config` reads and writes configuration variables. By default, values
are layered from three scopes: **system** (all users and repositories on the machine),
**global** (the current user, all of that user's repositories), and **local** (one
repository). Each more specific scope overrides the less specific one for the same
key, so a local `user.email` wins over a global one. Writing without a scope flag
defaults to local; `--global` writes the user-wide file; `--system` writes the
machine-wide file. The values of `user.name` and `user.email` are copied into each
new commit's author (and committer) metadata when the commit is created — they do
not change commits already in history.

Authentication to a host is separate from local identity. When a remote URL uses
**HTTPS**, Git asks for credentials (on GitHub, a personal access token in place of
a password). A **credential helper** or credential manager can cache or store those
credentials so they are not re-typed every time. When a remote URL uses **SSH**,
Git relies on SSH keys: the private key stays on the local machine, and the matching
public key is registered with the host. Neither path puts secrets into the repository
by itself; secrets only enter the object database if someone stages and commits them
as ordinary files.

On GitHub specifically, the command-line paths are HTTPS (token or credential
manager) and SSH (keys). The GitHub CLI's `gh auth login` is an interactive way to
establish a session with a GitHub host and, when HTTPS is chosen and the user
agrees, to wire Git to use those credentials for Git operations. Personal access
tokens exist as long-lived (or expiring) credentials with **scopes** or fine-grained
permissions that limit what the token may do; a token cannot grant more access than
its owner already has.

None of these setup steps push or pull history by themselves. They prepare local
config and host trust so later clone, fetch, and push commands can succeed.

## Practical example

On a new machine, set a machine-wide author identity, then confirm it:

```
$ git config --global user.name "Ada Example"
$ git config --global user.email "ada@example.com"
$ git config user.name
Ada Example
$ git config --list --show-origin
```

Inside one repository that should use a different email, override only that repo:

```
$ git config user.email "ada-work@example.com"
$ git config user.email
ada-work@example.com
```

Authenticate the GitHub CLI (interactive prompts choose host, protocol, and
browser or token flow):

```
$ gh auth login
$ gh auth status
```

For HTTPS remotes without relying on retyping a token, prefer a credential helper
or manager (platform-specific; Git for Windows commonly ships Git Credential
Manager). For SSH remotes, generate a key pair with the host's documented tool chain
and register only the **public** key with the host — never place a private key or
token into a tracked project file.

## Explanation guidance

### Essential

Treat identity and authentication as two different jobs. Identity (`user.name` and
`user.email`) answers "whose name appears on commits made on this machine (or in
this repository)?" Authentication answers "will the host accept my network
operations?" Set identity once globally, then override per repository only when a
project truly needs a different author line. For talking to a host, pick one remote
URL style and stick to it: **HTTPS** plus a credential helper or token, or **SSH**
plus keys. Prefer helpers, environment variables, and host-side secret storage over
embedding secrets in files. Never commit credentials, tokens, private keys, or other
secrets into a repository — once they are in a commit, they are part of history and
may be copied wherever that history goes.

### Experienced-user note

Config scopes layer as system → global → local (and optionally worktree), with the
most specific winning; `git config --list --show-origin` (and `--show-scope`) is the
fastest way to debug "why is this email wrong?" surprises. On HTTPS, Git's
`credential.helper` mechanism can chain helpers; empty-string reset followed by a
new helper list overrides a lower-priority setting. Personal access tokens are
scoped: classic tokens use broad OAuth-style scopes, while fine-grained tokens use
per-repository permissions — grant the minimum needed. `gh auth login` stores a
token for API and, when configured, Git HTTPS use; environment variables such as
those documented for `gh` suit headless automation without writing tokens into
project trees. Removing a secret that was already committed is not the same as
deleting the file in a new commit: the secret remains in older commits until history
is rewritten, which is an involved, coordination-heavy process covered under recovery
and history-rewriting capabilities.

### Optional deeper context

Internally, Git merges config from fixed file locations (system `gitconfig`, the
user's global config, then `.git/config`), so the same key can appear more than once
in `git config --list`; the last effective value wins. Credential helpers speak a
small stdin/stdout protocol (`get` / `store` / `erase`) keyed by a URL context, which
is why one stored credential can cover many repositories on the same host unless
path-sensitive options are enabled. Host tokens (for example GitHub personal access
tokens) are bearer credentials equivalent in risk to passwords: anyone who obtains
the token string can act within its scopes until it is revoked or expires.

## Cautions and common failures

- **Never commit credentials, tokens, private keys, or other secrets.** Do not put
  them in tracked files, sample configs, or commit messages. Store them in a
  credential helper or OS credential manager, inject them via environment variables
  or a host's secret store (for example Actions secrets), and keep private keys
  outside the project tree with restrictive permissions.
- **If a secret was committed, treat it as compromised immediately.** Revoke or
  rotate the secret first so the leaked value can no longer grant access. Removing
  the string from the latest tree is not enough if older commits still contain it;
  full removal requires rewriting history and coordinating every clone and fork —
  an involved recovery process described in host documentation on removing sensitive
  data, and in this module's history-recovery / rewriting-history capability pages.
  Prefer rotation even when history cleanup is deferred.
- **Wrong scope for identity.** Setting `user.email` only locally in one repo does
  not fix other repos; setting it only globally does not override a lingering local
  value. Use `git config --show-origin` when the author line on new commits looks
  wrong.
- **HTTPS password prompts are not account passwords on hosts that require tokens.**
  On GitHub, Git over HTTPS expects a personal access token (or a manager that
  obtains one), not the account login password.
- **SSH and HTTPS are different auth paths.** An SSH key registered with the host
  does not satisfy an `https://` remote, and a stored HTTPS token does not satisfy
  an `ssh://` or `git@` remote. Match the credential type to the remote URL.
- **Tokens are as sensitive as passwords.** Scope them narrowly, set expirations
  when possible, and revoke tokens that may have leaked. Do not paste tokens into
  chat logs, screenshots, or shared notes.

## Related capabilities

- Commits and history — uses the configured `user.name` / `user.email` on every new
  commit; see that page for what a commit records.
- Staging and the working tree — where accidental secret files are most often added;
  review with `git status` and `git diff --staged` before committing.
- Remotes, clone, fetch, and push — the network operations that require host
  authentication once setup is complete.
- History recovery and rewriting after a leaked secret — the involved follow-on when
  rotation alone is not enough and sensitive data must be purged from history
  (never rewrite shared history without coordination).

## Official sources

- <https://git-scm.com/docs/git-config> — `git config` command, scopes
  (`--system`, `--global`, `--local`), and `user.name` / `user.email`.
- <https://git-scm.com/book/en/v2/Getting-Started-First-Time-Git-Setup> — first-time
  identity setup and the three configuration levels with override rules.
- <https://git-scm.com/docs/gitcredentials> — credential helpers, HTTPS username and
  password (or token) acquisition, and helper configuration.
- <https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-authentication-to-github>
  — GitHub authentication modes, including HTTPS and SSH for command-line Git.
- <https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens>
  — personal access tokens, scopes and fine-grained permissions, and treating tokens
  like passwords.
- <https://docs.github.com/en/get-started/git-basics/caching-your-github-credentials-in-git>
  — credential managers and `gh auth login` for remembering HTTPS credentials.
- <https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository>
  — revoke or rotate secrets first; history rewrite is involved and optional relative
  to rotation.
- <https://cli.github.com/manual/gh_auth_login> — `gh auth login` flags, token
  storage, and Git protocol selection.

## Provenance

Authored 2026-08-01 against the official Git, GitHub, and GitHub CLI documentation
cited above, retrieved via Context7 (`/websites/git-scm`) and cross-checked directly
against the linked pages. This page follows the golden capability page structure for
the `git-and-github` module; the module-level provenance policy and source registry
live in `../provenance.md` and `../source-registry.md`.
