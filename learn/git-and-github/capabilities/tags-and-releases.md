---
title: Tags and GitHub Releases
module_id: git-and-github
capabilities:
  - tags-and-releases
context7_library: /websites/git-scm
context7_queries:
  - How do I tag a specific commit in git?
  - What is the difference between a git tag and a branch?
  - How do GitHub Releases relate to git tags?
official_sources:
  - https://git-scm.com/docs/git-tag
  - https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases
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

`git tag <name>` marks a specific commit with a fixed, human-readable label such as `v1.2.0`. Unlike a branch, a tag does not move: it always points to the exact commit it was created for. A GitHub Release wraps a tag with release notes and optional downloadable build assets, presented in the repository's Releases area of the GitHub UI.

## When it is useful

- Marking a version that was shipped or released, so anyone can find that exact state of the code later.
- Comparing what changed between two versions, since tags give stable reference points.
- Publishing a GitHub Release so users and stakeholders can download a specific build and read its notes without knowing how to use git.

## Prerequisites

- A local git repository (for tagging) or a repository hosted on GitHub (for Releases).
- Commits that exist locally; a tag must be created on something.
- For Releases, push access to the repository or permission to create a release in the GitHub UI.

## Current syntax

```
git tag v1.2.0
```

This creates a tag named `v1.2.0` at the current commit. Common related operations:

- `git tag` — list existing tags.
- Pushing tags to the remote so they appear on GitHub (tag pushing is standard git behavior; use `git push` with the tag to publish it).

## What happens (local and remote)

Locally, the tag is a permanent label pointing at one commit. It stays there as new commits are added — this is the key difference from a branch, which moves to the latest commit as work continues. Remotely, a tag only appears on GitHub once it has been pushed. Once pushed, a GitHub Release can be created for that tag in the GitHub UI, adding release notes and optional downloadable build assets.

## Practical example

A team finishes version 1.2.0:

1. Create the tag on the current commit: `git tag v1.2.0`.
2. Push the tag so it exists on GitHub.
3. In the GitHub repository, create a Release from the `v1.2.0` tag, add release notes describing what changed, and attach a downloadable build asset if applicable.

Months later, anyone can look at the `v1.2.0` tag or Release to see exactly what code shipped and download that build.

## Explanation guidance

### Essential

A branch is a movable pointer; a tag is a fixed label. Branches advance as new commits land; tags never do. A GitHub Release is the public-facing wrapper around a tag: notes plus optional files, viewable and downloadable in the browser.

### Experienced-user note

Tags and branches can coexist on the same commit, and a tag placed at the last commit of a release branch lets the branch keep advancing (e.g. for patches or the next release) while the tagged point remains frozen. Tags must be pushed to the remote separately from commits to be visible on GitHub.

### Optional deeper context

Tag conventions such as `v1.2.0` align with semantic versioning practices and make automated tooling that reads versions easier to configure. Releases are also commonly used as the distribution point where users grab prebuilt binaries, avoiding a build step.

## Cautions and common failures

- Tags that were never pushed do not exist on GitHub; Releases cannot be created for tags the remote does not have.
- Deleting a tag locally does not remove it from the remote, and vice versa; cleanup requires acting on both.
- Tag names with spaces or unusual characters are awkward; stick to simple, standard names.
- A tag on a commit that is not reachable from any pushed branch still exists locally but may not be visible remotely until the tag itself is pushed.

## Related capabilities

- branch-protection-rulesets
- repository-access-roles

## Official sources

- https://git-scm.com/docs/git-tag — official git documentation for `git tag`.
- https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases — official GitHub documentation about Releases.

## Provenance

This page was authored against the official `git-tag` documentation on git-scm.com and the "About releases" page on docs.github.com, retrieved via Context7. It should be spot-checked against current docs before shipping, since GitHub's documentation paths reorganize periodically.