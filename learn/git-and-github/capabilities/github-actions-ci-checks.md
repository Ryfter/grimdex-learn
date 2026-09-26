---
title: Reading CI checks on a pull request
module_id: git-and-github
capabilities:
  - github-actions-ci-checks
context7_library: /websites/github_en_actions
context7_queries:
  - pull request check status pending success failure
  - gh run view exit-status scripting
  - workflow skipped branch path filtering status check stuck pending
official_sources:
  - https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows
  - https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/view-workflow-run-history
  - https://docs.github.com/en/actions/using-workflows/trigger-a-workflow
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

A GitHub Actions workflow run triggered by a pull request (for example, via `on: pull_request`) shows up as a **check** on that PR. Each check communicates its state at a glance:

- **Pending** — the workflow is running (or waiting to run).
- **Success** (green) — the run finished and passed.
- **Failure** (red) — the run finished and failed.

This page covers reading and understanding what a check means and why one might be stuck — not how to author workflow YAML files, which is beyond this lesson's scope.

## When it is useful

- Interpreting a PR before merging: knowing whether a pending check means "still running," a green one means "safe to consider," and a red one means "fix before merge."
- Scripting around CI: using `gh run view <run-id> --exit-status`, which returns a non-zero exit code if the run failed, so shells and scripts can react to a failure automatically.
- Diagnosing the common beginner confusion where a PR seems blocked on a check that never appears to be doing anything.

## Prerequisites

- A repository with at least one GitHub Actions workflow that triggers on pull requests.
- The `gh` CLI (GitHub CLI) installed and authenticated, if you want to check run status from the terminal.

## Current syntax

From the CLI:

```
gh pr status        # summarizes your relevant PRs, including CI checks and review status
gh pr checks        # more detailed CI status for the current PR
gh run view <run-id> --exit-status   # non-zero exit code if the run failed
```

The `--exit-status` flag on `gh run view` is the documented way to make a script fail when the underlying workflow run failed.

## What happens (local and remote)

- When a PR is opened, GitHub evaluates the repository's workflows for `pull_request` triggers. Matching workflows run, and their runs appear as checks on the PR page.
- Check states transition from pending → success or failure as runs complete.
- If repository admins have configured branch protection with required status checks, the PR **cannot be merged** until the required checks reach a passing state.

## Practical example

A contributor opens a PR. The checks section shows one green check, one red check, and one check that has been sitting yellow/pending for a long time with no visible run activity.

They run:

```
gh pr checks
```

and see the failing run's ID. They inspect it:

```
gh run view 123456 --exit-status
```

The command exits non-zero, confirming the run failed — the red check reflects a real failure to fix.

## Explanation guidance

### Essential

- Pending means running or queued; green means passed; red means failed.
- A workflow run triggered by a PR shows up as a check on that PR — that's how CI "reports" to the PR.
- If a required check hasn't passed, branch protection blocks the merge regardless of everything else.

### Experienced-user note

- `gh run view <run-id> --exit-status` is designed for scripting: use it in shell scripts or CI wrappers to detect failure via exit code rather than parsing output.
- `gh pr status` gives a summary across your PRs; `gh pr checks` gives per-check CI detail for the current branch's PR.

### Optional deeper context

- The documented **gotcha**: if a workflow is **skipped** — due to branch filtering, path filtering, or a commit-message condition — any status check tied to that workflow can stay stuck in **PENDING** state. If that check is required by branch protection, the PR will be **blocked from merging even though nothing is actually running or failing**. Recognizing this pattern ("no run activity, check never resolves") saves a lot of confusion; the fix usually involves the workflow's trigger conditions or the branch protection configuration, and is documented in the official sources below.

## Cautions and common failures

- **Stuck-pending check**: as above, a skipped workflow (branch/path filter or commit-message condition) leaves its check pending and can block merge with nothing actually running. Don't keep re-running or waiting on it — check the workflow's trigger conditions.
- **A green check is not a guarantee of correctness**: it attests that the configured workflow ran and passed, not that the code is safe or correct.
- **Check appears pending but no workflow exists for it**: this can happen when a required check references a workflow that never triggers on this PR's changes.

## Related capabilities

- Branch protection & rulesets (`branch-protection-rulesets`) — required status checks are configured there.
- GitHub CLI for PRs (`github-cli-for-prs`) — `gh pr status`, `gh pr checks`, `gh pr checkout`.

## Official sources

- [Events that trigger workflows](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows)
- [View workflow run history](https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/view-workflow-run-history)
- [Trigger a workflow](https://docs.github.com/en/actions/using-workflows/trigger-a-workflow)

## Provenance

Authored against official GitHub Actions documentation (docs.github.com/en/actions), verified via Context7 as of 2026-09-20. Covers only recognition-level content: reading PR checks, scripting with `gh run view --exit-status`, and the documented skipped-workflow/pending-check gotcha. Workflow YAML authoring is explicitly out of scope; see official sources for authoring guidance.