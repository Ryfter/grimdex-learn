---
title: Commit identity and email privacy
module_id: git-and-github
capabilities:
  - commit-identity-email-privacy
context7_library: /websites/github_en
context7_queries:
  - "How do I set the name and email Git uses for commits?"
  - "How do I keep my personal email out of GitHub commit history?"
  - "What is GitHub's no-reply email address and how do I use it for commits?"
official_sources:
  - https://git-scm.com/docs/git-config
  - https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-email-preferences/setting-your-commit-email-address
last_checked: 2026-09-20
last_material_update: 2026-09-20
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

Every commit Git records carries the name and email address taken from your git configuration: `user.name` and `user.email`. These can be set globally (for all your repositories) or per-repository. The email you put there is written permanently into the commit history and becomes publicly visible wherever the history is published -- including on GitHub.

GitHub addresses this privacy exposure by offering every account a "no-reply" email address (for example, an ID-based address ending in `@users.noreply.github.com`). You can find it in your account's email settings and set it as your `user.email`, so commits you push are attributed to you on GitHub without ever publishing a real personal or work address.

## When it is useful

- Any time you push commits to a public repository -- or a repository that might later be made public -- and do not want your personal email harvested from the history.
- When you contribute to open source from a work machine and want to keep employer and personal identities separate.
- When multiple people share a machine and each needs a distinct identity for their commits.
- When you want GitHub to correctly attribute commits to your account (GitHub matches commits to accounts by email address).

## Prerequisites

- Git installed locally.
- A basic understanding of how to run git commands in a terminal.
- For GitHub attribution and the no-reply option: a GitHub account, and access to the email settings page.

## Current syntax

Set identity globally (applies to all repositories for your user):

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Set identity for one repository only (run inside that repository; omit `--global`):

```bash
git config user.name "Your Name"
git config user.email "ID+username@users.noreply.github.com"
```

Check what is currently set:

```bash
git config user.name
git config user.email
```

The no-reply address itself is obtained from GitHub's account email settings page, not from a git command.

## What happens (local and remote)

Locally, git reads `user.name` and `user.email` at the moment you create a commit and stamps them into the commit object. Per-repository settings override global ones. The values are not authenticated in any way -- git simply records whatever you configure.

Remotely, when you push to GitHub, GitHub tries to match the commit's email to a user account. If it matches, the commit shows your avatar and links to your profile. If the email is your no-reply address, the association works the same way, but your real address never appears in the published history.

Note that changing the configuration only affects future commits. Existing commits keep the identity they were created with; rewriting published history to scrub an email is a separate, more invasive operation.

## Practical example

A contributor wants to publish commits to a public repository without exposing their personal address.

1. In GitHub, open account email settings and note the provided no-reply email address.
2. Configure git to use it:

   ```bash
   git config --global user.name "Alex Doe"
   git config --global user.email "1234567+alexdoe@users.noreply.github.com"
   ```

3. Make and push a commit as usual. The commit on GitHub is attributed to Alex Doe's account, and the recorded email is the no-reply address rather than a personal one.
4. If one private work repository should use a different identity, run `git config user.email "alex@company.example"` (without `--global`) inside that repository; it overrides the global value for that repo only.

## Explanation guidance

### Essential

Commits are stamped with the name and email from your git configuration, and that information is public wherever the repository is public. GitHub gives every account a no-reply email address for exactly this purpose: set it as your `user.email` and your real address stays out of the history. Configuration can be global or per-repository, and it only affects commits you make after changing it.

### Experienced-user note

GitHub attributes commits by matching the email address, so if you switch to the no-reply address after already committing with a personal address, older commits will not re-associate with your account unless the history is rewritten. A common setup is a global default of the no-reply address with per-repository overrides for work projects -- and enabling GitHub's setting that blocks web-based commits from being attributed to your real address if it were ever pushed. Also remember identity is unrelated to signing: a commit can carry a no-reply email and still be GPG/SSH-signed for a Verified badge.

### Optional deeper context

The `user.name`/`user.email` values are part of the commit object format itself and were never designed as authentication -- anyone can configure any identity. What gives commits meaning is the combination of attribution (email matching on GitHub), optional cryptographic signatures, and push access controls on the remote. Teams standardizing on no-reply addresses usually pair this with contributor documentation so CI and release tooling that parse author emails are not surprised.

## Cautions and common failures

- **Changing config does not fix past commits.** Already-made commits keep their original identity; only new commits use the new settings.
- **Forgetting per-repo override direction.** Setting a per-repository email and expecting it to apply everywhere (or vice versa) is a frequent mix-up; use `git config user.email` inside a repo to check what actually applies there.
- **Misattributed commits on GitHub.** If the configured email does not match an email on your GitHub account (or your no-reply address), commits appear unattributed, with no avatar or profile link.
- **The email is not secret once committed.** If a real address was already pushed to a public repo, adding a .gitignore-style fix does nothing; the history contains it until rewritten.
- **No-reply format varies.** Use the exact address GitHub's email settings page shows for your account rather than guessing the format.

## Related capabilities

- verified-commit-badge -- signing commits and the Verified badge
- co-authored-commits -- crediting multiple people in one commit's message

## Official sources

- https://git-scm.com/docs/git-config -- official git documentation for configuration variables, including `user.name` and `user.email`.
- https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-email-preferences/setting-your-commit-email-address -- GitHub docs on setting your commit email address, including the no-reply option.

## Provenance

This page was authored against the cited official documentation -- git-scm.com's `git-config` reference and docs.github.com's guide to setting your commit email address -- retrieved via Context7. GitHub's documentation paths reorganize periodically, so spot-check the cited URLs against the current docs before shipping.