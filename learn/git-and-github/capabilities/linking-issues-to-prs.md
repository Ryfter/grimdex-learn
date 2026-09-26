---
title: Linking issues to PRs with closing keywords
module_id: git-and-github
capabilities:
  - linking-issues-to-prs
context7_library: /websites/github_en
context7_queries:
  - How do I close an issue automatically when a pull request is merged?
  - What closing keywords like Fixes or Closes link a PR to an issue?
  - Do closing keywords work when merging into a non-default branch?
official_sources:
  - https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue
  - https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/creating-an-issue
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

GitHub lets you connect a pull request to an issue by using a closing keyword in the pull request description or in a commit message. Writing a phrase such as `Closes #42` or `Fixes #108` in the PR description does two things at once: it displays a link between the PR and the issue in GitHub's interface, and it tells GitHub to automatically close the issue when the PR is merged into the repository's default branch.

The recognized keywords include `Closes`, `Fixes`, and `Resolves` (with common variants like `Closed`, `Fixed`, `Resolved`), followed by the issue number, for example `Closes #42`. A single PR description can contain several such lines to link multiple issues.

This capability covers traceability only: which pull request addressed which reported problem. It is not agile or sprint content — it says nothing about estimation, prioritization, or project boards.

## When it is useful

- When a PR is meant to resolve one or more tracked issues, and you want those issues to close themselves on merge rather than relying on someone remembering to close them manually.
- When reviewers or maintainers want to see, directly on the PR, which reported problems the change addresses.
- When you later need to answer "which change fixed issue #108?" — the issue's timeline shows the merging PR.
- When you want to avoid the common failure mode of an issue staying open after the fix has shipped.

## Prerequisites

- A GitHub repository with at least one open issue.
- A pull request, opened in the same repository as the issue.
- Knowledge of the issue number, shown in the issue's URL and title.

## Current syntax

In the pull request description (or in a commit message), use a keyword followed by the issue number:

```markdown
Closes #42

## Summary
Fixes the intermittent failure in report generation.

Closes #42
Fixes #108
```

Multiple issues can be linked with one line each. The keyword must appear with the `#` reference in the PR description or a commit message — a bare `#42` mention links the items in the UI but does not auto-close the issue on merge.

## What happens (local and remote)

Everything here happens on GitHub's side; no local git command is involved. When the PR is merged into the repository's **default branch**, GitHub automatically closes every issue referenced with a closing keyword in the PR description or commit messages. The issue's timeline records which PR closed it.

If the PR is merged into a branch other than the default branch, the linked issues are not auto-closed — they remain open.

## Practical example

A repository has issue #57: "Export button fails on files with 100+ rows." You open a pull request fixing the bug, and in the PR description you write:

```markdown
## What this changes
Caps rows-per-batch during export and handles overflow.

Closes #57
```

After review, the PR is merged into `main` (the default branch). GitHub closes issue #57 automatically, and the issue page shows "closed this in #58" style attribution to the merge. Nobody had to visit the issue and click Close.

Contrast: if the same fix were merged into a `release-1.4` branch instead, issue #57 would stay open even though the fix is merged, because auto-close only fires on merge into the default branch. In that case someone would close the issue manually, or reopen a PR to default branch.

## Explanation guidance

### Essential

- Write `Closes #<number>`, `Fixes #<number>`, or `Resolves #<number>` in the PR description to link the PR to the issue.
- On merge into the default branch, the issue closes automatically. This is the whole payoff — no manual bookkeeping.
- This is traceability: the connection between "reported problem" and "change that fixed it" is recorded automatically.

### Experienced-user note

- One PR can close multiple issues with one keyword line each.
- The reference must be a closing keyword plus number, not just a `#number` mention; mentions link the items but don't trigger auto-close.
- If your team merges into long-lived non-default branches (e.g., a release branch first), don't rely on auto-close; budget for manual closure or a later merge into default.
- Commit messages carrying closing keywords also work, which matters for people who write detailed commit messages and thin PR descriptions.

### Optional deeper context

- Auto-close applies when the merge lands on the default branch of the repository that owns the issue. This behaves predictably for same-repo PRs; for PRs from forks into the upstream repo, the issue and the PR live in the upstream repository, and the same closing-keyword behavior applies on merge there.
- Teams that track work across repositories sometimes pair closing keywords with full cross-references (`organization/repo#42` style mentions) so related discussions remain navigable — but note that plain cross-repo mention behavior differs from same-repo closing keywords and should be verified against current docs if used for auto-close.

## Cautions and common failures

- **Merged into a non-default branch: no auto-close.** The most common surprise. Closing keywords only fire on merge into the default branch.
- **Wrote only `#42` instead of `Closes #42`.** The PR and issue will be linked in the UI, but the issue will not close automatically.
- **Keyword in a PR comment instead of the description.** The auto-close behavior is tied to the PR description and commit messages, not arbitrary comments.
- **Issue closes too eagerly.** If a PR is merged before the fix is actually deployed to users, the issue closes on merge even though the user-visible problem may persist. Some teams prefer issues to close at deployment, which requires manual closure instead of the keyword.
- **No agile semantics.** Closing keywords do not move items on project boards, assign estimates, or update sprints. They are purely a merge-time close-and-link mechanism.

## Related capabilities

- markdown-for-prs-issues — the PR description where you write the closing keyword is rendered as Markdown.
- codeowners — review routing for the PR that closes the issue.
- branch-protection-rulesets — conditions the PR must satisfy before it can merge and trigger the auto-close.

## Official sources

- https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue — GitHub docs on linking a pull request to an issue, including closing keywords and auto-close behavior.
- https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/creating-an-issue — GitHub docs on issues, the objects being linked and closed.

## Provenance

This page was authored against the cited official GitHub documentation (docs.github.com, "Linking a pull request to an issue" and related issue-tracking pages), retrieved via Context7 (`/websites/github_en`). It should be spot-checked against the current docs before shipping, since GitHub's documentation paths reorganize periodically.