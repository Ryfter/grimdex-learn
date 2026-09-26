---
title: Branch protection and rulesets
module_id: git-and-github
capabilities:
  - branch-protection-rulesets
context7_library: /websites/github_en
context7_queries:
  - How do I require status checks and approving reviews before a pull request can be merged?
  - What are GitHub rulesets and how do they differ from branch protection rules?
  - Can I require signed commits on a protected branch?
official_sources:
  - https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
  - https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets
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

By default on GitHub, any pull request can be merged once its conflicts are resolved. Branch protection rules and rulesets are two repository-admin mechanisms that change this: they block merging into a designated branch until certain conditions are met.

Branch protection rules are the classic mechanism. A repository admin can add requirements such as:

- required status checks (e.g. CI must pass before merge),
- required approving pull request reviews,
- required signed commits (GitHub then shows its "Verified" badge only where a commit's GPG/SSH signature validates against a key registered to the committer's account -- which attests to who signed it, not that its contents are safe or correct).

Rulesets are a newer, complementary mechanism. They can apply to multiple branches at once (using patterns rather than one branch per rule), do not require admin access to view, and can include conditions based on code-scanning alerts. A ruleset can enforce rules similar to those of branch protection, including blocking merges until conditions are satisfied.

The two mechanisms can coexist in the same repository: a branch can be governed by both a branch protection rule and one or more rulesets, with all applicable requirements needing to be satisfied.

## When it is useful

- Any shared branch that others depend on (typically the default branch) where direct or unreviewed changes would be risky.
- Teams that want CI to be a merge gate, so broken code cannot land on the main branch even by accident.
- Organizations that need to enforce the same merge requirements across many branches at once -- rulesets' multi-branch targeting fits this better than one-rule-per-branch branch protection.
- Projects that want contributors to see which rules apply without needing admin access -- ruleset definitions are viewable by non-admins.
- Workflows where the review, checks, and rules mechanisms must combine rather than replace each other.

## Prerequisites

- A GitHub repository where you have admin access (needed to create or edit either branch protection rules or rulesets; viewing rulesets requires no admin access).
- Familiarity with pull requests as the path into the protected branch.
- For required status checks, a CI or other check that actually reports a status on pull requests.
- For required signed commits, committers who have registered a GPG or SSH signing key with their GitHub account.

## Current syntax

This is a GitHub-hosted platform feature, configured in the repository's Settings rather than via git commands.

- Branch protection rules: repository Settings, under branch protection; per-rule configuration of required status checks, required approving reviews, required signed commits, and other merge restrictions.
- Rulesets: repository Settings, under rulesets; a ruleset targets one or more branches by name or pattern and defines the rules that apply to them.

## What happens (local and remote)

Branch protection and rulesets take effect on the GitHub side when someone attempts to merge a pull request into a branch they cover:

- If required status checks are configured, the merge button stays blocked until those checks pass.
- If required approving reviews are configured, merge is blocked until the required number of approvals exists.
- If required signed commits are configured, unsigned (or invalidly signed) commits in the pull request block the merge.
- Rulesets add their own conditions, which can include code-scanning-alert conditions, and any branch-pattern matching they define.

Nothing changes in the local git workflow: contributors still push branches and open pull requests as usual. The rules only gate what can be merged on the remote. If both a branch protection rule and a ruleset apply to the same branch, every applicable requirement from both must be met before merge.

## Practical example

A team protects its default branch so that broken code cannot reach users:

1. CI runs on every pull request, reporting pass/fail as a status check.
2. A branch protection rule (or ruleset) on the default branch marks that status check as required and requires one approving review.
3. A contributor pushes a fix and opens a pull request. The merge button is blocked: the CI check is still running and no review has been given.
4. CI passes and a teammate approves the PR. The requirements are satisfied and the pull request can be merged.
5. Later, the team adopts a ruleset applying the same requirements to `release/*` as well as the default branch, in one ruleset rather than two separate per-branch rules. The original branch protection rule keeps working alongside it.

## Explanation guidance

### Essential

The default behavior is "any conflict-free PR can merge." Protection exists to change that. The three most common requirements are: tests must pass (required status checks), someone must approve (required reviews), and commits must be cryptographically signed (required signed commits). Rulesets are the newer way to do the same kind of gating, with the advantages of covering many branches at once, being visible to non-admins, and being able to depend on code-scanning alerts. Both mechanisms can be active at the same time on the same branch.

### Experienced-user note

For cross-cutting enforcement (e.g. "no merges into any release branch without passing checks"), rulesets avoid the maintenance burden of one branch protection rule per branch. Note also that a "Verified" badge requirement attests to signer identity only -- a signed commit can still contain broken or malicious code. Server-side enforcement via branch protection (or rulesets) is what makes signature a merge gate rather than just a display.

### Optional deeper context

The GitHub REST API references `required_signatures` on branch protection, so these requirements are scriptable and auditable beyond the web UI. Because rulesets are newer, older repositories and older integrations may only be aware of branch protection; teams migrating should check that any tooling reading protection state understands rulesets, or keep both mechanisms active during transition.

## Cautions and common failures

- Setting up protection without having CI report status means "required status checks" can never be satisfied -- merges stay blocked with no path forward.
- Requiring signed commits blocks every commit by contributors who have not registered a signing key with their GitHub account, which can surprise collaborators mid-merge.
- Rules are enforced at merge time on GitHub; they do not change local git behavior, so a contributor may push freely and only hit the wall at PR merge.
- Admins can edit or bypass some rules depending on configuration; protection is a policy mechanism, not a technical impossibility.
- Overlapping rules (branch protection plus one or more rulesets) each add requirements; a PR must satisfy all of them, which can make merge gates stricter than any single rule intended.

## Related capabilities

- verified-commit-badge (what the "Verified" badge on signed commits means)
- codeowners (automatic reviewer requests when protected paths change)
- github-cli-for-prs (checking PR status and CI checks locally with `gh pr status` / `gh pr checks`)
- linking-issues-to-prs (traceability through the PR merge gate)

## Official sources

- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches -- GitHub Docs: About protected branches (branch protection rules and what they can require).
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets -- GitHub Docs: Available rules for rulesets (what rulesets can enforce and how they relate to branch protection).

## Provenance

This page was authored against the cited official GitHub documentation ("About protected branches" and "Available rules for rulesets" on docs.github.com), retrieved via Context7 against docs.github.com. GitHub reorganizes its documentation paths periodically, so spot-check the cited URLs against current docs before shipping.