---
title: Responding to secret-scanning and push-protection alerts
module_id: git-and-github
capabilities:
  - secret-scanning-push-protection
context7_library: /websites/github_en
context7_queries:
  - How does GitHub secret scanning detect committed secrets?
  - What does push protection do when I try to push a secret?
  - How do I bypass a push protection block, and who is notified?
  - At what levels can secret scanning be enabled?
  - When does push protection fail to block a push?
official_sources:
  - https://docs.github.com/en/code-security/secret-scanning/introduction-to-secret-scanning
  - https://docs.github.com/en/code-security/secret-scanning/enabling-secret-scanning-features
  - https://docs.github.com/en/code-security/secret-scanning/troubleshooting-secret-scanning
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

Secret scanning is a GitHub security feature that detects known-format secrets (API tokens, passwords, keys) that have been committed to a repository. Push protection is a layer on top of secret scanning: instead of only alerting after a secret lands in the repository, GitHub blocks the push containing the detected secret before it ever reaches GitHub. If someone pushes anyway by bypassing the block with a stated reason, GitHub generates an alert.

## When it is useful

Any time code in a repository talks to an external service, there is a risk that a credential ends up hardcoded in a file and pushed. Secret scanning catches secrets that slipped through; push protection catches them at the moment of the push, before exposure. For organizations and account owners, enabling these features reduces the window during which a leaked credential is publicly visible and the cost of rotating it.

## Prerequisites

- A GitHub repository (or organization or personal account) where secret scanning features can be enabled.
- No special local tooling: detection and blocking happen on GitHub's side when you push.
- Awareness of what your secrets look like, so an alert can be matched to a real credential and rotated.

## Current syntax

There are no commands to learn for this capability. Enablement and response happen in the GitHub UI at the repository, organization, or user-account level:

- Repository settings: enable secret scanning, and push protection on top of it.
- Organization settings: enable the features for organization repositories.
- User-account settings: enable for personal repositories.

When a push is blocked, the push output explains the detected secret and offers paths to resolve or bypass the block.

## What happens (local and remote)

- Secret scanning scans committed content for known secret formats and raises alerts when matches are found.
- With push protection enabled, GitHub checks the pushed content before it is accepted. If a known-format secret is detected, the push is blocked and does not reach GitHub.
- To get the push through, the person pushing can either remove the secret and push again, or choose to bypass the block and state a reason. Bypassing lets the push through and generates a secret-scanning alert so the exposed secret can be reviewed.
- Enablement can be done at the repo, organization, or user-account level.

## Practical example

A developer accidentally writes an API token into a configuration file and runs `git push`. Because push protection is enabled on the repository, the push is rejected before the token is stored on GitHub. The developer removes the token from the file (moving it to a secrets manager or environment setting instead), and the second push succeeds. No alert exists because nothing landed.

In a second case, a developer is knowingly pushing a placeholder value that matches a token format for testing. They choose to bypass the block and state the reason ("test placeholder"). The push succeeds, and GitHub generates an alert so a security reviewer can confirm it really is a placeholder.

## Explanation guidance

### Essential

Secret scanning finds known-format secrets that were committed to a repository. Push protection goes a step earlier: it blocks a push containing a detected secret before it ever reaches GitHub, so nothing is exposed in the first place. If the push goes through via a bypass with a stated reason, an alert is generated so someone can follow up. The features can be turned on at the repository, organization, or personal-account level.

### Experienced-user note

Bypassing push protection is a deliberate, audited decision: the stated reason is recorded and an alert is created, so bypass is not a silent loophole. When an alert fires (whether from scanning or a bypass), the practical next step is to rotate the real credential if it is genuine -- removing the secret from the code alone does not un-leak it, since it remains in git history.

### Optional deeper context

Push protection has a documented limitation: if a push contains more than 1,000 secrets that already have alerts, push protection does not block that push. This is a real edge case in GitHub's troubleshooting documentation, worth knowing when triaging a large legacy push or history import that may contain many already-known secrets.

## Cautions and common failures

- Assuming a blocked push means the secret is safe: if someone bypassed with a reason, the secret is now on GitHub and should be treated as exposed until verified.
- Believing that deleting a secret in a later commit removes it: the secret stays in git history; rotation is the only reliable fix.
- Bypassing push protection casually to "get unblocked" -- this creates alerts that reviewers must spend time triaging.
- Relying on push protection to catch every secret: the >1,000 already-alerted secrets limitation means a very large push may not be blocked.
- Confusing the enablement levels: a repository-level setting covers only that repository; an organization-level setting covers organization repositories; a personal-account setting covers personal repositories.

## Related capabilities

- verified-commit-badge -- commits can be signed to attest to who made them; this is identity, not secret protection.
- repository-access-roles -- who can push to a repository in the first place.
- in-browser-commits -- edits made directly on github.com are also commits and can contain secrets.

## Official sources

- https://docs.github.com/en/code-security/secret-scanning/introduction-to-secret-scanning -- GitHub's introduction to secret scanning, covering detection and alerts.
- https://docs.github.com/en/code-security/secret-scanning/enabling-secret-scanning-features -- how to enable secret scanning and push protection at repo, org, and account levels.
- https://docs.github.com/en/code-security/secret-scanning/troubleshooting-secret-scanning -- troubleshooting guidance, including the >1,000 already-alerted secrets limitation.

## Provenance

This page was authored against the cited official GitHub documentation: the "Introduction to secret scanning", "Enabling secret scanning features", and "Troubleshooting secret scanning" pages on docs.github.com, retrieved via Context7. GitHub's documentation paths reorganize periodically, so the URLs and details should be spot-checked against the current docs before shipping.