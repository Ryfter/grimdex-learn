---
title: Line endings and .gitattributes
module_id: git-and-github
capabilities:
  - line-endings-gitattributes
context7_library: /websites/git-scm
context7_queries:
  - How do I stop git from showing whole-file diffs when only line endings changed?
  - What does text=auto do in a .gitattributes file?
  - What is the difference between eol=lf and eol=crlf?
  - How does core.autocrlf affect line endings on checkin and checkout?
official_sources:
  - https://git-scm.com/docs/gitattributes
  - https://git-scm.com/docs/config
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

Text files use invisible end-of-line characters, and different operating systems use different ones: Windows uses CRLF (two characters), while Mac and Linux use LF (one character). Git can convert between these formats automatically. A `.gitattributes` file, placed at the repository root, declares per-path attributes such as `text=auto` (normalize line endings on checkin) or explicit `eol=lf` / `eol=crlf` (force a specific ending on checkout). The related per-clone setting `core.autocrlf` is a git config option that does similar conversion, but only for that one clone. A `.gitattributes` file travels with the repository and applies to every contributor; `core.autocrlf` is set individually on each machine.

## When it is useful

Whenever a repository is shared between Windows (CRLF) and Mac/Linux (LF) contributors. Without line-ending configuration, a teammate's editor or OS can rewrite every line ending in a file, and Git records the file as fully changed. The telltale symptom is a diff that shows the entire file as modified when, visually, nothing but line endings changed. Declaring `.gitattributes` in the repo fixes this at the source, so the behavior is the same for everyone instead of depending on each person's local config.

## Prerequisites

- Git installed locally and a working knowledge of committing and pushing.
- No special permissions needed to add a `.gitattributes` file beyond normal write access to the repository.

## Current syntax

`.gitattributes` lives at the repository root. Each line maps a path pattern to attributes:

```
* text=auto
*.sh eol=lf
*.bat eol=crlf
```

- `text=auto` tells Git to treat matching files as text and normalize line endings on checkin.
- `eol=lf` or `eol=crlf` forces a specific line ending on checkout for matching paths.
- Explicit `eol` settings override the more general `text=auto` for those paths.

The companion config setting, set per clone:

```
git config core.autocrlf true
```

## What happens (local and remote)

Git applies line-ending conversion at the edges between the repository and your working copy. On checkin (commit), text may be normalized; on checkout, `eol` attributes or `core.autocrlf` determine what your editor sees. Nothing is sent to the remote until you commit and push as usual. Once `.gitattributes` is committed, every contributor's clone picks it up automatically -- no per-person setup required.

## Practical example

A team has Windows and Mac developers editing the same repository. After a Mac developer commits, a Windows developer's pull request shows every file as changed, though no content changed -- only CRLF endings were rewritten. The team adds a `.gitattributes` file at the repo root:

```
* text=auto
*.bat eol=crlf
*.sh  eol=lf
```

They commit and push this file. From then on, text files are normalized on checkin, line-ending-only churn stops appearing in diffs, and files that genuinely need a specific format (shell scripts, batch files) get it consistently.

## Explanation guidance

### Essential

- Line endings are invisible characters at the end of each line; Windows and Mac/Linux disagree on which to use.
- A `.gitattributes` file at the repo root sets conversion rules for the whole repository, so all contributors get the same behavior.
- The symptom this solves: a diff marking an entire file as changed when only line endings changed.
- `text=auto` is the common baseline setting; `eol=lf`/`eol=crlf` force specific endings where needed.

### Experienced-user note

- `core.autocrlf` is the per-clone config alternative, but it only helps the person who sets it. `.gitattributes` is the team-wide solution because it is committed with the repo.
- Explicit `eol` attributes in `.gitattributes` take precedence over `core.autocrlf` for matching paths, so repo-level rules win over individual machines.

### Optional deeper context

- Binary files should be excluded from text normalization; the `text` attribute's per-path patterns let you scope rules to file types.
- Repositories created before a `.gitattributes` file was added may still contain inconsistent endings already committed; the attribute file fixes future checkins, but existing history is unchanged.

## Cautions and common failures

- Adding `.gitattributes` after the fact does not retroactively change already-committed files; it governs future checkins and checkouts.
- If a whole-file diff appears and the cause is unclear, remember that line endings are invisible in most editors -- the diff itself is often the only visible clue.
- Setting `eol=crlf` on files that actually need LF (such as shell scripts) can break them on Mac/Linux; choose explicit rules deliberately.

## Related capabilities

- gitignore-essentials -- the other common per-repo configuration file pattern.
- partial-staging -- relevant when line-ending noise and real edits land in the same working copy.
- in-browser-commits -- small web edits also produce commits subject to the same line-ending rules.

## Official sources

- https://git-scm.com/docs/gitattributes -- official git documentation for `.gitattributes`, including `text`, `eol`, and per-path attributes.
- https://git-scm.com/docs/config -- official git documentation covering configuration variables, including `core.autocrlf`.

## Provenance

This page was authored against the cited official docs (git-scm.com's gitattributes and config pages), retrieved via Context7. Spot-check against current docs before shipping, since documentation paths reorganize periodically.