---
title: Staging part of a file with git add -p
module_id: git-and-github
capabilities:
  - partial-staging
context7_library: /websites/git-scm
context7_queries:
  - How do I stage only some changes in a file with git add -p?
  - What does the interactive patch mode prompt in git add mean?
  - How can I split a hunk when staging changes in git?
official_sources:
  - https://git-scm.com/docs/git-add
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

`git add -p` (long form `git add --patch`) is an interactive mode of the standard staging command. Instead of staging a whole file at once, it walks through each block of changes in that file — called a **hunk** — and asks, for each one, whether it should go into the next commit. A hunk is simply a contiguous group of changed (added, removed, or modified) lines, shown with a few lines of surrounding context so you can see where in the file the change sits. You can accept or reject each hunk independently, so one file can contribute only part of its edits to a commit while the rest stays in the working tree.

## When it is useful

The common situation is that unrelated edits have accumulated in the same file: a bug fix, a typo correction, and a formatting change all sitting together. A commit that mixes unrelated changes is harder to review, harder to revert selectively, and harder to understand later. Partial staging lets you put each kind of change into its own commit without needing a separate editor or any manual file juggling. It is also useful when you deliberately want to hold back part of your work — for example, committing a working fix now and leaving an experimental tweak uncommitted.

## Prerequisites

- Git installed locally and a repository with uncommitted changes in the working tree.
- Familiarity with the basic staging model: files move from the working tree to the staging area (`git add`), then into history (`git commit`).
- Comfort with a terminal prompt that pauses and waits for a single-character answer.

## Current syntax

```
git add -p          # interactive patch staging (or: git add --patch)
```

Git then prompts once per hunk with a single-letter menu. The essentials:

- `y` — stage this hunk
- `n` — skip this hunk (leave it unstaged)
- `s` — split the current hunk into smaller hunks, if the changes are separated by enough unchanged context, and ask about each piece separately

Other letters exist for edge cases (such as editing a hunk by hand), but `y`, `n`, and `s` cover the everyday workflow.

## What happens (local and remote)

Everything happens locally. Git compares the working tree against the staged copy and displays hunks one at a time. Answering `y` moves that hunk into the staging area; answering `n` leaves it in the working tree. After walking through all hunks, a `git commit` records only what was staged. The skipped hunks remain as uncommitted changes, ready to be staged and committed later — possibly in a second, separate commit. Nothing is pushed or shared until you commit and push, so wrong answers at the prompt are harmless and fully correctable before committing.

## Practical example

Suppose `report.py` contains both a fix to a calculation and a spelling correction, and you want them in separate commits:

```
$ git add -p report.py
@@ -12,7 +12,7 @@
-    total = sum(items)
+    total = sum(items) + tax
Stage this hunk [y,n,q,a,d,s,e,?]? y

@@ -40,6 +40,6 @@
-# calulate the average
+# calculate the average
Stage this hunk [y,n,q,a,d,s,e,?]? n
```

The first hunk (the calculation fix) is staged with `y`; the typo hunk is skipped with `n`. Then:

```
$ git commit -m "Fix tax handling in report total"
$ git add -p report.py    # this time answer y to the typo hunk
$ git commit -m "Fix spelling in comment"
```

If two changes sit too close together for Git to separate them into different hunks, answering `s` at the prompt attempts to split them so each part can be decided on its own.

## Explanation guidance

### Essential

Explain the staging area as a "what goes into the next commit" basket. `git add <file>` puts the whole file's current state in the basket; `git add -p` asks hunk by hunk what to put in. Emphasize the three core answers: `y` yes, `n` no, `s` split. Stress that nothing is lost by saying `n` — the change just stays in the working tree for later.

### Experienced-user note

Point out that clean, reviewable commits are a courtesy to whoever reads the history later — including your future self. If a hunk contains two tightly adjacent changes that `s` cannot separate, it is often easier to commit what can be separated, then decide whether the remainder matters enough to bother with. The `q` answer also quietly exits the prompt, leaving remaining hunks unstaged.

### Optional deeper context

The same patch-selection logic underlies other Git features: `git checkout -p` and `git restore -p` let you interactively discard changes, and `git stash -p` lets you stash only selected hunks. Once learners are comfortable with the hunk prompt in `git add -p`, these siblings behave the same way.

## Cautions and common failures

- **Typing the wrong letter.** `d` (done with this file) or `a` (stage all remaining hunks in this file) skip past hunks you meant to review. If the result looks wrong, you can reset the staging area (`git reset` without arguments unstages everything) and start the walk-through again.
- **Splitting is not always possible.** `s` only works when there are enough unchanged lines between changes; adjacent edits form one inseparable hunk.
- **Committed is not hidden.** Partial staging prevents unrelated changes from landing in the *next* commit, but anything already committed stays in history until you deliberately rewrite it — which is a separate, riskier operation.
- **End-of-file changes.** Additions or deletions at the very end of a file sometimes form one hunk with no split point; `s` will report it cannot split.

## Related capabilities

- gitignore-essentials — controlling which files are considered for tracking at all
- git-stash — setting uncommitted changes aside wholesale rather than hunk by hunk
- git-blame-file-history — seeing which commit last changed each line after the fact

## Official sources

- https://git-scm.com/docs/git-add — official Git documentation for `git add`, including the `--patch` interactive mode and its prompt options.

## Provenance

This page was authored against the official Git documentation at git-scm.com (specifically the `git-add` manual page covering the `--patch`/`-p` interactive mode and its hunk prompt), retrieved via Context7. GitHub's own documentation is not the source here because the capability is plain Git CLI behavior, not a github.com feature. Spot-check the cited page against current docs before shipping; documentation sites reorganize their URLs periodically.