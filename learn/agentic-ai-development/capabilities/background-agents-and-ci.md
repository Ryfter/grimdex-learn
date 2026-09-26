---
title: Background and autonomous agents in CI (issue-to-PR patterns)
module_id: agentic-ai-development
capabilities:
  - background-agents-and-ci
context7_library: /websites/platform_claude_en
context7_queries:
  - How do autonomous coding agents handle delegated tasks with human approval before merging?
  - What guardrails does Anthropic recommend when agents act with limited supervision?
  - How should permission and sandboxing features bound an agent's blast radius?
official_sources:
  - https://docs.github.com/en/copilot
  - https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
last_checked: 2026-09-20
last_material_update: 2026-09-20
status: current
claim_class: everyday
safety_class: normal
version_stamp: fall-2026-0.1.0
admission:
  course_independent: true
  public_ready: true
  provenance: practice-guidance-with-official-anchors
---

## What it is

Some coding-agent tools can now run in the background: instead of sitting with you in an editor, they take a task — commonly a GitHub issue — and work on it autonomously, producing a draft pull request with an attempted fix. GitHub's own Copilot coding agent is a real, shipped example of this pattern, and other vendors offer similar "assign a task, get a PR" offerings.

The key design idea is that autonomy stops before the merge point. The agent opens a draft PR, but a human reviews and approves it before anything lands, using the normal machinery of branch protection and required review. The approval gate is the existing code-review process, not a new AI-specific one.

## When it is useful

- Well-scoped issues (a bug with a clear reproduction, a small feature, routine refactors, documentation fixes) where "what done looks like" is easy to state.
- Teams that already review pull requests and want an agent to draft the first attempt, with the human effort concentrated in review rather than in writing the first version.
- Clearing backlogs of small, independent issues in parallel without waiting for a developer to pick each one up.

## Prerequisites

- A repository hosted on a platform that supports the agent feature (e.g. GitHub, for the Copilot coding agent).
- An existing review workflow: branch protection rules and required reviews, so nothing merges without a human.
- Issues written clearly enough that an agent can act on them without follow-up questions.

## Current syntax

There is no syntax to learn for the core pattern — it is driven by the issue tracker itself. On GitHub, the general shape (without relying on specific UI details that may change) is: assign an issue to the coding agent, the agent works on it and opens a draft pull request, and a human reviews that PR as they would any other. For exact, current assignment mechanics, consult GitHub's Copilot coding agent documentation directly rather than assuming a specific button or command.

## What happens (local and remote)

Everything happens remotely, in the platform's environment — not on your laptop:

1. A human assigns an issue to the agent.
2. The agent picks up the issue, works in its own branch or workspace, attempts the fix, and opens a draft pull request.
3. The agent may iterate based on review comments or automated checks, as a human contributor would.
4. A human reviews the draft PR. Branch protection / required review is the approval gate: the agent cannot merge its own work.
5. On approval, the change merges through the normal process, with the normal history and traceability.

Because the work happens in a PR, you get the same audit trail as any contributor: which issue it came from, what changed, what checks ran, and who approved it.

## Practical example

A team has a backlog issue: "Fix the date parsing error when the locale field is missing." A developer assigns the issue to the repo's coding agent. Some time later, a draft PR appears with a proposed fix and tests. A maintainer reviews it, notices the agent handled the missing-locale case but not an empty-string case, leaves review comments, and the agent pushes an update. The maintainer then approves, and branch protection ensures no merge happened before that approval.

The human time spent: reading the issue (already written), reviewing two rounds of a small diff, approving. The agent did the mechanical typing and searching in between.

## Explanation guidance

### Essential

- This is a shipped, real pattern today — not speculation. Assign an issue, get a draft PR, review it like any other PR.
- The safety story is not a new AI control system; it is the review process you should already have. Branch protection and required review are what stop an agent's work from reaching production unchecked.
- The agent drafts; the human decides. Treat agent PRs with the same (or slightly more) scrutiny as human PRs from an unfamiliar contributor.

### Experienced-user note

- Agent-drafted PRs work best when the issue itself is the spec — the pattern pairs naturally with plan-first and verification-first habits. If your repo has tests and CI checks, the agent has an objective signal to iterate against; if it doesn't, the draft PR quality will reflect that.
- This composes with least-privilege practices: the agent should have exactly the access it needs to open PRs, and nothing more.

### Optional deeper context

- The same underlying idea (delegate a bounded task, gate the result through a human check) extends beyond coding agents — Anthropic's platform docs describe human-confirmation steps in agent workflows more generally, including automated detection of suspicious content that can trigger a confirmation step.
- Over time, expect vendor implementations to differ in where the agent runs, how it comments, and how it iterates. The issue-to-draft-PR-to-review shape is the stable part of the pattern.

## Cautions and common failures

- **Vague issues produce vague PRs.** An agent assigned "improve the login flow" will produce something plausible-looking that likely isn't what anyone wanted. Well-specified issues are a prerequisite, not a nicety.
- **The review gate is only as strong as the review.** Rubber-stamping agent PRs ("the checks passed, ship it") removes the entire safety mechanism. Verify claims against the actual diff and actual test runs — don't take the agent's summary at face value.
- **Merge-to-main without protection is a footgun.** If your repo allows direct merges with no required review, an agent has nothing stopping it from landing changes. Set up branch protection first.
- **Don't assign what needs a conversation.** Issues requiring back-and-forth clarification, architectural decisions, or cross-team context are poor autonomous-agent candidates — delegate only genuinely independent, well-bounded tasks.

## Related capabilities

- **verifying-agent-work** — the core discipline of checking an agent's claims against the actual diff and actual runs; review of an agent PR is exactly this discipline applied in CI.
- **sandboxing-and-least-privilege** — bounding what the agent can do and touch when it works autonomously.
- **human-in-the-loop steering** — pausing or redirecting a running agent before it completes a long wrong-direction run.
- **agent evals** — a fixed set of golden tasks complements per-PR review when measuring agent quality over time.

## Official sources

- GitHub Copilot documentation (includes the Copilot coding agent): https://docs.github.com/en/copilot — vendor documentation for a shipped feature.
- GitHub on protected branches (required review / approval gates): https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
- Anthropic platform docs on agent guardrails (human-confirmation steps, sandboxing concepts): https://platform.claude.com/docs/en/test-and-evaluate/strengthen-guardrails/mitigate-jailbreaks

## Provenance

This page describes a real, current, shipped pattern: GitHub's Copilot coding agent and similar vendor offerings can be assigned a GitHub issue and open a draft PR attempting a fix, with branch protection / required review as the human approval gate before merge. Sources are GitHub's own product documentation and Anthropic's platform docs; specific UI mechanics were deliberately kept generic and readers are pointed to the official docs for current details. No statistics, flags, or UI specifics beyond the grounding facts have been invented.