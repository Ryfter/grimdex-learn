---
title: Crediting multiple commit authors
module_id: git-and-github
capabilities:
  - co-authored-commits
context7_library: /websites/github_en
context7_queries:
  - How do I credit a co-author in a git commit message?
  - What is the exact Co-authored-by trailer syntax for co-authored commits?
  - Why is my co-author not showing on a commit on GitHub?
official_sources:
  - https://docs.github.com/en/pull-requests/committing-changes-to-your-project/creating-and-editing-commits/creating-a-commit-with-multiple-authors
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

A co-authored commit is a single git commit that GitHub attributes to more than one person. Git itself only records one author and one committer per commit, so GitHub supports an additional convention: a `Co-authored-by:` trailer placed at the end of the commit message. When GitHub sees a well-formed trailer, it credits each named person alongside the primary author in the commit view and, where applicable, in contribution statistics.

## When it is useful

- Pair programming or mob programming, where two or more people genuinely wrote the change together.
- A change largely written by one person but reviewed or completed in substantial part by someone else.
- Importing or adapting someone else's code into a commit you are making, when you want public credit for the original author.
- Team reports or contribution reviews where you want an accurate record of who worked on what, rather than attributing a shared effort to one person.

## Prerequisites

- You (or the person committing) can create commits locally or via GitHub's web editor.
- Each co-author's name and the email address associated with their GitHub account. The trailer matches people on GitHub by email, so the correct email matters.
- No special git configuration or GitHub settings are required -- the trailer is just text in the commit message.

## Current syntax

A commit message with a co-author trailer looks like this:

```
Improve validation error messages

Co-authored-by: Jane Doe <jane.doe@example.com>
```

The exact requirements:

- The trailer is the literal string `Co-authored-by:` (capital C and lowercase b in "authored-by" is the conventional spelling), followed by a space, the person's name, and their email in angle brackets: `Co-authored-by: Name <email>`.
- There must be a blank line between the commit message's subject/body and the trailer line.
- Use one `Co-authored-by:` line per co-author; multiple co-authors means multiple such lines, each on its own line after the blank line.

```
Refactor onboarding flow

Co-authored-by: Jane Doe <jane.doe@example.com>
Co-authored-by: Sam Lee <sam.lee@example.com>
```

## What happens (local and remote)

Locally, git treats the trailer as ordinary text at the end of the commit message -- it stores it verbatim and git's own tooling ignores it. Nothing about the commit's stored author or committer changes.

Remotely, when the commit is pushed to GitHub, GitHub parses the message, matches each trailer's email address against GitHub accounts, and displays the co-authors as additional credited contributors on the commit. If an email doesn't match a GitHub account, the trailer is still stored but no GitHub profile is linked for that co-author.

## Practical example

You and a teammate, Priya, pair on a bugfix. You make the commit:

```
git commit -m "Fix pagination on search results

Co-authored-by: Priya Sharma <priya@users.noreply.github.com>"
```

(In a text editor this reads as: subject line, blank line, then the trailer.)

After you push and the commit appears on GitHub (for example, within a pull request), the commit page shows you as the author and Priya as a co-author, linked to her profile via the email her account uses.

Tip: to avoid exposing anyone's personal email in public history, co-authors can supply the no-reply email address GitHub assigns them (found in their account email settings) in the trailer instead of a real address.

## Explanation guidance

### Essential

Git stores exactly one author per commit, so the trailer is the mechanism for crediting everyone else who contributed. Say it plainly: a blank line, then one `Co-authored-by: Name <email>` line per person, at the end of the commit message. GitHub does the matching and display; there is nothing extra to configure.

### Experienced-user note

Because matching is by email address, use the email registered to the co-author's GitHub account (or their documented no-reply address) or the credit won't link to a profile. The trailer goes after the blank line separating it from the message body -- anything before that blank line is treated as body text, not a trailer.

### Optional deeper context

The trailer convention generalizes: `Co-authored-by:` is one of several recognized trailer lines that can appear in the footer section of a commit message, and tooling beyond GitHub can read them programmatically. Teams that track contribution carefully often adopt trailers consistently as lightweight metadata embedded in history itself.

## Cautions and common failures

- Missing blank line: if the trailer is directly attached to the commit message body with no blank line between them, GitHub may not recognize it as a co-author credit.
- Wrong email: the credit only links to a GitHub profile if the email matches one registered to that account; otherwise the trailer appears as plain text.
- Multiple co-authors on separate lines: putting two people on one line, or interleaving other text, breaks the convention -- use one trailer line per co-author.
- Editing the trailer after the fact: rewriting an existing commit to add a trailer changes the commit's hash, which requires a force-push on an already-shared branch -- add the trailer at commit time when possible.
- Contribution graph effects are not guaranteed in all cases; treat the commit-page attribution as the primary visible outcome.

## Related capabilities

- commit-identity-email-privacy -- controlling which name/email git records (relevant to the no-reply email used in trailers)
- verified-commit-badge -- signing commits so GitHub shows a "Verified" badge
- linking-issues-to-prs -- using closing keywords in commit messages and PR descriptions
- github-cli-for-prs -- creating commits and pull requests from the command line

## Official sources

- https://docs.github.com/en/pull-requests/committing-changes-to-your-project/creating-and-editing-commits/creating-a-commit-with-multiple-authors -- GitHub's documentation on creating a commit with multiple authors, including the Co-authored-by trailer format.

## Provenance

This page was authored against the cited official GitHub documentation (docs.github.com, "Creating a commit with multiple authors"), retrieved via Context7 (library `/websites/github_en`). The trailer syntax and blank-line requirement are long-stable behavior, but GitHub's documentation paths reorganize periodically, so the cited URL and details should be spot-checked against current docs before shipping.