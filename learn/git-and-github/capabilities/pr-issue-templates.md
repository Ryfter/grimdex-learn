---
title: Using PR and issue templates
module_id: git-and-github
capabilities:
  - pr-issue-templates
context7_library: /websites/github_en
context7_queries:
  - How do I add a pull request template to a repository?
  - Where do issue template files go in the .github folder?
  - How do templates pre-fill the PR or issue description box?
official_sources:
  - https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository
  - https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates
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

A repository can ship one or more template files that pre-fill the description box when someone opens a pull request or an issue. A pull request template lives at `.github/PULL_REQUEST_TEMPLATE.md`; issue templates live under `.github/ISSUE_TEMPLATE/` (either a single file or a folder of multiple templates). The templates are ordinary Markdown files checked into the repository, so they version with the code and can be edited like any other file.

## When it is useful

Templates solve a recurring problem: contributors open pull requests or issues with incomplete descriptions — missing context on what changed, why, or how it was tested. Reviewers then have to chase authors for details, which slows every review down.

- For **authors**, the template is a prompt sitting in the description box: it reminds them to state what changed, why, and how they verified it, instead of writing "fixes bug" and nothing else.
- For **reviewers**, consistently structured descriptions make PRs and issues comparable and scannable, so triage and review go faster and nothing important is silently omitted.

They are especially useful on repositories with many outside or infrequent contributors, who are the least likely to know what information maintainers need.

## Prerequisites

- Write access to the repository to add the template files (or a pull request adding them).
- Basic familiarity with Markdown, since templates are Markdown files.
- No local tooling is required — template files are typically added through a normal commit or even GitHub's in-browser editor.

## Current syntax

Files and locations:

- `.github/PULL_REQUEST_TEMPLATE.md` — the pull request template.
- `.github/ISSUE_TEMPLATE/` — one or more issue templates in this folder.

The templates are written in Markdown and typically contain headings or prompts such as:

```markdown
## What does this PR change?
## Why is this change needed?
## How was this tested?
```

For issues, multiple templates can be placed in the `.github/ISSUE_TEMPLATE/` folder so contributors can pick the one that fits (bug report, feature request, and so on).

## What happens (local and remote)

The template files live in the repository, so GitHub reads them at the moment someone opens a new PR or issue on github.com:

- When creating a **pull request**, the contents of `.github/PULL_REQUEST_TEMPLATE.md` are pre-filled into the description box.
- When creating an **issue**, GitHub presents the available issue templates from `.github/ISSUE_TEMPLATE/` for the author to choose from, and the chosen template is pre-filled into the issue body.

The templates themselves are just repository content — committing, changing, or removing them is an ordinary git operation, and the change takes effect for everyone opening PRs/issues afterward.

## Practical example

Add a pull request template:

1. In the repository, create the file `.github/PULL_REQUEST_TEMPLATE.md`.
2. Put prompting headings in it:

```markdown
## What does this PR change?

## Why is this change needed?

## How was this tested?
```

3. Commit and push it.

The next time anyone opens a pull request against this repository, the description box already contains those headings, and the author fills in each section instead of starting from a blank box.

## Explanation guidance

### Essential

- Templates are optional repository files; if present, GitHub uses them automatically.
- They only pre-fill the description box — they do not block a submission if the author deletes the text or ignores it.
- Both PR and issue templates are plain Markdown, so formatting is under your control (headings, task lists, code fences all work).

### Experienced-user note

- Keeping the template short increases the chance authors actually fill it in; a long questionnaire tends to be skipped wholesale.
- Template changes can be reviewed like any other change, so teams can iterate on the template through a pull request and see its effect in the PR diff.
- Templates pair naturally with CODEOWNERS and branch protection: templates raise the quality of incoming descriptions, while those mechanisms enforce review and checks.

### Optional deeper context

- Because templates live in `.github/`, they are visible in every clone — contributors using the CLI can read the same file to know what a good description looks like even when opening PRs from the command line.
- A repository can also be marked as a template repository (a separate feature), which is unrelated: that copies files and structure into new repositories, whereas PR/issue templates pre-fill description boxes.

## Cautions and common failures

- Templates are advisory, not enforced: nothing stops an author from erasing the pre-filled text and submitting an empty description. If enforcement is needed, look at branch protection or rulesets for review requirements instead.
- Wrong file location means no template appears — the PR template must be `.github/PULL_REQUEST_TEMPLATE.md` and issue templates under `.github/ISSUE_TEMPLATE/`.
- Templates only apply at creation time. Editing the template later does not retroactively update existing PRs or issues.

## Related capabilities

- codeowners — automatically routes review requests on PRs that touch owned paths.
- branch-protection-rulesets — can require approvals and status checks before merge.
- linking-issues-to-prs — closing keywords connect PRs to the issues they resolve.
- markdown-for-prs-issues — the rendering rules for what you put inside the template and descriptions.

## Official sources

- https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository — GitHub docs on creating a pull request template.
- https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates — GitHub docs overview of issue and pull request templates.

## Provenance

This page was authored against the cited official GitHub documentation (docs.github.com, "About issue and pull request templates" and "Creating a pull request template for your repository"), retrieved via Context7. It should be spot-checked against the current docs before shipping, since GitHub's documentation paths reorganize periodically.