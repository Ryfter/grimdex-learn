---
title: What the Verified commit badge means
module_id: git-and-github
capabilities:
  - verified-commit-badge
context7_library: /websites/github_en
context7_queries:
  - What does the Verified badge on a GitHub commit mean?
  - How does GitHub validate GPG or SSH signed commits?
  - Can branch protection require signed commits on GitHub?
official_sources:
  - https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification
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

A "Verified" badge is a small label GitHub displays next to a commit when the commit's cryptographic signature (GPG or SSH) can be validated against a key that is registered to the committer's GitHub account. It confirms that the commit was signed by the person who owns that key.

## When it is useful

- Teams that want assurance that commits attributed to a person were actually made (or signed) by that person's key.
- Organizations with compliance or audit requirements around commit provenance.
- Open-source projects where contributors may want to demonstrate that commits came from them, not an impersonator.

## Prerequisites

- A GitHub account.
- A GPG key or SSH key registered to that GitHub account, and the local git configuration set up to sign commits with that key. (Setup details are covered in GitHub's own signature-verification docs; this page is recognition-level.)

## Current syntax

Not applicable -- the badge is a GitHub UI feature, not a git command. The underlying mechanics involve signing commits locally (GPG or SSH) and uploading the corresponding public key to GitHub, which GitHub then uses to validate the signature on each commit it receives.

## What happens (local and remote)

- Locally, a commit is signed with the committer's GPG or SSH key.
- When the commit is pushed to GitHub, GitHub checks whether the signature can be validated against a key registered to a GitHub account. If it validates, GitHub shows the "Verified" badge on that commit.
- If the signature is missing, invalid, or does not match a registered key, no badge is shown (or GitHub shows an "Unverified" indication, depending on context).

## Practical example

A repository maintainer reviews a pull request. Several commits in the PR display a "Verified" badge, indicating each was signed with a key registered to the contributor's GitHub account. This gives the maintainer reasonable confidence the commits were made by that contributor, not someone spoofing their name and email in the commit metadata.

## Explanation guidance

### Essential

- The badge attests to WHO signed the commit -- that is, the signature matches a key registered to a known GitHub account.
- It does NOT attest that the commit's contents are safe, correct, or malware-free. A signed commit can still contain buggy or malicious code.
- Server-side branch protection on GitHub can require signed commits, blocking merges of unsigned commits when that protection is enabled (GitHub's REST docs reference `required_signatures` on branch protection for this).

### Experienced-user note

- Signing is done with GPG or SSH keys configured locally and registered to a GitHub account; losing or rotating the key affects future signing but does not retroactively invalidate past verified commits.
- Rebases or amendments can change a commit and require re-signing for the new commit to remain verified.

### Optional deeper context

- Signature verification happens at GitHub's side, so the badge reflects GitHub's validation, not a local check the reviewer runs themselves.
- Teams combining required signed commits with required reviews get two independent signals: who authored/signed the change, and who approved it.

## Cautions and common failures

- Mistaking "Verified" for "safe" -- the badge says nothing about code quality or intent.
- Assuming all commits in a repository are verified just because some are; verification is per-commit.
- Pushing commits signed with a key that is not registered to the committer's GitHub account; those commits will not show as verified.
- Believing signature verification replaces code review or automated testing; it does not.

## Related capabilities

- commit-identity-email-privacy -- controlling the name/email attached to commits, which is separate from cryptographic signing.
- branch-protection-rulesets -- the mechanism by which a repo admin can require signed commits before merge.

## Official sources

- https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification -- GitHub's explanation of commit signature verification and what the Verified badge indicates.

## Provenance

This page was authored against GitHub's official commit signature verification documentation (docs.github.com, "About commit signature verification"), retrieved via Context7. Branch protection requiring signed commits is corroborated by GitHub REST docs referencing `required_signatures` on branch protection. GitHub's documentation paths are reorganized periodically; spot-check the cited URLs against current docs before shipping.