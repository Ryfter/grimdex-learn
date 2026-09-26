---
title: .gitignore essentials
module_id: git-and-github
capabilities:
  - gitignore-essentials
context7_library: /websites/git-scm
context7_queries:
  - Why is my .gitignore rule not ignoring a file that is already tracked?
  - How do I stop tracking a file without deleting it locally?
  - How can I check whether a path is ignored by git?
official_sources:
  - https://git-scm.com/docs/gitignore
  - https://git-scm.com/docs/git-check-ignore
  - https://git-scm.com/docs/gitfaq
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

A `.gitignore` file sits at the top level of a repository (or in subdirectories) and lists patterns for files and directories that Git should leave alone — build artifacts, logs, local configuration, editor scratch files, and so on. When Git decides whether to report a file as "untracked" (not yet committed), it consults these patterns and skips anything that matches.

## When it is useful

- You want build output, dependencies, secrets, or personal editor settings to stay out of the repository.
- A file that was already committed is cluttering the repo and you want it removed from version control but kept on disk.
- A file seems to be "stuck" tracked despite an ignore rule, or an ignored file is unexpectedly showing up, and you need to find out why.

## Prerequisites

- Git installed and a repository to work in (cloning or `git init` is covered elsewhere).
- Basic comfort running commands in a terminal and editing a plain-text file.

## Current syntax

`.gitignore` pattern rules:

- Each line is a pattern; lines starting with `#` are comments.
- A leading `!` negates a pattern, re-including a file that a previous pattern excluded.
- Patterns can match file or directory names and contain simple wildcards (e.g. `*.log`, `build/`).

Related commands:

```
git rm --cached <file>    # untrack a file already in the index (keeps it on disk)
git check-ignore <path>   # report whether a path is ignored
```

## What happens (local and remote)

Adding a pattern to `.gitignore` changes nothing retroactively: the rules apply **only to untracked files**. If a file was committed before the rule existed, Git still tracks it, and every edit to it will show up in `git status` and future commits.

To stop tracking an already-tracked file:

1. Add the matching pattern to `.gitignore`.
2. Run `git rm --cached <file>`. This removes the file from the index (Git's staging area) but leaves the physical file on your disk. The removal is staged as a change; commit it as usual. From the next commit onward, the file is ignored.

`git check-ignore <path>` answers the question "is this path excluded?" — it exits quietly if the path is ignored and reports the path if not (typically non-zero exit when ignored). It is the quickest way to debug pattern rules before relying on them.

## Practical example

A project is accidentally committing a local settings file:

```
echo "config.local" >> .gitignore
git rm --cached config.local
git commit -m "Stop tracking local config"
```

The file remains on disk but no longer appears in `git status` or future commits.

To verify the rule works:

```
git check-ignore config.local
```

If the path is printed, Git is ignoring it. If nothing is printed, the pattern did not match — check spelling, slashes, and directory placement.

## Explanation guidance

### Essential

- Ignore rules affect only files Git has not committed yet; they are not a way to "undo" tracking by themselves.
- `git rm --cached` removes a file from version control without deleting it from your machine; plain `git rm` removes both.
- `git check-ignore` is the built-in tool for testing whether a rule actually catches a given path.

### Experienced-user note

- Because `.gitignore` itself is a file in the repo, it is normally committed so everyone's clone ignores the same things. Personal-only ignores (e.g. editor noise) can be handled by not committing patterns — but note the grounding facts here cover the repo-level `.gitignore` behavior: untracked-only application, negation with `!`, and the `git rm --cached` / `git check-ignore` pair.
- The Git FAQ specifically covers the "file is tracked, why is it not ignored?" confusion — the answer is always: untrack it with `git rm --cached`, then the rule takes effect.

### Optional deeper context

- Patterns can be scoped: a `.gitignore` in a subdirectory applies to that subtree, and Git checks them in a defined precedence order.
- Negation (`!`) has limits: if a parent directory is excluded by a pattern, files inside it cannot be re-included — you must exclude the parent directory's contents differently (e.g. ignore `dir/*` then re-include `!dir/keep.txt`).

## Cautions and common failures

- **"My ignore rule doesn't work."** The file is almost certainly already tracked. Add the pattern *and* run `git rm --cached <file>`, then commit.
- **Confusing `git rm --cached` with `git rm`.** The former untracks but keeps the file locally; the latter deletes the file from disk as well.
- **Assuming ignoring hides the file from history.** Old commits still contain the file; ignoring only prevents it from being committed going forward. Removing it from history is a separate, more involved topic.
- **Committed secrets.** A `.gitignore` rule does not remove a secret that was already pushed; treat it as compromised and rotate it.
- **Over-broad patterns** (e.g. a bare `*.dat`) can accidentally exclude files you actually want; test with `git check-ignore` before committing the `.gitignore` change.

## Related capabilities

- line-endings-gitattributes (`.gitattributes` governs a different class of per-path behavior)
- secret-scanning-push-protection (catching committed secrets at the GitHub side)
- partial-staging (keeping unrelated edits out of a commit)

## Official sources

- https://git-scm.com/docs/gitignore — gitignore documentation: pattern rules, untracked-only scope, comments and negation.
- https://git-scm.com/docs/git-check-ignore — documentation for `git check-ignore`, used to test whether a path is excluded.
- https://git-scm.com/docs/gitfaq — the Git FAQ, which explains untracking already-tracked files with `git rm --cached` when adding ignore rules.

## Provenance

This page was authored against the official Git documentation cited above — specifically git-scm.com's pages for `gitignore`, `git-check-ignore`, and the Git FAQ — retrieved via Context7 under the library id `/websites/git-scm`. It should be spot-checked against the current docs before shipping, since upstream documentation paths and wording are periodically reorganized.