---
title: Markdown formatting for PRs and issues
module_id: git-and-github
capabilities:
  - markdown-for-prs-issues
context7_library: /websites/github_en
context7_queries:
  - How do I format text in a GitHub pull request or issue description?
  - How do task-list checkboxes work in GitHub issues?
  - How do I add a code block with syntax highlighting in a GitHub comment?
official_sources:
  - https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax
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

GitHub renders Markdown in pull request and issue descriptions, as well as in comments on both. Markdown is a lightweight plain-text formatting syntax: you type simple characters like `#`, `-`, and backticks, and GitHub displays the result as formatted text. The relevant features include headings, bulleted and ordered lists, fenced code blocks (with an optional language tag for syntax highlighting), links, and task-list checkboxes.

## When it is useful

Any time you open, describe, or discuss a pull request or issue:

- Structuring a PR description so reviewers can quickly find what changed, why, and how it was tested.
- Writing an issue report with clear sections (steps to reproduce, expected vs. actual behavior).
- Sharing a code snippet inline without losing its formatting, using a fenced code block.
- Tracking subtasks inside an issue with checkboxes so progress is visible at a glance.

## Prerequisites

- A GitHub account and access to a repository where you can open an issue or pull request.
- No local installation is needed -- Markdown is entered directly in GitHub's web editor.

## Current syntax

The core patterns:

- Headings: lines starting with `#` (largest) through `######` (smallest).
- Unordered lists: lines starting with `-` or `*`.
- Ordered lists: lines starting with `1.`, `2.`, etc.
- Fenced code blocks: text surrounded by lines of three backticks; adding a language name after the opening backticks enables syntax highlighting, e.g. ` ```python `.
- Links: `[link text](https://example.com)`.
- Task lists: `- [ ]` for an unchecked checkbox and `- [x]` for a checked one.

## What happens (local and remote)

Everything happens on GitHub's side. When you save a description or comment, GitHub converts the Markdown source into rendered HTML for other readers. The original plain-text Markdown is preserved as the underlying content and can be edited again at any time. Nothing is pushed, cloned, or stored outside the repository's issue/PR data. Task-list checkboxes rendered in an issue can be checked and unchecked directly in the rendered view, which updates the underlying Markdown.

## Practical example

A pull request description:

````markdown
## What changed
- Added a retry loop to the upload script
- Fixed a typo in the README

## How it was tested
1. Ran the script against the staging server
2. Verified the log output

```python
result = upload_with_retries(path, attempts=3)
```

Reference: see the [upload spec](https://example.com/spec).

## Remaining tasks
- [x] Update the config file
- [ ] Ask a reviewer about error handling
````

Rendered, this shows a heading, two lists, a highlighted Python code block, a clickable link, and two checkboxes (one already ticked).

## Explanation guidance

### Essential

Markdown in PRs and issues is plain text with a few simple conventions. `#` makes headings, `-` makes bullet lists, three backticks make a code block, and putting a language name after the opening backticks makes the code display with colors matching that language. Square brackets plus a URL in parentheses make a link. `- [ ]` and `- [x]` create checkboxes that readers can tick off -- useful for turn-by-turn steps or subtasks in an issue.

### Experienced-user note

Consistent structure in PR descriptions (for example fixed headings for "what changed / why / how tested") makes review faster and pairs well with PR templates if the repository defines them. Task lists in issues are commonly used as lightweight checklists for multi-step work. Code fences with a language tag avoid the common failure mode of pasting code that GitHub mangles or partially interprets.

### Optional deeper context

The same Markdown rendering applies to comments, so discussions can stay formatted too. Because the raw Markdown is always preserved, nothing is lost by editing -- you can switch between the "Write" and preview views freely. Repositories that use issue and PR templates effectively standardize this formatting across contributors.

## Cautions and common failures

- Forgetting the closing triple-backtick fence: everything after the opening fence renders as code until a matching fence appears.
- Missing the language tag after the opening fence: the code block renders, but without syntax highlighting.
- Typing `- []` or `- [x ]` (wrong spacing) produces plain text, not a checkbox; the syntax must be exactly `- [ ]` or `- [x]`.
- Links with a missing parenthesis or bracket do not render as links.
- Indentation is significant for lists; inconsistent indentation can produce unintended nesting.

## Related capabilities

- pr-issue-templates
- linking-issues-to-prs
- in-browser-commits

## Official sources

- https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax -- GitHub Docs: basic writing and formatting syntax (headings, lists, code blocks, links, task lists).

## Provenance

Authored against the cited official GitHub documentation (docs.github.com, "Basic writing and formatting syntax"), retrieved via Context7. Spot-check against current docs before shipping, since GitHub's documentation paths reorganize periodically.