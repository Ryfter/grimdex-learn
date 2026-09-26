---
title: Finding who changed a line with git blame
module_id: git-and-github
capabilities:
  - git-blame-file-history
context7_library: /websites/git-scm
context7_queries:
  - How do I find out which commit and author last changed each line of a file?
  - What does git blame show and how do I read its output?
  - How do I see per-line file history on GitHub without the command line?
official_sources:
  - https://git-scm.com/docs/git-blame
  - https://git-scm.com/docs
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

`git blame <file>` is a command-line tool that annotates every line of a file with the commit that last changed it. For each line it shows a short commit identifier, the author, and when that change was made. GitHub's web interface offers an equivalent per-file "blame" view that shows the same per-line attribution in the browser, reachable from a file's history page.

## When it is useful

- You find a confusing line of code or an odd setting and want to know who wrote it, when, and in which commit -- so you can ask an informed question or read the commit message for context.
- A regression appeared and you want to trace which commit last touched the offending line.
- You are reviewing a file's history and want to see how responsibility for its content evolved line by line, without leaving the browser (GitHub blame view) or the terminal (CLI).

## Prerequisites

- A git repository containing the file's history (for the CLI), or a repository hosted on GitHub (for the web blame view).
- Basic familiarity with running git commands in a terminal, or with navigating files on github.com.

## Current syntax

```
git blame <file>
```

Replace `<file>` with the path to the file you want to annotate, for example:

```
git blame src/config/settings.py
```

## What happens (local and remote)

**Local (CLI):** running `git blame <file>` prints the file's contents line by line. Each line is prefixed with the short hash of the commit that last modified it, plus the author name and the date of that change. Nothing is modified -- blame is a read-only inspection command.

**Remote (GitHub web UI):** on github.com, navigate to a file in a repository and open its history page; from there you can open the per-file blame view. It shows the same per-line attribution as the CLI -- commit and author per line -- in a scrollable, clickable view, without needing a local clone or terminal.

## Practical example

Suppose a line in a configuration file reads `timeout: 30` and you want to know why. From a terminal, in your local copy of the repository:

```
git blame src/config/settings.py
```

The output annotates each line with the commit and author that last changed it. Find the line in question, note its commit hash, then look up that commit (for example with `git show <hash>`) to read its message and understand the change.

If you have no local clone, open the file on github.com, go to its history page, and open the blame view there -- the same per-line attribution is shown in the browser.

## Explanation guidance

### Essential

- `git blame` answers one question: *which commit last changed this specific line, and by whom?*
- It is read-only; it never changes files, branches, or history.
- GitHub's web blame view shows the same information for any file in a hosted repository, no tools installed.

### Experienced-user note

- Blame reports the *last* change to each line, not the full chain of changes. If a line was later reformatted, the blame points at the formatting commit, not the original author of the logic. Reading the commit behind a blame result usually clarifies this.
- Blame pairs naturally with file history: blame tells you which commit to inspect, and the commit's message and diff explain why the line changed.

### Optional deeper context

- The GitHub blame view is reachable from a file's history page, so the two views -- commit history of the file and per-line attribution -- complement each other in the web UI as well as in the CLI.
- Teams often use blame results as conversation starters ("I see you touched this line in commit X -- what was the reasoning?") rather than as verdicts about correctness.

## Cautions and common failures

- Blame attributes lines to the last commit that touched them; a purely cosmetic commit (reformatting, whitespace) will "take over" blame for lines it touched, hiding the original author of the logic.
- A blame result tells you *who made* a change, not *why* -- read the referenced commit's message (and any linked issue or pull request) for the rationale.
- Blame is not a judgment of responsibility for bugs; it is an attribution tool. Use it to find context, not to assign fault.
- On GitHub, the blame view requires the file to be hosted there; it works only for repositories you can view on github.com.

## Related capabilities

- `git-stash` -- setting aside in-progress changes before inspecting history.
- `cherry-picking` -- porting a specific commit (which blame may have helped you find) to another branch.
- `git-add-p-partial-staging` -- staging only some hunks after tracing which changes belong together.
- `github-dev-quick-edits` -- browser-based editing of the file you were just inspecting.

## Official sources

- https://git-scm.com/docs/git-blame -- official git documentation for the `git blame` command.
- https://git-scm.com/docs -- official git documentation index, covering related file-history inspection commands.

## Provenance

This page was authored against the official git documentation (git-scm.com/docs/git-blame and the git-scm.com docs index) and GitHub's documentation for the per-file blame view, retrieved via Context7. GitHub's documentation paths reorganize periodically, so spot-check the cited pages against current docs before shipping.